import { useCallback, useEffect, useState } from 'react'
import { GraduationCap, RefreshCw, UsersRound } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { ErrorState, LoadingState } from '../ScreenState'

interface Student {
  id: string
  full_name: string
  school_id: string
}

interface EnrollmentRow {
  student: Student | Student[] | null
}

function normalizeStudent(row: EnrollmentRow): Student | null {
  return Array.isArray(row.student) ? row.student[0] ?? null : row.student
}

export function EnrolledStudentsPanel({ classId, expectedCount }: { classId: string; expectedCount: number }) {
  const [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    const { data, error: queryError } = await supabase
      .from('enrollments')
      .select('student:profiles!enrollments_student_id_fkey(id, full_name, school_id)')
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
        .select('student:profiles!enrollments_student_id_fkey(id, full_name, school_id)')
        .eq('class_id', classId)
        .eq('status', 'enrolled')
      if (!active) return
      if (queryError) setError(queryError.message)
      else setStudents((data ?? []).map((row) => normalizeStudent(row as unknown as EnrollmentRow)).filter((student): student is Student => Boolean(student)))
      setLoading(false)
    })()
    return () => { active = false }
  }, [classId])

  if (loading) return <aside className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><LoadingState label="Loading students…" /></aside>
  if (error) return <aside className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><ErrorState message={error} onRetry={() => void load()} /></aside>

  return (
    <aside className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm lg:sticky lg:top-28">
      <div className="border-b border-slate-100 bg-gradient-to-r from-slate-50 to-blue-50 p-5">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">Class roster</p>
            <h2 className="mt-1 text-lg font-black text-slate-900">Enrolled students</h2>
          </div>
          <span className="inline-flex min-w-9 items-center justify-center rounded-full bg-brand-700 px-2.5 py-1 text-sm font-black text-white">{students.length}</span>
        </div>
        <p className="mt-2 text-xs leading-5 text-slate-500">Confirmed students enrolled in this subject and section.</p>
      </div>
      {students.length === 0 ? (
        <div className="p-6 text-center">
          <div className="mx-auto grid size-12 place-items-center rounded-2xl bg-slate-100 text-slate-400"><UsersRound size={22} /></div>
          <p className="mt-3 font-bold text-slate-700">No confirmed students</p>
          <p className="mt-1 text-xs leading-5 text-slate-400">Enrollment currently reports {expectedCount} students for this class.</p>
        </div>
      ) : (
        <div className="max-h-[560px] space-y-2 overflow-y-auto p-3">
          {students.map((student, index) => (
            <article key={student.id} className="flex items-center gap-3 rounded-xl border border-slate-100 p-3 transition hover:border-blue-200 hover:bg-blue-50/40">
              <div className="grid size-10 shrink-0 place-items-center rounded-xl bg-blue-50 text-brand-700"><GraduationCap size={19} /></div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-bold text-slate-900">{student.full_name}</p>
                <p className="mt-0.5 flex items-center gap-1.5 text-xs font-semibold text-slate-500"><UsersRound size={12} /> {student.school_id}</p>
              </div>
              <span className="text-xs font-bold text-slate-300">{index + 1}</span>
            </article>
          ))}
        </div>
      )}
      <button type="button" onClick={() => void load()} className="flex w-full items-center justify-center gap-2 border-t border-slate-100 px-4 py-3 text-xs font-bold text-brand-700 hover:bg-blue-50"><RefreshCw size={14} /> Refresh roster</button>
    </aside>
  )
}