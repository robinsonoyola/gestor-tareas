import {PGlite} from '@electric-sql/pglite'
import fs from 'node:fs'
import assert from 'node:assert/strict'
import {fileURLToPath} from 'node:url'
const root=fileURLToPath(new URL('../../',import.meta.url)),db=new PGlite(),results=[]
const id=n=>`00000000-0000-0000-0000-${String(n).padStart(12,'0')}`
const [ADMIN,WORKER,TASK,BADMIN]=[1,2,10,3].map(id)
const ok=(name,pass)=>{assert(pass,name);results.push(name)}
async function request(actor,org,sql){await db.exec('BEGIN');try{await db.exec('SET LOCAL ROLE authenticated');await db.query(`SELECT set_config('request.jwt.claim.sub',$1,true),set_config('request.jwt.claim.role','authenticated',true),set_config('request.headers',$2,true)`,[actor,JSON.stringify({'x-ase-organization-id':org})]);const value=await db.query(sql);await db.exec('COMMIT');return value.rows}catch(error){await db.exec('ROLLBACK');throw error}}
async function denied(name,actor,org,sql){try{await request(actor,org,sql);ok(name,false)}catch(error){ok(name,['42501','23503','23505','P0001'].includes(error.code))}}
try{
 await db.exec(fs.readFileSync(root+'supabase/tests/bootstrap.sql','utf8'))
 await db.exec(fs.readFileSync(root+'supabase/baseline/20261022_installed_public.sql','utf8'))
 await db.exec(fs.readFileSync(root+'supabase/tests/storage-baseline.sql','utf8'))
 await db.exec(`INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('${ADMIN}','admin@example.test','{"full_name":"Admin"}'),('${WORKER}','worker@example.test','{"full_name":"Worker"}');UPDATE public.users SET is_admin=true WHERE id='${ADMIN}';INSERT INTO public.work_settings VALUES(true,false);INSERT INTO public.tasks(id,title,status,schedule_type) VALUES('${TASK}','Tarea A','pending','daily');INSERT INTO public.task_assignments(task_id,user_id) VALUES('${TASK}','${WORKER}');`)
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261022000100_core_multitenancy_a1.sql','utf8'))
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261022000300_hosted_auth_identity.sql','utf8'))
 const org=(await db.query(`SELECT organization_id id FROM public.organization_memberships WHERE user_id='${ADMIN}'`)).rows[0].id
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261027000400_task_projects.sql','utf8'))
 await db.exec(fs.readFileSync(root+'supabase/migrations/20261027000500_project_milestones.sql','utf8'))
 const project=(await request(ADMIN,org,`SELECT public.work_save_project(NULL,'Apertura local','Preparación completa','active',DATE '2026-11-01',DATE '2026-11-30') v`))[0].v
 ok('admin creates project',!!project)
 await request(ADMIN,org,`SELECT public.work_set_task_project('${TASK}','${project}')`)
 const overview=(await request(ADMIN,org,`SELECT public.work_projects_overview() v`))[0].v
 ok('overview returns linked activity',overview.projects.length===1&&overview.projects[0].task_ids[0]===TASK)
 const milestone=(await request(ADMIN,org,`SELECT public.work_save_project_milestone(NULL,'${project}','Entrega inicial',DATE '2026-11-10',false) v`))[0].v
 ok('admin creates project milestone',!!milestone)
 const withMilestone=(await request(ADMIN,org,`SELECT public.work_projects_overview() v`))[0].v
 ok('overview returns project milestone',withMilestone.projects[0].milestones[0].title==='Entrega inicial')
 await request(ADMIN,org,`SELECT public.work_save_project_milestone('${milestone}','${project}','Entrega inicial',DATE '2026-11-10',true)`)
 ok('completed milestone keeps its completion time',(await db.query(`SELECT completed_at IS NOT NULL v FROM public.work_project_milestones WHERE id='${milestone}'`)).rows[0].v===true)
 await denied('employee cannot create projects',WORKER,org,`SELECT public.work_save_project(NULL,'No permitido',NULL,'active',NULL,NULL)`)
 await denied('employee cannot create milestones',WORKER,org,`SELECT public.work_save_project_milestone(NULL,'${project}','No permitido',NULL,false)`)
 await denied('employee cannot change project assignment',WORKER,org,`SELECT public.work_set_task_project('${TASK}',NULL)`)
 await db.exec(`INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('${BADMIN}','badmin@example.test','{"full_name":"B Admin"}');INSERT INTO public.organizations(id,name,slug)VALUES('${id(900)}','Empresa B','empresa-b');INSERT INTO public.organization_memberships(organization_id,user_id,role,status,full_name)VALUES('${id(900)}','${BADMIN}','admin','active','B Admin');`)
 await denied('another company cannot link a task from this project',BADMIN,id(900),`SELECT public.work_set_task_project('${TASK}','${project}')`)
 ok('tables are not exposed directly to authenticated',(await db.query(`SELECT has_table_privilege('authenticated','public.work_projects','SELECT') v`)).rows[0].v===false)
 ok('milestones are not exposed directly to authenticated',(await db.query(`SELECT has_table_privilege('authenticated','public.work_project_milestones','SELECT') v`)).rows[0].v===false)
 await request(ADMIN,org,`SELECT public.work_delete_project_milestone('${milestone}')`)
 ok('admin deletes milestone',(await db.query(`SELECT count(*)::int v FROM public.work_project_milestones WHERE id='${milestone}'`)).rows[0].v===0)
 await request(ADMIN,org,`SELECT public.work_set_task_project('${TASK}',NULL)`)
 ok('unlink keeps task and project',(await db.query(`SELECT (SELECT count(*) FROM public.tasks WHERE id='${TASK}')=1 AND (SELECT count(*) FROM public.work_projects WHERE id='${project}')=1 v`)).rows[0].v===true)
 console.log(`${results.length} comprobaciones de proyectos correctas`)
}finally{await db.close()}
