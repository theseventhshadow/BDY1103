-- tabla de planes (si aún no existe)
CREATE TABLE RESOURCE_PLAN (
  PLAN_ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  INSTITUCION_ID INTEGER,
  INSTITUCION_NOMBRE VARCHAR2(100),
  CARRERA_ID INTEGER,
  CARRERA_NOMBRE VARCHAR2(100),
  SEMESTRE_LABEL VARCHAR2(10), -- ej '2022-1'
  PROJECTED_STUDENTS NUMBER,
  REQUIRED_TEACHERS NUMBER,
  REQUIRED_CLASSROOMS NUMBER,
  CREATED_AT DATE DEFAULT SYSDATE
);

-- Procedimiento principal
CREATE OR REPLACE PROCEDURE build_resource_plan(p_next_n NUMBER DEFAULT 4) IS

  -- RECORD para la fila del cursor
  TYPE prog_rec IS RECORD (
    institucion_id INSTITUCIONES.INSTITUCION_ID%TYPE,
    institucion_nombre INSTITUCIONES.INSTITUCION_NOMBRE%TYPE,
    carrera_id CARRERAS.CARRERA_ID%TYPE,
    carrera_nombre CARRERAS.CARRERA_NOMBRE%TYPE
  );

  CURSOR c_prog IS
    SELECT DISTINCT m.INSTITUCION_ID,
           i.INSTITUCION_NOMBRE,
           m.CARRERA_ID,
           c.CARRERA_NOMBRE
    FROM MATRICULAS m
    JOIN INSTITUCIONES i ON m.INSTITUCION_ID = i.INSTITUCION_ID
    JOIN CARRERAS c ON m.CARRERA_ID = c.CARRERA_ID;

  v_prog prog_rec;
  v_proj sem_proj_t;
  v_sem_label VARCHAR2(10);
  v_teachers NUMBER;
  v_classrooms NUMBER;

  -- helpers to compute labels (starting from current year/semester)
  v_now_year NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'));
  v_now_month NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'MM'));
  v_now_sem NUMBER := CASE WHEN v_now_month <= 6 THEN 1 ELSE 2 END;

  -- exception
  e_no_history EXCEPTION;
BEGIN
  OPEN c_prog;
  LOOP
    FETCH c_prog INTO v_prog.institucion_id, v_prog.institucion_nombre, v_prog.carrera_id, v_prog.carrera_nombre;
    EXIT WHEN c_prog%NOTFOUND;

    v_proj := project_students_for_next_semesters(v_prog.institucion_id, v_prog.carrera_id, p_next_n);

    FOR i IN 1..p_next_n LOOP
      -- calcular etiqueta semestre (ejemplo simple rotativo)
      DECLARE
        sem_num NUMBER := v_now_sem + i;
        year_num NUMBER := v_now_year;
      BEGIN
        WHILE sem_num > 2 LOOP
          sem_num := sem_num - 2;
          year_num := year_num + 1;
        END LOOP;
        v_sem_label := TO_CHAR(year_num) || '-' || TO_CHAR(sem_num);
      END;

      v_teachers := teachers_needed(v_proj(i), 30); -- ratio configurable
      -- buscar capacidad por aula definida para la institución, si existe
      v_classrooms := classrooms_needed(v_proj(i),
                        NVL((SELECT CAPACIDAD_POR_AULA FROM INSTITUCION_CAPACIDAD WHERE INSTITUCION_ID = v_prog.institucion_id), 40));

      INSERT INTO RESOURCE_PLAN (INSTITUCION_ID, INSTITUCION_NOMBRE, CARRERA_ID, CARRERA_NOMBRE,
                                SEMESTRE_LABEL, PROJECTED_STUDENTS, REQUIRED_TEACHERS, REQUIRED_CLASSROOMS)
      VALUES (v_prog.institucion_id, v_prog.institucion_nombre, v_prog.carrera_id, v_prog.carrera_nombre,
              v_sem_label, v_proj(i), v_teachers, v_classrooms);
    END LOOP;

  END LOOP;
  CLOSE c_prog;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en build_resource_plan: '||SQLERRM);
    ROLLBACK;
END build_resource_plan;
/
