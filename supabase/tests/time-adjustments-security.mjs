import {PGlite} from '@electric-sql/pglite'
import fs from 'node:fs'
import assert from 'node:assert/strict'
import {fileURLToPath} from 'node:url'

const root=fileURLToPath(new URL('../../',import.meta.url))
const db=new PGlite(),results=[]
const id=n=>`00000000-0000-0000-0000-${String(n).padStart(12,'0')}`
const [ADMIN,WORKER,TASK,REQUEST1,REQUEST2,OPEN]=[1,2,10,101,102,103].map(id)
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
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261026000200_admin_time_adjustments.sql','utf8'))

 const created=(await request(ADMIN,org,`SELECT public.work_admin_adjust_time(NULL,'${WORKER}','${TASK}',now()-interval '3 hours',now()-interval '2 hours','Fichaje olvidado verificado','${REQUEST1}') v`))[0].v.id
 ok('admin creates closed correction record',!!created)
 ok('created duration is one hour',(await db.query(`SELECT extract(epoch FROM checkout_time-checkin_time)::int seconds FROM public.checkins WHERE id='${created}'`)).rows[0].seconds===3600)
 ok('creation has immutable audit entry',(await db.query(`SELECT count(*)::int n FROM public.work_time_adjustments WHERE checkin_id='${created}' AND action='create' AND previous_values IS NULL`)).rows[0].n===1)
 await request(ADMIN,org,`SELECT public.work_admin_adjust_time(NULL,'${WORKER}','${TASK}',now()-interval '3 hours',now()-interval '2 hours','Repetición de solicitud','${REQUEST1}')`)
 ok('same request is idempotent',(await db.query(`SELECT count(*)::int n FROM public.work_time_adjustments WHERE request_id='${REQUEST1}'`)).rows[0].n===1)
 await denied('employee cannot create adjustments',WORKER,org,`SELECT public.work_admin_adjust_time(NULL,'${WORKER}','${TASK}',now()-interval '5 hours',now()-interval '4 hours','Intento no autorizado','${REQUEST2}')`)
 await denied('overlapping record is rejected',ADMIN,org,`SELECT public.work_admin_adjust_time(NULL,'${WORKER}','${TASK}',now()-interval '150 minutes',now()-interval '90 minutes','Solapamiento intencionado','${REQUEST2}')`)
 await request(ADMIN,org,`SELECT public.work_admin_adjust_time('${created}','${WORKER}','${TASK}',now()-interval '4 hours',now()-interval '2 hours','Corrección confirmada por encargado','${REQUEST2}')`)
 ok('correction updates official checkin',(await db.query(`SELECT extract(epoch FROM checkout_time-checkin_time)::int seconds FROM public.checkins WHERE id='${created}'`)).rows[0].seconds===7200)
 ok('correction preserves before and after',(await db.query(`SELECT count(*)::int n FROM public.work_time_adjustments WHERE checkin_id='${created}' AND action='correct' AND previous_values ? 'start' AND new_values ? 'end'`)).rows[0].n===1)
 const history=(await request(ADMIN,org,`SELECT public.work_time_adjustment_history('${created}') v`))[0].v
 ok('authorized history returns both events',history.length===2)
 await db.exec(`INSERT INTO public.checkins(id,organization_id,task_id,user_id,checkin_method,checkin_time) VALUES('${OPEN}','${org}','${TASK}','${WORKER}','manual',now()-interval '10 minutes')`)
 await denied('open checkin cannot be corrected',ADMIN,org,`SELECT public.work_admin_adjust_time('${OPEN}','${WORKER}','${TASK}',now()-interval '20 minutes',now()-interval '5 minutes','Intento sobre registro abierto','${id(104)}')`)
 await denied('future end is rejected',ADMIN,org,`SELECT public.work_admin_adjust_time(NULL,'${WORKER}','${TASK}',now(),now()+interval '1 hour','Hora futura no permitida','${id(105)}')`)
 console.log(`${results.length} comprobaciones de corrección de tiempo correctas`)
}finally{await db.close()}
