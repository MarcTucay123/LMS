import { useCallback, useEffect, useState } from 'react'
import { ArrowLeft, CalendarClock, Eye, MapPin } from 'lucide-react'
import { Link, Navigate, useParams, useSearchParams } from 'react-router-dom'
import { EmptyState, ErrorState, LoadingState } from '../components/ScreenState'
import { supabase } from '../lib/supabase'
import type { ClassSummary } from '../types/database'
import { useAuth } from '../hooks/useAuth'
import { MaterialsTab } from '../components/classroom/MaterialsTab'
import { AssignmentsTab } from '../components/classroom/AssignmentsTab'
import { ExamsTab, QuizzesTab } from '../components/classroom/QuizzesTab'
import { DiscussionsTab } from '../components/classroom/DiscussionsTab'
import { AnnouncementsTab } from '../components/classroom/AnnouncementsTab'
import { ProgressTab } from '../components/classroom/ProgressTab'
import { EnrolledStudentsPanel } from '../components/classroom/StudentsTab'
import { formatScheduleMeeting, scheduleRoomLabel } from '../lib/classSchedule'

const tabs = ['materials', 'assignments', 'quizzes', 'exams', 'discussions', 'announcements', 'progress'] as const
type Tab = typeof tabs[number]

type RawClass = Omit<ClassSummary, 'subject' | 'instructor' | 'schedule'> & {
  subject: ClassSummary['subject'] | NonNullable<ClassSummary['subject']>[]
  instructor: ClassSummary['instructor'] | NonNullable<ClassSummary['instructor']>[]
  schedule?: ClassSummary['schedule']
}

function normalizeClass(raw: RawClass): ClassSummary {
  return {
    ...raw,
    subject: Array.isArray(raw.subject) ? raw.subject[0] ?? null : raw.subject,
    instructor: Array.isArray(raw.instructor) ? raw.instructor[0] ?? null : raw.instructor,
    schedule: raw.schedule ?? [],
  }
}

export function ClassPage() {
  const { profile } = useAuth()
  const { classId } = useParams()
  const [searchParams, setSearchParams] = useSearchParams()
  const [classItem, setClassItem] = useState<ClassSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [notFound, setNotFound] = useState(false)
  const requestedTab = searchParams.get('tab')
  const [activeTab, setActiveTab] = useState<Tab>(tabs.includes(requestedTab as Tab) ? requestedTab as Tab : 'materials')

  const selectTab = (tab: Tab) => {
    setActiveTab(tab)
    const next = new URLSearchParams(searchParams)
    if (tab === 'materials') next.delete('tab')
    else next.set('tab', tab)
    setSearchParams(next, { replace: true })
  }

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
  const canManageContent = profile?.role === 'instructor' && classItem.instructor_id === profile.id
  const isStudent = profile?.role === 'student'
  const canViewReports = profile?.role === 'admin' || canManageContent
  const isMonitoring = profile?.role === 'admin'

  return (
    <div>
      <Link className="mb-4 inline-flex items-center gap-2 text-sm font-semibold text-brand-700" to="/dashboard"><ArrowLeft size={17} /> Back to dashboard</Link>
      <section className="card classroom-outline overflow-hidden">
        <div className="bg-gradient-to-r from-brand-800 to-brand-600 p-4 text-white sm:p-8">
          <p className="text-sm font-bold uppercase tracking-wider text-blue-100">{classItem.subject?.code}</p>
          <h1 className="mt-1 text-xl font-bold sm:text-2xl">{classItem.subject?.title}</h1>
          <p className="mt-3 text-sm text-blue-100">Section {classItem.section} · {classItem.semester}, {classItem.school_year} · {classItem.instructor?.full_name}</p>
          <div className="mt-4 flex flex-wrap gap-2">
            {classItem.schedule.length === 0 && <span className="rounded-full bg-white/10 px-3 py-1.5 text-xs font-semibold text-blue-100 ring-1 ring-white/20">Schedule not yet published</span>}
            {classItem.schedule.map((meeting, index) => <span key={`${meeting.day_of_week}-${meeting.start_time}-${index}`} className="inline-flex items-center gap-2 rounded-full bg-white/10 px-3 py-1.5 text-xs font-semibold text-white ring-1 ring-white/20"><CalendarClock size={14} /> {formatScheduleMeeting(meeting)} <MapPin size={14} /> {scheduleRoomLabel(meeting)}</span>)}
          </div>
        </div>
        {isMonitoring && <div className="flex items-start gap-3 border-b border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900 sm:px-8"><Eye className="mt-0.5 shrink-0" size={18} /><div><p className="font-extrabold">Administrator monitoring view</p><p className="mt-0.5 text-amber-800">You can inspect classroom content, submissions, gradebook, and progress reports. Only the assigned instructor can create learning content, grade work, post announcements, or moderate discussions.</p></div></div>}
        <div className="overflow-x-auto border-b border-slate-200 px-4"><div className="flex min-w-max gap-1">{tabs.map((tab) => <button key={tab} onClick={() => selectTab(tab)} className={`border-b-2 px-4 py-4 text-sm font-semibold capitalize transition ${activeTab === tab ? 'border-brand-600 text-brand-700' : 'border-transparent text-slate-500 hover:text-slate-800'}`}>{tab}</button>)}</div></div>
        <div className={`grid gap-6 p-4 sm:p-8 ${canViewReports ? 'lg:grid-cols-[minmax(0,1fr)_320px] xl:grid-cols-[minmax(0,1fr)_360px]' : ''}`}>
          <div className="min-w-0">
            {activeTab === 'materials' && <MaterialsTab classId={classItem.id} canManage={canManageContent} />}
            {activeTab === 'assignments' && <AssignmentsTab classId={classItem.id} canManage={canManageContent} canViewReports={canViewReports} isStudent={isStudent} />}
            {activeTab === 'quizzes' && <QuizzesTab classId={classItem.id} canManage={canManageContent} isStudent={isStudent} />}
            {activeTab === 'exams' && <ExamsTab classId={classItem.id} canManage={canManageContent} isStudent={isStudent} />}
            {activeTab === 'discussions' && <DiscussionsTab classId={classItem.id} canManage={canManageContent} canParticipate={!isMonitoring} />}
            {activeTab === 'announcements' && <AnnouncementsTab classId={classItem.id} canManage={canManageContent} />}
            {activeTab === 'progress' && <ProgressTab classId={classItem.id} canViewReports={canViewReports} />}
          </div>
          {canViewReports && <EnrolledStudentsPanel classId={classItem.id} expectedCount={Number(classItem.enrolled_student_count)} />}
        </div>
      </section>
    </div>
  )
}