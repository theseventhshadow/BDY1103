-- ==========================================================
-- Verifica capacidad antes de insertar una nueva matrícula
-- ==========================================================

CREATE OR REPLACE TRIGGER trg_matriculas_check_capacidad
BEFORE INSERT ON MATRICULAS
FOR EACH ROW
DECLARE
  -- Variables principales
  v_total_estudiantes NUMBER;
  v_salas_requeridas NUMBER;
  v_salas_disp NUMBER;
  v_cap_por_aula NUMBER;
  
  -- Variables para logging y diagnóstico
  v_error_code NUMBER;
  v_error_msg VARCHAR2(4000);
  v_error_context VARCHAR2(1000);
  v_usuario VARCHAR2(100) := USER;
  v_timestamp TIMESTAMP := SYSTIMESTAMP;
  
  -- Variables para validaciones adicionales
  v_institucion_exists NUMBER := 0;
  v_carrera_exists NUMBER := 0;
  v_capacidad_record_count NUMBER := 0;
  
  -- Excepciones personalizadas
  e_datos_invalidos EXCEPTION;
  e_capacidad_excedida EXCEPTION;
  e_institucion_inexistente EXCEPTION;
  e_carrera_inexistente EXCEPTION;
  e_funcion_no_disponible EXCEPTION;
  e_datos_inconsistentes EXCEPTION;
  
  -- Códigos de error asociados
  PRAGMA EXCEPTION_INIT(e_capacidad_excedida, -20020);
  PRAGMA EXCEPTION_INIT(e_datos_invalidos, -20021);
  PRAGMA EXCEPTION_INIT(e_institucion_inexistente, -20022);
  PRAGMA EXCEPTION_INIT(e_carrera_inexistente, -20023);
  PRAGMA EXCEPTION_INIT(e_funcion_no_disponible, -20024);
  PRAGMA EXCEPTION_INIT(e_datos_inconsistentes, -20025);

BEGIN
  -- =====================================
  -- BLOQUE DE VALIDACIONES INICIALES
  -- =====================================
  
  -- Validación de datos básicos de la nueva matrícula  
  IF :NEW.INSTITUCION_ID IS NULL THEN
    RAISE_APPLICATION_ERROR(-20021, 'TRIGGER_ERROR: INSTITUCION_ID no puede ser NULL');
  END IF;
  
  IF :NEW.CARRERA_ID IS NULL THEN
    RAISE_APPLICATION_ERROR(-20021, 'TRIGGER_ERROR: CARRERA_ID no puede ser NULL');
  END IF;
  
  IF :NEW.ANIO_INGRESO IS NULL OR :NEW.ANIO_INGRESO < 1900 OR :NEW.ANIO_INGRESO > 2100 THEN
    RAISE_APPLICATION_ERROR(-20021, 'TRIGGER_ERROR: ANIO_INGRESO inválido (' || 
                           NVL(TO_CHAR(:NEW.ANIO_INGRESO), 'NULL') || ')');
  END IF;
  
  IF :NEW.SEMESTRE_INGRESO IS NULL OR :NEW.SEMESTRE_INGRESO NOT IN (1,2) THEN
    RAISE_APPLICATION_ERROR(-20021, 'TRIGGER_ERROR: SEMESTRE_INGRESO debe ser 1 o 2 (' || 
                           NVL(TO_CHAR(:NEW.SEMESTRE_INGRESO), 'NULL') || ')');
  END IF;

  -- Verificar existencia de institución
  BEGIN
    SELECT COUNT(*) INTO v_institucion_exists 
    FROM INSTITUCIONES 
    WHERE INSTITUCION_ID = :NEW.INSTITUCION_ID;
    
    IF v_institucion_exists = 0 THEN
      RAISE e_institucion_inexistente;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20022, 'TRIGGER_ERROR: Institución ID ' || 
                             :NEW.INSTITUCION_ID || ' no existe en INSTITUCIONES');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20022, 'TRIGGER_ERROR: Error verificando institución - ' || SQLERRM);
  END;

  -- Verificar existencia de carrera
  BEGIN
    SELECT COUNT(*) INTO v_carrera_exists 
    FROM CARRERAS 
    WHERE CARRERA_ID = :NEW.CARRERA_ID;
    
    IF v_carrera_exists = 0 THEN
      RAISE e_carrera_inexistente;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20023, 'TRIGGER_ERROR: Carrera ID ' || 
                             :NEW.CARRERA_ID || ' no existe en CARRERAS');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20023, 'TRIGGER_ERROR: Error verificando carrera - ' || SQLERRM);
  END;

  -- =====================================
  -- CÁLCULO DE ESTUDIANTES ACTUALES
  -- =====================================
  
  -- Contar alumnos actuales para la misma institucion + carrera y semestre
  BEGIN
    SELECT COUNT(*) INTO v_total_estudiantes
    FROM MATRICULAS m
    WHERE m.INSTITUCION_ID = :NEW.INSTITUCION_ID
      AND m.CARRERA_ID = :NEW.CARRERA_ID
      AND m.ANIO_INGRESO = :NEW.ANIO_INGRESO
      AND m.SEMESTRE_INGRESO = :NEW.SEMESTRE_INGRESO;
      
    v_total_estudiantes := v_total_estudiantes + 1; -- Incluir la nueva matrícula
    
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20025, 'TRIGGER_ERROR: Error contando estudiantes existentes - ' || SQLERRM);
  END;

  -- =====================================
  -- OBTENCIÓN DE CAPACIDAD INSTITUCIONAL
  -- =====================================
  
  -- Obtener capacidad de la institución con validaciones robustas
  BEGIN
    -- Verificar si existe registro de capacidad
    SELECT COUNT(*) INTO v_capacidad_record_count
    FROM INSTITUCION_CAPACIDAD
    WHERE INSTITUCION_ID = :NEW.INSTITUCION_ID;
    
    IF v_capacidad_record_count = 0 THEN
      -- Sin registro de capacidad - usar valores por defecto
      v_salas_disp := 10;      -- Aulas por defecto
      v_cap_por_aula := 40;    -- Capacidad por defecto
      IF log_error('INFO', 'trg_matriculas_check_capacidad', 
                   'Institución ' || :NEW.INSTITUCION_ID || 
                   ' sin registro de capacidad. Usando valores por defecto: ' ||
                   v_salas_disp || ' aulas de ' || v_cap_por_aula || ' estudiantes c/u') = 0 THEN
        NULL; -- Fallo en logging, continúa
      END IF;
    ELSE
      -- Obtener datos de capacidad
      SELECT NVL(TOTAL_AULAS, 0), NVL(CAPACIDAD_POR_AULA, 40) 
      INTO v_salas_disp, v_cap_por_aula
      FROM INSTITUCION_CAPACIDAD
      WHERE INSTITUCION_ID = :NEW.INSTITUCION_ID;
      
      -- Validaciones de datos obtenidos
      IF v_salas_disp < 0 THEN
        RAISE_APPLICATION_ERROR(-20025, 'TRIGGER_ERROR: TOTAL_AULAS negativo (' || 
                               v_salas_disp || ') para institución ' || :NEW.INSTITUCION_ID);
      END IF;
      
      IF v_cap_por_aula <= 0 THEN
        RAISE_APPLICATION_ERROR(-20025, 'TRIGGER_ERROR: CAPACIDAD_POR_AULA inválida (' || 
                               v_cap_por_aula || ') para institución ' || :NEW.INSTITUCION_ID);
      END IF;
      
      -- Advertencias para valores extremos
      IF v_salas_disp = 0 THEN
        IF log_error('WARNING', 'trg_matriculas_check_capacidad', 
                     'Institución ' || :NEW.INSTITUCION_ID || ' tiene 0 aulas registradas') = 0 THEN
          NULL; -- Fallo en logging, continúa
        END IF;
      END IF;
      
      IF v_cap_por_aula > 200 THEN
        IF log_error('WARNING', 'trg_matriculas_check_capacidad', 
                     'Capacidad por aula muy alta (' || v_cap_por_aula || 
                     ') para institución ' || :NEW.INSTITUCION_ID) = 0 THEN
          NULL; -- Fallo en logging, continúa
        END IF;
      END IF;
    END IF;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Fallback por si la consulta no retorna datos
      v_salas_disp := 10;
      v_cap_por_aula := 40;
      IF log_error('INFO', 'trg_matriculas_check_capacidad', 
                   'Sin datos de capacidad para institución ' || :NEW.INSTITUCION_ID || '. Usando fallback.') = 0 THEN
        NULL; -- Fallo en logging, continúa
      END IF;
    WHEN TOO_MANY_ROWS THEN
      RAISE_APPLICATION_ERROR(-20025, 'TRIGGER_ERROR: Múltiples registros de capacidad para institución ' || 
                             :NEW.INSTITUCION_ID || '. Configuración inconsistente.');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20025, 'TRIGGER_ERROR: Error obteniendo capacidad institucional - ' || SQLERRM);
  END;

  -- =====================================
  -- CÁLCULO DE SALAS REQUERIDAS
  -- =====================================
  
  BEGIN
    -- Llamar función para calcular salas necesarias
    v_salas_requeridas := classrooms_needed(v_total_estudiantes, v_cap_por_aula);
    
    -- Validar resultado de la función
    IF v_salas_requeridas IS NULL THEN
      RAISE_APPLICATION_ERROR(-20024, 'TRIGGER_ERROR: Función classrooms_needed retornó NULL');
    END IF;
    
    IF v_salas_requeridas < 0 THEN
      RAISE_APPLICATION_ERROR(-20024, 'TRIGGER_ERROR: Función classrooms_needed retornó valor negativo: ' || 
                             v_salas_requeridas);
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Si la función falla, calcular manualmente
      IF log_error('WARNING', 'trg_matriculas_check_capacidad', 
                   'Error en función classrooms_needed - ' || SQLERRM || '. Calculando manualmente.') = 0 THEN
        NULL; -- Fallo en logging, continúa
      END IF;
      v_salas_requeridas := CEIL(v_total_estudiantes / v_cap_por_aula);
  END;

  -- =====================================
  -- VERIFICACIÓN DE CAPACIDAD
  -- =====================================
  
  -- Registro informativo
  IF log_error('INFO', 'trg_matriculas_check_capacidad', 
               'VERIFICACIÓN CAPACIDAD - Institución: ' || :NEW.INSTITUCION_ID ||
               ', Carrera: ' || :NEW.CARRERA_ID ||
               ', Período: ' || :NEW.ANIO_INGRESO || '-' || :NEW.SEMESTRE_INGRESO ||
               ', Estudiantes: ' || v_total_estudiantes ||
               ', Cap/aula: ' || v_cap_por_aula ||
               ', Salas req: ' || v_salas_requeridas ||
               ', Salas disp: ' || v_salas_disp) = 0 THEN
    NULL; -- Fallo en logging, continúa
  END IF;
  
  -- Verificación principal de capacidad
  IF v_salas_disp = 0 THEN
    IF log_error('WARNING', 'trg_matriculas_check_capacidad', 
                 'Institución sin aulas registradas. Permitiendo inserción con advertencia.') = 0 THEN
      NULL; -- Fallo en logging, continúa
    END IF;
  ELSIF v_salas_requeridas > v_salas_disp THEN
    -- Capacidad excedida - bloquear inserción
    v_error_context := 'Institución: ' || :NEW.INSTITUCION_ID || 
                      ', Carrera: ' || :NEW.CARRERA_ID ||
                      ', Período: ' || :NEW.ANIO_INGRESO || '-' || :NEW.SEMESTRE_INGRESO;
    RAISE_APPLICATION_ERROR(-20020, 
      'CAPACIDAD_EXCEDIDA: Aulas insuficientes.' || CHR(10) ||
      'Requeridas: ' || v_salas_requeridas || ', Disponibles: ' || v_salas_disp || CHR(10) ||
      'Estudiantes: ' || v_total_estudiantes || ', Cap/aula: ' || v_cap_por_aula || CHR(10) ||
      'Contexto: ' || v_error_context);
  ELSE
    IF log_error('INFO', 'trg_matriculas_check_capacidad', 
                 'SUCCESS: Capacidad suficiente. Inserción permitida.') = 0 THEN
      NULL; -- Fallo en logging, continúa
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
/
