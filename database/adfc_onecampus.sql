
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `academic_classes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `academic_classes` (
  `class_id` bigint(20) unsigned NOT NULL,
  `class_uid` varchar(40) DEFAULT NULL,
  `program_id` int(10) unsigned DEFAULT NULL,
  `subject_id` int(10) unsigned DEFAULT NULL,
  `period_id` int(10) unsigned DEFAULT NULL,
  `instructor_id` int(10) unsigned DEFAULT NULL,
  `class_code` varchar(60) NOT NULL,
  `section` varchar(60) DEFAULT NULL,
  `year_level` tinyint(3) unsigned DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `academic_periods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `academic_periods` (
  `period_id` int(10) unsigned NOT NULL,
  `academic_year` varchar(20) NOT NULL,
  `semester` enum('1st','2nd','Summer') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `starts_on` date DEFAULT NULL,
  `ends_on` date DEFAULT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `access_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `access_permissions` (
  `permission_id` int(10) unsigned NOT NULL,
  `permission_code` varchar(120) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `access_role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `access_role_permissions` (
  `role_id` int(10) unsigned NOT NULL,
  `permission_id` int(10) unsigned NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `access_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `access_roles` (
  `role_id` int(10) unsigned NOT NULL,
  `role_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `activity_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `activity_logs` (
  `module_code` varchar(40) NOT NULL DEFAULT 'enrollment',
  `details_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`details_json`)),
  `old_values_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`old_values_json`)),
  `new_values_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`new_values_json`)),
  `log_id` bigint(20) unsigned NOT NULL,
  `admin_user_id` int(10) unsigned DEFAULT NULL,
  `action` varchar(60) NOT NULL,
  `record_type` varchar(60) DEFAULT NULL,
  `record_id` int(10) unsigned DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `adjustments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `adjustments` (
  `id` int(11) NOT NULL,
  `uid` char(36) DEFAULT NULL,
  `student_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `reason` varchar(150) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` int(11) DEFAULT NULL,
  `enrollment_id` int(11) DEFAULT NULL,
  `ref_key` varchar(40) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `admin_users`;
/*!50001 DROP VIEW IF EXISTS `admin_users`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `admin_users` AS SELECT
 1 AS `admin_user_id`,
  1 AS `username`,
  1 AS `email`,
  1 AS `password_hash`,
  1 AS `full_name`,
  1 AS `role`,
  1 AS `status`,
  1 AS `last_login`,
  1 AS `created_at`,
  1 AS `updated_at` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `admit_applicants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `admit_applicants` (
  `id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `reference_code` varchar(24) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(190) NOT NULL,
  `program` varchar(150) NOT NULL,
  `birth_date` date DEFAULT NULL,
  `phone` varchar(40) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `status` varchar(40) NOT NULL DEFAULT 'For evaluation',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `admit_evaluations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `admit_evaluations` (
  `id` bigint(20) unsigned NOT NULL,
  `applicant_id` bigint(20) unsigned NOT NULL,
  `evaluator_id` int(10) unsigned DEFAULT NULL,
  `exam_date` date NOT NULL,
  `score` decimal(5,2) NOT NULL,
  `decision` enum('Pending','Qualified','Not qualified') NOT NULL DEFAULT 'Pending',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `admit_interview_slots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `admit_interview_slots` (
  `id` bigint(20) unsigned NOT NULL,
  `interviewer_id` int(10) unsigned DEFAULT NULL,
  `starts_at` datetime NOT NULL,
  `ends_at` datetime NOT NULL,
  `capacity` smallint(5) unsigned NOT NULL DEFAULT 1,
  `location` varchar(190) NOT NULL DEFAULT 'ADFC Admissions Office',
  `status` enum('open','closed') NOT NULL DEFAULT 'open'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `admit_interviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `admit_interviews` (
  `id` bigint(20) unsigned NOT NULL,
  `applicant_id` bigint(20) unsigned NOT NULL,
  `interviewer_id` int(10) unsigned DEFAULT NULL,
  `slot_id` bigint(20) unsigned DEFAULT NULL,
  `scheduled_at` datetime NOT NULL,
  `location` varchar(190) NOT NULL,
  `status` enum('Scheduled','Completed','Cancelled','No show') NOT NULL DEFAULT 'Scheduled',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `announcements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `announcements` (
  `announcement_id` bigint(20) unsigned NOT NULL,
  `module_code` varchar(40) NOT NULL,
  `class_id` bigint(20) unsigned DEFAULT NULL,
  `program_id` int(10) unsigned DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `body` longtext NOT NULL,
  `audience` varchar(120) DEFAULT NULL,
  `created_by` int(10) unsigned DEFAULT NULL,
  `is_published` tinyint(1) NOT NULL DEFAULT 0,
  `published_at` datetime DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `applications` (
  `id` bigint(20) unsigned NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `reference_no` varchar(30) DEFAULT NULL,
  `program` varchar(30) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `gender` varchar(30) DEFAULT NULL,
  `civil_status` varchar(30) DEFAULT NULL,
  `nationality` varchar(70) DEFAULT 'Filipino',
  `address_line` varchar(255) DEFAULT NULL,
  `province` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `status` enum('draft','submitted','screening','portfolio_review','assessment','for_decision','approved','revision_required','completed') NOT NULL DEFAULT 'draft',
  `submitted_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `assessments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `assessments` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `assessor_id` bigint(20) unsigned DEFAULT NULL,
  `title` varchar(150) NOT NULL,
  `scheduled_at` datetime NOT NULL,
  `mode` enum('Onsite','Online') NOT NULL DEFAULT 'Onsite',
  `venue` varchar(255) NOT NULL,
  `status` enum('scheduled','completed','cancelled') NOT NULL DEFAULT 'scheduled',
  `feedback` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_approval_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_approval_requests` (
  `id` varchar(40) NOT NULL,
  `type` varchar(20) NOT NULL DEFAULT 'name',
  `username` varchar(64) NOT NULL,
  `member_id` varchar(40) NOT NULL DEFAULT '',
  `old_value` varchar(160) NOT NULL DEFAULT '',
  `new_value` varchar(160) NOT NULL DEFAULT '',
  `reason` varchar(250) NOT NULL DEFAULT '',
  `status` varchar(12) NOT NULL DEFAULT 'pending',
  `requested_at` datetime NOT NULL DEFAULT current_timestamp(),
  `decided_at` datetime DEFAULT NULL,
  `decided_by` varchar(120) NOT NULL DEFAULT '',
  `note` varchar(250) NOT NULL DEFAULT '',
  `seen` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_attendance_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_attendance_records` (
  `id` varchar(40) NOT NULL,
  `student_id` varchar(40) NOT NULL,
  `schedule_id` varchar(60) NOT NULL,
  `att_date` date NOT NULL,
  `status` varchar(10) NOT NULL,
  `subject` varchar(160) NOT NULL DEFAULT '',
  `block` varchar(80) NOT NULL DEFAULT '',
  `instructor` varchar(120) NOT NULL DEFAULT '',
  `time_in` varchar(20) NOT NULL DEFAULT '',
  `ts` bigint(20) NOT NULL DEFAULT 0,
  `is_test` tinyint(1) NOT NULL DEFAULT 0,
  `recorded_by` varchar(64) NOT NULL DEFAULT '',
  `extra` mediumtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_attendance_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_attendance_sessions` (
  `schedule_id` varchar(60) NOT NULL,
  `att_date` date NOT NULL,
  `instructor` varchar(120) NOT NULL DEFAULT '',
  `subject` varchar(160) NOT NULL DEFAULT '',
  `start_time` varchar(10) NOT NULL DEFAULT '',
  `end_time` varchar(10) NOT NULL DEFAULT '',
  `started_at` bigint(20) NOT NULL DEFAULT 0,
  `closed_at` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_email_sent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_email_sent` (
  `record_id` varchar(40) NOT NULL,
  `to_addr` varchar(120) NOT NULL,
  `sent_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_face_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_face_templates` (
  `member_id` varchar(40) NOT NULL,
  `descriptor` text NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_member_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_member_files` (
  `owner` varchar(64) NOT NULL,
  `kind` varchar(10) NOT NULL,
  `data` mediumtext NOT NULL,
  `updated_by` varchar(64) NOT NULL DEFAULT '',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_members` (
  `id` varchar(40) NOT NULL,
  `role` varchar(20) NOT NULL DEFAULT 'student',
  `name` varchar(120) NOT NULL,
  `department` varchar(160) NOT NULL DEFAULT '',
  `program` varchar(160) NOT NULL DEFAULT '',
  `section` varchar(60) NOT NULL DEFAULT '',
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  `email` varchar(120) NOT NULL DEFAULT '',
  `parent_email` varchar(120) NOT NULL DEFAULT '',
  `parent_mobile` varchar(30) NOT NULL DEFAULT '',
  `extra` mediumtext DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `student_id` int(10) unsigned DEFAULT NULL,
  `user_id` int(10) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_notification_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_notification_log` (
  `id` bigint(20) unsigned NOT NULL,
  `channel` varchar(10) NOT NULL DEFAULT 'email',
  `to_addr` varchar(120) NOT NULL DEFAULT '',
  `student_id` varchar(40) NOT NULL DEFAULT '',
  `subject` varchar(160) NOT NULL DEFAULT '',
  `status` varchar(12) NOT NULL DEFAULT '',
  `reason` varchar(250) NOT NULL DEFAULT '',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_notify_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_notify_queue` (
  `id` bigint(20) unsigned NOT NULL,
  `channel` varchar(10) NOT NULL,
  `record_id` varchar(40) NOT NULL,
  `student_id` varchar(40) NOT NULL DEFAULT '',
  `att_status` varchar(10) NOT NULL DEFAULT '',
  `recipient` varchar(10) NOT NULL DEFAULT 'parent',
  `to_addr` varchar(120) NOT NULL DEFAULT '',
  `subject` varchar(160) NOT NULL DEFAULT '',
  `message` text NOT NULL,
  `state` varchar(12) NOT NULL DEFAULT 'Queued',
  `note` varchar(250) NOT NULL DEFAULT '',
  `due_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `sent_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_password_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_password_resets` (
  `id` bigint(20) unsigned NOT NULL,
  `instructor_id` int(10) unsigned NOT NULL,
  `code_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `attempts` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `used` tinyint(1) NOT NULL DEFAULT 0,
  `ip` varchar(45) NOT NULL DEFAULT '',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attend_school_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `attend_school_data` (
  `part` varchar(40) NOT NULL,
  `v` mediumtext NOT NULL,
  `updated_by` varchar(64) NOT NULL DEFAULT '',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `audit_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `audit_logs` (
  `id` bigint(20) unsigned NOT NULL,
  `actor_id` bigint(20) unsigned DEFAULT NULL,
  `application_id` bigint(20) unsigned DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `details` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `auth_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auth_sessions` (
  `session_id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `token_hash` varchar(255) NOT NULL,
  `module_code` varchar(40) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` datetime DEFAULT NULL,
  `revoked_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_adjustments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_adjustments` (
  `id` int(11) NOT NULL,
  `uid` char(36) DEFAULT NULL,
  `student_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `reason` varchar(150) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` int(11) DEFAULT NULL,
  `enrollment_id` int(11) DEFAULT NULL,
  `ref_key` varchar(40) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_audit_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_bill_discounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_bill_discounts` (
  `id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `kind` enum('percent','amount') NOT NULL DEFAULT 'percent',
  `value` decimal(10,2) NOT NULL,
  `applies_to` varchar(8) NOT NULL DEFAULT 'tuition',
  `active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_bill_enrollment_discounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_bill_enrollment_discounts` (
  `id` int(11) NOT NULL,
  `enrollment_id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `percent` decimal(5,2) NOT NULL DEFAULT 0.00,
  `amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `applies_to` varchar(8) NOT NULL DEFAULT 'tuition',
  `source` varchar(8) NOT NULL DEFAULT 'staff'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_bill_enrollment_inbox`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_bill_enrollment_inbox` (
  `id` int(11) NOT NULL,
  `ext_ref` varchar(60) DEFAULT NULL,
  `event` varchar(20) DEFAULT NULL,
  `student_no` varchar(30) DEFAULT NULL,
  `status` varchar(10) NOT NULL,
  `message` varchar(255) DEFAULT NULL,
  `payload` mediumtext DEFAULT NULL,
  `enrollment_id` int(11) DEFAULT NULL,
  `received_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_bill_enrollment_subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_bill_enrollment_subjects` (
  `id` int(11) NOT NULL,
  `enrollment_id` int(11) NOT NULL,
  `code` varchar(20) DEFAULT NULL,
  `title` varchar(100) DEFAULT NULL,
  `units` decimal(4,1) NOT NULL DEFAULT 0.0,
  `lab_units` decimal(4,1) NOT NULL DEFAULT 0.0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_bill_enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_bill_enrollments` (
  `id` int(11) NOT NULL,
  `uid` char(36) NOT NULL,
  `ext_ref` varchar(60) DEFAULT NULL,
  `student_id` int(11) NOT NULL,
  `school_year` varchar(9) NOT NULL,
  `semester` varchar(12) NOT NULL,
  `year_level` tinyint(4) DEFAULT NULL,
  `course` varchar(60) DEFAULT NULL,
  `student_type` varchar(12) DEFAULT NULL,
  `units` decimal(5,1) NOT NULL DEFAULT 0.0,
  `lab_units` decimal(5,1) NOT NULL DEFAULT 0.0,
  `plan` enum('full','installment') NOT NULL DEFAULT 'installment',
  `status` enum('pre_enrolled','enrolled','dropped','withdrawn','cancelled') NOT NULL DEFAULT 'enrolled',
  `source` varchar(30) NOT NULL DEFAULT 'enrollment-system',
  `sig` char(32) DEFAULT NULL,
  `assessed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_bill_programs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_bill_programs` (
  `id` int(11) NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(60) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_bill_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_bill_settings` (
  `k` varchar(40) NOT NULL,
  `v` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_bill_terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_bill_terms` (
  `id` int(11) NOT NULL,
  `school_year` varchar(9) NOT NULL,
  `semester` varchar(12) NOT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `due_prelim` date DEFAULT NULL,
  `due_midterm` date DEFAULT NULL,
  `due_prefinal` date DEFAULT NULL,
  `due_final` date DEFAULT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_bills`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_bills` (
  `id` int(11) NOT NULL,
  `uid` char(36) DEFAULT NULL,
  `student_id` int(11) DEFAULT NULL,
  `description` varchar(150) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `enrollment_id` int(11) DEFAULT NULL,
  `ref_key` varchar(40) DEFAULT NULL,
  `category` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_enrollment_seen`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_enrollment_seen` (
  `enrollment_id` int(10) unsigned NOT NULL,
  `sig` char(32) NOT NULL,
  `failed` tinyint(1) NOT NULL DEFAULT 0,
  `seen_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_fees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_fees` (
  `id` int(11) NOT NULL,
  `name` varchar(80) NOT NULL,
  `kind` enum('fixed','per_unit','per_lab_unit') NOT NULL DEFAULT 'fixed',
  `category` enum('tuition','lab','misc','other') NOT NULL DEFAULT 'misc',
  `amount` decimal(10,2) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `course` varchar(60) DEFAULT NULL,
  `year_level` tinyint(4) DEFAULT NULL,
  `semester` varchar(12) DEFAULT NULL,
  `student_type` varchar(12) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_online_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_online_payments` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `session_id` varchar(80) NOT NULL,
  `reference` varchar(40) NOT NULL,
  `checkout_url` varchar(500) NOT NULL,
  `status` enum('pending','paid','expired','failed') NOT NULL DEFAULT 'pending',
  `channel` varchar(30) DEFAULT NULL,
  `provider_payment_id` varchar(60) DEFAULT NULL,
  `payment_id` int(11) DEFAULT NULL,
  `note` varchar(200) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `paid_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_payment_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_payment_requests` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `method` varchar(30) NOT NULL,
  `reference` varchar(60) NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `note` varchar(200) DEFAULT NULL,
  `payment_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `reviewed_by` int(11) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_payments` (
  `id` int(11) NOT NULL,
  `uid` char(36) DEFAULT NULL,
  `student_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `or_no` varchar(30) DEFAULT NULL,
  `source` enum('online','offline') DEFAULT 'online',
  `paid_at` datetime DEFAULT current_timestamp(),
  `method` varchar(12) DEFAULT NULL,
  `ref_no` varchar(40) DEFAULT NULL,
  `remarks` varchar(150) DEFAULT NULL,
  `received_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_students` (
  `id` int(11) NOT NULL,
  `student_no` varchar(30) DEFAULT NULL,
  `name` varchar(120) DEFAULT NULL,
  `course` varchar(60) DEFAULT NULL,
  `year_level` tinyint(4) DEFAULT NULL,
  `school_year` varchar(9) DEFAULT NULL,
  `semester` varchar(12) DEFAULT NULL,
  `units` smallint(6) DEFAULT NULL,
  `email` varchar(120) DEFAULT NULL,
  `contact` varchar(30) DEFAULT NULL,
  `status` varchar(12) NOT NULL DEFAULT 'active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `bil_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bil_users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `role` enum('admin','cashier','registrar','student') DEFAULT 'cashier',
  `token` char(64) DEFAULT NULL,
  `token_at` datetime DEFAULT NULL,
  `student_id` int(11) DEFAULT NULL,
  `must_change` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `billing_v_legacy_users`;
/*!50001 DROP VIEW IF EXISTS `billing_v_legacy_users`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `billing_v_legacy_users` AS SELECT
 1 AS `id`,
  1 AS `username`,
  1 AS `role`,
  1 AS `student_id`,
  1 AS `must_change`,
  1 AS `full_name`,
  1 AS `status` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `blocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blocks` (
  `block_id` int(10) unsigned NOT NULL,
  `program_id` int(10) unsigned NOT NULL,
  `period_id` int(10) unsigned NOT NULL,
  `year_level` tinyint(3) unsigned NOT NULL,
  `block_code` varchar(30) NOT NULL,
  `capacity` int(10) unsigned DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `campusfind_claims`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `campusfind_claims` (
  `campusfind_claim_id` int(10) unsigned NOT NULL,
  `campusfind_item_id` int(10) unsigned NOT NULL,
  `campusfind_claimant_user_id` int(10) unsigned NOT NULL,
  `campusfind_ownership_evidence` text NOT NULL,
  `campusfind_status` enum('pending','approved','rejected','completed') NOT NULL DEFAULT 'pending',
  `campusfind_reviewer_user_id` int(10) unsigned DEFAULT NULL,
  `campusfind_review_note` text DEFAULT NULL,
  `campusfind_reviewed_at` datetime DEFAULT NULL,
  `campusfind_completed_at` datetime DEFAULT NULL,
  `campusfind_created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `campusfind_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `campusfind_items` (
  `campusfind_item_id` int(10) unsigned NOT NULL,
  `campusfind_reporter_user_id` int(10) unsigned NOT NULL,
  `campusfind_item_type` enum('lost','found') NOT NULL,
  `campusfind_item_name` varchar(140) NOT NULL,
  `campusfind_category` varchar(60) NOT NULL,
  `campusfind_description` text NOT NULL,
  `campusfind_color` varchar(60) NOT NULL,
  `campusfind_location` varchar(150) NOT NULL,
  `campusfind_item_date` date NOT NULL,
  `campusfind_photo_path` varchar(255) DEFAULT NULL,
  `campusfind_status` enum('open','returned','closed') NOT NULL DEFAULT 'open',
  `campusfind_created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `campusfind_updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `campusfind_live_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `campusfind_live_revisions` (
  `campusfind_resource` varchar(64) NOT NULL,
  `campusfind_revision` bigint(20) unsigned NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `campusfind_section_views`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `campusfind_section_views` (
  `campusfind_user_id` int(10) unsigned NOT NULL,
  `campusfind_section_key` varchar(24) NOT NULL,
  `campusfind_last_seen_id` bigint(20) unsigned NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cebrms_borrow_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cebrms_borrow_items` (
  `borrow_item_id` bigint(20) unsigned NOT NULL,
  `transaction_id` bigint(20) unsigned NOT NULL,
  `equipment_id` int(10) unsigned NOT NULL,
  `quantity_borrowed` int(10) unsigned NOT NULL,
  `quantity_returned` int(10) unsigned NOT NULL DEFAULT 0,
  `item_status` enum('Borrowed','Partially Returned','Returned','Overdue','Lost') NOT NULL DEFAULT 'Borrowed'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cebrms_borrow_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cebrms_borrow_transactions` (
  `transaction_id` bigint(20) unsigned NOT NULL,
  `transaction_no` varchar(30) NOT NULL,
  `borrower_id` int(10) unsigned NOT NULL,
  `processed_by` int(10) unsigned DEFAULT NULL,
  `approved_by` int(10) unsigned DEFAULT NULL,
  `date_requested` datetime NOT NULL DEFAULT current_timestamp(),
  `date_borrowed` datetime DEFAULT NULL,
  `expected_return_date` date NOT NULL,
  `status` enum('Pending','Approved','Issued','Partially Returned','Returned','Overdue','Rejected','Cancelled') NOT NULL DEFAULT 'Pending',
  `purpose` varchar(255) DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  `qr_code_value` varchar(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cebrms_borrowers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cebrms_borrowers` (
  `borrower_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `student_id` int(10) unsigned DEFAULT NULL,
  `department_id` int(10) unsigned DEFAULT NULL,
  `borrower_no` varchar(30) NOT NULL,
  `borrower_type` enum('Student','Faculty','Staff','Other') NOT NULL,
  `external_full_name` varchar(100) DEFAULT NULL COMMENT 'For unregistered external borrowers only',
  `external_contact_no` varchar(20) DEFAULT NULL COMMENT 'For unregistered external borrowers only',
  `external_email` varchar(100) DEFAULT NULL COMMENT 'For unregistered external borrowers only',
  `status` enum('Active','Blocked','Inactive') NOT NULL DEFAULT 'Active',
  `qr_code_value` varchar(60) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cebrms_equipment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cebrms_equipment` (
  `equipment_id` int(10) unsigned NOT NULL,
  `category_id` int(10) unsigned NOT NULL,
  `maintenance_asset_id` int(10) unsigned DEFAULT NULL COMMENT 'Optional link to physical maintenance asset; not an automatic stock sync',
  `equipment_code` varchar(30) NOT NULL,
  `equipment_name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `total_quantity` int(10) unsigned NOT NULL DEFAULT 0,
  `available_quantity` int(10) unsigned NOT NULL DEFAULT 0,
  `damaged_quantity` int(10) unsigned NOT NULL DEFAULT 0,
  `condition_status` enum('Good','Fair','Needs Repair','Damaged') NOT NULL DEFAULT 'Good',
  `storage_location` varchar(100) DEFAULT NULL,
  `qr_code_value` varchar(60) NOT NULL,
  `status` enum('Active','Archived') NOT NULL DEFAULT 'Active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cebrms_equipment_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cebrms_equipment_categories` (
  `category_id` int(10) unsigned NOT NULL,
  `category_name` varchar(60) NOT NULL,
  `description` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cebrms_qr_scan_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cebrms_qr_scan_logs` (
  `scan_id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `qr_type` enum('Equipment','Borrower','Transaction','Unknown') NOT NULL,
  `qr_value` varchar(100) NOT NULL,
  `scan_context` enum('Borrow','Return','Lookup','Inventory') NOT NULL,
  `result` enum('Matched','Not Found','Invalid') NOT NULL,
  `scanned_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cebrms_return_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cebrms_return_records` (
  `return_id` bigint(20) unsigned NOT NULL,
  `borrow_item_id` bigint(20) unsigned NOT NULL,
  `received_by` int(10) unsigned NOT NULL,
  `actual_return_date` datetime NOT NULL DEFAULT current_timestamp(),
  `quantity_returned` int(10) unsigned NOT NULL,
  `quantity_damaged` int(10) unsigned NOT NULL DEFAULT 0,
  `quantity_missing` int(10) unsigned NOT NULL DEFAULT 0,
  `condition_notes` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `class_enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `class_enrollments` (
  `enrollment_id` int(11) NOT NULL,
  `enrollment_uid` char(36) DEFAULT NULL,
  `student_id` int(10) unsigned NOT NULL,
  `class_id` bigint(20) unsigned NOT NULL,
  `membership_status` enum('Active','Withdrawn','Completed') NOT NULL DEFAULT 'Active',
  `enrolled_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `credits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `credits` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `evaluator_id` bigint(20) unsigned NOT NULL,
  `course_name` varchar(180) NOT NULL,
  `units` tinyint(3) unsigned NOT NULL,
  `status` enum('recommended','approved','rejected') NOT NULL DEFAULT 'recommended',
  `remarks` text DEFAULT NULL,
  `decided_by` bigint(20) unsigned DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `departments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `departments` (
  `department_id` int(10) unsigned NOT NULL,
  `department_code` varchar(30) NOT NULL,
  `department_name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `education_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `education_records` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `institution` varchar(180) NOT NULL,
  `program_name` varchar(180) NOT NULL,
  `start_year` smallint(5) unsigned DEFAULT NULL,
  `end_year` smallint(5) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_ballots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_ballots` (
  `ballot_id` bigint(20) NOT NULL,
  `candidate_id` int(11) NOT NULL,
  `cast_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_candidacies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_candidacies` (
  `candidate_id` int(11) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `position_id` int(11) NOT NULL,
  `profile` text DEFAULT NULL,
  `platform` text DEFAULT NULL,
  `filing_status` enum('pending','approved','declined') NOT NULL DEFAULT 'pending',
  `review_remarks` text DEFAULT NULL,
  `reviewed_by` int(10) unsigned DEFAULT NULL,
  `review_date` datetime DEFAULT NULL,
  `filed_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_candidate_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_candidate_documents` (
  `document_id` int(11) NOT NULL,
  `candidate_id` int(11) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `upload_date` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_elections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_elections` (
  `election_id` int(11) NOT NULL,
  `election_name` varchar(150) NOT NULL,
  `academic_year` varchar(20) DEFAULT NULL,
  `voting_start` datetime NOT NULL,
  `voting_end` datetime NOT NULL,
  `face_match_threshold` decimal(4,3) NOT NULL DEFAULT 0.800,
  `eligibility_criteria` varchar(255) DEFAULT NULL,
  `election_status` enum('draft','scheduled','open','closed','archived') NOT NULL DEFAULT 'draft',
  `created_by` int(10) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_face_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_face_data` (
  `face_id` int(11) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `face_template` varbinary(2048) NOT NULL,
  `consent_status` enum('given','withdrawn') NOT NULL,
  `consent_date` datetime NOT NULL,
  `enrolled_at` datetime NOT NULL DEFAULT current_timestamp(),
  `data_status` enum('active','deleted') NOT NULL DEFAULT 'active',
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_face_verifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_face_verifications` (
  `verification_id` bigint(20) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `election_id` int(11) NOT NULL,
  `match_score` decimal(5,4) DEFAULT NULL,
  `liveness_result` enum('passed','failed') DEFAULT NULL,
  `verification_status` enum('verified','failed','pending_manual','manually_verified') NOT NULL,
  `reviewed_by` int(10) unsigned DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `attempted_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_positions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_positions` (
  `position_id` int(11) NOT NULL,
  `election_id` int(11) NOT NULL,
  `position_name` varchar(100) NOT NULL,
  `seats` tinyint(4) NOT NULL DEFAULT 1,
  `display_order` tinyint(4) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_results` (
  `result_id` int(11) NOT NULL,
  `candidate_id` int(11) NOT NULL,
  `vote_count` int(11) NOT NULL DEFAULT 0,
  `is_winner` tinyint(1) NOT NULL DEFAULT 0,
  `proclaimed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_security_login_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_security_login_attempts` (
  `attempt_id` bigint(20) unsigned NOT NULL,
  `email_hash` char(64) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `attempted_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_security_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_security_sessions` (
  `session_id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `token_hash` char(64) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `user_agent` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `last_seen_at` datetime NOT NULL DEFAULT current_timestamp(),
  `revoked_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `election_vote_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `election_vote_records` (
  `record_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `position_id` int(11) NOT NULL,
  `voted_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `employment_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `employment_records` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `company` varchar(180) NOT NULL,
  `job_title` varchar(180) NOT NULL,
  `date_started` date NOT NULL,
  `date_ended` date DEFAULT NULL,
  `responsibilities` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ems_employee_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ems_employee_details` (
  `user_id` int(10) unsigned NOT NULL,
  `employee_code` varchar(20) NOT NULL,
  `contact_number` varchar(30) DEFAULT NULL,
  `employment_status` enum('Active','Inactive','OnLeave','Resigned') NOT NULL DEFAULT 'Active',
  `date_hired` date DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ems_employee_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ems_employee_documents` (
  `document_id` bigint(20) unsigned NOT NULL,
  `employee_user_id` int(10) unsigned NOT NULL,
  `category` varchar(50) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `stored_path` varchar(500) NOT NULL,
  `uploaded_by_user_id` int(10) unsigned NOT NULL,
  `uploaded_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `enrollment_charges`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `enrollment_charges` (
  `charge_id` bigint(20) unsigned NOT NULL,
  `enrollment_id` int(10) unsigned NOT NULL,
  `fee_id` int(10) unsigned DEFAULT NULL,
  `fee_name_snapshot` varchar(150) NOT NULL,
  `amount_snapshot` decimal(12,2) NOT NULL,
  `assessed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `enrollment_subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `enrollment_subjects` (
  `enrollment_subject_id` int(10) unsigned NOT NULL,
  `enrollment_id` int(10) unsigned NOT NULL,
  `subject_id` int(10) unsigned NOT NULL,
  `subject_status` enum('Enrolled','Dropped') NOT NULL DEFAULT 'Enrolled',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `enrollments` (
  `enrollment_id` int(10) unsigned NOT NULL,
  `enrollment_number` varchar(35) DEFAULT NULL,
  `pre_enrollment_id` int(10) unsigned DEFAULT NULL,
  `enrollment_method` enum('Direct','Pre-Enrollment') NOT NULL DEFAULT 'Pre-Enrollment',
  `student_id` int(10) unsigned NOT NULL,
  `program_id` int(10) unsigned NOT NULL,
  `period_id` int(10) unsigned NOT NULL,
  `year_level` tinyint(3) unsigned NOT NULL,
  `block_id` int(10) unsigned DEFAULT NULL,
  `enrollment_status` enum('Pending','Confirmed','Cancelled') NOT NULL DEFAULT 'Pending',
  `student_load` enum('Regular','Irregular') NOT NULL DEFAULT 'Regular',
  `irregular_details` varchar(255) DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  `verified_by` int(10) unsigned DEFAULT NULL,
  `confirmed_by` int(10) unsigned DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_announcements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_announcements` (
  `id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `body` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_appeals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_appeals` (
  `id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `checkpoint_id` int(11) DEFAULT NULL,
  `reason` text NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `decided_by` int(11) DEFAULT NULL,
  `decision_note` varchar(255) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_attendance` (
  `id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `time_in` datetime DEFAULT NULL,
  `time_out` datetime DEFAULT NULL,
  `auto_timeout` tinyint(1) NOT NULL DEFAULT 0,
  `minutes_inside` decimal(7,1) NOT NULL DEFAULT 0.0,
  `unverified_minutes` decimal(7,1) NOT NULL DEFAULT 0.0,
  `checkpoints_passed` smallint(6) NOT NULL DEFAULT 0,
  `checkpoints_required` smallint(6) NOT NULL DEFAULT 0,
  `final_status` enum('present','late','partial','absent','flagged','excused') DEFAULT NULL,
  `override_status` enum('present','late','partial','absent','excused') DEFAULT NULL,
  `override_reason` varchar(255) DEFAULT NULL,
  `override_by` int(11) DEFAULT NULL,
  `presence_state` enum('inside','outside','stale','out_outside','out_offline','checked_out') DEFAULT NULL,
  `last_ping_at` datetime DEFAULT NULL,
  `last_inside_at` datetime DEFAULT NULL,
  `last_lat` decimal(10,7) DEFAULT NULL,
  `last_lng` decimal(10,7) DEFAULT NULL,
  `last_inside` tinyint(1) DEFAULT NULL,
  `outside_streak` tinyint(4) NOT NULL DEFAULT 0,
  `outside_since` datetime DEFAULT NULL,
  `manual_entry` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_audit_logs` (
  `id` bigint(20) NOT NULL,
  `actor_id` int(11) DEFAULT NULL,
  `actor_role` varchar(20) DEFAULT NULL,
  `action` varchar(80) NOT NULL,
  `target_type` varchar(40) DEFAULT NULL,
  `target_id` int(11) DEFAULT NULL,
  `detail` text DEFAULT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_challenges`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_challenges` (
  `id` bigint(20) NOT NULL,
  `nonce` char(32) NOT NULL,
  `student_id` int(11) NOT NULL,
  `checkpoint_id` int(11) NOT NULL,
  `type` varchar(12) NOT NULL,
  `used` tinyint(1) NOT NULL DEFAULT 0,
  `expires_at` datetime NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_checkpoint_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_checkpoint_results` (
  `id` bigint(20) NOT NULL,
  `checkpoint_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `result` enum('passed','missed','failed','outside','flagged','excused') NOT NULL,
  `best_attempt_id` bigint(20) DEFAULT NULL,
  `decided_by` int(11) DEFAULT NULL,
  `decision_note` varchar(255) DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_checkpoints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_checkpoints` (
  `id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  `seq` smallint(6) NOT NULL,
  `kind` enum('checkin','hourly','closing','checkout') NOT NULL,
  `opens_at` datetime NOT NULL,
  `closes_at` datetime NOT NULL,
  `state` enum('pending','open','closed') NOT NULL DEFAULT 'pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_course_representatives`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_course_representatives` (
  `course_id` int(11) NOT NULL,
  `rep_id` int(11) NOT NULL,
  `assigned_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_course_sections`;
/*!50001 DROP VIEW IF EXISTS `et_course_sections`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `et_course_sections` AS SELECT
 1 AS `id`,
  1 AS `course_id`,
  1 AS `name` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `et_courses`;
/*!50001 DROP VIEW IF EXISTS `et_courses`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `et_courses` AS SELECT
 1 AS `id`,
  1 AS `code`,
  1 AS `name` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `et_device_change_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_device_change_requests` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `new_device_hash` char(64) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `reason` varchar(255) NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `decided_by` int(11) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_devices` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `device_hash` char(64) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `bound_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_event_audience`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_event_audience` (
  `id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  `course_id` int(11) DEFAULT NULL,
  `year_level` tinyint(4) DEFAULT NULL,
  `section` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_event_breaks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_event_breaks` (
  `id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  `label` varchar(80) NOT NULL,
  `starts_at` datetime NOT NULL,
  `ends_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_events` (
  `id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `venue_id` int(11) NOT NULL,
  `owner_rep_id` int(11) NOT NULL,
  `starts_at` datetime NOT NULL,
  `ends_at` datetime NOT NULL,
  `checkin_opens_min_before` smallint(6) NOT NULL DEFAULT 15,
  `late_after_min` smallint(6) NOT NULL DEFAULT 15,
  `checkpoint_interval_min` smallint(6) NOT NULL DEFAULT 60,
  `checkpoint_window_min` smallint(6) NOT NULL DEFAULT 10,
  `require_checkout_scan` tinyint(1) NOT NULL DEFAULT 0,
  `required_pass_percent` tinyint(4) NOT NULL DEFAULT 100,
  `partial_pass_percent` tinyint(4) NOT NULL DEFAULT 50,
  `outside_grace_min` smallint(6) NOT NULL DEFAULT 5,
  `offline_grace_min` smallint(6) NOT NULL DEFAULT 5,
  `required_presence_percent` tinyint(4) NOT NULL DEFAULT 80,
  `partial_presence_percent` tinyint(4) NOT NULL DEFAULT 40,
  `status` enum('draft','scheduled','live','ended','finalized','cancelled') NOT NULL DEFAULT 'draft',
  `finalized_at` datetime DEFAULT NULL,
  `reopened_reason` varchar(255) DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  `status_before_delete` varchar(20) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_face_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_face_templates` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `descriptor_enc` text DEFAULT NULL,
  `is_reference` tinyint(1) NOT NULL DEFAULT 0,
  `photo_enc` mediumtext DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_flags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_flags` (
  `id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `scan_attempt_id` bigint(20) DEFAULT NULL,
  `reason` varchar(60) NOT NULL,
  `severity` enum('info','warn','block') NOT NULL,
  `status` enum('open','approved','rejected','auto_closed') NOT NULL DEFAULT 'open',
  `reviewed_by` int(11) DEFAULT NULL,
  `review_note` varchar(255) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_presence_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_presence_events` (
  `id` bigint(20) NOT NULL,
  `event_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `state` enum('inside','outside','stale','out_outside','out_offline','checked_out') NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_rate_limits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_rate_limits` (
  `k` varchar(120) NOT NULL,
  `hits` int(11) NOT NULL,
  `reset_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_scan_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_scan_attempts` (
  `id` bigint(20) NOT NULL,
  `checkpoint_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `idempotency_key` char(36) NOT NULL,
  `outcome` enum('passed','borderline','failed','outside','rejected') NOT NULL,
  `reject_reason` varchar(60) DEFAULT NULL,
  `challenge_type` varchar(12) DEFAULT NULL,
  `face_distance` decimal(5,4) DEFAULT NULL,
  `lat` decimal(10,7) DEFAULT NULL,
  `lng` decimal(10,7) DEFAULT NULL,
  `accuracy_m` decimal(7,2) DEFAULT NULL,
  `fix_age_ms` int(11) DEFAULT NULL,
  `snapshot_enc` mediumtext DEFAULT NULL,
  `spot_reviewed` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_settings` (
  `k` varchar(60) NOT NULL,
  `v` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_student_profiles`;
/*!50001 DROP VIEW IF EXISTS `et_student_profiles`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `et_student_profiles` AS SELECT
 1 AS `user_id`,
  1 AS `course_id`,
  1 AS `year_level`,
  1 AS `section`,
  1 AS `consent_at`,
  1 AS `consent_version`,
  1 AS `guardian_consent`,
  1 AS `face_enrolled` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `et_user_state`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_user_state` (
  `user_id` int(10) unsigned NOT NULL,
  `rep_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `organization` varchar(150) DEFAULT NULL,
  `suspended` tinyint(1) NOT NULL DEFAULT 0,
  `failed_logins` tinyint(4) NOT NULL DEFAULT 0,
  `locked_until` datetime DEFAULT NULL,
  `consent_at` datetime DEFAULT NULL,
  `consent_version` varchar(20) DEFAULT NULL,
  `guardian_consent` tinyint(1) NOT NULL DEFAULT 0,
  `face_enrolled` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `et_users`;
/*!50001 DROP VIEW IF EXISTS `et_users`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `et_users` AS SELECT
 1 AS `id`,
  1 AS `role`,
  1 AS `login_id`,
  1 AS `full_name`,
  1 AS `email`,
  1 AS `password_hash`,
  1 AS `status`,
  1 AS `must_change_pw`,
  1 AS `rep_enabled`,
  1 AS `failed_logins`,
  1 AS `locked_until`,
  1 AS `last_login_at`,
  1 AS `created_at` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `et_venues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `et_venues` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `shape` enum('circle','polygon') NOT NULL DEFAULT 'circle',
  `center_lat` decimal(10,7) DEFAULT NULL,
  `center_lng` decimal(10,7) DEFAULT NULL,
  `radius_m` int(11) DEFAULT NULL,
  `polygon_json` text DEFAULT NULL,
  `tolerance_m` int(11) NOT NULL DEFAULT 20,
  `max_accuracy_m` int(11) NOT NULL DEFAULT 50,
  `created_by` int(11) NOT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  `retired` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_academic_decisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_academic_decisions` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `round_no` int(10) unsigned NOT NULL,
  `decision` enum('approved','returned','declined') NOT NULL,
  `rationale` text NOT NULL,
  `decided_by` bigint(20) unsigned NOT NULL,
  `decided_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_applications` (
  `id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `reference_no` varchar(30) DEFAULT NULL,
  `program` varchar(30) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `gender` varchar(30) DEFAULT NULL,
  `civil_status` varchar(30) DEFAULT NULL,
  `nationality` varchar(70) DEFAULT 'Filipino',
  `address_line` varchar(255) DEFAULT NULL,
  `province` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `status` enum('draft','submitted','screening','portfolio_review','assessment','for_decision','approved','revision_required','completed') NOT NULL DEFAULT 'draft',
  `submitted_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_assessments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_assessments` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `assessor_id` int(10) unsigned DEFAULT NULL,
  `title` varchar(150) NOT NULL,
  `scheduled_at` datetime NOT NULL,
  `mode` enum('Onsite','Online') NOT NULL DEFAULT 'Onsite',
  `venue` varchar(255) NOT NULL,
  `status` enum('scheduled','completed','cancelled') NOT NULL DEFAULT 'scheduled',
  `feedback` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_audit_logs` (
  `id` bigint(20) unsigned NOT NULL,
  `actor_id` bigint(20) unsigned DEFAULT NULL,
  `application_id` bigint(20) unsigned DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `details` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_billing_fees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_billing_fees` (
  `id` bigint(20) unsigned NOT NULL,
  `code` varchar(30) NOT NULL,
  `label` varchar(160) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(10) unsigned NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_billing_invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_billing_invoices` (
  `id` bigint(20) unsigned NOT NULL,
  `invoice_no` varchar(32) DEFAULT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `fee_id` bigint(20) unsigned NOT NULL,
  `description` varchar(160) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `status` enum('issued','part_paid','paid','voided') NOT NULL DEFAULT 'issued',
  `due_on` date DEFAULT NULL,
  `created_by` int(10) unsigned NOT NULL,
  `void_reason` varchar(250) DEFAULT NULL,
  `voided_by` int(10) unsigned DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_billing_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_billing_payments` (
  `id` bigint(20) unsigned NOT NULL,
  `receipt_no` varchar(32) DEFAULT NULL,
  `invoice_id` bigint(20) unsigned NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `method` enum('cash','bank_transfer','gcash','other') NOT NULL,
  `external_reference` varchar(110) NOT NULL,
  `paid_on` date NOT NULL,
  `status` enum('posted','voided') NOT NULL DEFAULT 'posted',
  `recorded_by` int(10) unsigned NOT NULL,
  `void_reason` varchar(250) DEFAULT NULL,
  `voided_by` int(10) unsigned DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_credits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_credits` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `evaluator_id` int(10) unsigned NOT NULL,
  `course_name` varchar(180) NOT NULL,
  `units` tinyint(3) unsigned NOT NULL,
  `status` enum('recommended','approved','rejected') NOT NULL DEFAULT 'recommended',
  `remarks` text DEFAULT NULL,
  `decided_by` int(10) unsigned DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_education_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_education_records` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `institution` varchar(180) NOT NULL,
  `program_name` varchar(180) NOT NULL,
  `start_year` smallint(5) unsigned DEFAULT NULL,
  `end_year` smallint(5) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_employment_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_employment_records` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `company` varchar(180) NOT NULL,
  `job_title` varchar(180) NOT NULL,
  `date_started` date NOT NULL,
  `date_ended` date DEFAULT NULL,
  `responsibilities` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_enrollments` (
  `application_id` bigint(20) unsigned NOT NULL,
  `enrollment_reference` varchar(100) NOT NULL,
  `academic_year` varchar(9) NOT NULL,
  `enrolled_on` date NOT NULL,
  `verified_by` bigint(20) unsigned NOT NULL,
  `verified_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_evaluations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_evaluations` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `assessor_id` int(10) unsigned NOT NULL,
  `authenticity` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `relevance` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `sufficiency` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `currency_score` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `feedback` text DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_finance_clearances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_finance_clearances` (
  `application_id` bigint(20) unsigned NOT NULL,
  `status` enum('cleared','on_hold') NOT NULL,
  `note` varchar(500) NOT NULL,
  `reviewed_by` bigint(20) unsigned NOT NULL,
  `reviewed_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_form_field_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_form_field_reviews` (
  `form_key` varchar(40) NOT NULL,
  `field_id` varchar(40) NOT NULL,
  `word_location` varchar(180) NOT NULL,
  `evidence_note` varchar(500) NOT NULL,
  `source_sha256` char(64) NOT NULL,
  `reviewed_by` bigint(20) unsigned NOT NULL,
  `reviewed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_form_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_form_records` (
  `id` int(10) unsigned NOT NULL,
  `form_key` varchar(20) NOT NULL,
  `application_id` int(10) unsigned NOT NULL DEFAULT 0,
  `author_id` int(10) unsigned NOT NULL,
  `author_role` varchar(20) NOT NULL,
  `responses` longtext NOT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_form_signoffs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_form_signoffs` (
  `form_key` varchar(40) NOT NULL,
  `approved_version` varchar(120) NOT NULL,
  `acceptance_reference` varchar(180) NOT NULL,
  `source_sha256` char(64) NOT NULL,
  `reviewed_fields` smallint(5) unsigned NOT NULL,
  `unresolved_fields` smallint(5) unsigned NOT NULL,
  `verified_by` bigint(20) unsigned NOT NULL,
  `verified_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_grades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_grades` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `assessor_id` int(10) unsigned NOT NULL,
  `course_name` varchar(180) NOT NULL,
  `grade` decimal(5,2) NOT NULL,
  `status` enum('draft','published') NOT NULL DEFAULT 'draft',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_login_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_login_attempts` (
  `id` bigint(20) unsigned NOT NULL,
  `login_key` char(64) NOT NULL,
  `attempted_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_messages` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `sender_id` int(10) unsigned NOT NULL,
  `channel` enum('coordinator','assessor') NOT NULL DEFAULT 'coordinator',
  `subject` varchar(180) NOT NULL DEFAULT 'ETEEAP Message',
  `body` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_notifications` (
  `id` bigint(20) unsigned NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `upload_id` bigint(20) unsigned DEFAULT NULL,
  `title` varchar(180) NOT NULL,
  `body` text NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_panel_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_panel_members` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `assessor_id` bigint(20) unsigned NOT NULL,
  `member_type` enum('internal','external') NOT NULL,
  `appointed_by` bigint(20) unsigned NOT NULL,
  `appointed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_panel_votes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_panel_votes` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `assessor_id` bigint(20) unsigned NOT NULL,
  `round_no` int(10) unsigned NOT NULL,
  `recommendation` enum('endorse','revise','not_endorse') NOT NULL,
  `findings` text NOT NULL,
  `conflict_checked` tinyint(1) NOT NULL DEFAULT 0,
  `signed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_panels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_panels` (
  `application_id` bigint(20) unsigned NOT NULL,
  `round_no` int(10) unsigned NOT NULL DEFAULT 1,
  `minimum_votes` tinyint(3) unsigned NOT NULL DEFAULT 2,
  `meeting_on` datetime DEFAULT NULL,
  `created_by` bigint(20) unsigned NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_portfolio_assessments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_portfolio_assessments` (
  `assessment_id` int(11) NOT NULL,
  `applicant_id` int(11) NOT NULL,
  `assessor_id` int(11) NOT NULL,
  `assessment_date` date NOT NULL,
  `score_profile` decimal(5,2) DEFAULT 0.00,
  `score_education` decimal(5,2) DEFAULT 0.00,
  `score_technical` decimal(5,2) DEFAULT 0.00,
  `score_experience` decimal(5,2) DEFAULT 0.00,
  `score_projects` decimal(5,2) DEFAULT 0.00,
  `score_reflection` decimal(5,2) DEFAULT 0.00,
  `total_score` decimal(5,2) DEFAULT 0.00,
  `interpretation` varchar(50) DEFAULT NULL,
  `recommendation_tier` varchar(100) DEFAULT NULL,
  `panel_recommendation` enum('Approved for Full Credit','Approved with Conditions','Partial Credit Only','Not Qualified under ETEEAP') NOT NULL,
  `remarks` text DEFAULT NULL,
  `status` enum('Draft','Submitted by Assessor','Approved by Coordinator','Finalized') DEFAULT 'Submitted by Assessor',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_portfolio_rubric_forms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_portfolio_rubric_forms` (
  `id` int(10) unsigned NOT NULL,
  `application_id` int(10) unsigned NOT NULL,
  `assessor_id` int(10) unsigned NOT NULL,
  `assessment_date` date DEFAULT NULL,
  `panel_name` varchar(250) NOT NULL DEFAULT '',
  `ratings_json` text NOT NULL,
  `recommendation` varchar(80) NOT NULL DEFAULT '',
  `remarks` text NOT NULL,
  `total_score` decimal(6,3) DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_privacy_acknowledgements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_privacy_acknowledgements` (
  `user_id` bigint(20) unsigned NOT NULL,
  `notice_version` varchar(50) NOT NULL,
  `acknowledged_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_program_offerings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_program_offerings` (
  `id` bigint(20) unsigned NOT NULL,
  `code` varchar(30) NOT NULL,
  `degree_name` varchar(180) NOT NULL,
  `authorization_reference` varchar(180) NOT NULL,
  `valid_from` date NOT NULL,
  `valid_until` date NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `configured_by` int(10) unsigned NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_registrar_clearances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_registrar_clearances` (
  `application_id` bigint(20) unsigned NOT NULL,
  `credential_reference` varchar(90) NOT NULL,
  `graduation_on` date NOT NULL,
  `note` varchar(500) NOT NULL,
  `cleared_by` bigint(20) unsigned NOT NULL,
  `cleared_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_screenings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_screenings` (
  `application_id` bigint(20) unsigned NOT NULL,
  `decision` enum('eligible','needs_revision','ineligible') NOT NULL,
  `education_verified` tinyint(1) NOT NULL DEFAULT 0,
  `citizenship_verified` tinyint(1) NOT NULL DEFAULT 0,
  `second_degree_rule_checked` tinyint(1) NOT NULL DEFAULT 0,
  `work_relevance_verified` tinyint(1) NOT NULL DEFAULT 0,
  `notes` text NOT NULL,
  `reviewed_by` bigint(20) unsigned NOT NULL,
  `reviewed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_supplement_plans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_supplement_plans` (
  `application_id` bigint(20) unsigned NOT NULL,
  `plan_type` enum('none','required') NOT NULL,
  `rationale` text NOT NULL,
  `approved_by` bigint(20) unsigned NOT NULL,
  `decided_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_supplement_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_supplement_tasks` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `title` varchar(180) NOT NULL,
  `modality` enum('onsite','online','blended','workplace') NOT NULL,
  `requirements` text NOT NULL,
  `due_on` date DEFAULT NULL,
  `completion_note` text DEFAULT NULL,
  `evidence_upload_id` bigint(20) unsigned DEFAULT NULL,
  `state` enum('assigned','submitted','verified','waived') NOT NULL DEFAULT 'assigned',
  `assigned_by` bigint(20) unsigned NOT NULL,
  `reviewed_by` bigint(20) unsigned DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_tracer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_tracer` (
  `application_id` bigint(20) unsigned NOT NULL,
  `consent` tinyint(1) NOT NULL DEFAULT 0,
  `employment_status` enum('employed','self_employed','seeking','other') DEFAULT NULL,
  `industry` varchar(120) DEFAULT NULL,
  `submitted_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_upload_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_upload_events` (
  `id` bigint(20) unsigned NOT NULL,
  `upload_id` bigint(20) unsigned NOT NULL,
  `actor_id` int(10) unsigned DEFAULT NULL,
  `event_type` enum('uploaded','reviewed','resubmitted','legacy_review') NOT NULL,
  `old_status` enum('pending','verified','revision') DEFAULT NULL,
  `new_status` enum('pending','verified','revision') NOT NULL,
  `note` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_uploads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_uploads` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `uploaded_by` int(10) unsigned NOT NULL,
  `kind` enum('document','portfolio') NOT NULL,
  `requirement_key` varchar(40) DEFAULT NULL,
  `category` enum('employment','training','certification','project','supporting') DEFAULT NULL,
  `title` varchar(180) NOT NULL,
  `description` text DEFAULT NULL,
  `storage_name` varchar(90) NOT NULL,
  `original_name` varchar(255) NOT NULL,
  `mime_type` varchar(80) NOT NULL,
  `size_bytes` bigint(20) unsigned NOT NULL,
  `replaces_upload_id` bigint(20) unsigned DEFAULT NULL,
  `status` enum('pending','verified','revision') NOT NULL DEFAULT 'pending',
  `reviewer_note` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `eteeap_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eteeap_users` (
  `id` bigint(20) unsigned NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(190) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('applicant','coordinator','assessor','admin','finance','academic_head','registrar') NOT NULL DEFAULT 'applicant',
  `phone` varchar(35) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `session_version` int(10) unsigned NOT NULL DEFAULT 1,
  `mfa_secret` text DEFAULT NULL,
  `mfa_last_step` bigint(20) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `evaluations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `evaluations` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `assessor_id` bigint(20) unsigned NOT NULL,
  `authenticity` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `relevance` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `sufficiency` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `currency_score` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `feedback` text DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_criteria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_criteria` (
  `criterion_id` int(10) unsigned NOT NULL,
  `event_id` int(10) unsigned NOT NULL,
  `criterion_name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `weight_percentage` decimal(5,2) NOT NULL,
  `maximum_score` decimal(7,2) NOT NULL,
  `display_order` int(10) unsigned NOT NULL DEFAULT 1,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_entries` (
  `entry_id` int(10) unsigned NOT NULL,
  `event_id` int(10) unsigned NOT NULL,
  `participant_id` int(10) unsigned DEFAULT NULL,
  `team_id` int(10) unsigned DEFAULT NULL,
  `entry_code` varchar(30) NOT NULL,
  `status` enum('Registered','Withdrawn','Disqualified') NOT NULL DEFAULT 'Registered',
  `record_uuid` char(36) NOT NULL,
  `registered_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_events` (
  `event_id` int(10) unsigned NOT NULL,
  `event_name` varchar(150) NOT NULL,
  `event_category` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `event_date` date DEFAULT NULL,
  `status` enum('Upcoming','Ongoing','Completed') NOT NULL DEFAULT 'Upcoming',
  `created_by` int(10) unsigned NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `is_published` tinyint(1) NOT NULL DEFAULT 0,
  `publication_version` bigint(20) unsigned NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_generated_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_generated_reports` (
  `report_id` int(10) unsigned NOT NULL,
  `event_id` int(10) unsigned DEFAULT NULL,
  `report_type` varchar(100) NOT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `generated_by` int(10) unsigned NOT NULL,
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_integration_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_integration_logs` (
  `integration_log_id` bigint(20) unsigned NOT NULL,
  `service_name` varchar(150) NOT NULL,
  `request_type` varchar(50) NOT NULL,
  `reference_id` varchar(100) DEFAULT NULL,
  `response_status` varchar(50) NOT NULL,
  `error_message` text DEFAULT NULL,
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_judges`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_judges` (
  `assignment_id` int(10) unsigned NOT NULL,
  `event_id` int(10) unsigned NOT NULL,
  `judge_user_id` int(10) unsigned NOT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `record_uuid` char(36) NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_participant_photos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_participant_photos` (
  `participant_id` int(10) unsigned NOT NULL,
  `filename` varchar(80) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `is_public` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_participants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_participants` (
  `participant_id` int(10) unsigned NOT NULL,
  `student_reference` varchar(100) DEFAULT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `program_section` varchar(150) DEFAULT NULL,
  `participant_type` enum('Individual','Team Member') NOT NULL DEFAULT 'Individual',
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_point_awards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_point_awards` (
  `point_award_id` int(10) unsigned NOT NULL,
  `result_id` int(10) unsigned NOT NULL,
  `participant_id` int(10) unsigned DEFAULT NULL,
  `team_id` int(10) unsigned DEFAULT NULL,
  `points_awarded` decimal(8,2) NOT NULL DEFAULT 0.00,
  `approved_by` int(10) unsigned NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `awarded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_point_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_point_rules` (
  `point_rule_id` int(10) unsigned NOT NULL,
  `event_id` int(10) unsigned NOT NULL,
  `rank_position` int(10) unsigned NOT NULL,
  `points_value` decimal(8,2) NOT NULL DEFAULT 0.00,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_result_summaries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_result_summaries` (
  `result_id` int(10) unsigned NOT NULL,
  `entry_id` int(10) unsigned NOT NULL,
  `total_score` decimal(10,4) NOT NULL DEFAULT 0.0000,
  `rank_position` int(10) unsigned DEFAULT NULL,
  `result_status` enum('Provisional','Finalized') NOT NULL DEFAULT 'Provisional',
  `calculated_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `finalized_at` timestamp NULL DEFAULT NULL,
  `record_uuid` char(36) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_scores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_scores` (
  `score_id` int(10) unsigned NOT NULL,
  `entry_id` int(10) unsigned NOT NULL,
  `assignment_id` int(10) unsigned NOT NULL,
  `criterion_id` int(10) unsigned NOT NULL,
  `score_value` decimal(7,2) NOT NULL,
  `status` enum('Draft','Submitted','Approved') NOT NULL DEFAULT 'Draft',
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_sports_matches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_sports_matches` (
  `match_id` bigint(20) unsigned NOT NULL,
  `event_id` int(10) unsigned NOT NULL,
  `entry_a_id` int(10) unsigned NOT NULL,
  `entry_b_id` int(10) unsigned NOT NULL,
  `sport` enum('basketball','volleyball','other') NOT NULL,
  `sport_label` varchar(100) DEFAULT NULL,
  `score_a` int(10) unsigned DEFAULT NULL,
  `score_b` int(10) unsigned DEFAULT NULL,
  `period` varchar(100) DEFAULT NULL,
  `status` enum('scheduled','ongoing','completed') NOT NULL DEFAULT 'scheduled',
  `version` int(10) unsigned NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_staff_registration_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_staff_registration_requests` (
  `id` bigint(20) unsigned NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `requested_role` varchar(30) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Pending',
  `reviewed_by` int(10) unsigned DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_sync_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_sync_queue` (
  `sync_id` bigint(20) unsigned NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `table_name` varchar(100) NOT NULL,
  `operation` enum('Create','Update','Delete') NOT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`payload`)),
  `record_version` int(10) unsigned NOT NULL DEFAULT 1,
  `sync_status` enum('Pending','Processing','Synchronized','Failed','Conflict') NOT NULL DEFAULT 'Pending',
  `attempts` int(10) unsigned NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `synced_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_tabulator_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_tabulator_assignments` (
  `event_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_team_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_team_members` (
  `team_member_id` int(10) unsigned NOT NULL,
  `team_id` int(10) unsigned NOT NULL,
  `participant_id` int(10) unsigned NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `event_teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_teams` (
  `team_id` int(10) unsigned NOT NULL,
  `team_name` varchar(150) NOT NULL,
  `department` varchar(150) DEFAULT NULL,
  `coach_name` varchar(150) DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_completion_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_completion_logs` (
  `completion_id` int(11) NOT NULL,
  `schedule_id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `anonymous_hash` char(64) NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_department_heads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_department_heads` (
  `department_head_id` int(11) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `department_id` int(10) unsigned NOT NULL,
  `employee_number` varchar(30) DEFAULT NULL,
  `designation` varchar(100) DEFAULT 'Department Head',
  `appointment_start` date DEFAULT NULL,
  `appointment_end` date DEFAULT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_evaluation_questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_evaluation_questions` (
  `question_id` int(11) NOT NULL,
  `schedule_id` int(11) NOT NULL,
  `category` varchar(60) NOT NULL,
  `question_text` text NOT NULL,
  `question_order` int(11) NOT NULL,
  `rating_min` tinyint(4) NOT NULL DEFAULT 1,
  `rating_max` tinyint(4) NOT NULL DEFAULT 5,
  `is_required` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_evaluation_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_evaluation_reports` (
  `report_id` int(11) NOT NULL,
  `schedule_id` int(11) NOT NULL,
  `report_level` enum('FACULTY','PROGRAM','DEPARTMENT') NOT NULL,
  `department_id` int(10) unsigned DEFAULT NULL,
  `program_id` int(10) unsigned DEFAULT NULL,
  `faculty_id` int(10) unsigned DEFAULT NULL,
  `total_responses` int(11) NOT NULL DEFAULT 0,
  `average_rating` decimal(4,2) DEFAULT NULL,
  `score_percentage` decimal(5,2) DEFAULT NULL,
  `generated_by` int(10) unsigned NOT NULL,
  `approved_by` int(10) unsigned DEFAULT NULL,
  `release_status` enum('DRAFT','APPROVED','RELEASED','WITHHELD') NOT NULL DEFAULT 'DRAFT',
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_evaluation_responses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_evaluation_responses` (
  `response_id` int(11) NOT NULL,
  `submission_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `rating` tinyint(4) NOT NULL,
  `comment` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_evaluation_schedules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_evaluation_schedules` (
  `schedule_id` int(11) NOT NULL,
  `term_id` int(10) unsigned NOT NULL,
  `program_id` int(10) unsigned NOT NULL,
  `opens_at` datetime NOT NULL,
  `closes_at` datetime NOT NULL,
  `status` enum('DRAFT','SCHEDULED','READY','OPEN','CLOSED','RELEASED') NOT NULL DEFAULT 'SCHEDULED',
  `grade_gate_passed` tinyint(1) NOT NULL DEFAULT 0,
  `created_by` int(10) unsigned NOT NULL,
  `opened_by` int(10) unsigned DEFAULT NULL,
  `opened_at` datetime DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_evaluation_submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_evaluation_submissions` (
  `submission_id` int(11) NOT NULL,
  `schedule_id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `anonymous_token` char(64) NOT NULL,
  `submitted_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_grade_completion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_grade_completion` (
  `grade_completion_id` int(11) NOT NULL,
  `enrollment_id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `grade_component` enum('MIDTERM','FINAL','OVERALL_FINAL') NOT NULL,
  `completion_status` enum('PENDING','SUBMITTED','VALIDATED') NOT NULL DEFAULT 'PENDING',
  `validated_by` int(10) unsigned DEFAULT NULL,
  `validated_at` timestamp NULL DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_onecampus_webhook_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_onecampus_webhook_events` (
  `event_id` varchar(128) NOT NULL,
  `event_type` varchar(100) NOT NULL,
  `payload_sha256` char(64) NOT NULL,
  `received_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `processing_status` enum('RECEIVED','PROCESSED','FAILED') NOT NULL DEFAULT 'RECEIVED',
  `processed_at` timestamp NULL DEFAULT NULL,
  `failure_reason` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_schools`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_schools` (
  `school_id` int(11) NOT NULL,
  `school_code` varchar(30) NOT NULL,
  `school_name` varchar(180) NOT NULL,
  `barangay_or_area` varchar(120) DEFAULT NULL,
  `city_municipality` varchar(100) DEFAULT NULL,
  `province` varchar(100) DEFAULT NULL,
  `region` varchar(100) DEFAULT NULL,
  `school_type` enum('PUBLIC','PRIVATE') NOT NULL DEFAULT 'PRIVATE',
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_shs_specializations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_shs_specializations` (
  `specialization_id` int(11) NOT NULL,
  `strand_id` int(11) NOT NULL,
  `specialization_code` varchar(30) NOT NULL,
  `specialization_name` varchar(160) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_shs_strands`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_shs_strands` (
  `strand_id` int(11) NOT NULL,
  `track_id` tinyint(4) NOT NULL,
  `program_id` int(10) unsigned DEFAULT NULL,
  `strand_code` varchar(20) NOT NULL,
  `strand_name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_shs_tracks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_shs_tracks` (
  `track_id` tinyint(4) NOT NULL,
  `track_code` varchar(20) NOT NULL,
  `track_name` varchar(100) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fe_teaching_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fe_teaching_assignments` (
  `assignment_id` int(11) NOT NULL,
  `class_id` bigint(20) unsigned NOT NULL,
  `instructor_id` int(10) unsigned NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fee_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fee_items` (
  `fee_id` int(10) unsigned NOT NULL,
  `fee_code` varchar(30) NOT NULL,
  `fee_name` varchar(150) NOT NULL,
  `fee_basis` enum('Program','Subject') NOT NULL,
  `program_id` int(10) unsigned DEFAULT NULL,
  `subject_id` int(10) unsigned DEFAULT NULL,
  `period_id` int(10) unsigned DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fees` (
  `id` int(11) NOT NULL,
  `name` varchar(80) NOT NULL,
  `kind` enum('fixed','per_unit','per_lab_unit') NOT NULL DEFAULT 'fixed',
  `category` enum('tuition','lab','misc','other') NOT NULL DEFAULT 'misc',
  `amount` decimal(10,2) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `course` varchar(60) DEFAULT NULL,
  `year_level` tinyint(4) DEFAULT NULL,
  `semester` varchar(12) DEFAULT NULL,
  `student_type` varchar(12) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `grades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `grades` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `assessor_id` bigint(20) unsigned NOT NULL,
  `course_name` varchar(180) NOT NULL,
  `grade` decimal(5,2) NOT NULL,
  `status` enum('draft','published') NOT NULL DEFAULT 'draft',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `guidance_appointments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guidance_appointments` (
  `id` int(11) NOT NULL,
  `student_id` int(10) unsigned NOT NULL,
  `staff_id` int(11) NOT NULL,
  `availability_id` int(11) NOT NULL,
  `appointment_date` date NOT NULL,
  `appointment_time` time NOT NULL,
  `concern_category` varchar(100) NOT NULL,
  `appointment_type` varchar(50) NOT NULL,
  `reason` varchar(500) DEFAULT NULL,
  `status` enum('pending','confirmed','rescheduled','completed','cancelled') NOT NULL DEFAULT 'pending',
  `remarks` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `guidance_counselor_availability`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guidance_counselor_availability` (
  `id` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `available_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `status` enum('available','unavailable') NOT NULL DEFAULT 'available',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `guidance_follow_ups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guidance_follow_ups` (
  `id` int(11) NOT NULL,
  `record_id` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `follow_up_date` date NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'pending',
  `remarks` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `guidance_integration_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guidance_integration_settings` (
  `id` int(11) NOT NULL,
  `integration_name` varchar(80) NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 0,
  `status` varchar(30) NOT NULL DEFAULT 'not_configured',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `guidance_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guidance_records` (
  `id` int(11) NOT NULL,
  `student_id` int(10) unsigned NOT NULL,
  `appointment_id` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `record_date` date NOT NULL,
  `record_category` varchar(50) NOT NULL,
  `confidential_note` text NOT NULL,
  `record_status` varchar(30) NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `guidance_referrals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guidance_referrals` (
  `id` int(11) NOT NULL,
  `student_id` int(10) unsigned NOT NULL,
  `staff_id` int(11) NOT NULL,
  `referral_date` date NOT NULL,
  `referral_type` varchar(100) NOT NULL,
  `referred_to` varchar(100) NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'pending',
  `remarks` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `guidance_staff_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `guidance_staff_profiles` (
  `staff_id` int(11) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `guidance_role` varchar(50) NOT NULL DEFAULT 'Counselor',
  `department` varchar(100) DEFAULT 'Guidance Office',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `idcard_iadfc_auditevents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `idcard_iadfc_auditevents` (
  `EventId` bigint(20) NOT NULL,
  `UserId` int(11) NOT NULL,
  `CardId` int(11) DEFAULT NULL,
  `Action` varchar(160) NOT NULL,
  `PerformedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `idcard_iadfc_idcards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `idcard_iadfc_idcards` (
  `CardId` int(11) NOT NULL,
  `PersonId` int(11) NOT NULL,
  `CardReference` varchar(100) NOT NULL,
  `Status` varchar(30) NOT NULL DEFAULT 'Draft',
  `GeneratedBy` int(10) unsigned NOT NULL,
  `UpdatedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6),
  `IsSample` tinyint(1) NOT NULL DEFAULT 0,
  `ValidUntil` date NOT NULL DEFAULT '2028-10-31',
  `VerifyToken` varchar(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `Snapshot` longtext DEFAULT NULL,
  `ValidFrom` date DEFAULT NULL,
  `DateIssued` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `idcard_iadfc_idreleases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `idcard_iadfc_idreleases` (
  `ReleaseId` int(11) NOT NULL,
  `CardId` int(11) NOT NULL,
  `ReleasedBy` int(10) unsigned NOT NULL,
  `RecipientName` varchar(160) NOT NULL,
  `VerificationMethod` varchar(100) NOT NULL,
  `ReleasedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6),
  `Acknowledgment` longtext NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `idcard_iadfc_printrecords`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `idcard_iadfc_printrecords` (
  `PrintId` int(11) NOT NULL,
  `CardId` int(11) NOT NULL,
  `PrintedBy` int(10) unsigned NOT NULL,
  `PrintedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `idcard_iadfc_schoolsettings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `idcard_iadfc_schoolsettings` (
  `SettingId` int(11) NOT NULL,
  `SchoolName` varchar(200) NOT NULL,
  `Address` varchar(300) NOT NULL,
  `Motto` varchar(300) NOT NULL,
  `PublicBaseUrl` varchar(300) NOT NULL DEFAULT '',
  `PresidentName` varchar(160) NOT NULL DEFAULT '',
  `PresidentSignature` longtext NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `idcard_iadfc_staffusers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `idcard_iadfc_staffusers` (
  `UserId` int(11) NOT NULL,
  `OneCampusUserId` int(10) unsigned DEFAULT NULL,
  `Username` varchar(40) NOT NULL,
  `DisplayName` varchar(80) NOT NULL,
  `Role` varchar(30) NOT NULL DEFAULT 'ID Staff',
  `PasswordHash` varchar(500) NOT NULL,
  `IsActive` tinyint(1) NOT NULL DEFAULT 1,
  `FailedAttempts` int(11) NOT NULL DEFAULT 0,
  `LockedUntil` datetime(6) DEFAULT NULL,
  `LastLogin` datetime(6) DEFAULT NULL,
  `CreatedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `idcard_persons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `idcard_persons` (
  `PersonId` int(11) NOT NULL,
  `SchoolNumber` varchar(60) NOT NULL,
  `FullName` varchar(160) NOT NULL,
  `Course` varchar(160) NOT NULL,
  `PersonType` varchar(20) NOT NULL,
  `YearLevel` varchar(40) NOT NULL DEFAULT '',
  `EmergencyName` varchar(160) NOT NULL DEFAULT '',
  `EmergencyPhone` varchar(40) NOT NULL DEFAULT '',
  `Relationship` varchar(60) NOT NULL DEFAULT '',
  `Photo` longtext NOT NULL DEFAULT '',
  `Signature` longtext NOT NULL DEFAULT '',
  `Archived` tinyint(1) NOT NULL DEFAULT 0,
  `ContactNumber` varchar(40) NOT NULL DEFAULT '',
  `Affiliation` varchar(160) NOT NULL DEFAULT '',
  `Purpose` varchar(300) NOT NULL DEFAULT '',
  `RecordVerified` tinyint(1) NOT NULL DEFAULT 0,
  `BirthDate` date DEFAULT NULL,
  `Address` varchar(300) NOT NULL DEFAULT '',
  `EmergencyAddress` varchar(300) NOT NULL DEFAULT '',
  `student_id` int(10) unsigned DEFAULT NULL,
  `user_id` int(10) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `instructors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `instructors` (
  `instructor_id` int(10) unsigned NOT NULL,
  `instructor_uid` varchar(40) DEFAULT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `employee_number` varchar(50) DEFAULT NULL,
  `department_id` int(10) unsigned DEFAULT NULL,
  `designation` varchar(120) DEFAULT NULL,
  `academic_rank` varchar(100) DEFAULT NULL,
  `specialization` varchar(255) DEFAULT NULL,
  `employment_type` varchar(80) DEFAULT NULL,
  `date_hired` date DEFAULT NULL,
  `office` varchar(120) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_announcements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_announcements` (
  `id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `body` text NOT NULL,
  `active` int(11) NOT NULL DEFAULT 1,
  `created_by` int(11) DEFAULT NULL,
  `created_at` varchar(19) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_audit_log` (
  `id` int(11) NOT NULL,
  `actor_type` varchar(12) NOT NULL,
  `actor_id` int(11) DEFAULT NULL,
  `actor_name` varchar(120) DEFAULT NULL,
  `action` varchar(40) NOT NULL,
  `detail` varchar(255) DEFAULT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `created_at` varchar(19) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_extra_enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_extra_enrollments` (
  `id` int(11) NOT NULL,
  `student_id` int(10) unsigned NOT NULL,
  `offering_id` int(11) NOT NULL,
  `created_at` varchar(19) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_grades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_grades` (
  `id` int(11) NOT NULL,
  `student_id` int(10) unsigned NOT NULL COMMENT 'students.student_id',
  `offering_id` int(11) NOT NULL COMMENT 'kiosk_offerings.id',
  `grade` decimal(3,2) DEFAULT NULL,
  `mark` varchar(5) DEFAULT NULL,
  `uploaded_at` varchar(19) NOT NULL,
  `uploaded_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Uploaded grades';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_login_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_login_attempts` (
  `id` int(11) NOT NULL,
  `identifier` varchar(120) NOT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `attempted_at` varchar(19) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_offerings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_offerings` (
  `id` int(11) NOT NULL,
  `term_id` int(10) unsigned NOT NULL COMMENT 'academic_periods.period_id',
  `subject_id` int(10) unsigned NOT NULL COMMENT 'subjects.subject_id',
  `block_id` int(10) unsigned DEFAULT NULL COMMENT 'blocks.block_id (NULL = no block)',
  `section` varchar(60) NOT NULL DEFAULT 'No block' COMMENT 'blocks.block_code',
  `instructor_id` int(11) DEFAULT NULL COMMENT 'kiosk_users.id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Grade kiosk classes built from enrollments';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_outbox`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_outbox` (
  `id` int(11) NOT NULL,
  `to_email` varchar(120) NOT NULL,
  `subject` varchar(200) NOT NULL,
  `body` text NOT NULL,
  `status` varchar(12) NOT NULL,
  `created_at` varchar(19) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_payments` (
  `id` int(11) NOT NULL,
  `student_id` int(10) unsigned NOT NULL COMMENT 'students.student_id',
  `term_id` int(10) unsigned NOT NULL COMMENT 'academic_periods.period_id',
  `amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `or_number` varchar(40) DEFAULT NULL,
  `cashier_id` int(11) DEFAULT NULL,
  `paid_at` varchar(19) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Semester paid at the cashier: unlocks grades at the kiosk';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_settings` (
  `k` varchar(50) NOT NULL,
  `v` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_subjects` (
  `id` int(10) unsigned DEFAULT NULL,
  `code` varchar(20) DEFAULT NULL,
  `title` varchar(150) DEFAULT NULL,
  `units` decimal(4,1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_submission_rows`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_submission_rows` (
  `id` int(11) NOT NULL,
  `submission_id` int(11) NOT NULL,
  `line_no` int(11) NOT NULL,
  `student_no_raw` varchar(30) DEFAULT NULL,
  `name_raw` varchar(160) NOT NULL,
  `grade_raw` varchar(10) NOT NULL,
  `matched_student_id` int(10) unsigned DEFAULT NULL,
  `match_status` varchar(12) NOT NULL DEFAULT 'unmatched',
  `match_note` varchar(160) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_submissions` (
  `id` int(11) NOT NULL,
  `offering_id` int(11) NOT NULL,
  `instructor_id` int(11) DEFAULT NULL,
  `status` varchar(12) NOT NULL DEFAULT 'draft',
  `note` varchar(255) DEFAULT NULL,
  `updated_at` varchar(19) NOT NULL,
  `submitted_at` varchar(19) DEFAULT NULL,
  `uploaded_at` varchar(19) DEFAULT NULL,
  `uploaded_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Instructor grade sheets';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_terms` (
  `id` int(10) unsigned DEFAULT NULL,
  `school_year` varchar(20) DEFAULT NULL,
  `semester` varchar(12) DEFAULT NULL,
  `is_current` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `kiosk_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kiosk_users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(120) NOT NULL,
  `email` varchar(120) DEFAULT NULL,
  `role` varchar(20) NOT NULL,
  `active` int(11) NOT NULL DEFAULT 1,
  `created_at` varchar(19) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Grade kiosk staff: admin, cashier, evaluator, instructor';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_assignments` (
  `id` char(36) NOT NULL,
  `class_id` varchar(40) NOT NULL,
  `title` varchar(255) NOT NULL,
  `instructions` text NOT NULL,
  `due_at` datetime DEFAULT NULL,
  `points` decimal(10,2) NOT NULL DEFAULT 100.00,
  `status` enum('draft','published','closed') NOT NULL DEFAULT 'draft',
  `created_by` varchar(40) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_discussion_posts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_discussion_posts` (
  `id` char(36) NOT NULL,
  `topic_id` char(36) NOT NULL,
  `author_id` varchar(40) NOT NULL,
  `body` text NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_discussion_topics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_discussion_topics` (
  `id` char(36) NOT NULL,
  `class_id` varchar(40) NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `created_by` varchar(40) NOT NULL,
  `is_locked` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_materials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_materials` (
  `id` char(36) NOT NULL,
  `class_id` varchar(40) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `file_path` varchar(500) DEFAULT NULL,
  `external_url` varchar(1000) DEFAULT NULL,
  `created_by` varchar(40) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_quiz_answer_keys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_quiz_answer_keys` (
  `question_id` char(36) NOT NULL,
  `correct_answer` text NOT NULL,
  `case_sensitive` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_quiz_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_quiz_attempts` (
  `id` char(36) NOT NULL,
  `quiz_id` char(36) NOT NULL,
  `student_id` varchar(40) NOT NULL,
  `answers` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`answers`)),
  `score` decimal(10,2) DEFAULT NULL,
  `max_score` decimal(10,2) DEFAULT NULL,
  `status` enum('in_progress','submitted') NOT NULL DEFAULT 'submitted',
  `started_at` datetime NOT NULL DEFAULT current_timestamp(),
  `submitted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_quiz_questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_quiz_questions` (
  `id` char(36) NOT NULL,
  `quiz_id` char(36) NOT NULL,
  `prompt` text NOT NULL,
  `question_type` enum('multiple_choice','true_false','short_answer') NOT NULL,
  `options` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`options`)),
  `points` decimal(10,2) NOT NULL DEFAULT 1.00,
  `position` int(11) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_quizzes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_quizzes` (
  `id` char(36) NOT NULL,
  `class_id` varchar(40) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `opens_at` datetime DEFAULT NULL,
  `closes_at` datetime DEFAULT NULL,
  `time_limit_minutes` int(11) DEFAULT NULL,
  `status` enum('draft','published','closed') NOT NULL DEFAULT 'draft',
  `created_by` varchar(40) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_registration_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_registration_applications` (
  `id` char(36) NOT NULL,
  `auth_user_id` varchar(40) NOT NULL,
  `email` varchar(190) NOT NULL,
  `first_name` varchar(80) NOT NULL,
  `middle_name` varchar(80) DEFAULT NULL,
  `last_name` varchar(80) NOT NULL,
  `suffix` varchar(20) DEFAULT NULL,
  `student_id_number` varchar(30) DEFAULT NULL,
  `class_code` varchar(4) DEFAULT NULL,
  `program` varchar(30) DEFAULT NULL,
  `year_level` tinyint(3) unsigned DEFAULT NULL,
  `block` varchar(20) DEFAULT NULL,
  `academic_year` varchar(20) DEFAULT NULL,
  `semester` varchar(40) DEFAULT NULL,
  `terms_accepted_at` datetime DEFAULT NULL,
  `requested_role` enum('student','instructor','admin') NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `reviewed_by` varchar(40) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_registration_class_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_registration_class_links` (
  `application_id` char(36) NOT NULL,
  `class_id` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_submissions` (
  `id` char(36) NOT NULL,
  `assignment_id` char(36) NOT NULL,
  `student_id` varchar(40) NOT NULL,
  `content` text DEFAULT NULL,
  `file_path` varchar(500) DEFAULT NULL,
  `status` enum('draft','submitted','graded') NOT NULL DEFAULT 'submitted',
  `submitted_at` datetime NOT NULL DEFAULT current_timestamp(),
  `grade` decimal(10,2) DEFAULT NULL,
  `feedback` text DEFAULT NULL,
  `graded_by` varchar(40) DEFAULT NULL,
  `graded_at` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lms_sync_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lms_sync_logs` (
  `id` char(36) NOT NULL,
  `initiated_by` varchar(40) DEFAULT NULL,
  `status` enum('running','success','failed') NOT NULL,
  `records` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`records`)),
  `message` text DEFAULT NULL,
  `started_at` datetime NOT NULL DEFAULT current_timestamp(),
  `completed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `login_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `login_attempts` (
  `id` bigint(20) unsigned NOT NULL,
  `login_key` char(64) NOT NULL,
  `attempted_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maint_assets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `maint_assets` (
  `asset_id` int(10) unsigned NOT NULL,
  `location_id` int(10) unsigned NOT NULL,
  `asset_name` varchar(150) NOT NULL,
  `asset_type` varchar(20) NOT NULL,
  `asset_tag` varchar(50) DEFAULT NULL,
  `serial_number` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maint_attachments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `maint_attachments` (
  `attachment_id` int(10) unsigned NOT NULL,
  `request_id` int(10) unsigned DEFAULT NULL,
  `update_id` int(10) unsigned DEFAULT NULL,
  `finding_id` int(10) unsigned DEFAULT NULL,
  `uploaded_by_employee_id` varchar(64) NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `uploaded_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maint_employees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `maint_employees` (
  `employee_id` varchar(64) NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `full_name` varchar(150) DEFAULT NULL COMMENT 'Fallback for personnel without a central user account',
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maint_inspection_findings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `maint_inspection_findings` (
  `finding_id` int(10) unsigned NOT NULL,
  `inspection_id` int(10) unsigned NOT NULL,
  `asset_id` int(10) unsigned NOT NULL,
  `condition_result` varchar(20) NOT NULL DEFAULT 'Not Inspected',
  `findings` text DEFAULT NULL,
  `request_id` int(10) unsigned DEFAULT NULL,
  `inspected_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maint_inspections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `maint_inspections` (
  `inspection_id` int(10) unsigned NOT NULL,
  `inspection_title` varchar(150) NOT NULL,
  `inspection_date` date NOT NULL,
  `personnel_employee_id` varchar(64) NOT NULL,
  `created_by_employee_id` varchar(64) NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'Scheduled',
  `reviewed_by_employee_id` varchar(64) DEFAULT NULL,
  `review_remarks` text DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maint_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `maint_locations` (
  `location_id` int(10) unsigned NOT NULL,
  `building_name` varchar(100) NOT NULL,
  `floor_name` varchar(50) DEFAULT NULL,
  `room_or_area` varchar(100) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maint_maintenance_administrators`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `maint_maintenance_administrators` (
  `employee_id` varchar(64) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `granted_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maint_maintenance_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `maint_maintenance_requests` (
  `request_id` int(10) unsigned NOT NULL,
  `asset_id` int(10) unsigned DEFAULT NULL,
  `reported_location_id` int(10) unsigned NOT NULL,
  `unlisted_item_name` varchar(150) DEFAULT NULL,
  `reported_by_employee_id` varchar(64) NOT NULL,
  `problem_description` text NOT NULL,
  `priority` varchar(10) NOT NULL DEFAULT 'Normal',
  `status` varchar(30) NOT NULL DEFAULT 'Submitted',
  `reported_at` datetime NOT NULL,
  `verified_by_employee_id` varchar(64) DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `assigned_to_employee_id` varchar(64) DEFAULT NULL,
  `assigned_by_employee_id` varchar(64) DEFAULT NULL,
  `assigned_at` datetime DEFAULT NULL,
  `due_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maint_repair_updates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `maint_repair_updates` (
  `update_id` int(10) unsigned NOT NULL,
  `request_id` int(10) unsigned NOT NULL,
  `updated_by_employee_id` varchar(64) NOT NULL,
  `update_type` varchar(30) NOT NULL,
  `remarks` text NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `maint_request_comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `maint_request_comments` (
  `comment_id` int(10) unsigned NOT NULL,
  `request_id` int(10) unsigned NOT NULL,
  `employee_id` varchar(64) NOT NULL,
  `comment_text` text NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `messages` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `sender_id` bigint(20) unsigned NOT NULL,
  `channel` enum('coordinator','assessor') NOT NULL DEFAULT 'coordinator',
  `subject` varchar(180) NOT NULL DEFAULT 'ETEEAP Message',
  `body` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notifications` (
  `notification_id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `module_code` varchar(40) NOT NULL,
  `title` varchar(200) NOT NULL,
  `message` text NOT NULL,
  `link_url` varchar(255) DEFAULT NULL,
  `reference_type` varchar(60) DEFAULT NULL,
  `reference_id` bigint(20) unsigned DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_companies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_companies` (
  `company_id` int(10) unsigned NOT NULL,
  `company_name` varchar(150) NOT NULL,
  `address` text NOT NULL,
  `contact_person` varchar(100) DEFAULT NULL,
  `contact_number` varchar(15) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `industry` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_daily_time_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_daily_time_records` (
  `dtr_id` int(10) unsigned NOT NULL,
  `assignment_id` int(10) unsigned NOT NULL,
  `date` date NOT NULL,
  `time_in` time NOT NULL,
  `time_out` time NOT NULL,
  `total_hours` decimal(5,2) NOT NULL,
  `remarks` text DEFAULT NULL,
  `status` enum('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending',
  `verified_by` int(10) unsigned DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `verification_remarks` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_documents` (
  `document_id` int(10) unsigned NOT NULL,
  `assignment_id` int(10) unsigned NOT NULL,
  `document_type` varchar(100) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `uploaded_by` int(10) unsigned NOT NULL,
  `status` enum('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `remarks` text DEFAULT NULL,
  `uploaded_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_dtr_breaks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_dtr_breaks` (
  `dtr_id` int(10) unsigned NOT NULL,
  `break_minutes` smallint(5) unsigned NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_evaluation_criteria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_evaluation_criteria` (
  `criterion_id` int(10) unsigned NOT NULL,
  `name` varchar(120) NOT NULL,
  `weight` decimal(6,2) NOT NULL DEFAULT 1.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_evaluation_drafts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_evaluation_drafts` (
  `assignment_id` int(10) unsigned NOT NULL,
  `supervisor_id` int(10) unsigned NOT NULL,
  `scores_json` text NOT NULL,
  `remarks` text DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_evaluation_scores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_evaluation_scores` (
  `score_id` int(10) unsigned NOT NULL,
  `evaluation_id` int(10) unsigned NOT NULL,
  `criterion_id` int(10) unsigned NOT NULL,
  `score` decimal(4,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_evaluations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_evaluations` (
  `evaluation_id` int(10) unsigned NOT NULL,
  `assignment_id` int(10) unsigned NOT NULL,
  `supervisor_id` int(10) unsigned NOT NULL,
  `evaluation_date` date NOT NULL,
  `total_score` decimal(5,2) NOT NULL,
  `remarks` text DEFAULT NULL,
  `status` enum('Submitted','Reviewed','Approved') NOT NULL DEFAULT 'Submitted',
  `reviewed_by` int(10) unsigned DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_internship_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_internship_assignments` (
  `assignment_id` int(10) unsigned NOT NULL,
  `student_id` int(10) unsigned NOT NULL,
  `company_id` int(10) unsigned NOT NULL,
  `supervisor_id` int(10) unsigned NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `required_hours` int(11) NOT NULL,
  `schedule_details` varchar(255) DEFAULT NULL,
  `status` enum('Ongoing','Completed','Terminated','Pending') NOT NULL DEFAULT 'Pending',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_password_reset_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_password_reset_requests` (
  `request_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `status` enum('Pending','Resolved') NOT NULL DEFAULT 'Pending',
  `requested_at` datetime NOT NULL DEFAULT current_timestamp(),
  `resolved_at` datetime DEFAULT NULL,
  `resolved_by` int(10) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_progress_attachments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_progress_attachments` (
  `progress_id` int(10) unsigned NOT NULL,
  `document_id` int(10) unsigned NOT NULL,
  `title` varchar(150) NOT NULL,
  `note` text DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_progress_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_progress_reports` (
  `progress_id` int(10) unsigned NOT NULL,
  `assignment_id` int(10) unsigned NOT NULL,
  `week_start` date NOT NULL,
  `week_end` date NOT NULL,
  `accomplishments` text NOT NULL,
  `challenges` text DEFAULT NULL,
  `next_plan` text DEFAULT NULL,
  `status` enum('Pending','Reviewed','Revision Required') NOT NULL DEFAULT 'Pending',
  `feedback` text DEFAULT NULL,
  `reviewed_by` int(10) unsigned DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_required_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_required_documents` (
  `requirement_id` int(10) unsigned NOT NULL,
  `name` varchar(100) NOT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ojt_supervisors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ojt_supervisors` (
  `supervisor_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `company_id` int(10) unsigned NOT NULL,
  `position` varchar(100) NOT NULL,
  `contact_number` varchar(15) NOT NULL,
  `is_verified` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `online_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `online_payments` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `session_id` varchar(80) NOT NULL,
  `reference` varchar(40) NOT NULL,
  `checkout_url` varchar(500) NOT NULL,
  `status` enum('pending','paid','expired','failed') NOT NULL DEFAULT 'pending',
  `channel` varchar(30) DEFAULT NULL,
  `provider_payment_id` varchar(60) DEFAULT NULL,
  `payment_id` int(11) DEFAULT NULL,
  `note` varchar(200) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `paid_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `payment_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `payment_requests` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `method` varchar(30) NOT NULL,
  `reference` varchar(60) NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `note` varchar(200) DEFAULT NULL,
  `payment_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `reviewed_by` int(11) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `uid` char(36) DEFAULT NULL,
  `student_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `or_no` varchar(30) DEFAULT NULL,
  `source` enum('online','offline') DEFAULT 'online',
  `paid_at` datetime DEFAULT current_timestamp(),
  `method` varchar(12) DEFAULT NULL,
  `ref_no` varchar(40) DEFAULT NULL,
  `remarks` varchar(150) DEFAULT NULL,
  `received_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `portfolio_assessments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `portfolio_assessments` (
  `assessment_id` int(11) NOT NULL,
  `applicant_id` int(11) NOT NULL,
  `assessor_id` int(11) NOT NULL,
  `assessment_date` date NOT NULL,
  `score_profile` decimal(5,2) DEFAULT 0.00,
  `score_education` decimal(5,2) DEFAULT 0.00,
  `score_technical` decimal(5,2) DEFAULT 0.00,
  `score_experience` decimal(5,2) DEFAULT 0.00,
  `score_projects` decimal(5,2) DEFAULT 0.00,
  `score_reflection` decimal(5,2) DEFAULT 0.00,
  `total_score` decimal(5,2) DEFAULT 0.00,
  `interpretation` varchar(50) DEFAULT NULL,
  `recommendation_tier` varchar(100) DEFAULT NULL,
  `panel_recommendation` enum('Approved for Full Credit','Approved with Conditions','Partial Credit Only','Not Qualified under ETEEAP') NOT NULL,
  `remarks` text DEFAULT NULL,
  `status` enum('Draft','Submitted by Assessor','Approved by Coordinator','Finalized') DEFAULT 'Submitted by Assessor',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `portfolio_rubric_forms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `portfolio_rubric_forms` (
  `id` int(10) unsigned NOT NULL,
  `application_id` int(10) unsigned NOT NULL,
  `assessor_id` int(10) unsigned NOT NULL,
  `assessment_date` date DEFAULT NULL,
  `panel_name` varchar(250) NOT NULL DEFAULT '',
  `ratings_json` text NOT NULL,
  `recommendation` varchar(80) NOT NULL DEFAULT '',
  `remarks` text NOT NULL,
  `total_score` decimal(6,3) DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pre_enrollment_subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pre_enrollment_subjects` (
  `pre_enrollment_subject_id` int(10) unsigned NOT NULL,
  `pre_enrollment_id` int(10) unsigned NOT NULL,
  `subject_id` int(10) unsigned NOT NULL,
  `subject_status` varchar(32) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pre_enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pre_enrollments` (
  `pre_enrollment_id` int(10) unsigned NOT NULL,
  `reference_no` varchar(35) NOT NULL,
  `student_id` int(10) unsigned NOT NULL,
  `program_id` int(10) unsigned NOT NULL,
  `period_id` int(10) unsigned NOT NULL,
  `year_level` tinyint(3) unsigned NOT NULL,
  `application_status` varchar(40) NOT NULL DEFAULT 'Submitted',
  `is_eligible` tinyint(1) NOT NULL DEFAULT 0,
  `review_status` enum('Pending','Cleared','On Hold','Rejected') NOT NULL DEFAULT 'Pending',
  `reviewed_by` int(10) unsigned DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `review_remarks` varchar(255) DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `program_offerings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `program_offerings` (
  `id` bigint(20) unsigned NOT NULL,
  `code` varchar(30) NOT NULL,
  `degree_name` varchar(180) NOT NULL,
  `authorization_reference` varchar(180) NOT NULL,
  `valid_from` date NOT NULL,
  `valid_until` date NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `configured_by` bigint(20) unsigned NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `programs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `programs` (
  `program_id` int(10) unsigned NOT NULL,
  `program_code` varchar(20) NOT NULL,
  `program_name` varchar(150) NOT NULL,
  `department_id` int(10) unsigned DEFAULT NULL,
  `authority_to_operate` varchar(150) DEFAULT NULL,
  `authority_reference` varchar(120) DEFAULT NULL,
  `date_approved` date DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `program_uid` varchar(40) DEFAULT NULL,
  `education_level` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `readmit_application_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `readmit_application_history` (
  `id` varchar(40) NOT NULL,
  `seq` bigint(20) NOT NULL,
  `application_id` varchar(40) NOT NULL,
  `action` varchar(100) NOT NULL,
  `actor` varchar(120) NOT NULL,
  `actor_role` varchar(40) NOT NULL,
  `note` varchar(2000) NOT NULL DEFAULT '',
  `created_at` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `readmit_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `readmit_applications` (
  `id` varchar(40) NOT NULL,
  `seq` bigint(20) NOT NULL,
  `reference_no` varchar(30) NOT NULL,
  `applicant_id` varchar(40) NOT NULL,
  `program_id` int(10) unsigned DEFAULT NULL,
  `student_number` varchar(40) NOT NULL DEFAULT '',
  `department` varchar(150) NOT NULL DEFAULT '',
  `previous_year_level` varchar(40) NOT NULL DEFAULT '',
  `last_term` varchar(20) NOT NULL DEFAULT '',
  `last_academic_year` varchar(20) NOT NULL DEFAULT '',
  `reason_leaving` varchar(2000) NOT NULL DEFAULT '',
  `reason_returning` varchar(2000) NOT NULL DEFAULT '',
  `intended_term` varchar(20) NOT NULL DEFAULT '',
  `intended_academic_year` varchar(20) NOT NULL DEFAULT '',
  `status` enum('Draft','Submitted','Incomplete','Under Review','Approved','Denied','Withdrawn') NOT NULL DEFAULT 'Draft',
  `assigned_evaluator_id` varchar(40) DEFAULT NULL,
  `requirements_status` varchar(60) NOT NULL DEFAULT 'Not submitted',
  `eligibility_assessment` varchar(100) NOT NULL DEFAULT '',
  `evaluator_remarks` varchar(2000) NOT NULL DEFAULT '',
  `conditions` varchar(2000) NOT NULL DEFAULT '',
  `submitted_at` varchar(30) DEFAULT NULL,
  `created_at` varchar(30) NOT NULL,
  `updated_at` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `readmit_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `readmit_documents` (
  `id` varchar(40) NOT NULL,
  `seq` bigint(20) NOT NULL,
  `application_id` varchar(40) NOT NULL,
  `requirement_id` int(11) DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT 0,
  `file_name` varchar(200) NOT NULL DEFAULT '',
  `file_size` int(11) NOT NULL DEFAULT 0,
  `file_type` varchar(60) NOT NULL DEFAULT '',
  `stored_name` varchar(80) DEFAULT NULL,
  `status` enum('Missing','Uploaded','Verified','Correction Required') NOT NULL DEFAULT 'Missing',
  `note` varchar(255) NOT NULL DEFAULT '',
  `uploaded_at` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `readmit_requirements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `readmit_requirements` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT 0,
  `active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `report_exports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `report_exports` (
  `report_id` bigint(20) unsigned NOT NULL,
  `generated_by` int(10) unsigned DEFAULT NULL,
  `report_name` varchar(150) NOT NULL,
  `report_format` enum('PDF','Excel','CSV') NOT NULL,
  `filters_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`filters_json`)),
  `record_count` int(10) unsigned NOT NULL DEFAULT 0,
  `file_path` varchar(255) DEFAULT NULL,
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sch_class_meetings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sch_class_meetings` (
  `meeting_id` bigint(20) unsigned NOT NULL,
  `class_id` bigint(20) unsigned NOT NULL,
  `room_id` int(10) unsigned NOT NULL,
  `class_type` enum('LEC','LAB') NOT NULL DEFAULT 'LEC',
  `day_of_week` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday') NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `status` enum('Draft','Published','Conflict','Cancelled') NOT NULL DEFAULT 'Draft',
  `created_by` int(10) unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sch_instructor_load_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sch_instructor_load_settings` (
  `instructor_id` int(10) unsigned NOT NULL,
  `max_units` tinyint(3) unsigned NOT NULL DEFAULT 21,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sch_rooms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sch_rooms` (
  `room_id` int(10) unsigned NOT NULL,
  `room_code` varchar(30) NOT NULL,
  `maintenance_location_id` int(10) unsigned DEFAULT NULL,
  `building_description` varchar(80) DEFAULT NULL COMMENT 'Used if no maintenance location record is linked',
  `building` varchar(80) NOT NULL DEFAULT 'Academic Building',
  `room_type` enum('Lecture','Laboratory','AVR','Open Area') NOT NULL DEFAULT 'Lecture',
  `capacity` smallint(5) unsigned NOT NULL DEFAULT 40,
  `max_concurrent_sections` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `weekly_hours_used` decimal(4,1) NOT NULL DEFAULT 0.0,
  `occupancy_status` enum('Available','Occupied','Maintenance') NOT NULL DEFAULT 'Available',
  `operational_status` enum('Active','Maintenance','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sch_sync_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sch_sync_queue` (
  `queue_id` bigint(20) unsigned NOT NULL,
  `operation_type` enum('INSERT','UPDATE','DELETE') NOT NULL DEFAULT 'INSERT',
  `target_table` varchar(60) NOT NULL DEFAULT 'sch_class_meetings',
  `payload_json` mediumtext NOT NULL,
  `queued_by_user_id` int(10) unsigned DEFAULT NULL,
  `is_synced` tinyint(1) NOT NULL DEFAULT 0,
  `queued_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `synced_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_migrations` (
  `migration_id` bigint(20) unsigned NOT NULL,
  `module_code` varchar(40) NOT NULL,
  `migration_name` varchar(200) NOT NULL,
  `batch` int(11) NOT NULL DEFAULT 1,
  `applied_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_application_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_application_documents` (
  `id` bigint(20) unsigned NOT NULL,
  `scholarship_application_id` bigint(20) unsigned NOT NULL,
  `scholarship_requirement_id` bigint(20) unsigned DEFAULT NULL,
  `document_name` varchar(200) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_type` varchar(20) DEFAULT NULL,
  `file_size` bigint(20) unsigned NOT NULL DEFAULT 0,
  `verification_status` varchar(30) NOT NULL DEFAULT 'pending',
  `verification_notes` text DEFAULT NULL,
  `verified_by` int(10) unsigned DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `storage_disk` varchar(20) NOT NULL DEFAULT 'local',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `document_category` varchar(40) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_application_evaluations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_application_evaluations` (
  `id` bigint(20) unsigned NOT NULL,
  `scholarship_application_id` bigint(20) unsigned NOT NULL,
  `evaluator_id` int(10) unsigned NOT NULL,
  `score` tinyint(3) unsigned DEFAULT NULL,
  `recommendation` varchar(40) NOT NULL DEFAULT 'pending',
  `evaluation_notes` text DEFAULT NULL,
  `evaluated_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_application_status_histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_application_status_histories` (
  `id` bigint(20) unsigned NOT NULL,
  `scholarship_application_id` bigint(20) unsigned NOT NULL,
  `from_status` varchar(40) DEFAULT NULL,
  `to_status` varchar(40) NOT NULL,
  `changed_by` int(10) unsigned DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_cache` (
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_cache_locks` (
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_document_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_document_reviews` (
  `id` bigint(20) unsigned NOT NULL,
  `application_document_id` bigint(20) unsigned NOT NULL,
  `reviewed_by` int(10) unsigned NOT NULL,
  `status` varchar(30) NOT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_eligibility_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_eligibility_results` (
  `id` bigint(20) unsigned NOT NULL,
  `scholarship_application_id` bigint(20) unsigned NOT NULL,
  `checked_by` int(10) unsigned DEFAULT NULL,
  `result` varchar(30) NOT NULL DEFAULT 'manual_review',
  `reasons` text DEFAULT NULL,
  `checked_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_eligibility_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_eligibility_rules` (
  `id` bigint(20) unsigned NOT NULL,
  `scholarship_program_id` bigint(20) unsigned NOT NULL,
  `rule_key` varchar(60) NOT NULL,
  `rule_label` varchar(200) NOT NULL,
  `rule_type` varchar(30) NOT NULL DEFAULT 'text',
  `operator` varchar(20) NOT NULL DEFAULT '=',
  `rule_value` text NOT NULL,
  `failure_mode` varchar(20) NOT NULL DEFAULT 'manual_review',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_failed_jobs` (
  `id` bigint(20) unsigned NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_household_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_household_profiles` (
  `student_id` int(10) unsigned NOT NULL,
  `household_size` smallint(5) unsigned DEFAULT NULL,
  `monthly_household_income` decimal(12,2) DEFAULT NULL,
  `last_verified_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_jobs` (
  `id` bigint(20) unsigned NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) unsigned NOT NULL,
  `reserved_at` int(10) unsigned DEFAULT NULL,
  `available_at` int(10) unsigned NOT NULL,
  `created_at` int(10) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_personal_access_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_personal_access_tokens` (
  `id` bigint(20) unsigned NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) unsigned NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_renewal_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_renewal_applications` (
  `id` bigint(20) unsigned NOT NULL,
  `renewal_no` varchar(30) NOT NULL,
  `scholarship_award_id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `academic_year` varchar(20) NOT NULL,
  `statement` text DEFAULT NULL,
  `form_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`form_data`)),
  `status` varchar(30) NOT NULL DEFAULT 'draft',
  `remarks` text DEFAULT NULL,
  `decided_by` int(10) unsigned DEFAULT NULL,
  `decided_at` timestamp NULL DEFAULT NULL,
  `submitted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_scholarship_appeals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_scholarship_appeals` (
  `id` bigint(20) unsigned NOT NULL,
  `appeal_no` varchar(40) NOT NULL,
  `scholarship_award_id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `award_status_version` int(10) unsigned NOT NULL,
  `award_status` varchar(30) NOT NULL,
  `status_reason` text DEFAULT NULL,
  `statement` text NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'submitted',
  `pending_slot` tinyint(3) unsigned DEFAULT 1,
  `decision_reason` text DEFAULT NULL,
  `decided_by` int(10) unsigned DEFAULT NULL,
  `decided_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_scholarship_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_scholarship_applications` (
  `id` bigint(20) unsigned NOT NULL,
  `application_no` varchar(30) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `scholarship_program_id` bigint(20) unsigned NOT NULL,
  `assigned_to` int(10) unsigned DEFAULT NULL,
  `academic_year` varchar(20) NOT NULL DEFAULT '2026-2027',
  `status` varchar(40) NOT NULL DEFAULT 'draft',
  `enrollment_status` varchar(30) DEFAULT NULL,
  `statement` text DEFAULT NULL,
  `form_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`form_data`)),
  `guardian_name` varchar(200) DEFAULT NULL,
  `guardian_occupation` varchar(150) DEFAULT NULL,
  `household_size` smallint(5) unsigned DEFAULT NULL,
  `monthly_household_income` decimal(12,2) DEFAULT NULL,
  `submitted_at` timestamp NULL DEFAULT NULL,
  `decided_at` timestamp NULL DEFAULT NULL,
  `decided_by` int(10) unsigned DEFAULT NULL,
  `decision_remarks` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `last_saved_step` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `declaration_accepted_at` timestamp NULL DEFAULT NULL,
  `form_version` varchar(40) DEFAULT NULL,
  `adfc_form` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`adfc_form`)),
  `form_review` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`form_review`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_scholarship_awards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_scholarship_awards` (
  `id` bigint(20) unsigned NOT NULL,
  `award_no` varchar(30) NOT NULL,
  `scholarship_application_id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `scholarship_program_id` bigint(20) unsigned NOT NULL,
  `benefits` text DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `recipient_status` varchar(30) NOT NULL DEFAULT 'active',
  `remarks` text DEFAULT NULL,
  `awarded_by` int(10) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `status_reason` text DEFAULT NULL,
  `status_changed_at` timestamp NULL DEFAULT NULL,
  `status_version` int(10) unsigned NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_scholarship_programs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_scholarship_programs` (
  `id` bigint(20) unsigned NOT NULL,
  `code` varchar(30) NOT NULL COMMENT 'Scholarship ID',
  `name` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `category` varchar(100) NOT NULL DEFAULT 'General',
  `benefits` text DEFAULT NULL,
  `eligibility_criteria` text DEFAULT NULL,
  `application_template` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`application_template`)),
  `renewal_template` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`renewal_template`)),
  `opening_date` date DEFAULT NULL,
  `deadline` date DEFAULT NULL,
  `slots` int(10) unsigned DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'draft',
  `created_by` int(10) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scholar_scholarship_requirements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scholar_scholarship_requirements` (
  `id` bigint(20) unsigned NOT NULL,
  `scholarship_program_id` bigint(20) unsigned NOT NULL,
  `name` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT 1,
  `allowed_types` varchar(100) NOT NULL DEFAULT 'pdf,jpg,jpeg,png',
  `max_size_kb` int(10) unsigned NOT NULL DEFAULT 5120,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `staff_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `staff_profiles` (
  `user_id` int(10) unsigned NOT NULL,
  `admin_number` varchar(40) DEFAULT NULL,
  `admin_level` varchar(50) DEFAULT NULL,
  `job_title` varchar(120) DEFAULT NULL,
  `office` varchar(120) DEFAULT NULL,
  `department_id` int(10) unsigned DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `student_contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `student_contacts` (
  `contact_id` int(10) unsigned NOT NULL,
  `student_id` int(10) unsigned NOT NULL,
  `contact_role` enum('Guardian','Father','Mother','Emergency') NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `relationship` varchar(60) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `occupation` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `student_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `student_documents` (
  `document_id` bigint(20) unsigned NOT NULL,
  `student_id` int(10) unsigned NOT NULL,
  `document_type` varchar(60) NOT NULL,
  `original_filename` varchar(180) NOT NULL,
  `mime_type` enum('application/pdf','image/jpeg','image/png') NOT NULL,
  `file_size` int(10) unsigned NOT NULL,
  `file_blob` mediumblob NOT NULL,
  `uploaded_by` int(10) unsigned DEFAULT NULL,
  `verification_status` enum('Pending','Verified','Needs Resubmission') NOT NULL DEFAULT 'Pending',
  `verified_by` int(10) unsigned DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `verification_remarks` varchar(255) DEFAULT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `student_first_enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `student_first_enrollments` (
  `student_id` int(10) unsigned NOT NULL,
  `first_enrolled_on` date NOT NULL,
  `first_program_id` int(10) unsigned NOT NULL,
  `first_period_id` int(10) unsigned NOT NULL,
  `first_year_level` tinyint(3) unsigned NOT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `recorded_by` int(10) unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `students` (
  `student_id` int(10) unsigned NOT NULL,
  `student_number` varchar(30) DEFAULT NULL,
  `student_type` varchar(25) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `middle_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) NOT NULL,
  `extension_name` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `gender` varchar(10) DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  `contact_number` varchar(20) DEFAULT NULL,
  `home_address` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `student_uid` varchar(40) DEFAULT NULL,
  `lrn` varchar(40) DEFAULT NULL,
  `birth_place` varchar(150) DEFAULT NULL,
  `civil_status` varchar(40) DEFAULT NULL,
  `nationality` varchar(50) DEFAULT NULL,
  `education_level` enum('College','Senior High') DEFAULT NULL,
  `grade_level` varchar(15) DEFAULT NULL,
  `school_id` int(11) DEFAULT NULL,
  `strand_id` int(11) DEFAULT NULL,
  `specialization_id` int(11) DEFAULT NULL,
  `previous_school` varchar(180) DEFAULT NULL,
  `admission_date` date DEFAULT NULL,
  `record_status` enum('Active','Inactive','Graduated','Transferred') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `subjects` (
  `subject_id` int(10) unsigned NOT NULL,
  `program_id` int(10) unsigned DEFAULT NULL,
  `subject_code` varchar(20) NOT NULL,
  `subject_title` varchar(150) NOT NULL,
  `units` decimal(4,1) NOT NULL DEFAULT 0.0,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `subject_uid` varchar(40) DEFAULT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `system_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `system_settings` (
  `setting_id` bigint(20) unsigned NOT NULL,
  `module_code` varchar(40) NOT NULL,
  `setting_key` varchar(150) NOT NULL,
  `setting_value` longtext DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `uploads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `uploads` (
  `id` bigint(20) unsigned NOT NULL,
  `application_id` bigint(20) unsigned NOT NULL,
  `uploaded_by` bigint(20) unsigned NOT NULL,
  `kind` enum('document','portfolio') NOT NULL,
  `requirement_key` varchar(40) DEFAULT NULL,
  `category` enum('employment','training','certification','project','supporting') DEFAULT NULL,
  `title` varchar(180) NOT NULL,
  `description` text DEFAULT NULL,
  `storage_name` varchar(90) NOT NULL,
  `original_name` varchar(255) NOT NULL,
  `mime_type` varchar(80) NOT NULL,
  `size_bytes` bigint(20) unsigned NOT NULL,
  `replaces_upload_id` bigint(20) unsigned DEFAULT NULL,
  `status` enum('pending','verified','revision') NOT NULL DEFAULT 'pending',
  `reviewer_note` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `user_access_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_access_roles` (
  `user_id` int(10) unsigned NOT NULL,
  `role_id` int(10) unsigned NOT NULL,
  `module_code` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `user_mfa_methods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_mfa_methods` (
  `mfa_id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `method` varchar(40) NOT NULL,
  `secret_encrypted` text NOT NULL,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `user_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_profiles` (
  `user_id` int(10) unsigned NOT NULL,
  `avatar_path` varchar(255) DEFAULT NULL,
  `profile_photo` mediumblob DEFAULT NULL,
  `profile_photo_mime` varchar(100) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `user_id` int(10) unsigned NOT NULL,
  `user_uid` varchar(40) DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `email` varchar(190) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(190) NOT NULL,
  `status` enum('Active','Inactive','Pending','Disabled','Suspended') NOT NULL DEFAULT 'Active',
  `student_id` int(10) unsigned DEFAULT NULL,
  `last_login` datetime DEFAULT NULL,
  `email_verified_at` datetime DEFAULT NULL,
  `must_change_password` tinyint(1) NOT NULL DEFAULT 0,
  `session_version` int(10) unsigned NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50001 DROP VIEW IF EXISTS `admin_users`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `admin_users` AS select `u`.`user_id` AS `admin_user_id`,`u`.`username` AS `username`,`u`.`email` AS `email`,`u`.`password_hash` AS `password_hash`,`u`.`full_name` AS `full_name`,case when exists(select 1 from (`user_access_roles` `ur_admin` join `access_roles` `ar_admin` on(`ar_admin`.`role_id` = `ur_admin`.`role_id`)) where `ur_admin`.`user_id` = `u`.`user_id` and lcase(`ur_admin`.`module_code`) in ('enrollment','enrollment_management','enrollment-management') and `ar_admin`.`role_name` = 'Administrator' limit 1) then 'Administrator' else 'Enrollment Personnel' end AS `role`,`u`.`status` AS `status`,`u`.`last_login` AS `last_login`,`u`.`created_at` AS `created_at`,`u`.`updated_at` AS `updated_at` from `users` `u` where exists(select 1 from (`user_access_roles` `ur` join `access_roles` `ar` on(`ar`.`role_id` = `ur`.`role_id`)) where `ur`.`user_id` = `u`.`user_id` and lcase(`ur`.`module_code`) in ('enrollment','enrollment_management','enrollment-management') and `ar`.`role_name` in ('Administrator','Enrollment Personnel') limit 1) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `billing_v_legacy_users`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `billing_v_legacy_users` AS select `u`.`user_id` AS `id`,`u`.`username` AS `username`,case when exists(select 1 from (`user_access_roles` `ur` join `access_roles` `r` on(`r`.`role_id` = `ur`.`role_id`)) where `ur`.`user_id` = `u`.`user_id` and lcase(`ur`.`module_code`) = 'billing' and lcase(`r`.`role_name`) = 'administrator' limit 1) then 'admin' when exists(select 1 from (`user_access_roles` `ur` join `access_roles` `r` on(`r`.`role_id` = `ur`.`role_id`)) where `ur`.`user_id` = `u`.`user_id` and lcase(`ur`.`module_code`) = 'billing' and lcase(`r`.`role_name`) = 'cashier' limit 1) then 'cashier' when exists(select 1 from (`user_access_roles` `ur` join `access_roles` `r` on(`r`.`role_id` = `ur`.`role_id`)) where `ur`.`user_id` = `u`.`user_id` and lcase(`ur`.`module_code`) = 'billing' and lcase(`r`.`role_name`) = 'registrar' limit 1) then 'registrar' when exists(select 1 from (`user_access_roles` `ur` join `access_roles` `r` on(`r`.`role_id` = `ur`.`role_id`)) where `ur`.`user_id` = `u`.`user_id` and lcase(`ur`.`module_code`) = 'billing' and lcase(`r`.`role_name`) = 'student' limit 1) then 'student' else 'other' end AS `role`,`u`.`student_id` AS `student_id`,`u`.`must_change_password` AS `must_change`,`u`.`full_name` AS `full_name`,`u`.`status` AS `status` from `users` `u` where exists(select 1 from `user_access_roles` `ur` where `ur`.`user_id` = `u`.`user_id` and lcase(`ur`.`module_code`) = 'billing' limit 1) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `et_course_sections`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY INVOKER */
/*!50001 VIEW `et_course_sections` AS select min(`b`.`block_id`) AS `id`,`b`.`program_id` AS `course_id`,`b`.`block_code` AS `name` from `blocks` `b` where `b`.`status` = 'Active' group by `b`.`program_id`,`b`.`block_code` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `et_courses`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY INVOKER */
/*!50001 VIEW `et_courses` AS select `p`.`program_id` AS `id`,`p`.`program_code` AS `code`,`p`.`program_name` AS `name` from `programs` `p` where `p`.`status` = 'Active' */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `et_student_profiles`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY INVOKER */
/*!50001 VIEW `et_student_profiles` AS select `u`.`user_id` AS `user_id`,`e`.`program_id` AS `course_id`,`e`.`year_level` AS `year_level`,`b`.`block_code` AS `section`,`st`.`consent_at` AS `consent_at`,`st`.`consent_version` AS `consent_version`,coalesce(`st`.`guardian_consent`,0) AS `guardian_consent`,coalesce(`st`.`face_enrolled`,0) AS `face_enrolled` from (((`users` `u` join `enrollments` `e` on(`e`.`student_id` = `u`.`student_id` and `e`.`enrollment_status` = 'Confirmed' and `e`.`enrollment_id` = (select `e2`.`enrollment_id` from `enrollments` `e2` where `e2`.`student_id` = `u`.`student_id` and `e2`.`enrollment_status` = 'Confirmed' order by `e2`.`period_id` desc,`e2`.`enrollment_id` desc limit 1))) left join `blocks` `b` on(`b`.`block_id` = `e`.`block_id`)) left join `et_user_state` `st` on(`st`.`user_id` = `u`.`user_id`)) where `u`.`student_id` is not null */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `et_users`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY INVOKER */
/*!50001 VIEW `et_users` AS select `x`.`id` AS `id`,`x`.`role` AS `role`,`x`.`login_id` AS `login_id`,`x`.`full_name` AS `full_name`,`x`.`email` AS `email`,`x`.`password_hash` AS `password_hash`,`x`.`status` AS `status`,`x`.`must_change_pw` AS `must_change_pw`,`x`.`rep_enabled` AS `rep_enabled`,`x`.`failed_logins` AS `failed_logins`,`x`.`locked_until` AS `locked_until`,`x`.`last_login_at` AS `last_login_at`,`x`.`created_at` AS `created_at` from (select `u`.`user_id` AS `id`,case when exists(select 1 from (`user_access_roles` `ur` join `access_roles` `ar` on(`ar`.`role_id` = `ur`.`role_id`)) where `ur`.`user_id` = `u`.`user_id` and `ar`.`role_name` = 'EventTrack Administrator' and `ar`.`is_active` = 1 limit 1) then 'admin' when exists(select 1 from (`user_access_roles` `ur` join `access_roles` `ar` on(`ar`.`role_id` = `ur`.`role_id`)) where `ur`.`user_id` = `u`.`user_id` and `ar`.`role_name` = 'EventTrack Representative' and `ar`.`is_active` = 1 limit 1) then 'representative' when `u`.`student_id` is not null then 'student' else NULL end AS `role`,coalesce(nullif(`s`.`student_number`,''),`u`.`username`,`u`.`email`) AS `login_id`,`u`.`full_name` AS `full_name`,`u`.`email` AS `email`,`u`.`password_hash` AS `password_hash`,case when `u`.`status` = 'Pending' then 'invited' when `u`.`status` <> 'Active' or coalesce(`st`.`suspended`,0) = 1 or `s`.`student_id` is not null and `s`.`record_status` <> 'Active' then 'suspended' else 'active' end AS `status`,0 AS `must_change_pw`,coalesce(`st`.`rep_enabled`,0) AS `rep_enabled`,coalesce(`st`.`failed_logins`,0) AS `failed_logins`,`st`.`locked_until` AS `locked_until`,`u`.`last_login` AS `last_login_at`,`u`.`created_at` AS `created_at` from ((`users` `u` left join `students` `s` on(`s`.`student_id` = `u`.`student_id`)) left join `et_user_state` `st` on(`st`.`user_id` = `u`.`user_id`))) `x` where `x`.`role` is not null */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

