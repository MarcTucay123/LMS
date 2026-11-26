param(
    [string]$MySqlExe = 'C:\xampp\mysql\bin\mysql.exe',
    [string]$HostName = '127.0.0.1',
    [int]$Port = 3306,
    [string]$Database = 'adfc_onecampus',
    [string]$User = 'root',
    [string]$Password = ''
)

$ErrorActionPreference = 'Stop'
$migrationRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$migrationFiles = @(
    '001_prepare_lms_shared_data.sql',
    '002_create_lms_administrator.sql',
    '003_repair_lms_administrator_user_id.sql',
    '004_publish_enrollment_access.sql',
    '005_add_exams_and_lms_audit_support.sql',
    '006_add_identification_and_essay_grading.sql',
    '007_add_live_quiz_sessions.sql',
    '008_add_user_security_controls.sql',
    '009_add_quiz_exam_file_submissions.sql',
    '010_add_quiz_file_grading.sql',
    '011_add_discussion_message_actions.sql',
    '012_add_discussion_replies_reactions_and_soft_delete.sql',
    '013_add_discussion_membership_and_personal_hiding.sql',
    '014_add_discussion_notification_muting.sql',
    '015_add_discussion_attachments.sql',
    '016_add_lms_profile_pictures.sql',
    '017_add_discussion_video_calls.sql',
    '018_finalize_regular_discussion_calls.sql',
    '019_add_discussion_read_receipts.sql',
    '020_add_discussion_live_attendance_history.sql',
    '021_add_live_call_attendance_controls.sql',
    '022_add_my_learning_paths.sql'
)

if (-not (Test-Path -LiteralPath $MySqlExe)) {
    throw "mysql.exe was not found at $MySqlExe"
}

$mysqlArgs = @('--host', $HostName, '--port', $Port, '--user', $User, '--database', $Database)
if ($Password -ne '') {
    $env:MYSQL_PWD = $Password
}

try {
    foreach ($fileName in $migrationFiles) {
        $path = Join-Path $migrationRoot $fileName
        Write-Host "Applying $fileName to $HostName/$Database ..."
        Get-Content -LiteralPath $path -Raw | & $MySqlExe @mysqlArgs
        if ($LASTEXITCODE -ne 0) { throw "Migration failed: $fileName" }
    }

    Write-Host 'Running verification ...'
    Get-Content -LiteralPath (Join-Path $migrationRoot 'verify_lms_migration.sql') -Raw | & $MySqlExe @mysqlArgs
    if ($LASTEXITCODE -ne 0) { throw 'Migration verification failed.' }
    Write-Host 'LMS shared-database migration completed successfully.' -ForegroundColor Green
}
finally {
    Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
}
