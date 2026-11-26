-- ============================================================================
-- LMS migration 007: Enrollment-authorized live quiz sessions
-- Target database: adfc_onecampus
-- Safe to rerun. Creates only LMS-owned live-session records.
-- Import this file in phpMyAdmin after migration 006.
-- ============================================================================

SET NAMES utf8mb4;
USE `adfc_onecampus`;

-- Foreign-key targets must be indexed. The official shared dump normally adds
-- these indexes in its later ALTER TABLE section. Add them conditionally here
-- as a recovery measure when phpMyAdmin imported the table definitions but did
-- not reach that later index section.
SET @live_quiz_index_sql := IF(
    EXISTS (SELECT 1 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='quizzes' AND column_name='id' AND seq_in_index=1),
    'SELECT 1',
    'ALTER TABLE quizzes ADD UNIQUE KEY uq_lms_live_quizzes_id (id)'
);
PREPARE live_quiz_index_statement FROM @live_quiz_index_sql;
EXECUTE live_quiz_index_statement;
DEALLOCATE PREPARE live_quiz_index_statement;

SET @live_question_index_sql := IF(
    EXISTS (SELECT 1 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='quiz_questions' AND column_name='id' AND seq_in_index=1),
    'SELECT 1',
    'ALTER TABLE quiz_questions ADD UNIQUE KEY uq_lms_live_questions_id (id)'
);
PREPARE live_question_index_statement FROM @live_question_index_sql;
EXECUTE live_question_index_statement;
DEALLOCATE PREPARE live_question_index_statement;

SET @live_class_index_sql := IF(
    EXISTS (SELECT 1 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='academic_classes' AND column_name='class_uid' AND seq_in_index=1),
    'SELECT 1',
    'ALTER TABLE academic_classes ADD UNIQUE KEY uq_lms_live_class_uid (class_uid)'
);
PREPARE live_class_index_statement FROM @live_class_index_sql;
EXECUTE live_class_index_statement;
DEALLOCATE PREPARE live_class_index_statement;

SET @live_meeting_index_sql := IF(
    EXISTS (SELECT 1 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='class_meetings' AND column_name='meeting_id' AND seq_in_index=1),
    'SELECT 1',
    'ALTER TABLE class_meetings ADD UNIQUE KEY uq_lms_live_meeting_id (meeting_id)'
);
PREPARE live_meeting_index_statement FROM @live_meeting_index_sql;
EXECUTE live_meeting_index_statement;
DEALLOCATE PREPARE live_meeting_index_statement;

SET @live_user_index_sql := IF(
    EXISTS (SELECT 1 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='users' AND column_name='user_uid' AND seq_in_index=1),
    'SELECT 1',
    'ALTER TABLE users ADD UNIQUE KEY uq_lms_live_user_uid (user_uid)'
);
PREPARE live_user_index_statement FROM @live_user_index_sql;
EXECUTE live_user_index_statement;
DEALLOCATE PREPARE live_user_index_statement;

SET @live_student_index_sql := IF(
    EXISTS (SELECT 1 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='students' AND column_name='student_id' AND seq_in_index=1),
    'SELECT 1',
    'ALTER TABLE students ADD UNIQUE KEY uq_lms_live_student_id (student_id)'
);
PREPARE live_student_index_statement FROM @live_student_index_sql;
EXECUTE live_student_index_statement;
DEALLOCATE PREPARE live_student_index_statement;

CREATE TABLE IF NOT EXISTS `quiz_live_sessions` (
    `id` char(36) NOT NULL,
    `quiz_id` char(36) NOT NULL,
    `class_id` varchar(40) NOT NULL,
    `meeting_id` bigint(20) unsigned DEFAULT NULL,
    `scheduled_start` datetime DEFAULT NULL,
    `mode` enum('instructor_paced') NOT NULL DEFAULT 'instructor_paced',
    `status` enum('scheduled','lobby','active','paused','completed','cancelled') NOT NULL DEFAULT 'scheduled',
    `current_question_id` char(36) DEFAULT NULL,
    `question_time_seconds` int(10) unsigned DEFAULT NULL,
    `question_opened_at` datetime DEFAULT NULL,
    `show_correct_answer` tinyint(1) NOT NULL DEFAULT 1,
    `show_leaderboard` tinyint(1) NOT NULL DEFAULT 1,
    `randomize_choices` tinyint(1) NOT NULL DEFAULT 0,
    `started_at` datetime DEFAULT NULL,
    `ended_at` datetime DEFAULT NULL,
    `created_by` varchar(40) NOT NULL,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `idx_live_sessions_class_status_start` (`class_id`,`status`,`scheduled_start`),
    KEY `idx_live_sessions_quiz` (`quiz_id`),
    KEY `idx_live_sessions_meeting` (`meeting_id`),
    KEY `idx_live_sessions_current_question` (`current_question_id`),
    KEY `idx_live_sessions_creator` (`created_by`),
    CONSTRAINT `fk_lms_live_session_quiz` FOREIGN KEY (`quiz_id`) REFERENCES `quizzes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lms_live_session_class` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE,
    CONSTRAINT `fk_lms_live_session_meeting` FOREIGN KEY (`meeting_id`) REFERENCES `class_meetings` (`meeting_id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lms_live_session_question` FOREIGN KEY (`current_question_id`) REFERENCES `quiz_questions` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lms_live_session_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `quiz_live_participants` (
    `id` char(36) NOT NULL,
    `session_id` char(36) NOT NULL,
    `student_id` int(10) unsigned NOT NULL,
    `status` enum('connected','active','submitted','disconnected') NOT NULL DEFAULT 'connected',
    `joined_at` datetime NOT NULL DEFAULT current_timestamp(),
    `last_seen_at` datetime NOT NULL DEFAULT current_timestamp(),
    `completed_at` datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_live_participant_session_student` (`session_id`,`student_id`),
    KEY `idx_live_participants_session_status` (`session_id`,`status`),
    KEY `idx_live_participants_student` (`student_id`),
    CONSTRAINT `fk_lms_live_participant_session` FOREIGN KEY (`session_id`) REFERENCES `quiz_live_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lms_live_participant_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `quiz_live_responses` (
    `id` char(36) NOT NULL,
    `session_id` char(36) NOT NULL,
    `question_id` char(36) NOT NULL,
    `student_id` int(10) unsigned NOT NULL,
    `answer` longtext NOT NULL,
    `is_correct` tinyint(1) DEFAULT NULL,
    `points_awarded` decimal(10,2) NOT NULL DEFAULT 0.00,
    `response_time_ms` int(10) unsigned DEFAULT NULL,
    `submitted_at` datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_live_response_session_question_student` (`session_id`,`question_id`,`student_id`),
    KEY `idx_live_responses_session_question` (`session_id`,`question_id`),
    KEY `idx_live_responses_student` (`student_id`),
    CONSTRAINT `fk_lms_live_response_session` FOREIGN KEY (`session_id`) REFERENCES `quiz_live_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lms_live_response_question` FOREIGN KEY (`question_id`) REFERENCES `quiz_questions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lms_live_response_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (module_code, migration_name, batch, applied_at)
SELECT 'lms', '2026_11_23_lms_live_quiz_sessions_v1', 4, NOW()
WHERE NOT EXISTS (
    SELECT 1
    FROM schema_migrations
    WHERE module_code = 'lms'
      AND migration_name = '2026_11_23_lms_live_quiz_sessions_v1'
);

SELECT
    'LMS live quiz migration installed' AS result,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = DATABASE()
       AND table_name IN ('quiz_live_sessions','quiz_live_participants','quiz_live_responses')) AS live_quiz_tables_found;