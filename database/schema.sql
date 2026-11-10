CREATE DATABASE IF NOT EXISTS adfc_lms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE adfc_lms;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS quiz_attempts, quiz_answer_keys, quiz_questions, quizzes, submissions, assignments,
  discussion_posts, discussion_topics, announcements, materials, sync_logs, registration_application_classes,
  registration_applications, activation_records, enrollments, classes, subjects, profiles, users;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
  id CHAR(36) PRIMARY KEY,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  requested_role ENUM('student','instructor','admin') NULL,
  reset_token_hash CHAR(64) NULL,
  reset_expires_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE profiles (
  id CHAR(36) PRIMARY KEY,
  onecampus_user_id VARCHAR(100) NULL UNIQUE,
  source_system VARCHAR(80) NOT NULL DEFAULT 'lms_registration' COMMENT 'Authoritative identity source; external records are synchronized and read-only in LMS',
  synced_at DATETIME NULL,
  school_id VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(190) NOT NULL UNIQUE,
  full_name VARCHAR(255) NOT NULL,
  first_name VARCHAR(80) NULL,
  middle_name VARCHAR(80) NULL,
  last_name VARCHAR(80) NULL,
  suffix VARCHAR(20) NULL,
  class_code VARCHAR(20) NULL,
  program VARCHAR(30) NULL,
  year_level TINYINT UNSIGNED NULL,
  block VARCHAR(20) NULL,
  academic_year VARCHAR(20) NULL,
  semester VARCHAR(40) NULL,
  role ENUM('student','instructor','admin') NOT NULL,
  status ENUM('pending','active','inactive') NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT profiles_user_fk FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE subjects (
  id CHAR(36) PRIMARY KEY,
  onecampus_subject_id VARCHAR(100) NULL UNIQUE,
  source_system VARCHAR(80) NOT NULL DEFAULT 'course_catalog' COMMENT 'Owned by OneCampus/course catalog; LMS stores a synchronized projection',
  synced_at DATETIME NULL,
  code VARCHAR(40) NOT NULL UNIQUE,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE classes (
  id CHAR(36) PRIMARY KEY,
  onecampus_class_id VARCHAR(100) NULL UNIQUE,
  source_system VARCHAR(80) NOT NULL DEFAULT 'class_scheduling' COMMENT 'Owned by OneCampus/Class Scheduling; not editable in LMS',
  synced_at DATETIME NULL,
  subject_id CHAR(36) NOT NULL,
  instructor_id CHAR(36) NOT NULL,
  section VARCHAR(80) NOT NULL,
  school_year VARCHAR(20) NOT NULL,
  semester VARCHAR(40) NOT NULL,
  status ENUM('active','archived') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY classes_offering_unique (subject_id, section, school_year, semester),
  CONSTRAINT classes_subject_fk FOREIGN KEY (subject_id) REFERENCES subjects(id),
  CONSTRAINT classes_instructor_fk FOREIGN KEY (instructor_id) REFERENCES profiles(id)
) ENGINE=InnoDB;

CREATE TABLE enrollments (
  id CHAR(36) PRIMARY KEY,
  onecampus_enrollment_id VARCHAR(100) NULL UNIQUE,
  source_system VARCHAR(80) NOT NULL DEFAULT 'enrollment_management' COMMENT 'Owned by OneCampus/Enrollment Management; not editable in LMS',
  synced_at DATETIME NULL,
  class_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  status ENUM('enrolled','dropped','completed') NOT NULL DEFAULT 'enrolled',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY enrollments_member_unique (class_id, student_id),
  CONSTRAINT enrollments_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT enrollments_student_fk FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE activation_records (
  id CHAR(36) PRIMARY KEY,
  onecampus_user_id VARCHAR(100) NOT NULL UNIQUE,
  school_id VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(190) NOT NULL UNIQUE,
  full_name VARCHAR(255) NOT NULL,
  role ENUM('student','instructor','admin') NOT NULL,
  auth_user_id CHAR(36) NULL UNIQUE,
  activated_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT activation_user_fk FOREIGN KEY (auth_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE registration_applications (
  id CHAR(36) PRIMARY KEY,
  auth_user_id CHAR(36) NOT NULL UNIQUE,
  email VARCHAR(190) NOT NULL UNIQUE,
  full_name VARCHAR(255) NOT NULL,
  first_name VARCHAR(80) NOT NULL,
  middle_name VARCHAR(80) NULL,
  last_name VARCHAR(80) NOT NULL,
  suffix VARCHAR(20) NULL,
  student_id_number VARCHAR(30) NULL UNIQUE,
  class_code VARCHAR(4) NULL,
  program VARCHAR(30) NULL,
  year_level TINYINT UNSIGNED NULL,
  block VARCHAR(20) NULL,
  academic_year VARCHAR(20) NULL,
  semester VARCHAR(40) NULL,
  terms_accepted_at DATETIME NULL,
  requested_role ENUM('student','instructor','admin') NOT NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  reviewed_by CHAR(36) NULL,
  reviewed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT registrations_user_fk FOREIGN KEY (auth_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT registrations_reviewer_fk FOREIGN KEY (reviewed_by) REFERENCES profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE registration_application_classes (
  application_id CHAR(36) NOT NULL,
  class_id CHAR(36) NOT NULL,
  PRIMARY KEY (application_id, class_id),
  CONSTRAINT registration_classes_application_fk FOREIGN KEY (application_id) REFERENCES registration_applications(id) ON DELETE CASCADE,
  CONSTRAINT registration_classes_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE sync_logs (
  id CHAR(36) PRIMARY KEY,
  initiated_by CHAR(36) NULL,
  source ENUM('mock','onecampus_api') NOT NULL,
  status ENUM('running','success','failed') NOT NULL,
  records JSON NOT NULL,
  message TEXT NULL,
  started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  CONSTRAINT sync_initiator_fk FOREIGN KEY (initiated_by) REFERENCES profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE materials (
  id CHAR(36) PRIMARY KEY,
  class_id CHAR(36) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  file_path VARCHAR(500) NULL,
  external_url VARCHAR(1000) NULL,
  created_by CHAR(36) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT materials_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT materials_creator_fk FOREIGN KEY (created_by) REFERENCES profiles(id)
) ENGINE=InnoDB;

CREATE TABLE announcements (
  id CHAR(36) PRIMARY KEY, class_id CHAR(36) NOT NULL, title VARCHAR(255) NOT NULL, body TEXT NOT NULL,
  created_by CHAR(36) NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT announcements_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT announcements_creator_fk FOREIGN KEY (created_by) REFERENCES profiles(id)
) ENGINE=InnoDB;

CREATE TABLE discussion_topics (
  id CHAR(36) PRIMARY KEY, class_id CHAR(36) NOT NULL, title VARCHAR(255) NOT NULL, body TEXT NOT NULL,
  created_by CHAR(36) NOT NULL, is_locked BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT topics_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT topics_creator_fk FOREIGN KEY (created_by) REFERENCES profiles(id)
) ENGINE=InnoDB;

CREATE TABLE discussion_posts (
  id CHAR(36) PRIMARY KEY, topic_id CHAR(36) NOT NULL, author_id CHAR(36) NOT NULL, body TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT posts_topic_fk FOREIGN KEY (topic_id) REFERENCES discussion_topics(id) ON DELETE CASCADE,
  CONSTRAINT posts_author_fk FOREIGN KEY (author_id) REFERENCES profiles(id)
) ENGINE=InnoDB;

CREATE TABLE assignments (
  id CHAR(36) PRIMARY KEY, class_id CHAR(36) NOT NULL, title VARCHAR(255) NOT NULL, instructions TEXT NOT NULL,
  due_at DATETIME NULL, points DECIMAL(10,2) NOT NULL DEFAULT 100, status ENUM('draft','published','closed') NOT NULL DEFAULT 'draft',
  created_by CHAR(36) NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT assignments_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT assignments_creator_fk FOREIGN KEY (created_by) REFERENCES profiles(id)
) ENGINE=InnoDB;

CREATE TABLE submissions (
  id CHAR(36) PRIMARY KEY, assignment_id CHAR(36) NOT NULL, student_id CHAR(36) NOT NULL,
  content TEXT NULL, file_path VARCHAR(500) NULL, status ENUM('draft','submitted','graded') NOT NULL DEFAULT 'submitted',
  submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, grade DECIMAL(10,2) NULL, feedback TEXT NULL,
  graded_by CHAR(36) NULL, graded_at DATETIME NULL, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY submissions_student_unique (assignment_id, student_id),
  CONSTRAINT submissions_assignment_fk FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
  CONSTRAINT submissions_student_fk FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE,
  CONSTRAINT submissions_grader_fk FOREIGN KEY (graded_by) REFERENCES profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE quizzes (
  id CHAR(36) PRIMARY KEY, class_id CHAR(36) NOT NULL, title VARCHAR(255) NOT NULL, description TEXT NULL,
  opens_at DATETIME NULL, closes_at DATETIME NULL, time_limit_minutes INT NULL,
  status ENUM('draft','published','closed') NOT NULL DEFAULT 'draft', created_by CHAR(36) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT quizzes_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT quizzes_creator_fk FOREIGN KEY (created_by) REFERENCES profiles(id)
) ENGINE=InnoDB;

CREATE TABLE quiz_questions (
  id CHAR(36) PRIMARY KEY, quiz_id CHAR(36) NOT NULL, prompt TEXT NOT NULL,
  question_type ENUM('multiple_choice','true_false','short_answer') NOT NULL, options JSON NOT NULL,
  points DECIMAL(10,2) NOT NULL DEFAULT 1, position INT NOT NULL DEFAULT 0, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT questions_quiz_fk FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE quiz_answer_keys (
  question_id CHAR(36) PRIMARY KEY, correct_answer TEXT NOT NULL, case_sensitive BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT keys_question_fk FOREIGN KEY (question_id) REFERENCES quiz_questions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE quiz_attempts (
  id CHAR(36) PRIMARY KEY, quiz_id CHAR(36) NOT NULL, student_id CHAR(36) NOT NULL, answers JSON NOT NULL,
  score DECIMAL(10,2) NULL, max_score DECIMAL(10,2) NULL, status ENUM('in_progress','submitted') NOT NULL DEFAULT 'submitted',
  started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, submitted_at DATETIME NULL,
  UNIQUE KEY attempts_student_unique (quiz_id, student_id),
  CONSTRAINT attempts_quiz_fk FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE,
  CONSTRAINT attempts_student_fk FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB;