-- LMS migration 016: Private profile pictures shared across LMS identity displays.
-- Target database: adfc_onecampus. Safe to rerun.
USE `adfc_onecampus`;

CREATE TABLE IF NOT EXISTS user_profiles (
    user_id INT UNSIGNED NOT NULL,
    avatar_path VARCHAR(255) NULL,
    profile_photo MEDIUMBLOB NULL,
    profile_photo_mime VARCHAR(100) NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    CONSTRAINT fk_shared_profile_user FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @avatar_path_missing := (SELECT COUNT(*)=0 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='avatar_path');
SET @avatar_path_sql := IF(@avatar_path_missing,'ALTER TABLE user_profiles ADD COLUMN avatar_path VARCHAR(255) NULL AFTER user_id','SELECT 1');
PREPARE avatar_path_statement FROM @avatar_path_sql; EXECUTE avatar_path_statement; DEALLOCATE PREPARE avatar_path_statement;

INSERT INTO schema_migrations (migration_id,module_code,migration_name,batch,applied_at)
SELECT (SELECT COALESCE(MAX(migration_id),0)+1 FROM schema_migrations),'lms','2026_11_25_lms_profile_pictures_v1',10,NOW()
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_lms_profile_pictures_v1');

SET @profile_picture_migration_id := (SELECT MAX(migration_id) FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_25_lms_profile_pictures_v1');
DELETE FROM schema_migrations
WHERE module_code='lms' AND migration_name='2026_11_25_lms_profile_pictures_v1' AND migration_id<>@profile_picture_migration_id;
SET @profile_picture_migration_next_id := (SELECT COALESCE(MAX(migration_id),0)+1 FROM schema_migrations WHERE NOT (module_code='lms' AND migration_name='2026_11_25_lms_profile_pictures_v1'));
UPDATE schema_migrations
SET migration_id=IF(migration_id=0,@profile_picture_migration_next_id,migration_id),batch=10
WHERE module_code='lms' AND migration_name='2026_11_25_lms_profile_pictures_v1';