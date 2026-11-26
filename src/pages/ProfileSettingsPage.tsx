import { useRef, useState, type ChangeEvent, type FormEvent } from 'react'
import { BadgeCheck, Camera, Eye, EyeOff, KeyRound, LockKeyhole, Mail, ShieldCheck, Trash2, Upload, UserRound } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { ProfileAvatar } from '../components/ProfileAvatar'
import { useAuth } from '../hooks/useAuth'
import { roleLabels } from '../lib/auth'
import { supabase } from '../lib/supabase'

export function ProfileSettingsPage() {
  const { profile, refreshProfile } = useAuth()
  const navigate = useNavigate()
  const [currentPassword, setCurrentPassword] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [photoError, setPhotoError] = useState<string | null>(null)
  const [photoMessage, setPhotoMessage] = useState<string | null>(null)
  const [photoSaving, setPhotoSaving] = useState(false)
  const photoInput = useRef<HTMLInputElement>(null)

  if (!profile) return null

  const updatePhoto = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    event.target.value = ''
    if (!file) return
    setPhotoError(null); setPhotoMessage(null)
    const extensions: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/gif': 'gif' }
    const extension = extensions[file.type]
    if (!extension) return setPhotoError('Choose a JPG, PNG, WEBP, or GIF image.')
    if (file.size > 5 * 1024 * 1024) return setPhotoError('Profile pictures must be 5 MB or smaller.')
    setPhotoSaving(true)
    const path = `${profile.id}/${crypto.randomUUID()}.${extension}`
    const { error: uploadError } = await supabase.storage.from('profiles').upload(path, file)
    if (uploadError) setPhotoError(uploadError.message)
    else {
      await refreshProfile()
      setPhotoMessage('Your profile picture was updated across the LMS.')
    }
    setPhotoSaving(false)
  }

  const removePhoto = async () => {
    if (!profile.avatar_path) return
    setPhotoSaving(true); setPhotoError(null); setPhotoMessage(null)
    const { error: removeError } = await supabase.storage.from('profiles').remove([profile.avatar_path])
    if (removeError) setPhotoError(removeError.message)
    else {
      await refreshProfile()
      setPhotoMessage('Your profile picture was removed. Your initials will be shown instead.')
    }
    setPhotoSaving(false)
  }

  const changePassword = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    if (currentPassword === '') {
      setError('Enter your current password.')
      return
    }
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) {
      setError('Password must be at least 8 characters and contain uppercase, lowercase, and a number.')
      return
    }
    if (password !== confirmPassword) {
      setError('Passwords do not match.')
      return
    }

    setSubmitting(true)
    const { error: updateError } = await supabase.auth.updateUser({ password, currentPassword })
    if (updateError) {
      setSubmitting(false)
      setError(updateError.message)
      return
    }
    await supabase.auth.signOut()
    navigate(`/login?portal=${profile.role}`, { replace: true, state: { message: 'Your password was updated. Sign in again with your new password.' } })
  }

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <section className="card overflow-hidden">
        <div className="bg-gradient-to-r from-brand-800 to-brand-600 p-5 text-white sm:p-7">
          <div className="flex items-center gap-4">
            <ProfileAvatar name={profile.full_name} avatarPath={profile.avatar_path} className="size-16 text-lg ring-white/30" />
            <div className="min-w-0">
              <h2 className="truncate text-xl font-extrabold sm:text-2xl">{profile.full_name}</h2>
              <p className="mt-1 text-sm text-blue-100">{roleLabels[profile.role]} account</p>
            </div>
          </div>
        </div>
        <div className="grid gap-4 p-5 sm:grid-cols-2 sm:p-7">
          <ProfileDetail icon={<UserRound size={18} />} label="Full name" value={profile.full_name} />
          <ProfileDetail icon={<Mail size={18} />} label="Email address" value={profile.email} />
          <ProfileDetail icon={<BadgeCheck size={18} />} label="School ID" value={profile.school_id || 'Not available'} />
          <ProfileDetail icon={<ShieldCheck size={18} />} label="LMS role" value={roleLabels[profile.role]} />
          <p className="sm:col-span-2 rounded-xl border border-blue-100 bg-blue-50 p-4 text-sm leading-6 text-slate-600">Your name, email, school ID, and role are managed by the central OneCampus account. Contact the appropriate OneCampus administrator if these details need correction.</p>
        </div>
      </section>

      <section className="card p-5 sm:p-7">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-center">
          <div className="relative self-start">
            <ProfileAvatar name={profile.full_name} avatarPath={profile.avatar_path} className="size-28 text-2xl ring-4 ring-blue-100" />
            <span className="pointer-events-none absolute bottom-0 right-0 grid size-9 place-items-center rounded-full bg-brand-700 text-white ring-4 ring-white"><Camera size={17} /></span>
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-extrabold text-slate-900">Profile picture</h2>
            <p className="mt-1 max-w-2xl text-sm leading-6 text-slate-500">This picture appears beside your name throughout the LMS, including rosters, discussions, submissions, activities, and account menus. Click any displayed profile picture to view it larger.</p>
            {photoError && <div className="mt-3 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">{photoError}</div>}
            {photoMessage && <div className="mt-3 rounded-lg border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-800" role="status">{photoMessage}</div>}
            <div className="mt-4 flex flex-col gap-2 sm:flex-row">
              <input ref={photoInput} className="sr-only" type="file" accept="image/jpeg,image/png,image/webp,image/gif" onChange={(event) => void updatePhoto(event)} />
              <button type="button" className="button-primary" disabled={photoSaving} onClick={() => photoInput.current?.click()}><Upload size={17} /> {photoSaving ? 'Saving…' : profile.avatar_path ? 'Replace picture' : 'Upload picture'}</button>
              {profile.avatar_path && <button type="button" className="button-secondary text-red-600" disabled={photoSaving} onClick={() => void removePhoto()}><Trash2 size={17} /> Remove picture</button>}
            </div>
            <p className="mt-3 text-xs leading-5 text-slate-400">JPG, PNG, WEBP, or GIF. Maximum file size: 5 MB. Square images display best.</p>
          </div>
        </div>
      </section>

      <section className="card p-5 sm:p-7">
        <div className="mb-5 flex items-start gap-3">
          <div className="grid size-11 shrink-0 place-items-center rounded-xl bg-blue-50 text-brand-700"><KeyRound size={21} /></div>
          <div><h2 className="text-lg font-extrabold text-slate-900">Change password</h2><p className="mt-1 text-sm text-slate-500">Update the password for your central OneCampus account.</p></div>
        </div>

        <form className="max-w-xl space-y-4" onSubmit={changePassword} noValidate>
          {error && <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">{error}</div>}
          <label className="field-label">Current password<span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} autoComplete="current-password" value={currentPassword} onChange={(event) => setCurrentPassword(event.target.value)} placeholder="Enter your current password" /><button type="button" className="icon-button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? 'Hide passwords' : 'Show passwords'}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></span></label>
          <label className="field-label">New password<span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} autoComplete="new-password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Enter a new password" /></span></label>
          <label className="field-label">Confirm new password<span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} autoComplete="new-password" value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} placeholder="Confirm your new password" /></span></label>
          <p className="text-xs leading-5 text-slate-500">Use at least 8 characters with uppercase, lowercase, and a number. You will be signed out after changing your password.</p>
          <button className="button-primary" disabled={submitting}>{submitting ? 'Updating password…' : 'Change password'}</button>
        </form>
      </section>
    </div>
  )
}

function ProfileDetail({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return <div className="flex min-w-0 items-start gap-3 rounded-xl border border-slate-200 bg-slate-50 p-4 text-brand-700"><span className="mt-0.5 shrink-0" aria-hidden="true">{icon}</span><div className="min-w-0"><p className="text-xs font-extrabold uppercase tracking-wide text-slate-400">{label}</p><p className="mt-1 break-words text-sm font-bold text-slate-800">{value}</p></div></div>
}