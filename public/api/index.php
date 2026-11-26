<?php
declare(strict_types=1);

require __DIR__ . '/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && ($_GET['action'] ?? '') === 'storage.download') {
    download_file();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed.', 405);
$request = request_data();
$action = (string)($request['action'] ?? '');

try {
    match ($action) {
        'system.health' => system_health(),
        'system.onecampus-status' => system_onecampus_status(),
        'system.onecampus-connection' => system_onecampus_connection($request),
        'system.onecampus-disconnect' => system_onecampus_disconnect(),
        'system.first-admin-status' => system_first_admin_status(),
        'auth.session' => json_response(['session' => session_payload()]),
        'auth.login' => auth_login($request),
        'auth.logout' => auth_logout(),
        'auth.activity' => auth_activity(),
        'auth.forgot-password' => auth_forgot_password($request),
        'auth.update-user' => auth_update_user($request),
        'query' => query_action($request),
        'rpc' => rpc_action($request),
        'function' => function_action($request),
        'storage.upload' => storage_upload($request),
        'storage.remove' => storage_remove($request),
        'storage.signed-url' => storage_signed_url($request),
        default => fail('Unknown API action.', 404),
    };
} catch (Throwable $error) {
    error_log((string)$error);
    if (unique_violation($error)) fail('A record with the same identifying information already exists.', 409);
    fail('The server could not complete the request.', 500);
}

function system_health(): never
{
    $connection = onecampus_connection_config();
    db()->query('SELECT 1')->fetchColumn();
    json_response([
        'status' => 'ok',
        'database' => 'connected',
        'database_host' => $connection['host'],
        'database_port' => $connection['port'],
        'server_time' => (new DateTimeImmutable())->format(DATE_ATOM),
    ]);
}

function system_first_admin_status(): never
{
    $statement = db()->query("SELECT COUNT(*) FROM user_access_roles uar
        JOIN access_roles ar ON ar.role_id=uar.role_id
        JOIN users u ON u.user_id=uar.user_id
        WHERE uar.module_code IN ('lms','enrollment','scheduling')
          AND ar.role_name='Administrator' AND ar.is_active=1 AND u.status='Active'");
    json_response(['available' => (int)$statement->fetchColumn() === 0]);
}

function system_onecampus_connection(array $request): never
{
    global $config;
    if ($config['onecampus_setup_completed']) fail('OneCampus setup is already complete. Remove the private setup file on the server to reconfigure it.', 409);
    $host = trim((string)($request['host'] ?? ''));
    $port = trim((string)($request['port'] ?? '3306'));
    $name = trim((string)($request['database'] ?? 'adfc_onecampus'));
    $user = trim((string)($request['username'] ?? ''));
    $pass = (string)($request['password'] ?? '');
    if (!filter_var($host, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) || !is_private_lan_ipv4($host)) {
        fail('Enter 127.0.0.1 for a database on this PC or a private LAN IPv4 address such as 192.168.109.117.');
    }
    if (!ctype_digit($port) || (int)$port < 1 || (int)$port > 65535) fail('Enter a valid database port.');
    if (!preg_match('/^[A-Za-z0-9_]+$/', $name)) fail('Enter a valid database name.');
    if ($user === '') fail('Enter the database username.');
    $connection = ['host' => $host, 'port' => $port, 'name' => $name, 'user' => $user, 'pass' => $pass];
    try {
        verify_onecampus_database($connection);
        persist_onecampus_setup($connection);
        $_SESSION['onecampus_connection'] = $connection;
        json_response([
            'status' => 'connected',
            'host' => $host,
            'port' => $port,
            'database' => $name,
            'username' => $user,
        ]);
    } catch (PDOException $error) {
        error_log('OneCampus database connection failed for ' . $host . ': ' . $error->getMessage());
        fail('Unable to connect to the OneCampus database PC. Check its IP, MariaDB service, firewall, and read-only account.', 503);
    }
}

function system_onecampus_disconnect(): never
{
    global $config;
    $path = $config['private_root'] . DIRECTORY_SEPARATOR . 'api' . DIRECTORY_SEPARATOR . 'onecampus.setup.php';
    if (is_file($path) && !unlink($path)) {
        throw new RuntimeException('Unable to delete the private OneCampus setup file.');
    }
    unset($_SESSION['onecampus_connection']);
    json_response(['disconnected' => true]);
}

function persist_onecampus_setup(array $connection): void
{
    global $config;
    $directory = $config['private_root'] . DIRECTORY_SEPARATOR . 'api';
    if (!is_dir($directory) && !mkdir($directory, 0700, true) && !is_dir($directory)) {
        throw new RuntimeException('Unable to create the private setup directory.');
    }
    $path = $directory . DIRECTORY_SEPARATOR . 'onecampus.setup.php';
    $values = [
        'onecampus_db_host' => $connection['host'],
        'onecampus_db_port' => $connection['port'],
        'onecampus_db_name' => $connection['name'],
        'onecampus_db_user' => $connection['user'],
        'onecampus_db_pass' => $connection['pass'],
    ];
    $contents = "<?php\ndeclare(strict_types=1);\n\nreturn " . var_export($values, true) . ";\n";
    if (file_put_contents($path, $contents, LOCK_EX) === false) throw new RuntimeException('Unable to save the private OneCampus setup.');
}

function system_onecampus_status(): never
{
    global $config;
    $connection = onecampus_connection_config();
    $configured = $config['onecampus_setup_completed'] || isset($_SESSION['onecampus_connection']);
    if (!$configured) json_response(['configured' => false, 'connected' => false]);
    $details = [
        'configured' => true,
        'host' => $connection['host'],
        'port' => $connection['port'],
        'database' => $connection['name'],
        'username' => $connection['user'],
    ];
    if ($connection['host'] === '' || $connection['user'] === '') json_response([...$details, 'connected' => false]);
    try {
        verify_onecampus_database($connection);
        json_response([...$details, 'connected' => true]);
    } catch (Throwable $error) {
        error_log('OneCampus status check failed: ' . $error->getMessage());
        json_response([...$details, 'connected' => false]);
    }
}

function verify_onecampus_database(array $connection): void
{
    $source = onecampus_db($connection);
    $requiredTables = ['users', 'students', 'instructors', 'subjects', 'academic_periods', 'academic_classes', 'class_enrollments'];
    $placeholders = implode(',', array_fill(0, count($requiredTables), '?'));
    $statement = $source->prepare("SELECT table_name FROM information_schema.tables WHERE table_schema=? AND table_name IN ($placeholders)");
    $statement->execute([$connection['name'], ...$requiredTables]);
    $found = array_map('strtolower', $statement->fetchAll(PDO::FETCH_COLUMN));
    $missing = array_values(array_diff($requiredTables, $found));
    if ($missing !== []) fail('Connected, but the database is missing required OneCampus tables: ' . implode(', ', $missing) . '.', 422);
}

function is_private_lan_ipv4(string $host): bool
{
    $parts = array_map('intval', explode('.', $host));
    if (count($parts) !== 4) return false;
    return $host === '127.0.0.1'
        || $parts[0] === 10
        || ($parts[0] === 172 && $parts[1] >= 16 && $parts[1] <= 31)
        || ($parts[0] === 192 && $parts[1] === 168);
}

function auth_login(array $request): never
{
    $login = strtolower(trim((string)($request['email'] ?? '')));
    $password = (string)($request['password'] ?? '');
    if ($login === '' || $password === '') fail('Enter your username or email and password.');
    $settings = lms_security_settings();
    $roleSql = lms_role_sql();
    $stmt = db()->prepare("SELECT CAST(u.user_id AS CHAR) id,LOWER(u.email) email,u.password_hash,{$roleSql} requested_role
        FROM users u
        LEFT JOIN instructors i ON i.user_id=u.user_id
        LEFT JOIN students s ON s.student_id=u.student_id
        WHERE u.status='Active' AND (LOWER(u.username)=? OR LOWER(u.email)=?) LIMIT 1");
    $stmt->execute([$login, $login]);
    $user = $stmt->fetch();
    $loginKey = hash('sha256', $user ? 'user:' . $user['id'] : 'login:' . $login);
    $lock = login_lock_status($loginKey);
    if ($lock !== null) fail(login_lock_message($lock), 429);
    if (!$user || !password_verify($password, $user['password_hash'])) {
        $failure = record_failed_login($loginKey, $settings);
        if ($failure['locked_until'] !== null) fail(login_lock_message($failure['locked_until']), 429);
        $remaining = max(0, $settings['max_login_attempts'] - $failure['failed_attempts']);
        fail('Invalid login credentials. ' . $remaining . ' login attempt' . ($remaining === 1 ? '' : 's') . ' remaining.', 401);
    }
    if (!$user['requested_role']) fail('This account has not been granted access to the LMS.', 403);
    clear_failed_logins($loginKey);
    session_regenerate_id(true);
    $_SESSION['user_id'] = $user['id'];
    $_SESSION['last_activity_at'] = time();
    unset($_SESSION['session_expired_due_to_inactivity']);
    $payload = user_payload($user);
    json_response(['user' => $payload, 'session' => ['user' => $payload]]);
}

function login_lock_status(string $loginKey): ?string
{
    try {
        $statement = db()->prepare('SELECT locked_until FROM lms_login_attempts WHERE login_key=?');
        $statement->execute([$loginKey]);
        $lockedUntil = $statement->fetchColumn();
    } catch (PDOException $error) {
        if (($error->errorInfo[1] ?? null) === 1146) return null;
        throw $error;
    }
    if (!is_string($lockedUntil) || $lockedUntil === '') return null;
    if (strtotime($lockedUntil) > time()) return $lockedUntil;
    clear_failed_logins($loginKey);
    return null;
}

function record_failed_login(string $loginKey, array $settings): array
{
    $pdo = db();
    try {
        $pdo->beginTransaction();
        $pdo->prepare('INSERT IGNORE INTO lms_login_attempts (login_key,failed_attempts) VALUES (?,0)')->execute([$loginKey]);
        $select = $pdo->prepare('SELECT failed_attempts,locked_until FROM lms_login_attempts WHERE login_key=? FOR UPDATE');
        $select->execute([$loginKey]);
        $current = $select->fetch() ?: ['failed_attempts' => 0, 'locked_until' => null];
        if ($current['locked_until'] && strtotime((string)$current['locked_until']) > time()) {
            $pdo->commit();
            return ['failed_attempts' => (int)$current['failed_attempts'], 'locked_until' => (string)$current['locked_until']];
        }
        $attempts = (int)$current['failed_attempts'] + 1;
        $lockedUntil = $attempts >= $settings['max_login_attempts']
            ? (new DateTimeImmutable('now'))->modify('+' . $settings['lockout_minutes'] . ' minutes')->format('Y-m-d H:i:s')
            : null;
        $pdo->prepare('UPDATE lms_login_attempts SET failed_attempts=?,locked_until=?,last_failed_at=NOW() WHERE login_key=?')
            ->execute([$attempts, $lockedUntil, $loginKey]);
        $pdo->commit();
        return ['failed_attempts' => $attempts, 'locked_until' => $lockedUntil];
    } catch (PDOException $error) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        if (($error->errorInfo[1] ?? null) === 1146) return ['failed_attempts' => 1, 'locked_until' => null];
        throw $error;
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $error;
    }
}

function clear_failed_logins(string $loginKey): void
{
    try {
        db()->prepare('DELETE FROM lms_login_attempts WHERE login_key=?')->execute([$loginKey]);
    } catch (PDOException $error) {
        if (($error->errorInfo[1] ?? null) !== 1146) throw $error;
    }
}

function login_lock_message(string $lockedUntil): string
{
    $seconds = max(1, strtotime($lockedUntil) - time());
    $minutes = max(1, (int)ceil($seconds / 60));
    return 'Too many failed login attempts. Try again in ' . $minutes . ' minute' . ($minutes === 1 ? '' : 's') . '.';
}

function auth_logout(): never
{
    $userId = current_user_id();
    if ($userId !== null) {
        $studentStatement = db()->prepare('SELECT student_id FROM users WHERE user_id=?');
        $studentStatement->execute([$userId]);
        $studentId = $studentStatement->fetchColumn();
        if ($studentId) {
            db()->prepare("UPDATE quiz_live_participants p
                JOIN quiz_live_sessions s ON s.id=p.session_id
                SET p.status='disconnected',p.last_seen_at=NOW()
                WHERE p.student_id=? AND s.status IN ('lobby','active','paused') AND p.status<>'submitted'")
                ->execute([$studentId]);
        }
    }
    clear_authenticated_session();
    unset($_SESSION['session_expired_due_to_inactivity']);
    session_regenerate_id(true);
    json_response([]);
}

function auth_activity(): never
{
    require_active_user();
    $_SESSION['last_activity_at'] = time();
    json_response(['inactivity_timeout_minutes' => lms_security_settings()['inactivity_timeout_minutes']]);
}

function auth_forgot_password(array $request): never
{
    global $config;
    $email = strtolower(trim((string)($request['email'] ?? '')));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) fail('Enter a valid email address.');
    $roleSql = lms_role_sql();
    $stmt = db()->prepare("SELECT u.user_id
        FROM users u
        LEFT JOIN instructors i ON i.user_id=u.user_id
        LEFT JOIN students s ON s.student_id=u.student_id
        WHERE LOWER(u.email)=? AND u.status='Active' AND ({$roleSql}) IS NOT NULL
        LIMIT 1");
    $stmt->execute([$email]);
    $id = $stmt->fetchColumn();
    $resetUrl = null;
    if ($id) {
        $token = bin2hex(random_bytes(32));
        $update = db()->prepare('UPDATE users SET reset_token_hash=?, reset_expires_at=DATE_ADD(NOW(), INTERVAL 1 HOUR) WHERE user_id=?');
        $update->execute([hash('sha256', $token), $id]);
        $portal = 'student';
        $redirectTo = (string)($request['redirectTo'] ?? '');
        if ($redirectTo !== '') {
            parse_str((string)parse_url($redirectTo, PHP_URL_QUERY), $query);
            if (in_array($query['portal'] ?? null, ['student','instructor','admin'], true)) $portal = $query['portal'];
        }
        $resetUrl = $config['app_url'] . '/reset-password?portal=' . rawurlencode($portal) . '&token=' . rawurlencode($token);
        error_log('ADFC LMS password reset link for ' . $email . ': ' . $resetUrl);
    }
    json_response(['reset_url' => $resetUrl]);
}

function auth_update_user(array $request): never
{
    $password = (string)($request['password'] ?? '');
    validate_password($password);
    $token = trim((string)($request['token'] ?? ''));
    $isPasswordReset = $token !== '';
    $userId = null;
    if ($isPasswordReset) {
        $stmt = db()->prepare('SELECT user_id FROM users WHERE reset_token_hash=? AND reset_expires_at>NOW()');
        $stmt->execute([hash('sha256', $token)]);
        $userId = $stmt->fetchColumn() ?: null;
        if (!$userId) fail('This reset link is invalid or has expired.', 401);
    } else {
        $user = require_active_user();
        $currentPassword = (string)($request['currentPassword'] ?? '');
        if ($currentPassword === '') fail('Enter your current password.');
        $passwordStatement = db()->prepare('SELECT password_hash FROM users WHERE user_id=?');
        $passwordStatement->execute([$user['id']]);
        $currentPasswordHash = $passwordStatement->fetchColumn();
        if (!is_string($currentPasswordHash) || !password_verify($currentPassword, $currentPasswordHash)) {
            fail('The current password is incorrect.', 401);
        }
        $userId = $user['id'];
    }
    $updateSql = $isPasswordReset
        ? 'UPDATE users SET password_hash=?, reset_token_hash=NULL, reset_expires_at=NULL, session_version=session_version+1 WHERE user_id=?'
        : 'UPDATE users SET password_hash=?, session_version=session_version+1 WHERE user_id=?';
    $stmt = db()->prepare($updateSql);
    $stmt->execute([password_hash($password, PASSWORD_DEFAULT), $userId]);
    $roleSql = lms_role_sql();
    $userStmt = db()->prepare("SELECT CAST(u.user_id AS CHAR) id,LOWER(u.email) email,{$roleSql} requested_role
        FROM users u
        LEFT JOIN instructors i ON i.user_id=u.user_id
        LEFT JOIN students s ON s.student_id=u.student_id
        WHERE u.user_id=?");
    $userStmt->execute([$userId]);
    $user = $userStmt->fetch();
    if (!$user || !$user['requested_role']) fail('This account no longer has access to the LMS.', 403);
    json_response(['user' => user_payload($user)]);
}

function query_action(array $request): never
{
    $table = (string)($request['table'] ?? '');
    $operation = (string)($request['operation'] ?? 'select');
    $filters = is_array($request['filters'] ?? null) ? $request['filters'] : [];
    $orders = is_array($request['orders'] ?? null) ? $request['orders'] : [];
    $values = $request['values'] ?? null;
    $columns = (string)($request['columns'] ?? '*');
    $limit = isset($request['limit']) ? max(1, min(100, (int)$request['limit'])) : null;
    $singular = in_array($request['singular'] ?? null, ['single','maybeSingle'], true) ? $request['singular'] : null;

    $data = match ($operation) {
        'select' => query_select($table, $columns, $filters, $orders, $limit),
        'insert' => query_insert($table, is_array($values) ? $values : []),
        'update' => query_update($table, is_array($values) ? $values : [], $filters),
        'delete' => query_delete($table, $filters),
        default => fail('Unsupported query operation.'),
    };

    if ($singular) {
        $rows = is_array($data) && array_is_list($data) ? $data : [$data];
        if (count($rows) > 1 || ($singular === 'single' && count($rows) !== 1)) fail('Expected exactly one row.', 406);
        $data = $rows[0] ?? null;
    }
    json_response(['data' => $data]);
}

function query_select(string $table, string $columns, array $filters, array $orders, ?int $limit): array
{
    return match ($table) {
        'profiles' => select_profiles($filters, $orders),
        'subjects' => select_subjects($orders),
        'classes' => select_classes($filters, $orders),
        'enrollments' => select_enrollments($filters),
        'sync_logs' => select_sync_logs($orders, $limit),
        'audit_logs' => select_audit_logs($filters, $orders, $limit),
        'materials', 'announcements', 'assignments', 'quizzes' => select_class_children($table, $filters, $orders),
        'learning_modules' => select_learning_modules($filters, $orders),
        'learning_module_items' => select_learning_module_items($filters, $orders),
        'discussion_topics' => select_topics($filters, $orders),
        'discussion_posts' => select_posts($filters, $orders),
        'submissions' => select_submissions($filters, $orders),
        'quiz_questions' => select_questions($filters, $orders),
        'quiz_attempts' => select_attempts($filters),
        default => fail('This table is not available through the API.', 404),
    };
}

function select_learning_modules(array $filters, array $orders): array
{
    $user = require_active_user();
    $classId = (string)(filter_value($filters, 'class_id') ?? '');
    if ($classId === '' || !class_access($classId, $user)) fail('You are not allowed to access this learning path.', 403);
    $sql = 'SELECT * FROM learning_modules WHERE class_id=?';
    $params = [$classId];
    if (!class_report_access($classId, $user)) $sql .= " AND status<>'draft'";
    $sql .= order_clause($orders, ['position','created_at'], 'position ASC, created_at ASC');
    return fetch_all($sql, $params, 'learning_modules');
}

function select_learning_module_items(array $filters, array $orders): array
{
    $user = require_active_user();
    $moduleId = (string)(filter_value($filters, 'module_id') ?? '');
    if ($moduleId === '') fail('A module filter is required.');
    $statement = db()->prepare('SELECT class_id FROM learning_modules WHERE id=?');
    $statement->execute([$moduleId]);
    $classId = (string)($statement->fetchColumn() ?: '');
    if ($classId === '' || !class_access($classId, $user)) fail('You are not allowed to access these module activities.', 403);
    $uid = user_uid($user);
    $studentId = $user['role'] === 'student' ? (int)$user['student_id'] : 0;
    $sql = "SELECT i.*,
        CASE
            WHEN i.item_type IN ('material','discussion') THEN EXISTS(
                SELECT 1 FROM learning_item_completions c WHERE c.module_item_id=i.id AND c.user_id=?
            )
            WHEN i.item_type='assignment' THEN EXISTS(
                SELECT 1 FROM assignment_submissions s WHERE s.assignment_id=i.item_id AND s.student_id=? AND s.status IN ('submitted','graded')
            )
            WHEN i.item_type IN ('quiz','exam') THEN EXISTS(
                SELECT 1 FROM quiz_attempts a WHERE a.quiz_id=i.item_id AND a.student_id=? AND a.status='submitted'
            )
            ELSE 0
        END is_completed
        FROM learning_module_items i WHERE i.module_id=?";
    $sql .= order_clause($orders, ['position','created_at'], 'position ASC, created_at ASC');
    return fetch_all($sql, [$uid,$studentId,$studentId,$moduleId], 'learning_module_items');
}

function order_clause(array $orders, array $allowed, string $fallback = ''): string
{
    $parts = [];
    foreach ($orders as $order) {
        $column = (string)($order['column'] ?? '');
        if (!in_array($column, $allowed, true)) continue;
        $parts[] = '`' . $column . '` ' . (($order['ascending'] ?? true) ? 'ASC' : 'DESC');
    }
    if (!$parts && $fallback !== '') return ' ORDER BY ' . $fallback;
    return $parts ? ' ORDER BY ' . implode(', ', $parts) : '';
}

function qualified_order_clause(array $orders, array $allowed, string $alias, string $fallback): string
{
    $parts = [];
    foreach ($orders as $order) {
        $column = (string)($order['column'] ?? '');
        if (!in_array($column, $allowed, true)) continue;
        $parts[] = $alias . '.`' . $column . '` ' . (($order['ascending'] ?? true) ? 'ASC' : 'DESC');
    }
    return ' ORDER BY ' . ($parts ? implode(', ', $parts) : $fallback);
}

function select_profiles(array $filters, array $orders): array
{
    $user = require_active_user();
    $id = filter_value($filters, 'id');
    $role = filter_value($filters, 'role');
    if ($user['role'] !== 'admin' && $id !== $user['id']) fail('You are not allowed to view these profiles.', 403);
    $roleSql = lms_role_sql();
    $sql = "SELECT CAST(u.user_id AS CHAR) id,u.user_uid onecampus_user_id,'onecampus' source_system,
        u.updated_at synced_at,COALESCE(s.student_number,i.employee_number,u.username,u.user_uid) school_id,
        LOWER(u.email) email,u.full_name,NULL first_name,NULL middle_name,NULL last_name,NULL suffix,
        NULL class_code,NULL program,NULL year_level,NULL block,NULL academic_year,NULL semester,
        {$roleSql} role,
        CASE WHEN u.status='Active' THEN 'active' ELSE 'inactive' END status,up.avatar_path,u.created_at,u.updated_at
        FROM users u LEFT JOIN students s ON s.student_id=u.student_id LEFT JOIN instructors i ON i.user_id=u.user_id
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        WHERE ({$roleSql}) IS NOT NULL"; $params = [];
    if ($id !== null) { $sql .= ' AND u.user_id=?'; $params[] = $id; }
    if ($role !== null) {
        $sql .= " AND ({$roleSql})=?";
        $params[] = $role;
    }
    $sql .= qualified_order_clause($orders, ['full_name','created_at'], 'u', 'u.full_name ASC');
    return fetch_all($sql, $params, 'profiles');
}

function select_subjects(array $orders): array
{
    require_admin();
    return fetch_all("SELECT subject_uid id,subject_code code,subject_title title,description,created_at,created_at updated_at FROM subjects WHERE status='Active'" . order_clause($orders, ['code','created_at'], 'code ASC'), [], 'subjects');
}

function select_classes(array $filters, array $orders): array
{
    $user = require_active_user();
    $sql = "SELECT c.class_id internal_class_id,c.class_uid id,c.class_uid onecampus_class_id,'class_scheduling' source_system,c.updated_at synced_at,
        s.subject_uid subject_id,CAST(u.user_id AS CHAR) instructor_id,COALESCE(c.section,c.class_code) section,
        ap.academic_year school_year,CASE ap.semester WHEN '1st' THEN 'First Semester' WHEN '2nd' THEN 'Second Semester' ELSE 'Summer' END semester,
        CASE WHEN LOWER(c.status)='active' THEN 'active' ELSE 'archived' END status,c.created_at,c.updated_at,
        (SELECT COUNT(DISTINCT re.student_id)
         FROM blocks rb
         JOIN enrollments re ON re.block_id=rb.block_id AND re.period_id=c.period_id AND re.enrollment_status='Confirmed'
         JOIN enrollment_subjects res ON res.enrollment_id=re.enrollment_id AND res.subject_id=c.subject_id AND res.subject_status='Enrolled'
         WHERE rb.block_code=c.section) enrolled_student_count,
        JSON_OBJECT('code',s.subject_code,'title',s.subject_title) subject,
        JSON_OBJECT('full_name',COALESCE(u.full_name,'Not assigned'),'avatar_path',up.avatar_path) instructor
        FROM academic_classes c JOIN subjects s ON s.subject_id=c.subject_id JOIN academic_periods ap ON ap.period_id=c.period_id
        LEFT JOIN instructors i ON i.instructor_id=c.instructor_id LEFT JOIN users u ON u.user_id=i.user_id
        LEFT JOIN user_profiles up ON up.user_id=u.user_id WHERE 1=1";
    $params = [];
    if ($user['role'] === 'instructor') { $sql .= ' AND c.instructor_id=?'; $params[] = $user['instructor_id']; }
    elseif ($user['role'] === 'student') {
        $sql .= " AND EXISTS (
            SELECT 1 FROM blocks b
            JOIN enrollments e ON e.block_id=b.block_id AND e.period_id=c.period_id
            JOIN enrollment_subjects es ON es.enrollment_id=e.enrollment_id AND es.subject_id=c.subject_id
            WHERE b.block_code=c.section AND e.student_id=?
              AND e.enrollment_status='Confirmed' AND es.subject_status='Enrolled'
        )";
        $params[] = $user['student_id'];
    }
    foreach ($filters as $filter) {
        if (($filter['type'] ?? '') !== 'eq' || !in_array($filter['column'] ?? '', ['id','status'], true)) continue;
        if ($filter['column'] === 'id') { $sql .= ' AND c.class_uid=?'; $params[] = $filter['value']; }
        else { $sql .= " AND LOWER(c.status)=LOWER(?)"; $params[] = $filter['value']; }
    }
    $sql .= qualified_order_clause($orders, ['created_at','school_year','section'], 'c', 'c.created_at ASC');
    $rows = fetch_all($sql, $params, 'classes');
    $scheduleStmt = db()->prepare("SELECT cm.meeting_id,cm.class_type,cm.day_of_week,
        TIME_FORMAT(cm.start_time,'%H:%i') start_time,TIME_FORMAT(cm.end_time,'%H:%i') end_time,
        r.room_code,r.building
        FROM class_meetings cm JOIN rooms r ON r.room_id=cm.room_id
        WHERE cm.class_id=? AND cm.status='Published'
        ORDER BY FIELD(cm.day_of_week,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'),cm.start_time");
    foreach ($rows as &$row) {
        $row['subject'] = json_decode($row['subject'], true);
        $row['instructor'] = json_decode($row['instructor'], true);
        $scheduleStmt->execute([$row['internal_class_id']]);
        $row['schedule'] = $scheduleStmt->fetchAll();
        unset($row['internal_class_id']);
    }
    return $rows;
}

function select_enrollments(array $filters): array
{
    $user = require_active_user();
    $classId = (string)(filter_value($filters, 'class_id') ?? '');
    if ($classId === '') fail('A class filter is required.');
    if (!class_report_access($classId, $user) && $user['role'] !== 'student') fail('Access denied.', 403);
    if ($user['role'] === 'student' && !class_access($classId, $user)) fail('Access denied.', 403);
    $sql = "SELECT CONCAT('ENROLLMENT-',e.enrollment_id,'-',es.enrollment_subject_id) id,
        CONCAT('ENROLLMENT-',e.enrollment_id,'-',es.enrollment_subject_id) onecampus_enrollment_id,
        'enrollment_management' source_system,e.updated_at synced_at,c.class_uid class_id,
        COALESCE(CAST(u.user_id AS CHAR),s.student_uid,CONCAT('STUDENT-',s.student_id)) student_id,
        'enrolled' status,e.created_at,e.updated_at,
        JSON_OBJECT(
            'id',COALESCE(CAST(u.user_id AS CHAR),s.student_uid,CONCAT('STUDENT-',s.student_id)),
            'full_name',CONCAT_WS(' ',s.first_name,NULLIF(s.middle_name,''),s.last_name),
            'school_id',s.student_number,
            'avatar_path',up.avatar_path
        ) student
        FROM academic_classes c
        JOIN blocks b ON b.block_code=c.section
        JOIN enrollments e ON e.period_id=c.period_id AND e.block_id=b.block_id AND e.enrollment_status='Confirmed'
        JOIN enrollment_subjects es ON es.enrollment_id=e.enrollment_id AND es.subject_id=c.subject_id AND es.subject_status='Enrolled'
        JOIN students s ON s.student_id=e.student_id
        LEFT JOIN users u ON u.student_id=s.student_id
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        WHERE c.class_uid=?";
    $params = [$classId];
    $status = filter_value($filters, 'status'); if ($status !== null && $status !== 'enrolled') return [];
    $sql .= ' ORDER BY s.last_name,s.first_name,s.middle_name,s.student_number';
    $rows = fetch_all($sql, $params, 'enrollments');
    foreach ($rows as &$row) $row['student'] = json_decode($row['student'], true);
    return $rows;
}

function select_registrations(array $orders): array
{
    require_admin();
    $rows = fetch_all('SELECT * FROM registration_applications' . order_clause($orders, ['created_at'], 'created_at DESC'), [], 'registration_applications');
    $stmt = db()->prepare('SELECT class_id FROM registration_application_classes WHERE application_id=?');
    foreach ($rows as &$row) { $stmt->execute([$row['id']]); $row['selected_class_ids'] = $stmt->fetchAll(PDO::FETCH_COLUMN); }
    return $rows;
}

function select_sync_logs(array $orders, ?int $limit): array
{
    require_admin();
    $sql = "SELECT id,initiated_by,status,records,message,started_at,completed_at,'direct_database' source FROM learning_sync_logs" . order_clause($orders, ['started_at'], 'started_at DESC') . ' LIMIT ' . ($limit ?? 50);
    return fetch_all($sql, [], 'sync_logs');
}

function select_audit_logs(array $filters, array $orders, ?int $limit): array
{
    require_admin();
    $module = trim((string)(filter_value($filters, 'module_code') ?? ''));
    $sql = "SELECT a.log_id id,a.module_code,u.full_name actor_name,a.actor_role,a.action,a.record_type,
        COALESCE(JSON_UNQUOTE(JSON_EXTRACT(a.details_json,'$.record_id')),CAST(a.record_id AS CHAR)) record_label,
        a.description,a.ip_address,a.created_at
        FROM activity_logs a LEFT JOIN users u ON u.user_id=a.admin_user_id";
    $params = [];
    if ($module !== '') { $sql .= ' WHERE a.module_code=?'; $params[] = $module; }
    $sql .= qualified_order_clause($orders, ['created_at'], 'a', 'a.created_at DESC');
    $sql .= ' LIMIT ' . ($limit ?? 250);
    return fetch_all($sql, $params, 'audit_logs');
}

function select_class_children(string $table, array $filters, array $orders): array
{
    $user = require_active_user();
    $classId = (string)(filter_value($filters, 'class_id') ?? '');
    if ($classId === '' || !class_access($classId, $user)) fail('You are not allowed to access these class records.', 403);
    if ($table === 'announcements') return select_announcements($classId, $orders);
    $physicalTable = content_table($table);
    $sql = "SELECT * FROM `$physicalTable` WHERE class_id=?"; $params = [$classId];
    foreach ($filters as $filter) {
        if (($filter['type'] ?? '') !== 'neq' || ($filter['column'] ?? '') !== 'status') continue;
        $sql .= ' AND status<>?'; $params[] = $filter['value'];
    }
    if ($table === 'quizzes') {
        $kind = filter_value($filters, 'assessment_kind');
        if (in_array($kind, ['quiz','exam'], true)) { $sql .= ' AND assessment_kind=?'; $params[] = $kind; }
    }
    if (in_array($table, ['assignments','quizzes'], true) && !class_report_access($classId, $user)) $sql .= " AND status<>'draft'";
    $allowedOrders = ['created_at', 'due_at'];
    $sql .= order_clause($orders, $allowedOrders, $table === 'assignments' ? 'due_at ASC' : 'created_at DESC');
    return fetch_all($sql, $params, $table);
}

function select_announcements(string $classId, array $orders): array
{
    $sql = "SELECT CAST(a.announcement_id AS CHAR) id,c.class_uid class_id,a.title,a.body,
        CAST(a.created_by AS CHAR) created_by,a.created_at,COALESCE(a.published_at,a.created_at) updated_at
        FROM announcements a JOIN academic_classes c ON c.class_id=a.class_id
        WHERE a.module_code='lms' AND c.class_uid=?";
    $sql .= qualified_order_clause($orders, ['created_at'], 'a', 'a.created_at DESC');
    return fetch_all($sql, [$classId], 'announcements');
}

function select_topics(array $filters, array $orders): array
{
    $classId = (string)(filter_value($filters, 'class_id') ?? ''); $user = require_class_access($classId); $uid = user_uid($user);
    $sql = 'SELECT t.*, JSON_OBJECT("full_name",u.full_name,"avatar_path",up.avatar_path) author,
        (m.joined_at IS NOT NULL AND m.left_at IS NULL) is_joined,
        CASE WHEN m.muted_until>NOW() THEN m.muted_until ELSE NULL END muted_until
        FROM learning_discussion_topics t
        JOIN users u ON u.user_uid=t.created_by
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        LEFT JOIN learning_discussion_memberships m ON m.topic_id=t.id AND m.user_id=?
        WHERE t.class_id=?
          AND (m.hidden_at IS NULL OR COALESCE((SELECT MAX(p.created_at) FROM learning_discussion_posts p WHERE p.topic_id=t.id),t.created_at)>m.hidden_at)'
        . ' ORDER BY t.is_pinned DESC,t.pinned_at DESC,t.created_at DESC';
    $rows = fetch_all($sql, [$uid,$classId], 'discussion_topics'); foreach ($rows as &$row) $row['author'] = json_decode($row['author'], true); return $rows;
}

function select_posts(array $filters, array $orders): array
{
    $topicId = (string)(filter_value($filters, 'topic_id') ?? '');
    $stmt = db()->prepare('SELECT class_id FROM learning_discussion_topics WHERE id=?'); $stmt->execute([$topicId]);
    $classId = $stmt->fetchColumn(); if (!$classId) return []; $user = require_class_access($classId);
    if ($user['role'] !== 'admin' && !discussion_is_joined($topicId, user_uid($user))) return [];
    $sql = 'SELECT d.*, JSON_OBJECT("full_name",u.full_name,"avatar_path",up.avatar_path) author,
        rp.author_id reply_to_author_id,CASE WHEN rp.is_deleted=1 THEN NULL ELSE rp.body END reply_to_body,
        CASE WHEN rp.is_deleted=1 THEN NULL ELSE rp.attachment_name END reply_to_attachment_name,
        COALESCE(rp.is_deleted,0) reply_to_is_deleted,ru.full_name reply_to_author_name
        FROM learning_discussion_posts d JOIN users u ON u.user_uid=d.author_id
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        LEFT JOIN learning_discussion_posts rp ON rp.id=d.reply_to_id
        LEFT JOIN users ru ON ru.user_uid=rp.author_id
        WHERE d.topic_id=?' . qualified_order_clause($orders, ['created_at'], 'd', 'd.created_at ASC');
    $rows = fetch_all($sql, [$topicId], 'discussion_posts');
    $reactions = fetch_all('SELECT r.post_id,r.emoji,r.user_id,u.full_name,up.avatar_path,(r.user_id=?) reacted_by_me
        FROM learning_discussion_post_reactions r
        JOIN learning_discussion_posts p ON p.id=r.post_id
        JOIN users u ON u.user_uid=r.user_id
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        WHERE p.topic_id=? ORDER BY r.created_at', [user_uid($user),$topicId], 'discussion_post_reactions');
    $byPost = [];
    foreach ($reactions as $reaction) {
        $postKey = (string)$reaction['post_id'];
        $emojiKey = (string)$reaction['emoji'];
        if (!isset($byPost[$postKey][$emojiKey])) $byPost[$postKey][$emojiKey] = ['emoji' => $emojiKey, 'count' => 0, 'reacted_by_me' => false, 'users' => []];
        $byPost[$postKey][$emojiKey]['count']++;
        $byPost[$postKey][$emojiKey]['reacted_by_me'] = $byPost[$postKey][$emojiKey]['reacted_by_me'] || (bool)$reaction['reacted_by_me'];
        $byPost[$postKey][$emojiKey]['users'][] = ['id' => $reaction['user_id'], 'full_name' => $reaction['full_name'], 'avatar_path' => $reaction['avatar_path']];
    }
    foreach ($rows as &$row) {
        $row['author'] = json_decode($row['author'], true);
        $row['body'] = !empty($row['is_deleted']) ? '' : $row['body'];
        $row['reactions'] = !empty($row['is_deleted']) ? [] : array_values($byPost[$row['id']] ?? []);
    }
    return $rows;
}

function id_list_filter(array $filters, string $column): array
{
    $value = filter_value($filters, $column, 'in');
    return is_array($value) ? array_values(array_filter($value, 'is_string')) : [];
}

function select_submissions(array $filters, array $orders): array
{
    $user = require_active_user(); $ids = id_list_filter($filters, 'assignment_id'); if (!$ids) return [];
    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $classRows = fetch_all("SELECT DISTINCT class_id FROM learning_assignments WHERE id IN ($placeholders)", $ids);
    foreach ($classRows as $row) if (!class_access($row['class_id'], $user)) fail('Access denied.', 403);
    $sql = "SELECT s.*,CAST(u.user_id AS CHAR) student_id,JSON_OBJECT('full_name',u.full_name,'school_id',st.student_number,'avatar_path',up.avatar_path) student
        FROM assignment_submissions s JOIN students st ON st.student_id=s.student_id JOIN users u ON u.student_id=st.student_id
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        WHERE s.assignment_id IN ($placeholders)";
    $params = $ids;
    $canViewReports = count($classRows) > 0; foreach ($classRows as $row) $canViewReports = $canViewReports && class_report_access($row['class_id'], $user);
    if (!$canViewReports) { $sql .= ' AND s.student_id=?'; $params[] = $user['student_id']; }
    $sql .= qualified_order_clause($orders, ['submitted_at'], 's', 's.submitted_at DESC');
    $rows = fetch_all($sql, $params, 'submissions'); foreach ($rows as &$row) $row['student'] = json_decode($row['student'], true); return $rows;
}

function select_questions(array $filters, array $orders): array
{
    $user = require_active_user(); $ids = id_list_filter($filters, 'quiz_id'); if (!$ids) return [];
    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $classes = fetch_all("SELECT DISTINCT class_id FROM quizzes WHERE id IN ($placeholders)", $ids);
    foreach ($classes as $row) if (!class_access($row['class_id'], $user)) fail('Access denied.', 403);
    $canManage = count($classes) > 0;
    foreach ($classes as $row) $canManage = $canManage && class_manage($row['class_id'], $user);
    $sql = $canManage
        ? "SELECT qq.*,k.correct_answer FROM quiz_questions qq LEFT JOIN quiz_answer_keys k ON k.question_id=qq.id WHERE qq.quiz_id IN ($placeholders)"
        : "SELECT qq.* FROM quiz_questions qq WHERE qq.quiz_id IN ($placeholders)";
    $params = $ids;
    if ($user['role'] === 'student') {
        $sql .= ' AND EXISTS (SELECT 1 FROM quiz_attempts qa WHERE qa.quiz_id=qq.quiz_id AND qa.student_id=?)';
        $params[] = $user['student_id'];
    }
    return fetch_all($sql . qualified_order_clause($orders, ['position'], 'qq', 'qq.position ASC'), $params, 'quiz_questions');
}

function select_attempts(array $filters): array
{
    $user = require_active_user(); $ids = id_list_filter($filters, 'quiz_id'); if (!$ids) return [];
    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $classes = fetch_all("SELECT DISTINCT class_id FROM quizzes WHERE id IN ($placeholders)", $ids);
    foreach ($classes as $row) if (!class_access($row['class_id'], $user)) fail('Access denied.', 403);
    $canViewReports = count($classes) > 0; foreach ($classes as $row) $canViewReports = $canViewReports && class_report_access($row['class_id'], $user);
    if ($canViewReports) finalize_closed_quiz_attempts($ids);
    $sql = "SELECT a.*,CAST(u.user_id AS CHAR) student_id FROM quiz_attempts a
        JOIN students st ON st.student_id=a.student_id JOIN users u ON u.student_id=st.student_id
        WHERE a.quiz_id IN ($placeholders)"; $params = $ids;
    if (!$canViewReports) { $sql .= ' AND a.student_id=?'; $params[] = $user['student_id']; }
    return fetch_all($sql, $params, 'quiz_attempts');
}

function finalize_closed_quiz_attempts(array $quizIds): void
{
    if (!$quizIds) return;
    $placeholders = implode(',', array_fill(0, count($quizIds), '?'));
    $rows = fetch_all("SELECT a.id,a.quiz_id,a.answers,a.started_at,q.status quiz_status,q.closes_at,q.time_limit_minutes
        FROM quiz_attempts a JOIN quizzes q ON q.id=a.quiz_id
        WHERE a.status='in_progress' AND a.quiz_id IN ($placeholders)", $quizIds);
    $now = time();
    $update = db()->prepare("UPDATE quiz_attempts SET score=?,max_score=?,status='submitted',submitted_at=FROM_UNIXTIME(?) WHERE id=? AND status='in_progress'");
    foreach ($rows as $attempt) {
        $deadline = null;
        if ((int)$attempt['time_limit_minutes'] > 0) $deadline = strtotime($attempt['started_at']) + ((int)$attempt['time_limit_minutes'] * 60);
        if ($attempt['closes_at']) {
            $closing = strtotime($attempt['closes_at']);
            $deadline = $deadline === null ? $closing : min($deadline, $closing);
        }
        $manuallyClosed = $attempt['quiz_status'] === 'closed';
        $expired = $deadline !== null && $now > $deadline + 30;
        if (!$manuallyClosed && !$expired) continue;
        $answers = json_decode((string)$attempt['answers'], true);
        [$score, $max] = quiz_score((string)$attempt['quiz_id'], is_array($answers) ? $answers : []);
        $submittedAt = $expired && $deadline !== null ? $deadline : $now;
        $update->execute([$score, $max, $submittedAt, $attempt['id']]);
    }
}

function query_insert(string $table, array $values): array
{
    $user = require_active_user();
    $allowed = [
        'materials' => ['class_id','title','description','file_path','external_url'],
        'announcements' => ['class_id','title','body'],
        'discussion_topics' => ['class_id','title','body','is_locked'],
        'discussion_posts' => ['topic_id','body','attachment_path','attachment_name','attachment_mime','attachment_size','attachment_kind','reply_to_id'],
        'assignments' => ['class_id','title','instructions','due_at','points','status'],
        'quizzes' => ['class_id','title','description','file_submission_points','assessment_kind','exam_type','opens_at','closes_at','time_limit_minutes','status'],
        'quiz_questions' => ['quiz_id','prompt','question_type','options','points','position'],
        'quiz_answer_keys' => ['question_id','correct_answer','case_sensitive'],
        'learning_modules' => ['class_id','title','description','position','opens_at','due_at','status','prerequisite_module_id'],
        'learning_module_items' => ['module_id','item_type','item_id','title_override','position','is_required','estimated_minutes'],
    ];
    if (!isset($allowed[$table])) fail('Insert is not allowed for this table.', 403);

    if (in_array($table, ['discussion_topics','discussion_posts'], true)) {
        $classId = $table === 'discussion_topics' ? (string)($values['class_id'] ?? '') : class_id_for_topic((string)($values['topic_id'] ?? ''));
        if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
        if ($classId === '' || !class_access($classId, $user)) fail('Access denied.', 403);
    } else {
        $classId = insert_class_id($table, $values);
        if ($classId === '' || !class_manage($classId, $user)) fail('Only class managers can create this record.', 403);
    }

    if ($table === 'announcements') return insert_announcement($values, $user);

    if ($table === 'discussion_posts' && !discussion_is_joined((string)($values['topic_id'] ?? ''), user_uid($user))) fail('Join this discussion before posting.', 403);

    if ($table === 'discussion_posts') $values = validate_discussion_post_values($values, $user, $classId);
    if ($table === 'learning_module_items') validate_learning_module_item($values, $classId);
    if ($table === 'learning_modules') validate_learning_module_values($values, $classId);

    if ($table === 'discussion_posts' && !empty($values['reply_to_id'])) {
        $replyStatement = db()->prepare('SELECT topic_id,is_deleted FROM learning_discussion_posts WHERE id=?');
        $replyStatement->execute([(string)$values['reply_to_id']]); $replyTarget = $replyStatement->fetch();
        if (!$replyTarget || $replyTarget['topic_id'] !== ($values['topic_id'] ?? null)) fail('The message you are replying to is unavailable.');
        if (!empty($replyTarget['is_deleted'])) fail('You cannot reply to a deleted message.');
    }

    $row = ['id' => uuid()];
    foreach ($allowed[$table] as $column) if (array_key_exists($column, $values)) $row[$column] = normalize_write_value($column, $values[$column]);
    if (in_array($table, ['materials','discussion_topics','assignments','quizzes','learning_modules','learning_module_items'], true)) $row['created_by'] = user_uid($user);
    if ($table === 'discussion_posts') $row['author_id'] = user_uid($user);
    if (!isset($row['id'])) $row['id'] = uuid();
    if ($table === 'quiz_answer_keys') { unset($row['id']); }
    validate_insert_row($table, $row);
    if ($table === 'quizzes') validate_assessment_fields($row);

    $physicalTable = content_table($table);
    $columns = array_keys($row);
    $sql = "INSERT INTO `$physicalTable` (`" . implode('`,`', $columns) . '`) VALUES (' . implode(',', array_fill(0, count($columns), '?')) . ')';
    db()->prepare($sql)->execute(array_values($row));
    if ($table === 'discussion_topics') {
        db()->prepare('INSERT INTO learning_discussion_memberships (topic_id,user_id,joined_at,left_at,hidden_at) VALUES (?,?,NOW(),NULL,NULL) ON DUPLICATE KEY UPDATE joined_at=NOW(),left_at=NULL,hidden_at=NULL')->execute([$row['id'],user_uid($user)]);
    }
    $keyColumn = $table === 'quiz_answer_keys' ? 'question_id' : 'id';
    $stmt = db()->prepare("SELECT * FROM `$physicalTable` WHERE `$keyColumn`=?");
    $stmt->execute([$row[$keyColumn]]);
    $created = normalize_row($table, $stmt->fetch() ?: $row);
    lms_audit('create', $table, (string)($created[$keyColumn] ?? ''), 'Created ' . audit_record_label($table, $created), null, $created, $user);
    return $created;
}

function insert_announcement(array $values, array $user): array
{
    $classId = (string)($values['class_id'] ?? '');
    $stmt = db()->prepare('SELECT class_id FROM academic_classes WHERE class_uid=?');
    $stmt->execute([$classId]);
    $numericClassId = $stmt->fetchColumn();
    if (!$numericClassId) fail('Class not found.', 404);
    $title = trim((string)($values['title'] ?? ''));
    $body = trim((string)($values['body'] ?? ''));
    if ($title === '' || $body === '') fail('Complete all required fields.');
    db()->prepare("INSERT INTO announcements (module_code,class_id,title,body,created_by,is_published,published_at)
        VALUES ('lms',?,?,?,?,1,NOW())")->execute([$numericClassId, $title, $body, $user['id']]);
    $id = (string)db()->lastInsertId();
    $row = select_announcements($classId, []);
    foreach ($row as $item) if ($item['id'] === $id) return $item;
    return [];
}

function class_id_for_topic(string $topicId): string
{
    $stmt = db()->prepare('SELECT class_id FROM learning_discussion_topics WHERE id=?'); $stmt->execute([$topicId]);
    return (string)($stmt->fetchColumn() ?: '');
}

function discussion_is_joined(string $topicId, string $userId): bool
{
    $statement = db()->prepare('SELECT 1 FROM learning_discussion_memberships WHERE topic_id=? AND user_id=? AND joined_at IS NOT NULL AND left_at IS NULL');
    $statement->execute([$topicId,$userId]);
    return (bool)$statement->fetchColumn();
}

function insert_class_id(string $table, array $values): string
{
    if (isset($values['class_id'])) return (string)$values['class_id'];
    if ($table === 'learning_module_items') {
        $stmt = db()->prepare('SELECT class_id FROM learning_modules WHERE id=?');
        $stmt->execute([(string)($values['module_id'] ?? '')]);
        return (string)($stmt->fetchColumn() ?: '');
    }
    if ($table === 'quiz_questions') {
        $stmt = db()->prepare('SELECT class_id FROM quizzes WHERE id=?'); $stmt->execute([(string)($values['quiz_id'] ?? '')]); return (string)($stmt->fetchColumn() ?: '');
    }
    if ($table === 'quiz_answer_keys') return (string)(class_id_for_record('quiz_answer_keys', (string)($values['question_id'] ?? '')) ?? class_id_for_question((string)($values['question_id'] ?? '')));
    return '';
}

function class_id_for_question(string $questionId): string
{
    $stmt = db()->prepare('SELECT q.class_id FROM quiz_questions qq JOIN quizzes q ON q.id=qq.quiz_id WHERE qq.id=?'); $stmt->execute([$questionId]);
    return (string)($stmt->fetchColumn() ?: '');
}

function normalize_write_value(string $column, mixed $value): mixed
{
    if (in_array($column, ['due_at','opens_at','closes_at'], true)) return sql_datetime(is_string($value) ? $value : null);
    if (in_array($column, ['options','answers','records'], true)) return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if (in_array($column, ['is_locked','is_pinned','case_sensitive','is_required'], true)) return $value ? 1 : 0;
    return $value;
}

function validate_insert_row(string $table, array $row): void
{
    $required = [
        'materials' => ['class_id','title'], 'announcements' => ['class_id','title','body'],
        'discussion_topics' => ['class_id','title','body'], 'discussion_posts' => ['topic_id'],
        'assignments' => ['class_id','title','instructions','points','status'], 'quizzes' => ['class_id','title','status'],
        'quiz_questions' => ['quiz_id','prompt','question_type','options','points','position'],
        'quiz_answer_keys' => ['question_id','correct_answer'],
        'learning_modules' => ['class_id','title','position','status'],
        'learning_module_items' => ['module_id','item_type','item_id','position'],
    ];
    foreach ($required[$table] ?? [] as $column) if (!isset($row[$column]) || $row[$column] === '') fail('Complete all required fields.');
    if ($table === 'materials' && empty($row['file_path']) && empty($row['external_url'])) fail('A file or external URL is required.');
    if ($table === 'discussion_posts' && trim((string)($row['body'] ?? '')) === '' && empty($row['attachment_path'])) fail('Write a message or attach a file.');
}

function validate_learning_module_item(array $values, string $classId): void
{
    $type = (string)($values['item_type'] ?? '');
    $itemId = (string)($values['item_id'] ?? '');
    if (!in_array($type, ['material','assignment','quiz','exam','discussion'], true) || $itemId === '') fail('Choose a valid learning activity.');
    $queries = [
        'material' => 'SELECT class_id,NULL kind FROM learning_materials WHERE id=?',
        'assignment' => 'SELECT class_id,NULL kind FROM learning_assignments WHERE id=?',
        'quiz' => 'SELECT class_id,assessment_kind kind FROM quizzes WHERE id=?',
        'exam' => 'SELECT class_id,assessment_kind kind FROM quizzes WHERE id=?',
        'discussion' => 'SELECT class_id,NULL kind FROM learning_discussion_topics WHERE id=?',
    ];
    $statement = db()->prepare($queries[$type]);
    $statement->execute([$itemId]);
    $target = $statement->fetch();
    if (!$target || (string)$target['class_id'] !== $classId) fail('The selected activity does not belong to this class.');
    if (in_array($type, ['quiz','exam'], true) && (string)$target['kind'] !== $type) fail('The selected assessment type does not match this learning activity.');
}

function validate_learning_module_values(array $values, string $classId, string $moduleId = ''): void
{
    $position = (int)($values['position'] ?? 1);
    if (trim((string)($values['title'] ?? '')) === '') fail('Enter a module title.');
    if ($position < 1) fail('Module sequence must be at least 1.');
    if (isset($values['status']) && !in_array($values['status'], ['draft','published','closed'], true)) fail('Invalid module status.');
    $opensAt = normalize_write_value('opens_at', $values['opens_at'] ?? null);
    $dueAt = normalize_write_value('due_at', $values['due_at'] ?? null);
    if ($opensAt !== null && $dueAt !== null && strtotime($dueAt) <= strtotime($opensAt)) fail('The module due date must be after its opening date.');
    $prerequisiteId = trim((string)($values['prerequisite_module_id'] ?? ''));
    if ($prerequisiteId === '') return;
    if ($moduleId !== '' && $prerequisiteId === $moduleId) fail('A module cannot require itself.');
    $statement = db()->prepare('SELECT class_id FROM learning_modules WHERE id=?');
    $statement->execute([$prerequisiteId]);
    if ((string)($statement->fetchColumn() ?: '') !== $classId) fail('The prerequisite module must belong to the same class.');
}

function validate_discussion_post_values(array $values, array $user, string $classId): array
{
    global $config;
    $body = trim((string)($values['body'] ?? ''));
    $rawPath = trim((string)($values['attachment_path'] ?? ''));
    $path = $rawPath === '' ? '' : clean_storage_path($rawPath);
    if ($path === '') {
        $values['body'] = $body;
        foreach (['attachment_path','attachment_name','attachment_mime','attachment_size','attachment_kind'] as $column) $values[$column] = null;
        return $values;
    }

    $topicId = (string)($values['topic_id'] ?? '');
    $uid = user_uid($user);
    $prefix = $classId . '/' . $topicId . '/' . $uid . '/';
    if (!str_starts_with($path, $prefix)) fail('The discussion attachment path is invalid.');
    $file = $config['storage_path'] . DIRECTORY_SEPARATOR . 'discussions' . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $path);
    if (!is_file($file)) fail('Upload the discussion attachment before sending the message.');
    $size = filesize($file);
    if ($size === false || $size > 10485760) fail('Discussion attachments must be 10 MB or smaller.');
    $mime = class_exists('finfo') ? (new finfo(FILEINFO_MIME_TYPE))->file($file) : null;
    $mime = is_string($mime) && $mime !== '' ? $mime : 'application/octet-stream';
    $name = trim((string)($values['attachment_name'] ?? basename($path)));
    if ($name === '') $name = basename($path);
    if (mb_strlen($name) > 255) $name = mb_substr($name, 0, 255);
    $extension = strtolower(pathinfo($name, PATHINFO_EXTENSION));
    $kind = $extension === 'weba' || str_starts_with($mime, 'audio/') ? 'audio' : (str_starts_with($mime, 'image/') ? 'image' : (str_starts_with($mime, 'video/') ? 'video' : 'file'));
    $values['body'] = $body;
    $values['attachment_path'] = $path;
    $values['attachment_name'] = $name;
    $values['attachment_mime'] = $mime;
    $values['attachment_size'] = $size;
    $values['attachment_kind'] = $kind;
    return $values;
}

function validate_assessment_fields(array $values): void
{
    $kind = (string)($values['assessment_kind'] ?? 'quiz');
    if (!in_array($kind, ['quiz','exam'], true)) fail('Invalid assessment type.');
    $examType = trim((string)($values['exam_type'] ?? ''));
    if ($kind === 'exam' && $examType === '') fail('Select or enter an exam type.');
    if (mb_strlen($examType) > 100) fail('Exam type must not exceed 100 characters.');
    $opensAt = isset($values['opens_at']) && is_string($values['opens_at']) ? $values['opens_at'] : null;
    if ($opensAt !== null && $opensAt !== '' && strtotime($opensAt) < time()) fail('Opening date and time must be the current time or a future time. Past dates are not allowed.');
}

function assessment_label(array $row): string
{
    return ($row['assessment_kind'] ?? 'quiz') === 'exam' ? 'exam' : 'quiz';
}

function audit_record_label(string $table, array $row): string
{
    $type = $table === 'quizzes' ? assessment_label($row) : rtrim(str_replace('_', ' ', $table), 's');
    $name = trim((string)($row['title'] ?? $row['prompt'] ?? ''));
    return $type . ($name !== '' ? ': ' . $name : '');
}

function query_update(string $table, array $values, array $filters): array
{
    $id = (string)(filter_value($filters, 'id') ?? ''); if ($id === '') fail('An ID filter is required.');
    $allowed = [
        'discussion_topics' => ['is_pinned','pinned_by','pinned_at'],
        'discussion_posts' => ['is_pinned','pinned_by','pinned_at'],
        'quizzes' => ['title','description','file_submission_points','assessment_kind','exam_type','opens_at','closes_at','time_limit_minutes','status'],
        'learning_modules' => ['title','description','position','opens_at','due_at','status','prerequisite_module_id'],
        'learning_module_items' => ['title_override','position','is_required','estimated_minutes'],
    ];
    if (!isset($allowed[$table])) fail('Update is not allowed for this table.', 403);
    $classId = class_id_for_record($table, $id); if (!$classId) fail('Record not found.', 404);
    if ($table === 'discussion_topics') {
        $user = require_active_user();
        if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
        if (!class_manage($classId, $user) && !discussion_is_joined($id, user_uid($user))) {
            fail('Join this discussion before pinning the conversation.', 403);
        }
        if (!array_key_exists('is_pinned', $values)) fail('A pin state is required.');
        $isPinned = (bool)$values['is_pinned'];
        $values = [
            'is_pinned' => $isPinned,
            'pinned_by' => $isPinned ? user_uid($user) : null,
            'pinned_at' => $isPinned ? date('Y-m-d H:i:s') : null,
        ];
    } elseif ($table === 'discussion_posts') {
        $user = require_active_user();
        if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
        if (!array_key_exists('is_pinned', $values)) fail('A pin state is required.');
        $postStatement = db()->prepare('SELECT topic_id,is_deleted FROM learning_discussion_posts WHERE id=?'); $postStatement->execute([$id]);
        $post = $postStatement->fetch();
        if (!$post) fail('Message not found.', 404);
        if (!class_manage($classId, $user) && !discussion_is_joined((string)$post['topic_id'], user_uid($user))) {
            fail('Join this discussion before pinning messages.', 403);
        }
        if ((bool)$post['is_deleted']) fail('Deleted messages cannot be pinned.');
        $isPinned = (bool)$values['is_pinned'];
        $values = [
            'is_pinned' => $isPinned,
            'pinned_by' => $isPinned ? user_uid($user) : null,
            'pinned_at' => $isPinned ? date('Y-m-d H:i:s') : null,
        ];
    } else require_class_manager($classId);
    if ($table === 'quizzes') {
        if (array_key_exists('title', $values) && trim((string)$values['title']) === '') fail('Enter an assessment title.');
        if (array_key_exists('status', $values) && !in_array($values['status'], ['draft','published','closed'], true)) fail('Invalid quiz status.');
        if (array_key_exists('time_limit_minutes', $values) && $values['time_limit_minutes'] !== null && (!is_numeric($values['time_limit_minutes']) || (int)$values['time_limit_minutes'] < 1)) fail('Time limit must be at least one minute.');
        if (array_key_exists('file_submission_points', $values) && (!is_numeric($values['file_submission_points']) || (float)$values['file_submission_points'] <= 0)) fail('File submission points must be greater than zero.');
        $existingStatement = db()->prepare('SELECT * FROM quizzes WHERE id=?'); $existingStatement->execute([$id]); $existing = $existingStatement->fetch() ?: [];
        $opensAt = normalize_write_value('opens_at', $values['opens_at'] ?? $existing['opens_at'] ?? null);
        $closesAt = normalize_write_value('closes_at', $values['closes_at'] ?? $existing['closes_at'] ?? null);
        if ($opensAt !== null && $closesAt !== null && strtotime($closesAt) <= strtotime($opensAt)) fail('Closing date must be after the opening date.');
        $openingChanged = array_key_exists('opens_at', $values) && $opensAt !== ($existing['opens_at'] ?? null);
        if ($openingChanged && $opensAt !== null && strtotime($opensAt) < time()) fail('Opening date and time must be the current time or a future time. Past dates are not allowed.');
        $merged = array_merge($existing, $values);
        if (!$openingChanged) unset($merged['opens_at']);
        validate_assessment_fields($merged);
    }
    if ($table === 'learning_modules') {
        $existingStatement = db()->prepare('SELECT * FROM learning_modules WHERE id=?');
        $existingStatement->execute([$id]);
        $existing = $existingStatement->fetch() ?: [];
        validate_learning_module_values(array_merge($existing, $values), $classId, $id);
    }
    $sets = []; $params = [];
    foreach ($allowed[$table] as $column) if (array_key_exists($column, $values)) { $sets[] = "`$column`=?"; $params[] = normalize_write_value($column, $values[$column]); }
    if (!$sets) fail('No supported values were supplied.');
    $physicalTable = content_table($table);
    $beforeStatement = db()->prepare("SELECT * FROM `$physicalTable` WHERE id=?"); $beforeStatement->execute([$id]); $before = $beforeStatement->fetch() ?: [];
    $params[] = $id; db()->prepare("UPDATE `$physicalTable` SET " . implode(',', $sets) . ' WHERE id=?')->execute($params);
    if ($table === 'quizzes' && array_key_exists('file_submission_points', $values)) {
        $attempts=fetch_all('SELECT a.*,q.file_submission_points FROM quiz_attempts a JOIN quizzes q ON q.id=a.quiz_id WHERE a.quiz_id=? AND a.submission_file_path IS NOT NULL AND a.submission_file_path<>\'\' AND a.status=\'submitted\'',[$id]);
        $updateAttempt=db()->prepare('UPDATE quiz_attempts SET submission_file_score=?,score=?,max_score=? WHERE id=?');
        foreach($attempts as $attempt){$maximum=(float)$attempt['file_submission_points'];$attempt['submission_file_score']=min((float)($attempt['submission_file_score']??0),$maximum);[$score,$max]=quiz_attempt_score_totals($attempt);$updateAttempt->execute([$attempt['submission_file_score'],$score,$max,$attempt['id']]);}
    }
    $stmt = db()->prepare("SELECT * FROM `$physicalTable` WHERE id=?"); $stmt->execute([$id]);
    $updated = normalize_row($table, $stmt->fetch() ?: []);
    lms_audit('update', $table, $id, 'Updated ' . audit_record_label($table, $updated), normalize_row($table, $before), $updated);
    return $updated;
}

function query_delete(string $table, array $filters): array
{
    $id = (string)(filter_value($filters, 'id') ?? ''); if ($id === '') fail('An ID filter is required.');
    $allowed = ['materials','announcements','discussion_topics','discussion_posts','assignments','quizzes','quiz_questions','learning_modules','learning_module_items'];
    if (!in_array($table, $allowed, true)) fail('Delete is not allowed for this table.', 403);
    $classId = class_id_for_record($table, $id); if (!$classId) return [];
    $user = require_active_user();
    if ($table === 'discussion_topics') {
        if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
        if (!class_access($classId, $user)) fail('Access denied.', 403);
    } elseif ($table === 'discussion_posts') {
        if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
        if (!class_access($classId, $user)) fail('Access denied.', 403);
        $stmt = db()->prepare('SELECT author_id,is_deleted,attachment_path FROM learning_discussion_posts WHERE id=?'); $stmt->execute([$id]); $post = $stmt->fetch();
        if (!$post || $post['author_id'] !== user_uid($user)) fail('You can only unsend your own messages.', 403);
        if (!empty($post['is_deleted'])) return [];
    } elseif (!class_manage($classId, $user)) fail('Access denied.', 403);
    $labelStatement = db()->prepare($table === 'announcements' ? "SELECT title FROM announcements WHERE announcement_id=? AND module_code='lms'" : "SELECT * FROM `" . content_table($table) . "` WHERE id=?");
    $labelStatement->execute([$id]); $deleted = $labelStatement->fetch() ?: [];
    if ($table === 'discussion_topics') {
        db()->prepare('INSERT INTO learning_discussion_memberships (topic_id,user_id,hidden_at) VALUES (?,?,NOW()) ON DUPLICATE KEY UPDATE hidden_at=NOW()')->execute([$id,user_uid($user)]);
        lms_audit('hide', $table, $id, 'Deleted discussion conversation for current user', normalize_row($table, $deleted), ['hidden' => true], $user);
        return [];
    }
    if ($table === 'discussion_posts') {
        db()->prepare("UPDATE learning_discussion_posts SET body='',attachment_path=NULL,attachment_name=NULL,attachment_mime=NULL,attachment_size=NULL,attachment_kind=NULL,is_deleted=1,deleted_at=NOW(),deleted_by=?,is_pinned=0,pinned_by=NULL,pinned_at=NULL WHERE id=?")->execute([user_uid($user),$id]);
        db()->prepare('DELETE FROM learning_discussion_post_reactions WHERE post_id=?')->execute([$id]);
        if (!empty($post['attachment_path'])) remove_private_storage_file('discussions', (string)$post['attachment_path']);
        lms_audit('delete', $table, $id, 'Unsent discussion post', normalize_row($table, $deleted), ['is_deleted' => true], $user);
        return [];
    }
    $storedFiles = [];
    if ($table === 'quizzes') {
        if (!empty($deleted['attachment_path'])) $storedFiles[] = ['materials', (string)$deleted['attachment_path']];
        $fileStatement = db()->prepare("SELECT submission_file_path FROM quiz_attempts WHERE quiz_id=? AND submission_file_path IS NOT NULL AND submission_file_path<>''");
        $fileStatement->execute([$id]);
        foreach ($fileStatement->fetchAll(PDO::FETCH_COLUMN) as $path) $storedFiles[] = ['submissions', (string)$path];
    }
    if ($table === 'announcements') db()->prepare("DELETE FROM announcements WHERE announcement_id=? AND module_code='lms'")->execute([$id]);
    else {
        $physicalTable = content_table($table);
        db()->prepare("DELETE FROM `$physicalTable` WHERE id=?")->execute([$id]);
    }
    foreach ($storedFiles as [$bucket, $path]) remove_private_storage_file($bucket, $path);
    lms_audit('delete', $table, $id, 'Deleted ' . audit_record_label($table, $deleted), normalize_row($table, $deleted), null, $user);
    return [];
}

function rpc_action(array $request): never
{
    $name = (string)($request['name'] ?? ''); $args = is_array($request['args'] ?? null) ? $request['args'] : [];
    $data = match ($name) {
        'admin_update_user' => rpc_admin_update_user($args),
        'get_security_settings' => rpc_get_security_settings(),
        'admin_update_security_settings' => rpc_admin_update_security_settings($args),
        'get_class_notification_counts' => rpc_get_class_notification_counts($args),
        'toggle_discussion_reaction' => rpc_toggle_discussion_reaction($args),
        'mark_discussion_read' => rpc_mark_discussion_read($args),
        'join_discussion' => rpc_join_discussion($args),
        'leave_discussion' => rpc_leave_discussion($args),
        'set_discussion_mute' => rpc_set_discussion_mute($args),
        'discussion_live_call_status' => rpc_discussion_live_call_status($args),
        'discussion_live_session_history' => rpc_discussion_live_session_history($args),
        'discussion_live_state' => rpc_discussion_live_state($args),
        'start_discussion_live_session' => rpc_start_discussion_live_session($args),
        'join_discussion_live_session' => rpc_join_discussion_live_session($args),
        'update_discussion_live_presence' => rpc_update_discussion_live_presence($args),
        'leave_discussion_live_session' => rpc_leave_discussion_live_session($args),
        'end_discussion_live_session' => rpc_end_discussion_live_session($args),
        'send_discussion_live_signal' => rpc_send_discussion_live_signal($args),
        'post_discussion_live_event' => rpc_post_discussion_live_event($args),
        'submit_assignment' => rpc_submit_assignment($args),
        'grade_submission' => rpc_grade_submission($args),
        'update_quiz_question' => rpc_update_quiz_question($args),
        'grade_quiz_essay' => rpc_grade_quiz_essay($args),
        'grade_quiz_file' => rpc_grade_quiz_file($args),
        'start_quiz' => rpc_start_quiz($args),
        'submit_quiz' => rpc_submit_quiz($args),
        'set_quiz_attachment' => rpc_set_quiz_attachment($args),
        'remove_quiz_submission_file' => rpc_remove_quiz_submission_file($args),
        'list_live_quiz_sessions' => rpc_list_live_quiz_sessions($args),
        'create_live_quiz_session' => rpc_create_live_quiz_session($args),
        'live_quiz_state' => rpc_live_quiz_state($args),
        'join_live_quiz_session' => rpc_join_live_quiz_session($args),
        'control_live_quiz_session' => rpc_control_live_quiz_session($args),
        'submit_live_quiz_answer' => rpc_submit_live_quiz_answer($args),
        'set_learning_item_complete' => rpc_set_learning_item_complete($args),
        default => fail('Unknown server operation.', 404),
    };
    json_response(['data' => $data]);
}

function rpc_set_learning_item_complete(array $args): array
{
    $user = require_active_user();
    if ($user['role'] !== 'student') fail('Only students can update learning activity completion.', 403);
    $itemId = (string)($args['target_module_item_id'] ?? '');
    $completed = (bool)($args['completed'] ?? true);
    $statement = db()->prepare('SELECT i.item_type,m.class_id FROM learning_module_items i JOIN learning_modules m ON m.id=i.module_id WHERE i.id=?');
    $statement->execute([$itemId]);
    $item = $statement->fetch();
    if (!$item || !class_access((string)$item['class_id'], $user)) fail('Learning activity not found.', 404);
    if (!in_array($item['item_type'], ['material','discussion'], true)) fail('This activity is completed through its submission or assessment attempt.');
    $uid = user_uid($user);
    if ($completed) {
        db()->prepare('INSERT INTO learning_item_completions (module_item_id,user_id,completed_at) VALUES (?,?,NOW()) ON DUPLICATE KEY UPDATE completed_at=NOW()')->execute([$itemId,$uid]);
    } else {
        db()->prepare('DELETE FROM learning_item_completions WHERE module_item_id=? AND user_id=?')->execute([$itemId,$uid]);
    }
    return ['module_item_id' => $itemId, 'completed' => $completed];
}

function rpc_toggle_discussion_reaction(array $args): array
{
    $user = require_active_user();
    if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
    $postId = (string)($args['target_post_id'] ?? ''); $emoji = trim((string)($args['emoji'] ?? ''));
    if (!in_array($emoji, ['👍','❤️','😂','😮','😢','😡'], true)) fail('Select a supported reaction.');
    $statement = db()->prepare('SELECT p.is_deleted,p.topic_id,t.class_id FROM learning_discussion_posts p JOIN learning_discussion_topics t ON t.id=p.topic_id WHERE p.id=?');
    $statement->execute([$postId]); $post = $statement->fetch();
    if (!$post) fail('Message not found.', 404);
    if (!class_access((string)$post['class_id'], $user)) fail('Access denied.', 403);
    if (!discussion_is_joined((string)$post['topic_id'], user_uid($user))) fail('Join this discussion before reacting.', 403);
    if (!empty($post['is_deleted'])) fail('Deleted messages cannot receive reactions.');
    $uid = user_uid($user); $existing = db()->prepare('SELECT emoji FROM learning_discussion_post_reactions WHERE post_id=? AND user_id=?');
    $existing->execute([$postId,$uid]); $current = $existing->fetchColumn();
    if ($current === $emoji) db()->prepare('DELETE FROM learning_discussion_post_reactions WHERE post_id=? AND user_id=?')->execute([$postId,$uid]);
    else db()->prepare('INSERT INTO learning_discussion_post_reactions (id,post_id,user_id,emoji) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE emoji=VALUES(emoji),updated_at=NOW()')->execute([uuid(),$postId,$uid,$emoji]);
    return ['post_id' => $postId, 'emoji' => $current === $emoji ? null : $emoji];
}

function rpc_mark_discussion_read(array $args): array
{
    $user = require_active_user();
    $topicId = (string)($args['target_topic_id'] ?? '');
    $postId = trim((string)($args['target_post_id'] ?? ''));
    $classId = class_id_for_topic($topicId);
    if ($classId === '' || !class_access($classId, $user)) fail('Discussion not found or access denied.', 404);
    $uid = user_uid($user);
    if ($user['role'] !== 'admin' && !discussion_is_joined($topicId, $uid)) fail('Join this discussion before reading messages.', 403);

    if ($postId !== '' && $user['role'] !== 'admin') {
        $targetStatement = db()->prepare('SELECT created_at FROM learning_discussion_posts WHERE id=? AND topic_id=?');
        $targetStatement->execute([$postId,$topicId]);
        $targetCreatedAt = $targetStatement->fetchColumn();
        if (!$targetCreatedAt) fail('Message not found.', 404);

        $currentStatement = db()->prepare('SELECT p.created_at FROM learning_discussion_memberships m LEFT JOIN learning_discussion_posts p ON p.id=m.last_read_post_id WHERE m.topic_id=? AND m.user_id=?');
        $currentStatement->execute([$topicId,$uid]);
        $currentCreatedAt = $currentStatement->fetchColumn();
        if (!$currentCreatedAt || strtotime((string)$targetCreatedAt) >= strtotime((string)$currentCreatedAt)) {
            db()->prepare('UPDATE learning_discussion_memberships SET last_read_post_id=?,last_read_at=NOW() WHERE topic_id=? AND user_id=? AND joined_at IS NOT NULL AND left_at IS NULL')->execute([$postId,$topicId,$uid]);
        }
    }

    return fetch_all('SELECT m.last_read_post_id post_id,m.user_id,u.full_name,up.avatar_path,m.last_read_at
        FROM learning_discussion_memberships m
        JOIN users u ON u.user_uid=m.user_id AND u.status=\'Active\'
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        JOIN learning_discussion_posts p ON p.id=m.last_read_post_id AND p.topic_id=m.topic_id
        WHERE m.topic_id=? AND m.joined_at IS NOT NULL AND m.left_at IS NULL
          AND m.last_read_post_id IS NOT NULL AND m.last_read_at IS NOT NULL
          AND m.user_id<>? AND m.user_id<>p.author_id
        ORDER BY m.last_read_at,m.user_id', [$topicId,$uid]);
}

function rpc_join_discussion(array $args): array
{
    $user = require_active_user();
    if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
    $topicId = (string)($args['target_topic_id'] ?? '');
    $classId = class_id_for_topic($topicId);
    if ($classId === '' || !class_access($classId, $user)) fail('Discussion not found or access denied.', 404);
    db()->prepare('INSERT INTO learning_discussion_memberships (topic_id,user_id,joined_at,left_at,hidden_at,muted_until) VALUES (?,?,NOW(),NULL,NULL,NULL) ON DUPLICATE KEY UPDATE joined_at=NOW(),left_at=NULL,hidden_at=NULL,muted_until=NULL')->execute([$topicId,user_uid($user)]);
    return ['topic_id' => $topicId, 'is_joined' => true];
}

function rpc_leave_discussion(array $args): array
{
    $user = require_active_user();
    if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
    $topicId = (string)($args['target_topic_id'] ?? '');
    $classId = class_id_for_topic($topicId);
    if ($classId === '' || !class_access($classId, $user)) fail('Discussion not found or access denied.', 404);
    db()->prepare('INSERT INTO learning_discussion_memberships (topic_id,user_id,left_at,hidden_at,muted_until) VALUES (?,?,NOW(),NULL,NULL) ON DUPLICATE KEY UPDATE joined_at=NULL,left_at=NOW(),hidden_at=NULL,muted_until=NULL')->execute([$topicId,user_uid($user)]);
    return ['topic_id' => $topicId, 'is_joined' => false];
}

function rpc_set_discussion_mute(array $args): array
{
    $user = require_active_user();
    if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
    $topicId = (string)($args['target_topic_id'] ?? '');
    $duration = (string)($args['duration'] ?? '');
    $classId = class_id_for_topic($topicId);
    if ($classId === '' || !class_access($classId, $user)) fail('Discussion not found or access denied.', 404);
    $uid = user_uid($user);
    if (!discussion_is_joined($topicId, $uid)) fail('Join the discussion before changing its notifications.', 403);
    $mutedUntil = match ($duration) {
        'one_hour' => (new DateTimeImmutable('+1 hour'))->format('Y-m-d H:i:s'),
        'eight_hours' => (new DateTimeImmutable('+8 hours'))->format('Y-m-d H:i:s'),
        'one_day' => (new DateTimeImmutable('+1 day'))->format('Y-m-d H:i:s'),
        'until_unmuted' => '9999-12-31 23:59:59',
        'unmute' => null,
        default => fail('Select a valid notification mute duration.'),
    };
    db()->prepare('UPDATE learning_discussion_memberships SET muted_until=? WHERE topic_id=? AND user_id=?')->execute([$mutedUntil,$topicId,$uid]);
    return ['topic_id' => $topicId, 'muted_until' => $mutedUntil];
}

function discussion_live_topic(string $topicId): array
{
    $statement = db()->prepare('SELECT id,class_id,title FROM learning_discussion_topics WHERE id=?');
    $statement->execute([$topicId]);
    $topic = $statement->fetch();
    if (!$topic) fail('Discussion not found.', 404);
    return $topic;
}

function discussion_live_session(string $sessionId): array
{
    $statement = db()->prepare('SELECT s.*,t.title topic_title FROM discussion_live_sessions s JOIN learning_discussion_topics t ON t.id=s.topic_id WHERE s.id=?');
    $statement->execute([$sessionId]);
    $session = $statement->fetch();
    if (!$session) fail('Live discussion call not found.', 404);
    return $session;
}

function discussion_live_access(array $session): array
{
    $user = require_class_access((string)$session['class_id']);
    if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
    $uid = user_uid($user);
    if (!class_manage((string)$session['class_id'], $user) && !discussion_is_joined((string)$session['topic_id'], $uid)) {
        fail('Join the discussion before entering its call.', 403);
    }
    return $user;
}

function discussion_live_state_payload(array $session, array $user, int $afterSignalId = 0): array
{
    $uid = user_uid($user);
    $canManage = class_manage((string)$session['class_id'], $user);
    db()->prepare('DELETE FROM discussion_live_signals WHERE created_at<DATE_SUB(NOW(),INTERVAL 1 HOUR)')->execute();
    $participants = fetch_all("SELECT p.user_id,p.mic_muted,p.camera_enabled,p.screen_sharing,p.is_attending,p.joined_at,p.last_seen_at,
        u.full_name,up.avatar_path,(p.user_id=s.created_by) is_host
        FROM discussion_live_participants p
        JOIN discussion_live_sessions s ON s.id=p.session_id
        JOIN users u ON u.user_uid=p.user_id
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        WHERE p.session_id=? AND p.left_at IS NULL AND p.last_seen_at>=DATE_SUB(NOW(),INTERVAL 10 SECOND)
        ORDER BY is_host DESC,p.joined_at", [$session['id']], 'discussion_live_participants');
    $joinedStatement = db()->prepare('SELECT 1 FROM discussion_live_participants WHERE session_id=? AND user_id=? AND left_at IS NULL');
    $joinedStatement->execute([$session['id'],$uid]);
    $joined = (bool)$joinedStatement->fetchColumn();
    $attendanceRoster = [];
    if ($canManage) {
        $attendanceRoster = fetch_all("SELECT DISTINCT COALESCE(u.user_uid,s.student_uid,CONCAT('STUDENT-',s.student_id)) user_id,
            COALESCE(u.full_name,CONCAT_WS(' ',s.first_name,NULLIF(s.middle_name,''),s.last_name)) full_name,
            s.student_number school_id,up.avatar_path,
            CASE WHEN p.left_at IS NULL AND p.is_attending=1 AND p.last_seen_at>=DATE_SUB(NOW(),INTERVAL 5 SECOND) THEN COALESCE(p.screen_sharing,0) ELSE 0 END screen_sharing,
            p.joined_at,p.last_seen_at,
            CASE
                WHEN p.user_id IS NULL THEN 'not_joined'
                WHEN p.left_at IS NULL AND p.is_attending=1 AND p.last_seen_at>=DATE_SUB(NOW(),INTERVAL 5 SECOND) THEN 'active'
                ELSE 'inactive'
            END attendance_status
            FROM academic_classes c
            JOIN blocks b ON b.block_code=c.section
            JOIN enrollments e ON e.period_id=c.period_id AND e.block_id=b.block_id AND e.enrollment_status='Confirmed'
            JOIN enrollment_subjects es ON es.enrollment_id=e.enrollment_id AND es.subject_id=c.subject_id AND es.subject_status='Enrolled'
            JOIN students s ON s.student_id=e.student_id
            LEFT JOIN users u ON u.student_id=s.student_id
            LEFT JOIN user_profiles up ON up.user_id=u.user_id
            LEFT JOIN discussion_live_participants p ON p.session_id=? AND p.user_id=u.user_uid
            WHERE c.class_uid=?
            ORDER BY s.last_name,s.first_name,s.middle_name,s.student_number", [$session['id'],$session['class_id']]);
    }
    $events = fetch_all("SELECT e.id,e.user_id,e.event_type,e.content,e.attachment_path,e.attachment_name,e.attachment_mime,e.attachment_size,e.attachment_kind,e.created_at,u.full_name,up.avatar_path
        FROM discussion_live_events e JOIN users u ON u.user_uid=e.user_id LEFT JOIN user_profiles up ON up.user_id=u.user_id
        WHERE e.session_id=? ORDER BY e.id DESC LIMIT 100", [$session['id']], 'discussion_live_events');
    $events = array_reverse($events);
    $signals = fetch_all('SELECT id,sender_id,signal_type,payload_json,created_at FROM discussion_live_signals WHERE session_id=? AND recipient_id=? AND id>? ORDER BY id LIMIT 200', [$session['id'],$uid,$afterSignalId], 'discussion_live_signals');
    foreach ($signals as &$signal) $signal['payload'] = $signal['payload_json'] ? json_decode((string)$signal['payload_json'], true) : null;
    return [
        'session' => normalize_row('discussion_live_sessions', $session),
        'participants' => $participants,
        'attendance_roster' => $attendanceRoster,
        'events' => $events,
        'signals' => $signals,
        'is_host' => $uid === $session['created_by'],
        'joined' => $joined,
        'can_manage' => $canManage,
        'attendance_settings' => array_intersect_key(lms_security_settings(), array_flip([
            'live_attendance_minimized_enabled',
            'live_attendance_tab_hidden_enabled',
            'live_attendance_window_blur_enabled',
            'live_attendance_inactivity_enabled',
            'live_attendance_inactivity_seconds',
        ])),
    ];
}

function prevent_multiple_discussion_calls(string $userId, ?string $allowedSessionId = null): void
{
    $sql = "SELECT s.id,t.title
        FROM discussion_live_participants p
        JOIN discussion_live_sessions s ON s.id=p.session_id AND s.status='active'
        JOIN learning_discussion_topics t ON t.id=s.topic_id
        WHERE p.user_id=? AND p.left_at IS NULL AND p.last_seen_at>=DATE_SUB(NOW(),INTERVAL 10 SECOND)";
    $params = [$userId];
    if ($allowedSessionId !== null) {
        $sql .= ' AND s.id<>?';
        $params[] = $allowedSessionId;
    }
    $sql .= ' ORDER BY p.last_seen_at DESC LIMIT 1';
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $existing = $statement->fetch();
    if ($existing) fail('Leave or end your current call in “' . $existing['title'] . '” before joining or starting another call.', 409);
}

function rpc_discussion_live_call_status(array $args): ?array
{
    $topic = discussion_live_topic((string)($args['target_topic_id'] ?? ''));
    $user = require_class_access((string)$topic['class_id']);
    if ($user['role'] === 'admin') return null;
    $uid = user_uid($user);
    if (!class_manage((string)$topic['class_id'], $user) && !discussion_is_joined((string)$topic['id'], $uid)) return null;
    $statement = db()->prepare("SELECT s.id,s.topic_id,s.created_by,s.started_at,u.full_name host_name,up.avatar_path host_avatar_path,
        (SELECT COUNT(*) FROM discussion_live_participants p
         WHERE p.session_id=s.id AND p.left_at IS NULL AND p.is_attending=1 AND p.last_seen_at>=DATE_SUB(NOW(),INTERVAL 5 SECOND)) participant_count
        FROM discussion_live_sessions s
        JOIN users u ON u.user_uid=s.created_by
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        WHERE s.topic_id=? AND s.status='active'
        ORDER BY s.started_at DESC LIMIT 1");
    $statement->execute([$topic['id']]);
    $session = $statement->fetch();
    if (!$session) return null;
    $session['participant_count'] = (int)$session['participant_count'];
    $session['is_host'] = $session['created_by'] === $uid;
    return normalize_row('discussion_live_sessions', $session);
}

function rpc_discussion_live_session_history(array $args): array
{
    $classId = (string)($args['target_class_id'] ?? '');
    $user = require_class_access($classId);
    $canManage = class_manage($classId, $user);
    if (!$canManage && $user['role'] !== 'student') fail('Live-session history is available only to the assigned instructor and enrolled students.', 403);
    if ($canManage) {
        $sessions = fetch_all("SELECT s.id,s.topic_id,t.title topic_title,s.started_at,s.ended_at,u.full_name host_name,up.avatar_path host_avatar_path,
            COALESCE(SUM(h.attendance_status='active'),0) active_count,
            COALESCE(SUM(h.attendance_status='inactive'),0) inactive_count,
            COALESCE(SUM(h.attendance_status='not_joined'),0) not_joined_count
            FROM discussion_live_sessions s
            JOIN learning_discussion_topics t ON t.id=s.topic_id
            JOIN users u ON u.user_uid=s.created_by
            LEFT JOIN user_profiles up ON up.user_id=u.user_id
            JOIN discussion_live_attendance_history h ON h.session_id=s.id
            WHERE s.class_id=? AND s.status='ended' AND s.ended_at IS NOT NULL
            GROUP BY s.id,s.topic_id,t.title,s.started_at,s.ended_at,u.full_name,up.avatar_path
            ORDER BY s.ended_at DESC LIMIT 100", [$classId]);
    } else {
        $studentId = (int)($user['student_id'] ?? 0);
        if ($studentId <= 0) fail('Your account is not linked to a student record.', 409);
        $sessions = fetch_all("SELECT s.id,s.topic_id,t.title topic_title,s.started_at,s.ended_at,u.full_name host_name,up.avatar_path host_avatar_path,
            0 active_count,0 inactive_count,0 not_joined_count
            FROM discussion_live_sessions s
            JOIN learning_discussion_topics t ON t.id=s.topic_id
            JOIN users u ON u.user_uid=s.created_by
            LEFT JOIN user_profiles up ON up.user_id=u.user_id
            JOIN discussion_live_attendance_history h ON h.session_id=s.id AND h.student_id=?
            WHERE s.class_id=? AND s.status='ended' AND s.ended_at IS NOT NULL
            ORDER BY s.ended_at DESC LIMIT 100", [$studentId,$classId]);
    }
    if (!$sessions) return [];
    $sessionIds = array_column($sessions, 'id');
    $placeholders = implode(',', array_fill(0, count($sessionIds), '?'));
    $attendanceSql = "SELECT h.session_id,h.student_id,h.user_id,h.full_name,h.school_id,h.attendance_status,h.joined_at,h.last_seen_at,h.recorded_at,up.avatar_path
        FROM discussion_live_attendance_history h
        LEFT JOIN users u ON u.user_uid=h.user_id
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        WHERE h.session_id IN ($placeholders)";
    $attendanceParams = $sessionIds;
    if (!$canManage) {
        $attendanceSql .= ' AND h.student_id=?';
        $attendanceParams[] = (int)$user['student_id'];
    }
    $attendanceSql .= ' ORDER BY h.full_name,h.school_id';
    $attendance = fetch_all($attendanceSql, $attendanceParams);
    $attendanceBySession = [];
    foreach ($attendance as $row) {
        $row['student_id'] = (int)$row['student_id'];
        $attendanceBySession[$row['session_id']][] = $row;
    }
    $events = fetch_all("SELECT e.session_id,e.id,e.user_id,e.event_type,e.content,e.attachment_path,e.attachment_name,e.attachment_mime,e.attachment_size,e.attachment_kind,e.created_at,u.full_name,up.avatar_path
        FROM discussion_live_events e
        JOIN users u ON u.user_uid=e.user_id
        LEFT JOIN user_profiles up ON up.user_id=u.user_id
        WHERE e.session_id IN ($placeholders)
        ORDER BY e.session_id,e.id", $sessionIds, 'discussion_live_events');
    $eventsBySession = [];
    foreach ($events as $row) $eventsBySession[$row['session_id']][] = $row;
    foreach ($sessions as &$session) {
        $session['active_count'] = (int)$session['active_count'];
        $session['inactive_count'] = (int)$session['inactive_count'];
        $session['not_joined_count'] = (int)$session['not_joined_count'];
        $session['can_manage'] = $canManage;
        $session['attendance'] = $attendanceBySession[$session['id']] ?? [];
        $session['events'] = $eventsBySession[$session['id']] ?? [];
    }
    return $sessions;
}

function rpc_discussion_live_state(array $args): array
{
    $topic = discussion_live_topic((string)($args['target_topic_id'] ?? ''));
    $user = require_class_access((string)$topic['class_id']);
    if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
    $statement = db()->prepare("SELECT s.*,? topic_title FROM discussion_live_sessions s WHERE s.topic_id=? AND s.status='active' ORDER BY s.started_at DESC LIMIT 1");
    $statement->execute([$topic['title'],$topic['id']]);
    $session = $statement->fetch();
    if (!$session) return ['session'=>null,'participants'=>[],'attendance_roster'=>[],'events'=>[],'signals'=>[],'is_host'=>false,'joined'=>false,'can_manage'=>false,'attendance_settings'=>array_intersect_key(lms_security_settings(),array_flip(['live_attendance_minimized_enabled','live_attendance_tab_hidden_enabled','live_attendance_window_blur_enabled','live_attendance_inactivity_enabled','live_attendance_inactivity_seconds']))];
    discussion_live_access($session);
    return discussion_live_state_payload($session, $user, max(0, (int)($args['after_signal_id'] ?? 0)));
}

function rpc_start_discussion_live_session(array $args): array
{
    $topic = discussion_live_topic((string)($args['target_topic_id'] ?? ''));
    $user = require_class_access((string)$topic['class_id']);
    if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
    if (!discussion_is_joined((string)$topic['id'], user_uid($user)) && !class_manage((string)$topic['class_id'], $user)) fail('Join the discussion before starting a call.', 403);
    prevent_multiple_discussion_calls(user_uid($user));
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $existing = $pdo->prepare("SELECT id FROM discussion_live_sessions WHERE topic_id=? AND status='active' FOR UPDATE");
        $existing->execute([$topic['id']]);
        $sessionId = $existing->fetchColumn();
        if (!$sessionId) {
            $sessionId = uuid();
            $pdo->prepare("INSERT INTO discussion_live_sessions (id,topic_id,class_id,status,created_by) VALUES (?,?,?,'active',?)")
                ->execute([$sessionId,$topic['id'],$topic['class_id'],user_uid($user)]);
        }
        $pdo->commit();
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $error;
    }
    $session = discussion_live_session((string)$sessionId);
    db()->prepare('INSERT INTO discussion_live_participants (session_id,user_id,mic_muted,camera_enabled,screen_sharing,is_attending) VALUES (?,?,1,0,0,1) ON DUPLICATE KEY UPDATE left_at=NULL,last_seen_at=NOW(),screen_sharing=0,is_attending=1')->execute([$sessionId,user_uid($user)]);
    lms_audit('start', 'discussion_live_sessions', (string)$sessionId, 'Started discussion video call: ' . $topic['title'], null, $session, $user);
    return discussion_live_state_payload($session, $user);
}

function rpc_join_discussion_live_session(array $args): array
{
    $session = discussion_live_session((string)($args['target_session_id'] ?? ''));
    $user = discussion_live_access($session);
    prevent_multiple_discussion_calls(user_uid($user), (string)$session['id']);
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $lock = $pdo->prepare('SELECT status FROM discussion_live_sessions WHERE id=? FOR UPDATE');
        $lock->execute([$session['id']]);
        if ($lock->fetchColumn() !== 'active') {
            $pdo->rollBack();
            fail('This discussion call has ended.', 409);
        }
        $pdo->prepare('INSERT INTO discussion_live_participants (session_id,user_id,mic_muted,camera_enabled,screen_sharing,is_attending) VALUES (?,?,1,0,0,1) ON DUPLICATE KEY UPDATE mic_muted=1,camera_enabled=0,screen_sharing=0,is_attending=1,left_at=NULL,last_seen_at=NOW()')->execute([$session['id'],user_uid($user)]);
        $pdo->commit();
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $error;
    }
    return discussion_live_state_payload($session, $user);
}

function rpc_update_discussion_live_presence(array $args): array
{
    $session = discussion_live_session((string)($args['target_session_id'] ?? ''));
    $user = discussion_live_access($session);
    if ($session['status'] !== 'active') fail('This discussion call has ended.', 409);
    $uid = user_uid($user);
    db()->prepare('UPDATE discussion_live_participants SET mic_muted=?,camera_enabled=?,screen_sharing=?,is_attending=?,last_seen_at=NOW(),left_at=NULL WHERE session_id=? AND user_id=?')
        ->execute([!empty($args['mic_muted'])?1:0,!empty($args['camera_enabled'])?1:0,!empty($args['screen_sharing'])?1:0,!empty($args['is_attending'])?1:0,$session['id'],$uid]);
    return discussion_live_state_payload($session, $user, max(0, (int)($args['after_signal_id'] ?? 0)));
}

function rpc_leave_discussion_live_session(array $args): array
{
    $session = discussion_live_session((string)($args['target_session_id'] ?? ''));
    $user = discussion_live_access($session);
    db()->prepare('UPDATE discussion_live_participants SET left_at=NOW(),last_seen_at=NOW(),mic_muted=1,camera_enabled=0,screen_sharing=0,is_attending=0 WHERE session_id=? AND user_id=?')->execute([$session['id'],user_uid($user)]);
    return ['left' => true];
}

function rpc_end_discussion_live_session(array $args): array
{
    $session = discussion_live_session((string)($args['target_session_id'] ?? ''));
    $user = discussion_live_access($session);
    if (user_uid($user) !== $session['created_by']) fail('Only the call host can end this call.', 403);
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $lock = $pdo->prepare('SELECT status FROM discussion_live_sessions WHERE id=? FOR UPDATE');
        $lock->execute([$session['id']]);
        if ($lock->fetchColumn() !== 'active') {
            $pdo->rollBack();
            fail('This discussion call has already ended.', 409);
        }
        $pdo->prepare("INSERT INTO discussion_live_attendance_history (session_id,student_id,user_id,full_name,school_id,attendance_status,joined_at,last_seen_at,recorded_at)
            SELECT ?,s.student_id,u.user_uid,
                COALESCE(u.full_name,CONCAT_WS(' ',s.first_name,NULLIF(s.middle_name,''),s.last_name)),s.student_number,
                CASE
                    WHEN p.user_id IS NULL THEN 'not_joined'
                    WHEN p.left_at IS NULL AND p.is_attending=1 AND p.last_seen_at>=DATE_SUB(NOW(),INTERVAL 5 SECOND) THEN 'active'
                    ELSE 'inactive'
                END,
                p.joined_at,p.last_seen_at,NOW()
            FROM academic_classes c
            JOIN blocks b ON b.block_code=c.section
            JOIN enrollments e ON e.period_id=c.period_id AND e.block_id=b.block_id AND e.enrollment_status='Confirmed'
            JOIN enrollment_subjects es ON es.enrollment_id=e.enrollment_id AND es.subject_id=c.subject_id AND es.subject_status='Enrolled'
            JOIN students s ON s.student_id=e.student_id
            LEFT JOIN users u ON u.student_id=s.student_id
            LEFT JOIN discussion_live_participants p ON p.session_id=? AND p.user_id=u.user_uid
            WHERE c.class_uid=?
            ON DUPLICATE KEY UPDATE user_id=VALUES(user_id),full_name=VALUES(full_name),school_id=VALUES(school_id),attendance_status=VALUES(attendance_status),joined_at=VALUES(joined_at),last_seen_at=VALUES(last_seen_at),recorded_at=VALUES(recorded_at)")
            ->execute([$session['id'],$session['id'],$session['class_id']]);
        $pdo->prepare("UPDATE discussion_live_sessions SET status='ended',ended_at=NOW() WHERE id=?")->execute([$session['id']]);
        $pdo->prepare('UPDATE discussion_live_participants SET left_at=COALESCE(left_at,NOW()),mic_muted=1,camera_enabled=0,screen_sharing=0,is_attending=0 WHERE session_id=?')->execute([$session['id']]);
        $pdo->commit();
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $error;
    }
    lms_audit('end', 'discussion_live_sessions', (string)$session['id'], 'Ended discussion video call: ' . $session['topic_title'], $session, null, $user);
    return ['ended' => true];
}

function rpc_send_discussion_live_signal(array $args): array
{
    $session = discussion_live_session((string)($args['target_session_id'] ?? ''));
    $user = discussion_live_access($session);
    $recipient = (string)($args['recipient_id'] ?? '');
    $type = (string)($args['signal_type'] ?? '');
    if ($recipient === '' || !in_array($type, ['offer','answer','ice'], true)) fail('Invalid call signal.');
    $participant = db()->prepare('SELECT 1 FROM discussion_live_participants WHERE session_id=? AND user_id=? AND left_at IS NULL');
    $participant->execute([$session['id'],$recipient]);
    if (!$participant->fetchColumn()) fail('The participant is no longer in the call.', 409);
    $payload = $args['payload'] ?? null;
    db()->prepare('INSERT INTO discussion_live_signals (session_id,sender_id,recipient_id,signal_type,payload_json) VALUES (?,?,?,?,?)')
        ->execute([$session['id'],user_uid($user),$recipient,$type,json_encode($payload, JSON_UNESCAPED_SLASHES)]);
    return ['sent' => true];
}

function rpc_post_discussion_live_event(array $args): array
{
    global $config;
    $session = discussion_live_session((string)($args['target_session_id'] ?? ''));
    $user = discussion_live_access($session);
    $type = (string)($args['event_type'] ?? '');
    $content = trim((string)($args['content'] ?? ''));
    if (!in_array($type, ['comment','reaction'], true)) fail('Invalid live-call event.');
    $attachmentPath = trim((string)($args['attachment_path'] ?? ''));
    $attachmentName = null;
    $attachmentMime = null;
    $attachmentSize = null;
    $attachmentKind = null;
    if ($type === 'reaction') {
        if ($content === '' || mb_strlen($content) > 16) fail('Select a reaction.');
        $attachmentPath = '';
    } else {
        if (mb_strlen($content) > 1000) fail('Comments must be 1000 characters or fewer.');
        if ($content === '' && $attachmentPath === '') fail('Write a comment or attach a file.');
        if ($attachmentPath !== '') {
            $attachmentPath = clean_storage_path($attachmentPath);
            $uid = user_uid($user);
            $prefix = $session['class_id'] . '/' . $session['topic_id'] . '/' . $uid . '/';
            if (!str_starts_with($attachmentPath, $prefix)) fail('The live-comment attachment path is invalid.');
            $file = $config['storage_path'] . DIRECTORY_SEPARATOR . 'discussions' . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $attachmentPath);
            if (!is_file($file)) fail('Upload the live-comment attachment before posting.');
            $attachmentSize = filesize($file);
            if ($attachmentSize === false || $attachmentSize > 10485760) fail('Live-comment attachments must be 10 MB or smaller.');
            $detectedMime = class_exists('finfo') ? (new finfo(FILEINFO_MIME_TYPE))->file($file) : null;
            $attachmentMime = is_string($detectedMime) && $detectedMime !== '' ? $detectedMime : 'application/octet-stream';
            $attachmentName = trim((string)($args['attachment_name'] ?? basename($attachmentPath)));
            if ($attachmentName === '') $attachmentName = basename($attachmentPath);
            if (mb_strlen($attachmentName) > 255) $attachmentName = mb_substr($attachmentName, 0, 255);
            $attachmentKind = str_starts_with($attachmentMime, 'image/') ? 'image' : 'file';
        }
    }
    db()->prepare('INSERT INTO discussion_live_events (session_id,user_id,event_type,content,attachment_path,attachment_name,attachment_mime,attachment_size,attachment_kind) VALUES (?,?,?,?,?,?,?,?,?)')
        ->execute([$session['id'],user_uid($user),$type,$content,$attachmentPath ?: null,$attachmentName,$attachmentMime,$attachmentSize,$attachmentKind]);
    return ['posted' => true];
}

function rpc_admin_update_user(array $args): array
{
    $admin = require_admin(); $id = (string)($args['target_user_id'] ?? ''); $role = (string)($args['target_role'] ?? ''); $status = (string)($args['target_status'] ?? '');
    if (!in_array($role, ['student','instructor','admin'], true) || !in_array($status, ['pending','active','inactive'], true)) fail('Invalid role or status.');
    if ($id === $admin['id'] && ($role !== 'admin' || $status !== 'active')) fail('You cannot remove your own active administrator access.');
    if ($role !== 'instructor') { $stmt = db()->prepare('SELECT 1 FROM classes WHERE instructor_id=? LIMIT 1'); $stmt->execute([$id]); if ($stmt->fetchColumn()) fail("Reassign this instructor's class offerings before changing their role."); }
    db()->prepare('UPDATE profiles SET role=?,status=? WHERE id=?')->execute([$role,$status,$id]);
    lms_audit('user.update', 'user', $id, 'Updated LMS user role/status', null, ['role' => $role, 'status' => $status], $admin);
    $stmt = db()->prepare('SELECT * FROM profiles WHERE id=?'); $stmt->execute([$id]); $row = $stmt->fetch(); if (!$row) fail('User profile not found.',404); return normalize_row('profiles',$row);
}

function rpc_get_security_settings(): array
{
    require_admin();
    return lms_security_settings();
}

function rpc_admin_update_security_settings(array $args): array
{
    $admin = require_admin();
    $attempts = filter_var($args['max_login_attempts'] ?? null, FILTER_VALIDATE_INT);
    $lockout = filter_var($args['lockout_minutes'] ?? null, FILTER_VALIDATE_INT);
    $inactivity = filter_var($args['inactivity_timeout_minutes'] ?? null, FILTER_VALIDATE_INT);
    $minimizedEnabled = filter_var($args['live_attendance_minimized_enabled'] ?? null, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    $tabHiddenEnabled = filter_var($args['live_attendance_tab_hidden_enabled'] ?? null, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    $windowBlurEnabled = filter_var($args['live_attendance_window_blur_enabled'] ?? null, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    $liveInactivityEnabled = filter_var($args['live_attendance_inactivity_enabled'] ?? null, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    $liveInactivitySeconds = filter_var($args['live_attendance_inactivity_seconds'] ?? null, FILTER_VALIDATE_INT);
    if ($attempts === false || $attempts < 1 || $attempts > 20) fail('Maximum login attempts must be between 1 and 20.');
    if ($lockout === false || $lockout < 10 || $lockout > 30) fail('Login lockout duration must be between 10 and 30 minutes.');
    if ($inactivity === false || $inactivity < 1 || $inactivity > 240) fail('Inactivity auto-logout must be between 1 and 240 minutes.');
    if ($minimizedEnabled === null || $tabHiddenEnabled === null || $windowBlurEnabled === null || $liveInactivityEnabled === null) fail('Select valid live-call attendance rules.');
    if ($liveInactivitySeconds === false || $liveInactivitySeconds < 5 || $liveInactivitySeconds > 3600) fail('Live-call inactivity must be between 5 and 3600 seconds.');
    $before = lms_security_settings();
    db()->prepare('INSERT INTO lms_security_settings (settings_id,max_login_attempts,lockout_minutes,inactivity_timeout_minutes,live_attendance_minimized_enabled,live_attendance_tab_hidden_enabled,live_attendance_window_blur_enabled,live_attendance_inactivity_enabled,live_attendance_inactivity_seconds,updated_by) VALUES (1,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE max_login_attempts=VALUES(max_login_attempts),lockout_minutes=VALUES(lockout_minutes),inactivity_timeout_minutes=VALUES(inactivity_timeout_minutes),live_attendance_minimized_enabled=VALUES(live_attendance_minimized_enabled),live_attendance_tab_hidden_enabled=VALUES(live_attendance_tab_hidden_enabled),live_attendance_window_blur_enabled=VALUES(live_attendance_window_blur_enabled),live_attendance_inactivity_enabled=VALUES(live_attendance_inactivity_enabled),live_attendance_inactivity_seconds=VALUES(live_attendance_inactivity_seconds),updated_by=VALUES(updated_by)')
        ->execute([$attempts,$lockout,$inactivity,$minimizedEnabled?1:0,$tabHiddenEnabled?1:0,$windowBlurEnabled?1:0,$liveInactivityEnabled?1:0,$liveInactivitySeconds,$admin['id']]);
    $updated = lms_security_settings();
    lms_audit('security.settings.update', 'lms_security_settings', '1', 'Updated LMS login, auto-logout, and live-call attendance controls', $before, $updated, $admin);
    return $updated;
}

function rpc_get_class_notification_counts(array $args): array
{
    $user = require_active_user();
    if ($user['role'] === 'admin') return [];
    $seenAt = is_array($args['seen_at'] ?? null) ? $args['seen_at'] : [];

    if ($user['role'] === 'instructor') {
        $classStatement = db()->prepare("SELECT class_uid FROM academic_classes WHERE instructor_id=? AND status='Active'");
        $classStatement->execute([$user['instructor_id']]);
    } else {
        $classStatement = db()->prepare("SELECT DISTINCT c.class_uid
            FROM academic_classes c
            JOIN blocks b ON b.block_code=c.section
            JOIN enrollments e ON e.period_id=c.period_id AND e.block_id=b.block_id
            JOIN enrollment_subjects es ON es.enrollment_id=e.enrollment_id AND es.subject_id=c.subject_id
            WHERE e.student_id=? AND c.status='Active'
              AND e.enrollment_status='Confirmed' AND es.subject_status='Enrolled'");
        $classStatement->execute([$user['student_id']]);
    }

    $classIds = $classStatement->fetchAll(PDO::FETCH_COLUMN);
    $results = [];
    foreach ($classIds as $classIdValue) {
        $classId = (string)$classIdValue;
        $counts = [
            'materials' => 0,
            'assignments' => 0,
            'quizzes' => 0,
            'exams' => 0,
            'discussions' => 0,
            'announcements' => 0,
            'progress' => 0,
        ];
        $unreadItems = [
            'materials' => [],
            'assignments' => [],
            'quizzes' => [],
            'exams' => [],
            'discussions' => [],
            'announcements' => [],
            'progress' => [],
        ];

        if ($user['role'] === 'student') {
            $unreadItems['materials'] = notification_unread_items("SELECT id item_id,MAX(created_at) activity_at FROM learning_materials WHERE class_id=? AND created_at>? GROUP BY id", [$classId, notification_cutoff($seenAt, $classId, 'materials')], $seenAt, $classId, 'materials');
            $unreadItems['assignments'] = notification_unread_items("SELECT id item_id,MAX(created_at) activity_at FROM learning_assignments WHERE class_id=? AND status<>'draft' AND created_at>? GROUP BY id", [$classId, notification_cutoff($seenAt, $classId, 'assignments')], $seenAt, $classId, 'assignments');
            $unreadItems['quizzes'] = notification_unread_items("SELECT id item_id,MAX(created_at) activity_at FROM quizzes WHERE class_id=? AND assessment_kind='quiz' AND status<>'draft' AND created_at>? GROUP BY id", [$classId, notification_cutoff($seenAt, $classId, 'quizzes')], $seenAt, $classId, 'quizzes');
            $unreadItems['exams'] = notification_unread_items("SELECT id item_id,MAX(created_at) activity_at FROM quizzes WHERE class_id=? AND assessment_kind='exam' AND status<>'draft' AND created_at>? GROUP BY id", [$classId, notification_cutoff($seenAt, $classId, 'exams')], $seenAt, $classId, 'exams');
            $unreadItems['announcements'] = notification_unread_items("SELECT CAST(a.announcement_id AS CHAR) item_id,MAX(a.created_at) activity_at FROM announcements a JOIN academic_classes c ON c.class_id=a.class_id WHERE a.module_code='lms' AND c.class_uid=? AND a.created_at>? GROUP BY a.announcement_id", [$classId, notification_cutoff($seenAt, $classId, 'announcements')], $seenAt, $classId, 'announcements');
            $unreadItems['progress'] = notification_unread_items("SELECT s.assignment_id item_id,MAX(s.graded_at) activity_at FROM assignment_submissions s JOIN learning_assignments a ON a.id=s.assignment_id WHERE a.class_id=? AND s.student_id=? AND s.graded_at IS NOT NULL AND s.graded_at>? GROUP BY s.assignment_id", [$classId, $user['student_id'], notification_cutoff($seenAt, $classId, 'progress')], $seenAt, $classId, 'progress');
        } else {
            $unreadItems['assignments'] = notification_unread_items("SELECT s.assignment_id item_id,MAX(s.submitted_at) activity_at FROM assignment_submissions s JOIN learning_assignments a ON a.id=s.assignment_id WHERE a.class_id=? AND s.submitted_at>? GROUP BY s.assignment_id", [$classId, notification_cutoff($seenAt, $classId, 'assignments')], $seenAt, $classId, 'assignments');
            $unreadItems['quizzes'] = notification_unread_items("SELECT qa.quiz_id item_id,MAX(qa.submitted_at) activity_at FROM quiz_attempts qa JOIN quizzes q ON q.id=qa.quiz_id WHERE q.class_id=? AND q.assessment_kind='quiz' AND qa.status='submitted' AND qa.submitted_at>? GROUP BY qa.quiz_id", [$classId, notification_cutoff($seenAt, $classId, 'quizzes')], $seenAt, $classId, 'quizzes');
            $unreadItems['exams'] = notification_unread_items("SELECT qa.quiz_id item_id,MAX(qa.submitted_at) activity_at FROM quiz_attempts qa JOIN quizzes q ON q.id=qa.quiz_id WHERE q.class_id=? AND q.assessment_kind='exam' AND qa.status='submitted' AND qa.submitted_at>? GROUP BY qa.quiz_id", [$classId, notification_cutoff($seenAt, $classId, 'exams')], $seenAt, $classId, 'exams');
        }

        $discussionCutoff = notification_cutoff($seenAt, $classId, 'discussions');
        $unreadItems['discussions'] = notification_unread_items("SELECT activity.topic_id item_id,MAX(activity.activity_at) activity_at FROM (
            SELECT t.id topic_id,t.created_at activity_at FROM learning_discussion_topics t WHERE t.class_id=? AND t.created_by<>? AND t.created_at>?
            UNION ALL
            SELECT p.topic_id,p.created_at activity_at FROM learning_discussion_posts p JOIN learning_discussion_topics t ON t.id=p.topic_id WHERE t.class_id=? AND p.author_id<>? AND p.created_at>?
        ) activity LEFT JOIN learning_discussion_memberships mute_membership ON mute_membership.topic_id=activity.topic_id AND mute_membership.user_id=?
        WHERE mute_membership.muted_until IS NULL OR mute_membership.muted_until<=NOW()
        GROUP BY activity.topic_id", [$classId, user_uid($user), $discussionCutoff, $classId, user_uid($user), $discussionCutoff, user_uid($user)], $seenAt, $classId, 'discussions');

        foreach ($unreadItems as $section => $items) $counts[$section] = count($items);

        $results[] = ['class_id' => $classId, ...$counts, 'total' => array_sum($counts), 'unread_items' => $unreadItems];
    }
    return $results;
}

function notification_cutoff(array $seenAt, string $classId, string $section): string
{
    $classSeen = is_array($seenAt[$classId] ?? null) ? $seenAt[$classId] : [];
    $value = $classSeen[$section] ?? null;
    if (is_array($value)) $value = $value['through'] ?? null;
    if (!is_string($value) || trim($value) === '') return '1970-01-01 00:00:00';
    return sql_datetime($value) ?? '1970-01-01 00:00:00';
}

function notification_unread_items(string $sql, array $params, array $seenAt, string $classId, string $section): array
{
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $classSeen = is_array($seenAt[$classId] ?? null) ? $seenAt[$classId] : [];
    $sectionSeen = is_array($classSeen[$section] ?? null) ? $classSeen[$section] : [];
    $itemSeen = is_array($sectionSeen['items'] ?? null) ? $sectionSeen['items'] : [];
    $unread = [];
    foreach ($statement->fetchAll() as $row) {
        $itemId = (string)($row['item_id'] ?? '');
        $activityAt = strtotime((string)($row['activity_at'] ?? '')) ?: 0;
        $viewedAt = isset($itemSeen[$itemId]) && is_string($itemSeen[$itemId]) ? (strtotime($itemSeen[$itemId]) ?: 0) : 0;
        if ($itemId !== '' && $activityAt > $viewedAt) $unread[] = $itemId;
    }
    return $unread;
}

function rpc_submit_assignment(array $args): array
{
    $user=require_active_user(); if($user['role']!=='student') fail('Only students can submit assignments.',403);
    $assignmentId=(string)($args['target_assignment_id']??''); $stmt=db()->prepare("SELECT * FROM learning_assignments WHERE id=? AND status='published'"); $stmt->execute([$assignmentId]); $assignment=$stmt->fetch();
    if(!$assignment||!class_access($assignment['class_id'],$user)) fail('Assignment is unavailable.',403);
    $content=trim((string)($args['submission_content']??'')); $path=trim((string)($args['submission_file_path']??'')); if($content===''&&$path==='') fail('Add text or a file before submitting.');
    $id=uuid(); $sql="INSERT INTO assignment_submissions (id,assignment_id,student_id,content,file_path,status,submitted_at) VALUES (?,?,?,?,?,'submitted',NOW()) ON DUPLICATE KEY UPDATE content=VALUES(content),file_path=IF(VALUES(file_path)='',file_path,VALUES(file_path)),status='submitted',submitted_at=NOW(),grade=NULL,feedback=NULL,graded_by=NULL,graded_at=NULL";
    db()->prepare($sql)->execute([$id,$assignmentId,$user['student_id'],$content?:null,$path?:null]);
    $get=db()->prepare('SELECT s.*,CAST(u.user_id AS CHAR) student_id FROM assignment_submissions s JOIN users u ON u.student_id=s.student_id WHERE s.assignment_id=? AND s.student_id=?'); $get->execute([$assignmentId,$user['student_id']]); return normalize_row('submissions',$get->fetch());
}

function rpc_grade_submission(array $args): array
{
    $id=(string)($args['target_submission_id']??''); $stmt=db()->prepare('SELECT s.*,a.class_id,a.points FROM assignment_submissions s JOIN learning_assignments a ON a.id=s.assignment_id WHERE s.id=?'); $stmt->execute([$id]); $row=$stmt->fetch(); if(!$row) fail('Submission not found.',404);
    $user=require_class_manager($row['class_id']); $grade=(float)($args['awarded_grade']??-1); if($grade<0||$grade>(float)$row['points']) fail('Grade must be within the assignment point limit.');
    db()->prepare("UPDATE assignment_submissions SET grade=?,feedback=?,status='graded',graded_by=?,graded_at=NOW() WHERE id=?")->execute([$grade,trim((string)($args['grading_feedback']??'')),$user['id'],$id]);
    $get=db()->prepare('SELECT s.*,CAST(u.user_id AS CHAR) student_id FROM assignment_submissions s JOIN users u ON u.student_id=s.student_id WHERE s.id=?'); $get->execute([$id]); return normalize_row('submissions',$get->fetch());
}

function rpc_update_quiz_question(array $args): array
{
    $id = (string)($args['target_question_id'] ?? '');
    $statement = db()->prepare('SELECT qq.*,q.class_id,q.status quiz_status FROM quiz_questions qq JOIN quizzes q ON q.id=qq.quiz_id WHERE qq.id=?');
    $statement->execute([$id]);
    $existing = $statement->fetch();
    if (!$existing) fail('Question not found.', 404);
    $user = require_class_manager($existing['class_id']);
    if ($existing['quiz_status'] === 'closed') fail('Closed assessment questions cannot be edited.', 409);

    $prompt = trim((string)($args['question_prompt'] ?? ''));
    $type = (string)($args['question_type'] ?? '');
    $options = is_array($args['question_options'] ?? null) ? array_values(array_filter(array_map(fn($value) => trim((string)$value), $args['question_options']), fn($value) => $value !== '')) : [];
    $points = (float)($args['question_points'] ?? 0);
    $answer = trim((string)($args['correct_answer'] ?? ''));
    if ($prompt === '') fail('Enter the question.');
    if ($type !== 'essay' && $answer === '') fail('Enter the correct answer.');
    if (!in_array($type, ['multiple_choice','true_false','identification','essay'], true)) fail('Select a valid question type.');
    if (!is_finite($points) || $points <= 0) fail('Points must be greater than zero.');
    if ($type === 'true_false') $options = ['True', 'False'];
    if (in_array($type, ['identification','essay'], true)) $options = [];
    if ($type === 'multiple_choice' && count($options) < 2) fail('Enter at least two choices.');
    if (in_array($type, ['multiple_choice','true_false'], true) && !in_array($answer, $options, true)) fail('The correct answer must match one of the choices.');

    $pdo = db();
    $pdo->beginTransaction();
    try {
        $pdo->prepare('UPDATE quiz_questions SET prompt=?,question_type=?,options=?,points=? WHERE id=?')->execute([
            $prompt,
            $type,
            json_encode($options, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            $points,
            $id,
        ]);
        $pdo->prepare('INSERT INTO quiz_answer_keys (question_id,correct_answer,case_sensitive) VALUES (?,?,0) ON DUPLICATE KEY UPDATE correct_answer=VALUES(correct_answer)')->execute([$id, $answer]);
        $pdo->commit();
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $error;
    }
    $get = $pdo->prepare('SELECT qq.*,k.correct_answer FROM quiz_questions qq LEFT JOIN quiz_answer_keys k ON k.question_id=qq.id WHERE qq.id=?');
    $get->execute([$id]);
    $updated = normalize_row('quiz_questions', $get->fetch() ?: []);
    lms_audit('update', 'quiz_questions', $id, 'Updated quiz question: ' . $prompt, normalize_row('quiz_questions', $existing), $updated, $user);
    return $updated;
}

function available_student_quiz(string $quizId, array $user): array
{
    $stmt=db()->prepare("SELECT * FROM quizzes WHERE id=? AND status='published'");
    $stmt->execute([$quizId]);
    $quiz=$stmt->fetch();
    if(!$quiz||!class_access($quiz['class_id'],$user)) fail('Quiz is unavailable.',403);
    if($quiz['opens_at']&&strtotime($quiz['opens_at'])>time()) fail('Quiz is not open yet.',403);
    if($quiz['closes_at']&&strtotime($quiz['closes_at'])<time()) fail('Quiz is closed.',403);
    return $quiz;
}

function quiz_attempt_row(string $attemptId): array
{
    $get=db()->prepare('SELECT a.*,CAST(u.user_id AS CHAR) student_id FROM quiz_attempts a JOIN users u ON u.student_id=a.student_id WHERE a.id=?');
    $get->execute([$attemptId]);
    return normalize_row('quiz_attempts',$get->fetch());
}

function quiz_score(string $quizId, array $answers): array
{
    $questions=fetch_all('SELECT qq.id,qq.question_type,qq.points,k.correct_answer,k.case_sensitive FROM quiz_questions qq LEFT JOIN quiz_answer_keys k ON k.question_id=qq.id WHERE qq.quiz_id=?',[$quizId]);
    $score=0.0;$max=0.0;
    foreach($questions as $q){$max+=(float)$q['points'];if($q['question_type']==='essay')continue;$supplied=trim((string)($answers[$q['id']]??''));$correct=trim((string)($q['correct_answer']??''));$match=$q['case_sensitive']?$supplied===$correct:mb_strtolower($supplied)===mb_strtolower($correct);if($match)$score+=(float)$q['points'];}
    return [$score,$max];
}

function quiz_attempt_score_totals(array $attempt): array
{
    $answers=json_decode((string)($attempt['answers']??'{}'),true);if(!is_array($answers))$answers=[];
    [$automatic,$questionMax]=quiz_score((string)$attempt['quiz_id'],$answers);
    $essayScores=json_decode((string)($attempt['essay_scores']??'{}'),true);if(!is_array($essayScores))$essayScores=[];
    $essayQuestions=fetch_all("SELECT id,points FROM quiz_questions WHERE quiz_id=? AND question_type='essay'",[$attempt['quiz_id']]);$essayTotal=0.0;
    foreach($essayQuestions as $question){$value=(float)($essayScores[$question['id']]??0);$essayTotal+=min(max($value,0),(float)$question['points']);}
    $hasFile=trim((string)($attempt['submission_file_path']??''))!=='';
    $fileMaximum=$hasFile?(float)($attempt['file_submission_points']??0):0.0;
    $fileScore=$hasFile?min(max((float)($attempt['submission_file_score']??0),0),$fileMaximum):0.0;
    return [$automatic+$essayTotal+$fileScore,$questionMax+$fileMaximum];
}

function rpc_grade_quiz_essay(array $args): array
{
    $attemptId=(string)($args['target_attempt_id']??'');$questionId=(string)($args['target_question_id']??'');$awarded=(float)($args['awarded_points']??-1);
    $stmt=db()->prepare("SELECT a.*,q.class_id,q.file_submission_points,qq.prompt,qq.points FROM quiz_attempts a JOIN quizzes q ON q.id=a.quiz_id JOIN quiz_questions qq ON qq.quiz_id=a.quiz_id AND qq.id=? AND qq.question_type='essay' WHERE a.id=?");
    $stmt->execute([$questionId,$attemptId]);$attempt=$stmt->fetch();if(!$attempt)fail('Essay attempt not found.',404);
    $user=require_class_manager($attempt['class_id']);if($attempt['status']!=='submitted')fail('The student has not submitted this assessment.',409);
    $maximum=(float)$attempt['points'];if(!is_finite($awarded)||$awarded<0||$awarded>$maximum)fail('Essay score must be between zero and the question point value.');
    $essayScores=json_decode((string)($attempt['essay_scores']??'{}'),true);if(!is_array($essayScores))$essayScores=[];$essayScores[$questionId]=$awarded;$attempt['essay_scores']=json_encode($essayScores);
    [$score,$max]=quiz_attempt_score_totals($attempt);
    db()->prepare('UPDATE quiz_attempts SET essay_scores=?,score=?,max_score=? WHERE id=?')->execute([$attempt['essay_scores'],$score,$max,$attemptId]);
    $updated=quiz_attempt_row($attemptId);lms_audit('grade','quiz_attempts',$attemptId,'Graded essay question: '.$attempt['prompt'],null,['question_id'=>$questionId,'awarded_points'=>$awarded,'score'=>$updated['score']],$user);return $updated;
}

function rpc_grade_quiz_file(array $args): array
{
    $attemptId=(string)($args['target_attempt_id']??'');$awarded=(float)($args['awarded_points']??-1);
    $statement=db()->prepare("SELECT a.*,q.class_id,q.title,q.assessment_kind,q.file_submission_points FROM quiz_attempts a JOIN quizzes q ON q.id=a.quiz_id WHERE a.id=?");
    $statement->execute([$attemptId]);$attempt=$statement->fetch();if(!$attempt)fail('Assessment attempt not found.',404);
    $user=require_class_manager((string)$attempt['class_id']);if($attempt['status']!=='submitted')fail('The student has not submitted this assessment.',409);
    if(trim((string)($attempt['submission_file_path']??''))==='')fail('This attempt has no submitted file.',409);
    $maximum=(float)$attempt['file_submission_points'];if(!is_finite($awarded)||$awarded<0||$awarded>$maximum)fail('File score must be between zero and the file submission point value.');
    $attempt['submission_file_score']=$awarded;[$score,$max]=quiz_attempt_score_totals($attempt);
    db()->prepare('UPDATE quiz_attempts SET submission_file_score=?,score=?,max_score=? WHERE id=?')->execute([$awarded,$score,$max,$attemptId]);
    $updated=quiz_attempt_row($attemptId);lms_audit('grade','quiz_attempts',$attemptId,'Graded submitted file for '.($attempt['assessment_kind']==='exam'?'exam':'quiz').': '.$attempt['title'],null,['submission_file_score'=>$awarded,'score'=>$updated['score']],$user);return $updated;
}

function rpc_start_quiz(array $args): array
{
    $user=require_active_user(); if($user['role']!=='student') fail('Only students can start quizzes.',403);
    $quizId=(string)($args['target_quiz_id']??''); $quiz=available_student_quiz($quizId,$user);
    $existing=db()->prepare('SELECT * FROM quiz_attempts WHERE quiz_id=? AND student_id=?'); $existing->execute([$quizId,$user['student_id']]); $attempt=$existing->fetch();
    if($attempt){
        if($attempt['status']==='submitted') return quiz_attempt_row($attempt['id']);
        $deadline=null;
        if((int)$quiz['time_limit_minutes']>0)$deadline=strtotime($attempt['started_at'])+((int)$quiz['time_limit_minutes']*60);
        if($quiz['closes_at'])$deadline=$deadline===null?strtotime($quiz['closes_at']):min($deadline,strtotime($quiz['closes_at']));
        if($deadline!==null&&time()>$deadline+30){
            [$score,$max]=quiz_score($quizId,[]);
            db()->prepare("UPDATE quiz_attempts SET answers='{}',score=?,max_score=?,status='submitted',submitted_at=FROM_UNIXTIME(?) WHERE id=?")->execute([$score,$max,$deadline,$attempt['id']]);
        }
        return quiz_attempt_row($attempt['id']);
    }
    $id=uuid();
    try{db()->prepare("INSERT INTO quiz_attempts (id,quiz_id,student_id,answers,status) VALUES (?,?,?,'{}','in_progress')")->execute([$id,$quizId,$user['student_id']]);}
    catch(PDOException $error){if(!unique_violation($error))throw $error; $existing->execute([$quizId,$user['student_id']]); return quiz_attempt_row($existing->fetch()['id']);}
    return quiz_attempt_row($id);
}

function rpc_submit_quiz(array $args): array
{
    $user=require_active_user(); if($user['role']!=='student') fail('Only students can submit quiz attempts.',403);
    $quizId=(string)($args['target_quiz_id']??''); $stmt=db()->prepare("SELECT * FROM quizzes WHERE id=? AND status='published'"); $stmt->execute([$quizId]); $quiz=$stmt->fetch();
    if(!$quiz||!class_access($quiz['class_id'],$user)) fail('Quiz is unavailable.',403);
    if($quiz['opens_at']&&strtotime($quiz['opens_at'])>time()) fail('Quiz is not open yet.',403);
    $attemptStmt=db()->prepare("SELECT * FROM quiz_attempts WHERE quiz_id=? AND student_id=? AND status='in_progress'"); $attemptStmt->execute([$quizId,$user['student_id']]); $attempt=$attemptStmt->fetch();
    if(!$attempt) fail('Start the quiz before submitting it.',409);
    $deadline=null;
    if((int)$quiz['time_limit_minutes']>0)$deadline=strtotime($attempt['started_at'])+((int)$quiz['time_limit_minutes']*60);
    if($quiz['closes_at'])$deadline=$deadline===null?strtotime($quiz['closes_at']):min($deadline,strtotime($quiz['closes_at']));
    if($deadline!==null&&time()>$deadline+30) fail('The quiz time limit has expired.',409);
    $answers=is_array($args['submitted_answers']??null)?$args['submitted_answers']:[];
    $filePath=trim((string)($args['submission_file_path']??''));$fileName=trim((string)($args['submission_file_name']??''));
    if($filePath!==''&&!str_starts_with($filePath,$quiz['class_id'].'/'.$user['id'].'/quiz-attempts/'.$quizId.'/'))fail('Invalid assessment submission file.',403);
    if(($filePath==='')!==($fileName===''))fail('Assessment submission file details are incomplete.');
    [$score,$max]=quiz_score($quizId,$answers);if($filePath!=='')$max+=(float)$quiz['file_submission_points'];
    db()->prepare("UPDATE quiz_attempts SET answers=?,submission_file_path=IF(?='',submission_file_path,?),submission_file_name=IF(?='',submission_file_name,?),score=?,max_score=?,status='submitted',submitted_at=NOW() WHERE id=?")->execute([json_encode($answers),$filePath,$filePath,$fileName,$fileName,$score,$max,$attempt['id']]);
    return quiz_attempt_row($attempt['id']);
}

function rpc_set_quiz_attachment(array $args): array
{
    $quizId=(string)($args['target_quiz_id']??'');$statement=db()->prepare('SELECT * FROM quizzes WHERE id=?');$statement->execute([$quizId]);$quiz=$statement->fetch();if(!$quiz)fail('Quiz or exam not found.',404);
    $user=require_class_manager((string)$quiz['class_id']);$path=trim((string)($args['attachment_path']??''));$name=trim((string)($args['attachment_name']??''));
    if($path!==''&&!str_starts_with($path,$quiz['class_id'].'/quiz-attachments/'.$quizId.'/'))fail('Invalid assessment attachment.',403);
    if(($path==='')!==($name===''))fail('Assessment attachment details are incomplete.');
    $oldPath=(string)($quiz['attachment_path']??'');
    db()->prepare('UPDATE quizzes SET attachment_path=?,attachment_name=? WHERE id=?')->execute([$path?:null,$name?:null,$quizId]);
    if($oldPath!==''&&$oldPath!==$path)remove_private_storage_file('materials',$oldPath);
    $statement->execute([$quizId]);$updated=normalize_row('quizzes',$statement->fetch()?:[]);
    lms_audit($path===''?'attachment.remove':'attachment.update','quizzes',$quizId,($path===''?'Removed attachment from ':'Updated attachment for ').assessment_label($quiz).': '.$quiz['title'],normalize_row('quizzes',$quiz),$updated,$user);
    return $updated;
}

function rpc_remove_quiz_submission_file(array $args): array
{
    $attemptId=(string)($args['target_attempt_id']??'');$statement=db()->prepare('SELECT a.*,q.class_id,q.title,q.assessment_kind,q.file_submission_points,CAST(u.user_id AS CHAR) student_uid FROM quiz_attempts a JOIN quizzes q ON q.id=a.quiz_id JOIN users u ON u.student_id=a.student_id WHERE a.id=?');$statement->execute([$attemptId]);$attempt=$statement->fetch();if(!$attempt)fail('Assessment attempt not found.',404);
    $user=require_active_user();$ownsAttempt=$user['role']==='student'&&$user['student_id']&&(int)$user['student_id']===(int)$attempt['student_id'];if(!$ownsAttempt)fail('Only the student who submitted this file can remove it.',403);
    $path=(string)($attempt['submission_file_path']??'');$attempt['submission_file_path']=null;$attempt['submission_file_name']=null;$attempt['submission_file_score']=null;[$score,$max]=quiz_attempt_score_totals($attempt);db()->prepare('UPDATE quiz_attempts SET submission_file_path=NULL,submission_file_name=NULL,submission_file_score=NULL,score=?,max_score=? WHERE id=?')->execute([$score,$max,$attemptId]);
    if($path!=='')remove_private_storage_file('submissions',$path);
    $updated=quiz_attempt_row($attemptId);lms_audit('attachment.remove','quiz_attempts',$attemptId,'Removed submitted file from '.($attempt['assessment_kind']==='exam'?'exam':'quiz').': '.$attempt['title'],normalize_row('quiz_attempts',$attempt),$updated,$user);return $updated;
}

function remove_private_storage_file(string $bucket,string $path): void
{
    global $config;if(!in_array($bucket,['materials','submissions','discussions'],true))return;$clean=clean_storage_path($path);$file=$config['storage_path'].DIRECTORY_SEPARATOR.$bucket.DIRECTORY_SEPARATOR.str_replace('/',DIRECTORY_SEPARATOR,$clean);if(is_file($file))unlink($file);
}

function live_quiz_session(string $sessionId): array
{
    $statement = db()->prepare("SELECT s.*,q.title quiz_title,q.description quiz_description,q.assessment_kind
        FROM quiz_live_sessions s JOIN quizzes q ON q.id=s.quiz_id WHERE s.id=?");
    $statement->execute([$sessionId]);
    $session = $statement->fetch();
    if (!$session) fail('Live assessment session not found.', 404);
    return $session;
}

function live_quiz_enrolled_count(string $classId): int
{
    $statement = db()->prepare("SELECT COUNT(DISTINCT e.student_id)
        FROM academic_classes c
        JOIN blocks b ON b.block_code=c.section
        JOIN enrollments e ON e.period_id=c.period_id AND e.block_id=b.block_id AND e.enrollment_status='Confirmed'
        JOIN enrollment_subjects es ON es.enrollment_id=e.enrollment_id AND es.subject_id=c.subject_id AND es.subject_status='Enrolled'
        WHERE c.class_uid=?");
    $statement->execute([$classId]);
    return (int)$statement->fetchColumn();
}

function rpc_list_live_quiz_sessions(array $args): array
{
    $classId = (string)($args['target_class_id'] ?? '');
    $assessmentKind = (string)($args['assessment_kind'] ?? 'quiz');
    if (!in_array($assessmentKind, ['quiz','exam'], true)) fail('Invalid assessment type.');
    $user = require_class_access($classId);
    $sql = "SELECT s.*,q.title quiz_title,q.assessment_kind,
        (SELECT COUNT(*) FROM quiz_live_participants p WHERE p.session_id=s.id AND p.status IN ('connected','active') AND p.last_seen_at>=DATE_SUB(NOW(),INTERVAL 6 SECOND)) participant_count,
        (SELECT COUNT(*) FROM quiz_live_responses r WHERE r.session_id=s.id) response_count
        FROM quiz_live_sessions s JOIN quizzes q ON q.id=s.quiz_id WHERE s.class_id=? AND q.assessment_kind=?";
    $params = [$classId,$assessmentKind];
    if ($user['role'] === 'student') $sql .= " AND s.status NOT IN ('cancelled')";
    $sql .= ' ORDER BY COALESCE(s.scheduled_start,s.created_at) DESC';
    return fetch_all($sql, $params, 'quiz_live_sessions');
}

function rpc_create_live_quiz_session(array $args): array
{
    $quizId = (string)($args['target_quiz_id'] ?? '');
    $statement = db()->prepare("SELECT * FROM quizzes WHERE id=? AND assessment_kind IN ('quiz','exam')");
    $statement->execute([$quizId]);
    $quiz = $statement->fetch();
    if (!$quiz) fail('Quiz or exam not found.', 404);
    $assessmentNoun = $quiz['assessment_kind'] === 'exam' ? 'exam' : 'quiz';
    $user = require_class_manager((string)$quiz['class_id']);
    $countStatement = db()->prepare("SELECT COUNT(*) FROM quiz_questions WHERE quiz_id=? AND question_type<>'essay'");
    $countStatement->execute([$quizId]);
    if ((int)$countStatement->fetchColumn() === 0) fail('Add at least one objective question before creating a live session.');
    $essayStatement = db()->prepare("SELECT COUNT(*) FROM quiz_questions WHERE quiz_id=? AND question_type='essay'");
    $essayStatement->execute([$quizId]);
    if ((int)$essayStatement->fetchColumn() > 0) fail('Live sessions currently support objective questions only. Remove essay questions or use a regular ' . $assessmentNoun . '.');
    $scheduledStart = sql_datetime(is_string($args['scheduled_start'] ?? null) ? $args['scheduled_start'] : null);
    $meetingId = isset($args['meeting_id']) && $args['meeting_id'] !== '' ? (int)$args['meeting_id'] : null;
    if ($meetingId !== null) {
        $meeting = db()->prepare('SELECT 1 FROM class_meetings m JOIN academic_classes c ON c.class_id=m.class_id WHERE m.meeting_id=? AND c.class_uid=? AND m.status=\'Published\'');
        $meeting->execute([$meetingId, $quiz['class_id']]);
        if (!$meeting->fetchColumn()) fail('Select a published meeting for this class.');
    }
    $seconds = (int)($args['question_time_seconds'] ?? 30);
    if ($seconds < 5 || $seconds > 600) fail('Question time must be between 5 and 600 seconds.');
    $id = uuid();
    db()->prepare("INSERT INTO quiz_live_sessions
        (id,quiz_id,class_id,meeting_id,scheduled_start,question_time_seconds,show_correct_answer,show_leaderboard,randomize_choices,created_by)
        VALUES (?,?,?,?,?,?,?,?,?,?)")->execute([
            $id,$quizId,$quiz['class_id'],$meetingId,$scheduledStart,$seconds,
            !empty($args['show_correct_answer']) ? 1 : 0,
            !empty($args['show_leaderboard']) ? 1 : 0,
            !empty($args['randomize_choices']) ? 1 : 0,
            user_uid($user),
        ]);
    $created = live_quiz_session($id);
    lms_audit('create', 'quiz_live_sessions', $id, 'Created live ' . $assessmentNoun . ' session: ' . $quiz['title'], null, $created, $user);
    return normalize_row('quiz_live_sessions', $created);
}

function live_quiz_question_rows(string $quizId, bool $includeAnswers): array
{
    $sql = $includeAnswers
        ? 'SELECT q.*,k.correct_answer,k.case_sensitive FROM quiz_questions q LEFT JOIN quiz_answer_keys k ON k.question_id=q.id WHERE q.quiz_id=? ORDER BY q.position,q.created_at'
        : 'SELECT q.* FROM quiz_questions q WHERE q.quiz_id=? ORDER BY q.position,q.created_at';
    return fetch_all($sql, [$quizId], 'quiz_questions');
}

function live_quiz_results(string $sessionId, bool $includeStudents): array
{
    $rows = fetch_all("SELECT r.student_id,SUM(r.points_awarded) score,
        (SELECT COALESCE(SUM(q2.points),0) FROM quiz_live_sessions ls2 JOIN quiz_questions q2 ON q2.quiz_id=ls2.quiz_id WHERE ls2.id=r.session_id) max_score,
        " . ($includeStudents ? "CONCAT_WS(' ',st.first_name,NULLIF(st.middle_name,''),st.last_name) student_name,st.student_number,up.avatar_path," : '') . "
        COUNT(*) answered_count
        FROM quiz_live_responses r
        JOIN quiz_questions q ON q.id=r.question_id
        " . ($includeStudents ? 'JOIN students st ON st.student_id=r.student_id LEFT JOIN users u ON u.student_id=st.student_id LEFT JOIN user_profiles up ON up.user_id=u.user_id' : '') . "
        WHERE r.session_id=? GROUP BY r.student_id" . ($includeStudents ? ',st.first_name,st.middle_name,st.last_name,st.student_number,up.avatar_path' : '') . '
        ORDER BY score DESC,answered_count DESC', [$sessionId]);
    return $rows;
}

function rpc_live_quiz_state(array $args): array
{
    $sessionId = (string)($args['target_session_id'] ?? '');
    $session = live_quiz_session($sessionId);
    $user = require_class_access((string)$session['class_id']);
    auto_advance_expired_live_quiz($sessionId);
    $session = live_quiz_session($sessionId);
    $manager = class_manage((string)$session['class_id'], $user);
    if ($user['role'] === 'student') {
        db()->prepare("UPDATE quiz_live_participants SET last_seen_at=NOW(),status=CASE WHEN status='submitted' THEN status WHEN ?='active' THEN 'active' ELSE 'connected' END WHERE session_id=? AND student_id=?")
            ->execute([$session['status'], $session['id'], $user['student_id']]);
    }
    $questions = live_quiz_question_rows((string)$session['quiz_id'], $manager);
    if (!$manager) {
        $questions = array_values(array_filter($questions, fn(array $question) => $session['current_question_id'] !== null && $question['id'] === $session['current_question_id']));
        foreach ($questions as &$question) {
            if (!empty($session['randomize_choices']) && is_array($question['options'])) {
                usort($question['options'], fn($left, $right) => crc32($session['id'].'|'.$question['id'].'|'.$user['id'].'|'.(string)$left) <=> crc32($session['id'].'|'.$question['id'].'|'.$user['id'].'|'.(string)$right));
            }
        }
    }
    $participantStatement = db()->prepare('SELECT status,joined_at,last_seen_at,completed_at FROM quiz_live_participants WHERE session_id=? AND student_id=?');
    $participantStatement->execute([$session['id'], $user['student_id'] ?? 0]);
    $myParticipant = $participantStatement->fetch() ?: null;
    $answerStatement = db()->prepare('SELECT question_id,answer,is_correct,points_awarded,submitted_at FROM quiz_live_responses WHERE session_id=? AND student_id=?');
    $answerStatement->execute([$session['id'], $user['student_id'] ?? 0]);
    $myResponses = $answerStatement->fetchAll();
    if (!$manager && $session['status'] !== 'completed' && empty($session['show_correct_answer'])) {
        foreach ($myResponses as &$response) {
            $response['is_correct'] = null;
            $response['points_awarded'] = 0;
        }
    }
    $counts = db()->prepare("SELECT
        (SELECT COUNT(*) FROM quiz_live_participants WHERE session_id=? AND status IN ('connected','active') AND last_seen_at>=DATE_SUB(NOW(),INTERVAL 6 SECOND)) participant_count,
        (SELECT COUNT(*) FROM quiz_live_responses WHERE session_id=? AND question_id=?) response_count");
    $counts->execute([$session['id'],$session['id'],$session['current_question_id']]);
    $countRow = $counts->fetch() ?: ['participant_count'=>0,'response_count'=>0];
    $joinedStudentIds = [];
    if ($manager) {
        $joinedStatement = db()->prepare("SELECT CAST(u.user_id AS CHAR)
            FROM quiz_live_participants p
            JOIN users u ON u.student_id=p.student_id
            WHERE p.session_id=?
              AND p.status IN ('connected','active')
              AND p.last_seen_at>=DATE_SUB(NOW(),INTERVAL 6 SECOND)");
        $joinedStatement->execute([$session['id']]);
        $joinedStudentIds = $joinedStatement->fetchAll(PDO::FETCH_COLUMN);
    }
    $resultsVisible = $manager || $session['status'] === 'completed';
    $results = $resultsVisible ? live_quiz_results((string)$session['id'], $manager) : [];
    if (!$manager) {
        if (empty($session['show_leaderboard'])) $results = array_values(array_filter($results, fn(array $result) => (int)$result['student_id'] === (int)$user['student_id']));
        foreach ($results as $index => &$result) {
            $result['rank'] = $index + 1;
            unset($result['student_id']);
        }
    }
    return [
        'session' => normalize_row('quiz_live_sessions', $session),
        'questions' => $questions,
        'participant' => $myParticipant ? normalize_row('quiz_live_participants', $myParticipant) : null,
        'my_responses' => array_map(fn(array $row) => normalize_row('quiz_live_responses', $row), $myResponses),
        'participant_count' => (int)$countRow['participant_count'],
        'response_count' => (int)$countRow['response_count'],
        'enrolled_count' => live_quiz_enrolled_count((string)$session['class_id']),
        'joined_student_ids' => $joinedStudentIds,
        'results' => $results,
    ];
}

function rpc_join_live_quiz_session(array $args): array
{
    $session = live_quiz_session((string)($args['target_session_id'] ?? ''));
    $user = require_class_access((string)$session['class_id']);
    $assessmentNoun = $session['assessment_kind'] === 'exam' ? 'exam' : 'quiz';
    if ($user['role'] !== 'student' || !$user['student_id']) fail('Only enrolled students can join a live ' . $assessmentNoun . '.', 403);
    if (in_array($session['status'], ['completed','cancelled'], true)) fail('This live ' . $assessmentNoun . ' is no longer accepting participants.', 409);
    $id = uuid();
    db()->prepare("INSERT INTO quiz_live_participants (id,session_id,student_id,status)
        VALUES (?,?,?,'connected') ON DUPLICATE KEY UPDATE last_seen_at=NOW(),status=IF(status='submitted','submitted','connected')")
        ->execute([$id,$session['id'],$user['student_id']]);
    return rpc_live_quiz_state(['target_session_id'=>$session['id']]);
}

function rpc_control_live_quiz_session(array $args): array
{
    $session = live_quiz_session((string)($args['target_session_id'] ?? ''));
    $user = require_class_manager((string)$session['class_id']);
    $action = (string)($args['session_action'] ?? '');
    $questions = live_quiz_question_rows((string)$session['quiz_id'], true);
    $ids = array_column($questions, 'id');
    $sets = []; $params = [];
    if ($action === 'open_lobby' && $session['status'] === 'scheduled') $sets = ["status='lobby'","current_question_id=NULL","question_opened_at=NULL"];
    elseif ($action === 'start' && in_array($session['status'], ['scheduled','lobby'], true)) {
        if (!$ids) fail('This ' . ($session['assessment_kind'] === 'exam' ? 'exam' : 'quiz') . ' has no questions.');
        $sets = ["status='active'","current_question_id=?","question_opened_at=NOW()","started_at=COALESCE(started_at,NOW())"];
        $params[] = $ids[0];
    } elseif ($action === 'pause' && $session['status'] === 'active') $sets = ["status='paused'","question_opened_at=NULL"];
    elseif ($action === 'resume' && $session['status'] === 'paused') $sets = ["status='active'","question_opened_at=NOW()"];
    elseif ($action === 'complete' && !in_array($session['status'], ['completed','cancelled'], true)) $sets = ["status='completed'","question_opened_at=NULL","ended_at=NOW()"];
    elseif ($action === 'cancel' && !in_array($session['status'], ['completed','cancelled'], true)) $sets = ["status='cancelled'","question_opened_at=NULL","ended_at=NOW()"];
    else fail('That live-session action is not available in the current state.', 409);
    $params[] = $session['id'];
    db()->prepare('UPDATE quiz_live_sessions SET '.implode(',',$sets).' WHERE id=?')->execute($params);
    if (in_array($action, ['complete','cancel'], true)) db()->prepare("UPDATE quiz_live_participants SET status=IF(?='complete','submitted','disconnected'),completed_at=NOW() WHERE session_id=?")->execute([$action,$session['id']]);
    lms_audit($action, 'quiz_live_sessions', (string)$session['id'], ucfirst(str_replace('_',' ',$action)) . ' live ' . ($session['assessment_kind'] === 'exam' ? 'exam' : 'quiz') . ': ' . $session['quiz_title'], normalize_row('quiz_live_sessions',$session), null, $user);
    return rpc_live_quiz_state(['target_session_id'=>$session['id']]);
}

function rpc_submit_live_quiz_answer(array $args): array
{
    $session = live_quiz_session((string)($args['target_session_id'] ?? ''));
    $user = require_class_access((string)$session['class_id']);
    if ($user['role'] !== 'student' || !$user['student_id']) fail('Only enrolled students can answer a live ' . ($session['assessment_kind'] === 'exam' ? 'exam' : 'quiz') . '.', 403);
    if ($session['status'] !== 'active' || !$session['current_question_id']) fail('The instructor is not accepting answers right now.', 409);
    $participant = db()->prepare('SELECT 1 FROM quiz_live_participants WHERE session_id=? AND student_id=?');
    $participant->execute([$session['id'],$user['student_id']]);
    if (!$participant->fetchColumn()) fail('Enter the live-session lobby before answering.', 409);
    if ($session['question_time_seconds'] && $session['question_opened_at'] && time() > strtotime($session['question_opened_at']) + (int)$session['question_time_seconds'] + 2) fail('The question time has expired.', 409);
    $question = db()->prepare("SELECT q.*,k.correct_answer,k.case_sensitive FROM quiz_questions q LEFT JOIN quiz_answer_keys k ON k.question_id=q.id WHERE q.id=? AND q.quiz_id=? AND q.question_type<>'essay'");
    $question->execute([$session['current_question_id'],$session['quiz_id']]);
    $row = $question->fetch();
    if (!$row) fail('The current question is unavailable.', 409);
    $answer = trim((string)($args['submitted_answer'] ?? ''));
    if ($answer === '') fail('Select or enter an answer.');
    $correct = trim((string)($row['correct_answer'] ?? ''));
    $matches = !empty($row['case_sensitive']) ? $answer === $correct : mb_strtolower($answer) === mb_strtolower($correct);
    $responseMs = $session['question_opened_at'] ? max(0, min(2147483647, (int)round((microtime(true)-strtotime($session['question_opened_at']))*1000))) : null;
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $lock = $pdo->prepare('SELECT status,current_question_id FROM quiz_live_sessions WHERE id=? FOR UPDATE');
        $lock->execute([$session['id']]);
        $lockedSession = $lock->fetch();
        if (!$lockedSession || $lockedSession['status'] !== 'active' || $lockedSession['current_question_id'] !== $row['id']) {
            $pdo->rollBack();
            fail('The instructor has already moved to another question.', 409);
        }
        $pdo->prepare('INSERT INTO quiz_live_responses (id,session_id,question_id,student_id,answer,is_correct,points_awarded,response_time_ms) VALUES (?,?,?,?,?,?,?,?)')
            ->execute([uuid(),$session['id'],$row['id'],$user['student_id'],$answer,$matches?1:0,$matches?(float)$row['points']:0,$responseMs]);
        $pdo->prepare("UPDATE quiz_live_participants SET status='active',last_seen_at=NOW() WHERE session_id=? AND student_id=?")->execute([$session['id'],$user['student_id']]);
        $connected = $pdo->prepare("SELECT COUNT(*) FROM quiz_live_participants
            WHERE session_id=? AND status IN ('connected','active') AND last_seen_at>=DATE_SUB(NOW(),INTERVAL 6 SECOND)");
        $connected->execute([$session['id']]);
        $connectedCount = (int)$connected->fetchColumn();
        $answered = $pdo->prepare("SELECT COUNT(DISTINCT r.student_id)
            FROM quiz_live_responses r
            JOIN quiz_live_participants p ON p.session_id=r.session_id AND p.student_id=r.student_id
            WHERE r.session_id=? AND r.question_id=?
              AND p.status IN ('connected','active') AND p.last_seen_at>=DATE_SUB(NOW(),INTERVAL 6 SECOND)");
        $answered->execute([$session['id'],$row['id']]);
        if ($connectedCount > 0 && (int)$answered->fetchColumn() >= $connectedCount) advance_live_quiz_question($pdo, $session);
        $pdo->commit();
    } catch (PDOException $error) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        if (unique_violation($error)) fail('You already answered this question.', 409);
        throw $error;
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $error;
    }
    return rpc_live_quiz_state(['target_session_id'=>$session['id']]);
}

function advance_live_quiz_question(PDO $pdo, array $session): void
{
    $questionStatement = $pdo->prepare('SELECT id FROM quiz_questions WHERE quiz_id=? ORDER BY position,created_at');
    $questionStatement->execute([$session['quiz_id']]);
    $questionIds = $questionStatement->fetchAll(PDO::FETCH_COLUMN);
    $currentIndex = array_search($session['current_question_id'], $questionIds, true);
    $nextQuestionId = is_int($currentIndex) ? ($questionIds[$currentIndex + 1] ?? null) : ($questionIds[0] ?? null);
    if ($nextQuestionId === null) {
        $pdo->prepare("UPDATE quiz_live_sessions SET status='completed',question_opened_at=NULL,ended_at=NOW() WHERE id=? AND status='active'")->execute([$session['id']]);
        $pdo->prepare("UPDATE quiz_live_participants SET status='submitted',completed_at=NOW() WHERE session_id=? AND status<>'disconnected'")->execute([$session['id']]);
        return;
    }
    $pdo->prepare("UPDATE quiz_live_sessions SET current_question_id=?,question_opened_at=NOW() WHERE id=? AND status='active'")->execute([$nextQuestionId,$session['id']]);
}

function auto_advance_expired_live_quiz(string $sessionId): void
{
    if ($sessionId === '') return;
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $statement = $pdo->prepare('SELECT * FROM quiz_live_sessions WHERE id=? FOR UPDATE');
        $statement->execute([$sessionId]);
        $session = $statement->fetch();
        if ($session && $session['status'] === 'active' && $session['current_question_id']) {
            $connected = $pdo->prepare("SELECT COUNT(*) FROM quiz_live_participants
                WHERE session_id=? AND status IN ('connected','active') AND last_seen_at>=DATE_SUB(NOW(),INTERVAL 6 SECOND)");
            $connected->execute([$session['id']]);
            $connectedCount = (int)$connected->fetchColumn();
            $answered = $pdo->prepare("SELECT COUNT(DISTINCT r.student_id)
                FROM quiz_live_responses r
                JOIN quiz_live_participants p ON p.session_id=r.session_id AND p.student_id=r.student_id
                WHERE r.session_id=? AND r.question_id=?
                  AND p.status IN ('connected','active') AND p.last_seen_at>=DATE_SUB(NOW(),INTERVAL 6 SECOND)");
            $answered->execute([$session['id'],$session['current_question_id']]);
            $allConnectedAnswered = $connectedCount > 0 && (int)$answered->fetchColumn() >= $connectedCount;
            $expired = $session['question_opened_at'] && (int)$session['question_time_seconds'] > 0
                && time() >= strtotime($session['question_opened_at']) + (int)$session['question_time_seconds'];
            if ($allConnectedAnswered || $expired) advance_live_quiz_question($pdo, $session);
        }
        $pdo->commit();
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $error;
    }
}

function function_action(array $request): never
{
    $name=(string)($request['name']??'');$body=is_array($request['body']??null)?$request['body']:[];
    match($name){
        'register-account'=>registration_disabled(),
        'activate-account'=>registration_disabled(),
        'sync-onecampus'=>sync_onecampus(),
        default=>fail('Unknown server function.',404),
    };
}

function registration_disabled(): never
{
    fail('LMS self-registration and LMS-side approval are disabled. Accounts and access are managed by the main ADFC OneCampus system.', 403);
}

function sync_onecampus(): never
{
    require_admin();
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $ids = $pdo->query('SELECT enrollment_id FROM enrollments ORDER BY enrollment_id')->fetchAll(PDO::FETCH_COLUMN);
        $publish = $pdo->prepare('CALL sp_publish_lms_enrollment_access(?)');
        foreach ($ids as $id) {
            $publish->execute([$id]);
            $publish->closeCursor();
        }
        $counts = [
            'users' => (int)$pdo->query('SELECT COUNT(*) FROM vw_lms_users')->fetchColumn(),
            'subjects' => (int)$pdo->query('SELECT COUNT(*) FROM vw_lms_subjects')->fetchColumn(),
            'classes' => (int)$pdo->query('SELECT COUNT(*) FROM vw_lms_classes')->fetchColumn(),
            'enrollments' => (int)$pdo->query("SELECT COUNT(*) FROM class_enrollments WHERE membership_status='Active'")->fetchColumn(),
        ];
        $pdo->commit();
        json_response(['message' => 'Shared OneCampus access was verified and republished.', 'source' => 'onecampus_database', 'counts' => $counts]);
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $error;
    }
}

function onecampus_database_payload(): array
{
    $source = onecampus_db();
    $roleSql = lms_role_sql();
    $users = $source->query("SELECT
        COALESCE(u.user_uid, CONCAT('USER-', u.user_id)) AS id,
        LOWER(u.email) AS email,
        u.full_name AS fullName,
        COALESCE(s.student_number, i.employee_number, u.username, u.user_uid, CONCAT('USER-', u.user_id)) AS schoolId,
        {$roleSql} AS role,
        CASE WHEN u.status = 'Active' THEN 'active' ELSE 'inactive' END AS status
      FROM users u
      LEFT JOIN students s ON s.student_id = u.student_id
      LEFT JOIN instructors i ON i.user_id = u.user_id
      WHERE u.email IS NOT NULL AND u.email <> ''
        AND ({$roleSql}) IS NOT NULL")->fetchAll();
    $subjects = $source->query("SELECT
        COALESCE(subject_uid, CONCAT('SUBJECT-', subject_id)) AS id,
        subject_code AS code,
        subject_title AS title,
        description
      FROM subjects
      WHERE status = 'Active'")->fetchAll();
    $classes = $source->query("SELECT
        COALESCE(c.class_uid, CONCAT('CLASS-', c.class_id)) AS id,
        COALESCE(s.subject_uid, CONCAT('SUBJECT-', s.subject_id)) AS subjectId,
        COALESCE(u.user_uid, CONCAT('USER-', u.user_id)) AS instructorId,
        COALESCE(c.section, c.class_code) AS section,
        p.academic_year AS schoolYear,
        CASE p.semester WHEN '1st' THEN 'First Semester' WHEN '2nd' THEN 'Second Semester' ELSE 'Summer' END AS semester,
        CASE WHEN LOWER(c.status) = 'active' THEN 'active' ELSE 'archived' END AS status
      FROM academic_classes c
      JOIN subjects s ON s.subject_id = c.subject_id
      JOIN academic_periods p ON p.period_id = c.period_id
      JOIN instructors i ON i.instructor_id = c.instructor_id
      JOIN users u ON u.user_id = i.user_id
      WHERE c.class_uid IS NOT NULL OR c.class_id IS NOT NULL")->fetchAll();
    $enrollments = $source->query("SELECT
        COALESCE(e.enrollment_uid, CONCAT('CLASS-ENROLLMENT-', e.enrollment_id)) AS id,
        COALESCE(c.class_uid, CONCAT('CLASS-', c.class_id)) AS classId,
        COALESCE(u.user_uid, CONCAT('USER-', u.user_id)) AS studentId,
        CASE e.membership_status WHEN 'Active' THEN 'enrolled' WHEN 'Completed' THEN 'completed' ELSE 'dropped' END AS status
      FROM class_enrollments e
      JOIN academic_classes c ON c.class_id = e.class_id
      JOIN students s ON s.student_id = e.student_id
      JOIN users u ON u.student_id = s.student_id")->fetchAll();
    return compact('users', 'subjects', 'classes', 'enrollments');
}

function storage_upload(array $request): never
{
    global $config;$bucket=(string)($request['bucket']??'');$path=clean_storage_path((string)($request['path']??''));if(!in_array($bucket,['materials','submissions','discussions','profiles'],true)||!isset($_FILES['file']))fail('Invalid upload.');
    $parts=explode('/',$path);$classId=$parts[0]??'';$user=require_active_user();if($bucket==='materials'&&!class_manage($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&($user['role']!=='student'||!class_access($classId,$user)||!str_contains('/'.$path.'/','/'.$user['id'].'/')))fail('Access denied.',403);if($bucket==='discussions'){if($user['role']==='admin'||!class_access($classId,$user))fail('Access denied.',403);$topicId=$parts[1]??'';$ownerId=$parts[2]??'';if(class_id_for_topic($topicId)!==$classId||$ownerId!==user_uid($user)||!discussion_is_joined($topicId,user_uid($user)))fail('Join this discussion before attaching a file.',403);}if($bucket==='profiles'&&($parts[0]??'')!==$user['id'])fail('You can only update your own profile picture.',403);
    $file=$_FILES['file'];if(($file['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK)fail('File upload failed.');$maxBytes=$bucket==='profiles'?5242880:10485760;if(($file['size']??0)>$maxBytes)fail($bucket==='profiles'?'Profile pictures must be 5 MB or smaller.':'Files must be 10 MB or smaller.');
    if($bucket==='profiles'){$mime=class_exists('finfo')?(new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']):null;$allowed=['image/jpeg'=>['jpg','jpeg'],'image/png'=>['png'],'image/webp'=>['webp'],'image/gif'=>['gif']];$extension=strtolower(pathinfo($path,PATHINFO_EXTENSION));if(!is_string($mime)||!isset($allowed[$mime])||!in_array($extension,$allowed[$mime],true))fail('Upload a valid JPG, PNG, WEBP, or GIF image.');}
    $target=$config['storage_path'].DIRECTORY_SEPARATOR.$bucket.DIRECTORY_SEPARATOR.str_replace('/',DIRECTORY_SEPARATOR,$path);if(in_array($bucket,['discussions','profiles'],true)&&is_file($target))fail('This upload path is already in use.',409);$dir=dirname($target);if(!is_dir($dir)&&!mkdir($dir,0775,true)&&!is_dir($dir))fail('Unable to create the upload directory.',500);if(!move_uploaded_file($file['tmp_name'],$target))fail('Unable to save the uploaded file.',500);
    if($bucket==='profiles'){$old=db()->prepare('SELECT avatar_path FROM user_profiles WHERE user_id=?');$old->execute([$user['id']]);$oldPath=$old->fetchColumn();db()->prepare('INSERT INTO user_profiles (user_id,avatar_path) VALUES (?,?) ON DUPLICATE KEY UPDATE avatar_path=VALUES(avatar_path),updated_at=CURRENT_TIMESTAMP')->execute([$user['id'],$path]);if(is_string($oldPath)&&$oldPath!==''&&$oldPath!==$path)remove_private_storage_file('profiles',$oldPath);lms_audit('update','profile_picture',$user['id'],'Updated profile picture',null,['avatar_path'=>$path],$user);}
    json_response(['path'=>$path]);
}

function storage_remove(array $request): never
{
    $bucket=(string)($request['bucket']??'');$paths=is_array($request['paths']??null)?$request['paths']:[];$user=require_active_user();if(!in_array($bucket,['materials','submissions','discussions','profiles'],true))fail('Invalid storage bucket.');foreach($paths as $raw){$path=clean_storage_path((string)$raw);$parts=explode('/',$path);$classId=$parts[0]??'';if($bucket==='materials'&&!class_manage($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&!class_manage($classId,$user)&&($user['role']!=='student'||!str_contains('/'.$path.'/','/'.$user['id'].'/')))fail('Access denied.',403);if($bucket==='discussions'){if(($parts[2]??'')!==user_uid($user)||class_id_for_topic($parts[1]??'')!==$classId)fail('Access denied.',403);$linked=db()->prepare('SELECT 1 FROM learning_discussion_posts WHERE attachment_path=? AND is_deleted=0 UNION ALL SELECT 1 FROM discussion_live_events WHERE attachment_path=? LIMIT 1');$linked->execute([$path,$path]);if($linked->fetchColumn())fail('Sent discussion attachments cannot be removed.',409);}if($bucket==='profiles'){if(($parts[0]??'')!==$user['id'])fail('You can only remove your own profile picture.',403);$linked=db()->prepare('SELECT avatar_path FROM user_profiles WHERE user_id=?');$linked->execute([$user['id']]);if($linked->fetchColumn()!==$path)fail('This profile picture is no longer active.',409);db()->prepare('UPDATE user_profiles SET avatar_path=NULL WHERE user_id=?')->execute([$user['id']]);lms_audit('update','profile_picture',$user['id'],'Removed profile picture',['avatar_path'=>$path],['avatar_path'=>null],$user);}remove_private_storage_file($bucket,$path);}json_response([]);
}

function storage_signed_url(array $request): never
{
    global $config;$bucket=(string)($request['bucket']??'');$path=clean_storage_path((string)($request['path']??''));$disposition=(string)($request['disposition']??'download');if(!in_array($bucket,['materials','submissions','discussions','profiles'],true)||!in_array($disposition,['preview','download'],true))fail('Invalid file request.');$expires=time()+min(300,max(10,(int)($request['expiresIn']??60)));$parts=explode('/',$path);$classId=$parts[0]??'';$user=require_active_user();if($bucket==='profiles'){if($disposition!=='preview')fail('Profile pictures can only be viewed.',403);$linked=db()->prepare("SELECT 1 FROM user_profiles up JOIN users u ON u.user_id=up.user_id WHERE up.avatar_path=? AND u.status='Active'");$linked->execute([$path]);if(!$linked->fetchColumn())fail('Profile picture not found.',404);}else{if(!class_access($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&!class_report_access($classId,$user)&&!str_contains('/'.$path.'/','/'.$user['id'].'/'))fail('Access denied.',403);if($bucket==='discussions'&&$user['role']!=='admin'&&(class_id_for_topic($parts[1]??'')!==$classId||!discussion_is_joined($parts[1]??'',user_uid($user))))fail('Access denied.',403);}$token=hash_hmac('sha256',"$bucket|$path|$expires|$disposition",session_id());$url=$config['app_url'].'/api/index.php?action=storage.download&bucket='.rawurlencode($bucket).'&path='.rawurlencode($path).'&expires='.$expires.'&disposition='.$disposition.'&token='.$token;json_response(['signedUrl'=>$url]);
}

function download_file(): never
{
    global $config;$bucket=(string)($_GET['bucket']??'');$path=clean_storage_path((string)($_GET['path']??''));$expires=(int)($_GET['expires']??0);$disposition=(string)($_GET['disposition']??'download');$token=(string)($_GET['token']??'');if(!in_array($bucket,['materials','submissions','discussions','profiles'],true)||!in_array($disposition,['preview','download'],true)||$expires<time()||!hash_equals(hash_hmac('sha256',"$bucket|$path|$expires|$disposition",session_id()),$token))fail('This file link is invalid or expired.',403);$user=require_active_user();$parts=explode('/',$path);$classId=$parts[0]??'';if($bucket==='profiles'){$linked=db()->prepare("SELECT 1 FROM user_profiles up JOIN users u ON u.user_id=up.user_id WHERE up.avatar_path=? AND u.status='Active'");$linked->execute([$path]);if(!$linked->fetchColumn()||$disposition!=='preview')fail('Access denied.',403);}else{if(!class_access($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&!class_report_access($classId,$user)&&!str_contains('/'.$path.'/','/'.$user['id'].'/'))fail('Access denied.',403);if($bucket==='discussions'&&$user['role']!=='admin'&&(class_id_for_topic($parts[1]??'')!==$classId||!discussion_is_joined($parts[1]??'',user_uid($user))))fail('Access denied.',403);}$file=$config['storage_path'].DIRECTORY_SEPARATOR.$bucket.DIRECTORY_SEPARATOR.str_replace('/',DIRECTORY_SEPARATOR,$path);if(!is_file($file))fail('File not found.',404);$ext=strtolower(pathinfo($file,PATHINFO_EXTENSION));
    if ($disposition==='preview') {
        if ($ext==='docx') render_docx_preview($file,basename($file));
        if (in_array($ext,['pptx','xlsx'],true)) render_openxml_preview($file,basename($file),$ext);
        $nativeTypes=['pdf'=>'application/pdf','png'=>'image/png','jpg'=>'image/jpeg','jpeg'=>'image/jpeg','jfif'=>'image/jpeg','jif'=>'image/jpeg','jfi'=>'image/jpeg','gif'=>'image/gif','webp'=>'image/webp','bmp'=>'image/bmp','mp3'=>'audio/mpeg','wav'=>'audio/wav','ogg'=>'audio/ogg','oga'=>'audio/ogg','m4a'=>'audio/mp4','aac'=>'audio/aac','flac'=>'audio/flac','weba'=>'audio/webm','mp4'=>'video/mp4','webm'=>'video/webm','ogv'=>'video/ogg','mov'=>'video/quicktime','m4v'=>'video/x-m4v'];
        if (isset($nativeTypes[$ext])) { header('Content-Type: '.$nativeTypes[$ext]);header('Content-Disposition: inline; filename="'.basename($file).'"');header('X-Content-Type-Options: nosniff');header('Content-Length: '.filesize($file));readfile($file);exit; }
        render_universal_file_preview($file,basename($file),$ext);
    }
    header('Content-Type: application/octet-stream');header('Content-Disposition: attachment; filename="'.basename($file).'"');header('X-Content-Type-Options: nosniff');header('Content-Length: '.filesize($file));readfile($file);exit;
}

function render_openxml_preview(string $file, string $name, string $extension): never
{
    if (!class_exists('ZipArchive') || !class_exists('DOMDocument')) render_document_preview_error($name, 'This preview requires the PHP ZIP and DOM extensions.');
    $zip = new ZipArchive();
    if ($zip->open($file) !== true) render_document_preview_error($name, 'This Office file could not be opened. It may be damaged or password-protected.');
    $sections = [];
    if ($extension === 'pptx') {
        $entries = [];
        for ($index=0;$index<$zip->numFiles;$index++) { $entry=$zip->getNameIndex($index);if(is_string($entry)&&preg_match('#^ppt/slides/slide(\d+)\.xml$#',$entry,$match))$entries[(int)$match[1]]=$entry; }
        ksort($entries);
        foreach ($entries as $number=>$entry) { $text=openxml_text($zip->getFromName($entry));$sections[]=['title'=>'Slide '.$number,'content'=>$text!==''?$text:'No displayable text on this slide.']; }
    } else {
        $shared = [];$sharedXml=$zip->getFromName('xl/sharedStrings.xml');
        if (is_string($sharedXml)) $shared=openxml_shared_strings($sharedXml);
        $entries = [];
        for ($index=0;$index<$zip->numFiles;$index++) { $entry=$zip->getNameIndex($index);if(is_string($entry)&&preg_match('#^xl/worksheets/sheet(\d+)\.xml$#',$entry,$match))$entries[(int)$match[1]]=$entry; }
        ksort($entries);
        foreach ($entries as $number=>$entry) { $xml=$zip->getFromName($entry);$sections[]=['title'=>'Worksheet '.$number,'content'=>is_string($xml)?xlsx_sheet_text($xml,$shared):'']; }
    }
    $zip->close();
    if ($sections===[]) $sections[]=['title'=>'Document','content'=>'No displayable text was found in this file.'];
    render_safe_preview_page($name,strtoupper($extension).' preview',$sections);
}

function openxml_document(string $xml): ?array
{
    $previous=libxml_use_internal_errors(true);$document=new DOMDocument();$loaded=$document->loadXML($xml,LIBXML_NONET|LIBXML_COMPACT);libxml_clear_errors();libxml_use_internal_errors($previous);return $loaded?[$document,new DOMXPath($document)]:null;
}

function openxml_text(string|false $xml): string
{
    if (!is_string($xml)||$xml==='') return '';$parsed=openxml_document($xml);if($parsed===null)return '';
    [, $xpath]=$parsed;$parts=[];foreach($xpath->query('//*[local-name()="t"]') as $node){$value=trim($node->textContent);if($value!=='')$parts[]=$value;}return implode("\n",$parts);
}

function openxml_shared_strings(string $xml): array
{
    $parsed=openxml_document($xml);if($parsed===null)return [];
    [, $xpath]=$parsed;$values=[];foreach($xpath->query('//*[local-name()="si"]') as $item){$parts=[];foreach($xpath->query('.//*[local-name()="t"]',$item) as $text)$parts[]=$text->textContent;$values[]=implode('',$parts);}return $values;
}

function xlsx_sheet_text(string $xml, array $shared): string
{
    $parsed=openxml_document($xml);if($parsed===null)return 'This worksheet could not be read.';
    [, $xpath]=$parsed;$lines=[];foreach($xpath->query('//*[local-name()="row"]') as $row){$cells=[];foreach($xpath->query('./*[local-name()="c"]',$row) as $cell){$type=$cell->attributes?->getNamedItem('t')?->nodeValue;$value=$xpath->evaluate('string(*[local-name()="v"])',$cell);if($type==='s'&&isset($shared[(int)$value]))$value=$shared[(int)$value];elseif($type==='inlineStr')$value=$xpath->evaluate('string(*[local-name()="is"]//*[local-name()="t"])',$cell);$cells[]=trim((string)$value);}if($cells!==[])$lines[]=implode("\t",$cells);}return $lines===[]?'No displayable cell values were found.':implode("\n",$lines);
}

function render_universal_file_preview(string $file, string $name, string $extension): never
{
    $size=filesize($file);$mime=class_exists('finfo')?(new finfo(FILEINFO_MIME_TYPE))->file($file):null;$mime=is_string($mime)&&$mime!==''?$mime:'application/octet-stream';
    $sample=file_get_contents($file,false,null,0,min(131072,max(0,(int)$size)));$sample=is_string($sample)?$sample:'';
    $textExtensions=['txt','text','md','markdown','csv','tsv','json','jsonl','xml','yaml','yml','log','ini','conf','cfg','sql','html','htm','css','scss','less','js','jsx','ts','tsx','php','py','java','c','h','cpp','hpp','cs','go','rs','rb','sh','bat','cmd','ps1','env','properties','toml','rtf'];
    $isText=str_starts_with($mime,'text/')||in_array($extension,$textExtensions,true)||($sample!==''&&preg_match('//u',$sample)===1&&substr_count($sample,"\0")===0);
    if($isText){$content=$sample;if($size!==false&&$size>strlen($sample))$content.="\n\n[Preview truncated after ".number_format(strlen($sample))." bytes.]";render_safe_preview_page($name,'Text preview',[['title'=>'File contents','content'=>$content]],['Type'=>$mime,'Size'=>preview_file_size($size)]);}
    if(in_array($extension,['zip','jar','apk','epub','odt','ods','odp'],true)&&class_exists('ZipArchive')){$zip=new ZipArchive();if($zip->open($file)===true){$lines=[];$limit=min($zip->numFiles,1000);for($index=0;$index<$limit;$index++){$stat=$zip->statIndex($index);if(is_array($stat))$lines[]=($stat['name']??'Unknown entry')."\t".preview_file_size($stat['size']??0);}if($zip->numFiles>$limit)$lines[]='… '.number_format($zip->numFiles-$limit).' more entries';$zip->close();render_safe_preview_page($name,'Archive preview',[['title'=>'Archive contents','content'=>implode("\n",$lines)]],['Type'=>$mime,'Size'=>preview_file_size($size)]);}}
    $lines=[];foreach(str_split(substr($sample,0,65536),16) as $offset=>$chunk){$hex=implode(' ',str_split(bin2hex($chunk),2));$ascii=preg_replace('/[^\x20-\x7E]/','.',$chunk);$lines[]=sprintf('%08X  %-47s  |%s|',$offset*16,$hex,$ascii);}
    render_safe_preview_page($name,'Universal binary preview',[['title'=>'File data (first 64 KB)','content'=>$lines===[]?'This file is empty.':implode("\n",$lines)]],['Type'=>$mime,'Extension'=>$extension!==''?strtoupper($extension):'None','Size'=>preview_file_size($size),'SHA-256'=>hash_file('sha256',$file)?:'Unavailable']);
}

function preview_file_size(int|false $bytes): string
{
    if($bytes===false)return 'Unknown';$units=['B','KB','MB','GB'];$value=(float)$bytes;$unit=0;while($value>=1024&&$unit<count($units)-1){$value/=1024;$unit++;}return number_format($value,$unit===0?0:2).' '.$units[$unit];
}

function render_safe_preview_page(string $name, string $label, array $sections, array $metadata=[]): never
{
    $safeName=htmlspecialchars($name,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');$safeLabel=htmlspecialchars($label,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');$meta='';foreach($metadata as $key=>$value)$meta.='<div><dt>'.htmlspecialchars((string)$key,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8').'</dt><dd>'.htmlspecialchars((string)$value,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8').'</dd></div>';$content='';foreach($sections as $section)$content.='<section><h2>'.htmlspecialchars((string)($section['title']??'Preview'),ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8').'</h2><pre>'.htmlspecialchars((string)($section['content']??''),ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8').'</pre></section>';
    header('Content-Type: text/html; charset=utf-8');header('Content-Disposition: inline; filename="'.addcslashes($name,'"\\').'.html"');header('X-Content-Type-Options: nosniff');header("Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'self'");
    echo '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'.$safeName.'</title><style>html{background:#e2e8f0}body{box-sizing:border-box;max-width:1100px;min-height:calc(100vh - 32px);margin:16px auto;padding:36px;background:#fff;color:#0f172a;font:14px/1.55 Inter,Arial,sans-serif;box-shadow:0 6px 24px #0f172a24}header{padding-bottom:22px;border-bottom:1px solid #e2e8f0}header p{margin:0;color:#1d4ed8;font-size:12px;font-weight:800;text-transform:uppercase;letter-spacing:.12em}h1{margin:6px 0 0;overflow-wrap:anywhere;font-size:1.5rem}dl{display:flex;flex-wrap:wrap;gap:10px;margin:18px 0 0}dl div{min-width:130px;padding:10px 12px;border-radius:10px;background:#f8fafc}dt{color:#64748b;font-size:11px;font-weight:800;text-transform:uppercase}dd{margin:3px 0 0;overflow-wrap:anywhere;font-weight:700}section{margin-top:24px}h2{font-size:1rem}pre{overflow:auto;margin:10px 0 0;padding:18px;border:1px solid #e2e8f0;border-radius:12px;background:#f8fafc;white-space:pre-wrap;overflow-wrap:anywhere;font:13px/1.55 Consolas,"Courier New",monospace}@media(max-width:700px){body{min-height:100vh;margin:0;padding:22px;box-shadow:none}}</style></head><body><header><p>'.$safeLabel.'</p><h1>'.$safeName.'</h1>'.($meta!==''?'<dl>'.$meta.'</dl>':'').'</header><main>'.$content.'</main></body></html>';exit;
}

function render_docx_preview(string $file, string $name): never
{
    if (!class_exists('ZipArchive') || !class_exists('DOMDocument')) {
        render_document_preview_error($name, 'DOCX preview requires the PHP ZIP and DOM extensions. Enable them in XAMPP, then restart Apache.');
    }
    $zip = new ZipArchive();
    if ($zip->open($file) !== true) render_document_preview_error($name, 'This DOCX file could not be opened. It may be damaged or use an unsupported format.');
    $xml = $zip->getFromName('word/document.xml');
    $relationshipsXml = $zip->getFromName('word/_rels/document.xml.rels');
    if (!is_string($xml) || $xml === '') render_document_preview_error($name, 'This DOCX file does not contain a readable document body.');

    $previous = libxml_use_internal_errors(true);
    $document = new DOMDocument();
    $loaded = $document->loadXML($xml, LIBXML_NONET | LIBXML_COMPACT);
    libxml_clear_errors();
    libxml_use_internal_errors($previous);
    if (!$loaded) render_document_preview_error($name, 'This DOCX file contains invalid document data.');

    $xpath = new DOMXPath($document);
    $body = $xpath->query('//*[local-name()="body"]')->item(0);
    if (!$body) render_document_preview_error($name, 'This DOCX file does not contain a readable document body.');

    $content = '';
    foreach ($body->childNodes as $node) {
        if ($node->localName === 'p') $content .= docx_paragraph_html($node, $xpath);
        elseif ($node->localName === 'tbl') $content .= docx_table_html($node, $xpath);
    }
    $content .= docx_embedded_images_html($zip, is_string($relationshipsXml) ? $relationshipsXml : '');
    $zip->close();
    if (trim(strip_tags($content)) === '' && !str_contains($content, '<img')) $content = '<p class="empty">No displayable text or images were found in this document.</p>';

    $safeName = htmlspecialchars($name, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    header('Content-Type: text/html; charset=utf-8');
    header('Content-Disposition: inline; filename="' . addcslashes($name, '"\\') . '.html"');
    header('X-Content-Type-Options: nosniff');
    header("Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; img-src data:; base-uri 'none'; form-action 'none'; frame-ancestors 'self'");
    echo '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' . $safeName . '</title><style>'
        . 'html{background:#e2e8f0}body{box-sizing:border-box;max-width:900px;min-height:calc(100vh - 32px);margin:16px auto;padding:64px 72px;background:#fff;color:#0f172a;font:16px/1.65 Georgia,"Times New Roman",serif;box-shadow:0 6px 24px rgba(15,23,42,.14)}p{margin:0 0 1em;white-space:pre-wrap;overflow-wrap:anywhere}h1,h2,h3{font-family:Inter,Arial,sans-serif;line-height:1.25;margin:1.2em 0 .55em}h1{font-size:2rem}h2{font-size:1.55rem}h3{font-size:1.25rem}table{width:100%;margin:1.25em 0;border-collapse:collapse}td{border:1px solid #94a3b8;padding:.55em;vertical-align:top}.docx-images{display:grid;gap:1.25rem}.docx-images img{display:block;max-width:100%;height:auto;margin:0 auto}.empty{text-align:center;color:#64748b;font-family:Inter,Arial,sans-serif}@media(max-width:700px){body{min-height:100vh;margin:0;padding:28px 22px;box-shadow:none}}'
        . '</style></head><body><main aria-label="Preview of ' . $safeName . '">' . $content . '</main></body></html>';
    exit;
}

function docx_paragraph_html(DOMNode $paragraph, DOMXPath $xpath): string
{
    $style = (string)($xpath->evaluate('string(*[local-name()="pPr"]/*[local-name()="pStyle"]/@*[local-name()="val"])', $paragraph) ?: '');
    $tag = match (strtolower($style)) {
        'title', 'heading1' => 'h1',
        'subtitle', 'heading2' => 'h2',
        'heading3' => 'h3',
        default => 'p',
    };
    $html = '';
    foreach ($xpath->query('.//*[local-name()="r"]', $paragraph) as $run) {
        $text = '';
        foreach ($run->childNodes as $child) {
            if ($child->localName === 't') $text .= $child->textContent;
            elseif ($child->localName === 'tab') $text .= "\t";
            elseif (in_array($child->localName, ['br','cr'], true)) $text .= "\n";
        }
        if ($text === '') continue;
        $safe = htmlspecialchars($text, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
        if ($xpath->evaluate('boolean(*[local-name()="rPr"]/*[local-name()="b"])', $run)) $safe = '<strong>' . $safe . '</strong>';
        if ($xpath->evaluate('boolean(*[local-name()="rPr"]/*[local-name()="i"])', $run)) $safe = '<em>' . $safe . '</em>';
        if ($xpath->evaluate('boolean(*[local-name()="rPr"]/*[local-name()="u"])', $run)) $safe = '<u>' . $safe . '</u>';
        $html .= $safe;
    }
    return '<' . $tag . '>' . ($html !== '' ? $html : '&nbsp;') . '</' . $tag . '>';
}

function docx_table_html(DOMNode $table, DOMXPath $xpath): string
{
    $html = '<table><tbody>';
    foreach ($xpath->query('./*[local-name()="tr"]', $table) as $row) {
        $html .= '<tr>';
        foreach ($xpath->query('./*[local-name()="tc"]', $row) as $cell) {
            $cellHtml = '';
            foreach ($xpath->query('./*[local-name()="p"]', $cell) as $paragraph) $cellHtml .= docx_paragraph_html($paragraph, $xpath);
            $html .= '<td>' . ($cellHtml !== '' ? $cellHtml : '&nbsp;') . '</td>';
        }
        $html .= '</tr>';
    }
    return $html . '</tbody></table>';
}

function docx_embedded_images_html(ZipArchive $zip, string $relationshipsXml): string
{
    if ($relationshipsXml === '') return '';
    $previous = libxml_use_internal_errors(true);
    $relationships = new DOMDocument();
    $loaded = $relationships->loadXML($relationshipsXml, LIBXML_NONET | LIBXML_COMPACT);
    libxml_clear_errors();
    libxml_use_internal_errors($previous);
    if (!$loaded) return '';
    $html = '';
    $relationshipXPath = new DOMXPath($relationships);
    foreach ($relationshipXPath->query('//*[local-name()="Relationship"]') as $relationship) {
        if (!str_ends_with((string)$relationship->getAttribute('Type'), '/image')) continue;
        if (strcasecmp((string)$relationship->getAttribute('TargetMode'), 'External') === 0) continue;
        $target = str_replace('\\', '/', (string)$relationship->getAttribute('Target'));
        while (str_starts_with($target, '../')) $target = substr($target, 3);
        $entry = str_starts_with($target, 'word/') ? $target : 'word/' . ltrim($target, '/');
        if (!str_starts_with($entry, 'word/media/')) continue;
        $data = $zip->getFromName($entry);
        if (!is_string($data) || $data === '' || strlen($data) > 10 * 1024 * 1024) continue;
        $extension = strtolower(pathinfo($entry, PATHINFO_EXTENSION));
        $mime = match ($extension) {
            'png' => 'image/png',
            'jpg', 'jpeg', 'jfif' => 'image/jpeg',
            'gif' => 'image/gif',
            'webp' => 'image/webp',
            'bmp' => 'image/bmp',
            default => null,
        };
        if ($mime !== null) $html .= '<img src="data:' . $mime . ';base64,' . base64_encode($data) . '" alt="Embedded document image">';
    }
    return $html === '' ? '' : '<div class="docx-images">' . $html . '</div>';
}

function render_document_preview_error(string $name, string $message): never
{
    $safeName = htmlspecialchars($name, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    $safeMessage = htmlspecialchars($message, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    header('Content-Type: text/html; charset=utf-8');
    header('Content-Security-Policy: default-src \'none\'; style-src \'unsafe-inline\'; base-uri \'none\'; form-action \'none\'; frame-ancestors \'self\'');
    header('X-Content-Type-Options: nosniff');
    echo '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' . $safeName . '</title><style>body{display:grid;min-height:100vh;margin:0;place-items:center;background:#fff;color:#0f172a;font-family:Inter,Arial,sans-serif}.message{max-width:540px;padding:32px;text-align:center}.message h1{font-size:1.25rem}.message p{color:#64748b;line-height:1.6}</style></head><body><div class="message"><h1>Unable to preview this DOCX file</h1><p>' . $safeMessage . '</p></div></body></html>';
    exit;
}

function clean_storage_path(string $path): string
{
    $path=str_replace('\\','/',trim($path,'/'));if($path===''||str_contains($path,'..')||!preg_match('#^[A-Za-z0-9._/-]+$#',$path))fail('Invalid storage path.');return $path;
}