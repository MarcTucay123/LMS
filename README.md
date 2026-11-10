# ADFC OneCampus LMS

Web-based Learning Management System for Asian Development Foundation College.

## Runtime architecture

- React 19, TypeScript, Vite, React Router, and Tailwind CSS frontend
- PHP 8 API served by XAMPP Apache
- MariaDB/MySQL database served by XAMPP
- PHP session authentication and server-side role/class authorization
- Private uploads stored in `D:\LMS\storage\uploads` and streamed through authorized API endpoints
- OneCampus synchronization using `mock-onecampus/fixtures.json` by default, with optional remote API configuration
- Read-only synchronized projections for external identity, course catalog, class scheduling, and enrollment data

The browser compatibility client in `src/lib/supabase.ts` retains the former Supabase-style frontend calls, but all runtime requests now go to `public/api/index.php`.

Academic data ownership and database handoff rules are documented in `docs/DATABASE_INTEGRATION_CONTRACT.md`.

## Quick start

See [`docs/XAMPP_SETUP.md`](docs/XAMPP_SETUP.md) for complete installation, database import, configuration, deployment, credentials, and validation instructions.

```powershell
cd D:\LMS
npm install
npm run lint
npm run build
```

The standard deployment maps `C:\xampp\htdocs\lms` to `D:\LMS\dist`. Then open `http://localhost/lms/`.

## Demo accounts

All seeded accounts use password `DemoPass123!`.

| Role | Email |
|---|---|
| Administrator | `admin@adfc.edu.ph` |
| Instructor | `instructor@adfc.edu.ph` |
| Student | `student1@adfc.edu.ph` |
| Pending activation | `pending@adfc.edu.ph` |

## Main project structure

```text
database/             MariaDB schema and deterministic demo seed
docs/                 design assets and XAMPP setup guide
mock-onecampus/       OneCampus fallback fixture
public/api/           PHP API bootstrap, authorization, and action router
src/                  React application and PHP API compatibility client
storage/uploads/      private runtime files; ignored by Git
```

## Supported workflows

- Session login, logout, recovery-token password reset, and account activation
- Public student and instructor registration with administrator approval/rejection; administrator accounts are provisioned separately
- Role and account-status administration
- Class offering administration and OneCampus synchronization
- Role-scoped dashboards and classroom access
- Instructor-managed materials, announcements, discussions, assignments, grading, and quizzes, with administrator read-only classroom monitoring and progress reporting
- Authorized private upload, removal, and signed download flows

MariaDB does not provide Supabase Row Level Security. Every PHP endpoint therefore performs explicit session, role, class-membership, ownership, and instructor/administrator checks before reading or changing records.