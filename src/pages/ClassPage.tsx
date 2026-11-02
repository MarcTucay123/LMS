import { useCallback, useEffect, useState } from 'react'
import { ArrowLeft } from 'lucide-react'
import { Link, Navigate, useParams } from 'react-router-dom'
import { EmptyState, ErrorState, LoadingState } from '../components/ScreenState'
import { supabase } from '../lib/supabase'
import type { ClassSummary } from '../types/database'
import { useAuth } from '../hooks/useAuth'
import { MaterialsTab } from '../components/classroom/MaterialsTab'
import { AssignmentsTab } from '../components/classroom/AssignmentsTab'
import { QuizzesTab } from '../components/classroom/QuizzesTab'
import { DiscussionsTab } from '../components/classroom/DiscussionsTab'
import { AnnouncementsTab } from '../components/classroom/AnnouncementsTab'
import { ProgressTab } from '../components/classroom/ProgressTab'

const tabs = ['materials', 'assignments', 'quizzes', 'discussions', 'announcements', 'progress'] as const
type Tab = typeof tabs[number]

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
  const { profile } = useAuth()
  const { classId } = useParams()
  const [classItem, setClassItem] = useState<ClassSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [notFound, setNotFound] = useState(false)
  const [activeTab, setActiveTab] = useState<Tab>('materials')

  const load = useCallback(async () => {
    if (!classId) return
    setLoading(true); setError(null); setNotFound(false)
    const { data, error: queryError } = await supabase.from('classes').select('id, instructor_id, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)').eq('id', classId).maybeSingle()
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
      .select('id, instructor_id, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)')
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
  const canManage = profile?.role === 'admin' || classItem.instructor_id === profile?.id

  return (
    <div>
      <Link className="mb-4 inline-flex items-center gap-2 text-sm font-semibold text-brand-700" to="/dashboard"><ArrowLeft size={17} /> Back to dashboard</Link>
      <section className="card overflow-hidden">
        <div className="bg-gradient-to-r from-brand-800 to-brand-600 p-6 text-white sm:p-8">
          <p className="text-sm font-bold uppercase tracking-wider text-blue-100">{classItem.subject?.code}</p>
          <h1 className="mt-1 text-2xl font-bold">{classItem.subject?.title}</h1>
          <p className="mt-3 text-sm text-blue-100">Section {classItem.section} · {classItem.semester}, {classItem.school_year} · {classItem.instructor?.full_name}</p>
        </div>
        <div className="overflow-x-auto border-b border-slate-200 px-4"><div className="flex min-w-max gap-1">{tabs.map((tab) => <button key={tab} onClick={() => setActiveTab(tab)} className={`border-b-2 px-4 py-4 text-sm font-semibold capitalize transition ${activeTab === tab ? 'border-brand-600 text-brand-700' : 'border-transparent text-slate-500 hover:text-slate-800'}`}>{tab}</button>)}</div></div>
        <div className="p-6 sm:p-8">
          {activeTab === 'materials' && <MaterialsTab classId={classItem.id} canManage={canManage} />}
          {activeTab === 'assignments' && <AssignmentsTab classId={classItem.id} canManage={canManage} />}
          {activeTab === 'quizzes' && <QuizzesTab classId={classItem.id} canManage={canManage} />}
          {activeTab === 'discussions' && <DiscussionsTab classId={classItem.id} canManage={canManage} />}
          {activeTab === 'announcements' && <AnnouncementsTab classId={classItem.id} canManage={canManage} />}
          {activeTab === 'progress' && <ProgressTab classId={classItem.id} canManage={canManage} />}
        </div>
      </section>
    </div>
  )
}