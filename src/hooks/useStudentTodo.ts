import { useCallback, useEffect, useMemo, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { AssessmentKind, ClassSummary, Database } from '../types/database'

type Assignment = Database['public']['Tables']['assignments']['Row']
type Submission = Database['public']['Tables']['submissions']['Row']
type Quiz = Database['public']['Tables']['quizzes']['Row']
type Attempt = Database['public']['Tables']['quiz_attempts']['Row']

export type TodoStatus = 'assigned' | 'missing' | 'done'
export type TodoKind = 'assignment' | AssessmentKind

export interface StudentTodoItem {
  id: string
  classId: string
  classLabel: string
  title: string
  kind: TodoKind
  status: TodoStatus
  dueAt: string | null
  postedAt: string
  href: string
  points: number | null
}

interface ClassTodoData {
  assignments: Assignment[]
  submissions: Submission[]
  quizzes: Quiz[]
  attempts: Attempt[]
}

export function useStudentTodo(classes: ClassSummary[], enabled: boolean) {
  const [items, setItems] = useState<StudentTodoItem[]>([])
  const [loading, setLoading] = useState(enabled)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    if (!enabled) { setItems([]); setLoading(false); setError(null); return }
    if (!classes.length) { setItems([]); setLoading(false); setError(null); return }
    setLoading(true); setError(null)
    try {
      const rows = await Promise.all(classes.map(async (classItem) => {
        const [assignmentResult, quizResult] = await Promise.all([
          supabase.from('assignments').select('*').eq('class_id', classItem.id).order('due_at'),
          supabase.from('quizzes').select('*').eq('class_id', classItem.id).order('created_at', { ascending: false }),
        ])
        if (assignmentResult.error) throw assignmentResult.error
        if (quizResult.error) throw quizResult.error
        const assignments = assignmentResult.data ?? []
        const quizzes = quizResult.data ?? []
        const [submissionResult, attemptResult] = await Promise.all([
          assignments.length ? supabase.from('submissions').select('*').in('assignment_id', assignments.map((item) => item.id)) : Promise.resolve({ data: [], error: null }),
          quizzes.length ? supabase.from('quiz_attempts').select('*').in('quiz_id', quizzes.map((item) => item.id)) : Promise.resolve({ data: [], error: null }),
        ])
        if (submissionResult.error) throw submissionResult.error
        if (attemptResult.error) throw attemptResult.error
        return { classItem, data: { assignments, submissions: submissionResult.data ?? [], quizzes, attempts: attemptResult.data ?? [] } as ClassTodoData }
      }))
      setItems(rows.flatMap(({ classItem, data }) => buildClassTodo(classItem, data)))
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Unable to load your to-do list.')
    } finally {
      setLoading(false)
    }
  }, [classes, enabled])

  useEffect(() => {
    const timer = window.setTimeout(() => void load(), 0)
    return () => window.clearTimeout(timer)
  }, [load])

  const grouped = useMemo(() => ({
    assigned: items.filter((item) => item.status === 'assigned'),
    missing: items.filter((item) => item.status === 'missing'),
    done: items.filter((item) => item.status === 'done'),
  }), [items])

  return { items, grouped, loading, error, reload: load }
}

function buildClassTodo(classItem: ClassSummary, data: ClassTodoData): StudentTodoItem[] {
  const now = Date.now()
  const classLabel = `${classItem.subject?.code ?? 'Subject'} · ${classItem.section}`
  const submittedAssignments = new Set(data.submissions.map((item) => item.assignment_id))
  const attempts = new Map(data.attempts.map((item) => [item.quiz_id, item]))
  const assignmentItems = data.assignments.map((assignment): StudentTodoItem => {
    const done = submittedAssignments.has(assignment.id)
    const overdue = !done && (assignment.status === 'closed' || Boolean(assignment.due_at && new Date(assignment.due_at).getTime() < now))
    return { id: assignment.id, classId: classItem.id, classLabel, title: assignment.title, kind: 'assignment', status: done ? 'done' : overdue ? 'missing' : 'assigned', dueAt: assignment.due_at, postedAt: assignment.created_at, href: `/classes/${classItem.id}?tab=assignments`, points: Number(assignment.points) }
  })
  const quizItems = data.quizzes.map((quiz): StudentTodoItem => {
    const attempt = attempts.get(quiz.id)
    const done = attempt?.status === 'submitted'
    const overdue = !done && (quiz.status === 'closed' || Boolean(quiz.closes_at && new Date(quiz.closes_at).getTime() < now))
    const tab = quiz.assessment_kind === 'exam' ? 'exams' : 'quizzes'
    return { id: quiz.id, classId: classItem.id, classLabel, title: quiz.title, kind: quiz.assessment_kind, status: done ? 'done' : overdue ? 'missing' : 'assigned', dueAt: quiz.closes_at, postedAt: quiz.created_at, href: `/classes/${classItem.id}?tab=${tab}`, points: null }
  })
  return [...assignmentItems, ...quizItems].sort(compareTodo)
}

export function compareTodo(left: StudentTodoItem, right: StudentTodoItem) {
  if (!left.dueAt && !right.dueAt) return new Date(right.postedAt).getTime() - new Date(left.postedAt).getTime()
  if (!left.dueAt) return 1
  if (!right.dueAt) return -1
  return new Date(left.dueAt).getTime() - new Date(right.dueAt).getTime()
}