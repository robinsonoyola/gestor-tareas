import {tenantMode} from './organizationScope'
import { createClient } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'
import { taskAttachmentId } from '@/lib/taskAttachments'
import { normalizeWhatsApp } from '@/lib/whatsapp'

export async function createEmployeeAccount(form) {
  const fullName = form.full_name.trim()
  const email = form.email.trim().toLowerCase()
  const whatsapp = normalizeWhatsApp(form.whatsapp)
  if (!fullName || !email || !form.password || form.password.length < 6) {
    throw new Error('Completa nombre, email y una contraseña de al menos 6 caracteres.')
  }

  if(tenantMode()) {
    const {data,error}=await supabase.functions.invoke('create-employee',{body:{...form,full_name:fullName,email,whatsapp}})
    if(error || !data?.success){
      const failure=new Error(data?.error || 'No se pudo confirmar el alta del empleado. Revisa el servicio antes de repetirla.')
      failure.code=data?.code || 'EMPLOYEE_CREATE_UNCONFIRMED'
      throw failure
    }
    return data
  }

  const { data: actorData, error: actorError } = await supabase.auth.getUser()
  if (actorError || !actorData?.user) throw new Error('Inicia sesión como administrador antes de crear empleados.')
  const actorId = actorData.user.id
  const { data: actor, error: permissionError } = await supabase
    .from('users').select('id, is_admin').eq('id', actorId).single()
  if (permissionError || actor?.is_admin !== true) {
    throw new Error('Solo un administrador puede utilizar este formulario.')
  }

  const {data: roleData,error: roleError} = await supabase.rpc('work_roles_overview')
  if (roleError) throw new Error('No se pudieron comprobar los roles. Recarga Empleados antes de crear la cuenta.')
  if (form.role_id && !roleData.roles.some(r=>r.id===form.role_id && r.active)) throw new Error('El rol seleccionado ya no está activo. Selecciona otro.')

  // An independent, memory-only auth client cannot replace the admin session.
  // A unique storage key also prevents cross-tab auth broadcasts to the main client.
  const signupClient = createClient(
    import.meta.env.VITE_SUPABASE_URL,
    import.meta.env.VITE_SUPABASE_ANON_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
        storageKey: `employee-signup-${taskAttachmentId()}`
      }
    }
  )

  let accountCreated = false
  try {
    const { data: created, error: signupError } = await signupClient.auth.signUp({
      email,
      password: form.password,
      options: { data: { full_name: fullName } }
    })
    if (signupError) throw signupError
    if (!created?.user?.id || created.user.identities?.length === 0) {
      throw new Error('No se pudo crear una cuenta nueva. Comprueba si ese email ya está registrado.')
    }
    accountCreated = true

    const { data: current, error: sessionError } = await supabase.auth.getUser()
    if (sessionError || current?.user?.id !== actorId) {
      throw new Error('La sesión administrativa cambió durante el alta.')
    }

    // handle_new_user normally creates this row. Never insert it twice or upsert roles.
    const { data: existing, error: lookupError } = await supabase
      .from('users').select('id, email, is_admin').eq('id', created.user.id).maybeSingle()
    if (lookupError) throw lookupError
    if (existing && (existing.is_admin === true || existing.email?.toLowerCase() !== email)) {
      throw new Error('El perfil existente no coincide con el empleado solicitado.')
    }
    const fields = { full_name: fullName, whatsapp }
    const write = existing
      ? supabase.from('users').update(fields).eq('id', created.user.id)
      : supabase.from('users').insert({ id: created.user.id, email, ...fields, is_admin: false })
    const { data: saved, error: profileError } = await write.select('id, full_name, whatsapp').single()
    if (profileError) throw profileError
    if (saved?.id !== created.user.id || saved.full_name !== fullName || saved.whatsapp !== whatsapp) {
      throw new Error('No se confirmó el guardado completo del perfil.')
    }
    const {data: roleSaved,error: roleSaveError} = await supabase.rpc('work_save_employee_profile', {p_user:created.user.id,p_name:fullName,p_whatsapp:whatsapp,p_role:form.role_id || null})
    if (roleSaveError || roleSaved?.id !== created.user.id || (roleSaved?.role_id || null)!==(form.role_id || null)) throw new Error('No se confirmó el rol del empleado.')
    return { employee: saved, confirmationRequired: !created.user.email_confirmed_at && !created.session }
  } catch (error) {
    if (accountCreated) {
      const partial = new Error('La cuenta de acceso se creó, pero no se confirmó el perfil completo. No repitas el alta: recarga Empleados y revisa esa cuenta.')
      partial.code = 'EMPLOYEE_PROFILE_INCOMPLETE'
      throw partial
    }
    throw error
  } finally {
    // The temporary session is never persisted or assigned to the main client.
    signupClient.auth.stopAutoRefresh()
  }
}
