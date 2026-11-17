import { useMemo, useState } from 'react'
import { BookOpenCheck, CheckCircle2, ClipboardCheck, Filter, TriangleAlert } from 'lucide-react'
import { EmptyState, ErrorState, LoadingState } from '../components/ScreenState'
import { StudentTodoRow } from '../components/StudentTodoRow'
import { useClasses } from '../hooks/useClasses'
import { type StudentTodoItem, type TodoStatus, useStudentTodo } from '../hooks/useStudentTodo'

const tabs: { value: TodoStatus; label: string; icon: typeof ClipboardCheck }[] = [
  { value: 'assigned', label: 'Assigned', icon: ClipboardCheck },
  { value: 'missing', label: 'Missing', icon: TriangleAlert },
  { value: 'done', label: 'Done', icon: CheckCircle2 },
]

export function StudentTodoPage() {
  const { classes, loading: classesLoading, error: classesError, reload: reloadClasses } = useClasses()
  const { grouped, loading, error, reload } = useStudentTodo(classes, !classesLoading && !classesError)
  const [tab, setTab] = useState<TodoStatus>('assigned')
  const [classId, setClassId] = useState('all')
  const filtered = useMemo(() => grouped[tab].filter((item) => classId === 'all' || item.classId === classId), [classId, grouped, tab])
  const dated = filtered.filter((item) => item.dueAt)
  const noDate = filtered.filter((item) => !item.dueAt)
  const busy = classesLoading || loading
  const shownError = classesError ?? error

  return <div className="mx-auto max-w-[1200px]">
    <section className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 px-5 pt-5 sm:px-8 sm:pt-7">
        <div className="flex items-center gap-3"><div className="grid size-11 place-items-center rounded-2xl bg-blue-50 text-brand-700"><BookOpenCheck size={22} /></div><div><h2 className="text-2xl font-black text-slate-900">To-do</h2><p className="text-sm text-slate-500">Track assigned, missing, and completed classwork.</p></div></div>
        <div className="mt-6 flex gap-1 overflow-x-auto">{tabs.map((item) => { const Icon = item.icon; return <button type="button" key={item.value} onClick={() => setTab(item.value)} className={`inline-flex min-w-32 items-center justify-center gap-2 border-b-3 px-5 py-3 text-sm font-extrabold transition ${tab === item.value ? 'border-brand-600 text-brand-700' : 'border-transparent text-slate-500 hover:text-slate-800'}`}><Icon size={17} /> {item.label}<span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs">{grouped[item.value].length}</span></button> })}</div>
      </div>
      <div className="p-5 sm:p-8">
        <label className="mb-7 block max-w-md"><span className="mb-2 flex items-center gap-2 text-xs font-extrabold uppercase tracking-wide text-slate-500"><Filter size={14} /> Class</span><select className="form-select mt-0" value={classId} onChange={(event) => setClassId(event.target.value)}><option value="all">All classes</option>{classes.map((item) => <option key={item.id} value={item.id}>{item.subject?.code ?? 'Subject'} — {item.section}</option>)}</select></label>
        {busy && <LoadingState label="Loading your to-do list…" />}
        {shownError && <ErrorState message={shownError} onRetry={() => void (classesError ? reloadClasses() : reload())} />}
        {!busy && !shownError && filtered.length === 0 && <EmptyState title={`No ${tab} work`} description={tab === 'assigned' ? 'You have no unfinished assigned classwork.' : tab === 'missing' ? 'You have no overdue classwork.' : 'Completed work will appear here.'} />}
        {!busy && !shownError && filtered.length > 0 && <div className="space-y-8">{dated.length > 0 && <TodoGroup title={tab === 'missing' ? 'Past due' : tab === 'done' ? 'Completed work' : 'Due date'} items={dated} />}{noDate.length > 0 && <TodoGroup title="No due date" items={noDate} />}</div>}
      </div>
    </section>
  </div>
}

function TodoGroup({ title, items }: { title: string; items: StudentTodoItem[] }) {
  return <section><div className="mb-3 flex items-center justify-between"><h3 className="text-xl font-black text-slate-800">{title}</h3><span className="class-count-badge">{items.length}</span></div><div className="divide-y divide-slate-200 overflow-hidden rounded-2xl border border-slate-200">{items.map((item) => <StudentTodoRow key={`${item.kind}-${item.id}`} item={item} />)}</div></section>
}