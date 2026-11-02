# ADFC OneCampus LMS

Web-based Learning Management System for Asian Development Foundation College. The planned foundation, administration, synchronization, and class-learning phases are implemented.

- GitHub repository: `https://github.com/MarcTucay123/LMS.git`
- Hosted Supabase project reference: `ynsyycrrtgzmgjwwlyfm`

## Implemented features

- React, Vite, TypeScript, React Router, and Tailwind CSS
- Supabase browser client using only the public anon key
- Email/password login and logout
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

All class workspace tabs shown in the application are functional. Database RLS and security-definer RPCs enforce the same role boundaries as the user interface.

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

## Demo accounts

All active demo accounts use password `DemoPass123!`.

| Role | Email | Expected classes |
| --- | --- | --- |
| Admin | `admin@adfc.edu.ph` | All 3 active classes |
| Instructor | `instructor@adfc.edu.ph` | IT 101 and ENG 102 |
| Second instructor | `instructor2@adfc.edu.ph` | MATH 103 |
| Student | `student1@adfc.edu.ph` | IT 101 and ENG 102 |
| Second student | `student2@adfc.edu.ph` | MATH 103 |

Activation test fixture (initially pending):

- OneCampus ID: `OC-STU-003`
- School email: `pending@adfc.edu.ph`
- Choose a password meeting the displayed requirements.

The activation form never accepts a role. The Edge Function reads the role from `activation_records` and updates the matching pre-created Auth/profile account.

## Phase 1 test checklist

1. **Authentication:** Sign in as each demo role and confirm logout returns to `/login`.
2. **Role dashboards:**
   - Admin sees 3 classes.
   - `instructor@adfc.edu.ph` sees 2 classes.
   - `student1@adfc.edu.ph` sees 2 classes.
   - `student2@adfc.edu.ph` sees only MATH 103.
3. **Direct URL protection:** Sign in as `student1@adfc.edu.ph`, then open `/classes/20000000-0000-4000-8000-000000000003`. The app must show “Class unavailable”; the database returns no class row.
4. **Authorized URL:** With the same student, open `/classes/20000000-0000-4000-8000-000000000001`. The class overview must load.
5. **Activation:** Activate the pending fixture, then sign in using its new password. It should have an active student profile and no classes.
6. **No open registration:** Supabase email sign-up is disabled, and there is no registration route.

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