-- ============================================================================
-- LMS migration 020: Persist discussion live-call attendance history
-- Target database: adfc_onecampus
-- Safe to rerun. Stores the enrolled-student roster exactly when a host ends a call.
-- ============================================================================

SET NAMES utf8mb4;
USE `adfc_onecampus`;

CREATE TABLE IF NOT EXISTS `discussion_live_attendance_history` (
    `session_id` char(36) NOT NULL,
    `student_id` int(10) unsigned NOT NULL,
    `user_id` varchar(40) DEFAULT NULL,
    `full_name` varchar(200) NOT NULL,
    `school_id` varchar(50) NOT NULL,
    `attendance_status` enum('active','inactive','not_joined') NOT NULL,
    `joined_at` datetime DEFAULT NULL,
    `last_seen_at` datetime DEFAULT NULL,
    `recorded_at` datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`session_id`,`student_id`),
    KEY `idx_discussion_live_history_student` (`student_id`,`recorded_at`),
    KEY `idx_discussion_live_history_status` (`session_id`,`attendance_status`),
    CONSTRAINT `fk_discussion_live_history_session` FOREIGN KEY (`session_id`) REFERENCES `discussion_live_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_discussion_live_history_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (migration_id,module_code,migration_name,batch,applied_at)
SELECT (SELECT COALESCE(MAX(migration_id),0)+1 FROM schema_migrations),'lms','2026_11_25_discussion_live_attendance_history_v1',13,NOW()
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_discussion_live_attendance_history_v1');

SELECT 'Discussion live-call attendance history installed' AS result;