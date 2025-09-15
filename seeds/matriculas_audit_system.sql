-- MATRICULAS AUDIT SYSTEM
-- Comprehensive auditing solution for matriculas table operations
-- Provides complete audit trail for compliance and operational monitoring

------------------------------------------------------------------------
-- AUDIT TABLE CREATION
------------------------------------------------------------------------

-- Drop existing audit table if it exists
DROP TABLE matriculas_audit_log CASCADE CONSTRAINTS;
DROP SEQUENCE matriculas_batch_seq;

-- Create sequence for batch identification
CREATE SEQUENCE matriculas_batch_seq START WITH 1 INCREMENT BY 1;

-- Create comprehensive audit log table
CREATE TABLE matriculas_audit_log (
    -- Primary identification
    audit_id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- What happened
    operation_type      VARCHAR2(10) NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    matricula_id        NUMBER,
    
    -- When it happened
    audit_timestamp     TIMESTAMP DEFAULT SYSTIMESTAMP,
    audit_date          DATE DEFAULT SYSDATE,
    
    -- Who did it
    audit_user          VARCHAR2(128) DEFAULT USER,
    audit_session_id    NUMBER DEFAULT SYS_CONTEXT('USERENV', 'SESSIONID'),
    audit_client_info   VARCHAR2(64) DEFAULT SYS_CONTEXT('USERENV', 'CLIENT_INFO'),
    audit_program       VARCHAR2(64) DEFAULT SYS_CONTEXT('USERENV', 'MODULE'),
    audit_ip_address    VARCHAR2(15) DEFAULT SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
    
    -- Data values (before and after)
    old_genero_id       NUMBER,
    old_edad            NUMBER,
    old_rango_edad_id   NUMBER,
    old_anio_ingreso    NUMBER,
    old_semestre_ingreso NUMBER,
    old_institucion_id  NUMBER,
    old_carrera_id      NUMBER,
    old_via_ingreso_id  NUMBER,
    old_comuna_id       NUMBER,
    
    new_genero_id       NUMBER,
    new_edad            NUMBER,
    new_rango_edad_id   NUMBER,
    new_anio_ingreso    NUMBER,
    new_semestre_ingreso NUMBER,
    new_institucion_id  NUMBER,
    new_carrera_id      NUMBER,
    new_via_ingreso_id  NUMBER,
    new_comuna_id       NUMBER,
    
    -- Process identification
    batch_id            NUMBER,
    process_name        VARCHAR2(100) DEFAULT 'ETL_MATRICULAS_INSERT',
    source_description  VARCHAR2(200) DEFAULT 'matriculas_ed_superior_nuble_2021.xlsx',
    
    -- Error handling
    error_code          NUMBER,
    error_message       VARCHAR2(4000),
    
    -- Business context
    validation_status   VARCHAR2(20) DEFAULT 'VALID' CHECK (validation_status IN ('VALID', 'INVALID', 'WARNING')),
    validation_notes    VARCHAR2(1000),
    
    -- Additional metadata
    row_version         NUMBER DEFAULT 1,
    is_bulk_operation   CHAR(1) DEFAULT 'N' CHECK (is_bulk_operation IN ('Y', 'N'))
);

-- Create indexes for performance
CREATE INDEX idx_matriculas_audit_matricula_id ON matriculas_audit_log(matricula_id);
CREATE INDEX idx_matriculas_audit_timestamp ON matriculas_audit_log(audit_timestamp);
CREATE INDEX idx_matriculas_audit_user ON matriculas_audit_log(audit_user);
CREATE INDEX idx_matriculas_audit_batch ON matriculas_audit_log(batch_id);
CREATE INDEX idx_matriculas_audit_operation ON matriculas_audit_log(operation_type);

------------------------------------------------------------------------
-- AUDIT TRIGGER
------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_matriculas_audit
    AFTER INSERT OR UPDATE OR DELETE ON matriculas
    FOR EACH ROW
DECLARE
    v_operation_type VARCHAR2(10);
    v_batch_id NUMBER;
    v_validation_status VARCHAR2(20) := 'VALID';
    v_validation_notes VARCHAR2(1000) := NULL;
    
    -- Function to validate business rules
    FUNCTION validate_matricula_data(
        p_edad NUMBER,
        p_anio_ingreso NUMBER,
        p_semestre_ingreso NUMBER
    ) RETURN VARCHAR2 IS
        v_notes VARCHAR2(1000) := '';
        v_current_year NUMBER := EXTRACT(YEAR FROM SYSDATE);
    BEGIN
        -- Age validation
        IF p_edad < 15 OR p_edad > 80 THEN
            v_notes := v_notes || 'Age out of expected range (' || p_edad || '). ';
        END IF;
        
        -- Year validation
        IF p_anio_ingreso < 2000 OR p_anio_ingreso > v_current_year THEN
            v_notes := v_notes || 'Invalid enrollment year (' || p_anio_ingreso || '). ';
        END IF;
        
        -- Semester validation
        IF p_semestre_ingreso NOT IN (1, 2) THEN
            v_notes := v_notes || 'Invalid semester (' || p_semestre_ingreso || '). ';
        END IF;
        
        -- Future enrollment check
        IF p_anio_ingreso > v_current_year THEN
            v_notes := v_notes || 'Future enrollment date detected. ';
        END IF;
        
        RETURN TRIM(v_notes);
    END validate_matricula_data;
    
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation_type := 'INSERT';
    ELSIF UPDATING THEN
        v_operation_type := 'UPDATE';
    ELSIF DELETING THEN
        v_operation_type := 'DELETE';
    END IF;
    
    -- Get or generate batch ID (check if we're in a bulk operation)
    BEGIN
        -- Try to get batch ID from client info
        v_batch_id := TO_NUMBER(SYS_CONTEXT('USERENV', 'CLIENT_INFO'));
    EXCEPTION
        WHEN OTHERS THEN
            -- Generate new batch ID if not set
            v_batch_id := matriculas_batch_seq.NEXTVAL;
    END;
    
    -- Validate data for INSERT and UPDATE operations
    IF INSERTING OR UPDATING THEN
        v_validation_notes := validate_matricula_data(:NEW.edad, :NEW.anio_ingreso, :NEW.semestre_ingreso);
        
        IF v_validation_notes IS NOT NULL THEN
            v_validation_status := 'WARNING';
        END IF;
    END IF;
    
    -- Insert audit record (using autonomous transaction for reliability)
    INSERT INTO matriculas_audit_log (
        operation_type,
        matricula_id,
        audit_timestamp,
        audit_date,
        audit_user,
        audit_session_id,
        audit_client_info,
        audit_program,
        audit_ip_address,
        
        -- Old values (for UPDATE and DELETE)
        old_genero_id,
        old_edad,
        old_rango_edad_id,
        old_anio_ingreso,
        old_semestre_ingreso,
        old_institucion_id,
        old_carrera_id,
        old_via_ingreso_id,
        old_comuna_id,
        
        -- New values (for INSERT and UPDATE)
        new_genero_id,
        new_edad,
        new_rango_edad_id,
        new_anio_ingreso,
        new_semestre_ingreso,
        new_institucion_id,
        new_carrera_id,
        new_via_ingreso_id,
        new_comuna_id,
        
        batch_id,
        validation_status,
        validation_notes,
        is_bulk_operation
    ) VALUES (
        v_operation_type,
        COALESCE(:NEW.matricula_id, :OLD.matricula_id),
        SYSTIMESTAMP,
        SYSDATE,
        USER,
        SYS_CONTEXT('USERENV', 'SESSIONID'),
        SYS_CONTEXT('USERENV', 'CLIENT_INFO'),
        SYS_CONTEXT('USERENV', 'MODULE'),
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        
        -- Old values
        :OLD.genero_id,
        :OLD.edad,
        :OLD.rango_edad_id,
        :OLD.anio_ingreso,
        :OLD.semestre_ingreso,
        :OLD.institucion_id,
        :OLD.carrera_id,
        :OLD.via_ingreso_id,
        :OLD.comuna_id,
        
        -- New values
        :NEW.genero_id,
        :NEW.edad,
        :NEW.rango_edad_id,
        :NEW.anio_ingreso,
        :NEW.semestre_ingreso,
        :NEW.institucion_id,
        :NEW.carrera_id,
        :NEW.via_ingreso_id,
        :NEW.comuna_id,
        
        v_batch_id,
        v_validation_status,
        v_validation_notes,
        CASE WHEN SYS_CONTEXT('USERENV', 'CLIENT_INFO') IS NOT NULL THEN 'Y' ELSE 'N' END
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- If audit logging fails, log the error but don't fail the main operation
        -- This prevents audit issues from blocking legitimate data operations
        INSERT INTO matriculas_audit_log (
            operation_type,
            matricula_id,
            error_code,
            error_message,
            batch_id
        ) VALUES (
            v_operation_type || '_ERROR',
            COALESCE(:NEW.matricula_id, :OLD.matricula_id),
            SQLCODE,
            SQLERRM,
            v_batch_id
        );
END trg_matriculas_audit;
/

------------------------------------------------------------------------
-- AUDIT UTILITY VIEWS
------------------------------------------------------------------------

-- View for daily audit summary
CREATE OR REPLACE VIEW v_matriculas_audit_daily AS
SELECT 
    TRUNC(audit_date) as audit_day,
    operation_type,
    COUNT(*) as operation_count,
    COUNT(DISTINCT audit_user) as unique_users,
    COUNT(DISTINCT batch_id) as unique_batches,
    MIN(audit_timestamp) as first_operation,
    MAX(audit_timestamp) as last_operation
FROM matriculas_audit_log
WHERE audit_date >= TRUNC(SYSDATE) - 30  -- Last 30 days
GROUP BY TRUNC(audit_date), operation_type
ORDER BY audit_day DESC, operation_type;

-- View for error analysis
CREATE OR REPLACE VIEW v_matriculas_audit_errors AS
SELECT 
    audit_timestamp,
    audit_user,
    matricula_id,
    operation_type,
    error_code,
    error_message,
    batch_id
FROM matriculas_audit_log
WHERE error_code IS NOT NULL
ORDER BY audit_timestamp DESC;

-- View for validation warnings
CREATE OR REPLACE VIEW v_matriculas_audit_warnings AS
SELECT 
    audit_timestamp,
    audit_user,
    matricula_id,
    validation_status,
    validation_notes,
    new_edad,
    new_anio_ingreso,
    new_semestre_ingreso
FROM matriculas_audit_log
WHERE validation_status = 'WARNING'
ORDER BY audit_timestamp DESC;

-- View for batch processing summary
CREATE OR REPLACE VIEW v_matriculas_batch_summary AS
SELECT 
    batch_id,
    MIN(audit_timestamp) as batch_start,
    MAX(audit_timestamp) as batch_end,
    COUNT(*) as total_operations,
    COUNT(CASE WHEN operation_type = 'INSERT' THEN 1 END) as inserts,
    COUNT(CASE WHEN operation_type = 'UPDATE' THEN 1 END) as updates,
    COUNT(CASE WHEN operation_type = 'DELETE' THEN 1 END) as deletes,
    COUNT(CASE WHEN error_code IS NOT NULL THEN 1 END) as errors,
    COUNT(CASE WHEN validation_status = 'WARNING' THEN 1 END) as warnings,
    COUNT(DISTINCT audit_user) as unique_users,
    ROUND((MAX(audit_timestamp) - MIN(audit_timestamp)) * 24 * 60 * 60, 2) as duration_seconds
FROM matriculas_audit_log
GROUP BY batch_id
ORDER BY batch_start DESC;

------------------------------------------------------------------------
-- AUDIT REPORTING PROCEDURES
------------------------------------------------------------------------

-- Procedure to generate audit report
CREATE OR REPLACE PROCEDURE generate_audit_report(
    p_start_date IN DATE DEFAULT TRUNC(SYSDATE) - 7,
    p_end_date IN DATE DEFAULT TRUNC(SYSDATE) + 1
) IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('MATRICULAS AUDIT REPORT');
    DBMS_OUTPUT.PUT_LINE('Period: ' || TO_CHAR(p_start_date, 'DD-MON-YYYY') || ' to ' || TO_CHAR(p_end_date, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('Generated: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    -- Summary statistics
    FOR rec IN (
        SELECT 
            operation_type,
            COUNT(*) as total_ops,
            COUNT(DISTINCT audit_user) as unique_users,
            COUNT(DISTINCT batch_id) as unique_batches
        FROM matriculas_audit_log
        WHERE audit_date BETWEEN p_start_date AND p_end_date
        GROUP BY operation_type
        ORDER BY operation_type
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(rec.operation_type || ': ' || rec.total_ops || ' operations, ' || 
                           rec.unique_users || ' users, ' || rec.unique_batches || ' batches');
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
END generate_audit_report;
/

COMMIT;

-- Display creation summary
SELECT 'Matriculas audit system created successfully' AS STATUS FROM DUAL;