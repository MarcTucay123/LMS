import { useState, type FormEvent } from 'react'
import { Link, Navigate, useNavigate, useParams } from 'react-router-dom'
import { BadgeCheck, BookOpenCheck, Eye, EyeOff, GraduationCap, LockKeyhole, Mail, ShieldCheck, UserRound } from 'lucide-react'
import { supabase } from '../lib/supabase'
import type { UserRole } from '../types/database'

const roleDetails: Record<UserRole, { label: string; description: string; icon: typeof UserRound }> = {
  student: { label: 'Student', description: 'Register to access your enrolled classes and learning activities after approval.', icon: GraduationCap },
  instructor: { label: 'Instructor', description: 'Register to manage classes assigned by an administrator after approval.', icon: BookOpenCheck },
  admin: { label: 'Administrator', description: 'Register for administrative access. An existing active administrator must approve you.', icon: ShieldCheck },
}

function isUserRole(value: string | undefined): value is UserRole {
  return value === 'student' || value === 'instructor' || value === 'admin'
}

export function RegisterPage() {
  const navigate = useNavigate()
  const { role } = useParams()
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (!isUserRole(role)) return <Navigate to="/register/student" replace />

  const details = roleDetails[role]
  const RoleIcon = details.icon

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    const normalizedEmail = email.trim().toLowerCase()
    if (!fullName.trim() || !normalizedEmail || !password || !confirmPassword) return setError('Complete all required fields.')
    if (!/^[a-z0-9._%+-]+@gmail[.]com$/i.test(normalizedEmail)) return setError('Use a valid @gmail.com email address.')
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) return setError('Password must be at least 8 characters and contain uppercase, lowercase, and a number.')
    if (password !== confirmPassword) return setError('Passwords do not match.')

    setSubmitting(true)
    const { data, error: functionError } = await supabase.functions.invoke<{ message?: string }>('register-account', {
      body: { fullName: fullName.trim(), email: normalizedEmail, password, role },
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
    navigate(`/login?portal=${role}`, { replace: true, state: { message: data?.message ?? 'Registration submitted for administrator approval.' } })
  }

  return (
    <>
      <div className="mb-6 flex items-start gap-3">
        <div className={`grid size-11 shrink-0 place-items-center rounded-xl ${role === 'admin' ? 'bg-slate-900 text-white' : 'bg-blue-50 text-brand-700'}`}><RoleIcon size={22} /></div>
        <div>
          <h2 className="text-2xl font-extrabold tracking-tight text-slate-900">{details.label} registration</h2>
          <p className="mt-1 text-sm leading-5 text-slate-500">{details.description}</p>
        </div>
      </div>
      {error && <div className="mb-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">{error}</div>}
      <form onSubmit={handleSubmit} className="space-y-4" noValidate>
        <label className="field-label">Full name<span className="input-wrap"><UserRound size={18} /><input value={fullName} onChange={(event) => setFullName(event.target.value)} autoComplete="name" placeholder="Enter your complete name" /></span></label>
        <label className="field-label">Gmail address<span className="input-wrap"><Mail size={18} /><input type="email" value={email} onChange={(event) => setEmail(event.target.value)} autoComplete="email" placeholder="yourname@gmail.com" /></span></label>

        <label className="field-label">Create password<span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="new-password" /><button type="button" className="icon-button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? 'Hide password' : 'Show password'}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></span></label>
        <label className="field-label">Confirm password<span className="input-wrap"><BadgeCheck size={18} /><input type={showPassword ? 'text' : 'password'} value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} autoComplete="new-password" /></span></label>
        <p className="text-xs text-slate-500">Use at least 8 characters with uppercase, lowercase, and a number. Your {details.label.toLowerCase()} account remains pending until approved.</p>
        <button className={`w-full ${role === 'admin' ? 'admin-sign-in-button' : 'button-primary'}`} disabled={submitting}>{submitting ? 'Submitting…' : `Register as ${details.label}`}</button>
      </form>
      <p className="mt-5 text-center text-sm text-slate-600">Already registered? <Link className="font-bold text-brand-700" to={`/login?portal=${role}`}>Back to {details.label.toLowerCase()} sign in</Link></p>
    </>
  )
}