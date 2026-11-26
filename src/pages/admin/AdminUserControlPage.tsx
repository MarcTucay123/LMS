import { useCallback, useEffect, useState, type FormEvent, type ReactNode } from 'react'
import { Clock3, EyeOff, LogIn, Save, ShieldAlert, Video } from 'lucide-react'
import { AdminPageHeader } from '../../components/AdminPageHeader'
import { ErrorState, LoadingState } from '../../components/ScreenState'
import { supabase } from '../../lib/supabase'
import type { SecuritySettings } from '../../types/database'

const defaults: SecuritySettings = {
  max_login_attempts: 5,
  lockout_minutes: 15,
  inactivity_timeout_minutes: 10,
  live_attendance_minimized_enabled: true,
  live_attendance_tab_hidden_enabled: true,
  live_attendance_window_blur_enabled: true,
  live_attendance_inactivity_enabled: true,
  live_attendance_inactivity_seconds: 30,
}

export function AdminUserControlPage() {
  const [settings, setSettings] = useState<SecuritySettings>(defaults)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    const { data, error: queryError } = await supabase.rpc('get_security_settings', {})
    if (queryError || !data) setError(queryError?.message ?? 'Unable to load user security settings.')
    else setSettings(data)
    setLoading(false)
  }, [])

  useEffect(() => {
    const timer = window.setTimeout(() => void load(), 0)
    return () => window.clearTimeout(timer)
  }, [load])

  const updateNumber = (field: keyof SecuritySettings, value: string) => {
    setSettings((current) => ({ ...current, [field]: Number(value) }))
    setMessage(null)
  }

  const updateBoolean = (field: keyof SecuritySettings, value: boolean) => {
    setSettings((current) => ({ ...current, [field]: value }))
    setMessage(null)
  }

  const save = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    setError(null)
    setMessage(null)
    const { data, error: updateError } = await supabase.rpc('admin_update_security_settings', settings)
    setSaving(false)
    if (updateError || !data) {
      setError(updateError?.message ?? 'Unable to save user security settings.')
      return
    }
    setSettings(data)
    setMessage('User security controls were saved and are now active.')
  }

  return (
    <div className="mx-auto max-w-5xl">
      <AdminPageHeader icon={ShieldAlert} eyebrow="Administration" title="User control" description="Configure login protection, account auto-logout, and live-call attendance behavior." />
      {loading && <LoadingState label="Loading user security controls…" />}
      {error && <div className="mb-5"><ErrorState message={error} onRetry={() => void load()} /></div>}
      {message && <div className="mb-5 rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-semibold text-emerald-800">{message}</div>}

      {!loading && (
        <form onSubmit={save} className="space-y-5">
          <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <div className="mb-5 flex items-start gap-3">
              <div className="grid size-11 shrink-0 place-items-center rounded-xl bg-red-50 text-red-700"><LogIn size={22} /></div>
              <div><h3 className="font-extrabold text-slate-900">Brute-force login protection</h3><p className="mt-1 text-sm text-slate-500">After the allowed failed attempts, that username or email is temporarily blocked from signing in.</p></div>
            </div>
            <div className="grid gap-4 md:grid-cols-2">
              <NumberField label="Maximum failed login attempts" description="Allowed range: 1 to 20 attempts." min={1} max={20} value={settings.max_login_attempts} onChange={(value) => updateNumber('max_login_attempts', value)} />
              <NumberField label="Lockout duration (minutes)" description="Allowed range: 10 to 30 minutes." min={10} max={30} value={settings.lockout_minutes} onChange={(value) => updateNumber('lockout_minutes', value)} />
            </div>
          </section>

          <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <div className="mb-5 flex items-start gap-3">
              <div className="grid size-11 shrink-0 place-items-center rounded-xl bg-amber-50 text-amber-700"><Clock3 size={22} /></div>
              <div><h3 className="font-extrabold text-slate-900">Unattended session auto-logout</h3><p className="mt-1 text-sm text-slate-500">Mouse, keyboard, touch, and scrolling activity keep the session active. The API also rejects a session after the configured inactivity period.</p></div>
            </div>
            <div className="max-w-md">
              <NumberField label="Auto-logout after inactivity (minutes)" description="Default is 10 minutes. Allowed range: 1 to 240 minutes." min={1} max={240} value={settings.inactivity_timeout_minutes} onChange={(value) => updateNumber('inactivity_timeout_minutes', value)} />
            </div>
          </section>

          <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <div className="mb-5 flex items-start gap-3">
              <div className="grid size-11 shrink-0 place-items-center rounded-xl bg-orange-50 text-orange-700"><Video size={22} /></div>
              <div><h3 className="font-extrabold text-slate-900">Live-call attendance</h3><p className="mt-1 text-sm text-slate-500">Choose which conditions change a joined student from green Active to orange Joined, inactive. These rules are separate from account auto-logout.</p></div>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <AttendanceRuleField icon={<Video size={18} />} label="Call minimized" description="Mark the student inactive while the live-call window is minimized." checked={settings.live_attendance_minimized_enabled} onChange={(value) => updateBoolean('live_attendance_minimized_enabled', value)} />
              <AttendanceRuleField icon={<EyeOff size={18} />} label="Browser tab hidden" description="Mark the student inactive after changing tabs or hiding the LMS tab." checked={settings.live_attendance_tab_hidden_enabled} onChange={(value) => updateBoolean('live_attendance_tab_hidden_enabled', value)} />
              <AttendanceRuleField icon={<EyeOff size={18} />} label="Browser window unfocused" description="Mark the student inactive when another application or browser window has focus." checked={settings.live_attendance_window_blur_enabled} onChange={(value) => updateBoolean('live_attendance_window_blur_enabled', value)} />
              <AttendanceRuleField icon={<Clock3 size={18} />} label="No live-call interaction" description="Mark the student inactive after the configured period without live-call activity." checked={settings.live_attendance_inactivity_enabled} onChange={(value) => updateBoolean('live_attendance_inactivity_enabled', value)} />
            </div>
            <div className="mt-4 max-w-md">
              <NumberField label="Live-call inactivity timeout (seconds)" description="Default is 30 seconds. Allowed range: 5 to 3600 seconds. This applies only when No live-call interaction is enabled." min={5} max={3600} value={settings.live_attendance_inactivity_seconds} onChange={(value) => updateNumber('live_attendance_inactivity_seconds', value)} disabled={!settings.live_attendance_inactivity_enabled} />
            </div>
            <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-4 text-xs leading-5 text-slate-600"><strong className="text-slate-800">Status behavior:</strong> A joined student is green when every enabled rule passes. The student becomes orange when any enabled rule fails. A student who has never joined remains red.</div>
          </section>

          <div className="flex justify-end"><button className="button-primary" disabled={saving}><Save size={17} /> {saving ? 'Saving…' : 'Save user controls'}</button></div>
        </form>
      )}
    </div>
  )
}

function NumberField({ label, description, min, max, value, onChange, disabled = false }: { label: string; description: string; min: number; max: number; value: number; onChange: (value: string) => void; disabled?: boolean }) {
  return <label className={`block rounded-xl border border-slate-200 bg-slate-50 p-4 ${disabled ? 'opacity-60' : ''}`}><span className="block text-sm font-extrabold text-slate-800">{label}</span><input className="admin-search-input mt-3 w-full bg-white" type="number" required min={min} max={max} step={1} value={value} onChange={(event) => onChange(event.target.value)} disabled={disabled} /><span className="mt-2 block text-xs leading-5 text-slate-500">{description}</span></label>
}

function AttendanceRuleField({ icon, label, description, checked, onChange }: { icon: ReactNode; label: string; description: string; checked: boolean; onChange: (value: boolean) => void }) {
  return <label className={`flex cursor-pointer items-start gap-3 rounded-xl border p-4 transition ${checked ? 'border-orange-300 bg-orange-50/70' : 'border-slate-200 bg-slate-50'}`}><input className="mt-1 size-4 accent-orange-600" type="checkbox" checked={checked} onChange={(event) => onChange(event.target.checked)} /><span className={`mt-0.5 shrink-0 ${checked ? 'text-orange-700' : 'text-slate-400'}`}>{icon}</span><span className="min-w-0"><strong className="block text-sm text-slate-800">{label}</strong><span className="mt-1 block text-xs leading-5 text-slate-500">{description}</span></span></label>
}