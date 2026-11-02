import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { BadgeCheck, BookOpenCheck, Eye, EyeOff, GraduationCap, LockKeyhole, Mail, ShieldCheck, UserRound } from 'lucide-react'
import { supabase } from '../lib/supabase'
import type { UserRole } from '../types/database'

const roles: { value: UserRole; label: string; description: string; icon: typeof UserRound }[] = [
  { value: 'student', label: 'Student', description: 'Access enrolled classes and activities', icon: GraduationCap },
  { value: 'instructor', label: 'Instructor', description: 'Manage classes assigned after approval', icon: BookOpenCheck },
  { value: 'admin', label: 'Administrator', description: 'Requires approval by an active administrator', icon: ShieldCheck },
]

export function RegisterPage() {
  const navigate = useNavigate()
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [role, setRole] = useState<UserRole>('student')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

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
    navigate('/login', { replace: true, state: { message: data?.message ?? 'Registration submitted for administrator approval.' } })
  }

  return (
    <>
      <div className="mb-6">
        <h2 className="text-2xl font-extrabold tracking-tight text-slate-900">Register account</h2>
        <p className="mt-1 text-sm leading-5 text-slate-500">Apply using Gmail. Your OC ID is generated only after an administrator approves your account.</p>
      </div>
      {error && <div className="mb-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">{error}</div>}
      <form onSubmit={handleSubmit} className="space-y-4" noValidate>
        <label className="field-label">Full name<span className="input-wrap"><UserRound size={18} /><input value={fullName} onChange={(event) => setFullName(event.target.value)} autoComplete="name" placeholder="Enter your complete name" /></span></label>
        <label className="field-label">Gmail address<span className="input-wrap"><Mail size={18} /><input type="email" value={email} onChange={(event) => setEmail(event.target.value)} autoComplete="email" placeholder="yourname@gmail.com" /></span></label>

        <fieldset>
          <legend className="field-label mb-2">Apply as</legend>
          <div className="space-y-2">
            {roles.map((item) => {
              const Icon = item.icon
              return <label key={item.value} className={`flex cursor-pointer items-start gap-3 rounded-xl border p-3 transition ${role === item.value ? 'border-blue-300 bg-blue-50' : 'border-slate-200 hover:bg-slate-50'}`}><input className="mt-1" type="radio" name="role" value={item.value} checked={role === item.value} onChange={() => setRole(item.value)} /><Icon className={role === item.value ? 'text-brand-700' : 'text-slate-400'} size={19} /><span><strong className="block text-sm text-slate-800">{item.label}</strong><small className="text-xs text-slate-500">{item.description}</small></span></label>
            })}
          </div>
        </fieldset>

        <label className="field-label">Create password<span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="new-password" /><button type="button" className="icon-button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? 'Hide password' : 'Show password'}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></span></label>
        <label className="field-label">Confirm password<span className="input-wrap"><BadgeCheck size={18} /><input type={showPassword ? 'text' : 'password'} value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} autoComplete="new-password" /></span></label>
        <p className="text-xs text-slate-500">Use at least 8 characters with uppercase, lowercase, and a number. All roles remain pending until approved.</p>
        <button className="button-primary w-full" disabled={submitting}>{submitting ? 'Submitting…' : 'Submit registration'}</button>
      </form>
      <p className="mt-5 text-center text-sm text-slate-600">Already registered? <Link className="font-bold text-brand-700" to="/login">Back to sign in</Link></p>
    </>
  )
}