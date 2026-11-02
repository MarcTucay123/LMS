import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2'
import mockData from './fixtures.json' with { type: 'json' }
import { corsHeaders } from '../_shared/cors.ts'

type UserRole = 'student' | 'instructor'
type AccountStatus = 'pending' | 'active' | 'inactive'

interface OneCampusUser {
  id: string
  schoolId: string
  email: string
  fullName: string
  role: UserRole
  status: AccountStatus
}

interface OneCampusSubject {
  id: string
  code: string
  title: string
  description?: string | null
}

interface OneCampusClass {
  id: string
  subjectId: string
  instructorId: string
  section: string
  schoolYear: string
  semester: string
  status: 'active' | 'archived'
}

interface OneCampusEnrollment {
  id: string
  classId: string
  studentId: string
  status: 'enrolled' | 'dropped' | 'completed'
}

interface OneCampusPayload {
  users: OneCampusUser[]
  subjects: OneCampusSubject[]
  classes: OneCampusClass[]
  enrollments: OneCampusEnrollment[]
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
}

function assertPayload(value: unknown): asserts value is OneCampusPayload {
  if (!value || typeof value !== 'object') throw new Error('OneCampus returned an invalid payload.')
  const payload = value as Partial<OneCampusPayload>
  if (!Array.isArray(payload.users) || !Array.isArray(payload.subjects) || !Array.isArray(payload.classes) || !Array.isArray(payload.enrollments)) {
    throw new Error('OneCampus payload must contain users, subjects, classes, and enrollments arrays.')
  }
}

async function findAuthUserByEmail(admin: SupabaseClient, email: string) {
  for (let page = 1; page <= 10; page += 1) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 100 })
    if (error) throw error
    const match = data.users.find((user) => user.email?.toLowerCase() === email.toLowerCase())
    if (match) return match
    if (data.users.length < 100) return null
  }
  return null
}

async function loadOneCampusData(): Promise<{ payload: OneCampusPayload; source: 'mock' | 'onecampus_api' }> {
  const apiUrl = Deno.env.get('ONECAMPUS_API_URL')?.trim()
  if (!apiUrl) return { payload: mockData as OneCampusPayload, source: 'mock' }

  const apiKey = Deno.env.get('ONECAMPUS_API_KEY')
  if (!apiKey) throw new Error('ONECAMPUS_API_KEY is required when ONECAMPUS_API_URL is configured.')
  const response = await fetch(apiUrl, {
    headers: { Accept: 'application/json', Authorization: `Bearer ${apiKey}`, 'X-API-Key': apiKey },
  })
  if (!response.ok) throw new Error(`OneCampus API returned ${response.status}.`)
  const payload: unknown = await response.json()
  assertPayload(payload)
  return { payload, source: 'onecampus_api' }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405)

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const authorization = request.headers.get('Authorization')
  if (!supabaseUrl || !serviceRoleKey) return json({ error: 'Synchronization service is not configured.' }, 500)
  if (!authorization?.startsWith('Bearer ')) return json({ error: 'Authentication is required.' }, 401)

  const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { autoRefreshToken: false, persistSession: false } })
  const token = authorization.slice('Bearer '.length)
  const { data: userData, error: userError } = await admin.auth.getUser(token)
  if (userError || !userData.user) return json({ error: 'Invalid or expired session.' }, 401)

  const { data: caller } = await admin.from('profiles').select('id, role, status').eq('id', userData.user.id).maybeSingle()
  if (!caller || caller.role !== 'admin' || caller.status !== 'active') return json({ error: 'Only active administrators can run synchronization.' }, 403)

  let logId: string | null = null
  let source: 'mock' | 'onecampus_api' = Deno.env.get('ONECAMPUS_API_URL')?.trim() ? 'onecampus_api' : 'mock'
  try {
    const loaded = await loadOneCampusData()
    source = loaded.source
    const payload = loaded.payload

    const { data: log, error: logError } = await admin.from('sync_logs').insert({ initiated_by: caller.id, source, status: 'running' }).select('id').single()
    if (logError) throw logError
    logId = log.id

    for (const user of payload.users) {
      const normalizedEmail = user.email.trim().toLowerCase()
      const { data: existingProfile } = await admin.from('profiles').select('id, status').eq('onecampus_user_id', user.id).maybeSingle()
      let authUserId = existingProfile?.id

      if (!authUserId) {
        const existingAuthUser = await findAuthUserByEmail(admin, normalizedEmail)
        if (existingAuthUser) authUserId = existingAuthUser.id
        else {
          const { data: created, error: createError } = await admin.auth.admin.createUser({
            email: normalizedEmail,
            email_confirm: true,
            user_metadata: { full_name: user.fullName, onecampus_user_id: user.id },
          })
          if (createError) throw createError
          authUserId = created.user.id
        }
      }

      const profileStatus: AccountStatus = existingProfile?.status === 'active'
        ? 'active'
        : user.status === 'inactive' ? 'inactive' : 'pending'
      const { error: profileError } = await admin.from('profiles').upsert({
        id: authUserId,
        onecampus_user_id: user.id,
        school_id: user.schoolId,
        email: normalizedEmail,
        full_name: user.fullName,
        role: user.role,
        status: profileStatus,
      }, { onConflict: 'id' })
      if (profileError) throw profileError

      const { error: activationError } = await admin.from('activation_records').upsert({
        onecampus_user_id: user.id,
        school_id: user.schoolId,
        email: normalizedEmail,
        full_name: user.fullName,
        role: user.role,
        auth_user_id: authUserId,
        activated_at: profileStatus === 'active' ? new Date().toISOString() : null,
      }, { onConflict: 'onecampus_user_id' })
      if (activationError) throw activationError
    }

    const { error: subjectsError } = await admin.from('subjects').upsert(payload.subjects.map((subject) => ({
      onecampus_subject_id: subject.id,
      code: subject.code,
      title: subject.title,
      description: subject.description ?? null,
    })), { onConflict: 'onecampus_subject_id' })
    if (subjectsError) throw subjectsError

    const userIds = payload.users.map((user) => user.id)
    const subjectIds = payload.subjects.map((subject) => subject.id)
    const { data: syncedProfiles, error: profilesError } = await admin.from('profiles').select('id, onecampus_user_id').in('onecampus_user_id', userIds)
    if (profilesError) throw profilesError
    const { data: syncedSubjects, error: syncedSubjectsError } = await admin.from('subjects').select('id, onecampus_subject_id').in('onecampus_subject_id', subjectIds)
    if (syncedSubjectsError) throw syncedSubjectsError
    const profileMap = new Map(syncedProfiles.map((profile) => [profile.onecampus_user_id, profile.id]))
    const subjectMap = new Map(syncedSubjects.map((subject) => [subject.onecampus_subject_id, subject.id]))

    const classRows = payload.classes.map((classItem) => {
      const subjectId = subjectMap.get(classItem.subjectId)
      const instructorId = profileMap.get(classItem.instructorId)
      if (!subjectId || !instructorId) throw new Error(`Unable to map class ${classItem.id}.`)
      return {
        onecampus_class_id: classItem.id,
        subject_id: subjectId,
        instructor_id: instructorId,
        section: classItem.section,
        school_year: classItem.schoolYear,
        semester: classItem.semester,
        status: classItem.status,
      }
    })
    const { error: classesError } = await admin.from('classes').upsert(classRows, { onConflict: 'onecampus_class_id' })
    if (classesError) throw classesError

    const classIds = payload.classes.map((classItem) => classItem.id)
    const { data: syncedClasses, error: syncedClassesError } = await admin.from('classes').select('id, onecampus_class_id').in('onecampus_class_id', classIds)
    if (syncedClassesError) throw syncedClassesError
    const classMap = new Map(syncedClasses.map((classItem) => [classItem.onecampus_class_id, classItem.id]))

    const enrollmentRows = payload.enrollments.map((enrollment) => {
      const classId = classMap.get(enrollment.classId)
      const studentId = profileMap.get(enrollment.studentId)
      if (!classId || !studentId) throw new Error(`Unable to map enrollment ${enrollment.id}.`)
      return {
        onecampus_enrollment_id: enrollment.id,
        class_id: classId,
        student_id: studentId,
        status: enrollment.status,
      }
    })
    const { error: enrollmentsError } = await admin.from('enrollments').upsert(enrollmentRows, { onConflict: 'onecampus_enrollment_id' })
    if (enrollmentsError) throw enrollmentsError

    const counts = {
      users: payload.users.length,
      subjects: payload.subjects.length,
      classes: payload.classes.length,
      enrollments: payload.enrollments.length,
    }
    const { error: completeError } = await admin.from('sync_logs').update({
      status: 'success', records: counts, message: `Synchronization completed using ${source === 'mock' ? 'mock fixtures' : 'OneCampus API'}.`, completed_at: new Date().toISOString(),
    }).eq('id', logId)
    if (completeError) throw completeError

    return json({ message: 'OneCampus synchronization completed.', source, counts })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown synchronization error.'
    console.error('sync-onecampus failed', error)
    if (logId) {
      await admin.from('sync_logs').update({ status: 'failed', message, completed_at: new Date().toISOString() }).eq('id', logId)
    } else {
      await admin.from('sync_logs').insert({ initiated_by: caller.id, source, status: 'failed', message, completed_at: new Date().toISOString() })
    }
    return json({ error: message }, 500)
  }
})