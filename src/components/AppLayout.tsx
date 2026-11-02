import { BookOpen, GraduationCap, LayoutDashboard, LogOut, ShieldCheck, UserRound } from 'lucide-react'
import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

const roleLabels = { student: 'Student', instructor: 'Instructor', admin: 'Administrator' } as const

export function AppLayout() {
  const { profile, signOut } = useAuth()
  if (!profile) return null

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-4 px-4 py-3 sm:px-6 lg:px-8">
          <div className="flex min-w-0 items-center gap-3">
            <div className="grid size-11 shrink-0 place-items-center rounded-xl bg-brand-700 text-white shadow-sm">
              <GraduationCap aria-hidden="true" />
            </div>
            <div className="min-w-0">
              <p className="truncate font-bold text-brand-900">ADFC OneCampus</p>
              <p className="text-xs font-medium uppercase tracking-wider text-slate-500">Learning Management System</p>
            </div>
          </div>
          <button className="button-secondary" onClick={() => void signOut()}>
            <LogOut size={17} aria-hidden="true" />
            <span className="hidden sm:inline">Log out</span>
          </button>
        </div>
      </header>

      <div className="mx-auto grid max-w-7xl gap-6 px-4 py-6 sm:px-6 lg:grid-cols-[240px_1fr] lg:px-8">
        <aside className="card h-fit p-4">
          <div className="mb-5 flex items-center gap-3 border-b border-slate-100 pb-4">
            <div className="grid size-10 place-items-center rounded-full bg-brand-50 text-brand-700"><UserRound size={20} /></div>
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold text-slate-900">{profile.full_name}</p>
              <p className="text-xs text-slate-500">{roleLabels[profile.role]}</p>
            </div>
          </div>
          <nav aria-label="Main navigation" className="space-y-1">
            <NavLink to="/dashboard" className={({ isActive }) => `nav-link ${isActive ? 'nav-link-active' : ''}`}>
              <LayoutDashboard size={18} /> Dashboard
            </NavLink>
            <div className="nav-link cursor-default text-slate-400"><BookOpen size={18} /> My classes</div>
            {profile.role === 'admin' && <div className="nav-link cursor-default text-slate-400"><ShieldCheck size={18} /> Administration <span className="ml-auto text-[10px]">Phase 2</span></div>}
          </nav>
        </aside>
        <main className="min-w-0"><Outlet /></main>
      </div>
    </div>
  )
}