import { useMemo, useState } from 'react'
import { ArrowRight, Bell, BookOpen, CalendarClock, Clock3, GraduationCap, MapPin, Search, UsersRound, X } from 'lucide-react'
import { Link } from 'react-router-dom'
import { EmptyState, ErrorState, LoadingState } from '../components/ScreenState'
import { useAuth } from '../hooks/useAuth'
import { useClasses } from '../hooks/useClasses'
import { formatScheduleMeeting, scheduleRoomLabel } from '../lib/classSchedule'
import type { ClassSummary } from '../types/database'
import { useClassNotifications } from '../hooks/useClassNotifications'
import { ProfileAvatar } from '../components/ProfileAvatar'

function classSearchText(classItem: ClassSummary) {
  const schedule = classItem.schedule.flatMap((meeting) => [
    meeting.day_of_week,
    meeting.start_time,
    meeting.end_time,
    meeting.room_code,
    meeting.building,
    meeting.class_type,
  ])

  return [
    classItem.subject?.code,
    classItem.subject?.title,
    classItem.section,
    classItem.instructor?.full_name,
    classItem.semester,
    classItem.school_year,
    ...schedule,
  ].filter(Boolean).join(' ').toLocaleLowerCase()
}

export function ClassesPage() {
  const { profile } = useAuth()
  const { classes, loading, error, reload } = useClasses()
  const { byClass } = useClassNotifications()
  const [classSearch, setClassSearch] = useState('')
  const normalizedClassSearch = classSearch.trim().toLocaleLowerCase()
  const filteredClasses = useMemo(() => normalizedClassSearch
    ? classes.filter((classItem) => classSearchText(classItem).includes(normalizedClassSearch))
    : classes, [classes, normalizedClassSearch])

  if (!profile) return null

  const heading = profile.role === 'admin'
    ? 'LMS class workspaces'
    : profile.role === 'instructor'
      ? 'Classes you handle'
      : 'Classes you are enrolled in'

  return (
    <div className="mx-auto max-w-[1500px]">
      <section className="mb-7 rounded-2xl bg-gradient-to-r from-brand-800 to-brand-600 p-4 text-white shadow-lg shadow-blue-900/10 sm:p-8">
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
        <>
          <div className="mb-5 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="relative w-full max-w-2xl">
              <label className="sr-only" htmlFor="classes-page-search">Search classes</label>
              <Search className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={19} aria-hidden="true" />
              <input
                id="classes-page-search"
                type="search"
                className="admin-search-input pr-12"
                value={classSearch}
                onChange={(event) => setClassSearch(event.target.value)}
                placeholder="Search by subject, section, instructor, semester, or room…"
                autoComplete="off"
              />
              {classSearch && <button type="button" className="absolute right-2 top-1/2 grid size-9 -translate-y-1/2 place-items-center rounded-lg text-slate-400 transition hover:bg-slate-100 hover:text-slate-700" onClick={() => setClassSearch('')} aria-label="Clear class search"><X size={17} /></button>}
            </div>
            <span className="class-count-badge shrink-0">{normalizedClassSearch ? `${filteredClasses.length} of ${classes.length}` : classes.length} {classes.length === 1 ? 'class' : 'classes'}</span>
          </div>

          {filteredClasses.length === 0 ? <EmptyState title="No matching classes" description={`No classes match “${classSearch.trim()}”. Try a subject code, class title, section, instructor, semester, school year, schedule, or room.`} /> : <div className="grid gap-5 md:grid-cols-2 2xl:grid-cols-3">
          {filteredClasses.map((classItem) => {
            const index = classes.findIndex((item) => item.id === classItem.id)
            const notificationCount = byClass[classItem.id]?.total ?? 0
            return (
            <article key={classItem.id} className="class-card group">
              <div className={`class-card-banner class-banner-${(index % 3) + 1}`}>
                <div className="flex items-start gap-2"><div className="grid size-12 place-items-center rounded-2xl bg-white/15 text-white ring-1 ring-white/20"><BookOpen size={24} /></div>{notificationCount > 0 && <span className="class-notification-badge" aria-label={`${notificationCount} ${notificationCount === 1 ? 'notification' : 'notifications'}`}><Bell size={14} />{notificationCount}</span>}</div>
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
                  <div className="flex min-w-0 items-center gap-3">
                    <ProfileAvatar name={classItem.instructor?.full_name ?? 'Instructor'} avatarPath={classItem.instructor?.avatar_path} className="size-10 text-xs" />
                    <div className="min-w-0">
                    <p className="text-[11px] font-bold uppercase tracking-wide text-slate-400">Instructor</p>
                    <p className="truncate text-sm font-semibold text-slate-700">{classItem.instructor?.full_name ?? 'Not assigned'}</p>
                    </div>
                  </div>
                  <Link to={`/classes/${classItem.id}`} className="class-open-button" aria-label={`Open ${classItem.subject?.title ?? 'class'}`}><ArrowRight size={18} /></Link>
                </div>
              </div>
            </article>
            )
          })}
          </div>}
        </>
      )}
    </div>
  )
}