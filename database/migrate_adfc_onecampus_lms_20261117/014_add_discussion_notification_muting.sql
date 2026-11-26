-- LMS migration 014: Per-user discussion notification muting.
-- Target database: adfc_onecampus. Safe to rerun.
USE `adfc_onecampus`;

SET @muted_until_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='learning_discussion_memberships' AND column_name='muted_until');
SET @muted_until_sql := IF(@muted_until_missing,'ALTER TABLE learning_discussion_memberships ADD COLUMN muted_until DATETIME NULL AFTER hidden_at','SELECT 1');
PREPARE muted_until_statement FROM @muted_until_sql; EXECUTE muted_until_statement; DEALLOCATE PREPARE muted_until_statement;

INSERT INTO schema_migrations (module_code,migration_name,batch,applied_at)
SELECT 'lms','2026_11_25_lms_discussion_notification_muting_v1',8,NOW()
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_lms_discussion_notification_muting_v1');