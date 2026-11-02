import { ArrowRight, BookOpen, Clock3, GraduationCap, UsersRound } from 'lucide-react'
import { Link } from 'react-router-dom'
import { EmptyState, ErrorState, LoadingState } from '../components/ScreenState'
import { useAuth } from '../hooks/useAuth'
import { useClasses } from '../hooks/useClasses'

export function ClassesPage() {
  const { profile } = useAuth()
  const { classes, loading, error, reload } = useClasses()

  if (!profile) return null

  const heading = profile.role === 'admin'
    ? 'LMS class workspaces'
    : profile.role === 'instructor'
      ? 'Classes you handle'
      : 'Classes you are enrolled in'

  return (
    <div className="mx-auto max-w-[1500px]">
      <section className="mb-7 rounded-2xl bg-gradient-to-r from-brand-800 to-brand-600 p-6 text-white shadow-lg shadow-blue-900/10 sm:p-8">
        <div className="flex items-start gap-4">
          <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-white/15 ring-1 ring-white/20">
            <GraduationCap size={25} />
          </div>
          <div>
            <p className="text-xs font-extrabold uppercase tracking-[0.16em] text-blue-100">Course access</p>
            <h2 className="mt-1 text-2xl font-black sm:text-3xl">{heading}</h2>
            <p className="mt-2 max-w-3xl text-sm leading-6 text-blue-100">
              Open an authorized class to access its materials, activities, discussions, announcements, and learning progress.
            </p>
          </div>
        </div>
      </section>

      {loading && <LoadingState label="Loading authorized classes…" />}
      {error && <ErrorState message={error} onRetry={() => void reload()} />}
      {!loading && !error && classes.length === 0 && (
        <EmptyState
          title="No classes available"
          description="No active class is currently assigned or enrolled through OneCampus."
        />
      )}
      {!loading && !error && classes.length > 0 && (
        <div className="grid gap-5 md:grid-cols-2 2xl:grid-cols-3">
          {classes.map((classItem, index) => (
            <article key={classItem.id} className="class-card group">
              <div className={`class-card-banner class-banner-${(index % 3) + 1}`}>
                <div className="grid size-12 place-items-center rounded-2xl bg-white/15 text-white ring-1 ring-white/20"><BookOpen size={24} /></div>
                <span className="rounded-full bg-white/15 px-3 py-1 text-xs font-bold text-white ring-1 ring-white/20">Active</span>
              </div>
              <div className="p-5 sm:p-6">
                <p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">{classItem.subject?.code ?? 'Subject'}</p>
                <h3 className="mt-2 min-h-12 text-lg font-extrabold leading-6 text-slate-900">{classItem.subject?.title ?? 'Untitled subject'}</h3>
                <div className="mt-5 grid grid-cols-2 gap-3">
                  <div className="class-detail"><UsersRound size={16} /><span><small>Section</small>{classItem.section}</span></div>
                  <div className="class-detail"><Clock3 size={16} /><span><small>Semester</small>{classItem.semester}</span></div>
                </div>
                <div className="mt-5 flex items-center justify-between gap-3 border-t border-slate-100 pt-4">
                  <div className="min-w-0">
                    <p className="text-[11px] font-bold uppercase tracking-wide text-slate-400">Instructor</p>
                    <p className="truncate text-sm font-semibold text-slate-700">{classItem.instructor?.full_name ?? 'Not assigned'}</p>
                  </div>
                  <Link to={`/classes/${classItem.id}`} className="class-open-button" aria-label={`Open ${classItem.subject?.title ?? 'class'}`}><ArrowRight size={18} /></Link>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  )
}