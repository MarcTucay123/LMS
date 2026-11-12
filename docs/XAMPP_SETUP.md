# XAMPP deployment guide

This guide deploys the LMS from `D:\LMS` at `http://localhost/lms/` using XAMPP Apache, PHP, and MariaDB.

## 1. Requirements

- XAMPP installed at `C:\xampp`
- PHP 8.1 or later with `PDO`, `pdo_mysql`, `session`, `mbstring`, `fileinfo`, `curl`, and `openssl`
- Node.js and npm
- An NTFS volume that supports directory junctions

The checked XAMPP environment uses MariaDB 10.4.32. Apache must have `mod_rewrite` enabled and permit `.htaccess` overrides for `htdocs`.

## 2. Install and validate the frontend

```powershell
cd D:\LMS
npm install
npm run lint
npm run build
```

Vite copies `public/.htaccess` and `public/api` into `D:\LMS\dist`, so the production build contains both the SPA and PHP API.

## 3. Configure the PHP API

Defaults in `public/api/config.php` work with a standard local XAMPP installation:

```text
database: lms_db
host:     127.0.0.1
port:     3306
user:     root
password: empty
app URL:  http://localhost/lms
```

For overrides, copy the example outside the public web root:

```powershell
Copy-Item D:\LMS\api\config.local.example.php D:\LMS\api\config.local.php
```

Edit `D:\LMS\api\config.local.php` as needed. It is ignored by Git. Environment variables `LMS_DB_HOST`, `LMS_DB_PORT`, `LMS_DB_NAME`, `LMS_DB_USER`, `LMS_DB_PASS`, `LMS_APP_URL`, `ONECAMPUS_API_URL`, `ONECAMPUS_API_KEY`, `ONECAMPUS_DB_HOST`, `ONECAMPUS_DB_PORT`, `ONECAMPUS_DB_NAME`, `ONECAMPUS_DB_USER`, and `ONECAMPUS_DB_PASS` are also supported.

Synchronization source priority is: unified OneCampus database when `ONECAMPUS_DB_HOST` is set, OneCampus API when `ONECAMPUS_API_URL` is set, then `D:\LMS\mock-onecampus\fixtures.json`.

For a database server on another computer, place its LAN IP in the private PHP configuration, for example:

```php
'onecampus_db_host' => '192.168.109.211',
'onecampus_db_name' => 'adfc_onecampus',
'onecampus_db_user' => 'adfc_subsystems',
'onecampus_db_pass' => '',
```

For local testing when XAMPP/MariaDB and `adfc_onecampus` are on the same computer, use `127.0.0.1`. The setup page provides **This PC (home)** and **School server** shortcuts. `127.0.0.1` always means the computer running the LMS PHP API; it cannot reach the school database from home unless that database also exists locally.

Do not place MySQL credentials in any `VITE_*` variable. The pre-login setup form sends the connection details to PHP over the current LMS origin; PHP retains them in the server-side session and performs the database connection.

LAN users should open the LMS through the Apache server address, for example `http://192.168.1.10/lms/`. Keep `VITE_API_URL=/lms/api/index.php` so login and PHP session cookies remain on the same origin.

If the shared ADFC application server is `192.168.109.211` and Apache maps `/lms` to this project's `dist` directory, the LMS address is `http://192.168.109.211/lms/` (Apache on Windows also normally accepts `/LMS/`). This is separate from paths such as `/billing-system/` and `/adfc-kiosk/`.

Before login, `/lms/setup` asks for the database host, port, database name, `adfc_subsystems` username, and its current database password (blank when no password is configured). **Verify OneCampus and finish setup** verifies the unified tables and writes the verified database connection to the private `api/onecampus.setup.php` file. A successful connection displays a confirmation modal with the verified server details; selecting **Continue to login** opens the LMS login page. Setup does not create or change an LMS account password. After setup, the login page provides a **Back to database setup/status** button. The setup page then shows green when the saved OneCampus connection is reachable and red when it is unavailable, with **Check connection again** and **Disconnect** actions. Disconnect requires confirmation, deletes only `C:\xampp\htdocs\LMS\api\onecampus.setup.php`, clears the temporary connection session, and returns to the editable setup form. Once the first administrator exists, only an authenticated active LMS administrator can disconnect.

The LMS still requires its own `lms_db` because the shared `adfc_onecampus` tables use a different identity and academic schema. Do not overwrite `adfc_onecampus.users`, `announcements`, or `enrollments` with the LMS schema. After importing `database/schema.sql` into `lms_db`, open `/lms/register/admin` to create the first administrator. That account is active immediately; public administrator registration closes as soon as one administrator profile exists.

## 4. Start and import MariaDB

Start MySQL/MariaDB in the XAMPP Control Panel, then import the schema and seed:

```powershell
& C:\xampp\mysql\bin\mysql.exe -u root -e "source D:/LMS/database/schema.sql; source D:/LMS/database/seed.sql;"
```

`database/schema.sql` drops and recreates the LMS tables. Do not run it against a database containing data that must be retained.

For an existing database, apply the non-destructive ownership migration instead:

```powershell
& C:\xampp\mysql\bin\mysql.exe -u root lms_db -e "source D:/LMS/database/migrations/20261110_academic_data_ownership.sql;"
```

Verify the import:

```powershell
& C:\xampp\mysql\bin\mysql.exe -u root lms_db -e "SHOW TABLES; SELECT email, role, status FROM profiles;"
```

## 5. Create the Apache deployment junction

Run PowerShell with permission to create the junction:

```powershell
New-Item -ItemType Junction -Path C:\xampp\htdocs\lms -Target D:\LMS\dist
```

If `C:\xampp\htdocs\lms` already exists, verify or remove that specific target before creating the junction. Never point Apache directly at `D:\LMS`, because `database`, configuration, and private upload files must remain outside the public web root.

Start Apache in the XAMPP Control Panel and open `http://localhost/lms/`.

Direct SPA routes such as `http://localhost/lms/dashboard` are handled by `dist/.htaccess`. API requests are excluded from the SPA rewrite.

## 6. Demo credentials

All seeded users have password `DemoPass123!`.

| Role/status | Email |
|---|---|
| Active administrator | `admin@adfc.edu.ph` |
| Active instructor | `instructor@adfc.edu.ph` |
| Active instructor | `instructor2@adfc.edu.ph` |
| Active student | `student1@adfc.edu.ph` |
| Active student | `student2@adfc.edu.ph` |
| Pending student | `pending@adfc.edu.ph` |

The pending account can be activated with OneCampus ID `OC-STU-003` and email `pending@adfc.edu.ph`.

## 7. Password recovery in local development

The PHP backend creates a one-hour, single-use reset token. Because local XAMPP does not include an SMTP setup, the forgot-password page displays the local reset link when the email exists. The same link is written to the Apache PHP error log.

For production, replace this development behavior with an email provider and do not return reset URLs to the browser.

## 8. Private storage

Uploads are written beneath `D:\LMS\storage\uploads\materials` and `D:\LMS\storage\uploads\submissions`.

These files are outside `htdocs`. Downloads use short-lived session-bound URLs and are re-authorized by class membership, ownership, or class-manager permission.

Supported upload extensions are PDF, DOCX, and ZIP, with a 10 MB application limit. PHP/XAMPP `upload_max_filesize` and `post_max_size` must be at least as large.

## 9. Validation commands

```powershell
npm run lint
npm run build
& C:\xampp\php\php.exe -l D:\LMS\public\api\bootstrap.php
& C:\xampp\php\php.exe -l D:\LMS\public\api\config.php
& C:\xampp\php\php.exe -l D:\LMS\public\api\index.php
git diff --check
```

Recommended browser smoke tests:

1. Sign in as administrator and confirm all active classes are visible.
2. Run OneCampus sync and confirm the mock result reports 23 users, 4 subjects, 4 classes, and 20 enrollments.
3. Sign in as `student1@adfc.edu.ph` and confirm only enrolled classes are visible.
4. Sign in as the instructor, create and remove an announcement, and test assignment/quiz workflows.
5. Confirm a student cannot open administrator pages or retrieve another class's records/files.
6. Request a password reset and complete it through the local token link.

## 10. Production considerations

- Use a dedicated database user with a strong password and only required privileges.
- Serve over HTTPS and set `LMS_APP_URL` to the public HTTPS URL.
- Configure secure PHP session storage and an email provider.
- Replace the default development reset-link response.
- Restrict filesystem permissions on `storage/uploads` and local configuration.
- Set a real OneCampus API endpoint/key or disable synchronization if it is unavailable.
- Back up MariaDB and private uploads together.

## 11. Create a database handoff export

```powershell
& D:\LMS\database\export_database.ps1
```

The dump is written to `D:\LMS\database\exports\lms_db.sql`. That directory is ignored by Git because live exports contain account records and password hashes. Upload the dump only to a restricted-access Google Drive folder and share its printed SHA-256 checksum with authorized recipients.