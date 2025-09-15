-- PRODUCTION MATRICULAS INSERTS WITH ERROR HANDLING
-- This script processes all 18,785 matricula records with comprehensive error handling
-- Based on matriculas_insert_test.sql but designed for production use

SET SERVEROUTPUT ON;
SET AUTOCOMMIT OFF;

DECLARE
    v_error_count NUMBER := 0;
    v_success_count NUMBER := 0;
    v_total_records NUMBER := 18785; -- Total records from ETL process
    v_error_msg VARCHAR2(4000);
    v_current_record VARCHAR2(1000);
    v_max_errors CONSTANT NUMBER := 50; -- Allow up to 50 errors before aborting
    v_batch_commit_size CONSTANT NUMBER := 1000; -- Commit every 1000 successful inserts
    v_processed_count NUMBER := 0;
BEGIN
    -- Display start message
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('PRODUCTION MATRICULAS INSERT PROCESS');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Total records to process: ' || v_total_records);
    DBMS_OUTPUT.PUT_LINE('Maximum allowed errors: ' || v_max_errors);
    DBMS_OUTPUT.PUT_LINE('Batch commit size: ' || v_batch_commit_size);
    DBMS_OUTPUT.PUT_LINE('Process started at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
    
    /*
    ===============================================================================
    ===============================================================================
    
                            PASTE ALL INSERT STATEMENTS HERE
    
    Instructions:
    1. Copy ALL the INSERT statements from matriculas_inserts.sql 
    2. Paste them in this section, starting right after this comment block
    3. Each INSERT statement must be wrapped in the following pattern:
    
        -- Record N
        BEGIN
            v_current_record := 'MATRICULA_ID: [ID_VALUE]';
            [YOUR INSERT STATEMENT HERE]
            v_success_count := v_success_count + 1;
            v_processed_count := v_processed_count + 1;
            
            -- Commit every batch_commit_size successful records
            IF MOD(v_success_count, v_batch_commit_size) = 0 THEN
                COMMIT;
                DBMS_OUTPUT.PUT_LINE('Committed batch: ' || v_success_count || ' records processed successfully');
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_error_count := v_error_count + 1;
                v_error_msg := SQLERRM;
                DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
                
                -- Abort if too many errors
                IF v_error_count > v_max_errors THEN
                    DBMS_OUTPUT.PUT_LINE('❌ CRITICAL: Too many errors (' || v_error_count || '). Aborting process...');
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR(-20002, 'Process aborted due to excessive errors (' || v_error_count || ')');
                END IF;
        END;
    
    4. Example of how to wrap each INSERT:
    
        -- Record 1
        BEGIN
            v_current_record := 'MATRICULA_ID: 16';
            INSERT INTO matriculas (matricula_id, genero_id, edad, rango_edad_id, anio_ingreso, semestre_ingreso, institucion_id, carrera_id, via_ingreso_id, comuna_id) 
            VALUES (16, 1, 21, 2, 2019, 1, 1, 1, 5, 147);
            v_success_count := v_success_count + 1;
            v_processed_count := v_processed_count + 1;
            
            IF MOD(v_success_count, v_batch_commit_size) = 0 THEN
                COMMIT;
                DBMS_OUTPUT.PUT_LINE('Committed batch: ' || v_success_count || ' records processed successfully');
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_error_count := v_error_count + 1;
                v_error_msg := SQLERRM;
                DBMS_OUTPUT.PUT_LINE('ERROR inserting ' || v_current_record || ': ' || v_error_msg);
                
                IF v_error_count > v_max_errors THEN
                    DBMS_OUTPUT.PUT_LINE('❌ CRITICAL: Too many errors (' || v_error_count || '). Aborting process...');
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR(-20002, 'Process aborted due to excessive errors (' || v_error_count || ')');
                END IF;
        END;
    
    ===============================================================================
    ===============================================================================
    */
    
    -- PASTE YOUR 18,785 WRAPPED INSERT STATEMENTS HERE
    -- Each statement should follow the pattern shown above
    
    
    
    
    -- *** END OF INSERT STATEMENTS SECTION ***
    
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
    
    -- Validation check
    IF v_processed_count != v_total_records THEN
        DBMS_OUTPUT.PUT_LINE('⚠️  WARNING: Processed count (' || v_processed_count || ') does not match expected (' || v_total_records || ')');
    END IF;
    
    -- Final decision logic
    IF v_error_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ SUCCESS: All records inserted successfully.');
        DBMS_OUTPUT.PUT_LINE('✅ Transaction committed successfully.');
    ELSIF v_error_count <= v_max_errors THEN
        DBMS_OUTPUT.PUT_LINE('⚠️  WARNING: ' || v_error_count || ' errors occurred but within acceptable threshold (' || v_max_errors || ').');
        DBMS_OUTPUT.PUT_LINE('✅ Transaction committed with warnings.');
    ELSE
        -- This should not happen due to the error checking during processing
        DBMS_OUTPUT.PUT_LINE('❌ FAILURE: Too many errors (' || v_error_count || '). This should not happen!');
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'MATRICULAS insert failed due to excessive errors (' || v_error_count || ' errors)');
    END IF;
    
    -- Calculate success rate
    DECLARE
        v_success_rate NUMBER;
    BEGIN
        IF v_processed_count > 0 THEN
            v_success_rate := ROUND((v_success_count / v_processed_count) * 100, 2);
            DBMS_OUTPUT.PUT_LINE('Success rate: ' || v_success_rate || '%');
        END IF;
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Handle any unexpected errors in the main block
        DBMS_OUTPUT.PUT_LINE('=======================================================');
        DBMS_OUTPUT.PUT_LINE('❌ CRITICAL ERROR in MATRICULAS insert process');
        DBMS_OUTPUT.PUT_LINE('=======================================================');
        DBMS_OUTPUT.PUT_LINE('Error occurred at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('Error message: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Records successfully processed before error: ' || v_success_count);
        DBMS_OUTPUT.PUT_LINE('Total errors before critical failure: ' || v_error_count);
        DBMS_OUTPUT.PUT_LINE('Rolling back entire transaction...');
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ Transaction rolled back.');
        RAISE; -- Re-raise the exception
END;
/

-- Display final status
SELECT 
    'MATRICULAS production insert process completed at ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') AS FINAL_STATUS 
FROM DUAL;

-- Optional: Query to verify the inserted records
-- Uncomment the following lines if you want to see a summary of inserted data
/*
SELECT 
    'Total matriculas in database: ' || COUNT(*) AS VERIFICATION_COUNT
FROM matriculas;

SELECT 
    'Sample of inserted data:' AS SAMPLE_HEADER
FROM DUAL;

SELECT 
    matricula_id, genero_id, edad, anio_ingreso, semestre_ingreso
FROM matriculas 
WHERE ROWNUM <= 10
ORDER BY matricula_id;
*/