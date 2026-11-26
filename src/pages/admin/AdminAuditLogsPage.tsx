import { useCallback, useEffect, useMemo, useState } from 'react'
import { ClipboardList, Download, Eye, Printer, Search, X } from 'lucide-react'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { EmptyState, ErrorState, LoadingState } from '../../components/ScreenState'
import { supabase } from '../../lib/supabase'
import type { Database } from '../../types/database'

type AuditLog = Database['public']['Tables']['audit_logs']['Row']

function csvCell(value: string | number | null | undefined) {
  let text = value == null ? '' : String(value)
  if (/^[=+\-@]/.test(text)) text = `'${text}`
  return `"${text.replaceAll('"', '""')}"`
}

export function AdminAuditLogsPage() {
  const [logs, setLogs] = useState<AuditLog[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [query, setQuery] = useState('')
  const [moduleCode, setModuleCode] = useState('')
  const [previewOpen, setPreviewOpen] = useState(false)

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

  const downloadLogs = () => {
    const rows = [
      ['Date & time', 'Actor', 'Role', 'Module', 'Action', 'Record type', 'Record label', 'Description', 'IP address'],
      ...filteredLogs.map((log) => [
        new Date(log.created_at).toLocaleString(),
        log.actor_name ?? 'System',
        log.actor_role ?? 'system',
        log.module_code,
        log.action,
        log.record_type ?? '',
        log.record_label ?? '',
        log.description ?? '',
        log.ip_address ?? '',
      ]),
    ]
    const csv = `\uFEFF${rows.map((row) => row.map(csvCell).join(',')).join('\r\n')}`
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }))
    const anchor = document.createElement('a')
    const timestamp = new Date().toISOString().replaceAll(':', '-').replace(/\.\d{3}Z$/, 'Z')
    anchor.href = url
    anchor.download = `audit-logs-${timestamp}.csv`
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
    URL.revokeObjectURL(url)
  }

  return <div className="audit-print-report mx-auto max-w-[1500px]">
    <div className="print-report-heading hidden"><p>ADFC OneCampus Learning Management System</p><h1>Audit Logs</h1><span>Printed {new Date().toLocaleString()} · {filteredLogs.length} records</span></div>
    <AdminPageHeader icon={ClipboardList} eyebrow="Administration" title="Audit logs" description="Review administrative and learning-management activity recorded in the shared OneCampus audit trail." action={<div className="print-hidden flex w-full flex-col gap-2 sm:w-auto sm:flex-row"><button type="button" className="button-secondary w-full sm:w-auto" onClick={() => setPreviewOpen(true)} disabled={loading || Boolean(error) || filteredLogs.length === 0}><Eye size={17} /> Preview audit logs</button><button type="button" className="button-primary w-full sm:w-auto" onClick={() => window.print()}><Printer size={17} /> Print audit logs</button></div>} />
    <div className="print-hidden mb-5 grid gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-[minmax(0,1fr)_240px_auto] md:items-end">
      <label className="relative block"><span className="mb-1.5 block text-xs font-extrabold uppercase tracking-wide text-slate-500">Search logs</span><Search className="pointer-events-none absolute bottom-3 left-3 text-slate-400" size={18} /><input className="admin-search-input pl-10" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Actor, action, record, description, or IP" /></label>
      <label className="block"><span className="mb-1.5 block text-xs font-extrabold uppercase tracking-wide text-slate-500">Module</span><select className="admin-select w-full" value={moduleCode} onChange={(event) => setModuleCode(event.target.value)}><option value="">All modules</option><option value="lms">LMS</option>{modules.filter((module) => module !== 'lms').map((module) => <option key={module} value={module}>{module}</option>)}</select></label>
      <p className="pb-2 text-sm font-semibold text-slate-500">{filteredLogs.length} records</p>
    </div>
    {loading && <LoadingState label="Loading audit logs…" />}
    {error && <ErrorState message={error} onRetry={() => void load()} />}
    {!loading && !error && filteredLogs.length === 0 && <EmptyState title="No matching audit logs" description="Try another search or module filter." />}
    {!loading && !error && filteredLogs.length > 0 && <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"><div className="overflow-x-auto"><table className="admin-table"><thead><tr><th>Date & time</th><th>Actor</th><th>Module</th><th>Action</th><th>Record</th><th>Description</th><th>IP address</th></tr></thead><tbody>{filteredLogs.map((log) => <tr key={log.id}><td data-label="Date & time" className="whitespace-nowrap">{new Date(log.created_at).toLocaleString()}</td><td data-label="Actor"><p className="font-bold text-slate-800">{log.actor_name ?? 'System'}</p><p className="text-xs text-slate-400">{log.actor_role ?? 'system'}</p></td><td data-label="Module"><span className="status-pill status-pill-active uppercase">{log.module_code}</span></td><td data-label="Action"><span className="font-semibold text-slate-700">{log.action}</span></td><td data-label="Record"><p>{log.record_type ?? '—'}</p><p className="text-xs text-slate-400">{log.record_label ?? ''}</p></td><td data-label="Description" className="max-w-md text-sm text-slate-600">{log.description ?? '—'}</td><td data-label="IP address" className="font-mono text-xs text-slate-500">{log.ip_address ?? '—'}</td></tr>)}</tbody></table></div></div>}
    {previewOpen && <AuditLogPreview logs={filteredLogs} query={query} moduleCode={moduleCode} onClose={() => setPreviewOpen(false)} onDownload={downloadLogs} />}
  </div>
}

function AuditLogPreview({ logs, query, moduleCode, onClose, onDownload }: { logs: AuditLog[]; query: string; moduleCode: string; onClose: () => void; onDownload: () => void }) {
  useEffect(() => {
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const closeOnEscape = (event: KeyboardEvent) => { if (event.key === 'Escape') onClose() }
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', closeOnEscape)
    }
  }, [onClose])

  const filterSummary = [
    query.trim() ? `Search: “${query.trim()}”` : null,
    moduleCode ? `Module: ${moduleCode.toUpperCase()}` : 'All modules',
  ].filter(Boolean).join(' · ')

  return <div className="modal-backdrop print-hidden" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
    <section className="modal-card flex max-w-7xl flex-col overflow-hidden p-0 sm:p-0" role="dialog" aria-modal="true" aria-labelledby="audit-preview-title">
      <header className="flex items-start justify-between gap-3 border-b border-slate-200 px-4 py-4 sm:px-6">
        <div className="min-w-0">
          <p className="text-xs font-extrabold uppercase tracking-[0.14em] text-brand-700">Audit log preview</p>
          <h2 id="audit-preview-title" className="mt-1 text-lg font-black text-slate-900 sm:text-xl">Filtered audit records</h2>
          <p className="mt-1 text-xs font-semibold text-slate-500">{logs.length} {logs.length === 1 ? 'record' : 'records'} · {filterSummary}</p>
        </div>
        <button type="button" className="icon-action shrink-0" onClick={onClose} aria-label="Close audit log preview"><X size={19} /></button>
      </header>

      <div className="min-h-0 flex-1 overflow-auto bg-slate-100 p-3 sm:p-4">
        <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
          <div className="overflow-x-auto">
            <table className="admin-table">
              <thead><tr><th>Date & time</th><th>Actor</th><th>Role</th><th>Module</th><th>Action</th><th>Record</th><th>Description</th><th>IP address</th></tr></thead>
              <tbody>{logs.map((log) => <tr key={log.id}>
                <td data-label="Date & time" className="whitespace-nowrap">{new Date(log.created_at).toLocaleString()}</td>
                <td data-label="Actor" className="font-bold text-slate-800">{log.actor_name ?? 'System'}</td>
                <td data-label="Role" className="capitalize">{log.actor_role ?? 'system'}</td>
                <td data-label="Module"><span className="status-pill status-pill-active uppercase">{log.module_code}</span></td>
                <td data-label="Action" className="font-semibold">{log.action}</td>
                <td data-label="Record"><p>{log.record_type ?? '—'}</p><p className="text-xs text-slate-400">{log.record_label ?? ''}</p></td>
                <td data-label="Description" className="min-w-72 max-w-lg text-sm text-slate-600">{log.description ?? '—'}</td>
                <td data-label="IP address" className="whitespace-nowrap font-mono text-xs text-slate-500">{log.ip_address ?? '—'}</td>
              </tr>)}</tbody>
            </table>
          </div>
        </div>
      </div>

      <footer className="flex flex-col-reverse gap-2 border-t border-slate-200 px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-6">
        <p className="flex items-center gap-2 text-xs font-semibold text-slate-500"><Eye size={15} /> Preview reflects the current search and module filters</p>
        <div className="flex gap-2">
          <button type="button" className="button-secondary flex-1 sm:flex-none" onClick={onClose}>Close</button>
          <button type="button" className="button-primary flex-1 sm:flex-none" onClick={onDownload}><Download size={17} /> Download CSV</button>
        </div>
      </footer>
    </section>
  </div>
}