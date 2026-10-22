-- Hosted Supabase controls auth ACLs: custom roles cannot receive schema USAGE.
-- Narrow postgres-owned helpers expose only the current request identity.
BEGIN;
CREATE OR REPLACE FUNCTION ase_private.session_user_id() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$ SELECT auth.uid() $$;
CREATE OR REPLACE FUNCTION ase_private.session_role() RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$ SELECT auth.role() $$;
ALTER FUNCTION ase_private.session_user_id() OWNER TO postgres;
ALTER FUNCTION ase_private.session_role() OWNER TO postgres;
REVOKE ALL ON FUNCTION ase_private.session_user_id(),ase_private.session_role() FROM PUBLIC;
GRANT USAGE ON SCHEMA ase_private TO anon,authenticated,ase_tenant_executor;
GRANT EXECUTE ON FUNCTION ase_private.session_user_id(),ase_private.session_role() TO anon,authenticated,ase_tenant_executor;

DO $$
DECLARE f record; definition text; policy_item record; q text; w text; statement text;
BEGIN
 -- Keep every function owner, security mode, search_path and existing ACL intact.
 FOR f IN SELECT n.nspname,p.proname,p.oid
   FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE (p.proowner='ase_tenant_executor'::regrole OR (n.nspname='ase_private' AND NOT p.prosecdef))
     AND n.nspname IN ('public','ase_private') AND p.prokind='f'
 LOOP
   definition:=pg_get_functiondef(f.oid);
   IF position('auth.uid()' in definition)>0 OR position('auth.role()' in definition)>0 THEN
     definition:=replace(replace(definition,'auth.uid()','ase_private.session_user_id()'),'auth.role()','ase_private.session_role()');
     EXECUTE definition;
   END IF;
 END LOOP;
 -- Policies execute under the querying role; preserve their scope and predicates.
 FOR policy_item IN SELECT * FROM pg_policies WHERE schemaname='public'
   OR (schemaname='storage' AND policyname='work_incident_attachment_executor')
 LOOP
   q:=replace(replace(policy_item.qual,'auth.uid()','ase_private.session_user_id()'),'auth.role()','ase_private.session_role()');
   w:=replace(replace(policy_item.with_check,'auth.uid()','ase_private.session_user_id()'),'auth.role()','ase_private.session_role()');
   IF q IS DISTINCT FROM policy_item.qual OR w IS DISTINCT FROM policy_item.with_check THEN
     statement:=format('ALTER POLICY %I ON %I.%I',policy_item.policyname,policy_item.schemaname,policy_item.tablename);
     IF q IS NOT NULL THEN statement:=statement||format(' USING (%s)',q); END IF;
     IF w IS NOT NULL THEN statement:=statement||format(' WITH CHECK (%s)',w); END IF;
     EXECUTE statement;
   END IF;
 END LOOP;
END $$;
NOTIFY pgrst,'reload schema';
COMMIT;
