# ADFC OneCampus LMS

Web-based Learning Management System for Asian Development Foundation College. This repository currently contains **Phase 1 — Foundation** only.

- GitHub repository: `https://github.com/MarcTucay123/LMS.git`
- Hosted Supabase project reference: `ynsyycrrtgzmgjwwlyfm`

## Phase 1 features

- React, Vite, TypeScript, React Router, and Tailwind CSS
- Supabase browser client using only the public anon key
- Email/password login and logout
- OneCampus-record-based account activation through a Supabase Edge Function
- Database-owned `student`, `instructor`, and `admin` roles
- Role-aware application shell and protected routes
- Dashboard listing only classes allowed by PostgreSQL Row Level Security (RLS)
- Protected class overview route
- Local migration and deterministic demo seed

Later-phase features are intentionally not implemented yet. The class tabs are visible only as a route/wireframe preview.

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

5. Serve the activation Edge Function in a separate terminal:

   ```powershell
   npx supabase functions serve activate-account --no-verify-jwt
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
4. Deploy activation:

   ```powershell
   npx supabase functions deploy activate-account --no-verify-jwt
   ```

5. Configure the frontend with the hosted project URL and publishable key.

Supabase automatically provides `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to deployed Edge Functions. The service-role key must never be added to `.env`, Vite variables, or browser code.

## Environment variables

### Browser (`.env`)

| Variable | Required | Purpose |
| --- | --- | --- |
| `VITE_SUPABASE_URL` | Yes | Supabase project API URL |
| `VITE_SUPABASE_PUBLISHABLE_KEY` | Yes | Public browser publishable key |

### Edge Function secrets (required by later phases)

| Variable | Phase | Purpose |
| --- | --- | --- |
| `ONECAMPUS_API_URL` | Phase 2 | OneCampus REST API base URL; empty uses mock fixtures |
| `ONECAMPUS_API_KEY` | Phase 2 | Secret OneCampus API credential |

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
  pages/            Phase 1 route pages
  types/            generated-compatible database types
supabase/
  functions/        Edge Functions
  migrations/       PostgreSQL schema and RLS
  seed.sql           demo Auth users and academic data
```