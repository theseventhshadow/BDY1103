-- MATRICULAS INSERTS WITH FUNCTION-BASED ERROR HANDLING (NO AUDIT DEPENDENCIES)

SET SERVEROUTPUT ON;
SET AUTOCOMMIT OFF;

-- Create a function to handle individual matricula inserts
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

-- Create a procedure to handle batch processing and error management
CREATE OR REPLACE PROCEDURE process_matricula_batch(
    p_batch_size IN NUMBER DEFAULT 1000,
    p_max_errors IN NUMBER DEFAULT 50,
    p_success_count IN OUT NUMBER,
    p_error_count IN OUT NUMBER,
    p_should_abort OUT BOOLEAN
) IS
BEGIN
    p_should_abort := FALSE;
    
    -- Commit batch if we've reached the batch size
    IF MOD(p_success_count, p_batch_size) = 0 AND p_success_count > 0 THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✅ Committed batch: ' || p_success_count || ' records processed successfully');
    END IF;
    
    -- Check if we should abort due to too many errors
    IF p_error_count > p_max_errors THEN
        DBMS_OUTPUT.PUT_LINE('❌ CRITICAL: Too many errors (' || p_error_count || '). Aborting process...');
        ROLLBACK;
        p_should_abort := TRUE;
    END IF;
END process_matricula_batch;
/

-- Main processing block
DECLARE
    v_error_count NUMBER := 0;
    v_success_count NUMBER := 0;
    v_total_records NUMBER := 18785; -- Total records from ETL process
    v_max_errors CONSTANT NUMBER := 50; -- Allow up to 50 errors before aborting
    v_batch_commit_size CONSTANT NUMBER := 1000; -- Commit every 1000 successful inserts
    v_processed_count NUMBER := 0;
    v_should_abort BOOLEAN := FALSE;
    v_batch_id NUMBER := 0; -- Simple counter instead of sequence
    
    -- CORRECTED: Function to execute insert and handle result
    PROCEDURE execute_matricula_insert(
        p_matricula_id NUMBER, p_genero_id NUMBER, p_edad NUMBER, p_rango_edad_id NUMBER,
        p_anio_ingreso NUMBER, p_semestre_ingreso NUMBER, p_institucion_id NUMBER,
        p_carrera_id NUMBER, p_via_ingreso_id NUMBER, p_comuna_id NUMBER
    ) IS
        v_result VARCHAR2(4000);
    BEGIN
        -- Always increment processed count first
        v_processed_count := v_processed_count + 1;
        
        -- Attempt the insert
        v_result := insert_single_matricula(
            p_matricula_id, p_genero_id, p_edad, p_rango_edad_id,
            p_anio_ingreso, p_semestre_ingreso, p_institucion_id,
            p_carrera_id, p_via_ingreso_id, p_comuna_id
        );
        
        -- Handle the result
        IF v_result = 'SUCCESS' THEN
            v_success_count := v_success_count + 1;
        ELSE
            v_error_count := v_error_count + 1;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting MATRICULA_ID ' || p_matricula_id || ': ' || v_result);
        END IF;
        
        -- Check for batch processing every 100 records
        IF MOD(v_processed_count, 100) = 0 THEN
            process_matricula_batch(v_batch_commit_size, v_max_errors, v_success_count, v_error_count, v_should_abort);
            DBMS_OUTPUT.PUT_LINE('Progress: ' || v_processed_count || ' records processed (' || v_success_count || ' successful, ' || v_error_count || ' errors)');
            IF v_should_abort THEN
                RAISE_APPLICATION_ERROR(-20002, 'Process aborted due to excessive errors (' || v_error_count || ')');
            END IF;
        END IF;
    END execute_matricula_insert;
    
BEGIN
    -- Simple batch ID generation
    SELECT EXTRACT(SECOND FROM CURRENT_TIMESTAMP) * 1000 + 
           TO_NUMBER(TO_CHAR(SYSDATE, 'SSHHMISS')) INTO v_batch_id FROM DUAL;
    
    -- Display start message
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('MATRICULAS INSERT PROCESS (Function-Based - No Dependencies)');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Total records to process: ' || v_total_records);
    DBMS_OUTPUT.PUT_LINE('Maximum allowed errors: ' || v_max_errors);
    DBMS_OUTPUT.PUT_LINE('Batch commit size: ' || v_batch_commit_size);
    DBMS_OUTPUT.PUT_LINE('Process batch ID: ' || v_batch_id);
    DBMS_OUTPUT.PUT_LINE('Process started at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
    
    /*
    ===============================================================================
    ===============================================================================
    
                        INSERT STATEMENTS SECTION
    
    Instructions:
    1. Use this pattern for each record:
    
        -- Record N
        execute_matricula_insert(matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id);
    
    2. Example:
        execute_matricula_insert(16, 1, 21, 2, 2019, 1, 1, 1, 5, 147);
    
    3. PASTE YOUR INSERT CALLS BELOW THIS COMMENT BLOCK:
    ===============================================================================
    ===============================================================================
    */
    
    -- Test records (replace with your actual function calls from matriculas_functions_seed.sql)
    execute_matricula_insert(16, 1, 21, 2, 2019, 1, 1, 1, 5, 147);
    execute_matricula_insert(21, 2, 20, 2, 2021, 1, 1, 310, 5, 147);
    execute_matricula_insert(22, 2, 20, 2, 2021, 1, 10, 63, 5, 147);
    
    -- PASTE ALL YOUR execute_matricula_insert CALLS HERE
    -- (Copy from matriculas_functions_seed.sql - the lines that look like:)
    -- execute_matricula_insert(16, 1, 21, 2, 2019, 1, 1, 1, 5, 147);
    
    -- *** END OF INSERT STATEMENTS SECTION ***
    
    -- Final processing
    process_matricula_batch(v_batch_commit_size, v_max_errors, v_success_count, v_error_count, v_should_abort);
    
    -- Final commit for any remaining uncommitted successful records
    IF MOD(v_success_count, v_batch_commit_size) != 0 THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Final commit: ' || v_success_count || ' total records committed');
    END IF;
    
    -- Final processing and summary
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('MATRICULAS INSERT SUMMARY:');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Process completed at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Successfully inserted: ' || v_success_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Failed insertions: ' || v_error_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Total processed: ' || v_processed_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Expected total: ' || v_total_records || ' records');
    
    -- Validation check
    IF v_processed_count != v_total_records THEN
        DBMS_OUTPUT.PUT_LINE('⚠️  WARNING: Processed count (' || v_processed_count || ') does not match expected (' || v_total_records || ')');
        DBMS_OUTPUT.PUT_LINE('⚠️  Make sure you pasted all ' || v_total_records || ' function calls');
    END IF;
    
    -- Calculate success rate
    DECLARE
        v_success_rate NUMBER;
    BEGIN
        IF v_processed_count > 0 THEN
            v_success_rate := ROUND((v_success_count / v_processed_count) * 100, 2);
            DBMS_OUTPUT.PUT_LINE('Success rate: ' || v_success_rate || '%');
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('Process batch ID: ' || v_batch_id);
    END;
    
    -- Final decision logic
    IF v_error_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ SUCCESS: All records inserted successfully.');
    ELSIF v_error_count <= v_max_errors THEN
        DBMS_OUTPUT.PUT_LINE('⚠️  WARNING: ' || v_error_count || ' errors occurred but within acceptable threshold.');
        DBMS_OUTPUT.PUT_LINE('⚠️  Review error messages above for details.');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ CRITICAL ERROR: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Records processed before error: ' || v_processed_count);
        DBMS_OUTPUT.PUT_LINE('Successful inserts: ' || v_success_count);
        DBMS_OUTPUT.PUT_LINE('Errors encountered: ' || v_error_count);
        ROLLBACK;
        RAISE;
END;
/

-- Clean up functions (optional - comment out if you want to keep them)
-- DROP FUNCTION insert_single_matricula;
-- DROP PROCEDURE process_matricula_batch;

-- Display final status
SELECT 
    'MATRICULAS function-based insert process completed at ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') AS FINAL_STATUS 
FROM DUAL;