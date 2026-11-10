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
database: adfc_lms
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

Edit `D:\LMS\api\config.local.php` as needed. It is ignored by Git. Environment variables `LMS_DB_HOST`, `LMS_DB_PORT`, `LMS_DB_NAME`, `LMS_DB_USER`, `LMS_DB_PASS`, `LMS_APP_URL`, `ONECAMPUS_API_URL`, and `ONECAMPUS_API_KEY` are also supported.

When `ONECAMPUS_API_URL` is empty, synchronization uses `D:\LMS\mock-onecampus\fixtures.json`.

## 4. Start and import MariaDB

Start MySQL/MariaDB in the XAMPP Control Panel, then import the schema and seed:

```powershell
& C:\xampp\mysql\bin\mysql.exe -u root -e "source D:/LMS/database/schema.sql; source D:/LMS/database/seed.sql;"
```

`database/schema.sql` drops and recreates the LMS tables. Do not run it against a database containing data that must be retained.

Verify the import:

```powershell
& C:\xampp\mysql\bin\mysql.exe -u root adfc_lms -e "SHOW TABLES; SELECT email, role, status FROM profiles;"
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