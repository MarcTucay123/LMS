import { useCallback, useEffect, useState } from 'react'
import { CheckCircle2, DatabaseZap, RefreshCw, XCircle } from 'lucide-react'
import { Link } from 'react-router-dom'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { EmptyState, ErrorState, LoadingState } from '../../components/ScreenState'
import { supabase } from '../../lib/supabase'
import type { Database, Json } from '../../types/database'

type SyncLog = Database['public']['Tables']['sync_logs']['Row']

export function AdminSyncPage() {
  const [logs, setLogs] = useState<SyncLog[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [connection, setConnection] = useState<{ connected: boolean; host?: string; port?: string; database?: string } | null>(null)

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    const [{ data, error: queryError }, { data: status }] = await Promise.all([
      supabase.from('sync_logs').select('*').order('started_at', { ascending: false }).limit(50),
      supabase.oneCampusStatus(),
    ])
    if (queryError) setError(queryError.message)
    else setLogs(data ?? [])
    setConnection(status ? { connected: status.connected, host: status.host, port: status.port, database: status.database } : null)
    setLoading(false)
  }, [])

  useEffect(() => {
    let active = true
    void Promise.all([
      supabase.from('sync_logs').select('*').order('started_at', { ascending: false }).limit(50),
      supabase.oneCampusStatus(),
    ]).then(([{ data, error: queryError }, { data: status }]) => {
      if (!active) return
      if (queryError) setError(queryError.message)
      else setLogs(data ?? [])
      setConnection(status ? { connected: status.connected, host: status.host, port: status.port, database: status.database } : null)
      setLoading(false)
    })
    return () => { active = false }
  }, [])

  return (
    <div className="mx-auto max-w-[1500px]">
      <AdminPageHeader icon={DatabaseZap} eyebrow="OneCampus integration" title="Direct database connection" description="The LMS reads identity, subjects, classes, enrollments, and LMS content directly from the unified adfc_onecampus database." />
      <div className={`mb-6 rounded-2xl border-2 p-5 text-sm ${connection?.connected ? 'border-emerald-300 bg-emerald-50 text-emerald-900' : 'border-red-300 bg-red-50 text-red-900'}`}>
        <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
          <div>
            <p className="flex items-center gap-2 font-extrabold">{connection?.connected ? <CheckCircle2 size={18} /> : <XCircle size={18} />}{connection?.connected ? 'OneCampus database connected' : 'OneCampus database disconnected'}</p>
            <p className={`mt-1 ${connection?.connected ? 'text-emerald-700' : 'text-red-700'}`}>{connection?.connected ? `${connection.database} at ${connection.host}:${connection.port} is ready for direct LMS access.` : 'LMS access is unavailable until the saved OneCampus connection can be verified.'}</p>
          </div>
          <Link className="button-secondary shrink-0" to="/setup">Database setup/status</Link>
        </div>
      </div>
      <div className="mb-6 rounded-2xl border border-brand-700 bg-blue-50 p-5 text-sm text-blue-900"><p className="font-bold">No separate LMS database is required</p><p className="mt-1 text-blue-700">This deployment uses <strong>adfc_onecampus</strong> directly. On the LMS server, start Apache only; MySQL runs on the OneCampus database server.</p></div>
      {loading && <LoadingState label="Loading synchronization history…" />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {!loading && !error && logs.length === 0 && <EmptyState title="No synchronization required" description="Shared records are read directly from adfc_onecampus." />}
      {!loading && logs.length > 0 && <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"><div className="overflow-x-auto"><table className="admin-table"><thead><tr><th>Started</th><th>Source</th><th>Status</th><th>Records</th><th>Message</th></tr></thead><tbody>{logs.map((log) => <tr key={log.id}><td data-label="Started" className="whitespace-nowrap">{new Date(log.started_at).toLocaleString()}</td><td data-label="Source"><span className="font-semibold">{sourceLabel(log.source)}</span></td><td data-label="Status"><span className={`inline-flex items-center gap-1.5 font-bold ${log.status === 'success' ? 'text-emerald-700' : log.status === 'failed' ? 'text-red-700' : 'text-amber-700'}`}>{log.status === 'success' ? <CheckCircle2 size={16} /> : log.status === 'failed' ? <XCircle size={16} /> : <RefreshCw size={16} />}{log.status}</span></td><td data-label="Records"><code className="break-words text-xs text-slate-500">{formatRecords(log.records)}</code></td><td data-label="Message" className="max-w-md text-sm text-slate-500">{log.message ?? '—'}</td></tr>)}</tbody></table></div></div>}
    </div>
  )
}

function formatRecords(records: Json) {
  if (!records || typeof records !== 'object' || Array.isArray(records)) return '—'
  return Object.entries(records).map(([key, value]) => `${key}: ${String(value)}`).join(', ')
}

function sourceLabel(source?: string) {
  if (source === 'onecampus_database') return 'OneCampus database'
  if (source === 'onecampus_api') return 'OneCampus API'
  if (source === 'mock') return 'Mock fixtures'
  return 'Unknown source'
}