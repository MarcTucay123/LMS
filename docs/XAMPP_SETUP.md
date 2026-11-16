# XAMPP deployment guide

This guide deploys the LMS at `http://SERVER_IP/b1-learning-management/` using XAMPP Apache/PHP and the unified `adfc_onecampus` database.

## 1. Requirements

- XAMPP installed at `C:\xampp`
- PHP 8.1 or later with `PDO`, `pdo_mysql`, `session`, `mbstring`, `fileinfo`, `curl`, and `openssl`
- Node.js and npm
- An NTFS volume that supports directory junctions

The checked XAMPP environment uses MariaDB 10.4.32. Apache must have `mod_rewrite` enabled and permit `.htaccess` overrides for `htdocs`.

## 2. Clone and create the working XAMPP deployment

```powershell
cd C:\xampp\htdocs
git clone https://github.com/MarcTucay123/LMS.git LMS
Set-ExecutionPolicy -Scope Process Bypass
& C:\xampp\htdocs\LMS\scripts\setup-xampp.ps1
```

The repository is physically stored at `C:\xampp\htdocs\LMS`. The script runs
`npm ci`, builds the ignored `dist` directory, and creates
`C:\xampp\htdocs\b1-learning-management` as a junction to the repository.

Git stores the source code and deployment script. It does not store
`node_modules`, `dist`, the Windows junction, private database setup files, or
uploaded files. Those are recreated on each server.

## 3. Configure the PHP API

The school deployment uses the existing shared database connection:

```text
database: adfc_onecampus
host:     192.168.109.117
port:     3306
user:     onecampus
password: supplied OneCampus password
app URL:  detected from the current server host and /b1-learning-management path
```

For a private file override, copy the ignored example:

```powershell
Copy-Item C:\xampp\htdocs\LMS\api\config.local.example.php C:\xampp\htdocs\LMS\api\config.local.php
```

Edit `C:\xampp\htdocs\LMS\api\config.local.php` as needed. It is ignored by Git. The preferred deployment method is the `/b1-learning-management/setup` screen.

On the setup screen enter host `192.168.109.117`, port `3306`, database
`adfc_onecampus`, username `onecampus`, and the supplied password.

For local testing when XAMPP/MariaDB and `adfc_onecampus` are on the same computer, use `127.0.0.1`. The setup page provides **This PC (home)** and **School server** shortcuts. `127.0.0.1` always means the computer running the LMS PHP API; it cannot reach the school database from home unless that database also exists locally.

Do not place MySQL credentials in any `VITE_*` variable. The pre-login setup form sends the connection details to PHP over the current LMS origin; PHP retains them in the server-side session and performs the database connection.

LAN users open the LMS at `http://192.168.109.152/b1-learning-management/`. Keep API requests relative so login and PHP session cookies remain on the same origin.

The dashboard reads the LMS `subsystem.json`, whose school URL is `http://192.168.109.152/b1-learning-management/`.

Before login, `/b1-learning-management/setup` verifies the unified tables and
writes the connection to private `api/onecampus.setup.php`. That file is ignored
by Git. Do not copy the home version to school if it contains `127.0.0.1`.

The LMS does not require `lms_db`. On `192.168.109.152`, start Apache only. MySQL
runs on `192.168.109.117`.

## 4. Prepare the shared database

Back up `adfc_onecampus` on `192.168.109.117`, then import
`database/migrate_adfc_onecampus_lms_20261117/IMPORT_THIS_IN_PHPMYADMIN.sql` if
the migration has not already been applied. Do not create another MySQL user.

## 5. Verify Apache deployment

Start Apache in the XAMPP Control Panel and open `http://localhost/b1-learning-management/` locally or `http://192.168.109.152/b1-learning-management/` from another PC.

Direct SPA routes are handled by the repository-root `.htaccess`, which serves the compiled `dist` application and PHP API.

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