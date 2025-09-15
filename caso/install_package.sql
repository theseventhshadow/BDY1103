-- ======================================================================
-- INSTALACIÓN DEL PACKAGE PKG_PROYECCION_RECURSOS
-- ======================================================================
-- Archivo de instalación que maneja las dependencias y orden de ejecución
-- ======================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF

PROMPT ======================================================================
PROMPT Instalando Package PKG_PROYECCION_RECURSOS
PROMPT ======================================================================

-- ====================================================================
-- PASO 1: Verificar y crear dependencias
-- ====================================================================

PROMPT
PROMPT === PASO 1: Verificando dependencias ===

-- Verificar si existe la tabla ERROR_LOG
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count 
  FROM USER_TABLES 
  WHERE TABLE_NAME = 'ERROR_LOG';
  
  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Creando tabla ERROR_LOG...');
    EXECUTE IMMEDIATE '
      CREATE TABLE ERROR_LOG (
        LOG_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        SEVERITY VARCHAR2(10),
        SOURCE_OBJ VARCHAR2(100),
        ERROR_MSG VARCHAR2(4000),
        CREATED_AT DATE DEFAULT SYSDATE
      )';
    DBMS_OUTPUT.PUT_LINE('✓ Tabla ERROR_LOG creada exitosamente');
  ELSE
    DBMS_OUTPUT.PUT_LINE('✓ Tabla ERROR_LOG ya existe');
  END IF;
END;
/

-- Verificar si existe la tabla PLANES_RECURSOS
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count 
  FROM USER_TABLES 
  WHERE TABLE_NAME = 'PLANES_RECURSOS';
  
  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Creando tabla PLANES_RECURSOS...');
    EXECUTE IMMEDIATE '
      CREATE TABLE PLANES_RECURSOS (
        PLAN_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        INSTITUCION_ID INTEGER,
        INSTITUCION_NOMBRE VARCHAR2(200),
        CARRERA_ID INTEGER,
        CARRERA_NOMBRE VARCHAR2(200),
        SEMESTRE_LABEL VARCHAR2(10),
        ESTUDIANTES_PROYECTADOS NUMBER,
        PROFERORES_REQUERIDOS NUMBER,
        SALAS_REQUERIDAS NUMBER,
        CREATED_AT DATE DEFAULT SYSDATE,
        UPDATED_AT DATE DEFAULT SYSDATE
      )';
    DBMS_OUTPUT.PUT_LINE('✓ Tabla PLANES_RECURSOS creada exitosamente');
  ELSE
    DBMS_OUTPUT.PUT_LINE('✓ Tabla PLANES_RECURSOS ya existe');
  END IF;
END;
/

-- Verificar si existe la tabla INSTITUCION_CAPACIDAD
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count 
  FROM USER_TABLES 
  WHERE TABLE_NAME = 'INSTITUCION_CAPACIDAD';
  
  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Creando tabla INSTITUCION_CAPACIDAD...');
    EXECUTE IMMEDIATE '
      CREATE TABLE INSTITUCION_CAPACIDAD (
        INSTITUCION_ID INTEGER PRIMARY KEY,
        TOTAL_AULAS NUMBER DEFAULT 0,
        CAPACIDAD_POR_AULA NUMBER DEFAULT 40,
        DOCENTES_DISPONIBLES NUMBER DEFAULT 0
      )';
    -- Intentar crear foreign key si existe la tabla INSTITUCIONES
    BEGIN
      EXECUTE IMMEDIATE '
        ALTER TABLE INSTITUCION_CAPACIDAD 
        ADD CONSTRAINT FK_CAP_ID_INST 
        FOREIGN KEY (INSTITUCION_ID) REFERENCES INSTITUCIONES(INSTITUCION_ID)';
      DBMS_OUTPUT.PUT_LINE('✓ Foreign key agregada a INSTITUCION_CAPACIDAD');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠ No se pudo crear foreign key (tabla INSTITUCIONES no existe)');
    END;
    DBMS_OUTPUT.PUT_LINE('✓ Tabla INSTITUCION_CAPACIDAD creada exitosamente');
  ELSE
    DBMS_OUTPUT.PUT_LINE('✓ Tabla INSTITUCION_CAPACIDAD ya existe');
  END IF;
END;
/

-- ====================================================================
-- PASO 2: Nota sobre tipo VARRAY
-- ====================================================================

PROMPT
PROMPT === PASO 2: Información sobre tipo VARRAY ===

PROMPT ✓ El tipo VARRAY proy_sem_t será creado automáticamente por el package
PROMPT ✓ Se dimensionará dinámicamente basado en la duración máxima de carreras
PROMPT ✓ Si no existe tabla carreras, usará un tamaño por defecto de 50

-- ====================================================================
-- PASO 3: Eliminar versiones anteriores del package si existen
-- ====================================================================

PROMPT
PROMPT === PASO 3: Limpiando versiones anteriores ===

DECLARE
  v_count NUMBER;
BEGIN
  -- Verificar si existe el package body
  SELECT COUNT(*) INTO v_count 
  FROM USER_OBJECTS 
  WHERE OBJECT_NAME = 'PKG_PROYECCION_RECURSOS' 
    AND OBJECT_TYPE = 'PACKAGE BODY';
  
  IF v_count > 0 THEN
    DBMS_OUTPUT.PUT_LINE('Eliminando package body anterior...');
    EXECUTE IMMEDIATE 'DROP PACKAGE BODY PKG_PROYECCION_RECURSOS';
    DBMS_OUTPUT.PUT_LINE('✓ Package body anterior eliminado');
  END IF;
  
  -- Verificar si existe la especificación del package
  SELECT COUNT(*) INTO v_count 
  FROM USER_OBJECTS 
  WHERE OBJECT_NAME = 'PKG_PROYECCION_RECURSOS' 
    AND OBJECT_TYPE = 'PACKAGE';
  
  IF v_count > 0 THEN
    DBMS_OUTPUT.PUT_LINE('Eliminando especificación de package anterior...');
    EXECUTE IMMEDIATE 'DROP PACKAGE PKG_PROYECCION_RECURSOS';
    DBMS_OUTPUT.PUT_LINE('✓ Especificación anterior eliminada');
  END IF;
END;
/

-- ====================================================================
-- PASO 4: Crear especificación del package
-- ====================================================================

PROMPT
PROMPT === PASO 4: Creando especificación del package ===

@@package_spec.sql

PROMPT ✓ Especificación del package creada exitosamente

-- ====================================================================
-- PASO 5: Crear cuerpo del package
-- ====================================================================

PROMPT
PROMPT === PASO 5: Creando cuerpo del package ===

@@package_body.sql

PROMPT ✓ Cuerpo del package creado exitosamente

-- ====================================================================
-- PASO 6: Verificar instalación
-- ====================================================================

PROMPT
PROMPT === PASO 6: Verificando instalación ===

DECLARE
  v_count NUMBER;
  v_status VARCHAR2(10);
BEGIN
  -- Verificar especificación
  SELECT COUNT(*), MAX(STATUS) INTO v_count, v_status
  FROM USER_OBJECTS 
  WHERE OBJECT_NAME = 'PKG_PROYECCION_RECURSOS' 
    AND OBJECT_TYPE = 'PACKAGE';
  
  IF v_count > 0 AND v_status = 'VALID' THEN
    DBMS_OUTPUT.PUT_LINE('✓ Especificación del package: VÁLIDA');
  ELSE
    DBMS_OUTPUT.PUT_LINE('✗ Especificación del package: ' || NVL(v_status, 'NO ENCONTRADA'));
  END IF;
  
  -- Verificar cuerpo
  SELECT COUNT(*), MAX(STATUS) INTO v_count, v_status
  FROM USER_OBJECTS 
  WHERE OBJECT_NAME = 'PKG_PROYECCION_RECURSOS' 
    AND OBJECT_TYPE = 'PACKAGE BODY';
  
  IF v_count > 0 AND v_status = 'VALID' THEN
    DBMS_OUTPUT.PUT_LINE('✓ Cuerpo del package: VÁLIDO');
  ELSE
    DBMS_OUTPUT.PUT_LINE('✗ Cuerpo del package: ' || NVL(v_status, 'NO ENCONTRADO'));
  END IF;
  
  -- Verificar tipo VARRAY
  SELECT COUNT(*) INTO v_count
  FROM USER_TYPES 
  WHERE TYPE_NAME = 'PROY_SEM_T';
  
  IF v_count > 0 THEN
    DBMS_OUTPUT.PUT_LINE('✓ Tipo VARRAY proy_sem_t: CREADO');
  ELSE
    DBMS_OUTPUT.PUT_LINE('⚠ Tipo VARRAY proy_sem_t: NO CREADO (se creará en la inicialización)');
  END IF;
END;
/

-- ====================================================================
-- PASO 7: Instalar trigger integrado
-- ====================================================================

PROMPT
PROMPT === PASO 7: Instalando trigger integrado ===

@@trigger_integrado.sql

-- ====================================================================
-- PASO 8: Prueba básica
-- ====================================================================

PROMPT
PROMPT === PASO 8: Ejecutando prueba básica ===

DECLARE
  v_stats VARCHAR2(1000);
BEGIN
  -- Obtener estadísticas del package
  v_stats := PKG_PROYECCION_RECURSOS.get_package_stats();
  DBMS_OUTPUT.PUT_LINE('Estadísticas: ' || v_stats);
  
  -- Probar función básica
  DECLARE
    v_result NUMBER;
    v_max_duracion NUMBER;
    v_varray_exists BOOLEAN;
  BEGIN
    v_result := PKG_PROYECCION_RECURSOS.profs_req(100, 30);
    DBMS_OUTPUT.PUT_LINE('✓ Prueba profs_req(100, 30): ' || v_result || ' profesores');
    
    v_result := PKG_PROYECCION_RECURSOS.classrooms_needed(100, 40);
    DBMS_OUTPUT.PUT_LINE('✓ Prueba classrooms_needed(100, 40): ' || v_result || ' aulas');
    
    -- Probar funciones de VARRAY
    v_max_duracion := PKG_PROYECCION_RECURSOS.get_max_duracion_carreras();
    DBMS_OUTPUT.PUT_LINE('✓ Duración máxima de carreras: ' || v_max_duracion || ' semestres');
    
    v_varray_exists := PKG_PROYECCION_RECURSOS.verificar_varray_existente();
    DBMS_OUTPUT.PUT_LINE('✓ VARRAY proy_sem_t existe: ' || CASE WHEN v_varray_exists THEN 'SÍ' ELSE 'NO' END);
    
    -- Si no existe, intentar crearlo
    IF NOT v_varray_exists THEN
      PKG_PROYECCION_RECURSOS.crear_varray_dinamico();
      DBMS_OUTPUT.PUT_LINE('✓ VARRAY proy_sem_t creado dinámicamente');
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('✗ Error en pruebas básicas: ' || SQLERRM);
  END;
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('✗ Error en prueba del package: ' || SQLERRM);
END;
/

PROMPT
PROMPT ======================================================================
PROMPT Instalación del Package PKG_PROYECCION_RECURSOS COMPLETADA
PROMPT ======================================================================
PROMPT
PROMPT Para usar el package:
PROMPT 1. Ejecutar proyecciones: PKG_PROYECCION_RECURSOS.build_plan_recursos(4);
PROMPT 2. Ver estadísticas: SELECT PKG_PROYECCION_RECURSOS.get_package_stats() FROM DUAL;
PROMPT 3. Generar reporte: PKG_PROYECCION_RECURSOS.generar_reporte_capacidad();
PROMPT 4. Limpiar datos antiguos: PKG_PROYECCION_RECURSOS.limpiar_planes_antiguos(30);
PROMPT
PROMPT Tablas principales:
PROMPT - PLANES_RECURSOS: Resultados de las proyecciones
PROMPT - ERROR_LOG: Log de errores y eventos
PROMPT - INSTITUCION_CAPACIDAD: Configuración de capacidades
PROMPT ======================================================================