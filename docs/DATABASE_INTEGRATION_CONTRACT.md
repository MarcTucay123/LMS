# ADFC LMS database integration contract

## Purpose

The LMS participates in the shared ADFC system but must not become a second source of truth for academic master data. External records may be stored locally as synchronized projections so LMS foreign keys, authorization, and classroom workflows remain fast and reliable.

## Authoritative ownership

| Data | Authoritative subsystem | LMS behavior |
|---|---|---|
| Faculty/instructor identity | Employee Management System | Read-only synchronized profile |
| Student identity and official status | Enrollment Management / OneCampus | Read-only synchronized profile |
| Subjects and course catalog | Enrollment/Course Catalog | Read-only synchronized subject |
| Sections, offerings, instructor assignments, rooms, and schedules | Class Scheduling and Room Utilization | Read-only synchronized class offering |
| Student-class enrollment | Enrollment Management System | Read-only synchronized enrollment |
| LMS authentication and registration applications | LMS | LMS-owned |
| Materials and announcements | LMS | LMS-owned |
| Discussion topics and replies | LMS | LMS-owned |
| Assignments, submissions, and LMS grades | LMS | LMS-owned; official grade transfer requires a separate integration contract |
| Quizzes, questions, answer keys, and attempts | LMS | LMS-owned |

## Synchronized projection tables

The following tables exist in `lms_db` to support LMS joins and access control. They are not independent academic master tables:

- `profiles`
- `subjects`
- `classes`
- `enrollments`

Each contains:

- A stable local UUID used by LMS foreign keys
- A nullable `onecampus_*_id` external identifier
- `source_system`, naming the authoritative owner
- `synced_at`, recording the latest successful projection update

External records must be updated through the synchronization service. The generic LMS query API rejects direct class insertion and editing.

## LMS-owned tables

### Authentication and access

- `users`
- `registration_applications`
- `registration_application_classes` — requested subjects retained for review/audit only; not official enrollment
- `activation_records`
- `sync_logs`

### Teaching and learning

- `materials`
- `announcements`
- `discussion_topics`
- `discussion_posts`
- `assignments`
- `submissions`
- `quizzes`
- `quiz_questions`
- `quiz_answer_keys`
- `quiz_attempts`

## Write rules

1. The LMS must not create or reassign official class offerings.
2. LMS registration approval grants application access only.
3. Approval does not create official enrollment or instructor assignment records.
4. Enrollment and teaching assignments appear after synchronization from their owner.
5. `discussion_topics` and `discussion_posts` are valid LMS-specific tables and are not duplicates of another listed subsystem.
6. Shared external IDs must never be fabricated by the LMS. Locally registered profiles keep `onecampus_user_id = NULL` until an authoritative system links them.
7. Synchronization links an incoming external identity to an existing LMS registration by external ID first, then by normalized email, preventing duplicate profiles when the authoritative record becomes available later.

## Import and migration files

- Clean installation: `database/schema.sql`, then `database/seed.sql` for demonstration data only.
- Existing installation: `database/migrations/20261110_academic_data_ownership.sql`.
- Export helper: `database/export_database.ps1`.

## Unified database table mapping

When `ADFC_OneCampus_Unified_Schema.sql` is hosted on a shared MySQL/MariaDB server, the LMS reads it through the PHP API using a dedicated read-only connection. It does not connect from the browser and it does not duplicate the authoritative tables.

| Unified source | Owner | LMS projection / use |
|---|---|---|
| `users`, `instructors`, `students` | Employee Management / Central Auth and Enrollment Management | `profiles`; authentication remains in LMS `users` |
| `subjects` | Subject and Course Catalog | `subjects` |
| `academic_periods`, `academic_classes`, `instructors` | Class Scheduling System | `classes` |
| `fe_class_enrollments` | Enrollment Management System | `enrollments` |
| `lms_*` teaching tables | LMS | Use only when deploying the unified database as the LMS content store; do not import them into an existing `lms_db` installation |

The adapter uses stable `*_uid` values where available and deterministic prefixed source IDs otherwise. LMS-local UUIDs remain the foreign keys used by the application.

## Recommended database upload/import order

1. Import the shared identity and academic master tables from `ADFC_OneCampus_Unified_Schema.sql` on the database server.
2. Create a dedicated read-only database account for the LMS with `SELECT` access to `adfc_onecampus` only.
3. Import `database/schema.sql` into the LMS-owned `lms_db` database.
4. Optionally import `database/seed.sql` only for demonstration data.
5. Configure `ONECAMPUS_DB_HOST`, `ONECAMPUS_DB_PORT`, `ONECAMPUS_DB_NAME`, `ONECAMPUS_DB_USER`, and `ONECAMPUS_DB_PASS` on the PHP server.
6. Sign in as an LMS administrator and run **Sync now**. The LMS updates `profiles`, `subjects`, `classes`, and `enrollments` without changing the source tables.

## Google Drive handoff

Upload these non-sensitive files for programmers:

- `database/schema.sql`
- `database/migrations/20261110_academic_data_ownership.sql`
- `docs/DATABASE_INTEGRATION_CONTRACT.md`

Upload a generated SQL dump only to a restricted folder. A live dump contains email addresses, account records, password hashes, class activity, submissions, and grades. Do not place it in a public/shared-by-link folder.

After export, send the SHA-256 value with the filename so recipients can confirm the file was not corrupted.