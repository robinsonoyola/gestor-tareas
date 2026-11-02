import { supabase } from '@/lib/supabase'
import { normalizeWhatsApp } from '@/lib/whatsapp'

export async function createEmployeeAccount(form) {
  const fullName = form.full_name.trim()
  const email = form.email.trim().toLowerCase()
  const whatsapp = normalizeWhatsApp(form.whatsapp)
  if (!fullName || !email || !form.password || form.password.length < 6) {
    throw new Error('Completa nombre, email y una contraseña de al menos 6 caracteres.')
  }

  const {data,error}=await supabase.functions.invoke('create-employee',{body:{...form,full_name:fullName,email,whatsapp}})
  if(error || !data?.success){
    const failure=new Error(data?.error || 'No se pudo confirmar el alta del empleado. Revisa el servicio antes de repetirla.')
    failure.code=data?.code || 'EMPLOYEE_CREATE_UNCONFIRMED'
    throw failure
  }
  return data
}
