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
      DBMS_OUTPUT.PUT_LINE('=== ERROR EN VALIDACIONES ===');
      DBMS_OUTPUT.PUT_LINE('Código: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('Mensaje: ' || SQLERRM);
      RAISE;
  END;
  
  -- Mensaje informativo sobre filtros aplicados
  DBMS_OUTPUT.PUT_LINE('=== GENERANDO PLAN DE RECURSOS ===');
  DBMS_OUTPUT.PUT_LINE('Parámetros:');
  DBMS_OUTPUT.PUT_LINE('  - Semestres a proyectar: ' || p_next_n);
  DBMS_OUTPUT.PUT_LINE('  - Filtro Institución: ' || NVL(TO_CHAR(p_institucion_id), 'TODAS'));
  DBMS_OUTPUT.PUT_LINE('  - Filtro Carrera: ' || NVL(TO_CHAR(p_carrera_id), 'TODAS'));
  DBMS_OUTPUT.PUT_LINE('  - Filtro Región: ' || NVL(TO_CHAR(p_region_id), 'TODAS'));
  
  -- Abrir cursor complejo con parámetros
  OPEN c_prog(p_institucion_id, p_carrera_id, p_region_id);
  LOOP
    FETCH c_prog INTO v_prog.institucion_id, v_prog.institucion_nombre, v_prog.carrera_id, v_prog.carrera_nombre;
    EXIT WHEN c_prog%NOTFOUND;
    
    v_contador := v_contador + 1;
    v_current_inst_id := v_prog.institucion_id;
    v_current_carrera_id := v_prog.carrera_id;
    
    DBMS_OUTPUT.PUT_LINE('Procesando (' || v_contador || '): ' || 
                        v_prog.institucion_nombre || ' - ' || v_prog.carrera_nombre);

    -- Bloque protegido para la proyección
    BEGIN
      v_proyecto := proyeccion_estudiantes_para_prox_semestres(v_prog.institucion_id, v_prog.carrera_id, p_next_n);
      
      -- Validar que la proyección no sea nula
      IF v_proyecto IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: Proyección nula para Inst:' || v_prog.institucion_id || 
                           ', Carrera:' || v_prog.carrera_id || '. Saltando...');
        CONTINUE;
      END IF;
      
      -- Validar que tenga el número correcto de elementos
      IF v_proyecto.COUNT != p_next_n THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: Proyección incompleta (' || v_proyecto.COUNT || 
                           '/' || p_next_n || ' semestres). Continuando con datos parciales...');
      END IF;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: Sin datos históricos para Inst:' || v_prog.institucion_id || 
                           ', Carrera:' || v_prog.carrera_id || '. Saltando...');
        CONTINUE;
      WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Valores inválidos en proyección para Inst:' || v_prog.institucion_id || 
                           ', Carrera:' || v_prog.carrera_id || '. Saltando...');
        CONTINUE;
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Fallo en proyección para Inst:' || v_prog.institucion_id || 
                           ', Carrera:' || v_prog.carrera_id || ' - ' || SQLERRM);
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
            DBMS_OUTPUT.PUT_LINE('WARNING: Error calculando etiqueta semestre ' || i || 
                               '. Usando etiqueta por defecto: ' || v_sem_label);
        END;

        -- Validar proyección antes de usar
        IF v_proyecto(i) IS NULL THEN
          DBMS_OUTPUT.PUT_LINE('WARNING: Proyección nula para semestre ' || i || '. Usando 0.');
          v_proyecto(i) := 0;
        ELSIF v_proyecto(i) < 0 THEN
          DBMS_OUTPUT.PUT_LINE('WARNING: Proyección negativa (' || v_proyecto(i) || 
                             ') para semestre ' || i || '. Usando 0.');
          v_proyecto(i) := 0;
        END IF;

        -- Calcular profesores con manejo de errores
        BEGIN
          v_profs := profs_necesitados(v_proyecto(i), 30);
        EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Fallo calculando profesores para semestre ' || i || 
                               '. Usando cálculo por defecto.');
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
            DBMS_OUTPUT.PUT_LINE('ERROR: Fallo calculando salas para semestre ' || i || 
                               '. Usando cálculo por defecto.');
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
            DBMS_OUTPUT.PUT_LINE('WARNING: Registro duplicado para Inst:' || v_prog.institucion_id || 
                               ', Carrera:' || v_prog.carrera_id || ', Semestre:' || v_sem_label || '. Saltando...');
          WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Fallo insertando registro para semestre ' || i || 
                               ' - ' || SQLERRM);
            RAISE; -- Re-lanzar para que se maneje en el nivel superior
        END;
        
      EXCEPTION
        WHEN SUBSCRIPT_BEYOND_COUNT THEN
          DBMS_OUTPUT.PUT_LINE('ERROR: Índice fuera de rango en proyección (semestre ' || i || 
                             '). Elementos disponibles: ' || NVL(v_proyecto.COUNT, 0));
          EXIT; -- Salir del loop de semestres
        WHEN SUBSCRIPT_OUTSIDE_LIMIT THEN
          DBMS_OUTPUT.PUT_LINE('ERROR: Límite de VARRAY excedido en semestre ' || i);
          EXIT;
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR: Fallo procesando semestre ' || i || ' - ' || SQLERRM);
          -- Continuar con el siguiente semestre
      END;
    END LOOP;

  END LOOP;
  CLOSE c_prog;
  
  DBMS_OUTPUT.PUT_LINE('=== PROCESO COMPLETADO ===');
  DBMS_OUTPUT.PUT_LINE('Combinaciones procesadas: ' || v_contador);
  DBMS_OUTPUT.PUT_LINE('Registros totales generados: ' || (v_contador * p_next_n));
  
  COMMIT;
  
EXCEPTION
  -- Errores de validación de parámetros
  WHEN e_parametros_invalidos THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('======= ERROR DE PARÁMETROS =======');
    DBMS_OUTPUT.PUT_LINE('Código: ' || v_error_code);
    DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('Parámetros recibidos:');
    DBMS_OUTPUT.PUT_LINE('  - p_next_n: ' || NVL(TO_CHAR(p_next_n), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - p_institucion_id: ' || NVL(TO_CHAR(p_institucion_id), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - p_carrera_id: ' || NVL(TO_CHAR(p_carrera_id), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - p_region_id: ' || NVL(TO_CHAR(p_region_id), 'NULL'));
    IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
    ROLLBACK;
    RAISE;

  -- Errores de tabla no encontrada
  WHEN e_tabla_no_existe THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('======= ERROR DE TABLA FALTANTE =======');
    DBMS_OUTPUT.PUT_LINE('Código: ' || v_error_code);
    DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('Verifique que existan las siguientes tablas:');
    DBMS_OUTPUT.PUT_LINE('  - MATRICULAS, INSTITUCIONES, CARRERAS');
    DBMS_OUTPUT.PUT_LINE('  - PLANES_RECURSOS, INSTITUCION_CAPACIDAD');
    IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
    ROLLBACK;
    RAISE;

  -- Errores de cursor
  WHEN CURSOR_ALREADY_OPEN THEN
    DBMS_OUTPUT.PUT_LINE('======= ERROR DE CURSOR =======');
    DBMS_OUTPUT.PUT_LINE('El cursor ya estaba abierto. Cerrando y reintentando...');
    IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20300, 'Error de cursor: Ya estaba abierto');

  WHEN INVALID_CURSOR THEN
    DBMS_OUTPUT.PUT_LINE('======= ERROR DE CURSOR INVÁLIDO =======');
    DBMS_OUTPUT.PUT_LINE('Cursor en estado inválido');
    DBMS_OUTPUT.PUT_LINE('Combinaciones procesadas: ' || NVL(v_contador, 0));
    IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20301, 'Error de cursor: Estado inválido');

  -- Errores de memoria y recursos
  WHEN STORAGE_ERROR THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('======= ERROR DE MEMORIA =======');
    DBMS_OUTPUT.PUT_LINE('Código: ' || v_error_code);
    DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('Combinaciones procesadas: ' || NVL(v_contador, 0));
    DBMS_OUTPUT.PUT_LINE('Última institución procesada: ' || NVL(v_current_inst_id, 0));
    DBMS_OUTPUT.PUT_LINE('Última carrera procesada: ' || NVL(v_current_carrera_id, 0));
    IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20302, 'Error de memoria: Insuficiente espacio');

  WHEN PROGRAM_ERROR THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('======= ERROR DE PROGRAMA =======');
    DBMS_OUTPUT.PUT_LINE('Código: ' || v_error_code);
    DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('Error interno de PL/SQL detectado');
    IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20303, 'Error de programa interno');

  -- Errores de datos
  WHEN VALUE_ERROR THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('======= ERROR DE VALOR =======');
    DBMS_OUTPUT.PUT_LINE('Código: ' || v_error_code);
    DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('Datos problemáticos detectados en:');
    DBMS_OUTPUT.PUT_LINE('  - Institución: ' || NVL(v_current_inst_id, 0));
    DBMS_OUTPUT.PUT_LINE('  - Carrera: ' || NVL(v_current_carrera_id, 0));
    DBMS_OUTPUT.PUT_LINE('  - Registro: ' || NVL(v_contador, 0));
    IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20304, 'Error de datos: Valores inválidos');

  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('======= SIN DATOS =======');
    DBMS_OUTPUT.PUT_LINE('No se encontraron datos para procesar');
    DBMS_OUTPUT.PUT_LINE('Verifique los filtros aplicados:');
    DBMS_OUTPUT.PUT_LINE('  - Institución: ' || NVL(TO_CHAR(p_institucion_id), 'TODAS'));
    DBMS_OUTPUT.PUT_LINE('  - Carrera: ' || NVL(TO_CHAR(p_carrera_id), 'TODAS'));
    DBMS_OUTPUT.PUT_LINE('  - Región: ' || NVL(TO_CHAR(p_region_id), 'TODAS'));
    IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20305, 'Sin datos: No hay registros que procesar');

  -- Errores de transacción
  WHEN DUP_VAL_ON_INDEX THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('======= ERROR DE CLAVE DUPLICADA =======');
    DBMS_OUTPUT.PUT_LINE('Código: ' || v_error_code);
    DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('Posible ejecución duplicada del procedimiento');
    DBMS_OUTPUT.PUT_LINE('Considere limpiar PLANES_RECURSOS antes de ejecutar');
    IF c_prog%ISOPEN THEN CLOSE c_prog; END IF;
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20306, 'Error de duplicados: Ya existen registros');

  -- Errores generales del sistema
  WHEN OTHERS THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    
    DBMS_OUTPUT.PUT_LINE('======================================');
    DBMS_OUTPUT.PUT_LINE('======= ERROR INESPERADO =======');
    DBMS_OUTPUT.PUT_LINE('======================================');
    DBMS_OUTPUT.PUT_LINE('CÓDIGO DE ERROR: ' || v_error_code);
    DBMS_OUTPUT.PUT_LINE('MENSAJE: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('CONTEXTO DE EJECUCIÓN:');
    DBMS_OUTPUT.PUT_LINE('  - Timestamp: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('  - Usuario: ' || USER);
    DBMS_OUTPUT.PUT_LINE('  - Sesión: ' || SYS_CONTEXT('USERENV', 'SESSIONID'));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('PARÁMETROS DE ENTRADA:');
    DBMS_OUTPUT.PUT_LINE('  - p_next_n: ' || NVL(TO_CHAR(p_next_n), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - p_institucion_id: ' || NVL(TO_CHAR(p_institucion_id), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - p_carrera_id: ' || NVL(TO_CHAR(p_carrera_id), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - p_region_id: ' || NVL(TO_CHAR(p_region_id), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('ESTADO AL MOMENTO DEL ERROR:');
    DBMS_OUTPUT.PUT_LINE('  - Combinaciones procesadas: ' || NVL(v_contador, 0));
    DBMS_OUTPUT.PUT_LINE('  - Última institución: ' || NVL(v_current_inst_id, 0));
    DBMS_OUTPUT.PUT_LINE('  - Última carrera: ' || NVL(v_current_carrera_id, 0));
    DBMS_OUTPUT.PUT_LINE('  - Estado cursor: ' || CASE WHEN c_prog%ISOPEN THEN 'ABIERTO' ELSE 'CERRADO' END);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('ACCIONES RECOMENDADAS:');
    DBMS_OUTPUT.PUT_LINE('  1. Verificar integridad de datos en tablas base');
    DBMS_OUTPUT.PUT_LINE('  2. Comprobar disponibilidad de funciones auxiliares');
    DBMS_OUTPUT.PUT_LINE('  3. Revisar permisos de usuario');
    DBMS_OUTPUT.PUT_LINE('  4. Contactar al administrador si persiste');
    DBMS_OUTPUT.PUT_LINE('======================================');
    
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
/
