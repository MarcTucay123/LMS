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
    db()->query('SELECT 1')->fetchColumn();
    json_response([
        'status' => 'ok',
        'database' => 'connected',
        'server_time' => (new DateTimeImmutable())->format(DATE_ATOM),
    ]);
}

function auth_login(array $request): never
{
    $email = strtolower(trim((string)($request['email'] ?? '')));
    $password = (string)($request['password'] ?? '');
    $stmt = db()->prepare('SELECT id,email,password_hash,requested_role FROM users WHERE email=?');
    $stmt->execute([$email]);
    $user = $stmt->fetch();
    if (!$user || !password_verify($password, $user['password_hash'])) fail('Invalid login credentials', 401);
    session_regenerate_id(true);
    $_SESSION['user_id'] = $user['id'];
    $payload = user_payload($user);
    json_response(['user' => $payload, 'session' => ['user' => $payload]]);
}

function auth_logout(): never
{
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $params = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000, $params['path'], $params['domain'], $params['secure'], $params['httponly']);
    }
    session_destroy();
    json_response([]);
}

function auth_forgot_password(array $request): never
{
    global $config;
    $email = strtolower(trim((string)($request['email'] ?? '')));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) fail('Enter a valid email address.');
    $stmt = db()->prepare('SELECT id FROM users WHERE email=?');
    $stmt->execute([$email]);
    $id = $stmt->fetchColumn();
    $resetUrl = null;
    if ($id) {
        $token = bin2hex(random_bytes(32));
        $update = db()->prepare('UPDATE users SET reset_token_hash=?, reset_expires_at=DATE_ADD(NOW(), INTERVAL 1 HOUR) WHERE id=?');
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
        $stmt = db()->prepare('SELECT id FROM users WHERE reset_token_hash=? AND reset_expires_at>NOW()');
        $stmt->execute([hash('sha256', $token)]);
        $userId = $stmt->fetchColumn() ?: null;
    }
    if (!$userId) fail('This reset link is invalid or has expired.', 401);
    $stmt = db()->prepare('UPDATE users SET password_hash=?, reset_token_hash=NULL, reset_expires_at=NULL WHERE id=?');
    $stmt->execute([password_hash($password, PASSWORD_DEFAULT), $userId]);
    $userStmt = db()->prepare('SELECT id,email,requested_role FROM users WHERE id=?');
    $userStmt->execute([$userId]);
    json_response(['user' => user_payload($userStmt->fetch())]);
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
        'registration_applications' => select_registrations($orders),
        'sync_logs' => select_sync_logs($orders, $limit),
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
    $sql = 'SELECT * FROM profiles WHERE 1=1'; $params = [];
    if ($id !== null) { $sql .= ' AND id=?'; $params[] = $id; }
    if ($role !== null) { $sql .= ' AND role=?'; $params[] = $role; }
    $sql .= order_clause($orders, ['full_name','created_at'], 'full_name ASC');
    return fetch_all($sql, $params, 'profiles');
}

function select_subjects(array $orders): array
{
    require_admin();
    return fetch_all('SELECT id,code,title,description,created_at,updated_at FROM subjects' . order_clause($orders, ['code','created_at'], 'code ASC'), [], 'subjects');
}

function select_classes(array $filters, array $orders): array
{
    $user = require_active_user();
    $sql = 'SELECT c.*, JSON_OBJECT("code",s.code,"title",s.title) subject, JSON_OBJECT("full_name",p.full_name) instructor FROM classes c JOIN subjects s ON s.id=c.subject_id JOIN profiles p ON p.id=c.instructor_id WHERE 1=1';
    $params = [];
    if ($user['role'] === 'instructor') { $sql .= ' AND c.instructor_id=?'; $params[] = $user['id']; }
    elseif ($user['role'] === 'student') { $sql .= " AND EXISTS (SELECT 1 FROM enrollments e WHERE e.class_id=c.id AND e.student_id=? AND e.status='enrolled')"; $params[] = $user['id']; }
    foreach ($filters as $filter) {
        if (($filter['type'] ?? '') !== 'eq' || !in_array($filter['column'] ?? '', ['id','status'], true)) continue;
        $sql .= ' AND c.`' . $filter['column'] . '`=?'; $params[] = $filter['value'];
    }
    $sql .= qualified_order_clause($orders, ['created_at','school_year','section'], 'c', 'c.created_at ASC');
    $rows = fetch_all($sql, $params, 'classes');
    foreach ($rows as &$row) { $row['subject'] = json_decode($row['subject'], true); $row['instructor'] = json_decode($row['instructor'], true); }
    return $rows;
}

function select_enrollments(array $filters): array
{
    $user = require_active_user();
    $classId = (string)(filter_value($filters, 'class_id') ?? '');
    if ($classId === '') fail('A class filter is required.');
    if (!class_report_access($classId, $user) && $user['role'] !== 'student') fail('Access denied.', 403);
    if ($user['role'] === 'student' && !class_access($classId, $user)) fail('Access denied.', 403);
    $sql = 'SELECT e.*, JSON_OBJECT("id",p.id,"full_name",p.full_name,"school_id",p.school_id) student FROM enrollments e JOIN profiles p ON p.id=e.student_id WHERE e.class_id=?';
    $params = [$classId];
    $status = filter_value($filters, 'status'); if ($status !== null) { $sql .= ' AND e.status=?'; $params[] = $status; }
    if ($user['role'] === 'student') { $sql .= ' AND e.student_id=?'; $params[] = $user['id']; }
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
    $sql = 'SELECT * FROM sync_logs' . order_clause($orders, ['started_at'], 'started_at DESC') . ' LIMIT ' . ($limit ?? 50);
    return fetch_all($sql, [], 'sync_logs');
}

function select_class_children(string $table, array $filters, array $orders): array
{
    $user = require_active_user();
    $classId = (string)(filter_value($filters, 'class_id') ?? '');
    if ($classId === '' || !class_access($classId, $user)) fail('You are not allowed to access these class records.', 403);
    $sql = "SELECT * FROM `$table` WHERE class_id=?"; $params = [$classId];
    foreach ($filters as $filter) {
        if (($filter['type'] ?? '') !== 'neq' || ($filter['column'] ?? '') !== 'status') continue;
        $sql .= ' AND status<>?'; $params[] = $filter['value'];
    }
    if (in_array($table, ['assignments','quizzes'], true) && !class_report_access($classId, $user)) $sql .= " AND status<>'draft'";
    $allowedOrders = ['created_at', 'due_at'];
    $sql .= order_clause($orders, $allowedOrders, $table === 'assignments' ? 'due_at ASC' : 'created_at DESC');
    return fetch_all($sql, $params, $table);
}

function select_topics(array $filters, array $orders): array
{
    $classId = (string)(filter_value($filters, 'class_id') ?? ''); require_class_access($classId);
    $sql = 'SELECT t.*, JSON_OBJECT("full_name",p.full_name) author FROM discussion_topics t JOIN profiles p ON p.id=t.created_by WHERE t.class_id=?' . qualified_order_clause($orders, ['created_at'], 't', 't.created_at DESC');
    $rows = fetch_all($sql, [$classId], 'discussion_topics'); foreach ($rows as &$row) $row['author'] = json_decode($row['author'], true); return $rows;
}

function select_posts(array $filters, array $orders): array
{
    $topicId = (string)(filter_value($filters, 'topic_id') ?? '');
    $stmt = db()->prepare('SELECT class_id FROM discussion_topics WHERE id=?'); $stmt->execute([$topicId]);
    $classId = $stmt->fetchColumn(); if (!$classId) return []; require_class_access($classId);
    $sql = 'SELECT d.*, JSON_OBJECT("full_name",p.full_name) author FROM discussion_posts d JOIN profiles p ON p.id=d.author_id WHERE d.topic_id=?' . qualified_order_clause($orders, ['created_at'], 'd', 'd.created_at ASC');
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
    $classRows = fetch_all("SELECT DISTINCT class_id FROM assignments WHERE id IN ($placeholders)", $ids);
    foreach ($classRows as $row) if (!class_access($row['class_id'], $user)) fail('Access denied.', 403);
    $sql = "SELECT s.*, JSON_OBJECT('full_name',p.full_name,'school_id',p.school_id) student FROM submissions s JOIN profiles p ON p.id=s.student_id WHERE s.assignment_id IN ($placeholders)";
    $params = $ids;
    $canViewReports = count($classRows) > 0; foreach ($classRows as $row) $canViewReports = $canViewReports && class_report_access($row['class_id'], $user);
    if (!$canViewReports) { $sql .= ' AND s.student_id=?'; $params[] = $user['id']; }
    $sql .= qualified_order_clause($orders, ['submitted_at'], 's', 's.submitted_at DESC');
    $rows = fetch_all($sql, $params, 'submissions'); foreach ($rows as &$row) $row['student'] = json_decode($row['student'], true); return $rows;
}

function select_questions(array $filters, array $orders): array
{
    $user = require_active_user(); $ids = id_list_filter($filters, 'quiz_id'); if (!$ids) return [];
    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $classes = fetch_all("SELECT DISTINCT class_id FROM quizzes WHERE id IN ($placeholders)", $ids);
    foreach ($classes as $row) if (!class_access($row['class_id'], $user)) fail('Access denied.', 403);
    return fetch_all("SELECT * FROM quiz_questions WHERE quiz_id IN ($placeholders)" . order_clause($orders, ['position'], 'position ASC'), $ids, 'quiz_questions');
}

function select_attempts(array $filters): array
{
    $user = require_active_user(); $ids = id_list_filter($filters, 'quiz_id'); if (!$ids) return [];
    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $classes = fetch_all("SELECT DISTINCT class_id FROM quizzes WHERE id IN ($placeholders)", $ids);
    foreach ($classes as $row) if (!class_access($row['class_id'], $user)) fail('Access denied.', 403);
    $sql = "SELECT * FROM quiz_attempts WHERE quiz_id IN ($placeholders)"; $params = $ids;
    $canViewReports = count($classes) > 0; foreach ($classes as $row) $canViewReports = $canViewReports && class_report_access($row['class_id'], $user);
    if (!$canViewReports) { $sql .= ' AND student_id=?'; $params[] = $user['id']; }
    return fetch_all($sql, $params, 'quiz_attempts');
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
        'quizzes' => ['class_id','title','description','opens_at','closes_at','time_limit_minutes','status'],
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

    $row = ['id' => uuid()];
    foreach ($allowed[$table] as $column) if (array_key_exists($column, $values)) $row[$column] = normalize_write_value($column, $values[$column]);
    if (in_array($table, ['materials','announcements','discussion_topics','assignments','quizzes'], true)) $row['created_by'] = $user['id'];
    if ($table === 'discussion_posts') $row['author_id'] = $user['id'];
    if (!isset($row['id'])) $row['id'] = uuid();
    if ($table === 'quiz_answer_keys') { unset($row['id']); }
    validate_insert_row($table, $row);

    $columns = array_keys($row);
    $sql = "INSERT INTO `$table` (`" . implode('`,`', $columns) . '`) VALUES (' . implode(',', array_fill(0, count($columns), '?')) . ')';
    db()->prepare($sql)->execute(array_values($row));
    $keyColumn = $table === 'quiz_answer_keys' ? 'question_id' : 'id';
    $stmt = db()->prepare("SELECT * FROM `$table` WHERE `$keyColumn`=?");
    $stmt->execute([$row[$keyColumn]]);
    return normalize_row($table, $stmt->fetch() ?: $row);
}

function class_id_for_topic(string $topicId): string
{
    $stmt = db()->prepare('SELECT class_id FROM discussion_topics WHERE id=?'); $stmt->execute([$topicId]);
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

function query_update(string $table, array $values, array $filters): array
{
    $id = (string)(filter_value($filters, 'id') ?? ''); if ($id === '') fail('An ID filter is required.');
    $allowed = ['quizzes' => ['status']];
    if (!isset($allowed[$table])) fail('Update is not allowed for this table.', 403);
    $classId = class_id_for_record($table, $id); if (!$classId) fail('Record not found.', 404); require_class_manager($classId);
    $sets = []; $params = [];
    foreach ($allowed[$table] as $column) if (array_key_exists($column, $values)) { $sets[] = "`$column`=?"; $params[] = normalize_write_value($column, $values[$column]); }
    if (!$sets) fail('No supported values were supplied.');
    $params[] = $id; db()->prepare("UPDATE `$table` SET " . implode(',', $sets) . ' WHERE id=?')->execute($params);
    $stmt = db()->prepare("SELECT * FROM `$table` WHERE id=?"); $stmt->execute([$id]);
    return normalize_row($table, $stmt->fetch() ?: []);
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
        $stmt = db()->prepare('SELECT created_by FROM discussion_topics WHERE id=?'); $stmt->execute([$id]);
        if ($stmt->fetchColumn() !== $user['id'] && !class_manage($classId, $user)) fail('Access denied.', 403);
    } elseif (!class_manage($classId, $user)) fail('Access denied.', 403);
    db()->prepare("DELETE FROM `$table` WHERE id=?")->execute([$id]);
    return [];
}

function rpc_action(array $request): never
{
    $name = (string)($request['name'] ?? ''); $args = is_array($request['args'] ?? null) ? $request['args'] : [];
    $data = match ($name) {
        'admin_update_user' => rpc_admin_update_user($args),
        'admin_approve_registration' => rpc_approve_registration($args),
        'admin_reject_registration' => rpc_reject_registration($args),
        'submit_assignment' => rpc_submit_assignment($args),
        'grade_submission' => rpc_grade_submission($args),
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
    $stmt = db()->prepare('SELECT * FROM profiles WHERE id=?'); $stmt->execute([$id]); $row = $stmt->fetch(); if (!$row) fail('User profile not found.',404); return normalize_row('profiles',$row);
}

function rpc_approve_registration(array $args): array
{
    $admin = require_admin(); $id = (string)($args['target_application_id'] ?? '');
    $pdo = db(); $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("SELECT * FROM registration_applications WHERE id=? AND status='pending' FOR UPDATE"); $stmt->execute([$id]); $app = $stmt->fetch();
        if (!$app) fail('Pending registration application not found.',404);
        $count = (int)$pdo->query('SELECT COUNT(*) FROM profiles')->fetchColumn() + 1;
        $code = ['student'=>'STU','instructor'=>'FAC','admin'=>'ADMIN'][$app['requested_role']];
        $schoolId = $app['requested_role'] === 'student' && $app['student_id_number'] ? $app['student_id_number'] : sprintf('ADFC-%s-%06d',$code,$count);
        $insert = $pdo->prepare('INSERT INTO profiles (id,onecampus_user_id,source_system,school_id,email,full_name,first_name,middle_name,last_name,suffix,class_code,program,year_level,block,academic_year,semester,role,status) VALUES (?,NULL,\'lms_registration\',?,?,?,?,?,?,?,?,?,?,?,?,?,?,\'active\')');
        $insert->execute([$app['auth_user_id'],$schoolId,$app['email'],$app['full_name'],$app['first_name'],$app['middle_name'],$app['last_name'],$app['suffix'],$app['class_code'],$app['program'],$app['year_level'],$app['block'],$app['academic_year'],$app['semester'],$app['requested_role']]);
        $pdo->prepare("UPDATE registration_applications SET status='approved',reviewed_by=?,reviewed_at=NOW() WHERE id=?")->execute([$admin['id'],$id]);
        $pdo->commit(); $profile = $pdo->prepare('SELECT * FROM profiles WHERE id=?'); $profile->execute([$app['auth_user_id']]); return normalize_row('profiles',$profile->fetch());
    } catch (Throwable $error) { if ($pdo->inTransaction()) $pdo->rollBack(); throw $error; }
}

function rpc_reject_registration(array $args): array
{
    $admin=require_admin(); $id=(string)($args['target_application_id']??'');
    $stmt=db()->prepare("UPDATE registration_applications SET status='rejected',reviewed_by=?,reviewed_at=NOW() WHERE id=? AND status='pending'"); $stmt->execute([$admin['id'],$id]);
    if(!$stmt->rowCount()) fail('Pending registration application not found.',404);
    $get=db()->prepare('SELECT * FROM registration_applications WHERE id=?'); $get->execute([$id]); return normalize_row('registration_applications',$get->fetch());
}

function rpc_submit_assignment(array $args): array
{
    $user=require_active_user(); if($user['role']!=='student') fail('Only students can submit assignments.',403);
    $assignmentId=(string)($args['target_assignment_id']??''); $stmt=db()->prepare("SELECT * FROM assignments WHERE id=? AND status='published'"); $stmt->execute([$assignmentId]); $assignment=$stmt->fetch();
    if(!$assignment||!class_access($assignment['class_id'],$user)) fail('Assignment is unavailable.',403);
    $content=trim((string)($args['submission_content']??'')); $path=trim((string)($args['submission_file_path']??'')); if($content===''&&$path==='') fail('Add text or a file before submitting.');
    $id=uuid(); $sql="INSERT INTO submissions (id,assignment_id,student_id,content,file_path,status,submitted_at) VALUES (?,?,?,?,?,'submitted',NOW()) ON DUPLICATE KEY UPDATE content=VALUES(content),file_path=IF(VALUES(file_path)='',file_path,VALUES(file_path)),status='submitted',submitted_at=NOW(),grade=NULL,feedback=NULL,graded_by=NULL,graded_at=NULL";
    db()->prepare($sql)->execute([$id,$assignmentId,$user['id'],$content?:null,$path?:null]);
    $get=db()->prepare('SELECT * FROM submissions WHERE assignment_id=? AND student_id=?'); $get->execute([$assignmentId,$user['id']]); return normalize_row('submissions',$get->fetch());
}

function rpc_grade_submission(array $args): array
{
    $id=(string)($args['target_submission_id']??''); $stmt=db()->prepare('SELECT s.*,a.class_id,a.points FROM submissions s JOIN assignments a ON a.id=s.assignment_id WHERE s.id=?'); $stmt->execute([$id]); $row=$stmt->fetch(); if(!$row) fail('Submission not found.',404);
    $user=require_class_manager($row['class_id']); $grade=(float)($args['awarded_grade']??-1); if($grade<0||$grade>(float)$row['points']) fail('Grade must be within the assignment point limit.');
    db()->prepare("UPDATE submissions SET grade=?,feedback=?,status='graded',graded_by=?,graded_at=NOW() WHERE id=?")->execute([$grade,trim((string)($args['grading_feedback']??'')),$user['id'],$id]);
    $get=db()->prepare('SELECT * FROM submissions WHERE id=?'); $get->execute([$id]); return normalize_row('submissions',$get->fetch());
}

function rpc_submit_quiz(array $args): array
{
    $user=require_active_user(); if($user['role']!=='student') fail('Only students can submit quiz attempts.',403);
    $quizId=(string)($args['target_quiz_id']??''); $stmt=db()->prepare("SELECT * FROM quizzes WHERE id=? AND status='published'"); $stmt->execute([$quizId]); $quiz=$stmt->fetch(); if(!$quiz||!class_access($quiz['class_id'],$user)) fail('Quiz is unavailable.',403);
    if($quiz['opens_at']&&strtotime($quiz['opens_at'])>time()) fail('Quiz is not open yet.'); if($quiz['closes_at']&&strtotime($quiz['closes_at'])<time()) fail('Quiz is closed.');
    $answers=is_array($args['submitted_answers']??null)?$args['submitted_answers']:[]; $questions=fetch_all('SELECT qq.id,qq.points,k.correct_answer,k.case_sensitive FROM quiz_questions qq JOIN quiz_answer_keys k ON k.question_id=qq.id WHERE qq.quiz_id=?',[$quizId]);
    $score=0.0;$max=0.0; foreach($questions as $q){$max+=(float)$q['points'];$supplied=trim((string)($answers[$q['id']]??''));$correct=trim((string)$q['correct_answer']);$match=$q['case_sensitive']?$supplied===$correct:mb_strtolower($supplied)===mb_strtolower($correct);if($match)$score+=(float)$q['points'];}
    $id=uuid(); try{db()->prepare("INSERT INTO quiz_attempts (id,quiz_id,student_id,answers,score,max_score,status,submitted_at) VALUES (?,?,?,?,?,?,'submitted',NOW())")->execute([$id,$quizId,$user['id'],json_encode($answers),$score,$max]);}catch(PDOException $error){if(unique_violation($error))fail('Quiz has already been submitted.',409);throw $error;}
    $get=db()->prepare('SELECT * FROM quiz_attempts WHERE id=?');$get->execute([$id]);return normalize_row('quiz_attempts',$get->fetch());
}

function function_action(array $request): never
{
    $name=(string)($request['name']??'');$body=is_array($request['body']??null)?$request['body']:[];
    match($name){
        'register-account'=>register_account($body),
        'activate-account'=>activate_account($body),
        'sync-onecampus'=>sync_onecampus(),
        default=>fail('Unknown server function.',404),
    };
}

function register_account(array $body): never
{
    if(($body['action']??null)==='catalog'){
        $rows=fetch_all("SELECT c.id,c.section,c.school_year,c.semester,JSON_OBJECT('code',s.code,'title',s.title) subject FROM classes c JOIN subjects s ON s.id=c.subject_id WHERE c.status='active' ORDER BY c.school_year DESC,c.section ASC",[],'classes');
        foreach($rows as &$row)$row['subject']=json_decode($row['subject'],true);json_response(['classes'=>$rows]);
    }
    $role=(string)($body['role']??'');if(!in_array($role,['student','instructor'],true))fail('Public registration is available only for students and instructors.',403);
    $first=valid_name($body['firstName']??null,true);$middle=valid_name($body['middleName']??null);$last=valid_name($body['lastName']??null,true);$suffix=trim((string)($body['suffix']??''))?:null;
    $email=strtolower(trim((string)($body['email']??'')));if(!filter_var($email,FILTER_VALIDATE_EMAIL))fail('Use a valid email address.');
    $password=(string)($body['password']??'');validate_password($password);$full=implode(' ',array_filter([$first,$middle,$last,$suffix]));
    $studentId=$role==='student'?strtoupper(trim((string)($body['studentIdNumber']??''))):null;$classCode=$role==='student'?trim((string)($body['classCode']??'')):null;$program=$role==='student'?strtoupper(trim((string)($body['program']??''))):null;$year=$role==='student'?(int)($body['yearLevel']??0):null;$block=$role==='student'?strtoupper(trim((string)($body['block']??''))):null;$academicYear=$role==='student'?trim((string)($body['academicYear']??'')):null;$semester=$role==='student'?trim((string)($body['semester']??'')):null;$classIds=$role==='student'&&is_array($body['selectedClassIds']??null)?array_values(array_unique($body['selectedClassIds'])):[];
    if($role==='student'){
        if(!preg_match('/^[A-Z0-9-]{4,30}$/',$studentId??'')||!preg_match('/^[0-9]{4}$/',$classCode??'')||!preg_match('/^[0-9]{4}-[0-9]{4}$/',$academicYear??'')||$year<1||$year>10||!$program||!$block||!$semester||!$classIds||!($body['termsAccepted']??false))fail('Complete all required student registration details.');
        $placeholders=implode(',',array_fill(0,count($classIds),'?'));
        $check=db()->prepare("SELECT COUNT(*) FROM classes WHERE id IN ($placeholders) AND status='active' AND UPPER(section)=? AND school_year=? AND semester=?");$check->execute([...$classIds,strtoupper("$program-$year$block"),$academicYear,$semester]);if((int)$check->fetchColumn()!==count($classIds))fail('Selected classes do not match the supplied program, year, block, and academic term.');
    }
    $pdo=db();$pdo->beginTransaction();try{
        $id=uuid();$pdo->prepare('INSERT INTO users (id,email,password_hash,requested_role) VALUES (?,?,?,?)')->execute([$id,$email,password_hash($password,PASSWORD_DEFAULT),$role]);
        $pdo->prepare('INSERT INTO registration_applications (id,auth_user_id,email,full_name,first_name,middle_name,last_name,suffix,student_id_number,class_code,program,year_level,block,academic_year,semester,terms_accepted_at,requested_role) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,IF(?=1,NOW(),NULL),?)')->execute([uuid(),$id,$email,$full,$first,$middle,$last,$suffix,$studentId,$classCode,$program,$year?:null,$block,$academicYear,$semester,$role==='student'?1:0,$role]);
        $applicationId=(string)$pdo->query('SELECT id FROM registration_applications WHERE auth_user_id='.$pdo->quote($id))->fetchColumn();
        $link=$pdo->prepare('INSERT INTO registration_application_classes (application_id,class_id) VALUES (?,?)');foreach($classIds as $classId)$link->execute([$applicationId,$classId]);
        $pdo->commit();json_response(['message'=>'Registration submitted. An administrator must approve your account before you can sign in.'],201);
    }catch(Throwable $error){if($pdo->inTransaction())$pdo->rollBack();if(unique_violation($error))fail('This email address or Student ID Number is already registered.',409);throw $error;}
}

function activate_account(array $body): never
{
    $oneCampus=trim((string)($body['onecampusId']??''));$email=strtolower(trim((string)($body['email']??'')));$password=(string)($body['password']??'');validate_password($password);
    $stmt=db()->prepare('SELECT * FROM activation_records WHERE onecampus_user_id=? AND LOWER(email)=?');$stmt->execute([$oneCampus,$email]);$record=$stmt->fetch();if(!$record)fail('No matching OneCampus record was found.',404);if($record['activated_at'])fail('This account has already been activated.',409);if(!$record['auth_user_id'])fail('Your OneCampus record is not ready for activation.',409);
    db()->prepare('UPDATE users SET password_hash=? WHERE id=?')->execute([password_hash($password,PASSWORD_DEFAULT),$record['auth_user_id']]);db()->prepare("UPDATE profiles SET status='active' WHERE id=?")->execute([$record['auth_user_id']]);db()->prepare('UPDATE activation_records SET activated_at=NOW() WHERE id=?')->execute([$record['id']]);json_response(['message'=>'Account activated successfully.']);
}

function sync_onecampus(): never
{
    global $config;$admin=require_admin();$source=$config['onecampus_db_host']!==''?'onecampus_database':($config['onecampus_api_url']!==''?'onecampus_api':'mock');$logId=uuid();db()->prepare("INSERT INTO sync_logs (id,initiated_by,source,status,records) VALUES (?,?,?,'running','{}')")->execute([$logId,$admin['id'],$source]);
    try{
        if($source==='onecampus_database'){$payload=onecampus_database_payload();}
        else{if($source==='mock'){$json=file_get_contents($config['project_root'].DIRECTORY_SEPARATOR.'mock-onecampus'.DIRECTORY_SEPARATOR.'fixtures.json');}else{$headers="Accept: application/json\r\nAuthorization: Bearer {$config['onecampus_api_key']}\r\nX-API-Key: {$config['onecampus_api_key']}\r\n";$json=file_get_contents($config['onecampus_api_url'],false,stream_context_create(['http'=>['header'=>$headers,'timeout'=>30]]));}$payload=json_decode((string)$json,true);}
        if(!is_array($payload)||!isset($payload['users'],$payload['subjects'],$payload['classes'],$payload['enrollments']))throw new RuntimeException('OneCampus returned an invalid payload.');
        $pdo=db();$pdo->beginTransaction();$profileMap=[];$subjectMap=[];$classMap=[];
        foreach($payload['users'] as $item){$email=strtolower(trim($item['email']));$find=$pdo->prepare('SELECT id FROM profiles WHERE onecampus_user_id=? OR LOWER(email)=? LIMIT 1');$find->execute([$item['id'],$email]);$id=$find->fetchColumn()?:uuid();$exists=$pdo->prepare('SELECT id FROM users WHERE id=?');$exists->execute([$id]);if(!$exists->fetchColumn())$pdo->prepare('INSERT INTO users (id,email,password_hash,requested_role) VALUES (?,?,?,?)')->execute([$id,$email,password_hash(bin2hex(random_bytes(24)),PASSWORD_DEFAULT),$item['role']]);$owner=$item['role']==='instructor'?'employee_management':($item['role']==='student'?'enrollment_management':'onecampus');$pdo->prepare('INSERT INTO profiles (id,onecampus_user_id,source_system,synced_at,school_id,email,full_name,role,status) VALUES (?,?,?,NOW(),?,?,?,?,?) ON DUPLICATE KEY UPDATE onecampus_user_id=VALUES(onecampus_user_id),source_system=VALUES(source_system),synced_at=NOW(),school_id=VALUES(school_id),email=VALUES(email),full_name=VALUES(full_name),role=VALUES(role),status=VALUES(status)')->execute([$id,$item['id'],$owner,$item['schoolId'],$email,$item['fullName'],$item['role'],$item['status']]);$pdo->prepare('INSERT INTO activation_records (id,onecampus_user_id,school_id,email,full_name,role,auth_user_id,activated_at) VALUES (?,?,?,?,?,?,?,IF(?=\'active\',NOW(),NULL)) ON DUPLICATE KEY UPDATE school_id=VALUES(school_id),email=VALUES(email),full_name=VALUES(full_name),role=VALUES(role),auth_user_id=VALUES(auth_user_id)')->execute([uuid(),$item['id'],$item['schoolId'],$email,$item['fullName'],$item['role'],$id,$item['status']]);$profileMap[$item['id']]=$id;}
        foreach($payload['subjects'] as $item){$find=$pdo->prepare('SELECT id FROM subjects WHERE onecampus_subject_id=?');$find->execute([$item['id']]);$id=$find->fetchColumn()?:uuid();$pdo->prepare('INSERT INTO subjects (id,onecampus_subject_id,source_system,synced_at,code,title,description) VALUES (?,?,\'course_catalog\',NOW(),?,?,?) ON DUPLICATE KEY UPDATE source_system=VALUES(source_system),synced_at=NOW(),code=VALUES(code),title=VALUES(title),description=VALUES(description)')->execute([$id,$item['id'],$item['code'],$item['title'],$item['description']??null]);$subjectMap[$item['id']]=$id;}
        foreach($payload['classes'] as $item){$find=$pdo->prepare('SELECT id FROM classes WHERE onecampus_class_id=?');$find->execute([$item['id']]);$id=$find->fetchColumn()?:uuid();$pdo->prepare('INSERT INTO classes (id,onecampus_class_id,source_system,synced_at,subject_id,instructor_id,section,school_year,semester,status) VALUES (?,?,\'class_scheduling\',NOW(),?,?,?,?,?,?) ON DUPLICATE KEY UPDATE source_system=VALUES(source_system),synced_at=NOW(),subject_id=VALUES(subject_id),instructor_id=VALUES(instructor_id),section=VALUES(section),school_year=VALUES(school_year),semester=VALUES(semester),status=VALUES(status)')->execute([$id,$item['id'],$subjectMap[$item['subjectId']],$profileMap[$item['instructorId']],$item['section'],$item['schoolYear'],$item['semester'],$item['status']]);$classMap[$item['id']]=$id;}
        foreach($payload['enrollments'] as $item){$pdo->prepare('INSERT INTO enrollments (id,onecampus_enrollment_id,source_system,synced_at,class_id,student_id,status) VALUES (?,?,\'enrollment_management\',NOW(),?,?,?) ON DUPLICATE KEY UPDATE source_system=VALUES(source_system),synced_at=NOW(),class_id=VALUES(class_id),student_id=VALUES(student_id),status=VALUES(status)')->execute([uuid(),$item['id'],$classMap[$item['classId']],$profileMap[$item['studentId']],$item['status']]);}
        $counts=['users'=>count($payload['users']),'subjects'=>count($payload['subjects']),'classes'=>count($payload['classes']),'enrollments'=>count($payload['enrollments'])];$sourceLabel=$source==='mock'?'mock fixtures':($source==='onecampus_database'?'the unified OneCampus database':'the OneCampus API');$pdo->prepare("UPDATE sync_logs SET status='success',records=?,message=?,completed_at=NOW() WHERE id=?")->execute([json_encode($counts),'Synchronization completed using '.$sourceLabel.'.',$logId]);$pdo->commit();json_response(['message'=>'OneCampus synchronization completed.','source'=>$source,'counts'=>$counts]);
    }catch(Throwable $error){if(db()->inTransaction())db()->rollBack();db()->prepare("UPDATE sync_logs SET status='failed',message=?,completed_at=NOW() WHERE id=?")->execute([$error->getMessage(),$logId]);throw $error;}
}

function onecampus_database_payload(): array
{
    $source = onecampus_db();
    $users = $source->query("SELECT
        COALESCE(u.user_uid, CONCAT('USER-', u.user_id)) AS id,
        LOWER(u.email) AS email,
        u.full_name AS fullName,
        COALESCE(s.student_number, i.employee_number, u.username, u.user_uid, CONCAT('USER-', u.user_id)) AS schoolId,
        CASE
            WHEN LOWER(u.role) LIKE '%admin%' THEN 'admin'
            WHEN LOWER(u.role) LIKE '%instructor%' OR LOWER(u.role) LIKE '%faculty%' OR LOWER(u.role) LIKE '%teacher%' THEN 'instructor'
            ELSE 'student'
        END AS role,
        CASE WHEN u.status = 'Active' THEN 'active' ELSE 'inactive' END AS status
      FROM users u
      LEFT JOIN students s ON s.student_id = u.student_id
      LEFT JOIN instructors i ON i.user_id = u.user_id
      WHERE u.email IS NOT NULL AND u.email <> ''")->fetchAll();
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
        CONCAT('FE-ENROLLMENT-', e.enrollment_id) AS id,
        COALESCE(c.class_uid, CONCAT('CLASS-', c.class_id)) AS classId,
        COALESCE(u.user_uid, CONCAT('USER-', u.user_id)) AS studentId,
        CASE e.enrollment_status WHEN 'ACTIVE' THEN 'enrolled' WHEN 'COMPLETED' THEN 'completed' ELSE 'dropped' END AS status
      FROM fe_class_enrollments e
      JOIN academic_classes c ON c.class_id = e.class_id
      JOIN students s ON s.student_id = e.student_id
      JOIN users u ON u.student_id = s.student_id")->fetchAll();
    return compact('users', 'subjects', 'classes', 'enrollments');
}

function storage_upload(array $request): never
{
    global $config;$bucket=(string)($request['bucket']??'');$path=clean_storage_path((string)($request['path']??''));if(!in_array($bucket,['materials','submissions'],true)||!isset($_FILES['file']))fail('Invalid upload.');
    $classId=explode('/',$path)[0]??'';$user=require_active_user();if($bucket==='materials'&&!class_manage($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&($user['role']!=='student'||!class_access($classId,$user)||!str_contains('/'.$path.'/','/'.$user['id'].'/')))fail('Access denied.',403);
    $file=$_FILES['file'];if(($file['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK)fail('File upload failed.');if(($file['size']??0)>10485760)fail('Files must be 10 MB or smaller.');$ext=strtolower(pathinfo((string)$file['name'],PATHINFO_EXTENSION));if(!in_array($ext,['pdf','docx','zip'],true))fail('Only PDF, DOCX, and ZIP files are supported.');
    $target=$config['storage_path'].DIRECTORY_SEPARATOR.$bucket.DIRECTORY_SEPARATOR.str_replace('/',DIRECTORY_SEPARATOR,$path);$dir=dirname($target);if(!is_dir($dir)&&!mkdir($dir,0775,true)&&!is_dir($dir))fail('Unable to create the upload directory.',500);if(!move_uploaded_file($file['tmp_name'],$target))fail('Unable to save the uploaded file.',500);json_response(['path'=>$path]);
}

function storage_remove(array $request): never
{
    global $config;$bucket=(string)($request['bucket']??'');$paths=is_array($request['paths']??null)?$request['paths']:[];$user=require_active_user();foreach($paths as $raw){$path=clean_storage_path((string)$raw);$classId=explode('/',$path)[0]??'';if($bucket==='materials'&&!class_manage($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&!class_manage($classId,$user)&&($user['role']!=='student'||!str_contains('/'.$path.'/','/'.$user['id'].'/')))fail('Access denied.',403);$file=$config['storage_path'].DIRECTORY_SEPARATOR.$bucket.DIRECTORY_SEPARATOR.str_replace('/',DIRECTORY_SEPARATOR,$path);if(is_file($file))unlink($file);}json_response([]);
}

function storage_signed_url(array $request): never
{
    global $config;$bucket=(string)($request['bucket']??'');$path=clean_storage_path((string)($request['path']??''));$expires=time()+min(300,max(10,(int)($request['expiresIn']??60)));$classId=explode('/',$path)[0]??'';$user=require_active_user();if(!class_access($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&!class_report_access($classId,$user)&&!str_contains('/'.$path.'/','/'.$user['id'].'/'))fail('Access denied.',403);$token=hash_hmac('sha256',"$bucket|$path|$expires",session_id());$url=$config['app_url'].'/api/index.php?action=storage.download&bucket='.rawurlencode($bucket).'&path='.rawurlencode($path).'&expires='.$expires.'&token='.$token;json_response(['signedUrl'=>$url]);
}

function download_file(): never
{
    global $config;$bucket=(string)($_GET['bucket']??'');$path=clean_storage_path((string)($_GET['path']??''));$expires=(int)($_GET['expires']??0);$token=(string)($_GET['token']??'');if($expires<time()||!hash_equals(hash_hmac('sha256',"$bucket|$path|$expires",session_id()),$token))fail('This download link is invalid or expired.',403);$user=require_active_user();$classId=explode('/',$path)[0]??'';if(!class_access($classId,$user))fail('Access denied.',403);if($bucket==='submissions'&&!class_report_access($classId,$user)&&!str_contains('/'.$path.'/','/'.$user['id'].'/'))fail('Access denied.',403);$file=$config['storage_path'].DIRECTORY_SEPARATOR.$bucket.DIRECTORY_SEPARATOR.str_replace('/',DIRECTORY_SEPARATOR,$path);if(!is_file($file))fail('File not found.',404);header('Content-Type: application/octet-stream');header('Content-Disposition: attachment; filename="'.basename($file).'"');header('Content-Length: '.filesize($file));readfile($file);exit;
}

function clean_storage_path(string $path): string
{
    $path=str_replace('\\','/',trim($path,'/'));if($path===''||str_contains($path,'..')||!preg_match('#^[A-Za-z0-9._/-]+$#',$path))fail('Invalid storage path.');return $path;
}