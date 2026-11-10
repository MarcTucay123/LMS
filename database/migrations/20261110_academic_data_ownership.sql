USE lms_db;

-- Non-destructive migration for shared-system ownership metadata.
-- Safe to run against an existing LMS database; no tables or records are dropped.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS source_system VARCHAR(80) NOT NULL DEFAULT 'lms_registration'
    COMMENT 'Authoritative identity source; external records are synchronized and read-only in LMS' AFTER onecampus_user_id,
  ADD COLUMN IF NOT EXISTS synced_at DATETIME NULL AFTER source_system;

ALTER TABLE subjects
  ADD COLUMN IF NOT EXISTS source_system VARCHAR(80) NOT NULL DEFAULT 'course_catalog'
    COMMENT 'Owned by OneCampus/course catalog; LMS stores a synchronized projection' AFTER onecampus_subject_id,
  ADD COLUMN IF NOT EXISTS synced_at DATETIME NULL AFTER source_system;

ALTER TABLE classes
  ADD COLUMN IF NOT EXISTS source_system VARCHAR(80) NOT NULL DEFAULT 'class_scheduling'
    COMMENT 'Owned by OneCampus/Class Scheduling; not editable in LMS' AFTER onecampus_class_id,
  ADD COLUMN IF NOT EXISTS synced_at DATETIME NULL AFTER source_system;

ALTER TABLE enrollments
  ADD COLUMN IF NOT EXISTS source_system VARCHAR(80) NOT NULL DEFAULT 'enrollment_management'
    COMMENT 'Owned by OneCampus/Enrollment Management; not editable in LMS' AFTER onecampus_enrollment_id,
  ADD COLUMN IF NOT EXISTS synced_at DATETIME NULL AFTER source_system;

UPDATE profiles
SET source_system = CASE
      WHEN onecampus_user_id IS NULL THEN 'lms_registration'
      WHEN role = 'instructor' THEN 'employee_management'
      WHEN role = 'student' THEN 'enrollment_management'
      ELSE 'onecampus'
    END,
    synced_at = CASE WHEN onecampus_user_id IS NOT NULL THEN COALESCE(synced_at, updated_at) ELSE NULL END;

UPDATE subjects
SET source_system = 'course_catalog',
    synced_at = COALESCE(synced_at, updated_at);

UPDATE classes
SET source_system = 'class_scheduling',
    synced_at = COALESCE(synced_at, updated_at);

UPDATE enrollments
SET source_system = 'enrollment_management',
    synced_at = COALESCE(synced_at, updated_at);