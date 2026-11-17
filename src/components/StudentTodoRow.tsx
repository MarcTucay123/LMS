import { CheckCircle2, ChevronRight, ClipboardCheck, FileQuestion } from 'lucide-react'
import { Link } from 'react-router-dom'
import type { StudentTodoItem } from '../hooks/useStudentTodo'

export function StudentTodoRow({ item, compact = false }: { item: StudentTodoItem; compact?: boolean }) {
  const Icon = item.kind === 'assignment' ? ClipboardCheck : FileQuestion
  const iconStyle = item.kind === 'exam' ? 'bg-pink-100 text-pink-700' : item.kind === 'quiz' ? 'bg-cyan-100 text-cyan-700' : 'bg-blue-100 text-brand-700'
  return <Link to={item.href} className={`group flex items-center gap-3 bg-white transition hover:bg-slate-50 ${compact ? 'px-4 py-3' : 'px-4 py-4 sm:px-5'}`}><div className={`grid shrink-0 place-items-center rounded-full ${compact ? 'size-10' : 'size-12'} ${iconStyle}`}><Icon size={compact ? 18 : 21} /></div><div className="min-w-0 flex-1"><p className="truncate font-extrabold text-slate-900">{item.title}</p><p className="mt-0.5 truncate text-xs text-slate-500">{item.classLabel} · {kindLabel(item)}</p><p className="mt-1 text-xs font-semibold text-slate-400">{item.dueAt ? `Due ${formatTodoDate(item.dueAt)}` : `Posted ${formatTodoDate(item.postedAt)}`}</p></div>{item.status === 'missing' && <span className="hidden rounded-full bg-red-50 px-2.5 py-1 text-xs font-extrabold text-red-700 sm:inline">Missing</span>}{item.status === 'done' && <CheckCircle2 className="text-emerald-600" size={20} />}<ChevronRight className="shrink-0 text-slate-300 transition group-hover:translate-x-0.5 group-hover:text-brand-700" size={19} /></Link>
}

function kindLabel(item: StudentTodoItem) {
  if (item.kind === 'exam') return 'Exam'
  if (item.kind === 'quiz') return 'Quiz'
  return item.points === null ? 'Assignment' : `Assignment · ${item.points} points`
}

function formatTodoDate(value: string) {
  return new Date(value).toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: 'numeric', minute: '2-digit' })
}