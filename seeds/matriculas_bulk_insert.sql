-- BULK INSERT ALTERNATIVE FOR MATRICULAS
-- Uses SQL*Loader or external table approach for better memory management

-- Option 1: Direct bulk insert using external file
-- First, ensure your CSV file exists and is accessible

-- Create external table to read CSV data
CREATE OR REPLACE DIRECTORY matriculas_dir AS '/home/aframuz/code/study/duoc/4to_semestre/taller-base-datos/eva-01/seeds';

DROP TABLE matriculas_external;

CREATE TABLE matriculas_external (
    matricula_id        NUMBER,
    genero_id          NUMBER,
    edad               NUMBER,
    rango_edad_id      NUMBER,
    anio_ingreso       NUMBER,
    semestre_ingreso   NUMBER,
    institucion_id     NUMBER,
    carrera_id         NUMBER,
    via_ingreso_id     NUMBER,
    comuna_id          NUMBER
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY matriculas_dir
    ACCESS PARAMETERS (
        RECORDS DELIMITED BY NEWLINE
        SKIP 1
        FIELDS TERMINATED BY ','
        MISSING FIELD VALUES ARE NULL
        (
            matricula_id,
            genero_id,
            edad,
            rango_edad_id,
            anio_ingreso,
            semestre_ingreso,
            institucion_id,
            carrera_id,
            via_ingreso_id,
            comuna_id
        )
    )
    LOCATION ('matriculas.csv')
)
REJECT LIMIT UNLIMITED;

-- Bulk insert procedure with proper error handling
CREATE OR REPLACE PROCEDURE bulk_insert_matriculas IS
    v_inserted_count NUMBER := 0;
    v_error_count NUMBER := 0;
    v_batch_size CONSTANT NUMBER := 1000;
    
    CURSOR c_matriculas IS
        SELECT * FROM matriculas_external;
    
    TYPE t_matriculas_tab IS TABLE OF matriculas_external%ROWTYPE;
    v_matriculas t_matriculas_tab;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('BULK INSERT MATRICULAS FROM CSV');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Process started at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    
    -- Set up audit context
    DECLARE
        v_batch_id NUMBER;
    BEGIN
        SELECT matriculas_batch_seq.NEXTVAL INTO v_batch_id FROM DUAL;
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO(TO_CHAR(v_batch_id));
        DBMS_APPLICATION_INFO.SET_MODULE('MATRICULAS_BULK_INSERT', 'CSV_LOAD');
        DBMS_OUTPUT.PUT_LINE('Audit batch ID: ' || v_batch_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Warning: Audit system not available');
    END;
    
    OPEN c_matriculas;
    
    LOOP
        FETCH c_matriculas BULK COLLECT INTO v_matriculas LIMIT v_batch_size;
        
        EXIT WHEN v_matriculas.COUNT = 0;
        
        -- Bulk insert with error handling
        BEGIN
            FORALL i IN 1..v_matriculas.COUNT SAVE EXCEPTIONS
                INSERT INTO matriculas (
                    matricula_id, genero_id, edad, rango_edad_id,
                    anio_ingreso, semestre_ingreso, institucion_id,
                    carrera_id, via_ingreso_id, comuna_id
                ) VALUES (
                    v_matriculas(i).matricula_id,
                    v_matriculas(i).genero_id,
                    v_matriculas(i).edad,
                    v_matriculas(i).rango_edad_id,
                    v_matriculas(i).anio_ingreso,
                    v_matriculas(i).semestre_ingreso,
                    v_matriculas(i).institucion_id,
                    v_matriculas(i).carrera_id,
                    v_matriculas(i).via_ingreso_id,
                    v_matriculas(i).comuna_id
                );
            
            v_inserted_count := v_inserted_count + SQL%ROWCOUNT;
            COMMIT;
            
            DBMS_OUTPUT.PUT_LINE('Processed batch: ' || v_inserted_count || ' total records inserted');
            
        EXCEPTION
            WHEN OTHERS THEN
                -- Handle bulk operation errors
                IF SQLCODE = -24381 THEN -- FORALL save exceptions
                    FOR i IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
                        v_error_count := v_error_count + 1;
                        DBMS_OUTPUT.PUT_LINE('Error ' || i || ': ' || 
                            SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE) ||
                            ' at record ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX);
                    END LOOP;
                    
                    -- Commit successful records
                    v_inserted_count := v_inserted_count + (v_matriculas.COUNT - SQL%BULK_EXCEPTIONS.COUNT);
                    COMMIT;
                ELSE
                    -- Other errors
                    DBMS_OUTPUT.PUT_LINE('Batch error: ' || SQLERRM);
                    v_error_count := v_error_count + v_matriculas.COUNT;
                    ROLLBACK;
                END IF;
        END;
        
    END LOOP;
    
    CLOSE c_matriculas;
    
    -- Final summary
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('BULK INSERT SUMMARY');
    DBMS_OUTPUT.PUT_LINE('=======================================================');
    DBMS_OUTPUT.PUT_LINE('Process completed at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Successfully inserted: ' || v_inserted_count || ' records');
    DBMS_OUTPUT.PUT_LINE('Failed insertions: ' || v_error_count || ' records');
    
    IF v_error_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ SUCCESS: All records inserted successfully');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠️  Completed with ' || v_error_count || ' errors');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ CRITICAL ERROR: ' || SQLERRM);
        IF c_matriculas%ISOPEN THEN
            CLOSE c_matriculas;
        END IF;
        ROLLBACK;
        RAISE;
END bulk_insert_matriculas;
/

-- Execute the bulk insert
EXEC bulk_insert_matriculas;

-- Verify results
SELECT COUNT(*) AS total_matriculas FROM matriculas;

SELECT 'Bulk insert process completed' AS STATUS FROM DUAL;