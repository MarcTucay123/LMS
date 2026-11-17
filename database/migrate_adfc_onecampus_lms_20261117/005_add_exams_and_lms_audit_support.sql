-- ============================================================================
-- LMS migration 005: Exams and LMS audit-log support
-- Target database: adfc_onecampus
-- Safe to rerun. Existing quiz records remain quizzes.
-- ============================================================================

USE `adfc_onecampus`;

SET @assessment_kind_missing := (
    SELECT COUNT(*) = 0
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'quizzes' AND column_name = 'assessment_kind'
);
SET @assessment_kind_sql := IF(
    @assessment_kind_missing,
    "ALTER TABLE quizzes ADD COLUMN assessment_kind ENUM('quiz','exam') NOT NULL DEFAULT 'quiz' AFTER description",
    'SELECT 1'
);
PREPARE assessment_kind_statement FROM @assessment_kind_sql;
EXECUTE assessment_kind_statement;
DEALLOCATE PREPARE assessment_kind_statement;

SET @exam_type_missing := (
    SELECT COUNT(*) = 0
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'quizzes' AND column_name = 'exam_type'
);
SET @exam_type_sql := IF(
    @exam_type_missing,
    'ALTER TABLE quizzes ADD COLUMN exam_type VARCHAR(100) NULL AFTER assessment_kind',
    'SELECT 1'
);
PREPARE exam_type_statement FROM @exam_type_sql;
EXECUTE exam_type_statement;
DEALLOCATE PREPARE exam_type_statement;

SET @assessment_index_missing := (
    SELECT COUNT(*) = 0
    FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'quizzes' AND index_name = 'idx_quizzes_class_kind_created'
);
SET @assessment_index_sql := IF(
    @assessment_index_missing,
    'ALTER TABLE quizzes ADD INDEX idx_quizzes_class_kind_created (class_id, assessment_kind, created_at)',
    'SELECT 1'
);
PREPARE assessment_index_statement FROM @assessment_index_sql;
EXECUTE assessment_index_statement;
DEALLOCATE PREPARE assessment_index_statement;

SET @audit_index_missing := (
    SELECT COUNT(*) = 0
    FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'activity_logs' AND index_name = 'idx_activity_logs_module_created'
);
SET @audit_index_sql := IF(
    @audit_index_missing,
    'ALTER TABLE activity_logs ADD INDEX idx_activity_logs_module_created (module_code, created_at)',
    'SELECT 1'
);
PREPARE audit_index_statement FROM @audit_index_sql;
EXECUTE audit_index_statement;
DEALLOCATE PREPARE audit_index_statement;

INSERT INTO schema_migrations (module_code, migration_name, batch, applied_at)
SELECT 'lms', '2026_11_18_lms_exams_audit_v1', 3, NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM schema_migrations
    WHERE module_code = 'lms' AND migration_name = '2026_11_18_lms_exams_audit_v1'
);