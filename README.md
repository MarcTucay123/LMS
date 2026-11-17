# ADFC OneCampus LMS

Web-based Learning Management System for Asian Development Foundation College.

## Runtime architecture

- React 19, TypeScript, Vite, React Router, and Tailwind CSS frontend
- PHP 8 API served by XAMPP Apache
- Unified MariaDB/MySQL `adfc_onecampus` database
- PHP session authentication and server-side role/class authorization
- Direct unified-database access for identity, subjects, classes, enrollments, and LMS records
- Private uploads stored outside the public web directory and streamed through authorized API endpoints

The school deployment uses two computers:

| Computer | Purpose |
|---|---|
| `192.168.109.117` | Main OneCampus dashboard and the shared `adfc_onecampus` MySQL/MariaDB database |
| `192.168.109.152` | LMS XAMPP Apache/PHP web server |

The browser compatibility client in `src/lib/supabase.ts` retains the former Supabase-style frontend calls, but runtime requests go to `public/api/index.php`.

Academic data ownership and database handoff rules are documented in [`docs/DATABASE_INTEGRATION_CONTRACT.md`](docs/DATABASE_INTEGRATION_CONTRACT.md). More detailed XAMPP information is available in [`docs/XAMPP_SETUP.md`](docs/XAMPP_SETUP.md).

## School deployment overview

Deploy in this order:

1. Back up and migrate `adfc_onecampus` on `192.168.109.117`.
2. Clone and build the LMS on `192.168.109.152`.
3. Create the public `b1-learning-management` junction by running the setup script.
4. Configure the LMS database connection from the `/setup` page.
5. Copy the LMS `subsystem.json` metadata into the main dashboard's `SUBSYSTEMS` folder.
6. Test the public LMS URL from another computer on the school network.

## 1. Requirements

Install or confirm the following on the LMS web server (`192.168.109.152`):

- XAMPP at `C:\xampp`
- PHP 8.1 or later
- Node.js and npm
- Git for Windows
- PowerShell
- An NTFS drive that supports directory junctions
- Apache `mod_rewrite` enabled with `.htaccess` overrides allowed for `htdocs`

The PHP installation must enable `PDO`, `pdo_mysql`, `session`, `mbstring`, `fileinfo`, `curl`, and `openssl`.

## 2. Clone the LMS on the web-server PC

Open **PowerShell** on `192.168.109.152` and run:

```powershell
Set-Location C:\xampp\htdocs
git clone https://github.com/MarcTucay123/LMS.git LMS
Set-Location C:\xampp\htdocs\LMS
```

The real source-code and Git repository will be:

```text
C:\xampp\htdocs\LMS
```

Do not clone a second copy into `b1-learning-management`. The setup script creates that public path as a junction to the real `LMS` repository.

### Updating an existing clone

If `C:\xampp\htdocs\LMS` already exists, do not run `git clone` again. Update it instead:

```powershell
Set-Location C:\xampp\htdocs\LMS
git status
git pull --ff-only
```

Review `git status` before pulling. Do not discard local work or private server configuration accidentally.

## 3. Allow the PowerShell setup script to run

Windows may block local `.ps1` scripts. In the same PowerShell window, run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

This changes the execution policy only for the **current PowerShell process**. It does not permanently weaken the computer's system-wide policy. The temporary bypass ends when that PowerShell window is closed.

You can confirm the effective policy with:

```powershell
Get-ExecutionPolicy -List
```

If school Group Policy prevents even a process-scoped bypass, contact the computer or network administrator instead of changing machine-wide security settings.

## 4. Build the application and create the public junction

Run:

```powershell
& 'C:\xampp\htdocs\LMS\scripts\setup-xampp.ps1'
```

The script:

1. Runs `npm ci` when `package-lock.json` exists, otherwise `npm install`.
2. Runs `npm run build` and creates `C:\xampp\htdocs\LMS\dist`.
3. Creates this Windows directory junction:

   ```text
   C:\xampp\htdocs\b1-learning-management
       -> C:\xampp\htdocs\LMS
   ```

4. Leaves the Git repository physically stored at `C:\xampp\htdocs\LMS`.

The junction does not duplicate the project. Changes made in `LMS` are immediately visible through `b1-learning-management`.

If `C:\xampp\htdocs\b1-learning-management` already exists but is not the expected junction, the script stops without deleting it. Inspect, back up, rename, or remove that conflicting path manually before running the script again.

To rerun setup without reinstalling dependencies, use:

```powershell
& 'C:\xampp\htdocs\LMS\scripts\setup-xampp.ps1' -SkipInstall
```

Do not use `/LMS/` as the public school URL. The configured public URL is:

```text
http://192.168.109.152/b1-learning-management/
```

## 5. Back up the shared database before migration

The real school database is on:

```text
Server:   192.168.109.117
Database: adfc_onecampus
```

Before importing the LMS migration:

1. Open phpMyAdmin on `192.168.109.117`.
2. Select `adfc_onecampus`.
3. Use **Export** to create a complete SQL backup.
4. Store the backup safely until the LMS deployment and login tests pass.

Do not overwrite the live school database with the development dump `database/adfc_onecampus_updated (1).sql`. That large dump is for preparing a separate test database, not for replacing the existing school database.

## 6. Import the LMS migration in phpMyAdmin

On the database-server PC (`192.168.109.117`), import this file into the existing `adfc_onecampus` database:

```text
C:\xampp\htdocs\LMS\database\migrate_adfc_onecampus_lms_20261117\IMPORT_THIS_IN_PHPMYADMIN.sql
```

If the repository is not stored on `.117`, copy only the required SQL migration file to that PC or access it from approved removable/network storage.

In phpMyAdmin:

1. Connect to MySQL/MariaDB on `192.168.109.117`.
2. Select the `adfc_onecampus` database.
3. Open **Import**.
4. Select `IMPORT_THIS_IN_PHPMYADMIN.sql`.
5. Start the import and wait for the success message.

The migration already contains:

```sql
USE `adfc_onecampus`;
```

The combined file performs migrations 001 and 002. Do not separately import
`001_prepare_lms_shared_data.sql` and `002_create_lms_administrator.sql` after
successfully importing the combined file.

If phpMyAdmin shows the `adfc_lms` account with `user_id = 0`, import this
separate repair migration immediately afterward:

```text
C:\xampp\htdocs\LMS\database\migrate_adfc_onecampus_lms_20261117\003_repair_lms_administrator_user_id.sql
```

The repair assigns a valid numeric `user_id`, preserves
`user_uid = USER-LMS-ADMIN-0001`, and repairs the LMS role relationship.

### What the migration changes

The migration:

- Populates only missing stable IDs in existing shared records
- Creates or replaces these read-only LMS projections:
  - `vw_lms_users`
  - `vw_lms_subjects`
  - `vw_lms_classes`
  - `vw_lms_class_schedules`
  - `vw_lms_enrollments`
- Creates or repairs the subsystem-scoped LMS administrator
- Assigns the `Administrator` role with `module_code = 'lms'`
- Repairs an invalid LMS administrator `user_id = 0` without changing its
  stable `user_uid`
- Records the migrations in `schema_migrations`

The migration does not contain `DROP TABLE`, `DROP DATABASE`, `DELETE`, or `TRUNCATE` statements. The importing account still needs permission to update the UID columns, create or replace views, insert the LMS administrator and role assignment, and insert migration records.

### LMS administrator created by the migration

```text
Username:         adfc_lms
Email:            marctucay321321@gmail.com
Initial password: adfc1984
Scope:            lms
```

Change the initial password after the first successful login.

The migration is designed to be rerunnable, but rerunning it intentionally resets `adfc_lms` to the documented initial password and sets the account to require another password change. Do not rerun it after changing the password unless a reset is intended.

## 7. Verify the database migration

After the main import, optionally import this verification script in phpMyAdmin:

```text
C:\xampp\htdocs\LMS\database\migrate_adfc_onecampus_lms_20261117\verify_lms_migration.sql
```

Every value in the `failed_check` column must be:

```text
0
```

The main import should also return an LMS administrator row equivalent to:

```text
adfc_lms | marctucay321321@gmail.com | Active | Administrator | lms
```

The projection row counts can legitimately be zero when an authoritative OneCampus subsystem has not yet published records—for example, when `class_enrollments` is still empty. A zero projection row count is different from a nonzero `failed_check`.

## 8. Configure the LMS connection to OneCampus

On `192.168.109.152`, start **Apache** in XAMPP. Do not start a separate MySQL service there for the school deployment; the database remains on `192.168.109.117`.

Open:

```text
http://192.168.109.152/b1-learning-management/setup
```

Enter:

```text
Host:     192.168.109.117
Port:     3306
Database: adfc_onecampus
Username: onecampus
Password: supplied existing OneCampus database password
```

The database username `onecampus` is not the same as the LMS website administrator `adfc_lms`.

The setup page writes the private machine-local connection to:

```text
C:\xampp\htdocs\LMS\api\onecampus.setup.php
```

That file is ignored by Git. Do not commit it, share its password, or copy a home-test version containing `127.0.0.1` to the school server. If an old home-test file exists, disconnect through the setup page or delete that private file before configuring the school connection.

If `.152` cannot connect to `.117:3306`, ask the OneCampus database administrator to confirm that:

- MySQL/MariaDB accepts network connections on `192.168.109.117:3306`
- The firewall permits `.152` to connect
- The existing `onecampus` account accepts connections from `.152`
- The account has the permissions required by the LMS

Do not create a new database account unless authorized by the OneCampus database administrator.

## 9. Add the LMS metadata to the main dashboard

Place an LMS `subsystem.json` entry in the appropriate LMS folder under the main OneCampus dashboard's `SUBSYSTEMS` directory on `192.168.109.117`.

Use explicit table names so the dashboard does not need wildcard support:

```json
{
  "name": "Learning Management System",
  "block": 1,
  "group": "",
  "status": "in-progress",
  "members": [
    ""
  ],
  "code": "LMS",
  "url": "http://192.168.109.152/b1-learning-management/",
  "tables": [
    "learning_assignments",
    "learning_discussion_posts",
    "learning_discussion_topics",
    "learning_materials",
    "learning_registration_classes",
    "learning_registration_requests",
    "learning_sync_logs",
    "quizzes",
    "quiz_answer_keys",
    "quiz_attempts",
    "quiz_questions",
    "assignment_submissions"
  ]
}
```

The `tables` field declares LMS-owned tables for dashboard metadata. It does not create, import, move, or grant access to database tables.

Do not add shared authoritative tables such as `users`, `students`, `instructors`, `subjects`, `academic_classes`, `class_enrollments`, `class_meetings`, or `rooms` merely because the LMS reads them. Those records remain owned by their corresponding OneCampus subsystems.

The main dashboard's `SUBSYSTEMS` folder needs only the subsystem metadata. Do not copy the complete LMS repository, `dist`, junction, database dump, or private connection file into that folder.

## 10. Start and test the school deployment

On `192.168.109.152`:

1. Start Apache in the XAMPP Control Panel.
2. Leave the local MySQL service stopped for the school deployment.
3. Open the LMS locally and then from another LAN computer:

   ```text
   http://192.168.109.152/b1-learning-management/
   ```

4. Sign in through the Admin portal with:

   ```text
   Username: adfc_lms
   Password: adfc1984
   ```

5. Change the initial password when prompted.
6. Open the LMS card from the main OneCampus dashboard and confirm that it opens the same URL.

Recommended smoke tests:

1. Confirm the setup page reports a successful `adfc_onecampus` connection.
2. Sign in as the LMS administrator.
3. Confirm subjects, classes, instructors, schedules, and enrollments appear when their owning systems contain records.
4. Confirm LMS materials, discussions, assignments, submissions, and quizzes can be accessed according to role and class membership.
5. Confirm unauthorized users cannot open administrator pages or retrieve records/files belonging to another class.

## 11. Validate the project after cloning or updating

From PowerShell:

```powershell
Set-Location C:\xampp\htdocs\LMS
npm run lint
npm run build
& 'C:\xampp\php\php.exe' -l 'C:\xampp\htdocs\LMS\public\api\bootstrap.php'
& 'C:\xampp\php\php.exe' -l 'C:\xampp\htdocs\LMS\public\api\config.php'
& 'C:\xampp\php\php.exe' -l 'C:\xampp\htdocs\LMS\public\api\index.php'
git diff --check
```

If you update the source later, rebuild the production frontend:

```powershell
Set-Location C:\xampp\htdocs\LMS
git pull --ff-only
npm ci
npm run build
```

The junction does not need to be recreated after every pull as long as it still points to `C:\xampp\htdocs\LMS`.

## 12. Files that are local and not stored by Git

Git does not store or deploy these machine-specific/runtime items:

- `node_modules`
- `dist`
- `C:\xampp\htdocs\b1-learning-management` junction
- `api/onecampus.setup.php`
- `api/config.local.php`
- Private uploaded files
- Live database backups or exports

Recreate or configure these on each server. Never commit database passwords, production exports, or private uploads.

## 13. Main project structure

```text
api/                  Private machine-local PHP configuration examples
database/             Shared database migration package and test database material
docs/                 Integration contract and detailed XAMPP guide
public/api/            PHP API bootstrap, configuration, and action router
scripts/               XAMPP build and junction setup script
src/                   React application
subsystem.json         LMS metadata template
```

## 14. Supported workflows

- Session login, logout, recovery-token password reset, and account activation
- Direct sign-in for active users provisioned by OneCampus systems
- Role and account-status administration
- Class synchronization and role-scoped classroom access
- Instructor-managed materials, announcements, discussions, assignments, grading, and quizzes
- Administrator classroom monitoring and progress reporting
- Authorized private upload, removal, and signed download flows

MariaDB does not provide Supabase Row Level Security. Every PHP endpoint therefore performs explicit session, role, class-membership, ownership, and instructor/administrator checks before reading or changing records.

## Final school deployment checklist

- [ ] `adfc_onecampus` was backed up on `192.168.109.117`
- [ ] `IMPORT_THIS_IN_PHPMYADMIN.sql` was imported into the existing `adfc_onecampus`
- [ ] Every database `failed_check` is `0`
- [ ] The repository was cloned to `C:\xampp\htdocs\LMS` on `192.168.109.152`
- [ ] The process-scoped PowerShell execution policy command was run
- [ ] `scripts\setup-xampp.ps1` completed successfully
- [ ] `C:\xampp\htdocs\b1-learning-management` points to `C:\xampp\htdocs\LMS`
- [ ] Apache is running on `.152`
- [ ] The LMS setup page connects to `.117:3306/adfc_onecampus`
- [ ] The explicit-table `subsystem.json` was placed in the main dashboard's `SUBSYSTEMS` folder
- [ ] The LMS opens at `http://192.168.109.152/b1-learning-management/`
- [ ] The main dashboard LMS card opens the same URL
- [ ] `adfc_lms` can sign in and the initial password was changed