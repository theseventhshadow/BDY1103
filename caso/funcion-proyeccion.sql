-- ======================================================================
-- FUNCIÓN: proyeccion_estudiantes_para_prox_semestres
-- ======================================================================
-- Calcula una proyección de estudiantes para los próximos N semestres
-- basándose en datos históricos de matrícula con manejo robusto de errores
-- ======================================================================

CREATE OR REPLACE FUNCTION proyeccion_estudiantes_para_prox_semestres(
  p_institucion_id INTEGER,
  p_carrera_id INTEGER,
  p_next_n NUMBER DEFAULT 4
) RETURN proy_sem_t IS

  -- Variables principales
  v_resultado proy_sem_t := proy_sem_t();
  
  -- Tipo de registro para estructurar datos del cursor
  TYPE cnt_rec IS RECORD (anio SMALLINT, semestre SMALLINT, cnt NUMBER);
  
  -- Cursor para obtener datos históricos ordenados (más reciente primero)
  CURSOR c_hist IS
    SELECT ANIO_INGRESO, SEMESTRE_INGRESO, COUNT(*) cnt
    FROM MATRICULAS
    WHERE INSTITUCION_ID = p_institucion_id
      AND CARRERA_ID = p_carrera_id
    GROUP BY ANIO_INGRESO, SEMESTRE_INGRESO
    ORDER BY ANIO_INGRESO DESC, SEMESTRE_INGRESO DESC;

  -- Variables de trabajo
  v_counts SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
  idx INTEGER := 0;
  v_last NUMBER := 0;
  v_prev NUMBER := 0;
  v_growth NUMBER := 0;
  
BEGIN
  -- VALIDACIÓN DE PARÁMETROS DE ENTRADA
  IF p_institucion_id IS NULL OR p_carrera_id IS NULL THEN
    RAISE_APPLICATION_ERROR(-20005, 
      'Error de parámetros: institucion_id y carrera_id no pueden ser NULL');
  END IF;
  
  IF p_next_n IS NULL OR p_next_n <= 0 OR p_next_n > 50 THEN
    RAISE_APPLICATION_ERROR(-20006, 
      'Error de parámetros: next_n debe estar entre 1 y 50');
  END IF;

  -- RECOLECCIÓN DE DATOS HISTÓRICOS
  FOR r IN c_hist LOOP
    idx := idx + 1;
    v_counts.EXTEND;
    v_counts(idx) := r.cnt;
    EXIT WHEN idx = 2;
  END LOOP;

  -- ANÁLISIS Y PROYECCIÓN SEGÚN ESCENARIOS
  IF idx = 0 THEN
    -- Sin historial disponible
    DBMS_OUTPUT.PUT_LINE('INFO: Sin datos históricos para Institución ' || 
      p_institucion_id || ', Carrera ' || p_carrera_id || '. Proyectando ceros.');
    FOR i IN 1..p_next_n LOOP 
      v_resultado.EXTEND; 
      v_resultado(i) := 0; 
    END LOOP;
    RETURN v_resultado;
    
  ELSIF idx = 1 THEN
    -- Solo un período histórico disponible
    DBMS_OUTPUT.PUT_LINE('INFO: Solo un período histórico encontrado (' || 
      v_counts(1) || ' estudiantes). Manteniendo valor constante.');
    FOR i IN 1..p_next_n LOOP 
      v_resultado.EXTEND; 
      v_resultado(i) := v_counts(1); 
    END LOOP;
    RETURN v_resultado;
    
  ELSE
    -- Dos o más períodos - calcular crecimiento
    v_last := v_counts(1);
    v_prev := v_counts(2);
    
    IF v_prev = 0 THEN
      v_growth := 0;
      DBMS_OUTPUT.PUT_LINE('WARNING: Período anterior con 0 estudiantes. Usando crecimiento = 0');
    ELSE
      v_growth := (v_last - v_prev) / v_prev;
      DBMS_OUTPUT.PUT_LINE('INFO: Calculando proyección con crecimiento ' || 
        ROUND(v_growth * 100, 2) || '% (base: ' || v_prev || ' → ' || v_last || ')');
    END IF;
    
    -- Generar proyección con crecimiento compuesto
    FOR i IN 1..p_next_n LOOP
      v_resultado.EXTEND;
      IF i = 1 THEN
        v_resultado(i) := ROUND(v_last * (1 + v_growth));
      ELSE
        v_resultado(i) := ROUND(v_resultado(i-1) * (1 + v_growth));
      END IF;
    END LOOP;
    RETURN v_resultado;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('WARNING: No se encontraron datos históricos');
    DBMS_OUTPUT.PUT_LINE('  - Institución ID: ' || p_institucion_id);
    DBMS_OUTPUT.PUT_LINE('  - Carrera ID: ' || p_carrera_id);
    v_resultado := proy_sem_t();
    FOR i IN 1..p_next_n LOOP 
      v_resultado.EXTEND; 
      v_resultado(i) := 0; 
    END LOOP;
    RETURN v_resultado;
    
  WHEN VALUE_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: Valor inválido detectado en parámetros');
    DBMS_OUTPUT.PUT_LINE('  - Institución: ' || NVL(TO_CHAR(p_institucion_id), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - Carrera: ' || NVL(TO_CHAR(p_carrera_id), 'NULL')); 
    DBMS_OUTPUT.PUT_LINE('  - N semestres: ' || NVL(TO_CHAR(p_next_n), 'NULL'));
    RAISE_APPLICATION_ERROR(-20001, 
      'Error en valores: Verifique que los parámetros sean válidos');
    
  WHEN COLLECTION_IS_NULL THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: Problema con inicialización de colecciones');
    RAISE_APPLICATION_ERROR(-20002, 
      'Error interno: Fallo en inicialización de estructuras de datos');
    
  WHEN SUBSCRIPT_BEYOND_COUNT THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: Acceso fuera de rango en colección');
    DBMS_OUTPUT.PUT_LINE('  - idx actual: ' || NVL(TO_CHAR(idx), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - Tamaño v_counts: ' || NVL(TO_CHAR(v_counts.COUNT), 'NULL'));
    RAISE_APPLICATION_ERROR(-20003, 
      'Error de datos: Información histórica insuficiente');
    
  WHEN SUBSCRIPT_OUTSIDE_LIMIT THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: Límite de VARRAY excedido');
    DBMS_OUTPUT.PUT_LINE('  - N semestres solicitados: ' || NVL(TO_CHAR(p_next_n), 'NULL'));
    RAISE_APPLICATION_ERROR(-20004, 
      'Error de capacidad: Número de semestres excede límite máximo');
    
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('WARNING: División por cero detectada');
    DBMS_OUTPUT.PUT_LINE('  - Aplicando fallback: crecimiento = 0');
    v_resultado := proy_sem_t();
    FOR i IN 1..p_next_n LOOP 
      v_resultado.EXTEND; 
      v_resultado(i) := NVL(v_last, 0);
    END LOOP;
    RETURN v_resultado;
    
  WHEN OTHERS THEN
    DECLARE
      v_error_code NUMBER := SQLCODE;
      v_error_msg VARCHAR2(4000) := SQLERRM;
    BEGIN
      DBMS_OUTPUT.PUT_LINE('======== ERROR INESPERADO ========');
      DBMS_OUTPUT.PUT_LINE('CÓDIGO: ' || v_error_code);
      DBMS_OUTPUT.PUT_LINE('MENSAJE: ' || v_error_msg);
      DBMS_OUTPUT.PUT_LINE('PARÁMETROS:');
      DBMS_OUTPUT.PUT_LINE('  - p_institucion_id: ' || NVL(TO_CHAR(p_institucion_id), 'NULL'));
      DBMS_OUTPUT.PUT_LINE('  - p_carrera_id: ' || NVL(TO_CHAR(p_carrera_id), 'NULL'));
      DBMS_OUTPUT.PUT_LINE('  - p_next_n: ' || NVL(TO_CHAR(p_next_n), 'NULL'));
      DBMS_OUTPUT.PUT_LINE('ESTADO INTERNO:');
      DBMS_OUTPUT.PUT_LINE('  - idx: ' || NVL(TO_CHAR(idx), 'NULL'));
      DBMS_OUTPUT.PUT_LINE('  - v_last: ' || NVL(TO_CHAR(v_last), 'NULL'));
      DBMS_OUTPUT.PUT_LINE('  - v_prev: ' || NVL(TO_CHAR(v_prev), 'NULL'));
      DBMS_OUTPUT.PUT_LINE('===================================');
      
      -- Fallback seguro
      BEGIN
        v_resultado := proy_sem_t();
        FOR i IN 1..LEAST(NVL(p_next_n, 4), 50) LOOP
          v_resultado.EXTEND; 
          v_resultado(i) := 0; 
        END LOOP;
        RETURN v_resultado;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20999, 
            'Error crítico: Sistema inestable');
      END;
    END;
    
END proyeccion_estudiantes_para_prox_semestres;
/
