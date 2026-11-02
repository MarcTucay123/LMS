import { useState, type FormEvent } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  BookOpenCheck,
  Eye,
  EyeOff,
  GraduationCap,
  LockKeyhole,
  Mail,
  ShieldCheck,
  UserRound,
} from 'lucide-react'
import { pendingRoleCheckKey, roleLabels, type LoginPortal } from '../lib/auth'
import { supabase } from '../lib/supabase'

const portalDetails: Record<LoginPortal, { title: string; description: string; icon: typeof UserRound }> = {
  student: {
    title: 'Student sign in',
    description: 'Access your classes, learning materials, activities, and progress.',
    icon: GraduationCap,
  },
  instructor: {
    title: 'Instructor sign in',
    description: 'Manage your assigned classes and learning activities.',
    icon: BookOpenCheck,
  },
  admin: {
    title: 'Administrator sign in',
    description: 'Secure access for authorized ADFC system administrators.',
    icon: ShieldCheck,
  },
}

export function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const [portal, setPortal] = useState<LoginPortal>('student')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const message = (location.state as { message?: string } | null)?.message
  const details = portalDetails[portal]
  const PortalIcon = details.icon

  const selectPortal = (nextPortal: LoginPortal) => {
    setPortal(nextPortal)
    setError(null)
    setPassword('')
  }

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    if (!email.trim() || !password) {
      setError('Enter your email and password.')
      return
    }

    setSubmitting(true)
    window.sessionStorage.setItem(pendingRoleCheckKey, portal)
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({ email: email.trim(), password })
    if (signInError || !signInData.user) {
      window.sessionStorage.removeItem(pendingRoleCheckKey)
      setSubmitting(false)
      setError(signInError?.message === 'Invalid login credentials' ? 'Incorrect email or password.' : signInError?.message ?? 'Unable to sign in.')
      return
    }

    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('role, status')
      .eq('id', signInData.user.id)
      .single()

    window.sessionStorage.removeItem(pendingRoleCheckKey)

    if (profileError || !profile) {
      await supabase.auth.signOut()
      setSubmitting(false)
      setError(signInData.user.user_metadata?.requested_role
        ? 'Your registration is awaiting administrator approval.'
        : 'No LMS profile is linked to this account. Contact an administrator.')
      return
    }
    if (profile.status !== 'active') {
      await supabase.auth.signOut()
      setSubmitting(false)
      setError('Your account is not active. Contact an administrator.')
      return
    }
    if (profile.role !== portal) {
      await supabase.auth.signOut()
      setSubmitting(false)
      setError(`This account is registered as ${roleLabels[profile.role]}. Please use the ${roleLabels[profile.role]} sign-in form.`)
      return
    }

    await supabase.auth.refreshSession()
    setSubmitting(false)
    navigate('/dashboard', { replace: true })
  }

  return (
    <>
      {portal !== 'admin' ? (
        <div className="login-role-toggle" aria-label="Select account type">
          <button type="button" className={portal === 'student' ? 'login-role-option login-role-option-active' : 'login-role-option'} onClick={() => selectPortal('student')}>
            <GraduationCap size={18} /> Student
          </button>
          <button type="button" className={portal === 'instructor' ? 'login-role-option login-role-option-active' : 'login-role-option'} onClick={() => selectPortal('instructor')}>
            <BookOpenCheck size={18} /> Instructor
          </button>
        </div>
      ) : (
        <button type="button" className="mb-5 inline-flex items-center gap-2 text-sm font-bold text-brand-700 hover:text-brand-800" onClick={() => selectPortal('instructor')}>
          <ArrowLeft size={17} /> Back to instructor sign in
        </button>
      )}

      <div className="mb-6 flex items-start gap-3">
        <div className={`grid size-11 shrink-0 place-items-center rounded-xl ${portal === 'admin' ? 'bg-slate-900 text-white' : 'bg-blue-50 text-brand-700'}`}>
          <PortalIcon size={22} aria-hidden="true" />
        </div>
        <div>
          <h2 className="text-2xl font-extrabold tracking-tight text-slate-900">{details.title}</h2>
          <p className="mt-1 text-sm leading-5 text-slate-500">{details.description}</p>
        </div>
      </div>

      {message && <div className="mb-4 rounded-lg border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-800">{message}</div>}
      {error && <div className="mb-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">{error}</div>}

      <form onSubmit={handleSubmit} className="space-y-4" noValidate>
        <label className="field-label">
          Email address
          <span className="input-wrap"><Mail size={18} /><input type="email" autoComplete="email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="Enter your registered email" /></span>
        </label>
        <label className="field-label">
          Password
          <span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Enter your password" /><button type="button" className="icon-button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? 'Hide password' : 'Show password'}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></span>
        </label>
        <button className={`w-full ${portal === 'admin' ? 'admin-sign-in-button' : 'button-primary'}`} disabled={submitting}>
          {submitting ? 'Signing in…' : `Sign in as ${roleLabels[portal]}`}
        </button>
      </form>

      {portal === 'instructor' && (
        <button type="button" className="mt-4 flex w-full items-center justify-center gap-2 text-sm font-bold text-slate-600 hover:text-brand-700" onClick={() => selectPortal('admin')}>
          <ShieldCheck size={17} /> Sign In as Admin
        </button>
      )}

      <div className="mt-6 border-t border-slate-100 pt-5 text-center">
        <p className="text-sm text-slate-600">Don&apos;t have an account? <Link className="font-bold text-brand-700 hover:text-brand-800" to="/register">Register Account</Link></p>
        <p className="mt-2 text-xs text-slate-400">Gmail registration for all roles requires administrator approval.</p>
      </div>
    </>
  )
}