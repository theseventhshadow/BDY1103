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
      DBMS_OUTPUT.PUT_LINE('INFO: Institución ' || :NEW.INSTITUCION_ID || 
                          ' sin registro de capacidad. Usando valores por defecto: ' ||
                          v_salas_disp || ' aulas de ' || v_cap_por_aula || ' estudiantes c/u');
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
        DBMS_OUTPUT.PUT_LINE('WARNING: Institución ' || :NEW.INSTITUCION_ID || 
                           ' tiene 0 aulas registradas');
      END IF;
      
      IF v_cap_por_aula > 200 THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: Capacidad por aula muy alta (' || v_cap_por_aula || 
                           ') para institución ' || :NEW.INSTITUCION_ID);
      END IF;
    END IF;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Fallback por si la consulta no retorna datos
      v_salas_disp := 10;
      v_cap_por_aula := 40;
      DBMS_OUTPUT.PUT_LINE('INFO: Sin datos de capacidad para institución ' || 
                          :NEW.INSTITUCION_ID || '. Usando fallback.');
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
      DBMS_OUTPUT.PUT_LINE('WARNING: Error en función classrooms_needed - ' || SQLERRM);
      DBMS_OUTPUT.PUT_LINE('INFO: Calculando salas requeridas manualmente');
      v_salas_requeridas := CEIL(v_total_estudiantes / v_cap_por_aula);
  END;

  -- =====================================
  -- VERIFICACIÓN DE CAPACIDAD
  -- =====================================
  
  -- Registro informativo
  DBMS_OUTPUT.PUT_LINE('=== VERIFICACIÓN CAPACIDAD ===');
  DBMS_OUTPUT.PUT_LINE('Institución: ' || :NEW.INSTITUCION_ID);
  DBMS_OUTPUT.PUT_LINE('Carrera: ' || :NEW.CARRERA_ID);
  DBMS_OUTPUT.PUT_LINE('Período: ' || :NEW.ANIO_INGRESO || '-' || :NEW.SEMESTRE_INGRESO);
  DBMS_OUTPUT.PUT_LINE('Estudiantes actuales + nuevo: ' || v_total_estudiantes);
  DBMS_OUTPUT.PUT_LINE('Capacidad por aula: ' || v_cap_por_aula);
  DBMS_OUTPUT.PUT_LINE('Salas requeridas: ' || v_salas_requeridas);
  DBMS_OUTPUT.PUT_LINE('Salas disponibles: ' || v_salas_disp);
  
  -- Verificación principal de capacidad
  IF v_salas_disp = 0 THEN
    DBMS_OUTPUT.PUT_LINE('WARNING: Institución sin aulas registradas. Permitiendo inserción con advertencia.');
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
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Capacidad suficiente. Inserción permitida.');
  END IF;

EXCEPTION
  -- =====================================
  -- MANEJO ESPECÍFICO DE EXCEPCIONES
  -- =====================================
  
  -- Errores de validación de datos
  WHEN e_datos_invalidos THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('===== ERROR DE DATOS INVÁLIDOS =====');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('Usuario: ' || v_usuario);
    DBMS_OUTPUT.PUT_LINE('Código: ' || v_error_code);
    DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('Datos de matrícula problemáticos:');
    DBMS_OUTPUT.PUT_LINE('  - INSTITUCION_ID: ' || NVL(TO_CHAR(:NEW.INSTITUCION_ID), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - CARRERA_ID: ' || NVL(TO_CHAR(:NEW.CARRERA_ID), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - ANIO_INGRESO: ' || NVL(TO_CHAR(:NEW.ANIO_INGRESO), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - SEMESTRE_INGRESO: ' || NVL(TO_CHAR(:NEW.SEMESTRE_INGRESO), 'NULL'));
    RAISE;

  -- Capacidad excedida
  WHEN e_capacidad_excedida THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('===== CAPACIDAD EXCEDIDA =====');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('Usuario: ' || v_usuario);
    DBMS_OUTPUT.PUT_LINE('Matrícula rechazada por falta de capacidad:');
    DBMS_OUTPUT.PUT_LINE('  - Institución: ' || :NEW.INSTITUCION_ID);
    DBMS_OUTPUT.PUT_LINE('  - Carrera: ' || :NEW.CARRERA_ID);
    DBMS_OUTPUT.PUT_LINE('  - Período: ' || :NEW.ANIO_INGRESO || '-' || :NEW.SEMESTRE_INGRESO);
    DBMS_OUTPUT.PUT_LINE('  - Estudiantes totales: ' || NVL(v_total_estudiantes, 0));
    DBMS_OUTPUT.PUT_LINE('  - Salas requeridas: ' || NVL(v_salas_requeridas, 0));
    DBMS_OUTPUT.PUT_LINE('  - Salas disponibles: ' || NVL(v_salas_disp, 0));
    DBMS_OUTPUT.PUT_LINE('Recomendación: Aumentar TOTAL_AULAS en INSTITUCION_CAPACIDAD');
    RAISE;

  -- Institución inexistente
  WHEN e_institucion_inexistente THEN
    DBMS_OUTPUT.PUT_LINE('===== INSTITUCIÓN INEXISTENTE =====');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('Usuario: ' || v_usuario);
    DBMS_OUTPUT.PUT_LINE('INSTITUCION_ID no válido: ' || :NEW.INSTITUCION_ID);
    DBMS_OUTPUT.PUT_LINE('Verificar tabla INSTITUCIONES');
    RAISE_APPLICATION_ERROR(-20022, 'TRIGGER_ERROR: Institución ' || :NEW.INSTITUCION_ID || ' no existe');

  -- Carrera inexistente
  WHEN e_carrera_inexistente THEN
    DBMS_OUTPUT.PUT_LINE('===== CARRERA INEXISTENTE =====');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('Usuario: ' || v_usuario);
    DBMS_OUTPUT.PUT_LINE('CARRERA_ID no válido: ' || :NEW.CARRERA_ID);
    DBMS_OUTPUT.PUT_LINE('Verificar tabla CARRERAS');
    RAISE_APPLICATION_ERROR(-20023, 'TRIGGER_ERROR: Carrera ' || :NEW.CARRERA_ID || ' no existe');

  -- Función no disponible
  WHEN e_funcion_no_disponible THEN
    DBMS_OUTPUT.PUT_LINE('===== FUNCIÓN NO DISPONIBLE =====');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('Error en función classrooms_needed');
    DBMS_OUTPUT.PUT_LINE('Parámetros: estudiantes=' || NVL(v_total_estudiantes,0) || 
                         ', capacidad=' || NVL(v_cap_por_aula,0));
    RAISE_APPLICATION_ERROR(-20024, 'TRIGGER_ERROR: Función classrooms_needed no disponible');

  -- Datos inconsistentes
  WHEN e_datos_inconsistentes THEN
    DBMS_OUTPUT.PUT_LINE('===== DATOS INCONSISTENTES =====');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('Datos inconsistentes detectados en capacidad institucional');
    DBMS_OUTPUT.PUT_LINE('Institución: ' || :NEW.INSTITUCION_ID);
    DBMS_OUTPUT.PUT_LINE('Verificar tabla INSTITUCION_CAPACIDAD');
    RAISE;

  -- Sin datos encontrados (específico para capacidad)
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('===== SIN DATOS DE CAPACIDAD =====');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('No existe registro en INSTITUCION_CAPACIDAD para INSTITUCION_ID: ' || :NEW.INSTITUCION_ID);
    DBMS_OUTPUT.PUT_LINE('ACCIÓN: Matrícula permitida con valores por defecto');
    DBMS_OUTPUT.PUT_LINE('RECOMENDACIÓN: Crear registro de capacidad para esta institución');
    -- No bloquear la inserción, solo advertir

  -- Demasiadas filas
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('===== CONFIGURACIÓN DUPLICADA =====');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('Múltiples registros de capacidad para INSTITUCION_ID: ' || :NEW.INSTITUCION_ID);
    DBMS_OUTPUT.PUT_LINE('ACCIÓN: Matrícula bloqueada');
    DBMS_OUTPUT.PUT_LINE('CORRECCIÓN: Eliminar registros duplicados en INSTITUCION_CAPACIDAD');
    RAISE_APPLICATION_ERROR(-20025, 'TRIGGER_ERROR: Configuración de capacidad duplicada para institución ' || 
                           :NEW.INSTITUCION_ID);

  -- Errores de valor
  WHEN VALUE_ERROR THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('===== ERROR DE VALOR =====');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('Usuario: ' || v_usuario);
    DBMS_OUTPUT.PUT_LINE('Código: ' || v_error_code);
    DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('Error de conversión o valor inválido detectado');
    DBMS_OUTPUT.PUT_LINE('Contexto de datos:');
    DBMS_OUTPUT.PUT_LINE('  - v_total_estudiantes: ' || NVL(TO_CHAR(v_total_estudiantes), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - v_cap_por_aula: ' || NVL(TO_CHAR(v_cap_por_aula), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - v_salas_requeridas: ' || NVL(TO_CHAR(v_salas_requeridas), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - v_salas_disp: ' || NVL(TO_CHAR(v_salas_disp), 'NULL'));
    RAISE_APPLICATION_ERROR(-20026, 'TRIGGER_ERROR: Error de valor en cálculos de capacidad');

  -- Error de acceso (permisos, objetos bloqueados, etc.)
  WHEN ACCESS_INTO_NULL THEN
    DBMS_OUTPUT.PUT_LINE('===== ERROR DE ACCESO =====');
    DBMS_OUTPUT.PUT_LINE('Timestamp: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('Intento de acceso a variable no inicializada');
    RAISE_APPLICATION_ERROR(-20027, 'TRIGGER_ERROR: Variable no inicializada');

  -- Errores generales del sistema
  WHEN OTHERS THEN
    v_error_code := SQLCODE;
    v_error_msg := SQLERRM;
    
    DBMS_OUTPUT.PUT_LINE('================================================');
    DBMS_OUTPUT.PUT_LINE('======= ERROR INESPERADO EN TRIGGER =======');
    DBMS_OUTPUT.PUT_LINE('================================================');
    DBMS_OUTPUT.PUT_LINE('TIMESTAMP: ' || TO_CHAR(v_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('USUARIO: ' || v_usuario);
    DBMS_OUTPUT.PUT_LINE('CÓDIGO DE ERROR: ' || v_error_code);
    DBMS_OUTPUT.PUT_LINE('MENSAJE: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('CONTEXTO DE MATRÍCULA:');
    DBMS_OUTPUT.PUT_LINE('  - INSTITUCION_ID: ' || NVL(TO_CHAR(:NEW.INSTITUCION_ID), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - CARRERA_ID: ' || NVL(TO_CHAR(:NEW.CARRERA_ID), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - ANIO_INGRESO: ' || NVL(TO_CHAR(:NEW.ANIO_INGRESO), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - SEMESTRE_INGRESO: ' || NVL(TO_CHAR(:NEW.SEMESTRE_INGRESO), 'NULL'));
    IF :NEW.PERSONA_ID IS NOT NULL THEN
      DBMS_OUTPUT.PUT_LINE('  - PERSONA_ID: ' || :NEW.PERSONA_ID);
    END IF;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('ESTADO DE VARIABLES:');
    DBMS_OUTPUT.PUT_LINE('  - v_total_estudiantes: ' || NVL(TO_CHAR(v_total_estudiantes), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - v_cap_por_aula: ' || NVL(TO_CHAR(v_cap_por_aula), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - v_salas_requeridas: ' || NVL(TO_CHAR(v_salas_requeridas), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - v_salas_disp: ' || NVL(TO_CHAR(v_salas_disp), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - v_institucion_exists: ' || NVL(TO_CHAR(v_institucion_exists), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('  - v_carrera_exists: ' || NVL(TO_CHAR(v_carrera_exists), 'NULL'));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('INFORMACIÓN DEL SISTEMA:');
    DBMS_OUTPUT.PUT_LINE('  - Sesión: ' || SYS_CONTEXT('USERENV', 'SESSIONID'));
    DBMS_OUTPUT.PUT_LINE('  - Terminal: ' || SYS_CONTEXT('USERENV', 'TERMINAL'));
    DBMS_OUTPUT.PUT_LINE('  - IP Address: ' || SYS_CONTEXT('USERENV', 'IP_ADDRESS'));
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('ACCIONES RECOMENDADAS:');
    DBMS_OUTPUT.PUT_LINE('  1. Verificar integridad referencial en INSTITUCIONES y CARRERAS');
    DBMS_OUTPUT.PUT_LINE('  2. Comprobar existencia de función classrooms_needed');
    DBMS_OUTPUT.PUT_LINE('  3. Validar datos en INSTITUCION_CAPACIDAD');
    DBMS_OUTPUT.PUT_LINE('  4. Revisar permisos del usuario ' || v_usuario);
    DBMS_OUTPUT.PUT_LINE('  5. Contactar al DBA si el problema persiste');
    DBMS_OUTPUT.PUT_LINE('================================================');
    
    -- Re-lanzar con información contextual
    RAISE_APPLICATION_ERROR(-20999, 
      'TRIGGER_FATAL: Fallo inesperado en verificación de capacidad. ' ||
      'Código: ' || v_error_code || ', Inst: ' || NVL(TO_CHAR(:NEW.INSTITUCION_ID), 'NULL') ||
      ', Carrera: ' || NVL(TO_CHAR(:NEW.CARRERA_ID), 'NULL') ||
      '. Mensaje: ' || SUBSTR(v_error_msg, 1, 1000));
      
END;
/
