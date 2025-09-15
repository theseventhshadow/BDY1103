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
    IF log_error('INFO', 'proyeccion_estudiantes_para_prox_semestres', 
                 'Sin datos históricos - Proyectando ceros para Institución: ' || p_institucion_id || 
                 ', Carrera: ' || p_carrera_id || ', Semestres: ' || p_next_n) = 0 THEN
      NULL; -- Fallo en logging, continúa
    END IF;
    
    FOR i IN 1..p_next_n LOOP 
      v_resultado.EXTEND; 
      v_resultado(i) := 0; 
    END LOOP;
    RETURN v_resultado;
    
  ELSIF idx = 1 THEN
    -- Solo un período histórico disponible
    IF log_error('INFO', 'proyeccion_estudiantes_para_prox_semestres', 
                 'Solo un período histórico - Manteniendo valor constante para Institución: ' || p_institucion_id || 
                 ', Carrera: ' || p_carrera_id || ', Estudiantes: ' || v_counts(1) || ', Semestres: ' || p_next_n) = 0 THEN
      NULL; -- Fallo en logging, continúa
    END IF;
    
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
      IF log_error('WARNING', 'proyeccion_estudiantes_para_prox_semestres', 
                   'Período anterior con 0 estudiantes - Usando crecimiento = 0 para Institución: ' || p_institucion_id || 
                   ', Carrera: ' || p_carrera_id || ', v_last: ' || v_last || ', v_prev: ' || v_prev) = 0 THEN
        NULL; -- Fallo en logging, continúa
      END IF;
    ELSE
      v_growth := (v_last - v_prev) / v_prev;
      IF log_error('INFO', 'proyeccion_estudiantes_para_prox_semestres', 
                   'Calculando proyección con crecimiento ' || ROUND(v_growth * 100, 2) || '% (base: ' || v_prev || ' → ' || v_last || 
                   ') para Institución: ' || p_institucion_id || ', Carrera: ' || p_carrera_id || ', Semestres: ' || p_next_n) = 0 THEN
        NULL; -- Fallo en logging, continúa
      END IF;
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
    IF log_error('WARNING', 'proyeccion_estudiantes_para_prox_semestres', 
                 'No se encontraron datos históricos para Institución: ' || p_institucion_id || 
                 ', Carrera: ' || p_carrera_id || ', Parámetros: n_semestres=' || p_next_n) = 0 THEN
      NULL; -- Fallo en logging, continúa
    END IF;
    
    v_resultado := proy_sem_t();
    FOR i IN 1..p_next_n LOOP 
      v_resultado.EXTEND; 
      v_resultado(i) := 0; 
    END LOOP;
    RETURN v_resultado;
    
  WHEN VALUE_ERROR THEN
    IF log_error('ERROR', 'proyeccion_estudiantes_para_prox_semestres', 
                 'Valor inválido detectado en parámetros - Institución: ' || NVL(TO_CHAR(p_institucion_id), 'NULL') || 
                 ', Carrera: ' || NVL(TO_CHAR(p_carrera_id), 'NULL') || 
                 ', N semestres: ' || NVL(TO_CHAR(p_next_n), 'NULL')) = 0 THEN
      NULL; -- Fallo en logging, continúa
    END IF;
    RAISE_APPLICATION_ERROR(-20001, 
      'Error en valores: Verifique que los parámetros sean válidos');
    
  WHEN COLLECTION_IS_NULL THEN
    IF log_error('ERROR', 'proyeccion_estudiantes_para_prox_semestres', 
                 'Problema con inicialización de colecciones - Institución: ' || p_institucion_id || 
                 ', Carrera: ' || p_carrera_id || ', idx: ' || NVL(TO_CHAR(idx), 'NULL')) = 0 THEN
      NULL; -- Fallo en logging, continúa
    END IF;
    RAISE_APPLICATION_ERROR(-20002, 
      'Error interno: Fallo en inicialización de estructuras de datos');
    
  WHEN SUBSCRIPT_BEYOND_COUNT THEN
    IF log_error('ERROR', 'proyeccion_estudiantes_para_prox_semestres', 
                 'Acceso fuera de rango en colección - idx actual: ' || NVL(TO_CHAR(idx), 'NULL') || 
                 ', Tamaño v_counts: ' || NVL(TO_CHAR(v_counts.COUNT), 'NULL') ||
                 ', Institución: ' || p_institucion_id || ', Carrera: ' || p_carrera_id) = 0 THEN
      NULL; -- Fallo en logging, continúa
    END IF;
    RAISE_APPLICATION_ERROR(-20003, 
      'Error de datos: Información histórica insuficiente');
    
  WHEN SUBSCRIPT_OUTSIDE_LIMIT THEN
    IF log_error('ERROR', 'proyeccion_estudiantes_para_prox_semestres', 
                 'Límite de VARRAY excedido - N semestres solicitados: ' || NVL(TO_CHAR(p_next_n), 'NULL') ||
                 ', Institución: ' || p_institucion_id || ', Carrera: ' || p_carrera_id) = 0 THEN
      NULL; -- Fallo en logging, continúa
    END IF;
    RAISE_APPLICATION_ERROR(-20004, 
      'Error de capacidad: Número de semestres excede límite máximo');
    
  WHEN ZERO_DIVIDE THEN
    IF log_error('WARNING', 'proyeccion_estudiantes_para_prox_semestres', 
                 'División por cero detectada - Aplicando fallback: crecimiento = 0, v_last: ' || NVL(TO_CHAR(v_last), 'NULL') || 
                 ', v_prev: ' || NVL(TO_CHAR(v_prev), 'NULL') ||
                 ', Institución: ' || p_institucion_id || ', Carrera: ' || p_carrera_id) = 0 THEN
      NULL; -- Fallo en logging, continúa
    END IF;
    
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
      IF log_error('CRITICAL', 'proyeccion_estudiantes_para_prox_semestres', 
                   'ERROR INESPERADO: ' || v_error_msg || 
                   ' | PARÁMETROS: p_institucion_id=' || NVL(TO_CHAR(p_institucion_id), 'NULL') ||
                   ', p_carrera_id=' || NVL(TO_CHAR(p_carrera_id), 'NULL') ||
                   ', p_next_n=' || NVL(TO_CHAR(p_next_n), 'NULL') ||
                   ' | ESTADO: idx=' || NVL(TO_CHAR(idx), 'NULL') ||
                   ', v_last=' || NVL(TO_CHAR(v_last), 'NULL') ||
                   ', v_prev=' || NVL(TO_CHAR(v_prev), 'NULL')) = 0 THEN
        NULL; -- Fallo en logging, continúa
      END IF;
      
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
          IF log_error('CRITICAL', 'proyeccion_estudiantes_para_prox_semestres', 
                       'Error crítico en fallback: ' || SQLERRM || 
                       ' - Sistema inestable - Parámetros: inst=' || p_institucion_id || ', carrera=' || p_carrera_id) = 0 THEN
            NULL; -- Fallo en logging, continúa
          END IF;
          RAISE_APPLICATION_ERROR(-20999, 
            'Error crítico: Sistema inestable');
      END;
    END;
    
END proyeccion_estudiantes_para_prox_semestres;
/
