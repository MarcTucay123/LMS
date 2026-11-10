import { useCallback, useEffect, useState } from 'react'
import { CheckCircle2, DatabaseZap, RefreshCw, XCircle } from 'lucide-react'
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

  const load = useCallback(async () => {
    setLoading(true); setError(null)
    const { data, error: queryError } = await supabase.from('sync_logs').select('*').order('started_at', { ascending: false }).limit(50)
    if (queryError) setError(queryError.message)
    else setLogs(data ?? [])
    setLoading(false)
  }, [])

  useEffect(() => {
    let active = true
    void supabase.from('sync_logs').select('*').order('started_at', { ascending: false }).limit(50).then(({ data, error: queryError }) => {
      if (!active) return
      if (queryError) setError(queryError.message)
      else setLogs(data ?? [])
      setLoading(false)
    })
    return () => { active = false }
  }, [])

  const runSync = async () => {
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
    setMessage(`${data?.message ?? 'Synchronization completed.'} Source: ${data?.source === 'mock' ? 'mock fixtures' : 'OneCampus API'}.`)
    await load()
  }

  return (
    <div className="mx-auto max-w-[1500px]">
      <AdminPageHeader icon={DatabaseZap} eyebrow="OneCampus integration" title="Synchronization" description="Import read-only identity, course catalog, class scheduling, and enrollment projections from the systems that own those records." action={<button className="button-primary" onClick={() => void runSync()} disabled={syncing}><RefreshCw className={syncing ? 'animate-spin' : ''} size={18} /> {syncing ? 'Synchronizing…' : 'Sync now'}</button>} />
      <div className="mb-6 rounded-2xl border-2 border-blue-400 bg-blue-50 p-5 text-sm text-blue-900"><p className="font-bold">Synchronization is the only academic master-data write path</p><p className="mt-1 text-blue-700">When <code>ONECAMPUS_API_URL</code> is empty, the PHP API imports the repository fixtures. Configure the real shared-system endpoint before production use.</p></div>
      {message && <div className="mb-4 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm font-semibold text-emerald-800">{message}</div>}
      {loading && <LoadingState label="Loading synchronization history…" />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {!loading && !error && logs.length === 0 && <EmptyState title="No sync history" description="Select Sync now to import OneCampus data." />}
      {!loading && logs.length > 0 && <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"><div className="overflow-x-auto"><table className="admin-table"><thead><tr><th>Started</th><th>Source</th><th>Status</th><th>Records</th><th>Message</th></tr></thead><tbody>{logs.map((log) => <tr key={log.id}><td data-label="Started" className="whitespace-nowrap">{new Date(log.started_at).toLocaleString()}</td><td data-label="Source"><span className="font-semibold">{log.source === 'mock' ? 'Mock fixtures' : 'OneCampus API'}</span></td><td data-label="Status"><span className={`inline-flex items-center gap-1.5 font-bold ${log.status === 'success' ? 'text-emerald-700' : log.status === 'failed' ? 'text-red-700' : 'text-amber-700'}`}>{log.status === 'success' ? <CheckCircle2 size={16} /> : log.status === 'failed' ? <XCircle size={16} /> : <RefreshCw size={16} />}{log.status}</span></td><td data-label="Records"><code className="break-words text-xs text-slate-500">{formatRecords(log.records)}</code></td><td data-label="Message" className="max-w-md text-sm text-slate-500">{log.message ?? '—'}</td></tr>)}</tbody></table></div></div>}
    </div>
  )
}

function formatRecords(records: Json) {
  if (!records || typeof records !== 'object' || Array.isArray(records)) return '—'
  return Object.entries(records).map(([key, value]) => `${key}: ${String(value)}`).join(', ')
}