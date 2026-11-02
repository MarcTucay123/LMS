import { useCallback, useEffect, useMemo, useState } from 'react'
import { Award, BarChart3 } from 'lucide-react'
import { EmptyState, ErrorState, LoadingState } from '../ScreenState'
import { useAuth } from '../../hooks/useAuth'
import { supabase } from '../../lib/supabase'
import type { Database } from '../../types/database'
import { TabHeading } from './MaterialsTab'

type Assignment = Database['public']['Tables']['assignments']['Row']
type Quiz = Database['public']['Tables']['quizzes']['Row']
type Submission = Database['public']['Tables']['submissions']['Row']
type Attempt = Database['public']['Tables']['quiz_attempts']['Row']
type Question = Database['public']['Tables']['quiz_questions']['Row']
interface Student { id: string; full_name: string; school_id: string }

export function ProgressTab({ classId, canManage }: { classId: string; canManage: boolean }) {
  const { profile } = useAuth()
  const [assignments, setAssignments] = useState<Assignment[]>([]), [quizzes, setQuizzes] = useState<Quiz[]>([]), [questions, setQuestions] = useState<Question[]>([]), [submissions, setSubmissions] = useState<Submission[]>([]), [attempts, setAttempts] = useState<Attempt[]>([]), [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(true), [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    const [assignmentResult, quizResult, enrollmentResult] = await Promise.all([
      supabase.from('assignments').select('*').eq('class_id', classId).neq('status', 'draft'),
      supabase.from('quizzes').select('*').eq('class_id', classId).neq('status', 'draft'),
      canManage ? supabase.from('enrollments').select('student:profiles!enrollments_student_id_fkey(id, full_name, school_id)').eq('class_id', classId).eq('status', 'enrolled') : Promise.resolve({ data: [], error: null }),
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
  }, [canManage, classId])

  useEffect(() => {
    let active = true
    void (async () => {
      const [assignmentResult, quizResult, enrollmentResult] = await Promise.all([
        supabase.from('assignments').select('*').eq('class_id', classId).neq('status', 'draft'),
        supabase.from('quizzes').select('*').eq('class_id', classId).neq('status', 'draft'),
        canManage ? supabase.from('enrollments').select('student:profiles!enrollments_student_id_fkey(id, full_name, school_id)').eq('class_id', classId).eq('status', 'enrolled') : Promise.resolve({ data: [], error: null }),
      ])
      if (!active) return
      const firstError = assignmentResult.error ?? quizResult.error ?? enrollmentResult.error
      if (firstError) { setError(firstError.message); setLoading(false); return }
      const assignmentRows = assignmentResult.data ?? [], quizRows = quizResult.data ?? []
      setAssignments(assignmentRows); setQuizzes(quizRows); setStudents((enrollmentResult.data ?? []).map(normalizeStudent).filter(Boolean) as Student[])
      const [submissionResult, attemptResult, questionResult] = await Promise.all([
        assignmentRows.length ? supabase.from('submissions').select('*').in('assignment_id', assignmentRows.map((item) => item.id)) : Promise.resolve({ data: [], error: null }),
        quizRows.length ? supabase.from('quiz_attempts').select('*').in('quiz_id', quizRows.map((item) => item.id)) : Promise.resolve({ data: [], error: null }),
        quizRows.length ? supabase.from('quiz_questions').select('*').in('quiz_id', quizRows.map((item) => item.id)) : Promise.resolve({ data: [], error: null }),
      ])
      if (!active) return
      if (submissionResult.error || attemptResult.error || questionResult.error) setError((submissionResult.error ?? attemptResult.error ?? questionResult.error)?.message ?? 'Unable to load progress.')
      else { setSubmissions(submissionResult.data ?? []); setAttempts(attemptResult.data ?? []); setQuestions(questionResult.data ?? []) }
      setLoading(false)
    })()
    return () => { active = false }
  }, [canManage, classId])

  const maximum = useMemo(() => assignments.reduce((sum, item) => sum + Number(item.points), 0) + questions.reduce((sum, item) => sum + Number(item.points), 0), [assignments, questions])
  const ownResult = profile ? calculate(profile.id, assignments, quizzes, questions, submissions, attempts) : null

  if (loading) return <LoadingState label="Calculating progress…" />
  if (error) return <ErrorState message={error} onRetry={() => void load()} />
  if (!assignments.length && !quizzes.length) return <EmptyState title="No graded activities" description="Progress will appear after assignments or quizzes are published." />

  return <section><TabHeading title={canManage ? 'Class gradebook' : 'My progress'} description={canManage ? 'Review assignment and quiz performance for enrolled students.' : 'See your available scores across class activities.'} />
    {!canManage && ownResult && <div className="grid gap-4 md:grid-cols-3"><ProgressCard label="Overall score" value={`${ownResult.percentage.toFixed(1)}%`} icon={<Award />} /><ProgressCard label="Points earned" value={`${ownResult.earned} / ${ownResult.possible}`} icon={<BarChart3 />} /><ProgressCard label="Completed" value={`${ownResult.completed} / ${assignments.length + quizzes.length}`} icon={<BarChart3 />} /></div>}
    {canManage && <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white"><div className="overflow-x-auto"><table className="admin-table"><thead><tr><th>Student</th><th>Assignment points</th><th>Quiz points</th><th>Completed</th><th>Overall</th></tr></thead><tbody>{students.map((student) => { const result = calculate(student.id, assignments, quizzes, questions, submissions, attempts); const assignmentEarned = submissions.filter((item) => item.student_id === student.id).reduce((sum, item) => sum + Number(item.grade ?? 0), 0); const quizEarned = attempts.filter((item) => item.student_id === student.id).reduce((sum, item) => sum + Number(item.score ?? 0), 0); return <tr key={student.id}><td data-label="Student"><p className="font-bold text-slate-800">{student.full_name}</p><p className="text-xs text-slate-400">{student.school_id}</p></td><td data-label="Assignment points">{assignmentEarned} / {assignments.reduce((sum, item) => sum + Number(item.points), 0)}</td><td data-label="Quiz points">{quizEarned} / {questions.reduce((sum, item) => sum + Number(item.points), 0)}</td><td data-label="Completed">{result.completed} / {assignments.length + quizzes.length}</td><td data-label="Overall"><strong className="text-brand-700">{result.percentage.toFixed(1)}%</strong></td></tr>})}</tbody></table></div>{students.length === 0 && <div className="p-4 sm:p-6"><EmptyState title="No enrolled students" description="The gradebook will populate after enrollment sync." /></div>}</div>}
    <p className="mt-4 text-xs text-slate-400">Only graded assignments and submitted quizzes contribute to earned points. Published activity points define the available total. {maximum === 0 ? 'No points are available yet.' : ''}</p>
  </section>
}

function calculate(studentId: string, assignments: Assignment[], quizzes: Quiz[], questions: Question[], submissions: Submission[], attempts: Attempt[]) { const assignmentPossible = assignments.reduce((sum, item) => sum + Number(item.points), 0); const assignmentEarned = submissions.filter((item) => item.student_id === studentId).reduce((sum, item) => sum + Number(item.grade ?? 0), 0); const studentAttempts = attempts.filter((item) => item.student_id === studentId); const quizIds = new Set(quizzes.map((item) => item.id)); const quizPossible = questions.filter((item) => quizIds.has(item.quiz_id)).reduce((sum, item) => sum + Number(item.points), 0); const quizEarned = studentAttempts.reduce((sum, item) => sum + Number(item.score ?? 0), 0); const possible = assignmentPossible + quizPossible, earned = assignmentEarned + quizEarned; return { possible, earned, percentage: possible ? earned / possible * 100 : 0, completed: submissions.filter((item) => item.student_id === studentId).length + studentAttempts.length } }
function normalizeStudent(value: unknown): Student | null { const relation = (value as { student: Student | Student[] | null }).student; return Array.isArray(relation) ? relation[0] ?? null : relation }
function ProgressCard({ label, value, icon }: { label: string; value: string; icon: React.ReactNode }) { return <article className="summary-card min-h-32"><div><p className="summary-label">{label}</p><p className="summary-value">{value}</p></div><div className="summary-icon bg-blue-50 text-brand-700">{icon}</div></article> }