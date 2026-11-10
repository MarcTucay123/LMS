import { useCallback, useEffect, useState } from 'react'
import { BookCopy, DatabaseZap, LockKeyhole } from 'lucide-react'
import { Link } from 'react-router-dom'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { EmptyState, ErrorState, LoadingState } from '../../components/ScreenState'
import { supabase } from '../../lib/supabase'

interface ManagedClass {
  id: string
  onecampus_class_id: string | null
  source_system: string
  synced_at: string | null
  section: string
  school_year: string
  semester: string
  status: string
  subject: { code: string; title: string } | { code: string; title: string }[] | null
  instructor: { full_name: string } | { full_name: string }[] | null
}

export function AdminClassesPage() {
  const [classes, setClasses] = useState<ManagedClass[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    const { data, error: queryError } = await supabase
      .from('classes')
      .select('id, onecampus_class_id, source_system, synced_at, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)')
      .order('created_at', { ascending: false })
    if (queryError) setError(queryError.message)
    else setClasses((data ?? []) as unknown as ManagedClass[])
    setLoading(false)
  }, [])

  useEffect(() => {
    let active = true
    void supabase
      .from('classes')
      .select('id, onecampus_class_id, source_system, synced_at, section, school_year, semester, status, subject:subjects(code, title), instructor:profiles!classes_instructor_id_fkey(full_name)')
      .order('created_at', { ascending: false })
      .then(({ data, error: queryError }) => {
        if (!active) return
        if (queryError) setError(queryError.message)
        else setClasses((data ?? []) as unknown as ManagedClass[])
        setLoading(false)
      })
    return () => { active = false }
  }, [])

  return (
    <div className="mx-auto max-w-[1500px]">
      <AdminPageHeader
        icon={BookCopy}
        eyebrow="Academic integration"
        title="Synchronized class offerings"
        description="Class offerings, subjects, instructor assignments, sections, and academic terms are owned by OneCampus and Class Scheduling. The LMS displays a read-only synchronized copy."
        action={<Link className="button-primary" to="/admin/sync"><DatabaseZap size={18} /> Synchronization</Link>}
      />

      <div className="mb-6 flex items-start gap-3 rounded-2xl border-2 border-blue-400 bg-blue-50 p-4 text-sm text-blue-950 shadow-sm shadow-blue-900/10 sm:p-5">
        <LockKeyhole className="mt-0.5 shrink-0 text-brand-700" size={20} />
        <div>
          <p className="font-extrabold">Academic master data is read-only in the LMS</p>
          <p className="mt-1 text-blue-800">Create or change subjects, instructors, class offerings, sections, and schedules in their owning subsystem, then run synchronization. This prevents duplicate or conflicting records.</p>
        </div>
      </div>

      {loading && <LoadingState label="Loading synchronized class offerings…" />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {!loading && !error && classes.length === 0 && <EmptyState title="No synchronized class offerings" description="Run OneCampus synchronization after the Enrollment and Class Scheduling records are available." />}
      {!loading && classes.length > 0 && (
        <div className="grid gap-4 lg:grid-cols-2 2xl:grid-cols-3">
          {classes.map((item) => {
            const subject = Array.isArray(item.subject) ? item.subject[0] ?? null : item.subject
            const instructor = Array.isArray(item.instructor) ? item.instructor[0] ?? null : item.instructor
            return (
              <article className="card p-4 sm:p-5" key={item.id}>
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="text-xs font-extrabold uppercase tracking-wide text-brand-700">{subject?.code ?? 'Subject'}</p>
                    <h3 className="mt-1 break-words font-extrabold text-slate-900">{subject?.title ?? 'Unavailable subject'}</h3>
                  </div>
                  <span className={`status-pill shrink-0 ${item.status === 'active' ? 'status-pill-active' : 'status-pill-inactive'}`}>{item.status}</span>
                </div>
                <dl className="mt-5 grid grid-cols-1 gap-3 text-sm min-[400px]:grid-cols-2">
                  <DataItem label="Section" value={item.section} />
                  <DataItem label="School year" value={item.school_year} />
                  <DataItem label="Semester" value={item.semester} />
                  <DataItem label="Instructor" value={instructor?.full_name ?? 'Unassigned'} />
                </dl>
                <div className="mt-5 rounded-xl bg-blue-50 p-3 text-xs text-blue-800">
                  <p className="font-extrabold uppercase tracking-wide">Source: {formatSource(item.source_system)}</p>
                  <p className="mt-1 break-all">External ID: {item.onecampus_class_id ?? 'Not linked'}</p>
                  <p className="mt-1">Last synchronized: {item.synced_at ? new Date(item.synced_at).toLocaleString() : 'Not recorded'}</p>
                </div>
              </article>
            )
          })}
        </div>
      )}
    </div>
  )
}

function DataItem({ label, value }: { label: string; value: string }) {
  return <div className="min-w-0"><dt className="text-xs text-slate-400">{label}</dt><dd className="break-words font-semibold text-slate-800">{value}</dd></div>
}

function formatSource(source: string) {
  return source.replaceAll('_', ' ')
}