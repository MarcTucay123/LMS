import { useCallback, useEffect, useMemo, useState } from 'react'
import { Check, Clock3, UserCheck, X } from 'lucide-react'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { EmptyState, ErrorState, LoadingState } from '../../components/ScreenState'
import { supabase } from '../../lib/supabase'
import type { RegistrationApplication, UserRole } from '../../types/database'

interface ClassOption {
  id: string
  section: string
  school_year: string
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
  const [loading, setLoading] = useState(true)
  const [savingId, setSavingId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    const [applicationResult, classResult] = await Promise.all([
      supabase.from('registration_applications').select('*').order('created_at', { ascending: false }),
      supabase.from('classes').select('id, section, school_year, semester, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)').eq('status', 'active').order('created_at'),
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
      supabase.from('classes').select('id, section, school_year, semester, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)').eq('status', 'active').order('created_at'),
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

  const approve = async (application: RegistrationApplication) => {
    setSavingId(application.id); setError(null); setMessage(null)
    const { data, error: approvalError } = await supabase.rpc('admin_approve_registration', {
      target_application_id: application.id,
    })
    setSavingId(null)
    if (approvalError) return setError(approvalError.message)
    setMessage(`${data.full_name} was approved for LMS access as ${roleLabel(data.role)}. Official enrollment or teaching assignments must be synchronized from the owning subsystem.`)
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
      <AdminPageHeader icon={UserCheck} eyebrow="Administration" title="Registration approvals" description="Approve LMS account access. Official student enrollments and instructor assignments remain controlled by Enrollment and Class Scheduling." />
      {message && <div className="mb-4 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm font-semibold text-emerald-800">{message}</div>}
      {error && <div className="mb-4"><ErrorState message={error} onRetry={() => void load()} /></div>}
      {loading && <LoadingState label="Loading registration applications…" />}
      {!loading && !error && pending.length === 0 && <EmptyState title="No pending registrations" description="New account applications will appear here for review." />}
      {!loading && pending.length > 0 && <div className="space-y-5">{pending.map((application) => <article className="card p-4 sm:p-6" key={application.id}><div className="flex flex-col justify-between gap-4 md:flex-row md:items-start"><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><h3 className="break-words text-lg font-extrabold text-slate-900">{application.full_name}</h3><span className="status-pill bg-amber-50 text-amber-700">Pending {roleLabel(application.requested_role)}</span></div><p className="mt-1 break-all text-sm text-slate-600">{application.email}</p><dl className="mt-4 grid gap-3 rounded-xl bg-slate-50 p-3 text-sm min-[420px]:grid-cols-2 lg:grid-cols-4"><NameDetail label="First name" value={application.first_name} /><NameDetail label="Middle name" value={application.middle_name} /><NameDetail label="Last name" value={application.last_name} /><NameDetail label="Suffix" value={application.suffix} /></dl>{application.requested_role === 'student' && <StudentApplicationDetails application={application} classes={classes} />}<p className="mt-3 inline-flex items-center gap-1 text-xs text-slate-400"><Clock3 size={13} /> Applied {new Date(application.created_at).toLocaleString()}</p><p className="mt-3 text-xs font-semibold text-brand-700">Approval creates LMS access only. The official external ID, enrollment, or teaching assignment must arrive through synchronization.</p></div><div className="grid grid-cols-2 gap-2 sm:flex"><button className="button-secondary text-red-600" disabled={savingId === application.id} onClick={() => void reject(application)}><X size={16} /> Reject</button><button className="button-primary" disabled={savingId === application.id} onClick={() => void approve(application)}><Check size={16} /> {savingId === application.id ? 'Saving…' : 'Approve'}</button></div></div></article>)}</div>}

      {!loading && reviewed.length > 0 && <section className="mt-8"><h3 className="mb-3 text-lg font-extrabold text-slate-900">Reviewed applications</h3><div className="overflow-hidden rounded-2xl border border-slate-200 bg-white"><div className="overflow-x-auto"><table className="admin-table"><thead><tr><th>Applicant</th><th>Requested role</th><th>Status</th><th>Reviewed</th></tr></thead><tbody>{reviewed.map((item) => <tr key={item.id}><td data-label="Applicant"><p className="font-bold text-slate-800">{item.full_name}</p><p className="break-all text-xs text-slate-500">{item.email}</p></td><td data-label="Requested role" className="capitalize">{item.requested_role}</td><td data-label="Status"><span className={`status-pill ${item.status === 'approved' ? 'status-pill-active' : 'bg-red-50 text-red-700'}`}>{item.status}</span></td><td data-label="Reviewed">{item.reviewed_at ? new Date(item.reviewed_at).toLocaleString() : '—'}</td></tr>)}</tbody></table></div></div></section>}
    </div>
  )
}

function normalizeClass(item: RawClassOption): ClassOption {
  return { ...item, subject: Array.isArray(item.subject) ? item.subject[0] ?? null : item.subject, instructor: Array.isArray(item.instructor) ? item.instructor[0] ?? null : item.instructor }
}

function roleLabel(role: UserRole) {
  return role === 'admin' ? 'administrator' : role
}

function NameDetail({ label, value }: { label: string; value: string | null }) {
  return <div className="min-w-0"><dt className="text-[11px] font-extrabold uppercase tracking-wide text-slate-400">{label}</dt><dd className="mt-0.5 break-words font-semibold text-slate-700">{value ?? '—'}</dd></div>
}

function StudentApplicationDetails({ application, classes }: { application: RegistrationApplication; classes: ClassOption[] }) {
  const subjects = classes.filter((item) => application.selected_class_ids.includes(item.id))
  return <div className="mt-4 rounded-xl border border-blue-100 bg-blue-50/50 p-3"><dl className="grid gap-3 text-sm min-[420px]:grid-cols-2 lg:grid-cols-4"><NameDetail label="Student ID" value={application.student_id_number} /><NameDetail label="Class code" value={application.class_code} /><NameDetail label="Program / Year / Block" value={application.program && application.year_level && application.block ? `${application.program} · Year ${application.year_level} · ${application.block}` : null} /><NameDetail label="Academic term" value={application.academic_year && application.semester ? `${application.academic_year} · ${application.semester}` : null} /></dl><div className="mt-3"><p className="text-[11px] font-extrabold uppercase tracking-wide text-slate-400">Selected subjects</p>{subjects.length > 0 ? <ul className="mt-1 grid gap-1 text-sm text-slate-700 sm:grid-cols-2">{subjects.map((item) => <li key={item.id}><strong>{item.subject?.code}</strong> — {item.subject?.title}</li>)}</ul> : <p className="mt-1 text-sm text-slate-500">Legacy application or selected offerings are no longer active.</p>}</div></div>
}