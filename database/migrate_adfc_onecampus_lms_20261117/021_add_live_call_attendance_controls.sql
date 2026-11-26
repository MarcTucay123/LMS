-- ============================================================================
-- LMS migration 021: Administrator-controlled live-call attendance rules
-- Target database: adfc_onecampus
-- Safe to rerun. Keeps live-call attendance settings separate from auto-logout.
-- ============================================================================

SET NAMES utf8mb4;
USE `adfc_onecampus`;

SET @attendance_columns_sql := (
    SELECT IF(
        COUNT(*)=0,
        'SELECT 1',
        CONCAT('ALTER TABLE lms_security_settings ', GROUP_CONCAT(clause ORDER BY position SEPARATOR ', '))
    )
    FROM (
        SELECT 1 position, IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='lms_security_settings' AND column_name='live_attendance_minimized_enabled'), NULL, 'ADD COLUMN live_attendance_minimized_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER inactivity_timeout_minutes') clause
        UNION ALL
        SELECT 2, IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='lms_security_settings' AND column_name='live_attendance_tab_hidden_enabled'), NULL, 'ADD COLUMN live_attendance_tab_hidden_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER live_attendance_minimized_enabled')
        UNION ALL
        SELECT 3, IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='lms_security_settings' AND column_name='live_attendance_window_blur_enabled'), NULL, 'ADD COLUMN live_attendance_window_blur_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER live_attendance_tab_hidden_enabled')
        UNION ALL
        SELECT 4, IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='lms_security_settings' AND column_name='live_attendance_inactivity_enabled'), NULL, 'ADD COLUMN live_attendance_inactivity_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER live_attendance_window_blur_enabled')
        UNION ALL
        SELECT 5, IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='lms_security_settings' AND column_name='live_attendance_inactivity_seconds'), NULL, 'ADD COLUMN live_attendance_inactivity_seconds SMALLINT UNSIGNED NOT NULL DEFAULT 30 AFTER live_attendance_inactivity_enabled')
    ) missing_columns
    WHERE clause IS NOT NULL
);
SET @attendance_columns_sql := COALESCE(@attendance_columns_sql, 'SELECT 1');
PREPARE attendance_columns_statement FROM @attendance_columns_sql;
EXECUTE attendance_columns_statement;
DEALLOCATE PREPARE attendance_columns_statement;

INSERT INTO schema_migrations (migration_id,module_code,migration_name,batch,applied_at)
SELECT (SELECT COALESCE(MAX(migration_id),0)+1 FROM schema_migrations),'lms','2026_11_25_live_call_attendance_controls_v1',14,NOW()
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_live_call_attendance_controls_v1');

SELECT 'Live-call attendance controls installed' AS result;