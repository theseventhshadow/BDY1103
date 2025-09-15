-- BATCH PROCESSING SCRIPT GENERATOR FOR MATRICULAS
-- This script creates smaller, manageable batch files to avoid Java heap space errors

SET SERVEROUTPUT ON;

DECLARE
    v_batch_size CONSTANT NUMBER := 1000; -- Records per batch file
    v_total_records CONSTANT NUMBER := 18785;
    v_total_batches NUMBER;
    v_current_batch NUMBER := 1;
    v_file_handle UTL_FILE.FILE_TYPE;
    v_filename VARCHAR2(100);
    
BEGIN
    v_total_batches := CEIL(v_total_records / v_batch_size);
    
    DBMS_OUTPUT.PUT_LINE('Creating ' || v_total_batches || ' batch files...');
    DBMS_OUTPUT.PUT_LINE('Each batch will contain up to ' || v_batch_size || ' records');
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR batch_num IN 1..v_total_batches LOOP
        v_filename := 'matriculas_batch_' || LPAD(batch_num, 2, '0') || '.sql';
        
        DBMS_OUTPUT.PUT_LINE('Batch ' || batch_num || ': ' || v_filename);
        DBMS_OUTPUT.PUT_LINE('  Records: ' || ((batch_num - 1) * v_batch_size + 1) || 
                           ' to ' || LEAST(batch_num * v_batch_size, v_total_records));
        
        -- Instructions for creating each batch file
        DBMS_OUTPUT.PUT_LINE('  Command: Create file with records ' || 
                           ((batch_num - 1) * v_batch_size + 1) || '-' || 
                           LEAST(batch_num * v_batch_size, v_total_records));
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== BATCH FILE TEMPLATE ===');
    DBMS_OUTPUT.PUT_LINE('Each batch file should contain:');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-- MATRICULAS BATCH INSERT - Batch X of ' || v_total_batches);
    DBMS_OUTPUT.PUT_LINE('SET SERVEROUTPUT ON;');
    DBMS_OUTPUT.PUT_LINE('SET AUTOCOMMIT OFF;');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('BEGIN');
    DBMS_OUTPUT.PUT_LINE('    DBMS_OUTPUT.PUT_LINE(''Starting batch X insert...'');');
    DBMS_OUTPUT.PUT_LINE('    ');
    DBMS_OUTPUT.PUT_LINE('    -- Your execute_matricula_insert calls here');
    DBMS_OUTPUT.PUT_LINE('    -- execute_matricula_insert(id, genero, edad, ...);');
    DBMS_OUTPUT.PUT_LINE('    ');
    DBMS_OUTPUT.PUT_LINE('    COMMIT;');
    DBMS_OUTPUT.PUT_LINE('    DBMS_OUTPUT.PUT_LINE(''Batch X completed successfully'');');
    DBMS_OUTPUT.PUT_LINE('EXCEPTION');
    DBMS_OUTPUT.PUT_LINE('    WHEN OTHERS THEN');
    DBMS_OUTPUT.PUT_LINE('        DBMS_OUTPUT.PUT_LINE(''Error in batch X: '' || SQLERRM);');
    DBMS_OUTPUT.PUT_LINE('        ROLLBACK;');
    DBMS_OUTPUT.PUT_LINE('        RAISE;');
    DBMS_OUTPUT.PUT_LINE('END;');
    DBMS_OUTPUT.PUT_LINE('/');
    
END;
/

SELECT 'Batch planning completed' AS STATUS FROM DUAL;