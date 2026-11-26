import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { ArrowLeft, CalendarClock, EllipsisVertical, MapPin, UsersRound, Video, X } from 'lucide-react'
import { Link, Navigate, useParams, useSearchParams } from 'react-router-dom'
import { EmptyState, ErrorState, LoadingState } from '../components/ScreenState'
import { supabase } from '../lib/supabase'
import type { ClassSummary, LiveQuizLobbyStatus } from '../types/database'
import { useAuth } from '../hooks/useAuth'
import { MaterialsTab } from '../components/classroom/MaterialsTab'
import { AssignmentsTab } from '../components/classroom/AssignmentsTab'
import { ExamsTab, QuizzesTab } from '../components/classroom/QuizzesTab'
import { DiscussionsTab } from '../components/classroom/DiscussionsTab'
import { AnnouncementsTab } from '../components/classroom/AnnouncementsTab'
import { ProgressTab } from '../components/classroom/ProgressTab'
import { EnrolledStudentsPanel } from '../components/classroom/StudentsTab'
import { formatScheduleMeeting, scheduleRoomLabel } from '../lib/classSchedule'
import { useClassNotifications } from '../hooks/useClassNotifications'
import { useDiscussionCall } from '../hooks/useDiscussionCall'
import { MyLearningTab } from '../components/classroom/MyLearningTab'

const tabs = ['my-learning', 'materials', 'assignments', 'quizzes', 'exams', 'discussions', 'announcements', 'progress'] as const
type Tab = typeof tabs[number]
const tabLabels: Record<Tab, string> = { 'my-learning': 'My Learning', materials: 'Materials', assignments: 'Assignments', quizzes: 'Quizzes', exams: 'Exams', discussions: 'Discussions', announcements: 'Announcements', progress: 'Progress' }

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
  const { byClass } = useClassNotifications()
  const { activeClassId: callClassId, activeTopicTitle: callTopicTitle, isJoined: isInDiscussionCall, restoreCall } = useDiscussionCall()
  const isStudent = profile?.role === 'student'
  const { classId } = useParams()
  const [searchParams, setSearchParams] = useSearchParams()
  const [classItem, setClassItem] = useState<ClassSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [notFound, setNotFound] = useState(false)
  const [liveLobbyStatus, setLiveLobbyStatus] = useState<LiveQuizLobbyStatus | null>(null)
  const [studentLiveTabs, setStudentLiveTabs] = useState({ quizzes: false, exams: false })
  const requestedTab = searchParams.get('tab')
  const [activeTab, setActiveTab] = useState<Tab>(tabs.includes(requestedTab as Tab) ? requestedTab as Tab : 'my-learning')
  const [tabDirection, setTabDirection] = useState<'left' | 'right'>('right')
  const [tabIndicator, setTabIndicator] = useState({ x: 0, width: 0 })
  const [mobileActionsOpen, setMobileActionsOpen] = useState(false)
  const [mobileRosterOpen, setMobileRosterOpen] = useState(false)
  const tabButtons = useRef<Partial<Record<Tab, HTMLButtonElement | null>>>({})
  const mobileActionsRef = useRef<HTMLDivElement>(null)

  const selectTab = (tab: Tab) => {
    if (tab === activeTab) return
    setMobileActionsOpen(false)
    setMobileRosterOpen(false)
    setLiveLobbyStatus(null)
    setTabDirection(tabs.indexOf(tab) > tabs.indexOf(activeTab) ? 'right' : 'left')
    setActiveTab(tab)
    const next = new URLSearchParams(searchParams)
    if (tab === 'my-learning') next.delete('tab')
    else next.set('tab', tab)
    setSearchParams(next, { replace: true })
  }

  useLayoutEffect(() => {
    const activeButton = tabButtons.current[activeTab]
    if (!activeButton) return

    const updateIndicator = () => setTabIndicator({ x: activeButton.offsetLeft, width: activeButton.offsetWidth })
    updateIndicator()

    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    activeButton.scrollIntoView({ behavior: reduceMotion ? 'auto' : 'smooth', block: 'nearest', inline: 'center' })
    const resizeObserver = new ResizeObserver(updateIndicator)
    resizeObserver.observe(activeButton)
    window.addEventListener('resize', updateIndicator)
    return () => {
      resizeObserver.disconnect()
      window.removeEventListener('resize', updateIndicator)
    }
  }, [activeTab, classItem?.id, loading])

  useEffect(() => {
    if (!mobileActionsOpen) return
    const closeOnOutsideClick = (event: MouseEvent) => {
      if (!mobileActionsRef.current?.contains(event.target as Node)) setMobileActionsOpen(false)
    }
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setMobileActionsOpen(false)
    }
    document.addEventListener('mousedown', closeOnOutsideClick)
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.removeEventListener('mousedown', closeOnOutsideClick)
      window.removeEventListener('keydown', closeOnEscape)
    }
  }, [mobileActionsOpen])

  const load = useCallback(async () => {
    if (!classId) return
    setLoading(true); setError(null); setNotFound(false)
    const { data, error: queryError } = await supabase.from('classes').select('id, instructor_id, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name, avatar_path)').eq('id', classId).maybeSingle()
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
      .select('id, instructor_id, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name, avatar_path)')
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

  useEffect(() => {
    if (!classItem?.id || !isStudent) return
    let active = true
    let requestRunning = false
    const refreshLiveTabs = async () => {
      if (document.hidden || requestRunning) return
      requestRunning = true
      const [quizResult, examResult] = await Promise.all([
        supabase.rpc('list_live_quiz_sessions', { target_class_id: classItem.id, assessment_kind: 'quiz' }),
        supabase.rpc('list_live_quiz_sessions', { target_class_id: classItem.id, assessment_kind: 'exam' }),
      ])
      requestRunning = false
      if (!active) return
      const isLive = (status: string) => ['lobby', 'active', 'paused'].includes(status)
      setStudentLiveTabs({
        quizzes: !quizResult.error && (quizResult.data ?? []).some((session) => isLive(session.status)),
        exams: !examResult.error && (examResult.data ?? []).some((session) => isLive(session.status)),
      })
    }
    const initial = window.setTimeout(() => void refreshLiveTabs(), 0)
    const timer = window.setInterval(() => void refreshLiveTabs(), 4_000)
    const refreshWhenVisible = () => { if (document.visibilityState === 'visible') void refreshLiveTabs() }
    document.addEventListener('visibilitychange', refreshWhenVisible)
    window.addEventListener('focus', refreshWhenVisible)
    return () => {
      active = false
      window.clearTimeout(initial)
      window.clearInterval(timer)
      document.removeEventListener('visibilitychange', refreshWhenVisible)
      window.removeEventListener('focus', refreshWhenVisible)
    }
  }, [classItem?.id, isStudent])

  if (!classId) return <Navigate to="/dashboard" replace />
  if (loading) return <LoadingState label="Checking class access…" />
  if (error) return <ErrorState message={error} onRetry={() => void load()} />
  if (notFound || !classItem) return <EmptyState title="Class unavailable" description="This class does not exist or your account is not allowed to access it." />
  const canManageContent = profile?.role === 'instructor' && classItem.instructor_id === profile.id
  const canViewReports = profile?.role === 'admin' || canManageContent
  const isMonitoring = profile?.role === 'admin'
  const notificationCounts = byClass[classItem.id]

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
        {isMonitoring ? (
          <div className="p-4 sm:p-8">
            <EnrolledStudentsPanel classId={classItem.id} expectedCount={Number(classItem.enrolled_student_count)} fullWidth />
          </div>
        ) : (
          <>
            <div className="overflow-x-auto border-b border-slate-200 px-4"><div className="relative flex min-w-max gap-1 pb-1" role="tablist" aria-label="Classroom sections">{tabs.map((tab) => { const count = tab === 'my-learning' ? 0 : notificationCounts?.[tab] ?? 0; const hasLiveSession = isStudent && ((tab === 'quizzes' && studentLiveTabs.quizzes) || (tab === 'exams' && studentLiveTabs.exams)); const hasDiscussionCall = tab === 'discussions' && isInDiscussionCall && callClassId === classItem.id; const hasIndicator = count > 0 || hasLiveSession || hasDiscussionCall; return <button ref={(element) => { tabButtons.current[tab] = element }} key={tab} type="button" role="tab" aria-selected={activeTab === tab} onClick={() => { if (hasDiscussionCall && activeTab === tab) restoreCall(); else selectTab(tab) }} className={`relative py-4 pl-4 text-sm font-semibold transition-colors duration-200 ${hasIndicator ? 'pr-9' : 'pr-4'} ${activeTab === tab ? 'text-blue-700' : 'text-slate-500 hover:text-slate-800'}`}>{tabLabels[tab]}{hasIndicator && <span className="tab-notification-indicators">{count > 0 && <sup className="tab-notification-count" aria-label={`${count} ${tabLabels[tab]} ${count === 1 ? 'notification' : 'notifications'}`}>{count}</sup>}{hasLiveSession && <span className="tab-live-notification-dot" role="status" aria-label={`Live ${tab === 'exams' ? 'exam' : 'quiz'} session available`} title={`Live ${tab === 'exams' ? 'exam' : 'quiz'} session available`} />}{hasDiscussionCall && <span className="tab-call-notification-icon" role="status" aria-label={`You are in the discussion call: ${callTopicTitle}`} title={`In call: ${callTopicTitle}`}><Video size={14} /></span>}</span>}</button> })}<span className="classroom-tab-indicator" style={{ width: tabIndicator.width, transform: `translate3d(${tabIndicator.x}px, 0, 0)`, opacity: tabIndicator.width > 0 ? 1 : 0 }} aria-hidden="true" /></div></div>
            <div className="overflow-hidden"><div key={activeTab} className={`classroom-tab-panel classroom-tab-panel-${tabDirection} relative grid gap-6 p-4 sm:p-8 ${activeTab !== 'discussions' && (canViewReports || isStudent) ? 'lg:grid-cols-[minmax(0,1fr)_320px] xl:grid-cols-[minmax(0,1fr)_360px]' : ''}`}>
              {activeTab !== 'discussions' && (canViewReports || isStudent) && <div ref={mobileActionsRef} className="absolute right-3 top-3 z-20 lg:hidden">
                <button type="button" className="icon-action border-brand-200 shadow-sm" onClick={() => setMobileActionsOpen((open) => !open)} aria-label="Class options" aria-haspopup="menu" aria-expanded={mobileActionsOpen} aria-controls="mobile-class-options"><EllipsisVertical size={20} /></button>
                {mobileActionsOpen && <div id="mobile-class-options" className="absolute right-0 top-[calc(100%+0.5rem)] w-60 rounded-xl border border-slate-200 bg-white p-2 shadow-xl shadow-slate-900/10" role="menu">
                  <button type="button" className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left text-sm font-bold text-slate-700 transition hover:bg-blue-50 hover:text-brand-700" role="menuitem" onClick={() => { setMobileActionsOpen(false); setMobileRosterOpen(true) }}><UsersRound size={17} /> View enrolled students</button>
                </div>}
              </div>}
              <div className="min-w-0">
                {activeTab === 'my-learning' && <MyLearningTab classId={classItem.id} canManage={canManageContent} isStudent={isStudent} onNavigate={selectTab} />}
                {activeTab === 'materials' && <MaterialsTab classId={classItem.id} canManage={canManageContent} />}
                {activeTab === 'assignments' && <AssignmentsTab classId={classItem.id} canManage={canManageContent} canViewReports={canViewReports} isStudent={isStudent} />}
                {activeTab === 'quizzes' && <QuizzesTab classId={classItem.id} canManage={canManageContent} isStudent={isStudent} onLobbyStatusChange={canManageContent ? setLiveLobbyStatus : undefined} />}
                {activeTab === 'exams' && <ExamsTab classId={classItem.id} canManage={canManageContent} isStudent={isStudent} onLobbyStatusChange={canManageContent ? setLiveLobbyStatus : undefined} />}
                {activeTab === 'discussions' && <DiscussionsTab classId={classItem.id} canManage={canManageContent} canParticipate expectedRosterCount={Number(classItem.enrolled_student_count)} />}
                {activeTab === 'announcements' && <AnnouncementsTab classId={classItem.id} canManage={canManageContent} />}
                {activeTab === 'progress' && <ProgressTab classId={classItem.id} canViewReports={canViewReports} classDetails={classItem} />}
              </div>
              {activeTab !== 'discussions' && (canViewReports || isStudent) && <div className="hidden lg:block"><EnrolledStudentsPanel classId={classItem.id} expectedCount={Number(classItem.enrolled_student_count)} lobbyJoinedStudentIds={canManageContent && ['quizzes', 'exams'].includes(activeTab) ? liveLobbyStatus?.joined_student_ids ?? null : null} /></div>}
            </div></div>
            {mobileRosterOpen && <MobileRosterDialog classId={classItem.id} expectedCount={Number(classItem.enrolled_student_count)} lobbyJoinedStudentIds={canManageContent && ['quizzes', 'exams'].includes(activeTab) ? liveLobbyStatus?.joined_student_ids ?? null : null} onClose={() => setMobileRosterOpen(false)} />}
          </>
        )}
      </section>
    </div>
  )
}

function MobileRosterDialog({ classId, expectedCount, lobbyJoinedStudentIds, onClose }: { classId: string; expectedCount: number; lobbyJoinedStudentIds?: string[] | null; onClose: () => void }) {
  useEffect(() => {
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') onClose() }
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', closeOnEscape)
    }
  }, [onClose])

  return <div className="modal-backdrop lg:hidden" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}><section className="modal-card max-w-lg p-0 sm:p-0" role="dialog" aria-modal="true" aria-labelledby="mobile-roster-title"><header className="flex items-center justify-between gap-3 border-b border-slate-200 px-4 py-3"><div><p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">Class roster</p><h2 id="mobile-roster-title" className="mt-0.5 text-lg font-black text-slate-900">View enrolled students</h2></div><button type="button" className="icon-action" onClick={onClose} aria-label="Close enrolled students"><X size={19} /></button></header><div className="p-3"><EnrolledStudentsPanel classId={classId} expectedCount={expectedCount} lobbyJoinedStudentIds={lobbyJoinedStudentIds} fullWidth /></div></section></div>
}