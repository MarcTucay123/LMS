-- ============================================================================
-- LMS migration 019: Conversation-level discussion read receipts
-- Target database: adfc_onecampus
-- Safe to rerun. Stores each participant's latest read message per discussion.
-- ============================================================================

SET NAMES utf8mb4;
USE `adfc_onecampus`;

SET @discussion_last_read_post_missing := (
    SELECT COUNT(*)=0 FROM information_schema.columns
    WHERE table_schema=DATABASE()
      AND table_name='learning_discussion_memberships'
      AND column_name='last_read_post_id'
);
SET @discussion_last_read_post_sql := IF(
    @discussion_last_read_post_missing,
    'ALTER TABLE learning_discussion_memberships ADD COLUMN last_read_post_id CHAR(36) NULL AFTER muted_until',
    'SELECT 1'
);
PREPARE discussion_last_read_post_statement FROM @discussion_last_read_post_sql;
EXECUTE discussion_last_read_post_statement;
DEALLOCATE PREPARE discussion_last_read_post_statement;

SET @discussion_last_read_at_missing := (
    SELECT COUNT(*)=0 FROM information_schema.columns
    WHERE table_schema=DATABASE()
      AND table_name='learning_discussion_memberships'
      AND column_name='last_read_at'
);
SET @discussion_last_read_at_sql := IF(
    @discussion_last_read_at_missing,
    'ALTER TABLE learning_discussion_memberships ADD COLUMN last_read_at DATETIME NULL AFTER last_read_post_id',
    'SELECT 1'
);
PREPARE discussion_last_read_at_statement FROM @discussion_last_read_at_sql;
EXECUTE discussion_last_read_at_statement;
DEALLOCATE PREPARE discussion_last_read_at_statement;

SET @discussion_last_read_index_missing := (
    SELECT COUNT(*)=0 FROM information_schema.statistics
    WHERE table_schema=DATABASE()
      AND table_name='learning_discussion_memberships'
      AND index_name='ix_lms_discussion_last_read'
);
SET @discussion_last_read_index_sql := IF(
    @discussion_last_read_index_missing,
    'CREATE INDEX ix_lms_discussion_last_read ON learning_discussion_memberships (topic_id,last_read_post_id,last_read_at)',
    'SELECT 1'
);
PREPARE discussion_last_read_index_statement FROM @discussion_last_read_index_sql;
EXECUTE discussion_last_read_index_statement;
DEALLOCATE PREPARE discussion_last_read_index_statement;

INSERT INTO schema_migrations (migration_id,module_code,migration_name,batch,applied_at)
SELECT (SELECT COALESCE(MAX(migration_id),0)+1 FROM schema_migrations),'lms','2026_11_25_discussion_read_receipts_v1',13,NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM schema_migrations
    WHERE module_code='lms' AND migration_name='2026_11_25_discussion_read_receipts_v1'
);

SELECT 'Discussion read receipts installed' AS result;