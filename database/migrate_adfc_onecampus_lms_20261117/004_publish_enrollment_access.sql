-- Publishes authoritative confirmed Enrollment data to LMS RBAC and class membership.
-- Safe to rerun. It does not create accounts, guess student links, or invent classes.

SET NAMES utf8mb4;
USE `adfc_onecampus`;

-- Reset tokens are LMS authentication metadata; the password itself remains the
-- single shared central-account password in users.password_hash.
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS reset_token_hash CHAR(64) NULL AFTER locked_until,
    ADD COLUMN IF NOT EXISTS reset_expires_at DATETIME NULL AFTER reset_token_hash;
CREATE INDEX IF NOT EXISTS ix_users_reset_token_hash ON users (reset_token_hash);

DELIMITER $$

DROP PROCEDURE IF EXISTS `sp_publish_lms_enrollment_access`$$
CREATE PROCEDURE `sp_publish_lms_enrollment_access`(IN p_enrollment_id INT UNSIGNED)
BEGIN
    DECLARE v_student_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_status VARCHAR(20) DEFAULT NULL;

    SELECT student_id, enrollment_status
      INTO v_student_id, v_status
      FROM enrollments
     WHERE enrollment_id = p_enrollment_id
     LIMIT 1;

    IF v_student_id IS NOT NULL AND v_status = 'Confirmed' THEN
        -- Approval may activate an existing linked pending account, but never creates
        -- credentials or links an account by name/email heuristics.
        UPDATE users
           SET status = 'Active'
         WHERE student_id = v_student_id
           AND status = 'Pending';

        INSERT IGNORE INTO user_access_roles (user_id, role_id, module_code)
        SELECT u.user_id, ar.role_id, 'lms'
          FROM users u
          JOIN students s ON s.student_id = u.student_id
          JOIN access_roles ar ON ar.role_name = 'Student' AND ar.is_active = 1
         WHERE u.student_id = v_student_id
           AND u.status = 'Active'
           AND s.record_status = 'Active';

        INSERT INTO class_enrollments
            (enrollment_uid, student_id, class_id, membership_status, enrolled_at)
        SELECT UUID(), e.student_id, c.class_id, 'Active', COALESCE(e.confirmed_at, NOW())
          FROM enrollments e
          JOIN enrollment_subjects es
            ON es.enrollment_id = e.enrollment_id
           AND es.subject_status = 'Enrolled'
          JOIN blocks b ON b.block_id = e.block_id
          JOIN academic_classes c
            ON c.period_id = e.period_id
           AND c.subject_id = es.subject_id
           AND c.section = b.block_code
         WHERE e.enrollment_id = p_enrollment_id
           AND e.enrollment_status = 'Confirmed'
           AND c.status = 'Active'
        ON DUPLICATE KEY UPDATE
            membership_status = 'Active',
            updated_at = CURRENT_TIMESTAMP;

        UPDATE class_enrollments ce
        JOIN academic_classes c ON c.class_id = ce.class_id
        JOIN enrollments e
          ON e.student_id = ce.student_id
         AND e.period_id = c.period_id
        LEFT JOIN enrollment_subjects es
          ON es.enrollment_id = e.enrollment_id
         AND es.subject_id = c.subject_id
         AND es.subject_status = 'Enrolled'
           SET ce.membership_status = 'Withdrawn'
         WHERE e.enrollment_id = p_enrollment_id
           AND es.enrollment_subject_id IS NULL;
    ELSEIF v_student_id IS NOT NULL THEN
        UPDATE class_enrollments ce
        JOIN academic_classes c ON c.class_id = ce.class_id
        JOIN enrollments e
          ON e.student_id = ce.student_id
         AND e.period_id = c.period_id
           SET ce.membership_status = 'Withdrawn'
         WHERE e.enrollment_id = p_enrollment_id
           AND ce.membership_status = 'Active';
    END IF;
END$$

DROP TRIGGER IF EXISTS `trg_enrollments_lms_publish_ai`$$
CREATE TRIGGER `trg_enrollments_lms_publish_ai`
AFTER INSERT ON enrollments
FOR EACH ROW CALL sp_publish_lms_enrollment_access(NEW.enrollment_id)$$

DROP TRIGGER IF EXISTS `trg_enrollments_lms_publish_au`$$
CREATE TRIGGER `trg_enrollments_lms_publish_au`
AFTER UPDATE ON enrollments
FOR EACH ROW CALL sp_publish_lms_enrollment_access(NEW.enrollment_id)$$

DROP TRIGGER IF EXISTS `trg_enrollment_subjects_lms_publish_ai`$$
CREATE TRIGGER `trg_enrollment_subjects_lms_publish_ai`
AFTER INSERT ON enrollment_subjects
FOR EACH ROW CALL sp_publish_lms_enrollment_access(NEW.enrollment_id)$$

DROP TRIGGER IF EXISTS `trg_enrollment_subjects_lms_publish_au`$$
CREATE TRIGGER `trg_enrollment_subjects_lms_publish_au`
AFTER UPDATE ON enrollment_subjects
FOR EACH ROW CALL sp_publish_lms_enrollment_access(NEW.enrollment_id)$$

DROP TRIGGER IF EXISTS `trg_enrollment_subjects_lms_publish_ad`$$
CREATE TRIGGER `trg_enrollment_subjects_lms_publish_ad`
AFTER DELETE ON enrollment_subjects
FOR EACH ROW CALL sp_publish_lms_enrollment_access(OLD.enrollment_id)$$

DELIMITER ;

-- Existing active instructors receive an explicit LMS role. Authorization still
-- limits each instructor to classes assigned by academic_classes.instructor_id.
INSERT IGNORE INTO user_access_roles (user_id, role_id, module_code)
SELECT u.user_id, ar.role_id, 'lms'
  FROM instructors i
  JOIN users u ON u.user_id = i.user_id AND u.status = 'Active'
  JOIN access_roles ar ON ar.role_name = 'Instructor' AND ar.is_active = 1
 WHERE i.is_active = 1;

-- Idempotent backfill from every authoritative enrollment currently present.
DELIMITER $$
DROP PROCEDURE IF EXISTS `sp_backfill_lms_enrollment_access`$$
CREATE PROCEDURE `sp_backfill_lms_enrollment_access`()
BEGIN
    DECLARE v_done TINYINT DEFAULT 0;
    DECLARE v_enrollment_id INT UNSIGNED;
    DECLARE enrollment_cursor CURSOR FOR
        SELECT enrollment_id FROM enrollments ORDER BY enrollment_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN enrollment_cursor;
    enrollment_loop: LOOP
        FETCH enrollment_cursor INTO v_enrollment_id;
        IF v_done = 1 THEN
            LEAVE enrollment_loop;
        END IF;
        CALL sp_publish_lms_enrollment_access(v_enrollment_id);
    END LOOP;
    CLOSE enrollment_cursor;
END$$
DELIMITER ;

CALL sp_backfill_lms_enrollment_access();
DROP PROCEDURE IF EXISTS `sp_backfill_lms_enrollment_access`;

INSERT IGNORE INTO schema_migrations (module_code, migration_name, batch)
VALUES ('lms', '2026_11_17_publish_enrollment_access_v1', 3);