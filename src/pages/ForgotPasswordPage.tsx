import { useState, type FormEvent } from 'react'
import { ArrowLeft, KeyRound, Mail } from 'lucide-react'
import { Link, useSearchParams } from 'react-router-dom'
import type { LoginPortal } from '../lib/auth'
import { supabase } from '../lib/supabase'

function getPortal(value: string | null): LoginPortal {
  return value === 'instructor' || value === 'admin' ? value : 'student'
}

export function ForgotPasswordPage() {
  const [searchParams] = useSearchParams()
  const portal = getPortal(searchParams.get('portal'))
  const [email, setEmail] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [sent, setSent] = useState(false)

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    const normalizedEmail = email.trim().toLowerCase()
    if (!/^[^\s@]+@[^\s@]+[.][^\s@]+$/.test(normalizedEmail)) {
      setError('Enter a valid email address.')
      return
    }

    setSubmitting(true)
    const redirectTo = new URL('/reset-password', window.location.origin)
    redirectTo.searchParams.set('portal', portal)
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(normalizedEmail, { redirectTo: redirectTo.toString() })
    setSubmitting(false)
    if (resetError) {
      setError(resetError.message)
      return
    }
    setSent(true)
  }

  return (
    <>
      <Link className="mb-5 inline-flex items-center gap-2 text-sm font-bold text-brand-700 hover:text-brand-800" to={`/login?portal=${portal}`}><ArrowLeft size={17} /> Back to sign in</Link>
      <div className="mb-6 flex items-start gap-3">
        <div className="grid size-11 shrink-0 place-items-center rounded-xl bg-blue-50 text-brand-700"><KeyRound size={22} aria-hidden="true" /></div>
        <div><h2 className="text-2xl font-extrabold tracking-tight text-slate-900">Forgot password?</h2><p className="mt-1 text-sm leading-5 text-slate-500">Enter your registered email address and we&apos;ll send you a secure password-reset link.</p></div>
      </div>

      {sent ? (
        <div className="rounded-lg border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800"><p className="font-bold">Check your email</p><p className="mt-1">If an account exists for that address, a password-reset link has been sent. Check your spam folder if it does not arrive.</p></div>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-4" noValidate>
          {error && <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">{error}</div>}
          <label className="field-label">Email address<span className="input-wrap"><Mail size={18} /><input type="email" autoComplete="email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="Enter your registered email" /></span></label>
          <button className="button-primary w-full" disabled={submitting}>{submitting ? 'Sending reset link…' : 'Send reset link'}</button>
        </form>
      )}
    </>
  )
}