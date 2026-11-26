-- ============================================================================
-- LMS migration 018: Finalize regular discussion calls
-- Target database: adfc_onecampus
-- Safe to rerun after migration 017. Upgrades older call schemas and removes the
-- retired instructor live-session variant while preserving regular call history.
-- ============================================================================

SET NAMES utf8mb4;
USE `adfc_onecampus`;

SET @discussion_screen_sharing_missing := (
    SELECT COUNT(*)=0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='discussion_live_participants' AND column_name='screen_sharing'
);
SET @discussion_screen_sharing_sql := IF(
    @discussion_screen_sharing_missing,
    'ALTER TABLE discussion_live_participants ADD COLUMN screen_sharing TINYINT(1) NOT NULL DEFAULT 0 AFTER camera_enabled',
    'SELECT 1'
);
PREPARE discussion_screen_sharing_statement FROM @discussion_screen_sharing_sql;
EXECUTE discussion_screen_sharing_statement;
DEALLOCATE PREPARE discussion_screen_sharing_statement;

SET @discussion_attendance_missing := (
    SELECT COUNT(*)=0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='discussion_live_participants' AND column_name='is_attending'
);
SET @discussion_attendance_sql := IF(
    @discussion_attendance_missing,
    'ALTER TABLE discussion_live_participants ADD COLUMN is_attending TINYINT(1) NOT NULL DEFAULT 0 AFTER screen_sharing',
    'SELECT 1'
);
PREPARE discussion_attendance_statement FROM @discussion_attendance_sql;
EXECUTE discussion_attendance_statement;
DEALLOCATE PREPARE discussion_attendance_statement;

SET @discussion_live_attachment_sql := (
    SELECT IF(
        COUNT(*)=0,
        'SELECT 1',
        CONCAT(
            'ALTER TABLE discussion_live_events ',
            GROUP_CONCAT(clause ORDER BY position SEPARATOR ', ')
        )
    )
    FROM (
        SELECT 1 position, IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='discussion_live_events' AND column_name='attachment_path'), NULL, 'ADD COLUMN attachment_path VARCHAR(500) DEFAULT NULL AFTER content') clause
        UNION ALL
        SELECT 2, IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='discussion_live_events' AND column_name='attachment_name'), NULL, 'ADD COLUMN attachment_name VARCHAR(255) DEFAULT NULL AFTER attachment_path')
        UNION ALL
        SELECT 3, IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='discussion_live_events' AND column_name='attachment_mime'), NULL, 'ADD COLUMN attachment_mime VARCHAR(150) DEFAULT NULL AFTER attachment_name')
        UNION ALL
        SELECT 4, IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='discussion_live_events' AND column_name='attachment_size'), NULL, 'ADD COLUMN attachment_size BIGINT UNSIGNED DEFAULT NULL AFTER attachment_mime')
        UNION ALL
        SELECT 5, IF(EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='discussion_live_events' AND column_name='attachment_kind'), NULL, 'ADD COLUMN attachment_kind ENUM(''image'',''file'') DEFAULT NULL AFTER attachment_size')
    ) attachment_columns
    WHERE clause IS NOT NULL
);
SET @discussion_live_attachment_sql := COALESCE(@discussion_live_attachment_sql, 'SELECT 1');
PREPARE discussion_live_attachment_statement FROM @discussion_live_attachment_sql;
EXECUTE discussion_live_attachment_statement;
DEALLOCATE PREPARE discussion_live_attachment_statement;

SET @discussion_call_type_exists := (
    SELECT COUNT(*)>0 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='discussion_live_sessions' AND column_name='session_type'
);
SET @discussion_remove_instructor_sessions_sql := IF(
    @discussion_call_type_exists,
    "DELETE FROM discussion_live_sessions WHERE session_type='instructor'",
    'SELECT 1'
);
PREPARE discussion_remove_instructor_sessions_statement FROM @discussion_remove_instructor_sessions_sql;
EXECUTE discussion_remove_instructor_sessions_statement;
DEALLOCATE PREPARE discussion_remove_instructor_sessions_statement;

SET @discussion_call_type_index_exists := (
    SELECT COUNT(*)>0 FROM information_schema.statistics
    WHERE table_schema=DATABASE() AND table_name='discussion_live_sessions' AND index_name='idx_discussion_live_class_type_status'
);
SET @discussion_drop_call_type_index_sql := IF(
    @discussion_call_type_index_exists,
    'ALTER TABLE discussion_live_sessions DROP INDEX idx_discussion_live_class_type_status',
    'SELECT 1'
);
PREPARE discussion_drop_call_type_index_statement FROM @discussion_drop_call_type_index_sql;
EXECUTE discussion_drop_call_type_index_statement;
DEALLOCATE PREPARE discussion_drop_call_type_index_statement;

ALTER TABLE discussion_live_sessions
    MODIFY COLUMN status ENUM('active','ended') NOT NULL DEFAULT 'active';

SET @discussion_drop_call_type_sql := IF(
    @discussion_call_type_exists,
    'ALTER TABLE discussion_live_sessions DROP COLUMN session_type',
    'SELECT 1'
);
PREPARE discussion_drop_call_type_statement FROM @discussion_drop_call_type_sql;
EXECUTE discussion_drop_call_type_statement;
DEALLOCATE PREPARE discussion_drop_call_type_statement;

DELETE FROM schema_migrations
WHERE module_code='lms'
  AND migration_name IN (
      '2026_11_25_split_discussion_calls_live_sessions_v1',
      '2026_11_25_discussion_call_attendance_v1',
      '2026_11_25_discussion_screen_sharing_v1'
  );

INSERT INTO schema_migrations (migration_id,module_code,migration_name,batch,applied_at)
SELECT (SELECT COALESCE(MAX(migration_id),0)+1 FROM schema_migrations),'lms','2026_11_25_finalize_regular_discussion_calls_v1',12,NOW()
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_finalize_regular_discussion_calls_v1');

SELECT 'Regular discussion calls finalized; instructor live sessions removed' AS result;