-- LMS migration 012: Discussion replies, reactions, and soft-deleted messages.
-- Target database: adfc_onecampus. Safe to rerun.
USE `adfc_onecampus`;

SET @reply_to_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='reply_to_id');
SET @reply_to_sql := IF(@reply_to_missing,'ALTER TABLE learning_discussion_posts ADD COLUMN reply_to_id CHAR(36) NULL AFTER body','SELECT 1');
PREPARE reply_to_statement FROM @reply_to_sql; EXECUTE reply_to_statement; DEALLOCATE PREPARE reply_to_statement;

SET @is_deleted_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='is_deleted');
SET @is_deleted_sql := IF(@is_deleted_missing,'ALTER TABLE learning_discussion_posts ADD COLUMN is_deleted TINYINT(1) NOT NULL DEFAULT 0 AFTER pinned_at','SELECT 1');
PREPARE is_deleted_statement FROM @is_deleted_sql; EXECUTE is_deleted_statement; DEALLOCATE PREPARE is_deleted_statement;

SET @deleted_at_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='deleted_at');
SET @deleted_at_sql := IF(@deleted_at_missing,'ALTER TABLE learning_discussion_posts ADD COLUMN deleted_at DATETIME NULL AFTER is_deleted','SELECT 1');
PREPARE deleted_at_statement FROM @deleted_at_sql; EXECUTE deleted_at_statement; DEALLOCATE PREPARE deleted_at_statement;

SET @deleted_by_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='deleted_by');
SET @deleted_by_sql := IF(@deleted_by_missing,'ALTER TABLE learning_discussion_posts ADD COLUMN deleted_by VARCHAR(40) NULL AFTER deleted_at','SELECT 1');
PREPARE deleted_by_statement FROM @deleted_by_sql; EXECUTE deleted_by_statement; DEALLOCATE PREPARE deleted_by_statement;

SET @reply_index_missing := (SELECT COUNT(*)=0 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND index_name='ix_lms_discussion_posts_reply_to');
SET @reply_index_sql := IF(@reply_index_missing,'CREATE INDEX ix_lms_discussion_posts_reply_to ON learning_discussion_posts (reply_to_id)','SELECT 1');
PREPARE reply_index_statement FROM @reply_index_sql; EXECUTE reply_index_statement; DEALLOCATE PREPARE reply_index_statement;

-- Some phpMyAdmin imports stop before the dump's later primary-key section.
-- Restore a unique target index only when no unique index currently covers id.
SET @post_id_unique_missing := (SELECT COUNT(*)=0 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='id' AND non_unique=0);
SET @post_id_unique_sql := IF(@post_id_unique_missing,'CREATE UNIQUE INDEX uq_lms_discussion_posts_id ON learning_discussion_posts (id)','SELECT 1');
PREPARE post_id_unique_statement FROM @post_id_unique_sql; EXECUTE post_id_unique_statement; DEALLOCATE PREPARE post_id_unique_statement;

SET @reply_fk_missing := (SELECT COUNT(*)=0 FROM information_schema.table_constraints WHERE constraint_schema=DATABASE() AND table_name='learning_discussion_posts' AND constraint_name='fk_lms_discussion_posts_reply_to');
SET @reply_fk_sql := IF(@reply_fk_missing,'ALTER TABLE learning_discussion_posts ADD CONSTRAINT fk_lms_discussion_posts_reply_to FOREIGN KEY (reply_to_id) REFERENCES learning_discussion_posts(id) ON DELETE SET NULL','SELECT 1');
PREPARE reply_fk_statement FROM @reply_fk_sql; EXECUTE reply_fk_statement; DEALLOCATE PREPARE reply_fk_statement;

CREATE TABLE IF NOT EXISTS learning_discussion_post_reactions (
    id CHAR(36) NOT NULL,
    post_id CHAR(36) NOT NULL,
    user_id VARCHAR(40) NOT NULL,
    emoji VARCHAR(16) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_lms_discussion_reaction_user (post_id,user_id),
    KEY ix_lms_discussion_reaction_post (post_id),
    CONSTRAINT fk_lms_discussion_reactions_post FOREIGN KEY (post_id) REFERENCES learning_discussion_posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_lms_discussion_reactions_user FOREIGN KEY (user_id) REFERENCES users(user_uid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (module_code,migration_name,batch,applied_at)
SELECT 'lms','2026_11_25_lms_discussion_replies_reactions_v1',6,NOW()
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_lms_discussion_replies_reactions_v1');