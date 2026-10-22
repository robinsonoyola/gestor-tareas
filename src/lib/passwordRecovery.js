import {tenantMode} from './organizationScope'
import { createClient } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'

export async function requestPasswordReset(email) {
  const normalizedEmail = String(email || '').trim().toLowerCase()
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail) || normalizedEmail.length > 254) {
    throw new Error('Introduce un email válido.')
  }
  const redirectTo = new URL('/reset-password', window.location.origin).href
  const { error } = await supabase.auth.resetPasswordForEmail(normalizedEmail, { redirectTo })
  if (error) throw error
}

export async function requestEmployeePasswordReset(employeeId) {
  if(tenantMode()){
    const {data:email,error}=await supabase.rpc('mt_employee_reset_target',{p_user:employeeId})
    if(error||!email)throw new Error('No se pudo comprobar el empleado en esta empresa.')
    await requestPasswordReset(email)
    return email
  }

  const { data: identity, error: authError } = await supabase.auth.getUser()
  if (authError || !identity?.user) throw new Error('Inicia sesión como administrador.')
  const { data: actor, error: actorError } = await supabase.from('users')
    .select('is_admin').eq('id', identity.user.id).single()
  if (actorError || actor?.is_admin !== true) throw new Error('Solo administradores pueden usar esta opción.')
  const { data: employee, error: employeeError } = await supabase.from('users')
    .select('id, email, is_admin').eq('id', employeeId).single()
  if (employeeError || !employee?.email || employee.is_admin !== false) {
    throw new Error('No se pudo comprobar el empleado y su email guardado.')
  }
  await requestPasswordReset(employee.email)
  return employee.email
}

export function recoveryCredentials(href) {
  const url = new URL(href)
  const hash = new URLSearchParams(url.hash.slice(1))
  if (url.searchParams.has('error') || hash.has('error') || hash.has('error_code')) {
    throw new Error('El enlace no es válido o ha expirado. Solicita uno nuevo.')
  }
  if (url.searchParams.get('type') === 'recovery' && url.searchParams.get('token_hash')) {
    return { tokenHash: url.searchParams.get('token_hash') }
  }
  if (hash.get('type') === 'recovery' && hash.get('access_token') && hash.get('refresh_token')) {
    return { accessToken: hash.get('access_token'), refreshToken: hash.get('refresh_token') }
  }
  throw new Error('Abre el enlace completo del correo de recuperación. Esta página por sí sola no permite cambiar la contraseña.')
}

export async function initializePasswordRecovery(href) {
  const credentials = recoveryCredentials(href)
  const client = createClient(import.meta.env.VITE_SUPABASE_URL, import.meta.env.VITE_SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false,
      storageKey: `password-recovery-${crypto.randomUUID()}` }
  })
  const result = credentials.tokenHash
    ? await client.auth.verifyOtp({ token_hash: credentials.tokenHash, type: 'recovery' })
    : await client.auth.setSession({ access_token: credentials.accessToken, refresh_token: credentials.refreshToken })
  if (result.error || !result.data?.session || !result.data?.user) {
    throw new Error('El enlace no es válido o ha expirado. Solicita uno nuevo.')
  }
  return { client, user: result.data.user }
}

export function validateRecoveryPassword(password, confirmation) {
  if (password.length < 8) throw new Error('Usa una contraseña de al menos 8 caracteres.')
  if (password !== confirmation) throw new Error('Las contraseñas no coinciden.')
}
