-- ============================================================================
-- IMPORT THIS FILE IN PHPMYADMIN AFTER adfc_onecampus_updated (1).sql
-- Target database: adfc_onecampus
-- Contains required LMS migrations 001 and 002.
-- Safe to rerun. It does not delete master records.
-- ============================================================================

SET NAMES utf8mb4;
USE `adfc_onecampus`;

-- ---------------------------------------------------------------------------
-- MIGRATION 001: Prepare stable shared identifiers and LMS read projections
-- ---------------------------------------------------------------------------

SET @previous_safe_updates := @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;

UPDATE users
SET user_uid = CONCAT('USER-', LPAD(user_id, 10, '0'))
WHERE user_uid IS NULL OR TRIM(user_uid) = '';

UPDATE students
SET student_uid = CONCAT('STUDENT-', LPAD(student_id, 10, '0'))
WHERE student_uid IS NULL OR TRIM(student_uid) = '';

UPDATE instructors
SET instructor_uid = CONCAT('INSTRUCTOR-', LPAD(instructor_id, 10, '0'))
WHERE instructor_uid IS NULL OR TRIM(instructor_uid) = '';

UPDATE subjects
SET subject_uid = CONCAT('SUBJECT-', LPAD(subject_id, 10, '0'))
WHERE subject_uid IS NULL OR TRIM(subject_uid) = '';

UPDATE programs
SET program_uid = CONCAT('PROGRAM-', LPAD(program_id, 10, '0'))
WHERE program_uid IS NULL OR TRIM(program_uid) = '';

UPDATE academic_classes
SET class_uid = CONCAT('CLASS-', LPAD(class_id, 10, '0'))
WHERE class_uid IS NULL OR TRIM(class_uid) = '';

UPDATE class_enrollments
SET enrollment_uid = CONCAT('CLASS-ENROLLMENT-', LPAD(enrollment_id, 10, '0'))
WHERE enrollment_uid IS NULL OR TRIM(enrollment_uid) = '';

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_lms_users AS
SELECT
    u.user_uid AS external_user_id,
    u.user_id,
    u.username,
    LOWER(COALESCE(NULLIF(u.email, ''), NULLIF(s.email, ''))) AS email,
    u.full_name,
    COALESCE(s.student_number, i.employee_number, u.username, u.user_uid) AS school_id,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM user_access_roles uar
            INNER JOIN access_roles ar ON ar.role_id = uar.role_id
            WHERE uar.user_id = u.user_id
              AND uar.module_code = 'lms'
              AND ar.role_name = 'Administrator'
              AND ar.is_active = 1
        ) THEN 'admin'
        WHEN i.instructor_id IS NOT NULL AND i.is_active = 1 AND EXISTS (
            SELECT 1 FROM user_access_roles uar
            INNER JOIN access_roles ar ON ar.role_id = uar.role_id
            WHERE uar.user_id = u.user_id AND uar.module_code = 'lms'
              AND ar.role_name = 'Instructor' AND ar.is_active = 1
        ) THEN 'instructor'
        WHEN s.student_id IS NOT NULL AND s.record_status = 'Active' AND EXISTS (
            SELECT 1 FROM user_access_roles uar
            INNER JOIN access_roles ar ON ar.role_id = uar.role_id
            WHERE uar.user_id = u.user_id AND uar.module_code = 'lms'
              AND ar.role_name = 'Student' AND ar.is_active = 1
        ) AND EXISTS (
            SELECT 1 FROM class_enrollments ce
            WHERE ce.student_id = s.student_id AND ce.membership_status = 'Active'
        ) THEN 'student'
        ELSE NULL
    END AS lms_role,
    CASE WHEN u.status = 'Active' THEN 'active' ELSE 'inactive' END AS lms_status,
    s.student_id,
    i.instructor_id
FROM users u
LEFT JOIN students s ON s.student_id = u.student_id
LEFT JOIN instructors i ON i.user_id = u.user_id
WHERE EXISTS (
       SELECT 1
       FROM user_access_roles uar
       INNER JOIN access_roles ar ON ar.role_id = uar.role_id
       WHERE uar.user_id = u.user_id
         AND uar.module_code = 'lms'
         AND ar.is_active = 1
         AND ar.role_name IN ('Administrator', 'Instructor', 'Student')
   );

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_lms_subjects AS
SELECT
    s.subject_uid AS external_subject_id,
    s.subject_id,
    s.subject_code,
    s.subject_title,
    s.description,
    s.units,
    s.status,
    p.program_uid AS external_program_id,
    p.program_code,
    p.program_name
FROM subjects s
LEFT JOIN programs p ON p.program_id = s.program_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_lms_classes AS
SELECT
    c.class_uid AS external_class_id,
    c.class_id,
    c.class_code,
    c.section,
    c.status,
    s.subject_uid AS external_subject_id,
    s.subject_code,
    s.subject_title,
    p.academic_year,
    p.semester,
    u.user_uid AS external_instructor_user_id,
    u.full_name AS instructor_name,
    pr.program_uid AS external_program_id,
    pr.program_code,
    pr.program_name
FROM academic_classes c
INNER JOIN subjects s ON s.subject_id = c.subject_id
INNER JOIN academic_periods p ON p.period_id = c.period_id
LEFT JOIN instructors i ON i.instructor_id = c.instructor_id
LEFT JOIN users u ON u.user_id = i.user_id
LEFT JOIN programs pr ON pr.program_id = c.program_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_lms_class_schedules AS
SELECT
    c.class_uid AS external_class_id,
    c.class_code,
    m.meeting_id,
    m.class_type,
    m.day_of_week,
    m.start_time,
    m.end_time,
    m.status AS meeting_status,
    r.room_code,
    r.building,
    r.room_type
FROM academic_classes c
INNER JOIN class_meetings m ON m.class_id = c.class_id
INNER JOIN rooms r ON r.room_id = m.room_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_lms_enrollments AS
SELECT
    e.enrollment_uid AS external_enrollment_id,
    e.enrollment_id,
    c.class_uid AS external_class_id,
    c.class_code,
    u.user_uid AS external_student_user_id,
    s.student_uid AS external_student_id,
    s.student_number,
    u.full_name AS student_name,
    e.membership_status,
    e.enrolled_at
FROM class_enrollments e
INNER JOIN academic_classes c ON c.class_id = e.class_id
INNER JOIN students s ON s.student_id = e.student_id
LEFT JOIN users u ON u.student_id = s.student_id;

INSERT IGNORE INTO schema_migrations (module_code, migration_name, batch)
VALUES ('lms', '2026_11_17_lms_shared_data_v1', 1);

SET SQL_SAFE_UPDATES = @previous_safe_updates;

-- ---------------------------------------------------------------------------
-- MIGRATION 002: Create the LMS subsystem administrator
-- Username: adfc_lms
-- Initial password: adfc1984 (stored as bcrypt, not plaintext)
-- ---------------------------------------------------------------------------

INSERT INTO users (
    user_uid,
    username,
    email,
    password_hash,
    full_name,
    status,
    email_verified_at,
    must_change_password,
    session_version
) VALUES (
    'USER-LMS-ADMIN-0001',
    'adfc_lms',
    'marctucay321321@gmail.com',
    '$2y$10$sXbPk4cEnDlcdF7fYYMKtOgx0krvINSKySUWJbbRGkUzuE2McAbVO',
    'ADFC LMS Administrator',
    'Active',
    NOW(),
    1,
    1
)
ON DUPLICATE KEY UPDATE
    user_uid = VALUES(user_uid),
    username = VALUES(username),
    email = VALUES(email),
    password_hash = VALUES(password_hash),
    full_name = VALUES(full_name),
    status = 'Active',
    email_verified_at = COALESCE(email_verified_at, NOW()),
    must_change_password = 1,
    session_version = session_version + 1;

INSERT IGNORE INTO user_access_roles (user_id, role_id, module_code)
SELECT u.user_id, ar.role_id, 'lms'
FROM users u
INNER JOIN access_roles ar ON ar.role_name = 'Administrator'
WHERE u.username = 'adfc_lms';

INSERT IGNORE INTO schema_migrations (module_code, migration_name, batch)
VALUES ('lms', '2026_11_17_lms_administrator_v1', 1);

-- Quick success result shown by phpMyAdmin.
SELECT
    u.username,
    u.email,
    u.status,
    ar.role_name,
    uar.module_code
FROM users u
INNER JOIN user_access_roles uar ON uar.user_id = u.user_id
INNER JOIN access_roles ar ON ar.role_id = uar.role_id
WHERE u.username = 'adfc_lms'
  AND uar.module_code = 'lms';