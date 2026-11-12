-- ADFC ONECAMPUS | CENTRALIZED, SCHEMA-ONLY INTEGRATION DESIGN
-- Created from 14 actual SQL files found in the connected ADFC OneCampus Drive folder.
-- SOURCE DATA IS NOT COPIED: NO INSERT, UPDATE, DELETE, DROP, CREDENTIALS OR BIOMETRICS.
-- Architectural integration draft: existing subsystem PHP/Laravel/.NET code must be mapped to these names.
-- Fresh database only; do NOT import over deployed databases without tested migrations/backups.
-- MySQL 8 / MariaDB 10.4+ design, utf8mb4 / InnoDB.
-- NOTE: Repeated *_id fields are deliberate foreign keys, not duplicated person records.

CREATE DATABASE IF NOT EXISTS `adfc_onecampus` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `adfc_onecampus`;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;



-- === SHARED IDENTITY + CORE ENROLLMENT ===

CREATE TABLE IF NOT EXISTS `users` (
  `user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_uid` VARCHAR(40) NULL UNIQUE,
  `username` VARCHAR(100) NULL UNIQUE,
  `email` VARCHAR(190) NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `full_name` VARCHAR(190) NOT NULL,
  `role` VARCHAR(60) NOT NULL DEFAULT 'Student',
  `status` ENUM('Active','Inactive','Pending','Disabled','Suspended') NOT NULL DEFAULT 'Active',
  `student_id` INT UNSIGNED NULL,
  `last_login` DATETIME NULL,
  `email_verified_at` DATETIME NULL,
  `must_change_password` TINYINT(1) NOT NULL DEFAULT 0,
  `session_version` INT UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_users_student` (`student_id`),
  KEY `idx_users_role_status` (`role`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `programs` (
  program_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  program_code VARCHAR(20) NOT NULL UNIQUE,
  program_name VARCHAR(150) NOT NULL,
  department VARCHAR(100) NULL,
  authority_to_operate VARCHAR(150) NULL,
  authority_reference VARCHAR(120) NULL,
  date_approved DATE NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `program_uid` VARCHAR(40) NULL UNIQUE,
  `education_level` VARCHAR(30) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `students` (
  student_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_number VARCHAR(30) NULL UNIQUE,
  student_type VARCHAR(25) NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  middle_name VARCHAR(50) NULL,
  last_name VARCHAR(50) NOT NULL,
  extension_name VARCHAR(20) NULL,
  email VARCHAR(100) NULL,
  gender VARCHAR(10) NULL,
  birthdate DATE NULL,
  contact_number VARCHAR(20) NULL,
  home_address VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `student_uid` VARCHAR(40) NULL UNIQUE,
  `lrn` VARCHAR(40) NULL,
  `birth_place` VARCHAR(150) NULL,
  `civil_status` VARCHAR(40) NULL,
  `nationality` VARCHAR(50) NULL,
  `education_level` ENUM('College','Senior High') NULL,
  `grade_level` VARCHAR(15) NULL,
  `school_id` INT NULL,
  `strand_id` INT NULL,
  `specialization_id` INT NULL,
  `previous_school` VARCHAR(180) NULL,
  `admission_date` DATE NULL,
  `record_status` ENUM('Active','Inactive','Graduated','Transferred') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `academic_periods` (
  period_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  academic_year VARCHAR(20) NOT NULL,
  semester ENUM('1st','2nd','Summer') NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_period (academic_year,semester),
  `starts_on` DATE NULL,
  `ends_on` DATE NULL,
  `is_current` TINYINT(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `subjects` (
  subject_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  program_id INT UNSIGNED NULL,
  subject_code VARCHAR(20) NOT NULL,
  subject_title VARCHAR(150) NOT NULL,
  units DECIMAL(4,1) NOT NULL DEFAULT 0.0,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_subject_program FOREIGN KEY (program_id) REFERENCES programs(program_id),
  `subject_uid` VARCHAR(40) NULL UNIQUE,
  `description` TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pre_enrollments` (
  pre_enrollment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  reference_no VARCHAR(35) NOT NULL UNIQUE,
  student_id INT UNSIGNED NOT NULL,
  program_id INT UNSIGNED NOT NULL,
  period_id INT UNSIGNED NOT NULL,
  year_level TINYINT UNSIGNED NOT NULL,
  application_status VARCHAR(40) NOT NULL DEFAULT 'Submitted',
  is_eligible TINYINT(1) NOT NULL DEFAULT 0,
  review_status ENUM('Pending','Cleared','On Hold','Rejected') NOT NULL DEFAULT 'Pending',
  reviewed_by INT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  review_remarks VARCHAR(255) NULL,
  submitted_at DATETIME NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_pre_student FOREIGN KEY (student_id) REFERENCES students(student_id),
  CONSTRAINT fk_pre_program FOREIGN KEY (program_id) REFERENCES programs(program_id),
  CONSTRAINT fk_pre_period FOREIGN KEY (period_id) REFERENCES academic_periods(period_id),
  CONSTRAINT fk_pre_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pre_enrollment_subjects` (
  pre_enrollment_subject_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pre_enrollment_id INT UNSIGNED NOT NULL,
  subject_id INT UNSIGNED NOT NULL,
  subject_status VARCHAR(32) NULL,
  UNIQUE KEY uq_pre_subject (pre_enrollment_id,subject_id),
  CONSTRAINT fk_presub_import FOREIGN KEY (pre_enrollment_id) REFERENCES pre_enrollments(pre_enrollment_id),
  CONSTRAINT fk_presub_subject FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blocks` (
  block_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  program_id INT UNSIGNED NOT NULL,
  period_id INT UNSIGNED NOT NULL,
  year_level TINYINT UNSIGNED NOT NULL,
  block_code VARCHAR(30) NOT NULL,
  capacity INT UNSIGNED NULL,
  status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
  UNIQUE KEY uq_block (program_id,period_id,year_level,block_code),
  CONSTRAINT fk_block_program FOREIGN KEY (program_id) REFERENCES programs(program_id),
  CONSTRAINT fk_block_period FOREIGN KEY (period_id) REFERENCES academic_periods(period_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `enrollments` (
  enrollment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  enrollment_number VARCHAR(35) NULL UNIQUE,
  pre_enrollment_id INT UNSIGNED NULL UNIQUE,
  enrollment_method ENUM('Direct','Pre-Enrollment') NOT NULL DEFAULT 'Pre-Enrollment',
  student_id INT UNSIGNED NOT NULL,
  program_id INT UNSIGNED NOT NULL,
  period_id INT UNSIGNED NOT NULL,
  year_level TINYINT UNSIGNED NOT NULL,
  block_id INT UNSIGNED NULL,
  enrollment_status ENUM('Pending','Confirmed','Cancelled') NOT NULL DEFAULT 'Pending',
  student_load ENUM('Regular','Irregular') NOT NULL DEFAULT 'Regular',
  irregular_details VARCHAR(255) NULL,
  remarks VARCHAR(255) NULL,
  verified_by INT UNSIGNED NULL,
  confirmed_by INT UNSIGNED NULL,
  confirmed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_enrollment_student_period (student_id,period_id),
  CONSTRAINT fk_enroll_import FOREIGN KEY (pre_enrollment_id) REFERENCES pre_enrollments(pre_enrollment_id),
  CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES students(student_id),
  CONSTRAINT fk_enroll_program FOREIGN KEY (program_id) REFERENCES programs(program_id),
  CONSTRAINT fk_enroll_period FOREIGN KEY (period_id) REFERENCES academic_periods(period_id),
  CONSTRAINT fk_enroll_block FOREIGN KEY (block_id) REFERENCES blocks(block_id),
  CONSTRAINT fk_enroll_verify FOREIGN KEY (verified_by) REFERENCES users(user_id),
  CONSTRAINT fk_enroll_confirm FOREIGN KEY (confirmed_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `enrollment_subjects` (
  enrollment_subject_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  enrollment_id INT UNSIGNED NOT NULL,
  subject_id INT UNSIGNED NOT NULL,
  subject_status ENUM('Enrolled','Dropped') NOT NULL DEFAULT 'Enrolled',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_enrolled_subject (enrollment_id,subject_id),
  CONSTRAINT fk_ensub_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id),
  CONSTRAINT fk_ensub_subject FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `report_exports` (
  report_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  generated_by INT UNSIGNED NULL,
  report_name VARCHAR(150) NOT NULL,
  report_format ENUM('PDF','Excel','CSV') NOT NULL,
  filters_json JSON NULL,
  record_count INT UNSIGNED NOT NULL DEFAULT 0,
  file_path VARCHAR(255) NULL,
  generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_report_admin FOREIGN KEY (generated_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `activity_logs` (
  `module_code` VARCHAR(40) NOT NULL DEFAULT 'enrollment',
  `details_json` JSON NULL,
  `old_values_json` JSON NULL,
  `new_values_json` JSON NULL,
  log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_user_id INT UNSIGNED NULL,
  action VARCHAR(60) NOT NULL,
  record_type VARCHAR(60) NULL,
  record_id INT UNSIGNED NULL,
  description VARCHAR(255) NULL,
  ip_address VARCHAR(45) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_log_admin FOREIGN KEY (admin_user_id) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `student_contacts` (
  contact_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  student_id INT UNSIGNED NOT NULL,
  contact_role ENUM('Guardian','Father','Mother','Emergency') NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  relationship VARCHAR(60) NULL,
  phone VARCHAR(30) NULL,
  email VARCHAR(100) NULL,
  occupation VARCHAR(100) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_student_contact_role (student_id,contact_role),
  CONSTRAINT fk_student_contact_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `student_first_enrollments` (
  student_id INT UNSIGNED NOT NULL PRIMARY KEY,
  first_enrolled_on DATE NOT NULL,
  first_program_id INT UNSIGNED NOT NULL,
  first_academic_year VARCHAR(20) NOT NULL,
  first_semester ENUM('1st','2nd','Summer') NOT NULL,
  first_year_level TINYINT UNSIGNED NOT NULL,
  notes VARCHAR(255) NULL,
  recorded_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_first_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT fk_first_program FOREIGN KEY (first_program_id) REFERENCES programs(program_id),
  CONSTRAINT fk_first_user FOREIGN KEY (recorded_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `student_documents` (
  document_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  student_id INT UNSIGNED NOT NULL,
  document_type VARCHAR(60) NOT NULL,
  original_filename VARCHAR(180) NOT NULL,
  mime_type ENUM('application/pdf','image/jpeg','image/png') NOT NULL,
  file_size INT UNSIGNED NOT NULL,
  file_blob MEDIUMBLOB NOT NULL,
  uploaded_by INT UNSIGNED NULL,
  verification_status ENUM('Pending','Verified','Needs Resubmission') NOT NULL DEFAULT 'Pending',
  verified_by INT UNSIGNED NULL,
  verified_at DATETIME NULL,
  verification_remarks VARCHAR(255) NULL,
  uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_student_documents (student_id,uploaded_at),
  CONSTRAINT fk_document_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT fk_document_uploader FOREIGN KEY (uploaded_by) REFERENCES users(user_id) ON DELETE SET NULL,
  CONSTRAINT fk_document_verifier FOREIGN KEY (verified_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fee_items` (
  fee_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  fee_code VARCHAR(30) NOT NULL UNIQUE,
  fee_name VARCHAR(150) NOT NULL,
  fee_basis ENUM('Program','Subject') NOT NULL,
  program_id INT UNSIGNED NULL,
  subject_id INT UNSIGNED NULL,
  period_id INT UNSIGNED NULL,
  amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_fee_program FOREIGN KEY (program_id) REFERENCES programs(program_id),
  CONSTRAINT fk_fee_subject FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
  CONSTRAINT fk_fee_period FOREIGN KEY (period_id) REFERENCES academic_periods(period_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `enrollment_charges` (
  charge_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  enrollment_id INT UNSIGNED NOT NULL,
  fee_id INT UNSIGNED NULL,
  fee_name_snapshot VARCHAR(150) NOT NULL,
  amount_snapshot DECIMAL(12,2) NOT NULL,
  assessed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_enrollment_charge_fee (enrollment_id,fee_id),
  CONSTRAINT fk_charge_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
  CONSTRAINT fk_charge_fee FOREIGN KEY (fee_id) REFERENCES fee_items(fee_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- === SHARED CAMPUS ENTITIES AND SERVICES ===

CREATE TABLE IF NOT EXISTS `access_roles` (
  `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `role_name` VARCHAR(100) NOT NULL UNIQUE,
  `description` TEXT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `access_permissions` (
  `permission_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `permission_code` VARCHAR(120) NOT NULL UNIQUE,
  `description` TEXT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `access_role_permissions` (
  `role_id` INT UNSIGNED NOT NULL,
  `permission_id` INT UNSIGNED NOT NULL,
  `assigned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`,`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_access_roles` (
  `user_id` INT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  `module_code` VARCHAR(40) NOT NULL,
  PRIMARY KEY (`user_id`,`role_id`,`module_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `departments` (
  `department_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `department_code` VARCHAR(30) NOT NULL UNIQUE,
  `department_name` VARCHAR(150) NOT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `instructors` (
  `instructor_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `instructor_uid` VARCHAR(40) NULL UNIQUE,
  `user_id` INT UNSIGNED NOT NULL UNIQUE,
  `employee_number` VARCHAR(50) NULL UNIQUE,
  `department_id` INT UNSIGNED NULL,
  `designation` VARCHAR(120) NULL,
  `academic_rank` VARCHAR(100) NULL,
  `specialization` VARCHAR(255) NULL,
  `employment_type` VARCHAR(80) NULL,
  `date_hired` DATE NULL,
  `office` VARCHAR(120) NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `academic_classes` (
  `class_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `class_uid` VARCHAR(40) NULL UNIQUE,
  `program_id` INT UNSIGNED NULL,
  `subject_id` INT UNSIGNED NULL,
  `period_id` INT UNSIGNED NULL,
  `instructor_id` INT UNSIGNED NULL,
  `class_code` VARCHAR(60) NOT NULL,
  `section` VARCHAR(60) NULL,
  `year_level` TINYINT UNSIGNED NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'Active',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_academic_class_code_period` (`class_code`,`period_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `announcements` (
  `announcement_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `module_code` VARCHAR(40) NOT NULL,
  `class_id` BIGINT UNSIGNED NULL,
  `program_id` INT UNSIGNED NULL,
  `title` VARCHAR(255) NOT NULL,
  `body` LONGTEXT NOT NULL,
  `audience` VARCHAR(120) NULL,
  `created_by` INT UNSIGNED NULL,
  `is_published` TINYINT(1) NOT NULL DEFAULT 0,
  `published_at` DATETIME NULL,
  `expires_at` DATETIME NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `notifications` (
  `notification_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `module_code` VARCHAR(40) NOT NULL,
  `title` VARCHAR(200) NOT NULL,
  `message` TEXT NOT NULL,
  `link_url` VARCHAR(255) NULL,
  `reference_type` VARCHAR(60) NULL,
  `reference_id` BIGINT UNSIGNED NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `auth_sessions` (
  `session_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `token_hash` VARCHAR(255) NOT NULL UNIQUE,
  `module_code` VARCHAR(40) NOT NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_agent` VARCHAR(255) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` DATETIME NULL,
  `revoked_at` DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `schema_migrations` (
  `migration_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `module_code` VARCHAR(40) NOT NULL,
  `migration_name` VARCHAR(200) NOT NULL,
  `batch` INT NOT NULL DEFAULT 1,
  `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_schema_migration_module` (`module_code`,`migration_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `system_settings` (
  `setting_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `module_code` VARCHAR(40) NOT NULL,
  `setting_key` VARCHAR(150) NOT NULL,
  `setting_value` LONGTEXT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_shared_setting` (`module_code`,`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `staff_profiles` (
  `user_id` INT UNSIGNED NOT NULL PRIMARY KEY,
  `admin_number` VARCHAR(40) NULL UNIQUE,
  `admin_level` VARCHAR(50) NULL,
  `job_title` VARCHAR(120) NULL,
  `office` VARCHAR(120) NULL,
  `department_id` INT UNSIGNED NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_household_profiles` (
  `student_id` INT UNSIGNED NOT NULL PRIMARY KEY,
  `household_size` SMALLINT UNSIGNED NULL,
  `monthly_household_income` DECIMAL(12,2) NULL,
  `last_verified_at` DATETIME NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_mfa_methods` (
  `mfa_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `method` VARCHAR(40) NOT NULL,
  `secret_encrypted` TEXT NOT NULL,
  `is_enabled` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_user_mfa_method` (`user_id`,`method`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_profiles` (
  `user_id` INT UNSIGNED NOT NULL PRIMARY KEY,
  `avatar_path` VARCHAR(255) NULL,
  `profile_photo` MEDIUMBLOB NULL,
  `profile_photo_mime` VARCHAR(100) NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- === SUBSYSTEM-SPECIFIC TABLES (NORMALIZED NAMES) ===


-- CAMPUSFIND

CREATE TABLE IF NOT EXISTS `campusfind_items` (
  `campusfind_item_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `campusfind_reporter_user_id` INT UNSIGNED NOT NULL,
  `campusfind_item_type` ENUM('lost', 'found') NOT NULL,
  `campusfind_item_name` VARCHAR(140) NOT NULL,
  `campusfind_category` VARCHAR(60) NOT NULL,
  `campusfind_description` TEXT NOT NULL,
  `campusfind_color` VARCHAR(60) NOT NULL,
  `campusfind_location` VARCHAR(150) NOT NULL,
  `campusfind_item_date` DATE NOT NULL,
  `campusfind_photo_path` VARCHAR(255) DEFAULT NULL,
  `campusfind_status` ENUM('open', 'returned', 'closed') NOT NULL DEFAULT 'open',
  `campusfind_created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `campusfind_updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`campusfind_item_id`),
  KEY `idx_campusfind_items_browse` (`campusfind_item_type`, `campusfind_status`, `campusfind_category`),
  KEY `idx_campusfind_items_reporter` (`campusfind_reporter_user_id`),
  KEY `idx_campusfind_items_location` (`campusfind_location`),
  KEY `idx_campusfind_items_date` (`campusfind_item_date`),
  KEY `idx_campusfind_items_created` (`campusfind_created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `campusfind_claims` (
  `campusfind_claim_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `campusfind_item_id` INT UNSIGNED NOT NULL,
  `campusfind_claimant_user_id` INT UNSIGNED NOT NULL,
  `campusfind_ownership_evidence` TEXT NOT NULL,
  `campusfind_status` ENUM('pending', 'approved', 'rejected', 'completed') NOT NULL DEFAULT 'pending',
  `campusfind_reviewer_user_id` INT UNSIGNED DEFAULT NULL,
  `campusfind_review_note` TEXT DEFAULT NULL,
  `campusfind_reviewed_at` DATETIME DEFAULT NULL,
  `campusfind_completed_at` DATETIME DEFAULT NULL,
  `campusfind_created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`campusfind_claim_id`),
  KEY `idx_campusfind_claims_status` (`campusfind_status`),
  KEY `idx_campusfind_claims_item` (`campusfind_item_id`),
  KEY `idx_campusfind_claims_claimant` (`campusfind_claimant_user_id`),
  KEY `idx_campusfind_claims_reviewer` (`campusfind_reviewer_user_id`),
  KEY `idx_campusfind_claims_created` (`campusfind_created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `campusfind_section_views` (
  `campusfind_user_id` INT UNSIGNED NOT NULL,
  `campusfind_section_key` VARCHAR(24) NOT NULL,
  `campusfind_last_seen_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`campusfind_user_id`, `campusfind_section_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `campusfind_live_revisions` (
  `campusfind_resource` VARCHAR(64) NOT NULL,
  `campusfind_revision` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`campusfind_resource`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- FACULTY

CREATE TABLE IF NOT EXISTS `fe_completion_logs` (
  `completion_id` int(11) NOT NULL AUTO_INCREMENT,
  `schedule_id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `anonymous_hash` char(64) NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`completion_id`),
  UNIQUE KEY `uq_completion_log` (`schedule_id`,`assignment_id`,`anonymous_hash`),
  KEY `ix_completion_logs_assignment` (`assignment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_department_heads` (
  `department_head_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `department_id` INT UNSIGNED NOT NULL,
  `employee_number` varchar(30) DEFAULT NULL,
  `designation` varchar(100) DEFAULT 'Department Head',
  `appointment_start` date DEFAULT NULL,
  `appointment_end` date DEFAULT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`department_head_id`),
  UNIQUE KEY `uq_department_heads_user_department` (`user_id`,`department_id`),
  KEY `ix_department_heads_department_current` (`department_id`,`is_current`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_evaluation_questions` (
  `question_id` int(11) NOT NULL AUTO_INCREMENT,
  `schedule_id` int(11) NOT NULL,
  `category` varchar(60) NOT NULL,
  `question_text` text NOT NULL,
  `question_order` int(11) NOT NULL,
  `rating_min` tinyint(4) NOT NULL DEFAULT 1,
  `rating_max` tinyint(4) NOT NULL DEFAULT 5,
  `is_required` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`question_id`),
  UNIQUE KEY `uq_evaluation_question_order` (`schedule_id`,`question_order`),
  KEY `ix_evaluation_questions_schedule` (`schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_evaluation_reports` (
  `report_id` int(11) NOT NULL AUTO_INCREMENT,
  `schedule_id` int(11) NOT NULL,
  `report_level` enum('FACULTY','PROGRAM','DEPARTMENT') NOT NULL,
  `department_id` INT UNSIGNED DEFAULT NULL,
  `program_id` INT UNSIGNED DEFAULT NULL,
  `faculty_id` INT UNSIGNED DEFAULT NULL,
  `total_responses` int(11) NOT NULL DEFAULT 0,
  `average_rating` decimal(4,2) DEFAULT NULL,
  `score_percentage` decimal(5,2) DEFAULT NULL,
  `generated_by` INT UNSIGNED NOT NULL,
  `approved_by` INT UNSIGNED DEFAULT NULL,
  `release_status` enum('DRAFT','APPROVED','RELEASED','WITHHELD') NOT NULL DEFAULT 'DRAFT',
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`report_id`),
  KEY `ix_evaluation_reports_schedule` (`schedule_id`),
  KEY `ix_evaluation_reports_department` (`department_id`),
  KEY `ix_evaluation_reports_program` (`program_id`),
  KEY `ix_evaluation_reports_faculty` (`faculty_id`),
  KEY `ix_evaluation_reports_generated_by` (`generated_by`),
  KEY `ix_evaluation_reports_approved_by` (`approved_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_evaluation_responses` (
  `response_id` int(11) NOT NULL AUTO_INCREMENT,
  `submission_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `rating` tinyint(4) NOT NULL,
  `comment` text DEFAULT NULL,
  PRIMARY KEY (`response_id`),
  UNIQUE KEY `uq_evaluation_response_submission_question` (`submission_id`,`question_id`),
  KEY `ix_evaluation_responses_question` (`question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_evaluation_schedules` (
  `schedule_id` int(11) NOT NULL AUTO_INCREMENT,
  `term_id` INT UNSIGNED NOT NULL,
  `program_id` INT UNSIGNED NOT NULL,
  `opens_at` datetime NOT NULL,
  `closes_at` datetime NOT NULL,
  `status` enum('DRAFT','SCHEDULED','READY','OPEN','CLOSED','RELEASED') NOT NULL DEFAULT 'SCHEDULED',
  `grade_gate_passed` tinyint(1) NOT NULL DEFAULT 0,
  `created_by` INT UNSIGNED NOT NULL,
  `opened_by` INT UNSIGNED DEFAULT NULL,
  `opened_at` datetime DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`schedule_id`),
  UNIQUE KEY `uq_evaluation_schedule_term_program` (`term_id`,`program_id`),
  KEY `ix_evaluation_schedules_program` (`program_id`),
  KEY `ix_evaluation_schedules_creator` (`created_by`),
  KEY `ix_evaluation_schedules_opener` (`opened_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_evaluation_submissions` (
  `submission_id` int(11) NOT NULL AUTO_INCREMENT,
  `schedule_id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `anonymous_token` char(64) NOT NULL,
  `submitted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`submission_id`),
  UNIQUE KEY `uq_evaluation_submission_token` (`anonymous_token`),
  KEY `ix_evaluation_submissions_schedule_assignment` (`schedule_id`,`assignment_id`),
  KEY `fk_evaluation_submissions_assignment` (`assignment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_grade_completion` (
  `grade_completion_id` int(11) NOT NULL AUTO_INCREMENT,
  `enrollment_id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `grade_component` enum('MIDTERM','FINAL','OVERALL_FINAL') NOT NULL,
  `completion_status` enum('PENDING','SUBMITTED','VALIDATED') NOT NULL DEFAULT 'PENDING',
  `validated_by` INT UNSIGNED DEFAULT NULL,
  `validated_at` timestamp NULL DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`grade_completion_id`),
  UNIQUE KEY `uq_grade_completion_enrollment_component` (`enrollment_id`,`grade_component`),
  KEY `ix_grade_completion_assignment` (`assignment_id`),
  KEY `ix_grade_completion_validator` (`validated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_onecampus_webhook_events` (
  `event_id` varchar(128) NOT NULL,
  `event_type` varchar(100) NOT NULL,
  `payload_sha256` char(64) NOT NULL,
  `received_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `processing_status` enum('RECEIVED','PROCESSED','FAILED') NOT NULL DEFAULT 'RECEIVED',
  `processed_at` timestamp NULL DEFAULT NULL,
  `failure_reason` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`event_id`),
  KEY `ix_onecampus_webhook_received_at` (`received_at`),
  KEY `ix_onecampus_webhook_status` (`processing_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_schools` (
  `school_id` int(11) NOT NULL,
  `school_code` varchar(30) NOT NULL,
  `school_name` varchar(180) NOT NULL,
  `barangay_or_area` varchar(120) DEFAULT NULL,
  `city_municipality` varchar(100) DEFAULT NULL,
  `province` varchar(100) DEFAULT NULL,
  `region` varchar(100) DEFAULT NULL,
  `school_type` enum('PUBLIC','PRIVATE') NOT NULL DEFAULT 'PRIVATE',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`school_id`),
  UNIQUE KEY `uq_schools_code` (`school_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_shs_specializations` (
  `specialization_id` int(11) NOT NULL AUTO_INCREMENT,
  `strand_id` int(11) NOT NULL,
  `specialization_code` varchar(30) NOT NULL,
  `specialization_name` varchar(160) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`specialization_id`),
  UNIQUE KEY `uq_shs_specializations_code` (`specialization_code`),
  KEY `ix_shs_specializations_strand` (`strand_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_shs_strands` (
  `strand_id` int(11) NOT NULL AUTO_INCREMENT,
  `track_id` tinyint(4) NOT NULL,
  `program_id` INT UNSIGNED DEFAULT NULL,
  `strand_code` varchar(20) NOT NULL,
  `strand_name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`strand_id`),
  UNIQUE KEY `uq_shs_strands_code` (`strand_code`),
  KEY `ix_shs_strands_track` (`track_id`),
  KEY `ix_shs_strands_program` (`program_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_shs_tracks` (
  `track_id` tinyint(4) NOT NULL AUTO_INCREMENT,
  `track_code` varchar(20) NOT NULL,
  `track_name` varchar(100) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`track_id`),
  UNIQUE KEY `uq_shs_tracks_code` (`track_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_class_enrollments` (
  `enrollment_id` int(11) NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL,
  `class_id` BIGINT UNSIGNED NOT NULL,
  `enrollment_status` enum('ACTIVE','WITHDRAWN','COMPLETED') NOT NULL,
  `enrolled_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`enrollment_id`),
  UNIQUE KEY `uq_student_enrollment` (`student_id`,`class_id`),
  KEY `ix_student_enrollments_class` (`class_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fe_teaching_assignments` (
  `assignment_id` int(11) NOT NULL AUTO_INCREMENT,
  `class_id` BIGINT UNSIGNED NOT NULL,
  `instructor_id` INT UNSIGNED NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`assignment_id`),
  UNIQUE KEY `uq_teaching_assignment_class_instructor` (`class_id`,`instructor_id`),
  KEY `ix_teaching_assignments_instructor` (`instructor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- LMS

CREATE TABLE IF NOT EXISTS `lms_assignments` (
  `id` char(36) NOT NULL,
  `class_id` VARCHAR(40) NOT NULL,
  `title` varchar(255) NOT NULL,
  `instructions` text NOT NULL,
  `due_at` datetime DEFAULT NULL,
  `points` decimal(10,2) NOT NULL DEFAULT 100.00,
  `status` enum('draft','published','closed') NOT NULL DEFAULT 'draft',
  `created_by` VARCHAR(40) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `assignments_class_fk` (`class_id`),
  KEY `assignments_creator_fk` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_discussion_posts` (
  `id` char(36) NOT NULL,
  `topic_id` char(36) NOT NULL,
  `author_id` VARCHAR(40) NOT NULL,
  `body` text NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `posts_topic_fk` (`topic_id`),
  KEY `posts_author_fk` (`author_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_discussion_topics` (
  `id` char(36) NOT NULL,
  `class_id` VARCHAR(40) NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `created_by` VARCHAR(40) NOT NULL,
  `is_locked` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `topics_class_fk` (`class_id`),
  KEY `topics_creator_fk` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_class_enrollments` (
  `id` char(36) NOT NULL,
  `class_id` VARCHAR(40) NOT NULL,
  `student_id` VARCHAR(40) NOT NULL,
  `status` enum('enrolled','dropped','completed') NOT NULL DEFAULT 'enrolled',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `enrollments_member_unique` (`class_id`,`student_id`),
  KEY `enrollments_student_fk` (`student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_materials` (
  `id` char(36) NOT NULL,
  `class_id` VARCHAR(40) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `file_path` varchar(500) DEFAULT NULL,
  `external_url` varchar(1000) DEFAULT NULL,
  `created_by` VARCHAR(40) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `materials_class_fk` (`class_id`),
  KEY `materials_creator_fk` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_quiz_answer_keys` (
  `question_id` char(36) NOT NULL,
  `correct_answer` text NOT NULL,
  `case_sensitive` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_quiz_attempts` (
  `id` char(36) NOT NULL,
  `quiz_id` char(36) NOT NULL,
  `student_id` VARCHAR(40) NOT NULL,
  `answers` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`answers`)),
  `score` decimal(10,2) DEFAULT NULL,
  `max_score` decimal(10,2) DEFAULT NULL,
  `status` enum('in_progress','submitted') NOT NULL DEFAULT 'submitted',
  `started_at` datetime NOT NULL DEFAULT current_timestamp(),
  `submitted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `attempts_student_unique` (`quiz_id`,`student_id`),
  KEY `attempts_student_fk` (`student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_quiz_questions` (
  `id` char(36) NOT NULL,
  `quiz_id` char(36) NOT NULL,
  `prompt` text NOT NULL,
  `question_type` enum('multiple_choice','true_false','short_answer') NOT NULL,
  `options` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`options`)),
  `points` decimal(10,2) NOT NULL DEFAULT 1.00,
  `position` int(11) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `questions_quiz_fk` (`quiz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_quizzes` (
  `id` char(36) NOT NULL,
  `class_id` VARCHAR(40) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `opens_at` datetime DEFAULT NULL,
  `closes_at` datetime DEFAULT NULL,
  `time_limit_minutes` int(11) DEFAULT NULL,
  `status` enum('draft','published','closed') NOT NULL DEFAULT 'draft',
  `created_by` VARCHAR(40) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `quizzes_class_fk` (`class_id`),
  KEY `quizzes_creator_fk` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_registration_application_classes` (
  `application_id` char(36) NOT NULL,
  `class_id` VARCHAR(40) NOT NULL,
  PRIMARY KEY (`application_id`,`class_id`),
  KEY `registration_classes_class_fk` (`class_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_registration_applications` (
  `id` char(36) NOT NULL,
  `auth_user_id` VARCHAR(40) NOT NULL,
  `email` varchar(190) NOT NULL,
  `full_name` varchar(255) NOT NULL,
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
  `reviewed_by` VARCHAR(40) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_user_id` (`auth_user_id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `student_id_number` (`student_id_number`),
  KEY `registrations_reviewer_fk` (`reviewed_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_submissions` (
  `id` char(36) NOT NULL,
  `assignment_id` char(36) NOT NULL,
  `student_id` VARCHAR(40) NOT NULL,
  `content` text DEFAULT NULL,
  `file_path` varchar(500) DEFAULT NULL,
  `status` enum('draft','submitted','graded') NOT NULL DEFAULT 'submitted',
  `submitted_at` datetime NOT NULL DEFAULT current_timestamp(),
  `grade` decimal(10,2) DEFAULT NULL,
  `feedback` text DEFAULT NULL,
  `graded_by` VARCHAR(40) DEFAULT NULL,
  `graded_at` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `submissions_student_unique` (`assignment_id`,`student_id`),
  KEY `submissions_student_fk` (`student_id`),
  KEY `submissions_grader_fk` (`graded_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lms_sync_logs` (
  `id` char(36) NOT NULL,
  `initiated_by` VARCHAR(40) DEFAULT NULL,
  `status` enum('running','success','failed') NOT NULL,
  `records` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`records`)),
  `message` text DEFAULT NULL,
  `started_at` datetime NOT NULL DEFAULT current_timestamp(),
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sync_initiator_fk` (`initiated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- MAINTENANCE

CREATE TABLE IF NOT EXISTS `maint_assets` (
  `asset_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `location_id` int(10) unsigned NOT NULL,
  `asset_name` varchar(150) NOT NULL,
  `asset_type` varchar(20) NOT NULL,
  `asset_tag` varchar(50) DEFAULT NULL,
  `serial_number` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`asset_id`),
  UNIQUE KEY `assets_asset_tag_unique` (`asset_tag`),
  KEY `assets_location_id_foreign` (`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `maint_attachments` (
  `attachment_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `request_id` int(10) unsigned DEFAULT NULL,
  `update_id` int(10) unsigned DEFAULT NULL,
  `finding_id` int(10) unsigned DEFAULT NULL,
  `uploaded_by_employee_id` varchar(64) NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `uploaded_at` datetime NOT NULL,
  PRIMARY KEY (`attachment_id`),
  KEY `attachments_request_id_foreign` (`request_id`),
  KEY `attachments_update_id_foreign` (`update_id`),
  KEY `attachments_finding_id_foreign` (`finding_id`),
  KEY `attachments_uploaded_by_employee_id_foreign` (`uploaded_by_employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `maint_employees` (
  `employee_id` varchar(64) NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `maint_inspection_findings` (
  `finding_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `inspection_id` int(10) unsigned NOT NULL,
  `asset_id` int(10) unsigned NOT NULL,
  `condition_result` varchar(20) NOT NULL DEFAULT 'Not Inspected',
  `findings` text DEFAULT NULL,
  `request_id` int(10) unsigned DEFAULT NULL,
  `inspected_at` datetime DEFAULT NULL,
  PRIMARY KEY (`finding_id`),
  UNIQUE KEY `inspection_findings_inspection_id_asset_id_unique` (`inspection_id`,`asset_id`),
  KEY `inspection_findings_asset_id_foreign` (`asset_id`),
  KEY `inspection_findings_request_id_foreign` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `maint_inspections` (
  `inspection_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `inspection_title` varchar(150) NOT NULL,
  `inspection_date` date NOT NULL,
  `personnel_employee_id` varchar(64) NOT NULL,
  `created_by_employee_id` varchar(64) NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'Scheduled',
  `reviewed_by_employee_id` varchar(64) DEFAULT NULL,
  `review_remarks` text DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`inspection_id`),
  KEY `inspections_personnel_employee_id_foreign` (`personnel_employee_id`),
  KEY `inspections_created_by_employee_id_foreign` (`created_by_employee_id`),
  KEY `inspections_reviewed_by_employee_id_foreign` (`reviewed_by_employee_id`),
  KEY `inspections_inspection_date_index` (`inspection_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `maint_locations` (
  `location_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `building_name` varchar(100) NOT NULL,
  `floor_name` varchar(50) DEFAULT NULL,
  `room_or_area` varchar(100) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `maint_maintenance_administrators` (
  `employee_id` varchar(64) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `granted_at` datetime NOT NULL,
  PRIMARY KEY (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `maint_maintenance_requests` (
  `request_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
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
  `due_date` date DEFAULT NULL,
  PRIMARY KEY (`request_id`),
  KEY `maintenance_requests_asset_id_foreign` (`asset_id`),
  KEY `maintenance_requests_reported_location_id_foreign` (`reported_location_id`),
  KEY `maintenance_requests_reported_by_employee_id_foreign` (`reported_by_employee_id`),
  KEY `maintenance_requests_verified_by_employee_id_foreign` (`verified_by_employee_id`),
  KEY `maintenance_requests_assigned_to_employee_id_foreign` (`assigned_to_employee_id`),
  KEY `maintenance_requests_assigned_by_employee_id_foreign` (`assigned_by_employee_id`),
  KEY `maintenance_requests_status_index` (`status`),
  KEY `maintenance_requests_due_date_index` (`due_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `maint_repair_updates` (
  `update_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `request_id` int(10) unsigned NOT NULL,
  `updated_by_employee_id` varchar(64) NOT NULL,
  `update_type` varchar(30) NOT NULL,
  `remarks` text NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`update_id`),
  KEY `repair_updates_request_id_foreign` (`request_id`),
  KEY `repair_updates_updated_by_employee_id_foreign` (`updated_by_employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `maint_request_comments` (
  `comment_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `request_id` int(10) unsigned NOT NULL,
  `employee_id` varchar(64) NOT NULL,
  `comment_text` text NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`comment_id`),
  KEY `request_comments_request_id_foreign` (`request_id`),
  KEY `request_comments_employee_id_foreign` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- GUIDANCE

CREATE TABLE IF NOT EXISTS `guidance_staff_profiles` (
  `staff_id` INT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL UNIQUE,
  `guidance_role` VARCHAR(50) NOT NULL DEFAULT 'Counselor',
  `department` VARCHAR(100) DEFAULT 'Guidance Office',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `guidance_counselor_availability` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `staff_id` INT NOT NULL,
  `available_date` DATE NOT NULL,
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `status` ENUM('available','unavailable') NOT NULL DEFAULT 'available',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_staff_slot(staff_id,available_date,start_time),
  CONSTRAINT valid_availability_time CHECK (end_time > start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `guidance_appointments` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `staff_id` INT NOT NULL,
  `availability_id` INT NOT NULL,
  `appointment_date` DATE NOT NULL,
  `appointment_time` TIME NOT NULL,
  `concern_category` VARCHAR(100) NOT NULL,
  `appointment_type` VARCHAR(50) NOT NULL,
  `reason` VARCHAR(500),
  `status` ENUM('pending','confirmed','rescheduled','completed','cancelled') NOT NULL DEFAULT 'pending',
  `remarks` VARCHAR(255),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_appointment_staff_date(staff_id,appointment_date,appointment_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `guidance_records` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `appointment_id` INT NOT NULL UNIQUE,
  `staff_id` INT NOT NULL,
  `record_date` DATE NOT NULL,
  `record_category` VARCHAR(50) NOT NULL,
  `confidential_note` TEXT NOT NULL,
  `record_status` VARCHAR(30) NOT NULL DEFAULT 'active',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `guidance_referrals` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `staff_id` INT NOT NULL,
  `referral_date` DATE NOT NULL,
  `referral_type` VARCHAR(100) NOT NULL,
  `referred_to` VARCHAR(100) NOT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'pending',
  `remarks` VARCHAR(255),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `guidance_follow_ups` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `record_id` INT NOT NULL,
  `staff_id` INT NOT NULL,
  `follow_up_date` DATE NOT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'pending',
  `remarks` VARCHAR(255),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `guidance_integration_settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `integration_name` VARCHAR(80) NOT NULL UNIQUE,
  `enabled` BOOLEAN NOT NULL DEFAULT FALSE,
  `status` VARCHAR(30) NOT NULL DEFAULT 'not_configured',
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- EVENTS

CREATE TABLE IF NOT EXISTS `event_criteria` (
  `criterion_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_id` int(10) UNSIGNED NOT NULL,
  `criterion_name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `weight_percentage` decimal(5,2) NOT NULL,
  `maximum_score` decimal(7,2) NOT NULL,
  `display_order` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`criterion_id`),
  UNIQUE KEY `uq_criteria_uuid` (`record_uuid`),
  UNIQUE KEY `uq_event_criterion_name` (`event_id`,`criterion_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_events` (
  `event_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
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
  `publication_version` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`event_id`),
  UNIQUE KEY `uq_events_uuid` (`record_uuid`),
  KEY `fk_events_creator` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_entries` (
  `entry_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_id` int(10) UNSIGNED NOT NULL,
  `participant_id` int(10) UNSIGNED DEFAULT NULL,
  `team_id` int(10) UNSIGNED DEFAULT NULL,
  `entry_code` varchar(30) NOT NULL,
  `status` enum('Registered','Withdrawn','Disqualified') NOT NULL DEFAULT 'Registered',
  `record_uuid` char(36) NOT NULL,
  `registered_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`entry_id`),
  UNIQUE KEY `uq_event_entries_uuid` (`record_uuid`),
  UNIQUE KEY `uq_event_entry_code` (`event_id`,`entry_code`),
  UNIQUE KEY `uq_event_participant` (`event_id`,`participant_id`),
  UNIQUE KEY `uq_event_team` (`event_id`,`team_id`),
  KEY `fk_event_entries_participant` (`participant_id`),
  KEY `fk_event_entries_team` (`team_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_judges` (
  `assignment_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_id` int(10) UNSIGNED NOT NULL,
  `judge_user_id` int(10) UNSIGNED NOT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `record_uuid` char(36) NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`assignment_id`),
  UNIQUE KEY `uq_event_judges_uuid` (`record_uuid`),
  UNIQUE KEY `uq_event_judge_assignment` (`event_id`,`judge_user_id`),
  KEY `fk_event_judges_user` (`judge_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_tabulator_assignments` (
  `event_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`event_id`,`user_id`),
  UNIQUE KEY `event_tabulator_assignments_record_uuid_unique` (`record_uuid`),
  KEY `event_tabulator_assignments_user_id_foreign` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_generated_reports` (
  `report_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_id` int(10) UNSIGNED DEFAULT NULL,
  `report_type` varchar(100) NOT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `generated_by` int(10) UNSIGNED NOT NULL,
  `generated_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`report_id`),
  KEY `fk_reports_event` (`event_id`),
  KEY `fk_reports_user` (`generated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_integration_logs` (
  `integration_log_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `service_name` varchar(150) NOT NULL,
  `request_type` varchar(50) NOT NULL,
  `reference_id` varchar(100) DEFAULT NULL,
  `response_status` varchar(50) NOT NULL,
  `error_message` text DEFAULT NULL,
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`integration_log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_participants` (
  `participant_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_reference` varchar(100) DEFAULT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `program_section` varchar(150) DEFAULT NULL,
  `participant_type` enum('Individual','Team Member') NOT NULL DEFAULT 'Individual',
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`participant_id`),
  UNIQUE KEY `uq_participants_uuid` (`record_uuid`),
  UNIQUE KEY `uq_participants_student_reference` (`student_reference`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_participant_photos` (
  `participant_id` int(10) UNSIGNED NOT NULL,
  `filename` varchar(80) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `is_public` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`participant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_point_awards` (
  `point_award_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `result_id` int(10) UNSIGNED NOT NULL,
  `participant_id` int(10) UNSIGNED DEFAULT NULL,
  `team_id` int(10) UNSIGNED DEFAULT NULL,
  `points_awarded` decimal(8,2) NOT NULL DEFAULT 0.00,
  `approved_by` int(10) UNSIGNED NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `awarded_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`point_award_id`),
  UNIQUE KEY `uq_point_awards_result` (`result_id`),
  UNIQUE KEY `uq_point_awards_uuid` (`record_uuid`),
  KEY `fk_point_awards_participant` (`participant_id`),
  KEY `fk_point_awards_team` (`team_id`),
  KEY `fk_point_awards_approver` (`approved_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_point_rules` (
  `point_rule_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_id` int(10) UNSIGNED NOT NULL,
  `rank_position` int(10) UNSIGNED NOT NULL,
  `points_value` decimal(8,2) NOT NULL DEFAULT 0.00,
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`point_rule_id`),
  UNIQUE KEY `uq_point_rules_uuid` (`record_uuid`),
  UNIQUE KEY `uq_point_rule_rank` (`event_id`,`rank_position`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_result_summaries` (
  `result_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `entry_id` int(10) UNSIGNED NOT NULL,
  `total_score` decimal(10,4) NOT NULL DEFAULT 0.0000,
  `rank_position` int(10) UNSIGNED DEFAULT NULL,
  `result_status` enum('Provisional','Finalized') NOT NULL DEFAULT 'Provisional',
  `calculated_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `finalized_at` timestamp NULL DEFAULT NULL,
  `record_uuid` char(36) NOT NULL,
  PRIMARY KEY (`result_id`),
  UNIQUE KEY `uq_result_entry` (`entry_id`),
  UNIQUE KEY `uq_results_uuid` (`record_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_scores` (
  `score_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `entry_id` int(10) UNSIGNED NOT NULL,
  `assignment_id` int(10) UNSIGNED NOT NULL,
  `criterion_id` int(10) UNSIGNED NOT NULL,
  `score_value` decimal(7,2) NOT NULL,
  `status` enum('Draft','Submitted','Approved') NOT NULL DEFAULT 'Draft',
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`score_id`),
  UNIQUE KEY `uq_scores_uuid` (`record_uuid`),
  UNIQUE KEY `uq_score_per_criterion` (`entry_id`,`assignment_id`,`criterion_id`),
  KEY `fk_scores_assignment` (`assignment_id`),
  KEY `fk_scores_criterion` (`criterion_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_sports_matches` (
  `match_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
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
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`match_id`),
  KEY `sports_matches_entry_a_id_foreign` (`entry_a_id`),
  KEY `sports_matches_entry_b_id_foreign` (`entry_b_id`),
  KEY `sports_matches_event_id_index` (`event_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_staff_registration_requests` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `full_name` varchar(150) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `requested_role` varchar(30) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Pending',
  `reviewed_by` int(10) UNSIGNED DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `staff_registration_requests_username_unique` (`username`),
  KEY `staff_registration_requests_reviewed_by_foreign` (`reviewed_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_sync_queue` (
  `sync_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `record_uuid` char(36) NOT NULL,
  `table_name` varchar(100) NOT NULL,
  `operation` enum('Create','Update','Delete') NOT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`payload`)),
  `record_version` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `sync_status` enum('Pending','Processing','Synchronized','Failed','Conflict') NOT NULL DEFAULT 'Pending',
  `attempts` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `synced_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`sync_id`),
  KEY `idx_sync_status` (`sync_status`,`created_at`),
  KEY `idx_sync_record` (`table_name`,`record_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_teams` (
  `team_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `team_name` varchar(150) NOT NULL,
  `department` varchar(150) DEFAULT NULL,
  `coach_name` varchar(150) DEFAULT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `record_uuid` char(36) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`team_id`),
  UNIQUE KEY `uq_teams_uuid` (`record_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_team_members` (
  `team_member_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `team_id` int(10) UNSIGNED NOT NULL,
  `participant_id` int(10) UNSIGNED NOT NULL,
  `record_uuid` char(36) NOT NULL,
  `joined_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`team_member_id`),
  UNIQUE KEY `uq_team_members_uuid` (`record_uuid`),
  UNIQUE KEY `uq_team_member_pair` (`team_id`,`participant_id`),
  KEY `fk_team_members_participant` (`participant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- IDCARDS

CREATE TABLE IF NOT EXISTS `idcard_iadfc_idcards` (
  `CardId` int(11) NOT NULL AUTO_INCREMENT,
  `PersonId` int(11) NOT NULL,
  `CardReference` varchar(100) NOT NULL,
  `Status` varchar(30) NOT NULL DEFAULT 'Draft',
  `GeneratedBy` INT UNSIGNED NOT NULL,
  `UpdatedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6),
  `IsSample` tinyint(1) NOT NULL DEFAULT 0,
  `ValidUntil` date NOT NULL DEFAULT '2028-10-31',
  `VerifyToken` varchar(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `Snapshot` longtext DEFAULT NULL,
  `ValidFrom` date DEFAULT NULL,
  `DateIssued` date DEFAULT NULL,
  PRIMARY KEY (`CardId`),
  UNIQUE KEY `CardReference` (`CardReference`),
  UNIQUE KEY `VerifyToken` (`VerifyToken`),
  KEY `ix_iadfc_cards_person` (`PersonId`,`CardId`),
  KEY `ix_iadfc_cards_updated` (`UpdatedAt`,`CardId`),
  KEY `fk_iadfc_cards_staff` (`GeneratedBy`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `idcard_iadfc_idreleases` (
  `ReleaseId` int(11) NOT NULL AUTO_INCREMENT,
  `CardId` int(11) NOT NULL,
  `ReleasedBy` INT UNSIGNED NOT NULL,
  `RecipientName` varchar(160) NOT NULL,
  `VerificationMethod` varchar(100) NOT NULL,
  `ReleasedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6),
  `Acknowledgment` longtext NOT NULL DEFAULT '',
  PRIMARY KEY (`ReleaseId`),
  UNIQUE KEY `CardId` (`CardId`),
  KEY `fk_iadfc_release_staff` (`ReleasedBy`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `idcard_persons` (
  `PersonId` int(11) NOT NULL AUTO_INCREMENT,
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
  `student_id` INT UNSIGNED NULL UNIQUE,
  `user_id` INT UNSIGNED NULL,
  PRIMARY KEY (`PersonId`),
  UNIQUE KEY `SchoolNumber` (`SchoolNumber`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `idcard_iadfc_printrecords` (
  `PrintId` int(11) NOT NULL AUTO_INCREMENT,
  `CardId` int(11) NOT NULL,
  `PrintedBy` INT UNSIGNED NOT NULL,
  `PrintedAt` datetime(6) NOT NULL DEFAULT utc_timestamp(6),
  PRIMARY KEY (`PrintId`),
  KEY `ix_iadfc_prints_card_date` (`CardId`,`PrintedAt`),
  KEY `fk_iadfc_print_staff` (`PrintedBy`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `idcard_iadfc_schoolsettings` (
  `SettingId` int(11) NOT NULL,
  `SchoolName` varchar(200) NOT NULL,
  `Address` varchar(300) NOT NULL,
  `Motto` varchar(300) NOT NULL,
  `PublicBaseUrl` varchar(300) NOT NULL DEFAULT '',
  `PresidentName` varchar(160) NOT NULL DEFAULT '',
  `PresidentSignature` longtext NOT NULL DEFAULT '',
  PRIMARY KEY (`SettingId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ETEEAP

CREATE TABLE IF NOT EXISTS `eteeap_applications` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_app_user` (`user_id`),
  UNIQUE KEY `uq_app_reference` (`reference_no`),
  KEY `ix_app_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_assessments` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `assessor_id` INT UNSIGNED DEFAULT NULL,
  `title` varchar(150) NOT NULL,
  `scheduled_at` datetime NOT NULL,
  `mode` enum('Onsite','Online') NOT NULL DEFAULT 'Onsite',
  `venue` varchar(255) NOT NULL,
  `status` enum('scheduled','completed','cancelled') NOT NULL DEFAULT 'scheduled',
  `feedback` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `ix_assess_app` (`application_id`),
  KEY `ix_assessment_assessor` (`assessor_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_billing_fees` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` varchar(30) NOT NULL,
  `label` varchar(160) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `fk_fee_actor` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_billing_invoices` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_no` varchar(32) DEFAULT NULL,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `fee_id` bigint(20) UNSIGNED NOT NULL,
  `description` varchar(160) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `status` enum('issued','part_paid','paid','voided') NOT NULL DEFAULT 'issued',
  `due_on` date DEFAULT NULL,
  `created_by` INT UNSIGNED NOT NULL,
  `void_reason` varchar(250) DEFAULT NULL,
  `voided_by` INT UNSIGNED DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `invoice_no` (`invoice_no`),
  KEY `ix_bill_app` (`application_id`,`status`),
  KEY `fk_bill_fee` (`fee_id`),
  KEY `fk_bill_creator` (`created_by`),
  KEY `fk_bill_void` (`voided_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_billing_payments` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `receipt_no` varchar(32) DEFAULT NULL,
  `invoice_id` bigint(20) UNSIGNED NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `method` enum('cash','bank_transfer','gcash','other') NOT NULL,
  `external_reference` varchar(110) NOT NULL,
  `paid_on` date NOT NULL,
  `status` enum('posted','voided') NOT NULL DEFAULT 'posted',
  `recorded_by` INT UNSIGNED NOT NULL,
  `void_reason` varchar(250) DEFAULT NULL,
  `voided_by` INT UNSIGNED DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bill_reference` (`method`,`external_reference`),
  UNIQUE KEY `receipt_no` (`receipt_no`),
  KEY `ix_bill_pay` (`invoice_id`,`status`),
  KEY `fk_pay_actor` (`recorded_by`),
  KEY `fk_pay_void_actor` (`voided_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_credits` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `evaluator_id` INT UNSIGNED NOT NULL,
  `course_name` varchar(180) NOT NULL,
  `units` tinyint(3) UNSIGNED NOT NULL,
  `status` enum('recommended','approved','rejected') NOT NULL DEFAULT 'recommended',
  `remarks` text DEFAULT NULL,
  `decided_by` INT UNSIGNED DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `ix_credit_app` (`application_id`),
  KEY `ix_credit_eval` (`evaluator_id`),
  KEY `ix_credit_decider` (`decided_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_education_records` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `institution` varchar(180) NOT NULL,
  `program_name` varchar(180) NOT NULL,
  `start_year` smallint(5) UNSIGNED DEFAULT NULL,
  `end_year` smallint(5) UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_edu_app` (`application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_employment_records` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `company` varchar(180) NOT NULL,
  `job_title` varchar(180) NOT NULL,
  `date_started` date NOT NULL,
  `date_ended` date DEFAULT NULL,
  `responsibilities` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_work_app` (`application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_form_records` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `form_key` varchar(20) NOT NULL,
  `application_id` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `author_id` int(10) UNSIGNED NOT NULL,
  `author_role` varchar(20) NOT NULL,
  `responses` longtext NOT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `case_forms` (`application_id`,`form_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_evaluations` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `assessor_id` INT UNSIGNED NOT NULL,
  `authenticity` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `relevance` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `sufficiency` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `currency_score` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `feedback` text DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_eval_assessor` (`application_id`,`assessor_id`),
  KEY `ix_eval_assessor` (`assessor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_grades` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `assessor_id` INT UNSIGNED NOT NULL,
  `course_name` varchar(180) NOT NULL,
  `grade` decimal(5,2) NOT NULL,
  `status` enum('draft','published') NOT NULL DEFAULT 'draft',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_grade_course` (`application_id`,`assessor_id`,`course_name`),
  KEY `fk_grades_assessor` (`assessor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_login_attempts` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `login_key` char(64) NOT NULL,
  `attempted_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_login_limit` (`login_key`,`attempted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_messages` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` INT UNSIGNED NOT NULL,
  `channel` enum('coordinator','assessor') NOT NULL DEFAULT 'coordinator',
  `subject` varchar(180) NOT NULL DEFAULT 'ETEEAP Message',
  `body` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `ix_msg_app` (`application_id`),
  KEY `ix_msg_sender` (`sender_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_portfolio_assessments` (
  `assessment_id` int(11) NOT NULL AUTO_INCREMENT,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`assessment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_portfolio_rubric_forms` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` int(10) UNSIGNED NOT NULL,
  `assessor_id` int(10) UNSIGNED NOT NULL,
  `assessment_date` date DEFAULT NULL,
  `panel_name` varchar(250) NOT NULL DEFAULT '',
  `ratings_json` text NOT NULL,
  `recommendation` varchar(80) NOT NULL DEFAULT '',
  `remarks` text NOT NULL,
  `total_score` decimal(6,3) DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `applicant_assessor` (`application_id`,`assessor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_program_offerings` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` varchar(30) NOT NULL,
  `degree_name` varchar(180) NOT NULL,
  `authorization_reference` varchar(180) NOT NULL,
  `valid_from` date NOT NULL,
  `valid_until` date NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `configured_by` INT UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `fk_program_actor` (`configured_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_uploads` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` bigint(20) UNSIGNED NOT NULL,
  `uploaded_by` INT UNSIGNED NOT NULL,
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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_upload_storage` (`storage_name`),
  KEY `ix_upload_requirement` (`application_id`,`kind`,`requirement_key`),
  KEY `ix_upload_user` (`uploaded_by`),
  KEY `ix_upload_previous` (`replaces_upload_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eteeap_upload_events` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `upload_id` bigint(20) UNSIGNED NOT NULL,
  `actor_id` INT UNSIGNED DEFAULT NULL,
  `event_type` enum('uploaded','reviewed','resubmitted','legacy_review') NOT NULL,
  `old_status` enum('pending','verified','revision') DEFAULT NULL,
  `new_status` enum('pending','verified','revision') NOT NULL,
  `note` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `ix_file_event` (`upload_id`,`created_at`),
  KEY `fk_upload_event_actor` (`actor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ADMISSIONS

CREATE TABLE IF NOT EXISTS `admit_applicants` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NULL UNIQUE,
  `reference_code` VARCHAR(24) NOT NULL UNIQUE,
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(190) NOT NULL,
  `program` VARCHAR(150) NOT NULL,
  `birth_date` DATE NULL,
  `phone` VARCHAR(40) NULL,
  `address` TEXT NULL,
  `status` VARCHAR(40) NOT NULL DEFAULT 'For evaluation',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admit_evaluations` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `applicant_id` BIGINT UNSIGNED NOT NULL,
  `evaluator_id` INT UNSIGNED NULL,
  `exam_date` DATE NOT NULL,
  `score` DECIMAL(5,2) NOT NULL,
  `decision` ENUM('Pending','Qualified','Not qualified') NOT NULL DEFAULT 'Pending',
  `notes` TEXT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admit_interview_slots` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `interviewer_id` INT UNSIGNED NULL,
  `starts_at` DATETIME NOT NULL,
  `ends_at` DATETIME NOT NULL,
  `capacity` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `location` VARCHAR(190) NOT NULL DEFAULT 'ADFC Admissions Office',
  `status` ENUM('open','closed') NOT NULL DEFAULT 'open'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admit_interviews` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `applicant_id` BIGINT UNSIGNED NOT NULL,
  `interviewer_id` INT UNSIGNED NULL,
  `slot_id` BIGINT UNSIGNED NULL,
  `scheduled_at` DATETIME NOT NULL,
  `location` VARCHAR(190) NOT NULL,
  `status` ENUM('Scheduled','Completed','Cancelled','No show') NOT NULL DEFAULT 'Scheduled',
  `notes` TEXT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- SCHOLARSHIPS

CREATE TABLE IF NOT EXISTS `scholar_application_documents` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `scholarship_application_id` bigint(20) UNSIGNED NOT NULL,
  `scholarship_requirement_id` bigint(20) UNSIGNED DEFAULT NULL,
  `document_name` varchar(200) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_type` varchar(20) DEFAULT NULL,
  `file_size` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `verification_status` varchar(30) NOT NULL DEFAULT 'pending',
  `verification_notes` text DEFAULT NULL,
  `verified_by` INT UNSIGNED DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `storage_disk` varchar(20) NOT NULL DEFAULT 'local',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `document_category` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `application_documents_scholarship_requirement_id_foreign` (`scholarship_requirement_id`),
  KEY `application_documents_verified_by_foreign` (`verified_by`),
  KEY `app_docs_appid_verifstatus_idx` (`scholarship_application_id`,`verification_status`),
  KEY `application_documents_document_category_index` (`document_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_application_evaluations` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `scholarship_application_id` bigint(20) UNSIGNED NOT NULL,
  `evaluator_id` INT UNSIGNED NOT NULL,
  `score` tinyint(3) UNSIGNED DEFAULT NULL,
  `recommendation` varchar(40) NOT NULL DEFAULT 'pending',
  `evaluation_notes` text DEFAULT NULL,
  `evaluated_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `application_evaluations_evaluator_id_foreign` (`evaluator_id`),
  KEY `application_evaluations_scholarship_application_id_index` (`scholarship_application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_application_status_histories` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `scholarship_application_id` bigint(20) UNSIGNED NOT NULL,
  `from_status` varchar(40) DEFAULT NULL,
  `to_status` varchar(40) NOT NULL,
  `changed_by` INT UNSIGNED DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `application_status_histories_changed_by_foreign` (`changed_by`),
  KEY `application_status_histories_scholarship_application_id_index` (`scholarship_application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_cache` (
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL,
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_cache_locks` (
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL,
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_document_reviews` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_document_id` bigint(20) UNSIGNED NOT NULL,
  `reviewed_by` INT UNSIGNED NOT NULL,
  `status` varchar(30) NOT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `document_reviews_application_document_id_foreign` (`application_document_id`),
  KEY `document_reviews_reviewed_by_foreign` (`reviewed_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_eligibility_results` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `scholarship_application_id` bigint(20) UNSIGNED NOT NULL,
  `checked_by` INT UNSIGNED DEFAULT NULL,
  `result` varchar(30) NOT NULL DEFAULT 'manual_review',
  `reasons` text DEFAULT NULL,
  `checked_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `eligibility_results_checked_by_foreign` (`checked_by`),
  KEY `eligibility_results_scholarship_application_id_index` (`scholarship_application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_eligibility_rules` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `scholarship_program_id` bigint(20) UNSIGNED NOT NULL,
  `rule_key` varchar(60) NOT NULL,
  `rule_label` varchar(200) NOT NULL,
  `rule_type` varchar(30) NOT NULL DEFAULT 'text',
  `operator` varchar(20) NOT NULL DEFAULT '=',
  `rule_value` text NOT NULL,
  `failure_mode` varchar(20) NOT NULL DEFAULT 'manual_review',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `eligibility_rules_scholarship_program_id_is_active_index` (`scholarship_program_id`,`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_renewal_applications` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `renewal_no` varchar(30) NOT NULL,
  `scholarship_award_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `academic_year` varchar(20) NOT NULL,
  `statement` text DEFAULT NULL,
  `form_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`form_data`)),
  `status` varchar(30) NOT NULL DEFAULT 'draft',
  `remarks` text DEFAULT NULL,
  `decided_by` INT UNSIGNED DEFAULT NULL,
  `decided_at` timestamp NULL DEFAULT NULL,
  `submitted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `renewal_applications_renewal_no_unique` (`renewal_no`),
  UNIQUE KEY `renewals_award_cycle_unique` (`scholarship_award_id`,`academic_year`),
  KEY `renewal_applications_user_id_foreign` (`user_id`),
  KEY `renewal_applications_decided_by_foreign` (`decided_by`),
  KEY `renewal_applications_scholarship_award_id_status_index` (`scholarship_award_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_scholarship_appeals` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `appeal_no` varchar(40) NOT NULL,
  `scholarship_award_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `award_status_version` int(10) UNSIGNED NOT NULL,
  `award_status` varchar(30) NOT NULL,
  `status_reason` text DEFAULT NULL,
  `statement` text NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'submitted',
  `pending_slot` tinyint(3) UNSIGNED DEFAULT 1,
  `decision_reason` text DEFAULT NULL,
  `decided_by` INT UNSIGNED DEFAULT NULL,
  `decided_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `scholarship_appeals_appeal_no_unique` (`appeal_no`),
  UNIQUE KEY `appeals_one_pending_per_award` (`scholarship_award_id`,`pending_slot`),
  KEY `scholarship_appeals_decided_by_foreign` (`decided_by`),
  KEY `scholarship_appeals_user_id_status_index` (`user_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_scholarship_applications` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_no` varchar(30) NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `scholarship_program_id` bigint(20) UNSIGNED NOT NULL,
  `assigned_to` INT UNSIGNED DEFAULT NULL,
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
  `decided_by` INT UNSIGNED DEFAULT NULL,
  `decision_remarks` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `last_saved_step` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `declaration_accepted_at` timestamp NULL DEFAULT NULL,
  `form_version` varchar(40) DEFAULT NULL,
  `adfc_form` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`adfc_form`)),
  `form_review` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`form_review`)),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_app_user_schol_year` (`user_id`,`scholarship_program_id`,`academic_year`),
  UNIQUE KEY `scholarship_applications_application_no_unique` (`application_no`),
  KEY `scholarship_applications_scholarship_program_id_foreign` (`scholarship_program_id`),
  KEY `scholarship_applications_decided_by_foreign` (`decided_by`),
  KEY `scholarship_applications_status_scholarship_program_id_index` (`status`,`scholarship_program_id`),
  KEY `scholarship_applications_user_id_index` (`user_id`),
  KEY `sch_apps_assigned_to_idx` (`assigned_to`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_scholarship_awards` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `award_no` varchar(30) NOT NULL,
  `scholarship_application_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `scholarship_program_id` bigint(20) UNSIGNED NOT NULL,
  `benefits` text DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `recipient_status` varchar(30) NOT NULL DEFAULT 'active',
  `remarks` text DEFAULT NULL,
  `awarded_by` INT UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `status_reason` text DEFAULT NULL,
  `status_changed_at` timestamp NULL DEFAULT NULL,
  `status_version` int(10) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `scholarship_awards_award_no_unique` (`award_no`),
  UNIQUE KEY `scholarship_awards_scholarship_application_id_unique` (`scholarship_application_id`),
  KEY `scholarship_awards_scholarship_program_id_foreign` (`scholarship_program_id`),
  KEY `scholarship_awards_awarded_by_foreign` (`awarded_by`),
  KEY `scholarship_awards_user_id_recipient_status_index` (`user_id`,`recipient_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_scholarship_programs` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
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
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `scholarship_programs_code_unique` (`code`),
  KEY `scholarship_programs_created_by_foreign` (`created_by`),
  KEY `scholarship_programs_status_deadline_index` (`status`,`deadline`),
  KEY `scholarship_programs_category_index` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scholar_scholarship_requirements` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `scholarship_program_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT 1,
  `allowed_types` varchar(100) NOT NULL DEFAULT 'pdf,jpg,jpeg,png',
  `max_size_kb` int(10) UNSIGNED NOT NULL DEFAULT 5120,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `scholarship_requirements_scholarship_program_id_index` (`scholarship_program_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ELECTIONS

CREATE TABLE IF NOT EXISTS `election_face_data` (
  `face_id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `face_template` VARBINARY(2048) NOT NULL,
  `consent_status` ENUM('given','withdrawn') NOT NULL,
  `consent_date` DATETIME NOT NULL,
  `enrolled_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `data_status` ENUM('active','deleted') NOT NULL DEFAULT 'active',
  `deleted_at` DATETIME NULL,
  PRIMARY KEY (face_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `election_elections` (
  `election_id` INT NOT NULL AUTO_INCREMENT,
  `election_name` VARCHAR(150) NOT NULL,
  `academic_year` VARCHAR(20) NULL,
  `voting_start` DATETIME NOT NULL,
  `voting_end` DATETIME NOT NULL,
  `face_match_threshold` DECIMAL(4,3) NOT NULL DEFAULT 0.800,
  `eligibility_criteria` VARCHAR(255) NULL,
  `election_status` ENUM('draft','scheduled','open','closed','archived')
                       NOT NULL DEFAULT 'draft',
  `created_by` INT UNSIGNED NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (election_id),
  CONSTRAINT chk_elections_window CHECK (voting_end > voting_start),
  CONSTRAINT chk_elections_threshold CHECK (face_match_threshold BETWEEN 0 AND 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `election_face_verifications` (
  `verification_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `election_id` INT NOT NULL,
  `match_score` DECIMAL(5,4) NULL,
  `liveness_result` ENUM('passed','failed') NULL,
  `verification_status` ENUM('verified','failed','pending_manual','manually_verified')
                      NOT NULL,
  `reviewed_by` INT UNSIGNED NULL,
  `ip_address` VARCHAR(45) NULL,
  `attempted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (verification_id),
  KEY idx_fv_user_election (user_id, election_id),
  KEY idx_fv_status (verification_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `election_positions` (
  `position_id` INT NOT NULL AUTO_INCREMENT,
  `election_id` INT NOT NULL,
  `position_name` VARCHAR(100) NOT NULL,
  `seats` TINYINT NOT NULL DEFAULT 1,
  `display_order` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (position_id),
  UNIQUE KEY uq_positions_election_name (election_id, position_name),
  CONSTRAINT chk_positions_seats CHECK (seats >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `election_candidacies` (
  `candidate_id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `position_id` INT NOT NULL,
  `profile` TEXT NULL,
  `platform` TEXT NULL,
  `filing_status` ENUM('pending','approved','declined') NOT NULL DEFAULT 'pending',
  `review_remarks` TEXT NULL,
  `reviewed_by` INT UNSIGNED NULL,
  `review_date` DATETIME NULL,
  `filed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (candidate_id),
  UNIQUE KEY uq_candidacies_user_position (user_id, position_id),
  KEY idx_candidacies_position_status (position_id, filing_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `election_candidate_documents` (
  `document_id` INT NOT NULL AUTO_INCREMENT,
  `candidate_id` INT NOT NULL,
  `file_name` VARCHAR(255) NOT NULL,
  `file_path` VARCHAR(500) NOT NULL,
  `upload_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (document_id),
  KEY idx_cd_candidate (candidate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `election_vote_records` (
  `record_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` INT NOT NULL,
  `position_id` INT NOT NULL,
  `voted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (record_id),
  UNIQUE KEY uq_vote_records_user_position (user_id, position_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `election_ballots` (
  `ballot_id` BIGINT NOT NULL AUTO_INCREMENT,
  `candidate_id` INT NOT NULL,
  `cast_date` DATE NOT NULL,
  PRIMARY KEY (ballot_id),
  KEY idx_ballots_candidate (candidate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `election_results` (
  `result_id` INT NOT NULL AUTO_INCREMENT,
  `candidate_id` INT NOT NULL,
  `vote_count` INT NOT NULL DEFAULT 0,
  `is_winner` TINYINT(1) NOT NULL DEFAULT 0,
  `proclaimed_at` DATETIME NULL,
  PRIMARY KEY (result_id),
  UNIQUE KEY uq_results_candidate (candidate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `election_security_login_attempts` (
  `attempt_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `email_hash` CHAR(64) NOT NULL,
  `ip_address` VARCHAR(45) NOT NULL,
  `attempted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_login_email_time (email_hash, attempted_at),
  INDEX idx_login_ip_time (ip_address, attempted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `election_security_sessions` (
  `session_id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `token_hash` CHAR(64) NOT NULL UNIQUE,
  `ip_address` VARCHAR(45) NOT NULL,
  `user_agent` VARCHAR(255) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_seen_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `revoked_at` DATETIME NULL,
  INDEX idx_security_user (user_id, revoked_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- READMISSION

CREATE TABLE IF NOT EXISTS `readmit_requirements` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(150) NOT NULL,
  `is_required` TINYINT(1) NOT NULL DEFAULT 0,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_requirements_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `readmit_applications` (
  `id` VARCHAR(40) NOT NULL PRIMARY KEY,
  `seq` BIGINT NOT NULL AUTO_INCREMENT,
  `reference_no` VARCHAR(30) NOT NULL,
  `applicant_id` VARCHAR(40) NOT NULL,
  `program_id` INT UNSIGNED NULL,
  `student_number` VARCHAR(40) NOT NULL DEFAULT '',
  `department` VARCHAR(150) NOT NULL DEFAULT '',
  `previous_year_level` VARCHAR(40) NOT NULL DEFAULT '',
  `last_term` VARCHAR(20) NOT NULL DEFAULT '',
  `last_academic_year` VARCHAR(20) NOT NULL DEFAULT '',
  `reason_leaving` VARCHAR(2000) NOT NULL DEFAULT '',
  `reason_returning` VARCHAR(2000) NOT NULL DEFAULT '',
  `intended_term` VARCHAR(20) NOT NULL DEFAULT '',
  `intended_academic_year` VARCHAR(20) NOT NULL DEFAULT '',
  `status` ENUM('Draft','Submitted','Incomplete','Under Review','Approved','Denied','Withdrawn') NOT NULL DEFAULT 'Draft',
  `assigned_evaluator_id` VARCHAR(40) NULL,
  `requirements_status` VARCHAR(60) NOT NULL DEFAULT 'Not submitted',
  `eligibility_assessment` VARCHAR(100) NOT NULL DEFAULT '',
  `evaluator_remarks` VARCHAR(2000) NOT NULL DEFAULT '',
  `conditions` VARCHAR(2000) NOT NULL DEFAULT '',
  `submitted_at` VARCHAR(30) NULL,
  `created_at` VARCHAR(30) NOT NULL,
  `updated_at` VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_app_ref (reference_no),
  UNIQUE KEY uq_app_seq (seq),
  KEY idx_app_applicant (applicant_id),
  KEY idx_app_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `readmit_documents` (
  `id` VARCHAR(40) NOT NULL PRIMARY KEY,
  `seq` BIGINT NOT NULL AUTO_INCREMENT,
  `application_id` VARCHAR(40) NOT NULL,
  `requirement_id` INT NULL,
  `name` VARCHAR(150) NOT NULL,
  `is_required` TINYINT(1) NOT NULL DEFAULT 0,
  `file_name` VARCHAR(200) NOT NULL DEFAULT '',
  `file_size` INT NOT NULL DEFAULT 0,
  `file_type` VARCHAR(60) NOT NULL DEFAULT '',
  `stored_name` VARCHAR(80) NULL,
  `status` ENUM('Missing','Uploaded','Verified','Correction Required') NOT NULL DEFAULT 'Missing',
  `note` VARCHAR(255) NOT NULL DEFAULT '',
  `uploaded_at` VARCHAR(30) NULL,
  UNIQUE KEY uq_doc_seq (seq),
  KEY idx_doc_app (application_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `readmit_application_history` (
  `id` VARCHAR(40) NOT NULL PRIMARY KEY,
  `seq` BIGINT NOT NULL AUTO_INCREMENT,
  `application_id` VARCHAR(40) NOT NULL,
  `action` VARCHAR(100) NOT NULL,
  `actor` VARCHAR(120) NOT NULL,
  `actor_role` VARCHAR(40) NOT NULL,
  `note` VARCHAR(2000) NOT NULL DEFAULT '',
  `created_at` VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_hist_seq (seq),
  KEY idx_hist_app (application_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ATTENDANCE

CREATE TABLE IF NOT EXISTS `attend_approval_requests` (
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
  `seen` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `ix_appr_user` (`username`,`status`),
  KEY `ix_appr_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attend_attendance_records` (
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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_att` (`student_id`,`schedule_id`,`att_date`),
  KEY `ix_date` (`att_date`),
  KEY `ix_student` (`student_id`,`att_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attend_attendance_sessions` (
  `schedule_id` varchar(60) NOT NULL,
  `att_date` date NOT NULL,
  `instructor` varchar(120) NOT NULL DEFAULT '',
  `subject` varchar(160) NOT NULL DEFAULT '',
  `start_time` varchar(10) NOT NULL DEFAULT '',
  `end_time` varchar(10) NOT NULL DEFAULT '',
  `started_at` bigint(20) NOT NULL DEFAULT 0,
  `closed_at` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`schedule_id`,`att_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attend_email_sent` (
  `record_id` varchar(40) NOT NULL,
  `to_addr` varchar(120) NOT NULL,
  `sent_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`record_id`,`to_addr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attend_face_templates` (
  `member_id` varchar(40) NOT NULL,
  `descriptor` text NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attend_member_files` (
  `owner` varchar(64) NOT NULL,
  `kind` varchar(10) NOT NULL,
  `data` mediumtext NOT NULL,
  `updated_by` varchar(64) NOT NULL DEFAULT '',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`owner`,`kind`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attend_members` (
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
  `student_id` INT UNSIGNED NULL UNIQUE,
  `user_id` INT UNSIGNED NULL,
  PRIMARY KEY (`id`),
  KEY `ix_role` (`role`),
  KEY `ix_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attend_notification_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `channel` varchar(10) NOT NULL DEFAULT 'email',
  `to_addr` varchar(120) NOT NULL DEFAULT '',
  `student_id` varchar(40) NOT NULL DEFAULT '',
  `subject` varchar(160) NOT NULL DEFAULT '',
  `status` varchar(12) NOT NULL DEFAULT '',
  `reason` varchar(250) NOT NULL DEFAULT '',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `ix_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attend_notify_queue` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
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
  `sent_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_notify` (`channel`,`record_id`,`recipient`,`att_status`),
  KEY `ix_notify_due` (`state`,`due_at`),
  KEY `ix_notify_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attend_password_resets` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `instructor_id` int(10) unsigned NOT NULL,
  `code_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `attempts` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `used` tinyint(1) NOT NULL DEFAULT 0,
  `ip` varchar(45) NOT NULL DEFAULT '',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `ix_inst` (`instructor_id`,`used`,`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attend_school_data` (
  `part` varchar(40) NOT NULL,
  `v` mediumtext NOT NULL,
  `updated_by` varchar(64) NOT NULL DEFAULT '',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`part`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- === RELATIONSHIPS (SUBSYSTEM FOREIGN KEYS) ===

ALTER TABLE `users` ADD CONSTRAINT `fk_shared_user_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

ALTER TABLE `instructors` ADD CONSTRAINT `fk_shared_inst_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `instructors` ADD CONSTRAINT `fk_shared_inst_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`);

ALTER TABLE `academic_classes` ADD CONSTRAINT `fk_shared_class_program` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`);

ALTER TABLE `academic_classes` ADD CONSTRAINT `fk_shared_class_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`);

ALTER TABLE `academic_classes` ADD CONSTRAINT `fk_shared_class_period` FOREIGN KEY (`period_id`) REFERENCES `academic_periods` (`period_id`);

ALTER TABLE `academic_classes` ADD CONSTRAINT `fk_shared_class_instructor` FOREIGN KEY (`instructor_id`) REFERENCES `instructors` (`instructor_id`);

ALTER TABLE `access_role_permissions` ADD CONSTRAINT `fk_access_role` FOREIGN KEY (`role_id`) REFERENCES `access_roles` (`role_id`);

ALTER TABLE `access_role_permissions` ADD CONSTRAINT `fk_access_permission` FOREIGN KEY (`permission_id`) REFERENCES `access_permissions` (`permission_id`);

ALTER TABLE `user_access_roles` ADD CONSTRAINT `fk_user_role_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `user_access_roles` ADD CONSTRAINT `fk_user_role_role` FOREIGN KEY (`role_id`) REFERENCES `access_roles` (`role_id`);

ALTER TABLE `announcements` ADD CONSTRAINT `fk_shared_announcement_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `announcements` ADD CONSTRAINT `fk_shared_announcement_class` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_id`);

ALTER TABLE `notifications` ADD CONSTRAINT `fk_shared_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `auth_sessions` ADD CONSTRAINT `fk_shared_auth_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `user_profiles` ADD CONSTRAINT `fk_shared_profile_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `user_mfa_methods` ADD CONSTRAINT `fk_shared_mfa_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `staff_profiles` ADD CONSTRAINT `fk_staff_profiles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `staff_profiles` ADD CONSTRAINT `fk_staff_profiles_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`);

ALTER TABLE `scholar_household_profiles` ADD CONSTRAINT `fk_scholar_household_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

ALTER TABLE `students` ADD CONSTRAINT `fk_shared_student_school` FOREIGN KEY (`school_id`) REFERENCES `fe_schools` (`school_id`);

ALTER TABLE `students` ADD CONSTRAINT `fk_shared_student_strand` FOREIGN KEY (`strand_id`) REFERENCES `fe_shs_strands` (`strand_id`);

ALTER TABLE `students` ADD CONSTRAINT `fk_shared_student_specialization` FOREIGN KEY (`specialization_id`) REFERENCES `fe_shs_specializations` (`specialization_id`);

ALTER TABLE `idcard_persons` ADD CONSTRAINT `fk_idcard_person_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

ALTER TABLE `idcard_persons` ADD CONSTRAINT `fk_idcard_person_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `attend_members` ADD CONSTRAINT `fk_attend_member_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

ALTER TABLE `attend_members` ADD CONSTRAINT `fk_attend_member_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `campusfind_items` ADD CONSTRAINT `fk_campusfind_items_0_users` FOREIGN KEY (`campusfind_reporter_user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `campusfind_claims` ADD CONSTRAINT `fk_campusfind_claims_0_campusfind_items` FOREIGN KEY (`campusfind_item_id`) REFERENCES `campusfind_items` (`campusfind_item_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `campusfind_claims` ADD CONSTRAINT `fk_campusfind_claims_1_users` FOREIGN KEY (`campusfind_claimant_user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `campusfind_claims` ADD CONSTRAINT `fk_campusfind_claims_2_users` FOREIGN KEY (`campusfind_reviewer_user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `campusfind_section_views` ADD CONSTRAINT `fk_campusfind_section_views_0_users` FOREIGN KEY (`campusfind_user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

ALTER TABLE `fe_completion_logs` ADD CONSTRAINT `fk_fe_completion_logs_0_fe_teaching_assignments` FOREIGN KEY (`assignment_id`) REFERENCES `fe_teaching_assignments` (`assignment_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_completion_logs` ADD CONSTRAINT `fk_fe_completion_logs_1_fe_evaluation_schedules` FOREIGN KEY (`schedule_id`) REFERENCES `fe_evaluation_schedules` (`schedule_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_department_heads` ADD CONSTRAINT `fk_fe_department_heads_0_departments` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_department_heads` ADD CONSTRAINT `fk_fe_department_heads_1_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_questions` ADD CONSTRAINT `fk_fe_evaluation_questions_0_fe_evaluation_schedules` FOREIGN KEY (`schedule_id`) REFERENCES `fe_evaluation_schedules` (`schedule_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_reports` ADD CONSTRAINT `fk_fe_evaluation_reports_0_users` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_reports` ADD CONSTRAINT `fk_fe_evaluation_reports_1_departments` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_reports` ADD CONSTRAINT `fk_fe_evaluation_reports_2_users` FOREIGN KEY (`faculty_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_reports` ADD CONSTRAINT `fk_fe_evaluation_reports_3_users` FOREIGN KEY (`generated_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_reports` ADD CONSTRAINT `fk_fe_evaluation_reports_4_programs` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_reports` ADD CONSTRAINT `fk_fe_evaluation_reports_5_fe_evaluation_schedules` FOREIGN KEY (`schedule_id`) REFERENCES `fe_evaluation_schedules` (`schedule_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_responses` ADD CONSTRAINT `fk_fe_evaluation_responses_0_fe_evaluation_questions` FOREIGN KEY (`question_id`) REFERENCES `fe_evaluation_questions` (`question_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_responses` ADD CONSTRAINT `fk_fe_evaluation_responses_1_fe_evaluation_submissions` FOREIGN KEY (`submission_id`) REFERENCES `fe_evaluation_submissions` (`submission_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_schedules` ADD CONSTRAINT `fk_fe_evaluation_schedules_0_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_schedules` ADD CONSTRAINT `fk_fe_evaluation_schedules_1_users` FOREIGN KEY (`opened_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_schedules` ADD CONSTRAINT `fk_fe_evaluation_schedules_2_programs` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_schedules` ADD CONSTRAINT `fk_fe_evaluation_schedules_3_academic_periods` FOREIGN KEY (`term_id`) REFERENCES `academic_periods` (`period_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_submissions` ADD CONSTRAINT `fk_fe_evaluation_submissions_0_fe_teaching_assignments` FOREIGN KEY (`assignment_id`) REFERENCES `fe_teaching_assignments` (`assignment_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_evaluation_submissions` ADD CONSTRAINT `fk_fe_evaluation_submissions_1_fe_evaluation_schedules` FOREIGN KEY (`schedule_id`) REFERENCES `fe_evaluation_schedules` (`schedule_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_grade_completion` ADD CONSTRAINT `fk_fe_grade_completion_0_fe_teaching_assignments` FOREIGN KEY (`assignment_id`) REFERENCES `fe_teaching_assignments` (`assignment_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_grade_completion` ADD CONSTRAINT `fk_fe_grade_completion_1_fe_class_enrollments` FOREIGN KEY (`enrollment_id`) REFERENCES `fe_class_enrollments` (`enrollment_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_grade_completion` ADD CONSTRAINT `fk_fe_grade_completion_2_users` FOREIGN KEY (`validated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `fe_shs_specializations` ADD CONSTRAINT `fk_fe_shs_specializations_0_fe_shs_strands` FOREIGN KEY (`strand_id`) REFERENCES `fe_shs_strands` (`strand_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_shs_strands` ADD CONSTRAINT `fk_fe_shs_strands_0_programs` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `fe_shs_strands` ADD CONSTRAINT `fk_fe_shs_strands_1_fe_shs_tracks` FOREIGN KEY (`track_id`) REFERENCES `fe_shs_tracks` (`track_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_class_enrollments` ADD CONSTRAINT `fk_fe_class_enrollments_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_class_enrollments` ADD CONSTRAINT `fk_fe_class_enrollments_1_students` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_teaching_assignments` ADD CONSTRAINT `fk_fe_teaching_assignments_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_id`) ON UPDATE CASCADE;

ALTER TABLE `fe_teaching_assignments` ADD CONSTRAINT `fk_fe_teaching_assignments_1_users` FOREIGN KEY (`instructor_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

ALTER TABLE `lms_assignments` ADD CONSTRAINT `fk_lms_assignments_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE;

ALTER TABLE `lms_assignments` ADD CONSTRAINT `fk_lms_assignments_1_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_uid`);

ALTER TABLE `lms_discussion_posts` ADD CONSTRAINT `fk_lms_discussion_posts_0_users` FOREIGN KEY (`author_id`) REFERENCES `users` (`user_uid`);

ALTER TABLE `lms_discussion_posts` ADD CONSTRAINT `fk_lms_discussion_posts_1_lms_discussion_topics` FOREIGN KEY (`topic_id`) REFERENCES `lms_discussion_topics` (`id`) ON DELETE CASCADE;

ALTER TABLE `lms_discussion_topics` ADD CONSTRAINT `fk_lms_discussion_topics_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE;

ALTER TABLE `lms_discussion_topics` ADD CONSTRAINT `fk_lms_discussion_topics_1_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_uid`);

ALTER TABLE `lms_class_enrollments` ADD CONSTRAINT `fk_lms_class_enrollments_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE;

ALTER TABLE `lms_class_enrollments` ADD CONSTRAINT `fk_lms_class_enrollments_1_users` FOREIGN KEY (`student_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE;

ALTER TABLE `lms_materials` ADD CONSTRAINT `fk_lms_materials_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE;

ALTER TABLE `lms_materials` ADD CONSTRAINT `fk_lms_materials_1_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_uid`);

ALTER TABLE `lms_quiz_answer_keys` ADD CONSTRAINT `fk_lms_quiz_answer_keys_0_lms_quiz_questions` FOREIGN KEY (`question_id`) REFERENCES `lms_quiz_questions` (`id`) ON DELETE CASCADE;

ALTER TABLE `lms_quiz_attempts` ADD CONSTRAINT `fk_lms_quiz_attempts_0_lms_quizzes` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE CASCADE;

ALTER TABLE `lms_quiz_attempts` ADD CONSTRAINT `fk_lms_quiz_attempts_1_users` FOREIGN KEY (`student_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE;

ALTER TABLE `lms_quiz_questions` ADD CONSTRAINT `fk_lms_quiz_questions_0_lms_quizzes` FOREIGN KEY (`quiz_id`) REFERENCES `lms_quizzes` (`id`) ON DELETE CASCADE;

ALTER TABLE `lms_quizzes` ADD CONSTRAINT `fk_lms_quizzes_0_academic_classes` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE;

ALTER TABLE `lms_quizzes` ADD CONSTRAINT `fk_lms_quizzes_1_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_uid`);

ALTER TABLE `lms_registration_application_classes` ADD CONSTRAINT `fk_lms_registration_application_classes_0_application` FOREIGN KEY (`application_id`) REFERENCES `lms_registration_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `lms_registration_application_classes` ADD CONSTRAINT `fk_lms_registration_application_classes_1_class` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`class_uid`) ON DELETE CASCADE;

ALTER TABLE `lms_registration_applications` ADD CONSTRAINT `fk_lms_registration_applications_0_users` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_uid`) ON DELETE SET NULL;

ALTER TABLE `lms_registration_applications` ADD CONSTRAINT `fk_lms_registration_applications_1_users` FOREIGN KEY (`auth_user_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE;

ALTER TABLE `lms_submissions` ADD CONSTRAINT `fk_lms_submissions_0_lms_assignments` FOREIGN KEY (`assignment_id`) REFERENCES `lms_assignments` (`id`) ON DELETE CASCADE;

ALTER TABLE `lms_submissions` ADD CONSTRAINT `fk_lms_submissions_1_users` FOREIGN KEY (`graded_by`) REFERENCES `users` (`user_uid`) ON DELETE SET NULL;

ALTER TABLE `lms_submissions` ADD CONSTRAINT `fk_lms_submissions_2_users` FOREIGN KEY (`student_id`) REFERENCES `users` (`user_uid`) ON DELETE CASCADE;

ALTER TABLE `lms_sync_logs` ADD CONSTRAINT `fk_lms_sync_logs_0_users` FOREIGN KEY (`initiated_by`) REFERENCES `users` (`user_uid`) ON DELETE SET NULL;

ALTER TABLE `maint_assets` ADD CONSTRAINT `fk_maint_assets_0_maint_locations` FOREIGN KEY (`location_id`) REFERENCES `maint_locations` (`location_id`);

ALTER TABLE `maint_attachments` ADD CONSTRAINT `fk_maint_attachments_0_maint_inspection_findings` FOREIGN KEY (`finding_id`) REFERENCES `maint_inspection_findings` (`finding_id`);

ALTER TABLE `maint_attachments` ADD CONSTRAINT `fk_maint_attachments_1_maint_maintenance_requests` FOREIGN KEY (`request_id`) REFERENCES `maint_maintenance_requests` (`request_id`);

ALTER TABLE `maint_attachments` ADD CONSTRAINT `fk_maint_attachments_2_maint_repair_updates` FOREIGN KEY (`update_id`) REFERENCES `maint_repair_updates` (`update_id`);

ALTER TABLE `maint_attachments` ADD CONSTRAINT `fk_maint_attachments_3_maint_employees` FOREIGN KEY (`uploaded_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_inspection_findings` ADD CONSTRAINT `fk_maint_inspection_findings_0_maint_assets` FOREIGN KEY (`asset_id`) REFERENCES `maint_assets` (`asset_id`);

ALTER TABLE `maint_inspection_findings` ADD CONSTRAINT `fk_maint_inspection_findings_1_maint_inspections` FOREIGN KEY (`inspection_id`) REFERENCES `maint_inspections` (`inspection_id`) ON DELETE CASCADE;

ALTER TABLE `maint_inspection_findings` ADD CONSTRAINT `fk_maint_inspection_findings_2_maint_maintenance_requests` FOREIGN KEY (`request_id`) REFERENCES `maint_maintenance_requests` (`request_id`);

ALTER TABLE `maint_inspections` ADD CONSTRAINT `fk_maint_inspections_0_maint_employees` FOREIGN KEY (`created_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_inspections` ADD CONSTRAINT `fk_maint_inspections_1_maint_employees` FOREIGN KEY (`personnel_employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_inspections` ADD CONSTRAINT `fk_maint_inspections_2_maint_employees` FOREIGN KEY (`reviewed_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_maintenance_administrators` ADD CONSTRAINT `fk_maint_maintenance_administrators_0_maint_employees` FOREIGN KEY (`employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_maintenance_requests` ADD CONSTRAINT `fk_maint_maintenance_requests_0_maint_assets` FOREIGN KEY (`asset_id`) REFERENCES `maint_assets` (`asset_id`);

ALTER TABLE `maint_maintenance_requests` ADD CONSTRAINT `fk_maint_maintenance_requests_1_maint_employees` FOREIGN KEY (`assigned_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_maintenance_requests` ADD CONSTRAINT `fk_maint_maintenance_requests_2_maint_employees` FOREIGN KEY (`assigned_to_employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_maintenance_requests` ADD CONSTRAINT `fk_maint_maintenance_requests_3_maint_employees` FOREIGN KEY (`reported_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_maintenance_requests` ADD CONSTRAINT `fk_maint_maintenance_requests_4_maint_locations` FOREIGN KEY (`reported_location_id`) REFERENCES `maint_locations` (`location_id`);

ALTER TABLE `maint_maintenance_requests` ADD CONSTRAINT `fk_maint_maintenance_requests_5_maint_employees` FOREIGN KEY (`verified_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_repair_updates` ADD CONSTRAINT `fk_maint_repair_updates_0_maint_maintenance_requests` FOREIGN KEY (`request_id`) REFERENCES `maint_maintenance_requests` (`request_id`);

ALTER TABLE `maint_repair_updates` ADD CONSTRAINT `fk_maint_repair_updates_1_maint_employees` FOREIGN KEY (`updated_by_employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_request_comments` ADD CONSTRAINT `fk_maint_request_comments_0_maint_employees` FOREIGN KEY (`employee_id`) REFERENCES `maint_employees` (`employee_id`);

ALTER TABLE `maint_request_comments` ADD CONSTRAINT `fk_maint_request_comments_1_maint_maintenance_requests` FOREIGN KEY (`request_id`) REFERENCES `maint_maintenance_requests` (`request_id`) ON DELETE CASCADE;

ALTER TABLE `guidance_staff_profiles` ADD CONSTRAINT `fk_guidance_staff_profiles_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `guidance_counselor_availability` ADD CONSTRAINT `fk_guidance_counselor_availability_0_guidance_sta_44a23d93` FOREIGN KEY (`staff_id`) REFERENCES `guidance_staff_profiles` (`staff_id`);

ALTER TABLE `guidance_appointments` ADD CONSTRAINT `fk_guidance_appointments_0_students` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

ALTER TABLE `guidance_appointments` ADD CONSTRAINT `fk_guidance_appointments_1_guidance_staff_profiles` FOREIGN KEY (`staff_id`) REFERENCES `guidance_staff_profiles` (`staff_id`);

ALTER TABLE `guidance_appointments` ADD CONSTRAINT `fk_guidance_appointments_2_guidance_counselor_availability` FOREIGN KEY (`availability_id`) REFERENCES `guidance_counselor_availability` (`id`);

ALTER TABLE `guidance_records` ADD CONSTRAINT `fk_guidance_records_0_students` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

ALTER TABLE `guidance_records` ADD CONSTRAINT `fk_guidance_records_1_guidance_appointments` FOREIGN KEY (`appointment_id`) REFERENCES `guidance_appointments` (`id`);

ALTER TABLE `guidance_records` ADD CONSTRAINT `fk_guidance_records_2_guidance_staff_profiles` FOREIGN KEY (`staff_id`) REFERENCES `guidance_staff_profiles` (`staff_id`);

ALTER TABLE `guidance_referrals` ADD CONSTRAINT `fk_guidance_referrals_0_students` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

ALTER TABLE `guidance_referrals` ADD CONSTRAINT `fk_guidance_referrals_1_guidance_staff_profiles` FOREIGN KEY (`staff_id`) REFERENCES `guidance_staff_profiles` (`staff_id`);

ALTER TABLE `guidance_follow_ups` ADD CONSTRAINT `fk_guidance_follow_ups_0_guidance_records` FOREIGN KEY (`record_id`) REFERENCES `guidance_records` (`id`);

ALTER TABLE `guidance_follow_ups` ADD CONSTRAINT `fk_guidance_follow_ups_1_guidance_staff_profiles` FOREIGN KEY (`staff_id`) REFERENCES `guidance_staff_profiles` (`staff_id`);

ALTER TABLE `event_criteria` ADD CONSTRAINT `fk_event_criteria_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON UPDATE CASCADE;

ALTER TABLE `event_events` ADD CONSTRAINT `fk_event_events_0_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

ALTER TABLE `event_entries` ADD CONSTRAINT `fk_event_entries_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON UPDATE CASCADE;

ALTER TABLE `event_entries` ADD CONSTRAINT `fk_event_entries_1_event_participants` FOREIGN KEY (`participant_id`) REFERENCES `event_participants` (`participant_id`) ON UPDATE CASCADE;

ALTER TABLE `event_entries` ADD CONSTRAINT `fk_event_entries_2_event_teams` FOREIGN KEY (`team_id`) REFERENCES `event_teams` (`team_id`) ON UPDATE CASCADE;

ALTER TABLE `event_judges` ADD CONSTRAINT `fk_event_judges_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON UPDATE CASCADE;

ALTER TABLE `event_judges` ADD CONSTRAINT `fk_event_judges_1_users` FOREIGN KEY (`judge_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

ALTER TABLE `event_tabulator_assignments` ADD CONSTRAINT `fk_event_tabulator_assignments_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `event_tabulator_assignments` ADD CONSTRAINT `fk_event_tabulator_assignments_1_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `event_generated_reports` ADD CONSTRAINT `fk_event_generated_reports_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `event_generated_reports` ADD CONSTRAINT `fk_event_generated_reports_1_users` FOREIGN KEY (`generated_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

ALTER TABLE `event_participant_photos` ADD CONSTRAINT `fk_event_participant_photos_0_event_participants` FOREIGN KEY (`participant_id`) REFERENCES `event_participants` (`participant_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `event_point_awards` ADD CONSTRAINT `fk_event_point_awards_0_users` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

ALTER TABLE `event_point_awards` ADD CONSTRAINT `fk_event_point_awards_1_event_participants` FOREIGN KEY (`participant_id`) REFERENCES `event_participants` (`participant_id`) ON UPDATE CASCADE;

ALTER TABLE `event_point_awards` ADD CONSTRAINT `fk_event_point_awards_2_event_result_summaries` FOREIGN KEY (`result_id`) REFERENCES `event_result_summaries` (`result_id`) ON UPDATE CASCADE;

ALTER TABLE `event_point_awards` ADD CONSTRAINT `fk_event_point_awards_3_event_teams` FOREIGN KEY (`team_id`) REFERENCES `event_teams` (`team_id`) ON UPDATE CASCADE;

ALTER TABLE `event_point_rules` ADD CONSTRAINT `fk_event_point_rules_0_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON UPDATE CASCADE;

ALTER TABLE `event_result_summaries` ADD CONSTRAINT `fk_event_result_summaries_0_event_entries` FOREIGN KEY (`entry_id`) REFERENCES `event_entries` (`entry_id`) ON UPDATE CASCADE;

ALTER TABLE `event_scores` ADD CONSTRAINT `fk_event_scores_0_event_judges` FOREIGN KEY (`assignment_id`) REFERENCES `event_judges` (`assignment_id`) ON UPDATE CASCADE;

ALTER TABLE `event_scores` ADD CONSTRAINT `fk_event_scores_1_event_criteria` FOREIGN KEY (`criterion_id`) REFERENCES `event_criteria` (`criterion_id`) ON UPDATE CASCADE;

ALTER TABLE `event_scores` ADD CONSTRAINT `fk_event_scores_2_event_entries` FOREIGN KEY (`entry_id`) REFERENCES `event_entries` (`entry_id`) ON UPDATE CASCADE;

ALTER TABLE `event_sports_matches` ADD CONSTRAINT `fk_event_sports_matches_0_event_entries` FOREIGN KEY (`entry_a_id`) REFERENCES `event_entries` (`entry_id`) ON UPDATE CASCADE;

ALTER TABLE `event_sports_matches` ADD CONSTRAINT `fk_event_sports_matches_1_event_entries` FOREIGN KEY (`entry_b_id`) REFERENCES `event_entries` (`entry_id`) ON UPDATE CASCADE;

ALTER TABLE `event_sports_matches` ADD CONSTRAINT `fk_event_sports_matches_2_event_events` FOREIGN KEY (`event_id`) REFERENCES `event_events` (`event_id`) ON UPDATE CASCADE;

ALTER TABLE `event_staff_registration_requests` ADD CONSTRAINT `fk_event_staff_registration_requests_0_users` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `event_team_members` ADD CONSTRAINT `fk_event_team_members_0_event_participants` FOREIGN KEY (`participant_id`) REFERENCES `event_participants` (`participant_id`) ON UPDATE CASCADE;

ALTER TABLE `event_team_members` ADD CONSTRAINT `fk_event_team_members_1_event_teams` FOREIGN KEY (`team_id`) REFERENCES `event_teams` (`team_id`) ON UPDATE CASCADE;

ALTER TABLE `idcard_iadfc_idcards` ADD CONSTRAINT `fk_idcard_iadfc_idcards_0_idcard_persons` FOREIGN KEY (`PersonId`) REFERENCES `idcard_persons` (`PersonId`);

ALTER TABLE `idcard_iadfc_idcards` ADD CONSTRAINT `fk_idcard_iadfc_idcards_1_users` FOREIGN KEY (`GeneratedBy`) REFERENCES `users` (`user_id`);

ALTER TABLE `idcard_iadfc_idreleases` ADD CONSTRAINT `fk_idcard_iadfc_idreleases_0_idcard_iadfc_idcards` FOREIGN KEY (`CardId`) REFERENCES `idcard_iadfc_idcards` (`CardId`);

ALTER TABLE `idcard_iadfc_idreleases` ADD CONSTRAINT `fk_idcard_iadfc_idreleases_1_users` FOREIGN KEY (`ReleasedBy`) REFERENCES `users` (`user_id`);

ALTER TABLE `idcard_iadfc_printrecords` ADD CONSTRAINT `fk_idcard_iadfc_printrecords_0_idcard_iadfc_idcards` FOREIGN KEY (`CardId`) REFERENCES `idcard_iadfc_idcards` (`CardId`);

ALTER TABLE `idcard_iadfc_printrecords` ADD CONSTRAINT `fk_idcard_iadfc_printrecords_1_users` FOREIGN KEY (`PrintedBy`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_applications` ADD CONSTRAINT `fk_eteeap_applications_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

ALTER TABLE `eteeap_assessments` ADD CONSTRAINT `fk_eteeap_assessments_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `eteeap_assessments` ADD CONSTRAINT `fk_eteeap_assessments_1_users` FOREIGN KEY (`assessor_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `eteeap_billing_fees` ADD CONSTRAINT `fk_eteeap_billing_fees_0_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_billing_invoices` ADD CONSTRAINT `fk_eteeap_billing_invoices_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`);

ALTER TABLE `eteeap_billing_invoices` ADD CONSTRAINT `fk_eteeap_billing_invoices_1_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_billing_invoices` ADD CONSTRAINT `fk_eteeap_billing_invoices_2_eteeap_billing_fees` FOREIGN KEY (`fee_id`) REFERENCES `eteeap_billing_fees` (`id`);

ALTER TABLE `eteeap_billing_invoices` ADD CONSTRAINT `fk_eteeap_billing_invoices_3_users` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_billing_payments` ADD CONSTRAINT `fk_eteeap_billing_payments_0_users` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_billing_payments` ADD CONSTRAINT `fk_eteeap_billing_payments_1_eteeap_billing_invoices` FOREIGN KEY (`invoice_id`) REFERENCES `eteeap_billing_invoices` (`id`);

ALTER TABLE `eteeap_billing_payments` ADD CONSTRAINT `fk_eteeap_billing_payments_2_users` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_credits` ADD CONSTRAINT `fk_eteeap_credits_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `eteeap_credits` ADD CONSTRAINT `fk_eteeap_credits_1_users` FOREIGN KEY (`decided_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_credits` ADD CONSTRAINT `fk_eteeap_credits_2_users` FOREIGN KEY (`evaluator_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_education_records` ADD CONSTRAINT `fk_eteeap_education_records_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `eteeap_employment_records` ADD CONSTRAINT `fk_eteeap_employment_records_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `eteeap_evaluations` ADD CONSTRAINT `fk_eteeap_evaluations_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `eteeap_evaluations` ADD CONSTRAINT `fk_eteeap_evaluations_1_users` FOREIGN KEY (`assessor_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_grades` ADD CONSTRAINT `fk_eteeap_grades_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `eteeap_grades` ADD CONSTRAINT `fk_eteeap_grades_1_users` FOREIGN KEY (`assessor_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_messages` ADD CONSTRAINT `fk_eteeap_messages_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `eteeap_messages` ADD CONSTRAINT `fk_eteeap_messages_1_users` FOREIGN KEY (`sender_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_program_offerings` ADD CONSTRAINT `fk_eteeap_program_offerings_0_users` FOREIGN KEY (`configured_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_uploads` ADD CONSTRAINT `fk_eteeap_uploads_0_eteeap_applications` FOREIGN KEY (`application_id`) REFERENCES `eteeap_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `eteeap_uploads` ADD CONSTRAINT `fk_eteeap_uploads_1_eteeap_uploads` FOREIGN KEY (`replaces_upload_id`) REFERENCES `eteeap_uploads` (`id`) ON DELETE SET NULL;

ALTER TABLE `eteeap_uploads` ADD CONSTRAINT `fk_eteeap_uploads_2_users` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `eteeap_upload_events` ADD CONSTRAINT `fk_eteeap_upload_events_0_users` FOREIGN KEY (`actor_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `eteeap_upload_events` ADD CONSTRAINT `fk_eteeap_upload_events_1_eteeap_uploads` FOREIGN KEY (`upload_id`) REFERENCES `eteeap_uploads` (`id`) ON DELETE CASCADE;

ALTER TABLE `admit_applicants` ADD CONSTRAINT `fk_admit_applicants_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `admit_evaluations` ADD CONSTRAINT `fk_admit_evaluations_0_admit_applicants` FOREIGN KEY (`applicant_id`) REFERENCES `admit_applicants` (`id`) ON DELETE CASCADE;

ALTER TABLE `admit_evaluations` ADD CONSTRAINT `fk_admit_evaluations_1_users` FOREIGN KEY (`evaluator_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `admit_interview_slots` ADD CONSTRAINT `fk_admit_interview_slots_0_users` FOREIGN KEY (`interviewer_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `admit_interviews` ADD CONSTRAINT `fk_admit_interviews_0_admit_applicants` FOREIGN KEY (`applicant_id`) REFERENCES `admit_applicants` (`id`) ON DELETE CASCADE;

ALTER TABLE `admit_interviews` ADD CONSTRAINT `fk_admit_interviews_1_users` FOREIGN KEY (`interviewer_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `admit_interviews` ADD CONSTRAINT `fk_admit_interviews_2_admit_interview_slots` FOREIGN KEY (`slot_id`) REFERENCES `admit_interview_slots` (`id`) ON DELETE SET NULL;

ALTER TABLE `scholar_application_documents` ADD CONSTRAINT `fk_scholar_application_documents_0_scholar_schola_343d3f91` FOREIGN KEY (`scholarship_application_id`) REFERENCES `scholar_scholarship_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `scholar_application_documents` ADD CONSTRAINT `fk_scholar_application_documents_1_scholar_schola_eef01317` FOREIGN KEY (`scholarship_requirement_id`) REFERENCES `scholar_scholarship_requirements` (`id`) ON DELETE SET NULL;

ALTER TABLE `scholar_application_documents` ADD CONSTRAINT `fk_scholar_application_documents_2_users` FOREIGN KEY (`verified_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `scholar_application_evaluations` ADD CONSTRAINT `fk_scholar_application_evaluations_0_users` FOREIGN KEY (`evaluator_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

ALTER TABLE `scholar_application_evaluations` ADD CONSTRAINT `fk_scholar_application_evaluations_1_scholar_scho_0f7834d6` FOREIGN KEY (`scholarship_application_id`) REFERENCES `scholar_scholarship_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `scholar_application_status_histories` ADD CONSTRAINT `fk_scholar_application_status_histories_0_users` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `scholar_application_status_histories` ADD CONSTRAINT `fk_scholar_application_status_histories_1_scholar_0eb5d191` FOREIGN KEY (`scholarship_application_id`) REFERENCES `scholar_scholarship_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `scholar_document_reviews` ADD CONSTRAINT `fk_scholar_document_reviews_0_scholar_application_documents` FOREIGN KEY (`application_document_id`) REFERENCES `scholar_application_documents` (`id`);

ALTER TABLE `scholar_document_reviews` ADD CONSTRAINT `fk_scholar_document_reviews_1_users` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`);

ALTER TABLE `scholar_eligibility_results` ADD CONSTRAINT `fk_scholar_eligibility_results_0_users` FOREIGN KEY (`checked_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `scholar_eligibility_results` ADD CONSTRAINT `fk_scholar_eligibility_results_1_scholar_scholars_433b4b93` FOREIGN KEY (`scholarship_application_id`) REFERENCES `scholar_scholarship_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `scholar_eligibility_rules` ADD CONSTRAINT `fk_scholar_eligibility_rules_0_scholar_scholarship_programs` FOREIGN KEY (`scholarship_program_id`) REFERENCES `scholar_scholarship_programs` (`id`) ON DELETE CASCADE;

ALTER TABLE `scholar_renewal_applications` ADD CONSTRAINT `fk_scholar_renewal_applications_0_users` FOREIGN KEY (`decided_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `scholar_renewal_applications` ADD CONSTRAINT `fk_scholar_renewal_applications_1_scholar_scholar_9a1e773e` FOREIGN KEY (`scholarship_award_id`) REFERENCES `scholar_scholarship_awards` (`id`) ON DELETE CASCADE;

ALTER TABLE `scholar_renewal_applications` ADD CONSTRAINT `fk_scholar_renewal_applications_2_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

ALTER TABLE `scholar_scholarship_appeals` ADD CONSTRAINT `fk_scholar_scholarship_appeals_0_users` FOREIGN KEY (`decided_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `scholar_scholarship_appeals` ADD CONSTRAINT `fk_scholar_scholarship_appeals_1_scholar_scholarship_awards` FOREIGN KEY (`scholarship_award_id`) REFERENCES `scholar_scholarship_awards` (`id`) ON DELETE CASCADE;

ALTER TABLE `scholar_scholarship_appeals` ADD CONSTRAINT `fk_scholar_scholarship_appeals_2_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

ALTER TABLE `scholar_scholarship_applications` ADD CONSTRAINT `fk_scholar_scholarship_applications_0_users` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `scholar_scholarship_applications` ADD CONSTRAINT `fk_scholar_scholarship_applications_1_users` FOREIGN KEY (`decided_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `scholar_scholarship_applications` ADD CONSTRAINT `fk_scholar_scholarship_applications_2_scholar_sch_966bff10` FOREIGN KEY (`scholarship_program_id`) REFERENCES `scholar_scholarship_programs` (`id`) ON DELETE CASCADE;

ALTER TABLE `scholar_scholarship_applications` ADD CONSTRAINT `fk_scholar_scholarship_applications_3_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

ALTER TABLE `scholar_scholarship_awards` ADD CONSTRAINT `fk_scholar_scholarship_awards_0_users` FOREIGN KEY (`awarded_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `scholar_scholarship_awards` ADD CONSTRAINT `fk_scholar_scholarship_awards_1_scholar_scholarsh_da5a0353` FOREIGN KEY (`scholarship_application_id`) REFERENCES `scholar_scholarship_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `scholar_scholarship_awards` ADD CONSTRAINT `fk_scholar_scholarship_awards_2_scholar_scholarsh_ed8880b1` FOREIGN KEY (`scholarship_program_id`) REFERENCES `scholar_scholarship_programs` (`id`) ON DELETE CASCADE;

ALTER TABLE `scholar_scholarship_awards` ADD CONSTRAINT `fk_scholar_scholarship_awards_3_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

ALTER TABLE `scholar_scholarship_programs` ADD CONSTRAINT `fk_scholar_scholarship_programs_0_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

ALTER TABLE `scholar_scholarship_requirements` ADD CONSTRAINT `fk_scholar_scholarship_requirements_0_scholar_sch_a921b9c9` FOREIGN KEY (`scholarship_program_id`) REFERENCES `scholar_scholarship_programs` (`id`) ON DELETE CASCADE;

ALTER TABLE `election_face_data` ADD CONSTRAINT `fk_election_face_data_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_elections` ADD CONSTRAINT `fk_election_elections_0_users` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `election_face_verifications` ADD CONSTRAINT `fk_election_face_verifications_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_face_verifications` ADD CONSTRAINT `fk_election_face_verifications_1_election_elections` FOREIGN KEY (`election_id`) REFERENCES `election_elections` (`election_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_face_verifications` ADD CONSTRAINT `fk_election_face_verifications_2_users` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_positions` ADD CONSTRAINT `fk_election_positions_0_election_elections` FOREIGN KEY (`election_id`) REFERENCES `election_elections` (`election_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_candidacies` ADD CONSTRAINT `fk_election_candidacies_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_candidacies` ADD CONSTRAINT `fk_election_candidacies_1_election_positions` FOREIGN KEY (`position_id`) REFERENCES `election_positions` (`position_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_candidacies` ADD CONSTRAINT `fk_election_candidacies_2_users` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_candidate_documents` ADD CONSTRAINT `fk_election_candidate_documents_0_election_candidacies` FOREIGN KEY (`candidate_id`) REFERENCES `election_candidacies` (`candidate_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `election_vote_records` ADD CONSTRAINT `fk_election_vote_records_0_election_positions` FOREIGN KEY (`position_id`) REFERENCES `election_positions` (`position_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_ballots` ADD CONSTRAINT `fk_election_ballots_0_election_candidacies` FOREIGN KEY (`candidate_id`) REFERENCES `election_candidacies` (`candidate_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_results` ADD CONSTRAINT `fk_election_results_0_election_candidacies` FOREIGN KEY (`candidate_id`) REFERENCES `election_candidacies` (`candidate_id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `election_security_sessions` ADD CONSTRAINT `fk_election_security_sessions_0_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

ALTER TABLE `readmit_applications` ADD CONSTRAINT `fk_readmit_applications_0_users` FOREIGN KEY (`applicant_id`) REFERENCES `users` (`user_uid`);

ALTER TABLE `readmit_applications` ADD CONSTRAINT `fk_readmit_applications_1_programs` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`);

ALTER TABLE `readmit_applications` ADD CONSTRAINT `fk_readmit_applications_2_users` FOREIGN KEY (`assigned_evaluator_id`) REFERENCES `users` (`user_uid`);

ALTER TABLE `readmit_documents` ADD CONSTRAINT `fk_readmit_documents_0_readmit_applications` FOREIGN KEY (`application_id`) REFERENCES `readmit_applications` (`id`) ON DELETE CASCADE;

ALTER TABLE `readmit_documents` ADD CONSTRAINT `fk_readmit_documents_1_readmit_requirements` FOREIGN KEY (`requirement_id`) REFERENCES `readmit_requirements` (`id`);

ALTER TABLE `readmit_application_history` ADD CONSTRAINT `fk_readmit_application_history_0_readmit_applications` FOREIGN KEY (`application_id`) REFERENCES `readmit_applications` (`id`) ON DELETE CASCADE;


-- Read/write compatibility for the latest admin-side OneCampus UI (simple updatable view).
-- Other subsystem applications must update their table/column mappings.
CREATE OR REPLACE VIEW `admin_users` AS
SELECT `user_id` AS `admin_user_id`, `username`, `email`, `password_hash`,
       `full_name`, `role`, `status`, `last_login`, `created_at`, `updated_at`
FROM `users`
WHERE `role` IN ('Administrator','Enrollment Personnel');

SET FOREIGN_KEY_CHECKS=1;
