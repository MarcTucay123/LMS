-- ============================================================================
-- LMS migration 022: My Learning module paths
-- Target database: adfc_onecampus
-- Safe to rerun. Existing materials, assignments, quizzes, exams, and
-- discussions remain the authoritative activity records.
-- ============================================================================

SET NAMES utf8mb4;
USE `adfc_onecampus`;

CREATE TABLE IF NOT EXISTS learning_modules (
    id CHAR(36) NOT NULL,
    class_id VARCHAR(40) NOT NULL,
    title VARCHAR(180) NOT NULL,
    description TEXT NULL,
    position INT UNSIGNED NOT NULL DEFAULT 1,
    opens_at DATETIME NULL,
    due_at DATETIME NULL,
    status ENUM('draft','published','closed') NOT NULL DEFAULT 'draft',
    prerequisite_module_id CHAR(36) NULL,
    created_by VARCHAR(40) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_learning_modules_class_position (class_id, position),
    KEY ix_learning_modules_prerequisite (prerequisite_module_id),
    CONSTRAINT fk_learning_modules_class FOREIGN KEY (class_id) REFERENCES academic_classes (class_uid) ON DELETE CASCADE,
    CONSTRAINT fk_learning_modules_creator FOREIGN KEY (created_by) REFERENCES users (user_uid),
    CONSTRAINT fk_learning_modules_prerequisite FOREIGN KEY (prerequisite_module_id) REFERENCES learning_modules (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS learning_module_items (
    id CHAR(36) NOT NULL,
    module_id CHAR(36) NOT NULL,
    item_type ENUM('material','assignment','quiz','exam','discussion') NOT NULL,
    item_id CHAR(36) NOT NULL,
    title_override VARCHAR(180) NULL,
    position INT UNSIGNED NOT NULL DEFAULT 1,
    is_required TINYINT(1) NOT NULL DEFAULT 1,
    estimated_minutes SMALLINT UNSIGNED NULL,
    created_by VARCHAR(40) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_learning_module_activity (module_id, item_type, item_id),
    KEY ix_learning_module_items_order (module_id, position),
    CONSTRAINT fk_learning_module_items_module FOREIGN KEY (module_id) REFERENCES learning_modules (id) ON DELETE CASCADE,
    CONSTRAINT fk_learning_module_items_creator FOREIGN KEY (created_by) REFERENCES users (user_uid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS learning_item_completions (
    module_item_id CHAR(36) NOT NULL,
    user_id VARCHAR(40) NOT NULL,
    completed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (module_item_id, user_id),
    KEY ix_learning_item_completions_user (user_id, completed_at),
    CONSTRAINT fk_learning_item_completions_item FOREIGN KEY (module_item_id) REFERENCES learning_module_items (id) ON DELETE CASCADE,
    CONSTRAINT fk_learning_item_completions_user FOREIGN KEY (user_id) REFERENCES users (user_uid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (migration_id,module_code,migration_name,batch,applied_at)
SELECT (SELECT COALESCE(MAX(migration_id),0)+1 FROM schema_migrations),'lms','2026_11_26_lms_my_learning_paths_v1',15,NOW()
WHERE NOT EXISTS (SELECT 1 FROM schema_migrations WHERE module_code='lms' AND migration_name='2026_11_26_lms_my_learning_paths_v1');

SELECT 'My Learning module paths installed' AS result;