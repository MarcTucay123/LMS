-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 12, 2026 at 07:22 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `adfc_onecampus`
--

-- --------------------------------------------------------

--
-- Table structure for table `academic_classes`
--

CREATE TABLE `academic_classes` (
  `class_id` bigint(20) UNSIGNED NOT NULL,
  `class_uid` varchar(40) DEFAULT NULL,
  `program_id` int(10) UNSIGNED DEFAULT NULL,
  `subject_id` int(10) UNSIGNED DEFAULT NULL,
  `period_id` int(10) UNSIGNED DEFAULT NULL,
  `instructor_id` int(10) UNSIGNED DEFAULT NULL,
  `class_code` varchar(60) NOT NULL,
  `section` varchar(60) DEFAULT NULL,
  `year_level` tinyint(3) UNSIGNED DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `academic_periods`
--

CREATE TABLE `academic_periods` (
  `period_id` int(10) UNSIGNED NOT NULL,
  `academic_year` varchar(20) NOT NULL,
  `semester` enum('1st','2nd','Summer') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `starts_on` date DEFAULT NULL,
  `ends_on` date DEFAULT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `access_permissions`
--

CREATE TABLE `access_permissions` (
  `permission_id` int(10) UNSIGNED NOT NULL,
  `permission_code` varchar(120) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `access_roles`
--

CREATE TABLE `access_roles` (
  `role_id` int(10) UNSIGNED NOT NULL,
  `role_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `access_role_permissions`
--

CREATE TABLE `access_role_permissions` (
  `role_id` int(10) UNSIGNED NOT NULL,
  `permission_id` int(10) UNSIGNED NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `module_code` varchar(40) NOT NULL DEFAULT 'enrollment',
  `details_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`details_json`)),
  `old_values_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`old_values_json`)),
  `new_values_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`new_values_json`)),
  `log_id` bigint(20) UNSIGNED NOT NULL,
  `admin_user_id` int(10) UNSIGNED DEFAULT NULL,
  `action` varchar(60) NOT NULL,
  `record_type` varchar(60) DEFAULT NULL,
  `record_id` int(10) UNSIGNED DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `admin_users`
-- (See below for the actual view)
--
CREATE TABLE `admin_users` (
`admin_user_id` int(10) unsigned
,`username` varchar(100)
,`email` varchar(190)
,`password_hash` varchar(255)
,`full_name` varchar(190)
,`role` varchar(20)
,`status` enum('Active','Inactive','Pending','Disabled','Suspended')
,`last_login` datetime
,`created_at` timestamp
,`updated_at` timestamp
);

-- --------------------------------------------------------

--
-- Table structure for table `admit_applicants`
--

CREATE TABLE `admit_applicants` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `admit_evaluations`
--

CREATE TABLE `admit_evaluations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `applicant_id` bigint(20) UNSIGNED NOT NULL,
  `evaluator_id` int(10) UNSIGNED DEFAULT NULL,
  `exam_date` date NOT NULL,
  `score` decimal(5,2) NOT NULL,
  `decision` enum('Pending','Qualified','Not qualified') NOT NULL DEFAULT 'Pending',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `admit_interviews`
--

CREATE TABLE `admit_interviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `applicant_id` bigint(20) UNSIGNED NOT NULL,
  `interviewer_id` int(10) UNSIGNED DEFAULT NULL,
  `slot_id` bigint(20) UNSIGNED DEFAULT NULL,
  `scheduled_at` datetime NOT NULL,
  `location` varchar(190) NOT NULL,
  `status` enum('Scheduled','Completed','Cancelled','No show') NOT NULL DEFAULT 'Scheduled',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `admit_interview_slots`
--

CREATE TABLE `admit_interview_slots` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `interviewer_id` int(10) UNSIGNED DEFAULT NULL,
  `starts_at` datetime NOT NULL,
  `ends_at` datetime NOT NULL,
  `capacity` smallint(5) UNSIGNED NOT NULL DEFAULT 1,
  `location` varchar(190) NOT NULL DEFAULT 'ADFC Admissions Office',
  `status` enum('open','closed') NOT NULL DEFAULT 'open'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `announcements`
--

CREATE TABLE `announcements` (
  `announcement_id` bigint(20) UNSIGNED NOT NULL,
  `module_code` varchar(40) NOT NULL,
  `class_id` bigint(20) UNSIGNED DEFAULT NULL,
  `program_id` int(10) UNSIGNED DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `body` longtext NOT NULL,
  `audience` varchar(120) DEFAULT NULL,
  `created_by` int(10) UNSIGNED DEFAULT NULL,
  `is_published` tinyint(1) NOT NULL DEFAULT 0,
  `published_at` datetime DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `attend_approval_requests`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `attend_attendance_records`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `attend_attendance_sessions`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `attend_email_sent`
--

CREATE TABLE `attend_email_sent` (
  `record_id` varchar(40) NOT NULL,
  `to_addr` varchar(120) NOT NULL,
  `sent_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `attend_face_templates`
--

CREATE TABLE `attend_face_templates` (
  `member_id` varchar(40) NOT NULL,
  `descriptor` text NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `attend_members`
--

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
  `student_id` int(10) UNSIGNED DEFAULT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `attend_member_files`
--

CREATE TABLE `attend_member_files` (
  `owner` varchar(64) NOT NULL,
  `kind` varchar(10) NOT NULL,
  `data` mediumtext NOT NULL,
  `updated_by` varchar(64) NOT NULL DEFAULT '',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `attend_notification_log`
--

CREATE TABLE `attend_notification_log` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `channel` varchar(10) NOT NULL DEFAULT 'email',
  `to_addr` varchar(120) NOT NULL DEFAULT '',
  `student_id` varchar(40) NOT NULL DEFAULT '',
  `subject` varchar(160) NOT NULL DEFAULT '',
  `status` varchar(12) NOT NULL DEFAULT '',
  `reason` varchar(250) NOT NULL DEFAULT '',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `attend_notify_queue`
--

CREATE TABLE `attend_notify_queue` (
  `id` bigint(20) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `attend_password_resets`
--

CREATE TABLE `attend_password_resets` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `instructor_id` int(10) UNSIGNED NOT NULL,
  `code_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `used` tinyint(1) NOT NULL DEFAULT 0,
  `ip` varchar(45) NOT NULL DEFAULT '',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `attend_school_data`
--

CREATE TABLE `attend_school_data` (
  `part` varchar(40) NOT NULL,
  `v` mediumtext NOT NULL,
  `updated_by` varchar(64) NOT NULL DEFAULT '',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `auth_sessions`
--

CREATE TABLE `auth_sessions` (
  `session_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `token_hash` varchar(255) NOT NULL,
  `module_code` varchar(40) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` datetime DEFAULT NULL,
  `revoked_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_adjustments`
--

CREATE TABLE `billing_adjustments` (
  `adjustment_id` bigint(20) UNSIGNED NOT NULL,
  `adjustment_uid` char(36) DEFAULT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `enrollment_id` int(10) UNSIGNED DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL,
  `reason` varchar(150) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by_user_id` int(10) UNSIGNED DEFAULT NULL,
  `ref_key` varchar(40) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_discounts`
--

CREATE TABLE `billing_discounts` (
  `discount_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(60) NOT NULL,
  `kind` enum('percent','amount') NOT NULL DEFAULT 'percent',
  `value` decimal(12,2) NOT NULL,
  `applies_to` varchar(20) NOT NULL DEFAULT 'tuition',
  `active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_enrollment_discounts`
--

CREATE TABLE `billing_enrollment_discounts` (
  `enrollment_discount_id` bigint(20) UNSIGNED NOT NULL,
  `enrollment_id` int(10) UNSIGNED NOT NULL,
  `discount_id` int(10) UNSIGNED DEFAULT NULL,
  `name_snapshot` varchar(60) NOT NULL,
  `percent_snapshot` decimal(5,2) NOT NULL DEFAULT 0.00,
  `amount_snapshot` decimal(12,2) NOT NULL DEFAULT 0.00,
  `applies_to` varchar(20) NOT NULL DEFAULT 'tuition',
  `source` varchar(20) NOT NULL DEFAULT 'staff'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_enrollment_inbox`
--

CREATE TABLE `billing_enrollment_inbox` (
  `inbox_id` bigint(20) UNSIGNED NOT NULL,
  `enrollment_id` int(10) UNSIGNED DEFAULT NULL,
  `student_id` int(10) UNSIGNED DEFAULT NULL,
  `event` varchar(20) DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  `message` varchar(255) DEFAULT NULL,
  `payload` mediumtext DEFAULT NULL,
  `received_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_enrollment_plans`
--

CREATE TABLE `billing_enrollment_plans` (
  `enrollment_id` int(10) UNSIGNED NOT NULL,
  `billing_uid` char(36) DEFAULT NULL,
  `units_snapshot` decimal(5,1) NOT NULL DEFAULT 0.0,
  `lab_units_snapshot` decimal(5,1) NOT NULL DEFAULT 0.0,
  `plan` enum('full','installment') NOT NULL DEFAULT 'installment',
  `billing_status` enum('pre_enrolled','enrolled','dropped','withdrawn','cancelled') NOT NULL DEFAULT 'enrolled',
  `assessed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_enrollment_subject_details`
--

CREATE TABLE `billing_enrollment_subject_details` (
  `enrollment_subject_id` int(10) UNSIGNED NOT NULL,
  `units_snapshot` decimal(4,1) NOT NULL DEFAULT 0.0,
  `lab_units_snapshot` decimal(4,1) NOT NULL DEFAULT 0.0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_fee_rules`
--

CREATE TABLE `billing_fee_rules` (
  `fee_id` int(10) UNSIGNED NOT NULL,
  `calculation_kind` enum('fixed','per_unit','per_lab_unit') NOT NULL DEFAULT 'fixed',
  `category` enum('tuition','lab','misc','other') NOT NULL DEFAULT 'misc',
  `year_level` tinyint(3) UNSIGNED DEFAULT NULL,
  `student_type` varchar(25) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_invoices`
--

CREATE TABLE `billing_invoices` (
  `invoice_id` bigint(20) UNSIGNED NOT NULL,
  `invoice_uid` char(36) DEFAULT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `enrollment_id` int(10) UNSIGNED DEFAULT NULL,
  `description` varchar(150) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `ref_key` varchar(40) DEFAULT NULL,
  `category` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_online_payments`
--

CREATE TABLE `billing_online_payments` (
  `online_payment_id` bigint(20) UNSIGNED NOT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `enrollment_id` int(10) UNSIGNED DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL,
  `session_id` varchar(80) NOT NULL,
  `reference` varchar(40) NOT NULL,
  `checkout_url` varchar(500) NOT NULL,
  `status` enum('pending','paid','expired','failed') NOT NULL DEFAULT 'pending',
  `channel` varchar(30) DEFAULT NULL,
  `provider_payment_id` varchar(60) DEFAULT NULL,
  `payment_id` bigint(20) UNSIGNED DEFAULT NULL,
  `note` varchar(200) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `paid_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_payments`
--

CREATE TABLE `billing_payments` (
  `payment_id` bigint(20) UNSIGNED NOT NULL,
  `payment_uid` char(36) DEFAULT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `enrollment_id` int(10) UNSIGNED DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL,
  `or_no` varchar(30) DEFAULT NULL,
  `payment_source` enum('online','offline') NOT NULL DEFAULT 'online',
  `paid_at` datetime NOT NULL DEFAULT current_timestamp(),
  `method` varchar(30) DEFAULT NULL,
  `reference_no` varchar(40) DEFAULT NULL,
  `remarks` varchar(150) DEFAULT NULL,
  `received_by_user_id` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_payment_requests`
--

CREATE TABLE `billing_payment_requests` (
  `request_id` bigint(20) UNSIGNED NOT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `enrollment_id` int(10) UNSIGNED DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL,
  `method` varchar(30) NOT NULL,
  `reference` varchar(60) NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `note` varchar(200) DEFAULT NULL,
  `payment_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `reviewed_by_user_id` int(10) UNSIGNED DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_settings`
--

CREATE TABLE `billing_settings` (
  `k` varchar(40) NOT NULL,
  `v` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_term_schedules`
--

CREATE TABLE `billing_term_schedules` (
  `period_id` int(10) UNSIGNED NOT NULL,
  `due_prelim` date DEFAULT NULL,
  `due_midterm` date DEFAULT NULL,
  `due_prefinal` date DEFAULT NULL,
  `due_final` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `blocks`
--

CREATE TABLE `blocks` (
  `block_id` int(10) UNSIGNED NOT NULL,
  `program_id` int(10) UNSIGNED NOT NULL,
  `period_id` int(10) UNSIGNED NOT NULL,
  `year_level` tinyint(3) UNSIGNED NOT NULL,
  `block_code` varchar(30) NOT NULL,
  `capacity` int(10) UNSIGNED DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `campusfind_claims`
--

CREATE TABLE `campusfind_claims` (
  `campusfind_claim_id` int(10) UNSIGNED NOT NULL,
  `campusfind_item_id` int(10) UNSIGNED NOT NULL,
  `campusfind_claimant_user_id` int(10) UNSIGNED NOT NULL,
  `campusfind_ownership_evidence` text NOT NULL,
  `campusfind_status` enum('pending','approved','rejected','completed') NOT NULL DEFAULT 'pending',
  `campusfind_reviewer_user_id` int(10) UNSIGNED DEFAULT NULL,
  `campusfind_review_note` text DEFAULT NULL,
  `campusfind_reviewed_at` datetime DEFAULT NULL,
  `campusfind_completed_at` datetime DEFAULT NULL,
  `campusfind_created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `campusfind_items`
--

CREATE TABLE `campusfind_items` (
  `campusfind_item_id` int(10) UNSIGNED NOT NULL,
  `campusfind_reporter_user_id` int(10) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `campusfind_live_revisions`
--

CREATE TABLE `campusfind_live_revisions` (
  `campusfind_resource` varchar(64) NOT NULL,
  `campusfind_revision` bigint(20) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `campusfind_section_views`
--

CREATE TABLE `campusfind_section_views` (
  `campusfind_user_id` int(10) UNSIGNED NOT NULL,
  `campusfind_section_key` varchar(24) NOT NULL,
  `campusfind_last_seen_id` bigint(20) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cebrms_borrowers`
--

CREATE TABLE `cebrms_borrowers` (
  `borrower_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL,
  `student_id` int(10) UNSIGNED DEFAULT NULL,
  `department_id` int(10) UNSIGNED DEFAULT NULL,
  `borrower_no` varchar(30) NOT NULL,
  `borrower_type` enum('Student','Faculty','Staff','Other') NOT NULL,
  `external_full_name` varchar(100) DEFAULT NULL COMMENT 'For unregistered external borrowers only',
  `external_contact_no` varchar(20) DEFAULT NULL COMMENT 'For unregistered external borrowers only',
  `external_email` varchar(100) DEFAULT NULL COMMENT 'For unregistered external borrowers only',
  `status` enum('Active','Blocked','Inactive') NOT NULL DEFAULT 'Active',
  `qr_code_value` varchar(60) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `cebrms_borrow_items`
--

CREATE TABLE `cebrms_borrow_items` (
  `borrow_item_id` bigint(20) UNSIGNED NOT NULL,
  `transaction_id` bigint(20) UNSIGNED NOT NULL,
  `equipment_id` int(10) UNSIGNED NOT NULL,
  `quantity_borrowed` int(10) UNSIGNED NOT NULL,
  `quantity_returned` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `item_status` enum('Borrowed','Partially Returned','Returned','Overdue','Lost') NOT NULL DEFAULT 'Borrowed'
) ;

-- --------------------------------------------------------

--
-- Table structure for table `cebrms_borrow_transactions`
--

CREATE TABLE `cebrms_borrow_transactions` (
  `transaction_id` bigint(20) UNSIGNED NOT NULL,
  `transaction_no` varchar(30) NOT NULL,
  `borrower_id` int(10) UNSIGNED NOT NULL,
  `processed_by` int(10) UNSIGNED DEFAULT NULL,
  `approved_by` int(10) UNSIGNED DEFAULT NULL,
  `date_requested` datetime NOT NULL DEFAULT current_timestamp(),
  `date_borrowed` datetime DEFAULT NULL,
  `expected_return_date` date NOT NULL,
  `status` enum('Pending','Approved','Issued','Partially Returned','Returned','Overdue','Rejected','Cancelled') NOT NULL DEFAULT 'Pending',
  `purpose` varchar(255) DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  `qr_code_value` varchar(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cebrms_equipment`
--

CREATE TABLE `cebrms_equipment` (
  `equipment_id` int(10) UNSIGNED NOT NULL,
  `category_id` int(10) UNSIGNED NOT NULL,
  `maintenance_asset_id` int(10) UNSIGNED DEFAULT NULL COMMENT 'Optional link to physical maintenance asset; not an automatic stock sync',
  `equipment_code` varchar(30) NOT NULL,
  `equipment_name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `total_quantity` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `available_quantity` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `damaged_quantity` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `condition_status` enum('Good','Fair','Needs Repair','Damaged') NOT NULL DEFAULT 'Good',
  `storage_location` varchar(100) DEFAULT NULL,
  `qr_code_value` varchar(60) NOT NULL,
  `status` enum('Active','Archived') NOT NULL DEFAULT 'Active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `cebrms_equipment_categories`
--

CREATE TABLE `cebrms_equipment_categories` (
  `category_id` int(10) UNSIGNED NOT NULL,
  `category_name` varchar(60) NOT NULL,
  `description` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cebrms_qr_scan_logs`
--

CREATE TABLE `cebrms_qr_scan_logs` (
  `scan_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `qr_type` enum('Equipment','Borrower','Transaction','Unknown') NOT NULL,
  `qr_value` varchar(100) NOT NULL,
  `scan_context` enum('Borrow','Return','Lookup','Inventory') NOT NULL,
  `result` enum('Matched','Not Found','Invalid') NOT NULL,
  `scanned_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cebrms_return_records`
--

CREATE TABLE `cebrms_return_records` (
  `return_id` bigint(20) UNSIGNED NOT NULL,
  `borrow_item_id` bigint(20) UNSIGNED NOT NULL,
  `received_by` int(10) UNSIGNED NOT NULL,
  `actual_return_date` datetime NOT NULL DEFAULT current_timestamp(),
  `quantity_returned` int(10) UNSIGNED NOT NULL,
  `quantity_damaged` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `quantity_missing` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `condition_notes` varchar(255) DEFAULT NULL
) ;

-- --------------------------------------------------------

--
-- Table structure for table `class_enrollments`
--

CREATE TABLE `class_enrollments` (
  `enrollment_id` int(11) NOT NULL,
  `enrollment_uid` char(36) DEFAULT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `class_id` bigint(20) UNSIGNED NOT NULL,
  `membership_status` enum('Active','Withdrawn','Completed') NOT NULL DEFAULT 'Active',
  `enrolled_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `department_id` int(10) UNSIGNED NOT NULL,
  `department_code` varchar(30) NOT NULL,
  `department_name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `election_ballots`
--

CREATE TABLE `election_ballots` (
  `ballot_id` bigint(20) NOT NULL,
  `candidate_id` int(11) NOT NULL,
  `cast_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `election_candidacies`
--

CREATE TABLE `election_candidacies` (
  `candidate_id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `position_id` int(11) NOT NULL,
  `profile` text DEFAULT NULL,
  `platform` text DEFAULT NULL,
  `filing_status` enum('pending','approved','declined') NOT NULL DEFAULT 'pending',
  `review_remarks` text DEFAULT NULL,
  `reviewed_by` int(10) UNSIGNED DEFAULT NULL,
  `review_date` datetime DEFAULT NULL,
  `filed_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `election_candidate_documents`
--

CREATE TABLE `election_candidate_documents` (
  `document_id` int(11) NOT NULL,
  `candidate_id` int(11) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `upload_date` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `election_elections`
--

CREATE TABLE `election_elections` (
  `election_id` int(11) NOT NULL,
  `election_name` varchar(150) NOT NULL,
  `academic_year` varchar(20) DEFAULT NULL,
  `voting_start` datetime NOT NULL,
  `voting_end` datetime NOT NULL,
  `face_match_threshold` decimal(4,3) NOT NULL DEFAULT 0.800,
  `eligibility_criteria` varchar(255) DEFAULT NULL,
  `election_status` enum('draft','scheduled','open','closed','archived') NOT NULL DEFAULT 'draft',
  `created_by` int(10) UNSIGNED DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `election_face_data`
--

CREATE TABLE `election_face_data` (
  `face_id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `face_template` varbinary(2048) NOT NULL,
  `consent_status` enum('given','withdrawn') NOT NULL,
  `consent_date` datetime NOT NULL,
  `enrolled_at` datetime NOT NULL DEFAULT current_timestamp(),
  `data_status` enum('active','deleted') NOT NULL DEFAULT 'active',
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `election_face_verifications`
--

CREATE TABLE `election_face_verifications` (
  `verification_id` bigint(20) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `election_id` int(11) NOT NULL,
  `match_score` decimal(5,4) DEFAULT NULL,
  `liveness_result` enum('passed','failed') DEFAULT NULL,
  `verification_status` enum('verified','failed','pending_manual','manually_verified') NOT NULL,
  `reviewed_by` int(10) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `attempted_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `election_positions`
--

CREATE TABLE `election_positions` (
  `position_id` int(11) NOT NULL,
  `election_id` int(11) NOT NULL,
  `position_name` varchar(100) NOT NULL,
  `seats` tinyint(4) NOT NULL DEFAULT 1,
  `display_order` tinyint(4) NOT NULL DEFAULT 1
) ;

-- --------------------------------------------------------

--
-- Table structure for table `election_results`
--

CREATE TABLE `election_results` (
  `result_id` int(11) NOT NULL,
  `candidate_id` int(11) NOT NULL,
  `vote_count` int(11) NOT NULL DEFAULT 0,
  `is_winner` tinyint(1) NOT NULL DEFAULT 0,
  `proclaimed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `election_security_login_attempts`
--

CREATE TABLE `election_security_login_attempts` (
  `attempt_id` bigint(20) UNSIGNED NOT NULL,
  `email_hash` char(64) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `attempted_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `election_security_sessions`
--

CREATE TABLE `election_security_sessions` (
  `session_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `token_hash` char(64) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `user_agent` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `last_seen_at` datetime NOT NULL DEFAULT current_timestamp(),
  `revoked_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `election_vote_records`
--

CREATE TABLE `election_vote_records` (
  `record_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `position_id` int(11) NOT NULL,
  `voted_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ems_employee_details`
--

CREATE TABLE `ems_employee_details` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `employee_code` varchar(20) NOT NULL,
  `contact_number` varchar(30) DEFAULT NULL,
  `employment_status` enum('Active','Inactive','OnLeave','Resigned') NOT NULL DEFAULT 'Active',
  `date_hired` date DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ems_employee_documents`
--

CREATE TABLE `ems_employee_documents` (
  `document_id` bigint(20) UNSIGNED NOT NULL,
  `employee_user_id` int(10) UNSIGNED NOT NULL,
  `category` varchar(50) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `stored_path` varchar(500) NOT NULL,
  `uploaded_by_user_id` int(10) UNSIGNED NOT NULL,
  `uploaded_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `enrollments`
--

CREATE TABLE `enrollments` (
  `enrollment_id` int(10) UNSIGNED NOT NULL,
  `enrollment_number` varchar(35) DEFAULT NULL,
  `pre_enrollment_id` int(10) UNSIGNED DEFAULT NULL,
  `enrollment_method` enum('Direct','Pre-Enrollment') NOT NULL DEFAULT 'Pre-Enrollment',
  `student_id` int(10) UNSIGNED NOT NULL,
  `program_id` int(10) UNSIGNED NOT NULL,
  `period_id` int(10) UNSIGNED NOT NULL,
  `year_level` tinyint(3) UNSIGNED NOT NULL,
  `block_id` int(10) UNSIGNED DEFAULT NULL,
  `enrollment_status` enum('Pending','Confirmed','Cancelled') NOT NULL DEFAULT 'Pending',
  `student_load` enum('Regular','Irregular') NOT NULL DEFAULT 'Regular',
  `irregular_details` varchar(255) DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  `verified_by` int(10) UNSIGNED DEFAULT NULL,
  `confirmed_by` int(10) UNSIGNED DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `enrollment_charges`
--

CREATE TABLE `enrollment_charges` (
  `charge_id` bigint(20) UNSIGNED NOT NULL,
  `enrollment_id` int(10) UNSIGNED NOT NULL,
  `fee_id` int(10) UNSIGNED DEFAULT NULL,
  `fee_name_snapshot` varchar(150) NOT NULL,
  `amount_snapshot` decimal(12,2) NOT NULL,
  `assessed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `enrollment_subjects`
--

CREATE TABLE `enrollment_subjects` (
  `enrollment_subject_id` int(10) UNSIGNED NOT NULL,
  `enrollment_id` int(10) UNSIGNED NOT NULL,
  `subject_id` int(10) UNSIGNED NOT NULL,
  `subject_status` enum('Enrolled','Dropped') NOT NULL DEFAULT 'Enrolled',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_applications`
--

CREATE TABLE `eteeap_applications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_assessments`
--

CREATE TABLE `eteeap_assessments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `assessor_id` int(10) UNSIGNED DEFAULT NULL,
  `title` varchar(150) NOT NULL,
  `scheduled_at` datetime NOT NULL,
  `mode` enum('Onsite','Online') NOT NULL DEFAULT 'Onsite',
  `venue` varchar(255) NOT NULL,
  `status` enum('scheduled','completed','cancelled') NOT NULL DEFAULT 'scheduled',
  `feedback` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_billing_fees`
--

CREATE TABLE `eteeap_billing_fees` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(30) NOT NULL,
  `label` varchar(160) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_billing_invoices`
--

CREATE TABLE `eteeap_billing_invoices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `invoice_no` varchar(32) DEFAULT NULL,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `fee_id` bigint(20) UNSIGNED NOT NULL,
  `description` varchar(160) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `status` enum('issued','part_paid','paid','voided') NOT NULL DEFAULT 'issued',
  `due_on` date DEFAULT NULL,
  `created_by` int(10) UNSIGNED NOT NULL,
  `void_reason` varchar(250) DEFAULT NULL,
  `voided_by` int(10) UNSIGNED DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_billing_payments`
--

CREATE TABLE `eteeap_billing_payments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `receipt_no` varchar(32) DEFAULT NULL,
  `invoice_id` bigint(20) UNSIGNED NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `method` enum('cash','bank_transfer','gcash','other') NOT NULL,
  `external_reference` varchar(110) NOT NULL,
  `paid_on` date NOT NULL,
  `status` enum('posted','voided') NOT NULL DEFAULT 'posted',
  `recorded_by` int(10) UNSIGNED NOT NULL,
  `void_reason` varchar(250) DEFAULT NULL,
  `voided_by` int(10) UNSIGNED DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_credits`
--

CREATE TABLE `eteeap_credits` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `evaluator_id` int(10) UNSIGNED NOT NULL,
  `course_name` varchar(180) NOT NULL,
  `units` tinyint(3) UNSIGNED NOT NULL,
  `status` enum('recommended','approved','rejected') NOT NULL DEFAULT 'recommended',
  `remarks` text DEFAULT NULL,
  `decided_by` int(10) UNSIGNED DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_education_records`
--

CREATE TABLE `eteeap_education_records` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `institution` varchar(180) NOT NULL,
  `program_name` varchar(180) NOT NULL,
  `start_year` smallint(5) UNSIGNED DEFAULT NULL,
  `end_year` smallint(5) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_employment_records`
--

CREATE TABLE `eteeap_employment_records` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `company` varchar(180) NOT NULL,
  `job_title` varchar(180) NOT NULL,
  `date_started` date NOT NULL,
  `date_ended` date DEFAULT NULL,
  `responsibilities` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_evaluations`
--

CREATE TABLE `eteeap_evaluations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `assessor_id` int(10) UNSIGNED NOT NULL,
  `authenticity` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `relevance` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `sufficiency` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `currency_score` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `feedback` text DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_form_records`
--

CREATE TABLE `eteeap_form_records` (
  `id` int(10) UNSIGNED NOT NULL,
  `form_key` varchar(20) NOT NULL,
  `application_id` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `author_id` int(10) UNSIGNED NOT NULL,
  `author_role` varchar(20) NOT NULL,
  `responses` longtext NOT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_grades`
--

CREATE TABLE `eteeap_grades` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `assessor_id` int(10) UNSIGNED NOT NULL,
  `course_name` varchar(180) NOT NULL,
  `grade` decimal(5,2) NOT NULL,
  `status` enum('draft','published') NOT NULL DEFAULT 'draft',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_login_attempts`
--

CREATE TABLE `eteeap_login_attempts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `login_key` char(64) NOT NULL,
  `attempted_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_messages`
--

CREATE TABLE `eteeap_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` int(10) UNSIGNED NOT NULL,
  `channel` enum('coordinator','assessor') NOT NULL DEFAULT 'coordinator',
  `subject` varchar(180) NOT NULL DEFAULT 'ETEEAP Message',
  `body` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_portfolio_assessments`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_portfolio_rubric_forms`
--

CREATE TABLE `eteeap_portfolio_rubric_forms` (
  `id` int(10) UNSIGNED NOT NULL,
  `application_id` int(10) UNSIGNED NOT NULL,
  `assessor_id` int(10) UNSIGNED NOT NULL,
  `assessment_date` date DEFAULT NULL,
  `panel_name` varchar(250) NOT NULL DEFAULT '',
  `ratings_json` text NOT NULL,
  `recommendation` varchar(80) NOT NULL DEFAULT '',
  `remarks` text NOT NULL,
  `total_score` decimal(6,3) DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_program_offerings`
--

CREATE TABLE `eteeap_program_offerings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(30) NOT NULL,
  `degree_name` varchar(180) NOT NULL,
  `authorization_reference` varchar(180) NOT NULL,
  `valid_from` date NOT NULL,
  `valid_until` date NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `configured_by` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_uploads`
--

CREATE TABLE `eteeap_uploads` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `uploaded_by` int(10) UNSIGNED NOT NULL,
  `kind` enum('document','portfolio') NOT NULL,
  `requirement_key` varchar(40) DEFAULT NULL,
  `category` enum('employment','training','certification','project','supporting') DEFAULT NULL,
  `title` varchar(180) NOT NULL,
  `description` text DEFAULT NULL,
  `storage_name` varchar(90) NOT NULL,
  `original_name` varchar(255) NOT NULL,
  `mime_type` varchar(80) NOT NULL,
  `size_bytes` bigint(20) UNSIGNED NOT NULL,
  `replaces_upload_id` bigint(20) UNSIGNED DEFAULT NULL,
  `status` enum('pending','verified','revision') NOT NULL DEFAULT 'pending',
  `reviewer_note` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eteeap_upload_events`
--

CREATE TABLE `eteeap_upload_events` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `upload_id` bigint(20) UNSIGNED NOT NULL,
  `actor_id` int(10) UNSIGNED DEFAULT NULL,
  `event_type` enum('uploaded','reviewed','resubmitted','legacy_review') NOT NULL,
  `old_status` enum('pending','verified','revision') DEFAULT NULL,
  `new_status` enum('pending','verified','revision') NOT NULL,
  `note` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_criteria`
--

CREATE TABLE `event_criteria` (
  `criterion_id` int(10) UNSIGNED NOT NULL,
  `event_id` int(10) UNSIGNED NOT NULL,
  `criterion_name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `weight_percentage` decimal(5,2) NOT NULL,
  `maximum_score` decimal(7,2) NOT NULL,
  `display_order` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_entries`
--

CREATE TABLE `event_entries` (
  `entry_id` int(10) UNSIGNED NOT NULL,
  `event_id` int(10) UNSIGNED NOT NULL,
  `participant_id` int(10) UNSIGNED DEFAULT NULL,
  `team_id` int(10) UNSIGNED DEFAULT NULL,
  `entry_code` varchar(30) NOT NULL,
  `status` enum('Registered','Withdrawn','Disqualified') NOT NULL DEFAULT 'Registered',
  `record_uuid` char(36) NOT NULL,
  `registered_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_events`
--

CREATE TABLE `event_events` (
  `event_id` int(10) UNSIGNED NOT NULL,
  `event_name` varchar(150) NOT NULL,
  `event_category` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `event_date` date DEFAULT NULL,
  `status` enum('Upcoming','Ongoing','Completed') NOT NULL DEFAULT 'Upcoming',
  `created_by` int(10) UNSIGNED NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `is_published` tinyint(1) NOT NULL DEFAULT 0,
  `publication_version` bigint(20) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_generated_reports`
--

CREATE TABLE `event_generated_reports` (
  `report_id` int(10) UNSIGNED NOT NULL,
  `event_id` int(10) UNSIGNED DEFAULT NULL,
  `report_type` varchar(100) NOT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `generated_by` int(10) UNSIGNED NOT NULL,
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_integration_logs`
--

CREATE TABLE `event_integration_logs` (
  `integration_log_id` bigint(20) UNSIGNED NOT NULL,
  `service_name` varchar(150) NOT NULL,
  `request_type` varchar(50) NOT NULL,
  `reference_id` varchar(100) DEFAULT NULL,
  `response_status` varchar(50) NOT NULL,
  `error_message` text DEFAULT NULL,
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_judges`
--

CREATE TABLE `event_judges` (
  `assignment_id` int(10) UNSIGNED NOT NULL,
  `event_id` int(10) UNSIGNED NOT NULL,
  `judge_user_id` int(10) UNSIGNED NOT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `record_uuid` char(36) NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_participants`
--

CREATE TABLE `event_participants` (
  `participant_id` int(10) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `event_participant_photos`
--

CREATE TABLE `event_participant_photos` (
  `participant_id` int(10) UNSIGNED NOT NULL,
  `filename` varchar(80) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `is_public` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_point_awards`
--

CREATE TABLE `event_point_awards` (
  `point_award_id` int(10) UNSIGNED NOT NULL,
  `result_id` int(10) UNSIGNED NOT NULL,
  `participant_id` int(10) UNSIGNED DEFAULT NULL,
  `team_id` int(10) UNSIGNED DEFAULT NULL,
  `points_awarded` decimal(8,2) NOT NULL DEFAULT 0.00,
  `approved_by` int(10) UNSIGNED NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `awarded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_point_rules`
--

CREATE TABLE `event_point_rules` (
  `point_rule_id` int(10) UNSIGNED NOT NULL,
  `event_id` int(10) UNSIGNED NOT NULL,
  `rank_position` int(10) UNSIGNED NOT NULL,
  `points_value` decimal(8,2) NOT NULL DEFAULT 0.00,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_result_summaries`
--

CREATE TABLE `event_result_summaries` (
  `result_id` int(10) UNSIGNED NOT NULL,
  `entry_id` int(10) UNSIGNED NOT NULL,
  `total_score` decimal(10,4) NOT NULL DEFAULT 0.0000,
  `rank_position` int(10) UNSIGNED DEFAULT NULL,
  `result_status` enum('Provisional','Finalized') NOT NULL DEFAULT 'Provisional',
  `calculated_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `finalized_at` timestamp NULL DEFAULT NULL,
  `record_uuid` char(36) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_scores`
--

CREATE TABLE `event_scores` (
  `score_id` int(10) UNSIGNED NOT NULL,
  `entry_id` int(10) UNSIGNED NOT NULL,
  `assignment_id` int(10) UNSIGNED NOT NULL,
  `criterion_id` int(10) UNSIGNED NOT NULL,
  `score_value` decimal(7,2) NOT NULL,
  `status` enum('Draft','Submitted','Approved') NOT NULL DEFAULT 'Draft',
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_sports_matches`
--

CREATE TABLE `event_sports_matches` (
  `match_id` bigint(20) UNSIGNED NOT NULL,
  `event_id` int(10) UNSIGNED NOT NULL,
  `entry_a_id` int(10) UNSIGNED NOT NULL,
  `entry_b_id` int(10) UNSIGNED NOT NULL,
  `sport` enum('basketball','volleyball','other') NOT NULL,
  `sport_label` varchar(100) DEFAULT NULL,
  `score_a` int(10) UNSIGNED DEFAULT NULL,
  `score_b` int(10) UNSIGNED DEFAULT NULL,
  `period` varchar(100) DEFAULT NULL,
  `status` enum('scheduled','ongoing','completed') NOT NULL DEFAULT 'scheduled',
  `version` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_staff_registration_requests`
--

CREATE TABLE `event_staff_registration_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `requested_role` varchar(30) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Pending',
  `reviewed_by` int(10) UNSIGNED DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_sync_queue`
--

CREATE TABLE `event_sync_queue` (
  `sync_id` bigint(20) UNSIGNED NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `table_name` varchar(100) NOT NULL,
  `operation` enum('Create','Update','Delete') NOT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`payload`)),
  `record_version` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `sync_status` enum('Pending','Processing','Synchronized','Failed','Conflict') NOT NULL DEFAULT 'Pending',
  `attempts` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `synced_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_tabulator_assignments`
--

CREATE TABLE `event_tabulator_assignments` (
  `event_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_teams`
--

CREATE TABLE `event_teams` (
  `team_id` int(10) UNSIGNED NOT NULL,
  `team_name` varchar(150) NOT NULL,
  `department` varchar(150) DEFAULT NULL,
  `coach_name` varchar(150) DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `event_team_members`
--

CREATE TABLE `event_team_members` (
  `team_member_id` int(10) UNSIGNED NOT NULL,
  `team_id` int(10) UNSIGNED NOT NULL,
  `participant_id` int(10) UNSIGNED NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fee_items`
--

CREATE TABLE `fee_items` (
  `fee_id` int(10) UNSIGNED NOT NULL,
  `fee_code` varchar(30) NOT NULL,
  `fee_name` varchar(150) NOT NULL,
  `fee_basis` enum('Program','Subject') NOT NULL,
  `program_id` int(10) UNSIGNED DEFAULT NULL,
  `subject_id` int(10) UNSIGNED DEFAULT NULL,
  `period_id` int(10) UNSIGNED DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_completion_logs`
--

CREATE TABLE `fe_completion_logs` (
  `completion_id` int(11) NOT NULL,
  `schedule_id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `anonymous_hash` char(64) NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_department_heads`
--

CREATE TABLE `fe_department_heads` (
  `department_head_id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `department_id` int(10) UNSIGNED NOT NULL,
  `employee_number` varchar(30) DEFAULT NULL,
  `designation` varchar(100) DEFAULT 'Department Head',
  `appointment_start` date DEFAULT NULL,
  `appointment_end` date DEFAULT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_evaluation_questions`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `fe_evaluation_reports`
--

CREATE TABLE `fe_evaluation_reports` (
  `report_id` int(11) NOT NULL,
  `schedule_id` int(11) NOT NULL,
  `report_level` enum('FACULTY','PROGRAM','DEPARTMENT') NOT NULL,
  `department_id` int(10) UNSIGNED DEFAULT NULL,
  `program_id` int(10) UNSIGNED DEFAULT NULL,
  `faculty_id` int(10) UNSIGNED DEFAULT NULL,
  `total_responses` int(11) NOT NULL DEFAULT 0,
  `average_rating` decimal(4,2) DEFAULT NULL,
  `score_percentage` decimal(5,2) DEFAULT NULL,
  `generated_by` int(10) UNSIGNED NOT NULL,
  `approved_by` int(10) UNSIGNED DEFAULT NULL,
  `release_status` enum('DRAFT','APPROVED','RELEASED','WITHHELD') NOT NULL DEFAULT 'DRAFT',
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_evaluation_responses`
--

CREATE TABLE `fe_evaluation_responses` (
  `response_id` int(11) NOT NULL,
  `submission_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `rating` tinyint(4) NOT NULL,
  `comment` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_evaluation_schedules`
--

CREATE TABLE `fe_evaluation_schedules` (
  `schedule_id` int(11) NOT NULL,
  `term_id` int(10) UNSIGNED NOT NULL,
  `program_id` int(10) UNSIGNED NOT NULL,
  `opens_at` datetime NOT NULL,
  `closes_at` datetime NOT NULL,
  `status` enum('DRAFT','SCHEDULED','READY','OPEN','CLOSED','RELEASED') NOT NULL DEFAULT 'SCHEDULED',
  `grade_gate_passed` tinyint(1) NOT NULL DEFAULT 0,
  `created_by` int(10) UNSIGNED NOT NULL,
  `opened_by` int(10) UNSIGNED DEFAULT NULL,
  `opened_at` datetime DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_evaluation_submissions`
--

CREATE TABLE `fe_evaluation_submissions` (
  `submission_id` int(11) NOT NULL,
  `schedule_id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `anonymous_token` char(64) NOT NULL,
  `submitted_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_grade_completion`
--

CREATE TABLE `fe_grade_completion` (
  `grade_completion_id` int(11) NOT NULL,
  `enrollment_id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `grade_component` enum('MIDTERM','FINAL','OVERALL_FINAL') NOT NULL,
  `completion_status` enum('PENDING','SUBMITTED','VALIDATED') NOT NULL DEFAULT 'PENDING',
  `validated_by` int(10) UNSIGNED DEFAULT NULL,
  `validated_at` timestamp NULL DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_onecampus_webhook_events`
--

CREATE TABLE `fe_onecampus_webhook_events` (
  `event_id` varchar(128) NOT NULL,
  `event_type` varchar(100) NOT NULL,
  `payload_sha256` char(64) NOT NULL,
  `received_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `processing_status` enum('RECEIVED','PROCESSED','FAILED') NOT NULL DEFAULT 'RECEIVED',
  `processed_at` timestamp NULL DEFAULT NULL,
  `failure_reason` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_schools`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `fe_shs_specializations`
--

CREATE TABLE `fe_shs_specializations` (
  `specialization_id` int(11) NOT NULL,
  `strand_id` int(11) NOT NULL,
  `specialization_code` varchar(30) NOT NULL,
  `specialization_name` varchar(160) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_shs_strands`
--

CREATE TABLE `fe_shs_strands` (
  `strand_id` int(11) NOT NULL,
  `track_id` tinyint(4) NOT NULL,
  `program_id` int(10) UNSIGNED DEFAULT NULL,
  `strand_code` varchar(20) NOT NULL,
  `strand_name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_shs_tracks`
--

CREATE TABLE `fe_shs_tracks` (
  `track_id` tinyint(4) NOT NULL,
  `track_code` varchar(20) NOT NULL,
  `track_name` varchar(100) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fe_teaching_assignments`
--

CREATE TABLE `fe_teaching_assignments` (
  `assignment_id` int(11) NOT NULL,
  `class_id` bigint(20) UNSIGNED NOT NULL,
  `instructor_id` int(10) UNSIGNED NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `guidance_appointments`
--

CREATE TABLE `guidance_appointments` (
  `id` int(11) NOT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `guidance_counselor_availability`
--

CREATE TABLE `guidance_counselor_availability` (
  `id` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `available_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `status` enum('available','unavailable') NOT NULL DEFAULT 'available',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `guidance_follow_ups`
--

CREATE TABLE `guidance_follow_ups` (
  `id` int(11) NOT NULL,
  `record_id` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `follow_up_date` date NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'pending',
  `remarks` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `guidance_integration_settings`
--

CREATE TABLE `guidance_integration_settings` (
  `id` int(11) NOT NULL,
  `integration_name` varchar(80) NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 0,
  `status` varchar(30) NOT NULL DEFAULT 'not_configured',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `guidance_records`
--

CREATE TABLE `guidance_records` (
  `id` int(11) NOT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `appointment_id` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `record_date` date NOT NULL,
  `record_category` varchar(50) NOT NULL,
  `confidential_note` text NOT NULL,
  `record_status` varchar(30) NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `guidance_referrals`
--

CREATE TABLE `guidance_referrals` (
  `id` int(11) NOT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `staff_id` int(11) NOT NULL,
  `referral_date` date NOT NULL,
  `referral_type` varchar(100) NOT NULL,
  `referred_to` varchar(100) NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'pending',
  `remarks` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `guidance_staff_profiles`
--

CREATE TABLE `guidance_staff_profiles` (
  `staff_id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `guidance_role` varchar(50) NOT NULL DEFAULT 'Counselor',
  `department` varchar(100) DEFAULT 'Guidance Office',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `idcard_iadfc_idcards`
--

CREATE TABLE `idcard_iadfc_idcards` (
  `CardId` int(11) NOT NULL,
  `PersonId` int(11) NOT NULL,
  `CardReference` varchar(100) NOT NULL,
  `Status` varchar(30) NOT NULL DEFAULT 'Draft',
  `GeneratedBy` int(10) UNSIGNED NOT NULL,
  `UpdatedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6),
  `IsSample` tinyint(1) NOT NULL DEFAULT 0,
  `ValidUntil` date NOT NULL DEFAULT '2028-10-31',
  `VerifyToken` varchar(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `Snapshot` longtext DEFAULT NULL,
  `ValidFrom` date DEFAULT NULL,
  `DateIssued` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `idcard_iadfc_idreleases`
--

CREATE TABLE `idcard_iadfc_idreleases` (
  `ReleaseId` int(11) NOT NULL,
  `CardId` int(11) NOT NULL,
  `ReleasedBy` int(10) UNSIGNED NOT NULL,
  `RecipientName` varchar(160) NOT NULL,
  `VerificationMethod` varchar(100) NOT NULL,
  `ReleasedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6),
  `Acknowledgment` longtext NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `idcard_iadfc_printrecords`
--

CREATE TABLE `idcard_iadfc_printrecords` (
  `PrintId` int(11) NOT NULL,
  `CardId` int(11) NOT NULL,
  `PrintedBy` int(10) UNSIGNED NOT NULL,
  `PrintedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `idcard_iadfc_schoolsettings`
--

CREATE TABLE `idcard_iadfc_schoolsettings` (
  `SettingId` int(11) NOT NULL,
  `SchoolName` varchar(200) NOT NULL,
  `Address` varchar(300) NOT NULL,
  `Motto` varchar(300) NOT NULL,
  `PublicBaseUrl` varchar(300) NOT NULL DEFAULT '',
  `PresidentName` varchar(160) NOT NULL DEFAULT '',
  `PresidentSignature` longtext NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `idcard_persons`
--

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
  `student_id` int(10) UNSIGNED DEFAULT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `instructors`
--

CREATE TABLE `instructors` (
  `instructor_id` int(10) UNSIGNED NOT NULL,
  `instructor_uid` varchar(40) DEFAULT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `employee_number` varchar(50) DEFAULT NULL,
  `department_id` int(10) UNSIGNED DEFAULT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `lms_assignments`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `lms_discussion_posts`
--

CREATE TABLE `lms_discussion_posts` (
  `id` char(36) NOT NULL,
  `topic_id` char(36) NOT NULL,
  `author_id` varchar(40) NOT NULL,
  `body` text NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lms_discussion_topics`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `lms_materials`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `lms_quizzes`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `lms_quiz_answer_keys`
--

CREATE TABLE `lms_quiz_answer_keys` (
  `question_id` char(36) NOT NULL,
  `correct_answer` text NOT NULL,
  `case_sensitive` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lms_quiz_attempts`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `lms_quiz_questions`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `lms_registration_applications`
--

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
  `year_level` tinyint(3) UNSIGNED DEFAULT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `lms_registration_class_links`
--

CREATE TABLE `lms_registration_class_links` (
  `application_id` char(36) NOT NULL,
  `class_id` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lms_submissions`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `lms_sync_logs`
--

CREATE TABLE `lms_sync_logs` (
  `id` char(36) NOT NULL,
  `initiated_by` varchar(40) DEFAULT NULL,
  `status` enum('running','success','failed') NOT NULL,
  `records` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`records`)),
  `message` text DEFAULT NULL,
  `started_at` datetime NOT NULL DEFAULT current_timestamp(),
  `completed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maint_assets`
--

CREATE TABLE `maint_assets` (
  `asset_id` int(10) UNSIGNED NOT NULL,
  `location_id` int(10) UNSIGNED NOT NULL,
  `asset_name` varchar(150) NOT NULL,
  `asset_type` varchar(20) NOT NULL,
  `asset_tag` varchar(50) DEFAULT NULL,
  `serial_number` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maint_attachments`
--

CREATE TABLE `maint_attachments` (
  `attachment_id` int(10) UNSIGNED NOT NULL,
  `request_id` int(10) UNSIGNED DEFAULT NULL,
  `update_id` int(10) UNSIGNED DEFAULT NULL,
  `finding_id` int(10) UNSIGNED DEFAULT NULL,
  `uploaded_by_employee_id` varchar(64) NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `uploaded_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maint_employees`
--

CREATE TABLE `maint_employees` (
  `employee_id` varchar(64) NOT NULL,
  `user_id` int(10) UNSIGNED DEFAULT NULL,
  `full_name` varchar(150) DEFAULT NULL COMMENT 'Fallback for personnel without a central user account',
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ;

-- --------------------------------------------------------

--
-- Table structure for table `maint_inspections`
--

CREATE TABLE `maint_inspections` (
  `inspection_id` int(10) UNSIGNED NOT NULL,
  `inspection_title` varchar(150) NOT NULL,
  `inspection_date` date NOT NULL,
  `personnel_employee_id` varchar(64) NOT NULL,
  `created_by_employee_id` varchar(64) NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'Scheduled',
  `reviewed_by_employee_id` varchar(64) DEFAULT NULL,
  `review_remarks` text DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maint_inspection_findings`
--

CREATE TABLE `maint_inspection_findings` (
  `finding_id` int(10) UNSIGNED NOT NULL,
  `inspection_id` int(10) UNSIGNED NOT NULL,
  `asset_id` int(10) UNSIGNED NOT NULL,
  `condition_result` varchar(20) NOT NULL DEFAULT 'Not Inspected',
  `findings` text DEFAULT NULL,
  `request_id` int(10) UNSIGNED DEFAULT NULL,
  `inspected_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maint_locations`
--

CREATE TABLE `maint_locations` (
  `location_id` int(10) UNSIGNED NOT NULL,
  `building_name` varchar(100) NOT NULL,
  `floor_name` varchar(50) DEFAULT NULL,
  `room_or_area` varchar(100) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maint_maintenance_administrators`
--

CREATE TABLE `maint_maintenance_administrators` (
  `employee_id` varchar(64) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `granted_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maint_maintenance_requests`
--

CREATE TABLE `maint_maintenance_requests` (
  `request_id` int(10) UNSIGNED NOT NULL,
  `asset_id` int(10) UNSIGNED DEFAULT NULL,
  `reported_location_id` int(10) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `maint_repair_updates`
--

CREATE TABLE `maint_repair_updates` (
  `update_id` int(10) UNSIGNED NOT NULL,
  `request_id` int(10) UNSIGNED NOT NULL,
  `updated_by_employee_id` varchar(64) NOT NULL,
  `update_type` varchar(30) NOT NULL,
  `remarks` text NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maint_request_comments`
--

CREATE TABLE `maint_request_comments` (
  `comment_id` int(10) UNSIGNED NOT NULL,
  `request_id` int(10) UNSIGNED NOT NULL,
  `employee_id` varchar(64) NOT NULL,
  `comment_text` text NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `module_code` varchar(40) NOT NULL,
  `title` varchar(200) NOT NULL,
  `message` text NOT NULL,
  `link_url` varchar(255) DEFAULT NULL,
  `reference_type` varchar(60) DEFAULT NULL,
  `reference_id` bigint(20) UNSIGNED DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_companies`
--

CREATE TABLE `ojt_companies` (
  `company_id` int(10) UNSIGNED NOT NULL,
  `company_name` varchar(150) NOT NULL,
  `address` text NOT NULL,
  `contact_person` varchar(100) DEFAULT NULL,
  `contact_number` varchar(15) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `industry` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_daily_time_records`
--

CREATE TABLE `ojt_daily_time_records` (
  `dtr_id` int(10) UNSIGNED NOT NULL,
  `assignment_id` int(10) UNSIGNED NOT NULL,
  `date` date NOT NULL,
  `time_in` time NOT NULL,
  `time_out` time NOT NULL,
  `total_hours` decimal(5,2) NOT NULL,
  `remarks` text DEFAULT NULL,
  `status` enum('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending',
  `verified_by` int(10) UNSIGNED DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `verification_remarks` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_documents`
--

CREATE TABLE `ojt_documents` (
  `document_id` int(10) UNSIGNED NOT NULL,
  `assignment_id` int(10) UNSIGNED NOT NULL,
  `document_type` varchar(100) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `uploaded_by` int(10) UNSIGNED NOT NULL,
  `status` enum('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `remarks` text DEFAULT NULL,
  `uploaded_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_dtr_breaks`
--

CREATE TABLE `ojt_dtr_breaks` (
  `dtr_id` int(10) UNSIGNED NOT NULL,
  `break_minutes` smallint(5) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_evaluations`
--

CREATE TABLE `ojt_evaluations` (
  `evaluation_id` int(10) UNSIGNED NOT NULL,
  `assignment_id` int(10) UNSIGNED NOT NULL,
  `supervisor_id` int(10) UNSIGNED NOT NULL,
  `evaluation_date` date NOT NULL,
  `total_score` decimal(5,2) NOT NULL,
  `remarks` text DEFAULT NULL,
  `status` enum('Submitted','Reviewed','Approved') NOT NULL DEFAULT 'Submitted',
  `reviewed_by` int(10) UNSIGNED DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_evaluation_criteria`
--

CREATE TABLE `ojt_evaluation_criteria` (
  `criterion_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(120) NOT NULL,
  `weight` decimal(6,2) NOT NULL DEFAULT 1.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_evaluation_drafts`
--

CREATE TABLE `ojt_evaluation_drafts` (
  `assignment_id` int(10) UNSIGNED NOT NULL,
  `supervisor_id` int(10) UNSIGNED NOT NULL,
  `scores_json` text NOT NULL,
  `remarks` text DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_evaluation_scores`
--

CREATE TABLE `ojt_evaluation_scores` (
  `score_id` int(10) UNSIGNED NOT NULL,
  `evaluation_id` int(10) UNSIGNED NOT NULL,
  `criterion_id` int(10) UNSIGNED NOT NULL,
  `score` decimal(4,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_internship_assignments`
--

CREATE TABLE `ojt_internship_assignments` (
  `assignment_id` int(10) UNSIGNED NOT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `company_id` int(10) UNSIGNED NOT NULL,
  `supervisor_id` int(10) UNSIGNED NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `required_hours` int(11) NOT NULL,
  `schedule_details` varchar(255) DEFAULT NULL,
  `status` enum('Ongoing','Completed','Terminated','Pending') NOT NULL DEFAULT 'Pending',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_password_reset_requests`
--

CREATE TABLE `ojt_password_reset_requests` (
  `request_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `status` enum('Pending','Resolved') NOT NULL DEFAULT 'Pending',
  `requested_at` datetime NOT NULL DEFAULT current_timestamp(),
  `resolved_at` datetime DEFAULT NULL,
  `resolved_by` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_progress_attachments`
--

CREATE TABLE `ojt_progress_attachments` (
  `progress_id` int(10) UNSIGNED NOT NULL,
  `document_id` int(10) UNSIGNED NOT NULL,
  `title` varchar(150) NOT NULL,
  `note` text DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_progress_reports`
--

CREATE TABLE `ojt_progress_reports` (
  `progress_id` int(10) UNSIGNED NOT NULL,
  `assignment_id` int(10) UNSIGNED NOT NULL,
  `week_start` date NOT NULL,
  `week_end` date NOT NULL,
  `accomplishments` text NOT NULL,
  `challenges` text DEFAULT NULL,
  `next_plan` text DEFAULT NULL,
  `status` enum('Pending','Reviewed','Revision Required') NOT NULL DEFAULT 'Pending',
  `feedback` text DEFAULT NULL,
  `reviewed_by` int(10) UNSIGNED DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_required_documents`
--

CREATE TABLE `ojt_required_documents` (
  `requirement_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ojt_supervisors`
--

CREATE TABLE `ojt_supervisors` (
  `supervisor_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `company_id` int(10) UNSIGNED NOT NULL,
  `position` varchar(100) NOT NULL,
  `contact_number` varchar(15) NOT NULL,
  `is_verified` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pre_enrollments`
--

CREATE TABLE `pre_enrollments` (
  `pre_enrollment_id` int(10) UNSIGNED NOT NULL,
  `reference_no` varchar(35) NOT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `program_id` int(10) UNSIGNED NOT NULL,
  `period_id` int(10) UNSIGNED NOT NULL,
  `year_level` tinyint(3) UNSIGNED NOT NULL,
  `application_status` varchar(40) NOT NULL DEFAULT 'Submitted',
  `is_eligible` tinyint(1) NOT NULL DEFAULT 0,
  `review_status` enum('Pending','Cleared','On Hold','Rejected') NOT NULL DEFAULT 'Pending',
  `reviewed_by` int(10) UNSIGNED DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `review_remarks` varchar(255) DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pre_enrollment_subjects`
--

CREATE TABLE `pre_enrollment_subjects` (
  `pre_enrollment_subject_id` int(10) UNSIGNED NOT NULL,
  `pre_enrollment_id` int(10) UNSIGNED NOT NULL,
  `subject_id` int(10) UNSIGNED NOT NULL,
  `subject_status` varchar(32) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `programs`
--

CREATE TABLE `programs` (
  `program_id` int(10) UNSIGNED NOT NULL,
  `program_code` varchar(20) NOT NULL,
  `program_name` varchar(150) NOT NULL,
  `department_id` int(10) UNSIGNED DEFAULT NULL,
  `authority_to_operate` varchar(150) DEFAULT NULL,
  `authority_reference` varchar(120) DEFAULT NULL,
  `date_approved` date DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `program_uid` varchar(40) DEFAULT NULL,
  `education_level` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `readmit_applications`
--

CREATE TABLE `readmit_applications` (
  `id` varchar(40) NOT NULL,
  `seq` bigint(20) NOT NULL,
  `reference_no` varchar(30) NOT NULL,
  `applicant_id` varchar(40) NOT NULL,
  `program_id` int(10) UNSIGNED DEFAULT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `readmit_application_history`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `readmit_documents`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `readmit_requirements`
--

CREATE TABLE `readmit_requirements` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT 0,
  `active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `report_exports`
--

CREATE TABLE `report_exports` (
  `report_id` bigint(20) UNSIGNED NOT NULL,
  `generated_by` int(10) UNSIGNED DEFAULT NULL,
  `report_name` varchar(150) NOT NULL,
  `report_format` enum('PDF','Excel','CSV') NOT NULL,
  `filters_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`filters_json`)),
  `record_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `file_path` varchar(255) DEFAULT NULL,
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `schema_migrations`
--

CREATE TABLE `schema_migrations` (
  `migration_id` bigint(20) UNSIGNED NOT NULL,
  `module_code` varchar(40) NOT NULL,
  `migration_name` varchar(200) NOT NULL,
  `batch` int(11) NOT NULL DEFAULT 1,
  `applied_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_application_documents`
--

CREATE TABLE `scholar_application_documents` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `scholarship_application_id` bigint(20) UNSIGNED NOT NULL,
  `scholarship_requirement_id` bigint(20) UNSIGNED DEFAULT NULL,
  `document_name` varchar(200) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_type` varchar(20) DEFAULT NULL,
  `file_size` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `verification_status` varchar(30) NOT NULL DEFAULT 'pending',
  `verification_notes` text DEFAULT NULL,
  `verified_by` int(10) UNSIGNED DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `storage_disk` varchar(20) NOT NULL DEFAULT 'local',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `document_category` varchar(40) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_application_evaluations`
--

CREATE TABLE `scholar_application_evaluations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `scholarship_application_id` bigint(20) UNSIGNED NOT NULL,
  `evaluator_id` int(10) UNSIGNED NOT NULL,
  `score` tinyint(3) UNSIGNED DEFAULT NULL,
  `recommendation` varchar(40) NOT NULL DEFAULT 'pending',
  `evaluation_notes` text DEFAULT NULL,
  `evaluated_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_application_status_histories`
--

CREATE TABLE `scholar_application_status_histories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `scholarship_application_id` bigint(20) UNSIGNED NOT NULL,
  `from_status` varchar(40) DEFAULT NULL,
  `to_status` varchar(40) NOT NULL,
  `changed_by` int(10) UNSIGNED DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_cache`
--

CREATE TABLE `scholar_cache` (
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_cache_locks`
--

CREATE TABLE `scholar_cache_locks` (
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_document_reviews`
--

CREATE TABLE `scholar_document_reviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `application_document_id` bigint(20) UNSIGNED NOT NULL,
  `reviewed_by` int(10) UNSIGNED NOT NULL,
  `status` varchar(30) NOT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_eligibility_results`
--

CREATE TABLE `scholar_eligibility_results` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `scholarship_application_id` bigint(20) UNSIGNED NOT NULL,
  `checked_by` int(10) UNSIGNED DEFAULT NULL,
  `result` varchar(30) NOT NULL DEFAULT 'manual_review',
  `reasons` text DEFAULT NULL,
  `checked_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_eligibility_rules`
--

CREATE TABLE `scholar_eligibility_rules` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `scholarship_program_id` bigint(20) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `scholar_failed_jobs`
--

CREATE TABLE `scholar_failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_household_profiles`
--

CREATE TABLE `scholar_household_profiles` (
  `student_id` int(10) UNSIGNED NOT NULL,
  `household_size` smallint(5) UNSIGNED DEFAULT NULL,
  `monthly_household_income` decimal(12,2) DEFAULT NULL,
  `last_verified_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_jobs`
--

CREATE TABLE `scholar_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_job_batches`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `scholar_password_reset_tokens`
--

CREATE TABLE `scholar_password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_personal_access_tokens`
--

CREATE TABLE `scholar_personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_renewal_applications`
--

CREATE TABLE `scholar_renewal_applications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `renewal_no` varchar(30) NOT NULL,
  `scholarship_award_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `academic_year` varchar(20) NOT NULL,
  `statement` text DEFAULT NULL,
  `form_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`form_data`)),
  `status` varchar(30) NOT NULL DEFAULT 'draft',
  `remarks` text DEFAULT NULL,
  `decided_by` int(10) UNSIGNED DEFAULT NULL,
  `decided_at` timestamp NULL DEFAULT NULL,
  `submitted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_scholarship_appeals`
--

CREATE TABLE `scholar_scholarship_appeals` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `appeal_no` varchar(40) NOT NULL,
  `scholarship_award_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `award_status_version` int(10) UNSIGNED NOT NULL,
  `award_status` varchar(30) NOT NULL,
  `status_reason` text DEFAULT NULL,
  `statement` text NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'submitted',
  `pending_slot` tinyint(3) UNSIGNED DEFAULT 1,
  `decision_reason` text DEFAULT NULL,
  `decided_by` int(10) UNSIGNED DEFAULT NULL,
  `decided_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_scholarship_applications`
--

CREATE TABLE `scholar_scholarship_applications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `application_no` varchar(30) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `scholarship_program_id` bigint(20) UNSIGNED NOT NULL,
  `assigned_to` int(10) UNSIGNED DEFAULT NULL,
  `academic_year` varchar(20) NOT NULL DEFAULT '2026-2027',
  `status` varchar(40) NOT NULL DEFAULT 'draft',
  `enrollment_status` varchar(30) DEFAULT NULL,
  `statement` text DEFAULT NULL,
  `form_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`form_data`)),
  `guardian_name` varchar(200) DEFAULT NULL,
  `guardian_occupation` varchar(150) DEFAULT NULL,
  `household_size` smallint(5) UNSIGNED DEFAULT NULL,
  `monthly_household_income` decimal(12,2) DEFAULT NULL,
  `submitted_at` timestamp NULL DEFAULT NULL,
  `decided_at` timestamp NULL DEFAULT NULL,
  `decided_by` int(10) UNSIGNED DEFAULT NULL,
  `decision_remarks` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `last_saved_step` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `declaration_accepted_at` timestamp NULL DEFAULT NULL,
  `form_version` varchar(40) DEFAULT NULL,
  `adfc_form` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`adfc_form`)),
  `form_review` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`form_review`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_scholarship_awards`
--

CREATE TABLE `scholar_scholarship_awards` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `award_no` varchar(30) NOT NULL,
  `scholarship_application_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `scholarship_program_id` bigint(20) UNSIGNED NOT NULL,
  `benefits` text DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `recipient_status` varchar(30) NOT NULL DEFAULT 'active',
  `remarks` text DEFAULT NULL,
  `awarded_by` int(10) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `status_reason` text DEFAULT NULL,
  `status_changed_at` timestamp NULL DEFAULT NULL,
  `status_version` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_scholarship_programs`
--

CREATE TABLE `scholar_scholarship_programs` (
  `id` bigint(20) UNSIGNED NOT NULL,
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
  `slots` int(10) UNSIGNED DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'draft',
  `created_by` int(10) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scholar_scholarship_requirements`
--

CREATE TABLE `scholar_scholarship_requirements` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `scholarship_program_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT 1,
  `allowed_types` varchar(100) NOT NULL DEFAULT 'pdf,jpg,jpeg,png',
  `max_size_kb` int(10) UNSIGNED NOT NULL DEFAULT 5120,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sch_class_meetings`
--

CREATE TABLE `sch_class_meetings` (
  `meeting_id` bigint(20) UNSIGNED NOT NULL,
  `class_id` bigint(20) UNSIGNED NOT NULL,
  `room_id` int(10) UNSIGNED NOT NULL,
  `class_type` enum('LEC','LAB') NOT NULL DEFAULT 'LEC',
  `day_of_week` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday') NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `status` enum('Draft','Published','Conflict','Cancelled') NOT NULL DEFAULT 'Draft',
  `created_by` int(10) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `sch_instructor_load_settings`
--

CREATE TABLE `sch_instructor_load_settings` (
  `instructor_id` int(10) UNSIGNED NOT NULL,
  `max_units` tinyint(3) UNSIGNED NOT NULL DEFAULT 21,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sch_rooms`
--

CREATE TABLE `sch_rooms` (
  `room_id` int(10) UNSIGNED NOT NULL,
  `room_code` varchar(30) NOT NULL,
  `maintenance_location_id` int(10) UNSIGNED DEFAULT NULL,
  `building_description` varchar(80) DEFAULT NULL COMMENT 'Used if no maintenance location record is linked',
  `room_type` enum('Lecture','Laboratory','AVR') NOT NULL DEFAULT 'Lecture',
  `capacity` smallint(5) UNSIGNED NOT NULL DEFAULT 40,
  `operational_status` enum('Active','Maintenance','Inactive') NOT NULL DEFAULT 'Active'
) ;

-- --------------------------------------------------------

--
-- Table structure for table `sch_sync_queue`
--

CREATE TABLE `sch_sync_queue` (
  `queue_id` bigint(20) UNSIGNED NOT NULL,
  `operation_type` enum('INSERT','UPDATE','DELETE') NOT NULL DEFAULT 'INSERT',
  `target_table` varchar(60) NOT NULL DEFAULT 'sch_class_meetings',
  `payload_json` mediumtext NOT NULL,
  `queued_by_user_id` int(10) UNSIGNED DEFAULT NULL,
  `is_synced` tinyint(1) NOT NULL DEFAULT 0,
  `queued_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `synced_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `staff_profiles`
--

CREATE TABLE `staff_profiles` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `admin_number` varchar(40) DEFAULT NULL,
  `admin_level` varchar(50) DEFAULT NULL,
  `job_title` varchar(120) DEFAULT NULL,
  `office` varchar(120) DEFAULT NULL,
  `department_id` int(10) UNSIGNED DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

CREATE TABLE `students` (
  `student_id` int(10) UNSIGNED NOT NULL,
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

-- --------------------------------------------------------

--
-- Table structure for table `student_contacts`
--

CREATE TABLE `student_contacts` (
  `contact_id` int(10) UNSIGNED NOT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `contact_role` enum('Guardian','Father','Mother','Emergency') NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `relationship` varchar(60) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `occupation` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `student_documents`
--

CREATE TABLE `student_documents` (
  `document_id` bigint(20) UNSIGNED NOT NULL,
  `student_id` int(10) UNSIGNED NOT NULL,
  `document_type` varchar(60) NOT NULL,
  `original_filename` varchar(180) NOT NULL,
  `mime_type` enum('application/pdf','image/jpeg','image/png') NOT NULL,
  `file_size` int(10) UNSIGNED NOT NULL,
  `file_blob` mediumblob NOT NULL,
  `uploaded_by` int(10) UNSIGNED DEFAULT NULL,
  `verification_status` enum('Pending','Verified','Needs Resubmission') NOT NULL DEFAULT 'Pending',
  `verified_by` int(10) UNSIGNED DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `verification_remarks` varchar(255) DEFAULT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `student_first_enrollments`
--

CREATE TABLE `student_first_enrollments` (
  `student_id` int(10) UNSIGNED NOT NULL,
  `first_enrolled_on` date NOT NULL,
  `first_program_id` int(10) UNSIGNED NOT NULL,
  `first_period_id` int(10) UNSIGNED NOT NULL,
  `first_year_level` tinyint(3) UNSIGNED NOT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `recorded_by` int(10) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

CREATE TABLE `subjects` (
  `subject_id` int(10) UNSIGNED NOT NULL,
  `program_id` int(10) UNSIGNED DEFAULT NULL,
  `subject_code` varchar(20) NOT NULL,
  `subject_title` varchar(150) NOT NULL,
  `units` decimal(4,1) NOT NULL DEFAULT 0.0,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `subject_uid` varchar(40) DEFAULT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--

CREATE TABLE `system_settings` (
  `setting_id` bigint(20) UNSIGNED NOT NULL,
  `module_code` varchar(40) NOT NULL,
  `setting_key` varchar(150) NOT NULL,
  `setting_value` longtext DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `user_uid` varchar(40) DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `email` varchar(190) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(190) NOT NULL,
  `status` enum('Active','Inactive','Pending','Disabled','Suspended') NOT NULL DEFAULT 'Active',
  `student_id` int(10) UNSIGNED DEFAULT NULL,
  `last_login` datetime DEFAULT NULL,
  `email_verified_at` datetime DEFAULT NULL,
  `must_change_password` tinyint(1) NOT NULL DEFAULT 0,
  `session_version` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_access_roles`
--

CREATE TABLE `user_access_roles` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `role_id` int(10) UNSIGNED NOT NULL,
  `module_code` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_mfa_methods`
--

CREATE TABLE `user_mfa_methods` (
  `mfa_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `method` varchar(40) NOT NULL,
  `secret_encrypted` text NOT NULL,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_profiles`
--

CREATE TABLE `user_profiles` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `avatar_path` varchar(255) DEFAULT NULL,
  `profile_photo` mediumblob DEFAULT NULL,
  `profile_photo_mime` varchar(100) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure for view `admin_users`
--
DROP TABLE IF EXISTS `admin_users`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `admin_users`  AS SELECT `u`.`user_id` AS `admin_user_id`, `u`.`username` AS `username`, `u`.`email` AS `email`, `u`.`password_hash` AS `password_hash`, `u`.`full_name` AS `full_name`, CASE WHEN exists(select 1 from (`user_access_roles` `ur_admin` join `access_roles` `ar_admin` on(`ar_admin`.`role_id` = `ur_admin`.`role_id`)) where `ur_admin`.`user_id` = `u`.`user_id` AND lcase(`ur_admin`.`module_code`) in ('enrollment','enrollment_management','enrollment-management') AND `ar_admin`.`role_name` = 'Administrator' limit 1) THEN 'Administrator' ELSE 'Enrollment Personnel' END AS `role`, `u`.`status` AS `status`, `u`.`last_login` AS `last_login`, `u`.`created_at` AS `created_at`, `u`.`updated_at` AS `updated_at` FROM `users` AS `u` WHERE exists(select 1 from (`user_access_roles` `ur` join `access_roles` `ar` on(`ar`.`role_id` = `ur`.`role_id`)) where `ur`.`user_id` = `u`.`user_id` AND lcase(`ur`.`module_code`) in ('enrollment','enrollment_management','enrollment-management') AND `ar`.`role_name` in ('Administrator','Enrollment Personnel') limit 1) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `academic_classes`
--
ALTER TABLE `academic_classes`
  ADD PRIMARY KEY (`class_id`),
  ADD UNIQUE KEY `class_uid` (`class_uid`),
  ADD UNIQUE KEY `uq_academic_class_code_period` (`class_code`,`period_id`),
  ADD KEY `fk_shared_class_program` (`program_id`),
  ADD KEY `fk_shared_class_subject` (`subject_id`),
  ADD KEY `fk_shared_class_period` (`period_id`),
  ADD KEY `fk_shared_class_instructor` (`instructor_id`);

--
-- Indexes for table `academic_periods`
--
ALTER TABLE `academic_periods`
  ADD PRIMARY KEY (`period_id`),
  ADD UNIQUE KEY `uq_period` (`academic_year`,`semester`);

--
-- Indexes for table `access_permissions`
--
ALTER TABLE `access_permissions`
  ADD PRIMARY KEY (`permission_id`),
  ADD UNIQUE KEY `permission_code` (`permission_code`);

--
-- Indexes for table `access_roles`
--
ALTER TABLE `access_roles`
  ADD PRIMARY KEY (`role_id`),
  ADD UNIQUE KEY `role_name` (`role_name`);

--
-- Indexes for table `access_role_permissions`
--
ALTER TABLE `access_role_permissions`
  ADD PRIMARY KEY (`role_id`,`permission_id`),
  ADD KEY `fk_access_permission` (`permission_id`);

--
-- Indexes for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `fk_log_admin` (`admin_user_id`);

--
-- Indexes for table `admit_applicants`
--
ALTER TABLE `admit_applicants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `reference_code` (`reference_code`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `admit_evaluations`
--
ALTER TABLE `admit_evaluations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_admit_evaluations_0_admit_applicants` (`applicant_id`),
  ADD KEY `fk_admit_evaluations_1_users` (`evaluator_id`);

--
-- Indexes for table `admit_interviews`
--
ALTER TABLE `admit_interviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_admit_interviews_0_admit_applicants` (`applicant_id`),
  ADD KEY `fk_admit_interviews_1_users` (`interviewer_id`),
  ADD KEY `fk_admit_interviews_2_admit_interview_slots` (`slot_id`);

--
-- Indexes for table `admit_interview_slots`
--
ALTER TABLE `admit_interview_slots`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_admit_interview_slots_0_users` (`interviewer_id`);

--
-- Indexes for table `announcements`
--
ALTER TABLE `announcements`
  ADD PRIMARY KEY (`announcement_id`),
  ADD KEY `fk_shared_announcement_by` (`created_by`),
  ADD KEY `fk_shared_announcement_class` (`class_id`);

--
-- Indexes for table `attend_approval_requests`
--
ALTER TABLE `attend_approval_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_appr_user` (`username`,`status`),
  ADD KEY `ix_appr_status` (`status`);

--
-- Indexes for table `attend_attendance_records`
--
ALTER TABLE `attend_attendance_records`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_att` (`student_id`,`schedule_id`,`att_date`),
  ADD KEY `ix_date` (`att_date`),
  ADD KEY `ix_student` (`student_id`,`att_date`);

--
-- Indexes for table `attend_attendance_sessions`
--
ALTER TABLE `attend_attendance_sessions`
  ADD PRIMARY KEY (`schedule_id`,`att_date`);

--
-- Indexes for table `attend_email_sent`
--
ALTER TABLE `attend_email_sent`
  ADD PRIMARY KEY (`record_id`,`to_addr`);

--
-- Indexes for table `attend_face_templates`
--
ALTER TABLE `attend_face_templates`
  ADD PRIMARY KEY (`member_id`);

--
-- Indexes for table `attend_members`
--
ALTER TABLE `attend_members`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `student_id` (`student_id`),
  ADD KEY `ix_role` (`role`),
  ADD KEY `ix_email` (`email`),
  ADD KEY `fk_attend_member_user` (`user_id`);

--
-- Indexes for table `attend_member_files`
--
ALTER TABLE `attend_member_files`
  ADD PRIMARY KEY (`owner`,`kind`);

--
-- Indexes for table `attend_notification_log`
--
ALTER TABLE `attend_notification_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_created` (`created_at`);

--
-- Indexes for table `attend_notify_queue`
--
ALTER TABLE `attend_notify_queue`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_notify` (`channel`,`record_id`,`recipient`,`att_status`),
  ADD KEY `ix_notify_due` (`state`,`due_at`),
  ADD KEY `ix_notify_created` (`created_at`);

--
-- Indexes for table `attend_password_resets`
--
ALTER TABLE `attend_password_resets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_inst` (`instructor_id`,`used`,`expires_at`);

--
-- Indexes for table `attend_school_data`
--
ALTER TABLE `attend_school_data`
  ADD PRIMARY KEY (`part`);

--
-- Indexes for table `auth_sessions`
--
ALTER TABLE `auth_sessions`
  ADD PRIMARY KEY (`session_id`),
  ADD UNIQUE KEY `token_hash` (`token_hash`),
  ADD KEY `fk_shared_auth_user` (`user_id`);

--
-- Indexes for table `billing_adjustments`
--
ALTER TABLE `billing_adjustments`
  ADD PRIMARY KEY (`adjustment_id`),
  ADD UNIQUE KEY `uq_bil_adj_uid` (`adjustment_uid`),
  ADD KEY `ix_bil_adj_student` (`student_id`),
  ADD KEY `ix_bil_adj_enroll` (`enrollment_id`),
  ADD KEY `ix_bil_adj_actor` (`created_by_user_id`);

--
-- Indexes for table `billing_discounts`
--
ALTER TABLE `billing_discounts`
  ADD PRIMARY KEY (`discount_id`),
  ADD UNIQUE KEY `uq_bil_disc_name` (`name`);

--
-- Indexes for table `billing_enrollment_discounts`
--
ALTER TABLE `billing_enrollment_discounts`
  ADD PRIMARY KEY (`enrollment_discount_id`),
  ADD UNIQUE KEY `uq_bil_enr_disc_name` (`enrollment_id`,`name_snapshot`),
  ADD KEY `ix_bil_disc_catalog` (`discount_id`);

--
-- Indexes for table `billing_enrollment_inbox`
--
ALTER TABLE `billing_enrollment_inbox`
  ADD PRIMARY KEY (`inbox_id`),
  ADD KEY `ix_bil_inbox_enroll` (`enrollment_id`),
  ADD KEY `ix_bil_inbox_student` (`student_id`),
  ADD KEY `ix_bil_inbox_status` (`status`),
  ADD KEY `ix_bil_inbox_received` (`received_at`);

--
-- Indexes for table `billing_enrollment_plans`
--
ALTER TABLE `billing_enrollment_plans`
  ADD PRIMARY KEY (`enrollment_id`),
  ADD UNIQUE KEY `uq_bil_plan_uid` (`billing_uid`);

--
-- Indexes for table `billing_enrollment_subject_details`
--
ALTER TABLE `billing_enrollment_subject_details`
  ADD PRIMARY KEY (`enrollment_subject_id`);

--
-- Indexes for table `billing_fee_rules`
--
ALTER TABLE `billing_fee_rules`
  ADD PRIMARY KEY (`fee_id`);

--
-- Indexes for table `billing_invoices`
--
ALTER TABLE `billing_invoices`
  ADD PRIMARY KEY (`invoice_id`),
  ADD UNIQUE KEY `uq_bil_invoice_uid` (`invoice_uid`),
  ADD KEY `ix_bil_invoice_student` (`student_id`),
  ADD KEY `ix_bil_invoice_enroll` (`enrollment_id`);

--
-- Indexes for table `billing_online_payments`
--
ALTER TABLE `billing_online_payments`
  ADD PRIMARY KEY (`online_payment_id`),
  ADD UNIQUE KEY `uq_bil_online_session` (`session_id`),
  ADD UNIQUE KEY `uq_bil_online_reference` (`reference`),
  ADD KEY `ix_bil_online_student` (`student_id`),
  ADD KEY `ix_bil_online_enroll` (`enrollment_id`),
  ADD KEY `ix_bil_online_payment` (`payment_id`),
  ADD KEY `ix_bil_online_status` (`status`);

--
-- Indexes for table `billing_payments`
--
ALTER TABLE `billing_payments`
  ADD PRIMARY KEY (`payment_id`),
  ADD UNIQUE KEY `uq_bil_payment_uid` (`payment_uid`),
  ADD KEY `ix_bil_payment_student` (`student_id`),
  ADD KEY `ix_bil_payment_enroll` (`enrollment_id`),
  ADD KEY `ix_bil_payment_receiver` (`received_by_user_id`);

--
-- Indexes for table `billing_payment_requests`
--
ALTER TABLE `billing_payment_requests`
  ADD PRIMARY KEY (`request_id`),
  ADD KEY `ix_bil_req_student` (`student_id`),
  ADD KEY `ix_bil_req_enrollment` (`enrollment_id`),
  ADD KEY `ix_bil_req_status` (`status`),
  ADD KEY `ix_bil_req_payment` (`payment_id`),
  ADD KEY `ix_bil_req_reviewer` (`reviewed_by_user_id`);

--
-- Indexes for table `billing_settings`
--
ALTER TABLE `billing_settings`
  ADD PRIMARY KEY (`k`);

--
-- Indexes for table `billing_term_schedules`
--
ALTER TABLE `billing_term_schedules`
  ADD PRIMARY KEY (`period_id`);

--
-- Indexes for table `blocks`
--
ALTER TABLE `blocks`
  ADD PRIMARY KEY (`block_id`),
  ADD UNIQUE KEY `uq_block` (`program_id`,`period_id`,`year_level`,`block_code`),
  ADD KEY `fk_block_period` (`period_id`);

--
-- Indexes for table `campusfind_claims`
--
ALTER TABLE `campusfind_claims`
  ADD PRIMARY KEY (`campusfind_claim_id`),
  ADD KEY `idx_campusfind_claims_status` (`campusfind_status`),
  ADD KEY `idx_campusfind_claims_item` (`campusfind_item_id`),
  ADD KEY `idx_campusfind_claims_claimant` (`campusfind_claimant_user_id`),
  ADD KEY `idx_campusfind_claims_reviewer` (`campusfind_reviewer_user_id`),
  ADD KEY `idx_campusfind_claims_created` (`campusfind_created_at`);

--
-- Indexes for table `campusfind_items`
--
ALTER TABLE `campusfind_items`
  ADD PRIMARY KEY (`campusfind_item_id`),
  ADD KEY `idx_campusfind_items_browse` (`campusfind_item_type`,`campusfind_status`,`campusfind_category`),
  ADD KEY `idx_campusfind_items_reporter` (`campusfind_reporter_user_id`),
  ADD KEY `idx_campusfind_items_location` (`campusfind_location`),
  ADD KEY `idx_campusfind_items_date` (`campusfind_item_date`),
  ADD KEY `idx_campusfind_items_created` (`campusfind_created_at`);

--
-- Indexes for table `campusfind_live_revisions`
--
ALTER TABLE `campusfind_live_revisions`
  ADD PRIMARY KEY (`campusfind_resource`);

--
-- Indexes for table `campusfind_section_views`
--
ALTER TABLE `campusfind_section_views`
  ADD PRIMARY KEY (`campusfind_user_id`,`campusfind_section_key`);

--
-- Indexes for table `cebrms_borrowers`
--
ALTER TABLE `cebrms_borrowers`
  ADD PRIMARY KEY (`borrower_id`),
  ADD UNIQUE KEY `uq_cebrms_borrower_no` (`borrower_no`),
  ADD UNIQUE KEY `uq_cebrms_borrower_qr` (`qr_code_value`),
  ADD UNIQUE KEY `uq_cebrms_borrower_user` (`user_id`),
  ADD UNIQUE KEY `uq_cebrms_borrower_student` (`student_id`),
  ADD KEY `ix_cebrms_borrower_department` (`department_id`);

--
-- Indexes for table `cebrms_borrow_items`
--
ALTER TABLE `cebrms_borrow_items`
  ADD PRIMARY KEY (`borrow_item_id`),
  ADD UNIQUE KEY `uq_cebrms_borrow_tx_equipment` (`transaction_id`,`equipment_id`),
  ADD KEY `ix_cebrms_borrow_equipment` (`equipment_id`);

--
-- Indexes for table `cebrms_borrow_transactions`
--
ALTER TABLE `cebrms_borrow_transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD UNIQUE KEY `uq_cebrms_transaction_no` (`transaction_no`),
  ADD UNIQUE KEY `uq_cebrms_transaction_qr` (`qr_code_value`),
  ADD KEY `ix_cebrms_transaction_borrower` (`borrower_id`),
  ADD KEY `ix_cebrms_transaction_processor` (`processed_by`),
  ADD KEY `ix_cebrms_transaction_approver` (`approved_by`),
  ADD KEY `ix_cebrms_transaction_status_due` (`status`,`expected_return_date`);

--
-- Indexes for table `cebrms_equipment`
--
ALTER TABLE `cebrms_equipment`
  ADD PRIMARY KEY (`equipment_id`),
  ADD UNIQUE KEY `uq_cebrms_equipment_code` (`equipment_code`),
  ADD UNIQUE KEY `uq_cebrms_equipment_qr` (`qr_code_value`),
  ADD KEY `ix_cebrms_equipment_category` (`category_id`),
  ADD KEY `ix_cebrms_equipment_asset` (`maintenance_asset_id`);

--
-- Indexes for table `cebrms_equipment_categories`
--
ALTER TABLE `cebrms_equipment_categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `uq_cebrms_equipment_category_name` (`category_name`);

--
-- Indexes for table `cebrms_qr_scan_logs`
--
ALTER TABLE `cebrms_qr_scan_logs`
  ADD PRIMARY KEY (`scan_id`),
  ADD KEY `ix_cebrms_scan_user` (`user_id`),
  ADD KEY `ix_cebrms_scan_time` (`scanned_at`);

--
-- Indexes for table `cebrms_return_records`
--
ALTER TABLE `cebrms_return_records`
  ADD PRIMARY KEY (`return_id`),
  ADD KEY `ix_cebrms_return_item` (`borrow_item_id`),
  ADD KEY `ix_cebrms_return_received_by` (`received_by`);

--
-- Indexes for table `class_enrollments`
--
ALTER TABLE `class_enrollments`
  ADD PRIMARY KEY (`enrollment_id`),
  ADD UNIQUE KEY `uq_class_enrollment_student_class` (`student_id`,`class_id`),
  ADD UNIQUE KEY `uq_class_enrollment_uid` (`enrollment_uid`),
  ADD KEY `ix_class_enrollment_class` (`class_id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`department_id`),
  ADD UNIQUE KEY `department_code` (`department_code`);

--
-- Indexes for table `election_ballots`
--
ALTER TABLE `election_ballots`
  ADD PRIMARY KEY (`ballot_id`),
  ADD KEY `idx_ballots_candidate` (`candidate_id`);

--
-- Indexes for table `election_candidacies`
--
ALTER TABLE `election_candidacies`
  ADD PRIMARY KEY (`candidate_id`),
  ADD UNIQUE KEY `uq_candidacies_user_position` (`user_id`,`position_id`),
  ADD KEY `idx_candidacies_position_status` (`position_id`,`filing_status`),
  ADD KEY `fk_election_candidacies_2_users` (`reviewed_by`);

--
-- Indexes for table `election_candidate_documents`
--
ALTER TABLE `election_candidate_documents`
  ADD PRIMARY KEY (`document_id`),
  ADD KEY `idx_cd_candidate` (`candidate_id`);

--
-- Indexes for table `election_elections`
--
ALTER TABLE `election_elections`
  ADD PRIMARY KEY (`election_id`),
  ADD KEY `fk_election_elections_0_users` (`created_by`);

--
-- Indexes for table `election_face_data`
--
ALTER TABLE `election_face_data`
  ADD PRIMARY KEY (`face_id`),
  ADD KEY `fk_election_face_data_0_users` (`user_id`);

--
-- Indexes for table `election_face_verifications`
--
ALTER TABLE `election_face_verifications`
  ADD PRIMARY KEY (`verification_id`),
  ADD KEY `idx_fv_user_election` (`user_id`,`election_id`),
  ADD KEY `idx_fv_status` (`verification_status`),
  ADD KEY `fk_election_face_verifications_1_election_elections` (`election_id`),
  ADD KEY `fk_election_face_verifications_2_users` (`reviewed_by`);

--
-- Indexes for table `election_positions`
--
ALTER TABLE `election_positions`
  ADD PRIMARY KEY (`position_id`),
  ADD UNIQUE KEY `uq_positions_election_name` (`election_id`,`position_name`);

--
-- Indexes for table `election_results`
--
ALTER TABLE `election_results`
  ADD PRIMARY KEY (`result_id`),
  ADD UNIQUE KEY `uq_results_candidate` (`candidate_id`);

--
-- Indexes for table `election_security_login_attempts`
--
ALTER TABLE `election_security_login_attempts`
  ADD PRIMARY KEY (`attempt_id`),
  ADD KEY `idx_login_email_time` (`email_hash`,`attempted_at`),
  ADD KEY `idx_login_ip_time` (`ip_address`,`attempted_at`);

--
-- Indexes for table `election_security_sessions`
--
ALTER TABLE `election_security_sessions`
  ADD PRIMARY KEY (`session_id`),
  ADD UNIQUE KEY `token_hash` (`token_hash`),
  ADD KEY `idx_security_user` (`user_id`,`revoked_at`);

--
-- Indexes for table `election_vote_records`
--
ALTER TABLE `election_vote_records`
  ADD PRIMARY KEY (`record_id`),
  ADD UNIQUE KEY `uq_vote_records_user_position` (`user_id`,`position_id`),
  ADD KEY `fk_election_vote_records_0_election_positions` (`position_id`);

--
-- Indexes for table `ems_employee_details`
--
ALTER TABLE `ems_employee_details`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uq_ems_employee_code` (`employee_code`);

--
-- Indexes for table `ems_employee_documents`
--
ALTER TABLE `ems_employee_documents`
  ADD PRIMARY KEY (`document_id`),
  ADD KEY `ix_ems_doc_employee` (`employee_user_id`),
  ADD KEY `ix_ems_doc_uploader` (`uploaded_by_user_id`),
  ADD KEY `ix_ems_doc_uploaded` (`uploaded_at`);

--
-- Indexes for table `enrollments`
--
ALTER TABLE `enrollments`
  ADD PRIMARY KEY (`enrollment_id`),
  ADD UNIQUE KEY `uq_enrollment_student_period` (`student_id`,`period_id`),
  ADD UNIQUE KEY `enrollment_number` (`enrollment_number`),
  ADD UNIQUE KEY `pre_enrollment_id` (`pre_enrollment_id`),
  ADD KEY `fk_enroll_program` (`program_id`),
  ADD KEY `fk_enroll_period` (`period_id`),
  ADD KEY `fk_enroll_block` (`block_id`),
  ADD KEY `fk_enroll_verify` (`verified_by`),
  ADD KEY `fk_enroll_confirm` (`confirmed_by`);

--
-- Indexes for table `enrollment_charges`
--
ALTER TABLE `enrollment_charges`
  ADD PRIMARY KEY (`charge_id`),
  ADD UNIQUE KEY `uq_enrollment_charge_fee` (`enrollment_id`,`fee_id`),
  ADD KEY `fk_charge_fee` (`fee_id`);

--
-- Indexes for table `enrollment_subjects`
--
ALTER TABLE `enrollment_subjects`
  ADD PRIMARY KEY (`enrollment_subject_id`),
  ADD UNIQUE KEY `uq_enrolled_subject` (`enrollment_id`,`subject_id`),
  ADD KEY `fk_ensub_subject` (`subject_id`);

--
-- Indexes for table `eteeap_applications`
--
ALTER TABLE `eteeap_applications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_app_user` (`user_id`),
  ADD UNIQUE KEY `uq_app_reference` (`reference_no`),
  ADD KEY `ix_app_status` (`status`);

--
-- Indexes for table `eteeap_assessments`
--
ALTER TABLE `eteeap_assessments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_assess_app` (`application_id`),
  ADD KEY `ix_assessment_assessor` (`assessor_id`,`status`);

--
-- Indexes for table `eteeap_billing_fees`
--
ALTER TABLE `eteeap_billing_fees`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `fk_fee_actor` (`created_by`);

--
-- Indexes for table `eteeap_billing_invoices`
--
ALTER TABLE `eteeap_billing_invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `invoice_no` (`invoice_no`),
  ADD KEY `ix_bill_app` (`application_id`,`status`),
  ADD KEY `fk_bill_fee` (`fee_id`),
  ADD KEY `fk_bill_creator` (`created_by`),
  ADD KEY `fk_bill_void` (`voided_by`);

--
-- Indexes for table `eteeap_billing_payments`
--
ALTER TABLE `eteeap_billing_payments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_bill_reference` (`method`,`external_reference`),
  ADD UNIQUE KEY `receipt_no` (`receipt_no`),
  ADD KEY `ix_bill_pay` (`invoice_id`,`status`),
  ADD KEY `fk_pay_actor` (`recorded_by`),
  ADD KEY `fk_pay_void_actor` (`voided_by`);

--
-- Indexes for table `eteeap_credits`
--
ALTER TABLE `eteeap_credits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_credit_app` (`application_id`),
  ADD KEY `ix_credit_eval` (`evaluator_id`),
  ADD KEY `ix_credit_decider` (`decided_by`);

--
-- Indexes for table `eteeap_education_records`
--
ALTER TABLE `eteeap_education_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_edu_app` (`application_id`);

--
-- Indexes for table `eteeap_employment_records`
--
ALTER TABLE `eteeap_employment_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_work_app` (`application_id`);

--
-- Indexes for table `eteeap_evaluations`
--
ALTER TABLE `eteeap_evaluations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_eval_assessor` (`application_id`,`assessor_id`),
  ADD KEY `ix_eval_assessor` (`assessor_id`);

--
-- Indexes for table `eteeap_form_records`
--
ALTER TABLE `eteeap_form_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `case_forms` (`application_id`,`form_key`);

--
-- Indexes for table `eteeap_grades`
--
ALTER TABLE `eteeap_grades`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_grade_course` (`application_id`,`assessor_id`,`course_name`),
  ADD KEY `fk_grades_assessor` (`assessor_id`);

--
-- Indexes for table `eteeap_login_attempts`
--
ALTER TABLE `eteeap_login_attempts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_login_limit` (`login_key`,`attempted_at`);

--
-- Indexes for table `eteeap_messages`
--
ALTER TABLE `eteeap_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_msg_app` (`application_id`),
  ADD KEY `ix_msg_sender` (`sender_id`);

--
-- Indexes for table `eteeap_portfolio_assessments`
--
ALTER TABLE `eteeap_portfolio_assessments`
  ADD PRIMARY KEY (`assessment_id`);

--
-- Indexes for table `eteeap_portfolio_rubric_forms`
--
ALTER TABLE `eteeap_portfolio_rubric_forms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `applicant_assessor` (`application_id`,`assessor_id`);

--
-- Indexes for table `eteeap_program_offerings`
--
ALTER TABLE `eteeap_program_offerings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `fk_program_actor` (`configured_by`);

--
-- Indexes for table `eteeap_uploads`
--
ALTER TABLE `eteeap_uploads`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_upload_storage` (`storage_name`),
  ADD KEY `ix_upload_requirement` (`application_id`,`kind`,`requirement_key`),
  ADD KEY `ix_upload_user` (`uploaded_by`),
  ADD KEY `ix_upload_previous` (`replaces_upload_id`);

--
-- Indexes for table `eteeap_upload_events`
--
ALTER TABLE `eteeap_upload_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_file_event` (`upload_id`,`created_at`),
  ADD KEY `fk_upload_event_actor` (`actor_id`);

--
-- Indexes for table `event_criteria`
--
ALTER TABLE `event_criteria`
  ADD PRIMARY KEY (`criterion_id`),
  ADD UNIQUE KEY `uq_criteria_uuid` (`record_uuid`),
  ADD UNIQUE KEY `uq_event_criterion_name` (`event_id`,`criterion_name`);

--
-- Indexes for table `event_entries`
--
ALTER TABLE `event_entries`
  ADD PRIMARY KEY (`entry_id`),
  ADD UNIQUE KEY `uq_event_entries_uuid` (`record_uuid`),
  ADD UNIQUE KEY `uq_event_entry_code` (`event_id`,`entry_code`),
  ADD UNIQUE KEY `uq_event_participant` (`event_id`,`participant_id`),
  ADD UNIQUE KEY `uq_event_team` (`event_id`,`team_id`),
  ADD KEY `fk_event_entries_participant` (`participant_id`),
  ADD KEY `fk_event_entries_team` (`team_id`);

--
-- Indexes for table `event_events`
--
ALTER TABLE `event_events`
  ADD PRIMARY KEY (`event_id`),
  ADD UNIQUE KEY `uq_events_uuid` (`record_uuid`),
  ADD KEY `fk_events_creator` (`created_by`);

--
-- Indexes for table `event_generated_reports`
--
ALTER TABLE `event_generated_reports`
  ADD PRIMARY KEY (`report_id`),
  ADD KEY `fk_reports_event` (`event_id`),
  ADD KEY `fk_reports_user` (`generated_by`);

--
-- Indexes for table `event_integration_logs`
--
ALTER TABLE `event_integration_logs`
  ADD PRIMARY KEY (`integration_log_id`);

--
-- Indexes for table `event_judges`
--
ALTER TABLE `event_judges`
  ADD PRIMARY KEY (`assignment_id`),
  ADD UNIQUE KEY `uq_event_judges_uuid` (`record_uuid`),
  ADD UNIQUE KEY `uq_event_judge_assignment` (`event_id`,`judge_user_id`),
  ADD KEY `fk_event_judges_user` (`judge_user_id`);

--
-- Indexes for table `event_participants`
--
ALTER TABLE `event_participants`
  ADD PRIMARY KEY (`participant_id`),
  ADD UNIQUE KEY `uq_participants_uuid` (`record_uuid`),
  ADD UNIQUE KEY `uq_participants_student_reference` (`student_reference`);

--
-- Indexes for table `event_participant_photos`
--
ALTER TABLE `event_participant_photos`
  ADD PRIMARY KEY (`participant_id`);

--
-- Indexes for table `event_point_awards`
--
ALTER TABLE `event_point_awards`
  ADD PRIMARY KEY (`point_award_id`),
  ADD UNIQUE KEY `uq_point_awards_result` (`result_id`),
  ADD UNIQUE KEY `uq_point_awards_uuid` (`record_uuid`),
  ADD KEY `fk_point_awards_participant` (`participant_id`),
  ADD KEY `fk_point_awards_team` (`team_id`),
  ADD KEY `fk_point_awards_approver` (`approved_by`);

--
-- Indexes for table `event_point_rules`
--
ALTER TABLE `event_point_rules`
  ADD PRIMARY KEY (`point_rule_id`),
  ADD UNIQUE KEY `uq_point_rules_uuid` (`record_uuid`),
  ADD UNIQUE KEY `uq_point_rule_rank` (`event_id`,`rank_position`);

--
-- Indexes for table `event_result_summaries`
--
ALTER TABLE `event_result_summaries`
  ADD PRIMARY KEY (`result_id`),
  ADD UNIQUE KEY `uq_result_entry` (`entry_id`),
  ADD UNIQUE KEY `uq_results_uuid` (`record_uuid`);

--
-- Indexes for table `event_scores`
--
ALTER TABLE `event_scores`
  ADD PRIMARY KEY (`score_id`),
  ADD UNIQUE KEY `uq_scores_uuid` (`record_uuid`),
  ADD UNIQUE KEY `uq_score_per_criterion` (`entry_id`,`assignment_id`,`criterion_id`),
  ADD KEY `fk_scores_assignment` (`assignment_id`),
  ADD KEY `fk_scores_criterion` (`criterion_id`);

--
-- Indexes for table `event_sports_matches`
--
ALTER TABLE `event_sports_matches`
  ADD PRIMARY KEY (`match_id`),
  ADD KEY `sports_matches_entry_a_id_foreign` (`entry_a_id`),
  ADD KEY `sports_matches_entry_b_id_foreign` (`entry_b_id`),
  ADD KEY `sports_matches_event_id_index` (`event_id`);

--
-- Indexes for table `event_staff_registration_requests`
--
ALTER TABLE `event_staff_registration_requests`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `staff_registration_requests_username_unique` (`username`),
  ADD KEY `staff_registration_requests_reviewed_by_foreign` (`reviewed_by`);

--
-- Indexes for table `event_sync_queue`
--
ALTER TABLE `event_sync_queue`
  ADD PRIMARY KEY (`sync_id`),
  ADD KEY `idx_sync_status` (`sync_status`,`created_at`),
  ADD KEY `idx_sync_record` (`table_name`,`record_uuid`);

--
-- Indexes for table `event_tabulator_assignments`
--
ALTER TABLE `event_tabulator_assignments`
  ADD PRIMARY KEY (`event_id`,`user_id`),
  ADD UNIQUE KEY `event_tabulator_assignments_record_uuid_unique` (`record_uuid`),
  ADD KEY `event_tabulator_assignments_user_id_foreign` (`user_id`);

--
-- Indexes for table `event_teams`
--
ALTER TABLE `event_teams`
  ADD PRIMARY KEY (`team_id`),
  ADD UNIQUE KEY `uq_teams_uuid` (`record_uuid`);

--
-- Indexes for table `event_team_members`
--
ALTER TABLE `event_team_members`
  ADD PRIMARY KEY (`team_member_id`),
  ADD UNIQUE KEY `uq_team_members_uuid` (`record_uuid`),
  ADD UNIQUE KEY `uq_team_member_pair` (`team_id`,`participant_id`),
  ADD KEY `fk_team_members_participant` (`participant_id`);

--
-- Indexes for table `fee_items`
--
ALTER TABLE `fee_items`
  ADD PRIMARY KEY (`fee_id`),
  ADD UNIQUE KEY `fee_code` (`fee_code`),
  ADD KEY `fk_fee_program` (`program_id`),
  ADD KEY `fk_fee_subject` (`subject_id`),
  ADD KEY `fk_fee_period` (`period_id`);

--
-- Indexes for table `fe_completion_logs`
--
ALTER TABLE `fe_completion_logs`
  ADD PRIMARY KEY (`completion_id`),
  ADD UNIQUE KEY `uq_completion_log` (`schedule_id`,`assignment_id`,`anonymous_hash`),
  ADD KEY `ix_completion_logs_assignment` (`assignment_id`);

--
-- Indexes for table `fe_department_heads`
--
ALTER TABLE `fe_department_heads`
  ADD PRIMARY KEY (`department_head_id`),
  ADD UNIQUE KEY `uq_department_heads_user_department` (`user_id`,`department_id`),
  ADD KEY `ix_department_heads_department_current` (`department_id`,`is_current`);

--
-- Indexes for table `fe_evaluation_questions`
--
ALTER TABLE `fe_evaluation_questions`
  ADD PRIMARY KEY (`question_id`),
  ADD UNIQUE KEY `uq_evaluation_question_order` (`schedule_id`,`question_order`),
  ADD KEY `ix_evaluation_questions_schedule` (`schedule_id`);

--
-- Indexes for table `fe_evaluation_reports`
--
ALTER TABLE `fe_evaluation_reports`
  ADD PRIMARY KEY (`report_id`),
  ADD KEY `ix_evaluation_reports_schedule` (`schedule_id`),
  ADD KEY `ix_evaluation_reports_department` (`department_id`),
  ADD KEY `ix_evaluation_reports_program` (`program_id`),
  ADD KEY `ix_evaluation_reports_faculty` (`faculty_id`),
  ADD KEY `ix_evaluation_reports_generated_by` (`generated_by`),
  ADD KEY `ix_evaluation_reports_approved_by` (`approved_by`);

--
-- Indexes for table `fe_evaluation_responses`
--
ALTER TABLE `fe_evaluation_responses`
  ADD PRIMARY KEY (`response_id`),
  ADD UNIQUE KEY `uq_evaluation_response_submission_question` (`submission_id`,`question_id`),
  ADD KEY `ix_evaluation_responses_question` (`question_id`);

--
-- Indexes for table `fe_evaluation_schedules`
--
ALTER TABLE `fe_evaluation_schedules`
  ADD PRIMARY KEY (`schedule_id`),
  ADD UNIQUE KEY `uq_evaluation_schedule_term_program` (`term_id`,`program_id`),
  ADD KEY `ix_evaluation_schedules_program` (`program_id`),
  ADD KEY `ix_evaluation_schedules_creator` (`created_by`),
  ADD KEY `ix_evaluation_schedules_opener` (`opened_by`);

--
-- Indexes for table `fe_evaluation_submissions`
--
ALTER TABLE `fe_evaluation_submissions`
  ADD PRIMARY KEY (`submission_id`),
  ADD UNIQUE KEY `uq_evaluation_submission_token` (`anonymous_token`),
  ADD KEY `ix_evaluation_submissions_schedule_assignment` (`schedule_id`,`assignment_id`),
  ADD KEY `fk_evaluation_submissions_assignment` (`assignment_id`);

--
-- Indexes for table `fe_grade_completion`
--
ALTER TABLE `fe_grade_completion`
  ADD PRIMARY KEY (`grade_completion_id`),
  ADD UNIQUE KEY `uq_grade_completion_enrollment_component` (`enrollment_id`,`grade_component`),
  ADD KEY `ix_grade_completion_assignment` (`assignment_id`),
  ADD KEY `ix_grade_completion_validator` (`validated_by`);

--
-- Indexes for table `fe_onecampus_webhook_events`
--
ALTER TABLE `fe_onecampus_webhook_events`
  ADD PRIMARY KEY (`event_id`),
  ADD KEY `ix_onecampus_webhook_received_at` (`received_at`),
  ADD KEY `ix_onecampus_webhook_status` (`processing_status`);

--
-- Indexes for table `fe_schools`
--
ALTER TABLE `fe_schools`
  ADD PRIMARY KEY (`school_id`),
  ADD UNIQUE KEY `uq_schools_code` (`school_code`);

--
-- Indexes for table `fe_shs_specializations`
--
ALTER TABLE `fe_shs_specializations`
  ADD PRIMARY KEY (`specialization_id`),
  ADD UNIQUE KEY `uq_shs_specializations_code` (`specialization_code`),
  ADD KEY `ix_shs_specializations_strand` (`strand_id`);

--
-- Indexes for table `fe_shs_strands`
--
ALTER TABLE `fe_shs_strands`
  ADD PRIMARY KEY (`strand_id`),
  ADD UNIQUE KEY `uq_shs_strands_code` (`strand_code`),
  ADD KEY `ix_shs_strands_track` (`track_id`),
  ADD KEY `ix_shs_strands_program` (`program_id`);

--
-- Indexes for table `fe_shs_tracks`
--
ALTER TABLE `fe_shs_tracks`
  ADD PRIMARY KEY (`track_id`),
  ADD UNIQUE KEY `uq_shs_tracks_code` (`track_code`);

--
-- Indexes for table `fe_teaching_assignments`
--
ALTER TABLE `fe_teaching_assignments`
  ADD PRIMARY KEY (`assignment_id`),
  ADD UNIQUE KEY `uq_teaching_assignment_class_instructor` (`class_id`,`instructor_id`),
  ADD KEY `ix_teaching_assignments_instructor` (`instructor_id`);

--
-- Indexes for table `guidance_appointments`
--
ALTER TABLE `guidance_appointments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_appointment_staff_date` (`staff_id`,`appointment_date`,`appointment_time`),
  ADD KEY `fk_guidance_appointments_0_students` (`student_id`),
  ADD KEY `fk_guidance_appointments_2_guidance_counselor_availability` (`availability_id`);

--
-- Indexes for table `guidance_counselor_availability`
--
ALTER TABLE `guidance_counselor_availability`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_staff_slot` (`staff_id`,`available_date`,`start_time`);

--
-- Indexes for table `guidance_follow_ups`
--
ALTER TABLE `guidance_follow_ups`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_guidance_follow_ups_0_guidance_records` (`record_id`),
  ADD KEY `fk_guidance_follow_ups_1_guidance_staff_profiles` (`staff_id`);

--
-- Indexes for table `guidance_integration_settings`
--
ALTER TABLE `guidance_integration_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `integration_name` (`integration_name`);

--
-- Indexes for table `guidance_records`
--
ALTER TABLE `guidance_records`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `appointment_id` (`appointment_id`),
  ADD KEY `fk_guidance_records_0_students` (`student_id`),
  ADD KEY `fk_guidance_records_2_guidance_staff_profiles` (`staff_id`);

--
-- Indexes for table `guidance_referrals`
--
ALTER TABLE `guidance_referrals`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_guidance_referrals_0_students` (`student_id`),
  ADD KEY `fk_guidance_referrals_1_guidance_staff_profiles` (`staff_id`);

--
-- Indexes for table `guidance_staff_profiles`
--
ALTER TABLE `guidance_staff_profiles`
  ADD PRIMARY KEY (`staff_id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `idcard_iadfc_idcards`
--
ALTER TABLE `idcard_iadfc_idcards`
  ADD PRIMARY KEY (`CardId`),
  ADD UNIQUE KEY `CardReference` (`CardReference`),
  ADD UNIQUE KEY `VerifyToken` (`VerifyToken`),
  ADD KEY `ix_iadfc_cards_person` (`PersonId`,`CardId`),
  ADD KEY `ix_iadfc_cards_updated` (`UpdatedAt`,`CardId`),
  ADD KEY `fk_iadfc_cards_staff` (`GeneratedBy`);

--
-- Indexes for table `idcard_iadfc_idreleases`
--
ALTER TABLE `idcard_iadfc_idreleases`
  ADD PRIMARY KEY (`ReleaseId`),
  ADD UNIQUE KEY `CardId` (`CardId`),
  ADD KEY `fk_iadfc_release_staff` (`ReleasedBy`);

--
-- Indexes for table `idcard_iadfc_printrecords`
--
ALTER TABLE `idcard_iadfc_printrecords`
  ADD PRIMARY KEY (`PrintId`),
  ADD KEY `ix_iadfc_prints_card_date` (`CardId`,`PrintedAt`),
  ADD KEY `fk_iadfc_print_staff` (`PrintedBy`);

--
-- Indexes for table `idcard_iadfc_schoolsettings`
--
ALTER TABLE `idcard_iadfc_schoolsettings`
  ADD PRIMARY KEY (`SettingId`);

--
-- Indexes for table `idcard_persons`
--
ALTER TABLE `idcard_persons`
  ADD PRIMARY KEY (`PersonId`),
  ADD UNIQUE KEY `SchoolNumber` (`SchoolNumber`),
  ADD UNIQUE KEY `student_id` (`student_id`),
  ADD KEY `fk_idcard_person_user` (`user_id`);

--
-- Indexes for table `instructors`
--
ALTER TABLE `instructors`
  ADD PRIMARY KEY (`instructor_id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD UNIQUE KEY `instructor_uid` (`instructor_uid`),
  ADD UNIQUE KEY `employee_number` (`employee_number`),
  ADD KEY `fk_shared_inst_department` (`department_id`);

--
-- Indexes for table `lms_assignments`
--
ALTER TABLE `lms_assignments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `assignments_class_fk` (`class_id`),
  ADD KEY `assignments_creator_fk` (`created_by`);

--
-- Indexes for table `lms_discussion_posts`
--
ALTER TABLE `lms_discussion_posts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `posts_topic_fk` (`topic_id`),
  ADD KEY `posts_author_fk` (`author_id`);

--
-- Indexes for table `lms_discussion_topics`
--
ALTER TABLE `lms_discussion_topics`
  ADD PRIMARY KEY (`id`),
  ADD KEY `topics_class_fk` (`class_id`),
  ADD KEY `topics_creator_fk` (`created_by`);

--
-- Indexes for table `lms_materials`
--
ALTER TABLE `lms_materials`
  ADD PRIMARY KEY (`id`),
  ADD KEY `materials_class_fk` (`class_id`),
  ADD KEY `materials_creator_fk` (`created_by`);

--
-- Indexes for table `lms_quizzes`
--
ALTER TABLE `lms_quizzes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `quizzes_class_fk` (`class_id`),
  ADD KEY `quizzes_creator_fk` (`created_by`);

--
-- Indexes for table `lms_quiz_answer_keys`
--
ALTER TABLE `lms_quiz_answer_keys`
  ADD PRIMARY KEY (`question_id`);

--
-- Indexes for table `lms_quiz_attempts`
--
ALTER TABLE `lms_quiz_attempts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `attempts_student_unique` (`quiz_id`,`student_id`),
  ADD KEY `attempts_student_fk` (`student_id`);

--
-- Indexes for table `lms_quiz_questions`
--
ALTER TABLE `lms_quiz_questions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `questions_quiz_fk` (`quiz_id`);

--
-- Indexes for table `lms_registration_applications`
--
ALTER TABLE `lms_registration_applications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `auth_user_id` (`auth_user_id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `student_id_number` (`student_id_number`),
  ADD KEY `registrations_reviewer_fk` (`reviewed_by`);

--
-- Indexes for table `lms_registration_class_links`
--
ALTER TABLE `lms_registration_class_links`
  ADD PRIMARY KEY (`application_id`,`class_id`),
  ADD KEY `registration_classes_class_fk` (`class_id`);

--
-- Indexes for table `lms_submissions`
--
ALTER TABLE `lms_submissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `submissions_student_unique` (`assignment_id`,`student_id`),
  ADD KEY `submissions_student_fk` (`student_id`),
  ADD KEY `submissions_grader_fk` (`graded_by`);

--
-- Indexes for table `lms_sync_logs`
--
ALTER TABLE `lms_sync_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sync_initiator_fk` (`initiated_by`);

--
-- Indexes for table `maint_assets`
--
ALTER TABLE `maint_assets`
  ADD PRIMARY KEY (`asset_id`),
  ADD UNIQUE KEY `assets_asset_tag_unique` (`asset_tag`),
  ADD KEY `assets_location_id_foreign` (`location_id`);

--
-- Indexes for table `maint_attachments`
--
ALTER TABLE `maint_attachments`
  ADD PRIMARY KEY (`attachment_id`),
  ADD KEY `attachments_request_id_foreign` (`request_id`),
  ADD KEY `attachments_update_id_foreign` (`update_id`),
  ADD KEY `attachments_finding_id_foreign` (`finding_id`),
  ADD KEY `attachments_uploaded_by_employee_id_foreign` (`uploaded_by_employee_id`);

--
-- Indexes for table `maint_employees`
--
ALTER TABLE `maint_employees`
  ADD PRIMARY KEY (`employee_id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `maint_inspections`
--
ALTER TABLE `maint_inspections`
  ADD PRIMARY KEY (`inspection_id`),
  ADD KEY `inspections_personnel_employee_id_foreign` (`personnel_employee_id`),
  ADD KEY `inspections_created_by_employee_id_foreign` (`created_by_employee_id`),
  ADD KEY `inspections_reviewed_by_employee_id_foreign` (`reviewed_by_employee_id`),
  ADD KEY `inspections_inspection_date_index` (`inspection_date`);

--
-- Indexes for table `maint_inspection_findings`
--
ALTER TABLE `maint_inspection_findings`
  ADD PRIMARY KEY (`finding_id`),
  ADD UNIQUE KEY `inspection_findings_inspection_id_asset_id_unique` (`inspection_id`,`asset_id`),
  ADD KEY `inspection_findings_asset_id_foreign` (`asset_id`),
  ADD KEY `inspection_findings_request_id_foreign` (`request_id`);

--
-- Indexes for table `maint_locations`
--
ALTER TABLE `maint_locations`
  ADD PRIMARY KEY (`location_id`);

--
-- Indexes for table `maint_maintenance_administrators`
--
ALTER TABLE `maint_maintenance_administrators`
  ADD PRIMARY KEY (`employee_id`);

--
-- Indexes for table `maint_maintenance_requests`
--
ALTER TABLE `maint_maintenance_requests`
  ADD PRIMARY KEY (`request_id`),
  ADD KEY `maintenance_requests_asset_id_foreign` (`asset_id`),
  ADD KEY `maintenance_requests_reported_location_id_foreign` (`reported_location_id`),
  ADD KEY `maintenance_requests_reported_by_employee_id_foreign` (`reported_by_employee_id`),
  ADD KEY `maintenance_requests_verified_by_employee_id_foreign` (`verified_by_employee_id`),
  ADD KEY `maintenance_requests_assigned_to_employee_id_foreign` (`assigned_to_employee_id`),
  ADD KEY `maintenance_requests_assigned_by_employee_id_foreign` (`assigned_by_employee_id`),
  ADD KEY `maintenance_requests_status_index` (`status`),
  ADD KEY `maintenance_requests_due_date_index` (`due_date`);

--
-- Indexes for table `maint_repair_updates`
--
ALTER TABLE `maint_repair_updates`
  ADD PRIMARY KEY (`update_id`),
  ADD KEY `repair_updates_request_id_foreign` (`request_id`),
  ADD KEY `repair_updates_updated_by_employee_id_foreign` (`updated_by_employee_id`);

--
-- Indexes for table `maint_request_comments`
--
ALTER TABLE `maint_request_comments`
  ADD PRIMARY KEY (`comment_id`),
  ADD KEY `request_comments_request_id_foreign` (`request_id`),
  ADD KEY `request_comments_employee_id_foreign` (`employee_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `fk_shared_notif_user` (`user_id`);

--
-- Indexes for table `ojt_companies`
--
ALTER TABLE `ojt_companies`
  ADD PRIMARY KEY (`company_id`);

--
-- Indexes for table `ojt_daily_time_records`
--
ALTER TABLE `ojt_daily_time_records`
  ADD PRIMARY KEY (`dtr_id`),
  ADD UNIQUE KEY `uq_ojt_assignment_dtr_date` (`assignment_id`,`date`),
  ADD KEY `ix_ojt_dtr_status` (`status`),
  ADD KEY `ix_ojt_dtr_verifier` (`verified_by`);

--
-- Indexes for table `ojt_documents`
--
ALTER TABLE `ojt_documents`
  ADD PRIMARY KEY (`document_id`),
  ADD KEY `ix_ojt_doc_assignment` (`assignment_id`),
  ADD KEY `ix_ojt_doc_uploader` (`uploaded_by`);

--
-- Indexes for table `ojt_dtr_breaks`
--
ALTER TABLE `ojt_dtr_breaks`
  ADD PRIMARY KEY (`dtr_id`);

--
-- Indexes for table `ojt_evaluations`
--
ALTER TABLE `ojt_evaluations`
  ADD PRIMARY KEY (`evaluation_id`),
  ADD UNIQUE KEY `uq_ojt_evaluation_assignment` (`assignment_id`),
  ADD KEY `ix_ojt_eval_supervisor` (`supervisor_id`),
  ADD KEY `ix_ojt_eval_reviewer` (`reviewed_by`);

--
-- Indexes for table `ojt_evaluation_criteria`
--
ALTER TABLE `ojt_evaluation_criteria`
  ADD PRIMARY KEY (`criterion_id`),
  ADD UNIQUE KEY `uq_ojt_criterion_name` (`name`);

--
-- Indexes for table `ojt_evaluation_drafts`
--
ALTER TABLE `ojt_evaluation_drafts`
  ADD PRIMARY KEY (`assignment_id`),
  ADD KEY `ix_ojt_draft_supervisor` (`supervisor_id`);

--
-- Indexes for table `ojt_evaluation_scores`
--
ALTER TABLE `ojt_evaluation_scores`
  ADD PRIMARY KEY (`score_id`),
  ADD UNIQUE KEY `uq_ojt_score_eval_criterion` (`evaluation_id`,`criterion_id`),
  ADD KEY `ix_ojt_score_criterion` (`criterion_id`);

--
-- Indexes for table `ojt_internship_assignments`
--
ALTER TABLE `ojt_internship_assignments`
  ADD PRIMARY KEY (`assignment_id`),
  ADD KEY `ix_ojt_assignment_student` (`student_id`),
  ADD KEY `ix_ojt_assignment_company` (`company_id`),
  ADD KEY `ix_ojt_assignment_supervisor` (`supervisor_id`);

--
-- Indexes for table `ojt_password_reset_requests`
--
ALTER TABLE `ojt_password_reset_requests`
  ADD PRIMARY KEY (`request_id`),
  ADD KEY `ix_ojt_reset_status_requested` (`status`,`requested_at`),
  ADD KEY `ix_ojt_reset_user` (`user_id`),
  ADD KEY `ix_ojt_reset_resolved_by` (`resolved_by`);

--
-- Indexes for table `ojt_progress_attachments`
--
ALTER TABLE `ojt_progress_attachments`
  ADD PRIMARY KEY (`progress_id`),
  ADD UNIQUE KEY `uq_ojt_attachment_doc` (`document_id`);

--
-- Indexes for table `ojt_progress_reports`
--
ALTER TABLE `ojt_progress_reports`
  ADD PRIMARY KEY (`progress_id`),
  ADD UNIQUE KEY `uq_ojt_weekly_report` (`assignment_id`,`week_start`),
  ADD KEY `ix_ojt_progress_reviewer` (`reviewed_by`);

--
-- Indexes for table `ojt_required_documents`
--
ALTER TABLE `ojt_required_documents`
  ADD PRIMARY KEY (`requirement_id`),
  ADD UNIQUE KEY `uq_ojt_requirement_name` (`name`);

--
-- Indexes for table `ojt_supervisors`
--
ALTER TABLE `ojt_supervisors`
  ADD PRIMARY KEY (`supervisor_id`),
  ADD UNIQUE KEY `uq_ojt_supervisor_user` (`user_id`),
  ADD KEY `ix_ojt_supervisor_company` (`company_id`);

--
-- Indexes for table `pre_enrollments`
--
ALTER TABLE `pre_enrollments`
  ADD PRIMARY KEY (`pre_enrollment_id`),
  ADD UNIQUE KEY `reference_no` (`reference_no`),
  ADD KEY `fk_pre_student` (`student_id`),
  ADD KEY `fk_pre_program` (`program_id`),
  ADD KEY `fk_pre_period` (`period_id`),
  ADD KEY `fk_pre_reviewer` (`reviewed_by`);

--
-- Indexes for table `pre_enrollment_subjects`
--
ALTER TABLE `pre_enrollment_subjects`
  ADD PRIMARY KEY (`pre_enrollment_subject_id`),
  ADD UNIQUE KEY `uq_pre_subject` (`pre_enrollment_id`,`subject_id`),
  ADD KEY `fk_presub_subject` (`subject_id`);

--
-- Indexes for table `programs`
--
ALTER TABLE `programs`
  ADD PRIMARY KEY (`program_id`),
  ADD UNIQUE KEY `program_code` (`program_code`),
  ADD UNIQUE KEY `program_uid` (`program_uid`),
  ADD KEY `ix_programs_department` (`department_id`);

--
-- Indexes for table `readmit_applications`
--
ALTER TABLE `readmit_applications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_app_ref` (`reference_no`),
  ADD UNIQUE KEY `uq_app_seq` (`seq`),
  ADD KEY `idx_app_applicant` (`applicant_id`),
  ADD KEY `idx_app_status` (`status`),
  ADD KEY `fk_readmit_applications_1_programs` (`program_id`),
  ADD KEY `fk_readmit_applications_2_users` (`assigned_evaluator_id`);

--
-- Indexes for table `readmit_application_history`
--
ALTER TABLE `readmit_application_history`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_hist_seq` (`seq`),
  ADD KEY `idx_hist_app` (`application_id`);

--
-- Indexes for table `readmit_documents`
--
ALTER TABLE `readmit_documents`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_doc_seq` (`seq`),
  ADD KEY `idx_doc_app` (`application_id`),
  ADD KEY `fk_readmit_documents_1_readmit_requirements` (`requirement_id`);

--
-- Indexes for table `readmit_requirements`
--
ALTER TABLE `readmit_requirements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_requirements_name` (`name`);

--
-- Indexes for table `report_exports`
--
ALTER TABLE `report_exports`
  ADD PRIMARY KEY (`report_id`),
  ADD KEY `fk_report_admin` (`generated_by`);

--
-- Indexes for table `schema_migrations`
--
ALTER TABLE `schema_migrations`
  ADD PRIMARY KEY (`migration_id`),
  ADD UNIQUE KEY `uq_schema_migration_module` (`module_code`,`migration_name`);

--
-- Indexes for table `scholar_application_documents`
--
ALTER TABLE `scholar_application_documents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `application_documents_scholarship_requirement_id_foreign` (`scholarship_requirement_id`),
  ADD KEY `application_documents_verified_by_foreign` (`verified_by`),
  ADD KEY `app_docs_appid_verifstatus_idx` (`scholarship_application_id`,`verification_status`),
  ADD KEY `application_documents_document_category_index` (`document_category`);

--
-- Indexes for table `scholar_application_evaluations`
--
ALTER TABLE `scholar_application_evaluations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `application_evaluations_evaluator_id_foreign` (`evaluator_id`),
  ADD KEY `application_evaluations_scholarship_application_id_index` (`scholarship_application_id`);

--
-- Indexes for table `scholar_application_status_histories`
--
ALTER TABLE `scholar_application_status_histories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `application_status_histories_changed_by_foreign` (`changed_by`),
  ADD KEY `application_status_histories_scholarship_application_id_index` (`scholarship_application_id`);

--
-- Indexes for table `scholar_cache`
--
ALTER TABLE `scholar_cache`
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `scholar_cache_locks`
--
ALTER TABLE `scholar_cache_locks`
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `scholar_document_reviews`
--
ALTER TABLE `scholar_document_reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `document_reviews_application_document_id_foreign` (`application_document_id`),
  ADD KEY `document_reviews_reviewed_by_foreign` (`reviewed_by`);

--
-- Indexes for table `scholar_eligibility_results`
--
ALTER TABLE `scholar_eligibility_results`
  ADD PRIMARY KEY (`id`),
  ADD KEY `eligibility_results_checked_by_foreign` (`checked_by`),
  ADD KEY `eligibility_results_scholarship_application_id_index` (`scholarship_application_id`);

--
-- Indexes for table `scholar_eligibility_rules`
--
ALTER TABLE `scholar_eligibility_rules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `eligibility_rules_scholarship_program_id_is_active_index` (`scholarship_program_id`,`is_active`);

--
-- Indexes for table `scholar_failed_jobs`
--
ALTER TABLE `scholar_failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `scholar_household_profiles`
--
ALTER TABLE `scholar_household_profiles`
  ADD PRIMARY KEY (`student_id`);

--
-- Indexes for table `scholar_jobs`
--
ALTER TABLE `scholar_jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `scholar_job_batches`
--
ALTER TABLE `scholar_job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `scholar_password_reset_tokens`
--
ALTER TABLE `scholar_password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `scholar_personal_access_tokens`
--
ALTER TABLE `scholar_personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  ADD KEY `personal_access_tokens_expires_at_index` (`expires_at`);

--
-- Indexes for table `scholar_renewal_applications`
--
ALTER TABLE `scholar_renewal_applications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `renewal_applications_renewal_no_unique` (`renewal_no`),
  ADD UNIQUE KEY `renewals_award_cycle_unique` (`scholarship_award_id`,`academic_year`),
  ADD KEY `renewal_applications_user_id_foreign` (`user_id`),
  ADD KEY `renewal_applications_decided_by_foreign` (`decided_by`),
  ADD KEY `renewal_applications_scholarship_award_id_status_index` (`scholarship_award_id`,`status`);

--
-- Indexes for table `scholar_scholarship_appeals`
--
ALTER TABLE `scholar_scholarship_appeals`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `scholarship_appeals_appeal_no_unique` (`appeal_no`),
  ADD UNIQUE KEY `appeals_one_pending_per_award` (`scholarship_award_id`,`pending_slot`),
  ADD KEY `scholarship_appeals_decided_by_foreign` (`decided_by`),
  ADD KEY `scholarship_appeals_user_id_status_index` (`user_id`,`status`);

--
-- Indexes for table `scholar_scholarship_applications`
--
ALTER TABLE `scholar_scholarship_applications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_app_user_schol_year` (`user_id`,`scholarship_program_id`,`academic_year`),
  ADD UNIQUE KEY `scholarship_applications_application_no_unique` (`application_no`),
  ADD KEY `scholarship_applications_scholarship_program_id_foreign` (`scholarship_program_id`),
  ADD KEY `scholarship_applications_decided_by_foreign` (`decided_by`),
  ADD KEY `scholarship_applications_status_scholarship_program_id_index` (`status`,`scholarship_program_id`),
  ADD KEY `scholarship_applications_user_id_index` (`user_id`),
  ADD KEY `sch_apps_assigned_to_idx` (`assigned_to`);

--
-- Indexes for table `scholar_scholarship_awards`
--
ALTER TABLE `scholar_scholarship_awards`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `scholarship_awards_award_no_unique` (`award_no`),
  ADD UNIQUE KEY `scholarship_awards_scholarship_application_id_unique` (`scholarship_application_id`),
  ADD KEY `scholarship_awards_scholarship_program_id_foreign` (`scholarship_program_id`),
  ADD KEY `scholarship_awards_awarded_by_foreign` (`awarded_by`),
  ADD KEY `scholarship_awards_user_id_recipient_status_index` (`user_id`,`recipient_status`);

--
-- Indexes for table `scholar_scholarship_programs`
--
ALTER TABLE `scholar_scholarship_programs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `scholarship_programs_code_unique` (`code`),
  ADD KEY `scholarship_programs_created_by_foreign` (`created_by`),
  ADD KEY `scholarship_programs_status_deadline_index` (`status`,`deadline`),
  ADD KEY `scholarship_programs_category_index` (`category`);

--
-- Indexes for table `scholar_scholarship_requirements`
--
ALTER TABLE `scholar_scholarship_requirements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `scholarship_requirements_scholarship_program_id_index` (`scholarship_program_id`);

--
-- Indexes for table `sch_class_meetings`
--
ALTER TABLE `sch_class_meetings`
  ADD PRIMARY KEY (`meeting_id`),
  ADD UNIQUE KEY `uq_sch_class_exact_slot` (`class_id`,`day_of_week`,`start_time`,`end_time`),
  ADD KEY `ix_sch_room_day_start_end` (`room_id`,`day_of_week`,`start_time`,`end_time`),
  ADD KEY `ix_sch_meeting_creator` (`created_by`);

--
-- Indexes for table `sch_instructor_load_settings`
--
ALTER TABLE `sch_instructor_load_settings`
  ADD PRIMARY KEY (`instructor_id`);

--
-- Indexes for table `sch_rooms`
--
ALTER TABLE `sch_rooms`
  ADD PRIMARY KEY (`room_id`),
  ADD UNIQUE KEY `uq_sch_room_code` (`room_code`),
  ADD UNIQUE KEY `uq_sch_room_location` (`maintenance_location_id`);

--
-- Indexes for table `sch_sync_queue`
--
ALTER TABLE `sch_sync_queue`
  ADD PRIMARY KEY (`queue_id`),
  ADD KEY `ix_sch_sync_pending` (`is_synced`,`queued_at`),
  ADD KEY `fk_sch_sync_actor` (`queued_by_user_id`);

--
-- Indexes for table `staff_profiles`
--
ALTER TABLE `staff_profiles`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `admin_number` (`admin_number`),
  ADD KEY `fk_staff_profiles_department` (`department_id`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`student_id`),
  ADD UNIQUE KEY `student_number` (`student_number`),
  ADD UNIQUE KEY `student_uid` (`student_uid`),
  ADD KEY `fk_shared_student_school` (`school_id`),
  ADD KEY `fk_shared_student_strand` (`strand_id`),
  ADD KEY `fk_shared_student_specialization` (`specialization_id`);

--
-- Indexes for table `student_contacts`
--
ALTER TABLE `student_contacts`
  ADD PRIMARY KEY (`contact_id`),
  ADD UNIQUE KEY `uq_student_contact_role` (`student_id`,`contact_role`);

--
-- Indexes for table `student_documents`
--
ALTER TABLE `student_documents`
  ADD PRIMARY KEY (`document_id`),
  ADD KEY `idx_student_documents` (`student_id`,`uploaded_at`),
  ADD KEY `fk_document_uploader` (`uploaded_by`),
  ADD KEY `fk_document_verifier` (`verified_by`);

--
-- Indexes for table `student_first_enrollments`
--
ALTER TABLE `student_first_enrollments`
  ADD PRIMARY KEY (`student_id`),
  ADD KEY `fk_first_program` (`first_program_id`),
  ADD KEY `fk_first_period` (`first_period_id`),
  ADD KEY `fk_first_user` (`recorded_by`);

--
-- Indexes for table `subjects`
--
ALTER TABLE `subjects`
  ADD PRIMARY KEY (`subject_id`),
  ADD UNIQUE KEY `subject_uid` (`subject_uid`),
  ADD KEY `fk_subject_program` (`program_id`);

--
-- Indexes for table `system_settings`
--
ALTER TABLE `system_settings`
  ADD PRIMARY KEY (`setting_id`),
  ADD UNIQUE KEY `uq_shared_setting` (`module_code`,`setting_key`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `user_uid` (`user_uid`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `uq_users_student` (`student_id`),
  ADD KEY `idx_users_status` (`status`);

--
-- Indexes for table `user_access_roles`
--
ALTER TABLE `user_access_roles`
  ADD PRIMARY KEY (`user_id`,`role_id`,`module_code`),
  ADD KEY `fk_user_role_role` (`role_id`);

--
-- Indexes for table `user_mfa_methods`
--
ALTER TABLE `user_mfa_methods`
  ADD PRIMARY KEY (`mfa_id`),
  ADD UNIQUE KEY `uq_user_mfa_method` (`user_id`,`method`);

--
-- Indexes for table `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD PRIMARY KEY (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `academic_classes`
--
ALTER TABLE `academic_classes`
  MODIFY `class_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `academic_periods`
--
ALTER TABLE `academic_periods`
  MODIFY `period_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `access_permissions`
--
ALTER TABLE `access_permissions`
  MODIFY `permission_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `access_roles`
--
ALTER TABLE `access_roles`
  MODIFY `role_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `log_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `admit_applicants`
--
ALTER TABLE `admit_applicants`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `admit_evaluations`
--
ALTER TABLE `admit_evaluations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `admit_interviews`
--
ALTER TABLE `admit_interviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `admit_interview_slots`
--
ALTER TABLE `admit_interview_slots`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `announcements`
--
ALTER TABLE `announcements`
  MODIFY `announcement_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `attend_notification_log`
--
ALTER TABLE `attend_notification_log`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `attend_notify_queue`
--
ALTER TABLE `attend_notify_queue`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `attend_password_resets`
--
ALTER TABLE `attend_password_resets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `auth_sessions`
--
ALTER TABLE `auth_sessions`
  MODIFY `session_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `billing_adjustments`
--
ALTER TABLE `billing_adjustments`
  MODIFY `adjustment_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `billing_discounts`
--
ALTER TABLE `billing_discounts`
  MODIFY `discount_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `billing_enrollment_discounts`
--
ALTER TABLE `billing_enrollment_discounts`
  MODIFY `enrollment_discount_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `billing_enrollment_inbox`
--
ALTER TABLE `billing_enrollment_inbox`
  MODIFY `inbox_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `billing_invoices`
--
ALTER TABLE `billing_invoices`
  MODIFY `invoice_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `billing_online_payments`
--
ALTER TABLE `billing_online_payments`
  MODIFY `online_payment_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `billing_payments`
--
ALTER TABLE `billing_payments`
  MODIFY `payment_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `billing_payment_requests`
--
ALTER TABLE `billing_payment_requests`
  MODIFY `request_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `blocks`
--
ALTER TABLE `blocks`
  MODIFY `block_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `campusfind_claims`
--
ALTER TABLE `campusfind_claims`
  MODIFY `campusfind_claim_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `campusfind_items`
--
ALTER TABLE `campusfind_items`
  MODIFY `campusfind_item_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cebrms_borrowers`
--
ALTER TABLE `cebrms_borrowers`
  MODIFY `borrower_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cebrms_borrow_items`
--
ALTER TABLE `cebrms_borrow_items`
  MODIFY `borrow_item_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cebrms_borrow_transactions`
--
ALTER TABLE `cebrms_borrow_transactions`
  MODIFY `transaction_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cebrms_equipment`
--
ALTER TABLE `cebrms_equipment`
  MODIFY `equipment_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cebrms_equipment_categories`
--
ALTER TABLE `cebrms_equipment_categories`
  MODIFY `category_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cebrms_qr_scan_logs`
--
ALTER TABLE `cebrms_qr_scan_logs`
  MODIFY `scan_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cebrms_return_records`
--
ALTER TABLE `cebrms_return_records`
  MODIFY `return_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `class_enrollments`
--
ALTER TABLE `class_enrollments`
  MODIFY `enrollment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `department_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_ballots`
--
ALTER TABLE `election_ballots`
  MODIFY `ballot_id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_candidacies`
--
ALTER TABLE `election_candidacies`
  MODIFY `candidate_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_candidate_documents`
--
ALTER TABLE `election_candidate_documents`
  MODIFY `document_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_elections`
--
ALTER TABLE `election_elections`
  MODIFY `election_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_face_data`
--
ALTER TABLE `election_face_data`
  MODIFY `face_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_face_verifications`
--
ALTER TABLE `election_face_verifications`
  MODIFY `verification_id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_positions`
--
ALTER TABLE `election_positions`
  MODIFY `position_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_results`
--
ALTER TABLE `election_results`
  MODIFY `result_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_security_login_attempts`
--
ALTER TABLE `election_security_login_attempts`
  MODIFY `attempt_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_security_sessions`
--
ALTER TABLE `election_security_sessions`
  MODIFY `session_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `election_vote_records`
--
ALTER TABLE `election_vote_records`
  MODIFY `record_id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ems_employee_documents`
--
ALTER TABLE `ems_employee_documents`
  MODIFY `document_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `enrollments`
--
ALTER TABLE `enrollments`
  MODIFY `enrollment_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `enrollment_charges`
--
ALTER TABLE `enrollment_charges`
  MODIFY `charge_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `enrollment_subjects`
--
ALTER TABLE `enrollment_subjects`
  MODIFY `enrollment_subject_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_applications`
--
ALTER TABLE `eteeap_applications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_assessments`
--
ALTER TABLE `eteeap_assessments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_billing_fees`
--
ALTER TABLE `eteeap_billing_fees`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_billing_invoices`
--
ALTER TABLE `eteeap_billing_invoices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_billing_payments`
--
ALTER TABLE `eteeap_billing_payments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_credits`
--
ALTER TABLE `eteeap_credits`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_education_records`
--
ALTER TABLE `eteeap_education_records`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_employment_records`
--
ALTER TABLE `eteeap_employment_records`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_evaluations`
--
ALTER TABLE `eteeap_evaluations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_form_records`
--
ALTER TABLE `eteeap_form_records`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_grades`
--
ALTER TABLE `eteeap_grades`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_login_attempts`
--
ALTER TABLE `eteeap_login_attempts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_messages`
--
ALTER TABLE `eteeap_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_portfolio_assessments`
--
ALTER TABLE `eteeap_portfolio_assessments`
  MODIFY `assessment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_portfolio_rubric_forms`
--
ALTER TABLE `eteeap_portfolio_rubric_forms`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_program_offerings`
--
ALTER TABLE `eteeap_program_offerings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_uploads`
--
ALTER TABLE `eteeap_uploads`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eteeap_upload_events`
--
ALTER TABLE `eteeap_upload_events`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_criteria`
--
ALTER TABLE `event_criteria`
  MODIFY `criterion_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_entries`
--
ALTER TABLE `event_entries`
  MODIFY `entry_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_events`
--
ALTER TABLE `event_events`
  MODIFY `event_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_generated_reports`
--
ALTER TABLE `event_generated_reports`
  MODIFY `report_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_integration_logs`
--
ALTER TABLE `event_integration_logs`
  MODIFY `integration_log_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_judges`
--
ALTER TABLE `event_judges`
  MODIFY `assignment_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_participants`
--
ALTER TABLE `event_participants`
  MODIFY `participant_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_point_awards`
--
ALTER TABLE `event_point_awards`
  MODIFY `point_award_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_point_rules`
--
ALTER TABLE `event_point_rules`
  MODIFY `point_rule_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_result_summaries`
--
ALTER TABLE `event_result_summaries`
  MODIFY `result_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_scores`
--
ALTER TABLE `event_scores`
  MODIFY `score_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_sports_matches`
--
ALTER TABLE `event_sports_matches`
  MODIFY `match_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_staff_registration_requests`
--
ALTER TABLE `event_staff_registration_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_sync_queue`
--
ALTER TABLE `event_sync_queue`
  MODIFY `sync_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_teams`
--
ALTER TABLE `event_teams`
  MODIFY `team_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `event_team_members`
--
ALTER TABLE `event_team_members`
  MODIFY `team_member_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fee_items`
--
ALTER TABLE `fee_items`
  MODIFY `fee_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_completion_logs`
--
ALTER TABLE `fe_completion_logs`
  MODIFY `completion_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_department_heads`
--
ALTER TABLE `fe_department_heads`
  MODIFY `department_head_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_evaluation_questions`
--
ALTER TABLE `fe_evaluation_questions`
  MODIFY `question_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_evaluation_reports`
--
ALTER TABLE `fe_evaluation_reports`
  MODIFY `report_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_evaluation_responses`
--
ALTER TABLE `fe_evaluation_responses`
  MODIFY `response_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_evaluation_schedules`
--
ALTER TABLE `fe_evaluation_schedules`
  MODIFY `schedule_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_evaluation_submissions`
--
ALTER TABLE `fe_evaluation_submissions`
  MODIFY `submission_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_grade_completion`
--
ALTER TABLE `fe_grade_completion`
  MODIFY `grade_completion_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_shs_specializations`
--
ALTER TABLE `fe_shs_specializations`
  MODIFY `specialization_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_shs_strands`
--
ALTER TABLE `fe_shs_strands`
  MODIFY `strand_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_shs_tracks`
--
ALTER TABLE `fe_shs_tracks`
  MODIFY `track_id` tinyint(4) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fe_teaching_assignments`
--
ALTER TABLE `fe_teaching_assignments`
  MODIFY `assignment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `guidance_appointments`
--
ALTER TABLE `guidance_appointments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `guidance_counselor_availability`
--
ALTER TABLE `guidance_counselor_availability`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `guidance_follow_ups`
--
ALTER TABLE `guidance_follow_ups`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `guidance_integration_settings`
--
ALTER TABLE `guidance_integration_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `guidance_records`
--
ALTER TABLE `guidance_records`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `guidance_referrals`
--
ALTER TABLE `guidance_referrals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `idcard_iadfc_idcards`
--
ALTER TABLE `idcard_iadfc_idcards`
  MODIFY `CardId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `idcard_iadfc_idreleases`
--
ALTER TABLE `idcard_iadfc_idreleases`
  MODIFY `ReleaseId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `idcard_iadfc_printrecords`
--
ALTER TABLE `idcard_iadfc_printrecords`
  MODIFY `PrintId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `idcard_persons`
--
ALTER TABLE `idcard_persons`
  MODIFY `PersonId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `instructors`
--
ALTER TABLE `instructors`
  MODIFY `instructor_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maint_assets`
--
ALTER TABLE `maint_assets`
  MODIFY `asset_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maint_attachments`
--
ALTER TABLE `maint_attachments`
  MODIFY `attachment_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maint_inspections`
--
ALTER TABLE `maint_inspections`
  MODIFY `inspection_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maint_inspection_findings`
--
ALTER TABLE `maint_inspection_findings`
  MODIFY `finding_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maint_locations`
--
ALTER TABLE `maint_locations`
  MODIFY `location_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maint_maintenance_requests`
--
ALTER TABLE `maint_maintenance_requests`
  MODIFY `request_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maint_repair_updates`
--
ALTER TABLE `maint_repair_updates`
  MODIFY `update_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maint_request_comments`
--
ALTER TABLE `maint_request_comments`
  MODIFY `comment_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_companies`
--
ALTER TABLE `ojt_companies`
  MODIFY `company_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_daily_time_records`
--
ALTER TABLE `ojt_daily_time_records`
  MODIFY `dtr_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_documents`
--
ALTER TABLE `ojt_documents`
  MODIFY `document_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_evaluations`
--
ALTER TABLE `ojt_evaluations`
  MODIFY `evaluation_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_evaluation_criteria`
--
ALTER TABLE `ojt_evaluation_criteria`
  MODIFY `criterion_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_evaluation_scores`
--
ALTER TABLE `ojt_evaluation_scores`
  MODIFY `score_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_internship_assignments`
--
ALTER TABLE `ojt_internship_assignments`
  MODIFY `assignment_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_password_reset_requests`
--
ALTER TABLE `ojt_password_reset_requests`
  MODIFY `request_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_progress_reports`
--
ALTER TABLE `ojt_progress_reports`
  MODIFY `progress_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_required_documents`
--
ALTER TABLE `ojt_required_documents`
  MODIFY `requirement_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ojt_supervisors`
--
ALTER TABLE `ojt_supervisors`
  MODIFY `supervisor_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pre_enrollments`
--
ALTER TABLE `pre_enrollments`
  MODIFY `pre_enrollment_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pre_enrollment_subjects`
--
ALTER TABLE `pre_enrollment_subjects`
  MODIFY `pre_enrollment_subject_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `programs`
--
ALTER TABLE `programs`
  MODIFY `program_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `readmit_applications`
--
ALTER TABLE `readmit_applications`
  MODIFY `seq` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `readmit_application_history`
--
ALTER TABLE `readmit_application_history`
  MODIFY `seq` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `readmit_documents`
--
ALTER TABLE `readmit_documents`
  MODIFY `seq` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `readmit_requirements`
--
ALTER TABLE `readmit_requirements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `report_exports`
--
ALTER TABLE `report_exports`
  MODIFY `report_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `schema_migrations`
--
ALTER TABLE `schema_migrations`
  MODIFY `migration_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_application_documents`
--
ALTER TABLE `scholar_application_documents`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_application_evaluations`
--
ALTER TABLE `scholar_application_evaluations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_application_status_histories`
--
ALTER TABLE `scholar_application_status_histories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_document_reviews`
--
ALTER TABLE `scholar_document_reviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_eligibility_results`
--
ALTER TABLE `scholar_eligibility_results`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_eligibility_rules`
--
ALTER TABLE `scholar_eligibility_rules`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_failed_jobs`
--
ALTER TABLE `scholar_failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_jobs`
--
ALTER TABLE `scholar_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_personal_access_tokens`
--
ALTER TABLE `scholar_personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_renewal_applications`
--
ALTER TABLE `scholar_renewal_applications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_scholarship_appeals`
--
ALTER TABLE `scholar_scholarship_appeals`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_scholarship_applications`
--
ALTER TABLE `scholar_scholarship_applications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_scholarship_awards`
--
ALTER TABLE `scholar_scholarship_awards`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_scholarship_programs`
--
ALTER TABLE `scholar_scholarship_programs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scholar_scholarship_requirements`
--
ALTER TABLE `scholar_scholarship_requirements`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sch_class_meetings`
--
ALTER TABLE `sch_class_meetings`
  MODIFY `meeting_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sch_rooms`
--
ALTER TABLE `sch_rooms`
  MODIFY `room_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sch_sync_queue`
--
ALTER TABLE `sch_sync_queue`
  MODIFY `queue_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `students`
--
ALTER TABLE `students`
  MODIFY `student_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `student_contacts`
--
ALTER TABLE `student_contacts`
  MODIFY `contact_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `student_documents`
--
ALTER TABLE `student_documents`
  MODIFY `document_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `subjects`
--
ALTER TABLE `subjects`
  MODIFY `subject_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `system_settings`
--
ALTER TABLE `system_settings`
  MODIFY `setting_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_mfa_methods`
--
ALTER TABLE `user_mfa_methods`
  MODIFY `mfa_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `academic_classes`
--
ALTER TABLE `academic_classes`
  ADD CONSTRAINT `fk_shared_class_instructor` FOREIGN KEY (`instructor_id`) REFERENCES `instructors` (`instructor_id`),
  ADD CONSTRAINT `fk_shared_class_period` FOREIGN KEY (`period_id`) REFERENCES `academic_periods` (`period_id`),
  ADD CONSTRAINT `fk_shared_class_program` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`),
  ADD CONSTRAINT `fk_shared_class_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`);

--
-- Constraints for table `access_role_permissions`
--
ALTER TABLE `access_role_permissions`
  ADD CONSTRAINT `fk_access_permission` FOREIGN KEY (`permission_id`) REFERENCES `access_permissions` (`permission_id`),
  ADD CONSTRAINT `fk_access_role` FOREIGN KEY (`role_id`) REFERENCES `access_roles` (`role_id`);

--
-- Constraints for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD CONSTRAINT `fk_log_admin` FOREIGN KEY (`admin_user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `admit_applicants`
--
ALTER TABLE `admit_applicants`
  ADD CONSTRAINT `fk_admit_applicants_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `admit_evaluations`
--
ALTER TABLE `admit_evaluations`
  ADD CONSTRAINT `fk_admit_evaluations_0_admit_applicants` FOREIGN KEY (`applicant_id`) REFERENCES `admit_applicants` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_admit_evaluations_1_users` FOREIGN KEY (`evaluator_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `admit_interviews`
--
ALTER TABLE `admit_interviews`
  ADD CONSTRAINT `fk_admit_interviews_0_admit_applicants` FOREIGN KEY (`applicant_id`) REFERENCES `admit_applicants` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_admit_interviews_1_users` FOREIGN KEY (`interviewer_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_admit_interviews_2_admit_interview_slots` FOREIGN KEY (`slot_id`) REFERENCES `admit_interview_slots` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `admit_interview_slots`
--
ALTER TABLE `admit_interview_slots`
  ADD CONSTRAINT `fk_admit_interview_slots_0_users` FOREIGN KEY (`interviewer_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `announcements`
--
ALTER TABLE `announcements`
  ADD CONSTRAINT `fk_shared_announcement_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_shared_announcement_class` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_id`);

--
-- Constraints for table `attend_members`
--
ALTER TABLE `attend_members`
  ADD CONSTRAINT `fk_attend_member_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`),
  ADD CONSTRAINT `fk_attend_member_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `auth_sessions`
--
ALTER TABLE `auth_sessions`
  ADD CONSTRAINT `fk_shared_auth_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `billing_adjustments`
--
ALTER TABLE `billing_adjustments`
  ADD CONSTRAINT `fk_bil_adj_actor` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_bil_adj_enroll` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`enrollment_id`),
  ADD CONSTRAINT `fk_bil_adj_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `billing_enrollment_discounts`
--
ALTER TABLE `billing_enrollment_discounts`
  ADD CONSTRAINT `fk_bil_enr_disc_catalog` FOREIGN KEY (`discount_id`) REFERENCES `billing_discounts` (`discount_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_bil_enr_disc_enroll` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`enrollment_id`);

--
-- Constraints for table `billing_enrollment_inbox`
--
ALTER TABLE `billing_enrollment_inbox`
  ADD CONSTRAINT `fk_bil_inbox_enroll` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`enrollment_id`),
  ADD CONSTRAINT `fk_bil_inbox_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `billing_enrollment_plans`
--
ALTER TABLE `billing_enrollment_plans`
  ADD CONSTRAINT `fk_bil_plan_enroll` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`enrollment_id`) ON DELETE CASCADE;

--
-- Constraints for table `billing_enrollment_subject_details`
--
ALTER TABLE `billing_enrollment_subject_details`
  ADD CONSTRAINT `fk_bil_sub_enrsub` FOREIGN KEY (`enrollment_subject_id`) REFERENCES `enrollment_subjects` (`enrollment_subject_id`) ON DELETE CASCADE;

--
-- Constraints for table `billing_fee_rules`
--
ALTER TABLE `billing_fee_rules`
  ADD CONSTRAINT `fk_bil_rule_fee` FOREIGN KEY (`fee_id`) REFERENCES `fee_items` (`fee_id`) ON DELETE CASCADE;

--
-- Constraints for table `billing_invoices`
--
ALTER TABLE `billing_invoices`
  ADD CONSTRAINT `fk_bil_invoice_enroll` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`enrollment_id`),
  ADD CONSTRAINT `fk_bil_invoice_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `billing_online_payments`
--
ALTER TABLE `billing_online_payments`
  ADD CONSTRAINT `fk_bil_online_enroll` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`enrollment_id`),
  ADD CONSTRAINT `fk_bil_online_payment` FOREIGN KEY (`payment_id`) REFERENCES `billing_payments` (`payment_id`),
  ADD CONSTRAINT `fk_bil_online_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `billing_payments`
--
ALTER TABLE `billing_payments`
  ADD CONSTRAINT `fk_bil_payment_enroll` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`enrollment_id`),
  ADD CONSTRAINT `fk_bil_payment_receiver` FOREIGN KEY (`received_by_user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_bil_payment_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `billing_payment_requests`
--
ALTER TABLE `billing_payment_requests`
  ADD CONSTRAINT `fk_bil_req_enroll` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`enrollment_id`),
  ADD CONSTRAINT `fk_bil_req_payment` FOREIGN KEY (`payment_id`) REFERENCES `billing_payments` (`payment_id`),
  ADD CONSTRAINT `fk_bil_req_reviewer` FOREIGN KEY (`reviewed_by_user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_bil_req_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `billing_term_schedules`
--
ALTER TABLE `billing_term_schedules`
  ADD CONSTRAINT `fk_bil_term_period` FOREIGN KEY (`period_id`) REFERENCES `academic_periods` (`period_id`) ON DELETE CASCADE;

--
-- Constraints for table `blocks`
--
ALTER TABLE `blocks`
  ADD CONSTRAINT `fk_block_period` FOREIGN KEY (`period_id`) REFERENCES `academic_periods` (`period_id`),
  ADD CONSTRAINT `fk_block_program` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`);

--
-- Constraints for table `campusfind_claims`
--
ALTER TABLE `campusfind_claims`
  ADD CONSTRAINT `fk_campusfind_claims_0_campusfind_items` FOREIGN KEY (`campusfind_item_id`) REFERENCES `campusfind_items` (`campusfind_item_id`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_campusfind_claims_1_users` FOREIGN KEY (`campusfind_claimant_user_id`) REFERENCES `users` (`user_id`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_campusfind_claims_2_users` FOREIGN KEY (`campusfind_reviewer_user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `campusfind_items`
--
ALTER TABLE `campusfind_items`
  ADD CONSTRAINT `fk_campusfind_items_0_users` FOREIGN KEY (`campusfind_reporter_user_id`) REFERENCES `users` (`user_id`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Constraints for table `campusfind_section_views`
--
ALTER TABLE `campusfind_section_views`
  ADD CONSTRAINT `fk_campusfind_section_views_0_users` FOREIGN KEY (`campusfind_user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `cebrms_borrowers`
--
ALTER TABLE `cebrms_borrowers`
  ADD CONSTRAINT `fk_cebrms_borrower_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`),
  ADD CONSTRAINT `fk_cebrms_borrower_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`),
  ADD CONSTRAINT `fk_cebrms_borrower_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `cebrms_borrow_items`
--
ALTER TABLE `cebrms_borrow_items`
  ADD CONSTRAINT `fk_cebrms_bi_equipment` FOREIGN KEY (`equipment_id`) REFERENCES `cebrms_equipment` (`equipment_id`),
  ADD CONSTRAINT `fk_cebrms_bi_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `cebrms_borrow_transactions` (`transaction_id`);

--
-- Constraints for table `cebrms_borrow_transactions`
--
ALTER TABLE `cebrms_borrow_transactions`
  ADD CONSTRAINT `fk_cebrms_tx_approver` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_cebrms_tx_borrower` FOREIGN KEY (`borrower_id`) REFERENCES `cebrms_borrowers` (`borrower_id`),
  ADD CONSTRAINT `fk_cebrms_tx_processor` FOREIGN KEY (`processed_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `cebrms_equipment`
--
ALTER TABLE `cebrms_equipment`
  ADD CONSTRAINT `fk_cebrms_equipment_category` FOREIGN KEY (`category_id`) REFERENCES `cebrms_equipment_categories` (`category_id`),
  ADD CONSTRAINT `fk_cebrms_equipment_maint_asset` FOREIGN KEY (`maintenance_asset_id`) REFERENCES `maint_assets` (`asset_id`) ON DELETE SET NULL;

--
-- Constraints for table `cebrms_qr_scan_logs`
--
ALTER TABLE `cebrms_qr_scan_logs`
  ADD CONSTRAINT `fk_cebrms_scan_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `cebrms_return_records`
--
ALTER TABLE `cebrms_return_records`
  ADD CONSTRAINT `fk_cebrms_return_borrow_item` FOREIGN KEY (`borrow_item_id`) REFERENCES `cebrms_borrow_items` (`borrow_item_id`),
  ADD CONSTRAINT `fk_cebrms_return_receiver` FOREIGN KEY (`received_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `class_enrollments`
--
ALTER TABLE `class_enrollments`
  ADD CONSTRAINT `fk_class_enrollments_class` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_id`),
  ADD CONSTRAINT `fk_class_enrollments_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `election_ballots`
--
ALTER TABLE `election_ballots`
  ADD CONSTRAINT `fk_election_ballots_0_election_candidacies` FOREIGN KEY (`candidate_id`) REFERENCES `election_candidacies` (`candidate_id`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Constraints for table `election_candidacies`
--
ALTER TABLE `election_candidacies`
  ADD CONSTRAINT `fk_election_candidacies_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_election_candidacies_1_election_positions` FOREIGN KEY (`position_id`) REFERENCES `election_positions` (`position_id`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_election_candidacies_2_users` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Constraints for table `election_candidate_documents`
--
ALTER TABLE `election_candidate_documents`
  ADD CONSTRAINT `fk_election_candidate_documents_0_election_candidacies` FOREIGN KEY (`candidate_id`) REFERENCES `election_candidacies` (`candidate_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `election_elections`
--
ALTER TABLE `election_elections`
  ADD CONSTRAINT `fk_election_elections_0_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `election_face_data`
--
ALTER TABLE `election_face_data`
  ADD CONSTRAINT `fk_election_face_data_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Constraints for table `election_face_verifications`
--
ALTER TABLE `election_face_verifications`
  ADD CONSTRAINT `fk_election_face_verifications_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_election_face_verifications_1_election_elections` FOREIGN KEY (`election_id`) REFERENCES `election_elections` (`election_id`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_election_face_verifications_2_users` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Constraints for table `election_positions`
--
ALTER TABLE `election_positions`
  ADD CONSTRAINT `fk_election_positions_0_election_elections` FOREIGN KEY (`election_id`) REFERENCES `election_elections` (`election_id`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Constraints for table `election_results`
--
ALTER TABLE `election_results`
  ADD CONSTRAINT `fk_election_results_0_election_candidacies` FOREIGN KEY (`candidate_id`) REFERENCES `election_candidacies` (`candidate_id`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Constraints for table `election_security_sessions`
--
ALTER TABLE `election_security_sessions`
  ADD CONSTRAINT `fk_election_security_sessions_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `election_vote_records`
--
ALTER TABLE `election_vote_records`
  ADD CONSTRAINT `fk_election_vote_records_0_election_positions` FOREIGN KEY (`position_id`) REFERENCES `election_positions` (`position_id`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Constraints for table `ems_employee_details`
--
ALTER TABLE `ems_employee_details`
  ADD CONSTRAINT `fk_ems_employee_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `ems_employee_documents`
--
ALTER TABLE `ems_employee_documents`
  ADD CONSTRAINT `fk_ems_doc_employee` FOREIGN KEY (`employee_user_id`) REFERENCES `ems_employee_details` (`user_id`),
  ADD CONSTRAINT `fk_ems_doc_uploader` FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `enrollments`
--
ALTER TABLE `enrollments`
  ADD CONSTRAINT `fk_enroll_block` FOREIGN KEY (`block_id`) REFERENCES `blocks` (`block_id`),
  ADD CONSTRAINT `fk_enroll_confirm` FOREIGN KEY (`confirmed_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_enroll_import` FOREIGN KEY (`pre_enrollment_id`) REFERENCES `pre_enrollments` (`pre_enrollment_id`),
  ADD CONSTRAINT `fk_enroll_period` FOREIGN KEY (`period_id`) REFERENCES `academic_periods` (`period_id`),
  ADD CONSTRAINT `fk_enroll_program` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`),
  ADD CONSTRAINT `fk_enroll_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`),
  ADD CONSTRAINT `fk_enroll_verify` FOREIGN KEY (`verified_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `enrollment_charges`
--
ALTER TABLE `enrollment_charges`
  ADD CONSTRAINT `fk_charge_enrollment` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`enrollment_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_charge_fee` FOREIGN KEY (`fee_id`) REFERENCES `fee_items` (`fee_id`) ON DELETE SET NULL;

--
-- Constraints for table `enrollment_subjects`
--
ALTER TABLE `enrollment_subjects`
  ADD CONSTRAINT `fk_ensub_enrollment` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`enrollment_id`),
  ADD CONSTRAINT `fk_ensub_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`);

--
-- Constraints for table `eteeap_applications`
--
ALTER TABLE `eteeap_applications`
  ADD CONSTRAINT `fk_eteeap_applications_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `eteeap_assessments`
--
ALTER TABLE `eteeap_assessments`
  ADD CONSTRAINT `fk_eteeap_assessments_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_eteeap_assessments_1_users` FOREIGN KEY (`assessor_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `eteeap_billing_fees`
--
ALTER TABLE `eteeap_billing_fees`
  ADD CONSTRAINT `fk_eteeap_billing_fees_0_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `eteeap_billing_invoices`
--
ALTER TABLE `eteeap_billing_invoices`
  ADD CONSTRAINT `fk_eteeap_billing_invoices_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`),
  ADD CONSTRAINT `fk_eteeap_billing_invoices_1_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_eteeap_billing_invoices_2_eteeap_billing_fees` FOREIGN KEY (`fee_id`) REFERENCES `eteeap_billing_fees` (`id`),
  ADD CONSTRAINT `fk_eteeap_billing_invoices_3_users` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `eteeap_billing_payments`
--
ALTER TABLE `eteeap_billing_payments`
  ADD CONSTRAINT `fk_eteeap_billing_payments_0_users` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_eteeap_billing_payments_1_eteeap_billing_invoices` FOREIGN KEY (`invoice_id`) REFERENCES `eteeap_billing_invoices` (`id`),
  ADD CONSTRAINT `fk_eteeap_billing_payments_2_users` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `eteeap_credits`
--
ALTER TABLE `eteeap_credits`
  ADD CONSTRAINT `fk_eteeap_credits_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_eteeap_credits_1_users` FOREIGN KEY (`decided_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_eteeap_credits_2_users` FOREIGN KEY (`evaluator_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `eteeap_education_records`
--
ALTER TABLE `eteeap_education_records`
  ADD CONSTRAINT `fk_eteeap_education_records_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `eteeap_employment_records`
--
ALTER TABLE `eteeap_employment_records`
  ADD CONSTRAINT `fk_eteeap_employment_records_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `eteeap_evaluations`
--
ALTER TABLE `eteeap_evaluations`
  ADD CONSTRAINT `fk_eteeap_evaluations_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_eteeap_evaluations_1_users` FOREIGN KEY (`assessor_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `eteeap_grades`
--
ALTER TABLE `eteeap_grades`
  ADD CONSTRAINT `fk_eteeap_grades_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_eteeap_grades_1_users` FOREIGN KEY (`assessor_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `eteeap_messages`
--
ALTER TABLE `eteeap_messages`
  ADD CONSTRAINT `fk_eteeap_messages_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_eteeap_messages_1_users` FOREIGN KEY (`sender_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `eteeap_program_offerings`
--
ALTER TABLE `eteeap_program_offerings`
  ADD CONSTRAINT `fk_eteeap_program_offerings_0_users` FOREIGN KEY (`configured_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `eteeap_uploads`
--
ALTER TABLE `eteeap_uploads`
  ADD CONSTRAINT `fk_eteeap_uploads_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_eteeap_uploads_1_eteeap_uploads` FOREIGN KEY (`replaces_upload_id`) REFERENCES `eteeap_uploads` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_eteeap_uploads_2_users` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `eteeap_upload_events`
--
ALTER TABLE `eteeap_upload_events`
  ADD CONSTRAINT `fk_eteeap_upload_events_0_users` FOREIGN KEY (`actor_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_eteeap_upload_events_1_eteeap_uploads` FOREIGN KEY (`upload_id`) REFERENCES `eteeap_uploads` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `event_criteria`
--
ALTER TABLE `event_criteria`
  ADD CONSTRAINT `fk_event_criteria_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON UPDATE CASCADE;

--
-- Constraints for table `event_entries`
--
ALTER TABLE `event_entries`
  ADD CONSTRAINT `fk_event_entries_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_entries_1_event_participants` FOREIGN KEY (`participant_id`) REFERENCES `event_participants` (`participant_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_entries_2_event_teams` FOREIGN KEY (`team_id`) REFERENCES `event_teams` (`team_id`) ON UPDATE CASCADE;

--
-- Constraints for table `event_events`
--
ALTER TABLE `event_events`
  ADD CONSTRAINT `fk_event_events_0_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `event_generated_reports`
--
ALTER TABLE `event_generated_reports`
  ADD CONSTRAINT `fk_event_generated_reports_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_generated_reports_1_users` FOREIGN KEY (`generated_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `event_judges`
--
ALTER TABLE `event_judges`
  ADD CONSTRAINT `fk_event_judges_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_judges_1_users` FOREIGN KEY (`judge_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `event_participant_photos`
--
ALTER TABLE `event_participant_photos`
  ADD CONSTRAINT `fk_event_participant_photos_0_event_participants` FOREIGN KEY (`participant_id`) REFERENCES `event_participants` (`participant_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `event_point_awards`
--
ALTER TABLE `event_point_awards`
  ADD CONSTRAINT `fk_event_point_awards_0_users` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_point_awards_1_event_participants` FOREIGN KEY (`participant_id`) REFERENCES `event_participants` (`participant_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_point_awards_2_event_result_summaries` FOREIGN KEY (`result_id`) REFERENCES `event_result_summaries` (`result_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_point_awards_3_event_teams` FOREIGN KEY (`team_id`) REFERENCES `event_teams` (`team_id`) ON UPDATE CASCADE;

--
-- Constraints for table `event_point_rules`
--
ALTER TABLE `event_point_rules`
  ADD CONSTRAINT `fk_event_point_rules_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON UPDATE CASCADE;

--
-- Constraints for table `event_result_summaries`
--
ALTER TABLE `event_result_summaries`
  ADD CONSTRAINT `fk_event_result_summaries_0_event_entries` FOREIGN KEY (`entry_id`) REFERENCES `event_entries` (`entry_id`) ON UPDATE CASCADE;

--
-- Constraints for table `event_scores`
--
ALTER TABLE `event_scores`
  ADD CONSTRAINT `fk_event_scores_0_event_judges` FOREIGN KEY (`assignment_id`) REFERENCES `event_judges` (`assignment_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_scores_1_event_criteria` FOREIGN KEY (`criterion_id`) REFERENCES `event_criteria` (`criterion_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_scores_2_event_entries` FOREIGN KEY (`entry_id`) REFERENCES `event_entries` (`entry_id`) ON UPDATE CASCADE;

--
-- Constraints for table `event_sports_matches`
--
ALTER TABLE `event_sports_matches`
  ADD CONSTRAINT `fk_event_sports_matches_0_event_entries` FOREIGN KEY (`entry_a_id`) REFERENCES `event_entries` (`entry_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_sports_matches_1_event_entries` FOREIGN KEY (`entry_b_id`) REFERENCES `event_entries` (`entry_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_sports_matches_2_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON UPDATE CASCADE;

--
-- Constraints for table `event_staff_registration_requests`
--
ALTER TABLE `event_staff_registration_requests`
  ADD CONSTRAINT `fk_event_staff_registration_requests_0_users` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `event_tabulator_assignments`
--
ALTER TABLE `event_tabulator_assignments`
  ADD CONSTRAINT `fk_event_tabulator_assignments_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_tabulator_assignments_1_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `event_team_members`
--
ALTER TABLE `event_team_members`
  ADD CONSTRAINT `fk_event_team_members_0_event_participants` FOREIGN KEY (`participant_id`) REFERENCES `event_participants` (`participant_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_event_team_members_1_event_teams` FOREIGN KEY (`team_id`) REFERENCES `event_teams` (`team_id`) ON UPDATE CASCADE;

--
-- Constraints for table `fee_items`
--
ALTER TABLE `fee_items`
  ADD CONSTRAINT `fk_fee_period` FOREIGN KEY (`period_id`) REFERENCES `academic_periods` (`period_id`),
  ADD CONSTRAINT `fk_fee_program` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`),
  ADD CONSTRAINT `fk_fee_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`);

--
-- Constraints for table `fe_completion_logs`
--
ALTER TABLE `fe_completion_logs`
  ADD CONSTRAINT `fk_fe_completion_logs_0_fe_teaching_assignments` FOREIGN KEY (`assignment_id`) REFERENCES `fe_teaching_assignments` (`assignment_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_completion_logs_1_fe_evaluation_schedules` FOREIGN KEY (`schedule_id`) REFERENCES `fe_evaluation_schedules` (`schedule_id`) ON UPDATE CASCADE;

--
-- Constraints for table `fe_department_heads`
--
ALTER TABLE `fe_department_heads`
  ADD CONSTRAINT `fk_fe_department_heads_0_departments` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_department_heads_1_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `fe_evaluation_questions`
--
ALTER TABLE `fe_evaluation_questions`
  ADD CONSTRAINT `fk_fe_evaluation_questions_0_fe_evaluation_schedules` FOREIGN KEY (`schedule_id`) REFERENCES `fe_evaluation_schedules` (`schedule_id`) ON UPDATE CASCADE;

--
-- Constraints for table `fe_evaluation_reports`
--
ALTER TABLE `fe_evaluation_reports`
  ADD CONSTRAINT `fk_fe_evaluation_reports_0_users` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_evaluation_reports_1_departments` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_evaluation_reports_2_users` FOREIGN KEY (`faculty_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_evaluation_reports_3_users` FOREIGN KEY (`generated_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_evaluation_reports_4_programs` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_evaluation_reports_5_fe_evaluation_schedules` FOREIGN KEY (`schedule_id`) REFERENCES `fe_evaluation_schedules` (`schedule_id`) ON UPDATE CASCADE;

--
-- Constraints for table `fe_evaluation_responses`
--
ALTER TABLE `fe_evaluation_responses`
  ADD CONSTRAINT `fk_fe_evaluation_responses_0_fe_evaluation_questions` FOREIGN KEY (`question_id`) REFERENCES `fe_evaluation_questions` (`question_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_evaluation_responses_1_fe_evaluation_submissions` FOREIGN KEY (`submission_id`) REFERENCES `fe_evaluation_submissions` (`submission_id`) ON UPDATE CASCADE;

--
-- Constraints for table `fe_evaluation_schedules`
--
ALTER TABLE `fe_evaluation_schedules`
  ADD CONSTRAINT `fk_fe_evaluation_schedules_0_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_evaluation_schedules_1_users` FOREIGN KEY (`opened_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_evaluation_schedules_2_programs` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_evaluation_schedules_3_academic_periods` FOREIGN KEY (`term_id`) REFERENCES `academic_periods` (`period_id`) ON UPDATE CASCADE;

--
-- Constraints for table `fe_evaluation_submissions`
--
ALTER TABLE `fe_evaluation_submissions`
  ADD CONSTRAINT `fk_fe_evaluation_submissions_0_fe_teaching_assignments` FOREIGN KEY (`assignment_id`) REFERENCES `fe_teaching_assignments` (`assignment_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_evaluation_submissions_1_fe_evaluation_schedules` FOREIGN KEY (`schedule_id`) REFERENCES `fe_evaluation_schedules` (`schedule_id`) ON UPDATE CASCADE;

--
-- Constraints for table `fe_grade_completion`
--
ALTER TABLE `fe_grade_completion`
  ADD CONSTRAINT `fk_fe_grade_completion_0_fe_teaching_assignments` FOREIGN KEY (`assignment_id`) REFERENCES `fe_teaching_assignments` (`assignment_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_grade_completion_2_users` FOREIGN KEY (`validated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_grade_completion_class_enrollments` FOREIGN KEY (`enrollment_id`) REFERENCES `class_enrollments` (`enrollment_id`) ON UPDATE CASCADE;

--
-- Constraints for table `fe_shs_specializations`
--
ALTER TABLE `fe_shs_specializations`
  ADD CONSTRAINT `fk_fe_shs_specializations_0_fe_shs_strands` FOREIGN KEY (`strand_id`) REFERENCES `fe_shs_strands` (`strand_id`) ON UPDATE CASCADE;

--
-- Constraints for table `fe_shs_strands`
--
ALTER TABLE `fe_shs_strands`
  ADD CONSTRAINT `fk_fe_shs_strands_0_programs` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_shs_strands_1_fe_shs_tracks` FOREIGN KEY (`track_id`) REFERENCES `fe_shs_tracks` (`track_id`) ON UPDATE CASCADE;

--
-- Constraints for table `fe_teaching_assignments`
--
ALTER TABLE `fe_teaching_assignments`
  ADD CONSTRAINT `fk_fe_teaching_assignments_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_fe_teaching_assignments_1_users` FOREIGN KEY (`instructor_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `guidance_appointments`
--
ALTER TABLE `guidance_appointments`
  ADD CONSTRAINT `fk_guidance_appointments_0_students` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`),
  ADD CONSTRAINT `fk_guidance_appointments_1_guidance_staff_profiles` FOREIGN KEY (`staff_id`) REFERENCES `guidance_staff_profiles` (`staff_id`),
  ADD CONSTRAINT `fk_guidance_appointments_2_guidance_counselor_availability` FOREIGN KEY (`availability_id`) REFERENCES `guidance_counselor_availability` (`id`);

--
-- Constraints for table `guidance_counselor_availability`
--
ALTER TABLE `guidance_counselor_availability`
  ADD CONSTRAINT `fk_guidance_counselor_availability_0_guidance_sta_44a23d93` FOREIGN KEY (`staff_id`) REFERENCES `guidance_staff_profiles` (`staff_id`);

--
-- Constraints for table `guidance_follow_ups`
--
ALTER TABLE `guidance_follow_ups`
  ADD CONSTRAINT `fk_guidance_follow_ups_0_guidance_records` FOREIGN KEY (`record_id`) REFERENCES `guidance_records` (`id`),
  ADD CONSTRAINT `fk_guidance_follow_ups_1_guidance_staff_profiles` FOREIGN KEY (`staff_id`) REFERENCES `guidance_staff_profiles` (`staff_id`);

--
-- Constraints for table `guidance_records`
--
ALTER TABLE `guidance_records`
  ADD CONSTRAINT `fk_guidance_records_0_students` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`),
  ADD CONSTRAINT `fk_guidance_records_1_guidance_appointments` FOREIGN KEY (`appointment_id`) REFERENCES `guidance_appointments` (`id`),
  ADD CONSTRAINT `fk_guidance_records_2_guidance_staff_profiles` FOREIGN KEY (`staff_id`) REFERENCES `guidance_staff_profiles` (`staff_id`);

--
-- Constraints for table `guidance_referrals`
--
ALTER TABLE `guidance_referrals`
  ADD CONSTRAINT `fk_guidance_referrals_0_students` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`),
  ADD CONSTRAINT `fk_guidance_referrals_1_guidance_staff_profiles` FOREIGN KEY (`staff_id`) REFERENCES `guidance_staff_profiles` (`staff_id`);

--
-- Constraints for table `guidance_staff_profiles`
--
ALTER TABLE `guidance_staff_profiles`
  ADD CONSTRAINT `fk_guidance_staff_profiles_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `idcard_iadfc_idcards`
--
ALTER TABLE `idcard_iadfc_idcards`
  ADD CONSTRAINT `fk_idcard_iadfc_idcards_0_idcard_persons` FOREIGN KEY (`PersonId`) REFERENCES `idcard_persons` (`PersonId`),
  ADD CONSTRAINT `fk_idcard_iadfc_idcards_1_users` FOREIGN KEY (`GeneratedBy`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `idcard_iadfc_idreleases`
--
ALTER TABLE `idcard_iadfc_idreleases`
  ADD CONSTRAINT `fk_idcard_iadfc_idreleases_0_idcard_iadfc_idcards` FOREIGN KEY (`CardId`) REFERENCES `idcard_iadfc_idcards` (`CardId`),
  ADD CONSTRAINT `fk_idcard_iadfc_idreleases_1_users` FOREIGN KEY (`ReleasedBy`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `idcard_iadfc_printrecords`
--
ALTER TABLE `idcard_iadfc_printrecords`
  ADD CONSTRAINT `fk_idcard_iadfc_printrecords_0_idcard_iadfc_idcards` FOREIGN KEY (`CardId`) REFERENCES `idcard_iadfc_idcards` (`CardId`),
  ADD CONSTRAINT `fk_idcard_iadfc_printrecords_1_users` FOREIGN KEY (`PrintedBy`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `idcard_persons`
--
ALTER TABLE `idcard_persons`
  ADD CONSTRAINT `fk_idcard_person_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`),
  ADD CONSTRAINT `fk_idcard_person_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `instructors`
--
ALTER TABLE `instructors`
  ADD CONSTRAINT `fk_shared_inst_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`),
  ADD CONSTRAINT `fk_shared_inst_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `lms_assignments`
--
ALTER TABLE `lms_assignments`
  ADD CONSTRAINT `fk_lms_assignments_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_lms_assignments_1_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_uid`);

--
-- Constraints for table `lms_discussion_posts`
--
ALTER TABLE `lms_discussion_posts`
  ADD CONSTRAINT `fk_lms_discussion_posts_0_users` FOREIGN KEY (`author_id`) REFERENCES `users` (`user_uid`),
  ADD CONSTRAINT `fk_lms_discussion_posts_1_lms_discussion_topics` FOREIGN KEY (`topic_id`) REFERENCES `lms_discussion_topics` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `lms_discussion_topics`
--
ALTER TABLE `lms_discussion_topics`
  ADD CONSTRAINT `fk_lms_discussion_topics_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_lms_discussion_topics_1_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_uid`);

--
-- Constraints for table `lms_materials`
--
ALTER TABLE `lms_materials`
  ADD CONSTRAINT `fk_lms_materials_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_lms_materials_1_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_uid`);

--
-- Constraints for table `lms_quizzes`
--
ALTER TABLE `lms_quizzes`
  ADD CONSTRAINT `fk_lms_quizzes_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_lms_quizzes_1_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_uid`);

--
-- Constraints for table `lms_quiz_answer_keys`
--
ALTER TABLE `lms_quiz_answer_keys`
  ADD CONSTRAINT `fk_lms_quiz_answer_keys_0_lms_quiz_questions` FOREIGN KEY (`question_id`) REFERENCES `lms_quiz_questions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `lms_quiz_attempts`
--
ALTER TABLE `lms_quiz_attempts`
  ADD CONSTRAINT `fk_lms_quiz_attempts_0_lms_quizzes` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_lms_quiz_attempts_1_users` FOREIGN KEY (`student_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE;

--
-- Constraints for table `lms_quiz_questions`
--
ALTER TABLE `lms_quiz_questions`
  ADD CONSTRAINT `fk_lms_quiz_questions_0_lms_quizzes` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `lms_registration_applications`
--
ALTER TABLE `lms_registration_applications`
  ADD CONSTRAINT `fk_lms_registration_applications_0_users` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_uid`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_lms_registration_applications_1_users` FOREIGN KEY (`auth_user_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE;

--
-- Constraints for table `lms_registration_class_links`
--
ALTER TABLE `lms_registration_class_links`
  ADD CONSTRAINT `fk_lms_registration_class_links_0_lms_registratio_6e8f1059` FOREIGN KEY (`application_id`) REFERENCES `lms_registration_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_lms_registration_class_links_1_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE;

--
-- Constraints for table `lms_submissions`
--
ALTER TABLE `lms_submissions`
  ADD CONSTRAINT `fk_lms_submissions_0_lms_assignments` FOREIGN KEY (`assignment_id`) REFERENCES `lms_assignments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_lms_submissions_1_users` FOREIGN KEY (`graded_by`) REFERENCES `users` (`user_uid`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_lms_submissions_2_users` FOREIGN KEY (`student_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE;

--
-- Constraints for table `lms_sync_logs`
--
ALTER TABLE `lms_sync_logs`
  ADD CONSTRAINT `fk_lms_sync_logs_0_users` FOREIGN KEY (`initiated_by`) REFERENCES `users` (`user_uid`) ON DELETE SET NULL;

--
-- Constraints for table `maint_assets`
--
ALTER TABLE `maint_assets`
  ADD CONSTRAINT `fk_maint_assets_0_maint_locations` FOREIGN KEY (`location_id`) REFERENCES `maint_locations` (`location_id`);

--
-- Constraints for table `maint_attachments`
--
ALTER TABLE `maint_attachments`
  ADD CONSTRAINT `fk_maint_attachments_0_maint_inspection_findings` FOREIGN KEY (`finding_id`) REFERENCES `maint_inspection_findings` (`finding_id`),
  ADD CONSTRAINT `fk_maint_attachments_1_maint_maintenance_requests` FOREIGN KEY (`request_id`) REFERENCES `maint_maintenance_requests` (`request_id`),
  ADD CONSTRAINT `fk_maint_attachments_2_maint_repair_updates` FOREIGN KEY (`update_id`) REFERENCES `maint_repair_updates` (`update_id`),
  ADD CONSTRAINT `fk_maint_attachments_3_maint_employees` FOREIGN KEY (`uploaded_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

--
-- Constraints for table `maint_employees`
--
ALTER TABLE `maint_employees`
  ADD CONSTRAINT `fk_maint_employees_account` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `maint_inspections`
--
ALTER TABLE `maint_inspections`
  ADD CONSTRAINT `fk_maint_inspections_0_maint_employees` FOREIGN KEY (`created_by_employee_id`) REFERENCES `maint_employees` (`employee_id`),
  ADD CONSTRAINT `fk_maint_inspections_1_maint_employees` FOREIGN KEY (`personnel_employee_id`) REFERENCES `maint_employees` (`employee_id`),
  ADD CONSTRAINT `fk_maint_inspections_2_maint_employees` FOREIGN KEY (`reviewed_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

--
-- Constraints for table `maint_inspection_findings`
--
ALTER TABLE `maint_inspection_findings`
  ADD CONSTRAINT `fk_maint_inspection_findings_0_maint_assets` FOREIGN KEY (`asset_id`) REFERENCES `maint_assets` (`asset_id`),
  ADD CONSTRAINT `fk_maint_inspection_findings_1_maint_inspections` FOREIGN KEY (`inspection_id`) REFERENCES `maint_inspections` (`inspection_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_maint_inspection_findings_2_maint_maintenance_requests` FOREIGN KEY (`request_id`) REFERENCES `maint_maintenance_requests` (`request_id`);

--
-- Constraints for table `maint_maintenance_administrators`
--
ALTER TABLE `maint_maintenance_administrators`
  ADD CONSTRAINT `fk_maint_maintenance_administrators_0_maint_employees` FOREIGN KEY (`employee_id`) REFERENCES `maint_employees` (`employee_id`);

--
-- Constraints for table `maint_maintenance_requests`
--
ALTER TABLE `maint_maintenance_requests`
  ADD CONSTRAINT `fk_maint_maintenance_requests_0_maint_assets` FOREIGN KEY (`asset_id`) REFERENCES `maint_assets` (`asset_id`),
  ADD CONSTRAINT `fk_maint_maintenance_requests_1_maint_employees` FOREIGN KEY (`assigned_by_employee_id`) REFERENCES `maint_employees` (`employee_id`),
  ADD CONSTRAINT `fk_maint_maintenance_requests_2_maint_employees` FOREIGN KEY (`assigned_to_employee_id`) REFERENCES `maint_employees` (`employee_id`),
  ADD CONSTRAINT `fk_maint_maintenance_requests_3_maint_employees` FOREIGN KEY (`reported_by_employee_id`) REFERENCES `maint_employees` (`employee_id`),
  ADD CONSTRAINT `fk_maint_maintenance_requests_4_maint_locations` FOREIGN KEY (`reported_location_id`) REFERENCES `maint_locations` (`location_id`),
  ADD CONSTRAINT `fk_maint_maintenance_requests_5_maint_employees` FOREIGN KEY (`verified_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

--
-- Constraints for table `maint_repair_updates`
--
ALTER TABLE `maint_repair_updates`
  ADD CONSTRAINT `fk_maint_repair_updates_0_maint_maintenance_requests` FOREIGN KEY (`request_id`) REFERENCES `maint_maintenance_requests` (`request_id`),
  ADD CONSTRAINT `fk_maint_repair_updates_1_maint_employees` FOREIGN KEY (`updated_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

--
-- Constraints for table `maint_request_comments`
--
ALTER TABLE `maint_request_comments`
  ADD CONSTRAINT `fk_maint_request_comments_0_maint_employees` FOREIGN KEY (`employee_id`) REFERENCES `maint_employees` (`employee_id`),
  ADD CONSTRAINT `fk_maint_request_comments_1_maint_maintenance_requests` FOREIGN KEY (`request_id`) REFERENCES `maint_maintenance_requests` (`request_id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_shared_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `ojt_daily_time_records`
--
ALTER TABLE `ojt_daily_time_records`
  ADD CONSTRAINT `fk_ojt_dtr_assignment` FOREIGN KEY (`assignment_id`) REFERENCES `ojt_internship_assignments` (`assignment_id`),
  ADD CONSTRAINT `fk_ojt_dtr_verifier` FOREIGN KEY (`verified_by`) REFERENCES `ojt_supervisors` (`supervisor_id`);

--
-- Constraints for table `ojt_documents`
--
ALTER TABLE `ojt_documents`
  ADD CONSTRAINT `fk_ojt_doc_assignment` FOREIGN KEY (`assignment_id`) REFERENCES `ojt_internship_assignments` (`assignment_id`),
  ADD CONSTRAINT `fk_ojt_doc_uploader` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `ojt_dtr_breaks`
--
ALTER TABLE `ojt_dtr_breaks`
  ADD CONSTRAINT `fk_ojt_break_dtr` FOREIGN KEY (`dtr_id`) REFERENCES `ojt_daily_time_records` (`dtr_id`) ON DELETE CASCADE;

--
-- Constraints for table `ojt_evaluations`
--
ALTER TABLE `ojt_evaluations`
  ADD CONSTRAINT `fk_ojt_eval_assignment` FOREIGN KEY (`assignment_id`) REFERENCES `ojt_internship_assignments` (`assignment_id`),
  ADD CONSTRAINT `fk_ojt_eval_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_ojt_eval_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `ojt_supervisors` (`supervisor_id`);

--
-- Constraints for table `ojt_evaluation_drafts`
--
ALTER TABLE `ojt_evaluation_drafts`
  ADD CONSTRAINT `fk_ojt_draft_assignment` FOREIGN KEY (`assignment_id`) REFERENCES `ojt_internship_assignments` (`assignment_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ojt_draft_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `ojt_supervisors` (`supervisor_id`);

--
-- Constraints for table `ojt_evaluation_scores`
--
ALTER TABLE `ojt_evaluation_scores`
  ADD CONSTRAINT `fk_ojt_score_criterion` FOREIGN KEY (`criterion_id`) REFERENCES `ojt_evaluation_criteria` (`criterion_id`),
  ADD CONSTRAINT `fk_ojt_score_eval` FOREIGN KEY (`evaluation_id`) REFERENCES `ojt_evaluations` (`evaluation_id`);

--
-- Constraints for table `ojt_internship_assignments`
--
ALTER TABLE `ojt_internship_assignments`
  ADD CONSTRAINT `fk_ojt_assignment_company` FOREIGN KEY (`company_id`) REFERENCES `ojt_companies` (`company_id`),
  ADD CONSTRAINT `fk_ojt_assignment_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`),
  ADD CONSTRAINT `fk_ojt_assignment_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `ojt_supervisors` (`supervisor_id`);

--
-- Constraints for table `ojt_password_reset_requests`
--
ALTER TABLE `ojt_password_reset_requests`
  ADD CONSTRAINT `fk_ojt_reset_coordinator` FOREIGN KEY (`resolved_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_ojt_reset_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `ojt_progress_attachments`
--
ALTER TABLE `ojt_progress_attachments`
  ADD CONSTRAINT `fk_ojt_attachment_doc` FOREIGN KEY (`document_id`) REFERENCES `ojt_documents` (`document_id`),
  ADD CONSTRAINT `fk_ojt_progress_attachment` FOREIGN KEY (`progress_id`) REFERENCES `ojt_progress_reports` (`progress_id`) ON DELETE CASCADE;

--
-- Constraints for table `ojt_progress_reports`
--
ALTER TABLE `ojt_progress_reports`
  ADD CONSTRAINT `fk_ojt_progress_assignment` FOREIGN KEY (`assignment_id`) REFERENCES `ojt_internship_assignments` (`assignment_id`),
  ADD CONSTRAINT `fk_ojt_progress_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `ojt_supervisors`
--
ALTER TABLE `ojt_supervisors`
  ADD CONSTRAINT `fk_ojt_supervisor_company` FOREIGN KEY (`company_id`) REFERENCES `ojt_companies` (`company_id`),
  ADD CONSTRAINT `fk_ojt_supervisor_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `pre_enrollments`
--
ALTER TABLE `pre_enrollments`
  ADD CONSTRAINT `fk_pre_period` FOREIGN KEY (`period_id`) REFERENCES `academic_periods` (`period_id`),
  ADD CONSTRAINT `fk_pre_program` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`),
  ADD CONSTRAINT `fk_pre_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `fk_pre_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `pre_enrollment_subjects`
--
ALTER TABLE `pre_enrollment_subjects`
  ADD CONSTRAINT `fk_presub_import` FOREIGN KEY (`pre_enrollment_id`) REFERENCES `pre_enrollments` (`pre_enrollment_id`),
  ADD CONSTRAINT `fk_presub_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`);

--
-- Constraints for table `programs`
--
ALTER TABLE `programs`
  ADD CONSTRAINT `fk_programs_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE SET NULL;

--
-- Constraints for table `readmit_applications`
--
ALTER TABLE `readmit_applications`
  ADD CONSTRAINT `fk_readmit_applications_0_users` FOREIGN KEY (`applicant_id`) REFERENCES `users` (`user_uid`),
  ADD CONSTRAINT `fk_readmit_applications_1_programs` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`),
  ADD CONSTRAINT `fk_readmit_applications_2_users` FOREIGN KEY (`assigned_evaluator_id`) REFERENCES `users` (`user_uid`);

--
-- Constraints for table `readmit_application_history`
--
ALTER TABLE `readmit_application_history`
  ADD CONSTRAINT `fk_readmit_application_history_0_readmit_applications` FOREIGN KEY (`application_id`) REFERENCES `readmit_applications` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `readmit_documents`
--
ALTER TABLE `readmit_documents`
  ADD CONSTRAINT `fk_readmit_documents_0_readmit_applications` FOREIGN KEY (`application_id`) REFERENCES `readmit_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_readmit_documents_1_readmit_requirements` FOREIGN KEY (`requirement_id`) REFERENCES `readmit_requirements` (`id`);

--
-- Constraints for table `report_exports`
--
ALTER TABLE `report_exports`
  ADD CONSTRAINT `fk_report_admin` FOREIGN KEY (`generated_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `scholar_application_documents`
--
ALTER TABLE `scholar_application_documents`
  ADD CONSTRAINT `fk_scholar_application_documents_0_scholar_schola_343d3f91` FOREIGN KEY (`scholarship_application_id`) REFERENCES `scholar_scholarship_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_scholar_application_documents_1_scholar_schola_eef01317` FOREIGN KEY (`scholarship_requirement_id`) REFERENCES `scholar_scholarship_requirements` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_scholar_application_documents_2_users` FOREIGN KEY (`verified_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `scholar_application_evaluations`
--
ALTER TABLE `scholar_application_evaluations`
  ADD CONSTRAINT `fk_scholar_application_evaluations_0_users` FOREIGN KEY (`evaluator_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_scholar_application_evaluations_1_scholar_scho_0f7834d6` FOREIGN KEY (`scholarship_application_id`) REFERENCES `scholar_scholarship_applications` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `scholar_application_status_histories`
--
ALTER TABLE `scholar_application_status_histories`
  ADD CONSTRAINT `fk_scholar_application_status_histories_0_users` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_scholar_application_status_histories_1_scholar_0eb5d191` FOREIGN KEY (`scholarship_application_id`) REFERENCES `scholar_scholarship_applications` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `scholar_document_reviews`
--
ALTER TABLE `scholar_document_reviews`
  ADD CONSTRAINT `fk_scholar_document_reviews_0_scholar_application_documents` FOREIGN KEY (`application_document_id`) REFERENCES `scholar_application_documents` (`id`),
  ADD CONSTRAINT `fk_scholar_document_reviews_1_users` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `scholar_eligibility_results`
--
ALTER TABLE `scholar_eligibility_results`
  ADD CONSTRAINT `fk_scholar_eligibility_results_0_users` FOREIGN KEY (`checked_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_scholar_eligibility_results_1_scholar_scholars_433b4b93` FOREIGN KEY (`scholarship_application_id`) REFERENCES `scholar_scholarship_applications` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `scholar_eligibility_rules`
--
ALTER TABLE `scholar_eligibility_rules`
  ADD CONSTRAINT `fk_scholar_eligibility_rules_0_scholar_scholarship_programs` FOREIGN KEY (`scholarship_program_id`) REFERENCES `scholar_scholarship_programs` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `scholar_household_profiles`
--
ALTER TABLE `scholar_household_profiles`
  ADD CONSTRAINT `fk_scholar_household_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `scholar_renewal_applications`
--
ALTER TABLE `scholar_renewal_applications`
  ADD CONSTRAINT `fk_scholar_renewal_applications_0_users` FOREIGN KEY (`decided_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_scholar_renewal_applications_1_scholar_scholar_9a1e773e` FOREIGN KEY (`scholarship_award_id`) REFERENCES `scholar_scholarship_awards` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_scholar_renewal_applications_2_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `scholar_scholarship_appeals`
--
ALTER TABLE `scholar_scholarship_appeals`
  ADD CONSTRAINT `fk_scholar_scholarship_appeals_0_users` FOREIGN KEY (`decided_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_scholar_scholarship_appeals_1_scholar_scholarship_awards` FOREIGN KEY (`scholarship_award_id`) REFERENCES `scholar_scholarship_awards` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_scholar_scholarship_appeals_2_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `scholar_scholarship_applications`
--
ALTER TABLE `scholar_scholarship_applications`
  ADD CONSTRAINT `fk_scholar_scholarship_applications_0_users` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_scholar_scholarship_applications_1_users` FOREIGN KEY (`decided_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_scholar_scholarship_applications_2_scholar_sch_966bff10` FOREIGN KEY (`scholarship_program_id`) REFERENCES `scholar_scholarship_programs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_scholar_scholarship_applications_3_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `scholar_scholarship_awards`
--
ALTER TABLE `scholar_scholarship_awards`
  ADD CONSTRAINT `fk_scholar_scholarship_awards_0_users` FOREIGN KEY (`awarded_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_scholar_scholarship_awards_1_scholar_scholarsh_da5a0353` FOREIGN KEY (`scholarship_application_id`) REFERENCES `scholar_scholarship_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_scholar_scholarship_awards_2_scholar_scholarsh_ed8880b1` FOREIGN KEY (`scholarship_program_id`) REFERENCES `scholar_scholarship_programs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_scholar_scholarship_awards_3_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `scholar_scholarship_programs`
--
ALTER TABLE `scholar_scholarship_programs`
  ADD CONSTRAINT `fk_scholar_scholarship_programs_0_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `scholar_scholarship_requirements`
--
ALTER TABLE `scholar_scholarship_requirements`
  ADD CONSTRAINT `fk_scholar_scholarship_requirements_0_scholar_sch_a921b9c9` FOREIGN KEY (`scholarship_program_id`) REFERENCES `scholar_scholarship_programs` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `sch_class_meetings`
--
ALTER TABLE `sch_class_meetings`
  ADD CONSTRAINT `fk_sch_meeting_class` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_id`),
  ADD CONSTRAINT `fk_sch_meeting_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_sch_meeting_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`room_id`);

--
-- Constraints for table `sch_instructor_load_settings`
--
ALTER TABLE `sch_instructor_load_settings`
  ADD CONSTRAINT `fk_sch_load_instructor` FOREIGN KEY (`instructor_id`) REFERENCES `instructors` (`instructor_id`);

--
-- Constraints for table `sch_rooms`
--
ALTER TABLE `sch_rooms`
  ADD CONSTRAINT `fk_sch_room_maint_location` FOREIGN KEY (`maintenance_location_id`) REFERENCES `maint_locations` (`location_id`);

--
-- Constraints for table `sch_sync_queue`
--
ALTER TABLE `sch_sync_queue`
  ADD CONSTRAINT `fk_sch_sync_actor` FOREIGN KEY (`queued_by_user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `staff_profiles`
--
ALTER TABLE `staff_profiles`
  ADD CONSTRAINT `fk_staff_profiles_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`),
  ADD CONSTRAINT `fk_staff_profiles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `students`
--
ALTER TABLE `students`
  ADD CONSTRAINT `fk_shared_student_school` FOREIGN KEY (`school_id`) REFERENCES `fe_schools` (`school_id`),
  ADD CONSTRAINT `fk_shared_student_specialization` FOREIGN KEY (`specialization_id`) REFERENCES `fe_shs_specializations` (`specialization_id`),
  ADD CONSTRAINT `fk_shared_student_strand` FOREIGN KEY (`strand_id`) REFERENCES `fe_shs_strands` (`strand_id`);

--
-- Constraints for table `student_contacts`
--
ALTER TABLE `student_contacts`
  ADD CONSTRAINT `fk_student_contact_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE;

--
-- Constraints for table `student_documents`
--
ALTER TABLE `student_documents`
  ADD CONSTRAINT `fk_document_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_document_uploader` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_document_verifier` FOREIGN KEY (`verified_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `student_first_enrollments`
--
ALTER TABLE `student_first_enrollments`
  ADD CONSTRAINT `fk_first_period` FOREIGN KEY (`first_period_id`) REFERENCES `academic_periods` (`period_id`),
  ADD CONSTRAINT `fk_first_program` FOREIGN KEY (`first_program_id`) REFERENCES `programs` (`program_id`),
  ADD CONSTRAINT `fk_first_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_first_user` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `subjects`
--
ALTER TABLE `subjects`
  ADD CONSTRAINT `fk_subject_program` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`);

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_shared_user_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `user_access_roles`
--
ALTER TABLE `user_access_roles`
  ADD CONSTRAINT `fk_user_role_role` FOREIGN KEY (`role_id`) REFERENCES `access_roles` (`role_id`),
  ADD CONSTRAINT `fk_user_role_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `user_mfa_methods`
--
ALTER TABLE `user_mfa_methods`
  ADD CONSTRAINT `fk_shared_mfa_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD CONSTRAINT `fk_shared_profile_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
