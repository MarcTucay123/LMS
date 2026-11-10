param(
  [string]$Database = 'lms_db',
  [string]$User = 'root',
  [string]$Password = '',
  [string]$MySqlBin = 'C:\xampp\mysql\bin'
)

$ErrorActionPreference = 'Stop'
$dump = Join-Path $MySqlBin 'mysqldump.exe'
if (-not (Test-Path -LiteralPath $dump)) {
  throw "mysqldump.exe was not found at $dump"
}

$exportDirectory = Join-Path $PSScriptRoot 'exports'
New-Item -ItemType Directory -Path $exportDirectory -Force | Out-Null
$output = Join-Path $exportDirectory "${Database}.sql"

$arguments = @(
  "--user=$User",
  '--default-character-set=utf8mb4',
  '--single-transaction',
  '--routines',
  '--triggers',
  '--events',
  '--add-drop-database',
  '--databases',
  $Database,
  "--result-file=$output"
)
if ($Password -ne '') { $arguments = @("--password=$Password") + $arguments }

& $dump @arguments
if ($LASTEXITCODE -ne 0) { throw "mysqldump failed with exit code $LASTEXITCODE" }

$hash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
Write-Output "Export created: $output"
Write-Output "SHA256: $hash"
Write-Warning 'This export contains account records and password hashes. Upload it only to a restricted-access Google Drive folder.'