-- ======================================================================
-- PACKAGE BODY: PKG_PROYECCION_RECURSOS
-- ======================================================================
-- Implementación del package para proyecciones y planificación de recursos
-- ======================================================================

CREATE OR REPLACE PACKAGE BODY PKG_PROYECCION_RECURSOS AS

  -- ====================================================================
  -- VARIABLES PRIVADAS DEL PACKAGE
  -- ====================================================================
  
  -- Variables de configuración privadas
  g_debug_mode BOOLEAN := FALSE;
  g_log_enabled BOOLEAN := TRUE;
  g_package_initialized BOOLEAN := FALSE;
  g_call_count NUMBER := 0;
  g_error_count NUMBER := 0;
  
  -- Cache para mejorar rendimiento
  TYPE t_institucion_cache IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
  TYPE t_carrera_cache IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
  g_institucion_cache t_institucion_cache;
  g_carrera_cache t_carrera_cache;
  
  -- ====================================================================
  -- FUNCIONES PRIVADAS (SOLO ACCESIBLES DENTRO DEL PACKAGE)
  -- ====================================================================
  
  -- Función privada para validar parámetros comunes
  FUNCTION validar_parametros_basicos(
    p_institucion_id INTEGER,
    p_carrera_id INTEGER,
    p_next_n NUMBER
  ) RETURN BOOLEAN IS
  BEGIN
    IF p_institucion_id IS NULL OR p_carrera_id IS NULL THEN
      RETURN FALSE;
    END IF;
    
    IF p_next_n IS NULL OR p_next_n <= 0 OR p_next_n > C_MAX_PROYECCION_SEMESTERS THEN
      RETURN FALSE;
    END IF;
    
    RETURN TRUE;
  END validar_parametros_basicos;
  
  -- Función privada para obtener año y semestre actuales
  PROCEDURE get_current_year_semester(
    p_anio OUT NUMBER,
    p_semestre OUT NUMBER
  ) IS
    v_mes NUMBER;
  BEGIN
    p_anio := TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'));
    v_mes := TO_NUMBER(TO_CHAR(SYSDATE,'MM'));
    p_semestre := CASE WHEN v_mes <= 6 THEN 1 ELSE 2 END;
  END get_current_year_semester;
  
  -- ====================================================================
  -- IMPLEMENTACIÓN DE FUNCIONES PÚBLICAS
  -- ====================================================================
  
  -- Función de logging centralizado
  -- 1 Exito, 0 Fallo
  FUNCTION log_error(
    p_severity VARCHAR2,
    p_source_obj VARCHAR2,
    p_error_msg VARCHAR2
  ) RETURN NUMBER IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    IF NOT g_log_enabled THEN
      RETURN 1;
    END IF;
    
    INSERT INTO ERROR_LOG (SEVERITY, SOURCE_OBJ, ERROR_MSG)
    VALUES (p_severity, p_source_obj, p_error_msg);
    COMMIT;
    RETURN 1; 
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN 0; 
  END log_error;
  
  -- Función para calcular profesores requeridos
  FUNCTION profs_req(
    p_estudiantes NUMBER, 
    p_razon NUMBER DEFAULT C_DEFAULT_STUDENT_TEACHER_RATIO
  ) RETURN NUMBER IS
  BEGIN
    IF p_estudiantes IS NULL OR p_estudiantes <= 0 THEN
      RETURN 0;
    ELSE
      RETURN CEIL(p_estudiantes / NVL(p_razon, C_DEFAULT_STUDENT_TEACHER_RATIO));
    END IF;
  END profs_req;
  
  -- Función para calcular aulas requeridas
  FUNCTION salas_req(
    p_estudiantes NUMBER, 
    p_sala_capacidad NUMBER DEFAULT C_DEFAULT_CLASSROOM_CAPACITY
  ) RETURN NUMBER IS
  BEGIN
    IF p_estudiantes IS NULL OR p_estudiantes <= 0 THEN
      RETURN 0;
    ELSE
      RETURN CEIL(p_estudiantes / NVL(p_sala_capacidad, C_DEFAULT_CLASSROOM_CAPACITY));
    END IF;
  END salas_req;
  
  -- Función para validar existencia de institución
  FUNCTION institucion_exists(p_institucion_id INTEGER) RETURN BOOLEAN IS
    v_count NUMBER;
  BEGIN
    -- Verificar cache primero
    IF g_institucion_cache.EXISTS(p_institucion_id) THEN
      RETURN g_institucion_cache(p_institucion_id);
    END IF;
    
    -- Consultar base de datos
    SELECT COUNT(*) INTO v_count 
    FROM INSTITUCIONES 
    WHERE INSTITUCION_ID = p_institucion_id;
    
    -- Almacenar en cache
    g_institucion_cache(p_institucion_id) := (v_count > 0);
    
    RETURN (v_count > 0);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END institucion_exists;
  
  -- Función para validar existencia de carrera
  FUNCTION carrera_exists(p_carrera_id INTEGER) RETURN BOOLEAN IS
    v_count NUMBER;
  BEGIN
    -- Verificar cache primero
    IF g_carrera_cache.EXISTS(p_carrera_id) THEN
      RETURN g_carrera_cache(p_carrera_id);
    END IF;
    
    -- Consultar base de datos
    SELECT COUNT(*) INTO v_count 
    FROM CARRERAS 
    WHERE CARRERA_ID = p_carrera_id;
    
    -- Almacenar en cache
    g_carrera_cache(p_carrera_id) := (v_count > 0);
    
    RETURN (v_count > 0);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END carrera_exists;
  
  -- Función para obtener capacidad de institución
  FUNCTION get_institucion_capacity(
    p_institucion_id INTEGER,
    p_capacidad_por_aula OUT NUMBER,
    p_salas_disponibles OUT NUMBER
  ) RETURN BOOLEAN IS
    v_count NUMBER;
  BEGIN
    -- Verificar si existe registro de capacidad
    SELECT COUNT(*) INTO v_count
    FROM INSTITUCION_CAPACIDAD
    WHERE INSTITUCION_ID = p_institucion_id;
    
    IF v_count = 0 THEN
      -- Usar valores por defecto
      p_capacidad_por_aula := C_DEFAULT_CLASSROOM_CAPACITY;
      p_salas_disponibles := 10; -- Valor por defecto conservador
      
      IF log_error(C_LOG_WARNING, 'get_institucion_capacity', 
                   'Capacidad no configurada para institución ' || p_institucion_id || 
                   ' - usando valores por defecto') = 0 THEN
        NULL; -- Error en logging, continúa
      END IF;
    ELSE
      -- Obtener valores configurados
      SELECT NVL(CAPACIDAD_POR_AULA, C_DEFAULT_CLASSROOM_CAPACITY),
             NVL(TOTAL_AULAS, 10)
      INTO p_capacidad_por_aula, p_salas_disponibles
      FROM INSTITUCION_CAPACIDAD
      WHERE INSTITUCION_ID = p_institucion_id;
      
      -- Validar valores obtenidos
      IF p_capacidad_por_aula <= 0 THEN
        p_capacidad_por_aula := C_DEFAULT_CLASSROOM_CAPACITY;
      END IF;
      
      IF p_salas_disponibles <= 0 THEN
        p_salas_disponibles := 1;
      END IF;
    END IF;
    
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      p_capacidad_por_aula := C_DEFAULT_CLASSROOM_CAPACITY;
      p_salas_disponibles := 10;
      RETURN FALSE;
  END get_institucion_capacity;
  
  -- Función para calcular etiqueta de semestre
  FUNCTION calcular_semestre_label(
    p_base_anio NUMBER,
    p_base_semestre NUMBER,
    p_offset NUMBER
  ) RETURN VARCHAR2 IS
    v_anio NUMBER := p_base_anio;
    v_semestre NUMBER := p_base_semestre;
    v_remaining_offset NUMBER := p_offset;
  BEGIN
    -- Calcular el año y semestre resultante
    WHILE v_remaining_offset > 0 LOOP
      IF v_semestre = 1 THEN
        v_semestre := 2;
      ELSE
        v_semestre := 1;
        v_anio := v_anio + 1;
      END IF;
      v_remaining_offset := v_remaining_offset - 1;
    END LOOP;
    
    RETURN v_anio || '-' || v_semestre;
  END calcular_semestre_label;
  
  -- Función principal de proyección de estudiantes
  FUNCTION proyeccion_estudiantes_para_prox_semestres(
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
    -- Incrementar contador de llamadas
    g_call_count := g_call_count + 1;
    
    -- VALIDACIÓN DE PARÁMETROS DE ENTRADA
    IF NOT validar_parametros_basicos(p_institucion_id, p_carrera_id, p_next_n) THEN
      RAISE_APPLICATION_ERROR(-20005, 
        'Error de parámetros: institucion_id y carrera_id no pueden ser NULL, next_n debe estar entre 1 y ' || C_MAX_PROYECCION_SEMESTERS);
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
      IF log_error(C_LOG_INFO, 'proyeccion_estudiantes_para_prox_semestres', 
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
      IF log_error(C_LOG_INFO, 'proyeccion_estudiantes_para_prox_semestres', 
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
        IF log_error(C_LOG_WARNING, 'proyeccion_estudiantes_para_prox_semestres', 
                     'Período anterior con 0 estudiantes - Usando crecimiento = 0 para Institución: ' || p_institucion_id || 
                     ', Carrera: ' || p_carrera_id || ', v_last: ' || v_last || ', v_prev: ' || v_prev) = 0 THEN
          NULL; -- Fallo en logging, continúa
        END IF;
      ELSE
        v_growth := (v_last - v_prev) / v_prev;
        IF log_error(C_LOG_INFO, 'proyeccion_estudiantes_para_prox_semestres', 
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
  
  -- ====================================================================
  -- IMPLEMENTACIÓN DE PROCEDIMIENTOS PÚBLICOS
  -- ====================================================================
  
  -- Procedimiento principal para generar plan de recursos
  PROCEDURE build_plan_recursos(
    p_next_n NUMBER DEFAULT 4,
    p_institucion_id NUMBER DEFAULT NULL,
    p_carrera_id NUMBER DEFAULT NULL,
    p_region_id NUMBER DEFAULT NULL
  ) IS

    -- RECORD para la fila del cursor
    TYPE prog_rec IS RECORD (
      institucion_id INSTITUCIONES.INSTITUCION_ID%TYPE,
      institucion_nombre INSTITUCIONES.INSTITUCION_NOMBRE%TYPE,
      carrera_id CARRERAS.CARRERA_ID%TYPE,
      carrera_nombre CARRERAS.CARRERA_NOMBRE%TYPE
    );

    -- CURSOR COMPLEJO con parámetros para filtrar datos
    CURSOR c_prog(
      cp_institucion_id NUMBER,
      cp_carrera_id NUMBER,
      cp_region_id NUMBER
    ) IS
      SELECT DISTINCT m.INSTITUCION_ID,
             i.INSTITUCION_NOMBRE,
             m.CARRERA_ID,
             c.CARRERA_NOMBRE
      FROM MATRICULAS m
      JOIN INSTITUCIONES i ON m.INSTITUCION_ID = i.INSTITUCION_ID
      JOIN CARRERAS c ON m.CARRERA_ID = c.CARRERA_ID
      WHERE (cp_institucion_id IS NULL OR m.INSTITUCION_ID = cp_institucion_id)
        AND (cp_carrera_id IS NULL OR m.CARRERA_ID = cp_carrera_id)
        AND (cp_region_id IS NULL OR i.REGION_ID = cp_region_id)
      ORDER BY i.INSTITUCION_NOMBRE, c.CARRERA_NOMBRE;

    v_prog prog_rec;
    v_proyecto proy_sem_t;
    v_sem_label VARCHAR2(10);
    v_profs NUMBER;
    v_salas NUMBER;
    v_contador NUMBER := 0;

    -- helpers to compute labels (starting from current year/semester)
    v_anio_actual NUMBER;
    v_sem_actual NUMBER;

    -- Variables para logging de errores
    v_error_code NUMBER;
    v_error_msg VARCHAR2(4000);
    v_current_inst_id NUMBER;
    v_current_carrera_id NUMBER;
      -- Excepciones personalizadas
    e_no_historial EXCEPTION;
    e_parametros_invalidos EXCEPTION;
    e_tabla_no_existe EXCEPTION;
    e_capacidad_insuficiente EXCEPTION;
    e_datos_corruptos EXCEPTION;
    e_funcion_no_disponible EXCEPTION;
    
    -- Códigos de error personalizados
    PRAGMA EXCEPTION_INIT(e_tabla_no_existe, -00942);
    PRAGMA EXCEPTION_INIT(e_capacidad_insuficiente, -20200);
    PRAGMA EXCEPTION_INIT(e_datos_corruptos, -20201);
    PRAGMA EXCEPTION_INIT(e_funcion_no_disponible, -20202);
  BEGIN
    -- Incrementar contador de llamadas
    g_call_count := g_call_count + 1;
    
    -- Obtener año y semestre actuales
    get_current_year_semester(v_anio_actual, v_sem_actual);
    
    -- Validación de parámetros
    IF p_next_n IS NULL OR p_next_n <= 0 OR p_next_n > C_MAX_PROYECCION_SEMESTERS THEN
      RAISE_APPLICATION_ERROR(-20101, 'ERROR_PARAM: p_next_n debe estar entre 1 y ' || C_MAX_PROYECCION_SEMESTERS);
    END IF;
    
    -- Validación de existencia de institución si se especifica
    IF p_institucion_id IS NOT NULL AND NOT institucion_exists(p_institucion_id) THEN
      RAISE_APPLICATION_ERROR(-20104, 'ERROR_PARAM: La institución ' || p_institucion_id || ' no existe');
    END IF;
    
    -- Validación de existencia de carrera si se especifica
    IF p_carrera_id IS NOT NULL AND NOT carrera_exists(p_carrera_id) THEN
      RAISE_APPLICATION_ERROR(-20105, 'ERROR_PARAM: La carrera ' || p_carrera_id || ' no existe');
    END IF;
    
    -- Mensaje informativo sobre filtros aplicados
    -- If error logging fails, continue anyway
    IF log_error(C_LOG_INFO, 'build_plan_recursos', 
                 'Generando plan de recursos - Semestres: ' || p_next_n || 
                 ', Institución: ' || NVL(TO_CHAR(p_institucion_id), 'TODAS') ||
                 ', Carrera: ' || NVL(TO_CHAR(p_carrera_id), 'TODAS') ||
                 ', Región: ' || NVL(TO_CHAR(p_region_id), 'TODAS')) = 0 THEN
      NULL; 
    END IF;
    
    -- Abrir cursor complejo con parámetros
    OPEN c_prog(p_institucion_id, p_carrera_id, p_region_id);
    LOOP
      FETCH c_prog INTO v_prog.institucion_id, v_prog.institucion_nombre, v_prog.carrera_id, v_prog.carrera_nombre;
      EXIT WHEN c_prog%NOTFOUND;
      
      v_contador := v_contador + 1;
      v_current_inst_id := v_prog.institucion_id;
      v_current_carrera_id := v_prog.carrera_id;
      
      -- Obtener proyección para esta combinación
      BEGIN
        v_proyecto := proyeccion_estudiantes_para_prox_semestres(
          v_prog.institucion_id, 
          v_prog.carrera_id, 
          p_next_n
        );

        -- If error logging fails, continue anyway
        IF v_proyecto IS NULL OR v_proyecto.COUNT = 0 THEN
          IF log_error(C_LOG_WARNING, 'build_plan_recursos', 
                       'Proyección vacía para Institución: ' || v_prog.institucion_id || 
                       ', Carrera: ' || v_prog.carrera_id) = 0 THEN
            NULL; 
          END IF;
          CONTINUE;
        END IF;
        
    EXCEPTION
        -- If error logging fails, continue anyway
        WHEN NO_DATA_FOUND THEN
            IF log_error('WARNING', 'build_plan_recursos', 
                        'Sin datos históricos para Inst:' || v_prog.institucion_id || ', Carrera:' || v_prog.carrera_id || '. Saltando...') = 0 THEN
            NULL; 
            END IF;
            CONTINUE;
        -- If error logging fails, continue anyway
        WHEN VALUE_ERROR THEN
            IF log_error('ERROR', 'build_plan_recursos', 
                        'Valores inválidos en proyección para Inst:' || v_prog.institucion_id || ', Carrera:' || v_prog.carrera_id || '. Saltando...') = 0 THEN
            NULL; 
            END IF;
            CONTINUE;
        -- If error logging fails, continue anyway
        WHEN OTHERS THEN
            IF log_error('ERROR', 'build_plan_recursos', 
                        'Fallo en proyección para Inst:' || v_prog.institucion_id || ', Carrera:' || v_prog.carrera_id || ' - ' || SQLERRM) = 0 THEN
            NULL;
            END IF;
            CONTINUE;
    END;

      -- Generar registros para cada semestre proyectado
      FOR i IN 1..LEAST(p_next_n, NVL(v_proyecto.COUNT, 0)) LOOP
        BEGIN
          -- Calcular etiqueta del semestre
          v_sem_label := calcular_semestre_label(v_anio_actual, v_sem_actual, i);
          
          -- Calcular recursos necesarios
          v_profs := profs_req(v_proyecto(i));
          v_salas := salas_req(v_proyecto(i));
          
          -- Insertar registro en la tabla de planes
        BEGIN
          INSERT INTO PLANES_RECURSOS (INSTITUCION_ID, INSTITUCION_NOMBRE, CARRERA_ID, CARRERA_NOMBRE,
                                    SEMESTRE_LABEL, ESTUDIANTES_PROYECTADOS, PROFERORES_REQUERIDOS, SALAS_REQUERIDAS)
          VALUES (v_prog.institucion_id, v_prog.institucion_nombre, v_prog.carrera_id, v_prog.carrera_nombre,
                  v_sem_label, v_proyecto(i), v_profs, v_salas);
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            IF log_error('WARNING', 'build_plan_recursos', 
                         'Registro duplicado para Inst:' || v_prog.institucion_id || ', Carrera:' || v_prog.carrera_id || ', Semestre:' || v_sem_label || '. Saltando...') = 0 THEN
              NULL; 
            END IF;
          WHEN OTHERS THEN
            IF log_error('ERROR', 'build_plan_recursos', 
                         'Fallo insertando registro para semestre ' || i || ' - ' || SQLERRM) = 0 THEN
              NULL; 
            END IF;
            RAISE; 
        END;
          
      EXCEPTION
        WHEN SUBSCRIPT_BEYOND_COUNT THEN
          IF log_error('ERROR', 'build_plan_recursos', 
                       'Índice fuera de rango en proyección (semestre ' || i || '). Elementos disponibles: ' || NVL(v_proyecto.COUNT, 0)) = 0 THEN
            NULL;
          END IF;
          EXIT; -- Salir del loop de semestres
        WHEN SUBSCRIPT_OUTSIDE_LIMIT THEN
          IF log_error('ERROR', 'build_plan_recursos', 
                       'Límite de VARRAY excedido en semestre ' || i) = 0 THEN
            NULL;
          END IF;
          EXIT;
        WHEN OTHERS THEN
          IF log_error('ERROR', 'build_plan_recursos', 
                       'Fallo procesando semestre ' || i || ' - ' || SQLERRM) = 0 THEN
            NULL;
          END IF;
          -- Continuar con el siguiente semestre
       END;
      END LOOP;

    END LOOP;
    CLOSE c_prog;
    
    IF log_error(C_LOG_INFO, 'build_plan_recursos', 
                 'Proceso completado - Combinaciones procesadas: ' || v_contador || 
                 ', Registros totales generados: ' || (v_contador * p_next_n)) = 0 THEN
      NULL; -- Error logging failed, but continue
    END IF;
    
    COMMIT;
    
    EXCEPTION
    -- Errores de validación de parámetros
    WHEN e_parametros_invalidos THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        IF log_error('CRITICAL', 'build_plan_recursos', 
                    'Error de parámetros - Código: ' || v_error_code || ', Mensaje: ' || v_error_msg ||
                    ', p_next_n: ' || NVL(TO_CHAR(p_next_n), 'NULL') ||
                    ', p_institucion_id: ' || NVL(TO_CHAR(p_institucion_id), 'NULL') ||
                    ', p_carrera_id: ' || NVL(TO_CHAR(p_carrera_id), 'NULL') ||
                    ', p_region_id: ' || NVL(TO_CHAR(p_region_id), 'NULL')) = 0 THEN
        NULL; -- Error logging failed, but continue
        END IF;
        IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
        ROLLBACK;
        RAISE;

    -- Errores de tabla no encontrada
    WHEN e_tabla_no_existe THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        IF log_error('CRITICAL', 'build_plan_recursos', 
                    'Error de tabla faltante - Código: ' || v_error_code || ', Mensaje: ' || v_error_msg ||
                    '. Verifique que existan las tablas: MATRICULAS, INSTITUCIONES, CARRERAS, PLANES_RECURSOS, INSTITUCION_CAPACIDAD') = 0 THEN
        NULL; -- Error logging failed, but continue
        END IF;
        IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
        ROLLBACK;
        RAISE;

    -- Errores de cursor
    WHEN CURSOR_ALREADY_OPEN THEN
        IF log_error('ERROR', 'build_plan_recursos', 
                    'Error de cursor: Ya estaba abierto. Cerrando y reintentando...') = 0 THEN
        NULL; -- Error logging failed, but continue
        END IF;
        IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20300, 'Error de cursor: Ya estaba abierto');

    WHEN INVALID_CURSOR THEN
        IF log_error('ERROR', 'build_plan_recursos', 
                    'Cursor en estado inválido - Combinaciones procesadas: ' || NVL(v_contador, 0)) = 0 THEN
        NULL; -- Error logging failed, but continue
        END IF;
        IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20301, 'Error de cursor: Estado inválido');

    -- Errores de memoria y recursos
    WHEN STORAGE_ERROR THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        IF log_error('CRITICAL', 'build_plan_recursos', 
                    'Error de memoria - Código: ' || v_error_code || ', Mensaje: ' || v_error_msg ||
                    ', Combinaciones procesadas: ' || NVL(v_contador, 0) ||
                    ', Última institución: ' || NVL(v_current_inst_id, 0) ||
                    ', Última carrera: ' || NVL(v_current_carrera_id, 0)) = 0 THEN
        NULL; -- Error logging failed, but continue
        END IF;
        IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20302, 'Error de memoria: Insuficiente espacio');

    WHEN PROGRAM_ERROR THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        IF log_error('CRITICAL', 'build_plan_recursos', 
                    'Error de programa interno - Código: ' || v_error_code || ', Mensaje: ' || v_error_msg) = 0 THEN
        NULL; -- Error logging failed, but continue
        END IF;
        IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20303, 'Error de programa interno');

    -- Errores de datos
    WHEN VALUE_ERROR THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        IF log_error('ERROR', 'build_plan_recursos', 
                    'Error de valor - Código: ' || v_error_code || ', Mensaje: ' || v_error_msg ||
                    ', Institución: ' || NVL(v_current_inst_id, 0) ||
                    ', Carrera: ' || NVL(v_current_carrera_id, 0) ||
                    ', Registro: ' || NVL(v_contador, 0)) = 0 THEN
        NULL; -- Error logging failed, but continue
        END IF;
        IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20304, 'Error de datos: Valores inválidos');

    WHEN NO_DATA_FOUND THEN
        IF log_error('WARNING', 'build_plan_recursos', 
                    'Sin datos para procesar - Institución: ' || NVL(TO_CHAR(p_institucion_id), 'TODAS') ||
                    ', Carrera: ' || NVL(TO_CHAR(p_carrera_id), 'TODAS') ||
                    ', Región: ' || NVL(TO_CHAR(p_region_id), 'TODAS')) = 0 THEN
        NULL; -- Error logging failed, but continue
        END IF;
        IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20305, 'Sin datos: No hay registros que procesar');

    -- Errores de transacción
    WHEN DUP_VAL_ON_INDEX THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        IF log_error('ERROR', 'build_plan_recursos', 
                    'Error de clave duplicada - Código: ' || v_error_code || ', Mensaje: ' || v_error_msg ||
                    '. Posible ejecución duplicada. Considere limpiar PLANES_RECURSOS antes de ejecutar') = 0 THEN
        NULL; -- Error logging failed, but continue
        END IF;
        IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20306, 'Error de duplicados: Ya existen registros');

    -- Errores generales del sistema
    WHEN OTHERS THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        
        IF log_error('CRITICAL', 'build_plan_recursos', 
                    'Error inesperado - Código: ' || v_error_code || ', Mensaje: ' || v_error_msg ||
                    ', Timestamp: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                    ', Usuario: ' || USER || ', Sesión: ' || SYS_CONTEXT('USERENV', 'SESSIONID') ||
                    ', p_next_n: ' || NVL(TO_CHAR(p_next_n), 'NULL') ||
                    ', p_institucion_id: ' || NVL(TO_CHAR(p_institucion_id), 'NULL') ||
                    ', p_carrera_id: ' || NVL(TO_CHAR(p_carrera_id), 'NULL') ||
                    ', p_region_id: ' || NVL(TO_CHAR(p_region_id), 'NULL') ||
                    ', Combinaciones procesadas: ' || NVL(v_contador, 0) ||
                    ', Última institución: ' || NVL(v_current_inst_id, 0) ||
                    ', Última carrera: ' || NVL(v_current_carrera_id, 0) ||
                    ', Estado cursor: ' || CASE WHEN c_prog%ISOPEN THEN 'ABIERTO' ELSE 'CERRADO' END) = 0 THEN
        NULL; -- Error logging failed, but continue
        END IF;
        
        -- Limpieza de recursos
        BEGIN
        IF c_prog%ISOPEN THEN 
            CLOSE c_prog; 
            DBMS_OUTPUT.PUT_LINE('INFO: Cursor cerrado correctamente');
        END IF;
        EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('WARNING: Error cerrando cursor: ' || SQLERRM);
        END;
        
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('INFO: Transacción revertida');
        
        -- Re-lanzar con código específico
        RAISE_APPLICATION_ERROR(-20999, 
        'FATAL: build_plan_recursos falló (Código:' || v_error_code || ') - ' || 
        SUBSTR(v_error_msg, 1, 1000));
        
    END build_plan_recursos;
  
  -- Procedimiento para limpiar datos antiguos
  PROCEDURE limpiar_planes_antiguos(p_dias_antiguedad NUMBER DEFAULT 30) IS
    v_fecha_limite DATE;
    v_filas_eliminadas NUMBER;
  BEGIN
    v_fecha_limite := SYSDATE - NVL(p_dias_antiguedad, 30);
    
    DELETE FROM PLANES_RECURSOS 
    WHERE CREATED_AT < v_fecha_limite;
    
    v_filas_eliminadas := SQL%ROWCOUNT;
    
    IF log_error(C_LOG_INFO, 'limpiar_planes_antiguos', 
                 'Eliminadas ' || v_filas_eliminadas || ' filas anteriores a ' || 
                 TO_CHAR(v_fecha_limite, 'DD/MM/YYYY')) = 0 THEN
      NULL; -- Error logging failed, but continue
    END IF;
    
    COMMIT;
  END limpiar_planes_antiguos;
  
  -- Procedimiento para generar reporte de capacidad
  PROCEDURE generar_reporte_capacidad(
    p_institucion_id NUMBER DEFAULT NULL,
    p_mostrar_detalles BOOLEAN DEFAULT TRUE
  ) IS
    v_capacidad_aula NUMBER;
    v_salas_disp NUMBER;
    v_capacidad_ok BOOLEAN;
  BEGIN
    IF p_institucion_id IS NOT NULL THEN
      -- Reporte para una institución específica
      v_capacidad_ok := get_institucion_capacity(p_institucion_id, v_capacidad_aula, v_salas_disp);
      
      DBMS_OUTPUT.PUT_LINE('=== REPORTE DE CAPACIDAD INSTITUCIÓN ' || p_institucion_id || ' ===');
      DBMS_OUTPUT.PUT_LINE('Capacidad por aula: ' || v_capacidad_aula);
      DBMS_OUTPUT.PUT_LINE('Salas disponibles: ' || v_salas_disp);
      DBMS_OUTPUT.PUT_LINE('Capacidad total: ' || (v_capacidad_aula * v_salas_disp));
      
    ELSE
      -- Reporte general
      DBMS_OUTPUT.PUT_LINE('=== REPORTE GENERAL DE CAPACIDADES ===');
      FOR r IN (SELECT INSTITUCION_ID, INSTITUCION_NOMBRE FROM INSTITUCIONES ORDER BY INSTITUCION_NOMBRE) LOOP
        v_capacidad_ok := get_institucion_capacity(r.INSTITUCION_ID, v_capacidad_aula, v_salas_disp);
        DBMS_OUTPUT.PUT_LINE(r.INSTITUCION_NOMBRE || ': ' || (v_capacidad_aula * v_salas_disp) || ' estudiantes');
      END LOOP;
    END IF;
    
  END generar_reporte_capacidad;
  
  -- Procedimiento para inicializar configuración por defecto
  PROCEDURE inicializar_configuracion IS
  BEGIN
    g_debug_mode := FALSE;
    g_log_enabled := TRUE;
    g_package_initialized := TRUE;
    g_call_count := 0;
    g_error_count := 0;
    
    -- Limpiar caches
    g_institucion_cache.DELETE;
    g_carrera_cache.DELETE;
    
    -- Crear o verificar el tipo VARRAY dinámicamente
    BEGIN
      IF NOT verificar_varray_existente() THEN
        crear_varray_dinamico();
      ELSE
        IF log_error(C_LOG_INFO, 'inicializar_configuracion', 
                     'Tipo proy_sem_t ya existe y es válido') = 0 THEN
          NULL; -- Error logging failed, but continue
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        -- Si falla la creación del VARRAY, log el error pero continúa
        IF log_error(C_LOG_WARNING, 'inicializar_configuracion', 
                     'Error inicializando VARRAY: ' || SQLERRM || 
                     '. El package funcionará pero puede requerir creación manual del tipo.') = 0 THEN
          NULL; -- Error logging failed, but continue
        END IF;
    END;
    
    IF log_error(C_LOG_INFO, 'inicializar_configuracion', 
                 'Package PKG_PROYECCION_RECURSOS inicializado correctamente') = 0 THEN
      NULL; -- Error logging failed, but continue
    END IF;
  END inicializar_configuracion;
  
  -- ====================================================================
  -- FUNCIONES PIPELINED
  -- ====================================================================
  
  -- Función pipelined para obtener proyecciones como tabla
  FUNCTION get_proyecciones_tabla(
    p_institucion_id INTEGER DEFAULT NULL,
    p_carrera_id INTEGER DEFAULT NULL,
    p_next_n NUMBER DEFAULT 4
  ) RETURN t_proyecciones_tabla PIPELINED IS
    
    v_proyeccion proy_sem_t;
    v_detalle t_proyeccion_detalle;
    v_anio_actual NUMBER;
    v_sem_actual NUMBER;
    
  BEGIN
    get_current_year_semester(v_anio_actual, v_sem_actual);
    
    -- Cursor para todas las combinaciones o filtradas
    FOR r IN (
      SELECT DISTINCT m.INSTITUCION_ID, i.INSTITUCION_NOMBRE, 
             m.CARRERA_ID, c.CARRERA_NOMBRE
      FROM MATRICULAS m
      JOIN INSTITUCIONES i ON m.INSTITUCION_ID = i.INSTITUCION_ID
      JOIN CARRERAS c ON m.CARRERA_ID = c.CARRERA_ID
      WHERE (p_institucion_id IS NULL OR m.INSTITUCION_ID = p_institucion_id)
        AND (p_carrera_id IS NULL OR m.CARRERA_ID = p_carrera_id)
    ) LOOP
      
      BEGIN
        v_proyeccion := proyeccion_estudiantes_para_prox_semestres(
          r.INSTITUCION_ID, r.CARRERA_ID, p_next_n
        );
        
        FOR i IN 1..LEAST(p_next_n, NVL(v_proyeccion.COUNT, 0)) LOOP
          v_detalle.institucion_id := r.INSTITUCION_ID;
          v_detalle.institucion_nombre := r.INSTITUCION_NOMBRE;
          v_detalle.carrera_id := r.CARRERA_ID;
          v_detalle.carrera_nombre := r.CARRERA_NOMBRE;
          v_detalle.semestre_label := calcular_semestre_label(v_anio_actual, v_sem_actual, i);
          v_detalle.estudiantes_proyectados := v_proyeccion(i);
          v_detalle.profesores_requeridos := profs_req(v_proyeccion(i));
          v_detalle.salas_requeridas := salas_req(v_proyeccion(i));
          
          PIPE ROW(v_detalle);
        END LOOP;
        
      EXCEPTION
        WHEN OTHERS THEN
          -- Log error but continue with next combination
          NULL;
      END;
      
    END LOOP;
    
    RETURN;
  END get_proyecciones_tabla;
  
  -- Función para obtener estadísticas de uso del package
  FUNCTION get_package_stats RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PKG_PROYECCION_RECURSOS Stats: ' ||
           'Calls=' || g_call_count || 
           ', Errors=' || g_error_count || 
           ', Initialized=' || CASE WHEN g_package_initialized THEN 'YES' ELSE 'NO' END ||
           ', Debug=' || CASE WHEN g_debug_mode THEN 'ON' ELSE 'OFF' END;
  END get_package_stats;

  -- ====================================================================
  -- FUNCIONES PARA MANEJO DE VARRAY DINÁMICO
  -- ====================================================================
  
  -- Obtener el tamaño máximo del VARRAY basado en duración de carreras
  FUNCTION get_max_duracion_carreras RETURN NUMBER IS
    v_max_duracion NUMBER := 50; -- Valor por defecto
  BEGIN
    BEGIN
      SELECT MAX(duracion_total) INTO v_max_duracion FROM carreras;
      
      -- Validar que el valor sea razonable
      IF v_max_duracion IS NULL OR v_max_duracion <= 0 THEN
        v_max_duracion := 50;
        IF log_error(C_LOG_WARNING, 'get_max_duracion_carreras', 
                     'Duración máxima NULL o inválida. Usando valor por defecto: ' || v_max_duracion) = 0 THEN
          NULL; -- Error en logging, continúa
        END IF;
      ELSIF v_max_duracion > 200 THEN
        -- Limitar a un valor razonable
        v_max_duracion := 200;
        IF log_error(C_LOG_WARNING, 'get_max_duracion_carreras', 
                     'Duración máxima muy alta. Limitando a: ' || v_max_duracion) = 0 THEN
          NULL; -- Error en logging, continúa
        END IF;
      END IF;
      
      IF log_error(C_LOG_INFO, 'get_max_duracion_carreras', 
                   'Duración máxima obtenida de tabla carreras: ' || v_max_duracion) = 0 THEN
        NULL; -- Error en logging, continúa
      END IF;
      
    EXCEPTION
      WHEN OTHERS THEN
        v_max_duracion := 50;
        IF log_error(C_LOG_WARNING, 'get_max_duracion_carreras', 
                     'Error accediendo tabla carreras: ' || SQLERRM || 
                     '. Usando valor por defecto: ' || v_max_duracion) = 0 THEN
          NULL; -- Error en logging, continúa
        END IF;
    END;
    
    RETURN v_max_duracion;
  END get_max_duracion_carreras;
  
  -- Verificar si el tipo proy_sem_t existe y es del tamaño adecuado
  FUNCTION verificar_varray_existente RETURN BOOLEAN IS
    v_count NUMBER := 0;
    v_type_info VARCHAR2(4000);
    v_max_duracion NUMBER;
  BEGIN
    -- Verificar si existe el tipo
    SELECT COUNT(*) INTO v_count 
    FROM USER_TYPES 
    WHERE TYPE_NAME = 'PROY_SEM_T';
    
    IF v_count = 0 THEN
      IF log_error(C_LOG_INFO, 'verificar_varray_existente', 
                   'Tipo proy_sem_t no existe. Necesita ser creado.') = 0 THEN
        NULL; -- Error en logging, continúa
      END IF;
      RETURN FALSE;
    END IF;
    
    -- Obtener duración máxima actual
    v_max_duracion := get_max_duracion_carreras();
    
    -- Obtener información del tipo existente
    BEGIN
      SELECT TYPE_NAME || ' existe con límite definido' INTO v_type_info
      FROM USER_TYPES 
      WHERE TYPE_NAME = 'PROY_SEM_T';
      
      IF log_error(C_LOG_INFO, 'verificar_varray_existente', 
                   'Tipo proy_sem_t existe. Duración requerida: ' || v_max_duracion) = 0 THEN
        NULL; -- Error en logging, continúa
      END IF;
      
      -- Siempre retornar TRUE si existe, ya que Oracle maneja el redimensionamiento
      RETURN TRUE;
      
    EXCEPTION
      WHEN OTHERS THEN
        IF log_error(C_LOG_WARNING, 'verificar_varray_existente', 
                     'Error verificando tipo existente: ' || SQLERRM) = 0 THEN
          NULL; -- Error en logging, continúa
        END IF;
        RETURN FALSE;
    END;
    
  END verificar_varray_existente;
  
  -- Crear o recrear el tipo VARRAY proy_sem_t dinámicamente
  PROCEDURE crear_varray_dinamico IS
    v_max_duracion NUMBER;
    v_sql_stmt VARCHAR2(4000);
    v_exists BOOLEAN;
  BEGIN
    -- Obtener duración máxima
    v_max_duracion := get_max_duracion_carreras();
    
    -- Verificar si ya existe
    v_exists := verificar_varray_existente();
    
    -- Construir statement DDL
    v_sql_stmt := 'CREATE OR REPLACE TYPE proy_sem_t AS VARRAY(' || v_max_duracion || ') OF NUMBER';
    
    BEGIN
      -- Ejecutar DDL
      EXECUTE IMMEDIATE v_sql_stmt;
      
      IF v_exists THEN
        IF log_error(C_LOG_INFO, 'crear_varray_dinamico', 
                     'Tipo proy_sem_t recreado exitosamente con tamaño: ' || v_max_duracion) = 0 THEN
          NULL; -- Error en logging, continúa
        END IF;
      ELSE
        IF log_error(C_LOG_INFO, 'crear_varray_dinamico', 
                     'Tipo proy_sem_t creado exitosamente con tamaño: ' || v_max_duracion) = 0 THEN
          NULL; -- Error en logging, continúa
        END IF;
      END IF;
      
    EXCEPTION
      WHEN OTHERS THEN
        g_error_count := g_error_count + 1;
        IF log_error(C_LOG_ERROR, 'crear_varray_dinamico', 
                     'Error creando tipo VARRAY: ' || SQLERRM || 
                     '. SQL: ' || v_sql_stmt) = 0 THEN
          NULL; -- Error en logging, continúa
        END IF;
        RAISE_APPLICATION_ERROR(-20030, 'Error creando tipo VARRAY proy_sem_t: ' || SQLERRM);
    END;
    
  END crear_varray_dinamico;

  -- ====================================================================
  -- PROCEDIMIENTO PARA VERIFICACIÓN DE CAPACIDAD (TRIGGER)
  -- ====================================================================
  
  -- Procedimiento para verificar capacidad antes de insertar matrícula
  PROCEDURE verificar_capacidad_matricula(
    p_institucion_id INTEGER,
    p_carrera_id INTEGER,
    p_anio_ingreso INTEGER,
    p_semestre_ingreso INTEGER
  ) IS
    -- Variables principales
    v_total_estudiantes NUMBER;
    v_salas_requeridas NUMBER;
    v_salas_disp NUMBER;
    v_cap_por_aula NUMBER;
    
    -- Variables para validaciones adicionales
    v_capacidad_ok BOOLEAN;
    v_error_context VARCHAR2(1000);
    v_usuario VARCHAR2(100) := USER;
    
  BEGIN
    -- Incrementar contador de llamadas
    g_call_count := g_call_count + 1;
    
    -- =====================================
    -- VALIDACIONES INICIALES
    -- =====================================
    
    -- Validación de datos básicos
    IF p_institucion_id IS NULL THEN
      RAISE_APPLICATION_ERROR(-20021, 'TRIGGER_ERROR: INSTITUCION_ID no puede ser NULL');
    END IF;
    
    IF p_carrera_id IS NULL THEN
      RAISE_APPLICATION_ERROR(-20021, 'TRIGGER_ERROR: CARRERA_ID no puede ser NULL');
    END IF;
    
    IF p_anio_ingreso IS NULL OR p_anio_ingreso < 1900 OR p_anio_ingreso > 2100 THEN
      RAISE_APPLICATION_ERROR(-20021, 'TRIGGER_ERROR: ANIO_INGRESO inválido (' || 
                             NVL(TO_CHAR(p_anio_ingreso), 'NULL') || ')');
    END IF;
    
    IF p_semestre_ingreso IS NULL OR p_semestre_ingreso NOT IN (1,2) THEN
      RAISE_APPLICATION_ERROR(-20021, 'TRIGGER_ERROR: SEMESTRE_INGRESO debe ser 1 o 2 (' || 
                             NVL(TO_CHAR(p_semestre_ingreso), 'NULL') || ')');
    END IF;

    -- Verificar existencia de institución usando función del package
    IF NOT institucion_exists(p_institucion_id) THEN
      RAISE_APPLICATION_ERROR(-20022, 'TRIGGER_ERROR: Institución ' || p_institucion_id || ' no existe');
    END IF;

    -- Verificar existencia de carrera usando función del package
    IF NOT carrera_exists(p_carrera_id) THEN
      RAISE_APPLICATION_ERROR(-20023, 'TRIGGER_ERROR: Carrera ' || p_carrera_id || ' no existe');
    END IF;

    -- =====================================
    -- CÁLCULO DE ESTUDIANTES ACTUALES
    -- =====================================
    
    BEGIN
      SELECT COUNT(*) INTO v_total_estudiantes
      FROM MATRICULAS m
      WHERE m.INSTITUCION_ID = p_institucion_id
        AND m.CARRERA_ID = p_carrera_id
        AND m.ANIO_INGRESO = p_anio_ingreso
        AND m.SEMESTRE_INGRESO = p_semestre_ingreso;
        
      v_total_estudiantes := v_total_estudiantes + 1; -- Incluir la nueva matrícula
      
    EXCEPTION
      WHEN OTHERS THEN
        g_error_count := g_error_count + 1;
        RAISE_APPLICATION_ERROR(-20025, 'TRIGGER_ERROR: Error contando estudiantes existentes - ' || SQLERRM);
    END;

    -- =====================================
    -- OBTENCIÓN DE CAPACIDAD INSTITUCIONAL
    -- =====================================
    
    -- Usar función del package para obtener capacidad
    v_capacidad_ok := get_institucion_capacity(p_institucion_id, v_cap_por_aula, v_salas_disp);
    
    IF NOT v_capacidad_ok THEN
      IF log_error(C_LOG_WARNING, 'verificar_capacidad_matricula', 
                   'Error obteniendo capacidad para institución ' || p_institucion_id || 
                   '. Usando valores por defecto.') = 0 THEN
        NULL; -- Error en logging, continúa
      END IF;
    END IF;

    -- =====================================
    -- CÁLCULO DE SALAS REQUERIDAS
    -- =====================================
    
    BEGIN
      -- Usar función del package para calcular salas necesarias
      v_salas_requeridas := salas_req(v_total_estudiantes, v_cap_por_aula);
      
      -- Validar resultado
      IF v_salas_requeridas IS NULL OR v_salas_requeridas < 0 THEN
        RAISE_APPLICATION_ERROR(-20024, 'TRIGGER_ERROR: Error en cálculo de salas requeridas');
      END IF;
      
    EXCEPTION
      WHEN OTHERS THEN
        g_error_count := g_error_count + 1;
        IF log_error(C_LOG_WARNING, 'verificar_capacidad_matricula', 
                     'Error en función salas_req - ' || SQLERRM || '. Calculando manualmente.') = 0 THEN
          NULL; -- Error en logging, continúa
        END IF;
        v_salas_requeridas := CEIL(v_total_estudiantes / v_cap_por_aula);
    END;

    -- =====================================
    -- VERIFICACIÓN DE CAPACIDAD
    -- =====================================
    
    -- Registro informativo usando función del package
    IF log_error(C_LOG_INFO, 'verificar_capacidad_matricula', 
                 'VERIFICACIÓN CAPACIDAD - Institución: ' || p_institucion_id ||
                 ', Carrera: ' || p_carrera_id ||
                 ', Período: ' || p_anio_ingreso || '-' || p_semestre_ingreso ||
                 ', Estudiantes: ' || v_total_estudiantes ||
                 ', Cap/aula: ' || v_cap_por_aula ||
                 ', Salas req: ' || v_salas_requeridas ||
                 ', Salas disp: ' || v_salas_disp ||
                 ', Usuario: ' || v_usuario) = 0 THEN
      NULL; -- Error en logging, continúa
    END IF;
    
    -- Verificación principal de capacidad
    IF v_salas_disp = 0 THEN
      IF log_error(C_LOG_WARNING, 'verificar_capacidad_matricula', 
                   'Institución sin aulas registradas. Permitiendo inserción con advertencia.') = 0 THEN
        NULL; -- Error en logging, continúa
      END IF;
    ELSIF v_salas_requeridas > v_salas_disp THEN
      -- Capacidad excedida - bloquear inserción
      v_error_context := 'Institución: ' || p_institucion_id || 
                        ', Carrera: ' || p_carrera_id ||
                        ', Período: ' || p_anio_ingreso || '-' || p_semestre_ingreso;
      
      -- Log del error antes de lanzar excepción
      IF log_error(C_LOG_ERROR, 'verificar_capacidad_matricula', 
                   'CAPACIDAD EXCEDIDA - Matrícula rechazada' ||
                   ', Usuario: ' || v_usuario ||
                   ', Estudiantes totales: ' || v_total_estudiantes ||
                   ', Salas requeridas: ' || v_salas_requeridas ||
                   ', Salas disponibles: ' || v_salas_disp ||
                   ', Contexto: ' || v_error_context) = 0 THEN
        NULL; -- Error en logging, continúa
      END IF;
      
      g_error_count := g_error_count + 1;
      RAISE_APPLICATION_ERROR(-20020, 
        'CAPACIDAD_EXCEDIDA: Aulas insuficientes.' || CHR(10) ||
        'Requeridas: ' || v_salas_requeridas || ', Disponibles: ' || v_salas_disp || CHR(10) ||
        'Estudiantes: ' || v_total_estudiantes || ', Cap/aula: ' || v_cap_por_aula || CHR(10) ||
        'Contexto: ' || v_error_context);
    ELSE
      IF log_error(C_LOG_INFO, 'verificar_capacidad_matricula', 
                   'SUCCESS: Capacidad suficiente. Inserción permitida.' ||
                   ' Salas usadas: ' || v_salas_requeridas || '/' || v_salas_disp) = 0 THEN
        NULL; -- Error en logging, continúa
      END IF;
    END IF;

    EXCEPTION
    -- =====================================
    -- MANEJO ESPECÍFICO DE EXCEPCIONES
    -- =====================================
    
    -- Errores de validación de datos
    WHEN e_datos_invalidos THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        IF log_error('ERROR', 'trg_matriculas_check_capacidad', 
                    'ERROR DE DATOS INVÁLIDOS - Código: ' || v_error_code || 
                    ', Mensaje: ' || v_error_msg || 
                    ', Usuario: ' || v_usuario ||
                    ', INSTITUCION_ID: ' || NVL(TO_CHAR(:NEW.INSTITUCION_ID), 'NULL') ||
                    ', CARRERA_ID: ' || NVL(TO_CHAR(:NEW.CARRERA_ID), 'NULL') ||
                    ', ANIO_INGRESO: ' || NVL(TO_CHAR(:NEW.ANIO_INGRESO), 'NULL') ||
                    ', SEMESTRE_INGRESO: ' || NVL(TO_CHAR(:NEW.SEMESTRE_INGRESO), 'NULL')) = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        RAISE;

    -- Capacidad excedida
    WHEN e_capacidad_excedida THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        IF log_error('ERROR', 'trg_matriculas_check_capacidad', 
                    'CAPACIDAD EXCEDIDA - Matrícula rechazada por falta de capacidad' ||
                    ', Usuario: ' || v_usuario ||
                    ', Institución: ' || :NEW.INSTITUCION_ID ||
                    ', Carrera: ' || :NEW.CARRERA_ID ||
                    ', Período: ' || :NEW.ANIO_INGRESO || '-' || :NEW.SEMESTRE_INGRESO ||
                    ', Estudiantes totales: ' || NVL(v_total_estudiantes, 0) ||
                    ', Salas requeridas: ' || NVL(v_salas_requeridas, 0) ||
                    ', Salas disponibles: ' || NVL(v_salas_disp, 0) ||
                    '. Recomendación: Aumentar TOTAL_AULAS en INSTITUCION_CAPACIDAD') = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        RAISE;

    -- Institución inexistente
    WHEN e_institucion_inexistente THEN
        IF log_error('ERROR', 'trg_matriculas_check_capacidad', 
                    'INSTITUCIÓN INEXISTENTE - Usuario: ' || v_usuario ||
                    ', INSTITUCION_ID no válido: ' || :NEW.INSTITUCION_ID ||
                    '. Verificar tabla INSTITUCIONES') = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        RAISE_APPLICATION_ERROR(-20022, 'TRIGGER_ERROR: Institución ' || :NEW.INSTITUCION_ID || ' no existe');

    -- Carrera inexistente
    WHEN e_carrera_inexistente THEN
        IF log_error('ERROR', 'trg_matriculas_check_capacidad', 
                    'CARRERA INEXISTENTE - Usuario: ' || v_usuario ||
                    ', CARRERA_ID no válido: ' || :NEW.CARRERA_ID ||
                    '. Verificar tabla CARRERAS') = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        RAISE_APPLICATION_ERROR(-20023, 'TRIGGER_ERROR: Carrera ' || :NEW.CARRERA_ID || ' no existe');

    -- Función no disponible
    WHEN e_funcion_no_disponible THEN
        IF log_error('ERROR', 'trg_matriculas_check_capacidad', 
                    'FUNCIÓN NO DISPONIBLE - Error en función classrooms_needed' ||
                    ', Parámetros: estudiantes=' || NVL(v_total_estudiantes,0) || 
                    ', capacidad=' || NVL(v_cap_por_aula,0)) = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        RAISE_APPLICATION_ERROR(-20024, 'TRIGGER_ERROR: Función classrooms_needed no disponible');

    -- Datos inconsistentes
    WHEN e_datos_inconsistentes THEN
        IF log_error('ERROR', 'trg_matriculas_check_capacidad', 
                    'DATOS INCONSISTENTES - Datos inconsistentes detectados en capacidad institucional' ||
                    ', Institución: ' || :NEW.INSTITUCION_ID ||
                    '. Verificar tabla INSTITUCION_CAPACIDAD') = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        RAISE;

    -- Sin datos encontrados (específico para capacidad)
    WHEN NO_DATA_FOUND THEN
        IF log_error('WARNING', 'trg_matriculas_check_capacidad', 
                    'SIN DATOS DE CAPACIDAD - No existe registro en INSTITUCION_CAPACIDAD para INSTITUCION_ID: ' || :NEW.INSTITUCION_ID ||
                    '. ACCIÓN: Matrícula permitida con valores por defecto' ||
                    '. RECOMENDACIÓN: Crear registro de capacidad para esta institución') = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        -- No bloquear la inserción, solo advertir

    -- Demasiadas filas
    WHEN TOO_MANY_ROWS THEN
        IF log_error('ERROR', 'trg_matriculas_check_capacidad', 
                    'CONFIGURACIÓN DUPLICADA - Múltiples registros de capacidad para INSTITUCION_ID: ' || :NEW.INSTITUCION_ID ||
                    '. ACCIÓN: Matrícula bloqueada' ||
                    '. CORRECCIÓN: Eliminar registros duplicados en INSTITUCION_CAPACIDAD') = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        RAISE_APPLICATION_ERROR(-20025, 'TRIGGER_ERROR: Configuración de capacidad duplicada para institución ' || 
                            :NEW.INSTITUCION_ID);

    -- Errores de valor
    WHEN VALUE_ERROR THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        IF log_error('ERROR', 'trg_matriculas_check_capacidad', 
                    'ERROR DE VALOR - Código: ' || v_error_code || 
                    ', Mensaje: ' || v_error_msg ||
                    ', Usuario: ' || v_usuario ||
                    ', Error de conversión o valor inválido detectado' ||
                    ', v_total_estudiantes: ' || NVL(TO_CHAR(v_total_estudiantes), 'NULL') ||
                    ', v_cap_por_aula: ' || NVL(TO_CHAR(v_cap_por_aula), 'NULL') ||
                    ', v_salas_requeridas: ' || NVL(TO_CHAR(v_salas_requeridas), 'NULL') ||
                    ', v_salas_disp: ' || NVL(TO_CHAR(v_salas_disp), 'NULL')) = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        RAISE_APPLICATION_ERROR(-20026, 'TRIGGER_ERROR: Error de valor en cálculos de capacidad');

    -- Error de acceso (permisos, objetos bloqueados, etc.)
    WHEN ACCESS_INTO_NULL THEN
        IF log_error('ERROR', 'trg_matriculas_check_capacidad', 
                    'ERROR DE ACCESO - Intento de acceso a variable no inicializada') = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        RAISE_APPLICATION_ERROR(-20027, 'TRIGGER_ERROR: Variable no inicializada');

    -- Errores generales del sistema
    WHEN OTHERS THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        
        IF log_error('CRITICAL', 'trg_matriculas_check_capacidad', 
                    'ERROR INESPERADO EN TRIGGER - USUARIO: ' || v_usuario ||
                    ', CÓDIGO: ' || v_error_code ||
                    ', MENSAJE: ' || v_error_msg ||
                    ', CONTEXTO: INSTITUCION_ID=' || NVL(TO_CHAR(:NEW.INSTITUCION_ID), 'NULL') ||
                    ', CARRERA_ID=' || NVL(TO_CHAR(:NEW.CARRERA_ID), 'NULL') ||
                    ', ANIO_INGRESO=' || NVL(TO_CHAR(:NEW.ANIO_INGRESO), 'NULL') ||
                    ', SEMESTRE_INGRESO=' || NVL(TO_CHAR(:NEW.SEMESTRE_INGRESO), 'NULL') ||
                    ', PERSONA_ID=' || NVL(TO_CHAR(:NEW.PERSONA_ID), 'NULL') ||
                    ', VARIABLES: v_total_estudiantes=' || NVL(TO_CHAR(v_total_estudiantes), 'NULL') ||
                    ', v_cap_por_aula=' || NVL(TO_CHAR(v_cap_por_aula), 'NULL') ||
                    ', v_salas_requeridas=' || NVL(TO_CHAR(v_salas_requeridas), 'NULL') ||
                    ', v_salas_disp=' || NVL(TO_CHAR(v_salas_disp), 'NULL') ||
                    ', v_institucion_exists=' || NVL(TO_CHAR(v_institucion_exists), 'NULL') ||
                    ', v_carrera_exists=' || NVL(TO_CHAR(v_carrera_exists), 'NULL') ||
                    ', SISTEMA: Sesión=' || SYS_CONTEXT('USERENV', 'SESSIONID') ||
                    ', Terminal=' || SYS_CONTEXT('USERENV', 'TERMINAL') ||
                    ', IP=' || SYS_CONTEXT('USERENV', 'IP_ADDRESS')) = 0 THEN
        NULL; -- Fallo en logging, continúa
        END IF;
        
        -- Re-lanzar con información contextual
        RAISE_APPLICATION_ERROR(-20999, 
        'TRIGGER_FATAL: Fallo inesperado en verificación de capacidad. ' ||
        'Código: ' || v_error_code || ', Inst: ' || NVL(TO_CHAR(:NEW.INSTITUCION_ID), 'NULL') ||
        ', Carrera: ' || NVL(TO_CHAR(:NEW.CARRERA_ID), 'NULL') ||
        '. Mensaje: ' || SUBSTR(v_error_msg, 1, 1000));
        
    END;
  END verificar_capacidad_matricula;

BEGIN
  -- Inicialización automática del package
  inicializar_configuracion;
  
END PKG_PROYECCION_RECURSOS;
/