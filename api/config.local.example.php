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
    // Optional read-only connection to database/adfc_onecampus.sql.
    // Default host; the login page may test and select a private LAN IP for the current PHP session.
    'onecampus_db_host' => '192.168.109.211',
    'onecampus_db_port' => '3306',
    'onecampus_db_name' => 'adfc_onecampus',
    'onecampus_db_user' => 'adfc_lms',
    'onecampus_db_pass' => '',
];