import { useEffect, useState, type FormEvent } from 'react'
import { ArrowLeft, Eye, EyeOff, KeyRound, LockKeyhole } from 'lucide-react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import type { LoginPortal } from '../lib/auth'
import { supabase } from '../lib/supabase'

function getPortal(value: string | null): LoginPortal {
  return value === 'instructor' || value === 'admin' ? value : 'student'
}

export function ResetPasswordPage() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const portal = getPortal(searchParams.get('portal'))
  const hasResetToken = Boolean(searchParams.get('token'))
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [checkingSession, setCheckingSession] = useState(!hasResetToken)
  const [hasRecoverySession, setHasRecoverySession] = useState(hasResetToken)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (hasResetToken) return
    let active = true
    const checkSession = async () => {
      const { data, error: sessionError } = await supabase.auth.getSession()
      if (!active) return
      setHasRecoverySession(Boolean(data.session) && !sessionError)
      setCheckingSession(false)
    }
    void checkSession()
    const { data: listener } = supabase.auth.onAuthStateChange((event, session) => {
      if (!active || (event !== 'PASSWORD_RECOVERY' && event !== 'SIGNED_IN')) return
      setHasRecoverySession(Boolean(session))
      setCheckingSession(false)
    })
    return () => {
      active = false
      listener.subscription.unsubscribe()
    }
  }, [hasResetToken])

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) {
      setError('Password must be at least 8 characters and contain uppercase, lowercase, and a number.')
      return
    }
    if (password !== confirmPassword) {
      setError('Passwords do not match.')
      return
    }

    setSubmitting(true)
    const { error: updateError } = await supabase.auth.updateUser({ password })
    if (updateError) {
      setSubmitting(false)
      setError(updateError.message)
      return
    }
    await supabase.auth.signOut()
    navigate(`/login?portal=${portal}`, { replace: true, state: { message: 'Your password has been reset. Sign in with your new password.' } })
  }

  return (
    <>
      <Link className="mb-5 inline-flex items-center gap-2 text-sm font-bold text-brand-700 hover:text-brand-800" to={`/login?portal=${portal}`}><ArrowLeft size={17} /> Back to sign in</Link>
      <div className="mb-6 flex items-start gap-3">
        <div className="grid size-11 shrink-0 place-items-center rounded-xl bg-blue-50 text-brand-700"><KeyRound size={22} aria-hidden="true" /></div>
        <div><h2 className="text-2xl font-extrabold tracking-tight text-slate-900">Reset your password</h2><p className="mt-1 text-sm leading-5 text-slate-500">Choose a new password for your ADFC OneCampus account.</p></div>
      </div>

      {checkingSession ? (
        <p className="text-sm text-slate-500">Verifying your reset link…</p>
      ) : !hasRecoverySession ? (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-800"><p className="font-bold">This reset link is invalid or has expired.</p><p className="mt-1">Request a new password-reset email to continue.</p><Link className="mt-3 inline-flex font-bold text-brand-700 hover:text-brand-800" to={`/forgot-password?portal=${portal}`}>Request a new link</Link></div>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-4" noValidate>
          {error && <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">{error}</div>}
          <label className="field-label">New password<span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} autoComplete="new-password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Enter a new password" /><button type="button" className="icon-button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? 'Hide password' : 'Show password'}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></span></label>
          <label className="field-label">Confirm new password<span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} autoComplete="new-password" value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} placeholder="Confirm your new password" /></span></label>
          <p className="text-xs text-slate-500">Use at least 8 characters with uppercase, lowercase, and a number.</p>
          <button className="button-primary w-full" disabled={submitting}>{submitting ? 'Updating password…' : 'Reset password'}</button>
        </form>
      )}
    </>
  )
}