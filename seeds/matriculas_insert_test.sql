-- TEST SCRIPT FOR MATRICULAS INSERTS WITH ERROR HANDLING
-- This is a template showing the error handling strategy
-- Apply this pattern to the full matriculas_inserts.sql file

SET SERVEROUTPUT ON;
SET AUTOCOMMIT OFF;

DECLARE
    v_error_count NUMBER := 0;
    v_success_count NUMBER := 0;
    v_total_records NUMBER := 10; -- This would be 18785 in the full script
    v_error_msg VARCHAR2(4000);
    v_current_record VARCHAR2(1000);
BEGIN
    -- Display start message
    DBMS_OUTPUT.PUT_LINE('Starting MATRICULAS insert process...');
    DBMS_OUTPUT.PUT_LINE('Total records to process: ' || v_total_records);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    
    -- Sample INSERT statements (replace with actual data)
    -- Record 1
    BEGIN
        v_current_record := 'MATRICULA_ID: 16';
        INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
        VALUES (16, 1, 21, 2, 2019, 1, 1, 1, 5, 147);
        v_success_count := v_success_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
            -- Log the error but continue processing
    END;
    
    -- Record 2
    BEGIN
        v_current_record := 'MATRICULA_ID: 21';
        INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
        VALUES (21, 2, 20, 2, 2021, 1, 1, 310, 5, 147);
        v_success_count := v_success_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
    END;
    
    -- Record 3
    BEGIN
        v_current_record := 'MATRICULA_ID: 22';
        INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
        VALUES (22, 2, 20, 2, 2021, 1, 10, 63, 5, 147);
        v_success_count := v_success_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
    END;
    
    -- Record 4
    BEGIN
        v_current_record := 'MATRICULA_ID: 175';
        INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
        VALUES (175, 2, 19, 1, 2020, 1, 7, 131, 5, 147);
        v_success_count := v_success_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
    END;
    
    -- Record 5
    BEGIN
        v_current_record := 'MATRICULA_ID: 222';
        INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
        VALUES (222, 2, 32, 4, 2020, 1, 8, 228, 5, 147);
        v_success_count := v_success_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
    END;
    
    -- Record 6
    BEGIN
        v_current_record := 'MATRICULA_ID: 224';
        INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
        VALUES (224, 1, 23, 2, 2016, 1, 9, 74, 5, 147);
        v_success_count := v_success_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
    END;
    
    -- Record 7
    BEGIN
        v_current_record := 'MATRICULA_ID: 255';
        INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
        VALUES (255, 2, 19, 1, 2020, 1, 10, 77, 5, 147);
        v_success_count := v_success_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
    END;
    
    -- Record 8 (intentional error for testing - invalid foreign key)
    BEGIN
        v_current_record := 'MATRICULA_ID: 999 (TEST ERROR)';
        INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
        VALUES (999, 999, 25, 3, 2021, 1, 999, 999, 999, 147); -- Invalid foreign keys
        v_success_count := v_success_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
    END;
    
    -- Record 9
    BEGIN
        v_current_record := 'MATRICULA_ID: 300';
        INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
        VALUES (300, 1, 20, 2, 2021, 1, 1, 1, 5, 147);
        v_success_count := v_success_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
    END;
    
    -- Record 10
    BEGIN
        v_current_record := 'MATRICULA_ID: 301';
        INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
        VALUES (301, 2, 22, 2, 2021, 2, 1, 1, 5, 147);
        v_success_count := v_success_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
    END;
    
    -- Final processing and decision making
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('MATRICULAS INSERT SUMMARY:');
    DBMS_OUTPUT.PUT_LINE('Successfully inserted: ' || v_success_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Failed insertions: ' || v_error_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Total processed: ' || (v_success_count + v_error_count) || ' records');
    
    -- Decision logic: rollback if too many errors
    IF v_error_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ SUCCESS: All records inserted successfully. Committing transaction...');
        COMMIT;
    ELSIF v_error_count <= 5 THEN  -- Allow up to 5 errors (configurable threshold)
        DBMS_OUTPUT.PUT_LINE('⚠️  WARNING: ' || v_error_count || ' errors occurred but within acceptable threshold. Committing transaction...');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('❌ FAILURE: Too many errors (' || v_error_count || '). Rolling back entire transaction...');
        ROLLBACK;
        -- Raise an exception to stop execution
        RAISE_APPLICATION_ERROR(-20001, 'MATRICULAS insert failed due to excessive errors (' || v_error_count || ' errors)');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Handle any unexpected errors in the main block
        DBMS_OUTPUT.PUT_LINE('❌ CRITICAL ERROR in MATRICULAS insert process: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Rolling back entire transaction...');
        ROLLBACK;
        RAISE; -- Re-raise the exception
END;
/

-- Display final status
SELECT 'MATRICULAS insert process completed' AS STATUS FROM DUAL;