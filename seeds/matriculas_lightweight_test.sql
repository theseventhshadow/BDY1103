-- LIGHTWEIGHT MATRICULAS INSERT TEST
-- This version tests the functionality with a small dataset to avoid memory issues

SET SERVEROUTPUT ON;
SET AUTOCOMMIT OFF;

-- Create the functions and procedures first
CREATE OR REPLACE FUNCTION insert_single_matricula(
    p_matricula_id IN NUMBER,
    p_genero_id IN NUMBER,
    p_edad IN NUMBER,
    p_rango_edad_id IN NUMBER,
    p_anio_ingreso IN NUMBER,
    p_semestre_ingreso IN NUMBER,
    p_institucion_id IN NUMBER,
    p_carrera_id IN NUMBER,
    p_via_ingreso_id IN NUMBER,
    p_comuna_id IN NUMBER
) RETURN VARCHAR2 IS
BEGIN
    INSERT INTO matriculas (
        matricula_id, genero_id, edad, rango_edad_id, 
        anio_ingreso, semestre_ingreso, institucion_id, 
        carrera_id, via_ingreso_id, comuna_id
    ) VALUES (
        p_matricula_id, p_genero_id, p_edad, p_rango_edad_id,
        p_anio_ingreso, p_semestre_ingreso, p_institucion_id,
        p_carrera_id, p_via_ingreso_id, p_comuna_id
    );
    
    RETURN 'SUCCESS';
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RETURN 'DUPLICATE';
    WHEN OTHERS THEN
        RETURN SQLERRM;
END insert_single_matricula;
/

-- Test with just 10 records to verify functionality
DECLARE
    v_error_count NUMBER := 0;
    v_success_count NUMBER := 0;
    v_processed_count NUMBER := 0;
    
    PROCEDURE execute_matricula_insert(
        p_matricula_id NUMBER, p_genero_id NUMBER, p_edad NUMBER, p_rango_edad_id NUMBER,
        p_anio_ingreso NUMBER, p_semestre_ingreso NUMBER, p_institucion_id NUMBER,
        p_carrera_id NUMBER, p_via_ingreso_id NUMBER, p_comuna_id NUMBER
    ) IS
        v_result VARCHAR2(4000);
    BEGIN
        v_processed_count := v_processed_count + 1;
        
        v_result := insert_single_matricula(
            p_matricula_id, p_genero_id, p_edad, p_rango_edad_id,
            p_anio_ingreso, p_semestre_ingreso, p_institucion_id,
            p_carrera_id, p_via_ingreso_id, p_comuna_id
        );
        
        IF v_result = 'SUCCESS' THEN
            v_success_count := v_success_count + 1;
            DBMS_OUTPUT.PUT_LINE('✅ Record ' || v_processed_count || ': MATRICULA_ID ' || p_matricula_id || ' - SUCCESS');
        ELSE
            v_error_count := v_error_count + 1;
            DBMS_OUTPUT.PUT_LINE('❌ Record ' || v_processed_count || ': MATRICULA_ID ' || p_matricula_id || ' - ERROR: ' || v_result);
        END IF;
    END execute_matricula_insert;
    
BEGIN
    -- Set up audit context
    DECLARE
        v_batch_id NUMBER := 999; -- Test batch ID
    BEGIN
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO(TO_CHAR(v_batch_id));
        DBMS_APPLICATION_INFO.SET_MODULE('MATRICULAS_ETL_TEST', 'LIGHTWEIGHT_TEST');
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- Continue if audit system not available
    END;
    
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('LIGHTWEIGHT MATRICULAS INSERT TEST');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Testing functionality with 10 sample records...');
    DBMS_OUTPUT.PUT_LINE('Process started at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
    
    -- Test records (first 10 from your dataset)
    execute_matricula_insert(16, 1, 21, 2, 2019, 1, 1, 1, 5, 147);
    execute_matricula_insert(21, 2, 20, 2, 2021, 1, 1, 310, 5, 147);
    execute_matricula_insert(22, 2, 20, 2, 2021, 1, 10, 63, 5, 147);
    execute_matricula_insert(175, 2, 19, 1, 2020, 1, 7, 131, 5, 147);
    execute_matricula_insert(222, 2, 32, 4, 2020, 1, 8, 228, 5, 147);
    execute_matricula_insert(224, 1, 23, 2, 2016, 1, 9, 74, 5, 147);
    execute_matricula_insert(255, 2, 19, 1, 2020, 1, 10, 77, 5, 147);
    
    -- Test error case (invalid foreign keys)
    execute_matricula_insert(999, 999, 25, 3, 2021, 1, 999, 999, 999, 147);
    
    -- More valid records
    execute_matricula_insert(300, 1, 20, 2, 2021, 1, 1, 1, 5, 147);
    execute_matricula_insert(301, 2, 22, 2, 2021, 2, 1, 1, 5, 147);
    
    -- Summary
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('LIGHTWEIGHT TEST SUMMARY');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Process completed at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Successfully inserted: ' || v_success_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Failed insertions: ' || v_error_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Total processed: ' || v_processed_count || ' records');
    
    IF v_error_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ SUCCESS: All test records processed successfully');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠️  Test completed with ' || v_error_count || ' errors (expected for testing)');
        COMMIT; -- Commit successful ones
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ CRITICAL ERROR: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

-- Verify inserted records
SELECT COUNT(*) AS inserted_records FROM matriculas WHERE matricula_id IN (16, 21, 22, 175, 222, 224, 255, 300, 301);

SELECT 'Lightweight test completed' AS STATUS FROM DUAL;