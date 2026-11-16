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
    '002_create_lms_administrator.sql'
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
