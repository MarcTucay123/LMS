-- ============================================================================
-- LMS migration 009: Quiz and exam attachments and file submissions
-- Target database: adfc_onecampus
-- Safe to rerun.
-- ============================================================================

USE `adfc_onecampus`;

SET @quiz_attachment_path_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='quizzes' AND column_name='attachment_path'
);
SET @quiz_attachment_path_sql := IF(@quiz_attachment_path_missing,
    'ALTER TABLE quizzes ADD COLUMN attachment_path VARCHAR(1000) NULL AFTER description', 'SELECT 1');
PREPARE quiz_attachment_path_statement FROM @quiz_attachment_path_sql;
EXECUTE quiz_attachment_path_statement;
DEALLOCATE PREPARE quiz_attachment_path_statement;

SET @quiz_attachment_name_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='quizzes' AND column_name='attachment_name'
);
SET @quiz_attachment_name_sql := IF(@quiz_attachment_name_missing,
    'ALTER TABLE quizzes ADD COLUMN attachment_name VARCHAR(255) NULL AFTER attachment_path', 'SELECT 1');
PREPARE quiz_attachment_name_statement FROM @quiz_attachment_name_sql;
EXECUTE quiz_attachment_name_statement;
DEALLOCATE PREPARE quiz_attachment_name_statement;

SET @attempt_file_path_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='quiz_attempts' AND column_name='submission_file_path'
);
SET @attempt_file_path_sql := IF(@attempt_file_path_missing,
    'ALTER TABLE quiz_attempts ADD COLUMN submission_file_path VARCHAR(1000) NULL AFTER essay_scores', 'SELECT 1');
PREPARE attempt_file_path_statement FROM @attempt_file_path_sql;
EXECUTE attempt_file_path_statement;
DEALLOCATE PREPARE attempt_file_path_statement;

SET @attempt_file_name_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='quiz_attempts' AND column_name='submission_file_name'
);
SET @attempt_file_name_sql := IF(@attempt_file_name_missing,
    'ALTER TABLE quiz_attempts ADD COLUMN submission_file_name VARCHAR(255) NULL AFTER submission_file_path', 'SELECT 1');
PREPARE attempt_file_name_statement FROM @attempt_file_name_sql;
EXECUTE attempt_file_name_statement;
DEALLOCATE PREPARE attempt_file_name_statement;

INSERT INTO schema_migrations (module_code,migration_name,batch,applied_at)
SELECT 'lms','2026_11_25_lms_quiz_exam_files_v1',6,NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM schema_migrations
    WHERE module_code='lms' AND migration_name='2026_11_25_lms_quiz_exam_files_v1'
);