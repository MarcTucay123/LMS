import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type RequestedRole = 'student' | 'instructor' | 'admin'

interface RegistrationRequest {
  action?: 'catalog' | 'register'
  firstName?: string
  middleName?: string | null
  lastName?: string
  suffix?: string | null
  email?: string
  password?: string
  role?: RequestedRole
  studentIdNumber?: string
  classCode?: string
  program?: string
  yearLevel?: number
  block?: string
  academicYear?: string
  semester?: string
  selectedClassIds?: string[]
  termsAccepted?: boolean
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
}

function isValidEmail(email: string) {
  return /^[^\s@]+@[^\s@]+[.][^\s@]+$/.test(email)
}

function normalizeNamePart(value?: string | null) {
  return value?.trim().replace(/\s+/g, ' ') || null
}

function isValidNamePart(value: string) {
  return /^[\p{L}\p{M} .'-]+$/u.test(value) && value.length <= 80
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405)

  let createdUserId: string | null = null
  try {
    const body = await request.json() as RegistrationRequest
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (!supabaseUrl || !serviceRoleKey) return json({ error: 'Registration service is not configured.' }, 500)
    const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { autoRefreshToken: false, persistSession: false } })

    if (body.action === 'catalog') {
      const { data, error: catalogError } = await admin
        .from('classes')
        .select('id, section, school_year, semester, subject:subjects(code, title)')
        .eq('status', 'active')
        .order('school_year', { ascending: false })
        .order('section')
      if (catalogError) throw catalogError
      return json({ classes: data ?? [] })
    }

    const { firstName, middleName, lastName, suffix, email, password, role, studentIdNumber, classCode, program, yearLevel, block, academicYear, semester, selectedClassIds, termsAccepted } = body
    const normalizedFirstName = normalizeNamePart(firstName)
    const normalizedMiddleName = normalizeNamePart(middleName)
    const normalizedLastName = normalizeNamePart(lastName)
    const normalizedSuffix = normalizeNamePart(suffix)
    const normalizedEmail = email?.trim().toLowerCase()
    const normalizedStudentId = studentIdNumber?.trim().toUpperCase() || null
    const normalizedClassCode = classCode?.trim() || null
    const normalizedProgram = program?.trim().toUpperCase() || null
    const normalizedBlock = block?.trim().toUpperCase() || null
    const normalizedAcademicYear = academicYear?.trim() || null
    const normalizedSemester = semester?.trim() || null
    const normalizedClassIds = [...new Set(selectedClassIds ?? [])]
    const normalizedName = [normalizedFirstName, normalizedMiddleName, normalizedLastName, normalizedSuffix].filter(Boolean).join(' ')
    const allowedRoles: RequestedRole[] = ['student', 'instructor', 'admin']

    if (!normalizedFirstName || !normalizedLastName || !normalizedEmail || !password || !role) {
      return json({ error: 'First name, last name, email address, password, and requested role are required.' }, 400)
    }
    if (![normalizedFirstName, normalizedMiddleName, normalizedLastName].filter(Boolean).every((part) => isValidNamePart(part!)) || (normalizedSuffix && (!/^[\p{L}\p{M}0-9 .'-]+$/u.test(normalizedSuffix) || normalizedSuffix.length > 20))) return json({ error: 'Enter a valid personal name.' }, 400)
    if (!isValidEmail(normalizedEmail)) return json({ error: 'Enter a valid email address.' }, 400)
    if (!allowedRoles.includes(role)) return json({ error: 'Select a valid account role.' }, 400)
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) {
      return json({ error: 'Password must be at least 8 characters and contain uppercase, lowercase, and a number.' }, 400)
    }

    if (role === 'student') {
      if (!normalizedStudentId || !normalizedClassCode || !normalizedProgram || !yearLevel || !normalizedBlock || !normalizedAcademicYear || !normalizedSemester || normalizedClassIds.length === 0 || !termsAccepted) {
        return json({ error: 'Complete all required student registration fields and accept the terms.' }, 400)
      }
      if (!/^[A-Z0-9-]{4,30}$/.test(normalizedStudentId)) return json({ error: 'Enter a valid Student ID Number using letters, numbers, and hyphens.' }, 400)
      if (!/^[0-9]{4}$/.test(normalizedClassCode)) return json({ error: 'Class Code must contain exactly 4 digits.' }, 400)
      if (!Number.isInteger(yearLevel) || yearLevel < 1 || yearLevel > 10) return json({ error: 'Select a valid year level.' }, 400)
      if (!/^[0-9]{4}-[0-9]{4}$/.test(normalizedAcademicYear)) return json({ error: 'Select a valid academic year.' }, 400)

      const { data: selectedClasses, error: selectedClassesError } = await admin
        .from('classes')
        .select('id, section, school_year, semester')
        .in('id', normalizedClassIds)
        .eq('status', 'active')
      if (selectedClassesError) throw selectedClassesError
      const expectedSection = `${normalizedProgram}-${yearLevel}${normalizedBlock}`
      if ((selectedClasses?.length ?? 0) !== normalizedClassIds.length || selectedClasses?.some((item) => item.section.trim().toUpperCase() !== expectedSection || item.school_year.trim() !== normalizedAcademicYear || item.semester.trim() !== normalizedSemester)) {
        return json({ error: 'One or more selected subjects do not match the chosen academic details.' }, 400)
      }
    } else if (studentIdNumber || classCode || program || yearLevel || block || academicYear || semester || normalizedClassIds.length > 0 || termsAccepted) {
      return json({ error: 'Student academic details are only valid for student registrations.' }, 400)
    }

    const [{ data: existingApplication, error: applicationError }, { data: existingProfile, error: profileError }, studentApplicationResult, studentProfileResult] = await Promise.all([
      admin.from('registration_applications').select('status').eq('email', normalizedEmail).maybeSingle(),
      admin.from('profiles').select('id').eq('email', normalizedEmail).maybeSingle(),
      normalizedStudentId ? admin.from('registration_applications').select('id').ilike('student_id_number', normalizedStudentId).maybeSingle() : Promise.resolve({ data: null, error: null }),
      normalizedStudentId ? admin.from('profiles').select('id').ilike('school_id', normalizedStudentId).maybeSingle() : Promise.resolve({ data: null, error: null }),
    ])
    if (applicationError || profileError || studentApplicationResult.error || studentProfileResult.error) throw applicationError ?? profileError ?? studentApplicationResult.error ?? studentProfileResult.error
    if (existingProfile) return json({ error: 'An LMS account already uses this email address.' }, 409)
    if (studentApplicationResult.data || studentProfileResult.data) return json({ error: 'This Student ID Number is already registered.' }, 409)
    if (existingApplication) {
      const message = existingApplication.status === 'pending'
        ? 'This email address already has a pending registration.'
        : `This email address already has a ${existingApplication.status} registration.`
      return json({ error: message }, 409)
    }

    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email: normalizedEmail,
      password,
      email_confirm: true,
      user_metadata: { full_name: normalizedName, first_name: normalizedFirstName, middle_name: normalizedMiddleName, last_name: normalizedLastName, suffix: normalizedSuffix, requested_role: role, student_id_number: normalizedStudentId },
    })
    if (createError || !created.user) {
      if (createError?.message.toLowerCase().includes('already')) return json({ error: 'This email address is already registered.' }, 409)
      throw createError ?? new Error('Unable to create authentication account.')
    }
    createdUserId = created.user.id

    const { error: insertError } = await admin.from('registration_applications').insert({
      auth_user_id: created.user.id,
      email: normalizedEmail,
      full_name: normalizedName,
      first_name: normalizedFirstName,
      middle_name: normalizedMiddleName,
      last_name: normalizedLastName,
      suffix: normalizedSuffix,
      requested_role: role,
      student_id_number: role === 'student' ? normalizedStudentId : null,
      class_code: role === 'student' ? normalizedClassCode : null,
      program: role === 'student' ? normalizedProgram : null,
      year_level: role === 'student' ? yearLevel : null,
      block: role === 'student' ? normalizedBlock : null,
      academic_year: role === 'student' ? normalizedAcademicYear : null,
      semester: role === 'student' ? normalizedSemester : null,
      selected_class_ids: role === 'student' ? normalizedClassIds : [],
      terms_accepted_at: role === 'student' ? new Date().toISOString() : null,
    })
    if (insertError) throw insertError

    return json({ message: 'Registration submitted. An administrator must approve your account before you can sign in.' }, 201)
  } catch (error) {
    console.error('register-account failed', error)
    if (createdUserId) {
      const supabaseUrl = Deno.env.get('SUPABASE_URL')
      const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
      if (supabaseUrl && serviceRoleKey) {
        const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { autoRefreshToken: false, persistSession: false } })
        await admin.auth.admin.deleteUser(createdUserId)
      }
    }
    return json({ error: 'Unable to submit the registration right now. Please try again.' }, 500)
  }
})