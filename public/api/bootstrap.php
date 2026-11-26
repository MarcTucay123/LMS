<?php
declare(strict_types=1);

$config = require __DIR__ . '/config.php';

if (!date_default_timezone_set((string)$config['app_timezone'])) {
    throw new RuntimeException('The configured LMS timezone is invalid.');
}

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_name('adfc_lms_session');
    session_set_cookie_params([
        'lifetime' => 0,
        'path' => rtrim((string)$config['app_path'], '/') . '/',
        'secure' => isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
        'httponly' => true,
        'samesite' => 'Lax',
    ]);
    session_start();
}

function db(): PDO
{
    return onecampus_db();
}

function onecampus_connection_config(): array
{
    global $config;
    $sessionConfig = $_SESSION['onecampus_connection'] ?? [];
    return [
        'host' => is_array($sessionConfig) && isset($sessionConfig['host']) ? (string)$sessionConfig['host'] : (string)$config['onecampus_db_host'],
        'port' => is_array($sessionConfig) && isset($sessionConfig['port']) ? (string)$sessionConfig['port'] : (string)$config['onecampus_db_port'],
        'name' => is_array($sessionConfig) && isset($sessionConfig['name']) ? (string)$sessionConfig['name'] : (string)$config['onecampus_db_name'],
        'user' => is_array($sessionConfig) && isset($sessionConfig['user']) ? (string)$sessionConfig['user'] : (string)$config['onecampus_db_user'],
        'pass' => is_array($sessionConfig) && isset($sessionConfig['pass']) ? (string)$sessionConfig['pass'] : (string)$config['onecampus_db_pass'],
    ];
}

function onecampus_db(?array $connection = null): PDO
{
    global $config;
    static $connections = [];
    $selected = $connection ?? onecampus_connection_config();
    if (($selected['host'] ?? '') === '' || ($selected['user'] ?? '') === '') throw new RuntimeException('The OneCampus database connection is not configured.');
    $connectionKey = hash('sha256', json_encode($selected));
    if (isset($connections[$connectionKey]) && $connections[$connectionKey] instanceof PDO) return $connections[$connectionKey];
    $dsn = sprintf(
        'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
        $selected['host'],
        $selected['port'],
        $selected['name'],
    );
    $pdo = new PDO($dsn, $selected['user'], $selected['pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
        PDO::ATTR_TIMEOUT => 4,
    ]);
    $databaseTimezone = (string)($config['database_timezone'] ?? '+08:00');
    if (!preg_match('/^[+-](?:0\d|1[0-4]):[0-5]\d$/', $databaseTimezone)) {
        throw new RuntimeException('The configured database timezone is invalid.');
    }
    $pdo->exec("SET time_zone = " . $pdo->quote($databaseTimezone));
    $connections[$connectionKey] = $pdo;
    return $connections[$connectionKey];
}

function json_response(array $body = [], int $status = 200): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

function fail(string $message, int $status = 400): never
{
    json_response(['error' => $message], $status);
}

function request_data(): array
{
    if (str_contains($_SERVER['CONTENT_TYPE'] ?? '', 'multipart/form-data')) return $_POST;
    $raw = file_get_contents('php://input');
    if ($raw === '' || $raw === false) return $_POST;
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

function uuid(): string
{
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}

function sql_datetime(?string $value): ?string
{
    if ($value === null || trim($value) === '') return null;
    try {
        global $config;
        $timezone = new DateTimeZone((string)$config['app_timezone']);
        return (new DateTimeImmutable($value))->setTimezone($timezone)->format('Y-m-d H:i:s');
    }
    catch (Throwable) { fail('A supplied date is invalid.'); }
}

function current_user_id(): ?string
{
    $id = $_SESSION['user_id'] ?? null;
    if (!is_string($id) || $id === '') return null;
    $lastActivity = (int)($_SESSION['last_activity_at'] ?? time());
    $timeoutSeconds = lms_security_settings()['inactivity_timeout_minutes'] * 60;
    if (time() - $lastActivity >= $timeoutSeconds) {
        clear_authenticated_session();
        $_SESSION['session_expired_due_to_inactivity'] = true;
        return null;
    }
    return $id;
}

function clear_authenticated_session(): void
{
    unset($_SESSION['user_id'], $_SESSION['last_activity_at']);
}

function lms_security_settings(): array
{
    $defaults = [
        'max_login_attempts' => 5,
        'lockout_minutes' => 15,
        'inactivity_timeout_minutes' => 10,
        'live_attendance_minimized_enabled' => true,
        'live_attendance_tab_hidden_enabled' => true,
        'live_attendance_window_blur_enabled' => true,
        'live_attendance_inactivity_enabled' => true,
        'live_attendance_inactivity_seconds' => 30,
    ];
    try {
        $row = db()->query('SELECT max_login_attempts,lockout_minutes,inactivity_timeout_minutes,live_attendance_minimized_enabled,live_attendance_tab_hidden_enabled,live_attendance_window_blur_enabled,live_attendance_inactivity_enabled,live_attendance_inactivity_seconds FROM lms_security_settings WHERE settings_id=1')->fetch();
        if (!$row) return $defaults;
        return [
            'max_login_attempts' => (int)$row['max_login_attempts'],
            'lockout_minutes' => (int)$row['lockout_minutes'],
            'inactivity_timeout_minutes' => (int)$row['inactivity_timeout_minutes'],
            'live_attendance_minimized_enabled' => (bool)$row['live_attendance_minimized_enabled'],
            'live_attendance_tab_hidden_enabled' => (bool)$row['live_attendance_tab_hidden_enabled'],
            'live_attendance_window_blur_enabled' => (bool)$row['live_attendance_window_blur_enabled'],
            'live_attendance_inactivity_enabled' => (bool)$row['live_attendance_inactivity_enabled'],
            'live_attendance_inactivity_seconds' => (int)$row['live_attendance_inactivity_seconds'],
        ];
    } catch (PDOException $error) {
        if (in_array(($error->errorInfo[1] ?? null), [1054,1146], true)) return $defaults;
        throw $error;
    }
}

function user_payload(array $user): array
{
    return [
        'id' => $user['id'],
        'email' => $user['email'],
        'user_metadata' => ['requested_role' => $user['requested_role']],
    ];
}

function lms_role_sql(string $userAlias = 'u', string $instructorAlias = 'i', string $studentAlias = 's'): string
{
    return "CASE
        WHEN EXISTS (
            SELECT 1 FROM user_access_roles uar
            JOIN access_roles ar ON ar.role_id=uar.role_id
            WHERE uar.user_id={$userAlias}.user_id
              AND uar.module_code IN ('lms','enrollment','scheduling')
              AND ar.role_name='Administrator' AND ar.is_active=1
        ) THEN 'admin'
        WHEN {$instructorAlias}.instructor_id IS NOT NULL AND {$instructorAlias}.is_active=1 AND EXISTS (
            SELECT 1 FROM academic_classes ac
            WHERE ac.instructor_id={$instructorAlias}.instructor_id
              AND ac.status='Active'
        ) THEN 'instructor'
        WHEN {$studentAlias}.student_id IS NOT NULL AND {$studentAlias}.record_status='Active' AND EXISTS (
            SELECT 1 FROM enrollments e
            WHERE e.student_id={$studentAlias}.student_id
              AND e.enrollment_status='Confirmed'
        ) THEN 'student'
        ELSE NULL END";
}

function session_payload(): ?array
{
    $id = current_user_id();
    if ($id === null) return null;
    $roleSql = lms_role_sql();
    $stmt = db()->prepare("SELECT CAST(u.user_id AS CHAR) id,LOWER(u.email) email,{$roleSql} requested_role
        FROM users u
        LEFT JOIN instructors i ON i.user_id=u.user_id
        LEFT JOIN students s ON s.student_id=u.student_id
        WHERE u.user_id=?");
    $stmt->execute([$id]);
    $user = $stmt->fetch();
    if (!$user) return null;
    return ['user' => user_payload($user)];
}

function require_user(): array
{
    $id = current_user_id();
    if ($id === null) {
        $expired = !empty($_SESSION['session_expired_due_to_inactivity']);
        unset($_SESSION['session_expired_due_to_inactivity']);
        fail($expired ? 'Your session expired due to inactivity. Please sign in again.' : 'Authentication is required.', 401);
    }
    $roleSql = lms_role_sql();
    $stmt = db()->prepare("SELECT CAST(u.user_id AS CHAR) id,LOWER(u.email) email,
        {$roleSql} requested_role,{$roleSql} role,
        CASE WHEN u.status='Active' THEN 'active' ELSE 'inactive' END status,u.full_name,u.user_uid,
        u.student_id,i.instructor_id
        FROM users u
        LEFT JOIN instructors i ON i.user_id=u.user_id
        LEFT JOIN students s ON s.student_id=u.student_id
        WHERE u.user_id=?");
    $stmt->execute([$id]);
    $user = $stmt->fetch();
    if (!$user) fail('Invalid session.', 401);
    return $user;
}

function require_active_user(): array
{
    $user = require_user();
    if (!$user['role']) fail('Your account has not been granted access to the LMS.', 403);
    if ($user['status'] !== 'active') fail('Your account is not active.', 403);
    return $user;
}

function require_admin(): array
{
    $user = require_active_user();
    if ($user['role'] !== 'admin') fail('Only active administrators can perform this action.', 403);
    return $user;
}

function class_access(string $classId, ?array $user = null): bool
{
    $user ??= require_active_user();
    if ($user['role'] === 'admin') return true;
    if ($user['role'] === 'instructor') {
        $stmt = db()->prepare('SELECT 1 FROM academic_classes WHERE class_uid=? AND instructor_id=?');
        $stmt->execute([$classId, $user['instructor_id']]);
        return (bool)$stmt->fetchColumn();
    }
    $stmt = db()->prepare("SELECT 1
        FROM academic_classes c
        JOIN blocks b ON b.block_code=c.section
        JOIN enrollments e ON e.period_id=c.period_id AND e.block_id=b.block_id
        JOIN enrollment_subjects es ON es.enrollment_id=e.enrollment_id AND es.subject_id=c.subject_id
        WHERE c.class_uid=? AND e.student_id=?
          AND c.status='Active' AND e.enrollment_status='Confirmed' AND es.subject_status='Enrolled'");
    $stmt->execute([$classId, $user['student_id']]);
    return (bool)$stmt->fetchColumn();
}

function class_manage(string $classId, ?array $user = null): bool
{
    $user ??= require_active_user();
    if ($user['role'] !== 'instructor') return false;
    $stmt = db()->prepare('SELECT 1 FROM academic_classes WHERE class_uid=? AND instructor_id=?');
    $stmt->execute([$classId, $user['instructor_id']]);
    return (bool)$stmt->fetchColumn();
}

function class_report_access(string $classId, ?array $user = null): bool
{
    $user ??= require_active_user();
    return $user['role'] === 'admin' || class_manage($classId, $user);
}

function require_class_access(string $classId): array
{
    $user = require_active_user();
    if (!class_access($classId, $user)) fail('You are not allowed to access this class.', 403);
    return $user;
}

function require_class_manager(string $classId): array
{
    $user = require_active_user();
    if (!class_manage($classId, $user)) fail('Only the assigned instructor can manage instructional content for this class.', 403);
    return $user;
}

function class_id_for_record(string $table, string $id): ?string
{
    $queries = [
        'materials' => 'SELECT class_id FROM learning_materials WHERE id=?',
        'announcements' => "SELECT c.class_uid FROM announcements a JOIN academic_classes c ON c.class_id=a.class_id WHERE a.announcement_id=? AND a.module_code='lms'",
        'discussion_topics' => 'SELECT class_id FROM learning_discussion_topics WHERE id=?',
        'discussion_posts' => 'SELECT t.class_id FROM learning_discussion_posts p JOIN learning_discussion_topics t ON t.id=p.topic_id WHERE p.id=?',
        'assignments' => 'SELECT class_id FROM learning_assignments WHERE id=?',
        'submissions' => 'SELECT a.class_id FROM assignment_submissions s JOIN learning_assignments a ON a.id=s.assignment_id WHERE s.id=?',
        'quizzes' => 'SELECT class_id FROM quizzes WHERE id=?',
        'quiz_questions' => 'SELECT q.class_id FROM quiz_questions qq JOIN quizzes q ON q.id=qq.quiz_id WHERE qq.id=?',
        'quiz_answer_keys' => 'SELECT q.class_id FROM quiz_answer_keys k JOIN quiz_questions qq ON qq.id=k.question_id JOIN quizzes q ON q.id=qq.quiz_id WHERE k.question_id=?',
        'quiz_attempts' => 'SELECT q.class_id FROM quiz_attempts a JOIN quizzes q ON q.id=a.quiz_id WHERE a.id=?',
        'learning_modules' => 'SELECT class_id FROM learning_modules WHERE id=?',
        'learning_module_items' => 'SELECT m.class_id FROM learning_module_items i JOIN learning_modules m ON m.id=i.module_id WHERE i.id=?',
    ];
    if (!isset($queries[$table])) return null;
    $stmt = db()->prepare($queries[$table]);
    $stmt->execute([$id]);
    $value = $stmt->fetchColumn();
    return is_string($value) ? $value : null;
}

function content_table(string $table): string
{
    return match ($table) {
        'materials' => 'learning_materials',
        'discussion_topics' => 'learning_discussion_topics',
        'discussion_posts' => 'learning_discussion_posts',
        'assignments' => 'learning_assignments',
        'submissions' => 'assignment_submissions',
        'learning_modules' => 'learning_modules',
        'learning_module_items' => 'learning_module_items',
        default => $table,
    };
}

function user_uid(array $user): string
{
    $value = (string)($user['user_uid'] ?? '');
    if ($value === '') fail('Your account is missing its stable OneCampus identifier.', 409);
    return $value;
}

function normalize_row(string $table, array $row): array
{
    foreach ($row as $key => $value) {
        if (is_string($value) && in_array($key, [
            'opens_at', 'closes_at', 'due_at', 'started_at', 'submitted_at', 'graded_at',
            'created_at', 'updated_at', 'published_at', 'occurred_at', 'scheduled_start',
            'question_opened_at', 'ended_at', 'joined_at', 'last_seen_at', 'last_read_at', 'completed_at', 'pinned_at', 'deleted_at', 'muted_until', 'left_at',
        ], true) && preg_match('/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/', $value)) {
            global $config;
            $timezone = new DateTimeZone((string)$config['app_timezone']);
            $row[$key] = (new DateTimeImmutable($value, $timezone))->format(DATE_ATOM);
        }
        if (in_array($key, ['options','answers','essay_scores','records'], true) && is_string($value)) {
            $row[$key] = json_decode($value, true) ?? ($key === 'options' ? [] : []);
        }
        if (in_array($key, ['is_locked','is_pinned','is_deleted','is_joined','reply_to_is_deleted','reacted_by_me','case_sensitive','show_correct_answer','show_leaderboard','randomize_choices','is_correct','mic_muted','camera_enabled','screen_sharing','is_attending','is_host','my_joined','can_manage','is_required','is_completed'], true)) $row[$key] = $value === null ? null : (bool)$value;
        if (in_array($key, ['points','grade','score','max_score','points_awarded','file_submission_points','submission_file_score'], true) && $value !== null) $row[$key] = (float)$value;
        if (in_array($key, ['year_level','position','time_limit_minutes','question_time_seconds','response_time_ms','participant_count','response_count','enrolled_count','attachment_size','joined_count','estimated_minutes'], true) && $value !== null) $row[$key] = (int)$value;
    }
    if ($table === 'registration_applications' && !isset($row['selected_class_ids'])) $row['selected_class_ids'] = [];
    return $row;
}

function fetch_all(string $sql, array $params = [], string $table = ''): array
{
    $stmt = db()->prepare($sql);
    $stmt->execute($params);
    return array_map(fn(array $row) => normalize_row($table, $row), $stmt->fetchAll());
}

function lms_audit(string $action, ?string $recordType, ?string $recordId, string $description, ?array $oldValues = null, ?array $newValues = null, ?array $actor = null): void
{
    $actor ??= require_active_user();
    $details = $recordId === null ? null : ['record_id' => $recordId];
    $oldValues = audit_safe_values($oldValues);
    $newValues = audit_safe_values($newValues);
    $statement = db()->prepare("INSERT INTO activity_logs
        (module_code,details_json,old_values_json,new_values_json,admin_user_id,action,record_type,record_id,description,ip_address,details_text,actor_role,user_agent)
        VALUES ('lms',?,?,?,?,?,?,NULL,?,?,?,?,?)");
    $statement->execute([
        $details ? json_encode($details, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : null,
        $oldValues ? json_encode($oldValues, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : null,
        $newValues ? json_encode($newValues, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : null,
        $actor['id'] ?? null,
        mb_substr($action, 0, 60),
        $recordType ? mb_substr($recordType, 0, 60) : null,
        mb_substr($description, 0, 255),
        mb_substr((string)($_SERVER['REMOTE_ADDR'] ?? ''), 0, 45) ?: null,
        $description,
        $actor['role'] ?? null,
        mb_substr((string)($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255) ?: null,
    ]);
}

function audit_safe_values(?array $values): ?array
{
    if ($values === null) return null;
    foreach (['correct_answer', 'answers', 'password', 'password_hash', 'reset_token_hash'] as $sensitiveKey) unset($values[$sensitiveKey]);
    return $values;
}

function filter_value(array $filters, string $column, string $type = 'eq'): mixed
{
    foreach ($filters as $filter) {
        if (($filter['column'] ?? null) === $column && ($filter['type'] ?? null) === $type) return $filter['value'] ?? null;
    }
    return null;
}

function validate_password(string $password): void
{
    if (strlen($password) < 8 || !preg_match('/[A-Z]/', $password) || !preg_match('/[a-z]/', $password) || !preg_match('/[0-9]/', $password)) {
        fail('Password must be at least 8 characters and contain uppercase, lowercase, and a number.');
    }
}

function valid_name(?string $value, bool $required = false): ?string
{
    $value = trim(preg_replace('/\s+/', ' ', $value ?? '') ?? '');
    if ($value === '') {
        if ($required) fail('First name and last name are required.');
        return null;
    }
    if (mb_strlen($value) > 80 || !preg_match("/^[\p{L}\p{M} .'-]+$/u", $value)) fail('Enter a valid name.');
    return $value;
}

function unique_violation(Throwable $error): bool
{
    return $error instanceof PDOException && ($error->errorInfo[0] ?? '') === '23000';
}