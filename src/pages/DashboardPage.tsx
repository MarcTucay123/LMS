import { ArrowRight, BookOpen, CalendarDays, UsersRound } from 'lucide-react'
import { Link } from 'react-router-dom'
import { EmptyState, ErrorState, LoadingState } from '../components/ScreenState'
import { useAuth } from '../hooks/useAuth'
import { useClasses } from '../hooks/useClasses'

export function DashboardPage() {
  const { profile } = useAuth()
  const { classes, loading, error, reload } = useClasses()
  if (!profile) return null

  return (
    <div>
      <section className="mb-6 rounded-2xl bg-gradient-to-r from-brand-800 to-brand-600 p-6 text-white shadow-lg shadow-brand-900/10 sm:p-8">
        <p className="text-sm font-semibold uppercase tracking-widest text-blue-100">{profile.role} dashboard</p>
        <h1 className="mt-2 text-2xl font-bold sm:text-3xl">Welcome, {profile.full_name.split(' ')[0]}!</h1>
        <p className="mt-2 max-w-2xl text-sm text-blue-100">Access the classes assigned to your OneCampus account. Class access is enforced by the database.</p>
      </section>

      <div className="mb-4 flex items-end justify-between gap-4">
        <div><h2 className="text-xl font-bold text-slate-900">{profile.role === 'admin' ? 'All active classes' : 'My classes'}</h2><p className="text-sm text-slate-500">Academic classes available to your account</p></div>
        {!loading && !error && <span className="rounded-full bg-brand-50 px-3 py-1 text-sm font-semibold text-brand-700">{classes.length} {classes.length === 1 ? 'class' : 'classes'}</span>}
      </div>

      {loading && <LoadingState label="Loading your classes…" />}
      {error && <ErrorState message={error} onRetry={() => void reload()} />}
      {!loading && !error && classes.length === 0 && <EmptyState title="No classes available" description="No active class is assigned to your account. Contact the registrar or an administrator if this seems incorrect." />}
      {!loading && !error && classes.length > 0 && (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {classes.map((classItem) => (
            <article key={classItem.id} className="card group overflow-hidden">
              <div className="h-2 bg-gradient-to-r from-brand-700 to-sky-500" />
              <div className="p-5">
                <div className="mb-4 flex items-start justify-between gap-3"><div className="grid size-11 place-items-center rounded-xl bg-brand-50 text-brand-700"><BookOpen size={22} /></div><span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">Active</span></div>
                <p className="text-xs font-bold uppercase tracking-wider text-brand-700">{classItem.subject?.code ?? 'Subject'}</p>
                <h3 className="mt-1 min-h-12 font-bold text-slate-900">{classItem.subject?.title ?? 'Untitled subject'}</h3>
                <div className="mt-4 space-y-2 text-sm text-slate-500"><p className="flex items-center gap-2"><UsersRound size={16} /> Section {classItem.section}</p><p className="flex items-center gap-2"><CalendarDays size={16} /> {classItem.semester}, {classItem.school_year}</p></div>
                <p className="mt-4 truncate border-t border-slate-100 pt-4 text-xs text-slate-500">Instructor: <span className="font-medium text-slate-700">{classItem.instructor?.full_name ?? 'Not assigned'}</span></p>
                <Link to={`/classes/${classItem.id}`} className="mt-4 flex items-center justify-between font-semibold text-brand-700">Open class <ArrowRight className="transition-transform group-hover:translate-x-1" size={18} /></Link>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  )
}