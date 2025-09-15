-- Obtener máxima duración de carreras para dimensionar el VARRAY dinámicamente
DECLARE
    max_duracion NUMBER;
    sql_stmt VARCHAR2(4000);
BEGIN
    -- Obtener la duración máxima de la tabla carreras
    SELECT MAX(duracion_total) INTO max_duracion FROM carreras;
    
    -- Construir y ejecutar el DDL para crear el tipo VARRAY con el tamaño dinámico
    sql_stmt := 'CREATE OR REPLACE TYPE sem_proj_t AS VARRAY(' || max_duracion || ') OF NUMBER';
    EXECUTE IMMEDIATE sql_stmt;
    
    DBMS_OUTPUT.PUT_LINE('VARRAY creado con tamaño máximo: ' || max_duracion || ' semestres');
END;
/
