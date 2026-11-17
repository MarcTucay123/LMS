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
    $roleSql = lms_role_sql();
    $stmt = db()->prepare("SELECT CAST(u.user_id AS CHAR) id,LOWER(u.email) email,u.password_hash,{$roleSql} requested_role
        FROM users u
        LEFT JOIN instructors i ON i.user_id=u.user_id
        LEFT JOIN students s ON s.student_id=u.student_id
        WHERE u.status='Active' AND (LOWER(u.username)=? OR LOWER(u.email)=?) LIMIT 1");
    $stmt->execute([$login, $login]);
    $user = $stmt->fetch();
    if (!$user || !password_verify($password, $user['password_hash'])) fail('Invalid login credentials', 401);
    if (!$user['requested_role']) fail('This account has not been granted access to the LMS.', 403);
    session_regenerate_id(true);
    $_SESSION['user_id'] = $user['id'];
    $payload = user_payload($user);
    json_response(['user' => $payload, 'session' => ['user' => $payload]]);
}

function auth_logout(): never
{
    unset($_SESSION['user_id']);
    session_regenerate_id(true);
    json_response([]);
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
    $userId = current_user_id();
    if (!$userId && $token !== '') {
        $stmt = db()->prepare('SELECT user_id FROM users WHERE reset_token_hash=? AND reset_expires_at>NOW()');
        $stmt->execute([hash('sha256', $token)]);
        $userId = $stmt->fetchColumn() ?: null;
    }
    if (!$userId) fail('This reset link is invalid or has expired.', 401);
    $stmt = db()->prepare('UPDATE users SET password_hash=?, reset_token_hash=NULL, reset_expires_at=NULL, session_version=session_version+1 WHERE user_id=?');
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
        'discussion_topics' => select_topics($filters, $orders),
        'discussion_posts' => select_posts($filters, $orders),
        'submissions' => select_submissions($filters, $orders),
        'quiz_questions' => select_questions($filters, $orders),
        'quiz_attempts' => select_attempts($filters),
        default => fail('This table is not available through the API.', 404),
    };
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
        CASE WHEN u.status='Active' THEN 'active' ELSE 'inactive' END status,u.created_at,u.updated_at
        FROM users u LEFT JOIN students s ON s.student_id=u.student_id LEFT JOIN instructors i ON i.user_id=u.user_id
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
        JSON_OBJECT('full_name',COALESCE(u.full_name,'Not assigned')) instructor
        FROM academic_classes c JOIN subjects s ON s.subject_id=c.subject_id JOIN academic_periods ap ON ap.period_id=c.period_id
        LEFT JOIN instructors i ON i.instructor_id=c.instructor_id LEFT JOIN users u ON u.user_id=i.user_id WHERE 1=1";
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
    $scheduleStmt = db()->prepare("SELECT cm.class_type,cm.day_of_week,
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
            'school_id',s.student_number
        ) student
        FROM academic_classes c
        JOIN blocks b ON b.block_code=c.section
        JOIN enrollments e ON e.period_id=c.period_id AND e.block_id=b.block_id AND e.enrollment_status='Confirmed'
        JOIN enrollment_subjects es ON es.enrollment_id=e.enrollment_id AND es.subject_id=c.subject_id AND es.subject_status='Enrolled'
        JOIN students s ON s.student_id=e.student_id
        LEFT JOIN users u ON u.student_id=s.student_id
        WHERE c.class_uid=?";
    $params = [$classId];
    $status = filter_value($filters, 'status'); if ($status !== null && $status !== 'enrolled') return [];
    if ($user['role'] === 'student') { $sql .= ' AND e.student_id=?'; $params[] = $user['student_id']; }
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
    $classId = (string)(filter_value($filters, 'class_id') ?? ''); require_class_access($classId);
    $sql = 'SELECT t.*, JSON_OBJECT("full_name",u.full_name) author FROM learning_discussion_topics t JOIN users u ON u.user_uid=t.created_by WHERE t.class_id=?' . qualified_order_clause($orders, ['created_at'], 't', 't.created_at DESC');
    $rows = fetch_all($sql, [$classId], 'discussion_topics'); foreach ($rows as &$row) $row['author'] = json_decode($row['author'], true); return $rows;
}

function select_posts(array $filters, array $orders): array
{
    $topicId = (string)(filter_value($filters, 'topic_id') ?? '');
    $stmt = db()->prepare('SELECT class_id FROM learning_discussion_topics WHERE id=?'); $stmt->execute([$topicId]);
    $classId = $stmt->fetchColumn(); if (!$classId) return []; require_class_access($classId);
    $sql = 'SELECT d.*, JSON_OBJECT("full_name",u.full_name) author FROM learning_discussion_posts d JOIN users u ON u.user_uid=d.author_id WHERE d.topic_id=?' . qualified_order_clause($orders, ['created_at'], 'd', 'd.created_at ASC');
    $rows = fetch_all($sql, [$topicId], 'discussion_posts'); foreach ($rows as &$row) $row['author'] = json_decode($row['author'], true); return $rows;
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
    $sql = "SELECT s.*,CAST(u.user_id AS CHAR) student_id,JSON_OBJECT('full_name',u.full_name,'school_id',st.student_number) student
        FROM assignment_submissions s JOIN students st ON st.student_id=s.student_id JOIN users u ON u.student_id=st.student_id
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
        'discussion_posts' => ['topic_id','body'],
        'assignments' => ['class_id','title','instructions','due_at','points','status'],
        'quizzes' => ['class_id','title','description','assessment_kind','exam_type','opens_at','closes_at','time_limit_minutes','status'],
        'quiz_questions' => ['quiz_id','prompt','question_type','options','points','position'],
        'quiz_answer_keys' => ['question_id','correct_answer','case_sensitive'],
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

    $row = ['id' => uuid()];
    foreach ($allowed[$table] as $column) if (array_key_exists($column, $values)) $row[$column] = normalize_write_value($column, $values[$column]);
    if (in_array($table, ['materials','discussion_topics','assignments','quizzes'], true)) $row['created_by'] = user_uid($user);
    if ($table === 'discussion_posts') $row['author_id'] = user_uid($user);
    if (!isset($row['id'])) $row['id'] = uuid();
    if ($table === 'quiz_answer_keys') { unset($row['id']); }
    validate_insert_row($table, $row);
    if ($table === 'quizzes') validate_assessment_fields($row);

    $physicalTable = content_table($table);
    $columns = array_keys($row);
    $sql = "INSERT INTO `$physicalTable` (`" . implode('`,`', $columns) . '`) VALUES (' . implode(',', array_fill(0, count($columns), '?')) . ')';
    db()->prepare($sql)->execute(array_values($row));
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

function insert_class_id(string $table, array $values): string
{
    if (isset($values['class_id'])) return (string)$values['class_id'];
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
    if (in_array($column, ['is_locked','case_sensitive'], true)) return $value ? 1 : 0;
    return $value;
}

function validate_insert_row(string $table, array $row): void
{
    $required = [
        'materials' => ['class_id','title'], 'announcements' => ['class_id','title','body'],
        'discussion_topics' => ['class_id','title','body'], 'discussion_posts' => ['topic_id','body'],
        'assignments' => ['class_id','title','instructions','points','status'], 'quizzes' => ['class_id','title','status'],
        'quiz_questions' => ['quiz_id','prompt','question_type','options','points','position'],
        'quiz_answer_keys' => ['question_id','correct_answer'],
    ];
    foreach ($required[$table] ?? [] as $column) if (!isset($row[$column]) || $row[$column] === '') fail('Complete all required fields.');
    if ($table === 'materials' && empty($row['file_path']) && empty($row['external_url'])) fail('A file or external URL is required.');
}

function validate_assessment_fields(array $values): void
{
    $kind = (string)($values['assessment_kind'] ?? 'quiz');
    if (!in_array($kind, ['quiz','exam'], true)) fail('Invalid assessment type.');
    $examType = trim((string)($values['exam_type'] ?? ''));
    if ($kind === 'exam' && $examType === '') fail('Select or enter an exam type.');
    if (mb_strlen($examType) > 100) fail('Exam type must not exceed 100 characters.');
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
    $allowed = ['quizzes' => ['title','description','assessment_kind','exam_type','opens_at','closes_at','time_limit_minutes','status']];
    if (!isset($allowed[$table])) fail('Update is not allowed for this table.', 403);
    $classId = class_id_for_record($table, $id); if (!$classId) fail('Record not found.', 404); require_class_manager($classId);
    if ($table === 'quizzes') {
        if (array_key_exists('title', $values) && trim((string)$values['title']) === '') fail('Enter an assessment title.');
        if (array_key_exists('status', $values) && !in_array($values['status'], ['draft','published','closed'], true)) fail('Invalid quiz status.');
        if (array_key_exists('time_limit_minutes', $values) && $values['time_limit_minutes'] !== null && (!is_numeric($values['time_limit_minutes']) || (int)$values['time_limit_minutes'] < 1)) fail('Time limit must be at least one minute.');
        $opensAt = normalize_write_value('opens_at', $values['opens_at'] ?? null);
        $closesAt = normalize_write_value('closes_at', $values['closes_at'] ?? null);
        if ($opensAt !== null && $closesAt !== null && strtotime($closesAt) <= strtotime($opensAt)) fail('Closing date must be after the opening date.');
        $existingStatement = db()->prepare('SELECT * FROM quizzes WHERE id=?'); $existingStatement->execute([$id]); $existing = $existingStatement->fetch() ?: [];
        validate_assessment_fields(array_merge($existing, $values));
    }
    $sets = []; $params = [];
    foreach ($allowed[$table] as $column) if (array_key_exists($column, $values)) { $sets[] = "`$column`=?"; $params[] = normalize_write_value($column, $values[$column]); }
    if (!$sets) fail('No supported values were supplied.');
    $physicalTable = content_table($table);
    $beforeStatement = db()->prepare("SELECT * FROM `$physicalTable` WHERE id=?"); $beforeStatement->execute([$id]); $before = $beforeStatement->fetch() ?: [];
    $params[] = $id; db()->prepare("UPDATE `$physicalTable` SET " . implode(',', $sets) . ' WHERE id=?')->execute($params);
    $stmt = db()->prepare("SELECT * FROM `$physicalTable` WHERE id=?"); $stmt->execute([$id]);
    $updated = normalize_row($table, $stmt->fetch() ?: []);
    lms_audit('update', $table, $id, 'Updated ' . audit_record_label($table, $updated), normalize_row($table, $before), $updated);
    return $updated;
}

function query_delete(string $table, array $filters): array
{
    $id = (string)(filter_value($filters, 'id') ?? ''); if ($id === '') fail('An ID filter is required.');
    $allowed = ['materials','announcements','discussion_topics','assignments','quizzes','quiz_questions'];
    if (!in_array($table, $allowed, true)) fail('Delete is not allowed for this table.', 403);
    $classId = class_id_for_record($table, $id); if (!$classId) return [];
    $user = require_active_user();
    if ($table === 'discussion_topics') {
        if ($user['role'] === 'admin') fail('Administrators have read-only discussion access.', 403);
        $stmt = db()->prepare('SELECT created_by FROM learning_discussion_topics WHERE id=?'); $stmt->execute([$id]);
        if ($stmt->fetchColumn() !== user_uid($user) && !class_manage($classId, $user)) fail('Access denied.', 403);
    } elseif (!class_manage($classId, $user)) fail('Access denied.', 403);
    $labelStatement = db()->prepare($table === 'announcements' ? "SELECT title FROM announcements WHERE announcement_id=? AND module_code='lms'" : "SELECT * FROM `" . content_table($table) . "` WHERE id=?");
    $labelStatement->execute([$id]); $deleted = $labelStatement->fetch() ?: [];
    if ($table === 'announcements') db()->prepare("DELETE FROM announcements WHERE announcement_id=? AND module_code='lms'")->execute([$id]);
    else {
        $physicalTable = content_table($table);
        db()->prepare("DELETE FROM `$physicalTable` WHERE id=?")->execute([$id]);
    }
    lms_audit('delete', $table, $id, 'Deleted ' . audit_record_label($table, $deleted), normalize_row($table, $deleted), null, $user);
    return [];
}

function rpc_action(array $request): never
{
    $name = (string)($request['name'] ?? ''); $args = is_array($request['args'] ?? null) ? $request['args'] : [];
    $data = match ($name) {
        'admin_update_user' => rpc_admin_update_user($args),
        'submit_assignment' => rpc_submit_assignment($args),
        'grade_submission' => rpc_grade_submission($args),
        'update_quiz_question' => rpc_update_quiz_question($args),
        'grade_quiz_essay' => rpc_grade_quiz_essay($args),
        'start_quiz' => rpc_start_quiz($args),
        'submit_quiz' => rpc_submit_quiz($args),
        default => fail('Unknown server operation.', 404),
    };
    json_response(['data' => $data]);
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

function rpc_grade_quiz_essay(array $args): array
{
    $attemptId=(string)($args['target_attempt_id']??'');$questionId=(string)($args['target_question_id']??'');$awarded=(float)($args['awarded_points']??-1);
    $stmt=db()->prepare("SELECT a.*,q.class_id,qq.prompt,qq.points FROM quiz_attempts a JOIN quizzes q ON q.id=a.quiz_id JOIN quiz_questions qq ON qq.quiz_id=a.quiz_id AND qq.id=? AND qq.question_type='essay' WHERE a.id=?");
    $stmt->execute([$questionId,$attemptId]);$attempt=$stmt->fetch();if(!$attempt)fail('Essay attempt not found.',404);
    $user=require_class_manager($attempt['class_id']);if($attempt['status']!=='submitted')fail('The student has not submitted this assessment.',409);
    $maximum=(float)$attempt['points'];if(!is_finite($awarded)||$awarded<0||$awarded>$maximum)fail('Essay score must be between zero and the question point value.');
    $essayScores=json_decode((string)($attempt['essay_scores']??'{}'),true);if(!is_array($essayScores))$essayScores=[];$essayScores[$questionId]=$awarded;
    [$automatic,$max]=quiz_score((string)$attempt['quiz_id'],is_array(json_decode((string)$attempt['answers'],true))?json_decode((string)$attempt['answers'],true):[]);
    $essayQuestions=fetch_all("SELECT id,points FROM quiz_questions WHERE quiz_id=? AND question_type='essay'",[$attempt['quiz_id']]);$essayTotal=0.0;
    foreach($essayQuestions as $question){$value=(float)($essayScores[$question['id']]??0);$essayTotal+=min(max($value,0),(float)$question['points']);}
    db()->prepare('UPDATE quiz_attempts SET essay_scores=?,score=?,max_score=? WHERE id=?')->execute([json_encode($essayScores),$automatic+$essayTotal,$max,$attemptId]);
    $updated=quiz_attempt_row($attemptId);lms_audit('grade','quiz_attempts',$attemptId,'Graded essay question: '.$attempt['prompt'],null,['question_id'=>$questionId,'awarded_points'=>$awarded,'score'=>$updated['score']],$user);return $updated;
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
    $answers=is_array($args['submitted_answers']??null)?$args['submitted_answers']:[]; [$score,$max]=quiz_score($quizId,$answers);
    db()->prepare("UPDATE quiz_attempts SET answers=?,score=?,max_score=?,status='submitted',submitted_at=NOW() WHERE id=?")->execute([json_encode($answers),$score,$max,$attempt['id']]);
    return quiz_attempt_row($attempt['id']);
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
    global $config;$bucket=(string)($request['bucket']??'');$path=clean_storage_path((string)($request['path']??''));if(!in_array($bucket,['materials','submissions'],true)||!isset($_FILES['file']))fail('Invalid upload.');
    $classId=explode('/',$path)[0]??'';$user=require_active_user();if($bucket==='materials'&&!class_manage($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&($user['role']!=='student'||!class_access($classId,$user)||!str_contains('/'.$path.'/','/'.$user['id'].'/')))fail('Access denied.',403);
    $file=$_FILES['file'];if(($file['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK)fail('File upload failed.');if(($file['size']??0)>10485760)fail('Files must be 10 MB or smaller.');$ext=strtolower(pathinfo((string)$file['name'],PATHINFO_EXTENSION));if(!in_array($ext,['pdf','doc','docx','odt','rtf','txt','zip'],true))fail('Only PDF, Word, ODT, RTF, TXT, and ZIP files are supported.');
    $target=$config['storage_path'].DIRECTORY_SEPARATOR.$bucket.DIRECTORY_SEPARATOR.str_replace('/',DIRECTORY_SEPARATOR,$path);$dir=dirname($target);if(!is_dir($dir)&&!mkdir($dir,0775,true)&&!is_dir($dir))fail('Unable to create the upload directory.',500);if(!move_uploaded_file($file['tmp_name'],$target))fail('Unable to save the uploaded file.',500);json_response(['path'=>$path]);
}

function storage_remove(array $request): never
{
    global $config;$bucket=(string)($request['bucket']??'');$paths=is_array($request['paths']??null)?$request['paths']:[];$user=require_active_user();foreach($paths as $raw){$path=clean_storage_path((string)$raw);$classId=explode('/',$path)[0]??'';if($bucket==='materials'&&!class_manage($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&!class_manage($classId,$user)&&($user['role']!=='student'||!str_contains('/'.$path.'/','/'.$user['id'].'/')))fail('Access denied.',403);$file=$config['storage_path'].DIRECTORY_SEPARATOR.$bucket.DIRECTORY_SEPARATOR.str_replace('/',DIRECTORY_SEPARATOR,$path);if(is_file($file))unlink($file);}json_response([]);
}

function storage_signed_url(array $request): never
{
    global $config;$bucket=(string)($request['bucket']??'');$path=clean_storage_path((string)($request['path']??''));$disposition=(string)($request['disposition']??'download');if(!in_array($disposition,['preview','download'],true))fail('Invalid file disposition.');$expires=time()+min(300,max(10,(int)($request['expiresIn']??60)));$classId=explode('/',$path)[0]??'';$user=require_active_user();if(!class_access($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&!class_report_access($classId,$user)&&!str_contains('/'.$path.'/','/'.$user['id'].'/'))fail('Access denied.',403);$token=hash_hmac('sha256',"$bucket|$path|$expires|$disposition",session_id());$url=$config['app_url'].'/api/index.php?action=storage.download&bucket='.rawurlencode($bucket).'&path='.rawurlencode($path).'&expires='.$expires.'&disposition='.$disposition.'&token='.$token;json_response(['signedUrl'=>$url]);
}

function download_file(): never
{
    global $config;$bucket=(string)($_GET['bucket']??'');$path=clean_storage_path((string)($_GET['path']??''));$expires=(int)($_GET['expires']??0);$disposition=(string)($_GET['disposition']??'download');$token=(string)($_GET['token']??'');if(!in_array($disposition,['preview','download'],true)||$expires<time()||!hash_equals(hash_hmac('sha256',"$bucket|$path|$expires|$disposition",session_id()),$token))fail('This file link is invalid or expired.',403);$user=require_active_user();$classId=explode('/',$path)[0]??'';if(!class_access($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&!class_report_access($classId,$user)&&!str_contains('/'.$path.'/','/'.$user['id'].'/'))fail('Access denied.',403);$file=$config['storage_path'].DIRECTORY_SEPARATOR.$bucket.DIRECTORY_SEPARATOR.str_replace('/',DIRECTORY_SEPARATOR,$path);if(!is_file($file))fail('File not found.',404);$ext=strtolower(pathinfo($file,PATHINFO_EXTENSION));$types=['pdf'=>'application/pdf','txt'=>'text/plain; charset=utf-8'];$contentType=$disposition==='preview'?($types[$ext]??'application/octet-stream'):'application/octet-stream';header('Content-Type: '.$contentType);header('Content-Disposition: '.($disposition==='preview'?'inline':'attachment').'; filename="'.basename($file).'"');header('X-Content-Type-Options: nosniff');header('Content-Length: '.filesize($file));readfile($file);exit;
}

function clean_storage_path(string $path): string
{
    $path=str_replace('\\','/',trim($path,'/'));if($path===''||str_contains($path,'..')||!preg_match('#^[A-Za-z0-9._/-]+$#',$path))fail('Invalid storage path.');return $path;
}