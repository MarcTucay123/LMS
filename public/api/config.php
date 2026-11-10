<?php
declare(strict_types=1);

$apiDirectory = realpath(__DIR__) ?: __DIR__;
$projectRoot = dirname($apiDirectory, 2);
$config = [
    'db_host' => getenv('LMS_DB_HOST') ?: '127.0.0.1',
    'db_port' => getenv('LMS_DB_PORT') ?: '3306',
    'db_name' => getenv('LMS_DB_NAME') ?: 'adfc_lms',
    'db_user' => getenv('LMS_DB_USER') ?: 'root',
    'db_pass' => getenv('LMS_DB_PASS') ?: '',
    'app_url' => rtrim(getenv('LMS_APP_URL') ?: 'http://localhost/lms', '/'),
    'onecampus_api_url' => trim(getenv('ONECAMPUS_API_URL') ?: ''),
    'onecampus_api_key' => getenv('ONECAMPUS_API_KEY') ?: '',
    'project_root' => $projectRoot,
    'storage_path' => $projectRoot . DIRECTORY_SEPARATOR . 'storage' . DIRECTORY_SEPARATOR . 'uploads',
];

$localConfig = $projectRoot . DIRECTORY_SEPARATOR . 'api' . DIRECTORY_SEPARATOR . 'config.local.php';
if (is_file($localConfig)) {
    $overrides = require $localConfig;
    if (is_array($overrides)) $config = array_replace($config, $overrides);
}

return $config;