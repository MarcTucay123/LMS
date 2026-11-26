import { useEffect, useRef, useState } from 'react'
import {
  BarChart3,
  BookOpen,
  ChevronDown,
  ClipboardCheck,
  ClipboardList,
  FileText,
  FileCheck2,
  BookOpenCheck,
  GraduationCap,
  LayoutDashboard,
  LogOut,
  Megaphone,
  Menu,
  MessageCircle,
  NotebookTabs,
  RefreshCw,
  Settings,
  ShieldCheck,
  ShieldAlert,
  UserCog,
  Video,
  X,
} from 'lucide-react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { useClassNotifications } from '../hooks/useClassNotifications'
import type { ClassNotificationSection } from '../types/database'
import { useConfirmation } from '../hooks/useConfirmation'
import { useDiscussionCall } from '../hooks/useDiscussionCall'
import { ProfileAvatar } from './ProfileAvatar'
import { ThemeToggle } from './ThemeToggle'

const roleLabels = { student: 'Student', instructor: 'Instructor', admin: 'Administrator' } as const
const pageTitles: Record<string, { title: string; subtitle: string }> = {
  '/dashboard': { title: 'Dashboard', subtitle: 'Your learning overview and active classes' },
  '/classes': { title: 'My Classes', subtitle: 'Authorized assigned or enrolled class workspaces' },
  '/to-do': { title: 'To-do', subtitle: 'Assigned, missing, and completed student classwork' },
  '/workspace/materials': { title: 'Learning Materials', subtitle: 'Lessons, files, syllabi, and course resource links' },
  '/workspace/my-learning': { title: 'My Learning', subtitle: 'Course modules, timelines, required activities, and progress' },
  '/workspace/assignments': { title: 'Assignments', subtitle: 'Activities, submissions, scores, and instructor feedback' },
  '/workspace/quizzes': { title: 'Online Quizzes', subtitle: 'Class quizzes, attempts, objective scoring, and results' },
  '/workspace/exams': { title: 'Exams', subtitle: 'Major examinations, schedules, attempts, scoring, and results' },
  '/workspace/discussions': { title: 'Discussions', subtitle: 'Moderated conversations for course topics' },
  '/workspace/announcements': { title: 'Announcements', subtitle: 'Class updates, deadlines, and feedback notices' },
  '/workspace/progress': { title: 'Progress & Reports', subtitle: 'Activity completion and available score summaries' },
  '/profile-settings': { title: 'Profile Settings', subtitle: 'Review your OneCampus identity and manage account security' },
  '/admin/users': { title: 'User Accounts', subtitle: 'Manage LMS access, roles, and account status' },
  '/admin/classes': { title: 'Class Offerings', subtitle: 'Manage subjects, instructors, and academic offerings' },
  '/admin/sync': { title: 'OneCampus Sync', subtitle: 'Import institutional records and review sync history' },
  '/admin/audit-logs': { title: 'Audit Logs', subtitle: 'Review and print administrative and LMS activity' },
  '/admin/user-control': { title: 'User Control', subtitle: 'Configure login protection, auto-logout, and live-call attendance' },
}

export function AppLayout() {
  const { profile, signOut } = useAuth()
  const { confirm } = useConfirmation()
  const { total: notificationTotal, totalsBySection, loading: notificationsLoading } = useClassNotifications()
  const { isJoined: isInDiscussionCall, activeTopicTitle: callTopicTitle, restoreCall } = useDiscussionCall()
  const location = useLocation()
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [sidebarPinned, setSidebarPinned] = useState(() => window.localStorage.getItem('lms-sidebar-pinned') === 'true')
  const [sidebarHovered, setSidebarHovered] = useState(false)
  const [accountMenuOpen, setAccountMenuOpen] = useState(false)
  const [refreshKey, setRefreshKey] = useState(0)
  const accountMenuRef = useRef<HTMLDivElement>(null)
  const closeMenu = () => setMobileMenuOpen(false)
  const refreshPageData = () => setRefreshKey((value) => value + 1)
  const confirmSignOut = async () => {
    setAccountMenuOpen(false)
    const confirmed = await confirm({
      title: 'Log out of ADFC LMS?',
      message: 'You will be returned to the sign-in page. Make sure any unsaved work is completed before logging out.',
      confirmLabel: 'Log out',
      tone: 'warning',
      icon: 'logout',
    })
    if (confirmed) await signOut()
  }
  const sidebarExpanded = sidebarPinned || sidebarHovered
  const toggleSidebarPinned = () => {
    setSidebarPinned((current) => {
      const next = !current
      window.localStorage.setItem('lms-sidebar-pinned', String(next))
      if (!next) setSidebarHovered(false)
      return next
    })
  }

  useEffect(() => {
    if (!mobileMenuOpen) return
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => { document.body.style.overflow = previousOverflow }
  }, [mobileMenuOpen])

  useEffect(() => {
    if (!accountMenuOpen) return
    const closeOnOutsideClick = (event: MouseEvent) => {
      if (!accountMenuRef.current?.contains(event.target as Node)) setAccountMenuOpen(false)
    }
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setAccountMenuOpen(false)
    }
    document.addEventListener('mousedown', closeOnOutsideClick)
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.removeEventListener('mousedown', closeOnOutsideClick)
      window.removeEventListener('keydown', closeOnEscape)
    }
  }, [accountMenuOpen])

  if (!profile) return null

  const isClassroom = /^\/classes\/[^/]+\/?$/.test(location.pathname)
  const page = isClassroom
    ? { title: 'Classroom', subtitle: 'Learning resources and class activities' }
    : pageTitles[location.pathname] ?? pageTitles['/dashboard']

  return (
    <div className={`portal-layout min-h-screen bg-[#f5f7fb] ${sidebarPinned ? 'portal-layout-pinned' : ''}`}>
      {mobileMenuOpen && (
        <button
          className="fixed inset-0 z-40 bg-slate-950/40 backdrop-blur-[1px] lg:hidden"
          aria-label="Close navigation"
          onClick={closeMenu}
        />
      )}

      <aside
        className={`portal-sidebar ${sidebarExpanded ? 'portal-sidebar-expanded' : 'portal-sidebar-collapsed'} ${mobileMenuOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0`}
        onMouseEnter={() => setSidebarHovered(true)}
        onMouseLeave={() => setSidebarHovered(false)}
      >
        <div className="portal-sidebar-header flex h-24 items-center gap-3 border-b border-slate-200">
          <button type="button" className="portal-sidebar-toggle hidden shrink-0 lg:grid" onClick={toggleSidebarPinned} aria-label={sidebarPinned ? 'Unpin and collapse navigation' : 'Pin navigation open'} title={sidebarPinned ? 'Unpin sidebar' : 'Pin sidebar open'} aria-pressed={sidebarPinned}>
            <Menu size={23} />
          </button>
          <div className="portal-sidebar-logo grid size-12 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-blue-500 to-brand-800 text-white shadow-lg shadow-blue-700/20">
            <GraduationCap size={27} aria-hidden="true" />
          </div>
          <div className="portal-sidebar-copy min-w-0">
            <p className="truncate text-lg font-extrabold tracking-tight text-slate-900">ADFC LMS</p>
            <p className="truncate text-xs font-medium text-slate-500">OneCampus Learning Portal</p>
          </div>
          <button className="ml-auto grid size-9 place-items-center rounded-lg text-slate-500 hover:bg-slate-100 lg:hidden" onClick={closeMenu} aria-label="Close navigation">
            <X size={20} />
          </button>
        </div>

        <div className="portal-sidebar-scroll flex min-h-0 flex-1 flex-col overflow-y-auto px-4 py-6">
          <p className="portal-sidebar-section mb-3 px-3 text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">Main menu</p>
          <nav aria-label="Main navigation" className="space-y-1.5">
            <NavLink to="/dashboard" onClick={closeMenu} title={!sidebarExpanded ? 'Dashboard' : undefined} className={({ isActive }) => `portal-nav-link ${isActive ? 'portal-nav-link-active' : ''}`}>
              <LayoutDashboard size={19} aria-hidden="true" /><span className="portal-nav-label">Dashboard</span>
            </NavLink>
            {profile.role === 'student' && <NavLink to="/to-do" onClick={closeMenu} title={!sidebarExpanded ? 'To-do' : undefined} className={({ isActive }) => `portal-nav-link ${isActive ? 'portal-nav-link-active' : ''}`}><ClipboardList size={19} aria-hidden="true" /><span className="portal-nav-label">To-do</span></NavLink>}
            <NavLink to="/classes" onClick={closeMenu} title={!sidebarExpanded ? (profile.role === 'admin' ? 'Class workspaces' : 'My classes') : undefined} className={({ isActive }) => `portal-nav-link ${isActive ? 'portal-nav-link-active' : ''}`}>
              <BookOpen size={19} aria-hidden="true" /><span className="portal-nav-label">{profile.role === 'admin' ? 'Class workspaces' : 'My classes'}</span>
              {profile.role !== 'admin' && !notificationsLoading && notificationTotal > 0 && <span className="portal-nav-count" aria-label={`${notificationTotal} class ${notificationTotal === 1 ? 'notification' : 'notifications'}`}>{notificationTotal}</span>}
            </NavLink>
          </nav>

          {profile.role !== 'admin' && !isClassroom && (
            <>
              <p className="portal-sidebar-section mb-3 mt-8 px-3 text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">Class workspace</p>
              <nav aria-label="Class workspace" className="space-y-1.5">
                <WorkspaceNavLink to="/workspace/my-learning" label="My Learning" icon={<BookOpenCheck size={19} />} count={0} onClick={closeMenu} expanded={sidebarExpanded} />
                <WorkspaceNavLink to="/workspace/materials" label="Materials" icon={<FileText size={19} />} count={totalsBySection.materials} onClick={closeMenu} expanded={sidebarExpanded} />
                <WorkspaceNavLink to="/workspace/assignments" label="Assignments" icon={<ClipboardCheck size={19} />} count={totalsBySection.assignments} onClick={closeMenu} expanded={sidebarExpanded} />
                <WorkspaceNavLink to="/workspace/quizzes" label="Quizzes" icon={<NotebookTabs size={19} />} count={totalsBySection.quizzes} onClick={closeMenu} expanded={sidebarExpanded} />
                <WorkspaceNavLink to="/workspace/exams" label="Exams" icon={<FileCheck2 size={19} />} count={totalsBySection.exams} onClick={closeMenu} expanded={sidebarExpanded} />
                <WorkspaceNavLink to="/workspace/discussions" label="Discussions" icon={<MessageCircle size={19} />} count={totalsBySection.discussions} onClick={closeMenu} expanded={sidebarExpanded} callActive={isInDiscussionCall} callTitle={callTopicTitle} onRestoreCall={restoreCall} />
                <WorkspaceNavLink to="/workspace/announcements" label="Announcements" icon={<Megaphone size={19} />} count={totalsBySection.announcements} onClick={closeMenu} expanded={sidebarExpanded} />
                <WorkspaceNavLink to="/workspace/progress" label={profile.role === 'student' ? 'My progress' : 'Progress reports'} icon={<BarChart3 size={19} />} count={totalsBySection.progress} onClick={closeMenu} expanded={sidebarExpanded} />
              </nav>
            </>
          )}

          {profile.role === 'admin' && (
            <>
              <p className="portal-sidebar-section mb-3 mt-8 px-3 text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">Administration</p>
              <nav aria-label="Administration" className="space-y-1.5">
                <NavLink to="/admin/users" onClick={closeMenu} title={!sidebarExpanded ? 'User accounts' : undefined} className={({ isActive }) => `portal-nav-link ${isActive ? 'portal-nav-link-active' : ''}`}><UserCog size={19} aria-hidden="true" /><span className="portal-nav-label">User accounts</span></NavLink>
                <NavLink to="/admin/classes" onClick={closeMenu} title={!sidebarExpanded ? 'Class offerings' : undefined} className={({ isActive }) => `portal-nav-link ${isActive ? 'portal-nav-link-active' : ''}`}><ShieldCheck size={19} aria-hidden="true" /><span className="portal-nav-label">Class offerings</span></NavLink>
                <NavLink to="/admin/sync" onClick={closeMenu} title={!sidebarExpanded ? 'OneCampus sync' : undefined} className={({ isActive }) => `portal-nav-link ${isActive ? 'portal-nav-link-active' : ''}`}><RefreshCw size={19} aria-hidden="true" /><span className="portal-nav-label">OneCampus sync</span></NavLink>
                <NavLink to="/admin/audit-logs" onClick={closeMenu} title={!sidebarExpanded ? 'Audit logs' : undefined} className={({ isActive }) => `portal-nav-link ${isActive ? 'portal-nav-link-active' : ''}`}><ClipboardList size={19} aria-hidden="true" /><span className="portal-nav-label">Audit logs</span></NavLink>
                <NavLink to="/admin/user-control" onClick={closeMenu} title={!sidebarExpanded ? 'User control' : undefined} className={({ isActive }) => `portal-nav-link ${isActive ? 'portal-nav-link-active' : ''}`}><ShieldAlert size={19} aria-hidden="true" /><span className="portal-nav-label">User control</span></NavLink>
              </nav>
            </>
          )}
        </div>

        <div className="portal-sidebar-profile border-t border-slate-200 p-4">
          <div className="flex items-center gap-3 rounded-2xl bg-slate-50 p-3">
            <ProfileAvatar name={profile.full_name} avatarPath={profile.avatar_path} className="size-11 text-sm ring-4 ring-white" />
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-bold text-slate-900">{profile.full_name}</p>
              <p className="truncate text-xs text-slate-500">{profile.email}</p>
              <p className="mt-0.5 text-[11px] font-semibold uppercase tracking-wide text-brand-700">{roleLabels[profile.role]}</p>
            </div>
          </div>
        </div>
      </aside>

      <div className="min-w-0 lg:col-start-2">
        <header className="fixed inset-x-0 top-0 z-30 flex h-16 items-center justify-between gap-2 border-b border-slate-200 bg-white/95 px-3 shadow-sm backdrop-blur sm:h-20 sm:px-6 lg:sticky lg:inset-x-auto lg:h-24 lg:px-8 lg:shadow-none">
          <div className="flex min-w-0 items-center gap-3">
            <button className="grid size-10 shrink-0 place-items-center rounded-xl border border-slate-200 text-slate-600 lg:hidden" onClick={() => setMobileMenuOpen(true)} aria-label="Open navigation">
              <Menu size={21} />
            </button>
            <div className="min-w-0">
              <h1 className="truncate text-lg font-extrabold tracking-tight text-slate-900 sm:text-2xl">{page.title}</h1>
              <p className="hidden truncate text-sm text-slate-500 sm:block">{page.subtitle}</p>
            </div>
          </div>

          <div className="flex shrink-0 items-center gap-1.5 sm:gap-2">
          <ThemeToggle className="theme-toggle-compact sm:theme-toggle-full" />
          <div className="relative" ref={accountMenuRef}>
            <button
              type="button"
              className="flex min-h-11 items-center gap-2 rounded-xl px-1.5 py-1 text-left transition hover:bg-slate-50 sm:gap-3 sm:px-2"
              aria-haspopup="menu"
              aria-expanded={accountMenuOpen}
              aria-controls="account-menu"
              onClick={() => setAccountMenuOpen((open) => !open)}
            >
              <ProfileAvatar name={profile.full_name} avatarPath={profile.avatar_path} className="size-10 text-sm" clickable={false} />
              <div className="hidden max-w-44 min-w-0 sm:block">
                <p className="truncate text-sm font-bold text-slate-800">{profile.full_name}</p>
                <p className="text-xs text-slate-500">{roleLabels[profile.role]}</p>
              </div>
              <ChevronDown size={16} className={`shrink-0 text-slate-400 transition-transform ${accountMenuOpen ? 'rotate-180' : ''}`} aria-hidden="true" />
              <span className="sr-only">Open account menu</span>
            </button>

            {accountMenuOpen && (
              <div id="account-menu" className="absolute right-0 top-[calc(100%+0.5rem)] z-50 w-64 overflow-hidden rounded-xl border border-slate-200 bg-white p-2 shadow-xl shadow-slate-900/10" role="menu">
                <div className="border-b border-slate-100 px-3 py-2.5 sm:hidden">
                  <p className="truncate text-sm font-bold text-slate-900">{profile.full_name}</p>
                  <p className="mt-0.5 text-xs text-slate-500">{roleLabels[profile.role]}</p>
                </div>
                <NavLink to="/dashboard" className="portal-account-action" role="menuitem" onClick={() => setAccountMenuOpen(false)}>
                  <LayoutDashboard size={18} aria-hidden="true" />
                  <span>Dashboard</span>
                </NavLink>
                <NavLink to="/profile-settings" className="portal-account-action" role="menuitem" onClick={() => setAccountMenuOpen(false)}>
                  <Settings size={18} aria-hidden="true" />
                  <span>Profile Settings</span>
                </NavLink>
                <div className="my-1 border-t border-slate-100" />
                <button type="button" className="portal-logout w-full justify-start" role="menuitem" onClick={() => void confirmSignOut()}>
                  <LogOut size={18} aria-hidden="true" />
                  <span>Log out</span>
                </button>
              </div>
            )}
          </div>
          </div>
        </header>

        <div className="h-16 sm:h-20 lg:hidden" aria-hidden="true" />

        <main className="min-w-0 p-3 sm:p-6 lg:p-8"><Outlet key={`${location.pathname}-${refreshKey}`} /></main>
        <footer className="flex flex-col items-center justify-between gap-2 border-t border-slate-200 bg-white px-4 py-5 text-center text-xs text-slate-400 sm:flex-row sm:px-6 sm:text-left">
          <span>ADFC OneCampus Learning Management System</span>
          <button type="button" className="print-hidden inline-flex items-center gap-1.5 font-semibold text-slate-500 transition hover:text-brand-700" onClick={() => refreshPageData()} title="Refresh page data now">
            <RefreshCw size={13} />
            Refresh
          </button>
        </footer>
      </div>
    </div>
  )
}

function WorkspaceNavLink({ to, label, icon, count, onClick, expanded, callActive = false, callTitle, onRestoreCall }: { to: `/workspace/${ClassNotificationSection | 'my-learning'}`; label: string; icon: React.ReactNode; count: number; onClick: () => void; expanded: boolean; callActive?: boolean; callTitle?: string | null; onRestoreCall?: () => void }) {
  return <NavLink to={to} onClick={() => { onClick(); if (callActive) onRestoreCall?.() }} title={!expanded ? (callActive ? `In call: ${callTitle ?? label}` : label) : undefined} className={({ isActive }) => `portal-nav-link ${isActive ? 'portal-nav-link-active' : ''}`}><span className="portal-nav-icon" aria-hidden="true">{icon}</span><span className="portal-nav-label">{label}</span>{callActive && <span className="portal-nav-call" role="status" aria-label={`You are in the discussion call: ${callTitle ?? 'Discussion call'}`} title={`In call: ${callTitle ?? 'Discussion call'}`}><Video size={13} /></span>}{count > 0 && <span className="portal-nav-count" aria-label={`${count} ${label.toLocaleLowerCase()} ${count === 1 ? 'notification' : 'notifications'}`}>{count}</span>}</NavLink>
}