import { useEffect, useState, type FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { ArrowLeft, CircleCheckBig, CircleX, Database, Eye, EyeOff, LoaderCircle, LockKeyhole, Network, RefreshCw, Server, Unplug, UserRound } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'
import { useOneCampusSetup } from '../hooks/useOneCampusSetup'
import { supabase } from '../lib/supabase'

interface ConnectionStatus {
  configured: boolean
  connected: boolean
  host?: string
  port?: string
  database?: string
  username?: string
}

export function OneCampusSetupPage() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const { user, profile, loading: authLoading } = useAuth()
  const { refresh } = useOneCampusSetup()
  const [status, setStatus] = useState<ConnectionStatus | null>(null)
  const [checking, setChecking] = useState(true)
  const [host, setHost] = useState('192.168.109.211')
  const [port, setPort] = useState('3306')
  const [database, setDatabase] = useState('adfc_onecampus')
  const [username, setUsername] = useState('adfc_subsystems')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [disconnecting, setDisconnecting] = useState(false)
  const [confirmDisconnect, setConfirmDisconnect] = useState(false)
  const [continuing, setContinuing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [connectedDatabase, setConnectedDatabase] = useState<{
    host: string
    port: string
    database: string
    username: string
  } | null>(null)
  const disconnectRequested = searchParams.get('action') === 'disconnect' && profile?.role === 'admin'

  const checkStatus = async () => {
    setChecking(true)
    setError(null)
    const { data, error: statusError } = await supabase.oneCampusStatus()
    setStatus(data)
    setError(statusError?.message ?? null)
    setChecking(false)
  }

  useEffect(() => {
    let active = true
    void supabase.oneCampusStatus().then(({ data, error: statusError }) => {
      if (!active) return
      setStatus(data)
      setError(statusError?.message ?? null)
      setChecking(false)
    })
    return () => { active = false }
  }, [])

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    setSubmitting(true)
    const connection = { host: host.trim(), port: port.trim(), database: database.trim(), username: username.trim(), password }
    const { data, error: connectionError } = await supabase.connectOneCampus(connection)
    if (connectionError || !data || data.status !== 'connected') {
      setError(connectionError?.message ?? 'The server did not verify the OneCampus database connection.')
      setSubmitting(false)
      return
    }
    setSubmitting(false)
    setConnectedDatabase(data)
  }

  const handleContinue = async () => {
    setContinuing(true)
    await refresh()
    navigate('/login?portal=admin', { replace: true, state: { message: 'Setup completed. Sign in with your existing LMS account.' } })
  }

  const handleDisconnect = async () => {
    setDisconnecting(true)
    setError(null)
    const savedStatus = status
    const { data, error: disconnectError } = await supabase.disconnectOneCampus()
    if (disconnectError || !data?.disconnected) {
      if (disconnectError?.message === 'Authentication is required.') {
        setDisconnecting(false)
        setConfirmDisconnect(false)
        navigate('/login?portal=admin&returnTo=%2Fsetup%3Faction%3Ddisconnect', {
          state: { message: 'Sign in as an administrator to disconnect the saved OneCampus database.' },
        })
        return
      }
      setError(disconnectError?.message ?? 'The saved OneCampus connection could not be disconnected.')
      setDisconnecting(false)
      setConfirmDisconnect(false)
      return
    }
    if (savedStatus?.host) setHost(savedStatus.host)
    if (savedStatus?.port) setPort(savedStatus.port)
    if (savedStatus?.database) setDatabase(savedStatus.database)
    if (savedStatus?.username) setUsername(savedStatus.username)
    setPassword('')
    setShowPassword(false)
    setStatus({ configured: false, connected: false })
    setConfirmDisconnect(false)
    setDisconnecting(false)
    if (searchParams.get('action') === 'disconnect') navigate('/setup', { replace: true })
    await refresh()
  }

  const requestDisconnect = () => {
    setError(null)
    if (authLoading) return
    if (!user) {
      navigate('/login?portal=admin&returnTo=%2Fsetup%3Faction%3Ddisconnect', {
        state: { message: 'Sign in as an administrator to disconnect the saved OneCampus database.' },
      })
      return
    }
    if (profile?.role !== 'admin') {
      setError('Only an active administrator can disconnect the saved OneCampus database. Sign out and use an administrator account.')
      return
    }
    setConfirmDisconnect(true)
  }

  const closeDisconnectConfirmation = () => {
    setConfirmDisconnect(false)
    if (searchParams.get('action') === 'disconnect') navigate('/setup', { replace: true })
  }

  return (
    <main className="min-h-screen bg-auth-pattern px-3 py-6 sm:px-4 sm:py-12">
      <div className="mx-auto w-full max-w-xl rounded-2xl bg-white p-5 shadow-2xl shadow-slate-950/20 sm:p-8">
        <div className="mb-6">
          <div className="mb-4 flex items-center gap-3">
            <div className="grid size-14 place-items-center rounded-2xl bg-blue-50 text-brand-700"><Database size={30} /></div>
          </div>
          <p className="text-xs font-extrabold uppercase tracking-[0.18em] text-brand-700">ADFC OneCampus LMS</p>
          <h1 className="mt-1 text-2xl font-extrabold tracking-tight text-slate-900">OneCampus Database Setup</h1>
          <p className="mt-2 text-sm leading-6 text-slate-500">Configure the unified <strong>adfc_onecampus</strong> database or check whether the saved connection is currently reachable.</p>
        </div>

        {error && <div className="mb-5 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">{error}</div>}

        {checking ? (
          <div className="flex items-center justify-center gap-3 rounded-xl border border-slate-200 bg-slate-50 p-8 text-sm font-semibold text-slate-600" role="status"><LoaderCircle className="animate-spin" size={20} /> Checking saved connection…</div>
        ) : status?.configured ? (
          <section>
            <div className={`rounded-2xl border-2 p-5 ${status.connected ? 'border-emerald-300 bg-emerald-50' : 'border-red-300 bg-red-50'}`} role="status">
              <div className="flex items-start gap-4">
                <div className={`grid size-12 shrink-0 place-items-center rounded-full ${status.connected ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'}`}>
                  {status.connected ? <CircleCheckBig size={28} /> : <CircleX size={28} />}
                </div>
                <div>
                  <h2 className={`text-xl font-extrabold ${status.connected ? 'text-emerald-900' : 'text-red-900'}`}>{status.connected ? 'OneCampus is connected' : 'OneCampus is disconnected'}</h2>
                  <p className={`mt-1 text-sm leading-6 ${status.connected ? 'text-emerald-800' : 'text-red-800'}`}>{status.connected ? 'The saved database connection and required OneCampus tables were verified successfully.' : 'The setup is saved, but the database cannot currently be reached or verified. Check MariaDB, the network, firewall, credentials, and server IP.'}</p>
                </div>
              </div>
            </div>

            <dl className="mt-5 space-y-3 rounded-xl border border-slate-200 bg-white p-4 text-sm">
              <div className="flex justify-between gap-4"><dt className="font-semibold text-slate-500">Server</dt><dd className="break-all text-right font-bold text-slate-900">{status.host}:{status.port}</dd></div>
              <div className="flex justify-between gap-4"><dt className="font-semibold text-slate-500">Database</dt><dd className="break-all text-right font-bold text-slate-900">{status.database}</dd></div>
              <div className="flex justify-between gap-4"><dt className="font-semibold text-slate-500">Username</dt><dd className="break-all text-right font-bold text-slate-900">{status.username}</dd></div>
            </dl>

            <div className="mt-5 grid gap-3 sm:grid-cols-2">
              <button type="button" className="button-primary" onClick={() => void checkStatus()} disabled={checking}><RefreshCw size={17} /> Check connection again</button>
              <Link className="button-secondary" to="/login?portal=admin"><ArrowLeft size={17} /> Back to login</Link>
            </div>

            <div className="mt-5 rounded-xl border border-amber-200 bg-amber-50 p-4 text-xs leading-5 text-amber-900">
              <p className="font-extrabold">Disconnect or change the saved database</p>
              <p className="mt-1">Disconnecting deletes only the private saved connection file. It does not delete LMS or OneCampus data. After the first administrator exists, an active administrator session is required.</p>
              <button type="button" className="mt-3 inline-flex min-h-10 w-full items-center justify-center gap-2 rounded-lg border border-red-300 bg-white px-4 font-bold text-red-700 transition hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto" onClick={requestDisconnect} disabled={disconnecting || authLoading}>
                <Unplug size={17} /> {authLoading ? 'Checking access…' : 'Disconnect'}
              </button>
            </div>
          </section>
        ) : (
          <form className="space-y-4" onSubmit={handleSubmit} noValidate>
            <div className="grid gap-4 sm:grid-cols-[1fr_9rem]">
              <label className="field-label">Database host<span className="input-wrap"><Server size={18} /><input value={host} onChange={(event) => setHost(event.target.value)} inputMode="decimal" placeholder="127.0.0.1 or 192.168.109.211" required /></span></label>
              <label className="field-label">Port<span className="input-wrap"><Network size={18} /><input value={port} onChange={(event) => setPort(event.target.value)} inputMode="numeric" placeholder="3306" required /></span></label>
            </div>
            <div className="grid grid-cols-2 gap-2" aria-label="Database host shortcuts">
              <button type="button" className="button-secondary" onClick={() => setHost('127.0.0.1')}>This PC (home)</button>
              <button type="button" className="button-secondary" onClick={() => setHost('192.168.109.211')}>School server</button>
            </div>
            <p className="-mt-2 text-xs leading-5 text-slate-500">Use <strong>127.0.0.1</strong> only when XAMPP/MariaDB and <strong>adfc_onecampus</strong> are on this same computer. At school, use the OneCampus database PC&apos;s private LAN IP.</p>
            <label className="field-label">Database name<span className="input-wrap"><Database size={18} /><input value={database} onChange={(event) => setDatabase(event.target.value)} autoComplete="off" required /></span></label>
            <label className="field-label">Database username<span className="input-wrap"><UserRound size={18} /><input value={username} onChange={(event) => setUsername(event.target.value)} autoComplete="username" required /></span></label>
            <label className="field-label">Database password <span className="font-normal text-slate-400">(leave blank when no password is configured)</span>
              <span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="off" placeholder="Database password" /><button type="button" className="icon-button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? 'Hide password' : 'Show password'}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></span>
            </label>
            <p className="rounded-lg bg-slate-50 p-3 text-xs leading-5 text-slate-500">Setup only verifies and saves the OneCampus connection; it does not change any LMS account password.</p>
            <button className="button-primary w-full" disabled={submitting}>{submitting ? 'Verifying OneCampus…' : 'Verify OneCampus and finish setup'}</button>
          </form>
        )}
      </div>

      {connectedDatabase && (
        <div className="modal-backdrop" role="presentation">
          <section className="modal-card max-w-md text-center" role="dialog" aria-modal="true" aria-labelledby="connection-success-title" aria-describedby="connection-success-description">
            <div className="mx-auto grid size-16 place-items-center rounded-full bg-emerald-100 text-emerald-700"><CircleCheckBig size={36} aria-hidden="true" /></div>
            <h2 id="connection-success-title" className="mt-5 text-2xl font-extrabold text-slate-900">Successfully connected</h2>
            <p id="connection-success-description" className="mt-2 text-sm leading-6 text-slate-600">The LMS successfully verified and saved the OneCampus database connection.</p>
            <dl className="mt-5 rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-left text-sm">
              <div className="flex justify-between gap-4"><dt className="font-semibold text-slate-500">Server</dt><dd className="break-all text-right font-bold text-slate-900">{connectedDatabase.host}:{connectedDatabase.port}</dd></div>
              <div className="mt-2 flex justify-between gap-4"><dt className="font-semibold text-slate-500">Database</dt><dd className="break-all text-right font-bold text-slate-900">{connectedDatabase.database}</dd></div>
              <div className="mt-2 flex justify-between gap-4"><dt className="font-semibold text-slate-500">Username</dt><dd className="break-all text-right font-bold text-slate-900">{connectedDatabase.username}</dd></div>
            </dl>
            <button type="button" className="button-primary mt-6 w-full" onClick={() => void handleContinue()} disabled={continuing} autoFocus>{continuing ? 'Opening login…' : 'Continue to login'}</button>
          </section>
        </div>
      )}

      {(confirmDisconnect || disconnectRequested) && (
        <div className="modal-backdrop" role="presentation">
          <section className="modal-card max-w-md text-center" role="dialog" aria-modal="true" aria-labelledby="disconnect-title" aria-describedby="disconnect-description">
            <div className="mx-auto grid size-16 place-items-center rounded-full bg-red-100 text-red-700"><Unplug size={34} aria-hidden="true" /></div>
            <h2 id="disconnect-title" className="mt-5 text-2xl font-extrabold text-slate-900">Disconnect OneCampus?</h2>
            <p id="disconnect-description" className="mt-2 text-sm leading-6 text-slate-600">This deletes <code className="font-mono text-xs">api/onecampus.setup.php</code> from the LMS server and returns this page to the editable database setup form. No LMS or OneCampus records will be deleted.</p>
            <div className="mt-6 grid gap-3 sm:grid-cols-2">
              <button type="button" className="button-secondary" onClick={closeDisconnectConfirmation} disabled={disconnecting}>Cancel</button>
              <button type="button" className="inline-flex min-h-11 items-center justify-center gap-2 rounded-lg bg-red-600 px-4 font-bold text-white shadow-sm transition hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-60" onClick={() => void handleDisconnect()} disabled={disconnecting} autoFocus>
                <Unplug size={17} /> {disconnecting ? 'Disconnecting…' : 'Yes, disconnect'}
              </button>
            </div>
          </section>
        </div>
      )}
    </main>
  )
}