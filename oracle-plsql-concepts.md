# Advanced Oracle PL/SQL Concepts for Matriculas Insert Procedure

This document explains how to enhance the matriculas insert procedure using advanced Oracle PL/SQL concepts to improve performance, maintainability, and error handling.

## 1. VARRAY (Variable Arrays)

### **What it is:**
A VARRAY is a collection type that holds a fixed number of elements of the same datatype.

### **How it impacts the code:**
Instead of processing records one by one, we can batch process multiple records using VARRARs for better performance.

```sql
-- Define VARRAY types for batch processing
TYPE t_matricula_ids IS VARRAY(1000) OF NUMBER;
TYPE t_genero_ids IS VARRAY(1000) OF NUMBER;
TYPE t_edades IS VARRAY(1000) OF NUMBER;
-- ... more arrays for other columns

DECLARE
    v_matricula_ids t_matricula_ids;
    v_genero_ids t_genero_ids;
    v_edades t_edades;
    -- ... other arrays
    v_batch_size CONSTANT NUMBER := 1000;
BEGIN
    -- Populate arrays with batch data
    v_matricula_ids := t_matricula_ids(16, 21, 22, 175, 222, ...);
    v_genero_ids := t_genero_ids(1, 2, 2, 2, 2, ...);
    
    -- Use FORALL for bulk insert (much faster than individual inserts)
    FORALL i IN 1..v_matricula_ids.COUNT
        INSERT INTO matriculas VALUES (
            v_matricula_ids(i), v_genero_ids(i), v_edades(i), ...
        );
END;
```

### **Benefits:**
- **Performance**: Bulk operations are 10-100x faster than row-by-row processing
- **Memory efficiency**: Fixed-size collections prevent memory bloat
- **Network reduction**: Fewer round trips between PL/SQL and SQL engines

---

## 2. RECORD Types

### **What it is:**
A RECORD is a composite datatype that groups related data together, similar to a struct in other languages.

### **How it impacts the code:**
Instead of managing multiple variables, we can use records to represent complete matricula entries.

```sql
-- Define record type for matricula data
TYPE t_matricula_rec IS RECORD (
    matricula_id    NUMBER,
    genero_id       NUMBER,
    edad            NUMBER,
    rango_edad_id   NUMBER,
    anio_ingreso    NUMBER,
    semestre_ingreso NUMBER,
    institucion_id  NUMBER,
    carrera_id      NUMBER,
    via_ingreso_id  NUMBER,
    comuna_id       NUMBER,
    error_flag      BOOLEAN DEFAULT FALSE,
    error_message   VARCHAR2(4000)
);

-- Define collection of records
TYPE t_matricula_tab IS TABLE OF t_matricula_rec INDEX BY PLS_INTEGER;

DECLARE
    v_matriculas t_matricula_tab;
    v_current_matricula t_matricula_rec;
BEGIN
    -- Process records in a more organized way
    FOR i IN 1..v_matriculas.COUNT LOOP
        v_current_matricula := v_matriculas(i);
        
        BEGIN
            INSERT INTO matriculas VALUES (
                v_current_matricula.matricula_id,
                v_current_matricula.genero_id,
                -- ... other fields
            );
        EXCEPTION
            WHEN OTHERS THEN
                v_matriculas(i).error_flag := TRUE;
                v_matriculas(i).error_message := SQLERRM;
        END;
    END LOOP;
END;
```

### **Benefits:**
- **Organization**: Groups related data logically
- **Maintainability**: Easier to add/remove fields
- **Type safety**: Compile-time checking of field access
- **Readability**: Self-documenting code structure

---

## 3. Custom Exceptions

### **What it is:**
User-defined exceptions that provide specific error handling for business logic scenarios.

### **How it impacts the code:**
Create specific exceptions for different types of matricula insertion failures.

```sql
DECLARE
    -- Custom exceptions
    exc_foreign_key_violation EXCEPTION;
    exc_duplicate_matricula EXCEPTION;
    exc_invalid_data_range EXCEPTION;
    exc_too_many_errors EXCEPTION;
    
    -- Associate exceptions with Oracle error codes
    PRAGMA EXCEPTION_INIT(exc_foreign_key_violation, -2291);
    PRAGMA EXCEPTION_INIT(exc_duplicate_matricula, -1);
    
    v_error_count NUMBER := 0;
    v_max_errors CONSTANT NUMBER := 10;
    
BEGIN
    -- Insert logic here
    FOR i IN 1..matricula_count LOOP
        BEGIN
            -- Validate data before insert
            IF edad < 15 OR edad > 80 THEN
                RAISE exc_invalid_data_range;
            END IF;
            
            INSERT INTO matriculas VALUES (...);
            
        EXCEPTION
            WHEN exc_foreign_key_violation THEN
                v_error_count := v_error_count + 1;
                log_error('Foreign key violation for matricula ' || matricula_id);
                
            WHEN exc_duplicate_matricula THEN
                v_error_count := v_error_count + 1;
                log_error('Duplicate matricula ID: ' || matricula_id);
                
            WHEN exc_invalid_data_range THEN
                v_error_count := v_error_count + 1;
                log_error('Invalid age range for matricula ' || matricula_id);
                
            WHEN OTHERS THEN
                v_error_count := v_error_count + 1;
                log_error('Unexpected error: ' || SQLERRM);
        END;
        
        -- Check if too many errors occurred
        IF v_error_count > v_max_errors THEN
            RAISE exc_too_many_errors;
        END IF;
    END LOOP;
    
EXCEPTION
    WHEN exc_too_many_errors THEN
        DBMS_OUTPUT.PUT_LINE('Process aborted: Too many errors (' || v_error_count || ')');
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Matricula insert failed due to excessive errors');
END;
```

### **Benefits:**
- **Specific handling**: Different recovery strategies for different error types
- **Better logging**: More descriptive error messages
- **Business logic**: Enforce business rules with appropriate exceptions
- **Debugging**: Easier to identify root causes of failures

---

## 4. Triggers

### **What it is:**
Database triggers that automatically execute in response to database events.

### **How it impacts the code:**
Triggers can handle auditing, validation, and business logic automatically.

```sql
-- Audit trigger for matriculas table
CREATE OR REPLACE TRIGGER trg_matriculas_audit
    BEFORE INSERT OR UPDATE OR DELETE ON matriculas
    FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
BEGIN
    CASE
        WHEN INSERTING THEN v_operation := 'INSERT';
        WHEN UPDATING THEN v_operation := 'UPDATE';
        WHEN DELETING THEN v_operation := 'DELETE';
    END CASE;
    
    -- Log the operation
    INSERT INTO matriculas_audit_log (
        operation_type,
        matricula_id,
        operation_date,
        operation_user,
        old_values,
        new_values
    ) VALUES (
        v_operation,
        COALESCE(:NEW.matricula_id, :OLD.matricula_id),
        SYSDATE,
        USER,
        CASE WHEN v_operation != 'INSERT' THEN 
            'genero_id:' || :OLD.genero_id || ',edad:' || :OLD.edad 
        END,
        CASE WHEN v_operation != 'DELETE' THEN 
            'genero_id:' || :NEW.genero_id || ',edad:' || :NEW.edad 
        END
    );
END;

-- Validation trigger
CREATE OR REPLACE TRIGGER trg_matriculas_validate
    BEFORE INSERT OR UPDATE ON matriculas
    FOR EACH ROW
BEGIN
    -- Validate age ranges
    IF :NEW.edad < 15 OR :NEW.edad > 80 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid age: ' || :NEW.edad);
    END IF;
    
    -- Validate year range
    IF :NEW.anio_ingreso < 2000 OR :NEW.anio_ingreso > EXTRACT(YEAR FROM SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Invalid year: ' || :NEW.anio_ingreso);
    END IF;
    
    -- Auto-populate audit fields if they exist
    :NEW.created_date := COALESCE(:NEW.created_date, SYSDATE);
    :NEW.created_by := COALESCE(:NEW.created_by, USER);
END;
```

### **Benefits:**
- **Automatic enforcement**: Business rules enforced at database level
- **Auditing**: Automatic tracking of all changes
- **Data integrity**: Cannot be bypassed by applications
- **Centralized logic**: Business rules in one place

---

## 5. Functions

### **What it is:**
Reusable code blocks that return a single value and can be used in SQL statements.

### **How it impacts the code:**
Functions can encapsulate complex validation logic and calculations.

```sql
-- Function to validate matricula data
CREATE OR REPLACE FUNCTION validate_matricula_data(
    p_edad IN NUMBER,
    p_anio_ingreso IN NUMBER,
    p_semestre_ingreso IN NUMBER,
    p_genero_id IN NUMBER
) RETURN VARCHAR2 IS
    v_error_msg VARCHAR2(4000) := NULL;
BEGIN
    -- Age validation
    IF p_edad < 15 OR p_edad > 80 THEN
        v_error_msg := v_error_msg || 'Invalid age (' || p_edad || '). ';
    END IF;
    
    -- Year validation
    IF p_anio_ingreso < 2000 OR p_anio_ingreso > EXTRACT(YEAR FROM SYSDATE) THEN
        v_error_msg := v_error_msg || 'Invalid year (' || p_anio_ingreso || '). ';
    END IF;
    
    -- Semester validation
    IF p_semestre_ingreso NOT IN (1, 2) THEN
        v_error_msg := v_error_msg || 'Invalid semester (' || p_semestre_ingreso || '). ';
    END IF;
    
    -- Gender validation
    IF p_genero_id NOT IN (1, 2) THEN
        v_error_msg := v_error_msg || 'Invalid gender ID (' || p_genero_id || '). ';
    END IF;
    
    RETURN TRIM(v_error_msg);
END validate_matricula_data;

-- Function to calculate age range ID
CREATE OR REPLACE FUNCTION get_rango_edad_id(p_edad IN NUMBER) RETURN NUMBER IS
BEGIN
    RETURN CASE 
        WHEN p_edad BETWEEN 15 AND 19 THEN 1
        WHEN p_edad BETWEEN 20 AND 24 THEN 2
        WHEN p_edad BETWEEN 25 AND 29 THEN 3
        WHEN p_edad BETWEEN 30 AND 34 THEN 4
        WHEN p_edad BETWEEN 35 AND 39 THEN 5
        WHEN p_edad >= 40 THEN 6
        ELSE NULL
    END;
END get_rango_edad_id;

-- Using functions in the main procedure
DECLARE
    v_validation_error VARCHAR2(4000);
BEGIN
    FOR i IN 1..matricula_count LOOP
        -- Validate before insert
        v_validation_error := validate_matricula_data(
            p_edad => v_edad,
            p_anio_ingreso => v_anio_ingreso,
            p_semestre_ingreso => v_semestre_ingreso,
            p_genero_id => v_genero_id
        );
        
        IF v_validation_error IS NOT NULL THEN
            log_error('Validation failed for matricula ' || v_matricula_id || ': ' || v_validation_error);
            CONTINUE;
        END IF;
        
        -- Auto-calculate age range
        v_rango_edad_id := get_rango_edad_id(v_edad);
        
        INSERT INTO matriculas VALUES (...);
    END LOOP;
END;
```

### **Benefits:**
- **Reusability**: Same validation logic used across multiple procedures
- **Testability**: Functions can be tested independently
- **SQL integration**: Can be used directly in SQL queries
- **Modularity**: Complex logic broken into manageable pieces

---

## 6. Procedures

### **What it is:**
Reusable code blocks that perform specific tasks and can accept parameters.

### **How it impacts the code:**
Procedures can modularize the insert process into logical components.

```sql
-- Procedure to log errors
CREATE OR REPLACE PROCEDURE log_matricula_error(
    p_matricula_id IN NUMBER,
    p_error_code IN NUMBER,
    p_error_message IN VARCHAR2,
    p_error_context IN VARCHAR2 DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO matricula_error_log (
        log_id,
        matricula_id,
        error_code,
        error_message,
        error_context,
        error_date,
        session_user
    ) VALUES (
        matricula_error_log_seq.NEXTVAL,
        p_matricula_id,
        p_error_code,
        p_error_message,
        p_error_context,
        SYSDATE,
        USER
    );
    COMMIT;
END log_matricula_error;

-- Procedure to process a batch of matriculas
CREATE OR REPLACE PROCEDURE process_matricula_batch(
    p_batch_data IN t_matricula_tab,
    p_batch_id IN NUMBER,
    p_success_count OUT NUMBER,
    p_error_count OUT NUMBER
) IS
    v_current_matricula t_matricula_rec;
BEGIN
    p_success_count := 0;
    p_error_count := 0;
    
    FOR i IN 1..p_batch_data.COUNT LOOP
        v_current_matricula := p_batch_data(i);
        
        BEGIN
            INSERT INTO matriculas VALUES (
                v_current_matricula.matricula_id,
                v_current_matricula.genero_id,
                v_current_matricula.edad,
                v_current_matricula.rango_edad_id,
                v_current_matricula.anio_ingreso,
                v_current_matricula.semestre_ingreso,
                v_current_matricula.institucion_id,
                v_current_matricula.carrera_id,
                v_current_matricula.via_ingreso_id,
                v_current_matricula.comuna_id
            );
            
            p_success_count := p_success_count + 1;
            
        EXCEPTION
            WHEN OTHERS THEN
                p_error_count := p_error_count + 1;
                log_matricula_error(
                    p_matricula_id => v_current_matricula.matricula_id,
                    p_error_code => SQLCODE,
                    p_error_message => SQLERRM,
                    p_error_context => 'Batch ' || p_batch_id || ', Record ' || i
                );
        END;
    END LOOP;
END process_matricula_batch;

-- Main procedure using all components
CREATE OR REPLACE PROCEDURE insert_all_matriculas IS
    v_batch_data t_matricula_tab;
    v_batch_size CONSTANT NUMBER := 1000;
    v_total_success NUMBER := 0;
    v_total_errors NUMBER := 0;
    v_batch_success NUMBER;
    v_batch_errors NUMBER;
    v_batch_id NUMBER := 1;
BEGIN
    -- Load and process data in batches
    WHILE load_next_batch(v_batch_data, v_batch_size) > 0 LOOP
        process_matricula_batch(
            p_batch_data => v_batch_data,
            p_batch_id => v_batch_id,
            p_success_count => v_batch_success,
            p_error_count => v_batch_errors
        );
        
        v_total_success := v_total_success + v_batch_success;
        v_total_errors := v_total_errors + v_batch_errors;
        v_batch_id := v_batch_id + 1;
        
        -- Commit each successful batch
        IF v_batch_errors = 0 THEN
            COMMIT;
        ELSIF v_batch_errors <= 5 THEN -- Configurable threshold
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Batch ' || v_batch_id || ' completed with ' || v_batch_errors || ' errors');
        ELSE
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Batch ' || v_batch_id || ' failed with too many errors: ' || v_batch_errors);
        END IF;
    END LOOP;
    
    -- Final summary
    DBMS_OUTPUT.PUT_LINE('Total successful inserts: ' || v_total_success);
    DBMS_OUTPUT.PUT_LINE('Total errors: ' || v_total_errors);
END insert_all_matriculas;
```

### **Benefits:**
- **Modularity**: Complex process broken into manageable components
- **Reusability**: Procedures can be called from multiple contexts
- **Parameter passing**: Flexible input/output parameter handling
- **Transaction control**: Each procedure can manage its own transaction scope

---

## Complete Enhanced Architecture

### **Putting It All Together:**

```sql
-- 1. Define types (VARRAYs and RECORDs)
TYPE t_matricula_rec IS RECORD (...);
TYPE t_matricula_tab IS TABLE OF t_matricula_rec;

-- 2. Create utility functions
FUNCTION validate_matricula_data(...) RETURN VARCHAR2;
FUNCTION get_rango_edad_id(p_edad NUMBER) RETURN NUMBER;

-- 3. Create processing procedures
PROCEDURE log_matricula_error(...);
PROCEDURE process_matricula_batch(...);

-- 4. Create triggers for automatic validation
CREATE TRIGGER trg_matriculas_validate ...;
CREATE TRIGGER trg_matriculas_audit ...;

-- 5. Define custom exceptions
exc_foreign_key_violation EXCEPTION;
exc_duplicate_matricula EXCEPTION;
-- ... more exceptions

-- 6. Main processing procedure
PROCEDURE insert_all_matriculas IS
    -- Use all concepts together for robust, efficient processing
BEGIN
    -- Batch processing with VARRAYs
    -- Data validation with functions
    -- Error handling with custom exceptions
    -- Modular processing with procedures
    -- Automatic auditing with triggers
    -- Structured data with records
END;
```

### **Overall Benefits:**

1. **Performance**: 10-100x faster with bulk operations
2. **Maintainability**: Modular, well-organized code
3. **Reliability**: Comprehensive error handling and validation
4. **Auditability**: Complete tracking of all operations
5. **Scalability**: Handles large datasets efficiently
6. **Flexibility**: Easy to modify and extend

This architecture transforms a simple insert script into a robust, enterprise-grade data loading system that can handle real-world challenges like data validation, error recovery, performance optimization, and audit requirements.