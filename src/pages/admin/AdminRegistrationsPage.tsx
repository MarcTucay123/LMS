import { useCallback, useEffect, useMemo, useState } from 'react'
import { Check, Clock3, UserCheck, X } from 'lucide-react'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { EmptyState, ErrorState, LoadingState } from '../../components/ScreenState'
import { supabase } from '../../lib/supabase'
import type { RegistrationApplication, UserRole } from '../../types/database'

interface ClassOption {
  id: string
  section: string
  semester: string
  subject: { code: string; title: string } | null
  instructor: { full_name: string } | null
}

type RawClassOption = Omit<ClassOption, 'subject' | 'instructor'> & {
  subject: ClassOption['subject'] | NonNullable<ClassOption['subject']>[]
  instructor: ClassOption['instructor'] | NonNullable<ClassOption['instructor']>[]
}

export function AdminRegistrationsPage() {
  const [applications, setApplications] = useState<RegistrationApplication[]>([])
  const [classes, setClasses] = useState<ClassOption[]>([])
  const [selectedClasses, setSelectedClasses] = useState<Record<string, string[]>>({})
  const [loading, setLoading] = useState(true)
  const [savingId, setSavingId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    const [applicationResult, classResult] = await Promise.all([
      supabase.from('registration_applications').select('*').order('created_at', { ascending: false }),
      supabase.from('classes').select('id, section, semester, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)').eq('status', 'active').order('created_at'),
    ])
    const firstError = applicationResult.error ?? classResult.error
    if (firstError) setError(firstError.message)
    else {
      setApplications(applicationResult.data ?? [])
      setClasses((classResult.data ?? []).map((item) => normalizeClass(item as unknown as RawClassOption)))
    }
    setLoading(false)
  }, [])

  useEffect(() => {
    let active = true
    void Promise.all([
      supabase.from('registration_applications').select('*').order('created_at', { ascending: false }),
      supabase.from('classes').select('id, section, semester, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)').eq('status', 'active').order('created_at'),
    ]).then(([applicationResult, classResult]) => {
      if (!active) return
      const firstError = applicationResult.error ?? classResult.error
      if (firstError) setError(firstError.message)
      else {
        setApplications(applicationResult.data ?? [])
        setClasses((classResult.data ?? []).map((item) => normalizeClass(item as unknown as RawClassOption)))
      }
      setLoading(false)
    })
    return () => { active = false }
  }, [])

  const pending = useMemo(() => applications.filter((item) => item.status === 'pending'), [applications])
  const reviewed = useMemo(() => applications.filter((item) => item.status !== 'pending'), [applications])

  const toggleClass = (applicationId: string, classId: string) => {
    setSelectedClasses((current) => {
      const existing = current[applicationId] ?? []
      return { ...current, [applicationId]: existing.includes(classId) ? existing.filter((id) => id !== classId) : [...existing, classId] }
    })
  }

  const approve = async (application: RegistrationApplication) => {
    setSavingId(application.id); setError(null); setMessage(null)
    const { data, error: approvalError } = await supabase.rpc('admin_approve_registration', {
      target_application_id: application.id,
      assigned_class_ids: application.requested_role === 'instructor' ? selectedClasses[application.id] ?? [] : [],
    })
    setSavingId(null)
    if (approvalError) return setError(approvalError.message)
    setMessage(`${data.full_name} was approved as ${roleLabel(data.role)} with OC ID ${data.onecampus_user_id}.`)
    await load()
  }

  const reject = async (application: RegistrationApplication) => {
    setSavingId(application.id); setError(null); setMessage(null)
    const { error: rejectionError } = await supabase.rpc('admin_reject_registration', { target_application_id: application.id })
    setSavingId(null)
    if (rejectionError) return setError(rejectionError.message)
    setMessage(`${application.full_name}'s registration was rejected.`)
    await load()
  }

  return (
    <div className="mx-auto max-w-[1500px]">
      <AdminPageHeader icon={UserCheck} eyebrow="Administration" title="Registration approvals" description="Approve account applications, generate OC IDs, and assign classes to newly approved instructors." />
      {message && <div className="mb-4 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm font-semibold text-emerald-800">{message}</div>}
      {error && <div className="mb-4"><ErrorState message={error} onRetry={() => void load()} /></div>}
      {loading && <LoadingState label="Loading registration applications…" />}
      {!loading && !error && pending.length === 0 && <EmptyState title="No pending registrations" description="New account applications will appear here for review." />}
      {!loading && pending.length > 0 && <div className="space-y-5">{pending.map((application) => <article className="card p-5 sm:p-6" key={application.id}><div className="flex flex-col justify-between gap-4 md:flex-row md:items-start"><div><div className="flex flex-wrap items-center gap-2"><h3 className="text-lg font-extrabold text-slate-900">{application.full_name}</h3><span className="status-pill bg-amber-50 text-amber-700">Pending {roleLabel(application.requested_role)}</span></div><p className="mt-1 text-sm text-slate-600">{application.email}</p><p className="mt-2 inline-flex items-center gap-1 text-xs text-slate-400"><Clock3 size={13} /> Applied {new Date(application.created_at).toLocaleString()}</p><p className="mt-3 text-xs font-semibold text-brand-700">OC ID and account ID will be generated automatically after approval.</p></div><div className="flex gap-2"><button className="button-secondary text-red-600" disabled={savingId === application.id} onClick={() => void reject(application)}><X size={16} /> Reject</button><button className="button-primary" disabled={savingId === application.id} onClick={() => void approve(application)}><Check size={16} /> {savingId === application.id ? 'Saving…' : 'Approve'}</button></div></div>{application.requested_role === 'instructor' && <div className="mt-5 border-t border-slate-100 pt-4"><p className="text-sm font-extrabold text-slate-800">Assign active classes</p><p className="mt-1 text-xs text-slate-500">Selected classes will be reassigned to this instructor and will automatically appear on their dashboard.</p>{classes.length === 0 ? <p className="mt-3 text-sm text-slate-400">No active classes are available.</p> : <div className="mt-3 grid gap-2 md:grid-cols-2 xl:grid-cols-3">{classes.map((classItem) => <label key={classItem.id} className="flex cursor-pointer items-start gap-3 rounded-xl border border-slate-200 p-3 hover:bg-slate-50"><input className="mt-1" type="checkbox" checked={(selectedClasses[application.id] ?? []).includes(classItem.id)} onChange={() => toggleClass(application.id, classItem.id)} /><span><strong className="block text-sm text-slate-800">{classItem.subject?.code} — {classItem.section}</strong><small className="text-xs text-slate-500">{classItem.subject?.title} · Current: {classItem.instructor?.full_name ?? 'Unassigned'}</small></span></label>)}</div>}</div>}</article>)}</div>}

      {!loading && reviewed.length > 0 && <section className="mt-8"><h3 className="mb-3 text-lg font-extrabold text-slate-900">Reviewed applications</h3><div className="overflow-hidden rounded-2xl border border-slate-200 bg-white"><div className="overflow-x-auto"><table className="admin-table"><thead><tr><th>Applicant</th><th>Requested role</th><th>Status</th><th>Reviewed</th></tr></thead><tbody>{reviewed.map((item) => <tr key={item.id}><td><p className="font-bold text-slate-800">{item.full_name}</p><p className="text-xs text-slate-500">{item.email}</p></td><td className="capitalize">{item.requested_role}</td><td><span className={`status-pill ${item.status === 'approved' ? 'status-pill-active' : 'bg-red-50 text-red-700'}`}>{item.status}</span></td><td>{item.reviewed_at ? new Date(item.reviewed_at).toLocaleString() : '—'}</td></tr>)}</tbody></table></div></div></section>}
    </div>
  )
}

function normalizeClass(item: RawClassOption): ClassOption {
  return { ...item, subject: Array.isArray(item.subject) ? item.subject[0] ?? null : item.subject, instructor: Array.isArray(item.instructor) ? item.instructor[0] ?? null : item.instructor }
}

function roleLabel(role: UserRole) {
  return role === 'admin' ? 'administrator' : role
}