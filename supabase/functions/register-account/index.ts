import { createClient } from 'npm:@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

type RequestedRole = 'student' | 'instructor' | 'admin'

interface RegistrationRequest {
  fullName?: string
  email?: string
  password?: string
  role?: RequestedRole
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
}

function isValidEmail(email: string) {
  return /^[^\s@]+@[^\s@]+[.][^\s@]+$/.test(email)
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405)

  let createdUserId: string | null = null
  try {
    const { fullName, email, password, role } = await request.json() as RegistrationRequest
    const normalizedName = fullName?.trim()
    const normalizedEmail = email?.trim().toLowerCase()
    const allowedRoles: RequestedRole[] = ['student', 'instructor', 'admin']

    if (!normalizedName || normalizedName.length < 2 || !normalizedEmail || !password || !role) {
      return json({ error: 'Full name, email address, password, and requested role are required.' }, 400)
    }
    if (!isValidEmail(normalizedEmail)) return json({ error: 'Enter a valid email address.' }, 400)
    if (!allowedRoles.includes(role)) return json({ error: 'Select a valid account role.' }, 400)
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) {
      return json({ error: 'Password must be at least 8 characters and contain uppercase, lowercase, and a number.' }, 400)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (!supabaseUrl || !serviceRoleKey) return json({ error: 'Registration service is not configured.' }, 500)
    const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { autoRefreshToken: false, persistSession: false } })

    const [{ data: existingApplication, error: applicationError }, { data: existingProfile, error: profileError }] = await Promise.all([
      admin.from('registration_applications').select('status').eq('email', normalizedEmail).maybeSingle(),
      admin.from('profiles').select('id').eq('email', normalizedEmail).maybeSingle(),
    ])
    if (applicationError || profileError) throw applicationError ?? profileError
    if (existingProfile) return json({ error: 'An LMS account already uses this email address.' }, 409)
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
      user_metadata: { full_name: normalizedName, requested_role: role },
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
      requested_role: role,
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