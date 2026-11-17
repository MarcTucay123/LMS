import { useCallback, useEffect, useMemo, useState } from 'react'
import { ClipboardList, Printer, Search } from 'lucide-react'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { EmptyState, ErrorState, LoadingState } from '../../components/ScreenState'
import { supabase } from '../../lib/supabase'
import type { Database } from '../../types/database'

type AuditLog = Database['public']['Tables']['audit_logs']['Row']

export function AdminAuditLogsPage() {
  const [logs, setLogs] = useState<AuditLog[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [query, setQuery] = useState('')
  const [moduleCode, setModuleCode] = useState('')

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    let request = supabase.from('audit_logs').select('*').order('created_at', { ascending: false }).limit(250)
    if (moduleCode) request = request.eq('module_code', moduleCode)
    const { data, error: queryError } = await request
    if (queryError) setError(queryError.message); else setLogs(data ?? [])
    setLoading(false)
  }, [moduleCode])

  useEffect(() => { const timer = window.setTimeout(() => void load(), 0); return () => window.clearTimeout(timer) }, [load])

  const modules = useMemo(() => Array.from(new Set(logs.map((log) => log.module_code))).sort(), [logs])
  const filteredLogs = useMemo(() => {
    const term = query.trim().toLowerCase()
    if (!term) return logs
    return logs.filter((log) => [log.actor_name, log.actor_role, log.action, log.record_type, log.record_label, log.description, log.ip_address].some((value) => value?.toLowerCase().includes(term)))
  }, [logs, query])

  return <div className="audit-print-report mx-auto max-w-[1500px]">
    <div className="print-report-heading hidden"><p>ADFC OneCampus Learning Management System</p><h1>Audit Logs</h1><span>Printed {new Date().toLocaleString()} · {filteredLogs.length} records</span></div>
    <AdminPageHeader icon={ClipboardList} eyebrow="Administration" title="Audit logs" description="Review administrative and learning-management activity recorded in the shared OneCampus audit trail." action={<button type="button" className="button-primary print-hidden" onClick={() => window.print()}><Printer size={17} /> Print audit logs</button>} />
    <div className="print-hidden mb-5 grid gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-[minmax(0,1fr)_240px_auto] md:items-end">
      <label className="relative block"><span className="mb-1.5 block text-xs font-extrabold uppercase tracking-wide text-slate-500">Search logs</span><Search className="pointer-events-none absolute bottom-3 left-3 text-slate-400" size={18} /><input className="admin-search-input pl-10" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Actor, action, record, description, or IP" /></label>
      <label className="block"><span className="mb-1.5 block text-xs font-extrabold uppercase tracking-wide text-slate-500">Module</span><select className="admin-select w-full" value={moduleCode} onChange={(event) => setModuleCode(event.target.value)}><option value="">All modules</option><option value="lms">LMS</option>{modules.filter((module) => module !== 'lms').map((module) => <option key={module} value={module}>{module}</option>)}</select></label>
      <p className="pb-2 text-sm font-semibold text-slate-500">{filteredLogs.length} records</p>
    </div>
    {loading && <LoadingState label="Loading audit logs…" />}
    {error && <ErrorState message={error} onRetry={() => void load()} />}
    {!loading && !error && filteredLogs.length === 0 && <EmptyState title="No matching audit logs" description="Try another search or module filter." />}
    {!loading && !error && filteredLogs.length > 0 && <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"><div className="overflow-x-auto"><table className="admin-table"><thead><tr><th>Date & time</th><th>Actor</th><th>Module</th><th>Action</th><th>Record</th><th>Description</th><th>IP address</th></tr></thead><tbody>{filteredLogs.map((log) => <tr key={log.id}><td data-label="Date & time" className="whitespace-nowrap">{new Date(log.created_at).toLocaleString()}</td><td data-label="Actor"><p className="font-bold text-slate-800">{log.actor_name ?? 'System'}</p><p className="text-xs text-slate-400">{log.actor_role ?? 'system'}</p></td><td data-label="Module"><span className="status-pill status-pill-active uppercase">{log.module_code}</span></td><td data-label="Action"><span className="font-semibold text-slate-700">{log.action}</span></td><td data-label="Record"><p>{log.record_type ?? '—'}</p><p className="text-xs text-slate-400">{log.record_label ?? ''}</p></td><td data-label="Description" className="max-w-md text-sm text-slate-600">{log.description ?? '—'}</td><td data-label="IP address" className="font-mono text-xs text-slate-500">{log.ip_address ?? '—'}</td></tr>)}</tbody></table></div></div>}
  </div>
}