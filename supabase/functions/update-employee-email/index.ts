import {adminContext,cors,reply} from '../_shared/tenant.ts'
Deno.serve(async request=>{
 let headers:Record<string,string>
 try{headers=cors(request)}catch{return new Response('Origen no autorizado',{status:403})}
 if(request.method==='OPTIONS')return new Response(null,{status:204,headers})
 if(request.method!=='POST')return reply(headers,405,{error:'Método no permitido'})
 let service,grantId
 try{
  const context=await adminContext(request)
  service=context.service
  const body=await request.json()
  const reserved=await context.caller.rpc('mt_prepare_email_change',{p_user:body.userId,p_email:String(body.email||'').trim().toLowerCase()})
  if(reserved.error)throw new Error(reserved.error.message)
  grantId=reserved.data
  const target=await service.rpc('mt_email_change_grant',{p_id:grantId})
  if(target.error)throw new Error('Solicitud no disponible')
  const changed=await service.auth.admin.updateUserById(target.data.user_id,{email:target.data.email})
  if(changed.error||changed.data.user?.email?.toLowerCase()!==target.data.email)throw new Error('No se confirmó el cambio de correo')
  return reply(headers,200,{success:true})
 }catch(error){return reply(headers,403,{error:error.message||'No se pudo cambiar el correo'})}
 finally{if(service&&grantId)await service.rpc('mt_finish_email_change',{p_id:grantId})}
})
