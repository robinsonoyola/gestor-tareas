-- CORE-MULTITENANCY-A1: AUDIT CANDIDATE. STAGING FIRST; NOT APPROVED FOR PRODUCTION.
-- Preserve a verified backup and deploy the documented Auth services before activating.
BEGIN;
-- Section: 202610220001_tenant_boundary.sql
-- REVIEW CANDIDATE. Apply on a restored staging copy first.
-- Requires the captured 20261022 baseline. One transaction; no intermediate exposure.

SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='120s';
-- Reject drift since the supplied inventory; reconcile changes instead of guessing.
DO $guard$ BEGIN
 IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prokind='f' AND NOT EXISTS(SELECT 1 FROM pg_depend d WHERE d.classid='pg_proc'::regclass AND d.objid=p.oid AND d.deptype='e'))<>60 THEN RAISE EXCEPTION 'RPC inventory drifted; export schema again'; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES
('create_task_checkin_config','','f5b7b4296711cb344efbc553c03e2a48'),
('finish_manual_checkin','p_checkin_id uuid','0a59609772cfbd0b618d154b3a7a131a'),
('generate_task_access_code','p_task_id uuid','02749e74211ec4068d21dafe0b606331'),
('handle_new_user','','40d07f45fe9773d035721d329dcb6b7a'),
('sec01_guard_is_admin','','54503bda5b394fd3abb48e4d53e29436'),
('sec04_validate_comment_attachment','','09c9fe70ae65abb4066dfcf8ff726ca5'),
('sec06_is_admin','','274d774421ca0cee437c9052089d851d'),
('sec06_task_actor_names','p_task_id uuid','c2e0b397eb6cfd4a738bb386cfece4e9'),
('sync_confirmed_auth_email','','ec77372d25b23634bdb7453c5748317b'),
('validate_nfc_checkin','p_card_uid character varying, p_task_id uuid, p_user_id uuid','3c3a022b581f0f572e017500341e6f78'),
('work_admin_metrics','p_start date, p_end date, p_user uuid','3f3efc78f15c6af3ab2d062b247f43ad'),
('work_admin_overview','p_user uuid, p_date date','f8c0f24a8f0cbdde3759fdd848c5c3e3'),
('work_admin_productivity','p_start date, p_end date, p_task uuid, p_user uuid','a454c6e372275cfafd3657aedd183776'),
('work_assert_admin','','8880eafe24fc3d385a46cde40dcb6bb8'),
('work_assert_permission','p_key text','a90fcf94f085d0c2441c0081887825c0'),
('work_can_detail','p_task_id uuid','6aca09e33aaa691ef75f91627122963c'),
('work_can_file','p_name text','c5ef03db084597d98b71b1cadea0ddab'),
('work_checkin_history','p_start date, p_end date, p_user uuid, p_task uuid, p_only_open boolean, p_offset integer, p_limit integer, p_personal boolean','5231bff9600903f6cdb14d19d3dce638'),
('work_create_credential','p_kind text, p_name text, p_user uuid','412dd0e66b00abb597aac9ea9adff4aa'),
('work_create_hashed_credential','p_kind text, p_name text, p_user uuid','565125ad4cbeac769d220bbcdb9303a2'),
('work_deadline','p_day date, p_state text, p_finished timestamp with time zone','2dff583db8c9159f4787edddb1147621'),
('work_delete_credential','p_kind text, p_id uuid','923e32096235f0d0fd97ecf6f69a3d7e'),
('work_delete_role','p_id uuid','da8ce4c24c7437f7a0da2225a6f1b0ee'),
('work_detail_access','p_task_id uuid','a1c3be024d054949b48017aced6e296f'),
('work_employee_directory','','28d451d9dc9be2d61052b9bc44501cd7'),
('work_get_card_key','p_id uuid','08f6ad1db012ea6609d044bf7ae58694'),
('work_get_station_key','p_id uuid','da46e36bbb036f4ee906698cec3b6648'),
('work_guard_assignment','','d6acaab6205a5a159f6c9b6394026df1'),
('work_guard_checkin','','9cb054e98ccd94cc2b1b3a5fadcc8fe5'),
('work_has_permission','p_key text','fddddab5046325e77399fe094443ea09'),
('work_hash','p_value text','61ee3868854c762b54bfbcee623841b0'),
('work_home_summary','','f01c4b68632a153872997fbd52471b02'),
('work_legacy_actor_names','p_task_id uuid','c96ea14bfdad97272c1ae89e6db15d95'),
('work_manage_task','p_action text, p_id uuid, p_title text, p_description text, p_schedule text, p_date date, p_status text, p_users uuid[]','43d52b1633d6b1368a17a11245ff56b2'),
('work_mode','','f5cbfd96fd0aa15a31d3f4fac3b30265'),
('work_my_day','','e1aabad01a83e7f48e045c79c65c6aa3'),
('work_my_permissions','','b450cea3e57a6f5ee9db184b6fdd4619'),
('work_overdue_items','p_limit integer','922e8a111bb4f7efd1a5ee44d9118bb7'),
('work_planning_assignments','p_user uuid','45f5356613d32d35fb2adb90de4486a8'),
('work_planning_calendar','p_user uuid, p_start date, p_end date','a8b78e659685b5fa22377f625bb7b407'),
('work_revoke_credential','p_kind text, p_id uuid','8b0385ed4cd0b4a2a225cc2202015f7f'),
('work_roles_overview','','73187b5eff0c961ffff94cd051fe06ed'),
('work_rotate_card_key','p_id uuid','6ff2862a009fc1d13fd62809c7db4183'),
('work_rotate_station_key','p_id uuid','17fd35800eaacbe47b2585eaa4cec584'),
('work_save_card_key','p_id uuid, p_token text','a7a387a028cf2cd47b76014e1ac2ffe3'),
('work_save_employee_profile','p_user uuid, p_name text, p_whatsapp text, p_role uuid','5a89e8091afe0b83ff637c5da102c2b0'),
('work_save_plan','p_user uuid, p_date date, p_tasks uuid[]','6dca4ebbd95f8587842ed6228ffddddc'),
('work_save_plan_range','p_user uuid, p_start date, p_end date, p_tasks uuid[], p_weekdays integer[], p_existing text','ba806c6d27b41e1d43135b4680c5666c'),
('work_save_role','p_id uuid, p_name text, p_description text, p_active boolean','b1cb2d93030dbb48ad50227b0b86bff8'),
('work_save_station_key','p_id uuid, p_token text','c433444a0dfadd92d0a5c80862f824c4'),
('work_set_card_active','p_id uuid, p_active boolean','a22ab2258123c0bf46c4c40d2eaec068'),
('work_set_mode','p_enabled boolean','80aa1f84171749fcb6f5800f5ab62e5d'),
('work_set_role_permissions','p_id uuid, p_permissions text[]','5716cb74fd1f6f29a0ffed169955a302'),
('work_set_station_active','p_id uuid, p_active boolean','d999f496f847ab02d03b75890a49a8ff'),
('work_station_confirm','p_station text, p_ticket uuid, p_action text','5598594abc4435541f5d6ee0f958e7a8'),
('work_station_day','p_station text, p_ticket uuid','1498e6b9ccd547d54c1fe8b7ffc01ab6'),
('work_station_identify','p_station text, p_card text','f40bcb27032c053738b8148b26a7574a'),
('work_task_catalog','','94325eada9e4753479aaecc771f7a22e'),
('work_task_options','','6a86f2d9e415c05c3c1809c2b442f97e'),
('work_today','','0c06f1ef0ec9234840ad070cef7b7595')
 ) expected(name,args,hash) LEFT JOIN (SELECT p.oid,p.proname,pg_get_function_identity_arguments(p.oid) args FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prokind='f') actual ON actual.proname=expected.name AND actual.args=expected.args
 WHERE actual.oid IS NULL OR md5(btrim(regexp_replace(pg_get_functiondef(actual.oid),'[[:space:]]+',' ','g')))<>expected.hash)
 THEN RAISE EXCEPTION 'RPC definitions drifted since capture; reconcile before migration'; END IF;
END $guard$;
DO $policies$ BEGIN
 IF (SELECT count(*) FROM pg_policies WHERE schemaname IN ('public','storage'))<>37 THEN RAISE EXCEPTION 'RLS policy inventory drifted; reconcile before migration'; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES
('public','checkins','Enable delete for admins','57ac519ba0792feea7bd8cb03b46ac05'),
('public','checkins','sec05_insert_own_assigned_manual_checkin','798f08e203d5b6c502642aac8535e1c0'),
('public','checkins','sec05_read_assigned_checkins_or_admin','0d2c6f26fae68b37564f20171d7c90f4'),
('public','checkins','work_checkins_detail','8fe6f42c23b85eadbcfea3a42d84e6a8'),
('public','nfc_cards','Admins can manage NFC cards','a1a2af330aa289c1fdcfb6de6b8a2425'),
('public','nfc_cards','Employees can view NFC cards for assigned tasks','e14ca5b70f5030c02fbb00baddab6007'),
('public','task_access_codes','Admins can manage access codes','576911436ab80e1c5a583708c4754c21'),
('public','task_access_codes','Users can view active codes for their tasks','220b6d900b482b93670ee72776472382'),
('public','task_assignments','Enable delete for admins','57ac519ba0792feea7bd8cb03b46ac05'),
('public','task_assignments','Enable insert for admins','d18b2fb02dd09547032ed94462f5375e'),
('public','task_assignments','sec05_read_own_assignments_or_admin','fd46f828775890edf72a33ade07c5147'),
('public','task_assignments','work_permission_assignment_delete','595601fa114c90556ef66af1f31e3b29'),
('public','task_assignments','work_permission_assignment_insert','777c7eacd837da06c60157fa29e9bf92'),
('public','task_assignments','work_permission_assignment_update','e71ac062404ea8d1f718faa631b1eb2b'),
('public','task_checkin_config','Admins can manage checkin config','a1a2af330aa289c1fdcfb6de6b8a2425'),
('public','task_checkin_config','Employees can view checkin config for assigned tasks','e2dcc21beb33a27364b0e010e788f030'),
('public','task_checkin_config','work_config_detail','91a51da6e4562f61c8735e6c36d29bd7'),
('public','task_comments','Users can insert comments on their tasks','8cf576a3fe979cdddb6e48c270219add'),
('public','task_comments','Users can view comments on their tasks','a526fbe373316be18dd82848a75acb0c'),
('public','task_comments','work_comments_detail','5f8a957292378e736fa7eed619762fbc'),
('public','tasks','Enable delete for admins','57ac519ba0792feea7bd8cb03b46ac05'),
('public','tasks','Enable insert for admins','d18b2fb02dd09547032ed94462f5375e'),
('public','tasks','Enable update for admins and assigned employees','f7b9c1fd4ff2732d068921137c68ddf1'),
('public','tasks','sec05_read_assigned_tasks_or_admin','ccc1c877c5e94790e9a64de79afdeb8b'),
('public','tasks','work_permission_task_delete','595601fa114c90556ef66af1f31e3b29'),
('public','tasks','work_permission_task_insert','777c7eacd837da06c60157fa29e9bf92'),
('public','tasks','work_permission_task_update','e71ac062404ea8d1f718faa631b1eb2b'),
('public','tasks','work_task_detail','c80aa73c66eac0851647edaf92302943'),
('public','tasks','work_task_update','d513ff80b656e3c66ae96082eda50951'),
('public','users','sec06_delete_admin','388f6f843d0d2d01f85d38c22b56f2c9'),
('public','users','sec06_insert_admin','516817a752aff36b4171661c30aa09b6'),
('public','users','sec06_read_self_or_admin','7142e0c7d000664aa63859d5276da39a'),
('public','users','sec06_update_self_or_admin','2d13ddbb9c7635e54ac35d449478df15'),
('storage','objects','sec04_read_assigned_task_files','50d09732b72d8040cf3f482c2f16ff91'),
('storage','objects','sec04_upload_own_assigned_task_files','8a6a0268d22e5ede4e0330e8f701f116'),
('storage','objects','work_files_insert','19fee1c87f24083703c9e2371720e773'),
('storage','objects','work_files_read','5948edbb89f94214764e36027e0dc27f')
 ) expected(s,t,n,h) LEFT JOIN pg_policies p ON p.schemaname=expected.s AND p.tablename=expected.t AND p.policyname=expected.n
 WHERE p.policyname IS NULL OR md5(concat_ws(chr(31),p.permissive,p.cmd,array_to_string(p.roles,','),btrim(regexp_replace(coalesce(p.qual,''),'[[:space:]]+',' ','g')),btrim(regexp_replace(coalesce(p.with_check,''),'[[:space:]]+',' ','g'))))<>expected.h)
 THEN RAISE EXCEPTION 'RLS policy definitions drifted; reconcile before migration'; END IF;
END $policies$;


DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname IN ('anon','authenticated') AND (rolsuper OR rolbypassrls))
 OR pg_has_role('anon','postgres','MEMBER') OR pg_has_role('authenticated','postgres','MEMBER') THEN
  RAISE EXCEPTION 'API roles have elevated privileges; reconcile before migration';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM storage.buckets WHERE id='task-files' AND public IS FALSE) THEN
  RAISE EXCEPTION 'task-files must exist and be private before migration';
 END IF;
 IF to_regclass('public.organizations') IS NOT NULL OR to_regclass('public.organization_memberships') IS NOT NULL THEN
  RAISE EXCEPTION 'Tenant objects already exist; reconcile instead of overwriting';
 END IF;
 IF EXISTS(SELECT 1 FROM public.users u WHERE NOT EXISTS(SELECT 1 FROM auth.users a WHERE a.id=u.id)) THEN
  RAISE EXCEPTION 'Profiles without auth identity: reconcile without deleting history';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM public.users WHERE is_admin IS TRUE) THEN
  RAISE EXCEPTION 'No existing administrator; identify the initial administrator before migrating';
 END IF;
END $$;

CREATE SCHEMA ase_private;
REVOKE ALL ON SCHEMA ase_private FROM PUBLIC,anon,authenticated;
CREATE ROLE ase_tenant_executor NOLOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
GRANT ase_tenant_executor TO postgres;
-- No API role is a member. Functions run as this non-owner, RLS-bound role.
GRANT USAGE ON SCHEMA public,auth,ase_private TO ase_tenant_executor;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
GRANT EXECUTE ON FUNCTION auth.uid(),auth.role() TO ase_tenant_executor;

CREATE TABLE public.organizations(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),name text NOT NULL CHECK(length(trim(name)) BETWEEN 1 AND 150),
 slug text NOT NULL UNIQUE CHECK(slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' AND length(slug)<=80),
 status text NOT NULL DEFAULT 'active' CHECK(status IN ('active','suspended')),
 created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.organization_memberships(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL REFERENCES public.organizations(id),
 user_id uuid NOT NULL REFERENCES auth.users(id),role text NOT NULL CHECK(role IN ('owner','admin','member')),
 status text NOT NULL DEFAULT 'active' CHECK(status IN ('active','invited','disabled')),
 full_name text NOT NULL,whatsapp text,
 created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(organization_id,user_id)
);
CREATE INDEX mt_memberships_user ON public.organization_memberships(user_id,status,organization_id);
REVOKE ALL ON public.organizations,public.organization_memberships FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.organizations,public.organization_memberships TO ase_tenant_executor;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_memberships ENABLE ROW LEVEL SECURITY;

-- Private resolver is one of the deliberately privileged, narrowly scoped helpers.
-- A request header is a selection ONLY: both membership and organization must be active.
-- For the anonymous station, the secret is revalidated against its own organization.
CREATE FUNCTION ase_private.current_org() RETURNS uuid LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=auth.uid(); requested text; result uuid; total integer; secret text;
BEGIN
 IF actor IS NOT NULL THEN
  requested:=nullif(current_setting('request.headers',true),'')::jsonb->>'x-ase-organization-id';
  IF requested IS NOT NULL THEN
   IF requested !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN RETURN NULL; END IF;
   SELECT m.organization_id INTO result FROM public.organization_memberships m JOIN public.organizations o ON o.id=m.organization_id
    WHERE m.organization_id=requested::uuid AND m.user_id=actor AND m.status='active' AND o.status='active';
   RETURN result;
  END IF;
  SELECT count(*),(array_agg(m.organization_id))[1] INTO total,result
   FROM public.organization_memberships m JOIN public.organizations o ON o.id=m.organization_id
   WHERE m.user_id=actor AND m.status='active' AND o.status='active';
  RETURN CASE WHEN total=1 THEN result ELSE NULL END;
 END IF;
 secret:=nullif(current_setting('ase.station_secret',true),'');
 IF secret IS NULL OR length(secret)>128 OR auth.role() IS DISTINCT FROM 'anon' THEN RETURN NULL; END IF;
 SELECT s.organization_id INTO result FROM public.work_stations s JOIN public.organizations o ON o.id=s.organization_id
  WHERE s.token_hash=encode(sha256(convert_to(secret,'UTF8')),'hex') AND s.active AND s.archived_at IS NULL AND o.status='active';
 RETURN result;
EXCEPTION WHEN invalid_text_representation THEN RETURN NULL;
END $$;
REVOKE ALL ON FUNCTION ase_private.current_org() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.current_org() TO ase_tenant_executor;
-- RLS expressions execute as API roles too; this exposes only their validated context.
GRANT USAGE ON SCHEMA ase_private TO authenticated;
GRANT EXECUTE ON FUNCTION ase_private.current_org() TO authenticated;

CREATE FUNCTION ase_private.bind_station(secret text) RETURNS void LANGUAGE plpgsql VOLATILE SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NOT NULL OR auth.role() IS DISTINCT FROM 'anon' OR secret IS NULL OR length(secret)>128 THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto no disponible';
 END IF;
 PERFORM set_config('ase.station_secret',secret,true);
 IF ase_private.current_org() IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto no disponible'; END IF;
END $$;
REVOKE ALL ON FUNCTION ase_private.bind_station(text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.bind_station(text) TO ase_tenant_executor;

DO $$ DECLARE t text; org uuid; BEGIN
 INSERT INTO public.organizations(name,slug) VALUES('ASE Work','ase-work') RETURNING id INTO org;
 INSERT INTO public.organization_memberships(organization_id,user_id,role,full_name,whatsapp)
 SELECT org,id,CASE WHEN is_admin IS TRUE THEN 'admin' ELSE 'member' END,coalesce(full_name,'Usuario'),whatsapp FROM public.users;
 FOREACH t IN ARRAY ARRAY['tasks','task_assignments','checkins','task_comments','task_access_codes','task_checkin_config','nfc_cards',
 'work_day_plan','work_employee_cards','work_employee_card_keys','work_stations','work_station_keys','work_station_tickets',
 'work_roles','work_employee_roles','work_settings'] LOOP
  -- A constant column default backfills metadata without firing business UPDATE triggers.
  -- Preserve active plans, assignments, timestamps and all existing trigger protections.
  EXECUTE format('ALTER TABLE public.%I ADD COLUMN organization_id uuid DEFAULT %L::uuid',t,org);
  EXECUTE format('ALTER TABLE public.%I ALTER COLUMN organization_id SET NOT NULL, ALTER COLUMN organization_id SET DEFAULT ase_private.current_org()',t);
  EXECUTE format('ALTER TABLE public.%I ADD CONSTRAINT mt_organization_fk FOREIGN KEY(organization_id) REFERENCES public.organizations(id)',t);
  EXECUTE format('CREATE INDEX ON public.%I(organization_id)',t);
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
  EXECUTE format('REVOKE ALL ON public.%I FROM anon',t);
  EXECUTE format('REVOKE TRUNCATE,REFERENCES,TRIGGER ON public.%I FROM PUBLIC,authenticated',t);
  EXECUTE format('GRANT SELECT,INSERT,UPDATE,DELETE ON public.%I TO ase_tenant_executor',t);
  EXECUTE format('CREATE POLICY mt_executor ON public.%I TO ase_tenant_executor USING(true) WITH CHECK(true)',t);
  EXECUTE format('CREATE POLICY mt_boundary ON public.%I AS RESTRICTIVE TO PUBLIC USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org())',t);
 END LOOP;
END $$;
-- Multiple companies must not share a singleton, role assignment or active-card uniqueness.
ALTER TABLE public.work_settings DROP CONSTRAINT work_settings_pkey, ADD PRIMARY KEY(organization_id,singleton);
ALTER TABLE public.work_employee_roles DROP CONSTRAINT work_employee_roles_pkey, ADD PRIMARY KEY(organization_id,user_id);
ALTER TABLE public.work_day_plan DROP CONSTRAINT work_day_plan_user_id_task_id_work_date_key,
 ADD UNIQUE(organization_id,user_id,task_id,work_date);
ALTER TABLE public.work_day_plan DROP CONSTRAINT work_day_plan_user_id_work_date_priority_key,
 ADD UNIQUE(organization_id,user_id,work_date,priority) DEFERRABLE INITIALLY DEFERRED;
-- The following existing partial/expression indexes are replaced by the generated companion SQL.

-- Both membership and organization are immutable through ordinary business writes.
CREATE FUNCTION ase_private.guard_row() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE target uuid;
BEGIN
 IF TG_OP='UPDATE' AND NEW.organization_id IS DISTINCT FROM OLD.organization_id THEN
  RAISE EXCEPTION USING ERRCODE='23514',MESSAGE='No se puede trasladar un registro a otra empresa';
 END IF;
 IF TG_TABLE_NAME IN ('task_assignments','work_day_plan','work_employee_cards','work_employee_roles','work_station_tickets','checkins','task_comments') THEN
  target:=NEW.user_id;
  IF target IS NOT NULL AND (TG_OP='INSERT' OR NEW.user_id IS DISTINCT FROM OLD.user_id) THEN
   PERFORM 1 FROM public.organization_memberships WHERE organization_id=NEW.organization_id AND user_id=target AND status='active' FOR SHARE;
   IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='23514',MESSAGE='El empleado no está activo en esta empresa'; END IF;
  END IF;
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION ase_private.guard_row() FROM PUBLIC,anon,authenticated;
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['tasks','task_assignments','checkins','task_comments','task_access_codes','task_checkin_config','nfc_cards',
 'work_day_plan','work_employee_cards','work_employee_card_keys','work_stations','work_station_keys','work_station_tickets',
 'work_roles','work_employee_roles','work_settings'] LOOP
 EXECUTE format('CREATE TRIGGER mt_row BEFORE INSERT OR UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION ase_private.guard_row()',t);
 END LOOP;
END $$;

-- Identity remains global. This view supplies organization-specific employment attributes.
CREATE VIEW ase_private.employee_profiles WITH(security_invoker=true) AS
 SELECT u.id,u.email,m.full_name,m.whatsapp,(m.role IN ('owner','admin')) AS is_admin,u.created_at,m.status AS membership_status
 FROM public.users u JOIN public.organization_memberships m ON m.user_id=u.id
 WHERE m.organization_id=ase_private.current_org();
GRANT SELECT ON public.users TO ase_tenant_executor;
GRANT UPDATE(full_name) ON public.users TO ase_tenant_executor;
GRANT SELECT ON ase_private.employee_profiles TO ase_tenant_executor;
GRANT UPDATE(full_name) ON ase_private.employee_profiles TO ase_tenant_executor;
GRANT UPDATE(full_name,whatsapp,status,updated_at) ON public.organization_memberships TO ase_tenant_executor;
CREATE POLICY mt_memberships_executor ON public.organization_memberships TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY mt_organizations_executor ON public.organizations FOR SELECT TO ase_tenant_executor USING(id=ase_private.current_org());
CREATE POLICY mt_profiles_executor ON public.users TO ase_tenant_executor USING(
 EXISTS(SELECT 1 FROM public.organization_memberships m WHERE m.user_id=users.id AND m.organization_id=ase_private.current_org()))
 WITH CHECK(false);

CREATE OR REPLACE FUNCTION public.sec06_is_admin() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT auth.uid() IS NOT NULL AND EXISTS(SELECT 1 FROM public.organization_memberships m
 WHERE m.organization_id=ase_private.current_org() AND m.user_id=auth.uid() AND m.status='active' AND m.role IN ('owner','admin'))
$$;
ALTER FUNCTION public.sec06_is_admin() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.sec06_is_admin() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sec06_is_admin() TO authenticated,ase_tenant_executor;

-- API callers may read their global identity; only scoped employee RPC exposes coworkers.
DROP POLICY sec06_read_self_or_admin ON public.users;
DROP POLICY sec06_insert_admin ON public.users;
DROP POLICY sec06_update_self_or_admin ON public.users;
DROP POLICY sec06_delete_admin ON public.users;
CREATE POLICY mt_profile_self ON public.users FOR SELECT TO authenticated USING(id=auth.uid());
CREATE POLICY mt_profile_update_self ON public.users FOR UPDATE TO authenticated USING(id=auth.uid()) WITH CHECK(id=auth.uid());
REVOKE ALL ON public.users FROM anon,authenticated;
GRANT SELECT ON public.users TO authenticated;
GRANT UPDATE(full_name,whatsapp) ON public.users TO authenticated;
-- Global legacy is_admin is retained as historical data, never as tenant authority.

CREATE FUNCTION public.mt_context() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; actor uuid:=auth.uid(); org uuid:=ase_private.current_org(); profile jsonb;
BEGIN
 IF actor IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',o.id,'name',o.name,'role',m.role) ORDER BY o.name,o.id),'[]'::jsonb) INTO result
 FROM public.organization_memberships m JOIN public.organizations o ON o.id=m.organization_id
 WHERE m.user_id=actor AND m.status='active' AND o.status='active';
 SELECT jsonb_build_object('id',u.id,'email',u.email,'full_name',m.full_name,'whatsapp',m.whatsapp,'is_admin',m.role IN ('owner','admin'),
  'created_at',u.created_at) INTO profile FROM public.users u JOIN public.organization_memberships m ON m.user_id=u.id
 WHERE u.id=actor AND m.organization_id=org AND m.status='active';
 RETURN jsonb_build_object('organizations',result,'active_organization_id',org,'profile',profile);
END $$;
-- Context intentionally enumerates only actor memberships, including when no organization is selected.
REVOKE ALL ON FUNCTION public.mt_context() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.mt_context() TO authenticated;

CREATE FUNCTION public.mt_create_organization(p_name text,p_slug text) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=auth.uid(); org uuid; profile public.users%ROWTYPE;
BEGIN
 IF actor IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;
 SELECT * INTO profile FROM public.users WHERE id=actor;
 IF NOT FOUND THEN RAISE EXCEPTION 'Perfil de identidad no disponible'; END IF;
 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 150 OR p_slug IS NULL OR length(p_slug)>80 OR p_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' THEN RAISE EXCEPTION 'Nombre o identificador no válido'; END IF;
 INSERT INTO public.organizations(name,slug) VALUES(trim(p_name),p_slug) RETURNING id INTO org;
 INSERT INTO public.organization_memberships(organization_id,user_id,role,full_name,whatsapp)
 VALUES(org,actor,'owner',coalesce(profile.full_name,'Usuario'),profile.whatsapp);
 INSERT INTO public.work_settings(organization_id,singleton,enabled) VALUES(org,true,false);
 RETURN org;
END $$;
REVOKE ALL ON FUNCTION public.mt_create_organization(text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.mt_create_organization(text,text) TO authenticated;

-- Companion migration installs cross-tenant FKs, scoped RPCs and Storage rules in this transaction.


ALTER TABLE public.nfc_cards DROP CONSTRAINT nfc_cards_card_uid_key, ADD UNIQUE(organization_id,card_uid);

-- GENERATED COMPANION

DROP INDEX public.work_one_active_per_employee; CREATE UNIQUE INDEX work_one_active_per_employee ON public.work_day_plan(organization_id,user_id) WHERE state='active';

DROP INDEX public.work_one_active_card_per_employee; CREATE UNIQUE INDEX work_one_active_card_per_employee ON public.work_employee_cards(organization_id,user_id) WHERE active;

DROP INDEX public.work_role_name_unique; CREATE UNIQUE INDEX work_role_name_unique ON public.work_roles(organization_id,lower(trim(name)));

ALTER TABLE public.tasks ADD UNIQUE(organization_id,id);

ALTER TABLE public.work_roles ADD UNIQUE(organization_id,id);

ALTER TABLE public.work_day_plan ADD UNIQUE(organization_id,id);

ALTER TABLE public.work_employee_cards ADD UNIQUE(organization_id,id);

ALTER TABLE public.work_stations ADD UNIQUE(organization_id,id);

ALTER TABLE public.nfc_cards ADD UNIQUE(organization_id,id);

ALTER TABLE public.task_assignments ADD CONSTRAINT mt_task_id_fk FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id);

ALTER TABLE public.checkins ADD CONSTRAINT mt_task_id_fk FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id);

ALTER TABLE public.task_comments ADD CONSTRAINT mt_task_id_fk FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id);

ALTER TABLE public.task_access_codes ADD CONSTRAINT mt_task_id_fk FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id);

ALTER TABLE public.task_checkin_config ADD CONSTRAINT mt_task_id_fk FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id);

ALTER TABLE public.nfc_cards ADD CONSTRAINT mt_task_id_fk FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id);

ALTER TABLE public.work_day_plan ADD CONSTRAINT mt_task_id_fk FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id);

ALTER TABLE public.work_employee_roles ADD CONSTRAINT mt_role_id_fk FOREIGN KEY(organization_id,role_id) REFERENCES public.work_roles(organization_id,id);

ALTER TABLE public.work_employee_card_keys ADD CONSTRAINT mt_card_id_fk FOREIGN KEY(organization_id,card_id) REFERENCES public.work_employee_cards(organization_id,id);

ALTER TABLE public.work_station_keys ADD CONSTRAINT mt_station_id_fk FOREIGN KEY(organization_id,station_id) REFERENCES public.work_stations(organization_id,id);

ALTER TABLE public.work_station_tickets ADD CONSTRAINT mt_station_id_fk FOREIGN KEY(organization_id,station_id) REFERENCES public.work_stations(organization_id,id);

ALTER TABLE public.work_station_tickets ADD CONSTRAINT mt_card_id_fk FOREIGN KEY(organization_id,card_id) REFERENCES public.work_employee_cards(organization_id,id);

ALTER TABLE public.work_station_tickets ADD CONSTRAINT mt_plan_id_fk FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id);

ALTER TABLE public.checkins ADD CONSTRAINT mt_work_plan_id_fk FOREIGN KEY(organization_id,work_plan_id) REFERENCES public.work_day_plan(organization_id,id);

ALTER TABLE public.checkins ADD CONSTRAINT mt_work_station_id_fk FOREIGN KEY(organization_id,work_station_id) REFERENCES public.work_stations(organization_id,id);

ALTER TABLE public.checkins ADD CONSTRAINT mt_employee_card_id_fk FOREIGN KEY(organization_id,employee_card_id) REFERENCES public.work_employee_cards(organization_id,id);

ALTER TABLE public.checkins ADD CONSTRAINT mt_nfc_card_id_fk FOREIGN KEY(organization_id,nfc_card_id) REFERENCES public.nfc_cards(organization_id,id);

ALTER TABLE public.task_assignments ADD CONSTRAINT mt_member_fk FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id);

ALTER TABLE public.checkins ADD CONSTRAINT mt_member_fk FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id);

ALTER TABLE public.task_comments ADD CONSTRAINT mt_member_fk FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id);

ALTER TABLE public.task_access_codes ADD CONSTRAINT mt_member_fk FOREIGN KEY(organization_id,created_by) REFERENCES public.organization_memberships(organization_id,user_id);

ALTER TABLE public.work_day_plan ADD CONSTRAINT mt_member_fk FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id);

ALTER TABLE public.work_employee_cards ADD CONSTRAINT mt_member_fk FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id);

ALTER TABLE public.work_employee_roles ADD CONSTRAINT mt_member_fk FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id);

ALTER TABLE public.work_station_tickets ADD CONSTRAINT mt_member_fk FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id);

ALTER TABLE public.work_day_plan ADD UNIQUE(organization_id,id,task_id,user_id);
ALTER TABLE public.work_employee_cards ADD UNIQUE(organization_id,id,user_id);
ALTER TABLE public.nfc_cards ADD UNIQUE(organization_id,id,task_id);
ALTER TABLE public.checkins ADD CONSTRAINT mt_plan_identity_fk FOREIGN KEY(organization_id,work_plan_id,task_id,user_id) REFERENCES public.work_day_plan(organization_id,id,task_id,user_id);
ALTER TABLE public.checkins ADD CONSTRAINT mt_card_identity_fk FOREIGN KEY(organization_id,employee_card_id,user_id) REFERENCES public.work_employee_cards(organization_id,id,user_id);
ALTER TABLE public.checkins ADD CONSTRAINT mt_nfc_task_fk FOREIGN KEY(organization_id,nfc_card_id,task_id) REFERENCES public.nfc_cards(organization_id,id,task_id);
ALTER TABLE public.work_station_tickets ADD CONSTRAINT mt_ticket_card_user_fk FOREIGN KEY(organization_id,card_id,user_id) REFERENCES public.work_employee_cards(organization_id,id,user_id);
ALTER TABLE public.work_day_plan ADD UNIQUE(organization_id,id,user_id);
ALTER TABLE public.work_station_tickets ADD CONSTRAINT mt_ticket_plan_user_fk FOREIGN KEY(organization_id,plan_id,user_id) REFERENCES public.work_day_plan(organization_id,id,user_id);
CREATE INDEX mt_plan_calendar ON public.work_day_plan(organization_id,user_id,work_date);
CREATE INDEX mt_checkin_history ON public.checkins(organization_id,checkin_time);


CREATE OR REPLACE FUNCTION public.create_task_checkin_config()
 RETURNS trigger
 LANGUAGE plpgsql
SET search_path TO ''
AS $function$
BEGIN
  INSERT INTO public.task_checkin_config (task_id, qr_enabled, manual_enabled)
  VALUES (NEW.id, true, true)
  ON CONFLICT (task_id) DO NOTHING;
  RETURN NEW;
END;
$function$
;

ALTER FUNCTION public.create_task_checkin_config() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.create_task_checkin_config() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.create_task_checkin_config() TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.create_task_checkin_config() TO authenticated;

CREATE OR REPLACE FUNCTION public.finish_manual_checkin(p_checkin_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_actor uuid := (SELECT auth.uid());
 v_row public.checkins%ROWTYPE;
 v_closed_at timestamptz;
BEGIN
 IF v_actor IS NULL OR (SELECT auth.role()) IS DISTINCT FROM 'authenticated' THEN
   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Se requiere sesion autenticada';
 END IF;
 SELECT * INTO v_row FROM public.checkins c
 WHERE c.id=p_checkin_id AND c.user_id=v_actor FOR UPDATE;
 IF NOT FOUND THEN
   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible para esta cuenta';
 END IF;
 IF v_row.checkin_method IS DISTINCT FROM 'manual' THEN
   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Este cierre solo permite fichajes manuales';
 END IF;
 PERFORM 1 FROM public.task_assignments a
 WHERE a.task_id=v_row.task_id AND a.user_id=v_actor FOR KEY SHARE;
 IF NOT FOUND THEN
   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No estas asignado a esta tarea';
 END IF;
 -- Reintentar devuelve la salida existente sin cambiar la hora.
 IF v_row.checkout_time IS NOT NULL THEN
   RETURN pg_catalog.json_build_object('success',true,'checkin_id',v_row.id,'checkout_time',v_row.checkout_time,'already_closed',true);
 END IF;
 -- Permite finalizar una sesion propia ya abierta aunque se haya deshabilitado
 -- manual_enabled despues de la entrada. No permite iniciar sesiones.
 IF v_row.checkin_time IS NULL OR v_row.checkin_time>pg_catalog.clock_timestamp() THEN
   RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Hora de entrada no valida; requiere revision';
 END IF;
 v_closed_at:=pg_catalog.clock_timestamp();
 UPDATE public.checkins SET checkout_time=v_closed_at WHERE id=v_row.id;
 RETURN pg_catalog.json_build_object('success',true,'checkin_id',v_row.id,'checkout_time',v_closed_at,'already_closed',false);
END;
$function$
;

ALTER FUNCTION public.finish_manual_checkin(p_checkin_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.finish_manual_checkin(p_checkin_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.finish_manual_checkin(p_checkin_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.finish_manual_checkin(p_checkin_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.generate_task_access_code(p_task_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_actor uuid := (SELECT auth.uid());
 v_code text;
BEGIN
 IF v_actor IS NULL OR (SELECT auth.role()) IS DISTINCT FROM 'authenticated' THEN
   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Se requiere una sesion de usuario autenticada';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles u WHERE u.id=v_actor AND u.is_admin IS TRUE) THEN
   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Solo administradores pueden generar codigos';
 END IF;
 IF p_task_id IS NULL THEN
   RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Tarea obligatoria';
 END IF;
 PERFORM 1 FROM public.tasks t WHERE t.id=p_task_id FOR KEY SHARE;
 IF NOT FOUND THEN
   RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Tarea no disponible';
 END IF;
 -- UUID aleatorio completo; no usar MD5(random()) truncado como credencial.
 v_code := 'TASK-' || pg_catalog.upper(pg_catalog.replace(pg_catalog.gen_random_uuid()::text,'-',''));
 INSERT INTO public.task_access_codes(id,task_id,access_code,created_by,created_at,is_active,expires_at)
 VALUES(pg_catalog.gen_random_uuid(),p_task_id,v_code,v_actor,pg_catalog.now(),true,NULL);
 RETURN v_code;
END;
$function$
;

ALTER FUNCTION public.generate_task_access_code(p_task_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.generate_task_access_code(p_task_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.generate_task_access_code(p_task_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.generate_task_access_code(p_task_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.sec04_validate_comment_attachment()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE v_ref text; v_actor uuid := (SELECT auth.uid()); v_prefix text;
BEGIN
 IF (SELECT auth.role()) IN ('anon','authenticated') THEN
   IF v_actor IS NULL OR NEW.user_id IS DISTINCT FROM v_actor OR NEW.task_id IS NULL THEN
     RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Comentario no autorizado';
   END IF;
   IF TG_OP='UPDATE' THEN
     IF NEW.image_url IS NOT DISTINCT FROM OLD.image_url
       AND NEW.video_url IS NOT DISTINCT FROM OLD.video_url
       AND NEW.task_id IS NOT DISTINCT FROM OLD.task_id
       AND NEW.user_id IS NOT DISTINCT FROM OLD.user_id THEN
       RETURN NEW;
     END IF;
   END IF;
   v_prefix:='tasks/'||NEW.task_id::text||'/'||v_actor::text||'/';
   FOREACH v_ref IN ARRAY ARRAY[NEW.image_url,NEW.video_url] LOOP
     IF v_ref IS NOT NULL AND (
       pg_catalog.left(v_ref,pg_catalog.length(v_prefix))<>v_prefix
       OR v_ref !~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov)$'
     ) THEN
       RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La referencia debe pertenecer a tu subida de esta tarea';
     END IF;
   END LOOP;
 END IF;
 RETURN NEW;
END;
$function$
;

ALTER FUNCTION public.sec04_validate_comment_attachment() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.sec04_validate_comment_attachment() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.sec04_validate_comment_attachment() TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.sec06_task_actor_names(p_task_id uuid)
 RETURNS TABLE(id uuid, full_name text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
 IF NOT public.work_can_detail(p_task_id) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Abre solo tu tarea en curso'; END IF;
 RETURN QUERY SELECT * FROM public.work_legacy_actor_names(p_task_id);
END $function$
;

ALTER FUNCTION public.sec06_task_actor_names(p_task_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.sec06_task_actor_names(p_task_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.sec06_task_actor_names(p_task_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.sec06_task_actor_names(p_task_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.validate_nfc_checkin(p_card_uid character varying, p_task_id uuid, p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_actor uuid := (SELECT auth.uid());
 v_card public.nfc_cards%ROWTYPE;
 v_last public.checkins%ROWTYPE;
 v_id uuid;
 v_type text;
BEGIN
 IF v_actor IS NULL OR (SELECT auth.role()) IS DISTINCT FROM 'authenticated' THEN
   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Se requiere una sesion de usuario autenticada';
 END IF;
 IF p_user_id IS DISTINCT FROM v_actor THEN
   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='No se permite fichar por otra persona';
 END IF;
 IF p_task_id IS NULL OR p_card_uid IS NULL OR pg_catalog.btrim(p_card_uid)='' THEN
   RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Tarea y tarjeta obligatorias';
 END IF;
 -- Serializa operaciones NFC de una misma tarea. El indice protege ademas
 -- contra duplicados que intenten crear otros caminos de escritura.
 PERFORM 1 FROM public.tasks t WHERE t.id=p_task_id FOR UPDATE;
 IF NOT FOUND THEN
   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Tarea no disponible o no autorizada';
 END IF;
 PERFORM 1 FROM public.task_assignments a
 WHERE a.task_id=p_task_id AND a.user_id=v_actor FOR KEY SHARE;
 IF NOT FOUND THEN
   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Tarea no disponible o no autorizada';
 END IF;
 SELECT * INTO v_card FROM public.nfc_cards c
 WHERE c.card_uid=p_card_uid AND c.is_active IS TRUE AND c.task_id=p_task_id
 FOR SHARE;
 IF NOT FOUND THEN
   RETURN pg_catalog.json_build_object('success',false,'message','Tarjeta no valida para esta tarea');
 END IF;
 PERFORM 1 FROM public.task_checkin_config c
 WHERE c.task_id=p_task_id AND c.nfc_enabled IS TRUE FOR SHARE;
 IF NOT FOUND THEN
   RETURN pg_catalog.json_build_object('success',false,'message','Fichaje NFC no habilitado');
 END IF;
 SELECT * INTO v_last FROM public.checkins c
 WHERE c.task_id=p_task_id AND c.user_id=v_actor AND c.checkout_time IS NULL
 FOR UPDATE;
 IF FOUND THEN
   -- checkins.updated_at no existe en el esquema auditado.
   UPDATE public.checkins SET checkout_time=pg_catalog.now() WHERE id=v_last.id;
   v_id:=v_last.id;
   v_type:='checkout';
 ELSE
   INSERT INTO public.checkins(id,task_id,user_id,checkin_method,nfc_card_id,checkin_time)
   VALUES(pg_catalog.gen_random_uuid(),p_task_id,v_actor,'nfc',v_card.id,pg_catalog.now())
   RETURNING id INTO v_id;
   v_type:='checkin';
 END IF;
 RETURN pg_catalog.json_build_object(
   'success',true,'type',v_type,'checkin_id',v_id,
   'message',CASE WHEN v_type='checkin' THEN 'Fichaje iniciado con NFC' ELSE 'Fichaje finalizado con NFC' END
 );
END;
$function$
;

ALTER FUNCTION public.validate_nfc_checkin(p_card_uid character varying, p_task_id uuid, p_user_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.validate_nfc_checkin(p_card_uid character varying, p_task_id uuid, p_user_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.validate_nfc_checkin(p_card_uid character varying, p_task_id uuid, p_user_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.validate_nfc_checkin(p_card_uid character varying, p_task_id uuid, p_user_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_admin_metrics(p_start date, p_end date, p_user uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_states jsonb; v_days jsonb; v_people jsonb; v_from timestamptz; v_to timestamptz;
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 THEN RAISE EXCEPTION 'Selecciona hasta 366 días'; END IF;
 IF p_user IS NOT NULL AND NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_user AND is_admin IS FALSE) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
 v_from:=p_start::timestamp AT TIME ZONE 'Europe/Madrid';
 v_to:=(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid';
 SELECT jsonb_build_object('total',count(*),'pending',count(*) FILTER(WHERE state='pending'),'active',count(*) FILTER(WHERE state='active'),
  'completed',count(*) FILTER(WHERE state='completed'),'overdue',count(*) FILTER(WHERE state IN ('pending','active') AND work_date<public.work_today()),
  'late',count(*) FILTER(WHERE state='completed' AND finished_at >= (work_date+1)::timestamp AT TIME ZONE 'Europe/Madrid'))
 INTO v_states FROM public.work_day_plan WHERE work_date BETWEEN p_start AND p_end AND (p_user IS NULL OR user_id=p_user);
 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.date),'[]'::jsonb) INTO v_days FROM (
  SELECT d::date AS date,count(p.id) AS total,count(p.id) FILTER(WHERE p.state='completed') AS completed,
   count(p.id) FILTER(WHERE p.state IN ('pending','active') AND p.work_date<public.work_today()) AS overdue
  FROM generate_series(p_start::timestamp,p_end::timestamp,interval '1 day') d
  LEFT JOIN public.work_day_plan p ON p.work_date=d::date AND (p_user IS NULL OR p.user_id=p_user)
  GROUP BY d
 ) q;
 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.seconds DESC,q.name,q.id),'[]'::jsonb) INTO v_people FROM (
  SELECT u.id,u.full_name AS name,
   (SELECT count(*) FROM public.work_day_plan p WHERE p.user_id=u.id AND p.work_date BETWEEN p_start AND p_end) AS total,
   (SELECT count(*) FROM public.work_day_plan p WHERE p.user_id=u.id AND p.work_date BETWEEN p_start AND p_end AND p.state='completed') AS completed,
   (SELECT count(*) FROM public.work_day_plan p WHERE p.user_id=u.id AND p.work_date BETWEEN p_start AND p_end AND p.state IN ('pending','active') AND p.work_date<public.work_today()) AS overdue,
   (SELECT coalesce(sum(greatest(0,extract(epoch FROM least(coalesce(c.checkout_time,now()),v_to,now())-greatest(c.checkin_time,v_from)))),0) FROM public.checkins c
    WHERE c.user_id=u.id AND c.checkin_time<v_to AND coalesce(c.checkout_time,now())>v_from) AS seconds,
   (SELECT count(*) FROM public.checkins c WHERE c.user_id=u.id AND c.checkout_time IS NULL AND c.checkin_time<least(v_to,now()) AND now()>v_from) AS open
  FROM ase_private.employee_profiles u WHERE u.is_admin IS FALSE AND (p_user IS NULL OR u.id=p_user)
 ) q;
 RETURN jsonb_build_object('states',v_states,'days',v_days,'employees',v_people,'as_of',now());
END $function$
;

ALTER FUNCTION public.work_admin_metrics(p_start date, p_end date, p_user uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_admin_metrics(p_start date, p_end date, p_user uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_admin_metrics(p_start date, p_end date, p_user uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_admin_metrics(p_start date, p_end date, p_user uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_admin_overview(p_user uuid, p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_plan jsonb; v_cards jsonb; v_stations jsonb; v_overdue jsonb;

BEGIN

 PERFORM public.work_assert_permission('planning.view');

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'task_id',p.task_id,'title',t.title,'priority',p.priority,'state',p.state,'work_date',p.work_date) || public.work_deadline(p.work_date,p.state,p.finished_at) ORDER BY p.priority),'[]'::jsonb)

 INTO v_plan FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id WHERE p.user_id=p_user AND p.work_date=p_date;

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'user_id',user_id,'label',label,'active',active)),'[]'::jsonb) INTO v_cards FROM public.work_employee_cards WHERE archived_at IS NULL;

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'active',active,'reader_mode',reader_mode)),'[]'::jsonb) INTO v_stations FROM public.work_stations WHERE archived_at IS NULL;

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'title',t.title,'work_date',p.work_date,'state',p.state) ORDER BY p.work_date,p.priority),'[]'::jsonb)
 INTO v_overdue FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id
 WHERE p.user_id=p_user AND p.work_date<public.work_today() AND p.state IN ('pending','active');
 RETURN jsonb_build_object('overdue',v_overdue,'enabled',public.work_mode(),'plan',v_plan,'cards',CASE WHEN public.sec06_is_admin() THEN v_cards ELSE '[]'::jsonb END,'stations',CASE WHEN public.sec06_is_admin() THEN v_stations ELSE '[]'::jsonb END);

END $function$
;

ALTER FUNCTION public.work_admin_overview(p_user uuid, p_date date) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_admin_overview(p_user uuid, p_date date) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_admin_overview(p_user uuid, p_date date) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_admin_overview(p_user uuid, p_date date) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_admin_productivity(p_start date, p_end date, p_task uuid, p_user uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_from timestamptz; v_to timestamptz; result jsonb;
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 THEN RAISE EXCEPTION 'Selecciona hasta 366 días'; END IF;
 IF p_task IS NULL OR NOT EXISTS(SELECT 1 FROM public.tasks WHERE id=p_task) THEN RAISE EXCEPTION 'Selecciona una actividad'; END IF;
 IF p_user IS NOT NULL AND NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_user AND is_admin IS FALSE) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
 v_from:=p_start::timestamp AT TIME ZONE 'Europe/Madrid'; v_to:=(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid';
 WITH samples AS (
  SELECT c.id,c.user_id,u.full_name AS name,c.checkin_time,c.checkout_time,
   (c.checkout_time AT TIME ZONE 'Europe/Madrid')::date AS day,
   extract(epoch FROM c.checkout_time-c.checkin_time)::double precision AS seconds
  FROM public.checkins c JOIN ase_private.employee_profiles u ON u.id=c.user_id AND u.is_admin IS FALSE
  WHERE c.task_id=p_task AND (p_user IS NULL OR c.user_id=p_user)
   AND c.checkout_time>=v_from AND c.checkout_time<v_to AND c.checkin_time IS NOT NULL AND c.checkout_time>c.checkin_time
 ), people AS (
  SELECT user_id AS id,name,count(*) AS count,sum(seconds) AS total,avg(seconds) AS average,
   percentile_cont(0.5) WITHIN GROUP(ORDER BY seconds) AS median,min(seconds) AS minimum,max(seconds) AS maximum
  FROM samples GROUP BY user_id,name
 ), daily AS (
  SELECT day,count(*) AS count,avg(seconds) AS average FROM samples GROUP BY day
 ), recent AS (
  SELECT id,user_id,name,checkin_time,checkout_time,seconds FROM samples ORDER BY checkout_time DESC,id LIMIT 200
 )
 SELECT jsonb_build_object(
  'summary',(SELECT jsonb_build_object('count',count(*),'total',coalesce(sum(seconds),0),'average',avg(seconds),'median',percentile_cont(0.5) WITHIN GROUP(ORDER BY seconds)) FROM samples),
  'employees',coalesce((SELECT jsonb_agg(to_jsonb(p) ORDER BY p.name,p.id) FROM people p),'[]'::jsonb),
  'days',coalesce((SELECT jsonb_agg(to_jsonb(d) ORDER BY d.day) FROM daily d),'[]'::jsonb),
  'recent',coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.checkout_time DESC,r.id) FROM recent r),'[]'::jsonb),
  'invalid',(SELECT count(*) FROM public.checkins c JOIN ase_private.employee_profiles u ON u.id=c.user_id AND u.is_admin IS FALSE WHERE c.task_id=p_task AND (p_user IS NULL OR c.user_id=p_user) AND c.checkout_time>=v_from AND c.checkout_time<v_to AND (c.checkin_time IS NULL OR c.checkout_time<=c.checkin_time)),
  'as_of',now()) INTO result;
 RETURN result;
END $function$
;

ALTER FUNCTION public.work_admin_productivity(p_start date, p_end date, p_task uuid, p_user uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_admin_productivity(p_start date, p_end date, p_task uuid, p_user uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_admin_productivity(p_start date, p_end date, p_task uuid, p_user uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_admin_productivity(p_start date, p_end date, p_task uuid, p_user uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_assert_admin()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
 IF NOT coalesce(public.sec06_is_admin(),false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Solo administración'; END IF;
END $function$
;

ALTER FUNCTION public.work_assert_admin() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_assert_admin() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_assert_admin() TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_assert_permission(p_key text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN IF NOT public.work_has_permission(p_key) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tu rol no tiene autorización para esta acción'; END IF; END $function$
;

ALTER FUNCTION public.work_assert_permission(p_key text) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_assert_permission(p_key text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_assert_permission(p_key text) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_assert_permission(p_key text) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_can_detail(p_task_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT public.sec06_is_admin() OR (NOT public.work_mode()) OR EXISTS(
  SELECT 1 FROM public.work_day_plan p JOIN public.checkins c ON c.work_plan_id=p.id
  JOIN public.task_assignments a ON a.task_id=p.task_id AND a.user_id=p.user_id
  WHERE p.user_id=auth.uid() AND p.task_id=p_task_id AND p.state='active' AND c.checkout_time IS NULL
 )
$function$
;

ALTER FUNCTION public.work_can_detail(p_task_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_can_detail(p_task_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_can_detail(p_task_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_can_detail(p_task_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_can_file(p_name text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_task uuid;
BEGIN
 IF NOT public.work_mode() OR public.sec06_is_admin() THEN RETURN true; END IF;
 IF p_name ~ '^tasks/[0-9a-f-]{36}/' THEN
  BEGIN v_task:=split_part(p_name,'/',2)::uuid; EXCEPTION WHEN invalid_text_representation THEN RETURN false; END;
  RETURN public.work_can_detail(v_task);
 END IF;
 RETURN EXISTS(SELECT 1 FROM public.task_comments c WHERE public.work_can_detail(c.task_id)
 AND (c.image_url=p_name OR c.video_url=p_name
 OR split_part(c.image_url,'/storage/v1/object/public/task-files/',2)=p_name
 OR split_part(c.video_url,'/storage/v1/object/public/task-files/',2)=p_name));
END $function$
;

ALTER FUNCTION public.work_can_file(p_name text) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_can_file(p_name text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_can_file(p_name text) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_can_file(p_name text) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_checkin_history(p_start date, p_end date, p_user uuid DEFAULT NULL::uuid, p_task uuid DEFAULT NULL::uuid, p_only_open boolean DEFAULT false, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50, p_personal boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result jsonb; target_user uuid;
BEGIN
 IF auth.uid() IS NULL OR p_personal IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;
 IF p_personal THEN target_user:=auth.uid(); ELSE PERFORM public.work_assert_permission('checkins.view'); target_user:=p_user; END IF;
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR p_offset IS NULL OR p_offset<0 OR p_limit IS NULL OR p_limit<1 OR p_limit>100 OR p_only_open IS NULL THEN RAISE EXCEPTION 'Filtros no válidos'; END IF;
 WITH filtered AS (
 SELECT c.id,c.task_id,c.user_id,coalesce(u.full_name,'Empleado eliminado') AS employee,t.title,c.checkin_time,c.checkout_time,c.checkin_method,c.location,
 greatest(0,extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)) AS seconds
 FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id
 WHERE (target_user IS NULL OR c.user_id=target_user) AND (p_task IS NULL OR c.task_id=p_task)
 AND (NOT p_only_open OR c.checkout_time IS NULL)
 AND c.checkin_time>=p_start::timestamp AT TIME ZONE 'Europe/Madrid' AND c.checkin_time<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
 ), page AS (SELECT * FROM filtered ORDER BY checkin_time DESC,id OFFSET p_offset LIMIT p_limit)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(to_jsonb(p) ORDER BY p.checkin_time DESC,p.id) FROM page p),'[]'::jsonb),'as_of',now()) INTO result;
 RETURN result;
END $function$
;

ALTER FUNCTION public.work_checkin_history(p_start date, p_end date, p_user uuid, p_task uuid, p_only_open boolean, p_offset integer, p_limit integer, p_personal boolean) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_checkin_history(p_start date, p_end date, p_user uuid, p_task uuid, p_only_open boolean, p_offset integer, p_limit integer, p_personal boolean) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_checkin_history(p_start date, p_end date, p_user uuid, p_task uuid, p_only_open boolean, p_offset integer, p_limit integer, p_personal boolean) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_checkin_history(p_start date, p_end date, p_user uuid, p_task uuid, p_only_open boolean, p_offset integer, p_limit integer, p_personal boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_create_credential(p_kind text, p_name text, p_user uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_result jsonb;
BEGIN
 PERFORM public.work_assert_admin();
 v_result:=public.work_create_hashed_credential(p_kind,p_name,p_user);
 IF p_kind='station' THEN
  INSERT INTO public.work_station_keys(station_id,token) VALUES((v_result->>'id')::uuid,v_result->>'token');
 ELSIF p_kind='card' THEN
  INSERT INTO public.work_employee_card_keys(card_id,token) VALUES((v_result->>'id')::uuid,v_result->>'token');
 END IF;
 RETURN v_result;
END $function$
;

ALTER FUNCTION public.work_create_credential(p_kind text, p_name text, p_user uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_create_credential(p_kind text, p_name text, p_user uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_create_credential(p_kind text, p_name text, p_user uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_create_credential(p_kind text, p_name text, p_user uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_create_hashed_credential(p_kind text, p_name text, p_user uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_token text:='ASE-'||replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-',''); v_id uuid;
BEGIN
 PERFORM public.work_assert_admin();
 IF p_kind='card' THEN
  PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND is_admin IS FALSE AND membership_status='active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
  IF EXISTS(SELECT 1 FROM public.work_employee_cards WHERE user_id=p_user AND active) THEN
   RAISE EXCEPTION 'El empleado ya tiene una tarjeta activa. Desactívala antes de crear otra';
  END IF;
  INSERT INTO public.work_employee_cards(user_id,label,token_hash) VALUES(p_user,trim(p_name),public.work_hash(v_token)) RETURNING id INTO v_id;
 ELSIF p_kind='station' THEN
  INSERT INTO public.work_stations(name,token_hash) VALUES(trim(p_name),public.work_hash(v_token)) RETURNING id INTO v_id;
 ELSE RAISE EXCEPTION 'Tipo no válido'; END IF;
 RETURN jsonb_build_object('id',v_id,'token',v_token,'kind',p_kind);
END $function$
;

ALTER FUNCTION public.work_create_hashed_credential(p_kind text, p_name text, p_user uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_create_hashed_credential(p_kind text, p_name text, p_user uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_create_hashed_credential(p_kind text, p_name text, p_user uuid) TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_deadline(p_day date, p_state text, p_finished timestamp with time zone)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
 SELECT jsonb_build_object(
  'due_at',(p_day+1)::timestamp AT TIME ZONE 'Europe/Madrid',
  'overdue',p_state IN ('pending','active') AND now()>=(p_day+1)::timestamp AT TIME ZONE 'Europe/Madrid',
  'completed_late',p_state='completed' AND p_finished>=(p_day+1)::timestamp AT TIME ZONE 'Europe/Madrid')
$function$
;

ALTER FUNCTION public.work_deadline(p_day date, p_state text, p_finished timestamp with time zone) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_deadline(p_day date, p_state text, p_finished timestamp with time zone) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_deadline(p_day date, p_state text, p_finished timestamp with time zone) TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_delete_credential(p_kind text, p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
 PERFORM public.work_assert_admin();
 IF p_kind='card' THEN
  UPDATE public.work_employee_cards SET active=false,archived_at=coalesce(archived_at,clock_timestamp()) WHERE id=p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Tarjeta no disponible'; END IF;
  UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE card_id=p_id AND result IS NULL;
 ELSIF p_kind='station' THEN
  UPDATE public.work_stations SET active=false,archived_at=coalesce(archived_at,clock_timestamp()) WHERE id=p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Punto no disponible'; END IF;
  UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE station_id=p_id AND result IS NULL;
 ELSE RAISE EXCEPTION 'Tipo no válido'; END IF;
END $function$
;

ALTER FUNCTION public.work_delete_credential(p_kind text, p_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_delete_credential(p_kind text, p_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_delete_credential(p_kind text, p_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_delete_credential(p_kind text, p_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_delete_role(p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
 PERFORM public.work_assert_admin();
 PERFORM 1 FROM public.work_roles WHERE id=p_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'El rol ya no existe'; END IF;
 IF EXISTS(SELECT 1 FROM public.work_employee_roles WHERE role_id=p_id) THEN RAISE EXCEPTION 'Hay empleados con este rol. Reasígnalos antes de eliminarlo o desactiva el rol'; END IF;
 DELETE FROM public.work_roles WHERE id=p_id;
END $function$
;

ALTER FUNCTION public.work_delete_role(p_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_delete_role(p_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_delete_role(p_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_delete_role(p_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_detail_access(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT jsonb_build_object('enabled',public.work_mode(),'allowed',auth.uid() IS NOT NULL AND public.work_can_detail(p_task_id))
$function$
;

ALTER FUNCTION public.work_detail_access(p_task_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_detail_access(p_task_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_detail_access(p_task_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_detail_access(p_task_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_employee_directory()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result jsonb;
BEGIN
 IF NOT (public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view') OR public.work_has_permission('reports.view') OR public.work_has_permission('checkins.view')) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso al directorio'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'full_name',full_name) ORDER BY full_name,id),'[]'::jsonb) INTO result FROM ase_private.employee_profiles WHERE is_admin IS FALSE AND membership_status='active';
 RETURN result;
END $function$
;

ALTER FUNCTION public.work_employee_directory() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_employee_directory() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_employee_directory() TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_employee_directory() TO authenticated;

CREATE OR REPLACE FUNCTION public.work_get_card_key(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_hash text; v_token text;
BEGIN
 PERFORM public.work_assert_admin();
 SELECT token_hash INTO v_hash FROM public.work_employee_cards WHERE id=p_id AND archived_at IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Tarjeta no disponible'; END IF;
 SELECT token INTO v_token FROM public.work_employee_card_keys WHERE card_id=p_id;
 IF v_token IS NULL OR public.work_hash(v_token)<>v_hash THEN RETURN jsonb_build_object('available',false); END IF;
 RETURN jsonb_build_object('available',true,'token',v_token);
END $function$
;

ALTER FUNCTION public.work_get_card_key(p_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_get_card_key(p_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_get_card_key(p_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_get_card_key(p_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_get_station_key(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_hash text; v_token text;
BEGIN
 PERFORM public.work_assert_admin();
 SELECT token_hash INTO v_hash FROM public.work_stations WHERE id=p_id AND archived_at IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Punto no disponible'; END IF;
 SELECT token INTO v_token FROM public.work_station_keys WHERE station_id=p_id;
 IF v_token IS NULL OR public.work_hash(v_token)<>v_hash THEN RETURN jsonb_build_object('available',false); END IF;
 RETURN jsonb_build_object('available',true,'token',v_token);
END $function$
;

ALTER FUNCTION public.work_get_station_key(p_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_get_station_key(p_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_get_station_key(p_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_get_station_key(p_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_guard_assignment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=OLD.user_id FOR UPDATE;
 IF public.work_mode() AND EXISTS(SELECT 1 FROM public.work_day_plan WHERE task_id=OLD.task_id AND user_id=OLD.user_id AND state='active') THEN
  RAISE EXCEPTION 'Finaliza la tarea en la tablet antes de cambiar su asignación';
 END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END $function$
;

ALTER FUNCTION public.work_guard_assignment() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_guard_assignment() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_guard_assignment() TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_guard_checkin()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
 PERFORM 1 FROM public.work_settings WHERE singleton FOR SHARE;
 IF public.work_mode() AND coalesce(auth.role(),'') IN ('anon','authenticated')
 AND coalesce(current_setting('ase.tablet_write',true),'')<>'on' THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='El inicio y fin de tarea se realizan en la tablet';
 END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END $function$
;

ALTER FUNCTION public.work_guard_checkin() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_guard_checkin() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_guard_checkin() TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_has_permission(p_key text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT auth.uid() IS NOT NULL AND (public.sec06_is_admin() OR EXISTS(
  SELECT 1 FROM public.work_employee_roles a JOIN public.work_roles r ON r.id=a.role_id
  WHERE a.user_id=auth.uid() AND r.active AND p_key=ANY(r.permissions)));
$function$
;

ALTER FUNCTION public.work_has_permission(p_key text) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_has_permission(p_key text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_has_permission(p_key text) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_has_permission(p_key text) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_hash(p_value text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
 SELECT encode(sha256(convert_to(p_value,'UTF8')),'hex')
$function$
;

ALTER FUNCTION public.work_hash(p_value text) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_hash(p_value text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_hash(p_value text) TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_home_summary()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE counts jsonb:='{}'; active_items jsonb:='[]'; overdue jsonb:='null';
BEGIN
 IF NOT(public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view') OR public.work_has_permission('reports.view') OR public.work_has_permission('checkins.view')) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso al resumen'; END IF;
 IF public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view') OR public.work_has_permission('reports.view') THEN
 SELECT jsonb_build_object('planned',count(*),'completed',count(*) FILTER(WHERE state='completed'),'active',count(*) FILTER(WHERE state='active'),'pending',count(*) FILTER(WHERE state='pending')) INTO counts FROM public.work_day_plan WHERE work_date=public.work_today();
 END IF;
 IF public.work_has_permission('checkins.view') THEN
 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.checkin_time),'[]'::jsonb) INTO active_items FROM (SELECT c.id,c.user_id,c.checkin_time,t.title,u.full_name AS employee FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id WHERE c.checkout_time IS NULL ORDER BY c.checkin_time LIMIT 100) q;
 END IF;
 IF public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view') THEN overdue:=public.work_overdue_items(5); END IF;
 RETURN jsonb_build_object('date',public.work_today(),'counts',counts,'working',active_items,'overdue',overdue,'as_of',now());
END $function$
;

ALTER FUNCTION public.work_home_summary() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_home_summary() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_home_summary() TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_home_summary() TO authenticated;

CREATE OR REPLACE FUNCTION public.work_legacy_actor_names(p_task_id uuid)
 RETURNS TABLE(id uuid, full_name text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_actor uuid := (SELECT auth.uid());
BEGIN
 IF v_actor IS NULL OR (SELECT auth.role()) IS DISTINCT FROM 'authenticated' THEN
   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Sesion autenticada obligatoria';
 END IF;
 IF NOT public.sec06_is_admin()
 AND NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=p_task_id AND a.user_id=v_actor) THEN
   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarea no disponible para esta cuenta';
 END IF;
 RETURN QUERY
 SELECT u.id,u.full_name FROM ase_private.employee_profiles u
 WHERE u.id IN (
   SELECT c.user_id FROM public.checkins c WHERE c.task_id=p_task_id
   UNION
   SELECT c.user_id FROM public.task_comments c WHERE c.task_id=p_task_id
 ) ORDER BY u.id;
END;
$function$
;

ALTER FUNCTION public.work_legacy_actor_names(p_task_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_legacy_actor_names(p_task_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_legacy_actor_names(p_task_id uuid) TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_manage_task(p_action text, p_id uuid DEFAULT NULL::uuid, p_title text DEFAULT NULL::text, p_description text DEFAULT NULL::text, p_schedule text DEFAULT 'daily'::text, p_date date DEFAULT NULL::date, p_status text DEFAULT 'pending'::text, p_users uuid[] DEFAULT '{}'::uuid[])
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result uuid;
BEGIN
 IF p_action IS NULL OR p_action NOT IN ('create','edit','delete') THEN RAISE EXCEPTION 'Acción no válida'; END IF;
 PERFORM public.work_assert_permission('tasks.'||p_action);
 IF p_action<>'create' THEN
  PERFORM 1 FROM public.tasks WHERE id=p_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 END IF;
 IF p_action='delete' THEN
  IF EXISTS(SELECT 1 FROM public.checkins WHERE task_id=p_id AND checkout_time IS NULL) THEN RAISE EXCEPTION 'No puedes eliminar una tarea con fichajes abiertos'; END IF;
  DELETE FROM public.tasks WHERE id=p_id; RETURN p_id;
 END IF;
 IF p_title IS NULL OR length(trim(p_title)) NOT BETWEEN 1 AND 200 OR p_status IS NULL OR p_status NOT IN ('pending','in_progress','completed') OR p_schedule IS NULL OR p_schedule NOT IN ('daily','weekly','monthly','custom_date') OR (p_schedule='custom_date' AND p_date IS NULL) THEN RAISE EXCEPTION 'Datos de tarea no válidos'; END IF;
 IF p_users IS NULL OR cardinality(p_users)>100 OR EXISTS(SELECT 1 FROM unnest(p_users) x WHERE x IS NULL OR NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=x AND is_admin IS FALSE AND membership_status='active')) THEN RAISE EXCEPTION 'Selecciona empleados válidos'; END IF;
 IF p_action='create' THEN
  INSERT INTO public.tasks(title,description,schedule_type,schedule_date,status) VALUES(trim(p_title),p_description,p_schedule,p_date,p_status) RETURNING id INTO result;
 ELSE
  UPDATE public.tasks SET title=trim(p_title),description=p_description,schedule_type=p_schedule,schedule_date=p_date,status=p_status WHERE id=p_id RETURNING id INTO result;
 END IF;
 DELETE FROM public.task_assignments WHERE task_id=result AND NOT user_id=ANY(p_users);
 INSERT INTO public.task_assignments(task_id,user_id) SELECT result,x FROM (SELECT DISTINCT unnest(p_users) x) v
 WHERE NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=result AND user_id=x);
 RETURN result;
END $function$
;

ALTER FUNCTION public.work_manage_task(p_action text, p_id uuid, p_title text, p_description text, p_schedule text, p_date date, p_status text, p_users uuid[]) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_manage_task(p_action text, p_id uuid, p_title text, p_description text, p_schedule text, p_date date, p_status text, p_users uuid[]) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_manage_task(p_action text, p_id uuid, p_title text, p_description text, p_schedule text, p_date date, p_status text, p_users uuid[]) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_manage_task(p_action text, p_id uuid, p_title text, p_description text, p_schedule text, p_date date, p_status text, p_users uuid[]) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_mode()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT enabled FROM public.work_settings WHERE singleton
$function$
;

ALTER FUNCTION public.work_mode() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_mode() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_mode() TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_mode() TO authenticated;

CREATE OR REPLACE FUNCTION public.work_my_day()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_items jsonb;

BEGIN

 IF auth.uid() IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'task_id',p.task_id,'title',t.title,'state',p.state,

  'priority',p.priority,'work_date',p.work_date,'started_at',p.started_at,'finished_at',p.finished_at,

  'can_open',p.state='active' AND public.work_can_detail(p.task_id)) || public.work_deadline(p.work_date,p.state,p.finished_at) ORDER BY p.work_date,p.priority),'[]'::jsonb)

 INTO v_items FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id

 WHERE p.user_id=auth.uid() AND (p.work_date=public.work_today() OR p.state='active' OR (p.work_date<public.work_today() AND p.state='pending'))

 AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=p.task_id AND a.user_id=p.user_id);

 RETURN jsonb_build_object('date',public.work_today(),'items',v_items);

END $function$
;

ALTER FUNCTION public.work_my_day() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_my_day() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_my_day() TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_my_day() TO authenticated;

CREATE OR REPLACE FUNCTION public.work_my_permissions()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result jsonb;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;
 IF public.sec06_is_admin() THEN RETURN jsonb_build_object('role','Administrador','permissions',ARRAY['tasks.view','tasks.create','tasks.edit','tasks.delete','planning.view','planning.edit','reports.view','checkins.view']); END IF;
 SELECT jsonb_build_object('role',r.name,'permissions',CASE WHEN r.active THEN r.permissions ELSE '{}'::text[] END) INTO result
 FROM public.work_employee_roles a JOIN public.work_roles r ON r.id=a.role_id WHERE a.user_id=auth.uid();
 RETURN coalesce(result,jsonb_build_object('role',null,'permissions','[]'::jsonb));
END $function$
;

ALTER FUNCTION public.work_my_permissions() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_my_permissions() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_my_permissions() TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_my_permissions() TO authenticated;

CREATE OR REPLACE FUNCTION public.work_overdue_items(p_limit integer DEFAULT 200)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result jsonb;
BEGIN
 IF NOT(public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view')) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso al seguimiento'; END IF;
 IF p_limit IS NULL OR p_limit<1 OR p_limit>1000 THEN RAISE EXCEPTION 'Límite no válido'; END IF;
 WITH filtered AS (SELECT p.id,p.task_id,p.user_id,p.work_date,p.state,p.priority,t.title,u.full_name AS employee FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.state IN ('pending','active') AND p.work_date<public.work_today()), page AS (SELECT * FROM filtered ORDER BY work_date,priority,id LIMIT p_limit)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(to_jsonb(p) ORDER BY p.work_date,p.priority,p.id) FROM page p),'[]'::jsonb)) INTO result;
 RETURN result;
END $function$
;

ALTER FUNCTION public.work_overdue_items(p_limit integer) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_overdue_items(p_limit integer) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_overdue_items(p_limit integer) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_overdue_items(p_limit integer) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_planning_assignments(p_user uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',t.id,'title',t.title) ORDER BY t.title,t.id),'[]'::jsonb) INTO result FROM public.tasks t WHERE EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=t.id AND a.user_id=p_user);
 RETURN result;
END $function$
;

ALTER FUNCTION public.work_planning_assignments(p_user uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_planning_assignments(p_user uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_planning_assignments(p_user uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_planning_assignments(p_user uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_planning_calendar(p_user uuid, p_start date, p_end date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>41 THEN RAISE EXCEPTION 'Selecciona hasta 42 días'; END IF;
 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.day),'[]'::jsonb) INTO result FROM (SELECT work_date AS day,count(*) AS total,count(*) FILTER(WHERE state='completed') AS completed,count(*) FILTER(WHERE state='active') AS active,count(*) FILTER(WHERE state IN ('pending','active') AND work_date<public.work_today()) AS overdue FROM public.work_day_plan WHERE user_id=p_user AND work_date BETWEEN p_start AND p_end GROUP BY work_date) q;
 RETURN result;
END $function$
;

ALTER FUNCTION public.work_planning_calendar(p_user uuid, p_start date, p_end date) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_planning_calendar(p_user uuid, p_start date, p_end date) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_planning_calendar(p_user uuid, p_start date, p_end date) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_planning_calendar(p_user uuid, p_start date, p_end date) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_revoke_credential(p_kind text, p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
 PERFORM public.work_assert_admin();
 IF p_kind='card' THEN UPDATE public.work_employee_cards SET active=false WHERE id=p_id;
 ELSIF p_kind='station' THEN UPDATE public.work_stations SET active=false WHERE id=p_id;
 ELSE RAISE EXCEPTION 'Tipo no válido'; END IF;
END $function$
;

ALTER FUNCTION public.work_revoke_credential(p_kind text, p_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_revoke_credential(p_kind text, p_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_revoke_credential(p_kind text, p_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_revoke_credential(p_kind text, p_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_roles_overview()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE roles jsonb; assignments jsonb;
BEGIN
 PERFORM public.work_assert_admin();
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',r.id,'name',r.name,'description',r.description,'active',r.active,'permissions',r.permissions,
  'employees',(SELECT count(*) FROM public.work_employee_roles a WHERE a.role_id=r.id)) ORDER BY r.active DESC,r.name,r.id),'[]'::jsonb)
 INTO roles FROM public.work_roles r;
 SELECT coalesce(jsonb_agg(jsonb_build_object('user_id',user_id,'role_id',role_id)),'[]'::jsonb) INTO assignments FROM public.work_employee_roles;
 RETURN jsonb_build_object('roles',roles,'assignments',assignments);
END $function$
;

ALTER FUNCTION public.work_roles_overview() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_roles_overview() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_roles_overview() TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_roles_overview() TO authenticated;

CREATE OR REPLACE FUNCTION public.work_rotate_card_key(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_token text:='ASE-'||replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-','');
BEGIN
 PERFORM public.work_assert_admin();
 UPDATE public.work_employee_cards SET token_hash=public.work_hash(v_token) WHERE id=p_id AND archived_at IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Tarjeta no disponible'; END IF;
 INSERT INTO public.work_employee_card_keys(card_id,token) VALUES(p_id,v_token)
 ON CONFLICT(card_id) DO UPDATE SET token=EXCLUDED.token,saved_at=clock_timestamp();
 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE card_id=p_id AND result IS NULL;
 RETURN jsonb_build_object('available',true,'token',v_token);
END $function$
;

ALTER FUNCTION public.work_rotate_card_key(p_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_rotate_card_key(p_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_rotate_card_key(p_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_rotate_card_key(p_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_rotate_station_key(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_token text:='ASE-'||replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-','');
BEGIN
 PERFORM public.work_assert_admin();
 UPDATE public.work_stations SET token_hash=public.work_hash(v_token) WHERE id=p_id AND archived_at IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Punto no disponible'; END IF;
 INSERT INTO public.work_station_keys(station_id,token) VALUES(p_id,v_token)
 ON CONFLICT(station_id) DO UPDATE SET token=EXCLUDED.token,saved_at=clock_timestamp();
 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE station_id=p_id AND result IS NULL;
 RETURN jsonb_build_object('available',true,'token',v_token);
END $function$
;

ALTER FUNCTION public.work_rotate_station_key(p_id uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_rotate_station_key(p_id uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_rotate_station_key(p_id uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_rotate_station_key(p_id uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_save_card_key(p_id uuid, p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_hash text;
BEGIN
 PERFORM public.work_assert_admin();
 SELECT token_hash INTO v_hash FROM public.work_employee_cards WHERE id=p_id AND archived_at IS NULL FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Tarjeta no disponible'; END IF;
 IF p_token IS NULL OR length(p_token)>128 OR public.work_hash(trim(p_token))<>v_hash THEN
  RAISE EXCEPTION 'El código no corresponde a este registro';
 END IF;
 INSERT INTO public.work_employee_card_keys(card_id,token) VALUES(p_id,trim(p_token))
 ON CONFLICT(card_id) DO UPDATE SET token=EXCLUDED.token,saved_at=clock_timestamp();
 RETURN jsonb_build_object('available',true,'token',trim(p_token));
END $function$
;

ALTER FUNCTION public.work_save_card_key(p_id uuid, p_token text) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_save_card_key(p_id uuid, p_token text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_save_card_key(p_id uuid, p_token text) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_save_card_key(p_id uuid, p_token text) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_save_employee_profile(p_user uuid, p_name text, p_whatsapp text, p_role uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_existing_role uuid; role_enabled boolean;
BEGIN
 PERFORM public.work_assert_admin();
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND is_admin IS FALSE FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 150 THEN RAISE EXCEPTION 'Introduce un nombre de hasta 150 caracteres'; END IF;
 IF p_whatsapp IS NOT NULL AND p_whatsapp !~ '^\+?[0-9]{7,15}$' THEN RAISE EXCEPTION 'WhatsApp no válido'; END IF;
 SELECT role_id INTO v_existing_role FROM public.work_employee_roles WHERE user_id=p_user;
 IF p_role IS NOT NULL THEN
  SELECT active INTO role_enabled FROM public.work_roles WHERE id=p_role FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'El rol seleccionado ya no existe'; END IF;
  IF NOT role_enabled AND p_role IS DISTINCT FROM v_existing_role THEN RAISE EXCEPTION 'El rol está desactivado. Selecciona otro rol activo'; END IF;
  INSERT INTO public.work_employee_roles(user_id,role_id) VALUES(p_user,p_role) ON CONFLICT(organization_id,user_id) DO UPDATE SET role_id=EXCLUDED.role_id;
 ELSE DELETE FROM public.work_employee_roles WHERE user_id=p_user;
 END IF;
 UPDATE public.organization_memberships SET full_name=trim(p_name),whatsapp=p_whatsapp,updated_at=now() WHERE organization_id=ase_private.current_org() AND user_id=p_user;
 RETURN jsonb_build_object('id',p_user,'role_id',p_role);
END $function$
;

ALTER FUNCTION public.work_save_employee_profile(p_user uuid, p_name text, p_whatsapp text, p_role uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_save_employee_profile(p_user uuid, p_name text, p_whatsapp text, p_role uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_save_employee_profile(p_user uuid, p_name text, p_whatsapp text, p_role uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_save_employee_profile(p_user uuid, p_name text, p_whatsapp text, p_role uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_save_plan(p_user uuid, p_date date, p_tasks uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

 PERFORM public.work_assert_permission('planning.edit');

 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND is_admin IS FALSE FOR UPDATE;

 IF NOT FOUND OR p_date IS NULL OR p_tasks IS NULL OR cardinality(p_tasks)>100 THEN RAISE EXCEPTION 'Plan no válido'; END IF;

 IF cardinality(p_tasks)<>(SELECT count(DISTINCT x) FROM unnest(p_tasks) x)

 OR EXISTS(SELECT 1 FROM unnest(p_tasks) x WHERE x IS NULL OR NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.user_id=p_user AND a.task_id=x)) THEN

  RAISE EXCEPTION 'Solo tareas asignadas, sin duplicados';

 END IF;

 IF EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.user_id=p_user AND p.work_date=p_date AND p.state<>'pending' AND NOT p.task_id=ANY(p_tasks)) THEN

  RAISE EXCEPTION 'No se pueden retirar tareas iniciadas o completadas';

 END IF;

 -- Conservar el historial y no colocar pendientes antes de las ya iniciadas.

 IF EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.user_id=p_user AND p.work_date=p_date AND p.state<>'pending'

  AND array_position(p_tasks,p.task_id) IS DISTINCT FROM p.priority) THEN

  RAISE EXCEPTION 'El orden de las tareas iniciadas o completadas está bloqueado';

 END IF;

 DELETE FROM public.work_day_plan WHERE user_id=p_user AND work_date=p_date AND state='pending' AND NOT task_id=ANY(p_tasks);

 INSERT INTO public.work_day_plan(user_id,task_id,work_date,priority)

 SELECT p_user,x,p_date,n::integer FROM unnest(p_tasks) WITH ORDINALITY AS v(x,n)

 ON CONFLICT(organization_id,user_id,task_id,work_date) DO UPDATE SET priority=EXCLUDED.priority;

END $function$
;

ALTER FUNCTION public.work_save_plan(p_user uuid, p_date date, p_tasks uuid[]) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_save_plan(p_user uuid, p_date date, p_tasks uuid[]) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_save_plan(p_user uuid, p_date date, p_tasks uuid[]) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_save_plan(p_user uuid, p_date date, p_tasks uuid[]) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_save_plan_range(p_user uuid, p_start date, p_end date, p_tasks uuid[], p_weekdays integer[], p_existing text DEFAULT 'empty'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE d date; existing_tasks uuid[]; merged uuid[]; changed integer:=0; skipped integer:=0;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND is_admin IS FALSE FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 THEN RAISE EXCEPTION 'Selecciona un intervalo de hasta 366 días'; END IF;
 IF p_existing IS NULL OR p_existing NOT IN ('empty','append') THEN RAISE EXCEPTION 'Opción no válida'; END IF;
 IF p_tasks IS NULL OR cardinality(p_tasks)=0 OR cardinality(p_tasks)>100 OR cardinality(p_tasks)<>(SELECT count(DISTINCT x) FROM unnest(p_tasks) x)
 OR EXISTS(SELECT 1 FROM unnest(p_tasks) x WHERE x IS NULL OR NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.user_id=p_user AND a.task_id=x)) THEN RAISE EXCEPTION 'Selecciona tareas asignadas sin duplicados'; END IF;
 IF p_weekdays IS NULL OR cardinality(p_weekdays)=0 OR EXISTS(SELECT 1 FROM unnest(p_weekdays) x WHERE x IS NULL OR x<1 OR x>7) THEN RAISE EXCEPTION 'Selecciona días de la semana'; END IF;
 FOR d IN SELECT p_start+i FROM generate_series(0,p_end-p_start) i LOOP
  IF NOT extract(isodow FROM d)::integer=ANY(p_weekdays) THEN CONTINUE; END IF;
  SELECT coalesce(array_agg(task_id ORDER BY priority),'{}'::uuid[]) INTO existing_tasks FROM public.work_day_plan WHERE user_id=p_user AND work_date=d;
  IF cardinality(existing_tasks)>0 AND p_existing='empty' THEN skipped:=skipped+1; CONTINUE; END IF;
  SELECT existing_tasks || coalesce(array_agg(x ORDER BY n),'{}'::uuid[]) INTO merged FROM unnest(p_tasks) WITH ORDINALITY v(x,n) WHERE NOT x=ANY(existing_tasks);
  IF merged=existing_tasks THEN skipped:=skipped+1; CONTINUE; END IF;
  PERFORM public.work_save_plan(p_user,d,merged);
  changed:=changed+1;
 END LOOP;
 RETURN jsonb_build_object('changed',changed,'skipped',skipped);
END $function$
;

ALTER FUNCTION public.work_save_plan_range(p_user uuid, p_start date, p_end date, p_tasks uuid[], p_weekdays integer[], p_existing text) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_save_plan_range(p_user uuid, p_start date, p_end date, p_tasks uuid[], p_weekdays integer[], p_existing text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_save_plan_range(p_user uuid, p_start date, p_end date, p_tasks uuid[], p_weekdays integer[], p_existing text) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_save_plan_range(p_user uuid, p_start date, p_end date, p_tasks uuid[], p_weekdays integer[], p_existing text) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_save_role(p_id uuid, p_name text, p_description text, p_active boolean DEFAULT true)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result uuid;
BEGIN
 PERFORM public.work_assert_admin();
 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 80 OR length(coalesce(p_description,''))>500 OR p_active IS NULL THEN RAISE EXCEPTION 'Introduce un nombre de hasta 80 caracteres y una descripción de hasta 500'; END IF;
 IF p_id IS NULL THEN
  INSERT INTO public.work_roles(name,description,active) VALUES(trim(p_name),trim(coalesce(p_description,'')),p_active) RETURNING id INTO result;
 ELSE
  UPDATE public.work_roles SET name=trim(p_name),description=trim(coalesce(p_description,'')),active=p_active WHERE id=p_id RETURNING id INTO result;
  IF result IS NULL THEN RAISE EXCEPTION 'El rol ya no existe'; END IF;
 END IF;
 RETURN result;
EXCEPTION WHEN unique_violation THEN RAISE EXCEPTION 'Ya existe un rol con ese nombre';
END $function$
;

ALTER FUNCTION public.work_save_role(p_id uuid, p_name text, p_description text, p_active boolean) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_save_role(p_id uuid, p_name text, p_description text, p_active boolean) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_save_role(p_id uuid, p_name text, p_description text, p_active boolean) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_save_role(p_id uuid, p_name text, p_description text, p_active boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_save_station_key(p_id uuid, p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_hash text;
BEGIN
 PERFORM public.work_assert_admin();
 SELECT token_hash INTO v_hash FROM public.work_stations WHERE id=p_id AND archived_at IS NULL FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Punto no disponible'; END IF;
 IF p_token IS NULL OR length(p_token)>128 OR public.work_hash(trim(p_token))<>v_hash THEN
  RAISE EXCEPTION 'El código no corresponde a este registro';
 END IF;
 INSERT INTO public.work_station_keys(station_id,token) VALUES(p_id,trim(p_token))
 ON CONFLICT(station_id) DO UPDATE SET token=EXCLUDED.token,saved_at=clock_timestamp();
 RETURN jsonb_build_object('available',true,'token',trim(p_token));
END $function$
;

ALTER FUNCTION public.work_save_station_key(p_id uuid, p_token text) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_save_station_key(p_id uuid, p_token text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_save_station_key(p_id uuid, p_token text) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_save_station_key(p_id uuid, p_token text) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_set_card_active(p_id uuid, p_active boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid;
BEGIN
 PERFORM public.work_assert_admin();
 IF p_active IS NULL THEN RAISE EXCEPTION 'Estado no vÃ¡lido'; END IF;
 -- Mismo orden de bloqueo que una confirmaciÃ³n de fichaje: tarjeta y empleado.
 SELECT user_id INTO v_user FROM public.work_employee_cards WHERE id=p_id AND archived_at IS NULL FOR UPDATE;
 IF v_user IS NULL THEN RAISE EXCEPTION 'Tarjeta no disponible'; END IF;
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=v_user AND is_admin IS FALSE FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 IF p_active AND EXISTS(SELECT 1 FROM public.work_employee_cards WHERE user_id=v_user AND active AND id<>p_id) THEN
  RAISE EXCEPTION 'Desactiva primero la otra tarjeta activa del empleado';
 END IF;
 UPDATE public.work_employee_cards SET active=p_active WHERE id=p_id;
 -- Una identificaciÃ³n emitida antes del cambio no se puede reutilizar al reactivar.
 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second'
 WHERE card_id=p_id AND result IS NULL;
END $function$
;

ALTER FUNCTION public.work_set_card_active(p_id uuid, p_active boolean) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_set_card_active(p_id uuid, p_active boolean) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_set_card_active(p_id uuid, p_active boolean) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_set_card_active(p_id uuid, p_active boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_set_mode(p_enabled boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
 PERFORM public.work_assert_admin();
 -- También lo toman los RPC de fichaje; evita activar/desactivar durante una escritura.
 PERFORM 1 FROM public.work_settings WHERE singleton FOR UPDATE;
 IF p_enabled IS NULL THEN RAISE EXCEPTION 'Modo no válido'; END IF;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE checkout_time IS NULL)
 OR EXISTS(SELECT 1 FROM public.work_day_plan WHERE state='active') THEN
  RAISE EXCEPTION 'Finaliza primero todos los fichajes abiertos';
 END IF;
 UPDATE public.work_settings SET enabled=p_enabled WHERE singleton;
END $function$
;

ALTER FUNCTION public.work_set_mode(p_enabled boolean) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_set_mode(p_enabled boolean) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_set_mode(p_enabled boolean) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_set_mode(p_enabled boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_set_role_permissions(p_id uuid, p_permissions text[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE keys text[];
BEGIN
 PERFORM public.work_assert_admin();
 IF p_permissions IS NULL OR EXISTS(SELECT 1 FROM unnest(p_permissions) x WHERE x IS NULL OR x NOT IN ('tasks.view','tasks.create','tasks.edit','tasks.delete','planning.view','planning.edit','reports.view','checkins.view')) THEN RAISE EXCEPTION 'Autorización no válida'; END IF;
 keys:=p_permissions;
 IF keys && ARRAY['tasks.create','tasks.edit','tasks.delete'] THEN keys:=array_append(keys,'tasks.view'); END IF;
 IF 'planning.edit'=ANY(keys) THEN keys:=array_append(keys,'planning.view'); END IF;
 SELECT coalesce(array_agg(DISTINCT x),'{}'::text[]) INTO keys FROM unnest(keys) x;
 UPDATE public.work_roles SET permissions=keys WHERE id=p_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'El rol ya no existe'; END IF;
END $function$
;

ALTER FUNCTION public.work_set_role_permissions(p_id uuid, p_permissions text[]) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_set_role_permissions(p_id uuid, p_permissions text[]) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_set_role_permissions(p_id uuid, p_permissions text[]) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_set_role_permissions(p_id uuid, p_permissions text[]) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_set_station_active(p_id uuid, p_active boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
 PERFORM public.work_assert_admin();
 IF p_active IS NULL THEN RAISE EXCEPTION 'Estado no vÃ¡lido'; END IF;
 UPDATE public.work_stations SET active=p_active WHERE id=p_id AND archived_at IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Punto no disponible'; END IF;
 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second'
 WHERE station_id=p_id AND result IS NULL;
 -- No modifica checkins ni estados de tareas en curso.
END $function$
;

ALTER FUNCTION public.work_set_station_active(p_id uuid, p_active boolean) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_set_station_active(p_id uuid, p_active boolean) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_set_station_active(p_id uuid, p_active boolean) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_set_station_active(p_id uuid, p_active boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.work_station_confirm(p_station text, p_ticket uuid, p_action text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE s public.work_stations%ROWTYPE; k public.work_station_tickets%ROWTYPE; p public.work_day_plan%ROWTYPE;

 v_checkin uuid; v_time timestamptz:=clock_timestamp(); v_result jsonb;

BEGIN
 PERFORM ase_private.bind_station(p_station);

 PERFORM 1 FROM public.work_settings WHERE singleton FOR SHARE;

 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;

 SELECT * INTO s FROM public.work_stations WHERE token_hash=public.work_hash(p_station) AND active FOR SHARE;

 IF s.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto no disponible'; END IF;

 SELECT * INTO k FROM public.work_station_tickets WHERE id=p_ticket AND station_id=s.id FOR UPDATE;

 IF k.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Vuelve a pasar tu tarjeta'; END IF;

 IF p_action IS NULL OR p_action NOT IN ('start','finish') OR p_action<>k.expected_action THEN RAISE EXCEPTION 'Acción no válida'; END IF;

 IF k.result IS NOT NULL THEN RETURN k.result; END IF;

 IF k.expires_at<=v_time THEN RAISE EXCEPTION 'La identificación ha caducado. Vuelve a pasar tu tarjeta'; END IF;

 PERFORM 1 FROM public.work_employee_cards WHERE id=k.card_id AND user_id=k.user_id AND active FOR SHARE;

 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarjeta desactivada'; END IF;

 PERFORM 1 FROM ase_private.employee_profiles WHERE id=k.user_id AND is_admin IS FALSE AND membership_status='active' FOR UPDATE;

 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;

 SELECT * INTO p FROM public.work_day_plan WHERE id=k.plan_id AND user_id=k.user_id FOR UPDATE;

 IF p.id IS NULL OR NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=p.task_id AND user_id=p.user_id) THEN RAISE EXCEPTION 'Asignación no disponible'; END IF;

 PERFORM set_config('ase.tablet_write','on',true);

 IF p_action='start' THEN

  IF p.state<>'pending' OR p.work_date<>public.work_today()

  OR EXISTS(SELECT 1 FROM public.work_day_plan WHERE user_id=p.user_id AND state='active')

  OR EXISTS(SELECT 1 FROM public.checkins WHERE user_id=p.user_id AND checkout_time IS NULL)

  OR EXISTS(SELECT 1 FROM public.work_day_plan WHERE user_id=p.user_id AND work_date=p.work_date AND state='pending' AND priority<p.priority) THEN

   RAISE EXCEPTION 'El estado cambió. Vuelve a pasar tu tarjeta';

  END IF;

  -- La prueba del lector se registra honestamente como manual, nunca como NFC físico.

  INSERT INTO public.checkins(task_id,user_id,checkin_time,checkin_method,location,work_plan_id,work_station_id,employee_card_id)

  VALUES(p.task_id,p.user_id,v_time,'manual','Tablet · lectura por código',p.id,s.id,k.card_id) RETURNING id INTO v_checkin;

  UPDATE public.work_day_plan SET state='active',started_at=v_time WHERE id=p.id;

 ELSE

  IF p.state<>'active' THEN RAISE EXCEPTION 'La tarea ya no está en curso. Vuelve a pasar tu tarjeta'; END IF;

  UPDATE public.checkins SET checkout_time=v_time WHERE work_plan_id=p.id AND user_id=p.user_id AND checkout_time IS NULL AND checkin_time<=v_time RETURNING id INTO v_checkin;

  IF v_checkin IS NULL THEN RAISE EXCEPTION 'No se pudo confirmar la salida'; END IF;

  UPDATE public.work_day_plan SET state='completed',finished_at=v_time WHERE id=p.id;

 END IF;

 PERFORM set_config('ase.tablet_write','off',true);

 v_result:=jsonb_build_object('success',true,'action',p_action,'checkin_id',v_checkin,'time',v_time);

 UPDATE public.work_station_tickets SET result=v_result WHERE id=k.id;

 RETURN v_result;

END $function$
;

ALTER FUNCTION public.work_station_confirm(p_station text, p_ticket uuid, p_action text) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_station_confirm(p_station text, p_ticket uuid, p_action text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_station_confirm(p_station text, p_ticket uuid, p_action text) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_station_confirm(p_station text, p_ticket uuid, p_action text) TO authenticated;

GRANT EXECUTE ON FUNCTION public.work_station_confirm(p_station text, p_ticket uuid, p_action text) TO anon;

CREATE OR REPLACE FUNCTION public.work_station_day(p_station text, p_ticket uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid; v_items jsonb; v_name text;
BEGIN
 PERFORM ase_private.bind_station(p_station);
 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;
 SELECT k.user_id,u.full_name INTO v_user,v_name
 FROM public.work_station_tickets k
 JOIN public.work_stations s ON s.id=k.station_id AND s.active
 JOIN public.work_employee_cards c ON c.id=k.card_id AND c.active AND c.user_id=k.user_id
 JOIN ase_private.employee_profiles u ON u.id=k.user_id AND u.is_admin IS FALSE AND u.membership_status='active'
 WHERE k.id=p_ticket AND s.token_hash=public.work_hash(p_station) AND k.expires_at>clock_timestamp();
 IF v_user IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Vuelve a identificarte para consultar tus tareas'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'title',t.title,'state',p.state,
  'priority',p.priority,'work_date',p.work_date) || public.work_deadline(p.work_date,p.state,p.finished_at) ORDER BY p.work_date,p.priority),'[]'::jsonb)
 INTO v_items FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id
 WHERE p.user_id=v_user AND (p.work_date=public.work_today() OR p.state='active' OR (p.work_date<public.work_today() AND p.state='pending'))
 AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=p.task_id AND a.user_id=p.user_id);
 RETURN jsonb_build_object('employee',v_name,'date',public.work_today(),'items',v_items);
END $function$
;

ALTER FUNCTION public.work_station_day(p_station text, p_ticket uuid) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_station_day(p_station text, p_ticket uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_station_day(p_station text, p_ticket uuid) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_station_day(p_station text, p_ticket uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.work_station_day(p_station text, p_ticket uuid) TO anon;

CREATE OR REPLACE FUNCTION public.work_station_identify(p_station text, p_card text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE s public.work_stations%ROWTYPE; c public.work_employee_cards%ROWTYPE; p public.work_day_plan%ROWTYPE;
 v_ticket uuid; v_action text:='none'; v_name text; v_title text; v_description text;
BEGIN
 PERFORM ase_private.bind_station(p_station);
 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;
 SELECT * INTO s FROM public.work_stations WHERE token_hash=public.work_hash(p_station) AND active FOR UPDATE;
 SELECT * INTO c FROM public.work_employee_cards WHERE token_hash=public.work_hash(p_card) AND active;
 IF s.id IS NULL OR c.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto o tarjeta no disponible'; END IF;
 SELECT full_name INTO v_name FROM ase_private.employee_profiles WHERE id=c.user_id AND is_admin IS FALSE AND membership_status='active';
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarjeta no disponible'; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE user_id=c.user_id AND state='active';
 IF p.id IS NOT NULL THEN v_action:='finish';
 ELSE
  SELECT x.* INTO p FROM public.work_day_plan x WHERE x.user_id=c.user_id AND x.work_date=public.work_today() AND x.state='pending'
   ORDER BY x.priority LIMIT 1;
  IF p.id IS NOT NULL THEN v_action:='start'; END IF;
 END IF;
 IF p.id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE user_id=c.user_id AND task_id=p.task_id) THEN
  RAISE EXCEPTION 'La asignación cambió. Consulta al encargado';
 END IF;
 SELECT title,description INTO v_title,v_description FROM public.tasks WHERE id=p.task_id;
 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE station_id=s.id AND result IS NULL;
 DELETE FROM public.work_station_tickets WHERE expires_at<now()-interval '7 days';
 INSERT INTO public.work_station_tickets(station_id,card_id,user_id,plan_id,expected_action)
 VALUES(s.id,c.id,c.user_id,p.id,v_action) RETURNING id INTO v_ticket;
 RETURN jsonb_build_object('ticket',v_ticket,'employee',v_name,'title',v_title,'description',v_description,'action',v_action,
  'started_at',p.started_at,'reader_mode',s.reader_mode);
END $function$
;

ALTER FUNCTION public.work_station_identify(p_station text, p_card text) OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_station_identify(p_station text, p_card text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_station_identify(p_station text, p_card text) TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_station_identify(p_station text, p_card text) TO authenticated;

GRANT EXECUTE ON FUNCTION public.work_station_identify(p_station text, p_card text) TO anon;

CREATE OR REPLACE FUNCTION public.work_task_catalog()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 SELECT coalesce(jsonb_agg(to_jsonb(t)||jsonb_build_object('assigned_users',coalesce((SELECT jsonb_agg(jsonb_build_object('id',u.id,'full_name',u.full_name) ORDER BY u.full_name,u.id) FROM public.task_assignments a JOIN ase_private.employee_profiles u ON u.id=a.user_id WHERE a.task_id=t.id),'[]'::jsonb)) ORDER BY t.created_at DESC,t.id),'[]'::jsonb) INTO result FROM public.tasks t;
 RETURN result;
END $function$
;

ALTER FUNCTION public.work_task_catalog() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_task_catalog() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_task_catalog() TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_task_catalog() TO authenticated;

CREATE OR REPLACE FUNCTION public.work_task_options()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result jsonb;
BEGIN
 IF NOT (public.work_has_permission('tasks.view') OR public.work_has_permission('reports.view') OR public.work_has_permission('checkins.view')) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso a las actividades'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'title',title) ORDER BY title,id),'[]'::jsonb) INTO result FROM public.tasks;
 RETURN result;
END $function$
;

ALTER FUNCTION public.work_task_options() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_task_options() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_task_options() TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_task_options() TO authenticated;

CREATE OR REPLACE FUNCTION public.work_today()
 RETURNS date
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
 SELECT (now() AT TIME ZONE 'Europe/Madrid')::date
$function$
;

ALTER FUNCTION public.work_today() OWNER TO ase_tenant_executor;

REVOKE ALL ON FUNCTION public.work_today() FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.work_today() TO ase_tenant_executor;

GRANT EXECUTE ON FUNCTION public.work_today() TO authenticated;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
SET search_path TO ''
AS $function$

BEGIN

  INSERT INTO public.users (id, email, full_name, is_admin)

  VALUES (

    NEW.id,

    NEW.email,

    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario Nuevo'),

    FALSE

  );

  RETURN NEW;

END;

$function$
;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION public.sync_confirmed_auth_email()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

  IF NEW.email IS NOT NULL AND NEW.email IS DISTINCT FROM OLD.email THEN

    UPDATE public.users SET email = NEW.email WHERE id = NEW.id;

  END IF;

  RETURN NEW;

END;

$function$
;

REVOKE ALL ON FUNCTION public.sync_confirmed_auth_email() FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION public.sec01_guard_is_admin()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$

BEGIN

  -- No confiar en campos enviados por el navegador.

  -- auth.role() procede del contexto JWT validado por la API.

  -- Los cambios reales por anon/authenticated quedan bloqueados incluso

  -- cuando la cuenta tiene is_admin=true en public.users.

  IF NEW.is_admin IS DISTINCT FROM OLD.is_admin

     AND (SELECT auth.role()) IN ('anon', 'authenticated') THEN

    RAISE EXCEPTION USING

      ERRCODE = '42501',

      MESSAGE = 'El rol de administrador solo puede cambiarse mediante un canal administrativo seguro';

  END IF;

  RETURN NEW;

END;

$function$
;

REVOKE ALL ON FUNCTION public.sec01_guard_is_admin() FROM PUBLIC,anon,authenticated;

DROP POLICY "Enable delete for admins" ON public.checkins;

DROP POLICY "sec05_insert_own_assigned_manual_checkin" ON public.checkins;

DROP POLICY "sec05_read_assigned_checkins_or_admin" ON public.checkins;

DROP POLICY "Admins can manage NFC cards" ON public.nfc_cards;

DROP POLICY "Employees can view NFC cards for assigned tasks" ON public.nfc_cards;

DROP POLICY "Admins can manage access codes" ON public.task_access_codes;

DROP POLICY "Users can view active codes for their tasks" ON public.task_access_codes;

DROP POLICY "Enable delete for admins" ON public.task_assignments;

DROP POLICY "Enable insert for admins" ON public.task_assignments;

DROP POLICY "sec05_read_own_assignments_or_admin" ON public.task_assignments;

DROP POLICY "Admins can manage checkin config" ON public.task_checkin_config;

DROP POLICY "Employees can view checkin config for assigned tasks" ON public.task_checkin_config;

DROP POLICY "Users can insert comments on their tasks" ON public.task_comments;

DROP POLICY "Users can view comments on their tasks" ON public.task_comments;

DROP POLICY "Enable delete for admins" ON public.tasks;

DROP POLICY "Enable insert for admins" ON public.tasks;

DROP POLICY "Enable update for admins and assigned employees" ON public.tasks;

DROP POLICY "sec05_read_assigned_tasks_or_admin" ON public.tasks;

CREATE POLICY mt_read ON public.tasks FOR SELECT TO authenticated USING(public.sec06_is_admin() OR EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=tasks.id AND a.user_id=auth.uid()));

CREATE POLICY mt_read ON public.task_assignments FOR SELECT TO authenticated USING(public.sec06_is_admin() OR user_id=auth.uid());

CREATE POLICY mt_read ON public.checkins FOR SELECT TO authenticated USING(public.sec06_is_admin() OR EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=checkins.task_id AND a.user_id=auth.uid()));

CREATE POLICY mt_read ON public.task_comments FOR SELECT TO authenticated USING(EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=task_comments.task_id AND a.user_id=auth.uid()));

CREATE POLICY mt_read ON public.nfc_cards FOR SELECT TO authenticated USING(public.sec06_is_admin() OR EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=nfc_cards.task_id AND a.user_id=auth.uid()));

CREATE POLICY mt_read ON public.task_checkin_config FOR SELECT TO authenticated USING(public.sec06_is_admin() OR EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=task_checkin_config.task_id AND a.user_id=auth.uid()));

CREATE POLICY mt_read ON public.task_access_codes FOR SELECT TO authenticated USING(public.sec06_is_admin() OR (is_active AND (expires_at IS NULL OR expires_at>now()) AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=task_access_codes.task_id AND a.user_id=auth.uid())));

CREATE POLICY mt_admin_insert ON public.tasks FOR INSERT TO authenticated WITH CHECK(public.sec06_is_admin());

CREATE POLICY mt_admin_update ON public.tasks FOR UPDATE TO authenticated USING(public.sec06_is_admin()) WITH CHECK(public.sec06_is_admin());

CREATE POLICY mt_admin_delete ON public.tasks FOR DELETE TO authenticated USING(public.sec06_is_admin());

CREATE POLICY mt_admin_insert ON public.task_assignments FOR INSERT TO authenticated WITH CHECK(public.sec06_is_admin());

CREATE POLICY mt_admin_update ON public.task_assignments FOR UPDATE TO authenticated USING(public.sec06_is_admin()) WITH CHECK(public.sec06_is_admin());

CREATE POLICY mt_admin_delete ON public.task_assignments FOR DELETE TO authenticated USING(public.sec06_is_admin());

CREATE POLICY mt_admin_insert ON public.nfc_cards FOR INSERT TO authenticated WITH CHECK(public.sec06_is_admin());

CREATE POLICY mt_admin_update ON public.nfc_cards FOR UPDATE TO authenticated USING(public.sec06_is_admin()) WITH CHECK(public.sec06_is_admin());

CREATE POLICY mt_admin_delete ON public.nfc_cards FOR DELETE TO authenticated USING(public.sec06_is_admin());

CREATE POLICY mt_admin_insert ON public.task_checkin_config FOR INSERT TO authenticated WITH CHECK(public.sec06_is_admin());

CREATE POLICY mt_admin_update ON public.task_checkin_config FOR UPDATE TO authenticated USING(public.sec06_is_admin()) WITH CHECK(public.sec06_is_admin());

CREATE POLICY mt_admin_delete ON public.task_checkin_config FOR DELETE TO authenticated USING(public.sec06_is_admin());

CREATE POLICY mt_admin_insert ON public.task_access_codes FOR INSERT TO authenticated WITH CHECK(public.sec06_is_admin());

CREATE POLICY mt_admin_update ON public.task_access_codes FOR UPDATE TO authenticated USING(public.sec06_is_admin()) WITH CHECK(public.sec06_is_admin());

CREATE POLICY mt_admin_delete ON public.task_access_codes FOR DELETE TO authenticated USING(public.sec06_is_admin());

CREATE POLICY mt_comment_insert ON public.task_comments FOR INSERT TO authenticated WITH CHECK(user_id=auth.uid() AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=task_comments.task_id AND a.user_id=auth.uid()));

CREATE POLICY mt_manual_insert ON public.checkins FOR INSERT TO authenticated WITH CHECK(work_plan_id IS NULL AND work_station_id IS NULL AND employee_card_id IS NULL AND ((user_id = ( SELECT auth.uid() AS uid)) AND (task_id IS NOT NULL) AND ((checkin_method)::text = 'manual'::text) AND (checkout_time IS NULL) AND (nfc_card_id IS NULL) AND (EXISTS ( SELECT 1
   FROM task_assignments a
  WHERE ((a.task_id = checkins.task_id) AND (a.user_id = ( SELECT auth.uid() AS uid))))) AND (EXISTS ( SELECT 1
   FROM task_checkin_config c
  WHERE ((c.task_id = checkins.task_id) AND (c.manual_enabled IS TRUE))))));

CREATE POLICY mt_checkin_delete ON public.checkins FOR DELETE TO authenticated USING(public.sec06_is_admin());

DROP POLICY IF EXISTS "sec04_read_assigned_task_files" ON storage.objects;

CREATE POLICY "sec04_read_assigned_task_files" ON storage.objects AS PERMISSIVE FOR SELECT TO authenticated USING (((bucket_id = 'task-files'::text) AND (((name ~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov)$'::text) AND (EXISTS ( SELECT 1
   FROM task_assignments a
  WHERE (((a.task_id)::text = split_part(objects.name, '/'::text, 2)) AND (a.user_id = ( SELECT auth.uid() AS uid)))))) OR ((name ~ '^(images|videos)/[0-9a-f-]{36}-[0-9]+\.[a-z0-9]+$'::text) AND (EXISTS ( SELECT 1
   FROM (task_comments c
     JOIN task_assignments a ON ((a.task_id = c.task_id)))
  WHERE ((a.user_id = ( SELECT auth.uid() AS uid)) AND (((strpos(c.image_url, '/storage/v1/object/public/task-files/'::text) > 0) AND (split_part(c.image_url, '/storage/v1/object/public/task-files/'::text, 2) = objects.name)) OR ((strpos(c.video_url, '/storage/v1/object/public/task-files/'::text) > 0) AND (split_part(c.video_url, '/storage/v1/object/public/task-files/'::text, 2) = objects.name))))))))));

DROP POLICY IF EXISTS "sec04_upload_own_assigned_task_files" ON storage.objects;

CREATE POLICY "sec04_upload_own_assigned_task_files" ON storage.objects AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((bucket_id = 'task-files'::text) AND (name ~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov)$'::text) AND (split_part(name, '/'::text, 3) = (( SELECT auth.uid() AS uid))::text) AND (EXISTS ( SELECT 1
   FROM task_assignments a
  WHERE (((a.task_id)::text = split_part(objects.name, '/'::text, 2)) AND (a.user_id = ( SELECT auth.uid() AS uid)))))));

DROP POLICY IF EXISTS "work_files_insert" ON storage.objects;

CREATE POLICY "work_files_insert" ON storage.objects AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((bucket_id <> 'task-files'::text) OR work_can_file(name)));

DROP POLICY IF EXISTS "work_files_read" ON storage.objects;

CREATE POLICY "work_files_read" ON storage.objects AS RESTRICTIVE FOR SELECT TO authenticated USING (((bucket_id <> 'task-files'::text) OR work_can_file(name)));

REVOKE ALL ON FUNCTION public.create_task_checkin_config() FROM anon,authenticated;

REVOKE ALL ON FUNCTION public.sec04_validate_comment_attachment() FROM anon,authenticated;

REVOKE ALL ON FUNCTION public.work_guard_assignment() FROM anon,authenticated;

REVOKE ALL ON FUNCTION public.work_guard_checkin() FROM anon,authenticated;

REVOKE ALL ON FUNCTION public.work_create_hashed_credential(p_kind text, p_name text, p_user uuid) FROM anon,authenticated;

-- No API path may use the old employment flag as a global tenant authority.
-- Historical original values are retained privately for reconciliation and recovery.
CREATE TABLE ase_private.legacy_admin_flags AS SELECT id,is_admin FROM public.users;
REVOKE ALL ON ase_private.legacy_admin_flags FROM PUBLIC,anon,authenticated,ase_tenant_executor;
UPDATE public.users SET is_admin=false WHERE is_admin IS TRUE;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM PUBLIC,anon,authenticated;
REVOKE TRUNCATE,REFERENCES,TRIGGER ON storage.objects FROM anon,authenticated;
NOTIFY pgrst,'reload schema';



-- Section: 202610220002_employee_identity.sql
-- Requires the tenant boundary. Privileged Auth operations are restricted to server functions.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE TABLE ase_private.email_changes(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL UNIQUE,
 organization_id uuid NOT NULL REFERENCES public.organizations(id),actor_id uuid NOT NULL,
 email text NOT NULL,expires_at timestamptz NOT NULL DEFAULT clock_timestamp()+interval '5 minutes'
);
REVOKE ALL ON ase_private.email_changes FROM PUBLIC,anon,authenticated,ase_tenant_executor;

CREATE FUNCTION ase_private.guard_membership() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE target uuid;
BEGIN
 target:=CASE WHEN TG_OP='DELETE' THEN OLD.user_id ELSE NEW.user_id END;
 PERFORM pg_advisory_xact_lock(hashtextextended(target::text,1701));
 IF EXISTS(SELECT 1 FROM ase_private.email_changes WHERE user_id=target AND expires_at>clock_timestamp()) THEN
  RAISE EXCEPTION USING ERRCODE='23514',MESSAGE='Cambio de correo en curso. Vuelve a intentarlo en unos minutos';
 END IF;
 IF TG_OP='UPDATE' AND (NEW.user_id IS DISTINCT FROM OLD.user_id OR NEW.organization_id IS DISTINCT FROM OLD.organization_id) THEN
  RAISE EXCEPTION 'La pertenencia no se puede trasladar';
 END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 IF TG_OP='UPDATE' THEN NEW.updated_at:=clock_timestamp(); END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION ase_private.guard_membership() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER mt_membership_identity BEFORE INSERT OR UPDATE OR DELETE ON public.organization_memberships
 FOR EACH ROW EXECUTE FUNCTION ase_private.guard_membership();

CREATE FUNCTION public.mt_employees() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_admin();
 SELECT coalesce(jsonb_agg(to_jsonb(p)-'membership_status' ORDER BY p.created_at DESC,p.id),'[]'::jsonb) INTO result
 FROM ase_private.employee_profiles p WHERE p.is_admin IS FALSE AND p.membership_status='active';
 RETURN result;
END $$;
ALTER FUNCTION public.mt_employees() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.mt_employees() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.mt_employees() TO authenticated,ase_tenant_executor;

CREATE FUNCTION public.mt_employee_reset_target(p_user uuid) RETURNS text LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result text;
BEGIN
 PERFORM public.work_assert_admin();
 SELECT email INTO result FROM ase_private.employee_profiles WHERE id=p_user AND NOT is_admin AND membership_status='active';
 IF result IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Empleado no disponible'; END IF;
 RETURN result;
END $$;
ALTER FUNCTION public.mt_employee_reset_target(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.mt_employee_reset_target(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.mt_employee_reset_target(uuid) TO authenticated,ase_tenant_executor;

CREATE FUNCTION public.mt_delete_employee(p_user uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_admin();
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND NOT is_admin AND membership_status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE user_id=p_user AND checkout_time IS NULL) THEN
  RAISE EXCEPTION 'Finaliza el fichaje antes de retirar al empleado';
 END IF;
 UPDATE public.work_employee_cards SET active=false WHERE user_id=p_user;
 DELETE FROM public.work_employee_roles WHERE user_id=p_user;
 UPDATE public.organization_memberships SET status='disabled',updated_at=now() WHERE user_id=p_user AND organization_id=ase_private.current_org();
END $$;
ALTER FUNCTION public.mt_delete_employee(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.mt_delete_employee(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.mt_delete_employee(uuid) TO authenticated,ase_tenant_executor;

CREATE FUNCTION public.mt_attach_created_employee(p_actor uuid,p_org uuid,p_user uuid,p_nonce text,p_name text,p_whatsapp text,p_role uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 -- Callable only with the backend service role. The Edge Function verifies the actor's JWT.
 PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,1701));
 IF NOT EXISTS(SELECT 1 FROM public.organization_memberships m JOIN public.organizations o ON o.id=m.organization_id
  WHERE m.user_id=p_actor AND m.organization_id=p_org AND m.role IN ('owner','admin') AND m.status='active' AND o.status='active') THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Administración no disponible';
 END IF;
 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 150 OR (p_whatsapp IS NOT NULL AND p_whatsapp !~ '^\+?[0-9]{7,15}$') THEN
  RAISE EXCEPTION 'Datos del empleado no válidos';
 END IF;
 IF p_nonce IS NULL OR length(p_nonce)<32 OR NOT EXISTS(SELECT 1 FROM auth.users WHERE id=p_user AND raw_user_meta_data->>'ase_onboarding_nonce'=p_nonce)
 OR EXISTS(SELECT 1 FROM public.organization_memberships WHERE user_id=p_user) THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No se confirmó una cuenta nueva para este empleado';
 END IF;
 IF p_role IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_roles WHERE id=p_role AND organization_id=p_org AND active) THEN RAISE EXCEPTION 'Rol no disponible'; END IF;
 INSERT INTO public.organization_memberships(organization_id,user_id,role,full_name,whatsapp) VALUES(p_org,p_user,'member',trim(p_name),p_whatsapp);
 IF p_role IS NOT NULL THEN INSERT INTO public.work_employee_roles(organization_id,user_id,role_id) VALUES(p_org,p_user,p_role); END IF;
 RETURN jsonb_build_object('id',p_user,'full_name',trim(p_name),'whatsapp',p_whatsapp,'role_id',p_role);
END $$;
REVOKE ALL ON FUNCTION public.mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid) TO service_role;

CREATE FUNCTION public.mt_prepare_email_change(p_user uuid,p_email text) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org(); result uuid;
BEGIN
 IF auth.uid() IS NULL OR NOT public.sec06_is_admin() THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Solo administración'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,1701));
 IF p_email IS NULL OR length(p_email)>254 OR p_email !~ '^[^\s@]+@[^\s@]+\.[^\s@]+$' THEN RAISE EXCEPTION 'Correo no válido'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.organization_memberships WHERE user_id=p_user AND organization_id=org AND status='active' AND role='member')
 OR (SELECT count(*) FROM public.organization_memberships WHERE user_id=p_user)<>1 THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Esta identidad es compartida o no está disponible. Su titular debe gestionar el correo de acceso';
 END IF;
 DELETE FROM ase_private.email_changes WHERE user_id=p_user AND expires_at<=clock_timestamp();
 INSERT INTO ase_private.email_changes(user_id,organization_id,actor_id,email) VALUES(p_user,org,auth.uid(),lower(trim(p_email))) RETURNING id INTO result;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.mt_prepare_email_change(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.mt_prepare_email_change(uuid,text) TO authenticated;

CREATE FUNCTION public.mt_email_change_grant(p_id uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE grant_row ase_private.email_changes%ROWTYPE;
BEGIN
 SELECT * INTO grant_row FROM ase_private.email_changes WHERE id=p_id AND expires_at>clock_timestamp();
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Solicitud caducada'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.organization_memberships m JOIN public.organizations o ON o.id=m.organization_id
  WHERE m.user_id=grant_row.actor_id AND m.organization_id=grant_row.organization_id AND m.status='active' AND m.role IN ('owner','admin') AND o.status='active') THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Permiso de administración revocado';
 END IF;
 RETURN jsonb_build_object('user_id',grant_row.user_id,'email',grant_row.email);
END $$;
CREATE FUNCTION public.mt_finish_email_change(p_id uuid) RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 DELETE FROM ase_private.email_changes WHERE id=p_id
$$;
REVOKE ALL ON FUNCTION public.mt_email_change_grant(uuid),public.mt_finish_email_change(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.mt_email_change_grant(uuid),public.mt_finish_email_change(uuid) TO service_role;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';



-- Section: 202610220003_access_resolution.sql

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE FUNCTION public.mt_resolve_task_access(p_code text) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 IF auth.uid() IS NULL OR p_code IS NULL OR length(p_code)>128 THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Enlace no disponible'; END IF;
 SELECT jsonb_build_object('task_id',c.task_id,'organization_id',c.organization_id) INTO result
 FROM public.task_access_codes c JOIN public.organization_memberships m ON m.organization_id=c.organization_id AND m.user_id=auth.uid() AND m.status='active'
 JOIN public.organizations o ON o.id=c.organization_id AND o.status='active'
 JOIN public.task_assignments a ON a.organization_id=c.organization_id AND a.task_id=c.task_id AND a.user_id=auth.uid()
 WHERE c.access_code=p_code AND c.is_active AND (c.expires_at IS NULL OR c.expires_at>now());
 IF result IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Enlace no disponible para esta cuenta'; END IF;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.mt_resolve_task_access(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.mt_resolve_task_access(text) TO authenticated;
-- Fix helper semantics as well as the data-layer boundary: a foreign UUID never grants detail.
CREATE OR REPLACE FUNCTION public.work_can_detail(p_task_id uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.tasks WHERE id=p_task_id) AND
 (public.sec06_is_admin() OR EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=p_task_id AND user_id=auth.uid())) AND (
 public.sec06_is_admin() OR NOT coalesce(public.work_mode(),true) OR EXISTS(
 SELECT 1 FROM public.work_day_plan p JOIN public.checkins c ON c.work_plan_id=p.id
 JOIN public.task_assignments a ON a.task_id=p.task_id AND a.user_id=p.user_id
 WHERE p.user_id=auth.uid() AND p.task_id=p_task_id AND p.state='active' AND c.checkout_time IS NULL))
$$;
ALTER FUNCTION public.work_can_detail(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_can_detail(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_can_detail(uuid) TO authenticated,ase_tenant_executor;
CREATE FUNCTION public.mt_identity_email_exists(p_email text) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM auth.users WHERE lower(email)=lower(trim(p_email)))
$$;
REVOKE ALL ON FUNCTION public.mt_identity_email_exists(text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.mt_identity_email_exists(text) TO service_role;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';


CREATE FUNCTION ase_private.touch_organization() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN NEW.updated_at:=clock_timestamp(); RETURN NEW; END $$;
REVOKE ALL ON FUNCTION ase_private.touch_organization() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER mt_organization_updated BEFORE UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION ase_private.touch_organization();
COMMIT;
