-- ======================================================================
-- TRIGGER SIMPLIFICADO: trg_matriculas_check_capacidad
-- ======================================================================
-- Trigger que utiliza el package PKG_PROYECCION_RECURSOS para verificar
-- la capacidad antes de insertar una nueva matrícula
-- ======================================================================

CREATE OR REPLACE TRIGGER trg_matriculas_check_capacidad
BEFORE INSERT ON MATRICULAS
FOR EACH ROW
BEGIN
  -- Delegar toda la lógica al procedimiento del package
  PKG_PROYECCION_RECURSOS.verificar_capacidad_matricula(
    :NEW.INSTITUCION_ID,
    :NEW.CARRERA_ID,
    :NEW.ANIO_INGRESO,
    :NEW.SEMESTRE_INGRESO
  );
  
EXCEPTION
  WHEN OTHERS THEN
    -- Re-lanzar cualquier excepción que venga del package
    -- El package ya se encarga del logging detallado
    RAISE;
END;
/

-- Mostrar información del trigger creado
SELECT 
  trigger_name,
  status,
  trigger_type,
  triggering_event,
  table_name
FROM user_triggers 
WHERE trigger_name = 'TRG_MATRICULAS_CHECK_CAPACIDAD';

PROMPT ======================================================================
PROMPT Trigger TRG_MATRICULAS_CHECK_CAPACIDAD creado exitosamente
PROMPT ======================================================================
PROMPT
PROMPT El trigger ahora utiliza el package PKG_PROYECCION_RECURSOS para:
PROMPT - Validación de datos de entrada
PROMPT - Verificación de existencia de institución y carrera
PROMPT - Cálculo de estudiantes actuales
PROMPT - Obtención de capacidad institucional
PROMPT - Cálculo de salas requeridas
PROMPT - Verificación de capacidad disponible
PROMPT - Logging centralizado de eventos y errores
PROMPT
PROMPT Ventajas de esta implementación:
PROMPT ✓ Trigger más simple y mantenible
PROMPT ✓ Lógica centralizada en el package
PROMPT ✓ Reutilización de funciones existentes
PROMPT ✓ Sistema de logging unificado
PROMPT ✓ Manejo de errores consistente
PROMPT ✓ Fácil testing y debugging
PROMPT ======================================================================