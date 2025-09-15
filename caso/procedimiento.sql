-- tabla de planes (si aún no existe)
CREATE TABLE PLANES_RECURSOS (
  PLAN_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  INSTITUCION_ID INTEGER,
  INSTITUCION_NOMBRE VARCHAR2(200),
  CARRERA_ID INTEGER,
  CARRERA_NOMBRE VARCHAR2(200),
  SEMESTRE_LABEL VARCHAR2(10), -- ej '2022-1'
  ESTUDIANTES_PROYECTADOS NUMBER,
  PROFERORES_REQUERIDOS NUMBER,
  SALAS_REQUERIDAS NUMBER,
  CREATED_AT DATE DEFAULT SYSDATE,
  UPDATED_AT DATE DEFAULT SYSDATE
);

-- Procedimiento principal con parámetros adicionales para filtrar
CREATE OR REPLACE PROCEDURE build_plan_recursos(
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
  v_anio_actual NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'));
  v_mes_actual NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'MM'));
  v_sem_actual NUMBER := CASE WHEN v_mes_actual <= 6 THEN 1 ELSE 2 END;

  -- Variables para logging de errores
  v_error_code NUMBER;
  v_error_msg VARCHAR2(4000);
  v_error_context VARCHAR2(1000);
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
  -- Bloque de validaciones con manejo específico
  BEGIN
    -- Validación de parámetro p_next_n
    IF p_next_n IS NULL THEN
      RAISE_APPLICATION_ERROR(-20101, 'ERROR_PARAM: p_next_n no puede ser NULL');
    ELSIF p_next_n <= 0 THEN
      RAISE_APPLICATION_ERROR(-20102, 'ERROR_PARAM: p_next_n debe ser mayor que 0 (valor recibido: ' || p_next_n || ')');
    ELSIF p_next_n > 20 THEN
      RAISE_APPLICATION_ERROR(-20103, 'ERROR_PARAM: p_next_n no puede ser mayor que 20 (valor recibido: ' || p_next_n || ')');
    END IF;
    
    -- Validación de existencia de institución si se especifica
    IF p_institucion_id IS NOT NULL THEN
      DECLARE
        v_inst_count NUMBER;
      BEGIN
        SELECT COUNT(*) INTO v_inst_count 
        FROM INSTITUCIONES 
        WHERE INSTITUCION_ID = p_institucion_id;
        
        IF v_inst_count = 0 THEN
          RAISE_APPLICATION_ERROR(-20104, 'ERROR_PARAM: Institución ID ' || p_institucion_id || ' no existe');
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20104, 'ERROR_PARAM: Institución ID ' || p_institucion_id || ' no encontrada');
      END;
    END IF;
    
    -- Validación de existencia de carrera si se especifica
    IF p_carrera_id IS NOT NULL THEN
      DECLARE
        v_carrera_count NUMBER;
      BEGIN
        SELECT COUNT(*) INTO v_carrera_count 
        FROM CARRERAS 
        WHERE CARRERA_ID = p_carrera_id;
        
        IF v_carrera_count = 0 THEN
          RAISE_APPLICATION_ERROR(-20105, 'ERROR_PARAM: Carrera ID ' || p_carrera_id || ' no existe');
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20105, 'ERROR_PARAM: Carrera ID ' || p_carrera_id || ' no encontrada');
      END;
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      IF log_error('CRITICAL', 'build_plan_recursos', 
                   'Error en validaciones - Código: ' || SQLCODE || ', Mensaje: ' || SQLERRM) = 0 THEN
        NULL; -- Error logging failed, but continue
      END IF;
      RAISE;
  END;
  
  -- Mensaje informativo sobre filtros aplicados
  IF log_error('INFO', 'build_plan_recursos', 
               'Generando plan de recursos - Semestres: ' || p_next_n || 
               ', Institución: ' || NVL(TO_CHAR(p_institucion_id), 'TODAS') ||
               ', Carrera: ' || NVL(TO_CHAR(p_carrera_id), 'TODAS') ||
               ', Región: ' || NVL(TO_CHAR(p_region_id), 'TODAS')) = 0 THEN
    NULL; -- Error logging failed, but continue
  END IF;
  
  -- Abrir cursor complejo con parámetros
  OPEN c_prog(p_institucion_id, p_carrera_id, p_region_id);
  LOOP
    FETCH c_prog INTO v_prog.institucion_id, v_prog.institucion_nombre, v_prog.carrera_id, v_prog.carrera_nombre;
    EXIT WHEN c_prog%NOTFOUND;
    
    v_contador := v_contador + 1;
    v_current_inst_id := v_prog.institucion_id;
    v_current_carrera_id := v_prog.carrera_id;
    
    IF log_error('INFO', 'build_plan_recursos', 
                 'Procesando (' || v_contador || '): ' || v_prog.institucion_nombre || ' - ' || v_prog.carrera_nombre) = 0 THEN
      NULL; -- Error logging failed, but continue
    END IF;

    -- Bloque protegido para la proyección
    BEGIN
      v_proyecto := proyeccion_estudiantes_para_prox_semestres(v_prog.institucion_id, v_prog.carrera_id, p_next_n);
      
      -- Validar que la proyección no sea nula
      IF v_proyecto IS NULL THEN
        IF log_error('WARNING', 'build_plan_recursos', 
                     'Proyección nula para Inst:' || v_prog.institucion_id || ', Carrera:' || v_prog.carrera_id || '. Saltando...') = 0 THEN
          NULL; -- Error logging failed, but continue
        END IF;
        CONTINUE;
      END IF;
      
      -- Validar que tenga el número correcto de elementos
      IF v_proyecto.COUNT != p_next_n THEN
        IF log_error('WARNING', 'build_plan_recursos', 
                     'Proyección incompleta (' || v_proyecto.COUNT || '/' || p_next_n || ' semestres). Continuando con datos parciales...') = 0 THEN
          NULL; -- Error logging failed, but continue
        END IF;
      END IF;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        IF log_error('WARNING', 'build_plan_recursos', 
                     'Sin datos históricos para Inst:' || v_prog.institucion_id || ', Carrera:' || v_prog.carrera_id || '. Saltando...') = 0 THEN
          NULL; -- Error logging failed, but continue
        END IF;
        CONTINUE;
      WHEN VALUE_ERROR THEN
        IF log_error('ERROR', 'build_plan_recursos', 
                     'Valores inválidos en proyección para Inst:' || v_prog.institucion_id || ', Carrera:' || v_prog.carrera_id || '. Saltando...') = 0 THEN
          NULL; -- Error logging failed, but continue
        END IF;
        CONTINUE;
      WHEN OTHERS THEN
        IF log_error('ERROR', 'build_plan_recursos', 
                     'Fallo en proyección para Inst:' || v_prog.institucion_id || ', Carrera:' || v_prog.carrera_id || ' - ' || SQLERRM) = 0 THEN
          NULL; -- Error logging failed, but continue
        END IF;
        CONTINUE;
    END;

    FOR i IN 1..LEAST(p_next_n, NVL(v_proyecto.COUNT, 0)) LOOP
      BEGIN
        -- calcular etiqueta semestre (ejemplo simple rotativo)
        DECLARE
          sem_num NUMBER := v_sem_actual + i;
          anio_num NUMBER := v_anio_actual;
        BEGIN
          WHILE sem_num > 2 LOOP
            sem_num := sem_num - 2;
            anio_num := anio_num + 1;
          END LOOP;
          v_sem_label := TO_CHAR(anio_num) || '-' || TO_CHAR(sem_num);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            v_sem_label := 'ERROR-' || i;
            IF log_error('WARNING', 'build_plan_recursos', 
                         'Error calculando etiqueta semestre ' || i || '. Usando etiqueta por defecto: ' || v_sem_label) = 0 THEN
              NULL; -- Error logging failed, but continue
            END IF;
        END;

        -- Validar proyección antes de usar
        IF v_proyecto(i) IS NULL THEN
          IF log_error('WARNING', 'build_plan_recursos', 
                       'Proyección nula para semestre ' || i || '. Usando 0.') = 0 THEN
            NULL; -- Error logging failed, but continue
          END IF;
          v_proyecto(i) := 0;
        ELSIF v_proyecto(i) < 0 THEN
          IF log_error('WARNING', 'build_plan_recursos', 
                       'Proyección negativa (' || v_proyecto(i) || ') para semestre ' || i || '. Usando 0.') = 0 THEN
            NULL; -- Error logging failed, but continue
          END IF;
          v_proyecto(i) := 0;
        END IF;

        -- Calcular profesores con manejo de errores
        BEGIN
          v_profs := profs_necesitados(v_proyecto(i), 30);
        EXCEPTION
          WHEN OTHERS THEN
            IF log_error('ERROR', 'build_plan_recursos', 
                         'Fallo calculando profesores para semestre ' || i || '. Usando cálculo por defecto.') = 0 THEN
              NULL; -- Error logging failed, but continue
            END IF;
            v_profs := CEIL(NVL(v_proyecto(i), 0) / 30);
        END;
        
        -- Calcular salas con manejo de errores
        BEGIN
          DECLARE
            v_capacidad_aula NUMBER;
          BEGIN
            SELECT CAPACIDAD_POR_AULA INTO v_capacidad_aula 
            FROM INSTITUCION_CAPACIDAD 
            WHERE INSTITUCION_ID = v_prog.institucion_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_capacidad_aula := 40; -- valor por defecto
          END;
          
          v_salas := salas_req(v_proyecto(i), v_capacidad_aula);
        EXCEPTION
          WHEN OTHERS THEN
            IF log_error('ERROR', 'build_plan_recursos', 
                         'Fallo calculando salas para semestre ' || i || '. Usando cálculo por defecto.') = 0 THEN
              NULL; -- Error logging failed, but continue
            END IF;
            v_salas := CEIL(NVL(v_proyecto(i), 0) / 40);
        END;

        -- INSERT protegido
        BEGIN
          INSERT INTO PLANES_RECURSOS (INSTITUCION_ID, INSTITUCION_NOMBRE, CARRERA_ID, CARRERA_NOMBRE,
                                    SEMESTRE_LABEL, ESTUDIANTES_PROYECTADOS, PROFERORES_REQUERIDOS, SALAS_REQUERIDAS)
          VALUES (v_prog.institucion_id, v_prog.institucion_nombre, v_prog.carrera_id, v_prog.carrera_nombre,
                  v_sem_label, v_proyecto(i), v_profs, v_salas);
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            IF log_error('WARNING', 'build_plan_recursos', 
                         'Registro duplicado para Inst:' || v_prog.institucion_id || ', Carrera:' || v_prog.carrera_id || ', Semestre:' || v_sem_label || '. Saltando...') = 0 THEN
              NULL; -- Error logging failed, but continue
            END IF;
          WHEN OTHERS THEN
            IF log_error('ERROR', 'build_plan_recursos', 
                         'Fallo insertando registro para semestre ' || i || ' - ' || SQLERRM) = 0 THEN
              NULL; -- Error logging failed, but continue
            END IF;
            RAISE; -- Re-lanzar para que se maneje en el nivel superior
        END;
        
      EXCEPTION
        WHEN SUBSCRIPT_BEYOND_COUNT THEN
          IF log_error('ERROR', 'build_plan_recursos', 
                       'Índice fuera de rango en proyección (semestre ' || i || '). Elementos disponibles: ' || NVL(v_proyecto.COUNT, 0)) = 0 THEN
            NULL; -- Error logging failed, but continue
          END IF;
          EXIT; -- Salir del loop de semestres
        WHEN SUBSCRIPT_OUTSIDE_LIMIT THEN
          IF log_error('ERROR', 'build_plan_recursos', 
                       'Límite de VARRAY excedido en semestre ' || i) = 0 THEN
            NULL; -- Error logging failed, but continue
          END IF;
          EXIT;
        WHEN OTHERS THEN
          IF log_error('ERROR', 'build_plan_recursos', 
                       'Fallo procesando semestre ' || i || ' - ' || SQLERRM) = 0 THEN
            NULL; -- Error logging failed, but continue
          END IF;
          -- Continuar con el siguiente semestre
      END;
    END LOOP;

  END LOOP;
  CLOSE c_prog;
  
  IF log_error('INFO', 'build_plan_recursos', 
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
        IF log_error('INFO', 'build_plan_recursos', 'Cursor cerrado correctamente') = 0 THEN
          NULL; -- Error logging failed, but continue
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        IF log_error('WARNING', 'build_plan_recursos', 'Error cerrando cursor: ' || SQLERRM) = 0 THEN
          NULL; -- Error logging failed, but continue
        END IF;
    END;
    
    ROLLBACK;
    IF log_error('INFO', 'build_plan_recursos', 'Transacción revertida') = 0 THEN
      NULL; -- Error logging failed, but continue
    END IF;
    
    -- Re-lanzar con código específico
    RAISE_APPLICATION_ERROR(-20999, 
      'FATAL: build_plan_recursos falló (Código:' || v_error_code || ') - ' || 
      SUBSTR(v_error_msg, 1, 1000));
      
END build_plan_recursos;
/
