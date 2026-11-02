import { useEffect, useMemo, useState, type FormEvent } from 'react'
import { BadgeCheck, CheckCircle2, Eye, EyeOff, Info, LockKeyhole, Mail, UserRound, UsersRound } from 'lucide-react'
import { Link, useNavigate } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import { getFunctionErrorMessage } from '../lib/functionError'

interface CatalogClass {
  id: string
  section: string
  school_year: string
  semester: string
  subject: { code: string; title: string } | { code: string; title: string }[] | null
}

interface ClassOffering {
  id: string
  section: string
  schoolYear: string
  semester: string
  program: string
  yearLevel: number
  block: string
  subject: { code: string; title: string }
}

function parseOffering(item: CatalogClass): ClassOffering | null {
  const match = item.section.trim().toUpperCase().match(/^(.+)-(\d+)([A-Z]+)$/)
  const subject = Array.isArray(item.subject) ? item.subject[0] : item.subject
  if (!match || !subject) return null
  return { id: item.id, section: item.section, schoolYear: item.school_year, semester: item.semester, program: match[1], yearLevel: Number(match[2]), block: match[3], subject }
}

function unique<T>(values: T[]) {
  return [...new Set(values)]
}

export function StudentRegistrationForm() {
  const navigate = useNavigate()
  const [offerings, setOfferings] = useState<ClassOffering[]>([])
  const [loadingCatalog, setLoadingCatalog] = useState(true)
  const [studentIdNumber, setStudentIdNumber] = useState('')
  const [classCode, setClassCode] = useState('')
  const [firstName, setFirstName] = useState('')
  const [middleName, setMiddleName] = useState('')
  const [lastName, setLastName] = useState('')
  const [email, setEmail] = useState('')
  const [program, setProgram] = useState('')
  const [yearLevel, setYearLevel] = useState('')
  const [block, setBlock] = useState('')
  const [semester, setSemester] = useState('')
  const [academicYear, setAcademicYear] = useState('')
  const [selectedClassIds, setSelectedClassIds] = useState<string[]>([])
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [termsAccepted, setTermsAccepted] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let active = true
    void supabase.functions.invoke<{ classes?: CatalogClass[] }>('register-account', { body: { action: 'catalog' } }).then(async ({ data, error: catalogError }) => {
      if (!active) return
      if (catalogError) setError(await getFunctionErrorMessage(catalogError, 'Student registration is temporarily unavailable because the registration service has not been deployed. Please contact the LMS administrator.'))
      else setOfferings((data?.classes ?? []).map(parseOffering).filter((item): item is ClassOffering => Boolean(item)))
      setLoadingCatalog(false)
    })
    return () => { active = false }
  }, [])

  const programs = useMemo(() => unique(offerings.map((item) => item.program)).sort(), [offerings])
  const yearLevels = useMemo(() => unique(offerings.filter((item) => !program || item.program === program).map((item) => item.yearLevel)).sort((a, b) => a - b), [offerings, program])
  const blocks = useMemo(() => unique(offerings.filter((item) => (!program || item.program === program) && (!yearLevel || item.yearLevel === Number(yearLevel))).map((item) => item.block)).sort(), [offerings, program, yearLevel])
  const semesters = useMemo(() => unique(offerings.filter((item) => (!program || item.program === program) && (!yearLevel || item.yearLevel === Number(yearLevel)) && (!block || item.block === block)).map((item) => item.semester)).sort(), [offerings, program, yearLevel, block])
  const academicYears = useMemo(() => unique(offerings.filter((item) => (!program || item.program === program) && (!yearLevel || item.yearLevel === Number(yearLevel)) && (!block || item.block === block) && (!semester || item.semester === semester)).map((item) => item.schoolYear)).sort().reverse(), [offerings, program, yearLevel, block, semester])
  const matchingOfferings = useMemo(() => offerings.filter((item) => item.program === program && item.yearLevel === Number(yearLevel) && item.block === block && item.semester === semester && item.schoolYear === academicYear), [offerings, program, yearLevel, block, semester, academicYear])

  const resetSelections = () => setSelectedClassIds([])
  const toggleClass = (id: string) => setSelectedClassIds((current) => current.includes(id) ? current.filter((item) => item !== id) : [...current, id])

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    const normalizedFirstName = firstName.trim().replace(/\s+/g, ' ')
    const normalizedMiddleName = middleName.trim().replace(/\s+/g, ' ')
    const normalizedLastName = lastName.trim().replace(/\s+/g, ' ')
    const normalizedEmail = email.trim().toLowerCase()
    const normalizedStudentId = studentIdNumber.trim().toUpperCase()
    const validName = /^[\p{L}\p{M} .'-]+$/u

    if (!normalizedStudentId || !classCode || !normalizedFirstName || !normalizedLastName || !normalizedEmail || !program || !yearLevel || !block || !semester || !academicYear || !password || !confirmPassword) return setError('Complete all required fields.')
    if (!/^[A-Z0-9-]{4,30}$/.test(normalizedStudentId)) return setError('Enter a valid Student ID Number using letters, numbers, and hyphens.')
    if (!/^\d{4}$/.test(classCode)) return setError('Class Code must contain exactly 4 digits.')
    if (![normalizedFirstName, normalizedMiddleName, normalizedLastName].filter(Boolean).every((part) => validName.test(part))) return setError('Enter a valid name using letters, spaces, apostrophes, periods, or hyphens.')
    if (!/^[^\s@]+@[^\s@]+[.][^\s@]+$/.test(normalizedEmail)) return setError('Use a valid email address.')
    if (selectedClassIds.length === 0) return setError('Select at least one subject.')
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) return setError('Password must be at least 8 characters and contain uppercase, lowercase, and a number.')
    if (password !== confirmPassword) return setError('Passwords do not match.')
    if (!termsAccepted) return setError('You must agree to the Terms and Privacy Policy.')

    setSubmitting(true)
    const { data, error: functionError } = await supabase.functions.invoke<{ message?: string }>('register-account', {
      body: { action: 'register', role: 'student', studentIdNumber: normalizedStudentId, classCode, firstName: normalizedFirstName, middleName: normalizedMiddleName || null, lastName: normalizedLastName, suffix: null, email: normalizedEmail, program, yearLevel: Number(yearLevel), block, semester, academicYear, selectedClassIds, termsAccepted, password },
    })
    setSubmitting(false)
    if (functionError) {
      setError(await getFunctionErrorMessage(functionError, 'Student registration is temporarily unavailable because the registration service has not been deployed. Please contact the LMS administrator.'))
      return
    }
    navigate('/login?portal=student', { replace: true, state: { message: data?.message ?? 'Registration submitted for administrator approval.' } })
  }

  return (
    <>
      <div className="mb-6"><h2 className="text-2xl font-extrabold tracking-tight text-slate-900">Student Registration</h2><p className="mt-1 text-sm text-slate-500">Create your account</p></div>
      <div className="mb-3 rounded-lg border border-blue-200 bg-blue-50 p-3 text-xs text-blue-800"><p className="flex items-center gap-2 font-bold"><Info size={15} /> Important Notice</p><p className="mt-1 flex items-start gap-2"><UsersRound className="mt-0.5 shrink-0" size={14} /><span>Only <strong>ONE account per student</strong> is allowed. Duplicate registrations will be rejected.</span></p></div>
      <div className="mb-5 rounded-lg border border-blue-200 bg-blue-50 p-3 text-xs text-blue-800"><p className="flex items-center gap-2 font-bold"><Mail size={15} /> Email Requirement</p><p className="mt-1 flex items-start gap-2"><CheckCircle2 className="mt-0.5 shrink-0" size={14} /><span>Please use your <strong>active email account</strong> for registration and communication.</span></p></div>
      {error && <div className="mb-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">{error}</div>}

      <form className="space-y-4" onSubmit={handleSubmit} noValidate>
        <div className="grid gap-4 min-[420px]:grid-cols-2">
          <RequiredField label="Student ID Number"><input className="form-input" value={studentIdNumber} onChange={(event) => setStudentIdNumber(event.target.value.toUpperCase())} maxLength={30} placeholder="e.g., 2023-00123" /></RequiredField>
          <RequiredField label="Class Code"><input className="form-input" inputMode="numeric" value={classCode} onChange={(event) => setClassCode(event.target.value.replace(/\D/g, '').slice(0, 4))} placeholder="4-digit number (e.g., 2023, 4567)" /><span className="mt-1 block text-xs text-slate-500">Must be exactly 4 numbers only.</span></RequiredField>
          <RequiredField label="First Name"><span className="input-wrap"><UserRound size={18} /><input value={firstName} onChange={(event) => setFirstName(event.target.value)} autoComplete="given-name" maxLength={80} /></span></RequiredField>
          <label className="field-label">Middle Name <span className="font-normal text-slate-400">(optional)</span><span className="input-wrap"><UserRound size={18} /><input value={middleName} onChange={(event) => setMiddleName(event.target.value)} autoComplete="additional-name" maxLength={80} /></span></label>
          <RequiredField label="Last Name"><span className="input-wrap"><UserRound size={18} /><input value={lastName} onChange={(event) => setLastName(event.target.value)} autoComplete="family-name" maxLength={80} /></span></RequiredField>
          <RequiredField label="Email"><span className="input-wrap"><Mail size={18} /><input type="email" value={email} onChange={(event) => setEmail(event.target.value)} autoComplete="email" placeholder="student@example.com" /></span></RequiredField>
          <RequiredField label="Program"><select className="form-select" value={program} disabled={loadingCatalog} onChange={(event) => { setProgram(event.target.value); setYearLevel(''); setBlock(''); setSemester(''); setAcademicYear(''); resetSelections() }}><option value="">Select Program</option>{programs.map((item) => <option key={item}>{item}</option>)}</select></RequiredField>
          <RequiredField label="Year Level"><select className="form-select" value={yearLevel} disabled={!program} onChange={(event) => { setYearLevel(event.target.value); setBlock(''); setSemester(''); setAcademicYear(''); resetSelections() }}><option value="">Select Year</option>{yearLevels.map((item) => <option key={item} value={item}>Year {item}</option>)}</select></RequiredField>
          <RequiredField label="Block"><select className="form-select" value={block} disabled={!yearLevel} onChange={(event) => { setBlock(event.target.value); setSemester(''); setAcademicYear(''); resetSelections() }}><option value="">Select Block</option>{blocks.map((item) => <option key={item}>{item}</option>)}</select></RequiredField>
          <RequiredField label="Semester"><select className="form-select" value={semester} disabled={!block} onChange={(event) => { setSemester(event.target.value); setAcademicYear(''); resetSelections() }}><option value="">Select Semester</option>{semesters.map((item) => <option key={item}>{item}</option>)}</select></RequiredField>
        </div>
        <RequiredField label="Academic Year"><select className="form-select" value={academicYear} disabled={!semester} onChange={(event) => { setAcademicYear(event.target.value); resetSelections() }}><option value="">Select Academic Year</option>{academicYears.map((item) => <option key={item}>{item}</option>)}</select></RequiredField>

        <fieldset><legend className="field-label"><span className="text-red-500">* </span>Subjects Enrolled</legend><div className="mt-2 flex justify-end gap-4 text-xs"><button type="button" className="font-bold text-brand-700" disabled={matchingOfferings.length === 0} onClick={() => setSelectedClassIds(matchingOfferings.map((item) => item.id))}>Select All</button><button type="button" className="font-bold text-slate-500" onClick={() => setSelectedClassIds([])}>Deselect All</button></div><div className="mt-2 min-h-24 rounded-lg border border-slate-200 p-3">{!academicYear ? <p className="grid min-h-16 place-items-center text-center text-xs text-slate-400">Please select program, year level, block, semester, and academic year to view subjects.</p> : matchingOfferings.length === 0 ? <p className="grid min-h-16 place-items-center text-center text-xs text-slate-400">No matching active subjects are available.</p> : <div className="grid gap-2 sm:grid-cols-2">{matchingOfferings.map((item) => <label key={item.id} className="flex cursor-pointer items-start gap-2 rounded-lg border border-slate-200 p-3 text-sm hover:bg-slate-50"><input className="mt-1" type="checkbox" checked={selectedClassIds.includes(item.id)} onChange={() => toggleClass(item.id)} /><span><strong>{item.subject.code}</strong><span className="block text-xs text-slate-500">{item.subject.title}</span></span></label>)}</div>}</div><p className="mt-1 text-xs text-slate-500">Select subjects that match your enrolled courses. Subjects are filtered from active class offerings.</p></fieldset>

        <div className="grid gap-4 min-[420px]:grid-cols-2">
          <RequiredField label="Password"><span className="input-wrap"><LockKeyhole size={18} /><input type={showPassword ? 'text' : 'password'} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="new-password" placeholder="Minimum 8 characters" /><button type="button" className="icon-button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? 'Hide password' : 'Show password'}>{showPassword ? <EyeOff size={18} /> : <Eye size={18} />}</button></span></RequiredField>
          <RequiredField label="Confirm Password"><span className="input-wrap"><BadgeCheck size={18} /><input type={showPassword ? 'text' : 'password'} value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} autoComplete="new-password" placeholder="Re-enter your password" /></span></RequiredField>
        </div>
        <label className="flex items-start gap-2 text-xs text-slate-600"><input className="mt-0.5" type="checkbox" checked={termsAccepted} onChange={(event) => setTermsAccepted(event.target.checked)} /><span>I agree to the <span className="font-bold text-brand-700">Terms and Privacy Policy</span>.</span></label>
        <button className="button-primary w-full" disabled={submitting || loadingCatalog}><UserRound size={17} /> {submitting ? 'Submitting…' : 'Register Account'}</button>
      </form>
      <div className="mt-5 border-t border-slate-100 pt-5 text-center"><p className="text-sm text-slate-600">Already have an account? <Link className="font-bold text-brand-700" to="/login?portal=student">Login here →</Link></p></div>
      <p className="mt-4 text-center text-xs text-slate-400"><span className="text-red-500">*</span> Required fields</p>
    </>
  )
}

function RequiredField({ label, children }: { label: string; children: React.ReactNode }) {
  return <label className="field-label"><span className="text-red-500">* </span>{label}{children}</label>
}