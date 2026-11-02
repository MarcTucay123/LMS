import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { BadgeCheck, Eye, EyeOff, IdCard, LockKeyhole, Mail } from 'lucide-react'
import { supabase } from '../lib/supabase'

export function ActivatePage() {
  const navigate = useNavigate()
  const [onecampusId, setOnecampusId] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    if (!onecampusId.trim() || !email.trim() || !password || !confirmPassword) return setError('Complete all fields.')
    if (password.length < 8) return setError('Password must be at least 8 characters.')
    if (!/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) return setError('Password must contain uppercase, lowercase, and a number.')
    if (password !== confirmPassword) return setError('Passwords do not match.')

    setSubmitting(true)
    const { data, error: functionError } = await supabase.functions.invoke<{ message?: string }>('activate-account', {
      body: { onecampusId: onecampusId.trim(), email: email.trim().toLowerCase(), password },
    })
    setSubmitting(false)
    if (functionError) {
      let message = functionError.message
      if (functionError.context instanceof Response) {
        const body = await functionError.context.json().catch(() => null) as { error?: string } | null
        message = body?.error ?? message
      }
      setError(message)
      return
    }
    navigate('/login', { replace: true, state: { message: data?.message ?? 'Account activated. You can now sign in.' } })
  }

  return (
    <>
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-slate-900">Activate account</h2>
        <p className="mt-1 text-sm text-slate-500">We’ll match your details with OneCampus records. Your role is assigned by the school.</p>
      </div>
      {error && <div className="mb-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">{error}</div>}
      <form onSubmit={handleSubmit} className="space-y-4" noValidate>
        <label className="field-label">OneCampus ID<span className="input-wrap"><IdCard size={18} /><input value={onecampusId} onChange={(event) => setOnecampusId(event.target.value)} autoComplete="username" placeholder="e.g. OC-STU-003" /></span></label>
        <label className="field-label">School email<span className="input-wrap"><Mail size={18} /><input type="email" value={email} onChange={(event) => setEmail(event.target.value)} autoComplete="email" placeholder="you@adfc.edu.ph" /></span></label>
        <label className="field-label">Create password<span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="new-password" /><button type="button" className="icon-button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? 'Hide password' : 'Show password'}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></span></label>
        <label className="field-label">Confirm password<span className="input-wrap"><BadgeCheck size={18} /><input type={showPassword ? 'text' : 'password'} value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} autoComplete="new-password" /></span></label>
        <p className="text-xs text-slate-500">Use at least 8 characters with uppercase, lowercase, and a number.</p>
        <button className="button-primary w-full" disabled={submitting}>{submitting ? 'Activating…' : 'Activate account'}</button>
      </form>
      <button className="mt-5 w-full text-center text-sm font-semibold text-brand-700" onClick={() => navigate('/login')}>Back to sign in</button>
    </>
  )
}