-- ============================================================================
-- LMS migration 011: Discussion message pinning
-- Target database: adfc_onecampus
-- Safe to rerun.
-- ============================================================================

USE `adfc_onecampus`;

SET @discussion_topic_is_pinned_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='learning_discussion_topics' AND column_name='is_pinned'
);
SET @discussion_topic_is_pinned_sql := IF(@discussion_topic_is_pinned_missing,
    'ALTER TABLE learning_discussion_topics ADD COLUMN is_pinned TINYINT(1) NOT NULL DEFAULT 0 AFTER is_locked', 'SELECT 1');
PREPARE discussion_topic_is_pinned_statement FROM @discussion_topic_is_pinned_sql;
EXECUTE discussion_topic_is_pinned_statement;
DEALLOCATE PREPARE discussion_topic_is_pinned_statement;

SET @discussion_topic_pinned_by_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='learning_discussion_topics' AND column_name='pinned_by'
);
SET @discussion_topic_pinned_by_sql := IF(@discussion_topic_pinned_by_missing,
    'ALTER TABLE learning_discussion_topics ADD COLUMN pinned_by VARCHAR(50) NULL AFTER is_pinned', 'SELECT 1');
PREPARE discussion_topic_pinned_by_statement FROM @discussion_topic_pinned_by_sql;
EXECUTE discussion_topic_pinned_by_statement;
DEALLOCATE PREPARE discussion_topic_pinned_by_statement;

SET @discussion_topic_pinned_at_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='learning_discussion_topics' AND column_name='pinned_at'
);
SET @discussion_topic_pinned_at_sql := IF(@discussion_topic_pinned_at_missing,
    'ALTER TABLE learning_discussion_topics ADD COLUMN pinned_at DATETIME NULL AFTER pinned_by', 'SELECT 1');
PREPARE discussion_topic_pinned_at_statement FROM @discussion_topic_pinned_at_sql;
EXECUTE discussion_topic_pinned_at_statement;
DEALLOCATE PREPARE discussion_topic_pinned_at_statement;

SET @discussion_topic_pin_index_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.statistics
    WHERE table_schema=DATABASE() AND table_name='learning_discussion_topics' AND index_name='ix_lms_discussion_topics_pinned'
);
SET @discussion_topic_pin_index_sql := IF(@discussion_topic_pin_index_missing,
    'CREATE INDEX ix_lms_discussion_topics_pinned ON learning_discussion_topics (class_id,is_pinned,pinned_at)', 'SELECT 1');
PREPARE discussion_topic_pin_index_statement FROM @discussion_topic_pin_index_sql;
EXECUTE discussion_topic_pin_index_statement;
DEALLOCATE PREPARE discussion_topic_pin_index_statement;

SET @discussion_is_pinned_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='is_pinned'
);
SET @discussion_is_pinned_sql := IF(@discussion_is_pinned_missing,
    'ALTER TABLE learning_discussion_posts ADD COLUMN is_pinned TINYINT(1) NOT NULL DEFAULT 0 AFTER body', 'SELECT 1');
PREPARE discussion_is_pinned_statement FROM @discussion_is_pinned_sql;
EXECUTE discussion_is_pinned_statement;
DEALLOCATE PREPARE discussion_is_pinned_statement;

SET @discussion_pinned_by_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='pinned_by'
);
SET @discussion_pinned_by_sql := IF(@discussion_pinned_by_missing,
    'ALTER TABLE learning_discussion_posts ADD COLUMN pinned_by VARCHAR(50) NULL AFTER is_pinned', 'SELECT 1');
PREPARE discussion_pinned_by_statement FROM @discussion_pinned_by_sql;
EXECUTE discussion_pinned_by_statement;
DEALLOCATE PREPARE discussion_pinned_by_statement;

SET @discussion_pinned_at_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='pinned_at'
);
SET @discussion_pinned_at_sql := IF(@discussion_pinned_at_missing,
    'ALTER TABLE learning_discussion_posts ADD COLUMN pinned_at DATETIME NULL AFTER pinned_by', 'SELECT 1');
PREPARE discussion_pinned_at_statement FROM @discussion_pinned_at_sql;
EXECUTE discussion_pinned_at_statement;
DEALLOCATE PREPARE discussion_pinned_at_statement;

SET @discussion_pin_index_missing := (
    SELECT COUNT(*) = 0 FROM information_schema.statistics
    WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND index_name='ix_lms_discussion_posts_pinned'
);
SET @discussion_pin_index_sql := IF(@discussion_pin_index_missing,
    'CREATE INDEX ix_lms_discussion_posts_pinned ON learning_discussion_posts (topic_id,is_pinned,pinned_at)', 'SELECT 1');
PREPARE discussion_pin_index_statement FROM @discussion_pin_index_sql;
EXECUTE discussion_pin_index_statement;
DEALLOCATE PREPARE discussion_pin_index_statement;

INSERT INTO schema_migrations (module_code,migration_name,batch,applied_at)
SELECT 'lms','2026_11_25_lms_discussion_message_actions_v1',6,NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM schema_migrations
    WHERE module_code='lms' AND migration_name='2026_11_25_lms_discussion_message_actions_v1'
);