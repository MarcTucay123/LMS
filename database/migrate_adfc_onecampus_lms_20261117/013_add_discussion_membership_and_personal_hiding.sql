-- LMS migration 013: Per-user discussion membership, leaving, and personal hiding.
-- Target database: adfc_onecampus. Safe to rerun.
USE `adfc_onecampus`;

-- Some phpMyAdmin imports stop before the dump's later primary-key section.
SET @topic_id_unique_missing := (SELECT COUNT(*)=0 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='learning_discussion_topics' AND column_name='id' AND non_unique=0);
SET @topic_id_unique_sql := IF(@topic_id_unique_missing,'CREATE UNIQUE INDEX uq_lms_discussion_topics_id ON learning_discussion_topics (id)','SELECT 1');
PREPARE topic_id_unique_statement FROM @topic_id_unique_sql; EXECUTE topic_id_unique_statement; DEALLOCATE PREPARE topic_id_unique_statement;

CREATE TABLE IF NOT EXISTS learning_discussion_memberships (
    topic_id CHAR(36) NOT NULL,
    user_id VARCHAR(40) NOT NULL,
    joined_at DATETIME NULL,
    left_at DATETIME NULL,
    hidden_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (topic_id,user_id),
    KEY ix_lms_discussion_memberships_user (user_id,hidden_at),
    CONSTRAINT fk_lms_discussion_memberships_topic FOREIGN KEY (topic_id) REFERENCES learning_discussion_topics(id) ON DELETE CASCADE,
    CONSTRAINT fk_lms_discussion_memberships_user FOREIGN KEY (user_id) REFERENCES users(user_uid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Topic creators are members of discussions they already created.
INSERT IGNORE INTO learning_discussion_memberships (topic_id,user_id,joined_at)
SELECT t.id,t.created_by,t.created_at FROM learning_discussion_topics t
;

INSERT INTO schema_migrations (module_code,migration_name,batch,applied_at)
SELECT 'lms','2026_11_25_lms_discussion_membership_v1',7,NOW()
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_lms_discussion_membership_v1');