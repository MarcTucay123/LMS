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
SELECT 'missing_quiz_attachment_path_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='quizzes' AND column_name='attachment_path'
UNION ALL
SELECT 'missing_quiz_attachment_name_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='quizzes' AND column_name='attachment_name'
UNION ALL
SELECT 'missing_quiz_attempt_submission_file_path_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='quiz_attempts' AND column_name='submission_file_path'
UNION ALL
SELECT 'missing_quiz_attempt_submission_file_name_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='quiz_attempts' AND column_name='submission_file_name'
UNION ALL
SELECT 'missing_quiz_file_submission_points_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='quizzes' AND column_name='file_submission_points'
UNION ALL
SELECT 'missing_quiz_attempt_submission_file_score_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='quiz_attempts' AND column_name='submission_file_score'
UNION ALL
SELECT 'missing_discussion_post_is_pinned_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='is_pinned'
UNION ALL
SELECT 'missing_discussion_post_pinned_by_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='pinned_by'
UNION ALL
SELECT 'missing_discussion_post_pinned_at_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='pinned_at'
UNION ALL
SELECT 'missing_discussion_topic_is_pinned_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='learning_discussion_topics' AND column_name='is_pinned'
UNION ALL
SELECT 'missing_discussion_topic_pinned_by_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='learning_discussion_topics' AND column_name='pinned_by'
UNION ALL
SELECT 'missing_discussion_topic_pinned_at_column', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.columns
WHERE table_schema=DATABASE() AND table_name='learning_discussion_topics' AND column_name='pinned_at'
UNION ALL
SELECT 'missing_discussion_post_reply_to_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='reply_to_id'
UNION ALL
SELECT 'missing_discussion_post_unique_id_index', IF(COUNT(*) >= 1, 0, 1) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='id' AND non_unique=0
UNION ALL
SELECT 'missing_discussion_post_is_deleted_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='is_deleted'
UNION ALL
SELECT 'missing_discussion_post_deleted_at_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='deleted_at'
UNION ALL
SELECT 'missing_discussion_post_deleted_by_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='deleted_by'
UNION ALL
SELECT 'missing_discussion_post_reactions_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='learning_discussion_post_reactions'
UNION ALL
SELECT 'missing_discussion_reaction_user_unique_index', IF(COUNT(*) = 2, 0, 1) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='learning_discussion_post_reactions' AND index_name='uq_lms_discussion_reaction_user'
UNION ALL
SELECT 'missing_discussion_memberships_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='learning_discussion_memberships'
UNION ALL
SELECT 'missing_discussion_membership_primary_key', IF(COUNT(*) = 2, 0, 1) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='learning_discussion_memberships' AND index_name='PRIMARY'
UNION ALL
SELECT 'missing_discussion_membership_muted_until_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_memberships' AND column_name='muted_until'
UNION ALL
SELECT 'missing_discussion_membership_last_read_post_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_memberships' AND column_name='last_read_post_id'
UNION ALL
SELECT 'missing_discussion_membership_last_read_at_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_memberships' AND column_name='last_read_at'
UNION ALL
SELECT 'missing_discussion_membership_last_read_index', IF(COUNT(*) = 3, 0, 1) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='learning_discussion_memberships' AND index_name='ix_lms_discussion_last_read'
UNION ALL
SELECT 'missing_discussion_post_attachment_path_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='attachment_path'
UNION ALL
SELECT 'missing_discussion_post_attachment_name_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='attachment_name'
UNION ALL
SELECT 'missing_discussion_post_attachment_mime_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='attachment_mime'
UNION ALL
SELECT 'missing_discussion_post_attachment_size_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='attachment_size'
UNION ALL
SELECT 'missing_discussion_post_attachment_kind_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='attachment_kind'
UNION ALL
SELECT 'missing_user_profiles_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='user_profiles'
UNION ALL
SELECT 'missing_user_profiles_avatar_path_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='avatar_path'
UNION ALL
SELECT 'missing_discussion_live_sessions_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='discussion_live_sessions'
UNION ALL
SELECT 'missing_discussion_live_participants_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='discussion_live_participants'
UNION ALL
SELECT 'missing_discussion_live_events_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='discussion_live_events'
UNION ALL
SELECT 'missing_discussion_live_signals_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='discussion_live_signals'
UNION ALL
SELECT 'obsolete_discussion_live_session_type_column', COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='discussion_live_sessions' AND column_name='session_type'
UNION ALL
SELECT 'missing_discussion_live_attendance_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='discussion_live_participants' AND column_name='is_attending'
UNION ALL
SELECT 'missing_discussion_live_screen_sharing_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='discussion_live_participants' AND column_name='screen_sharing'
UNION ALL
SELECT 'missing_discussion_live_attachment_path_column', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='discussion_live_events' AND column_name='attachment_path'
UNION ALL
SELECT 'missing_discussion_live_attendance_history_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='discussion_live_attendance_history'
UNION ALL
SELECT 'missing_learning_modules_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='learning_modules'
UNION ALL
SELECT 'missing_learning_module_items_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='learning_module_items'
UNION ALL
SELECT 'missing_learning_item_completions_table', IF(COUNT(*) = 1, 0, 1) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='learning_item_completions'
UNION ALL
SELECT 'legacy_short_answer_questions', COUNT(*)
FROM quiz_questions WHERE question_type='short_answer'
UNION ALL
SELECT 'missing_live_quiz_sessions_table', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.tables
WHERE table_schema=DATABASE() AND table_name='quiz_live_sessions'
UNION ALL
SELECT 'missing_live_quiz_participants_table', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.tables
WHERE table_schema=DATABASE() AND table_name='quiz_live_participants'
UNION ALL
SELECT 'missing_live_quiz_responses_table', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.tables
WHERE table_schema=DATABASE() AND table_name='quiz_live_responses'
UNION ALL
SELECT 'missing_lms_security_settings_table', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.tables
WHERE table_schema=DATABASE() AND table_name='lms_security_settings'
UNION ALL
SELECT 'missing_lms_login_attempts_table', IF(COUNT(*) = 1, 0, 1)
FROM information_schema.tables
WHERE table_schema=DATABASE() AND table_name='lms_login_attempts'
UNION ALL
SELECT 'missing_lms_security_settings_row', IF(COUNT(*) = 1, 0, 1)
FROM lms_security_settings
WHERE settings_id=1
UNION ALL
SELECT 'missing_live_attendance_minimized_setting', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='lms_security_settings' AND column_name='live_attendance_minimized_enabled'
UNION ALL
SELECT 'missing_live_attendance_tab_hidden_setting', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='lms_security_settings' AND column_name='live_attendance_tab_hidden_enabled'
UNION ALL
SELECT 'missing_live_attendance_window_blur_setting', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='lms_security_settings' AND column_name='live_attendance_window_blur_enabled'
UNION ALL
SELECT 'missing_live_attendance_inactivity_setting', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='lms_security_settings' AND column_name='live_attendance_inactivity_enabled'
UNION ALL
SELECT 'missing_live_attendance_inactivity_seconds_setting', IF(COUNT(*) = 1, 0, 1) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='lms_security_settings' AND column_name='live_attendance_inactivity_seconds';

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
