# ADFC OneCampus LMS migration package

Prepared for deployment on **November 17, 2026** from the supplied
`database/adfc_onecampus_updated (1).sql` structure. The supplied SQL dump is
not modified by this package.

## What this package does

1. Backfills only missing stable IDs for shared users, students, instructors,
   subjects, programs, classes, and class enrollments.
2. Creates read-only LMS projections for identities, subjects, classes,
   schedules/rooms, and enrollments.
3. Creates a subsystem-scoped administrator:
   - Username: `adfc_lms`
   - Initial password: `adfc1984`
   - Email identity: `marctucay321321@gmail.com`
   - Scope: `user_access_roles.module_code = 'lms'`
4. Repairs an LMS administrator accidentally stored with numeric `user_id = 0`
   while preserving `user_uid = USER-LMS-ADMIN-0001`.
5. Records the migrations in the shared `schema_migrations` table.
6. Supplies verification queries and an optional least-privilege MySQL account
   template.

## Important ownership rule

The LMS reads student, employee/instructor, subject, class, schedule, room, and
enrollment records from their Tier 1 owners. The migration does not manufacture
enrollment rows. The current supplied database contains zero
`class_enrollments`; the LMS enrollment projection will therefore remain empty
until the Enrollment Management System publishes those records.

## Local test at home (127.0.0.1)

1. Import `adfc_onecampus_updated (1).sql` into a new `adfc_onecampus` database
   in phpMyAdmin.
2. Import the following ready-to-import file in phpMyAdmin:

   `IMPORT_THIS_IN_PHPMYADMIN.sql`

   It explicitly contains `USE adfc_onecampus;` and includes migrations 001 and
   002. You do not need to paste those two migrations separately when
   using this combined file.
3. If the `adfc_lms` row shows `user_id = 0`, import
   `003_repair_lms_administrator_user_id.sql` as a separate repair migration.
4. Optionally run `verify_lms_migration.sql` from phpMyAdmin to see the detailed
   checks and retrievable rows.
5. Alternatively, open PowerShell and run the shared database migrations with:

   ```powershell
   & 'C:\xampp\htdocs\LMS\database\migrate_adfc_onecampus_lms_20261117\run_migrations.ps1'
   ```

6. Review the verification output. Every `failed_check` must be `0`.
7. Configure the LMS OneCampus connection to host `127.0.0.1`, database
   `adfc_onecampus`, and a MySQL account that has `SELECT` permission.
8. Open `http://localhost/b1-learning-management/`, use the Admin portal, and
   sign in with username `adfc_lms` or email
   `marctucay321321@gmail.com`, using password `adfc1984`.
9. Sign in. The LMS now reads the unified `adfc_onecampus` tables directly; a
   separate `lms_db` database is not used.

## School server deployment

### School network architecture

- `192.168.109.117`: existing MySQL/MariaDB server containing
  `adfc_onecampus`, plus the ADFC OneCampus dashboard.
- `192.168.109.152`: LMS Apache/PHP server containing
  `/b1-learning-management/`.
- Do **not** start MySQL in the XAMPP Control Panel on `192.168.109.152`.
- Start Apache on `192.168.109.152`. MySQL must be running and reachable on
  `192.168.109.117:3306`.

This package does **not** create a MySQL/database user. Use the existing school
database access supplied by the OneCampus team:

```text
Database host: 192.168.109.117
Database name: adfc_onecampus
Database user: onecampus
Database password: supplied existing OneCampus database password
```

These are database connection credentials. They are separate from the LMS web
administrator username `adfc_lms`.

For the current home test, local XAMPP MySQL is required only because the test
copy of `adfc_onecampus` is hosted locally. A separate `lms_db` is not required.

On `192.168.109.117`, back up `adfc_onecampus` and import:

1. `IMPORT_THIS_IN_PHPMYADMIN.sql` into MySQL on `.117` to prepare
   `adfc_onecampus` and create the web administrator.

Alternatively, run the shared migration from a machine that can reach MySQL:

```powershell
& 'C:\path\to\run_migrations.ps1' `
  -HostName '192.168.109.117' `
  -Database 'adfc_onecampus' `
  -User '<migration-user>' `
  -Password '<migration-user-password>'
```

The migration user needs permission to update the UID columns, create/replace
views, insert the LMS administrator and role assignment, and insert a migration
record. Do not run the optional service-account file until its placeholder
password and allowed host have been changed.

Do not copy the home-test `api/onecampus.setup.php` file to the school server.
If it already exists on `.152` and contains `127.0.0.1`, delete it and configure
the OneCampus connection again using `192.168.109.117`, because that saved setup
file overrides the default OneCampus connection.

On the setup screen tomorrow, enter:

```text
Host: 192.168.109.117
Port: 3306
Database: adfc_onecampus
Username: onecampus
Password: supplied existing OneCampus database password
```

If `.152` cannot connect to `.117:3306`, ask the existing OneCampus database
administrator to verify that the supplied `onecampus` account accepts a
connection from `.152`. Do not create or grant another account from this LMS
package.

## File order

For phpMyAdmin, import only:

1. `IMPORT_THIS_IN_PHPMYADMIN.sql` — migrates `adfc_onecampus`
2. `003_repair_lms_administrator_user_id.sql` — safe separate repair for an
   existing `adfc_lms` row with `user_id = 0`
3. Optionally import `verify_lms_migration.sql`

The migration package contains these files in order:

1. `001_prepare_lms_shared_data.sql`
2. `002_create_lms_administrator.sql`
3. `003_repair_lms_administrator_user_id.sql` is the separate ID repair
4. `verify_lms_migration.sql` is verification only

All required migrations are idempotent and may be rerun. The administrator
migration intentionally resets `adfc_lms` to the documented initial password
when rerun, so do not rerun migration 002 after changing that password unless a
password reset is intended.

## Retrieval views

- `vw_lms_users`
- `vw_lms_subjects`
- `vw_lms_classes`
- `vw_lms_class_schedules`
- `vw_lms_enrollments`

These views use `SQL SECURITY INVOKER`, so the LMS service account still needs
`SELECT` access to the underlying `adfc_onecampus` tables. They do not grant
permissions by themselves.

## Security follow-up

The LMS web administrator bootstrap password is an initial handoff credential.
Change it after the first successful server login. Database credentials are
separate and must be entered only in the ignored server-side setup file.
