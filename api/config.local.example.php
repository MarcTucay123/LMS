<?php
declare(strict_types=1);

return [
    // Unified deployment: the LMS uses the existing adfc_onecampus connection.
    'db_host' => '192.168.109.117',
    'db_port' => '3306',
    'db_name' => 'adfc_onecampus',
    'db_user' => 'onecampus',
    'db_pass' => 'ENTER_EXISTING_DATABASE_PASSWORD',
    'app_url' => 'http://192.168.109.152/b1-learning-management',
    'onecampus_api_url' => '',
    'onecampus_api_key' => '',
    // Existing school OneCampus database access. No MySQL user is created by
    // this LMS package.
    'onecampus_db_host' => '192.168.109.117',
    'onecampus_db_port' => '3306',
    'onecampus_db_name' => 'adfc_onecampus',
    'onecampus_db_user' => 'onecampus',
    'onecampus_db_pass' => 'ENTER_EXISTING_DATABASE_PASSWORD',
];