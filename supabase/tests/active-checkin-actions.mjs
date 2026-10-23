import {PGlite} from '@electric-sql/pglite';
import {pgcrypto} from '@electric-sql/pglite/contrib/pgcrypto';
import fs from 'node:fs';import assert from 'node:assert/strict';
const root=new URL('../../',import.meta.url).pathname.replace(/^\/([A-Za-z]:)/,'$1');const db=new PGlite({extensions:{pgcrypto}});const results=[];
const id=n=>`00000000-0000-0000-0000-${String(n).padStart(12,'0')}`;
const [ADMIN,A,BADMIN,B,SHARED,TA,TB]=[1,2,3,4,5,10,20].map(id);
const ok=(name,pass)=>{assert(pass,name);results.push({test:name,expected:'PASS',actual:'PASS'})};
async function request(actor,org,sql,role='authenticated'){
 await db.exec('BEGIN');try{await db.exec(`SET LOCAL ROLE ${role}`);await db.query(`SELECT set_config('request.jwt.claim.sub',$1,true),set_config('request.jwt.claim.role',$2,true),set_config('request.headers',$3,true)`,[actor||'',role,org?JSON.stringify({'x-ase-organization-id':org}):'{}']);const v=await db.query(sql);await db.exec('COMMIT');return v.rows;}catch(e){await db.exec('ROLLBACK');throw e;}}
async function denied(name,actor,org,sql,role='authenticated'){try{const rows=await request(actor,org,sql,role);ok(name,rows.length===0||rows[0]?.n===0||rows[0]?.v===null||Array.isArray(rows[0]?.v)&&rows[0].v.length===0);}catch(e){ok(name,['42501','23503','23514','22023','P0001'].includes(e.code));}}
try{
await db.exec(fs.readFileSync(root+'supabase/tests/bootstrap.sql','utf8'));await db.exec(fs.readFileSync(root+'supabase/baseline/20261022_installed_public.sql','utf8'));await db.exec(fs.readFileSync(root+'supabase/tests/storage-baseline.sql','utf8'));
await db.exec(`INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('${ADMIN}','admina@example.test','{"full_name":"Admin A"}'),('${A}','workera@example.test','{"full_name":"Worker A"}'),('${SHARED}','shared@example.test','{"full_name":"Shared"}');UPDATE public.users SET is_admin=true WHERE id='${ADMIN}';INSERT INTO public.work_settings VALUES(true,false);INSERT INTO public.tasks(id,title,status,schedule_type) VALUES('${TA}','Legacy A','pending','daily');INSERT INTO public.task_assignments(task_id,user_id) VALUES('${TA}','${A}');`);
const legacyRole=id(100),legacyCard=id(101),legacyStation=id(102);
await db.exec(`INSERT INTO public.work_roles(id,name) VALUES('${legacyRole}','Legacy role');INSERT INTO public.work_employee_roles(user_id,role_id) VALUES('${A}','${legacyRole}');INSERT INTO public.work_day_plan(user_id,task_id,work_date,priority) VALUES('${A}','${TA}',public.work_today(),1);INSERT INTO public.work_employee_cards(id,user_id,label,token_hash,active) VALUES('${legacyCard}','${A}','Old card',public.work_hash('ASE-OLD-CARD'),false);INSERT INTO public.work_employee_card_keys(card_id,token) VALUES('${legacyCard}','ASE-OLD-CARD');INSERT INTO public.work_stations(id,name,token_hash,active) VALUES('${legacyStation}','Old station',public.work_hash('ASE-OLD-STATION'),false);INSERT INTO public.work_station_keys(station_id,token) VALUES('${legacyStation}','ASE-OLD-STATION');INSERT INTO public.work_station_tickets(station_id,card_id,user_id,expected_action,expires_at) VALUES('${legacyStation}','${legacyCard}','${A}','none',now()-interval '1 day');INSERT INTO public.nfc_cards(card_uid,card_name,task_id) VALUES('OLD-UID','Old tag','${TA}');INSERT INTO public.checkins(task_id,user_id,checkin_time,checkout_time,checkin_method) VALUES('${TA}','${A}',now()-interval '1 day',now()-interval '23 hours','manual');INSERT INTO public.task_comments(task_id,user_id,comment) VALUES('${TA}','${A}','Legacy comment');INSERT INTO public.task_access_codes(task_id,access_code,created_by) VALUES('${TA}','TASK-LEGACY','${ADMIN}');`);
const business=['tasks','task_assignments','checkins','task_comments','task_access_codes','task_checkin_config','nfc_cards','work_day_plan','work_employee_cards','work_employee_card_keys','work_stations','work_station_keys','work_station_tickets','work_roles','work_employee_roles','work_settings'];
const snapshot={};for(const table of business)snapshot[table]=(await db.query(`SELECT jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text) v FROM public.${table} t`)).rows[0].v;
await db.exec(fs.readFileSync(root+'supabase/migrations/20261022000100_core_multitenancy_a1.sql','utf8'));
for(const table of business){const after=(await db.query(`SELECT jsonb_agg(to_jsonb(t)-'organization_id' ORDER BY (to_jsonb(t)-'organization_id')::text) v FROM public.${table} t`)).rows[0].v;ok('backfill preserves every legacy field in '+table,JSON.stringify(after)===JSON.stringify(snapshot[table]));}
const OA=(await db.query(`SELECT id FROM public.organizations WHERE slug='ase-work'`)).rows[0].id;
ok('legacy task retained',(await db.query(`SELECT count(*)::int n FROM public.tasks WHERE id='${TA}' AND organization_id='${OA}'`)).rows[0].n===1);
ok('legacy role retained as membership',(await request(ADMIN,OA,'SELECT public.sec06_is_admin() v'))[0].v===true);
ok('global admin retired',(await db.query('SELECT count(*)::int n FROM public.users WHERE is_admin IS TRUE')).rows[0].n===0);
await db.exec(`INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('${BADMIN}','adminb@example.test','{"full_name":"Admin B"}'),('${B}','workerb@example.test','{"full_name":"Worker B"}');`);
const OB=(await request(BADMIN,null,`SELECT public.mt_create_organization('Company B','company-b') v`))[0].v;
await db.query(`INSERT INTO public.organization_memberships(organization_id,user_id,role,full_name) VALUES($1,$2,'member','Worker B'),($1,$3,'member','Shared B')`,[OB,B,SHARED]);
await request(BADMIN,OB,`INSERT INTO public.tasks(id,title,status,schedule_type) VALUES('${TB}','Secret B','pending','daily')`);
await request(BADMIN,OB,`INSERT INTO public.task_assignments(task_id,user_id) VALUES('${TB}','${B}')`);

await db.exec(`CREATE SCHEMA extensions; CREATE EXTENSION pgcrypto WITH SCHEMA extensions; GRANT USAGE ON SCHEMA extensions TO ase_tenant_executor;`);
const migration='supabase/migrations/20261022000200_work_usability.sql';
await db.exec(fs.readFileSync(root+migration,'utf8'));
await db.exec('REVOKE USAGE ON SCHEMA auth FROM ase_tenant_executor;');
await db.exec(fs.readFileSync(root+'supabase/migrations/20261022000300_hosted_auth_identity.sql','utf8'));
await db.exec(fs.readFileSync(root+'supabase/migrations/20261022000400_station_auto_code.sql','utf8'));
// Hosted postgres is not superuser: exercise ALTER OWNER with the same restriction.
await db.exec('CREATE ROLE station_migration_installer NOLOGIN NOSUPERUSER; GRANT ase_tenant_executor TO station_migration_installer; ALTER SCHEMA public OWNER TO station_migration_installer; SET ROLE station_migration_installer;');
await db.exec(fs.readFileSync(root+'supabase/migrations/20261023000100_manual_station_key.sql','utf8'));
await db.exec('RESET ROLE; ALTER SCHEMA public OWNER TO postgres;');
ok('station migration leaves executor without schema CREATE',(await db.query("SELECT has_schema_privilege('ase_tenant_executor','public','CREATE') v")).rows[0].v===false);


await db.exec('ALTER SCHEMA public OWNER TO station_migration_installer; SET ROLE station_migration_installer;');
await db.exec(fs.readFileSync(root+'supabase/migrations/20261023000200_confirmed_task_nfc.sql','utf8'));
await db.exec('RESET ROLE; ALTER SCHEMA public OWNER TO postgres;');
const UID='04:A1:B2:C3:D4:E5:F6',CARD=id(701),CARD2=id(702);
await db.exec(`INSERT INTO public.nfc_cards(id,organization_id,card_uid,card_name,task_id,is_active) VALUES('${CARD}','${OA}','${UID}','Task tag','${TA}',true),('${CARD2}','${OA}','04:A1:B2:C3:D4:E5:F7','Second tag','${TA}',true);UPDATE public.task_checkin_config SET nfc_enabled=true WHERE task_id='${TA}';INSERT INTO public.task_checkin_config(organization_id,task_id,nfc_enabled) SELECT '${OA}','${TA}',true WHERE NOT EXISTS(SELECT 1 FROM public.task_checkin_config WHERE task_id='${TA}');`);
const countBefore=(await db.query(`SELECT count(*)::int n FROM public.checkins`)).rows[0].n;
await denied('anonymous task NFC denied',null,null,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkin')`,'anon');
await denied('unassigned actor cannot check in',SHARED,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkin')`);
await denied('foreign company task NFC denied',B,OB,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkin')`);
await denied('unknown card denied',A,OA,`SELECT public.work_task_nfc_checkin('04:00:00:00:00:00:00','${TA}','checkin')`);
await denied('invalid action denied',A,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','toggle')`);
await denied('empty UID denied',A,OA,`SELECT public.work_task_nfc_checkin('','${TA}','checkin')`);
ok('rejected identification has no writes',(await db.query(`SELECT count(*)::int n FROM public.checkins`)).rows[0].n===countBefore);
const started=(await request(A,OA,`SELECT public.work_task_nfc_checkin('04a1b2c3d4e5f6','${TA}','checkin') v`))[0].v;
ok('explicit start creates NFC checkin',started.success&&started.type==='checkin'&&Boolean(started.checkin_id));
ok('checkin retains authenticated actor and assigned card',(await db.query(`SELECT user_id,checkin_method,nfc_card_id FROM public.checkins WHERE id='${started.checkin_id}'`)).rows[0].nfc_card_id===CARD);
await denied('repeated start cannot close current NFC checkin',A,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkin')`);
ok('record remains open after repeated start',(await db.query(`SELECT checkout_time IS NULL v FROM public.checkins WHERE id='${started.checkin_id}'`)).rows[0].v);
const old=(await request(A,OA,`SELECT public.validate_nfc_checkin('${UID}','${TA}','${A}') v`))[0].v;
ok('legacy toggle endpoint no longer writes',old.success===false&&(await db.query(`SELECT checkout_time IS NULL v FROM public.checkins WHERE id='${started.checkin_id}'`)).rows[0].v);
await denied('closing requires expected checkin',A,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkout')`);
await denied('closing with another tag denied',A,OA,`SELECT public.work_task_nfc_checkin('04:A1:B2:C3:D4:E5:F7','${TA}','checkout','${started.checkin_id}')`);
await denied('other employee cannot close the checkin',SHARED,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkout','${started.checkin_id}')`);
const finished=(await request(A,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkout','${started.checkin_id}') v`))[0].v;
ok('explicit close records the same checkin',finished.success&&finished.checkin_id===started.checkin_id&&finished.checkout_time);
const repeat=(await request(A,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkout','${started.checkin_id}') v`))[0].v;
ok('retrying close is idempotent',repeat.already_closed&&repeat.checkin_id===started.checkin_id&&repeat.checkout_time===finished.checkout_time);
ok('only one record created',(await db.query(`SELECT count(*)::int n FROM public.checkins`)).rows[0].n===countBefore+1);
await request(ADMIN,OA,`SELECT public.work_set_mode(true)`);
await denied('exclusive tablet mode still blocks mobile NFC',A,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkin')`);
await request(ADMIN,OA,`SELECT public.work_set_mode(false)`);
await db.exec(`UPDATE public.task_checkin_config SET nfc_enabled=false WHERE task_id='${TA}'`);
await denied('disabled NFC task denied',A,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkin')`);
ok('executor retains no schema CREATE',(await db.query("SELECT has_schema_privilege('ase_tenant_executor','public','CREATE') v")).rows[0].v===false);
await db.exec(fs.readFileSync(root+'supabase/migrations/20261023000300_active_checkin_actions.sql','utf8'));
await denied('comment without open checkin denied',A,OA,`INSERT INTO public.task_comments(task_id,user_id,comment) VALUES('${TA}','${A}','No active checkin') RETURNING id`);
await denied('incident without open checkin denied',A,OA,`INSERT INTO public.work_incidents(task_id,reporter_id,assigned_user,subject,description,blocks_work) VALUES('${TA}','${A}','${A}','Test incident','No active checkin',false) RETURNING id`);
await denied('upload without open checkin denied',A,OA,`INSERT INTO storage.objects(bucket_id,name) VALUES('task-files','tasks/${TA}/${A}/${id(901)}.jpg') RETURNING id`);
ok('closed checkin grants no actions',(await request(A,OA,`SELECT public.work_can_act('${TA}') v`))[0].v===false);
await db.exec(`UPDATE public.task_checkin_config SET nfc_enabled=true WHERE task_id='${TA}'`);
const live=(await request(A,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkin') v`))[0].v;
ok('own live checkin allows actions',(await request(A,OA,`SELECT public.work_can_act('${TA}') v`))[0].v===true);
ok('comment while checked in succeeds',(await request(A,OA,`INSERT INTO public.task_comments(task_id,user_id,comment) VALUES('${TA}','${A}','Working now') RETURNING id`)).length===1);
ok('incident while checked in succeeds',(await request(A,OA,`SELECT public.work_report_incident('${TA}','Test incident','Work in progress','${A}',NULL,false,'{}') v`))[0].v);
ok('upload while checked in succeeds',(await request(A,OA,`INSERT INTO storage.objects(bucket_id,name) VALUES('task-files','tasks/${TA}/${A}/${id(902)}.jpg') RETURNING id`)).length===1);
ok('other worker cannot use the active checkin',(await request(SHARED,OA,`SELECT public.work_can_act('${TA}') v`))[0].v===false);
ok('other company cannot use the active checkin',(await request(B,OB,`SELECT public.work_can_act('${TA}') v`))[0].v===false);
await request(A,OA,`SELECT public.work_task_nfc_checkin('${UID}','${TA}','checkout','${live.checkin_id}')`);
await denied('comment after closing denied',A,OA,`INSERT INTO public.task_comments(task_id,user_id,comment) VALUES('${TA}','${A}','Already closed') RETURNING id`);
ok('admin retains actions',(await request(ADMIN,OA,`SELECT public.work_can_act('${TA}') v`))[0].v===true);
console.log(JSON.stringify({passed:results.length,scope:'Synthetic PostgreSQL: explicit task NFC actions, role boundaries and non-superuser installation'}));
}catch(e){console.log(JSON.stringify({error:e.message,code:e.code,where:e.where}));process.exitCode=1;}finally{fs.writeFileSync(root+'supabase/tests/active-checkin-actions-results.json',JSON.stringify({scope:'Synthetic isolated PostgreSQL; no hosted writes or physical NFC testing',results},null,2));await db.close()}
