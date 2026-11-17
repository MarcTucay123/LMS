-- Run after migrations 001 through 004. Every failed_check value should be 0.

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
  AND ar.role_name = 'Administrator'
UNION ALL
SELECT 'lms_admin_invalid_user_id', COUNT(*)
FROM users
WHERE username = 'adfc_lms'
  AND user_id = 0
UNION ALL
SELECT 'lms_admin_missing_user_uid', COUNT(*)
FROM users
WHERE username = 'adfc_lms'
  AND (user_uid IS NULL OR TRIM(user_uid) = '')
UNION ALL
SELECT 'confirmed_students_missing_lms_role', COUNT(*)
FROM enrollments e
JOIN users u ON u.student_id=e.student_id
WHERE e.enrollment_status='Confirmed'
  AND NOT EXISTS (
      SELECT 1 FROM user_access_roles uar
      JOIN access_roles ar ON ar.role_id=uar.role_id
      WHERE uar.user_id=u.user_id AND uar.module_code='lms'
        AND ar.role_name='Student' AND ar.is_active=1
  )
UNION ALL
SELECT 'confirmed_subjects_missing_active_membership', COUNT(*)
FROM enrollments e
JOIN enrollment_subjects es ON es.enrollment_id=e.enrollment_id AND es.subject_status='Enrolled'
JOIN blocks b ON b.block_id=e.block_id
JOIN academic_classes c ON c.period_id=e.period_id AND c.subject_id=es.subject_id AND c.section=b.block_code
LEFT JOIN class_enrollments ce ON ce.student_id=e.student_id AND ce.class_id=c.class_id AND ce.membership_status='Active'
WHERE e.enrollment_status='Confirmed' AND c.status='Active' AND ce.enrollment_id IS NULL
UNION ALL
SELECT 'missing_quiz_assessment_kind_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='quizzes' AND column_name='assessment_kind'
UNION ALL
SELECT 'missing_quiz_exam_type_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='quizzes' AND column_name='exam_type'
UNION ALL
SELECT 'missing_quiz_attempt_essay_scores_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='quiz_attempts' AND column_name='essay_scores'
UNION ALL
SELECT 'legacy_short_answer_questions', COUNT(*)
FROM quiz_questions WHERE question_type='short_answer';

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
