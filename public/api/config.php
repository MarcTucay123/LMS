<?php
declare(strict_types=1);

$apiDirectory = realpath(__DIR__) ?: __DIR__;
$projectRoot = dirname($apiDirectory, 2);
$privateRoot = basename($projectRoot) === 'dist' ? dirname($projectRoot) : $projectRoot;
$scriptName = str_replace('\\', '/', (string)($_SERVER['SCRIPT_NAME'] ?? '/b1-learning-management/api/index.php'));
$apiPosition = strpos($scriptName, '/api/');
$detectedAppPath = $apiPosition === false ? '/b1-learning-management' : substr($scriptName, 0, $apiPosition);
$detectedAppPath = '/' . trim($detectedAppPath, '/');
if (str_ends_with($detectedAppPath, '/dist')) {
    $detectedAppPath = substr($detectedAppPath, 0, -5) ?: '/b1-learning-management';
}
$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = (string)($_SERVER['HTTP_HOST'] ?? 'localhost');
$defaultAppUrl = $scheme . '://' . $host . $detectedAppPath;
$config = [
    'db_host' => getenv('LMS_DB_HOST') ?: '192.168.109.117',
    'db_port' => getenv('LMS_DB_PORT') ?: '3306',
    'db_name' => getenv('LMS_DB_NAME') ?: 'adfc_onecampus',
    'db_user' => getenv('LMS_DB_USER') ?: 'onecampus',
    'db_pass' => getenv('LMS_DB_PASS') ?: '',
    'app_url' => rtrim(getenv('LMS_APP_URL') ?: $defaultAppUrl, '/'),
    'app_path' => $detectedAppPath,
    'onecampus_api_url' => trim(getenv('ONECAMPUS_API_URL') ?: ''),
    'onecampus_api_key' => getenv('ONECAMPUS_API_KEY') ?: '',
    'onecampus_db_host' => trim(getenv('ONECAMPUS_DB_HOST') ?: '192.168.109.117'),
    'onecampus_db_port' => getenv('ONECAMPUS_DB_PORT') ?: '3306',
    'onecampus_db_name' => getenv('ONECAMPUS_DB_NAME') ?: 'adfc_onecampus',
    'onecampus_db_user' => getenv('ONECAMPUS_DB_USER') ?: 'onecampus',
    'onecampus_db_pass' => getenv('ONECAMPUS_DB_PASS') ?: '',
    'onecampus_setup_completed' => false,
    'project_root' => $projectRoot,
    'private_root' => $privateRoot,
    'storage_path' => $privateRoot . DIRECTORY_SEPARATOR . 'storage' . DIRECTORY_SEPARATOR . 'uploads',
];

$localConfig = $privateRoot . DIRECTORY_SEPARATOR . 'api' . DIRECTORY_SEPARATOR . 'config.local.php';
if (is_file($localConfig)) {
    $overrides = require $localConfig;
    if (is_array($overrides)) $config = array_replace($config, $overrides);
}

$setupConfig = $privateRoot . DIRECTORY_SEPARATOR . 'api' . DIRECTORY_SEPARATOR . 'onecampus.setup.php';
if (is_file($setupConfig)) {
    $overrides = require $setupConfig;
    if (is_array($overrides)) $config = array_replace($config, $overrides, ['onecampus_setup_completed' => true]);
}

$configuredPath = parse_url((string)$config['app_url'], PHP_URL_PATH);
$config['app_path'] = '/' . trim(is_string($configuredPath) && $configuredPath !== '' ? $configuredPath : $detectedAppPath, '/');

return $config;