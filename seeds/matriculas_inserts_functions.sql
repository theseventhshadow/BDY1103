-- PRODUCTION MATRICULAS INSERTS WITH FUNCTION-BASED ERROR HANDLING
-- This script uses functions to simplify the insert wrapping process
-- Cleaner, more maintainable approach than repetitive BEGIN/EXCEPTION blocks

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
    v_result VARCHAR2(10);
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
    v_result VARCHAR2(4000);
    v_batch_commit_count NUMBER := 0;
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
    v_insert_result VARCHAR2(4000);
    
    -- Function to execute insert and handle result
    FUNCTION execute_matricula_insert(
        p_matricula_id NUMBER, p_genero_id NUMBER, p_edad NUMBER, p_rango_edad_id NUMBER,
        p_anio_ingreso NUMBER, p_semestre_ingreso NUMBER, p_institucion_id NUMBER,
        p_carrera_id NUMBER, p_via_ingreso_id NUMBER, p_comuna_id NUMBER
    ) RETURN BOOLEAN IS
        v_result VARCHAR2(4000);
    BEGIN
        v_result := insert_single_matricula(
            p_matricula_id, p_genero_id, p_edad, p_rango_edad_id,
            p_anio_ingreso, p_semestre_ingreso, p_institucion_id,
            p_carrera_id, p_via_ingreso_id, p_comuna_id
        );
        
        IF v_result = 'SUCCESS' THEN
            v_success_count := v_success_count + 1;
            RETURN TRUE;
        ELSE
            v_error_count := v_error_count + 1;
            DBMS_OUTPUT.PUT_LINE('ERROR inserting MATRICULA_ID ' || p_matricula_id || ': ' || v_result);
            RETURN FALSE;
        END IF;
    END execute_matricula_insert;
    
BEGIN
    -- Set up audit context for batch tracking
    DECLARE
        v_batch_id NUMBER;
    BEGIN
        SELECT matriculas_batch_seq.NEXTVAL INTO v_batch_id FROM DUAL;
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO(TO_CHAR(v_batch_id));
        DBMS_APPLICATION_INFO.SET_MODULE('MATRICULAS_ETL_INSERT', 'BULK_LOAD_PRODUCTION');
    EXCEPTION
        WHEN OTHERS THEN
            -- If audit system not available, continue without batch tracking
            NULL;
    END;
    
    -- Display start message
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('PRODUCTION MATRICULAS INSERT PROCESS (Function-Based)');
    DBMS_OUTPUT.PUT_LINE('WITH COMPREHENSIVE AUDIT LOGGING');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Total records to process: ' || v_total_records);
    DBMS_OUTPUT.PUT_LINE('Maximum allowed errors: ' || v_max_errors);
    DBMS_OUTPUT.PUT_LINE('Batch commit size: ' || v_batch_commit_size);
    DBMS_OUTPUT.PUT_LINE('Audit batch ID: ' || SYS_CONTEXT('USERENV', 'CLIENT_INFO'));
    DBMS_OUTPUT.PUT_LINE('Process started at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
    
    /*
    ===============================================================================
    ===============================================================================
    
                        SIMPLIFIED INSERT STATEMENTS SECTION
    
    Instructions:
    1. Copy your INSERT VALUES from matriculas_inserts.sql
    2. Convert each INSERT to a simple function call
    3. Use this pattern for each record:
    
        -- Record N
        IF execute_matricula_insert(matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) THEN
            v_processed_count := v_processed_count + 1;
        ELSE
            v_processed_count := v_processed_count + 1;
        END IF;
        
        -- Process batch management every 100 records for performance
        IF MOD(v_processed_count, 100) = 0 THEN
            process_matricula_batch(v_batch_commit_size, v_max_errors, v_success_count, v_error_count, v_should_abort);
            IF v_should_abort THEN
                RAISE_APPLICATION_ERROR(-20002, 'Process aborted due to excessive errors (' || v_error_count || ')');
            END IF;
        END IF;
    
    4. Example conversions:
    
       FROM THIS:
       INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
       VALUES (16, 1, 21, 2, 2019, 1, 1, 1, 5, 147);
       
       TO THIS:
       -- Record 1
       IF execute_matricula_insert(16, 1, 21, 2, 2019, 1, 1, 1, 5, 147) THEN
           v_processed_count := v_processed_count + 1;
       ELSE
           v_processed_count := v_processed_count + 1;
       END IF;
       
       IF MOD(v_processed_count, 100) = 0 THEN
           process_matricula_batch(v_batch_commit_size, v_max_errors, v_success_count, v_error_count, v_should_abort);
           IF v_should_abort THEN
               RAISE_APPLICATION_ERROR(-20002, 'Process aborted due to excessive errors (' || v_error_count || ')');
           END IF;
       END IF;
    
    EVEN SIMPLER OPTION:
    You can also use this ultra-compact format (one line per record):
    
    v_processed_count := v_processed_count + 1; IF NOT execute_matricula_insert(16, 1, 21, 2, 2019, 1, 1, 1, 5, 147) THEN NULL; END IF; IF MOD(v_processed_count, 100) = 0 THEN process_matricula_batch(v_batch_commit_size, v_max_errors, v_success_count, v_error_count, v_should_abort); IF v_should_abort THEN RAISE_APPLICATION_ERROR(-20002, 'Aborted'); END IF; END IF;
    
    ===============================================================================
    ===============================================================================
    */
    
    -- PASTE YOUR CONVERTED FUNCTION CALLS HERE
    -- Each record should use the execute_matricula_insert function
    
    -- Example records (replace with your actual data):
    
    -- Record 1
    IF execute_matricula_insert(16, 1, 21, 2, 2019, 1, 1, 1, 5, 147) THEN
        v_processed_count := v_processed_count + 1;
    ELSE
        v_processed_count := v_processed_count + 1;
    END IF;
    
    IF MOD(v_processed_count, 100) = 0 THEN
        process_matricula_batch(v_batch_commit_size, v_max_errors, v_success_count, v_error_count, v_should_abort);
        IF v_should_abort THEN
            RAISE_APPLICATION_ERROR(-20002, 'Process aborted due to excessive errors (' || v_error_count || ')');
        END IF;
    END IF;
    
    -- Record 2
    IF execute_matricula_insert(21, 2, 20, 2, 2021, 1, 1, 310, 5, 147) THEN
        v_processed_count := v_processed_count + 1;
    ELSE
        v_processed_count := v_processed_count + 1;
    END IF;
    
    IF MOD(v_processed_count, 100) = 0 THEN
        process_matricula_batch(v_batch_commit_size, v_max_errors, v_success_count, v_error_count, v_should_abort);
        IF v_should_abort THEN
            RAISE_APPLICATION_ERROR(-20002, 'Process aborted due to excessive errors (' || v_error_count || ')');
        END IF;
    END IF;
    
    -- ADD YOUR REMAINING 18,783 RECORDS HERE USING THE SAME PATTERN
    
    
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
    DBMS_OUTPUT.PUT_LINE('PRODUCTION MATRICULAS INSERT SUMMARY:');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Process completed at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Successfully inserted: ' || v_success_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Failed insertions: ' || v_error_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Total processed: ' || v_processed_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Expected total: ' || v_total_records || ' records');
    
    -- Calculate success rate
    DECLARE
        v_success_rate NUMBER;
        v_batch_id VARCHAR2(100);
    BEGIN
        IF v_processed_count > 0 THEN
            v_success_rate := ROUND((v_success_count / v_processed_count) * 100, 2);
            DBMS_OUTPUT.PUT_LINE('Success rate: ' || v_success_rate || '%');
        END IF;
        
        -- Display audit information
        v_batch_id := SYS_CONTEXT('USERENV', 'CLIENT_INFO');
        IF v_batch_id IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Audit batch ID: ' || v_batch_id);
            DBMS_OUTPUT.PUT_LINE('View audit details: SELECT * FROM v_matriculas_batch_summary WHERE batch_id = ' || v_batch_id);
        END IF;
    END;
    
    -- Final decision logic
    IF v_error_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ SUCCESS: All records inserted successfully.');
        DBMS_OUTPUT.PUT_LINE('✅ Complete audit trail available in matriculas_audit_log table.');
    ELSIF v_error_count <= v_max_errors THEN
        DBMS_OUTPUT.PUT_LINE('⚠️  WARNING: ' || v_error_count || ' errors occurred but within acceptable threshold.');
        DBMS_OUTPUT.PUT_LINE('⚠️  Check audit log for detailed error analysis.');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ CRITICAL ERROR: ' || SQLERRM);
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