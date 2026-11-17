-- Repairs an LMS administrator accidentally stored with users.user_id = 0.
--
-- The shared users table uses:
--   user_id  INT UNSIGNED AUTO_INCREMENT (internal relational key)
--   user_uid VARCHAR(40) UNIQUE          (stable public identifier)
--
-- Safe to rerun. Existing valid user_id values and user_uid values are preserved.

SET NAMES utf8mb4;
USE `adfc_onecampus`;

SET @previous_foreign_key_checks := @@FOREIGN_KEY_CHECKS;
SET @lms_admin_old_user_id := 0;
SET @lms_admin_new_user_id := (
    SELECT COALESCE(MAX(user_id), 0) + 1
    FROM users
);
SET @repair_lms_admin := (
    SELECT COUNT(*)
    FROM users
    WHERE user_id = @lms_admin_old_user_id
      AND username = 'adfc_lms'
      AND user_uid = 'USER-LMS-ADMIN-0001'
);

SET FOREIGN_KEY_CHECKS = 0;

-- Preserve subsystem role assignments that use the numeric internal key.
UPDATE IGNORE user_access_roles
SET user_id = @lms_admin_new_user_id
WHERE user_id = @lms_admin_old_user_id
  AND @repair_lms_admin = 1;

-- Preserve any LMS registration references if this account was already used.
UPDATE learning_registration_requests
SET user_id = @lms_admin_new_user_id
WHERE user_id = @lms_admin_old_user_id
  AND @repair_lms_admin = 1;

UPDATE learning_registration_requests
SET reviewed_by = @lms_admin_new_user_id
WHERE reviewed_by = @lms_admin_old_user_id
  AND @repair_lms_admin = 1;

-- Change only the broken internal key. The stable user_uid is intentionally kept.
UPDATE users
SET user_id = @lms_admin_new_user_id
WHERE user_id = @lms_admin_old_user_id
  AND username = 'adfc_lms'
  AND user_uid = 'USER-LMS-ADMIN-0001'
  AND @repair_lms_admin = 1;

-- Keep MySQL's auto-increment counter ahead of the repaired value so future
-- inserts do not collide with the recovered administrator record.
SET @lms_admin_next_auto_increment := (
    SELECT COALESCE(MAX(user_id), 0) + 1
    FROM users
);
ALTER TABLE users AUTO_INCREMENT = @lms_admin_next_auto_increment;

SET FOREIGN_KEY_CHECKS = @previous_foreign_key_checks;

-- Recreate the LMS role assignment if the broken row did not have one.
INSERT IGNORE INTO user_access_roles (user_id, role_id, module_code)
SELECT u.user_id, ar.role_id, 'lms'
FROM users u
INNER JOIN access_roles ar ON ar.role_name = 'Administrator'
WHERE u.username = 'adfc_lms'
  AND u.user_uid = 'USER-LMS-ADMIN-0001';

INSERT IGNORE INTO schema_migrations (module_code, migration_name, batch)
VALUES ('lms', '2026_11_17_lms_administrator_user_id_repair_v1', 2);

SELECT
    u.user_id,
    u.user_uid,
    u.username,
    u.status,
    ar.role_name,
    uar.module_code
FROM users u
LEFT JOIN user_access_roles uar
    ON uar.user_id = u.user_id
   AND uar.module_code = 'lms'
LEFT JOIN access_roles ar ON ar.role_id = uar.role_id
WHERE u.username = 'adfc_lms';