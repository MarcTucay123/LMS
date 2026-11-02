import { useState } from 'react'
import {
  Bell,
  BookOpen,
  ChevronDown,
  GraduationCap,
  LayoutDashboard,
  LogOut,
  Menu,
  MessageSquareText,
  ShieldCheck,
  TrendingUp,
  X,
} from 'lucide-react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

const roleLabels = { student: 'Student', instructor: 'Instructor', admin: 'Administrator' } as const

const pageTitles: Record<string, { title: string; subtitle: string }> = {
  '/dashboard': { title: 'Dashboard', subtitle: 'Your learning overview and active classes' },
}

function initials(name: string) {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join('')
    .toUpperCase()
}

export function AppLayout() {
  const { profile, signOut } = useAuth()
  const location = useLocation()
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  if (!profile) return null

  const page = location.pathname.startsWith('/classes/')
    ? { title: 'Classroom', subtitle: 'Learning resources and class activities' }
    : pageTitles[location.pathname] ?? pageTitles['/dashboard']

  const closeMenu = () => setMobileMenuOpen(false)

  return (
    <div className="min-h-screen bg-[#f5f7fb] lg:grid lg:grid-cols-[278px_minmax(0,1fr)]">
      {mobileMenuOpen && (
        <button
          className="fixed inset-0 z-40 bg-slate-950/40 backdrop-blur-[1px] lg:hidden"
          aria-label="Close navigation"
          onClick={closeMenu}
        />
      )}

      <aside className={`portal-sidebar ${mobileMenuOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0`}>
        <div className="flex h-24 items-center gap-3 border-b border-slate-200 px-6">
          <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-blue-500 to-brand-800 text-white shadow-lg shadow-blue-700/20">
            <GraduationCap size={27} aria-hidden="true" />
          </div>
          <div className="min-w-0">
            <p className="truncate text-lg font-extrabold tracking-tight text-slate-900">ADFC LMS</p>
            <p className="truncate text-xs font-medium text-slate-500">OneCampus Learning Portal</p>
          </div>
          <button className="ml-auto grid size-9 place-items-center rounded-lg text-slate-500 hover:bg-slate-100 lg:hidden" onClick={closeMenu} aria-label="Close navigation">
            <X size={20} />
          </button>
        </div>

        <div className="flex min-h-0 flex-1 flex-col overflow-y-auto px-4 py-6">
          <p className="mb-3 px-3 text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">Main menu</p>
          <nav aria-label="Main navigation" className="space-y-1.5">
            <NavLink to="/dashboard" onClick={closeMenu} className={({ isActive }) => `portal-nav-link ${isActive ? 'portal-nav-link-active' : ''}`}>
              <LayoutDashboard size={19} /> Dashboard
            </NavLink>
            <NavLink to="/dashboard#classes" onClick={closeMenu} className="portal-nav-link">
              <BookOpen size={19} /> {profile.role === 'admin' ? 'Class offerings' : 'My classes'}
            </NavLink>
          </nav>

          <p className="mb-3 mt-8 px-3 text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">Learning</p>
          <nav aria-label="Future learning features" className="space-y-1.5">
            <div className="portal-nav-link portal-nav-disabled"><Bell size={19} /> Announcements <span>Soon</span></div>
            <div className="portal-nav-link portal-nav-disabled"><MessageSquareText size={19} /> Discussions <span>Soon</span></div>
            <div className="portal-nav-link portal-nav-disabled"><TrendingUp size={19} /> Progress <span>Soon</span></div>
            {profile.role === 'admin' && <div className="portal-nav-link portal-nav-disabled"><ShieldCheck size={19} /> Administration <span>Phase 2</span></div>}
          </nav>
        </div>

        <div className="border-t border-slate-200 p-4">
          <div className="flex items-center gap-3 rounded-2xl bg-slate-50 p-3">
            <div className="grid size-11 shrink-0 place-items-center rounded-full bg-brand-700 text-sm font-bold text-white ring-4 ring-white">
              {initials(profile.full_name)}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-bold text-slate-900">{profile.full_name}</p>
              <p className="truncate text-xs text-slate-500">{profile.email}</p>
              <p className="mt-0.5 text-[11px] font-semibold uppercase tracking-wide text-brand-700">{roleLabels[profile.role]}</p>
            </div>
          </div>
        </div>
      </aside>

      <div className="min-w-0 lg:col-start-2">
        <header className="sticky top-0 z-30 flex h-20 items-center justify-between border-b border-slate-200 bg-white/95 px-4 backdrop-blur sm:px-6 lg:h-24 lg:px-8">
          <div className="flex min-w-0 items-center gap-3">
            <button className="grid size-10 shrink-0 place-items-center rounded-xl border border-slate-200 text-slate-600 lg:hidden" onClick={() => setMobileMenuOpen(true)} aria-label="Open navigation">
              <Menu size={21} />
            </button>
            <div className="min-w-0">
              <h1 className="truncate text-xl font-extrabold tracking-tight text-slate-900 sm:text-2xl">{page.title}</h1>
              <p className="hidden truncate text-sm text-slate-500 sm:block">{page.subtitle}</p>
            </div>
          </div>

          <div className="flex items-center gap-2 sm:gap-3">
            <div className="hidden items-center gap-3 border-r border-slate-200 pr-4 md:flex">
              <div className="grid size-10 place-items-center rounded-full bg-blue-50 text-sm font-bold text-brand-700 ring-2 ring-blue-100">{initials(profile.full_name)}</div>
              <div className="max-w-44">
                <p className="truncate text-sm font-bold text-slate-800">{profile.full_name}</p>
                <p className="text-xs text-slate-500">{roleLabels[profile.role]}</p>
              </div>
              <ChevronDown size={16} className="text-slate-400" />
            </div>
            <button className="portal-logout" onClick={() => void signOut()} title="Log out">
              <LogOut size={18} aria-hidden="true" />
              <span className="hidden sm:inline">Log out</span>
            </button>
          </div>
        </header>

        <main className="min-w-0 p-4 sm:p-6 lg:p-8"><Outlet /></main>
        <footer className="border-t border-slate-200 bg-white px-6 py-5 text-center text-xs text-slate-400 lg:text-right">
          ADFC OneCampus Learning Management System
        </footer>
      </div>
    </div>
  )
}