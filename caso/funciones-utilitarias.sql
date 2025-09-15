-- docentes necesarios (ratio por defecto 30)
CREATE OR REPLACE FUNCTION profs_req(p_estudiantes NUMBER, p_razon NUMBER DEFAULT 30) RETURN NUMBER IS
BEGIN
  IF p_estudiantes IS NULL OR p_estudiantes <= 0 THEN
    RETURN 0;
  ELSE
    RETURN CEIL(p_estudiantes / NVL(p_razon,30));
  END IF;
END teachers_needed;
/

-- aulas necesarias (capacidad por aula por defecto 40)
CREATE OR REPLACE FUNCTION classrooms_needed(p_estudiantes NUMBER, p_sala_capacidad NUMBER DEFAULT 40) RETURN NUMBER IS
BEGIN
  IF p_estudiantes IS NULL OR p_estudiantes <= 0 THEN
    RETURN 0;
  ELSE
    RETURN CEIL(p_estudiantes / NVL(p_sala_capacidad,40));
  END IF;
END classrooms_needed;
/
