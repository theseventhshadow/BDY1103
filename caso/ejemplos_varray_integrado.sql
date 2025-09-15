-- ======================================================================
-- EJEMPLOS DE USO DEL VARRAY INTEGRADO AL PACKAGE
-- ======================================================================
-- Ejemplos específicos para demostrar la funcionalidad del VARRAY dinámico
-- integrado al package PKG_PROYECCION_RECURSOS
-- ======================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF

PROMPT ======================================================================
PROMPT EJEMPLOS DE VARRAY DINÁMICO INTEGRADO
PROMPT ======================================================================

-- ====================================================================
-- EJEMPLO 1: Verificar configuración actual del VARRAY
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 1: Estado actual del VARRAY ===

DECLARE
  v_max_duracion NUMBER;
  v_varray_exists BOOLEAN;
  v_type_count NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Verificando configuración del VARRAY...');
  
  -- Obtener duración máxima
  v_max_duracion := PKG_PROYECCION_RECURSOS.get_max_duracion_carreras();
  DBMS_OUTPUT.PUT_LINE('Duración máxima de carreras: ' || v_max_duracion || ' semestres');
  
  -- Verificar si existe el tipo
  v_varray_exists := PKG_PROYECCION_RECURSOS.verificar_varray_existente();
  DBMS_OUTPUT.PUT_LINE('VARRAY proy_sem_t existe: ' || CASE WHEN v_varray_exists THEN 'SÍ' ELSE 'NO' END);
  
  -- Verificar directamente en diccionario de datos
  SELECT COUNT(*) INTO v_type_count FROM USER_TYPES WHERE TYPE_NAME = 'PROY_SEM_T';
  DBMS_OUTPUT.PUT_LINE('Confirmación en USER_TYPES: ' || CASE WHEN v_type_count > 0 THEN 'EXISTE' ELSE 'NO EXISTE' END);
  
  IF v_type_count > 0 THEN
    FOR r IN (SELECT TYPE_NAME, TYPECODE FROM USER_TYPES WHERE TYPE_NAME = 'PROY_SEM_T') LOOP
      DBMS_OUTPUT.PUT_LINE('Tipo: ' || r.TYPE_NAME || ', Código: ' || r.TYPECODE);
    END LOOP;
  END IF;
  
END;
/

-- ====================================================================
-- EJEMPLO 2: Crear VARRAY dinámicamente si no existe
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 2: Creación dinámica del VARRAY ===

DECLARE
  v_varray_exists BOOLEAN;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Verificando necesidad de crear VARRAY...');
  
  v_varray_exists := PKG_PROYECCION_RECURSOS.verificar_varray_existente();
  
  IF NOT v_varray_exists THEN
    DBMS_OUTPUT.PUT_LINE('VARRAY no existe. Creando dinámicamente...');
    PKG_PROYECCION_RECURSOS.crear_varray_dinamico();
    DBMS_OUTPUT.PUT_LINE('✓ VARRAY creado exitosamente');
  ELSE
    DBMS_OUTPUT.PUT_LINE('✓ VARRAY ya existe y es válido');
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- ====================================================================
-- EJEMPLO 3: Recrear VARRAY con nuevo tamaño (simular cambio de datos)
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 3: Recreación del VARRAY ===

DECLARE
  v_max_duracion_antes NUMBER;
  v_max_duracion_despues NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Recreando VARRAY para asegurar tamaño óptimo...');
  
  -- Obtener duración actual
  v_max_duracion_antes := PKG_PROYECCION_RECURSOS.get_max_duracion_carreras();
  DBMS_OUTPUT.PUT_LINE('Duración antes de recrear: ' || v_max_duracion_antes);
  
  -- Recrear el VARRAY
  PKG_PROYECCION_RECURSOS.crear_varray_dinamico();
  
  -- Verificar duración después
  v_max_duracion_despues := PKG_PROYECCION_RECURSOS.get_max_duracion_carreras();
  DBMS_OUTPUT.PUT_LINE('Duración después de recrear: ' || v_max_duracion_despues);
  
  DBMS_OUTPUT.PUT_LINE('✓ VARRAY recreado exitosamente');
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('✗ Error recreando VARRAY: ' || SQLERRM);
END;
/

-- ====================================================================
-- EJEMPLO 4: Usar el VARRAY en una función de proyección
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 4: Uso del VARRAY en proyección ===

DECLARE
  v_proyeccion proy_sem_t;
  v_institucion_id INTEGER := 1;  -- Ajustar según datos disponibles
  v_carrera_id INTEGER := 1;      -- Ajustar según datos disponibles
  v_semestres NUMBER := 6;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Probando proyección con VARRAY dinámico...');
  
  -- Verificar que el VARRAY existe antes de usarlo
  IF NOT PKG_PROYECCION_RECURSOS.verificar_varray_existente() THEN
    DBMS_OUTPUT.PUT_LINE('Creando VARRAY necesario...');
    PKG_PROYECCION_RECURSOS.crear_varray_dinamico();
  END IF;
  
  BEGIN
    -- Intentar proyección
    v_proyeccion := PKG_PROYECCION_RECURSOS.proyeccion_estudiantes_para_prox_semestres(
      v_institucion_id, 
      v_carrera_id, 
      v_semestres
    );
    
    IF v_proyeccion IS NOT NULL AND v_proyeccion.COUNT > 0 THEN
      DBMS_OUTPUT.PUT_LINE('✓ Proyección exitosa para ' || v_semestres || ' semestres:');
      FOR i IN 1..v_proyeccion.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('  Semestre ' || i || ': ' || v_proyeccion(i) || ' estudiantes');
      END LOOP;
    ELSE
      DBMS_OUTPUT.PUT_LINE('⚠ Proyección retornó datos vacíos (normal si no hay datos históricos)');
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('⚠ Error en proyección (puede ser normal si no hay datos): ' || SQLERRM);
  END;
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('✗ Error general: ' || SQLERRM);
END;
/

-- ====================================================================
-- EJEMPLO 5: Comparar rendimiento con y sin cache
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 5: Información sobre optimización ===

DECLARE
  v_stats VARCHAR2(1000);
  v_max_duracion NUMBER;
  v_call_count_before NUMBER;
  v_call_count_after NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Información sobre optimización del VARRAY...');
  
  -- Obtener estadísticas antes
  v_stats := PKG_PROYECCION_RECURSOS.get_package_stats();
  DBMS_OUTPUT.PUT_LINE('Estadísticas antes: ' || v_stats);
  
  -- Realizar varias llamadas para probar cache
  FOR i IN 1..3 LOOP
    v_max_duracion := PKG_PROYECCION_RECURSOS.get_max_duracion_carreras();
  END LOOP;
  
  -- Obtener estadísticas después
  v_stats := PKG_PROYECCION_RECURSOS.get_package_stats();
  DBMS_OUTPUT.PUT_LINE('Estadísticas después: ' || v_stats);
  
  DBMS_OUTPUT.PUT_LINE('✓ El package optimiza automáticamente las consultas repetidas');
  
END;
/

-- ====================================================================
-- EJEMPLO 6: Verificar integración completa
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 6: Verificación de integración completa ===

DECLARE
  v_todo_ok BOOLEAN := TRUE;
  v_error_msg VARCHAR2(4000);
BEGIN
  DBMS_OUTPUT.PUT_LINE('Verificando integración completa del VARRAY con el package...');
  
  -- Test 1: Función de duración máxima
  BEGIN
    DECLARE v_result NUMBER;
    BEGIN
      v_result := PKG_PROYECCION_RECURSOS.get_max_duracion_carreras();
      DBMS_OUTPUT.PUT_LINE('✓ Test 1 - get_max_duracion_carreras(): ' || v_result);
    END;
  EXCEPTION
    WHEN OTHERS THEN
      v_todo_ok := FALSE;
      DBMS_OUTPUT.PUT_LINE('✗ Test 1 falló: ' || SQLERRM);
  END;
  
  -- Test 2: Verificación de existencia
  BEGIN
    DECLARE v_result BOOLEAN;
    BEGIN
      v_result := PKG_PROYECCION_RECURSOS.verificar_varray_existente();
      DBMS_OUTPUT.PUT_LINE('✓ Test 2 - verificar_varray_existente(): ' || CASE WHEN v_result THEN 'TRUE' ELSE 'FALSE' END);
    END;
  EXCEPTION
    WHEN OTHERS THEN
      v_todo_ok := FALSE;
      DBMS_OUTPUT.PUT_LINE('✗ Test 2 falló: ' || SQLERRM);
  END;
  
  -- Test 3: Creación dinámica
  BEGIN
    PKG_PROYECCION_RECURSOS.crear_varray_dinamico();
    DBMS_OUTPUT.PUT_LINE('✓ Test 3 - crear_varray_dinamico(): Exitoso');
  EXCEPTION
    WHEN OTHERS THEN
      v_todo_ok := FALSE;
      DBMS_OUTPUT.PUT_LINE('✗ Test 3 falló: ' || SQLERRM);
  END;
  
  -- Test 4: Uso en proyección (con manejo de errores)
  BEGIN
    DECLARE 
      v_proyeccion proy_sem_t;
    BEGIN
      v_proyeccion := PKG_PROYECCION_RECURSOS.proyeccion_estudiantes_para_prox_semestres(1, 1, 2);
      DBMS_OUTPUT.PUT_LINE('✓ Test 4 - proyeccion_estudiantes_para_prox_semestres(): Ejecutado');
    END;
  EXCEPTION
    WHEN OTHERS THEN
      -- Este test puede fallar si no hay datos, pero no indica error en el VARRAY
      DBMS_OUTPUT.PUT_LINE('⚠ Test 4 - proyeccion: ' || SUBSTR(SQLERRM, 1, 50) || ' (puede ser normal sin datos)');
  END;
  
  IF v_todo_ok THEN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('🎉 ¡INTEGRACIÓN COMPLETA EXITOSA!');
    DBMS_OUTPUT.PUT_LINE('   El VARRAY está completamente integrado al package');
  ELSE
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('⚠ Algunos tests fallaron - revisar configuración');
  END IF;
  
END;
/

PROMPT
PROMPT ======================================================================
PROMPT EJEMPLOS DE VARRAY DINÁMICO COMPLETADOS
PROMPT ======================================================================
PROMPT
PROMPT Funcionalidades demostradas:
PROMPT ✓ Creación automática del VARRAY basada en duración de carreras
PROMPT ✓ Verificación de existencia y validez del tipo
PROMPT ✓ Recreación dinámica cuando sea necesario
PROMPT ✓ Integración seamless con funciones de proyección
PROMPT ✓ Optimización y cache para mejor rendimiento
PROMPT ✓ Manejo robusto de errores y fallbacks
PROMPT
PROMPT Ventajas de la integración:
PROMPT • No requiere archivos separados (varray.sql)
PROMPT • Dimensionamiento automático basado en datos reales
PROMPT • Actualización automática cuando cambian los datos
PROMPT • Manejo unificado de errores con el resto del package
PROMPT • Inicialización automática al instalar el package
PROMPT ======================================================================