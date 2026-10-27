import {PGlite} from '@electric-sql/pglite'
import fs from 'node:fs'
import assert from 'node:assert/strict'
import {fileURLToPath} from 'node:url'

const root=fileURLToPath(new URL('../../',import.meta.url)),db=new PGlite(),results=[]
const id=n=>`00000000-0000-0000-0000-${String(n).padStart(12,'0')}`
const [ADMIN,WORKER,NEW_USER,EXTRA_USER]=[1,2,3,4].map(id)
const ok=(name,pass)=>{assert(pass,name);results.push(name)}
async function request(actor,org,sql){await db.exec('BEGIN');try{await db.exec('SET LOCAL ROLE authenticated');await db.query(`SELECT set_config('request.jwt.claim.sub',$1,true),set_config('request.jwt.claim.role','authenticated',true),set_config('request.headers',$2,true)`,[actor,JSON.stringify({'x-ase-organization-id':org})]);const value=await db.query(sql);await db.exec('COMMIT');return value.rows}catch(error){await db.exec('ROLLBACK');throw error}}

try{
 await db.exec(fs.readFileSync(root+'supabase/tests/bootstrap.sql','utf8'))
 await db.exec(fs.readFileSync(root+'supabase/baseline/20261022_installed_public.sql','utf8'))
 await db.exec(fs.readFileSync(root+'supabase/tests/storage-baseline.sql','utf8'))
 await db.exec(`INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('${ADMIN}','admin@example.test','{"full_name":"Admin"}'),('${WORKER}','worker@example.test','{"full_name":"Worker"}');UPDATE public.users SET is_admin=true WHERE id='${ADMIN}';INSERT INTO public.work_settings VALUES(true,false);`)
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261022000100_core_multitenancy_a1.sql','utf8'))
 const org=(await db.query(`SELECT organization_id id FROM public.organization_memberships WHERE user_id='${ADMIN}'`)).rows[0].id
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261027000200_organization_user_capacity.sql','utf8'))
 await db.exec(`UPDATE public.organizations SET user_limit=2 WHERE id='${org}'`)
 const capacity=(await request(ADMIN,org,`SELECT public.work_organization_capacity() v`))[0].v
 ok('capacity includes administrators and employees',capacity.used===2&&capacity.limit===2&&capacity.available===0&&capacity.can_add===false)
 let employeeDenied=false
 try{await request(WORKER,org,`SELECT public.work_organization_capacity()`)}catch(error){employeeDenied=error.code==='42501'}
 ok('employees cannot inspect contracted capacity',employeeDenied)

 await db.exec(`INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('${NEW_USER}','new@example.test','{"full_name":"New","ase_onboarding_nonce":"12345678901234567890123456789012"}')`)
 let fullDenied=false
 try{await db.query(`SELECT public.mt_attach_created_employee('${ADMIN}','${org}','${NEW_USER}','12345678901234567890123456789012','New',NULL,NULL)`)}catch(error){fullDenied=error.code==='P0001'}
 ok('database rejects an employee above the organization limit',fullDenied)
 ok('rejected employee has no membership',(await db.query(`SELECT count(*)::int n FROM public.organization_memberships WHERE organization_id='${org}' AND user_id='${NEW_USER}'`)).rows[0].n===0)

 await db.exec(`UPDATE public.organization_memberships SET status='disabled' WHERE organization_id='${org}' AND user_id='${WORKER}';INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('${EXTRA_USER}','extra@example.test','{"full_name":"Extra","ase_onboarding_nonce":"abcdefghijklmnopqrstuvwxyz123456"}')`)
 const attached=(await db.query(`SELECT public.mt_attach_created_employee('${ADMIN}','${org}','${EXTRA_USER}','abcdefghijklmnopqrstuvwxyz123456','Extra',NULL,NULL) v`)).rows[0].v
 ok('a released place can be assigned again',attached.id===EXTRA_USER)
 const finalCapacity=(await request(ADMIN,org,`SELECT public.work_organization_capacity() v`))[0].v
 ok('capacity returns to the contracted limit',finalCapacity.used===2&&finalCapacity.can_add===false)
 ok('capacity function is not exposed to anonymous users',(await db.query(`SELECT has_function_privilege('anon','public.work_organization_capacity()','EXECUTE') v`)).rows[0].v===false)
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261027000300_remove_organization_user_capacity.sql','utf8'))
 ok('removal migration drops the commercial limit column',(await db.query(`SELECT count(*)::int n FROM information_schema.columns WHERE table_schema='public' AND table_name='organizations' AND column_name='user_limit'`)).rows[0].n===0)
 ok('removal migration drops the capacity endpoint',(await db.query(`SELECT to_regprocedure('public.work_organization_capacity()') IS NULL v`)).rows[0].v===true)
 const unrestricted=(await db.query(`SELECT public.mt_attach_created_employee('${ADMIN}','${org}','${NEW_USER}','12345678901234567890123456789012','New',NULL,NULL) v`)).rows[0].v
 ok('employee creation is unrestricted again',unrestricted.id===NEW_USER)
 console.log(`${results.length} comprobaciones de límite de usuarios correctas`)
}finally{await db.close()}
