import { ArrowRight, BookOpen, ExternalLink } from 'lucide-react'
import { Link, Navigate, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { AnnouncementsTab } from '../components/classroom/AnnouncementsTab'
import { AssignmentsTab } from '../components/classroom/AssignmentsTab'
import { DiscussionsTab } from '../components/classroom/DiscussionsTab'
import { MaterialsTab } from '../components/classroom/MaterialsTab'
import { ProgressTab } from '../components/classroom/ProgressTab'
import { ExamsTab, QuizzesTab } from '../components/classroom/QuizzesTab'
import { MyLearningTab } from '../components/classroom/MyLearningTab'
import { EmptyState, ErrorState, LoadingState } from '../components/ScreenState'
import { useAuth } from '../hooks/useAuth'
import { useClasses } from '../hooks/useClasses'

const workspaceSections = {
  'my-learning': {
    label: 'My Learning',
    description: 'Module-based course paths, required activities, timelines, and completion progress.',
  },
  materials: {
    label: 'Learning materials',
    description: 'Lessons, syllabi, downloadable files, and course resource links.',
  },
  assignments: {
    label: 'Assignments',
    description: 'Instructions, deadlines, student submissions, scores, and feedback.',
  },
  quizzes: {
    label: 'Online quizzes',
    description: 'Scheduled class quizzes, objective scoring, attempts, and results.',
  },
  exams: {
    label: 'Exams',
    description: 'Prelim, midterm, semi-final, final, and custom class examinations.',
  },
  discussions: {
    label: 'Discussions',
    description: 'Moderated course conversations and topic-based exchanges.',
  },
  announcements: {
    label: 'Announcements',
    description: 'Important class updates, deadline reminders, and notices.',
  },
  progress: {
    label: 'Progress and reports',
    description: 'Activity completion and available assignment and quiz score summaries.',
  },
} as const

type WorkspaceSection = keyof typeof workspaceSections

function isWorkspaceSection(value: string | undefined): value is WorkspaceSection {
  return Boolean(value && value in workspaceSections)
}

export function WorkspacePage() {
  const { section } = useParams()
  const [searchParams, setSearchParams] = useSearchParams()
  const navigate = useNavigate()
  const { profile } = useAuth()
  const { classes, loading, error, reload } = useClasses()
  const validSection = isWorkspaceSection(section) ? section : null
  const requestedClassId = searchParams.get('class')
  const selectedClass = classes.find((item) => item.id === requestedClassId) ?? classes[0] ?? null
  const canManageContent = Boolean(selectedClass && profile?.role === 'instructor' && selectedClass.instructor_id === profile.id)
  const isStudent = profile?.role === 'student'
  const canViewReports = canManageContent

  if (!validSection) return <Navigate to="/workspace/my-learning" replace />
  if (!profile) return null
  if (profile.role === 'admin') return <Navigate to="/classes" replace />
  const details = workspaceSections[validSection]

  const selectClass = (classId: string) => {
    const next = new URLSearchParams(searchParams)
    next.set('class', classId)
    setSearchParams(next, { replace: true })
  }

  return (
    <div className="mx-auto max-w-[1500px]">
      <section className="mb-6 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm sm:p-6">
        <div className="flex flex-col justify-between gap-5 lg:flex-row lg:items-end">
          <div>
            <p className="text-xs font-extrabold uppercase tracking-[0.16em] text-brand-700">Class workspace</p>
            <h2 className="mt-1 text-2xl font-black tracking-tight text-slate-900">{details.label}</h2>
            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">{details.description}</p>
          </div>
          {!loading && !error && classes.length > 0 && (
            <label className="block w-full lg:max-w-md">
              <span className="mb-1.5 block text-xs font-extrabold uppercase tracking-wide text-slate-500">Selected class</span>
              <select className="form-select mt-0" value={selectedClass?.id ?? ''} onChange={(event) => selectClass(event.target.value)}>
                {classes.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.subject?.code ?? 'Subject'} — {item.section} ({item.semester})
                  </option>
                ))}
              </select>
            </label>
          )}
        </div>
      </section>

      {loading && <LoadingState label="Loading your class workspace…" />}
      {error && <ErrorState message={error} onRetry={() => void reload()} />}
      {!loading && !error && !selectedClass && (
        <EmptyState title="No class workspace available" description="No active class is assigned or enrolled through OneCampus." />
      )}
      {!loading && !error && selectedClass && (
        <section className="card classroom-outline overflow-hidden">
          <div className="flex flex-col justify-between gap-4 border-b border-slate-200 bg-slate-50 px-5 py-4 sm:flex-row sm:items-center sm:px-6">
            <div className="flex min-w-0 items-center gap-3">
              <div className="grid size-10 shrink-0 place-items-center rounded-xl bg-blue-100 text-brand-700"><BookOpen size={19} /></div>
              <div className="min-w-0">
                <p className="truncate font-extrabold text-slate-900">{selectedClass.subject?.code} · {selectedClass.subject?.title}</p>
                <p className="truncate text-xs text-slate-500">Section {selectedClass.section} · {selectedClass.instructor?.full_name}</p>
              </div>
            </div>
            <Link className="button-secondary w-full sm:w-auto" to={`/classes/${selectedClass.id}`}>
              Full classroom <ExternalLink size={15} />
            </Link>
          </div>
          <div className="p-4 sm:p-6 lg:p-8">
            {validSection === 'my-learning' && <MyLearningTab classId={selectedClass.id} canManage={canManageContent} isStudent={isStudent} onNavigate={(tab) => navigate(`/classes/${selectedClass.id}?tab=${tab}`)} />}
            {validSection === 'materials' && <MaterialsTab classId={selectedClass.id} canManage={canManageContent} />}
            {validSection === 'assignments' && <AssignmentsTab classId={selectedClass.id} canManage={canManageContent} canViewReports={canViewReports} isStudent={isStudent} />}
            {validSection === 'quizzes' && <QuizzesTab classId={selectedClass.id} canManage={canManageContent} isStudent={isStudent} />}
            {validSection === 'exams' && <ExamsTab classId={selectedClass.id} canManage={canManageContent} isStudent={isStudent} />}
            {validSection === 'discussions' && <DiscussionsTab classId={selectedClass.id} canManage={canManageContent} canParticipate expectedRosterCount={Number(selectedClass.enrolled_student_count)} />}
            {validSection === 'announcements' && <AnnouncementsTab classId={selectedClass.id} canManage={canManageContent} />}
            {validSection === 'progress' && <ProgressTab classId={selectedClass.id} canViewReports={canViewReports} classDetails={selectedClass} />}
          </div>
          <div className="border-t border-slate-100 px-5 py-4 text-right sm:px-6">
            <Link to="/classes" className="inline-flex items-center gap-2 text-sm font-bold text-brand-700">Browse all classes <ArrowRight size={16} /></Link>
          </div>
        </section>
      )}
    </div>
  )
}