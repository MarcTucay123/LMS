import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'
import { BookOpenCheck, Check, CheckCircle2, ChevronDown, ChevronUp, Circle, FileQuestion, FileText, GraduationCap, LockKeyhole, MessageCircle, Plus, Trash2, X } from 'lucide-react'
import { DateTimeField } from '../DateTimeField'
import { EmptyState, ErrorState, LoadingState } from '../ScreenState'
import { useConfirmation } from '../../hooks/useConfirmation'
import { supabase } from '../../lib/supabase'
import type { Database, LearningItemType, PublishStatus } from '../../types/database'
import { TabHeading } from './MaterialsTab'
import { formatDate } from './workspace'

type LearningModule = Database['public']['Tables']['learning_modules']['Row']
type ModuleItem = Database['public']['Tables']['learning_module_items']['Row']
type Material = Database['public']['Tables']['materials']['Row']
type Assignment = Database['public']['Tables']['assignments']['Row']
type Quiz = Database['public']['Tables']['quizzes']['Row']
type Discussion = Database['public']['Tables']['discussion_topics']['Row']
type Activity = { id: string; type: LearningItemType; title: string; description: string | null; status?: string; dueAt?: string | null }

const itemLabels: Record<LearningItemType, string> = {
  material: 'Material',
  assignment: 'Assignment',
  quiz: 'Quiz / knowledge check',
  exam: 'Exam',
  discussion: 'Discussion',
}

const itemTabs: Record<LearningItemType, 'materials' | 'assignments' | 'quizzes' | 'exams' | 'discussions'> = {
  material: 'materials',
  assignment: 'assignments',
  quiz: 'quizzes',
  exam: 'exams',
  discussion: 'discussions',
}

export function MyLearningTab({ classId, canManage, isStudent, onNavigate }: { classId: string; canManage: boolean; isStudent: boolean; onNavigate: (tab: 'materials' | 'assignments' | 'quizzes' | 'exams' | 'discussions') => void }) {
  const { confirm } = useConfirmation()
  const [modules, setModules] = useState<LearningModule[]>([])
  const [items, setItems] = useState<Record<string, ModuleItem[]>>({})
  const [activities, setActivities] = useState<Activity[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [moduleFormOpen, setModuleFormOpen] = useState(false)
  const [itemFormModule, setItemFormModule] = useState<string | null>(null)
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({})
  const [saving, setSaving] = useState(false)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [position, setPosition] = useState('1')
  const [opensAt, setOpensAt] = useState('')
  const [dueAt, setDueAt] = useState('')
  const [status, setStatus] = useState<PublishStatus>('draft')
  const [prerequisite, setPrerequisite] = useState('')
  const [itemType, setItemType] = useState<LearningItemType>('material')
  const [itemId, setItemId] = useState('')
  const [itemTitle, setItemTitle] = useState('')
  const [itemPosition, setItemPosition] = useState('1')
  const [itemRequired, setItemRequired] = useState(true)
  const [estimatedMinutes, setEstimatedMinutes] = useState('')
  const [now, setNow] = useState(0)

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    const [moduleResult, materialResult, assignmentResult, quizResult, discussionResult] = await Promise.all([
      supabase.from('learning_modules').select('*').eq('class_id', classId).order('position'),
      supabase.from('materials').select('*').eq('class_id', classId).order('created_at'),
      supabase.from('assignments').select('*').eq('class_id', classId).order('due_at'),
      supabase.from('quizzes').select('*').eq('class_id', classId).order('created_at'),
      supabase.from('discussion_topics').select('*').eq('class_id', classId).order('created_at'),
    ])
    const firstError = moduleResult.error ?? materialResult.error ?? assignmentResult.error ?? quizResult.error ?? discussionResult.error
    if (firstError) { setError(firstError.message); setLoading(false); return }
    const moduleRows = moduleResult.data ?? []
    const itemResults = await Promise.all(moduleRows.map((module) => supabase.from('learning_module_items').select('*').eq('module_id', module.id).order('position')))
    const itemError = itemResults.find((result) => result.error)?.error
    if (itemError) { setError(itemError.message); setLoading(false); return }
    setModules(moduleRows)
    setItems(Object.fromEntries(moduleRows.map((module, index) => [module.id, itemResults[index].data ?? []])))
    setActivities(buildActivities(materialResult.data ?? [], assignmentResult.data ?? [], quizResult.data ?? [], discussionResult.data ?? []))
    setLoading(false)
  }, [classId])

  useEffect(() => { const timer = window.setTimeout(() => void load(), 0); return () => window.clearTimeout(timer) }, [load])
  useEffect(() => {
    const update = () => setNow(Date.now())
    const initial = window.setTimeout(update, 0)
    const timer = window.setInterval(update, 60_000)
    return () => { window.clearTimeout(initial); window.clearInterval(timer) }
  }, [])

  const activityByKey = useMemo(() => new Map(activities.map((activity) => [`${activity.type}:${activity.id}`, activity])), [activities])
  const moduleCompletion = useMemo(() => Object.fromEntries(modules.map((module) => {
    const required = (items[module.id] ?? []).filter((item) => item.is_required)
    return [module.id, required.length > 0 && required.every((item) => item.is_completed)]
  })), [items, modules])
  const allItems = modules.flatMap((module) => items[module.id] ?? [])
  const completedCount = allItems.filter((item) => item.is_completed).length
  const progress = allItems.length ? Math.round(completedCount / allItems.length * 100) : 0

  const createModule = async (event: FormEvent) => {
    event.preventDefault(); setError(null)
    const numericPosition = Number(position)
    if (!title.trim() || !Number.isInteger(numericPosition) || numericPosition < 1) return setError('Enter a module title and a valid sequence number.')
    if (opensAt && dueAt && new Date(dueAt).getTime() <= new Date(opensAt).getTime()) return setError('The module due date must be after its opening date.')
    setSaving(true)
    const { error: insertError } = await supabase.from('learning_modules').insert({ class_id: classId, title: title.trim(), description: description.trim() || null, position: numericPosition, opens_at: opensAt ? new Date(opensAt).toISOString() : null, due_at: dueAt ? new Date(dueAt).toISOString() : null, status, prerequisite_module_id: prerequisite || null })
    setSaving(false)
    if (insertError) return setError(insertError.message)
    setTitle(''); setDescription(''); setPosition(String(modules.length + 2)); setOpensAt(''); setDueAt(''); setStatus('draft'); setPrerequisite(''); setModuleFormOpen(false)
    await load()
  }

  const updateModuleStatus = async (module: LearningModule) => {
    const next: PublishStatus = module.status === 'published' ? 'closed' : 'published'
    const { error: updateError } = await supabase.from('learning_modules').update({ status: next }).eq('id', module.id)
    if (updateError) setError(updateError.message); else await load()
  }

  const removeModule = async (module: LearningModule) => {
    if (!await confirm({ title: `Delete “${module.title}”?`, message: 'The module and its learning-path links will be deleted. Original materials, assignments, quizzes, exams, and discussions will remain available in their existing tabs.', confirmLabel: 'Delete module', tone: 'danger', icon: 'delete' })) return
    const { error: deleteError } = await supabase.from('learning_modules').delete().eq('id', module.id)
    if (deleteError) setError(deleteError.message); else await load()
  }

  const beginAddItem = (module: LearningModule) => {
    setItemFormModule(module.id); setItemType('material'); setItemId(''); setItemTitle(''); setItemPosition(String((items[module.id]?.length ?? 0) + 1)); setItemRequired(true); setEstimatedMinutes('')
  }

  const addItem = async (event: FormEvent) => {
    event.preventDefault(); setError(null)
    if (!itemFormModule || !itemId) return setError('Choose an activity to add.')
    const numericPosition = Number(itemPosition), minutes = estimatedMinutes ? Number(estimatedMinutes) : null
    if (!Number.isInteger(numericPosition) || numericPosition < 1 || (minutes !== null && (!Number.isInteger(minutes) || minutes < 1))) return setError('Enter valid sequence and estimated-time values.')
    setSaving(true)
    const { error: insertError } = await supabase.from('learning_module_items').insert({ module_id: itemFormModule, item_type: itemType, item_id: itemId, title_override: itemTitle.trim() || null, position: numericPosition, is_required: itemRequired, estimated_minutes: minutes })
    setSaving(false)
    if (insertError) return setError(insertError.message)
    setItemFormModule(null); await load()
  }

  const removeItem = async (item: ModuleItem) => {
    const activity = activityByKey.get(`${item.item_type}:${item.item_id}`)
    if (!await confirm({ title: 'Remove learning-path activity?', message: `“${item.title_override || activity?.title || 'This activity'}” will be removed from the module, but its original record will not be deleted.`, confirmLabel: 'Remove activity', tone: 'danger', icon: 'delete' })) return
    const { error: deleteError } = await supabase.from('learning_module_items').delete().eq('id', item.id)
    if (deleteError) setError(deleteError.message); else await load()
  }

  const setComplete = async (item: ModuleItem) => {
    const { error: completionError } = await supabase.rpc('set_learning_item_complete', { target_module_item_id: item.id, completed: !item.is_completed })
    if (completionError) setError(completionError.message); else await load()
  }

  if (loading) return <LoadingState label="Loading your learning path…" />
  if (error && modules.length === 0) return <ErrorState message={error} onRetry={() => void load()} />

  return <section>
    <TabHeading title={canManage ? 'Course builder' : 'My Learning'} description={canManage ? 'Organize existing class activities into sequenced modules and timelines.' : 'Follow your course modules, complete activities, and track what comes next.'} action={canManage && <button className={moduleFormOpen ? 'button-secondary' : 'button-primary'} onClick={() => { setModuleFormOpen((open) => !open); setPosition(String(modules.length + 1)) }}>{moduleFormOpen ? <><X size={17} /> Cancel</> : <><Plus size={17} /> Add module</>}</button>} />
    {error && <div className="mb-4"><ErrorState message={error} onRetry={() => void load()} /></div>}
    {!canManage && modules.length > 0 && <div className="mb-6 rounded-2xl border border-blue-200 bg-gradient-to-r from-blue-50 to-white p-5"><div className="flex flex-wrap items-center justify-between gap-3"><div><p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">Course progress</p><p className="mt-1 text-2xl font-black text-slate-900">{progress}% complete</p><p className="mt-1 text-sm text-slate-500">{completedCount} of {allItems.length} learning activities completed</p></div><GraduationCap className="text-brand-700" size={42} /></div><div className="mt-4 h-2.5 overflow-hidden rounded-full bg-blue-100"><div className="h-full rounded-full bg-brand-700 transition-all" style={{ width: `${progress}%` }} /></div></div>}
    {moduleFormOpen && <form className="workspace-form mb-6" onSubmit={createModule}><h3 className="font-extrabold text-slate-900">New course module</h3><input className="form-input" placeholder="Module title, e.g. Module 1: Introduction" value={title} onChange={(event) => setTitle(event.target.value)} /><textarea className="form-textarea" placeholder="Module description (optional)" value={description} onChange={(event) => setDescription(event.target.value)} /><div className="grid gap-3 md:grid-cols-2"><DateTimeField label="Opens at (optional)" value={opensAt} onChange={setOpensAt} /><DateTimeField label="Due at (optional)" value={dueAt} min={opensAt || undefined} onChange={setDueAt} /></div><div className="grid gap-3 md:grid-cols-3"><label className="field-label">Sequence<input className="form-input" type="number" min="1" value={position} onChange={(event) => setPosition(event.target.value)} /></label><label className="field-label">Initial status<select className="form-select" value={status} onChange={(event) => setStatus(event.target.value as PublishStatus)}><option value="draft">Draft</option><option value="published">Published</option></select></label><label className="field-label">Prerequisite module<select className="form-select" value={prerequisite} onChange={(event) => setPrerequisite(event.target.value)}><option value="">None</option>{modules.map((module) => <option key={module.id} value={module.id}>{module.title}</option>)}</select></label></div><div className="flex justify-end"><button className="button-primary" disabled={saving}>{saving ? 'Creating…' : 'Create module'}</button></div></form>}
    {modules.length === 0 ? <EmptyState title="No learning modules yet" description={canManage ? 'Create the first module, then connect existing materials, assignments, quizzes, exams, and discussions.' : 'Your instructor has not published a learning path yet.'} /> : <div className="space-y-4">{modules.map((module) => {
      const moduleItems = items[module.id] ?? []
      const prerequisiteModule = modules.find((candidate) => candidate.id === module.prerequisite_module_id)
      const opensInFuture = Boolean(now > 0 && module.opens_at && new Date(module.opens_at).getTime() > now)
      const locked = isStudent && (opensInFuture || Boolean(prerequisiteModule && !moduleCompletion[prerequisiteModule.id]))
      const moduleCompleted = Boolean(moduleCompletion[module.id])
      const isCollapsed = collapsed[module.id] ?? false
      const availableActivities = activities.filter((activity) => activity.type === itemType && !moduleItems.some((existing) => existing.item_type === activity.type && existing.item_id === activity.id))
      return <article className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm" key={module.id}>
        <header className="class-roster-header flex flex-wrap items-start justify-between gap-3 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-blue-50 p-4 sm:p-5"><div className="flex min-w-0 flex-1 items-start gap-3"><div className={`mt-0.5 grid size-10 shrink-0 place-items-center rounded-full ${moduleCompleted ? 'bg-emerald-100 text-emerald-700' : locked ? 'bg-slate-200 text-slate-500' : 'bg-blue-100 text-brand-700'}`}>{moduleCompleted ? <CheckCircle2 size={21} /> : locked ? <LockKeyhole size={19} /> : <BookOpenCheck size={20} />}</div><div className="min-w-0"><div className="flex flex-wrap items-center gap-2"><h3 className="break-words text-lg font-black text-slate-900">{module.title}</h3>{canManage && <span className={`status-pill ${module.status === 'published' ? 'status-pill-active' : 'status-pill-inactive'}`}>{module.status}</span>}{moduleCompleted && <span className="status-pill status-pill-active">Completed</span>}</div>{module.description && <p className="mt-1 text-sm text-slate-600">{module.description}</p>}<p className="mt-2 text-xs font-semibold text-slate-500">{moduleItems.length} activities{module.opens_at ? ` · Opens ${formatDate(module.opens_at)}` : ''}{module.due_at ? ` · Due ${formatDate(module.due_at)}` : ''}</p>{locked && <p className="mt-2 text-xs font-bold text-amber-700">{opensInFuture ? `Available ${formatDate(module.opens_at)}` : `Complete ${prerequisiteModule?.title ?? 'the prerequisite module'} first.`}</p>}</div></div><div className="flex shrink-0 gap-2">{canManage && <><button className="button-secondary" onClick={() => void updateModuleStatus(module)}>{module.status === 'published' ? 'Close' : 'Publish'}</button><button className="icon-action text-red-600" title="Delete module" onClick={() => void removeModule(module)}><Trash2 size={17} /></button></>}<button className="icon-action" aria-label={isCollapsed ? `Expand ${module.title}` : `Collapse ${module.title}`} onClick={() => setCollapsed((current) => ({ ...current, [module.id]: !isCollapsed }))}>{isCollapsed ? <ChevronDown size={19} /> : <ChevronUp size={19} />}</button></div></header>
        {!isCollapsed && <div className="p-4 sm:p-5">{moduleItems.length === 0 ? <p className="rounded-xl bg-slate-50 p-4 text-sm text-slate-500">No activities have been added to this module.</p> : <div className="space-y-2">{moduleItems.map((item, index) => {
          const activity = activityByKey.get(`${item.item_type}:${item.item_id}`)
          const titleText = item.title_override || activity?.title || 'Unavailable activity'
          return <div className={`flex flex-col gap-3 rounded-xl border p-3 sm:flex-row sm:items-center ${item.is_completed ? 'border-emerald-200 bg-emerald-50' : locked ? 'border-slate-200 bg-slate-50 opacity-70' : 'border-slate-200 bg-white'}`} key={item.id}><div className="flex min-w-0 flex-1 items-start gap-3"><div className={`mt-0.5 grid size-8 shrink-0 place-items-center rounded-full ${item.is_completed ? 'bg-emerald-600 text-white' : 'bg-slate-100 text-slate-500'}`}>{item.is_completed ? <Check size={16} /> : <Circle size={15} />}</div><ItemIcon type={item.item_type} /><div className="min-w-0"><p className="break-words font-extrabold text-slate-900">{index + 1}. {titleText}</p><p className="mt-0.5 text-xs font-semibold text-slate-500">{itemLabels[item.item_type]} · {item.is_required ? 'Required' : 'Optional'}{item.estimated_minutes ? ` · About ${item.estimated_minutes} min` : ''}{activity?.dueAt ? ` · Due ${formatDate(activity.dueAt)}` : ''}</p>{activity?.description && <p className="mt-1 line-clamp-2 text-sm text-slate-600">{activity.description}</p>}</div></div><div className="flex flex-wrap gap-2 sm:justify-end">{isStudent && ['material','discussion'].includes(item.item_type) && !locked && <button className={item.is_completed ? 'button-secondary' : 'button-primary'} onClick={() => void setComplete(item)}>{item.is_completed ? 'Mark incomplete' : 'Mark complete'}</button>}<button className="button-secondary" disabled={locked || !activity} onClick={() => onNavigate(itemTabs[item.item_type])}>{locked ? <LockKeyhole size={15} /> : null} Open activity</button>{canManage && <button className="icon-action text-red-600" title="Remove from module" onClick={() => void removeItem(item)}><Trash2 size={16} /></button>}</div></div>
        })}</div>}
        {canManage && (itemFormModule === module.id ? <ActivityPickerForm itemType={itemType} itemId={itemId} itemTitle={itemTitle} itemPosition={itemPosition} itemRequired={itemRequired} estimatedMinutes={estimatedMinutes} availableActivities={availableActivities} activityCounts={activityCounts(activities, moduleItems)} saving={saving} onTypeChange={(value) => { setItemType(value); setItemId('') }} onItemChange={setItemId} onTitleChange={setItemTitle} onPositionChange={setItemPosition} onRequiredChange={setItemRequired} onEstimatedMinutesChange={setEstimatedMinutes} onCreateActivity={() => onNavigate(itemTabs[itemType])} onClose={() => setItemFormModule(null)} onSubmit={addItem} /> : <button className="button-secondary mt-4" onClick={() => beginAddItem(module)}><Plus size={16} /> Add learning activity</button>)}</div>}
      </article>
    })}</div>}
  </section>
}

function ActivityPickerForm({ itemType, itemId, itemTitle, itemPosition, itemRequired, estimatedMinutes, availableActivities, activityCounts: counts, saving, onTypeChange, onItemChange, onTitleChange, onPositionChange, onRequiredChange, onEstimatedMinutesChange, onCreateActivity, onClose, onSubmit }: { itemType: LearningItemType; itemId: string; itemTitle: string; itemPosition: string; itemRequired: boolean; estimatedMinutes: string; availableActivities: Activity[]; activityCounts: Record<LearningItemType, number>; saving: boolean; onTypeChange: (value: LearningItemType) => void; onItemChange: (value: string) => void; onTitleChange: (value: string) => void; onPositionChange: (value: string) => void; onRequiredChange: (value: boolean) => void; onEstimatedMinutesChange: (value: string) => void; onCreateActivity: () => void; onClose: () => void; onSubmit: (event: FormEvent) => void }) {
  const typeName = itemLabels[itemType]
  return <form className="workspace-form mt-4" onSubmit={onSubmit}>
    <div className="flex items-center justify-between gap-3"><div><h4 className="font-extrabold text-slate-900">Add learning activity</h4><p className="mt-1 text-xs text-slate-500">Choose an activity already created for this class, or create a new one first.</p></div><button type="button" className="icon-action" onClick={onClose}><X size={17} /></button></div>
    <div className="grid gap-3 md:grid-cols-2">
      <label className="field-label">Activity type<select className="form-select" value={itemType} onChange={(event) => onTypeChange(event.target.value as LearningItemType)}>{Object.entries(itemLabels).map(([value, label]) => <option key={value} value={value}>{label} ({counts[value as LearningItemType]})</option>)}</select></label>
      <label className="field-label">Existing activity<select className="form-select" value={itemId} disabled={availableActivities.length === 0} onChange={(event) => onItemChange(event.target.value)}><option value="">{availableActivities.length ? `Choose ${typeName.toLowerCase()}` : `No ${typeName.toLowerCase()} available`}</option>{availableActivities.map((activity) => <option key={activity.id} value={activity.id}>{activity.title}</option>)}</select></label>
    </div>
    {availableActivities.length === 0 && <div className="rounded-xl border border-amber-200 bg-amber-50 p-4"><p className="text-sm font-bold text-amber-900">No {typeName.toLowerCase()} has been created for this class yet.</p><p className="mt-1 text-xs text-amber-700">Create it in the {itemTabs[itemType]} tab, then return here to place it in this module.</p><button type="button" className="button-secondary mt-3" onClick={onCreateActivity}><Plus size={16} /> Create {typeName.toLowerCase()}</button></div>}
    <input className="form-input" placeholder="Learning-path title override, e.g. Diagnostic Pre-Assessment (optional)" value={itemTitle} onChange={(event) => onTitleChange(event.target.value)} />
    <div className="grid gap-3 sm:grid-cols-3"><label className="field-label">Sequence<input className="form-input" type="number" min="1" value={itemPosition} onChange={(event) => onPositionChange(event.target.value)} /></label><label className="field-label">Estimated minutes<input className="form-input" type="number" min="1" placeholder="Optional" value={estimatedMinutes} onChange={(event) => onEstimatedMinutesChange(event.target.value)} /></label><label className="flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-3 text-sm font-bold text-slate-700"><input type="checkbox" checked={itemRequired} onChange={(event) => onRequiredChange(event.target.checked)} /> Required for completion</label></div>
    <div className="flex justify-end"><button className="button-primary" disabled={saving || availableActivities.length === 0 || !itemId}>{saving ? 'Adding…' : 'Add activity'}</button></div>
  </form>
}

function activityCounts(activities: Activity[], moduleItems: ModuleItem[]): Record<LearningItemType, number> {
  const counts: Record<LearningItemType, number> = { material: 0, assignment: 0, quiz: 0, exam: 0, discussion: 0 }
  for (const activity of activities) {
    if (!moduleItems.some((item) => item.item_type === activity.type && item.item_id === activity.id)) counts[activity.type]++
  }
  return counts
}

function buildActivities(materials: Material[], assignments: Assignment[], quizzes: Quiz[], discussions: Discussion[]): Activity[] {
  return [
    ...materials.map((item) => ({ id: item.id, type: 'material' as const, title: item.title, description: item.description })),
    ...assignments.map((item) => ({ id: item.id, type: 'assignment' as const, title: item.title, description: item.instructions, status: item.status, dueAt: item.due_at })),
    ...quizzes.map((item) => ({ id: item.id, type: item.assessment_kind as 'quiz' | 'exam', title: item.title, description: item.description, status: item.status, dueAt: item.closes_at })),
    ...discussions.map((item) => ({ id: item.id, type: 'discussion' as const, title: item.title, description: item.body })),
  ]
}

function ItemIcon({ type }: { type: LearningItemType }) {
  const className = 'mt-1 shrink-0 text-brand-700'
  if (type === 'material') return <FileText className={className} size={18} />
  if (type === 'assignment') return <BookOpenCheck className={className} size={18} />
  if (type === 'discussion') return <MessageCircle className={className} size={18} />
  if (type === 'exam') return <GraduationCap className={className} size={18} />
  return <FileQuestion className={className} size={18} />
}