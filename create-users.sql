-- This script must be run by a user with administrative privileges (e.g., SYS AS SYSDBA).
-- Enable output to see the status messages.
SET SERVEROUTPUT ON;

-- This script is a self-contained PL/SQL block.
-- All configuration is done in the DECLARE section below.
DECLARE
    -- =========================================================================
    -- CONFIG (EDIT THE VALUES IN THIS SECTION BEFORE RUNNING)
    -- =========================================================================
    -- USER and ROLE settings
    v_username                    VARCHAR2(128) := 'CRISAGUILA';
    v_password                    VARCHAR2(128) := 'duocMAT4141#2025'; -- Passwords with special chars are handled.
    v_role_name                   VARCHAR2(128) := 'SUPER_USER';

    -- Tablespace, quota, and profile settings
    v_default_tablespace          VARCHAR2(128) := 'USERS';
    v_temp_tablespace             VARCHAR2(128) := 'TEMP';
    v_quota_on_default_ts         VARCHAR2(30)  := 'UNLIMITED'; -- e.g., '50M', '1G', 'UNLIMITED'
    v_profile                     VARCHAR2(128) := 'DEFAULT';

    -- Account behavior settings
    v_account_locked              VARCHAR2(3)   := 'NO';  -- Use 'YES' or 'NO'
    v_password_expire             VARCHAR2(3)   := 'YES'; -- Use 'YES' or 'NO'

    -- Privilege settings
    v_grant_create_any_index      VARCHAR2(3)   := 'NO';  -- 'YES' grants the powerful CREATE ANY INDEX privilege.
    v_add_system_privs            VARCHAR2(1000) := NULL; -- Comma-separated list or leave NULL.
    v_grant_role_with_admin_option VARCHAR2(3)   := 'NO';  -- 'YES' allows the user to grant this role to others.
    -- =========================================================================
    -- END CONFIG
    -- =========================================================================
    l_sql VARCHAR2(4000);

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Script Started ---');

    -- 1) Create role (idempotent pattern)
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 1) Processing Role: ' || v_role_name || ' ---');
    BEGIN
        EXECUTE IMMEDIATE 'CREATE ROLE ' || v_role_name;
        DBMS_OUTPUT.PUT_LINE('SUCCESS: Role ''' || v_role_name || ''' created.');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -1921 THEN -- ORA-01921: role name conflicts with another user or role name
                DBMS_OUTPUT.PUT_LINE('INFO: Role ''' || v_role_name || ''' already exists. Skipping creation.');
            ELSE
                RAISE;
            END IF;
    END;

    -- 2) Grant privileges to role
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 2) Granting privileges to role ''' || v_role_name || ''' ---');
    -- Core grants
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE TRIGGER, CREATE TYPE TO ' || v_role_name;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Granted core privileges (SESSION, TABLE, VIEW, TRIGGER, TYPE).');

    -- Optional additional privileges
    IF v_add_system_privs IS NOT NULL AND TRIM(v_add_system_privs) IS NOT NULL THEN
        EXECUTE IMMEDIATE 'GRANT ' || v_add_system_privs || ' TO ' || v_role_name;
        DBMS_OUTPUT.PUT_LINE('SUCCESS: Granted additional privileges: ' || v_add_system_privs);
    ELSE
        DBMS_OUTPUT.PUT_LINE('INFO: No additional system privileges to grant.');
    END IF;

    -- Optional powerful privilege (use with caution)
    IF UPPER(v_grant_create_any_index) = 'YES' THEN
        EXECUTE IMMEDIATE 'GRANT CREATE ANY INDEX TO ' || v_role_name;
        DBMS_OUTPUT.PUT_LINE('WARNING: Granted powerful privilege: CREATE ANY INDEX.');
    END IF;

    -- 3) Create user (idempotent pattern)
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 3) Processing User: ' || v_username || ' ---');
    BEGIN
        l_sql := 'CREATE USER ' || v_username ||
                 ' IDENTIFIED BY "' || v_password || '"' ||
                 ' DEFAULT TABLESPACE ' || v_default_tablespace ||
                 ' TEMPORARY TABLESPACE ' || v_temp_tablespace ||
                 ' QUOTA ' || v_quota_on_default_ts || ' ON ' || v_default_tablespace ||
                 ' PROFILE ' || v_profile;

        IF UPPER(v_password_expire) = 'YES' THEN
            l_sql := l_sql || ' PASSWORD EXPIRE';
        END IF;

        IF UPPER(v_account_locked) = 'YES' THEN
            l_sql := l_sql || ' ACCOUNT LOCK';
        ELSE
            l_sql := l_sql || ' ACCOUNT UNLOCK';
        END IF;

        EXECUTE IMMEDIATE l_sql;
        DBMS_OUTPUT.PUT_LINE('SUCCESS: User ''' || v_username || ''' created.');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -1920 THEN -- ORA-01920: user name conflicts with another user or role name
                DBMS_OUTPUT.PUT_LINE('INFO: User ''' || v_username || ''' already exists. Skipping creation.');
            ELSE
                RAISE;
            END IF;
    END;

    -- 4) Grant the role to the user
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 4) Granting role to user ---');
    l_sql := 'GRANT ' || v_role_name || ' TO ' || v_username;
    IF UPPER(v_grant_role_with_admin_option) = 'YES' THEN
        l_sql := l_sql || ' WITH ADMIN OPTION';
        EXECUTE IMMEDIATE l_sql;
        DBMS_OUTPUT.PUT_LINE('SUCCESS: Granted role ''' || v_role_name || ''' to ''' || v_username || ''' WITH ADMIN OPTION.');
    ELSE
        EXECUTE IMMEDIATE l_sql;
        DBMS_OUTPUT.PUT_LINE('SUCCESS: Granted role ''' || v_role_name || ''' to ''' || v_username || '''.');
    END IF;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Script Finished Successfully ---');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || '!!! An unexpected error occurred: ' || SQLERRM || ' !!!');
        RAISE;
END;
/


-- ===========================
-- Testing (run as the new user)
-- ===========================
-- 1) Connect as the new user:
-- CONNECT app_user/ChangeMe#2025

-- 2) Quick create tests:
-- CREATE TABLE test_tbl (id NUMBER PRIMARY KEY, txt VARCHAR2(100));
-- CREATE VIEW test_v AS SELECT id, txt FROM test_tbl;
-- The following CREATE INDEX is implicitly handled by the PRIMARY KEY constraint.
-- If additional indexes are needed, the user has the privilege via CREATE TABLE.


-- ===========================
-- Cleanup / revoke (if you need to remove)
-- ===========================
-- To undo the changes, run these commands as an admin user.
-- Remember to replace the role and username if you changed them.
--
-- REVOKE app_schema_builder FROM app_user;
-- DROP USER app_user CASCADE;
-- DROP ROLE app_schema_builder;