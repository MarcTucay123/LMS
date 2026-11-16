-- Run after 001 and 002. Every failed_check value should be 0.

USE `adfc_onecampus`;

SELECT 'users_without_uid' AS check_name, COUNT(*) AS failed_check
FROM users WHERE user_uid IS NULL OR TRIM(user_uid) = ''
UNION ALL
SELECT 'students_without_uid', COUNT(*) FROM students WHERE student_uid IS NULL OR TRIM(student_uid) = ''
UNION ALL
SELECT 'instructors_without_uid', COUNT(*) FROM instructors WHERE instructor_uid IS NULL OR TRIM(instructor_uid) = ''
UNION ALL
SELECT 'subjects_without_uid', COUNT(*) FROM subjects WHERE subject_uid IS NULL OR TRIM(subject_uid) = ''
UNION ALL
SELECT 'classes_without_uid', COUNT(*) FROM academic_classes WHERE class_uid IS NULL OR TRIM(class_uid) = ''
UNION ALL
SELECT 'enrollments_without_uid', COUNT(*) FROM class_enrollments WHERE enrollment_uid IS NULL OR TRIM(enrollment_uid) = ''
UNION ALL
SELECT 'missing_lms_admin', IF(COUNT(*) = 1, 0, 1)
FROM users u
INNER JOIN user_access_roles uar ON uar.user_id = u.user_id
INNER JOIN access_roles ar ON ar.role_id = uar.role_id
WHERE u.username = 'adfc_lms'
  AND u.status = 'Active'
  AND uar.module_code = 'lms'
  AND ar.role_name = 'Administrator';

SELECT 'vw_lms_users' AS projection, COUNT(*) AS row_count FROM vw_lms_users
UNION ALL
SELECT 'vw_lms_subjects', COUNT(*) FROM vw_lms_subjects
UNION ALL
SELECT 'vw_lms_classes', COUNT(*) FROM vw_lms_classes
UNION ALL
SELECT 'vw_lms_class_schedules', COUNT(*) FROM vw_lms_class_schedules
UNION ALL
SELECT 'vw_lms_enrollments', COUNT(*) FROM vw_lms_enrollments;

SELECT external_user_id, username, email, full_name, school_id, lms_role, lms_status
FROM vw_lms_users
ORDER BY lms_role, full_name;

SELECT external_class_id, class_code, subject_code, subject_title, academic_year,
       semester, external_instructor_user_id, instructor_name
FROM vw_lms_classes
ORDER BY class_code;

SELECT * FROM vw_lms_enrollments ORDER BY class_code, student_number;
