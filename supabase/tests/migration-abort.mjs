import {PGlite} from '@electric-sql/pglite';import {fileURLToPath} from 'node:url';
import fs from 'node:fs';import assert from 'node:assert/strict';
const root=fileURLToPath(new URL('../../',import.meta.url));const results=[];
for(const scenario of ['rpc-drift','rls-drift','legacy-card-user-mismatch']){
 const db=new PGlite();try{
 await db.exec(fs.readFileSync(root+'supabase/tests/bootstrap.sql','utf8'));await db.exec(fs.readFileSync(root+'supabase/baseline/20261022_installed_public.sql','utf8'));await db.exec(fs.readFileSync(root+'supabase/tests/storage-baseline.sql','utf8'));
 await db.exec(`INSERT INTO auth.users(id,email) VALUES('00000000-0000-0000-0000-000000000001','admin@example.test'),('00000000-0000-0000-0000-000000000002','worker@example.test');UPDATE public.users SET is_admin=true WHERE id='00000000-0000-0000-0000-000000000001';INSERT INTO public.work_settings VALUES(true,false);INSERT INTO public.tasks(id,title) VALUES('00000000-0000-0000-0000-000000000010','Preserve');`);
 if(scenario==='rpc-drift')await db.exec(`CREATE OR REPLACE FUNCTION public.work_today() RETURNS date LANGUAGE sql STABLE SET search_path='' AS $$SELECT current_date+1$$`);
 if(scenario==='rls-drift')await db.exec(`CREATE POLICY unexpected ON public.tasks TO authenticated USING(true)`);
 if(scenario==='legacy-card-user-mismatch')await db.exec(`INSERT INTO public.work_employee_cards(id,user_id,label,token_hash) VALUES('00000000-0000-0000-0000-000000000100','00000000-0000-0000-0000-000000000002','Mismatch',public.work_hash('card'));INSERT INTO public.checkins(task_id,user_id,employee_card_id) VALUES('00000000-0000-0000-0000-000000000010','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000100');`);
 let failed=false;try{await db.exec(fs.readFileSync(root+'supabase/migrations/20261022000100_core_multitenancy_a1.sql','utf8'))}catch(error){failed=true;await db.exec('ROLLBACK')}
 assert(failed,scenario+' must stop migration');assert.equal((await db.query(`SELECT to_regclass('public.organizations') v`)).rows[0].v,null);assert.equal((await db.query(`SELECT count(*)::int n FROM information_schema.columns WHERE table_schema='public' AND column_name='organization_id'`)).rows[0].n,0);assert.equal((await db.query(`SELECT count(*)::int n FROM public.tasks WHERE title='Preserve'`)).rows[0].n,1);assert.equal((await db.query(`SELECT is_admin FROM public.users WHERE id='00000000-0000-0000-0000-000000000001'`)).rows[0].is_admin,true);
 results.push({test:scenario,actual:'PASS',evidence:'transaction rolls back; legacy rows and admin flag retained; no tenant columns remain'});
 }finally{await db.close()}
}
fs.writeFileSync(root+'supabase/tests/abort-results.json',JSON.stringify({scope:'Isolated PostgreSQL; synthetic inconsistent legacy data and metadata drift',results},null,2));console.log(JSON.stringify({passed:results.length}));
