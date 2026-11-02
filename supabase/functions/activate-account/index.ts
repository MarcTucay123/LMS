import { createClient } from 'npm:@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

interface ActivationRequest {
  onecampusId?: string
  email?: string
  password?: string
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405)

  try {
    const { onecampusId, email, password } = await request.json() as ActivationRequest
    const normalizedOnecampusId = onecampusId?.trim()
    const normalizedEmail = email?.trim().toLowerCase()
    if (!normalizedOnecampusId || !normalizedEmail || !password) return json({ error: 'OneCampus ID, school email, and password are required.' }, 400)
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) return json({ error: 'Password must be at least 8 characters and contain uppercase, lowercase, and a number.' }, 400)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (!supabaseUrl || !serviceRoleKey) return json({ error: 'Activation service is not configured.' }, 500)
    const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { autoRefreshToken: false, persistSession: false } })

    const { data: record, error: recordError } = await admin
      .from('activation_records')
      .select('*')
      .eq('onecampus_user_id', normalizedOnecampusId)
      .ilike('email', normalizedEmail)
      .maybeSingle()
    if (recordError) throw recordError
    if (!record) return json({ error: 'No matching OneCampus record was found. Check your ID and school email.' }, 404)
    if (record.activated_at) return json({ error: 'This account has already been activated. Please sign in.' }, 409)
    if (!record.auth_user_id) return json({ error: 'Your OneCampus record is not ready for activation. Contact an administrator.' }, 409)

    const { error: authError } = await admin.auth.admin.updateUserById(record.auth_user_id, { password, email_confirm: true })
    if (authError) throw authError

    const activatedAt = new Date().toISOString()
    const { error: profileError } = await admin.from('profiles').update({ status: 'active' }).eq('id', record.auth_user_id)
    if (profileError) throw profileError
    const { error: activationError } = await admin.from('activation_records').update({ activated_at: activatedAt }).eq('id', record.id)
    if (activationError) throw activationError

    return json({ message: 'Account activated successfully. Sign in with your school email and new password.' })
  } catch (error) {
    console.error('activate-account failed', error)
    return json({ error: 'Unable to activate the account right now. Please try again.' }, 500)
  }
})