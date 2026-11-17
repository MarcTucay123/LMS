import { useEffect, useMemo, useState } from 'react'
import {
  ArrowRight,
  BadgeCheck,
  BookOpen,
  CalendarDays,
  CalendarClock,
  Clock3,
  ClipboardCheck,
  ChevronRight,
  GraduationCap,
  Layers3,
  MapPin,
  Sparkles,
  UsersRound,
} from 'lucide-react'
import { Link } from 'react-router-dom'
import { EmptyState, ErrorState, LoadingState } from '../components/ScreenState'
import { useAuth } from '../hooks/useAuth'
import { useClasses } from '../hooks/useClasses'
import { useStudentTodo } from '../hooks/useStudentTodo'
import { formatScheduleMeeting, scheduleRoomLabel } from '../lib/classSchedule'
import { StudentTodoRow } from '../components/StudentTodoRow'

const roleLabels = { student: 'Student', instructor: 'Instructor', admin: 'Administrator' } as const

function greetingForHour(hour: number) {
  if (hour < 12) return 'Good morning'
  if (hour < 18) return 'Good afternoon'
  return 'Good evening'
}

function firstName(fullName: string) {
  return fullName.trim().split(/\s+/)[0] ?? fullName
}

export function DashboardPage() {
  const { profile } = useAuth()
  const { classes, loading, error, reload } = useClasses()
  const [now, setNow] = useState(() => new Date())
  const { grouped: todo, loading: todoLoading, error: todoError } = useStudentTodo(classes, profile?.role === 'student' && !loading && !error)

  useEffect(() => {
    const timer = window.setInterval(() => setNow(new Date()), 1000)
    return () => window.clearInterval(timer)
  }, [])

  const academicYears = useMemo(() => [...new Set(classes.map((item) => item.school_year))], [classes])
  const semesters = useMemo(() => [...new Set(classes.map((item) => item.semester))], [classes])
  if (!profile) return null

  const classLabel = profile.role === 'admin' ? 'Active class offerings' : profile.role === 'instructor' ? 'Classes handled' : 'Classes enrolled'
  const primaryYear = academicYears[0] ?? 'Not assigned'
  const primarySemester = semesters[0] ?? 'No active semester'
  const dueSoon = todo.assigned.filter((item) => item.dueAt && new Date(item.dueAt).getTime() >= now.getTime() && new Date(item.dueAt).getTime() <= now.getTime() + 7 * 24 * 60 * 60 * 1000).slice(0, 5)

  return (
    <div className="mx-auto max-w-[1500px]">
      <section className="dashboard-hero">
        <div className="dashboard-hero-orb dashboard-hero-orb-one" />
        <div className="dashboard-hero-orb dashboard-hero-orb-two" />
        <div className="relative z-10 grid gap-8 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-center">
          <div className="flex items-start gap-4 sm:gap-5">
            <div className="mt-1 grid size-12 shrink-0 place-items-center rounded-2xl bg-white/15 text-white ring-1 ring-white/20 backdrop-blur sm:size-14">
              <Sparkles size={27} aria-hidden="true" />
            </div>
            <div>
              <p className="text-sm font-semibold text-blue-100">{now.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })}</p>
              <h2 className="mt-2 text-2xl font-black tracking-tight text-white sm:text-4xl">
                {greetingForHour(now.getHours())}, <span className="text-amber-300">{firstName(profile.full_name)}!</span>
              </h2>
              <p className="mt-3 max-w-2xl text-sm leading-6 text-blue-100 sm:text-base">
                Welcome to your ADFC learning space. Continue your classes and keep track of the academic term from one secure portal.
              </p>
            </div>
          </div>

          <div className="border-t border-white/15 pt-5 text-left lg:min-w-64 lg:border-l lg:border-t-0 lg:pl-8 lg:pt-0 lg:text-right">
            <p className="font-mono text-3xl font-black tracking-tight text-white sm:text-4xl">{now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}</p>
            <p className="mt-1 text-sm text-blue-100">Current time</p>
            <div className="mt-4 flex flex-wrap gap-2 lg:justify-end">
              <span className="hero-badge"><GraduationCap size={15} /> {roleLabels[profile.role]}</span>
              <span className="hero-badge"><CalendarDays size={15} /> {primaryYear}</span>
            </div>
          </div>
        </div>
      </section>

      <section className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-3" aria-label="Academic summary">
        <article className="summary-card">
          <div>
            <p className="summary-label">{classLabel}</p>
            <p className="summary-value">{loading ? '—' : classes.length}</p>
            <p className="summary-caption">Available through your account</p>
          </div>
          <div className="summary-icon bg-blue-50 text-blue-600"><BookOpen size={24} /></div>
        </article>

        <article className="summary-card">
          <div>
            <p className="summary-label">Academic term</p>
            <p className="summary-value summary-value-text">{primaryYear}</p>
            <p className="summary-caption">{primarySemester}</p>
          </div>
          <div className="summary-icon bg-violet-50 text-violet-600"><CalendarDays size={24} /></div>
        </article>

        <article className="summary-card md:col-span-2 xl:col-span-1">
          <div>
            <p className="summary-label">Account status</p>
            <p className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-3 py-1 text-sm font-bold text-emerald-700"><BadgeCheck size={16} /> Active</p>
            <p className="summary-caption">Verified OneCampus profile</p>
          </div>
          <div className="summary-icon bg-emerald-50 text-emerald-600"><BadgeCheck size={24} /></div>
        </article>
      </section>

      {profile.role === 'student' && <section className="mt-6 overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 px-5 py-4 sm:px-7"><div className="flex items-center gap-3"><div className="grid size-10 place-items-center rounded-xl bg-blue-50 text-brand-700"><ClipboardCheck size={20} /></div><div><h2 className="text-xl font-black text-slate-900">Due soon</h2><p className="text-xs text-slate-500">Unfinished work due in the next seven days</p></div></div><Link to="/to-do" className="inline-flex items-center gap-1 text-sm font-extrabold text-brand-700 hover:text-brand-800">View to-do <ChevronRight size={17} /></Link></div>
        {todoLoading ? <div className="p-5 sm:p-7"><LoadingState label="Checking upcoming work…" /></div> : todoError ? <div className="p-5 text-sm font-semibold text-red-600 sm:p-7">{todoError}</div> : dueSoon.length ? <div className="divide-y divide-slate-100">{dueSoon.map((item) => <StudentTodoRow key={`${item.kind}-${item.id}`} item={item} compact />)}</div> : <p className="px-5 py-10 text-center text-sm font-semibold text-slate-500 sm:px-7">You don't have any work due in the next seven days.</p>}
      </section>}

      <section id="classes" className="mt-8 scroll-mt-28">
        <div className="mb-5 flex flex-col justify-between gap-3 sm:flex-row sm:items-end">
          <div>
            <div className="flex items-center gap-2 text-brand-700"><Layers3 size={18} /><p className="text-xs font-extrabold uppercase tracking-[0.16em]">Academic workspace</p></div>
            <h2 className="mt-1 text-2xl font-black tracking-tight text-slate-900">{profile.role === 'admin' ? 'Active classes' : 'My classes'}</h2>
            <p className="mt-1 text-sm text-slate-500">Open a class to access its learning area.</p>
          </div>
          {!loading && !error && <span className="class-count-badge">{classes.length} {classes.length === 1 ? 'class' : 'classes'}</span>}
        </div>

        {loading && <LoadingState label="Loading your classes…" />}
        {error && <ErrorState message={error} onRetry={() => void reload()} />}
        {!loading && !error && classes.length === 0 && <EmptyState title="No classes available" description="No active class is assigned to your account. Contact the registrar or an administrator if this seems incorrect." />}
        {!loading && !error && classes.length > 0 && (
          <div className="grid gap-5 md:grid-cols-2 2xl:grid-cols-3">
            {classes.map((classItem, index) => (
              <article key={classItem.id} className="class-card group">
                <div className={`class-card-banner class-banner-${(index % 3) + 1}`}>
                  <div className="grid size-12 place-items-center rounded-2xl bg-white/15 text-white ring-1 ring-white/20"><BookOpen size={24} /></div>
                  <div className="flex flex-col items-end gap-2"><span className="rounded-full bg-white/15 px-3 py-1 text-xs font-bold text-white ring-1 ring-white/20">Active</span><span className="inline-flex items-center gap-1.5 rounded-full bg-white px-3 py-1 text-xs font-extrabold text-brand-700 shadow-sm"><UsersRound size={14} /> {Number(classItem.enrolled_student_count)} {Number(classItem.enrolled_student_count) === 1 ? 'student' : 'students'}</span></div>
                </div>
                <div className="p-5 sm:p-6">
                  <p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">{classItem.subject?.code ?? 'Subject'}</p>
                  <h3 className="mt-2 min-h-12 text-lg font-extrabold leading-6 text-slate-900">{classItem.subject?.title ?? 'Untitled subject'}</h3>
                  <div className="mt-5 grid grid-cols-1 gap-3 min-[400px]:grid-cols-2">
                    <div className="class-detail"><UsersRound size={16} /><span><small>Section</small>{classItem.section}</span></div>
                    <div className="class-detail"><Clock3 size={16} /><span><small>Semester</small>{classItem.semester}</span></div>
                  </div>
                  <div className="mt-4 space-y-2 rounded-xl bg-slate-50 p-3">
                    {classItem.schedule.length === 0 ? <p className="text-xs font-semibold text-slate-400">Schedule not yet published</p> : classItem.schedule.map((meeting, meetingIndex) => <div key={`${meeting.day_of_week}-${meeting.start_time}-${meetingIndex}`} className="text-xs text-slate-600"><p className="flex items-center gap-2 font-bold text-slate-700"><CalendarClock size={14} className="text-brand-700" /> {formatScheduleMeeting(meeting)}</p><p className="mt-1 flex items-center gap-2 pl-5"><MapPin size={13} /> {scheduleRoomLabel(meeting)}</p></div>)}
                  </div>
                  <div className="mt-5 flex items-center justify-between gap-3 border-t border-slate-100 pt-4">
                    <div className="min-w-0"><p className="text-[11px] font-bold uppercase tracking-wide text-slate-400">Instructor</p><p className="truncate text-sm font-semibold text-slate-700">{classItem.instructor?.full_name ?? 'Not assigned'}</p></div>
                    <Link to={`/classes/${classItem.id}`} className="class-open-button" aria-label={`Open ${classItem.subject?.title ?? 'class'}`}><ArrowRight size={18} /></Link>
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}