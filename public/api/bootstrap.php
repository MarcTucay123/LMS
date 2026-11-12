<?php
declare(strict_types=1);

$config = require __DIR__ . '/config.php';

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_name('adfc_lms_session');
    session_set_cookie_params([
        'lifetime' => 0,
        'path' => '/lms/',
        'secure' => isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
        'httponly' => true,
        'samesite' => 'Lax',
    ]);
    session_start();
}

function db(): PDO
{
    static $pdo;
    global $config;
    if ($pdo instanceof PDO) return $pdo;
    $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $config['db_host'], $config['db_port'], $config['db_name']);
    $pdo = new PDO($dsn, $config['db_user'], $config['db_pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
    return $pdo;
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
    try { return (new DateTimeImmutable($value))->format('Y-m-d H:i:s'); }
    catch (Throwable) { fail('A supplied date is invalid.'); }
}

function current_user_id(): ?string
{
    $id = $_SESSION['user_id'] ?? null;
    return is_string($id) && $id !== '' ? $id : null;
}

function user_payload(array $user): array
{
    return [
        'id' => $user['id'],
        'email' => $user['email'],
        'user_metadata' => ['requested_role' => $user['requested_role']],
    ];
}

function session_payload(): ?array
{
    $id = current_user_id();
    if (!$id) return null;
    $stmt = db()->prepare('SELECT id,email,requested_role FROM users WHERE id=?');
    $stmt->execute([$id]);
    $user = $stmt->fetch();
    if (!$user) return null;
    return ['user' => user_payload($user)];
}

function require_user(): array
{
    $id = current_user_id();
    if (!$id) fail('Authentication is required.', 401);
    $stmt = db()->prepare('SELECT u.id,u.email,u.requested_role,p.role,p.status,p.full_name FROM users u LEFT JOIN profiles p ON p.id=u.id WHERE u.id=?');
    $stmt->execute([$id]);
    $user = $stmt->fetch();
    if (!$user) fail('Invalid session.', 401);
    return $user;
}

function require_active_user(): array
{
    $user = require_user();
    if (!$user['role'] || $user['status'] !== 'active') fail('Your account is not active.', 403);
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
        $stmt = db()->prepare('SELECT 1 FROM classes WHERE id=? AND instructor_id=?');
        $stmt->execute([$classId, $user['id']]);
        return (bool)$stmt->fetchColumn();
    }
    $stmt = db()->prepare("SELECT 1 FROM enrollments WHERE class_id=? AND student_id=? AND status='enrolled'");
    $stmt->execute([$classId, $user['id']]);
    return (bool)$stmt->fetchColumn();
}

function class_manage(string $classId, ?array $user = null): bool
{
    $user ??= require_active_user();
    if ($user['role'] !== 'instructor') return false;
    $stmt = db()->prepare('SELECT 1 FROM classes WHERE id=? AND instructor_id=?');
    $stmt->execute([$classId, $user['id']]);
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
        'materials' => 'SELECT class_id FROM materials WHERE id=?',
        'announcements' => 'SELECT class_id FROM announcements WHERE id=?',
        'discussion_topics' => 'SELECT class_id FROM discussion_topics WHERE id=?',
        'discussion_posts' => 'SELECT t.class_id FROM discussion_posts p JOIN discussion_topics t ON t.id=p.topic_id WHERE p.id=?',
        'assignments' => 'SELECT class_id FROM assignments WHERE id=?',
        'submissions' => 'SELECT a.class_id FROM submissions s JOIN assignments a ON a.id=s.assignment_id WHERE s.id=?',
        'quizzes' => 'SELECT class_id FROM quizzes WHERE id=?',
        'quiz_questions' => 'SELECT q.class_id FROM quiz_questions qq JOIN quizzes q ON q.id=qq.quiz_id WHERE qq.id=?',
        'quiz_answer_keys' => 'SELECT q.class_id FROM quiz_answer_keys k JOIN quiz_questions qq ON qq.id=k.question_id JOIN quizzes q ON q.id=qq.quiz_id WHERE k.question_id=?',
        'quiz_attempts' => 'SELECT q.class_id FROM quiz_attempts a JOIN quizzes q ON q.id=a.quiz_id WHERE a.id=?',
    ];
    if (!isset($queries[$table])) return null;
    $stmt = db()->prepare($queries[$table]);
    $stmt->execute([$id]);
    $value = $stmt->fetchColumn();
    return is_string($value) ? $value : null;
}

function normalize_row(string $table, array $row): array
{
    foreach ($row as $key => $value) {
        if (in_array($key, ['options','answers','records'], true) && is_string($value)) {
            $row[$key] = json_decode($value, true) ?? ($key === 'options' ? [] : []);
        }
        if ($key === 'is_locked' || $key === 'case_sensitive') $row[$key] = (bool)$value;
        if (in_array($key, ['points','grade','score','max_score'], true) && $value !== null) $row[$key] = (float)$value;
        if (in_array($key, ['year_level','position','time_limit_minutes'], true) && $value !== null) $row[$key] = (int)$value;
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