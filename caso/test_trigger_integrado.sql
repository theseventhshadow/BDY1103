-- ======================================================================
-- PRUEBAS DEL TRIGGER INTEGRADO CON PACKAGE
-- ======================================================================
-- Pruebas para verificar el funcionamiento del trigger que usa el package
-- PKG_PROYECCION_RECURSOS para verificación de capacidad
-- ======================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF

PROMPT ======================================================================
PROMPT PRUEBAS DEL TRIGGER INTEGRADO
PROMPT ======================================================================

-- ====================================================================
-- PREPARACIÓN: Configurar datos de prueba
-- ====================================================================

PROMPT
PROMPT === Configurando datos de prueba ===

-- Asegurar que existe al menos una institución y carrera para pruebas
DECLARE
  v_inst_count NUMBER;
  v_carrera_count NUMBER;
BEGIN
  -- Verificar instituciones
  SELECT COUNT(*) INTO v_inst_count FROM INSTITUCIONES WHERE ROWNUM = 1;
  IF v_inst_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('⚠ No hay instituciones en la base de datos');
    DBMS_OUTPUT.PUT_LINE('  Creando institución de prueba...');
    INSERT INTO INSTITUCIONES (INSTITUCION_ID, INSTITUCION_NOMBRE, REGION_ID)
    VALUES (9999, 'INSTITUCIÓN PRUEBA TRIGGER', 1);
  END IF;
  
  -- Verificar carreras
  SELECT COUNT(*) INTO v_carrera_count FROM CARRERAS WHERE ROWNUM = 1;
  IF v_carrera_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('⚠ No hay carreras en la base de datos');
    DBMS_OUTPUT.PUT_LINE('  Creando carrera de prueba...');
    INSERT INTO CARRERAS (CARRERA_ID, CARRERA_NOMBRE, DURACION_TOTAL)
    VALUES (9999, 'CARRERA PRUEBA TRIGGER', 8);
  END IF;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✓ Datos de prueba configurados');
END;
/

-- Configurar capacidad muy limitada para la institución de prueba
MERGE INTO INSTITUCION_CAPACIDAD ic
USING (SELECT 9999 as inst_id FROM DUAL) src
ON (ic.INSTITUCION_ID = src.inst_id)
WHEN MATCHED THEN
  UPDATE SET 
    TOTAL_AULAS = 1,           -- Solo 1 aula
    CAPACIDAD_POR_AULA = 2,    -- Solo 2 estudiantes por aula
    DOCENTES_DISPONIBLES = 1
WHEN NOT MATCHED THEN
  INSERT (INSTITUCION_ID, TOTAL_AULAS, CAPACIDAD_POR_AULA, DOCENTES_DISPONIBLES)
  VALUES (9999, 1, 2, 1);

COMMIT;

PROMPT ✓ Capacidad limitada configurada para pruebas (1 aula, 2 estudiantes máximo)

-- ====================================================================
-- PRUEBA 1: Inserción exitosa (dentro de capacidad)
-- ====================================================================

PROMPT
PROMPT === PRUEBA 1: Inserción dentro de capacidad ===

DECLARE
  v_error_occurred BOOLEAN := FALSE;
  v_matricula_id NUMBER;
BEGIN
  -- Generar ID único para la matrícula
  SELECT NVL(MAX(MATRICULA_ID), 0) + 1 INTO v_matricula_id FROM MATRICULAS;
  
  -- Intentar insertar primera matrícula (debería ser exitosa)
  INSERT INTO MATRICULAS (
    MATRICULA_ID, GENERO_ID, EDAD, RANGO_EDAD_ID,
    ANIO_INGRESO, SEMESTRE_INGRESO,
    INSTITUCION_ID, CARRERA_ID, VIA_INGRESO_ID, COMUNA_ID
  ) VALUES (
    v_matricula_id, 1, 20, 1,
    2024, 1,
    9999, 9999, 1, 1
  );
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 1 EXITOSA: Primera matrícula insertada correctamente');
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('✗ PRUEBA 1 FALLÓ: ' || SQLERRM);
    v_error_occurred := TRUE;
END;
/

-- ====================================================================
-- PRUEBA 2: Segunda inserción exitosa (llegar al límite)
-- ====================================================================

PROMPT
PROMPT === PRUEBA 2: Segunda inserción (límite de capacidad) ===

DECLARE
  v_error_occurred BOOLEAN := FALSE;
  v_matricula_id NUMBER;
BEGIN
  -- Generar ID único para la matrícula
  SELECT NVL(MAX(MATRICULA_ID), 0) + 1 INTO v_matricula_id FROM MATRICULAS;
  
  -- Intentar insertar segunda matrícula (debería ser exitosa, llegando al límite)
  INSERT INTO MATRICULAS (
    MATRICULA_ID, GENERO_ID, EDAD, RANGO_EDAD_ID,
    ANIO_INGRESO, SEMESTRE_INGRESO,
    INSTITUCION_ID, CARRERA_ID, VIA_INGRESO_ID, COMUNA_ID
  ) VALUES (
    v_matricula_id, 2, 21, 1,
    2024, 1,
    9999, 9999, 1, 1
  );
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 2 EXITOSA: Segunda matrícula insertada (capacidad al límite)');
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('✗ PRUEBA 2 FALLÓ: ' || SQLERRM);
    v_error_occurred := TRUE;
END;
/

-- ====================================================================
-- PRUEBA 3: Inserción que excede capacidad (debe fallar)
-- ====================================================================

PROMPT
PROMPT === PRUEBA 3: Inserción que excede capacidad (debe fallar) ===

DECLARE
  v_error_occurred BOOLEAN := FALSE;
  v_matricula_id NUMBER;
BEGIN
  -- Generar ID único para la matrícula
  SELECT NVL(MAX(MATRICULA_ID), 0) + 1 INTO v_matricula_id FROM MATRICULAS;
  
  -- Intentar insertar tercera matrícula (DEBE FALLAR por capacidad excedida)
  INSERT INTO MATRICULAS (
    MATRICULA_ID, GENERO_ID, EDAD, RANGO_EDAD_ID,
    ANIO_INGRESO, SEMESTRE_INGRESO,
    INSTITUCION_ID, CARRERA_ID, VIA_INGRESO_ID, COMUNA_ID
  ) VALUES (
    v_matricula_id, 1, 22, 1,
    2024, 1,
    9999, 9999, 1, 1
  );
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✗ PRUEBA 3 FALLÓ: La inserción debería haber sido rechazada por capacidad');
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    IF SQLCODE = -20020 THEN
      DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 3 EXITOSA: Inserción correctamente rechazada por capacidad excedida');
      DBMS_OUTPUT.PUT_LINE('  Mensaje: ' || SUBSTR(SQLERRM, 1, 100) || '...');
    ELSE
      DBMS_OUTPUT.PUT_LINE('✗ PRUEBA 3 FALLÓ: Error inesperado - ' || SQLERRM);
    END IF;
END;
/

-- ====================================================================
-- PRUEBA 4: Inserción con institución inexistente (debe fallar)
-- ====================================================================

PROMPT
PROMPT === PRUEBA 4: Institución inexistente (debe fallar) ===

DECLARE
  v_error_occurred BOOLEAN := FALSE;
  v_matricula_id NUMBER;
BEGIN
  -- Generar ID único para la matrícula
  SELECT NVL(MAX(MATRICULA_ID), 0) + 1 INTO v_matricula_id FROM MATRICULAS;
  
  -- Intentar insertar con institución inexistente
  INSERT INTO MATRICULAS (
    MATRICULA_ID, GENERO_ID, EDAD, RANGO_EDAD_ID,
    ANIO_INGRESO, SEMESTRE_INGRESO,
    INSTITUCION_ID, CARRERA_ID, VIA_INGRESO_ID, COMUNA_ID
  ) VALUES (
    v_matricula_id, 1, 20, 1,
    2024, 1,
    99999, 9999, 1, 1  -- Institución inexistente
  );
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✗ PRUEBA 4 FALLÓ: La inserción debería haber sido rechazada por institución inexistente');
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    IF SQLCODE = -20022 THEN
      DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 4 EXITOSA: Inserción correctamente rechazada por institución inexistente');
    ELSE
      DBMS_OUTPUT.PUT_LINE('✗ PRUEBA 4 FALLÓ: Error inesperado - ' || SQLERRM);
    END IF;
END;
/

-- ====================================================================
-- PRUEBA 5: Inserción con carrera inexistente (debe fallar)
-- ====================================================================

PROMPT
PROMPT === PRUEBA 5: Carrera inexistente (debe fallar) ===

DECLARE
  v_error_occurred BOOLEAN := FALSE;
  v_matricula_id NUMBER;
BEGIN
  -- Generar ID único para la matrícula
  SELECT NVL(MAX(MATRICULA_ID), 0) + 1 INTO v_matricula_id FROM MATRICULAS;
  
  -- Intentar insertar con carrera inexistente
  INSERT INTO MATRICULAS (
    MATRICULA_ID, GENERO_ID, EDAD, RANGO_EDAD_ID,
    ANIO_INGRESO, SEMESTRE_INGRESO,
    INSTITUCION_ID, CARRERA_ID, VIA_INGRESO_ID, COMUNA_ID
  ) VALUES (
    v_matricula_id, 1, 20, 1,
    2024, 1,
    9999, 99999, 1, 1  -- Carrera inexistente
  );
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✗ PRUEBA 5 FALLÓ: La inserción debería haber sido rechazada por carrera inexistente');
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    IF SQLCODE = -20023 THEN
      DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 5 EXITOSA: Inserción correctamente rechazada por carrera inexistente');
    ELSE
      DBMS_OUTPUT.PUT_LINE('✗ PRUEBA 5 FALLÓ: Error inesperado - ' || SQLERRM);
    END IF;
END;
/

-- ====================================================================
-- PRUEBA 6: Datos inválidos (debe fallar)
-- ====================================================================

PROMPT
PROMPT === PRUEBA 6: Datos inválidos (debe fallar) ===

DECLARE
  v_error_occurred BOOLEAN := FALSE;
  v_matricula_id NUMBER;
BEGIN
  -- Generar ID único para la matrícula
  SELECT NVL(MAX(MATRICULA_ID), 0) + 1 INTO v_matricula_id FROM MATRICULAS;
  
  -- Intentar insertar con semestre inválido
  INSERT INTO MATRICULAS (
    MATRICULA_ID, GENERO_ID, EDAD, RANGO_EDAD_ID,
    ANIO_INGRESO, SEMESTRE_INGRESO,
    INSTITUCION_ID, CARRERA_ID, VIA_INGRESO_ID, COMUNA_ID
  ) VALUES (
    v_matricula_id, 1, 20, 1,
    2024, 3,  -- Semestre inválido (solo 1 o 2)
    9999, 9999, 1, 1
  );
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✗ PRUEBA 6 FALLÓ: La inserción debería haber sido rechazada por semestre inválido');
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    IF SQLCODE = -20021 THEN
      DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 6 EXITOSA: Inserción correctamente rechazada por datos inválidos');
    ELSE
      DBMS_OUTPUT.PUT_LINE('✗ PRUEBA 6 FALLÓ: Error inesperado - ' || SQLERRM);
    END IF;
END;
/

-- ====================================================================
-- VERIFICACIÓN DE LOGS
-- ====================================================================

PROMPT
PROMPT === Verificación de logs generados ===

-- Mostrar logs generados durante las pruebas
SELECT 
  TO_CHAR(CREATED_AT, 'HH24:MI:SS') AS hora,
  SEVERITY,
  SOURCE_OBJ,
  SUBSTR(ERROR_MSG, 1, 100) AS mensaje
FROM ERROR_LOG 
WHERE CREATED_AT >= SYSDATE - 1/24  -- Última hora
  AND SOURCE_OBJ = 'verificar_capacidad_matricula'
ORDER BY CREATED_AT DESC
FETCH FIRST 10 ROWS ONLY;

-- Mostrar estadísticas del package
SELECT PKG_PROYECCION_RECURSOS.get_package_stats() AS estadisticas FROM DUAL;

-- ====================================================================
-- VERIFICACIÓN DE MATRICULAS INSERTADAS
-- ====================================================================

PROMPT
PROMPT === Verificación de matrículas insertadas ===

SELECT 
  MATRICULA_ID,
  INSTITUCION_ID,
  CARRERA_ID,
  ANIO_INGRESO,
  SEMESTRE_INGRESO,
  'Insertada en pruebas' AS comentario
FROM MATRICULAS 
WHERE INSTITUCION_ID = 9999 
  AND CARRERA_ID = 9999
ORDER BY MATRICULA_ID;

-- ====================================================================
-- LIMPIEZA (OPCIONAL)
-- ====================================================================

PROMPT
PROMPT === Limpieza de datos de prueba ===

BEGIN
  -- Eliminar matrículas de prueba
  DELETE FROM MATRICULAS 
  WHERE INSTITUCION_ID = 9999 AND CARRERA_ID = 9999;
  
  -- Eliminar configuración de capacidad de prueba
  DELETE FROM INSTITUCION_CAPACIDAD 
  WHERE INSTITUCION_ID = 9999;
  
  -- Eliminar datos maestros de prueba si se crearon
  DELETE FROM INSTITUCIONES WHERE INSTITUCION_ID = 9999;
  DELETE FROM CARRERAS WHERE CARRERA_ID = 9999;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✓ Datos de prueba eliminados');
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('⚠ Error eliminando datos de prueba: ' || SQLERRM);
END;
/

PROMPT
PROMPT ======================================================================
PROMPT PRUEBAS DEL TRIGGER INTEGRADO COMPLETADAS
PROMPT ======================================================================
PROMPT
PROMPT Resultados esperados:
PROMPT ✓ PRUEBA 1: Primera matrícula insertada exitosamente
PROMPT ✓ PRUEBA 2: Segunda matrícula insertada (límite alcanzado)
PROMPT ✓ PRUEBA 3: Tercera matrícula rechazada por capacidad excedida
PROMPT ✓ PRUEBA 4: Matrícula rechazada por institución inexistente
PROMPT ✓ PRUEBA 5: Matrícula rechazada por carrera inexistente
PROMPT ✓ PRUEBA 6: Matrícula rechazada por datos inválidos
PROMPT
PROMPT El trigger integrado con el package funciona correctamente si
PROMPT todas las pruebas muestran los resultados esperados.
PROMPT ======================================================================