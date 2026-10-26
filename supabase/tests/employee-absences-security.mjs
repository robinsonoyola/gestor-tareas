import {PGlite} from '@electric-sql/pglite'
import fs from 'node:fs'
import assert from 'node:assert/strict'
import {fileURLToPath} from 'node:url'

const root=fileURLToPath(new URL('../../',import.meta.url)),db=new PGlite(),results=[]
const id=n=>`00000000-0000-0000-0000-${String(n).padStart(12,'0')}`
const [ADMIN,WORKER,TASK,BADMIN,BWORKER]=[1,2,10,3,4].map(id)
const ok=(name,pass)=>{assert(pass,name);results.push(name)}
async function request(actor,org,sql){await db.exec('BEGIN');try{await db.exec('SET LOCAL ROLE authenticated');await db.query(`SELECT set_config('request.jwt.claim.sub',$1,true),set_config('request.jwt.claim.role','authenticated',true),set_config('request.headers',$2,true)`,[actor,JSON.stringify({'x-ase-organization-id':org})]);const value=await db.query(sql);await db.exec('COMMIT');return value.rows}catch(error){await db.exec('ROLLBACK');throw error}}
async function denied(name,actor,org,sql){try{await request(actor,org,sql);ok(name,false)}catch(error){ok(name,['42501','23503','23514','P0001'].includes(error.code))}}

try{
 await db.exec(fs.readFileSync(root+'supabase/tests/bootstrap.sql','utf8'))
 await db.exec(fs.readFileSync(root+'supabase/baseline/20261022_installed_public.sql','utf8'))
 await db.exec(fs.readFileSync(root+'supabase/tests/storage-baseline.sql','utf8'))
 await db.exec(`INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('${ADMIN}','admin@example.test','{"full_name":"Admin"}'),('${WORKER}','worker@example.test','{"full_name":"Worker"}');UPDATE public.users SET is_admin=true WHERE id='${ADMIN}';INSERT INTO public.work_settings VALUES(true,false);INSERT INTO public.tasks(id,title,status,schedule_type) VALUES('${TASK}','Tarea','pending','daily');INSERT INTO public.task_assignments(task_id,user_id) VALUES('${TASK}','${WORKER}');`)
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261022000100_core_multitenancy_a1.sql','utf8'))
 const org=(await db.query(`SELECT organization_id id FROM public.organization_memberships WHERE user_id='${ADMIN}'`)).rows[0].id
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261026000300_employee_absences.sql','utf8'))
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261026000400_employee_own_absences.sql','utf8'))
 const future=(await request(ADMIN,org,`SELECT public.work_save_absence(NULL,'${WORKER}','vacation',public.work_today()+1,public.work_today()+3,'Vacaciones aprobadas') v`))[0].v
 ok('admin creates employee absence',!!future)
 const directory=(await request(ADMIN,org,`SELECT public.work_absence_directory(public.work_today(),public.work_today()+10) v`))[0].v
 ok('directory returns people and absence',directory.people.length===1&&directory.absences.length===1&&directory.absences[0].employee==='Worker')
 const personal=(await request(WORKER,org,`SELECT public.work_my_absences(NULL,NULL) v`))[0].v
 ok('employee sees own absence only',personal.items.length===1&&personal.items[0].id===future)
 await denied('employee cannot create absence',WORKER,org,`SELECT public.work_save_absence(NULL,'${WORKER}','leave',public.work_today()+5,public.work_today()+5,NULL)`)
 await denied('overlapping absence is rejected',ADMIN,org,`SELECT public.work_save_absence(NULL,'${WORKER}','leave',public.work_today()+3,public.work_today()+4,NULL)`)
 await denied('planning during absence is rejected',ADMIN,org,`SELECT public.work_save_plan('${WORKER}',public.work_today()+2,ARRAY['${TASK}']::uuid[])`)
 const today=(await request(ADMIN,org,`SELECT public.work_save_absence(NULL,'${WORKER}','unavailable',public.work_today(),public.work_today(),'No disponible') v`))[0].v
 await denied('open checkin during absence is rejected',WORKER,org,`INSERT INTO public.checkins(task_id,user_id,checkin_method,checkin_time) VALUES('${TASK}','${WORKER}','manual',now())`)
 await db.exec(`INSERT INTO public.checkins(organization_id,task_id,user_id,checkin_method,checkin_time,checkout_time) VALUES('${org}','${TASK}','${WORKER}','manual',now()-interval '2 hours',now()-interval '1 hour')`)
 ok('closed historical record remains possible',(await db.query(`SELECT count(*)::int n FROM public.checkins WHERE organization_id='${org}' AND user_id='${WORKER}' AND checkout_time IS NOT NULL`)).rows[0].n===1)
 await request(ADMIN,org,`SELECT public.work_cancel_absence('${today}')`)
 ok('cancellation preserves history',(await db.query(`SELECT cancelled_at IS NOT NULL v FROM public.work_employee_absences WHERE id='${today}'`)).rows[0].v===true)
 await request(ADMIN,org,`SELECT public.work_cancel_absence('${future}')`)
 await request(ADMIN,org,`SELECT public.work_save_plan('${WORKER}',public.work_today()+2,ARRAY['${TASK}']::uuid[])`)
 ok('planning works after cancellation',(await db.query(`SELECT count(*)::int n FROM public.work_day_plan WHERE organization_id='${org}' AND user_id='${WORKER}'`)).rows[0].n===1)
 await db.exec(`INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('${BADMIN}','badmin@example.test','{"full_name":"B Admin"}'),('${BWORKER}','bworker@example.test','{"full_name":"B Worker"}');INSERT INTO public.organizations(id,name,slug)VALUES('${id(900)}','Empresa B','empresa-b');INSERT INTO public.organization_memberships(organization_id,user_id,role,status,full_name)VALUES('${id(900)}','${BADMIN}','admin','active','B Admin'),('${id(900)}','${BWORKER}','member','active','B Worker');`)
 await denied('another company cannot cancel absence',BADMIN,id(900),`SELECT public.work_cancel_absence('${future}')`)
 ok('migration leaves schema create revoked',(await db.query(`SELECT has_schema_privilege('ase_tenant_executor','public','CREATE') v`)).rows[0].v===false)
 console.log(`${results.length} comprobaciones de ausencias correctas`)
}finally{await db.close()}
