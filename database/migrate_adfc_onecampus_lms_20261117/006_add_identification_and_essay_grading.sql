-- ============================================================================
-- LMS migration 006: Identification questions and manual essay grading
-- Target database: adfc_onecampus
-- Safe to rerun. Existing short-answer questions become identification items.
-- ============================================================================

USE `adfc_onecampus`;

ALTER TABLE quiz_questions
    MODIFY COLUMN question_type ENUM('multiple_choice','true_false','short_answer','identification','essay') NOT NULL;

UPDATE quiz_questions
SET question_type = 'identification'
WHERE question_type = 'short_answer';

ALTER TABLE quiz_questions
    MODIFY COLUMN question_type ENUM('multiple_choice','true_false','identification','essay') NOT NULL;

SET @essay_scores_missing := (
    SELECT COUNT(*) = 0
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'quiz_attempts' AND column_name = 'essay_scores'
);
SET @essay_scores_sql := IF(
    @essay_scores_missing,
    "ALTER TABLE quiz_attempts ADD COLUMN essay_scores LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT ('{}') CHECK (JSON_VALID(essay_scores)) AFTER answers",
    'SELECT 1'
);
PREPARE essay_scores_statement FROM @essay_scores_sql;
EXECUTE essay_scores_statement;
DEALLOCATE PREPARE essay_scores_statement;

INSERT INTO schema_migrations (module_code, migration_name, batch, applied_at)
SELECT 'lms', '2026_11_18_lms_identification_essay_grading_v1', 3, NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM schema_migrations
    WHERE module_code = 'lms' AND migration_name = '2026_11_18_lms_identification_essay_grading_v1'
);