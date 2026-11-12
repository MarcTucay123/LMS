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
  const [syncing, setSyncing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
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

  const runSync = async () => {
    if (!connection?.connected) {
      setError('OneCampus is disconnected. Check the saved database connection before synchronizing.')
      return
    }
    setSyncing(true); setError(null); setMessage(null)
    const { data, error: functionError } = await supabase.functions.invoke<{ message?: string; counts?: Json; source?: string }>('sync-onecampus', { body: {} })
    setSyncing(false)
    if (functionError) {
      let detail = functionError.message
      if (functionError.context instanceof Response) {
        const body = await functionError.context.json().catch(() => null) as { error?: string } | null
        detail = body?.error ?? detail
      }
      setError(detail)
      await load()
      return
    }
    setMessage(`${data?.message ?? 'Synchronization completed.'} Source: ${sourceLabel(data?.source)}.`)
    await load()
  }

  return (
    <div className="mx-auto max-w-[1500px]">
      <AdminPageHeader icon={DatabaseZap} eyebrow="OneCampus integration" title="Synchronization" description="Import read-only identity, course catalog, class scheduling, and enrollment projections from the systems that own those records." action={<button className="button-primary" onClick={() => void runSync()} disabled={syncing || !connection?.connected}><RefreshCw className={syncing ? 'animate-spin' : ''} size={18} /> {syncing ? 'Synchronizing…' : 'Sync now'}</button>} />
      <div className={`mb-6 rounded-2xl border-2 p-5 text-sm ${connection?.connected ? 'border-emerald-300 bg-emerald-50 text-emerald-900' : 'border-red-300 bg-red-50 text-red-900'}`}>
        <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
          <div>
            <p className="flex items-center gap-2 font-extrabold">{connection?.connected ? <CheckCircle2 size={18} /> : <XCircle size={18} />}{connection?.connected ? 'OneCampus database connected' : 'OneCampus database disconnected'}</p>
            <p className={`mt-1 ${connection?.connected ? 'text-emerald-700' : 'text-red-700'}`}>{connection?.connected ? `${connection.database} at ${connection.host}:${connection.port} is ready to synchronize.` : 'Sync is disabled until the saved OneCampus connection can be verified.'}</p>
          </div>
          <Link className="button-secondary shrink-0" to="/setup">Database setup/status</Link>
        </div>
      </div>
      <div className="mb-6 rounded-2xl border-2 border-blue-400 bg-blue-50 p-5 text-sm text-blue-900"><p className="font-bold">Synchronization is the only academic master-data write path</p><p className="mt-1 text-blue-700">Sync reads the shared <strong>adfc_onecampus</strong> database and updates the read-only LMS projections in <strong>lms_db</strong>: profiles, subjects, classes, and enrollments. It does not modify the OneCampus source tables.</p></div>
      {message && <div className="mb-4 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm font-semibold text-emerald-800">{message}</div>}
      {loading && <LoadingState label="Loading synchronization history…" />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {!loading && !error && logs.length === 0 && <EmptyState title="No sync history" description="Select Sync now to import OneCampus data." />}
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