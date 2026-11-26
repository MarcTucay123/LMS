import { useCallback, useEffect, useId, useState } from 'react'
import { RefreshCw, UsersRound } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { ErrorState, LoadingState } from '../ScreenState'
import { ProfileAvatar } from '../ProfileAvatar'

interface Student {
  id: string
  full_name: string
  school_id: string
  avatar_path: string | null
}

interface EnrollmentRow {
  student: Student | Student[] | null
}

function normalizeStudent(row: EnrollmentRow): Student | null {
  return Array.isArray(row.student) ? row.student[0] ?? null : row.student
}

export function EnrolledStudentsPanel({ classId, expectedCount, lobbyJoinedStudentIds, fullWidth = false }: { classId: string; expectedCount: number; lobbyJoinedStudentIds?: string[] | null; fullWidth?: boolean }) {
  const rosterContentId = useId()
  const [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [contentHidden, setContentHidden] = useState(false)
  const liveRosterVisible = lobbyJoinedStudentIds !== null && lobbyJoinedStudentIds !== undefined
  const rosterHidden = contentHidden && !liveRosterVisible

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    const { data, error: queryError } = await supabase
      .from('enrollments')
      .select('student:profiles!enrollments_student_id_fkey(id, full_name, school_id, avatar_path)')
      .eq('class_id', classId)
      .eq('status', 'enrolled')
    if (queryError) setError(queryError.message)
    else setStudents((data ?? []).map((row) => normalizeStudent(row as unknown as EnrollmentRow)).filter((student): student is Student => Boolean(student)))
    setLoading(false)
  }, [classId])

  useEffect(() => {
    let active = true
    void (async () => {
      const { data, error: queryError } = await supabase
        .from('enrollments')
        .select('student:profiles!enrollments_student_id_fkey(id, full_name, school_id, avatar_path)')
        .eq('class_id', classId)
        .eq('status', 'enrolled')
      if (!active) return
      if (queryError) setError(queryError.message)
      else setStudents((data ?? []).map((row) => normalizeStudent(row as unknown as EnrollmentRow)).filter((student): student is Student => Boolean(student)))
      setLoading(false)
    })()
    return () => { active = false }
  }, [classId])

  if (loading) return <aside className="w-full rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><LoadingState label="Loading students…" /></aside>
  if (error) return <aside className="w-full rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><ErrorState message={error} onRetry={() => void load()} /></aside>

  return (
    <aside className={`w-full overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm ${fullWidth ? '' : 'lg:sticky lg:top-28'}`}>
      <div className="class-roster-header border-b border-slate-100 bg-gradient-to-r from-slate-50 to-blue-50 p-5">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">Class roster</p>
            <h2 className="mt-1 text-lg font-black text-slate-900">Enrolled students</h2>
          </div>
          <div className="flex shrink-0 items-center gap-2">
            <span className="inline-flex min-w-9 items-center justify-center rounded-full bg-brand-700 px-2.5 py-1 text-sm font-black text-white">{students.length}</span>
            <button
              type="button"
              className="rounded px-1 py-0.5 text-xs font-bold text-brand-700 underline decoration-brand-300 underline-offset-4 transition hover:bg-blue-100 hover:text-brand-900 hover:decoration-brand-700 disabled:cursor-not-allowed disabled:text-slate-400 disabled:no-underline"
              onClick={() => setContentHidden((hidden) => !hidden)}
              disabled={liveRosterVisible}
              title={liveRosterVisible ? 'The roster remains visible during a live session.' : rosterHidden ? 'Show class roster' : 'Hide class roster'}
              aria-expanded={!rosterHidden}
              aria-controls={rosterContentId}
            >
              {rosterHidden ? 'Show' : 'Hide'}
            </button>
          </div>
        </div>
        {!rosterHidden && <p className="mt-2 text-xs leading-5 text-slate-500">{liveRosterVisible ? <><span className="mr-3 inline-flex items-center gap-1.5"><span className="size-2.5 rounded-full bg-emerald-500" /> Joined</span><span className="inline-flex items-center gap-1.5"><span className="size-2.5 rounded-full bg-red-500" /> Not joined</span></> : 'Confirmed students enrolled in this subject and section.'}</p>}
      </div>
      {!rosterHidden && <div id={rosterContentId}>
        {students.length === 0 ? (
          <div className="p-6 text-center">
            <div className="mx-auto grid size-12 place-items-center rounded-2xl bg-slate-100 text-slate-400"><UsersRound size={22} /></div>
            <p className="mt-3 font-bold text-slate-700">No confirmed students</p>
            <p className="mt-1 text-xs leading-5 text-slate-400">Enrollment currently reports {expectedCount} students for this class.</p>
          </div>
        ) : (
          <div className={fullWidth ? 'grid gap-3 p-4 sm:grid-cols-2 xl:grid-cols-3' : 'max-h-[560px] space-y-2 overflow-y-auto p-3'}>
            {students.map((student, index) => (
              <article key={student.id} className="flex items-center gap-3 rounded-xl border border-slate-100 p-3 transition hover:border-blue-200 hover:bg-blue-50/40">
                <ProfileAvatar name={student.full_name} avatarPath={student.avatar_path} className="size-10 text-xs" />
                <div className="min-w-0 flex-1">
                  <p className="flex items-center gap-2 truncate text-sm font-bold text-slate-900">{liveRosterVisible && <span className={`size-2.5 shrink-0 rounded-full ring-2 ring-white ${lobbyJoinedStudentIds.includes(student.id) ? 'bg-emerald-500' : 'bg-red-500'}`} title={lobbyJoinedStudentIds.includes(student.id) ? 'Joined live session' : 'Not joined'} aria-label={lobbyJoinedStudentIds.includes(student.id) ? 'Joined live session' : 'Not joined'} />}<span className="truncate">{student.full_name}</span></p>
                  <p className="mt-0.5 flex items-center gap-1.5 text-xs font-semibold text-slate-500"><UsersRound size={12} /> {student.school_id}</p>
                </div>
                <span className="text-xs font-bold text-slate-300">{index + 1}</span>
              </article>
            ))}
          </div>
        )}
        <button type="button" onClick={() => void load()} className="flex w-full items-center justify-center gap-2 border-t border-slate-100 px-4 py-3 text-xs font-bold text-brand-700 transition hover:bg-blue-50"><RefreshCw size={14} /> Refresh roster</button>
      </div>}
    </aside>
  )
}