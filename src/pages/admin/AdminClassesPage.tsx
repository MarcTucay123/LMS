import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { BookCopy, Pencil, Plus, X } from 'lucide-react'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { EmptyState, ErrorState, LoadingState } from '../../components/ScreenState'
import { supabase } from '../../lib/supabase'

interface Option { id: string; label: string }
interface ManagedClass {
  id: string
  subject_id: string
  instructor_id: string
  section: string
  school_year: string
  semester: string
  status: string
  subject: { code: string; title: string } | null
  instructor: { full_name: string } | null
}

interface ClassForm { subjectId: string; instructorId: string; section: string; schoolYear: string; semester: string; status: 'active' | 'archived' }
const emptyForm: ClassForm = { subjectId: '', instructorId: '', section: '', schoolYear: '', semester: 'First Semester', status: 'active' }

export function AdminClassesPage() {
  const [classes, setClasses] = useState<ManagedClass[]>([])
  const [subjects, setSubjects] = useState<Option[]>([])
  const [instructors, setInstructors] = useState<Option[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [formOpen, setFormOpen] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [form, setForm] = useState<ClassForm>(emptyForm)
  const [saving, setSaving] = useState(false)

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    const [classResult, subjectResult, instructorResult] = await Promise.all([
      supabase.from('classes').select('id, subject_id, instructor_id, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)').order('created_at', { ascending: false }),
      supabase.from('subjects').select('id, code, title').order('code'),
      supabase.from('profiles').select('id, full_name, status').eq('role', 'instructor').order('full_name'),
    ])
    const firstError = classResult.error ?? subjectResult.error ?? instructorResult.error
    if (firstError) setError(firstError.message)
    else {
      setClasses((classResult.data ?? []).map((row) => normalizeClass(row as unknown as ManagedClass)))
      setSubjects((subjectResult.data ?? []).map((item) => ({ id: item.id, label: `${item.code} — ${item.title}` })))
      setInstructors((instructorResult.data ?? []).map((item) => ({ id: item.id, label: `${item.full_name} (${item.status})` })))
    }
    setLoading(false)
  }, [])

  useEffect(() => {
    let active = true
    const requests = [
      supabase.from('classes').select('id, subject_id, instructor_id, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)').order('created_at', { ascending: false }),
      supabase.from('subjects').select('id, code, title').order('code'),
      supabase.from('profiles').select('id, full_name, status').eq('role', 'instructor').order('full_name'),
    ] as const
    void Promise.all(requests).then(([classResult, subjectResult, instructorResult]) => {
      if (!active) return
      const firstError = classResult.error ?? subjectResult.error ?? instructorResult.error
      if (firstError) setError(firstError.message)
      else {
        setClasses((classResult.data ?? []).map((row) => normalizeClass(row as unknown as ManagedClass)))
        setSubjects((subjectResult.data ?? []).map((item) => ({ id: item.id, label: `${item.code} — ${item.title}` })))
        setInstructors((instructorResult.data ?? []).map((item) => ({ id: item.id, label: `${item.full_name} (${item.status})` })))
      }
      setLoading(false)
    })
    return () => { active = false }
  }, [])

  const openCreate = () => { setEditingId(null); setForm(emptyForm); setFormOpen(true); setError(null); setMessage(null) }
  const openEdit = (item: ManagedClass) => {
    setEditingId(item.id)
    setForm({ subjectId: item.subject_id, instructorId: item.instructor_id, section: item.section, schoolYear: item.school_year, semester: item.semester, status: item.status as 'active' | 'archived' })
    setFormOpen(true); setError(null); setMessage(null)
  }

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault(); setError(null); setMessage(null)
    if (!form.subjectId || !form.instructorId || !form.section.trim() || !form.schoolYear.trim() || !form.semester.trim()) return setError('Complete all class offering fields.')
    setSaving(true)
    const values = { subject_id: form.subjectId, instructor_id: form.instructorId, section: form.section.trim(), school_year: form.schoolYear.trim(), semester: form.semester.trim(), status: form.status }
    const result = editingId ? await supabase.from('classes').update(values).eq('id', editingId) : await supabase.from('classes').insert(values)
    setSaving(false)
    if (result.error) return setError(result.error.message)
    setFormOpen(false); setMessage(editingId ? 'Class offering updated.' : 'Class offering created.')
    await load()
  }

  return (
    <div className="mx-auto max-w-[1500px]">
      <AdminPageHeader icon={BookCopy} eyebrow="Administration" title="Class offerings" description="Create, assign, update, activate, or archive LMS class offerings." action={<button className="button-primary" onClick={openCreate}><Plus size={18} /> New class</button>} />
      {message && <div className="mb-4 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm font-semibold text-emerald-800">{message}</div>}
      {error && <div className="mb-4"><ErrorState message={error} onRetry={() => void load()} /></div>}
      {loading && <LoadingState label="Loading class offerings…" />}
      {!loading && !error && classes.length === 0 && <EmptyState title="No class offerings" description="Create a class or run OneCampus synchronization." />}
      {!loading && classes.length > 0 && <div className="grid gap-4 lg:grid-cols-2 2xl:grid-cols-3">{classes.map((item) => <article className="card p-5" key={item.id}><div className="flex items-start justify-between gap-3"><div><p className="text-xs font-extrabold uppercase tracking-wide text-brand-700">{item.subject?.code}</p><h3 className="mt-1 font-extrabold text-slate-900">{item.subject?.title}</h3></div><span className={`status-pill ${item.status === 'active' ? 'status-pill-active' : 'status-pill-inactive'}`}>{item.status}</span></div><dl className="mt-5 grid grid-cols-2 gap-3 text-sm"><div><dt className="text-xs text-slate-400">Section</dt><dd className="font-semibold">{item.section}</dd></div><div><dt className="text-xs text-slate-400">School year</dt><dd className="font-semibold">{item.school_year}</dd></div><div><dt className="text-xs text-slate-400">Semester</dt><dd className="font-semibold">{item.semester}</dd></div><div><dt className="text-xs text-slate-400">Instructor</dt><dd className="truncate font-semibold">{item.instructor?.full_name}</dd></div></dl><button className="button-secondary mt-5 w-full" onClick={() => openEdit(item)}><Pencil size={16} /> Edit offering</button></article>)}</div>}

      {formOpen && <div className="modal-backdrop" role="presentation"><div className="modal-card" role="dialog" aria-modal="true" aria-labelledby="class-form-title"><div className="flex items-start justify-between gap-4"><div><h3 id="class-form-title" className="text-xl font-black text-slate-900">{editingId ? 'Edit class offering' : 'New class offering'}</h3><p className="mt-1 text-sm text-slate-500">Assign a subject and an instructor profile.</p></div><button className="icon-button" onClick={() => setFormOpen(false)} aria-label="Close"><X size={19} /></button></div><form className="mt-6 space-y-4" onSubmit={handleSubmit}><label className="field-label">Subject<select className="form-select" value={form.subjectId} onChange={(event) => setForm({ ...form, subjectId: event.target.value })}><option value="">Select subject</option>{subjects.map((item) => <option key={item.id} value={item.id}>{item.label}</option>)}</select></label><label className="field-label">Instructor<select className="form-select" value={form.instructorId} onChange={(event) => setForm({ ...form, instructorId: event.target.value })}><option value="">Select instructor</option>{instructors.map((item) => <option key={item.id} value={item.id}>{item.label}</option>)}</select></label><div className="grid gap-4 sm:grid-cols-2"><label className="field-label">Section<input className="form-input" value={form.section} onChange={(event) => setForm({ ...form, section: event.target.value })} placeholder="BSIT-2A" /></label><label className="field-label">School year<input className="form-input" value={form.schoolYear} onChange={(event) => setForm({ ...form, schoolYear: event.target.value })} placeholder="2026-2027" /></label></div><div className="grid gap-4 sm:grid-cols-2"><label className="field-label">Semester<input className="form-input" value={form.semester} onChange={(event) => setForm({ ...form, semester: event.target.value })} /></label><label className="field-label">Status<select className="form-select" value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value as 'active' | 'archived' })}><option value="active">Active</option><option value="archived">Archived</option></select></label></div><div className="flex justify-end gap-3 pt-2"><button type="button" className="button-secondary" onClick={() => setFormOpen(false)}>Cancel</button><button className="button-primary" disabled={saving}>{saving ? 'Saving…' : 'Save class'}</button></div></form></div></div>}
    </div>
  )
}

function normalizeClass(item: ManagedClass): ManagedClass {
  return { ...item, subject: Array.isArray(item.subject) ? item.subject[0] ?? null : item.subject, instructor: Array.isArray(item.instructor) ? item.instructor[0] ?? null : item.instructor }
}