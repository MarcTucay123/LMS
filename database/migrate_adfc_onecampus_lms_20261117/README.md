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
5. Publishes confirmed Enrollment records as explicit `lms:Student` RBAC grants
   and active `class_enrollments`, with transaction-scoped triggers for future
   enrollment approvals and subject changes. It never creates credentials or
   guesses missing account links.
6. Grants active instructors an explicit `lms:Instructor` role; assigned-class
   checks remain enforced by the LMS API.
7. Adds expiring LMS reset-token metadata to the shared user account while
   continuing to update the one central `users.password_hash` credential.
8. Records the migrations in the shared `schema_migrations` table.
9. Supplies verification queries and an optional least-privilege MySQL account
   template.

## Important ownership rule

The LMS reads student, employee/instructor, subject, class, schedule, room, and
enrollment records from their Tier 1 owners. Migration 004 derives LMS
memberships only from authoritative `Confirmed`
`enrollments`, `Enrolled` enrollment subjects, blocks, periods, and matching
active scheduled classes. Approved students without a linked `users.student_id`
remain without login access until the central Pre-Enrollment/account workflow
creates and links their credentials.

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
4. Import `004_publish_enrollment_access.sql` to enable explicit LMS student and
   instructor RBAC plus confirmed-class publication.
5. Import `005_add_exams_and_lms_audit_support.sql` to add the Exams category
   and optimized LMS audit-log retrieval.
6. Import `006_add_identification_and_essay_grading.sql` to replace short answer
   with Identification and add instructor-scored Essay questions.
7. Import `007_add_live_quiz_sessions.sql` to add enrollment-authorized,
   instructor-paced live quiz and exam sessions linked to existing classes and schedules.
8. Import `008_add_user_security_controls.sql` to add editable failed-login
   lockout and inactivity auto-logout controls.
9. Import `009_add_quiz_exam_file_submissions.sql` to add optional instructor
   attachments and student file submissions for regular quizzes and exams.
10. Import `010_add_quiz_file_grading.sql` to add instructor scoring for student
   quiz and exam file submissions.
11. Import `011_add_discussion_message_actions.sql` to add persistent instructor
    pinning for discussion conversations and messages. Message authors can unsend
    through the LMS API.
12. Import `012_add_discussion_replies_reactions_and_soft_delete.sql` to add
    message replies, emoji reactions, and Messenger-style deleted-message placeholders.
13. Import `013_add_discussion_membership_and_personal_hiding.sql` to require
    joining discussions and add per-user leave and delete-conversation behavior.
14. Import `014_add_discussion_notification_muting.sql` to add per-user timed or
    indefinite notification muting for joined discussions.
15. Import `015_add_discussion_attachments.sql` to add private file, image, video,
    and recorded-audio attachments to discussion messages.
16. Import `016_add_lms_profile_pictures.sql` to enable private user-uploaded profile
    pictures across LMS navigation, rosters, discussions, and activity views.
17. Import `017_add_discussion_video_calls.sql` to add the complete regular
    discussion-call schema: WebRTC signaling, presence, attendance state, in-call
    comments with private photo/file attachments, reactions, and screen sharing
    for every joined participant.
18. Import `018_finalize_regular_discussion_calls.sql` to upgrade an older call schema,
    add any missing live-comment attachment columns, remove the retired instructor
    live-session variant, and keep only member-started calls inside regular discussions.
19. Import `019_add_discussion_read_receipts.sql` to store each joined participant's
    latest read discussion message for compact Seen-by profile indicators.
20. Import `020_add_discussion_live_attendance_history.sql` to preserve the complete
    enrolled-student attendance roster when the call host ends a discussion call.
21. Import `021_add_live_call_attendance_controls.sql` to let administrators enable
    individual inactive-attendance triggers and configure the activity timeout.
22. Import `022_add_my_learning_paths.sql` to add instructor-built course modules,
    ordered learning activities, prerequisites, timelines, and student completion tracking.
23. Optionally run `verify_lms_migration.sql` from phpMyAdmin to see the detailed
   checks and retrievable rows.
6. Alternatively, open PowerShell and run the shared database migrations with:

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
3. `004_publish_enrollment_access.sql`
4. `005_add_exams_and_lms_audit_support.sql`
5. `006_add_identification_and_essay_grading.sql`
6. `007_add_live_quiz_sessions.sql`
7. `008_add_user_security_controls.sql`
8. `009_add_quiz_exam_file_submissions.sql`
9. `010_add_quiz_file_grading.sql`
10. `011_add_discussion_message_actions.sql`
11. `012_add_discussion_replies_reactions_and_soft_delete.sql`
12. `013_add_discussion_membership_and_personal_hiding.sql`
13. `014_add_discussion_notification_muting.sql`
14. `015_add_discussion_attachments.sql`
15. `016_add_lms_profile_pictures.sql`
16. `017_add_discussion_video_calls.sql`
17. `018_finalize_regular_discussion_calls.sql`
18. `019_add_discussion_read_receipts.sql`
19. `020_add_discussion_live_attendance_history.sql`
20. `021_add_live_call_attendance_controls.sql`
21. Optionally import `verify_lms_migration.sql`

The migration package contains these files in order:

1. `001_prepare_lms_shared_data.sql`
2. `002_create_lms_administrator.sql`
3. `003_repair_lms_administrator_user_id.sql` is the separate ID repair
4. `004_publish_enrollment_access.sql` publishes Enrollment-owned access
5. `005_add_exams_and_lms_audit_support.sql` adds exam classification and LMS
   audit-log lookup support
6. `006_add_identification_and_essay_grading.sql` adds Identification and manual
   Essay grading
7. `007_add_live_quiz_sessions.sql` adds code-free live sessions authorized by
   existing OneCampus class enrollment
8. `008_add_user_security_controls.sql` adds LMS-owned brute-force protection
   settings, login-attempt lockouts, and inactivity timeout configuration
9. `009_add_quiz_exam_file_submissions.sql` adds quiz and exam file submissions
10. `010_add_quiz_file_grading.sql` adds file-submission grading
11. `011_add_discussion_message_actions.sql` adds discussion message actions
12. `012_add_discussion_replies_reactions_and_soft_delete.sql` adds replies,
    reactions, and deleted-message placeholders
13. `013_add_discussion_membership_and_personal_hiding.sql` adds discussion membership
14. `014_add_discussion_notification_muting.sql` adds discussion notification muting
15. `015_add_discussion_attachments.sql` adds discussion attachments and recordings
16. `016_add_lms_profile_pictures.sql` adds LMS profile pictures
17. `017_add_discussion_video_calls.sql` adds the complete discussion-call schema
18. `018_finalize_regular_discussion_calls.sql` removes the retired separate
    discussion live-session variant and finalizes regular discussion calls
19. `019_add_discussion_read_receipts.sql` adds persistent conversation read receipts
20. `020_add_discussion_live_attendance_history.sql` adds finalized call attendance history
21. `021_add_live_call_attendance_controls.sql` adds configurable inactive-attendance rules
22. `verify_lms_migration.sql` is verification only

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
