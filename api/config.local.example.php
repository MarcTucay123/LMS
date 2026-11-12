<?php
declare(strict_types=1);

return [
    'db_host' => '127.0.0.1',
    'db_port' => '3306',
    'db_name' => 'lms_db',
    'db_user' => 'root',
    'db_pass' => '',
    'app_url' => 'http://localhost/lms',
    'onecampus_api_url' => '',
    'onecampus_api_key' => '',
    // Optional read-only connection to ADFC_OneCampus_Unified_Schema.sql.
    // Set the database server's LAN IP here, never in the React login form.
    'onecampus_db_host' => '',
    'onecampus_db_port' => '3306',
    'onecampus_db_name' => 'adfc_onecampus',
    'onecampus_db_user' => 'lms_reader',
    'onecampus_db_pass' => '',
];