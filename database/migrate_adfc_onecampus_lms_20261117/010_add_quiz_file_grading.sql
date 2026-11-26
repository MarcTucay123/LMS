-- ============================================================================
-- LMS migration 010: Manual grading for quiz and exam file submissions
-- Target database: adfc_onecampus
-- Safe to rerun.
-- ============================================================================

USE `adfc_onecampus`;

SET @file_submission_points_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='quizzes' AND column_name='file_submission_points'
);
SET @file_submission_points_sql := IF(@file_submission_points_missing,
    'ALTER TABLE quizzes ADD COLUMN file_submission_points DECIMAL(10,2) NOT NULL DEFAULT 100.00 AFTER attachment_name', 'SELECT 1');
PREPARE file_submission_points_statement FROM @file_submission_points_sql;
EXECUTE file_submission_points_statement;
DEALLOCATE PREPARE file_submission_points_statement;

SET @submission_file_score_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='quiz_attempts' AND column_name='submission_file_score'
);
SET @submission_file_score_sql := IF(@submission_file_score_missing,
    'ALTER TABLE quiz_attempts ADD COLUMN submission_file_score DECIMAL(10,2) NULL AFTER submission_file_name', 'SELECT 1');
PREPARE submission_file_score_statement FROM @submission_file_score_sql;
EXECUTE submission_file_score_statement;
DEALLOCATE PREPARE submission_file_score_statement;

UPDATE quiz_attempts a
JOIN quizzes q ON q.id=a.quiz_id
LEFT JOIN (
    SELECT quiz_id,SUM(points) AS question_points
    FROM quiz_questions
    GROUP BY quiz_id
) totals ON totals.quiz_id=a.quiz_id
SET a.max_score=COALESCE(totals.question_points,0)+q.file_submission_points
WHERE a.submission_file_path IS NOT NULL
  AND a.submission_file_path<>'';

INSERT INTO schema_migrations (module_code,migration_name,batch,applied_at)
SELECT 'lms','2026_11_25_lms_quiz_file_grading_v1',6,NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM schema_migrations
    WHERE module_code='lms' AND migration_name='2026_11_25_lms_quiz_file_grading_v1'
);