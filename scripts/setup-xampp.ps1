param(
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [string]$PublicPath = 'C:\xampp\htdocs\b1-learning-management',
    [switch]$SkipInstall,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

$project = (Resolve-Path -LiteralPath $ProjectPath).Path
if (-not (Test-Path -LiteralPath (Join-Path $project 'package.json') -PathType Leaf)) {
    throw "The project path does not contain package.json: $project"
}

Push-Location $project
try {
    if (-not $SkipInstall) {
        if (Test-Path -LiteralPath (Join-Path $project 'package-lock.json')) {
            & npm.cmd ci
        } else {
            & npm.cmd install
        }
        if ($LASTEXITCODE -ne 0) { throw "npm dependency installation failed with exit code $LASTEXITCODE." }
    }

    if (-not $SkipBuild) {
        & npm.cmd run build
        if ($LASTEXITCODE -ne 0) { throw "The production build failed with exit code $LASTEXITCODE." }
    }
} finally {
    Pop-Location
}

$distIndex = Join-Path $project 'dist\index.html'
if (-not (Test-Path -LiteralPath $distIndex -PathType Leaf)) {
    throw "The production build is missing: $distIndex"
}

$projectFullPath = [IO.Path]::GetFullPath($project).TrimEnd('\')
$publicFullPath = [IO.Path]::GetFullPath($PublicPath).TrimEnd('\')

if ($projectFullPath -ieq $publicFullPath) {
    Write-Host "The repository already uses the canonical public folder: $project" -ForegroundColor Green
} elseif (Test-Path -LiteralPath $PublicPath) {
    $existing = Get-Item -LiteralPath $PublicPath -Force
    $existingTarget = @($existing.Target) | Select-Object -First 1
    $targetMatches = $existingTarget -and
        ([IO.Path]::GetFullPath($existingTarget).TrimEnd('\') -ieq $projectFullPath)
    if ($existing.LinkType -eq 'Junction' -and $targetMatches) {
        Write-Host "Public junction is already correct: $PublicPath -> $project" -ForegroundColor Green
    } else {
        throw "The public path already exists and is not the expected junction: $PublicPath`nMove or rename it manually, then run this script again. Nothing was deleted."
    }
} else {
    New-Item -ItemType Junction -Path $PublicPath -Target $project | Out-Null
    Write-Host "Created public junction: $PublicPath -> $project" -ForegroundColor Green
}

Write-Host ''
Write-Host 'XAMPP deployment is ready.' -ForegroundColor Green
Write-Host 'Start Apache only on the LMS server.'
Write-Host 'Local URL:  http://localhost/b1-learning-management/'
Write-Host 'School URL: http://192.168.109.152/b1-learning-management/'
Write-Host 'Database setup: /b1-learning-management/setup'