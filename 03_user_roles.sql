-- ============================================================
-- Boston Crime Reports Database
-- File: 03_user_roles.sql
-- Description: Role-based access control (RBAC) setup
-- Run as: superuser / database owner
-- ============================================================

-- ============================================================
-- 1. Create User Groups (Roles)
-- ============================================================

-- Read-only analysts: can query all tables
CREATE ROLE readonly_group NOLOGIN;

-- Read-write data engineers: can load and modify data
CREATE ROLE readwrite_group NOLOGIN;

-- ============================================================
-- 2. Grant Schema Usage
-- ============================================================

GRANT USAGE ON SCHEMA crimes TO readonly_group;
GRANT USAGE ON SCHEMA crimes TO readwrite_group;

-- ============================================================
-- 3. Grant Table Privileges
-- ============================================================

-- Read-only: SELECT only
GRANT SELECT ON ALL TABLES IN SCHEMA crimes TO readonly_group;

-- Read-write: SELECT + INSERT + UPDATE + DELETE
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA crimes TO readwrite_group;

-- Read-write also needs USAGE on sequences (for SERIAL columns)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA crimes TO readwrite_group;

-- ============================================================
-- 4. Ensure Future Tables Inherit Permissions
-- ============================================================

ALTER DEFAULT PRIVILEGES IN SCHEMA crimes
    GRANT SELECT ON TABLES TO readonly_group;

ALTER DEFAULT PRIVILEGES IN SCHEMA crimes
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO readwrite_group;

ALTER DEFAULT PRIVILEGES IN SCHEMA crimes
    GRANT USAGE, SELECT ON SEQUENCES TO readwrite_group;

-- ============================================================
-- 5. Create Individual Users and Assign to Groups
-- ============================================================

-- Data Analyst (read-only access)
CREATE USER analyst_user WITH PASSWORD 'SecurePass!1';
GRANT readonly_group TO analyst_user;

-- Data Engineer (read-write access)
CREATE USER engineer_user WITH PASSWORD 'SecurePass!2';
GRANT readwrite_group TO engineer_user;

-- ============================================================
-- 6. Revoke Public Access (security best practice)
-- ============================================================

-- Revoke default public schema privileges
REVOKE ALL ON SCHEMA crimes FROM PUBLIC;
REVOKE ALL ON DATABASE boston_crimes FROM PUBLIC;

-- ============================================================
-- 7. Verify Role Assignments
-- ============================================================

-- List all roles and their members
SELECT
    r.rolname          AS role_name,
    m.rolname          AS member_name,
    r.rolcanlogin      AS can_login,
    r.rolcreatedb      AS can_create_db
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
ORDER BY role_name;
