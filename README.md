# ADFC OneCampus LMS

Web-based Learning Management System for Asian Development Foundation College. The planned foundation, administration, synchronization, and class-learning phases are implemented.

- GitHub repository: `https://github.com/MarcTucay123/LMS.git`
- Hosted Supabase project reference: `ynsyycrrtgzmgjwwlyfm`

## Implemented features

- React, Vite, TypeScript, React Router, and Tailwind CSS
- Supabase browser client using only the public anon key
- Email/password login, password recovery, and logout
- Public email registration for student, instructor, and administrator applicants
- Administrator approval with automatically generated OC and account IDs
- Instructor class assignment during approval with automatic dashboard visibility
- OneCampus-record-based account activation through a Supabase Edge Function
- Database-owned `student`, `instructor`, and `admin` roles
- Role-aware application shell and protected routes
- Dashboard listing only classes allowed by PostgreSQL Row Level Security (RLS)
- Protected class overview route
- Local migration and deterministic demo seed
- Admin-only user role and account-status management
- Admin-only class offering management
- OneCampus synchronization Edge Function with real API support and mock fallback
- Sync history and record counts
- Secure class materials with private file downloads and external links
- Class announcements and threaded discussions
- Assignment publishing, private student submissions, grading, and feedback
- Quiz authoring, protected answer keys, automatic scoring, and one-attempt enforcement
- Student progress summaries and instructor/admin gradebooks
- Functional role-aware sidebar navigation for classes, materials, assignments, quizzes, discussions, announcements, and progress reports

All class workspace tabs shown in the application are functional. Database RLS and security-definer RPCs enforce the same role boundaries as the user interface.

## Approved system scope

The LMS is a web-based subsystem of ADFC OneCampus for course content delivery and learning-activity monitoring. It uses authorized shared account, subject, class, instructor, and enrollment identifiers from OneCampus to restrict access to assigned or enrolled classes.

### Included functionality

- Course access for authorized administrators, assigned instructors, and enrolled students
- Lessons, syllabi, downloadable files, and external course resources
- Assignment instructions, deadlines, private submissions, status tracking, scores, and feedback
- Quiz availability, attempts, automatic scoring for objective items, and instructor review workflows
- Course announcements and moderated discussions
- Student learning-progress views, outstanding/completed activity tracking, and available activity-score summaries
- Deadline and feedback notices plus class activity completion and score reports

### Delimitations

- The LMS does not create or maintain OneCampus master student, instructor, subject, or enrollment records.
- Attendance, enrollment processing, class/room scheduling, faculty evaluation, library circulation, and live video classes are outside the system.
- Scores shown in the LMS are assignment and quiz activity results only; they are not official final-grade computation.
- The application is browser-based and has no separate native mobile application.
- Course content is private to authorized class members and administrators and is not open to the general public.

## Role navigation

All sidebar links are backed by routable pages and may be refreshed or opened directly:

- **All active roles:** Dashboard, authorized classes, materials, assignments, quizzes, discussions, announcements, and progress/reports
- **Administrator:** User accounts, master class offerings, and OneCampus synchronization in addition to LMS class oversight
- **Instructor:** Assigned-class authoring, moderation, grading, feedback, and class progress reports
- **Student:** Enrolled-class resources, submissions, quiz attempts, discussions, notices, and personal progress

## Prerequisites

- Node.js 20 or newer
- npm
- Docker Desktop (for local Supabase)
- Supabase CLI (included as a dev dependency; use it through `npx supabase`)

## Local setup

1. Install dependencies:

   ```powershell
   Set-Location 'D:\LMS'
   npm install
   ```

2. Start Docker Desktop, then start Supabase:

   ```powershell
   npx supabase start
   ```

3. Apply migrations and seed data:

   ```powershell
   npx supabase db reset
   ```

4. Copy `.env.example` to `.env`. Obtain the local URL and publishable/anon key from `npx supabase status`:

   ```env
   VITE_SUPABASE_URL=http://127.0.0.1:54321
   VITE_SUPABASE_PUBLISHABLE_KEY=<local publishable or anon key>
   ```

5. Serve the Edge Functions in a separate terminal:

   ```powershell
   npx supabase functions serve
   ```

6. Start the web app:

   ```powershell
   npm run dev
   ```

7. Open `http://localhost:5173`.

## Hosted Supabase setup

1. Create/link a Supabase project.
2. Apply the migration with `npx supabase db push`.
3. Use `supabase/seed.sql` only for a non-production demo environment.
4. For mock mode, do not set `ONECAMPUS_API_URL`; the function automatically uses the bundled fixtures. For the real API, configure both secrets:

   ```powershell
   npx supabase secrets set ONECAMPUS_API_URL="https://onecampus.example/api/lms-sync" ONECAMPUS_API_KEY="<secret-key>"
   ```

5. Deploy the Edge Functions:

   ```powershell
   npx supabase functions deploy activate-account --no-verify-jwt
   npx supabase functions deploy register-account --no-verify-jwt
   npx supabase functions deploy sync-onecampus
   ```

6. Configure the frontend with the hosted project URL and publishable key.

Supabase automatically provides `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to deployed Edge Functions. The service-role key must never be added to `.env`, Vite variables, or browser code.

## Vercel deployment

The repository includes `vercel.json` with the Vite build settings and an SPA rewrite for React Router routes.

1. Import or connect `MarcTucay123/LMS` in Vercel and set the production branch to `main`.
2. In **Project Settings → Environment Variables**, add these variables for Production, Preview, and Development:

   ```env
   VITE_SUPABASE_URL=https://ynsyycrrtgzmgjwwlyfm.supabase.co
   VITE_SUPABASE_PUBLISHABLE_KEY=<hosted Supabase publishable key>
   ```

3. Keep the project root directory at the repository root. Vercel will run `npm run build` and serve `dist`.
4. Push to `main` or select **Deployments → Redeploy** to create the production deployment.

In Supabase **Authentication → URL Configuration**, add each deployed application origin followed by `/reset-password` to the allowed redirect URLs (for example, `https://your-domain.example/reset-password`). Local development should allow `http://localhost:5173/reset-password`.

Do not add `SUPABASE_SERVICE_ROLE_KEY` or `ONECAMPUS_API_KEY` to Vercel. Those are Supabase Edge Function secrets, not frontend variables.

## Environment variables

### Browser (`.env`)

| Variable | Required | Purpose |
| --- | --- | --- |
| `VITE_SUPABASE_URL` | Yes | Supabase project API URL |
| `VITE_SUPABASE_PUBLISHABLE_KEY` | Yes | Public browser publishable key |

### Edge Function secrets

| Variable | Phase | Purpose |
| --- | --- | --- |
| `ONECAMPUS_API_URL` | Phase 2 | OneCampus REST API endpoint; empty uses mock fixtures |
| `ONECAMPUS_API_KEY` | Phase 2 | Secret OneCampus API credential; required only for the real API |

Do not prefix secrets with `VITE_`. `SUPABASE_SERVICE_ROLE_KEY` and the OneCampus API key are server-side only.

## Public registration and approval

Each login portal has a matching fixed-role registration form:

- Student: `/login?portal=student` → `/register/student`
- Instructor: `/login?portal=instructor` → `/register/instructor`
- Administrator: `/login?portal=admin` → `/register/admin`

The registration forms do not contain a role selector. The route fixes the requested role and follows this workflow:

1. Student applicants provide their Student ID, four-digit class code, structured name, active email, program, year level, block, semester, academic year, selected active class offerings, password, and terms acceptance. Instructor and administrator applicants keep the simpler structured-name, email, and password form. The system generates the display name from the structured name fields.
2. The public `register-account` Edge Function creates the Supabase Auth credential and a pending `registration_applications` row. It does not create an LMS profile or accept a user-supplied OC ID.
3. The applicant cannot enter the LMS while the application is pending because no active profile exists.
4. An existing active administrator opens **Registration approvals** and approves or rejects the request.
5. Approval generates a sequential OneCampus identifier such as `OC-STU-000001`, `OC-FAC-000002`, or `OC-ADMIN-000003`. Student profiles use the submitted Student ID as their internal account ID; instructor and administrator account IDs are generated.
6. Student approval uses the submitted Student ID as `profiles.school_id` and creates enrollments for the selected active offerings atomically.
7. For an instructor application, the administrator can select active classes during approval. The database updates `classes.instructor_id`, so those classes automatically appear on the instructor dashboard after sign-in.
8. Administrator applications are never self-approved; they require an existing active administrator.

To deploy this workflow to hosted Supabase, apply:

```powershell
npx supabase db push
npx supabase functions deploy register-account --no-verify-jwt
```

If using the Supabase SQL Editor instead of the CLI, paste and run the complete contents of these files in order:

```text
supabase/migrations/202611020005_public_registration_approval.sql
supabase/migrations/202611020006_allow_all_email_providers.sql
supabase/migrations/202611020007_structured_registration_names.sql
supabase/migrations/202611020008_expanded_student_registration.sql
```

Then deploy the `register-account` Edge Function from the CLI. The migration alone creates the database approval workflow, but the Edge Function is required for public registration because Auth administration must remain server-side.

If registration shows that the service has not been deployed, authenticate the CLI and deploy both the pending database migration and function:

```powershell
npx supabase login
npx supabase link --project-ref ynsyycrrtgzmgjwwlyfm
npx supabase db push
npx supabase functions deploy register-account --project-ref ynsyycrrtgzmgjwwlyfm --no-verify-jwt
```

Verify the function is present with:

```powershell
npx supabase functions list --project-ref ynsyycrrtgzmgjwwlyfm
```

## Demo accounts

All active demo accounts use password `DemoPass123!`.

| Role | Email | Expected classes |
| --- | --- | --- |
| Admin | `admin@adfc.edu.ph` | All 3 active classes |
| Instructor | `instructor@adfc.edu.ph` | IT 101 and ENG 102 |
| Second instructor | `instructor2@adfc.edu.ph` | MATH 103 |
| Student | `student1@adfc.edu.ph` | IT 101 and ENG 102 |
| Second student | `student2@adfc.edu.ph` | MATH 103 |

Legacy OneCampus activation test fixture (initially pending):

- OneCampus ID: `OC-STU-003`
- School email: `pending@adfc.edu.ph`
- Choose a password meeting the displayed requirements.

The legacy activation Edge Function remains available for records imported or pre-created through OneCampus integration. New public applicants use `/register` and do not enter an OC ID.

## Phase 1 test checklist

1. **Authentication:** Sign in as each demo role and confirm logout returns to `/login`.
2. **Role dashboards:**
   - Admin sees 3 classes.
   - `instructor@adfc.edu.ph` sees 2 classes.
   - `student1@adfc.edu.ph` sees 2 classes.
   - `student2@adfc.edu.ph` sees only MATH 103.
3. **Direct URL protection:** Sign in as `student1@adfc.edu.ph`, then open `/classes/20000000-0000-4000-8000-000000000003`. The app must show “Class unavailable”; the database returns no class row.
4. **Authorized URL:** With the same student, open `/classes/20000000-0000-4000-8000-000000000001`. The class overview must load.
5. **Registration:** Submit a student application using a valid email provider and confirm sign-in is blocked until administrator approval.
6. **Instructor approval:** Submit an instructor application, select classes during approval, then confirm those classes appear on the approved instructor dashboard.
7. **Admin approval:** Submit an administrator application and confirm only an existing active administrator can approve it.

## Phase 2 test checklist

1. Sign in through the administrator login using `admin@adfc.edu.ph`.
2. Open **OneCampus sync** and select **Sync now**.
3. With `ONECAMPUS_API_URL` empty, verify the result reports mock fixtures and imports:
   - 23 users: 3 instructors and 20 students
   - 4 subjects
   - 4 classes
   - 20 enrollments
4. Verify a success row appears in `sync_logs` with matching record counts.
5. Run synchronization again and confirm it updates existing records without duplicating OneCampus IDs.
6. Open **User accounts**, change a non-admin user's status or role, save, and refresh the page.
7. Confirm the current administrator cannot deactivate or demote their own account.
8. Open **Class offerings**, create or edit an offering, and confirm it persists.
9. Sign in as a student or instructor and directly open `/admin/sync`, `/admin/users`, or `/admin/classes`. The app must redirect to `/dashboard`.
10. Invoke `sync-onecampus` with a non-admin access token. The function must return HTTP 403 and must not import data.

## Class workspace test checklist

Use the seeded IT 101 class with `instructor@adfc.edu.ph` and `student1@adfc.edu.ph`.

1. **Materials:** Instructor adds an external link or supported file. Student can open it; an unrelated student cannot access its class or storage path.
2. **Announcements:** Instructor publishes an announcement. Student sees it but has no create/delete controls.
3. **Discussions:** Student creates a topic and reply. Topic authors and class managers can delete it; non-authors cannot.
4. **Assignments:**
   - Instructor creates a published assignment.
   - Student submits text and/or a private file.
   - Instructor downloads the file, awards a grade within the point limit, and leaves feedback.
   - Student sees only their own submission and grade.
5. **Quizzes:**
   - Instructor creates a quiz, adds questions and answer keys, then publishes it.
   - Student sees questions but never receives answer-key rows.
   - Student submits once and receives an automatic score.
   - A second submission is rejected by the database.
6. **Progress:** Student sees only personal results. Instructor/admin sees the enrolled-student gradebook.
7. **Account status:** Deactivate a user and verify direct class-table and Storage access is rejected after session refresh.
8. **Direct URL/RLS:** Attempt to access a class outside the account's enrollment/teaching assignments. The class and all child records must remain unavailable.

## Quality checks

```powershell
npm run lint
npm run build
```

When local Supabase is running:

```powershell
npx supabase db reset
```

## Main project structure

```text
src/
  components/       layouts, guards, and common states
  hooks/            auth and class data hooks
  lib/supabase.ts   typed browser client
  components/classroom/  materials, communication, assessments, and progress
  pages/                 role dashboards, class pages, and admin screens
  types/            generated-compatible database types
supabase/
  functions/        Edge Functions
  migrations/       PostgreSQL schema and RLS
  seed.sql           demo Auth users and academic data
mock-onecampus/
  fixtures.json      OneCampus fallback dataset
```