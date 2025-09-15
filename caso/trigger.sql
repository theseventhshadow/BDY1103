CREATE OR REPLACE TRIGGER trg_matriculas_check_capacity
BEFORE INSERT ON MATRICULAS
FOR EACH ROW
DECLARE
  v_total_students NUMBER;
  v_required_classrooms NUMBER;
  v_avail_aulas NUMBER;
  v_cap_por_aula NUMBER;
BEGIN
  -- contar alumnos actuales para la misma institucion + carrera y semestre (podrías ajustar la granularidad)
  SELECT COUNT(*) INTO v_total_students
  FROM MATRICULAS m
  WHERE m.INSTITUCION_ID = :NEW.INSTITUCION_ID
    AND m.CARRERA_ID = :NEW.CARRERA_ID
    AND m.ANIO_INGRESO = :NEW.ANIO_INGRESO
    AND m.SEMESTRE_INGRESO = :NEW.SEMESTRE_INGRESO;

  v_total_students := v_total_students + 1; -- incluimos la nueva matricula

  -- obtener capacidad de la institución (si existe)
  SELECT NVL(TOTAL_AULAS,0), NVL(CAPACIDAD_POR_AULA,40) INTO v_avail_aulas, v_cap_por_aula
  FROM INSTITUCION_CAPACIDAD
  WHERE INSTITUCION_ID = :NEW.INSTITUCION_ID;

  v_required_classrooms := classrooms_needed(v_total_students, v_cap_por_aula);

  IF v_avail_aulas IS NULL THEN
    -- si no hay registro, permitimos la inserción pero avisamos (o podríamos bloquear)
    DBMS_OUTPUT.PUT_LINE('Advertencia: institución sin registro de capacidad. Inserción permitida por defecto.');
  ELSIF v_required_classrooms > v_avail_aulas THEN
    RAISE_APPLICATION_ERROR(-20020, 'Capacidad insuficiente: aulas requeridas='||v_required_classrooms||
                                ', disponibles='||v_avail_aulas||' (Institución ID='||:NEW.INSTITUCION_ID||')');
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No hay registro de INSTITUCION_CAPACIDAD para INSTITUCION_ID='||:NEW.INSTITUCION_ID||'.');
  WHEN OTHERS THEN
    -- en triggers preferible registrar el error y bloquear si es crítico
    DBMS_OUTPUT.PUT_LINE('Error en trigger capacity check: '||SQLERRM);
    RAISE; -- opcional: re-raise para bloquear la inserción si hay fallo inesperado
END;
/
