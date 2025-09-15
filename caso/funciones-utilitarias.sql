-- docentes necesarios (ratio por defecto 30)
CREATE OR REPLACE FUNCTION teachers_needed(p_students NUMBER, p_ratio NUMBER DEFAULT 30) RETURN NUMBER IS
BEGIN
  IF p_students IS NULL OR p_students <= 0 THEN
    RETURN 0;
  ELSE
    RETURN CEIL(p_students / NVL(p_ratio,30));
  END IF;
END teachers_needed;
/

-- aulas necesarias (capacidad por aula por defecto 40)
CREATE OR REPLACE FUNCTION classrooms_needed(p_students NUMBER, p_classroom_capacity NUMBER DEFAULT 40) RETURN NUMBER IS
BEGIN
  IF p_students IS NULL OR p_students <= 0 THEN
    RETURN 0;
  ELSE
    RETURN CEIL(p_students / NVL(p_classroom_capacity,40));
  END IF;
END classrooms_needed;
/
