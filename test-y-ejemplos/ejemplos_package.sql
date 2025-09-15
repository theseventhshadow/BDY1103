-- ======================================================================
-- EJEMPLOS DE USO DEL PACKAGE PKG_PROYECCION_RECURSOS
-- ======================================================================
-- Ejemplos prácticos de cómo usar las funciones y procedimientos del package
-- ======================================================================

SET SERVEROUTPUT ON
SET PAGESIZE 50
SET LINESIZE 120

PROMPT ======================================================================
PROMPT EJEMPLOS DE USO: PKG_PROYECCION_RECURSOS
PROMPT ======================================================================

-- ====================================================================
-- EJEMPLO 1: Verificar estado del package
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 1: Estado del Package ===

SELECT PKG_PROYECCION_RECURSOS.get_package_stats() AS package_stats FROM DUAL;

-- ====================================================================
-- EJEMPLO 2: Funciones básicas de cálculo
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 2: Funciones básicas de cálculo ===

SELECT 
  'Para 150 estudiantes:' AS escenario,
  PKG_PROYECCION_RECURSOS.profs_req(150) AS profesores_default,
  PKG_PROYECCION_RECURSOS.profs_req(150, 25) AS profesores_ratio_25,
  PKG_PROYECCION_RECURSOS.classrooms_needed(150) AS aulas_default,
  PKG_PROYECCION_RECURSOS.classrooms_needed(150, 30) AS aulas_capacidad_30
FROM DUAL
UNION ALL
SELECT 
  'Para 75 estudiantes:' AS escenario,
  PKG_PROYECCION_RECURSOS.profs_req(75) AS profesores_default,
  PKG_PROYECCION_RECURSOS.profs_req(75, 20) AS profesores_ratio_20,
  PKG_PROYECCION_RECURSOS.classrooms_needed(75) AS aulas_default,
  PKG_PROYECCION_RECURSOS.classrooms_needed(75, 25) AS aulas_capacidad_25
FROM DUAL;

-- ====================================================================
-- EJEMPLO 3: Proyección para una institución y carrera específica
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 3: Proyección específica ===

-- Nota: Estos valores deben existir en tu base de datos
-- Ajusta los IDs según tus datos reales

DECLARE
  v_proyeccion proy_sem_t;
  v_institucion_id INTEGER := 1; -- Ajustar según tus datos
  v_carrera_id INTEGER := 1;     -- Ajustar según tus datos
BEGIN
  DBMS_OUTPUT.PUT_LINE('Proyección para Institución ' || v_institucion_id || ', Carrera ' || v_carrera_id || ':');
  
  BEGIN
    v_proyeccion := PKG_PROYECCION_RECURSOS.proyeccion_estudiantes_para_prox_semestres(
      v_institucion_id, 
      v_carrera_id, 
      6  -- Próximos 6 semestres
    );
    
    IF v_proyeccion IS NOT NULL AND v_proyeccion.COUNT > 0 THEN
      FOR i IN 1..v_proyeccion.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('  Semestre ' || i || ': ' || v_proyeccion(i) || ' estudiantes, ' ||
                           PKG_PROYECCION_RECURSOS.profs_req(v_proyeccion(i)) || ' profesores, ' ||
                           PKG_PROYECCION_RECURSOS.classrooms_needed(v_proyeccion(i)) || ' aulas');
      END LOOP;
    ELSE
      DBMS_OUTPUT.PUT_LINE('  Sin proyección disponible (sin datos históricos)');
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  Error: ' || SQLERRM);
  END;
END;
/

-- ====================================================================
-- EJEMPLO 4: Validación de existencia de entidades
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 4: Validación de existencias ===

DECLARE
  v_inst_exists BOOLEAN;
  v_carrera_exists BOOLEAN;
BEGIN
  -- Probar con IDs que probablemente existan
  FOR i IN 1..3 LOOP
    v_inst_exists := PKG_PROYECCION_RECURSOS.institucion_exists(i);
    v_carrera_exists := PKG_PROYECCION_RECURSOS.carrera_exists(i);
    
    DBMS_OUTPUT.PUT_LINE('ID ' || i || ' - Institución: ' || 
                        CASE WHEN v_inst_exists THEN 'EXISTE' ELSE 'NO EXISTE' END ||
                        ', Carrera: ' || 
                        CASE WHEN v_carrera_exists THEN 'EXISTE' ELSE 'NO EXISTE' END);
  END LOOP;
END;
/

-- ====================================================================
-- EJEMPLO 5: Obtener capacidad de instituciones
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 5: Capacidades institucionales ===

DECLARE
  v_capacidad_aula NUMBER;
  v_salas_disp NUMBER;
  v_success BOOLEAN;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Capacidades por institución:');
  
  FOR i IN 1..3 LOOP
    v_success := PKG_PROYECCION_RECURSOS.get_institucion_capacity(
      i, v_capacidad_aula, v_salas_disp
    );
    
    IF v_success THEN
      DBMS_OUTPUT.PUT_LINE('  Institución ' || i || ': ' || v_salas_disp || 
                          ' aulas de ' || v_capacidad_aula || ' estudiantes c/u = ' ||
                          (v_salas_disp * v_capacidad_aula) || ' capacidad total');
    ELSE
      DBMS_OUTPUT.PUT_LINE('  Institución ' || i || ': Error obteniendo capacidad');
    END IF;
  END LOOP;
END;
/

-- ====================================================================
-- EJEMPLO 6: Generar plan completo de recursos
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 6: Generar plan de recursos ===

BEGIN
  DBMS_OUTPUT.PUT_LINE('Generando plan de recursos para los próximos 4 semestres...');
  
  -- Limpiar planes anteriores primero
  PKG_PROYECCION_RECURSOS.limpiar_planes_antiguos(7);
  
  -- Generar nuevo plan (esto puede tomar tiempo dependiendo del volumen de datos)
  PKG_PROYECCION_RECURSOS.build_plan_recursos(
    p_next_n => 4,           -- 4 semestres
    p_institucion_id => NULL, -- Todas las instituciones
    p_carrera_id => NULL,     -- Todas las carreras
    p_region_id => NULL       -- Todas las regiones
  );
  
  DBMS_OUTPUT.PUT_LINE('Plan generado exitosamente.');
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error generando plan: ' || SQLERRM);
END;
/

-- ====================================================================
-- EJEMPLO 7: Consultar resultados del plan generado
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 7: Resultados del plan ===

-- Mostrar resumen por semestre
SELECT 
  SEMESTRE_LABEL,
  COUNT(*) AS combinaciones,
  SUM(ESTUDIANTES_PROYECTADOS) AS total_estudiantes,
  SUM(PROFERORES_REQUERIDOS) AS total_profesores,
  SUM(SALAS_REQUERIDAS) AS total_salas
FROM PLANES_RECURSOS 
WHERE CREATED_AT >= SYSDATE - 1  -- Planes del último día
GROUP BY SEMESTRE_LABEL
ORDER BY SEMESTRE_LABEL;

-- Mostrar top 10 instituciones con más estudiantes proyectados
PROMPT
PROMPT Top 10 instituciones con más estudiantes proyectados:

SELECT * FROM (
  SELECT 
    INSTITUCION_NOMBRE,
    SUM(ESTUDIANTES_PROYECTADOS) AS total_estudiantes_proyectados,
    SUM(PROFERORES_REQUERIDOS) AS total_profesores_req,
    SUM(SALAS_REQUERIDAS) AS total_salas_req
  FROM PLANES_RECURSOS 
  WHERE CREATED_AT >= SYSDATE - 1
  GROUP BY INSTITUCION_NOMBRE
  ORDER BY total_estudiantes_proyectados DESC
) WHERE ROWNUM <= 10;

-- ====================================================================
-- EJEMPLO 8: Usar función pipelined para consultas flexibles
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 8: Función pipelined ===

-- Obtener proyecciones como tabla (limitando resultados para el ejemplo)
SELECT * FROM (
  SELECT 
    institucion_nombre,
    carrera_nombre,
    semestre_label,
    estudiantes_proyectados,
    profesores_requeridos,
    salas_requeridas
  FROM TABLE(PKG_PROYECCION_RECURSOS.get_proyecciones_tabla(
    p_institucion_id => NULL,  -- Todas las instituciones
    p_carrera_id => NULL,      -- Todas las carreras  
    p_next_n => 2              -- Solo próximos 2 semestres
  ))
  ORDER BY estudiantes_proyectados DESC
) WHERE ROWNUM <= 15;

-- ====================================================================
-- EJEMPLO 9: Generar reporte de capacidad
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 9: Reporte de capacidad ===

BEGIN
  PKG_PROYECCION_RECURSOS.generar_reporte_capacidad(
    p_institucion_id => NULL,    -- Todas las instituciones
    p_mostrar_detalles => TRUE
  );
END;
/

-- ====================================================================
-- EJEMPLO 10: Logging y estadísticas finales
-- ====================================================================

PROMPT
PROMPT === EJEMPLO 10: Log de eventos y estadísticas ===

-- Ver últimos eventos de log
SELECT 
  TO_CHAR(CREATED_AT, 'DD/MM/YYYY HH24:MI:SS') AS fecha,
  SEVERITY,
  SOURCE_OBJ,
  SUBSTR(ERROR_MSG, 1, 80) AS mensaje
FROM ERROR_LOG 
WHERE CREATED_AT >= SYSDATE - 1
ORDER BY CREATED_AT DESC
FETCH FIRST 10 ROWS ONLY;

-- Estadísticas finales del package
SELECT PKG_PROYECCION_RECURSOS.get_package_stats() AS estadisticas_finales FROM DUAL;

-- Resumen de tablas principales
PROMPT
PROMPT Resumen de registros en tablas principales:
SELECT 'PLANES_RECURSOS' AS tabla, COUNT(*) AS registros FROM PLANES_RECURSOS
UNION ALL
SELECT 'ERROR_LOG' AS tabla, COUNT(*) AS registros FROM ERROR_LOG
UNION ALL  
SELECT 'INSTITUCION_CAPACIDAD' AS tabla, COUNT(*) AS registros FROM INSTITUCION_CAPACIDAD;

PROMPT
PROMPT ======================================================================
PROMPT EJEMPLOS COMPLETADOS
PROMPT ======================================================================
PROMPT
PROMPT Notas importantes:
PROMPT 1. Ajusta los IDs de institución y carrera según tus datos reales
PROMPT 2. El package maneja automáticamente casos sin datos históricos
PROMPT 3. Revisa la tabla ERROR_LOG para diagnósticos detallados
PROMPT 4. Usa limpiar_planes_antiguos() regularmente para mantener limpia la BD
PROMPT ======================================================================