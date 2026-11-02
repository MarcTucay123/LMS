import { useState, type FormEvent } from 'react'
import { Link, Navigate, useNavigate, useParams } from 'react-router-dom'
import { BadgeCheck, BookOpenCheck, Eye, EyeOff, GraduationCap, LockKeyhole, Mail, ShieldCheck, UserRound } from 'lucide-react'
import { supabase } from '../lib/supabase'
import type { UserRole } from '../types/database'
import { StudentRegistrationForm } from './StudentRegistrationForm'

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
  const [firstName, setFirstName] = useState('')
  const [middleName, setMiddleName] = useState('')
  const [lastName, setLastName] = useState('')
  const [suffix, setSuffix] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (!isUserRole(role)) return <Navigate to="/register/student" replace />
  if (role === 'student') return <StudentRegistrationForm />

  const details = roleDetails[role]
  const RoleIcon = details.icon

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    const normalizedEmail = email.trim().toLowerCase()
    const normalizedFirstName = firstName.trim().replace(/\s+/g, ' ')
    const normalizedMiddleName = middleName.trim().replace(/\s+/g, ' ')
    const normalizedLastName = lastName.trim().replace(/\s+/g, ' ')
    const normalizedSuffix = suffix.trim().replace(/\s+/g, ' ')
    const validName = /^[\p{L}\p{M} .'-]+$/u
    const validSuffix = /^[\p{L}\p{M}0-9 .'-]+$/u
    if (!normalizedFirstName || !normalizedLastName || !normalizedEmail || !password || !confirmPassword) return setError('Complete all required fields.')
    if (![normalizedFirstName, normalizedMiddleName, normalizedLastName].filter(Boolean).every((part) => validName.test(part)) || (normalizedSuffix && !validSuffix.test(normalizedSuffix))) return setError('Enter a valid name using letters, spaces, apostrophes, periods, or hyphens.')
    if (!/^[^\s@]+@[^\s@]+[.][^\s@]+$/.test(normalizedEmail)) return setError('Use a valid email address.')
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) return setError('Password must be at least 8 characters and contain uppercase, lowercase, and a number.')
    if (password !== confirmPassword) return setError('Passwords do not match.')

    setSubmitting(true)
    const { data, error: functionError } = await supabase.functions.invoke<{ message?: string }>('register-account', {
      body: { firstName: normalizedFirstName, middleName: normalizedMiddleName || null, lastName: normalizedLastName, suffix: normalizedSuffix || null, email: normalizedEmail, password, role },
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
        <fieldset>
          <legend className="mb-2 text-sm font-semibold text-slate-700">Personal name</legend>
          <div className="grid gap-4 sm:grid-cols-2">
            <label className="field-label">First name<span className="input-wrap"><UserRound size={18} /><input value={firstName} onChange={(event) => setFirstName(event.target.value)} autoComplete="given-name" maxLength={80} placeholder="First name" /></span></label>
            <label className="field-label">Middle name <span className="font-normal text-slate-400">(optional)</span><span className="input-wrap"><UserRound size={18} /><input value={middleName} onChange={(event) => setMiddleName(event.target.value)} autoComplete="additional-name" maxLength={80} placeholder="Middle name" /></span></label>
            <label className="field-label">Last name<span className="input-wrap"><UserRound size={18} /><input value={lastName} onChange={(event) => setLastName(event.target.value)} autoComplete="family-name" maxLength={80} placeholder="Last name" /></span></label>
            <label className="field-label">Suffix <span className="font-normal text-slate-400">(optional)</span><span className="input-wrap"><BadgeCheck size={18} /><input value={suffix} onChange={(event) => setSuffix(event.target.value)} autoComplete="honorific-suffix" maxLength={20} placeholder="Jr., Sr., III" /></span></label>
          </div>
        </fieldset>
        <label className="field-label">Email address<span className="input-wrap"><Mail size={18} /><input type="email" value={email} onChange={(event) => setEmail(event.target.value)} autoComplete="email" placeholder="Enter your email address" /></span></label>

        <label className="field-label">Create password<span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="new-password" /><button type="button" className="icon-button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? 'Hide password' : 'Show password'}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></span></label>
        <label className="field-label">Confirm password<span className="input-wrap"><BadgeCheck size={18} /><input type={showPassword ? 'text' : 'password'} value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} autoComplete="new-password" /></span></label>
        <p className="text-xs text-slate-500">Use at least 8 characters with uppercase, lowercase, and a number. Your {details.label.toLowerCase()} account remains pending until approved.</p>
        <button className={`w-full ${role === 'admin' ? 'admin-sign-in-button' : 'button-primary'}`} disabled={submitting}>{submitting ? 'Submitting…' : `Register as ${details.label}`}</button>
      </form>
      <p className="mt-5 text-center text-sm text-slate-600">Already registered? <Link className="font-bold text-brand-700" to={`/login?portal=${role}`}>Back to {details.label.toLowerCase()} sign in</Link></p>
    </>
  )
}