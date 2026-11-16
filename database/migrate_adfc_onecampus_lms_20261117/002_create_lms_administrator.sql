-- Creates/repairs the administrator requested for the LMS subsystem.
-- Login username: adfc_lms
-- Initial password: adfc1984
-- The stored value is a PHP bcrypt hash; the plain password is not stored.
-- Safe to rerun. Change the password after the first successful server login.

SET NAMES utf8mb4;
USE `adfc_onecampus`;

INSERT INTO users (
    user_uid,
    username,
    email,
    password_hash,
    full_name,
    status,
    email_verified_at,
    must_change_password,
    session_version
) VALUES (
    'USER-LMS-ADMIN-0001',
    'adfc_lms',
    'marctucay321321@gmail.com',
    '$2y$10$sXbPk4cEnDlcdF7fYYMKtOgx0krvINSKySUWJbbRGkUzuE2McAbVO',
    'ADFC LMS Administrator',
    'Active',
    NOW(),
    1,
    1
)
ON DUPLICATE KEY UPDATE
    user_uid = VALUES(user_uid),
    username = VALUES(username),
    email = VALUES(email),
    password_hash = VALUES(password_hash),
    full_name = VALUES(full_name),
    status = 'Active',
    email_verified_at = COALESCE(email_verified_at, NOW()),
    must_change_password = 1,
    session_version = session_version + 1;

INSERT IGNORE INTO user_access_roles (user_id, role_id, module_code)
SELECT u.user_id, ar.role_id, 'lms'
FROM users u
INNER JOIN access_roles ar ON ar.role_name = 'Administrator'
WHERE u.username = 'adfc_lms';

INSERT IGNORE INTO schema_migrations (module_code, migration_name, batch)
VALUES ('lms', '2026_11_17_lms_administrator_v1', 1);
