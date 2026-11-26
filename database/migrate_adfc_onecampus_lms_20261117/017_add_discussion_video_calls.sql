-- ============================================================================
-- LMS migration 017: Complete regular discussion-call schema
-- Target database: adfc_onecampus
-- Safe to rerun. Creates sessions, attendance, screen sharing, chat, and WebRTC signals.
-- ============================================================================

SET NAMES utf8mb4;
USE `adfc_onecampus`;

CREATE TABLE IF NOT EXISTS `discussion_live_sessions` (
    `id` char(36) NOT NULL,
    `topic_id` char(36) NOT NULL,
    `class_id` varchar(40) NOT NULL,
    `status` enum('active','ended') NOT NULL DEFAULT 'active',
    `created_by` varchar(40) NOT NULL,
    `started_at` datetime NOT NULL DEFAULT current_timestamp(),
    `ended_at` datetime DEFAULT NULL,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `idx_discussion_live_topic_status` (`topic_id`,`status`,`started_at`),
    KEY `idx_discussion_live_class_status` (`class_id`,`status`),
    CONSTRAINT `fk_discussion_live_topic` FOREIGN KEY (`topic_id`) REFERENCES `learning_discussion_topics` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_discussion_live_class` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE,
    CONSTRAINT `fk_discussion_live_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `discussion_live_participants` (
    `session_id` char(36) NOT NULL,
    `user_id` varchar(40) NOT NULL,
    `mic_muted` tinyint(1) NOT NULL DEFAULT 1,
    `camera_enabled` tinyint(1) NOT NULL DEFAULT 0,
    `screen_sharing` tinyint(1) NOT NULL DEFAULT 0,
    `is_attending` tinyint(1) NOT NULL DEFAULT 0,
    `joined_at` datetime NOT NULL DEFAULT current_timestamp(),
    `last_seen_at` datetime NOT NULL DEFAULT current_timestamp(),
    `left_at` datetime DEFAULT NULL,
    PRIMARY KEY (`session_id`,`user_id`),
    KEY `idx_discussion_live_presence` (`session_id`,`last_seen_at`,`left_at`),
    CONSTRAINT `fk_discussion_live_participant_session` FOREIGN KEY (`session_id`) REFERENCES `discussion_live_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_discussion_live_participant_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `discussion_live_events` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `session_id` char(36) NOT NULL,
    `user_id` varchar(40) NOT NULL,
    `event_type` enum('comment','reaction') NOT NULL,
    `content` varchar(1000) NOT NULL,
    `attachment_path` varchar(500) DEFAULT NULL,
    `attachment_name` varchar(255) DEFAULT NULL,
    `attachment_mime` varchar(150) DEFAULT NULL,
    `attachment_size` bigint(20) unsigned DEFAULT NULL,
    `attachment_kind` enum('image','file') DEFAULT NULL,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `idx_discussion_live_events_session` (`session_id`,`id`),
    CONSTRAINT `fk_discussion_live_event_session` FOREIGN KEY (`session_id`) REFERENCES `discussion_live_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_discussion_live_event_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `discussion_live_signals` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `session_id` char(36) NOT NULL,
    `sender_id` varchar(40) NOT NULL,
    `recipient_id` varchar(40) NOT NULL,
    `signal_type` varchar(20) NOT NULL,
    `payload_json` longtext DEFAULT NULL,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `idx_discussion_live_signal_recipient` (`session_id`,`recipient_id`,`id`),
    KEY `idx_discussion_live_signal_created` (`created_at`),
    CONSTRAINT `fk_discussion_live_signal_session` FOREIGN KEY (`session_id`) REFERENCES `discussion_live_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_discussion_live_signal_sender` FOREIGN KEY (`sender_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE,
    CONSTRAINT `fk_discussion_live_signal_recipient` FOREIGN KEY (`recipient_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (migration_id,module_code,migration_name,batch,applied_at)
SELECT (SELECT COALESCE(MAX(migration_id),0)+1 FROM schema_migrations),'lms','2026_11_25_discussion_video_calls_v1',11,NOW()
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_discussion_video_calls_v1');

SELECT 'Complete regular discussion-call schema installed' AS result;