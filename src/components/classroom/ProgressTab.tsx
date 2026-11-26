import { useCallback, useEffect, useMemo, useState } from 'react'
import { createPortal } from 'react-dom'
import { Award, BarChart3, Download, Eye, Printer, X } from 'lucide-react'
import { EmptyState, ErrorState, LoadingState } from '../ScreenState'
import { ScoreBar } from '../ScoreBar'
import { useAuth } from '../../hooks/useAuth'
import { supabase } from '../../lib/supabase'
import type { ClassSummary, Database } from '../../types/database'
import { formatScheduleMeeting, scheduleRoomLabel } from '../../lib/classSchedule'
import { TabHeading } from './MaterialsTab'
import { useClassNotifications } from '../../hooks/useClassNotifications'
import { ProfileAvatar } from '../ProfileAvatar'

type Assignment = Database['public']['Tables']['assignments']['Row']
type Quiz = Database['public']['Tables']['quizzes']['Row']
type Submission = Database['public']['Tables']['submissions']['Row']
type Attempt = Database['public']['Tables']['quiz_attempts']['Row']
type Question = Database['public']['Tables']['quiz_questions']['Row']
type ProgressClass = Pick<ClassSummary, 'id' | 'section' | 'school_year' | 'semester' | 'subject' | 'instructor' | 'schedule'>
interface Student { id: string; full_name: string; school_id: string; avatar_path: string | null }
interface ReportRow { id: string; fullName: string; schoolId: string; avatarPath: string | null; assignmentEarned: number; assignmentPossible: number; quizEarned: number; quizPossible: number; completed: number; activityCount: number; earned: number; possible: number }

export function ProgressTab({ classId, canViewReports, classDetails }: { classId: string; canViewReports: boolean; classDetails: ProgressClass }) {
  const { profile } = useAuth()
  const { byClass, markViewed } = useClassNotifications()
  const [assignments, setAssignments] = useState<Assignment[]>([]), [quizzes, setQuizzes] = useState<Quiz[]>([]), [questions, setQuestions] = useState<Question[]>([]), [submissions, setSubmissions] = useState<Submission[]>([]), [attempts, setAttempts] = useState<Attempt[]>([]), [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(true), [error, setError] = useState<string | null>(null), [previewOpen, setPreviewOpen] = useState(false)
  const generatedAt = useMemo(() => new Date(), [])

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    const [assignmentResult, quizResult, enrollmentResult] = await Promise.all([
      supabase.from('assignments').select('*').eq('class_id', classId).neq('status', 'draft'),
      supabase.from('quizzes').select('*').eq('class_id', classId).neq('status', 'draft'),
      canViewReports ? supabase.from('enrollments').select('student:profiles!enrollments_student_id_fkey(id, full_name, school_id, avatar_path)').eq('class_id', classId).eq('status', 'enrolled') : Promise.resolve({ data: [], error: null }),
    ])
    const firstError = assignmentResult.error ?? quizResult.error ?? enrollmentResult.error
    if (firstError) { setError(firstError.message); setLoading(false); return }
    const assignmentRows = assignmentResult.data ?? [], quizRows = quizResult.data ?? []
    setAssignments(assignmentRows); setQuizzes(quizRows); setStudents((enrollmentResult.data ?? []).map(normalizeStudent).filter(Boolean) as Student[])
    const [submissionResult, attemptResult, questionResult] = await Promise.all([
      assignmentRows.length ? supabase.from('submissions').select('*').in('assignment_id', assignmentRows.map((item) => item.id)) : Promise.resolve({ data: [], error: null }),
      quizRows.length ? supabase.from('quiz_attempts').select('*').in('quiz_id', quizRows.map((item) => item.id)) : Promise.resolve({ data: [], error: null }),
      quizRows.length ? supabase.from('quiz_questions').select('*').in('quiz_id', quizRows.map((item) => item.id)) : Promise.resolve({ data: [], error: null }),
    ])
    if (submissionResult.error || attemptResult.error || questionResult.error) setError((submissionResult.error ?? attemptResult.error ?? questionResult.error)?.message ?? 'Unable to load progress.')
    else { setSubmissions(submissionResult.data ?? []); setAttempts(attemptResult.data ?? []); setQuestions(questionResult.data ?? []) }
    setLoading(false)
  }, [canViewReports, classId])

  useEffect(() => { const timer = window.setTimeout(() => void load(), 0); return () => window.clearTimeout(timer) }, [load])

  const assignmentPossible = useMemo(() => assignments.reduce((sum, item) => sum + Number(item.points), 0), [assignments])
  const quizPossible = useMemo(() => questions.reduce((sum, item) => sum + Number(item.points), 0), [questions])
  const maximum = assignmentPossible + quizPossible
  const activityCount = assignments.length + quizzes.length
  const ownResult = profile ? calculate(profile.id, assignments, quizzes, questions, submissions, attempts) : null
  const reportRows = useMemo<ReportRow[]>(() => students.map((student) => {
    const result = calculate(student.id, assignments, quizzes, questions, submissions, attempts)
    return { id: student.id, fullName: student.full_name, schoolId: student.school_id, avatarPath: student.avatar_path, assignmentEarned: submissions.filter((item) => item.student_id === student.id).reduce((sum, item) => sum + Number(item.grade ?? 0), 0), assignmentPossible, quizEarned: attempts.filter((item) => item.student_id === student.id).reduce((sum, item) => sum + Number(item.score ?? 0), 0), quizPossible, completed: result.completed, activityCount, earned: result.earned, possible: result.possible }
  }), [activityCount, assignmentPossible, assignments, attempts, questions, quizPossible, quizzes, students, submissions])

  const downloadReport = () => {
    const schedule = classDetails.schedule.length ? classDetails.schedule.map((meeting) => `${formatScheduleMeeting(meeting)} · ${scheduleRoomLabel(meeting)}`).join(' | ') : 'Schedule not yet published'
    const rows: (string | number)[][] = [['ADFC OneCampus Learning Management System'], ['Class Progress Report'], ['Subject code', classDetails.subject?.code ?? ''], ['Subject title', classDetails.subject?.title ?? ''], ['Class', `Section ${classDetails.section} · ${classDetails.semester}, ${classDetails.school_year} · ${classDetails.instructor?.full_name ?? 'Not assigned'}`], ['Schedule', schedule], ['Generated', generatedAt.toLocaleString()], [], ['Student', 'School ID', 'Assignment earned', 'Assignment possible', 'Quiz earned', 'Quiz possible', 'Completed', 'Activities', 'Overall earned', 'Overall possible', 'Overall percentage'], ...reportRows.map((row) => [row.fullName, row.schoolId, row.assignmentEarned, row.assignmentPossible, row.quizEarned, row.quizPossible, row.completed, row.activityCount, row.earned, row.possible, percentage(row.earned, row.possible)])]
    const csv = `\uFEFF${rows.map((row) => row.map(csvCell).join(',')).join('\r\n')}`
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }))
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.download = `${classDetails.subject?.code ?? 'class'}-progress-report.csv`.replace(/[^a-zA-Z0-9._-]/g, '_')
    document.body.appendChild(anchor); anchor.click(); anchor.remove(); URL.revokeObjectURL(url)
  }

  const printReport = () => {
    const cleanup = () => document.body.classList.remove('printing-progress-report')
    document.body.classList.add('printing-progress-report')
    window.addEventListener('afterprint', cleanup, { once: true })
    window.print()
  }

  if (loading) return <LoadingState label="Calculating progress…" />
  if (error) return <ErrorState message={error} onRetry={() => void load()} />
  if (!assignments.length && !quizzes.length) return <EmptyState title="No graded activities" description="Progress will appear after assignments or quizzes are published." />

  return <>
    <section>
      <TabHeading title={canViewReports ? 'Class gradebook' : 'My progress'} description={canViewReports ? 'Review assignment and quiz performance for enrolled students.' : 'See your available scores across class activities.'} action={canViewReports && <div className="flex w-full flex-col gap-2 sm:w-auto sm:flex-row"><button type="button" className="button-secondary w-full sm:w-auto" onClick={() => setPreviewOpen(true)}><Eye size={17} /> Preview Report</button><button type="button" className="button-primary w-full sm:w-auto" onClick={printReport}><Printer size={17} /> Print report</button></div>} />
      {!canViewReports && ownResult && <div className={`grid gap-4 rounded-2xl md:grid-cols-3 ${byClass[classId]?.progress ? 'notification-content-unread' : ''}`} onClick={() => markViewed(classId, 'progress')}><ProgressCard label="Overall score" icon={<Award />}><ScoreBar earned={ownResult.earned} possible={ownResult.possible} label="Overall" compact /></ProgressCard><ProgressCard label="Points earned" icon={<BarChart3 />}><ScoreBar earned={ownResult.earned} possible={ownResult.possible} label="Points" compact /></ProgressCard><ProgressCard label="Completed" icon={<BarChart3 />}><ScoreBar earned={ownResult.completed} possible={activityCount} label="Activities" compact /></ProgressCard></div>}
      {canViewReports && <ReportTable rows={reportRows} />}
      <p className="mt-4 text-xs text-slate-400">Only graded assignments and submitted quizzes contribute to earned points. Published activity points define the available total. {maximum === 0 ? 'No points are available yet.' : ''}</p>
    </section>
    {canViewReports && createPortal(<PrintableProgressReport classDetails={classDetails} rows={reportRows} generatedAt={generatedAt} maximum={maximum} />, document.body)}
    {previewOpen && <ProgressReportPreview classDetails={classDetails} rows={reportRows} generatedAt={generatedAt} maximum={maximum} onClose={() => setPreviewOpen(false)} onDownload={downloadReport} onPrint={printReport} />}
  </>
}

function ReportHeader({ classDetails, generatedAt }: { classDetails: ProgressClass; generatedAt: Date }) {
  return <header className="progress-report-header"><p className="progress-report-eyebrow">ADFC OneCampus Learning Management System</p><h1>Class Progress Report</h1><div className="progress-report-class"><p className="progress-report-code">{classDetails.subject?.code ?? 'Subject'}</p><h2>{classDetails.subject?.title ?? 'Untitled subject'}</h2><p>Section {classDetails.section} · {classDetails.semester}, {classDetails.school_year} · {classDetails.instructor?.full_name ?? 'Not assigned'}</p><div className="progress-report-schedules">{classDetails.schedule.length ? classDetails.schedule.map((meeting) => <p key={meeting.meeting_id}><span>{formatScheduleMeeting(meeting)}</span><span>{scheduleRoomLabel(meeting)}</span></p>) : <p>Schedule not yet published</p>}</div></div><p className="progress-report-generated">Generated {generatedAt.toLocaleString()}</p></header>
}

function PrintableProgressReport({ classDetails, rows, generatedAt, maximum }: { classDetails: ProgressClass; rows: ReportRow[]; generatedAt: Date; maximum: number }) {
  return <section className="progress-print-report print-only-report" aria-hidden="true"><ReportHeader classDetails={classDetails} generatedAt={generatedAt} /><h3>Class gradebook</h3><p className="progress-report-description">Review assignment and quiz performance for enrolled students.</p><ReportTable rows={rows} report /><p className="progress-report-note">Only graded assignments and submitted quizzes contribute to earned points. Published activity points define the available total. {maximum === 0 ? 'No points are available yet.' : ''}</p></section>
}

function ProgressReportPreview({ classDetails, rows, generatedAt, maximum, onClose, onDownload, onPrint }: { classDetails: ProgressClass; rows: ReportRow[]; generatedAt: Date; maximum: number; onClose: () => void; onDownload: () => void; onPrint: () => void }) {
  useEffect(() => { const previousOverflow = document.body.style.overflow; document.body.style.overflow = 'hidden'; const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') onClose() }; window.addEventListener('keydown', closeOnEscape); return () => { document.body.style.overflow = previousOverflow; window.removeEventListener('keydown', closeOnEscape) } }, [onClose])
  return <div className="modal-backdrop print-hidden" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}><section className="modal-card flex max-w-6xl flex-col overflow-hidden p-0 sm:p-0" role="dialog" aria-modal="true" aria-labelledby="progress-preview-title"><header className="flex items-start justify-between gap-3 border-b border-slate-200 px-4 py-4 sm:px-6"><div><p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">Progress report preview</p><h2 id="progress-preview-title" className="mt-1 text-lg font-black text-slate-900 sm:text-xl">{classDetails.subject?.code} class progress report</h2></div><button type="button" className="icon-action shrink-0" onClick={onClose} aria-label="Close report preview"><X size={19} /></button></header><div className="min-h-0 flex-1 overflow-auto bg-slate-100 p-3 sm:p-5"><article className="progress-report-preview mx-auto max-w-[850px] bg-white p-5 shadow-sm sm:p-8"><ReportHeader classDetails={classDetails} generatedAt={generatedAt} /><h3 className="mt-6 text-lg font-black">Class gradebook</h3><p className="progress-report-description">Review assignment and quiz performance for enrolled students.</p><ReportTable rows={rows} report /><p className="progress-report-note">Only graded assignments and submitted quizzes contribute to earned points. Published activity points define the available total. {maximum === 0 ? 'No points are available yet.' : ''}</p></article></div><footer className="flex flex-col-reverse gap-2 border-t border-slate-200 px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-6"><p className="text-xs font-semibold text-slate-500">Print dialog can save the portrait report as PDF.</p><div className="flex flex-col gap-2 sm:flex-row"><button type="button" className="button-secondary" onClick={onClose}>Close</button><button type="button" className="button-secondary" onClick={onDownload}><Download size={17} /> Download CSV</button><button type="button" className="button-primary" onClick={onPrint}><Printer size={17} /> Print / Save PDF</button></div></footer></section></div>
}

function ReportTable({ rows, report = false }: { rows: ReportRow[]; report?: boolean }) {
  if (rows.length === 0) return <div className="p-4 sm:p-6"><EmptyState title="No enrolled students" description="The gradebook will populate after enrollment sync." /></div>
  return <div className={`overflow-hidden rounded-2xl border border-slate-200 bg-white ${report ? 'progress-report-table' : ''}`}><div className="overflow-x-auto"><table className="admin-table"><thead><tr><th>Student</th><th>Assignment points</th><th>Quiz points</th><th>Completed</th><th>Overall</th></tr></thead><tbody>{rows.map((row) => <tr key={row.id}><td data-label="Student"><div className="flex min-w-44 items-center gap-3">{!report && <ProfileAvatar name={row.fullName} avatarPath={row.avatarPath} className="size-10 text-xs" />}<div><p className="font-bold text-slate-800">{row.fullName}</p><p className="text-xs text-slate-400">{row.schoolId}</p></div></div></td><td data-label="Assignment points"><ScoreBar earned={row.assignmentEarned} possible={row.assignmentPossible} label="Assignments" compact /></td><td data-label="Quiz points"><ScoreBar earned={row.quizEarned} possible={row.quizPossible} label="Quizzes" compact /></td><td data-label="Completed"><ScoreBar earned={row.completed} possible={row.activityCount} label="Activities" compact /></td><td data-label="Overall"><ScoreBar earned={row.earned} possible={row.possible} label="Overall" compact /></td></tr>)}</tbody></table></div></div>
}

function calculate(studentId: string, assignments: Assignment[], quizzes: Quiz[], questions: Question[], submissions: Submission[], attempts: Attempt[]) { const assignmentPossible = assignments.reduce((sum, item) => sum + Number(item.points), 0); const assignmentEarned = submissions.filter((item) => item.student_id === studentId).reduce((sum, item) => sum + Number(item.grade ?? 0), 0); const studentAttempts = attempts.filter((item) => item.student_id === studentId); const quizIds = new Set(quizzes.map((item) => item.id)); const quizPossible = questions.filter((item) => quizIds.has(item.quiz_id)).reduce((sum, item) => sum + Number(item.points), 0); const quizEarned = studentAttempts.reduce((sum, item) => sum + Number(item.score ?? 0), 0); return { possible: assignmentPossible + quizPossible, earned: assignmentEarned + quizEarned, completed: submissions.filter((item) => item.student_id === studentId).length + studentAttempts.length } }
function normalizeStudent(value: unknown): Student | null { const relation = (value as { student: Student | Student[] | null }).student; return Array.isArray(relation) ? relation[0] ?? null : relation }
function ProgressCard({ label, icon, children }: { label: string; icon: React.ReactNode; children: React.ReactNode }) { return <article className="summary-card min-h-36"><div className="min-w-0 flex-1"><p className="summary-label">{label}</p><div className="mt-4">{children}</div></div><div className="summary-icon bg-blue-50 text-brand-700">{icon}</div></article> }
function percentage(earned: number, possible: number) { return possible > 0 ? `${(earned / possible * 100).toFixed(1)}%` : '0.0%' }
function csvCell(value: string | number | null | undefined) { let text = value == null ? '' : String(value); if (/^[=+\-@]/.test(text)) text = `'${text}`; return `"${text.replaceAll('"', '""')}"` }