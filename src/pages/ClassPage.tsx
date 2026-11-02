import { useCallback, useEffect, useState } from 'react'
import { ArrowLeft, BookOpen, Construction } from 'lucide-react'
import { Link, Navigate, useParams } from 'react-router-dom'
import { EmptyState, ErrorState, LoadingState } from '../components/ScreenState'
import { supabase } from '../lib/supabase'
import type { ClassSummary } from '../types/database'

const tabs = ['materials', 'assignments', 'quizzes', 'discussions', 'announcements', 'progress']

type RawClass = Omit<ClassSummary, 'subject' | 'instructor'> & {
  subject: ClassSummary['subject'] | NonNullable<ClassSummary['subject']>[]
  instructor: ClassSummary['instructor'] | NonNullable<ClassSummary['instructor']>[]
}

function normalizeClass(raw: RawClass): ClassSummary {
  return {
    ...raw,
    subject: Array.isArray(raw.subject) ? raw.subject[0] ?? null : raw.subject,
    instructor: Array.isArray(raw.instructor) ? raw.instructor[0] ?? null : raw.instructor,
  }
}

export function ClassPage() {
  const { classId } = useParams()
  const [classItem, setClassItem] = useState<ClassSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [notFound, setNotFound] = useState(false)

  const load = useCallback(async () => {
    if (!classId) return
    setLoading(true); setError(null); setNotFound(false)
    const { data, error: queryError } = await supabase.from('classes').select('id, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)').eq('id', classId).maybeSingle()
    if (queryError) setError(queryError.message)
    else if (!data) setNotFound(true)
    else {
      setClassItem(normalizeClass(data as unknown as RawClass))
    }
    setLoading(false)
  }, [classId])

  useEffect(() => {
    if (!classId) return
    let active = true
    void supabase
      .from('classes')
      .select('id, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)')
      .eq('id', classId)
      .maybeSingle()
      .then(({ data, error: queryError }) => {
        if (!active) return
        if (queryError) setError(queryError.message)
        else if (!data) setNotFound(true)
        else setClassItem(normalizeClass(data as unknown as RawClass))
        setLoading(false)
      })
    return () => { active = false }
  }, [classId])
  if (!classId) return <Navigate to="/dashboard" replace />
  if (loading) return <LoadingState label="Checking class access…" />
  if (error) return <ErrorState message={error} onRetry={() => void load()} />
  if (notFound || !classItem) return <EmptyState title="Class unavailable" description="This class does not exist or your account is not allowed to access it." />

  return (
    <div>
      <Link className="mb-4 inline-flex items-center gap-2 text-sm font-semibold text-brand-700" to="/dashboard"><ArrowLeft size={17} /> Back to dashboard</Link>
      <section className="card overflow-hidden">
        <div className="bg-gradient-to-r from-brand-800 to-brand-600 p-6 text-white sm:p-8">
          <p className="text-sm font-bold uppercase tracking-wider text-blue-100">{classItem.subject?.code}</p>
          <h1 className="mt-1 text-2xl font-bold">{classItem.subject?.title}</h1>
          <p className="mt-3 text-sm text-blue-100">Section {classItem.section} · {classItem.semester}, {classItem.school_year} · {classItem.instructor?.full_name}</p>
        </div>
        <div className="overflow-x-auto border-b border-slate-200 px-4"><div className="flex min-w-max gap-1">{tabs.map((tab, index) => <button key={tab} disabled className={`border-b-2 px-4 py-4 text-sm font-semibold capitalize ${index === 0 ? 'border-brand-600 text-brand-700' : 'border-transparent text-slate-400'}`}>{tab}</button>)}</div></div>
        <div className="p-6 sm:p-8">
          <div className="rounded-xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center"><div className="mx-auto grid size-12 place-items-center rounded-full bg-white text-brand-700 shadow-sm"><Construction /></div><h2 className="mt-4 font-bold text-slate-900">Class access is ready</h2><p className="mx-auto mt-2 max-w-lg text-sm text-slate-500">Phase 1 establishes secure class membership. Materials, assignments, quizzes, discussions, announcements, and progress will be implemented in their scheduled phases.</p><div className="mx-auto mt-5 inline-flex items-center gap-2 rounded-lg bg-brand-50 px-4 py-2 text-sm font-semibold text-brand-700"><BookOpen size={17} /> Authorized class member</div></div>
        </div>
      </section>
    </div>
  )
}