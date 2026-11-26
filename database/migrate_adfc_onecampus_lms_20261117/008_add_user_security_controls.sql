-- ============================================================================
-- LMS migration 008: Administrator-controlled login and inactivity security
-- Target database: adfc_onecampus
-- Safe to rerun. Creates only LMS-owned security settings and attempt records.
-- Import this file in phpMyAdmin after migration 007.
-- ============================================================================

SET NAMES utf8mb4;
USE `adfc_onecampus`;

CREATE TABLE IF NOT EXISTS `lms_security_settings` (
    `settings_id` tinyint(3) unsigned NOT NULL DEFAULT 1,
    `max_login_attempts` smallint(5) unsigned NOT NULL DEFAULT 5,
    `lockout_minutes` smallint(5) unsigned NOT NULL DEFAULT 15,
    `inactivity_timeout_minutes` smallint(5) unsigned NOT NULL DEFAULT 10,
    `updated_by` int(10) unsigned DEFAULT NULL,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`settings_id`),
    KEY `idx_lms_security_settings_updated_by` (`updated_by`),
    CONSTRAINT `chk_lms_security_settings_singleton` CHECK (`settings_id` = 1),
    CONSTRAINT `chk_lms_max_login_attempts` CHECK (`max_login_attempts` BETWEEN 1 AND 20),
    CONSTRAINT `chk_lms_lockout_minutes` CHECK (`lockout_minutes` BETWEEN 10 AND 30),
    CONSTRAINT `chk_lms_inactivity_minutes` CHECK (`inactivity_timeout_minutes` BETWEEN 1 AND 240)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `lms_security_settings`
    (`settings_id`, `max_login_attempts`, `lockout_minutes`, `inactivity_timeout_minutes`)
VALUES (1, 5, 15, 10)
ON DUPLICATE KEY UPDATE `settings_id` = VALUES(`settings_id`);

CREATE TABLE IF NOT EXISTS `lms_login_attempts` (
    `login_key` char(64) NOT NULL,
    `failed_attempts` smallint(5) unsigned NOT NULL DEFAULT 0,
    `locked_until` datetime DEFAULT NULL,
    `last_failed_at` datetime DEFAULT NULL,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`login_key`),
    KEY `idx_lms_login_attempts_locked_until` (`locked_until`),
    KEY `idx_lms_login_attempts_last_failed_at` (`last_failed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (module_code, migration_name, batch, applied_at)
SELECT 'lms', '2026_11_24_lms_user_security_controls_v1', 5, NOW()
WHERE NOT EXISTS (
    SELECT 1
    FROM schema_migrations
    WHERE module_code = 'lms'
      AND migration_name = '2026_11_24_lms_user_security_controls_v1'
);

SELECT
    'LMS user security controls installed' AS result,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = DATABASE()
       AND table_name IN ('lms_security_settings','lms_login_attempts')) AS security_tables_found;