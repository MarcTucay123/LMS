-- LMS migration 015: Private file, image, video, and audio attachments for discussion messages.
-- Target database: adfc_onecampus. Safe to rerun.
USE `adfc_onecampus`;

SET @attachment_path_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='attachment_path');
SET @attachment_path_sql := IF(@attachment_path_missing,'ALTER TABLE learning_discussion_posts ADD COLUMN attachment_path VARCHAR(1000) NULL AFTER body','SELECT 1');
PREPARE attachment_path_statement FROM @attachment_path_sql; EXECUTE attachment_path_statement; DEALLOCATE PREPARE attachment_path_statement;

SET @attachment_name_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='attachment_name');
SET @attachment_name_sql := IF(@attachment_name_missing,'ALTER TABLE learning_discussion_posts ADD COLUMN attachment_name VARCHAR(255) NULL AFTER attachment_path','SELECT 1');
PREPARE attachment_name_statement FROM @attachment_name_sql; EXECUTE attachment_name_statement; DEALLOCATE PREPARE attachment_name_statement;

SET @attachment_mime_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='attachment_mime');
SET @attachment_mime_sql := IF(@attachment_mime_missing,'ALTER TABLE learning_discussion_posts ADD COLUMN attachment_mime VARCHAR(150) NULL AFTER attachment_name','SELECT 1');
PREPARE attachment_mime_statement FROM @attachment_mime_sql; EXECUTE attachment_mime_statement; DEALLOCATE PREPARE attachment_mime_statement;

SET @attachment_size_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='attachment_size');
SET @attachment_size_sql := IF(@attachment_size_missing,'ALTER TABLE learning_discussion_posts ADD COLUMN attachment_size BIGINT UNSIGNED NULL AFTER attachment_mime','SELECT 1');
PREPARE attachment_size_statement FROM @attachment_size_sql; EXECUTE attachment_size_statement; DEALLOCATE PREPARE attachment_size_statement;

SET @attachment_kind_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_posts' AND column_name='attachment_kind');
SET @attachment_kind_sql := IF(@attachment_kind_missing,"ALTER TABLE learning_discussion_posts ADD COLUMN attachment_kind ENUM('file','image','video','audio') NULL AFTER attachment_size",'SELECT 1');
PREPARE attachment_kind_statement FROM @attachment_kind_sql; EXECUTE attachment_kind_statement; DEALLOCATE PREPARE attachment_kind_statement;

INSERT INTO schema_migrations (migration_id,module_code,migration_name,batch,applied_at)
SELECT (SELECT COALESCE(MAX(migration_id),0)+1 FROM schema_migrations),'lms','2026_11_25_lms_discussion_attachments_v1',9,NOW()
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_lms_discussion_attachments_v1');

SET @attachment_migration_id := (SELECT MAX(migration_id) FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_lms_discussion_attachments_v1');
DELETE FROM schema_migrations
WHERE module_code='lms' AND migration_name='2026_11_25_lms_discussion_attachments_v1' AND migration_id<>@attachment_migration_id;
SET @attachment_migration_next_id := (SELECT COALESCE(MAX(migration_id),0)+1 FROM schema_migrations WHERE NOT (module_code='lms' AND migration_name='2026_11_25_lms_discussion_attachments_v1'));
UPDATE schema_migrations
SET migration_id=IF(migration_id=0,@attachment_migration_next_id,migration_id),batch=9
WHERE module_code='lms' AND migration_name='2026_11_25_lms_discussion_attachments_v1';