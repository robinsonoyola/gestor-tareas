import {createClient} from 'npm:@supabase/supabase-js@2.47.10'

export function cors(request:Request){
 const origin=request.headers.get('origin')
 const allowed=(Deno.env.get('ALLOWED_ORIGINS')||'').split(',').map(value=>value.trim()).filter(Boolean)
 if(origin && !allowed.includes(origin))throw new Error('Origen no autorizado')
 return {'Access-Control-Allow-Origin':origin||'null','Vary':'Origin',
 'Access-Control-Allow-Headers':'authorization,apikey,content-type,x-client-info,x-ase-organization-id',
 'Access-Control-Allow-Methods':'POST, OPTIONS','Content-Type':'application/json'}
}
export async function adminContext(request:Request){
 const url=Deno.env.get('SUPABASE_URL')!
 const anon=Deno.env.get('SUPABASE_ANON_KEY')!
 const key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
 if(!url||!anon||!key)throw new Error('Configuración incompleta del servicio')
 const authorization=request.headers.get('authorization')||''
 if(!authorization.startsWith('Bearer '))throw new Error('Inicia sesión')
 const headers:Record<string,string>={Authorization:authorization}
 const organization=request.headers.get('x-ase-organization-id')
 if(organization)headers['x-ase-organization-id']=organization
 const caller=createClient(url,anon,{global:{headers},auth:{persistSession:false,autoRefreshToken:false,detectSessionInUrl:false}})
 const {data:identity,error:identityError}=await caller.auth.getUser(authorization.slice(7))
 if(identityError||!identity.user)throw new Error('Sesión no válida')
 const {data:context,error:contextError}=await caller.rpc('mt_context')
 if(contextError||!context?.active_organization_id||!context.profile?.is_admin)throw new Error('No tienes permiso de administración en esta empresa')
 const service=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false,detectSessionInUrl:false}})
 return {caller,service,actor:identity.user.id,organization:context.active_organization_id,url,anon}
}
export function reply(headers:Record<string,string>,status:number,body:unknown){return new Response(JSON.stringify(body),{status,headers})}
