import {createClient} from 'npm:@supabase/supabase-js@2.47.10'
import {adminContext,cors,reply} from '../_shared/tenant.ts'
Deno.serve(async request=>{
 let headers:Record<string,string>
 try{headers=cors(request)}catch{return new Response('Origen no autorizado',{status:403})}
 if(request.method==='OPTIONS')return new Response(null,{status:204,headers})
 if(request.method!=='POST')return reply(headers,405,{error:'Método no permitido'})
 let accountCreated=false
 try{
  const {caller,service,actor,organization,url,anon}=await adminContext(request)
  const body=await request.json()
  const name=String(body.full_name||'').trim(),email=String(body.email||'').trim().toLowerCase(),password=String(body.password||'')
  const whatsapp=body.whatsapp||null,role=body.role_id||null
  if(!name||name.length>150||!email||email.length>254||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||password.length<6||password.length>1024)throw new Error('Revisa los datos del empleado')
  if(whatsapp && !/^\+?[0-9]{7,15}$/.test(whatsapp))throw new Error('WhatsApp no válido')
  const roles=await caller.rpc('work_roles_overview')
  if(roles.error || role && !roles.data.roles.some((item:{id:string;active:boolean})=>item.id===role&&item.active))throw new Error('Rol no disponible')
  const capacity=await caller.rpc('work_organization_capacity')
  if(capacity.error)throw new Error('No se pudo comprobar el límite de usuarios')
  if(!capacity.data?.can_add)throw new Error(`La empresa ha alcanzado su límite de ${capacity.data?.limit||30} usuarios`)
  const exists=await service.rpc('mt_identity_email_exists',{p_email:email})
  if(exists.error)throw new Error('No se pudo comprobar el correo')
  if(exists.data)throw new Error('Ese correo ya tiene una cuenta. No se modificó su identidad')
  const nonce=crypto.randomUUID()
  const signup=createClient(url,anon,{auth:{persistSession:false,autoRefreshToken:false,detectSessionInUrl:false}})
  const created=await signup.auth.signUp({email,password,options:{data:{full_name:name,ase_onboarding_nonce:nonce}}})
  if(created.error||!created.data.user?.id)throw new Error('No se pudo crear la cuenta de acceso')
  const verified=await service.auth.admin.getUserById(created.data.user.id)
  if(verified.error||verified.data.user?.user_metadata?.ase_onboarding_nonce!==nonce)throw new Error('No se confirmó una cuenta nueva')
  accountCreated=true
  const saved=await service.rpc('mt_attach_created_employee',{p_actor:actor,p_org:organization,p_user:created.data.user.id,p_nonce:nonce,p_name:name,p_whatsapp:whatsapp,p_role:role})
  if(saved.error)throw new Error('No se confirmó el perfil del empleado')
  return reply(headers,200,{success:true,employee:saved.data,confirmationRequired:!created.data.user.email_confirmed_at&&!created.data.session})
 }catch(error){return reply(headers,accountCreated?409:403,{error:accountCreated?'La cuenta se creó pero no se confirmó su pertenencia. No repitas el alta; requiere revisión.':error.message,code:accountCreated?'EMPLOYEE_PROFILE_INCOMPLETE':'EMPLOYEE_CREATE_REJECTED'})}
})
