-- ASE Work - actualización completa desde la captura heredada del 22/10/2026.
-- No es el instalador de una empresa nueva. Requiere copia verificada y la captura indicada.
-- Todas las migraciones se ejecutan en una sola transacción.
BEGIN;

-- ==== 20261022000100_core_multitenancy_a1.sql ====
-- CORE-MULTITENANCY-A1: AUDIT CANDIDATE. STAGING FIRST; NOT APPROVED FOR PRODUCTION.
-- Preserve a verified backup and deploy the documented Auth services before activating.

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

-- ==== 20261022000200_work_usability.sql ====
-- Apply ONLY after CORE-MULTITENANCY-A1, first in the isolated staging project.

SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='120s';
DO $$ BEGIN
 IF to_regclass('public.organization_memberships') IS NULL OR to_regrole('ase_tenant_executor') IS NULL
 THEN RAISE EXCEPTION 'Instala primero CORE-MULTITENANCY-A1'; END IF;
END $$;
GRANT USAGE ON SCHEMA extensions TO ase_tenant_executor;
CREATE TABLE public.work_areas(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL DEFAULT ase_private.current_org() REFERENCES public.organizations(id),
 name text NOT NULL CHECK(length(btrim(name)) BETWEEN 2 AND 100),active boolean NOT NULL DEFAULT true,
 UNIQUE(organization_id,id),UNIQUE(organization_id,name));
CREATE TABLE public.work_area_members(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),area_id uuid NOT NULL,user_id uuid NOT NULL,
 PRIMARY KEY(organization_id,area_id,user_id),
 FOREIGN KEY(organization_id,area_id) REFERENCES public.work_areas(organization_id,id),
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id));
CREATE TABLE public.work_personal_pins(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),user_id uuid NOT NULL,
 pin_hash text NOT NULL,active boolean NOT NULL DEFAULT true,failures integer NOT NULL DEFAULT 0,locked_until timestamptz,
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),PRIMARY KEY(organization_id,user_id),
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id));
CREATE TABLE public.work_pin_attempts(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),station_id uuid NOT NULL,attempts integer NOT NULL DEFAULT 0,
 window_start timestamptz NOT NULL DEFAULT clock_timestamp(),PRIMARY KEY(organization_id,station_id),
 FOREIGN KEY(organization_id,station_id) REFERENCES public.work_stations(organization_id,id));
CREATE TABLE public.work_incidents(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 task_id uuid NOT NULL,plan_id uuid,reporter_id uuid NOT NULL,assigned_user uuid,area_id uuid,
 subject text NOT NULL CHECK(length(btrim(subject)) BETWEEN 3 AND 160),description text NOT NULL CHECK(length(btrim(description)) BETWEEN 3 AND 5000),
 state text NOT NULL DEFAULT 'open' CHECK(state IN ('open','in_progress','resolved')),
 blocks_work boolean NOT NULL DEFAULT false,resolution text NOT NULL DEFAULT '',attachments text[] NOT NULL DEFAULT '{}',
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(organization_id,id),CHECK(assigned_user IS NOT NULL OR area_id IS NOT NULL),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id),
 FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id),
 FOREIGN KEY(organization_id,reporter_id) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,assigned_user) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,area_id) REFERENCES public.work_areas(organization_id,id));
CREATE INDEX work_incidents_recipient ON public.work_incidents(organization_id,assigned_user,state,created_at);
CREATE TABLE public.work_notifications(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL DEFAULT ase_private.current_org(),user_id uuid NOT NULL,
 incident_id uuid NOT NULL,message text NOT NULL,seen boolean NOT NULL DEFAULT false,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,incident_id) REFERENCES public.work_incidents(organization_id,id));
CREATE INDEX work_notification_inbox ON public.work_notifications(organization_id,user_id,seen,created_at);
ALTER TABLE public.checkins ADD CONSTRAINT work_checkins_org_id_key UNIQUE(organization_id,id);
CREATE TABLE public.work_task_closures(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 plan_id uuid NOT NULL,checkin_id uuid NOT NULL,actor_id uuid NOT NULL,reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 5 AND 2000),
 kind text NOT NULL CHECK(kind IN ('admin_finish','incident_block')),incident_id uuid,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id),
 FOREIGN KEY(organization_id,checkin_id) REFERENCES public.checkins(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,incident_id) REFERENCES public.work_incidents(organization_id,id));
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['work_areas','work_area_members','work_personal_pins','work_pin_attempts','work_incidents','work_notifications','work_task_closures'] LOOP
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
  EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC,anon,authenticated',t);
  EXECUTE format('GRANT SELECT,INSERT,UPDATE,DELETE ON public.%I TO ase_tenant_executor',t);
  EXECUTE format('CREATE POLICY work_feature_boundary ON public.%I AS RESTRICTIVE TO PUBLIC USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org())',t);
  EXECUTE format('CREATE POLICY work_feature_executor ON public.%I TO ase_tenant_executor USING(true) WITH CHECK(true)',t);
 END LOOP;
END $$;
ALTER TABLE public.work_day_plan DROP CONSTRAINT work_day_plan_state_check;
ALTER TABLE public.work_day_plan ADD CONSTRAINT work_day_plan_state_check CHECK(state IN ('pending','active','completed','blocked'));
ALTER TABLE public.work_station_tickets ALTER COLUMN card_id DROP NOT NULL;
ALTER TABLE public.work_station_tickets ADD COLUMN credential_version text;
ALTER TABLE public.work_station_tickets ADD COLUMN credential_method text NOT NULL DEFAULT 'manual' CHECK(credential_method IN ('manual','nfc','pin'));
ALTER TABLE public.work_station_tickets ADD CONSTRAINT work_ticket_credential_required CHECK((credential_method='pin' AND credential_version IS NOT NULL) OR (credential_method<>'pin' AND card_id IS NOT NULL));

CREATE FUNCTION ase_private.close_work(p_plan uuid,p_reason text,p_kind text,p_incident uuid DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;c uuid;ts timestamptz:=clock_timestamp();u uuid;
BEGIN
 IF length(btrim(p_reason)) NOT BETWEEN 5 AND 2000 THEN RAISE EXCEPTION 'Escribe un motivo de entre 5 y 2000 caracteres'; END IF;
 SELECT user_id INTO u FROM public.work_day_plan WHERE id=p_plan;
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=u AND membership_status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE id=p_plan FOR UPDATE;
 IF p.state IS DISTINCT FROM 'active' THEN RAISE EXCEPTION 'La tarea ya no está en curso'; END IF;
 IF p_kind='admin_finish' THEN PERFORM public.work_assert_admin();
 ELSIF p_kind='incident_block' THEN
  IF p.user_id IS DISTINCT FROM auth.uid() OR p_incident IS NULL THEN RAISE EXCEPTION 'Incidencia no autorizada'; END IF;
 ELSE RAISE EXCEPTION 'Tipo de cierre no válido'; END IF;
 PERFORM set_config('ase.tablet_write','on',true);
 UPDATE public.checkins SET checkout_time=ts WHERE work_plan_id=p.id AND user_id=p.user_id AND checkout_time IS NULL AND checkin_time<=ts RETURNING id INTO c;
 IF c IS NULL THEN RAISE EXCEPTION 'No se encontró el fichaje activo'; END IF;
 UPDATE public.work_day_plan SET state=CASE WHEN p_kind='admin_finish' THEN 'completed' ELSE 'blocked' END,finished_at=ts WHERE id=p.id;
 INSERT INTO public.work_task_closures(plan_id,checkin_id,actor_id,reason,kind,incident_id) VALUES(p.id,c,auth.uid(),btrim(p_reason),p_kind,p_incident);
 UPDATE public.work_station_tickets SET expires_at=ts WHERE plan_id=p.id AND result IS NULL;
 PERFORM set_config('ase.tablet_write','off',true);
 RETURN c;
END $$;
REVOKE ALL ON FUNCTION ase_private.close_work(uuid,text,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.close_work(uuid,text,text,uuid) TO ase_tenant_executor;

CREATE FUNCTION public.work_admin_finish(p_plan uuid,p_reason text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN PERFORM public.work_assert_admin();RETURN jsonb_build_object('checkin_id',ase_private.close_work(p_plan,p_reason,'admin_finish'));END $$;

CREATE FUNCTION public.work_area_directory() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL OR ase_private.current_org() IS NULL THEN RAISE EXCEPTION 'Inicia sesión'; END IF;
 RETURN jsonb_build_object('areas',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'name',a.name,'members',coalesce((SELECT jsonb_agg(m.user_id) FROM public.work_area_members m WHERE m.area_id=a.id),'[]'::jsonb)) ORDER BY a.name) FROM public.work_areas a WHERE a.active),'[]'::jsonb),
 'people',coalesce((SELECT jsonb_agg(jsonb_build_object('id',p.id,'full_name',p.full_name) ORDER BY p.full_name) FROM ase_private.employee_profiles p WHERE p.membership_status='active'),'[]'::jsonb));
END $$;
CREATE FUNCTION public.work_save_area(p_name text,p_members uuid[]) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE area uuid;u uuid;BEGIN
 PERFORM public.work_assert_admin();
 IF p_members IS NULL OR cardinality(p_members) NOT BETWEEN 1 AND 100 OR length(btrim(p_name)) NOT BETWEEN 2 AND 100 THEN RAISE EXCEPTION 'Escribe un área y selecciona responsables'; END IF;
 FOREACH u IN ARRAY p_members LOOP
  IF NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=u AND membership_status='active') THEN RAISE EXCEPTION 'Responsable no disponible en esta empresa'; END IF;
 END LOOP;
 INSERT INTO public.work_areas(name) VALUES(btrim(p_name)) ON CONFLICT(organization_id,name) DO UPDATE SET active=true RETURNING id INTO area;
 DELETE FROM public.work_area_members WHERE area_id=area;
 INSERT INTO public.work_area_members(area_id,user_id) SELECT area,unnest(p_members) ON CONFLICT DO NOTHING;
 RETURN area;
END $$;

GRANT USAGE ON SCHEMA storage TO ase_tenant_executor;
GRANT SELECT ON storage.objects TO ase_tenant_executor;
CREATE POLICY work_incident_attachment_executor ON storage.objects FOR SELECT TO ase_tenant_executor USING(bucket_id='task-files' AND split_part(name,'/',3)=auth.uid()::text AND public.work_can_file(name));

CREATE FUNCTION public.work_report_incident(p_task uuid,p_subject text,p_description text,p_user uuid DEFAULT NULL,p_area uuid DEFAULT NULL,p_block boolean DEFAULT false,p_files text[] DEFAULT '{}') RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE plan uuid;result uuid;path text;prefix text;BEGIN
 IF auth.uid() IS NULL OR NOT public.work_can_detail(p_task) OR p_block IS NULL THEN RAISE EXCEPTION 'Solo puedes reportar sobre una tarea disponible para ti'; END IF;
 IF p_user IS NULL AND p_area IS NULL THEN RAISE EXCEPTION 'Selecciona un área o responsable'; END IF;
 IF p_user IS NOT NULL AND NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_user AND membership_status='active') THEN RAISE EXCEPTION 'Responsable no disponible'; END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas a JOIN public.work_area_members m ON m.area_id=a.id JOIN ase_private.employee_profiles u ON u.id=m.user_id AND u.membership_status='active' WHERE a.id=p_area AND a.active) THEN RAISE EXCEPTION 'Área sin responsables disponibles'; END IF;
 IF p_files IS NULL OR cardinality(p_files)>3 THEN RAISE EXCEPTION 'Adjunta hasta 3 imágenes'; END IF;
 prefix:='tasks/'||p_task::text||'/'||auth.uid()::text||'/';
 FOREACH path IN ARRAY p_files LOOP
  IF left(path,length(prefix))<>prefix OR path !~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp)$' OR NOT EXISTS(SELECT 1 FROM storage.objects WHERE bucket_id='task-files' AND name=path) THEN RAISE EXCEPTION 'Adjunto no disponible'; END IF;
 END LOOP;
 SELECT id INTO plan FROM public.work_day_plan WHERE task_id=p_task AND user_id=auth.uid() AND state='active';
 IF p_block AND plan IS NULL THEN RAISE EXCEPTION 'No tienes esta tarea en curso'; END IF;
 INSERT INTO public.work_incidents(task_id,plan_id,reporter_id,assigned_user,area_id,subject,description,blocks_work,attachments)
 VALUES(p_task,plan,auth.uid(),p_user,p_area,btrim(p_subject),btrim(p_description),p_block,p_files) RETURNING id INTO result;
 INSERT INTO public.work_notifications(user_id,incident_id,message)
 SELECT DISTINCT recipient,result,'Nueva incidencia: '||btrim(p_subject) FROM(
 SELECT p_user AS recipient WHERE p_user IS NOT NULL UNION SELECT m.user_id FROM public.work_area_members m JOIN ase_private.employee_profiles u ON u.id=m.user_id AND u.membership_status='active' WHERE m.area_id=p_area) x;
 IF p_block THEN PERFORM ase_private.close_work(plan,p_subject||': '||left(p_description,1500),'incident_block',result); END IF;
 RETURN result;
END $$;

CREATE FUNCTION public.work_incident_inbox() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL OR ase_private.current_org() IS NULL THEN RAISE EXCEPTION 'Inicia sesión'; END IF;
 RETURN jsonb_build_object('items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('task_title',t.title,'reporter',u.full_name,'assigned_name',v.full_name,'area_name',a.name,'can_manage',public.sec06_is_admin() OR i.assigned_user=auth.uid() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=auth.uid())) ORDER BY i.created_at DESC)
 FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=i.reporter_id LEFT JOIN ase_private.employee_profiles v ON v.id=i.assigned_user LEFT JOIN public.work_areas a ON a.id=i.area_id
 WHERE public.sec06_is_admin() OR i.reporter_id=auth.uid() OR i.assigned_user=auth.uid() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=auth.uid())),'[]'::jsonb),
 'notifications',coalesce((SELECT jsonb_agg(to_jsonb(n) ORDER BY n.created_at DESC) FROM (SELECT * FROM public.work_notifications WHERE user_id=auth.uid() ORDER BY created_at DESC LIMIT 100) n),'[]'::jsonb));
END $$;
CREATE FUNCTION public.work_update_incident(p_id uuid,p_state text,p_resolution text DEFAULT '') RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE i public.work_incidents%ROWTYPE;BEGIN
 SELECT * INTO i FROM public.work_incidents WHERE id=p_id FOR UPDATE;
 IF i.id IS NULL OR NOT coalesce(public.sec06_is_admin() OR i.assigned_user=auth.uid() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=auth.uid()),false) THEN RAISE EXCEPTION 'No puedes gestionar esta incidencia'; END IF;
 IF p_state NOT IN ('open','in_progress','resolved') OR p_state IS NULL OR p_resolution IS NULL OR length(p_resolution)>5000 OR (p_state='resolved' AND length(btrim(p_resolution))<5) THEN RAISE EXCEPTION 'Indica un estado y, al resolver, explica la solución'; END IF;
 UPDATE public.work_incidents SET state=p_state,resolution=btrim(p_resolution),updated_at=clock_timestamp() WHERE id=i.id;
 UPDATE public.work_notifications SET seen=true WHERE user_id=auth.uid() AND incident_id=i.id;
 INSERT INTO public.work_notifications(user_id,incident_id,message) VALUES(i.reporter_id,i.id,'Incidencia actualizada: '||i.subject);
END $$;
CREATE FUNCTION public.work_seen_notifications() RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$UPDATE public.work_notifications SET seen=true WHERE user_id=auth.uid()$$;

CREATE FUNCTION public.work_pin_settings(p_user uuid,p_pin text DEFAULT NULL,p_active boolean DEFAULT true) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE value text;BEGIN
 PERFORM public.work_assert_admin();
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND NOT is_admin AND membership_status='active' FOR UPDATE;
 IF NOT FOUND OR p_active IS NULL THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 IF NOT p_active THEN UPDATE public.work_personal_pins SET active=false WHERE user_id=p_user;RETURN jsonb_build_object('active',false);END IF;
 value:=coalesce(nullif(btrim(p_pin),''),lpad((('x'||encode(extensions.gen_random_bytes(4),'hex'))::bit(32)::bigint % 100000)::text,5,'0'));
 IF value !~ '^[0-9]{5}$' THEN RAISE EXCEPTION 'El PIN debe tener exactamente 5 dígitos'; END IF;
 INSERT INTO public.work_personal_pins(user_id,pin_hash) VALUES(p_user,extensions.crypt(value,extensions.gen_salt('bf',10)))
 ON CONFLICT(organization_id,user_id) DO UPDATE SET pin_hash=EXCLUDED.pin_hash,active=true,failures=0,locked_until=NULL,updated_at=clock_timestamp();
 RETURN jsonb_build_object('active',true,'pin',value);
END $$;
CREATE FUNCTION public.work_import_pins(p_rows jsonb,p_apply boolean DEFAULT false) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE row jsonb;u uuid;ids uuid[]:='{}';preview jsonb:='[]';errors jsonb:='[]';n integer:=0;BEGIN
 PERFORM public.work_assert_admin();
 IF p_rows IS NULL OR jsonb_typeof(p_rows)<>'array' OR jsonb_array_length(p_rows) NOT BETWEEN 1 AND 200 OR p_apply IS NULL THEN RAISE EXCEPTION 'Importa entre 1 y 200 empleados';END IF;
 FOR row IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
  n:=n+1;u:=NULL;
  SELECT id INTO u FROM ase_private.employee_profiles WHERE NOT is_admin AND membership_status='active' AND (id::text=row->>'employee' OR lower(email)=lower(row->>'employee'));
  IF u IS NULL OR u=ANY(ids) OR coalesce(row->>'pin','') !~ '^[0-9]{5}$' THEN errors:=errors||jsonb_build_object('row',n,'error','Empleado desconocido, duplicado o PIN distinto de 5 dígitos');
  ELSE ids:=array_append(ids,u);preview:=preview||jsonb_build_object('user_id',u,'employee',(SELECT full_name FROM ase_private.employee_profiles WHERE id=u),'row',n);END IF;
 END LOOP;
 IF p_apply AND jsonb_array_length(errors)>0 THEN RAISE EXCEPTION 'La importación tiene errores. Corrige la vista previa'; END IF;
 IF p_apply THEN n:=0;FOR row IN SELECT value FROM jsonb_array_elements(p_rows) LOOP n:=n+1;PERFORM public.work_pin_settings((preview->(n-1)->>'user_id')::uuid,row->>'pin',true);END LOOP;END IF;
 RETURN jsonb_build_object('preview',preview,'errors',errors,'applied',p_apply);
END $$;

CREATE FUNCTION public.work_station_people(p_station text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN PERFORM ase_private.bind_station(p_station);
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',u.id,'name',u.full_name) ORDER BY u.full_name) FROM public.work_personal_pins pin JOIN ase_private.employee_profiles u ON u.id=pin.user_id WHERE pin.active AND NOT u.is_admin AND u.membership_status='active'),'[]'::jsonb);END $$;

CREATE OR REPLACE FUNCTION public.work_station_identify_v2(p_station text, p_card text DEFAULT NULL, p_method text DEFAULT 'manual', p_user uuid DEFAULT NULL)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE s public.work_stations%ROWTYPE; c public.work_employee_cards%ROWTYPE; p public.work_day_plan%ROWTYPE;
 v_ticket uuid; v_action text:='none'; v_name text; v_title text; v_description text; pin public.work_personal_pins%ROWTYPE; attempt_row public.work_pin_attempts%ROWTYPE; selected_user uuid;
BEGIN
 PERFORM ase_private.bind_station(p_station);
 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;
 SELECT * INTO s FROM public.work_stations WHERE token_hash=public.work_hash(p_station) AND active FOR UPDATE;
 IF p_method IS NULL OR p_method NOT IN ('manual','nfc','pin') THEN RAISE EXCEPTION 'Método no válido';END IF;
 IF s.id IS NULL THEN RAISE EXCEPTION 'Punto no disponible';END IF;
 IF p_method='pin' THEN
  INSERT INTO public.work_pin_attempts(station_id) VALUES(s.id) ON CONFLICT DO NOTHING;
  SELECT * INTO attempt_row FROM public.work_pin_attempts WHERE station_id=s.id FOR UPDATE;
  IF attempt_row.window_start < clock_timestamp()-interval '15 minutes' THEN
   UPDATE public.work_pin_attempts SET attempts=0,window_start=clock_timestamp() WHERE station_id=s.id;attempt_row.attempts:=0;
  END IF;
  IF attempt_row.attempts>=20 THEN RETURN jsonb_build_object('error','Demasiados intentos en este punto. Espera 15 minutos.'); END IF;
  SELECT * INTO pin FROM public.work_personal_pins WHERE user_id=p_user FOR UPDATE;
  IF pin.locked_until>clock_timestamp() THEN RETURN jsonb_build_object('error','Identificación no disponible. Espera 15 minutos o consulta al administrador.');END IF;
  IF pin.user_id IS NULL OR NOT pin.active OR p_card IS NULL OR p_card !~ '^[0-9]{5}$' OR pin.pin_hash IS DISTINCT FROM extensions.crypt(p_card,pin.pin_hash) THEN
   UPDATE public.work_pin_attempts SET attempts=attempts+1 WHERE station_id=s.id;
   UPDATE public.work_personal_pins SET failures=failures+1,locked_until=CASE WHEN failures>=4 THEN clock_timestamp()+interval '15 minutes' ELSE locked_until END WHERE user_id=p_user;
   RETURN jsonb_build_object('error','Empleado o PIN no válido.');
  END IF;
  UPDATE public.work_personal_pins SET failures=0,locked_until=NULL WHERE user_id=p_user;
  selected_user:=pin.user_id;
 ELSE
  SELECT * INTO c FROM public.work_employee_cards WHERE token_hash=public.work_hash(p_card) AND active;
  selected_user:=c.user_id;
 END IF;
 IF s.id IS NULL OR selected_user IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto o tarjeta no disponible'; END IF;
 SELECT full_name INTO v_name FROM ase_private.employee_profiles WHERE id=selected_user AND is_admin IS FALSE AND membership_status='active';
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarjeta no disponible'; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE user_id=selected_user AND state='active';
 IF p.id IS NOT NULL THEN v_action:='finish';
 ELSE
  SELECT x.* INTO p FROM public.work_day_plan x WHERE x.user_id=selected_user AND x.work_date=public.work_today() AND x.state='pending'
   ORDER BY x.priority LIMIT 1;
  IF p.id IS NOT NULL THEN v_action:='start'; END IF;
 END IF;
 IF p.id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE user_id=selected_user AND task_id=p.task_id) THEN
  RAISE EXCEPTION 'La asignación cambió. Consulta al encargado';
 END IF;
 SELECT title,description INTO v_title,v_description FROM public.tasks WHERE id=p.task_id;
 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE station_id=s.id AND result IS NULL;
 DELETE FROM public.work_station_tickets WHERE expires_at<now()-interval '7 days';
 INSERT INTO public.work_station_tickets(station_id,card_id,user_id,plan_id,expected_action,credential_method,credential_version)
 VALUES(s.id,c.id,selected_user,p.id,v_action,p_method,pin.pin_hash) RETURNING id INTO v_ticket;
 RETURN jsonb_build_object('ticket',v_ticket,'employee',v_name,'title',v_title,'description',v_description,'action',v_action,
  'started_at',p.started_at,'reader_mode',s.reader_mode);
END $function$;
CREATE OR REPLACE FUNCTION public.work_station_confirm_v2(p_station text, p_ticket uuid, p_action text)
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

 IF k.credential_method='pin' THEN
  PERFORM 1 FROM public.work_personal_pins WHERE user_id=k.user_id AND active AND pin_hash=k.credential_version FOR SHARE;
 ELSE
  PERFORM 1 FROM public.work_employee_cards WHERE id=k.card_id AND user_id=k.user_id AND active FOR SHARE;
 END IF;

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

  VALUES(p.task_id,p.user_id,v_time,CASE WHEN k.credential_method='nfc' THEN 'nfc' ELSE 'manual' END,CASE WHEN k.credential_method='pin' THEN 'Tablet · PIN personal' WHEN k.credential_method='nfc' THEN 'Tablet · lectura NFC' ELSE 'Tablet · lectura por código' END,p.id,s.id,k.card_id) RETURNING id INTO v_checkin;

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

END $function$;
CREATE OR REPLACE FUNCTION public.work_station_day_v2(p_station text, p_ticket uuid)
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
 LEFT JOIN public.work_employee_cards c ON c.id=k.card_id AND c.active AND c.user_id=k.user_id
 JOIN ase_private.employee_profiles u ON u.id=k.user_id AND u.is_admin IS FALSE AND u.membership_status='active'
 WHERE ((k.credential_method<>'pin' AND c.id IS NOT NULL) OR (k.credential_method='pin' AND EXISTS(SELECT 1 FROM public.work_personal_pins pin WHERE pin.user_id=k.user_id AND pin.active AND pin.pin_hash=k.credential_version))) AND k.id=p_ticket AND s.token_hash=public.work_hash(p_station) AND k.expires_at>clock_timestamp();
 IF v_user IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Vuelve a identificarte para consultar tus tareas'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'title',t.title,'state',p.state,
  'priority',p.priority,'work_date',p.work_date) || public.work_deadline(p.work_date,p.state,p.finished_at) ORDER BY p.work_date,p.priority),'[]'::jsonb)
 INTO v_items FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id
 WHERE p.user_id=v_user AND (p.work_date=public.work_today() OR p.state='active' OR (p.work_date<public.work_today() AND p.state='pending'))
 AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=p.task_id AND a.user_id=p.user_id);
 RETURN jsonb_build_object('employee',v_name,'date',public.work_today(),'items',v_items);
END $function$;
CREATE OR REPLACE FUNCTION public.work_my_day_v2()
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

END $function$;

CREATE FUNCTION public.work_search(p_terms text[] DEFAULT '{}',p_state text DEFAULT NULL,p_kind text DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE tasks jsonb;people jsonb;incidents jsonb;BEGIN
 IF auth.uid() IS NULL OR ase_private.current_org() IS NULL THEN RAISE EXCEPTION 'Inicia sesión';END IF;
 IF p_terms IS NULL OR cardinality(p_terms)>10 OR EXISTS(SELECT 1 FROM unnest(p_terms) t WHERE length(t)>80) OR (p_state IS NOT NULL AND p_state NOT IN ('active','pending','completed','blocked','open','in_progress','resolved')) OR (p_kind IS NOT NULL AND p_kind NOT IN ('tasks','people','incidents')) THEN RAISE EXCEPTION 'Búsqueda no válida'; END IF;
 SELECT coalesce(jsonb_agg(x),'[]'::jsonb) INTO tasks FROM (
  SELECT p.id,p.task_id,t.title,u.full_name AS employee,p.state,p.work_date,public.work_can_detail(t.id) AS can_open
  FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id JOIN ase_private.employee_profiles u ON u.id=p.user_id
  WHERE (public.work_has_permission('planning.view') OR public.sec06_is_admin() OR p.user_id=auth.uid())
  AND (p_state IS NULL OR p.state=p_state) AND (p_kind IS NULL OR p_kind='tasks')
  AND NOT EXISTS(SELECT 1 FROM unnest(p_terms) term WHERE position(term IN translate(lower(t.title||' '||u.full_name),'áéíóúüñ','aeiouun'))=0)
  ORDER BY (p.state='active') DESC,p.work_date DESC,p.priority LIMIT 100) x;
 SELECT tasks||coalesce(jsonb_agg(x),'[]'::jsonb) INTO tasks FROM (
  SELECT t.id,t.id AS task_id,t.title,names.employee,
   CASE t.status WHEN 'in_progress' THEN 'active' ELSE t.status::text END AS state,NULL::date AS work_date,public.work_can_detail(t.id) AS can_open
  FROM public.tasks t CROSS JOIN LATERAL(SELECT string_agg(u.full_name,', ' ORDER BY u.full_name) AS employee FROM public.task_assignments a JOIN ase_private.employee_profiles u ON u.id=a.user_id WHERE a.task_id=t.id AND (public.work_has_permission('tasks.view') OR a.user_id=auth.uid())) names
  WHERE NOT EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.task_id=t.id)
  AND (public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=t.id AND a.user_id=auth.uid()))
  AND (p_kind IS NULL OR p_kind='tasks') AND (p_state IS NULL OR (CASE t.status WHEN 'in_progress' THEN 'active' ELSE t.status::text END)=p_state)
  AND NOT EXISTS(SELECT 1 FROM unnest(p_terms) term WHERE position(term IN translate(lower(t.title||' '||coalesce(names.employee,'')),'áéíóúüñ','aeiouun'))=0)
  ORDER BY t.created_at DESC LIMIT 100) x;
 SELECT coalesce(jsonb_agg(value),'[]'::jsonb) INTO tasks FROM (SELECT value FROM jsonb_array_elements(tasks) WITH ORDINALITY e(value,n) ORDER BY n LIMIT 100) x;
 SELECT coalesce(jsonb_agg(x),'[]'::jsonb) INTO people FROM (
  SELECT u.id,u.full_name FROM ase_private.employee_profiles u WHERE public.sec06_is_admin() AND u.membership_status='active'
  AND p_state IS NULL AND (p_kind IS NULL OR p_kind='people')
  AND NOT EXISTS(SELECT 1 FROM unnest(p_terms) term WHERE position(term IN translate(lower(u.full_name||' '||u.email),'áéíóúüñ','aeiouun'))=0)
  ORDER BY full_name LIMIT 100) x;
 SELECT coalesce(jsonb_agg(x),'[]'::jsonb) INTO incidents FROM (
  SELECT i.id,i.subject,i.state,t.title FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id
  WHERE (public.sec06_is_admin() OR i.reporter_id=auth.uid() OR i.assigned_user=auth.uid() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=auth.uid()))
  AND (p_state IS NULL OR i.state=CASE p_state WHEN 'pending' THEN 'open' WHEN 'active' THEN 'in_progress' WHEN 'completed' THEN 'resolved' ELSE p_state END)
  AND (p_kind IS NULL OR p_kind='incidents')
  AND NOT EXISTS(SELECT 1 FROM unnest(p_terms) term WHERE position(term IN translate(lower(i.subject||' '||i.description||' '||t.title),'áéíóúüñ','aeiouun'))=0)
  ORDER BY i.created_at DESC LIMIT 100) x;
 RETURN jsonb_build_object('tasks',tasks,'people',people,'incidents',incidents,'limit_per_group',100);
END $$;

CREATE FUNCTION public.work_incident_file_allowed(p_path text) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT auth.uid() IS NOT NULL AND EXISTS(SELECT 1 FROM public.work_incidents i WHERE p_path=ANY(i.attachments)
 AND (public.sec06_is_admin() OR i.reporter_id=auth.uid() OR i.assigned_user=auth.uid() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=auth.uid())))
$$;
CREATE POLICY work_incident_file_read ON storage.objects FOR SELECT TO authenticated USING(bucket_id='task-files' AND public.work_incident_file_allowed(name));
ALTER POLICY work_files_read ON storage.objects USING(bucket_id<>'task-files' OR public.work_can_file(name) OR public.work_incident_file_allowed(name));


CREATE FUNCTION public.work_usability_ready() RETURNS boolean LANGUAGE sql STABLE SET search_path='' AS $$SELECT true$$;
CREATE FUNCTION public.work_open_tasks() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN PERFORM public.work_assert_admin();RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',p.id,'title',t.title,'employee',u.full_name) ORDER BY p.started_at) FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.state='active'),'[]'::jsonb);END $$;


CREATE FUNCTION public.work_pin_overview() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$BEGIN PERFORM public.work_assert_admin();RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('user_id',user_id,'active',active,'updated_at',updated_at)) FROM public.work_personal_pins),'[]'::jsonb);END $$;


CREATE FUNCTION public.work_closure_history() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN PERFORM public.work_assert_admin();RETURN coalesce((SELECT jsonb_agg(x ORDER BY x.created_at DESC) FROM(SELECT c.id,c.kind,c.reason,c.created_at,t.title,u.full_name AS employee,a.full_name AS actor FROM public.work_task_closures c JOIN public.work_day_plan p ON p.id=c.plan_id JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id LEFT JOIN ase_private.employee_profiles a ON a.id=c.actor_id ORDER BY c.created_at DESC LIMIT 50)x),'[]'::jsonb);END $$;

-- No change to existing RPC signatures or their security snapshot.
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
DO $$ DECLARE f record;BEGIN
 FOR f IN SELECT p.oid::regprocedure AS signature FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname=ANY(ARRAY['work_admin_finish','work_area_directory','work_save_area','work_report_incident','work_incident_inbox','work_update_incident','work_seen_notifications','work_pin_settings','work_import_pins','work_station_people','work_station_identify_v2','work_station_confirm_v2','work_station_day_v2','work_my_day_v2','work_search','work_incident_file_allowed','work_usability_ready','work_open_tasks','work_pin_overview','work_closure_history']) LOOP
  EXECUTE format('ALTER FUNCTION %s OWNER TO ase_tenant_executor',f.signature);
  EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC,anon,authenticated',f.signature);
  EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated',f.signature);
 END LOOP;
END $$;
GRANT EXECUTE ON FUNCTION public.work_usability_ready() TO anon;
GRANT EXECUTE ON FUNCTION public.work_station_people(text),public.work_station_identify_v2(text,text,text,uuid),public.work_station_confirm_v2(text,uuid,text),public.work_station_day_v2(text,uuid) TO anon;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261022000300_hosted_auth_identity.sql ====
-- Hosted Supabase controls auth ACLs: custom roles cannot receive schema USAGE.
-- Narrow postgres-owned helpers expose only the current request identity.

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

-- ==== 20261022000400_station_auto_code.sql ====
-- ASE Work - Pruebas: automatic code identification; NFC credentials unchanged.

CREATE OR REPLACE FUNCTION public.work_pin_settings(p_user uuid,p_pin text DEFAULT NULL,p_active boolean DEFAULT true) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE value text;BEGIN
 PERFORM public.work_assert_admin();
 PERFORM pg_advisory_xact_lock(hashtextextended(ase_private.current_org()::text,0));
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND NOT is_admin AND membership_status='active' FOR UPDATE;
 IF NOT FOUND OR p_active IS NULL THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 IF NOT p_active THEN UPDATE public.work_personal_pins SET active=false WHERE user_id=p_user;RETURN jsonb_build_object('active',false);END IF;
 value:=coalesce(nullif(btrim(p_pin),''),lpad((('x'||encode(extensions.gen_random_bytes(4),'hex'))::bit(32)::bigint % 100000)::text,5,'0'));
 IF value !~ '^[0-9]{5}$' THEN RAISE EXCEPTION 'El PIN debe tener exactamente 5 dígitos'; END IF;
 IF EXISTS(SELECT 1 FROM public.work_personal_pins WHERE active AND user_id<>p_user AND pin_hash=extensions.crypt(value,pin_hash)) THEN RAISE EXCEPTION 'Ese código ya está asignado. Elige otro código de 5 dígitos'; END IF;
 INSERT INTO public.work_personal_pins(user_id,pin_hash) VALUES(p_user,extensions.crypt(value,extensions.gen_salt('bf',10)))
 ON CONFLICT(organization_id,user_id) DO UPDATE SET pin_hash=EXCLUDED.pin_hash,active=true,failures=0,locked_until=NULL,updated_at=clock_timestamp();
 RETURN jsonb_build_object('active',true,'pin',value);
END $$;
CREATE OR REPLACE FUNCTION public.work_station_identify_v2(p_station text, p_card text DEFAULT NULL, p_method text DEFAULT 'manual', p_user uuid DEFAULT NULL)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE s public.work_stations%ROWTYPE; c public.work_employee_cards%ROWTYPE; p public.work_day_plan%ROWTYPE;
 v_ticket uuid; v_action text:='none'; v_name text; v_title text; v_description text; pin public.work_personal_pins%ROWTYPE; attempt_row public.work_pin_attempts%ROWTYPE; selected_user uuid; matches uuid[];
BEGIN
 PERFORM ase_private.bind_station(p_station);
 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;
 SELECT * INTO s FROM public.work_stations WHERE token_hash=public.work_hash(p_station) AND active FOR UPDATE;
 IF p_method IS NULL OR p_method NOT IN ('manual','nfc','pin') THEN RAISE EXCEPTION 'Método no válido';END IF;
 IF s.id IS NULL THEN RAISE EXCEPTION 'Punto no disponible';END IF;
 IF p_method='pin' THEN
  INSERT INTO public.work_pin_attempts(station_id) VALUES(s.id) ON CONFLICT DO NOTHING;
  SELECT * INTO attempt_row FROM public.work_pin_attempts WHERE station_id=s.id FOR UPDATE;
  IF attempt_row.window_start < clock_timestamp()-interval '15 minutes' THEN
   UPDATE public.work_pin_attempts SET attempts=0,window_start=clock_timestamp() WHERE station_id=s.id;attempt_row.attempts:=0;
  END IF;
  IF attempt_row.attempts>=20 THEN RETURN jsonb_build_object('error','Demasiados intentos en este punto. Espera 15 minutos.'); END IF;
  IF p_user IS NULL THEN
   IF p_card IS NOT NULL AND p_card ~ '^[0-9]{5}$' THEN
    SELECT array_agg(candidate.user_id) INTO matches FROM (
     SELECT x.user_id FROM public.work_personal_pins x
     JOIN ase_private.employee_profiles u ON u.id=x.user_id AND u.membership_status='active' AND NOT u.is_admin
     WHERE x.active AND x.pin_hash=extensions.crypt(p_card,x.pin_hash) LIMIT 2
    ) candidate;
   END IF;
   IF coalesce(cardinality(matches),0)<>1 THEN
    UPDATE public.work_pin_attempts SET attempts=attempts+1 WHERE station_id=s.id;
    RETURN jsonb_build_object('error','Código no disponible. Comprueba los 5 dígitos o consulta al administrador.');
   END IF;
   p_user:=matches[1];
  END IF;
  SELECT * INTO pin FROM public.work_personal_pins WHERE user_id=p_user FOR UPDATE;
  IF pin.locked_until>clock_timestamp() THEN RETURN jsonb_build_object('error','Identificación no disponible. Espera 15 minutos o consulta al administrador.');END IF;
  IF pin.user_id IS NULL OR NOT pin.active OR p_card IS NULL OR p_card !~ '^[0-9]{5}$' OR pin.pin_hash IS DISTINCT FROM extensions.crypt(p_card,pin.pin_hash) THEN
   UPDATE public.work_pin_attempts SET attempts=attempts+1 WHERE station_id=s.id;
   UPDATE public.work_personal_pins SET failures=failures+1,locked_until=CASE WHEN failures>=4 THEN clock_timestamp()+interval '15 minutes' ELSE locked_until END WHERE user_id=p_user;
   RETURN jsonb_build_object('error','Empleado o PIN no válido.');
  END IF;
  UPDATE public.work_personal_pins SET failures=0,locked_until=NULL WHERE user_id=p_user;
  selected_user:=pin.user_id;
 ELSE
  SELECT * INTO c FROM public.work_employee_cards WHERE token_hash=public.work_hash(p_card) AND active;
  selected_user:=c.user_id;
 END IF;
 IF s.id IS NULL OR selected_user IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto o tarjeta no disponible'; END IF;
 SELECT full_name INTO v_name FROM ase_private.employee_profiles WHERE id=selected_user AND is_admin IS FALSE AND membership_status='active';
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarjeta no disponible'; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE user_id=selected_user AND state='active';
 IF p.id IS NOT NULL THEN v_action:='finish';
 ELSE
  SELECT x.* INTO p FROM public.work_day_plan x WHERE x.user_id=selected_user AND x.work_date=public.work_today() AND x.state='pending'
   ORDER BY x.priority LIMIT 1;
  IF p.id IS NOT NULL THEN v_action:='start'; END IF;
 END IF;
 IF p.id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE user_id=selected_user AND task_id=p.task_id) THEN
  RAISE EXCEPTION 'La asignación cambió. Consulta al encargado';
 END IF;
 SELECT title,description INTO v_title,v_description FROM public.tasks WHERE id=p.task_id;
 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE station_id=s.id AND result IS NULL;
 DELETE FROM public.work_station_tickets WHERE expires_at<now()-interval '7 days';
 INSERT INTO public.work_station_tickets(station_id,card_id,user_id,plan_id,expected_action,credential_method,credential_version)
 VALUES(s.id,c.id,selected_user,p.id,v_action,p_method,pin.pin_hash) RETURNING id INTO v_ticket;
 RETURN jsonb_build_object('ticket',v_ticket,'employee',v_name,'title',v_title,'description',v_description,'action',v_action,
  'started_at',p.started_at,'reader_mode',s.reader_mode);
END $function$;

ALTER FUNCTION public.work_pin_settings(uuid,text,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_station_identify_v2(text,text,text,uuid) OWNER TO ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261023000100_manual_station_key.sql ====
-- A station key configures a shared device; it is separate from employee PINs.

-- Non-superuser postgres needs the target owner to have CREATE during ownership transfer.
-- Both grant and revoke are in this transaction; the role retains no CREATE afterwards.
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_create_station(p_name text,p_token text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE token text:=nullif(btrim(p_token),''); station_id uuid;
BEGIN
 PERFORM public.work_assert_admin();
 IF p_name IS NULL OR length(btrim(p_name)) NOT BETWEEN 1 AND 100 THEN
  RAISE EXCEPTION 'Introduce un nombre de punto de entre 1 y 100 caracteres';
 END IF;
 IF token IS NULL THEN RETURN public.work_create_credential('station',btrim(p_name),NULL); END IF;
 IF length(token) NOT BETWEEN 8 AND 128 OR token ~ '[[:cntrl:]]' THEN
  RAISE EXCEPTION 'La clave del punto debe tener entre 8 y 128 caracteres, sin saltos de línea';
 END IF;
 INSERT INTO public.work_stations(name,token_hash)
 VALUES(btrim(p_name),public.work_hash(token)) RETURNING id INTO station_id;
 INSERT INTO public.work_station_keys(station_id,token) VALUES(station_id,token);
 RETURN jsonb_build_object('id',station_id,'token',token,'kind','station');
EXCEPTION WHEN unique_violation THEN
 RAISE EXCEPTION 'No se pudo utilizar esa clave. Elige una diferente';
END $$;
ALTER FUNCTION public.work_create_station(text,text) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_create_station(text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_create_station(text,text) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261023000200_confirmed_task_nfc.sql ====
-- NFC attached to a task: explicit action, authenticated user and expected check-in.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_task_nfc_checkin(p_card_uid text,p_task uuid,p_action text,p_expected_checkin uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=ase_private.session_user_id(); card public.nfc_cards%ROWTYPE;
 current_checkin public.checkins%ROWTYPE; result_id uuid; normalized text; matches integer; closed_at timestamptz;
BEGIN
 IF actor IS NULL OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR ase_private.current_org() IS NULL THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión para fichar';
 END IF;
 IF public.work_mode() THEN RAISE EXCEPTION 'Está activo el modo exclusivo de punto compartido. Confirma allí el fichaje'; END IF;
 IF p_action IS NULL OR p_action NOT IN ('checkin','checkout') OR p_task IS NULL THEN RAISE EXCEPTION 'Acción de fichaje no válida'; END IF;
 normalized:=lower(regexp_replace(coalesce(p_card_uid,''),'[[:space:]:-]','','g'));
 IF normalized !~ '^([0-9a-f]{2}){4,16}$' THEN RAISE EXCEPTION 'No se pudo leer el UID físico de la tarjeta'; END IF;
 -- Serialize a user's mobile NFC requests before checking open records.
 PERFORM 1 FROM public.organization_memberships WHERE user_id=actor AND organization_id=ase_private.current_org() AND status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Sesión no disponible'; END IF;
 PERFORM 1 FROM public.tasks t JOIN public.task_assignments a ON a.task_id=t.id AND a.organization_id=t.organization_id
 WHERE t.id=p_task AND a.user_id=actor FOR SHARE OF t,a;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarea no disponible o no asignada'; END IF;
 PERFORM 1 FROM public.task_checkin_config WHERE task_id=p_task AND nfc_enabled FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'El NFC no está habilitado para esta tarea'; END IF;
 SELECT count(*) INTO matches FROM public.nfc_cards c WHERE c.task_id=p_task AND c.is_active
 AND lower(regexp_replace(c.card_uid,'[[:space:]:-]','','g'))=normalized;
 IF matches<>1 THEN RAISE EXCEPTION 'Tarjeta no disponible para esta tarea'; END IF;
 SELECT * INTO card FROM public.nfc_cards c WHERE c.task_id=p_task AND c.is_active
 AND lower(regexp_replace(c.card_uid,'[[:space:]:-]','','g'))=normalized FOR SHARE;
 IF p_action='checkin' THEN
  IF p_expected_checkin IS NOT NULL THEN RAISE EXCEPTION 'Actualiza el estado del fichaje antes de iniciar'; END IF;
  PERFORM 1 FROM public.checkins WHERE user_id=actor AND checkout_time IS NULL FOR UPDATE;
  IF FOUND THEN RAISE EXCEPTION 'Ya tienes un fichaje abierto. Finalízalo antes de iniciar otro'; END IF;
  INSERT INTO public.checkins(task_id,user_id,checkin_method,nfc_card_id,checkin_time)
  VALUES(p_task,actor,'nfc',card.id,clock_timestamp()) RETURNING id INTO result_id;
 ELSE
  IF p_expected_checkin IS NULL THEN RAISE EXCEPTION 'Actualiza el estado del fichaje antes de finalizar'; END IF;
  SELECT * INTO current_checkin FROM public.checkins WHERE id=p_expected_checkin AND task_id=p_task AND user_id=actor FOR UPDATE;
  IF current_checkin.id IS NULL OR current_checkin.checkin_method<>'nfc' OR current_checkin.nfc_card_id IS DISTINCT FROM card.id THEN
   RAISE EXCEPTION 'Ese fichaje no corresponde a esta tarjeta y tarea';
  END IF;
  -- Retrying a confirmed close returns the same record, never starts a new one.
  IF current_checkin.checkout_time IS NOT NULL THEN
   RETURN jsonb_build_object('success',true,'type','checkout','checkin_id',current_checkin.id,'checkout_time',current_checkin.checkout_time,'already_closed',true);
  END IF;
  closed_at:=clock_timestamp();
  UPDATE public.checkins SET checkout_time=closed_at WHERE id=current_checkin.id;
  result_id:=current_checkin.id;
 END IF;
 RETURN jsonb_build_object('success',true,'type',p_action,'checkin_id',result_id,'checkout_time',closed_at);
END $$;
ALTER FUNCTION public.work_task_nfc_checkin(text,uuid,text,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_task_nfc_checkin(text,uuid,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_task_nfc_checkin(text,uuid,text,uuid) TO authenticated,ase_tenant_executor;
-- Retire the old toggle endpoint, which could close a record merely by reading twice.
CREATE OR REPLACE FUNCTION public.validate_nfc_checkin(p_card_uid character varying,p_task_id uuid,p_user_id uuid)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 RETURN json_build_object('success',false,'message','Actualiza la aplicación y confirma expresamente el inicio o la finalización del fichaje NFC');
END $$;
ALTER FUNCTION public.validate_nfc_checkin(character varying,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.validate_nfc_checkin(character varying,uuid,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.validate_nfc_checkin(character varying,uuid,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261023000300_active_checkin_actions.sql ====
-- Restrict employee writes to the employee's currently open checkin in this company.
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_can_act(p_task uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT ase_private.session_user_id() IS NOT NULL AND
 (public.sec06_is_admin() OR EXISTS (
  SELECT 1 FROM public.checkins c
  WHERE c.organization_id=ase_private.current_org() AND c.task_id=p_task
   AND c.user_id=ase_private.session_user_id() AND c.checkout_time IS NULL
 ))
$$;
ALTER FUNCTION public.work_can_act(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_can_act(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_can_act(uuid) TO authenticated,ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_require_active_checkin() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT public.work_can_act(NEW.task_id) THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Debes fichar en esta tarea antes de enviar comentarios, archivos o incidencias';
 END IF;
 RETURN NEW;
END $$;
ALTER FUNCTION public.work_require_active_checkin() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_require_active_checkin() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER work_comments_active_checkin BEFORE INSERT ON public.task_comments
 FOR EACH ROW EXECUTE FUNCTION public.work_require_active_checkin();
CREATE TRIGGER work_incidents_active_checkin BEFORE INSERT ON public.work_incidents
 FOR EACH ROW EXECUTE FUNCTION public.work_require_active_checkin();
CREATE POLICY work_upload_active_checkin ON storage.objects AS RESTRICTIVE FOR INSERT TO authenticated
 WITH CHECK (bucket_id <> 'task-files' OR CASE
 WHEN name ~ '^tasks/[0-9a-f-]{36}/' THEN public.work_can_act(split_part(name,'/',2)::uuid)
 ELSE false END);
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst, 'reload schema';

-- ==== 20261023000400_mobile_priority_queue.sql ====
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE FUNCTION public.work_incident_resolver(p_task uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.work_incidents i WHERE i.organization_id=ase_private.current_org()
 AND i.task_id=p_task AND i.state IN ('open','in_progress') AND
 (i.assigned_user=ase_private.session_user_id() OR EXISTS(SELECT 1 FROM public.work_area_members m
 WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id AND m.user_id=ase_private.session_user_id())))
$$;
CREATE FUNCTION public.work_mobile_queue() RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS (
 SELECT t.id task_id,t.title,p.id plan_id,p.priority,p.work_date,
 CASE WHEN o.id IS NOT NULL THEN 'active' WHEN p.state IN ('completed','blocked') THEN p.state
 WHEN c.id IS NOT NULL AND (p.id IS NULL OR c.checkin_time>=p.created_at) THEN 'completed'
 WHEN p.state IS NOT NULL THEN p.state ELSE 'unplanned' END state,
 public.work_incident_resolver(t.id) incident
 FROM public.tasks t
 LEFT JOIN LATERAL (SELECT * FROM public.work_day_plan x WHERE x.organization_id=t.organization_id AND x.task_id=t.id
 AND x.user_id=ase_private.session_user_id() AND (x.work_date=public.work_today() OR x.state='active')
 ORDER BY (x.state='active') DESC,x.work_date DESC LIMIT 1) p ON true
 LEFT JOIN LATERAL (SELECT id FROM public.checkins x WHERE x.organization_id=t.organization_id AND x.task_id=t.id AND x.user_id=ase_private.session_user_id()
 AND x.checkout_time IS NULL LIMIT 1) o ON true
 LEFT JOIN LATERAL (SELECT id,checkin_time FROM public.checkins x WHERE x.organization_id=t.organization_id AND x.task_id=t.id AND x.user_id=ase_private.session_user_id()
 AND x.checkout_time IS NOT NULL AND (x.checkin_time AT TIME ZONE 'Europe/Madrid')::date=public.work_today() ORDER BY x.checkin_time DESC LIMIT 1) c ON true
 WHERE t.organization_id=ase_private.current_org() AND (EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=t.organization_id AND a.task_id=t.id AND a.user_id=ase_private.session_user_id()) OR public.work_incident_resolver(t.id))
 ), next_item AS (SELECT task_id FROM items WHERE state='pending' AND work_date=public.work_today() ORDER BY priority,task_id LIMIT 1),
 opened AS (SELECT EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=ase_private.current_org() AND user_id=ase_private.session_user_id() AND checkout_time IS NULL) v)
 SELECT jsonb_build_object('date',public.work_today(),'next_task',(SELECT task_id FROM next_item),
 'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',NOT opened.v AND (i.task_id=(SELECT task_id FROM next_item) OR i.incident),
 'can_finish',i.state='active') ORDER BY (i.state='completed'),(i.state='active') DESC,i.priority NULLS LAST,i.task_id) FROM items i CROSS JOIN opened),'[]'::jsonb))
$$;
ALTER TABLE public.checkins ADD COLUMN work_incident_id uuid;
ALTER TABLE public.checkins ADD CONSTRAINT checkin_incident_scope FOREIGN KEY(organization_id,work_incident_id) REFERENCES public.work_incidents(organization_id,id);
CREATE FUNCTION public.work_mobile_order_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb;incident uuid;
BEGIN
 IF public.work_mode() OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR public.sec06_is_admin() THEN RETURN NEW; END IF;
 IF NEW.user_id IS DISTINCT FROM ase_private.session_user_id() THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible'; END IF;
 PERFORM 1 FROM public.organization_memberships WHERE organization_id=ase_private.current_org() AND user_id=NEW.user_id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=NEW.organization_id AND user_id=NEW.user_id AND checkout_time IS NULL) THEN RAISE EXCEPTION 'Finaliza primero tu fichaje activo'; END IF;
 SELECT x INTO item FROM jsonb_array_elements(public.work_mobile_queue()->'items') x WHERE x->>'task_id'=NEW.task_id::text;
 IF item IS NULL OR NOT coalesce((item->>'can_start')::boolean,false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Esta tarea está en consulta. Ficha en la siguiente tarea según el orden del encargado'; END IF;
 IF item->>'task_id'=public.work_mobile_queue()->>'next_task' THEN NEW.work_plan_id:=(item->>'plan_id')::uuid;
 ELSE
  SELECT i.id INTO incident FROM public.work_incidents i WHERE i.organization_id=NEW.organization_id AND i.task_id=NEW.task_id AND i.state IN ('open','in_progress')
  AND (i.assigned_user=NEW.user_id OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id AND m.user_id=NEW.user_id)) ORDER BY i.created_at LIMIT 1;
  NEW.work_incident_id:=incident;
 END IF;
 RETURN NEW;
END $$;
CREATE FUNCTION public.work_mobile_plan_sync() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.work_plan_id IS NOT NULL THEN
  IF TG_OP='INSERT' THEN UPDATE public.work_day_plan SET state='active',started_at=NEW.checkin_time,finished_at=NULL WHERE organization_id=NEW.organization_id AND id=NEW.work_plan_id AND user_id=NEW.user_id AND state='pending';
  ELSIF OLD.checkout_time IS NULL AND NEW.checkout_time IS NOT NULL THEN
   UPDATE public.work_day_plan SET state='completed',finished_at=NEW.checkout_time WHERE organization_id=NEW.organization_id AND id=NEW.work_plan_id AND user_id=NEW.user_id AND state='active';
  END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER work_mobile_order BEFORE INSERT ON public.checkins FOR EACH ROW EXECUTE FUNCTION public.work_mobile_order_guard();
CREATE TRIGGER work_mobile_sync AFTER INSERT OR UPDATE OF checkout_time ON public.checkins FOR EACH ROW EXECUTE FUNCTION public.work_mobile_plan_sync();
-- Assigned employees may consult details and history without reopening their work.
CREATE OR REPLACE FUNCTION public.work_can_detail(p_task_id uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT ase_private.session_user_id() IS NOT NULL AND (public.sec06_is_admin() OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task_id AND user_id=ase_private.session_user_id()) OR public.work_incident_resolver(p_task_id))
$$;
CREATE POLICY mobile_manual_insert ON public.checkins FOR INSERT TO authenticated WITH CHECK(user_id=ase_private.session_user_id() AND checkin_method='manual' AND checkout_time IS NULL AND work_station_id IS NULL AND employee_card_id IS NULL AND nfc_card_id IS NULL AND work_plan_id IS NOT NULL AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=checkins.organization_id AND a.task_id=checkins.task_id AND a.user_id=ase_private.session_user_id()));
CREATE POLICY incident_task_read ON public.tasks FOR SELECT TO authenticated USING(public.work_incident_resolver(id));
CREATE POLICY incident_config_read ON public.task_checkin_config FOR SELECT TO authenticated USING(public.work_incident_resolver(task_id));
CREATE POLICY incident_checkins_read ON public.checkins FOR SELECT TO authenticated USING(public.work_incident_resolver(task_id));
CREATE POLICY incident_comments_read ON public.task_comments FOR SELECT TO authenticated USING(public.work_incident_resolver(task_id));
CREATE POLICY incident_comments_insert ON public.task_comments FOR INSERT TO authenticated WITH CHECK(user_id=ase_private.session_user_id() AND public.work_incident_resolver(task_id));
CREATE POLICY incident_upload ON storage.objects FOR INSERT TO authenticated WITH CHECK(bucket_id='task-files' AND name ~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov)$' AND split_part(name,'/',3)=ase_private.session_user_id()::text AND public.work_incident_resolver(split_part(name,'/',2)::uuid));
DO $$ DECLARE f text; BEGIN
 FOREACH f IN ARRAY ARRAY['work_incident_resolver(uuid)','work_mobile_queue()','work_mobile_order_guard()','work_mobile_plan_sync()'] LOOP
 EXECUTE 'ALTER FUNCTION public.'||f||' OWNER TO ase_tenant_executor';
 EXECUTE 'REVOKE ALL ON FUNCTION public.'||f||' FROM PUBLIC,anon,authenticated';
 END LOOP;
END $$;
GRANT EXECUTE ON FUNCTION public.work_incident_resolver(uuid),public.work_mobile_queue() TO authenticated,ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_task_nfc_checkin(p_card_uid text,p_task uuid,p_action text,p_expected_checkin uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=ase_private.session_user_id(); card public.nfc_cards%ROWTYPE;
 current_checkin public.checkins%ROWTYPE; result_id uuid; normalized text; matches integer; closed_at timestamptz;
BEGIN
 IF actor IS NULL OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR ase_private.current_org() IS NULL THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión para fichar';
 END IF;
 IF public.work_mode() THEN RAISE EXCEPTION 'Está activo el modo exclusivo de punto compartido. Confirma allí el fichaje'; END IF;
 IF p_action IS NULL OR p_action NOT IN ('checkin','checkout') OR p_task IS NULL THEN RAISE EXCEPTION 'Acción de fichaje no válida'; END IF;
 normalized:=lower(regexp_replace(coalesce(p_card_uid,''),'[[:space:]:-]','','g'));
 IF normalized !~ '^([0-9a-f]{2}){4,16}$' THEN RAISE EXCEPTION 'No se pudo leer el UID físico de la tarjeta'; END IF;
 -- Serialize a user's mobile NFC requests before checking open records.
 PERFORM 1 FROM public.organization_memberships WHERE user_id=actor AND organization_id=ase_private.current_org() AND status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Sesión no disponible'; END IF;
 PERFORM 1 FROM public.tasks t LEFT JOIN public.task_assignments a ON a.task_id=t.id AND a.organization_id=t.organization_id AND a.user_id=actor
 WHERE t.id=p_task AND (a.user_id=actor OR public.work_incident_resolver(p_task)) FOR SHARE OF t;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarea no disponible o no asignada'; END IF;
 PERFORM 1 FROM public.task_checkin_config WHERE task_id=p_task AND nfc_enabled FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'El NFC no está habilitado para esta tarea'; END IF;
 SELECT count(*) INTO matches FROM public.nfc_cards c WHERE c.task_id=p_task AND c.is_active
 AND lower(regexp_replace(c.card_uid,'[[:space:]:-]','','g'))=normalized;
 IF matches<>1 THEN RAISE EXCEPTION 'Tarjeta no disponible para esta tarea'; END IF;
 SELECT * INTO card FROM public.nfc_cards c WHERE c.task_id=p_task AND c.is_active
 AND lower(regexp_replace(c.card_uid,'[[:space:]:-]','','g'))=normalized FOR SHARE;
 IF p_action='checkin' THEN
  IF p_expected_checkin IS NOT NULL THEN RAISE EXCEPTION 'Actualiza el estado del fichaje antes de iniciar'; END IF;
  PERFORM 1 FROM public.checkins WHERE user_id=actor AND checkout_time IS NULL FOR UPDATE;
  IF FOUND THEN RAISE EXCEPTION 'Ya tienes un fichaje abierto. Finalízalo antes de iniciar otro'; END IF;
  INSERT INTO public.checkins(task_id,user_id,checkin_method,nfc_card_id,checkin_time)
  VALUES(p_task,actor,'nfc',card.id,clock_timestamp()) RETURNING id INTO result_id;
 ELSE
  IF p_expected_checkin IS NULL THEN RAISE EXCEPTION 'Actualiza el estado del fichaje antes de finalizar'; END IF;
  SELECT * INTO current_checkin FROM public.checkins WHERE id=p_expected_checkin AND task_id=p_task AND user_id=actor FOR UPDATE;
  IF current_checkin.id IS NULL OR current_checkin.checkin_method<>'nfc' OR current_checkin.nfc_card_id IS DISTINCT FROM card.id THEN
   RAISE EXCEPTION 'Ese fichaje no corresponde a esta tarjeta y tarea';
  END IF;
  -- Retrying a confirmed close returns the same record, never starts a new one.
  IF current_checkin.checkout_time IS NOT NULL THEN
   RETURN jsonb_build_object('success',true,'type','checkout','checkin_id',current_checkin.id,'checkout_time',current_checkin.checkout_time,'already_closed',true);
  END IF;
  closed_at:=clock_timestamp();
  UPDATE public.checkins SET checkout_time=closed_at WHERE id=current_checkin.id;
  result_id:=current_checkin.id;
 END IF;
 RETURN jsonb_build_object('success',true,'type',p_action,'checkin_id',result_id,'checkout_time',closed_at);
END $$;
ALTER FUNCTION public.work_task_nfc_checkin(text,uuid,text,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_task_nfc_checkin(text,uuid,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_task_nfc_checkin(text,uuid,text,uuid) TO authenticated,ase_tenant_executor;

REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261023000500_incident_history.sql ====
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE TABLE public.work_incident_history(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_id uuid NOT NULL,
 incident_id uuid NOT NULL,
 actor_id uuid,
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 kind text NOT NULL CHECK(kind IN ('created','updated','snapshot')),
 previous_state text,
 state text NOT NULL,
 note text NOT NULL DEFAULT '',
 FOREIGN KEY(organization_id,incident_id) REFERENCES public.work_incidents(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
CREATE INDEX incident_history_timeline ON public.work_incident_history(organization_id,incident_id,recorded_at,id);
ALTER TABLE public.work_incident_history ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_incident_history FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_incident_history TO ase_tenant_executor;
CREATE POLICY incident_history_boundary ON public.work_incident_history AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY incident_history_executor ON public.work_incident_history TO ase_tenant_executor USING(true) WITH CHECK(true);
-- Keep only the known current state of existing records, without inventing earlier transitions.
INSERT INTO public.work_incident_history(organization_id,incident_id,kind,state,note)
 SELECT organization_id,id,'snapshot',state,coalesce(resolution,'') FROM public.work_incidents;
CREATE FUNCTION public.work_record_incident_history() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF TG_OP='INSERT' THEN
  INSERT INTO public.work_incident_history(organization_id,incident_id,actor_id,kind,state,note)
  VALUES(NEW.organization_id,NEW.id,ase_private.session_user_id(),'created',NEW.state,coalesce(NEW.resolution,''));
 ELSIF NEW.state IS DISTINCT FROM OLD.state OR NEW.resolution IS DISTINCT FROM OLD.resolution
 OR NEW.assigned_user IS DISTINCT FROM OLD.assigned_user OR NEW.area_id IS DISTINCT FROM OLD.area_id THEN
  INSERT INTO public.work_incident_history(organization_id,incident_id,actor_id,kind,previous_state,state,note)
  VALUES(NEW.organization_id,NEW.id,ase_private.session_user_id(),'updated',OLD.state,NEW.state,coalesce(NEW.resolution,''));
 END IF;
 RETURN NEW;
END $$;
ALTER FUNCTION public.work_record_incident_history() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_record_incident_history() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER work_incident_timeline AFTER INSERT OR UPDATE ON public.work_incidents
 FOR EACH ROW EXECUTE FUNCTION public.work_record_incident_history();
CREATE FUNCTION public.work_incident_history(p_incident uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE allowed boolean;events jsonb;
BEGIN
 SELECT true INTO allowed FROM public.work_incidents i
 WHERE i.organization_id=ase_private.current_org() AND i.id=p_incident
 AND (public.sec06_is_admin() OR i.reporter_id=ase_private.session_user_id() OR i.assigned_user=ase_private.session_user_id()
 OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id AND m.user_id=ase_private.session_user_id()));
 IF ase_private.session_user_id() IS NULL OR allowed IS DISTINCT FROM true THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Incidencia no disponible';
 END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',h.id,'at',h.recorded_at,'kind',h.kind,
 'previous_state',h.previous_state,'state',h.state,'note',h.note,'actor',u.full_name) ORDER BY h.recorded_at,h.id),'[]'::jsonb)
 INTO events FROM public.work_incident_history h LEFT JOIN ase_private.employee_profiles u ON u.id=h.actor_id
 WHERE h.organization_id=ase_private.current_org() AND h.incident_id=p_incident;
 RETURN events;
END $$;
ALTER FUNCTION public.work_incident_history(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_incident_history(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_incident_history(uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261023000600_lock_resolved_incidents.sql ====
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE FUNCTION public.work_lock_resolved_incident() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF OLD.state='resolved' THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La incidencia está resuelta y solo permite consultar su historial';
 END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 RETURN NEW;
END $$;
ALTER FUNCTION public.work_lock_resolved_incident() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_lock_resolved_incident() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER work_resolved_incident_readonly BEFORE UPDATE OR DELETE ON public.work_incidents
 FOR EACH ROW EXECUTE FUNCTION public.work_lock_resolved_incident();
CREATE OR REPLACE FUNCTION public.work_incident_inbox() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF ase_private.session_user_id() IS NULL OR ase_private.current_org() IS NULL THEN RAISE EXCEPTION 'Inicia sesión'; END IF;
 RETURN jsonb_build_object('items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('task_title',t.title,'reporter',u.full_name,'assigned_name',v.full_name,'area_name',a.name,'can_manage',i.state<>'resolved' AND (public.sec06_is_admin() OR i.assigned_user=ase_private.session_user_id() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=ase_private.session_user_id()))) ORDER BY i.created_at DESC)
 FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=i.reporter_id LEFT JOIN ase_private.employee_profiles v ON v.id=i.assigned_user LEFT JOIN public.work_areas a ON a.id=i.area_id
 WHERE public.sec06_is_admin() OR i.reporter_id=ase_private.session_user_id() OR i.assigned_user=ase_private.session_user_id() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=ase_private.session_user_id())),'[]'::jsonb),
 'notifications',coalesce((SELECT jsonb_agg(to_jsonb(n) ORDER BY n.created_at DESC) FROM (SELECT * FROM public.work_notifications WHERE user_id=ase_private.session_user_id() ORDER BY created_at DESC LIMIT 100) n),'[]'::jsonb));
END $$;
ALTER FUNCTION public.work_incident_inbox() OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261023000700_reports_and_history_search.sql ====
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_checkin_history_search(p_start date, p_end date, p_user uuid DEFAULT NULL::uuid, p_task uuid DEFAULT NULL::uuid, p_only_open boolean DEFAULT false, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50, p_personal boolean DEFAULT false, p_search text DEFAULT '', p_method text DEFAULT NULL, p_state text DEFAULT NULL)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE result jsonb; target_user uuid;
BEGIN
 IF ase_private.session_user_id() IS NULL OR p_personal IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;
 IF p_personal THEN target_user:=ase_private.session_user_id(); ELSE PERFORM public.work_assert_permission('checkins.view'); target_user:=p_user; END IF;
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR p_offset IS NULL OR p_offset<0 OR p_limit IS NULL OR p_limit<1 OR p_limit>100 OR p_only_open IS NULL THEN RAISE EXCEPTION 'Filtros no válidos'; END IF;
 IF length(coalesce(p_search,''))>120 OR (p_method IS NOT NULL AND p_method NOT IN ('nfc','manual','qr')) OR (p_state IS NOT NULL AND p_state NOT IN ('open','closed')) THEN RAISE EXCEPTION 'Filtros no válidos'; END IF;
 WITH filtered AS (
 SELECT c.id,c.task_id,c.user_id,coalesce(u.full_name,'Empleado eliminado') AS employee,t.title,c.checkin_time,c.checkout_time,c.checkin_method,c.location,
 greatest(0,extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)) AS seconds
 FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id
 WHERE (target_user IS NULL OR c.user_id=target_user) AND (p_task IS NULL OR c.task_id=p_task)
 AND (NOT p_only_open OR c.checkout_time IS NULL)
 AND (p_method IS NULL OR c.checkin_method=p_method)
 AND (p_state IS NULL OR (p_state='open' AND c.checkout_time IS NULL) OR (p_state='closed' AND c.checkout_time IS NOT NULL))
 AND (coalesce(btrim(p_search),'')='' OR strpos(lower(coalesce(u.full_name,'')||' '||t.title),lower(btrim(p_search)))>0)
 AND c.checkin_time>=p_start::timestamp AT TIME ZONE 'Europe/Madrid' AND c.checkin_time<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
 ), page AS (SELECT * FROM filtered ORDER BY checkin_time DESC,id OFFSET p_offset LIMIT p_limit)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(to_jsonb(p) ORDER BY p.checkin_time DESC,p.id) FROM page p),'[]'::jsonb),'as_of',now()) INTO result;
 RETURN result;
END $function$
;
ALTER FUNCTION public.work_checkin_history_search(date,date,uuid,uuid,boolean,integer,integer,boolean,text,text,text) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_checkin_history_search(date,date,uuid,uuid,boolean,integer,integer,boolean,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_checkin_history_search(date,date,uuid,uuid,boolean,integer,integer,boolean,text,text,text) TO authenticated,ase_tenant_executor;
CREATE FUNCTION public.work_report_table(p_kind text,p_start date,p_end date,p_search text DEFAULT '',p_state text DEFAULT NULL,p_method text DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 IF p_kind IS NULL OR p_kind NOT IN ('checkins','tasks','productivity','incidents','closures') OR p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR length(coalesce(p_search,''))>120 THEN RAISE EXCEPTION 'Selecciona un informe y un período de hasta 366 días'; END IF;
 WITH source AS (
SELECT row FROM (SELECT jsonb_build_object('_at',c.checkin_time,'_state',CASE WHEN c.checkout_time IS NULL THEN 'open' ELSE 'closed' END,'_method',c.checkin_method,'employee',u.full_name,'task',t.title,'start',c.checkin_time,'end',c.checkout_time,'minutes',round((extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)/60)::numeric,2),'method',c.checkin_method,'status',CASE WHEN c.checkout_time IS NULL THEN 'En curso' ELSE 'Cerrado' END) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id) dataset WHERE p_kind='checkins'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',(coalesce(p.work_date,t.schedule_date,(t.created_at AT TIME ZONE 'Europe/Madrid')::date)::timestamp AT TIME ZONE 'Europe/Madrid'),'_state',coalesce(p.state,'unplanned'),'employee',u.full_name,'task',t.title,'date',coalesce(p.work_date,t.schedule_date),'priority',p.priority,'status',CASE p.state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'completed' THEN 'Completada' WHEN 'blocked' THEN 'Bloqueada' ELSE 'Sin planificación' END) row FROM public.tasks t LEFT JOIN public.task_assignments a ON a.task_id=t.id LEFT JOIN ase_private.employee_profiles u ON u.id=a.user_id LEFT JOIN public.work_day_plan p ON p.task_id=t.id AND p.user_id=a.user_id) dataset WHERE p_kind='tasks'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',((c.checkin_time AT TIME ZONE 'Europe/Madrid')::date::timestamp AT TIME ZONE 'Europe/Madrid'),'employee',u.full_name,'task',t.title,'date',(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date,'count',count(*),'minutes',round(sum(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2),'average',round(avg(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2)) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id WHERE c.checkout_time>=c.checkin_time GROUP BY c.user_id,u.full_name,t.id,t.title,(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date) dataset WHERE p_kind='productivity'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',i.created_at,'_state',i.state,'employee',u.full_name,'task',t.title,'subject',i.subject,'responsible',coalesce(a.name,v.full_name),'start',i.created_at,'updated',i.updated_at,'status',CASE i.state WHEN 'open' THEN 'Abierta' WHEN 'in_progress' THEN 'En atención' ELSE 'Resuelta' END,'blocked',CASE WHEN i.blocks_work THEN 'Sí' ELSE 'No' END,'resolution',i.resolution) row FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=i.reporter_id LEFT JOIN ase_private.employee_profiles v ON v.id=i.assigned_user LEFT JOIN public.work_areas a ON a.id=i.area_id) dataset WHERE p_kind='incidents'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',c.created_at,'employee',u.full_name,'task',t.title,'actor',v.full_name,'start',c.created_at,'type',CASE c.kind WHEN 'admin_finish' THEN 'Cierre administrativo' ELSE 'Bloqueo por incidencia' END,'reason',c.reason) row FROM public.work_task_closures c JOIN public.work_day_plan p ON p.id=c.plan_id JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id LEFT JOIN ase_private.employee_profiles v ON v.id=c.actor_id) dataset WHERE p_kind='closures'
 ), filtered AS (
 SELECT row FROM source WHERE (row->>'_at')::timestamptz>=p_start::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (row->>'_at')::timestamptz<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (p_state IS NULL OR row->>'_state'=p_state) AND (p_method IS NULL OR row->>'_method'=p_method)
 AND (coalesce(btrim(p_search),'')='' OR strpos(lower((row-'_at'-'_state'-'_method')::text),lower(btrim(p_search)))>0)
 ), limited AS (SELECT row FROM filtered ORDER BY row->>'_at' DESC,row::text LIMIT 10001)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(row-'_at'-'_state'-'_method') FROM limited),'[]'::jsonb),'as_of',now()) INTO result;
 IF (result->>'total')::integer>10000 THEN RAISE EXCEPTION 'Hay más de 10.000 filas. Reduce las fechas o utiliza el buscador antes de descargar'; END IF;
 RETURN result;
END $$;
ALTER FUNCTION public.work_report_table(text,date,date,text,text,text) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_report_table(text,date,date,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_report_table(text,date,date,text,text,text) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261023000800_report_employee_filter.sql ====
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE FUNCTION public.work_report_table(p_kind text,p_start date,p_end date,p_search text,p_state text,p_method text,p_employee uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 IF p_kind IS NULL OR p_kind NOT IN ('checkins','tasks','productivity','incidents','closures') OR p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR length(coalesce(p_search,''))>120 THEN RAISE EXCEPTION 'Selecciona un informe y un período de hasta 366 días'; END IF;
 WITH source AS (
SELECT row FROM (SELECT jsonb_build_object('_at',c.checkin_time,'_state',CASE WHEN c.checkout_time IS NULL THEN 'open' ELSE 'closed' END,'_method',c.checkin_method,'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'start',c.checkin_time,'end',c.checkout_time,'minutes',round((extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)/60)::numeric,2),'method',c.checkin_method,'status',CASE WHEN c.checkout_time IS NULL THEN 'En curso' ELSE 'Cerrado' END) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id) dataset WHERE p_kind='checkins'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',(coalesce(p.work_date,t.schedule_date,(t.created_at AT TIME ZONE 'Europe/Madrid')::date)::timestamp AT TIME ZONE 'Europe/Madrid'),'_state',coalesce(p.state,'unplanned'),'_users',jsonb_build_array(a.user_id),'employee',u.full_name,'task',t.title,'date',coalesce(p.work_date,t.schedule_date),'priority',p.priority,'status',CASE p.state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'completed' THEN 'Completada' WHEN 'blocked' THEN 'Bloqueada' ELSE 'Sin planificación' END) row FROM public.tasks t LEFT JOIN public.task_assignments a ON a.task_id=t.id LEFT JOIN ase_private.employee_profiles u ON u.id=a.user_id LEFT JOIN public.work_day_plan p ON p.task_id=t.id AND p.user_id=a.user_id) dataset WHERE p_kind='tasks'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',((c.checkin_time AT TIME ZONE 'Europe/Madrid')::date::timestamp AT TIME ZONE 'Europe/Madrid'),'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'date',(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date,'count',count(*),'minutes',round(sum(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2),'average',round(avg(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2)) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id WHERE c.checkout_time>=c.checkin_time GROUP BY c.user_id,u.full_name,t.id,t.title,(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date) dataset WHERE p_kind='productivity'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',i.created_at,'_state',i.state,'_users',jsonb_build_array(i.reporter_id,i.assigned_user)||coalesce((SELECT jsonb_agg(m.user_id) FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id),'[]'::jsonb),'employee',u.full_name,'task',t.title,'subject',i.subject,'responsible',coalesce(a.name,v.full_name),'start',i.created_at,'updated',i.updated_at,'status',CASE i.state WHEN 'open' THEN 'Abierta' WHEN 'in_progress' THEN 'En atención' ELSE 'Resuelta' END,'blocked',CASE WHEN i.blocks_work THEN 'Sí' ELSE 'No' END,'resolution',i.resolution) row FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=i.reporter_id LEFT JOIN ase_private.employee_profiles v ON v.id=i.assigned_user LEFT JOIN public.work_areas a ON a.id=i.area_id) dataset WHERE p_kind='incidents'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',c.created_at,'_users',jsonb_build_array(p.user_id),'employee',u.full_name,'task',t.title,'actor',v.full_name,'start',c.created_at,'type',CASE c.kind WHEN 'admin_finish' THEN 'Cierre administrativo' ELSE 'Bloqueo por incidencia' END,'reason',c.reason) row FROM public.work_task_closures c JOIN public.work_day_plan p ON p.id=c.plan_id JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id LEFT JOIN ase_private.employee_profiles v ON v.id=c.actor_id) dataset WHERE p_kind='closures'
 ), filtered AS (
 SELECT row FROM source WHERE (row->>'_at')::timestamptz>=p_start::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (row->>'_at')::timestamptz<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (p_employee IS NULL OR row->'_users' @> jsonb_build_array(p_employee))
 AND (p_state IS NULL OR row->>'_state'=p_state) AND (p_method IS NULL OR row->>'_method'=p_method)
 AND (coalesce(btrim(p_search),'')='' OR strpos(lower((row-'_at'-'_state'-'_method'-'_users')::text),lower(btrim(p_search)))>0)
 ), limited AS (SELECT row FROM filtered ORDER BY row->>'_at' DESC,row::text LIMIT 10001)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(row-'_at'-'_state'-'_method'-'_users') FROM limited),'[]'::jsonb),'as_of',now()) INTO result;
 IF (result->>'total')::integer>10000 THEN RAISE EXCEPTION 'Hay más de 10.000 filas. Reduce las fechas o utiliza el buscador antes de descargar'; END IF;
 RETURN result;
END $$;
ALTER FUNCTION public.work_report_table(text,date,date,text,text,text,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_report_table(text,date,date,text,text,text,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_report_table(text,date,date,text,text,text,uuid) TO authenticated,ase_tenant_executor;
CREATE FUNCTION public.work_report_employees() RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',id,'full_name',full_name,'status',membership_status) ORDER BY full_name,id) FROM ase_private.employee_profiles),'[]'::jsonb);
END $$;
ALTER FUNCTION public.work_report_employees() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_report_employees() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_report_employees() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261023000900_task_checklists.sql ====
-- Checklist templates and immutable per-checkin copies. Existing completed records are unchanged.
CREATE TABLE IF NOT EXISTS public.work_checklist_templates (
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(), task_id uuid NOT NULL, steps jsonb NOT NULL DEFAULT '[]',
 PRIMARY KEY(organization_id,task_id), FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 CHECK(jsonb_typeof(steps)='array' AND jsonb_array_length(steps)<=50));
CREATE TABLE IF NOT EXISTS public.work_checklist_runs (
 organization_id uuid NOT NULL, checkin_id uuid NOT NULL, steps jsonb NOT NULL DEFAULT '[]',
 PRIMARY KEY(organization_id,checkin_id), FOREIGN KEY(organization_id,checkin_id) REFERENCES public.checkins(organization_id,id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS public.work_checklist_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,checkin_id uuid NOT NULL,step_id uuid NOT NULL,
 actor_id uuid NOT NULL,done boolean NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 FOREIGN KEY(organization_id,checkin_id) REFERENCES public.work_checklist_runs(organization_id,checkin_id) ON DELETE CASCADE);
CREATE INDEX IF NOT EXISTS work_checklist_events_history ON public.work_checklist_events(organization_id,checkin_id,created_at,id);
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['work_checklist_templates','work_checklist_runs','work_checklist_events'] LOOP
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
  EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC,anon,authenticated',t);
  EXECUTE format('GRANT SELECT,INSERT,UPDATE ON public.%I TO ase_tenant_executor',t);
  EXECUTE format('DROP POLICY IF EXISTS checklist_executor ON public.%I',t);
  EXECUTE format('CREATE POLICY checklist_executor ON public.%I TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org())',t);
 END LOOP;
END $$;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_save_checklist(p_task uuid,p_steps jsonb,p_previous jsonb) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb; normalized jsonb:='[]'; existing jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 PERFORM 1 FROM public.tasks WHERE id=p_task FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Tarea no disponible'; END IF;
 SELECT steps INTO existing FROM public.work_checklist_templates WHERE task_id=p_task;
 IF coalesce(existing,'[]') IS DISTINCT FROM p_previous THEN RAISE EXCEPTION 'Los pasos han cambiado. Cierra y vuelve a abrir la lista antes de guardar'; END IF;
 IF p_steps IS NULL OR jsonb_typeof(p_steps)<>'array' THEN RAISE EXCEPTION 'Lista de pasos no válida'; END IF;
 IF jsonb_array_length(p_steps)>50 THEN RAISE EXCEPTION 'Máximo 50 pasos por tarea'; END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(p_steps) LOOP
  IF jsonb_typeof(item)<>'object' OR jsonb_typeof(item->'title') IS DISTINCT FROM 'string' OR length(btrim(item->>'title')) NOT BETWEEN 1 AND 200 OR jsonb_typeof(item->'required') IS DISTINCT FROM 'boolean' OR item->>'id' IS NULL THEN RAISE EXCEPTION 'Cada paso necesita título, identificador y obligatoriedad'; END IF;
  normalized:=normalized||jsonb_build_array(jsonb_build_object('id',(item->>'id')::uuid,'title',btrim(item->>'title'),'required',(item->>'required')::boolean));
 END LOOP;
 IF (SELECT count(DISTINCT value->>'id') FROM jsonb_array_elements(normalized))<>jsonb_array_length(normalized) THEN RAISE EXCEPTION 'No repitas identificadores de pasos'; END IF;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE task_id=p_task AND checkout_time IS NULL) THEN RAISE EXCEPTION 'Espera a que finalicen los fichajes abiertos para modificar los pasos'; END IF;
 INSERT INTO public.work_checklist_templates(organization_id,task_id,steps) VALUES(ase_private.current_org(),p_task,normalized)
 ON CONFLICT(organization_id,task_id) DO UPDATE SET steps=EXCLUDED.steps;
END $$;
CREATE OR REPLACE FUNCTION public.work_snapshot_checklist() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE items jsonb;
BEGIN
 PERFORM 1 FROM public.tasks WHERE id=NEW.task_id FOR SHARE;
 SELECT steps INTO items FROM public.work_checklist_templates WHERE task_id=NEW.task_id;
 INSERT INTO public.work_checklist_runs(organization_id,checkin_id,steps)
 VALUES(NEW.organization_id,NEW.id,coalesce(items,'[]')) ON CONFLICT DO NOTHING;
 RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS work_checklist_snapshot ON public.checkins;
CREATE TRIGGER work_checklist_snapshot AFTER INSERT ON public.checkins FOR EACH ROW EXECUTE FUNCTION public.work_snapshot_checklist();
-- Bootstrap only open checkins. Empty templates make existing execution compatible.
INSERT INTO public.work_checklist_runs(organization_id,checkin_id,steps)
 SELECT c.organization_id,c.id,coalesce(t.steps,'[]') FROM public.checkins c LEFT JOIN public.work_checklist_templates t ON t.organization_id=c.organization_id AND t.task_id=c.task_id
 WHERE c.checkout_time IS NULL ON CONFLICT DO NOTHING;
CREATE OR REPLACE FUNCTION public.work_get_checklist(p_task uuid,p_checkin uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE c public.checkins%ROWTYPE; items jsonb; events jsonb; manager boolean;
BEGIN
 IF ase_private.session_user_id() IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;
 manager:=public.work_has_permission('tasks.view') OR public.work_has_permission('checkins.view');
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE id=p_task) OR NOT (manager OR public.work_incident_resolver(p_task) OR EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarea no disponible'; END IF;
 IF p_checkin IS NULL THEN
  SELECT steps INTO items FROM public.work_checklist_templates WHERE task_id=p_task;
  RETURN jsonb_build_object('steps',coalesce(items,'[]'),'editable',false,'events','[]'::jsonb);
 END IF;
 SELECT * INTO c FROM public.checkins WHERE id=p_checkin AND task_id=p_task;
 IF NOT FOUND OR NOT(manager OR c.user_id=ase_private.session_user_id()) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible'; END IF;
 SELECT steps INTO items FROM public.work_checklist_runs WHERE checkin_id=c.id;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',e.id,'step_id',e.step_id,'done',e.done,'at',e.created_at,'actor',coalesce(u.full_name,'Empleado')) ORDER BY e.created_at,e.id),'[]') INTO events
 FROM public.work_checklist_events e LEFT JOIN ase_private.employee_profiles u ON u.id=e.actor_id WHERE e.checkin_id=c.id;
 RETURN jsonb_build_object('steps',coalesce(items,'[]'),'editable',c.user_id=ase_private.session_user_id() AND c.checkout_time IS NULL,'events',events);
END $$;
CREATE OR REPLACE FUNCTION public.work_mark_checklist(p_checkin uuid,p_step uuid,p_done boolean) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE c public.checkins%ROWTYPE;items jsonb;position integer;
BEGIN
 SELECT * INTO c FROM public.checkins WHERE id=p_checkin FOR UPDATE;
 IF NOT FOUND OR c.user_id IS DISTINCT FROM ase_private.session_user_id() OR c.checkout_time IS NOT NULL OR p_done IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Solo puedes marcar pasos durante tu fichaje activo'; END IF;
 SELECT steps INTO items FROM public.work_checklist_runs WHERE checkin_id=c.id FOR UPDATE;
 SELECT (ordinality-1)::integer INTO position FROM jsonb_array_elements(items) WITH ORDINALITY WHERE value->>'id'=p_step::text;
 IF position IS NULL THEN RAISE EXCEPTION 'Paso no disponible'; END IF;
 IF coalesce((items->position->>'done')::boolean,false)=p_done THEN RETURN; END IF;
 items:=jsonb_set(items,ARRAY[position::text,'done'],to_jsonb(p_done));
 UPDATE public.work_checklist_runs SET steps=items WHERE checkin_id=c.id;
 INSERT INTO public.work_checklist_events(organization_id,checkin_id,step_id,actor_id,done) VALUES(c.organization_id,c.id,p_step,ase_private.session_user_id(),p_done);
END $$;
CREATE OR REPLACE FUNCTION public.work_guard_checklist_completion() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 -- Exceptional administrative/incident closures retain their separate, mandatory reason and audit.
 IF EXISTS(SELECT 1 FROM public.work_task_closures WHERE checkin_id=NEW.id AND kind IN ('incident_block','admin_finish')) THEN RETURN NEW; END IF;
 IF EXISTS(SELECT 1 FROM public.work_checklist_runs r CROSS JOIN LATERAL jsonb_array_elements(r.steps) item WHERE r.checkin_id=NEW.id AND (item->>'required')::boolean AND NOT coalesce((item->>'done')::boolean,false)) THEN
  RAISE EXCEPTION 'Completa los pasos obligatorios antes de finalizar la tarea';
 END IF;
 RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS work_checklist_completion ON public.checkins;
CREATE CONSTRAINT TRIGGER work_checklist_completion AFTER UPDATE ON public.checkins DEFERRABLE INITIALLY DEFERRED
 FOR EACH ROW WHEN(OLD.checkout_time IS NULL AND NEW.checkout_time IS NOT NULL) EXECUTE FUNCTION public.work_guard_checklist_completion();
ALTER FUNCTION public.work_save_checklist(uuid,jsonb,jsonb) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_snapshot_checklist() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_get_checklist(uuid,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mark_checklist(uuid,uuid,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_guard_checklist_completion() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_save_checklist(uuid,jsonb,jsonb),public.work_get_checklist(uuid,uuid),public.work_mark_checklist(uuid,uuid,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_save_checklist(uuid,jsonb,jsonb),public.work_get_checklist(uuid,uuid),public.work_mark_checklist(uuid,uuid,boolean) TO authenticated,ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_snapshot_checklist(),public.work_guard_checklist_completion() FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION public.work_station_checklist(p_station text,p_ticket uuid,p_step uuid DEFAULT NULL,p_done boolean DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE k public.work_station_tickets%ROWTYPE;c public.checkins%ROWTYPE;items jsonb;position integer;
BEGIN
 -- Reuse station binding, card/PIN revocation, membership and expiry validation.
 PERFORM public.work_station_day_v2(p_station,p_ticket);
 SELECT * INTO k FROM public.work_station_tickets WHERE id=p_ticket FOR UPDATE;
 IF NOT FOUND OR k.expires_at<=clock_timestamp() OR k.result IS NOT NULL OR k.expected_action<>'finish' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Vuelve a identificarte para consultar tus pasos'; END IF;
 SELECT * INTO c FROM public.checkins WHERE user_id=k.user_id AND work_plan_id=k.plan_id AND checkout_time IS NULL FOR UPDATE;
 IF NOT FOUND OR NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=c.task_id AND user_id=k.user_id) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes esta tarea en curso'; END IF;
 SELECT steps INTO items FROM public.work_checklist_runs WHERE checkin_id=c.id FOR UPDATE;
 IF p_step IS NOT NULL THEN
  IF p_done IS NULL THEN RAISE EXCEPTION 'Marca un estado válido'; END IF;
  SELECT (ordinality-1)::integer INTO position FROM jsonb_array_elements(items) WITH ORDINALITY WHERE value->>'id'=p_step::text;
  IF position IS NULL THEN RAISE EXCEPTION 'Paso no disponible'; END IF;
  IF coalesce((items->position->>'done')::boolean,false) IS DISTINCT FROM p_done THEN
   items:=jsonb_set(items,ARRAY[position::text,'done'],to_jsonb(p_done));
   UPDATE public.work_checklist_runs SET steps=items WHERE checkin_id=c.id;
   INSERT INTO public.work_checklist_events(organization_id,checkin_id,step_id,actor_id,done) VALUES(c.organization_id,c.id,p_step,k.user_id,p_done);
  END IF;
 END IF;
 RETURN jsonb_build_object('steps',coalesce(items,'[]'),'checkin_id',c.id);
END $$;
ALTER FUNCTION public.work_station_checklist(text,uuid,uuid,boolean) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_station_checklist(text,uuid,uuid,boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.work_station_checklist(text,uuid,uuid,boolean) TO anon,authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261023001000_planning_board.sql ====
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_planning_board(p_date date,p_user uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE items jsonb; total integer;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_date IS NULL THEN RAISE EXCEPTION 'Selecciona una fecha válida'; END IF;
 SELECT count(*) INTO total FROM public.work_day_plan WHERE work_date=p_date AND (p_user IS NULL OR user_id=p_user);
 IF total>10000 THEN RAISE EXCEPTION 'Hay demasiadas tareas para mostrar. Selecciona un empleado'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object(
  'id',p.id,'task_id',p.task_id,'employee_id',p.user_id,'employee',coalesce(u.full_name,'Empleado no disponible'),
  'title',t.title,'description',t.description,'priority',p.priority,'state',p.state,'work_date',p.work_date,
  'started_at',p.started_at,'finished_at',p.finished_at) || public.work_deadline(p.work_date,p.state,p.finished_at)
  ORDER BY p.priority,u.full_name,p.id),'[]'::jsonb) INTO items
 FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
 WHERE p.work_date=p_date AND (p_user IS NULL OR p.user_id=p_user);
 RETURN jsonb_build_object('date',p_date,'items',items,'total',total,'as_of',now());
END $$;
ALTER FUNCTION public.work_planning_board(date,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board(date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_board(date,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261023001100_board_state_changes.sql ====
-- A reopened plan retains prior closed checkins, with at most one open execution.
DROP INDEX IF EXISTS public.work_checkin_per_plan;
CREATE UNIQUE INDEX work_checkin_per_plan ON public.checkins(organization_id,work_plan_id) WHERE work_plan_id IS NOT NULL AND checkout_time IS NULL;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS board_version bigint NOT NULL DEFAULT 0;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS board_reopened_at timestamptz;
CREATE TABLE IF NOT EXISTS public.work_board_events(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),id uuid NOT NULL,plan_id uuid NOT NULL,actor_id uuid NOT NULL,actor_name text NOT NULL,
 from_state text NOT NULL,to_state text NOT NULL,reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 5 AND 2000),
 checkin_id uuid,incident_id uuid,responsible_id uuid,applied_version bigint NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id),FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id),
 FOREIGN KEY(organization_id,checkin_id) REFERENCES public.checkins(organization_id,id),
 FOREIGN KEY(organization_id,incident_id) REFERENCES public.work_incidents(organization_id,id));
ALTER TABLE public.work_board_events ADD COLUMN IF NOT EXISTS responsible_id uuid;
CREATE INDEX IF NOT EXISTS work_board_events_plan ON public.work_board_events(organization_id,plan_id,created_at,id);
ALTER TABLE public.work_board_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_board_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_board_events TO ase_tenant_executor;
DROP POLICY IF EXISTS board_events_executor ON public.work_board_events;
CREATE POLICY board_events_executor ON public.work_board_events TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_board_version() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$ BEGIN
 NEW.board_version:=OLD.board_version+1; RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS work_board_version ON public.work_day_plan;
CREATE TRIGGER work_board_version BEFORE UPDATE ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION public.work_board_version();
CREATE OR REPLACE FUNCTION public.work_move_board(p_plan uuid,p_state text,p_version bigint,p_reason text,p_request uuid,p_responsible uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;c public.checkins%ROWTYPE;e public.work_board_events%ROWTYPE;
 actor uuid:=ase_private.session_user_id();person uuid;stamp timestamptz:=clock_timestamp();incident uuid;checkin uuid;version bigint;old_flag text:=coalesce(current_setting('ase.tablet_write',true),'off');
BEGIN
 PERFORM public.work_assert_admin();
 IF p_request IS NULL OR p_version IS NULL OR p_state IS NULL OR p_state NOT IN ('pending','active','blocked','completed') OR p_reason IS NULL OR length(btrim(p_reason)) NOT BETWEEN 5 AND 2000 THEN RAISE EXCEPTION 'Indica un motivo de 5 a 2000 caracteres y un estado válido'; END IF;
 SELECT * INTO e FROM public.work_board_events WHERE id=p_request;
 IF FOUND THEN
  IF e.plan_id<>p_plan OR e.to_state<>p_state OR e.actor_id<>actor OR e.reason<>btrim(p_reason) OR e.responsible_id IS DISTINCT FROM (CASE WHEN p_state='blocked' THEN p_responsible ELSE NULL END) THEN RAISE EXCEPTION 'Identificador de operación ya utilizado'; END IF;
  RETURN jsonb_build_object('success',true,'state',e.to_state,'version',e.applied_version,'repeated',true);
 END IF;
 SELECT user_id INTO person FROM public.work_day_plan WHERE id=p_plan;
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=person AND membership_status='active' AND is_admin IS FALSE FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado o planificación no disponible'; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE id=p_plan FOR UPDATE;
 IF NOT FOUND OR p.board_version<>p_version THEN RAISE EXCEPTION 'La tarjeta ha cambiado. Actualiza el tablero y vuelve a intentarlo'; END IF;
 IF p.state=p_state THEN RAISE EXCEPTION 'La tarea ya está en ese estado'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=p.task_id AND user_id=p.user_id) THEN RAISE EXCEPTION 'La tarea ya no está asignada al empleado'; END IF;
 IF p.state='active' AND p_state='pending' OR p.state='pending' AND p_state='completed' OR p.state='blocked' AND p_state='completed' THEN RAISE EXCEPTION 'Para completar debe existir un fichaje activo. Para detener trabajo utiliza Bloqueadas'; END IF;
 IF p.state IN ('blocked','completed') AND p_state IN ('pending','active') AND EXISTS(SELECT 1 FROM public.work_incidents WHERE plan_id=p.id AND blocks_work AND state<>'resolved') THEN RAISE EXCEPTION 'Resuelve primero las incidencias que bloquean esta tarea'; END IF;
 SELECT * INTO c FROM public.checkins WHERE work_plan_id=p.id AND user_id=p.user_id AND checkout_time IS NULL FOR UPDATE;
 PERFORM set_config('ase.tablet_write','on',true);
 IF p_state='active' THEN
  IF p.work_date<>public.work_today() THEN RAISE EXCEPTION 'Solo se puede iniciar trabajo planificado para hoy'; END IF;
  IF EXISTS(SELECT 1 FROM public.checkins WHERE user_id=p.user_id AND checkout_time IS NULL) OR EXISTS(SELECT 1 FROM public.work_day_plan WHERE user_id=p.user_id AND state='active') THEN RAISE EXCEPTION 'El empleado ya tiene un fichaje activo'; END IF;
  IF EXISTS(SELECT 1 FROM public.work_day_plan WHERE user_id=p.user_id AND work_date=p.work_date AND state='pending' AND priority<p.priority AND id<>p.id) THEN RAISE EXCEPTION 'Respeta el orden de tareas del empleado o revisa su planificación'; END IF;
  IF p.state<>'pending' THEN UPDATE public.work_day_plan SET state='pending',started_at=NULL,finished_at=NULL,board_reopened_at=stamp WHERE id=p.id; END IF;
  INSERT INTO public.checkins(task_id,user_id,checkin_time,checkin_method,location,work_plan_id)
   VALUES(p.task_id,p.user_id,stamp,'manual','Inicio administrativo desde tablero',p.id) RETURNING id INTO checkin;
  UPDATE public.work_day_plan SET state='active',started_at=stamp,finished_at=NULL WHERE id=p.id;
 ELSIF p_state='completed' THEN
  IF p.state<>'active' OR c.id IS NULL THEN RAISE EXCEPTION 'No hay un fichaje activo que finalizar'; END IF;
  IF EXISTS(SELECT 1 FROM public.work_checklist_runs r CROSS JOIN LATERAL jsonb_array_elements(r.steps) item WHERE r.checkin_id=c.id AND (item->>'required')::boolean AND NOT coalesce((item->>'done')::boolean,false)) THEN RAISE EXCEPTION 'Completa los pasos obligatorios antes de finalizar la tarea'; END IF;
  checkin:=ase_private.close_work(p.id,btrim(p_reason),'admin_finish',NULL);
 ELSIF p_state='blocked' THEN
  IF p_responsible IS NULL OR NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_responsible AND membership_status='active') THEN RAISE EXCEPTION 'Selecciona quién resolverá la incidencia'; END IF;
  IF p.state='active' AND c.id IS NULL THEN RAISE EXCEPTION 'No se encontró el fichaje activo. Revisa la planificación'; END IF;
  INSERT INTO public.work_incidents(task_id,plan_id,reporter_id,assigned_user,subject,description,blocks_work)
   VALUES(p.task_id,p.id,actor,p_responsible,'Bloqueo desde tablero',btrim(p_reason),true) RETURNING id INTO incident;
  INSERT INTO public.work_notifications(user_id,incident_id,message) VALUES(p_responsible,incident,'Nueva incidencia: '||left(p_reason,120));
  IF c.id IS NOT NULL THEN
   UPDATE public.checkins SET checkout_time=stamp WHERE id=c.id;
   INSERT INTO public.work_task_closures(plan_id,checkin_id,actor_id,reason,kind,incident_id)
    VALUES(p.id,c.id,actor,btrim(p_reason),'incident_block',incident);
   checkin:=c.id;
  END IF;
  UPDATE public.work_day_plan SET state='blocked',finished_at=CASE WHEN c.id IS NOT NULL THEN stamp ELSE finished_at END WHERE id=p.id;
 ELSIF p_state='pending' THEN
  IF c.id IS NOT NULL THEN RAISE EXCEPTION 'Detén primero el fichaje antes de devolverla a pendientes'; END IF;
  UPDATE public.work_day_plan SET state='pending',started_at=NULL,finished_at=NULL,board_reopened_at=stamp WHERE id=p.id;
 END IF;
 UPDATE public.work_station_tickets SET expires_at=stamp WHERE plan_id=p.id AND result IS NULL;
 SELECT board_version INTO version FROM public.work_day_plan WHERE id=p.id;
 INSERT INTO public.work_board_events(id,plan_id,actor_id,actor_name,from_state,to_state,reason,checkin_id,incident_id,responsible_id,applied_version)
  VALUES(p_request,p.id,actor,coalesce((SELECT full_name FROM ase_private.employee_profiles WHERE id=actor),'Administrador'),p.state,p_state,btrim(p_reason),checkin,incident,CASE WHEN p_state='blocked' THEN p_responsible ELSE NULL END,version);
 PERFORM set_config('ase.tablet_write',old_flag,true);
 RETURN jsonb_build_object('success',true,'state',p_state,'version',version,'checkin_id',checkin,'incident_id',incident);
END $$;
CREATE OR REPLACE FUNCTION public.work_board_history(p_plan uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 SELECT coalesce(jsonb_agg(to_jsonb(e) ORDER BY e.created_at DESC,e.id),'[]') INTO result
 FROM(SELECT id,actor_name,from_state,to_state,reason,created_at FROM public.work_board_events WHERE plan_id=p_plan ORDER BY created_at DESC,id LIMIT 200) e;
 RETURN result;
END $$;
ALTER FUNCTION public.work_board_version() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_move_board(uuid,text,bigint,text,uuid,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_board_history(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_board_version() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.work_move_board(uuid,text,bigint,text,uuid,uuid),public.work_board_history(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_move_board(uuid,text,bigint,text,uuid,uuid),public.work_board_history(uuid) TO authenticated,ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS (
 SELECT t.id task_id,t.title,p.id plan_id,p.priority,p.work_date,
 CASE WHEN o.id IS NOT NULL THEN 'active' WHEN p.state IN ('completed','blocked') THEN p.state
 WHEN c.id IS NOT NULL AND (p.id IS NULL OR c.checkin_time>=greatest(p.created_at,coalesce(p.board_reopened_at,p.created_at))) THEN 'completed'
 WHEN p.state IS NOT NULL THEN p.state ELSE 'unplanned' END state,
 public.work_incident_resolver(t.id) incident
 FROM public.tasks t
 LEFT JOIN LATERAL (SELECT * FROM public.work_day_plan x WHERE x.organization_id=t.organization_id AND x.task_id=t.id
 AND x.user_id=ase_private.session_user_id() AND (x.work_date=public.work_today() OR x.state='active')
 ORDER BY (x.state='active') DESC,x.work_date DESC LIMIT 1) p ON true
 LEFT JOIN LATERAL (SELECT id FROM public.checkins x WHERE x.organization_id=t.organization_id AND x.task_id=t.id AND x.user_id=ase_private.session_user_id()
 AND x.checkout_time IS NULL LIMIT 1) o ON true
 LEFT JOIN LATERAL (SELECT id,checkin_time FROM public.checkins x WHERE x.organization_id=t.organization_id AND x.task_id=t.id AND x.user_id=ase_private.session_user_id()
 AND x.checkout_time IS NOT NULL AND (x.checkin_time AT TIME ZONE 'Europe/Madrid')::date=public.work_today() ORDER BY x.checkin_time DESC LIMIT 1) c ON true
 WHERE t.organization_id=ase_private.current_org() AND (EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=t.organization_id AND a.task_id=t.id AND a.user_id=ase_private.session_user_id()) OR public.work_incident_resolver(t.id))
 ), next_item AS (SELECT task_id FROM items WHERE state='pending' AND work_date=public.work_today() ORDER BY priority,task_id LIMIT 1),
 opened AS (SELECT EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=ase_private.current_org() AND user_id=ase_private.session_user_id() AND checkout_time IS NULL) v)
 SELECT jsonb_build_object('date',public.work_today(),'next_task',(SELECT task_id FROM next_item),
 'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',NOT opened.v AND (i.task_id=(SELECT task_id FROM next_item) OR i.incident),
 'can_finish',i.state='active') ORDER BY (i.state='completed'),(i.state='active') DESC,i.priority NULLS LAST,i.task_id) FROM items i CROSS JOIN opened),'[]'::jsonb))
$$;
CREATE OR REPLACE FUNCTION public.work_planning_board(p_date date,p_user uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE items jsonb; total integer;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_date IS NULL THEN RAISE EXCEPTION 'Selecciona una fecha válida'; END IF;
 SELECT count(*) INTO total FROM public.work_day_plan WHERE work_date=p_date AND (p_user IS NULL OR user_id=p_user);
 IF total>10000 THEN RAISE EXCEPTION 'Hay demasiadas tareas para mostrar. Selecciona un empleado'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object(
  'id',p.id,'task_id',p.task_id,'employee_id',p.user_id,'employee',coalesce(u.full_name,'Empleado no disponible'),
  'title',t.title,'description',t.description,'priority',p.priority,'state',p.state,'work_date',p.work_date,
  'version',p.board_version,'started_at',p.started_at,'finished_at',p.finished_at) || public.work_deadline(p.work_date,p.state,p.finished_at)
  ORDER BY p.priority,u.full_name,p.id),'[]'::jsonb) INTO items
 FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
 WHERE p.work_date=p_date AND (p_user IS NULL OR p.user_id=p_user);
 RETURN jsonb_build_object('date',p_date,'items',items,'total',total,'as_of',now());
END $$;
ALTER FUNCTION public.work_planning_board(date,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board(date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_board(date,uuid) TO authenticated,ase_tenant_executor;

REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261024000100_recurring_work.sql ====
CREATE TABLE IF NOT EXISTS public.work_recurrences(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 task_id uuid NOT NULL,user_id uuid NOT NULL,anchor date NOT NULL,next_due date,
 frequency text NOT NULL CHECK(frequency IN ('daily','weekly','monthly','yearly')),
 every_n integer NOT NULL CHECK(every_n BETWEEN 1 AND 365),basis text NOT NULL CHECK(basis IN ('fixed','completion')),
 notice_days integer NOT NULL CHECK(notice_days BETWEEN 0 AND 365),active boolean NOT NULL DEFAULT true,
 cursor_n integer NOT NULL DEFAULT 0,last_plan uuid,last_error text,created_by uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(organization_id,id),UNIQUE(organization_id,task_id,user_id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id),
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,created_by) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,last_plan) REFERENCES public.work_day_plan(organization_id,id));
CREATE TABLE IF NOT EXISTS public.work_recurrence_runs(
 organization_id uuid NOT NULL,recurrence_id uuid NOT NULL,due date NOT NULL,plan_id uuid NOT NULL,
 notified_at timestamptz,completed_at timestamptz,PRIMARY KEY(organization_id,recurrence_id,due),
 UNIQUE(organization_id,plan_id),
 FOREIGN KEY(organization_id,recurrence_id) REFERENCES public.work_recurrences(organization_id,id),
 FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id));
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['work_recurrences','work_recurrence_runs'] LOOP
 EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
 EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC,anon,authenticated',t);
 EXECUTE format('GRANT SELECT,INSERT,UPDATE ON public.%I TO ase_tenant_executor',t);
 IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename=t AND policyname='recurrence_scope') THEN
 EXECUTE format('CREATE POLICY recurrence_scope ON public.%I TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org())',t);
 END IF;
 END LOOP;
END $$;
-- Reminders share the existing in-app inbox; an incident is optional for these notices.
ALTER TABLE public.work_notifications ALTER COLUMN incident_id DROP NOT NULL;
CREATE OR REPLACE FUNCTION ase_private.recurrence_date(p_anchor date,p_frequency text,p_n integer) RETURNS date
LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT CASE p_frequency WHEN 'daily' THEN p_anchor+p_n WHEN 'weekly' THEN p_anchor+7*p_n
 WHEN 'monthly' THEN (p_anchor+make_interval(months=>p_n))::date
 WHEN 'yearly' THEN (p_anchor+make_interval(years=>p_n))::date END
$$;
REVOKE ALL ON FUNCTION ase_private.recurrence_date(date,text,integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.recurrence_date(date,text,integer) TO ase_tenant_executor;
-- Owner-only scheduler worker. Every business lookup explicitly includes the organization.
CREATE OR REPLACE FUNCTION ase_private.run_recurrences(p_org uuid,p_today date) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE; candidate record; plan uuid; n integer; generated integer:=0; iteration integer; finished timestamptz;
BEGIN
 IF p_org IS NULL OR p_today IS NULL OR NOT pg_try_advisory_xact_lock(hashtextextended('recurrences:'||p_org::text,0)) THEN RETURN 0; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.organizations WHERE id=p_org AND status='active') THEN RETURN 0; END IF;
 FOR candidate IN SELECT id,user_id FROM public.work_recurrences WHERE organization_id=p_org AND active ORDER BY user_id,id LOOP
  -- Same employee-first lock order as normal planning/check-ins.
  PERFORM 1 FROM public.users WHERE id=candidate.user_id FOR UPDATE;
  SELECT * INTO r FROM public.work_recurrences WHERE organization_id=p_org AND id=candidate.id FOR UPDATE;
  IF NOT r.active THEN CONTINUE; END IF;
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM public.organization_memberships WHERE organization_id=p_org AND user_id=r.user_id AND status='active' AND role NOT IN ('admin','owner'))
    OR NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=p_org AND task_id=r.task_id AND user_id=r.user_id) THEN
    RAISE EXCEPTION 'El encargado no está activo o ya no tiene asignada la tarea';
   END IF;
   iteration:=0;
   WHILE r.next_due IS NOT NULL AND r.next_due<=p_today+greatest(30,r.notice_days) LOOP
    iteration:=iteration+1;
    IF iteration>400 THEN RAISE EXCEPTION 'Hay demasiadas ejecuciones atrasadas. Revisa la repetición'; END IF;
    SELECT id INTO plan FROM public.work_day_plan WHERE organization_id=p_org AND user_id=r.user_id AND task_id=r.task_id AND work_date=r.next_due;
    IF plan IS NULL THEN
     SELECT coalesce(max(priority),0)+1 INTO n FROM public.work_day_plan WHERE organization_id=p_org AND user_id=r.user_id AND work_date=r.next_due;
     INSERT INTO public.work_day_plan(organization_id,user_id,task_id,work_date,priority) VALUES(p_org,r.user_id,r.task_id,r.next_due,n) RETURNING id INTO plan;
     generated:=generated+1;
    END IF;
    INSERT INTO public.work_recurrence_runs(organization_id,recurrence_id,due,plan_id) VALUES(p_org,r.id,r.next_due,plan) ON CONFLICT DO NOTHING;
    r.last_plan:=plan;
    IF r.basis='completion' THEN
     SELECT finished_at INTO finished FROM public.work_day_plan WHERE organization_id=p_org AND id=plan AND state='completed';
     IF finished IS NULL THEN r.next_due:=NULL;
     ELSE
      r.next_due:=ase_private.recurrence_date((finished AT TIME ZONE 'Europe/Madrid')::date,r.frequency,r.every_n);
      UPDATE public.work_recurrence_runs SET completed_at=finished WHERE organization_id=p_org AND plan_id=plan;
     END IF;
     EXIT;
    ELSE
     r.cursor_n:=r.cursor_n+1;
     r.next_due:=ase_private.recurrence_date(r.anchor,r.frequency,r.cursor_n*r.every_n);
    END IF;
   END LOOP;
   UPDATE public.work_recurrences SET next_due=r.next_due,cursor_n=r.cursor_n,last_plan=r.last_plan,last_error=NULL WHERE organization_id=p_org AND id=r.id;
  EXCEPTION WHEN OTHERS THEN
   UPDATE public.work_recurrences SET last_error=left(SQLERRM,500) WHERE organization_id=p_org AND id=r.id;
  END;
 END LOOP;
 -- Exactly one advance reminder per occurrence, including tasks generated on earlier runs.
 FOR candidate IN SELECT x.*,rule.user_id,t.title FROM public.work_recurrence_runs x JOIN public.work_recurrences rule ON rule.organization_id=x.organization_id AND rule.id=x.recurrence_id
 JOIN public.tasks t ON t.organization_id=rule.organization_id AND t.id=rule.task_id
 JOIN public.work_day_plan p ON p.organization_id=x.organization_id AND p.id=x.plan_id
 WHERE x.organization_id=p_org AND rule.active AND x.notified_at IS NULL AND x.due-rule.notice_days<=p_today AND p.state IN ('pending','active')
 LOOP
  INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message) VALUES(p_org,candidate.user_id,NULL,'Tarea programada: '||candidate.title||' · '||to_char(candidate.due,'DD/MM/YYYY'));
  UPDATE public.work_recurrence_runs SET notified_at=clock_timestamp() WHERE organization_id=p_org AND recurrence_id=candidate.recurrence_id AND due=candidate.due;
 END LOOP;
 RETURN generated;
END $$;
REVOKE ALL ON FUNCTION ase_private.run_recurrences(uuid,date) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.run_recurrences(uuid,date) TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION ase_private.recurrence_completed() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.state='completed' AND OLD.state IS DISTINCT FROM 'completed' AND NEW.finished_at IS NOT NULL THEN
  UPDATE public.work_recurrence_runs SET completed_at=NEW.finished_at WHERE organization_id=NEW.organization_id AND plan_id=NEW.id AND completed_at IS NULL;
  IF FOUND THEN
   UPDATE public.work_recurrences r SET next_due=ase_private.recurrence_date((NEW.finished_at AT TIME ZONE 'Europe/Madrid')::date,r.frequency,r.every_n)
    WHERE r.organization_id=NEW.organization_id AND r.last_plan=NEW.id AND r.basis='completion' AND r.next_due IS NULL;
  END IF;
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION ase_private.recurrence_completed() FROM PUBLIC,anon,authenticated,ase_tenant_executor;
DROP TRIGGER IF EXISTS recurrence_completed ON public.work_day_plan;
CREATE TRIGGER recurrence_completed AFTER UPDATE OF state ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION ase_private.recurrence_completed();
CREATE OR REPLACE FUNCTION ase_private.recurrence_scheduler_ready() RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE ready boolean; BEGIN
 IF to_regclass('cron.job') IS NULL THEN RETURN false; END IF;
 EXECUTE 'SELECT EXISTS(SELECT 1 FROM cron.job WHERE jobname=''ase-work-recurrences'' AND active AND command=''SELECT ase_private.schedule_recurrences()'' AND schedule=''17 * * * *'')' INTO ready;
 RETURN ready;
END $$;
REVOKE ALL ON FUNCTION ase_private.recurrence_scheduler_ready() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.recurrence_scheduler_ready() TO ase_tenant_executor;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_recurrence_list() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 RETURN jsonb_build_object('automation_ready',ase_private.recurrence_scheduler_ready(),'items',coalesce((SELECT jsonb_agg(to_jsonb(r)||jsonb_build_object('title',t.title,'employee',u.full_name,'runs',
  (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.due DESC),'[]'::jsonb) FROM (SELECT x.due,p.state,p.finished_at,x.notified_at FROM public.work_recurrence_runs x JOIN public.work_day_plan p ON p.id=x.plan_id WHERE x.recurrence_id=r.id ORDER BY x.due DESC LIMIT 24) x)) ORDER BY r.created_at DESC)
 FROM public.work_recurrences r JOIN public.tasks t ON t.id=r.task_id JOIN ase_private.employee_profiles u ON u.id=r.user_id),'[]'::jsonb));
END $$;
ALTER FUNCTION public.work_recurrence_list() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_recurrence_list() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_recurrence_list() TO authenticated;
CREATE OR REPLACE FUNCTION public.work_create_recurrence(p_id uuid,p_task uuid,p_user uuid,p_start date,p_frequency text,p_every integer,p_basis text,p_notice integer) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND NOT is_admin AND membership_status='active' FOR UPDATE;
 IF NOT FOUND OR p_id IS NULL OR p_start IS NULL OR p_start<public.work_today() OR p_start>public.work_today()+3650 OR p_frequency IS NULL OR p_frequency NOT IN ('daily','weekly','monthly','yearly') OR p_every IS NULL OR p_every NOT BETWEEN 1 AND 365 OR p_basis IS NULL OR p_basis NOT IN ('fixed','completion') OR p_notice IS NULL OR p_notice NOT BETWEEN 0 AND 365 THEN RAISE EXCEPTION 'Revisa el encargado, la fecha y la repetición'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=p_task AND user_id=p_user) THEN RAISE EXCEPTION 'Asigna primero la tarea al encargado'; END IF;
 SELECT * INTO r FROM public.work_recurrences WHERE id=p_id;
 IF r.id IS NOT NULL THEN
  IF r.task_id=p_task AND r.user_id=p_user AND r.anchor=p_start AND r.frequency=p_frequency AND r.every_n=p_every AND r.basis=p_basis AND r.notice_days=p_notice THEN RETURN r.id; END IF;
  RAISE EXCEPTION 'La solicitud ya se utilizó con otros datos';
 END IF;
 INSERT INTO public.work_recurrences(id,task_id,user_id,anchor,next_due,frequency,every_n,basis,notice_days,created_by)
 VALUES(p_id,p_task,p_user,p_start,p_start,p_frequency,p_every,p_basis,p_notice,ase_private.session_user_id());
 PERFORM ase_private.run_recurrences(ase_private.current_org(),public.work_today());
 RETURN p_id;
END $$;
ALTER FUNCTION public.work_create_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_create_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_create_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_pause_recurrence(p_id uuid,p_active boolean) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 IF p_active IS NULL THEN RAISE EXCEPTION 'Estado no válido'; END IF;
 UPDATE public.work_recurrences SET active=p_active WHERE id=p_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Repetición no disponible'; END IF;
END $$;
ALTER FUNCTION public.work_pause_recurrence(uuid,boolean) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_pause_recurrence(uuid,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_pause_recurrence(uuid,boolean) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_run_recurrences() RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 RETURN ase_private.run_recurrences(ase_private.current_org(),public.work_today());
END $$;
ALTER FUNCTION public.work_run_recurrences() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_run_recurrences() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_run_recurrences() TO authenticated;
-- Database scheduler only: no API key or user session is persisted.
CREATE OR REPLACE FUNCTION ase_private.schedule_recurrences() RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid; BEGIN
 FOR org IN SELECT id FROM public.organizations WHERE status='active' LOOP
  PERFORM ase_private.run_recurrences(org,(clock_timestamp() AT TIME ZONE 'Europe/Madrid')::date);
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION ase_private.schedule_recurrences() FROM PUBLIC,anon,authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261024000200_area_recurrences.sql ====
ALTER TABLE public.work_recurrences ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.work_recurrences ADD COLUMN IF NOT EXISTS area_id uuid;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='recurrence_area_fk') THEN
 ALTER TABLE public.work_recurrences ADD CONSTRAINT recurrence_area_fk FOREIGN KEY(organization_id,area_id) REFERENCES public.work_areas(organization_id,id);
 ALTER TABLE public.work_recurrences ADD CONSTRAINT recurrence_one_target CHECK((user_id IS NOT NULL)::integer+(area_id IS NOT NULL)::integer=1);
END IF; END $$;
CREATE UNIQUE INDEX IF NOT EXISTS recurrence_per_area ON public.work_recurrences(organization_id,task_id,area_id) WHERE area_id IS NOT NULL;
CREATE TABLE IF NOT EXISTS public.work_area_recurrence_due(
 organization_id uuid NOT NULL,recurrence_id uuid NOT NULL,due date NOT NULL,plan_id uuid,assigned_by uuid,assigned_at timestamptz,notified_at timestamptz,
 PRIMARY KEY(organization_id,recurrence_id,due),
 FOREIGN KEY(organization_id,recurrence_id) REFERENCES public.work_recurrences(organization_id,id),
 FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id),
 FOREIGN KEY(organization_id,assigned_by) REFERENCES public.organization_memberships(organization_id,user_id));
ALTER TABLE public.work_area_recurrence_due ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_area_recurrence_due FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE ON public.work_area_recurrence_due TO ase_tenant_executor;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_area_recurrence_due' AND policyname='area_due_scope') THEN
 CREATE POLICY area_due_scope ON public.work_area_recurrence_due TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
END IF; END $$;
CREATE OR REPLACE FUNCTION ase_private.run_area_recurrences(p_org uuid,p_today date) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE rule public.work_recurrences%ROWTYPE; x record; recipient uuid; iteration integer; BEGIN
 FOR rule IN SELECT * FROM public.work_recurrences WHERE organization_id=p_org AND active AND area_id IS NOT NULL ORDER BY id FOR UPDATE LOOP
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM public.work_areas WHERE organization_id=p_org AND id=rule.area_id AND active) THEN RAISE EXCEPTION 'Área inactiva. Revisa sus responsables'; END IF;
   iteration:=0;
   WHILE rule.next_due IS NOT NULL AND rule.next_due<=p_today+greatest(30,rule.notice_days) LOOP
    iteration:=iteration+1;IF iteration>400 THEN RAISE EXCEPTION 'Demasiadas fechas pendientes. Revisa la repetición'; END IF;
    INSERT INTO public.work_area_recurrence_due(organization_id,recurrence_id,due) VALUES(p_org,rule.id,rule.next_due) ON CONFLICT DO NOTHING;
    IF rule.basis='completion' THEN rule.next_due:=NULL;EXIT; END IF;
    rule.cursor_n:=rule.cursor_n+1;rule.next_due:=ase_private.recurrence_date(rule.anchor,rule.frequency,rule.cursor_n*rule.every_n);
   END LOOP;
   UPDATE public.work_recurrences SET next_due=rule.next_due,cursor_n=rule.cursor_n,last_error=NULL WHERE organization_id=p_org AND id=rule.id;
  EXCEPTION WHEN OTHERS THEN UPDATE public.work_recurrences SET last_error=left(SQLERRM,500) WHERE organization_id=p_org AND id=rule.id; END;
 END LOOP;
 FOR x IN SELECT d.*,a.name,t.title FROM public.work_area_recurrence_due d JOIN public.work_recurrences r ON r.organization_id=d.organization_id AND r.id=d.recurrence_id
 JOIN public.work_areas a ON a.organization_id=r.organization_id AND a.id=r.area_id JOIN public.tasks t ON t.organization_id=r.organization_id AND t.id=r.task_id
 WHERE d.organization_id=p_org AND r.active AND d.plan_id IS NULL AND d.notified_at IS NULL AND d.due-r.notice_days<=p_today LOOP
  FOR recipient IN SELECT m.user_id FROM public.organization_memberships m WHERE m.organization_id=p_org AND m.status='active' AND (m.role IN ('admin','owner') OR EXISTS(SELECT 1 FROM public.work_area_members am JOIN public.work_recurrences r ON r.organization_id=am.organization_id AND r.area_id=am.area_id WHERE am.organization_id=p_org AND am.user_id=m.user_id AND r.id=x.recurrence_id)) LOOP
   INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message) VALUES(p_org,recipient,NULL,'Pendiente de asignación: '||x.title||' · Área '||x.name||' · '||to_char(x.due,'DD/MM/YYYY'));
  END LOOP;
  UPDATE public.work_area_recurrence_due SET notified_at=clock_timestamp() WHERE organization_id=p_org AND recurrence_id=x.recurrence_id AND due=x.due;
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION ase_private.run_area_recurrences(uuid,date) FROM PUBLIC,anon,authenticated,ase_tenant_executor;
CREATE OR REPLACE FUNCTION ase_private.run_recurrences(p_org uuid,p_today date) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE; candidate record; plan uuid; n integer; generated integer:=0; iteration integer; finished timestamptz;
BEGIN
 IF p_org IS NULL OR p_today IS NULL OR NOT pg_try_advisory_xact_lock(hashtextextended('recurrences:'||p_org::text,0)) THEN RETURN 0; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.organizations WHERE id=p_org AND status='active') THEN RETURN 0; END IF;
 FOR candidate IN SELECT id,user_id FROM public.work_recurrences WHERE organization_id=p_org AND active AND user_id IS NOT NULL ORDER BY user_id,id LOOP
  -- Same employee-first lock order as normal planning/check-ins.
  PERFORM 1 FROM public.users WHERE id=candidate.user_id FOR UPDATE;
  SELECT * INTO r FROM public.work_recurrences WHERE organization_id=p_org AND id=candidate.id FOR UPDATE;
  IF NOT r.active THEN CONTINUE; END IF;
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM public.organization_memberships WHERE organization_id=p_org AND user_id=r.user_id AND status='active' AND role NOT IN ('admin','owner'))
    OR NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=p_org AND task_id=r.task_id AND user_id=r.user_id) THEN
    RAISE EXCEPTION 'El encargado no está activo o ya no tiene asignada la tarea';
   END IF;
   iteration:=0;
   WHILE r.next_due IS NOT NULL AND r.next_due<=p_today+greatest(30,r.notice_days) LOOP
    iteration:=iteration+1;
    IF iteration>400 THEN RAISE EXCEPTION 'Hay demasiadas ejecuciones atrasadas. Revisa la repetición'; END IF;
    SELECT id INTO plan FROM public.work_day_plan WHERE organization_id=p_org AND user_id=r.user_id AND task_id=r.task_id AND work_date=r.next_due;
    IF plan IS NULL THEN
     SELECT coalesce(max(priority),0)+1 INTO n FROM public.work_day_plan WHERE organization_id=p_org AND user_id=r.user_id AND work_date=r.next_due;
     INSERT INTO public.work_day_plan(organization_id,user_id,task_id,work_date,priority) VALUES(p_org,r.user_id,r.task_id,r.next_due,n) RETURNING id INTO plan;
     generated:=generated+1;
    END IF;
    INSERT INTO public.work_recurrence_runs(organization_id,recurrence_id,due,plan_id) VALUES(p_org,r.id,r.next_due,plan) ON CONFLICT DO NOTHING;
    r.last_plan:=plan;
    IF r.basis='completion' THEN
     SELECT finished_at INTO finished FROM public.work_day_plan WHERE organization_id=p_org AND id=plan AND state='completed';
     IF finished IS NULL THEN r.next_due:=NULL;
     ELSE
      r.next_due:=ase_private.recurrence_date((finished AT TIME ZONE 'Europe/Madrid')::date,r.frequency,r.every_n);
      UPDATE public.work_recurrence_runs SET completed_at=finished WHERE organization_id=p_org AND plan_id=plan;
     END IF;
     EXIT;
    ELSE
     r.cursor_n:=r.cursor_n+1;
     r.next_due:=ase_private.recurrence_date(r.anchor,r.frequency,r.cursor_n*r.every_n);
    END IF;
   END LOOP;
   UPDATE public.work_recurrences SET next_due=r.next_due,cursor_n=r.cursor_n,last_plan=r.last_plan,last_error=NULL WHERE organization_id=p_org AND id=r.id;
  EXCEPTION WHEN OTHERS THEN
   IF r.last_error IS DISTINCT FROM left(SQLERRM,500) THEN
    INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message)
     SELECT p_org,m.user_id,NULL,'Repetición pendiente de revisión: '||t.title||'. Revisa el encargado y su asignación.'
     FROM public.organization_memberships m JOIN public.tasks t ON t.organization_id=m.organization_id AND t.id=r.task_id
     WHERE m.organization_id=p_org AND m.status='active' AND m.role IN ('admin','owner');
   END IF;
   UPDATE public.work_recurrences SET last_error=left(SQLERRM,500) WHERE organization_id=p_org AND id=r.id;
  END;
 END LOOP;
 -- Exactly one advance reminder per occurrence, including tasks generated on earlier runs.
 FOR candidate IN SELECT x.*,p.user_id,t.title FROM public.work_recurrence_runs x JOIN public.work_recurrences rule ON rule.organization_id=x.organization_id AND rule.id=x.recurrence_id
 JOIN public.tasks t ON t.organization_id=rule.organization_id AND t.id=rule.task_id
 JOIN public.work_day_plan p ON p.organization_id=x.organization_id AND p.id=x.plan_id
 WHERE x.organization_id=p_org AND rule.active AND x.notified_at IS NULL AND x.due-rule.notice_days<=p_today AND p.state IN ('pending','active') AND EXISTS(SELECT 1 FROM public.organization_memberships m WHERE m.organization_id=p_org AND m.user_id=p.user_id AND m.status='active')
 LOOP
  INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message) VALUES(p_org,candidate.user_id,NULL,'Tarea programada: '||candidate.title||' · '||to_char(candidate.due,'DD/MM/YYYY'));
  UPDATE public.work_recurrence_runs SET notified_at=clock_timestamp() WHERE organization_id=p_org AND recurrence_id=candidate.recurrence_id AND due=candidate.due;
 END LOOP;
 PERFORM ase_private.run_area_recurrences(p_org,p_today);
 RETURN generated;
END $$;
REVOKE ALL ON FUNCTION ase_private.run_recurrences(uuid,date) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.run_recurrences(uuid,date) TO ase_tenant_executor;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_create_area_recurrence(p_id uuid,p_task uuid,p_area uuid,p_start date,p_frequency text,p_every integer,p_basis text,p_notice integer) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 PERFORM 1 FROM public.work_areas WHERE id=p_area AND active FOR UPDATE;
 IF NOT FOUND OR p_id IS NULL OR p_start IS NULL OR p_start<public.work_today() OR p_start>public.work_today()+3650 OR p_frequency IS NULL OR p_frequency NOT IN ('daily','weekly','monthly','yearly') OR p_every IS NULL OR p_every NOT BETWEEN 1 AND 365 OR p_basis IS NULL OR p_basis NOT IN ('fixed','completion') OR p_notice IS NULL OR p_notice NOT BETWEEN 0 AND 365 THEN RAISE EXCEPTION 'Revisa el encargado, la fecha y la repetición'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE id=p_task) THEN RAISE EXCEPTION 'Tarea no disponible'; END IF;
 SELECT * INTO r FROM public.work_recurrences WHERE id=p_id;
 IF r.id IS NOT NULL THEN
  IF r.task_id=p_task AND r.area_id=p_area AND r.anchor=p_start AND r.frequency=p_frequency AND r.every_n=p_every AND r.basis=p_basis AND r.notice_days=p_notice THEN RETURN r.id; END IF;
  RAISE EXCEPTION 'La solicitud ya se utilizó con otros datos';
 END IF;
 INSERT INTO public.work_recurrences(id,task_id,area_id,anchor,next_due,frequency,every_n,basis,notice_days,created_by)
 VALUES(p_id,p_task,p_area,p_start,p_start,p_frequency,p_every,p_basis,p_notice,ase_private.session_user_id());
 PERFORM ase_private.run_recurrences(ase_private.current_org(),public.work_today());
 RETURN p_id;
END $$;
ALTER FUNCTION public.work_create_area_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_create_area_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_create_area_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_assign_area_recurrence(p_id uuid,p_due date,p_user uuid) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE; d public.work_area_recurrence_due%ROWTYPE; plan uuid; n integer; finished timestamptz; BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND NOT is_admin AND membership_status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 SELECT * INTO r FROM public.work_recurrences WHERE id=p_id AND area_id IS NOT NULL FOR UPDATE;
 IF r.id IS NULL OR NOT r.active THEN RAISE EXCEPTION 'Repetición no disponible o pausada'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.work_area_members WHERE area_id=r.area_id AND user_id=p_user) THEN RAISE EXCEPTION 'El empleado debe pertenecer al área'; END IF;
 SELECT * INTO d FROM public.work_area_recurrence_due WHERE recurrence_id=r.id AND due=p_due FOR UPDATE;
 IF d.recurrence_id IS NULL THEN RAISE EXCEPTION 'Fecha pendiente no disponible'; END IF;
 IF d.plan_id IS NOT NULL THEN
  IF EXISTS(SELECT 1 FROM public.work_day_plan WHERE id=d.plan_id AND user_id=p_user) THEN RETURN d.plan_id; END IF;
  RAISE EXCEPTION 'Esta ejecución ya se asignó. Revisa la planificación';
 END IF;
 INSERT INTO public.task_assignments(task_id,user_id) VALUES(r.task_id,p_user) ON CONFLICT DO NOTHING;
 SELECT id,finished_at INTO plan,finished FROM public.work_day_plan WHERE task_id=r.task_id AND user_id=p_user AND work_date=p_due;
 IF plan IS NULL THEN
  SELECT coalesce(max(priority),0)+1 INTO n FROM public.work_day_plan WHERE user_id=p_user AND work_date=p_due;
  INSERT INTO public.work_day_plan(task_id,user_id,work_date,priority) VALUES(r.task_id,p_user,p_due,n) RETURNING id INTO plan;
 END IF;
 IF EXISTS(SELECT 1 FROM public.work_recurrence_runs WHERE plan_id=plan AND recurrence_id<>r.id) THEN RAISE EXCEPTION 'Ese empleado ya tiene la misma tarea recurrente en esa fecha'; END IF;
 INSERT INTO public.work_recurrence_runs(organization_id,recurrence_id,due,plan_id,completed_at) VALUES(ase_private.current_org(),r.id,p_due,plan,finished) ON CONFLICT DO NOTHING;
 UPDATE public.work_area_recurrence_due SET plan_id=plan,assigned_by=ase_private.session_user_id(),assigned_at=clock_timestamp() WHERE recurrence_id=r.id AND due=p_due;
 UPDATE public.work_recurrences SET last_plan=plan,next_due=CASE WHEN basis='completion' AND finished IS NOT NULL THEN ase_private.recurrence_date((finished AT TIME ZONE 'Europe/Madrid')::date,frequency,every_n) ELSE next_due END WHERE id=r.id;
 INSERT INTO public.work_notifications(user_id,incident_id,message) SELECT p_user,NULL,'Nueva tarea del área: '||title||' · '||to_char(p_due,'DD/MM/YYYY') FROM public.tasks WHERE id=r.task_id;
 RETURN plan;
END $$;
ALTER FUNCTION public.work_assign_area_recurrence(uuid,date,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_assign_area_recurrence(uuid,date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_assign_area_recurrence(uuid,date,uuid) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_recurrence_list() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 RETURN jsonb_build_object('automation_ready',ase_private.recurrence_scheduler_ready(),'areas',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'name',a.name,'members',(SELECT coalesce(jsonb_agg(user_id),'[]'::jsonb) FROM public.work_area_members WHERE area_id=a.id))) FROM public.work_areas a WHERE active),'[]'::jsonb),
 'tasks',coalesce((SELECT jsonb_agg(jsonb_build_object('id',id,'title',title) ORDER BY title) FROM public.tasks),'[]'::jsonb),
 'items',coalesce((SELECT jsonb_agg(to_jsonb(r)||jsonb_build_object('title',t.title,'employee',u.full_name,'area_name',a.name,'runs',
 (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.due DESC),'[]'::jsonb) FROM (
 SELECT x.due,p.id plan_id,p.user_id,p.state,p.finished_at,x.notified_at,u.full_name employee FROM public.work_recurrence_runs x JOIN public.work_day_plan p ON p.id=x.plan_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE x.recurrence_id=r.id
 UNION ALL SELECT d.due,NULL::uuid,NULL::uuid,'unassigned'::text,NULL::timestamptz,d.notified_at,NULL::text FROM public.work_area_recurrence_due d WHERE d.recurrence_id=r.id AND d.plan_id IS NULL ORDER BY due DESC) x)) ORDER BY r.created_at DESC)
 FROM public.work_recurrences r JOIN public.tasks t ON t.id=r.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=r.user_id LEFT JOIN public.work_areas a ON a.id=r.area_id),'[]'::jsonb));
END $$;
ALTER FUNCTION public.work_recurrence_list() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_recurrence_list() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_recurrence_list() TO authenticated;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261024000300_task_importance.sql ====
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS importance text NOT NULL DEFAULT 'normal';
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='task_importance_valid' AND conrelid='public.tasks'::regclass) THEN
 ALTER TABLE public.tasks ADD CONSTRAINT task_importance_valid CHECK(importance IN ('low','normal','high','urgent'));
END IF; END $$;
CREATE TABLE IF NOT EXISTS public.work_importance_events(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL REFERENCES public.organizations(id),task_id uuid NOT NULL,
 actor_id uuid,actor_name text NOT NULL,previous text,current_value text NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id),
 CHECK(previous IS NULL OR previous IN ('low','normal','high','urgent')),
 CHECK(current_value IN ('low','normal','high','urgent')));
CREATE INDEX IF NOT EXISTS work_importance_events_task ON public.work_importance_events(organization_id,task_id,created_at DESC,id);
ALTER TABLE public.work_importance_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_importance_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_importance_events TO ase_tenant_executor;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_importance_events' AND policyname='importance_scope') THEN
 CREATE POLICY importance_scope ON public.work_importance_events FOR SELECT TO ase_tenant_executor USING(organization_id=ase_private.current_org());
END IF; END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_importance_events' AND policyname='importance_insert') THEN
 CREATE POLICY importance_insert ON public.work_importance_events FOR INSERT TO ase_tenant_executor WITH CHECK(organization_id=ase_private.current_org());
END IF; END $$;
CREATE OR REPLACE FUNCTION ase_private.log_task_importance() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=ase_private.session_user_id(); actor_name text; BEGIN
 IF coalesce(current_setting('ase.suppress_importance_audit',true),'off')='on' THEN RETURN NEW; END IF;
 IF TG_OP='UPDATE' AND OLD.importance=NEW.importance THEN RETURN NEW; END IF;
 SELECT full_name INTO actor_name FROM public.organization_memberships WHERE organization_id=NEW.organization_id AND user_id=actor;
 INSERT INTO public.work_importance_events(organization_id,task_id,actor_id,actor_name,previous,current_value)
 VALUES(NEW.organization_id,NEW.id,actor,coalesce(actor_name,'Sistema'),CASE WHEN TG_OP='UPDATE' THEN OLD.importance ELSE NULL END,NEW.importance);
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION ase_private.log_task_importance() FROM PUBLIC,anon,authenticated,ase_tenant_executor;
DROP TRIGGER IF EXISTS task_importance_audit ON public.tasks;
CREATE TRIGGER task_importance_audit AFTER INSERT OR UPDATE OF importance ON public.tasks FOR EACH ROW EXECUTE FUNCTION ase_private.log_task_importance();
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_manage_task_importance(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_users uuid[] DEFAULT '{}'::uuid[]) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid; previous_value text; actor uuid:=ase_private.session_user_id(); actor_name text; org uuid:=ase_private.current_org(); old_flag text:=coalesce(current_setting('ase.suppress_importance_audit',true),'off'); BEGIN
 IF p_importance IS NULL OR p_importance NOT IN ('low','normal','high','urgent') THEN RAISE EXCEPTION 'Importancia no válida'; END IF;
 IF p_action IS NULL OR p_action NOT IN ('create','edit') THEN RAISE EXCEPTION 'Acción no válida'; END IF;
 PERFORM set_config('ase.suppress_importance_audit','on',true);
 result:=public.work_manage_task(p_action,p_id,p_title,p_description,p_schedule,p_date,p_status,p_users);
 SELECT importance INTO previous_value FROM public.tasks WHERE organization_id=org AND id=result FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 UPDATE public.tasks SET importance=p_importance WHERE organization_id=org AND id=result;
 PERFORM set_config('ase.suppress_importance_audit',old_flag,true);
 IF p_action='create' OR previous_value IS DISTINCT FROM p_importance THEN
  SELECT full_name INTO actor_name FROM public.organization_memberships WHERE organization_id=org AND user_id=actor;
  INSERT INTO public.work_importance_events(organization_id,task_id,actor_id,actor_name,previous,current_value)
  VALUES(org,result,actor,coalesce(actor_name,'Sistema'),CASE WHEN p_action='edit' THEN previous_value ELSE NULL END,p_importance);
 END IF;
 RETURN result;
END $$;
ALTER FUNCTION public.work_manage_task_importance(text,text,uuid,text,text,text,date,text,uuid[]) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_importance(text,text,uuid,text,text,text,date,text,uuid[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_importance(text,text,uuid,text,text,text,date,text,uuid[]) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_importance_history(p_task uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=ase_private.current_org() AND id=p_task) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF NOT (public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION 'No puedes consultar esta tarea'; END IF;
 RETURN coalesce((SELECT jsonb_agg(to_jsonb(e) ORDER BY created_at DESC,id) FROM(SELECT id,actor_name,previous,current_value,created_at FROM public.work_importance_events WHERE organization_id=ase_private.current_org() AND task_id=p_task ORDER BY created_at DESC,id LIMIT 100) e),'[]'::jsonb);
END $$;
ALTER FUNCTION public.work_importance_history(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_importance_history(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_importance_history(uuid) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS (
 SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,
 CASE WHEN o.id IS NOT NULL THEN 'active' WHEN p.state IN ('completed','blocked') THEN p.state
 WHEN c.id IS NOT NULL AND (p.id IS NULL OR c.checkin_time>=greatest(p.created_at,coalesce(p.board_reopened_at,p.created_at))) THEN 'completed'
 WHEN p.state IS NOT NULL THEN p.state ELSE 'unplanned' END state,
 public.work_incident_resolver(t.id) incident
 FROM public.tasks t
 LEFT JOIN LATERAL (SELECT * FROM public.work_day_plan x WHERE x.organization_id=t.organization_id AND x.task_id=t.id
 AND x.user_id=ase_private.session_user_id() AND (x.work_date=public.work_today() OR x.state='active')
 ORDER BY (x.state='active') DESC,x.work_date DESC LIMIT 1) p ON true
 LEFT JOIN LATERAL (SELECT id FROM public.checkins x WHERE x.organization_id=t.organization_id AND x.task_id=t.id AND x.user_id=ase_private.session_user_id()
 AND x.checkout_time IS NULL LIMIT 1) o ON true
 LEFT JOIN LATERAL (SELECT id,checkin_time FROM public.checkins x WHERE x.organization_id=t.organization_id AND x.task_id=t.id AND x.user_id=ase_private.session_user_id()
 AND x.checkout_time IS NOT NULL AND (x.checkin_time AT TIME ZONE 'Europe/Madrid')::date=public.work_today() ORDER BY x.checkin_time DESC LIMIT 1) c ON true
 WHERE t.organization_id=ase_private.current_org() AND (EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=t.organization_id AND a.task_id=t.id AND a.user_id=ase_private.session_user_id()) OR public.work_incident_resolver(t.id))
 ), next_item AS (SELECT task_id FROM items WHERE state='pending' AND work_date=public.work_today() ORDER BY priority,task_id LIMIT 1),
 opened AS (SELECT EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=ase_private.current_org() AND user_id=ase_private.session_user_id() AND checkout_time IS NULL) v)
 SELECT jsonb_build_object('date',public.work_today(),'next_task',(SELECT task_id FROM next_item),
 'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',NOT opened.v AND (i.task_id=(SELECT task_id FROM next_item) OR i.incident),
 'can_finish',i.state='active') ORDER BY (i.state='completed'),(i.state='active') DESC,i.priority NULLS LAST,i.task_id) FROM items i CROSS JOIN opened),'[]'::jsonb))
$$;
CREATE OR REPLACE FUNCTION public.work_planning_board(p_date date,p_user uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE items jsonb; total integer;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_date IS NULL THEN RAISE EXCEPTION 'Selecciona una fecha válida'; END IF;
 SELECT count(*) INTO total FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND work_date=p_date AND (p_user IS NULL OR user_id=p_user);
 IF total>10000 THEN RAISE EXCEPTION 'Hay demasiadas tareas para mostrar. Selecciona un empleado'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object(
  'id',p.id,'task_id',p.task_id,'employee_id',p.user_id,'employee',coalesce(u.full_name,'Empleado no disponible'),
  'title',t.title,'description',t.description,'importance',t.importance,'priority',p.priority,'state',p.state,'work_date',p.work_date,
  'version',p.board_version,'started_at',p.started_at,'finished_at',p.finished_at) || public.work_deadline(p.work_date,p.state,p.finished_at)
  ORDER BY p.priority,u.full_name,p.id),'[]'::jsonb) INTO items
 FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
 WHERE p.organization_id=ase_private.current_org() AND p.work_date=p_date AND (p_user IS NULL OR p.user_id=p_user);
 RETURN jsonb_build_object('date',p_date,'items',items,'total',total,'as_of',now());
END $$;
ALTER FUNCTION public.work_planning_board(date,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board(date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_board(date,uuid) TO authenticated,ase_tenant_executor;

REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261024000400_execution_schedules.sql ====
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS schedule_kind text NOT NULL DEFAULT 'scheduled';
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS available_from timestamptz;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS scheduled_for timestamptz;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS due_at timestamptz;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS planned_end timestamptz;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS strict_schedule boolean NOT NULL DEFAULT true;

UPDATE public.work_day_plan
SET schedule_kind='scheduled',
    scheduled_for=work_date::timestamp AT TIME ZONE 'Europe/Madrid',
    due_at=(work_date+1)::timestamp AT TIME ZONE 'Europe/Madrid',
    strict_schedule=true
WHERE schedule_kind='scheduled' AND scheduled_for IS NULL;

DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='work_execution_schedule_kind' AND conrelid='public.work_day_plan'::regclass) THEN
  ALTER TABLE public.work_day_plan ADD CONSTRAINT work_execution_schedule_kind CHECK(schedule_kind IN ('anytime','deadline','window','scheduled','period'));
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='work_execution_schedule_shape' AND conrelid='public.work_day_plan'::regclass) THEN
  ALTER TABLE public.work_day_plan ADD CONSTRAINT work_execution_schedule_shape CHECK(
   (schedule_kind='anytime' AND available_from IS NULL AND scheduled_for IS NULL AND due_at IS NULL AND planned_end IS NULL AND strict_schedule IS FALSE)
   OR (schedule_kind='deadline' AND available_from IS NULL AND scheduled_for IS NULL AND due_at IS NOT NULL AND planned_end IS NULL AND strict_schedule IS FALSE)
   OR (schedule_kind='window' AND available_from IS NOT NULL AND scheduled_for IS NULL AND due_at IS NOT NULL AND planned_end IS NULL AND strict_schedule IS FALSE AND available_from<due_at)
   OR (schedule_kind='scheduled' AND available_from IS NULL AND scheduled_for IS NOT NULL AND planned_end IS NULL AND (due_at IS NULL OR scheduled_for<due_at))
   OR (schedule_kind='period' AND available_from IS NOT NULL AND scheduled_for IS NULL AND planned_end IS NOT NULL AND strict_schedule IS FALSE AND available_from<planned_end AND (due_at IS NULL OR available_from<due_at))
  );
 END IF;
END $$;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_execution_timing(p_plan uuid,p_moment timestamptz DEFAULT clock_timestamp()) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE; start_limit timestamptz; end_limit timestamptz; allowed boolean; overdue boolean;
BEGIN
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan;
 IF NOT FOUND THEN RAISE EXCEPTION 'Ejecución no disponible'; END IF;
 start_limit:=CASE p.schedule_kind WHEN 'window' THEN p.available_from WHEN 'period' THEN p.available_from WHEN 'scheduled' THEN CASE WHEN p.strict_schedule THEN p.scheduled_for END END;
 end_limit:=CASE p.schedule_kind WHEN 'deadline' THEN p.due_at WHEN 'window' THEN p.due_at WHEN 'scheduled' THEN p.due_at WHEN 'period' THEN coalesce(p.due_at,p.planned_end) END;
 overdue:=p.state IN ('pending','active') AND end_limit IS NOT NULL AND p_moment>=end_limit;
 allowed:=p.state='pending' AND (start_limit IS NULL OR p_moment>=start_limit) AND (end_limit IS NULL OR p_moment<end_limit);
 RETURN jsonb_build_object('kind',p.schedule_kind,'available_from',p.available_from,'scheduled_for',p.scheduled_for,'due_at',p.due_at,'planned_end',p.planned_end,'strict',p.strict_schedule,'can_start_time',allowed,'overdue',overdue,'starts_later',p.state='pending' AND start_limit IS NOT NULL AND p_moment<start_limit,'start_limit',start_limit,'end_limit',end_limit);
END $$;

DROP FUNCTION IF EXISTS public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid);
CREATE OR REPLACE FUNCTION public.work_set_execution_schedule(p_plan uuid,p_kind text,p_available_from timestamptz DEFAULT NULL,p_scheduled_for timestamptz DEFAULT NULL,p_due_at timestamptz DEFAULT NULL,p_planned_end timestamptz DEFAULT NULL,p_strict boolean DEFAULT false,p_version bigint DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE; result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 -- Normalise fields that are not part of the selected mode. This makes mode
 -- changes safe even when an older client submits values from hidden inputs.
 p_available_from:=CASE WHEN p_kind IN('window','period') THEN p_available_from END;
 p_scheduled_for:=CASE WHEN p_kind='scheduled' THEN p_scheduled_for END;
 p_due_at:=CASE WHEN p_kind IN('deadline','window','scheduled','period') THEN p_due_at END;
 p_planned_end:=CASE WHEN p_kind='period' THEN p_planned_end END;
 p_strict:=p_kind='scheduled' AND coalesce(p_strict,false);
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'La ejecución ya no existe'; END IF;
 IF p_version IS NOT NULL AND p.board_version<>p_version THEN RAISE EXCEPTION 'La ejecución ha cambiado. Actualiza la planificación'; END IF;
 IF p.state IN ('completed','blocked') THEN RAISE EXCEPTION 'No se cambian las fechas de una ejecución cerrada o bloqueada'; END IF;
 IF p_kind IS NULL OR p_kind NOT IN ('anytime','deadline','window','scheduled','period') THEN RAISE EXCEPTION 'Selecciona cuándo debe hacerse'; END IF;
 IF NOT (
  (p_kind='anytime' AND p_available_from IS NULL AND p_scheduled_for IS NULL AND p_due_at IS NULL AND p_planned_end IS NULL AND p_strict IS FALSE)
  OR (p_kind='deadline' AND p_available_from IS NULL AND p_scheduled_for IS NULL AND p_due_at IS NOT NULL AND p_planned_end IS NULL AND p_strict IS FALSE)
  OR (p_kind='window' AND p_available_from IS NOT NULL AND p_scheduled_for IS NULL AND p_due_at IS NOT NULL AND p_planned_end IS NULL AND p_strict IS FALSE AND p_available_from<p_due_at)
  OR (p_kind='scheduled' AND p_available_from IS NULL AND p_scheduled_for IS NOT NULL AND p_planned_end IS NULL AND (p_due_at IS NULL OR p_scheduled_for<p_due_at))
  OR (p_kind='period' AND p_available_from IS NOT NULL AND p_scheduled_for IS NULL AND p_planned_end IS NOT NULL AND p_strict IS FALSE AND p_available_from<p_planned_end AND (p_due_at IS NULL OR p_available_from<p_due_at))
 ) THEN RAISE EXCEPTION 'Las fechas no corresponden al tipo de planificación'; END IF;
 UPDATE public.work_day_plan SET schedule_kind=p_kind,available_from=p_available_from,scheduled_for=p_scheduled_for,due_at=p_due_at,planned_end=p_planned_end,strict_schedule=p_strict WHERE organization_id=p.organization_id AND id=p.id;
 SELECT public.work_execution_timing(p.id) INTO result;
 RETURN result||jsonb_build_object('id',p.id,'version',(SELECT board_version FROM public.work_day_plan WHERE id=p.id));
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_schedule_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE timing jsonb;
BEGIN
 IF NEW.work_plan_id IS NULL THEN RETURN NEW; END IF;
 SELECT public.work_execution_timing(NEW.work_plan_id,coalesce(NEW.checkin_time,clock_timestamp())) INTO timing;
 IF NOT coalesce((timing->>'can_start_time')::boolean,false) THEN
  IF coalesce((timing->>'starts_later')::boolean,false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Esta tarea todavía no está disponible'; END IF;
  IF coalesce((timing->>'overdue')::boolean,false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La fecha límite ha pasado. Solicita al encargado que reprograme la tarea'; END IF;
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La tarea no puede iniciarse en este momento';
 END IF;
 RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS zz_work_execution_schedule_guard ON public.checkins;
CREATE TRIGGER zz_work_execution_schedule_guard BEFORE INSERT ON public.checkins FOR EACH ROW EXECUTE FUNCTION public.work_execution_schedule_guard();

ALTER FUNCTION public.work_execution_timing(uuid,timestamptz) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_guard() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_execution_timing(uuid,timestamptz),public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint),public.work_execution_schedule_guard() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_execution_timing(uuid,timestamptz),public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint) TO authenticated,ase_tenant_executor;

REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
-- Complete execution-date contract. Kept in the same incremental migration so
-- the UI is never activated against the earlier foundation alone.

CREATE TABLE IF NOT EXISTS public.work_execution_schedule_events(
 organization_id uuid NOT NULL, id uuid NOT NULL DEFAULT gen_random_uuid(), plan_id uuid NOT NULL,
 request_id uuid, actor_id uuid, actor_name text NOT NULL, previous jsonb NOT NULL, current_value jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id), UNIQUE(organization_id,request_id),
 FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id)
);
ALTER TABLE public.work_execution_schedule_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_execution_schedule_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_execution_schedule_events TO ase_tenant_executor;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_execution_schedule_events' AND policyname='execution_schedule_scope') THEN
 CREATE POLICY execution_schedule_scope ON public.work_execution_schedule_events TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
END IF; END $$;

CREATE OR REPLACE FUNCTION ase_private.execution_schedule_json(p public.work_day_plan) RETURNS jsonb
LANGUAGE sql IMMUTABLE SET search_path='' AS $$ SELECT jsonb_build_object('schedule_kind',p.schedule_kind,'available_from',p.available_from,'scheduled_for',p.scheduled_for,'due_at',p.due_at,'planned_end',p.planned_end,'strict_schedule',p.strict_schedule) $$;

-- Every newly created execution, including personal and area recurrences, gets
-- dates derived from its own work_date. No catalog date is copied.
CREATE OR REPLACE FUNCTION public.work_execution_schedule_defaults() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$ BEGIN
 IF NEW.schedule_kind IS NULL THEN NEW.schedule_kind:='scheduled'; END IF;
 IF NEW.schedule_kind='scheduled' AND NEW.scheduled_for IS NULL THEN
  NEW.scheduled_for:=NEW.work_date::timestamp AT TIME ZONE 'Europe/Madrid';
  NEW.due_at:=coalesce(NEW.due_at,(NEW.work_date+1)::timestamp AT TIME ZONE 'Europe/Madrid');
  NEW.strict_schedule:=true;
 END IF;
 RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS aa_work_execution_schedule_defaults ON public.work_day_plan;
CREATE TRIGGER aa_work_execution_schedule_defaults BEFORE INSERT ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION public.work_execution_schedule_defaults();

-- One authoritative server decision for manual, NFC, tablet and board starts.
CREATE OR REPLACE FUNCTION public.work_execution_eligibility(p_plan uuid,p_moment timestamptz DEFAULT clock_timestamp()) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE; start_limit timestamptz; end_limit timestamptz; temporal boolean; earlier boolean; assigned boolean; opened boolean; reason text;
BEGIN
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan;
 IF NOT FOUND THEN RAISE EXCEPTION 'Ejecución no disponible'; END IF;
 start_limit:=CASE p.schedule_kind WHEN 'window' THEN p.available_from WHEN 'period' THEN p.available_from WHEN 'scheduled' THEN CASE WHEN p.strict_schedule THEN p.scheduled_for END END;
 end_limit:=CASE p.schedule_kind WHEN 'deadline' THEN p.due_at WHEN 'window' THEN p.due_at WHEN 'scheduled' THEN p.due_at WHEN 'period' THEN coalesce(p.due_at,p.planned_end) END;
 temporal:=(start_limit IS NULL OR p_moment>=start_limit) AND (end_limit IS NULL OR p_moment<end_limit);
 assigned:=EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=p.organization_id AND a.task_id=p.task_id AND a.user_id=p.user_id);
 opened:=EXISTS(SELECT 1 FROM public.checkins c WHERE c.organization_id=p.organization_id AND c.user_id=p.user_id AND c.checkout_time IS NULL AND c.work_plan_id IS DISTINCT FROM p.id);
 earlier:=EXISTS(SELECT 1 FROM public.work_day_plan x WHERE x.organization_id=p.organization_id AND x.user_id=p.user_id AND x.state='pending' AND x.id<>p.id AND x.priority<p.priority AND x.work_date=p.work_date);
 reason:=CASE WHEN p.state<>'pending' THEN 'state' WHEN NOT assigned THEN 'assignment' WHEN opened THEN 'open_checkin' WHEN earlier THEN 'order' WHEN start_limit IS NOT NULL AND p_moment<start_limit THEN 'too_early' WHEN end_limit IS NOT NULL AND p_moment>=end_limit THEN 'overdue' ELSE NULL END;
 RETURN ase_private.execution_schedule_json(p)||jsonb_build_object('kind',p.schedule_kind,'strict',p.strict_schedule,'can_start',reason IS NULL,'can_start_time',temporal,'reason',reason,'overdue',p.state IN ('pending','active') AND end_limit IS NOT NULL AND p_moment>=end_limit,'starts_later',p.state='pending' AND start_limit IS NOT NULL AND p_moment<start_limit,'start_limit',start_limit,'end_limit',end_limit);
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_timing(p_plan uuid,p_moment timestamptz DEFAULT clock_timestamp()) RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$ SELECT public.work_execution_eligibility(p_plan,p_moment) $$;

DROP FUNCTION IF EXISTS public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint);
CREATE FUNCTION public.work_set_execution_schedule(p_plan uuid,p_kind text,p_available_from timestamptz DEFAULT NULL,p_scheduled_for timestamptz DEFAULT NULL,p_due_at timestamptz DEFAULT NULL,p_planned_end timestamptz DEFAULT NULL,p_strict boolean DEFAULT false,p_version bigint DEFAULT NULL,p_request uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE; before_value jsonb; after_value jsonb; existing public.work_execution_schedule_events%ROWTYPE; result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 p_available_from:=CASE WHEN p_kind IN('window','period') THEN p_available_from END;
 p_scheduled_for:=CASE WHEN p_kind='scheduled' THEN p_scheduled_for END;
 p_due_at:=CASE WHEN p_kind IN('deadline','window','scheduled','period') THEN p_due_at END;
 p_planned_end:=CASE WHEN p_kind='period' THEN p_planned_end END;
 p_strict:=p_kind='scheduled' AND coalesce(p_strict,false);
 IF p_request IS NOT NULL THEN SELECT * INTO existing FROM public.work_execution_schedule_events WHERE organization_id=ase_private.current_org() AND request_id=p_request; IF FOUND THEN IF existing.plan_id<>p_plan OR existing.current_value IS DISTINCT FROM jsonb_build_object('schedule_kind',p_kind,'available_from',p_available_from,'scheduled_for',p_scheduled_for,'due_at',p_due_at,'planned_end',p_planned_end,'strict_schedule',p_strict) THEN RAISE EXCEPTION 'Identificador de operación ya utilizado'; END IF; RETURN existing.current_value||jsonb_build_object('id',p_plan,'repeated',true); END IF; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'La ejecución ya no existe'; END IF;
 IF p_version IS NOT NULL AND p.board_version<>p_version THEN RAISE EXCEPTION 'La ejecución ha cambiado. Actualiza la planificación'; END IF;
 IF p.state IN ('completed','blocked') THEN RAISE EXCEPTION 'No se cambian las fechas de una ejecución cerrada o bloqueada'; END IF;
 before_value:=ase_private.execution_schedule_json(p);
 IF NOT ((p_kind='anytime' AND p_available_from IS NULL AND p_scheduled_for IS NULL AND p_due_at IS NULL AND p_planned_end IS NULL AND NOT p_strict) OR (p_kind='deadline' AND p_available_from IS NULL AND p_scheduled_for IS NULL AND p_due_at IS NOT NULL AND p_planned_end IS NULL AND NOT p_strict) OR (p_kind='window' AND p_available_from IS NOT NULL AND p_scheduled_for IS NULL AND p_due_at IS NOT NULL AND p_planned_end IS NULL AND NOT p_strict AND p_available_from<p_due_at) OR (p_kind='scheduled' AND p_available_from IS NULL AND p_scheduled_for IS NOT NULL AND p_planned_end IS NULL AND (p_due_at IS NULL OR p_scheduled_for<p_due_at)) OR (p_kind='period' AND p_available_from IS NOT NULL AND p_scheduled_for IS NULL AND p_planned_end IS NOT NULL AND NOT p_strict AND p_available_from<p_planned_end AND (p_due_at IS NULL OR p_available_from<p_due_at))) THEN RAISE EXCEPTION 'Las fechas no corresponden al tipo de planificación'; END IF;
 UPDATE public.work_day_plan SET schedule_kind=p_kind,available_from=p_available_from,scheduled_for=p_scheduled_for,due_at=p_due_at,planned_end=p_planned_end,strict_schedule=p_strict WHERE organization_id=p.organization_id AND id=p.id RETURNING * INTO p;
 after_value:=ase_private.execution_schedule_json(p);
 IF before_value IS DISTINCT FROM after_value THEN INSERT INTO public.work_execution_schedule_events(organization_id,plan_id,request_id,actor_id,actor_name,previous,current_value) VALUES(p.organization_id,p.id,p_request,ase_private.session_user_id(),coalesce((SELECT full_name FROM ase_private.employee_profiles WHERE id=ase_private.session_user_id()),'Administración'),before_value,after_value); END IF;
 result:=public.work_execution_eligibility(p.id); RETURN result||jsonb_build_object('id',p.id,'version',p.board_version);
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_schedule_history(p_plan uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF NOT EXISTS(SELECT 1 FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan) THEN RAISE EXCEPTION 'Ejecución no disponible'; END IF;
 RETURN coalesce((SELECT jsonb_agg(to_jsonb(e) ORDER BY created_at DESC,id) FROM(SELECT id,actor_name,previous,current_value,created_at FROM public.work_execution_schedule_events WHERE organization_id=ase_private.current_org() AND plan_id=p_plan ORDER BY created_at DESC,id LIMIT 100)e),'[]'::jsonb);
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_schedule_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE eligibility jsonb; BEGIN IF NEW.work_plan_id IS NULL THEN RETURN NEW; END IF; eligibility:=public.work_execution_eligibility(NEW.work_plan_id,coalesce(NEW.checkin_time,clock_timestamp())); IF NOT coalesce((eligibility->>'can_start')::boolean,false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE=CASE eligibility->>'reason' WHEN 'too_early' THEN 'Esta tarea todavía no está disponible' WHEN 'overdue' THEN 'La fecha límite ha pasado. Solicita al encargado que reprograme la tarea' WHEN 'order' THEN 'Respeta el orden de tareas del empleado' WHEN 'open_checkin' THEN 'El empleado ya tiene un fichaje activo' WHEN 'assignment' THEN 'La tarea ya no está asignada al empleado' ELSE 'La tarea no puede iniciarse en este momento' END; END IF; RETURN NEW; END $$;

CREATE OR REPLACE FUNCTION public.work_admin_overview(p_user uuid,p_date date) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE v_plan jsonb;v_cards jsonb;v_stations jsonb;v_overdue jsonb; BEGIN PERFORM public.work_assert_permission('planning.view');
 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.priority),'[]') INTO v_plan FROM(SELECT p.id,p.task_id,t.title,p.priority,p.state,p.work_date,p.board_version version,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org() AND p.user_id=p_user AND p.work_date=p_date)q;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'user_id',user_id,'label',label,'active',active)),'[]') INTO v_cards FROM public.work_employee_cards WHERE organization_id=ase_private.current_org() AND archived_at IS NULL; SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'active',active,'reader_mode',reader_mode)),'[]') INTO v_stations FROM public.work_stations WHERE organization_id=ase_private.current_org() AND archived_at IS NULL;
 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.due_at,q.priority),'[]') INTO v_overdue FROM(SELECT p.id,p.user_id,p.task_id,t.title,p.work_date,p.priority,p.state,p.due_at,p.schedule_kind FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org() AND p.user_id=p_user AND p.state IN('pending','active') AND (public.work_execution_eligibility(p.id)->>'overdue')::boolean)q;
 RETURN jsonb_build_object('overdue',v_overdue,'enabled',public.work_mode(),'plan',v_plan,'cards',CASE WHEN public.sec06_is_admin() THEN v_cards ELSE '[]'::jsonb END,'stations',CASE WHEN public.sec06_is_admin() THEN v_stations ELSE '[]'::jsonb END); END $$;

CREATE OR REPLACE FUNCTION public.work_planning_board(p_date date,p_user uuid DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ DECLARE items jsonb;total integer; BEGIN PERFORM public.work_assert_permission('planning.view');IF p_date IS NULL THEN RAISE EXCEPTION 'Selecciona una fecha válida';END IF;SELECT count(*) INTO total FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND work_date=p_date AND(p_user IS NULL OR user_id=p_user);SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.priority,q.employee,q.id),'[]') INTO items FROM(SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org() AND p.work_date=p_date AND(p_user IS NULL OR p.user_id=p_user))q;RETURN jsonb_build_object('date',p_date,'items',items,'total',total,'as_of',now());END $$;

CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS (
  SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,p.state,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,
   (public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,
   (public.work_execution_eligibility(p.id)->>'can_start')::boolean eligible,public.work_incident_resolver(t.id) incident
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  WHERE p.organization_id=ase_private.current_org() AND p.user_id=ase_private.session_user_id() AND p.state IN('pending','active','blocked','completed')
   AND (p.state='active' OR p.work_date BETWEEN public.work_today()-30 AND public.work_today()+365)
 ), next_item AS (SELECT plan_id,task_id FROM items WHERE state='pending' AND eligible ORDER BY work_date,priority,plan_id LIMIT 1)
 SELECT jsonb_build_object('date',public.work_today(),'next_plan',(SELECT plan_id FROM next_item),'next_task',(SELECT task_id FROM next_item),'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',i.eligible AND (i.plan_id=(SELECT plan_id FROM next_item) OR i.incident),'can_finish',i.state='active') ORDER BY (i.state='completed'),(i.state='active') DESC,i.work_date,i.priority,i.plan_id) FROM items i),'[]'::jsonb))
$$;

CREATE OR REPLACE FUNCTION public.work_planning_calendar(p_user uuid,p_start date,p_end date) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('planning.view');IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>41 THEN RAISE EXCEPTION 'Selecciona hasta 42 días';END IF;SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.day),'[]') INTO result FROM(SELECT work_date AS day,count(*) AS total,count(*) FILTER(WHERE state='completed') AS completed,count(*) FILTER(WHERE state='active') AS active,count(*) FILTER(WHERE state IN('pending','active') AND (public.work_execution_eligibility(id)->>'overdue')::boolean) AS overdue,count(*) FILTER(WHERE state='pending' AND (public.work_execution_eligibility(id)->>'starts_later')::boolean) AS upcoming FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND user_id=p_user AND work_date BETWEEN p_start AND p_end GROUP BY work_date)q;RETURN result;END $$;

CREATE OR REPLACE FUNCTION public.work_overdue_items(p_limit integer DEFAULT 200) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ DECLARE result jsonb;BEGIN IF NOT(public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view'))THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso al seguimiento';END IF;IF p_limit IS NULL OR p_limit<1 OR p_limit>1000 THEN RAISE EXCEPTION 'Límite no válido';END IF;WITH filtered AS(SELECT p.id,p.task_id,p.user_id,p.work_date,p.state,p.priority,p.schedule_kind,p.due_at,p.planned_end,t.title,u.full_name employee FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org() AND p.state IN('pending','active') AND(public.work_execution_eligibility(p.id)->>'overdue')::boolean),page AS(SELECT * FROM filtered ORDER BY coalesce(due_at,planned_end),work_date,priority,id LIMIT p_limit)SELECT jsonb_build_object('total',(SELECT count(*)FROM filtered),'items',coalesce((SELECT jsonb_agg(to_jsonb(p)ORDER BY coalesce(p.due_at,p.planned_end),p.work_date,p.priority,p.id)FROM page p),'[]'))INTO result;RETURN result;END $$;

ALTER FUNCTION ase_private.execution_schedule_json(public.work_day_plan) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_defaults() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_eligibility(uuid,timestamptz) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_timing(uuid,timestamptz) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_history(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_guard() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_admin_overview(uuid,date) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_board(date,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_queue() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_calendar(uuid,date,date) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_overdue_items(integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_execution_eligibility(uuid,timestamptz),public.work_execution_timing(uuid,timestamptz),public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid),public.work_execution_schedule_history(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_execution_eligibility(uuid,timestamptz),public.work_execution_timing(uuid,timestamptz),public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid),public.work_execution_schedule_history(uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261024000500_board_range_and_execution_identity.sql ====
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

-- Replace the temporary hosted wrapper with the definitive normalized API.
CREATE OR REPLACE FUNCTION public.work_set_execution_schedule(p_plan uuid,p_kind text,p_available_from timestamptz DEFAULT NULL,p_scheduled_for timestamptz DEFAULT NULL,p_due_at timestamptz DEFAULT NULL,p_planned_end timestamptz DEFAULT NULL,p_strict boolean DEFAULT false,p_version bigint DEFAULT NULL,p_request uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE; before_value jsonb; after_value jsonb; existing public.work_execution_schedule_events%ROWTYPE; result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 p_available_from:=CASE WHEN p_kind IN('window','period') THEN p_available_from END;
 p_scheduled_for:=CASE WHEN p_kind='scheduled' THEN p_scheduled_for END;
 p_due_at:=CASE WHEN p_kind IN('deadline','window','scheduled','period') THEN p_due_at END;
 p_planned_end:=CASE WHEN p_kind='period' THEN p_planned_end END;
 p_strict:=p_kind='scheduled' AND coalesce(p_strict,false);
 IF p_request IS NOT NULL THEN SELECT * INTO existing FROM public.work_execution_schedule_events WHERE organization_id=ase_private.current_org() AND request_id=p_request; IF FOUND THEN IF existing.plan_id<>p_plan OR existing.current_value IS DISTINCT FROM jsonb_build_object('schedule_kind',p_kind,'available_from',p_available_from,'scheduled_for',p_scheduled_for,'due_at',p_due_at,'planned_end',p_planned_end,'strict_schedule',p_strict) THEN RAISE EXCEPTION 'Identificador de operación ya utilizado'; END IF; RETURN existing.current_value||jsonb_build_object('id',p_plan,'repeated',true); END IF; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'La ejecución ya no existe'; END IF;
 IF p_version IS NOT NULL AND p.board_version<>p_version THEN RAISE EXCEPTION 'La ejecución ha cambiado. Actualiza la planificación'; END IF;
 IF p.state IN ('completed','blocked') THEN RAISE EXCEPTION 'No se cambian las fechas de una ejecución cerrada o bloqueada'; END IF;
 before_value:=ase_private.execution_schedule_json(p);
 IF NOT ((p_kind='anytime' AND p_available_from IS NULL AND p_scheduled_for IS NULL AND p_due_at IS NULL AND p_planned_end IS NULL AND NOT p_strict) OR (p_kind='deadline' AND p_available_from IS NULL AND p_scheduled_for IS NULL AND p_due_at IS NOT NULL AND p_planned_end IS NULL AND NOT p_strict) OR (p_kind='window' AND p_available_from IS NOT NULL AND p_scheduled_for IS NULL AND p_due_at IS NOT NULL AND p_planned_end IS NULL AND NOT p_strict AND p_available_from<p_due_at) OR (p_kind='scheduled' AND p_available_from IS NULL AND p_scheduled_for IS NOT NULL AND p_planned_end IS NULL AND (p_due_at IS NULL OR p_scheduled_for<p_due_at)) OR (p_kind='period' AND p_available_from IS NOT NULL AND p_scheduled_for IS NULL AND p_planned_end IS NOT NULL AND NOT p_strict AND p_available_from<p_planned_end AND (p_due_at IS NULL OR p_available_from<p_due_at))) THEN RAISE EXCEPTION 'Las fechas no corresponden al tipo de planificación'; END IF;
 UPDATE public.work_day_plan SET schedule_kind=p_kind,available_from=p_available_from,scheduled_for=p_scheduled_for,due_at=p_due_at,planned_end=p_planned_end,strict_schedule=p_strict WHERE organization_id=p.organization_id AND id=p.id RETURNING * INTO p;
 after_value:=ase_private.execution_schedule_json(p);
 IF before_value IS DISTINCT FROM after_value THEN INSERT INTO public.work_execution_schedule_events(organization_id,plan_id,request_id,actor_id,actor_name,previous,current_value) VALUES(p.organization_id,p.id,p_request,ase_private.session_user_id(),coalesce((SELECT full_name FROM ase_private.employee_profiles WHERE id=ase_private.session_user_id()),'Administración'),before_value,after_value); END IF;
 result:=public.work_execution_eligibility(p.id); RETURN result||jsonb_build_object('id',p.id,'version',p.board_version);
END $$;
DROP FUNCTION IF EXISTS public.work_set_execution_schedule_raw(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid);

-- A queue entry is an execution (work_day_plan), not a catalogue task. The
-- same recurring task can therefore occur more than once without one row
-- replacing or enabling another.
CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS (
  SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,p.state,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,
   (public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,
   (public.work_execution_eligibility(p.id)->>'can_start')::boolean eligible,public.work_incident_resolver(t.id) incident
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  WHERE p.organization_id=ase_private.current_org() AND p.user_id=ase_private.session_user_id() AND p.state IN('pending','active','blocked','completed')
   AND (p.state='active' OR p.work_date BETWEEN public.work_today()-30 AND public.work_today()+365)
 ), next_item AS (SELECT plan_id,task_id FROM items WHERE state='pending' AND eligible ORDER BY work_date,priority,plan_id LIMIT 1)
 SELECT jsonb_build_object('date',public.work_today(),'next_plan',(SELECT plan_id FROM next_item),'next_task',(SELECT task_id FROM next_item),'items',
  coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',i.eligible AND (i.plan_id=(SELECT plan_id FROM next_item) OR i.incident),'can_finish',i.state='active')
   ORDER BY (i.state='completed'),(i.state='active') DESC,i.work_date,i.priority,i.plan_id) FROM items i),'[]'::jsonb))
$$;

CREATE OR REPLACE FUNCTION public.work_mobile_order_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb;incident uuid;queue jsonb;
BEGIN
 IF public.work_mode() OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR public.sec06_is_admin() THEN RETURN NEW; END IF;
 IF NEW.user_id IS DISTINCT FROM ase_private.session_user_id() THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible'; END IF;
 PERFORM 1 FROM public.organization_memberships WHERE organization_id=ase_private.current_org() AND user_id=NEW.user_id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=NEW.organization_id AND user_id=NEW.user_id AND checkout_time IS NULL) THEN RAISE EXCEPTION 'Finaliza primero tu fichaje activo'; END IF;
 queue:=public.work_mobile_queue();
 SELECT x INTO item FROM jsonb_array_elements(queue->'items') x
  WHERE x->>'plan_id'=queue->>'next_plan' AND x->>'task_id'=NEW.task_id::text LIMIT 1;
 IF item IS NULL THEN
  SELECT x INTO item FROM jsonb_array_elements(queue->'items') x
   WHERE x->>'task_id'=NEW.task_id::text AND coalesce((x->>'incident')::boolean,false) ORDER BY (x->>'work_date')::date,(x->>'priority')::integer,x->>'plan_id' LIMIT 1;
 END IF;
 IF item IS NULL OR NOT coalesce((item->>'can_start')::boolean,false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Esta tarea está en consulta. Ficha en la siguiente ejecución según el orden del encargado'; END IF;
 IF item->>'plan_id'=queue->>'next_plan' THEN NEW.work_plan_id:=(item->>'plan_id')::uuid;
 ELSE
  SELECT i.id INTO incident FROM public.work_incidents i WHERE i.organization_id=NEW.organization_id AND i.task_id=NEW.task_id AND i.state IN ('open','in_progress')
  AND (i.assigned_user=NEW.user_id OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id AND m.user_id=NEW.user_id)) ORDER BY i.created_at LIMIT 1;
  NEW.work_incident_id:=incident;
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días'; END IF;
 IF p_state IS NOT NULL AND p_state NOT IN('pending','active','blocked','completed') THEN RAISE EXCEPTION 'Estado no válido'; END IF;
 IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida'; END IF;
 WITH base AS (
  SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible') employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,
   (public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
  WHERE p.organization_id=ase_private.current_org() AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)
   AND(nullif(btrim(p_query),'') IS NULL OR concat_ws(' ',t.title,t.description,u.full_name) ILIKE '%'||btrim(p_query)||'%')
 ), page AS (SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)
 SELECT jsonb_build_object('start',p_start,'end',p_end,'total',(SELECT count(*) FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object(
  'pending',(SELECT count(*) FROM base WHERE state='pending'),'active',(SELECT count(*) FROM base WHERE state='active'),'blocked',(SELECT count(*) FROM base WHERE state='blocked'),'completed',(SELECT count(*) FROM base WHERE state='completed')),
  'items',coalesce((SELECT jsonb_agg(to_jsonb(page) ORDER BY work_date,priority,employee,id) FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp()) INTO result;
 RETURN result;
END $$;

ALTER FUNCTION public.work_mobile_queue() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_order_guard() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) TO authenticated,ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261024000600_productivity_areas.sql ====
-- ASE Work: productivity reports filtered by work area.

CREATE OR REPLACE FUNCTION public.work_admin_productivity_area(p_start date, p_end date, p_task uuid, p_area uuid)
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
 IF p_area IS NULL OR NOT EXISTS(SELECT 1 FROM public.work_areas WHERE id=p_area AND active) THEN RAISE EXCEPTION 'Área no válida'; END IF;
 v_from:=p_start::timestamp AT TIME ZONE 'Europe/Madrid'; v_to:=(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid';
 WITH samples AS (
  SELECT c.id,c.user_id,u.full_name AS name,c.checkin_time,c.checkout_time,
   (c.checkout_time AT TIME ZONE 'Europe/Madrid')::date AS day,
   extract(epoch FROM c.checkout_time-c.checkin_time)::double precision AS seconds
  FROM public.checkins c JOIN ase_private.employee_profiles u ON u.id=c.user_id AND u.is_admin IS FALSE
  WHERE c.task_id=p_task AND EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=p_area AND m.user_id=c.user_id)
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
  'invalid',(SELECT count(*) FROM public.checkins c JOIN ase_private.employee_profiles u ON u.id=c.user_id AND u.is_admin IS FALSE WHERE c.task_id=p_task AND EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=p_area AND m.user_id=c.user_id) AND c.checkout_time>=v_from AND c.checkout_time<v_to AND (c.checkin_time IS NULL OR c.checkout_time<=c.checkin_time)),
  'as_of',now()) INTO result;
 RETURN result;
END $function$;

-- PostgreSQL requires the future owner to be able to create objects in the
-- function's schema while ownership is transferred. Keep this privilege only
-- for the ALTER OWNER statement.
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
ALTER FUNCTION public.work_admin_productivity_area(date,date,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_admin_productivity_area(date,date,uuid,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_admin_productivity_area(date,date,uuid,uuid) TO ase_tenant_executor,authenticated;

-- ==== 20261024000700_report_area_filter.sql ====
-- ASE Work: common employee or area scope for every report.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE FUNCTION public.work_report_table_scope(p_kind text,p_start date,p_end date,p_search text,p_state text,p_method text,p_employee uuid,p_area uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 IF p_kind IS NULL OR p_kind NOT IN ('checkins','tasks','productivity','incidents','closures') OR p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR length(coalesce(p_search,''))>120 THEN RAISE EXCEPTION 'Selecciona un informe y un período de hasta 366 días'; END IF;
 IF p_employee IS NOT NULL AND p_area IS NOT NULL THEN RAISE EXCEPTION 'Selecciona un empleado o un área'; END IF;
 IF p_employee IS NOT NULL AND NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_employee) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas WHERE id=p_area AND active) THEN RAISE EXCEPTION 'Área no válida'; END IF;
 WITH source AS (
SELECT row FROM (SELECT jsonb_build_object('_at',c.checkin_time,'_state',CASE WHEN c.checkout_time IS NULL THEN 'open' ELSE 'closed' END,'_method',c.checkin_method,'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'start',c.checkin_time,'end',c.checkout_time,'minutes',round((extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)/60)::numeric,2),'method',c.checkin_method,'status',CASE WHEN c.checkout_time IS NULL THEN 'En curso' ELSE 'Cerrado' END) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id) dataset WHERE p_kind='checkins'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',(coalesce(p.work_date,t.schedule_date,(t.created_at AT TIME ZONE 'Europe/Madrid')::date)::timestamp AT TIME ZONE 'Europe/Madrid'),'_state',coalesce(p.state,'unplanned'),'_users',jsonb_build_array(a.user_id),'employee',u.full_name,'task',t.title,'date',coalesce(p.work_date,t.schedule_date),'priority',p.priority,'status',CASE p.state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'completed' THEN 'Completada' WHEN 'blocked' THEN 'Bloqueada' ELSE 'Sin planificación' END) row FROM public.tasks t LEFT JOIN public.task_assignments a ON a.task_id=t.id LEFT JOIN ase_private.employee_profiles u ON u.id=a.user_id LEFT JOIN public.work_day_plan p ON p.task_id=t.id AND p.user_id=a.user_id) dataset WHERE p_kind='tasks'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',((c.checkin_time AT TIME ZONE 'Europe/Madrid')::date::timestamp AT TIME ZONE 'Europe/Madrid'),'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'date',(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date,'count',count(*),'minutes',round(sum(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2),'average',round(avg(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2)) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id WHERE c.checkout_time>=c.checkin_time GROUP BY c.user_id,u.full_name,t.id,t.title,(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date) dataset WHERE p_kind='productivity'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',i.created_at,'_state',i.state,'_users',jsonb_build_array(i.reporter_id,i.assigned_user)||coalesce((SELECT jsonb_agg(m.user_id) FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id),'[]'::jsonb),'employee',u.full_name,'task',t.title,'subject',i.subject,'responsible',coalesce(a.name,v.full_name),'start',i.created_at,'updated',i.updated_at,'status',CASE i.state WHEN 'open' THEN 'Abierta' WHEN 'in_progress' THEN 'En atención' ELSE 'Resuelta' END,'blocked',CASE WHEN i.blocks_work THEN 'Sí' ELSE 'No' END,'resolution',i.resolution) row FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=i.reporter_id LEFT JOIN ase_private.employee_profiles v ON v.id=i.assigned_user LEFT JOIN public.work_areas a ON a.id=i.area_id) dataset WHERE p_kind='incidents'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',c.created_at,'_users',jsonb_build_array(p.user_id),'employee',u.full_name,'task',t.title,'actor',v.full_name,'start',c.created_at,'type',CASE c.kind WHEN 'admin_finish' THEN 'Cierre administrativo' ELSE 'Bloqueo por incidencia' END,'reason',c.reason) row FROM public.work_task_closures c JOIN public.work_day_plan p ON p.id=c.plan_id JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id LEFT JOIN ase_private.employee_profiles v ON v.id=c.actor_id) dataset WHERE p_kind='closures'
 ), filtered AS (
 SELECT row FROM source WHERE (row->>'_at')::timestamptz>=p_start::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (row->>'_at')::timestamptz<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (p_employee IS NULL OR row->'_users' @> jsonb_build_array(p_employee))
 AND (p_area IS NULL OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=p_area AND row->'_users' @> jsonb_build_array(m.user_id)))
 AND (p_state IS NULL OR row->>'_state'=p_state) AND (p_method IS NULL OR row->>'_method'=p_method)
 AND (coalesce(btrim(p_search),'')='' OR strpos(lower((row-'_at'-'_state'-'_method'-'_users')::text),lower(btrim(p_search)))>0)
 ), limited AS (SELECT row FROM filtered ORDER BY row->>'_at' DESC,row::text LIMIT 10001)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(row-'_at'-'_state'-'_method'-'_users') FROM limited),'[]'::jsonb),'as_of',now()) INTO result;
 IF (result->>'total')::integer>10000 THEN RAISE EXCEPTION 'Hay más de 10.000 filas. Reduce las fechas o utiliza el buscador antes de descargar'; END IF;
 RETURN result;
END $$;

ALTER FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261024000800_operational_notifications.sql ====
-- ASE Work: deduplicated operational notifications.

ALTER TABLE public.work_notifications ADD COLUMN IF NOT EXISTS kind text NOT NULL DEFAULT 'incident';
ALTER TABLE public.work_notifications ADD COLUMN IF NOT EXISTS event_key text;
ALTER TABLE public.work_notifications ALTER COLUMN incident_id DROP NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS work_notification_event_once
 ON public.work_notifications(organization_id,user_id,event_key) WHERE event_key IS NOT NULL;

GRANT CREATE ON SCHEMA ase_private TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION ase_private.notify_new_assignment() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE task_title text; area_recurrence_pending boolean:=false;
BEGIN
 IF to_regclass('public.work_recurrences') IS NOT NULL AND to_regclass('public.work_area_recurrence_due') IS NOT NULL THEN
  EXECUTE 'SELECT EXISTS(SELECT 1 FROM public.work_recurrences r JOIN public.work_area_recurrence_due d ON d.recurrence_id=r.id AND d.plan_id IS NULL JOIN public.work_area_members m ON m.area_id=r.area_id AND m.user_id=$1 WHERE r.organization_id=$2 AND r.task_id=$3 AND r.area_id IS NOT NULL)' INTO area_recurrence_pending USING NEW.user_id,NEW.organization_id,NEW.task_id;
 END IF;
 IF area_recurrence_pending THEN RETURN NEW; END IF;
 SELECT title INTO task_title FROM public.tasks WHERE organization_id=NEW.organization_id AND id=NEW.task_id;
 INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)
 VALUES(NEW.organization_id,NEW.user_id,NULL,'Nueva tarea asignada: '||coalesce(task_title,'Tarea'), 'assignment','assignment:'||NEW.task_id::text||':'||NEW.user_id::text||':'||txid_current()::text)
 ON CONFLICT(organization_id,user_id,event_key) WHERE event_key IS NOT NULL DO NOTHING;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION ase_private.notify_importance_change() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid; task_title text; label text;
BEGIN
 SELECT title INTO task_title FROM public.tasks WHERE organization_id=NEW.organization_id AND id=NEW.task_id;
 label:=CASE NEW.current_value WHEN 'urgent' THEN 'Urgente' WHEN 'high' THEN 'Alta' WHEN 'low' THEN 'Baja' ELSE 'Normal' END;
 FOR recipient IN SELECT user_id FROM public.task_assignments WHERE organization_id=NEW.organization_id AND task_id=NEW.task_id LOOP
  INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)
  VALUES(NEW.organization_id,recipient,NULL,'Importancia actualizada: '||coalesce(task_title,'Tarea')||' · '||label,'importance','importance:'||NEW.id::text||':'||recipient::text)
  ON CONFLICT(organization_id,user_id,event_key) WHERE event_key IS NOT NULL DO NOTHING;
 END LOOP;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION ase_private.notify_execution_schedule_change() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid; task_title text; schedule_label text;
BEGIN
 SELECT p.user_id,t.title INTO recipient,task_title FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=NEW.organization_id AND p.id=NEW.plan_id;
 schedule_label:=CASE NEW.current_value->>'schedule_kind' WHEN 'window' THEN 'ventana de ejecución' WHEN 'deadline' THEN 'fecha límite' WHEN 'scheduled' THEN 'fecha programada' WHEN 'period' THEN 'período planificado' ELSE 'sin fecha' END;
 IF recipient IS NOT NULL THEN
  INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)
  VALUES(NEW.organization_id,recipient,NULL,'Planificación actualizada: '||coalesce(task_title,'Tarea')||' · '||schedule_label,'schedule','schedule:'||NEW.id::text||':'||recipient::text)
  ON CONFLICT(organization_id,user_id,event_key) WHERE event_key IS NOT NULL DO NOTHING;
 END IF;
 RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS work_notify_new_assignment ON public.task_assignments;
CREATE TRIGGER work_notify_new_assignment AFTER INSERT ON public.task_assignments FOR EACH ROW EXECUTE FUNCTION ase_private.notify_new_assignment();
DROP TRIGGER IF EXISTS work_notify_importance_change ON public.work_importance_events;
CREATE TRIGGER work_notify_importance_change AFTER INSERT ON public.work_importance_events FOR EACH ROW EXECUTE FUNCTION ase_private.notify_importance_change();
DROP TRIGGER IF EXISTS work_notify_execution_schedule_change ON public.work_execution_schedule_events;
CREATE TRIGGER work_notify_execution_schedule_change AFTER INSERT ON public.work_execution_schedule_events FOR EACH ROW EXECUTE FUNCTION ase_private.notify_execution_schedule_change();

ALTER FUNCTION ase_private.notify_new_assignment() OWNER TO ase_tenant_executor;
ALTER FUNCTION ase_private.notify_importance_change() OWNER TO ase_tenant_executor;
ALTER FUNCTION ase_private.notify_execution_schedule_change() OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA ase_private FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.notify_new_assignment(),ase_private.notify_importance_change(),ase_private.notify_execution_schedule_change() FROM PUBLIC,anon,authenticated,ase_tenant_executor;

-- ==== 20261024000900_deadline_notifications.sql ====
-- ASE Work: one reminder in the last 24 hours and one overdue notification.

CREATE OR REPLACE FUNCTION ase_private.run_deadline_notifications(p_org uuid,p_now timestamptz) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE changed integer:=0; inserted integer;
BEGIN
 IF p_org IS NULL OR p_now IS NULL THEN RAISE EXCEPTION 'Contexto de avisos no válido'; END IF;
 WITH candidates AS (
  SELECT p.id,p.user_id,t.title,coalesce(p.due_at,p.planned_end) deadline
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  WHERE p.organization_id=p_org AND p.state IN('pending','active') AND coalesce(p.due_at,p.planned_end)>p_now AND coalesce(p.due_at,p.planned_end)<=p_now+interval '24 hours'
 )
 INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)
 SELECT p_org,user_id,NULL,'Próxima fecha límite: '||title||' · '||to_char(deadline AT TIME ZONE 'Europe/Madrid','DD/MM/YYYY HH24:MI'),'deadline_soon','deadline-soon:'||id::text||':'||extract(epoch FROM deadline)::bigint::text FROM candidates
 ON CONFLICT(organization_id,user_id,event_key) WHERE event_key IS NOT NULL DO NOTHING;
 GET DIAGNOSTICS inserted=ROW_COUNT; changed:=changed+inserted;
 WITH candidates AS (
  SELECT p.id,p.user_id,t.title,coalesce(p.due_at,p.planned_end) deadline
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  WHERE p.organization_id=p_org AND p.state IN('pending','active') AND coalesce(p.due_at,p.planned_end)<=p_now
 )
 INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)
 SELECT p_org,user_id,NULL,'Tarea vencida: '||title||' · límite '||to_char(deadline AT TIME ZONE 'Europe/Madrid','DD/MM/YYYY HH24:MI'),'overdue','deadline-overdue:'||id::text||':'||extract(epoch FROM deadline)::bigint::text FROM candidates
 ON CONFLICT(organization_id,user_id,event_key) WHERE event_key IS NOT NULL DO NOTHING;
 GET DIAGNOSTICS inserted=ROW_COUNT; changed:=changed+inserted;
 RETURN changed;
END $$;

CREATE OR REPLACE FUNCTION ase_private.schedule_deadline_notifications() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid; moment timestamptz:=clock_timestamp();
BEGIN
 FOR org IN SELECT id FROM public.organizations WHERE status='active' LOOP
  PERFORM ase_private.run_deadline_notifications(org,moment);
 END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.work_run_deadline_notifications() RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 RETURN ase_private.run_deadline_notifications(ase_private.current_org(),clock_timestamp());
END $$;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
ALTER FUNCTION public.work_run_deadline_notifications() OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.run_deadline_notifications(uuid,timestamptz),ase_private.schedule_deadline_notifications() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.run_deadline_notifications(uuid,timestamptz) TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_run_deadline_notifications() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_run_deadline_notifications() TO authenticated;
NOTIFY pgrst,'reload schema';

-- ==== 20261024001000_unified_task_history.sql ====
CREATE TABLE IF NOT EXISTS public.work_task_assignment_events(
 organization_id uuid NOT NULL,
 id uuid NOT NULL DEFAULT gen_random_uuid(),
 task_id uuid NOT NULL,
 user_id uuid NOT NULL,
 actor_id uuid,
 actor_name text NOT NULL,
 employee_name text NOT NULL,
 action text NOT NULL CHECK(action IN('assigned','unassigned')),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id)
);
CREATE INDEX IF NOT EXISTS work_task_assignment_events_task ON public.work_task_assignment_events(organization_id,task_id,created_at DESC,id);
ALTER TABLE public.work_task_assignment_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_assignment_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_task_assignment_events TO ase_tenant_executor;
DROP POLICY IF EXISTS task_assignment_events_executor ON public.work_task_assignment_events;
CREATE POLICY task_assignment_events_executor ON public.work_task_assignment_events TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

GRANT CREATE ON SCHEMA ase_private TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION ase_private.log_task_assignment_event() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE row_value public.task_assignments%ROWTYPE; actor uuid:=ase_private.session_user_id();
BEGIN
 row_value:=CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
 INSERT INTO public.work_task_assignment_events(organization_id,task_id,user_id,actor_id,actor_name,employee_name,action)
 VALUES(row_value.organization_id,row_value.task_id,row_value.user_id,actor,
  coalesce((SELECT full_name FROM public.organization_memberships WHERE organization_id=row_value.organization_id AND user_id=actor),'Sistema'),
  coalesce((SELECT full_name FROM public.organization_memberships WHERE organization_id=row_value.organization_id AND user_id=row_value.user_id),'Empleado no disponible'),
  CASE WHEN TG_OP='DELETE' THEN 'unassigned' ELSE 'assigned' END);
 RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END $$;
DROP TRIGGER IF EXISTS work_log_task_assignment ON public.task_assignments;
CREATE TRIGGER work_log_task_assignment AFTER INSERT OR DELETE ON public.task_assignments FOR EACH ROW EXECUTE FUNCTION ase_private.log_task_assignment_event();
ALTER FUNCTION ase_private.log_task_assignment_event() OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA ase_private FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.log_task_assignment_event() FROM PUBLIC,anon,authenticated,ase_tenant_executor;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_task_timeline(p_task uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=ase_private.current_org() AND id=p_task) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF NOT(public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes consultar esta tarea'; END IF;
 WITH events AS (
  SELECT 'created:'||t.id::text id,'created' kind,'Tarea creada' title,t.title detail,'Sistema' actor_name,t.created_at
  FROM public.tasks t WHERE t.organization_id=ase_private.current_org() AND t.id=p_task
  UNION ALL
  SELECT 'assignment:'||e.id::text,'assignment_'||e.action,
   CASE e.action WHEN 'assigned' THEN 'Empleado asignado' ELSE 'Empleado retirado' END,e.employee_name,e.actor_name,e.created_at
  FROM public.work_task_assignment_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL
  SELECT 'importance:'||e.id::text,'importance','Importancia modificada',
   coalesce(CASE e.previous WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,'Creación')||' → '||
   CASE e.current_value WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,
   e.actor_name,e.created_at FROM public.work_importance_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL
  SELECT 'schedule:'||e.id::text,'schedule','Planificación modificada',
   CASE e.current_value->>'schedule_kind' WHEN 'anytime' THEN 'En cualquier momento' WHEN 'deadline' THEN 'Antes de una fecha' WHEN 'window' THEN 'Ventana de ejecución' WHEN 'scheduled' THEN 'Fecha u hora concreta' WHEN 'period' THEN 'Periodo planificado' ELSE 'Planificación actualizada' END,
   e.actor_name,e.created_at FROM public.work_execution_schedule_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id
   WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
  UNION ALL
  SELECT 'state:'||e.id::text,'state','Estado modificado',
   CASE e.from_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' ELSE e.from_state END||' → '||
   CASE e.to_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' ELSE e.to_state END||' · '||e.reason,
   e.actor_name,e.created_at FROM public.work_board_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id
   WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
 ), page AS (SELECT * FROM events ORDER BY created_at DESC,id DESC LIMIT 250)
 SELECT coalesce(jsonb_agg(to_jsonb(page) ORDER BY created_at DESC,id DESC),'[]'::jsonb) INTO result FROM page;
 RETURN result;
END $$;
ALTER FUNCTION public.work_task_timeline(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_task_timeline(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_timeline(uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;

NOTIFY pgrst,'reload schema';

-- ==== 20261025000100_share_access_assignments.sql ====
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_share_task_access(p_task uuid,p_users uuid[],p_expires_days integer DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org(); code text; expires_at timestamptz; blocked_names text;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_task IS NULL OR NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=org AND id=p_task FOR KEY SHARE) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF p_users IS NULL OR cardinality(p_users)<1 OR cardinality(p_users)>100 OR cardinality(p_users)<>(SELECT count(DISTINCT id) FROM unnest(p_users)u(id)) OR EXISTS(
  SELECT 1 FROM unnest(p_users)u(id) WHERE id IS NULL OR NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles e WHERE e.id=u.id AND e.is_admin IS FALSE AND e.membership_status='active')
 ) THEN RAISE EXCEPTION 'Selecciona al menos un empleado activo'; END IF;
 IF p_expires_days IS NOT NULL AND p_expires_days NOT IN(1,7,30,90) THEN RAISE EXCEPTION 'Caducidad no válida'; END IF;

 SELECT string_agg(coalesce(e.full_name,'Empleado'),', ' ORDER BY e.full_name) INTO blocked_names
 FROM public.task_assignments a LEFT JOIN ase_private.employee_profiles e ON e.id=a.user_id
 WHERE a.organization_id=org AND a.task_id=p_task AND NOT(a.user_id=ANY(p_users)) AND (
  EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.organization_id=org AND p.task_id=p_task AND p.user_id=a.user_id AND p.state IN('pending','active','blocked'))
  OR EXISTS(SELECT 1 FROM public.checkins c WHERE c.organization_id=org AND c.task_id=p_task AND c.user_id=a.user_id AND c.checkout_time IS NULL)
 );
 IF blocked_names IS NOT NULL THEN RAISE EXCEPTION 'No puedes retirar a %: tiene planificación pendiente, activa o bloqueada',blocked_names; END IF;

 DELETE FROM public.task_assignments a WHERE a.organization_id=org AND a.task_id=p_task AND NOT(a.user_id=ANY(p_users));
 INSERT INTO public.task_assignments(organization_id,task_id,user_id)
 SELECT org,p_task,u.id FROM unnest(p_users)u(id)
 WHERE NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=org AND a.task_id=p_task AND a.user_id=u.id);

 code:='TASK-'||upper(replace(gen_random_uuid()::text,'-',''));
 expires_at:=CASE WHEN p_expires_days IS NULL THEN NULL ELSE clock_timestamp()+make_interval(days=>p_expires_days) END;
 INSERT INTO public.task_access_codes(organization_id,id,task_id,access_code,created_by,created_at,is_active,expires_at)
 VALUES(org,gen_random_uuid(),p_task,code,ase_private.session_user_id(),clock_timestamp(),true,expires_at);
 RETURN jsonb_build_object('code',code,'expires_at',expires_at,'assigned',cardinality(p_users));
END $$;
ALTER FUNCTION public.work_share_task_access(uuid,uuid[],integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_share_task_access(uuid,uuid[],integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_share_task_access(uuid,uuid[],integer) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;

NOTIFY pgrst,'reload schema';

-- ==== 20261025000200_task_people_roles.sql ====
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_guard_assignment() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF TG_OP='UPDATE' AND NEW.organization_id=OLD.organization_id AND NEW.task_id=OLD.task_id AND NEW.user_id=OLD.user_id THEN RETURN NEW;END IF;
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=OLD.user_id FOR UPDATE;
 IF public.work_mode()AND EXISTS(SELECT 1 FROM public.work_day_plan WHERE task_id=OLD.task_id AND user_id=OLD.user_id AND state='active')THEN RAISE EXCEPTION 'Finaliza la tarea en la tablet antes de cambiar su asignación';END IF;
 IF TG_OP='DELETE'THEN RETURN OLD;END IF;RETURN NEW;
END $$;
ALTER FUNCTION public.work_guard_assignment() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_guard_assignment() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_guard_assignment() TO ase_tenant_executor;

ALTER TABLE public.task_assignments ADD COLUMN IF NOT EXISTS responsibility_role text NOT NULL DEFAULT 'collaborator';
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='task_assignment_responsibility_role' AND conrelid='public.task_assignments'::regclass) THEN ALTER TABLE public.task_assignments ADD CONSTRAINT task_assignment_responsibility_role CHECK(responsibility_role IN('primary','collaborator')); END IF; END $$;
WITH ranked AS(SELECT organization_id,task_id,user_id,row_number() OVER(PARTITION BY organization_id,task_id ORDER BY user_id) n FROM public.task_assignments)
UPDATE public.task_assignments a SET responsibility_role='primary' FROM ranked r WHERE r.organization_id=a.organization_id AND r.task_id=a.task_id AND r.user_id=a.user_id AND r.n=1 AND NOT EXISTS(SELECT 1 FROM public.task_assignments x WHERE x.organization_id=a.organization_id AND x.task_id=a.task_id AND x.responsibility_role='primary');
CREATE UNIQUE INDEX IF NOT EXISTS task_assignments_one_primary ON public.task_assignments(organization_id,task_id) WHERE responsibility_role='primary';

CREATE TABLE IF NOT EXISTS public.work_task_followers(
 organization_id uuid NOT NULL,task_id uuid NOT NULL,user_id uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,task_id,user_id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id) ON DELETE CASCADE
);
ALTER TABLE public.work_task_followers ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_followers FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,DELETE ON public.work_task_followers TO ase_tenant_executor;
DROP POLICY IF EXISTS task_followers_executor ON public.work_task_followers;
CREATE POLICY task_followers_executor ON public.work_task_followers TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_manage_task_roles(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[]) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;org uuid:=ase_private.current_org();executors uuid[];blocked_names text;
BEGIN
 p_collaborators:=coalesce(p_collaborators,'{}'::uuid[]);p_followers:=coalesce(p_followers,'{}'::uuid[]);
 IF cardinality(p_collaborators)>99 OR cardinality(p_followers)>100 OR (p_primary IS NULL AND cardinality(p_collaborators)>0) THEN RAISE EXCEPTION 'Selecciona un responsable principal para los colaboradores'; END IF;
 executors:=CASE WHEN p_primary IS NULL THEN '{}'::uuid[] ELSE ARRAY[p_primary]||p_collaborators END;
 IF cardinality(executors)<>(SELECT count(DISTINCT id) FROM unnest(executors)u(id)) OR cardinality(p_followers)<>(SELECT count(DISTINCT id) FROM unnest(p_followers)u(id)) OR executors&&p_followers THEN RAISE EXCEPTION 'Una persona no puede repetir ni tener dos funciones en la misma tarea'; END IF;
 IF EXISTS(SELECT 1 FROM unnest(executors||p_followers)u(id) WHERE id IS NULL OR NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles e WHERE e.id=u.id AND e.is_admin IS FALSE AND e.membership_status='active')) THEN RAISE EXCEPTION 'Selecciona empleados activos'; END IF;
 IF p_action='edit' THEN
  SELECT string_agg(coalesce(e.full_name,'Empleado'),', ' ORDER BY e.full_name) INTO blocked_names FROM public.task_assignments a LEFT JOIN ase_private.employee_profiles e ON e.id=a.user_id WHERE a.organization_id=org AND a.task_id=p_id AND NOT(a.user_id=ANY(executors)) AND EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.organization_id=org AND p.task_id=p_id AND p.user_id=a.user_id AND p.state IN('pending','active','blocked'));
  IF blocked_names IS NOT NULL THEN RAISE EXCEPTION 'No puedes retirar a %: tiene planificación pendiente, activa o bloqueada',blocked_names; END IF;
 END IF;
 result:=public.work_manage_task_importance(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,executors);
 UPDATE public.task_assignments SET responsibility_role=CASE WHEN user_id=p_primary THEN 'primary' ELSE 'collaborator' END WHERE organization_id=org AND task_id=result;
 DELETE FROM public.work_task_followers WHERE organization_id=org AND task_id=result AND NOT(user_id=ANY(p_followers));
 INSERT INTO public.work_task_followers(organization_id,task_id,user_id) SELECT org,result,u.id FROM unnest(p_followers)u(id) ON CONFLICT DO NOTHING;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_task_catalog() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('tasks.view');
 SELECT coalesce(jsonb_agg(to_jsonb(t)||jsonb_build_object(
  'assigned_users',coalesce((SELECT jsonb_agg(jsonb_build_object('id',u.id,'full_name',u.full_name,'role',a.responsibility_role) ORDER BY (a.responsibility_role='primary') DESC,u.full_name,u.id) FROM public.task_assignments a JOIN ase_private.employee_profiles u ON u.id=a.user_id WHERE a.organization_id=t.organization_id AND a.task_id=t.id),'[]'::jsonb),
  'followers',coalesce((SELECT jsonb_agg(jsonb_build_object('id',u.id,'full_name',u.full_name) ORDER BY u.full_name,u.id) FROM public.work_task_followers f JOIN ase_private.employee_profiles u ON u.id=f.user_id WHERE f.organization_id=t.organization_id AND f.task_id=t.id),'[]'::jsonb)
 ) ORDER BY t.created_at DESC,t.id),'[]'::jsonb) INTO result FROM public.tasks t WHERE t.organization_id=ase_private.current_org();RETURN result;END $$;

CREATE OR REPLACE FUNCTION public.work_share_task_access(p_task uuid,p_users uuid[],p_expires_days integer DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();code text;expires_at timestamptz;blocked_names text;BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_task IS NULL OR NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=org AND id=p_task FOR KEY SHARE) THEN RAISE EXCEPTION 'La tarea ya no existe';END IF;
 IF p_users IS NULL OR cardinality(p_users)<1 OR cardinality(p_users)>100 OR cardinality(p_users)<>(SELECT count(DISTINCT id)FROM unnest(p_users)u(id)) OR EXISTS(SELECT 1 FROM unnest(p_users)u(id)WHERE id IS NULL OR NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles e WHERE e.id=u.id AND e.is_admin IS FALSE AND e.membership_status='active'))THEN RAISE EXCEPTION 'Selecciona al menos un empleado activo';END IF;
 IF p_expires_days IS NOT NULL AND p_expires_days NOT IN(1,7,30,90)THEN RAISE EXCEPTION 'Caducidad no válida';END IF;
 SELECT string_agg(coalesce(e.full_name,'Empleado'),', ' ORDER BY e.full_name)INTO blocked_names FROM public.task_assignments a LEFT JOIN ase_private.employee_profiles e ON e.id=a.user_id WHERE a.organization_id=org AND a.task_id=p_task AND NOT(a.user_id=ANY(p_users))AND EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.organization_id=org AND p.task_id=p_task AND p.user_id=a.user_id AND p.state IN('pending','active','blocked'));
 IF blocked_names IS NOT NULL THEN RAISE EXCEPTION 'No puedes retirar a %: tiene planificación pendiente, activa o bloqueada',blocked_names;END IF;
 DELETE FROM public.task_assignments a WHERE a.organization_id=org AND a.task_id=p_task AND NOT(a.user_id=ANY(p_users));
 INSERT INTO public.task_assignments(organization_id,task_id,user_id,responsibility_role)SELECT org,p_task,u.id,'collaborator' FROM unnest(p_users)u(id)WHERE NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=org AND a.task_id=p_task AND a.user_id=u.id);
 IF NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=org AND task_id=p_task AND responsibility_role='primary')THEN UPDATE public.task_assignments SET responsibility_role='primary' WHERE organization_id=org AND task_id=p_task AND user_id=(SELECT min(user_id)FROM public.task_assignments WHERE organization_id=org AND task_id=p_task);END IF;
 code:='TASK-'||upper(replace(gen_random_uuid()::text,'-',''));expires_at:=CASE WHEN p_expires_days IS NULL THEN NULL ELSE clock_timestamp()+make_interval(days=>p_expires_days)END;
 INSERT INTO public.task_access_codes(organization_id,id,task_id,access_code,created_by,created_at,is_active,expires_at)VALUES(org,gen_random_uuid(),p_task,code,ase_private.session_user_id(),clock_timestamp(),true,expires_at);
 RETURN jsonb_build_object('code',code,'expires_at',expires_at,'assigned',cardinality(p_users));END $$;

GRANT CREATE ON SCHEMA ase_private TO ase_tenant_executor;
SET LOCAL ROLE ase_tenant_executor;
CREATE OR REPLACE FUNCTION ase_private.notify_task_follower() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)VALUES(NEW.organization_id,NEW.user_id,NULL,'Ahora sigues la tarea: '||coalesce((SELECT title FROM public.tasks WHERE organization_id=NEW.organization_id AND id=NEW.task_id),'Tarea'),'assignment','follower:'||NEW.task_id::text||':'||NEW.user_id::text||':'||txid_current()::text)ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;RETURN NEW;END $$;
CREATE OR REPLACE FUNCTION ase_private.notify_follower_importance_change() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid;task_title text;label text;BEGIN SELECT title INTO task_title FROM public.tasks WHERE organization_id=NEW.organization_id AND id=NEW.task_id;label:=CASE NEW.current_value WHEN 'urgent'THEN'Urgente' WHEN'high'THEN'Alta' WHEN'low'THEN'Baja' ELSE'Normal'END;
 FOR recipient IN SELECT user_id FROM public.work_task_followers WHERE organization_id=NEW.organization_id AND task_id=NEW.task_id LOOP INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)VALUES(NEW.organization_id,recipient,NULL,'Importancia actualizada: '||coalesce(task_title,'Tarea')||' · '||label,'importance','importance:'||NEW.id::text||':'||recipient::text)ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;END LOOP;RETURN NEW;END $$;
CREATE OR REPLACE FUNCTION ase_private.notify_follower_schedule_change() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid;task uuid;task_title text;schedule_label text;BEGIN SELECT p.task_id,t.title INTO task,task_title FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=NEW.organization_id AND p.id=NEW.plan_id;schedule_label:=CASE NEW.current_value->>'schedule_kind' WHEN'window'THEN'ventana de ejecución' WHEN'deadline'THEN'fecha límite' WHEN'scheduled'THEN'fecha programada' WHEN'period'THEN'período planificado' ELSE'sin fecha'END;
 FOR recipient IN SELECT user_id FROM public.work_task_followers WHERE organization_id=NEW.organization_id AND task_id=task LOOP INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)VALUES(NEW.organization_id,recipient,NULL,'Planificación actualizada: '||coalesce(task_title,'Tarea')||' · '||schedule_label,'schedule','schedule:'||NEW.id::text||':'||recipient::text)ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;END LOOP;RETURN NEW;END $$;
RESET ROLE;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_trigger WHERE tgname='work_notify_task_follower' AND tgrelid='public.work_task_followers'::regclass)THEN CREATE TRIGGER work_notify_task_follower AFTER INSERT ON public.work_task_followers FOR EACH ROW EXECUTE FUNCTION ase_private.notify_task_follower();END IF;END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_trigger WHERE tgname='work_notify_follower_importance' AND tgrelid='public.work_importance_events'::regclass)THEN CREATE TRIGGER work_notify_follower_importance AFTER INSERT ON public.work_importance_events FOR EACH ROW EXECUTE FUNCTION ase_private.notify_follower_importance_change();END IF;END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_trigger WHERE tgname='work_notify_follower_schedule' AND tgrelid='public.work_execution_schedule_events'::regclass)THEN CREATE TRIGGER work_notify_follower_schedule AFTER INSERT ON public.work_execution_schedule_events FOR EACH ROW EXECUTE FUNCTION ase_private.notify_follower_schedule_change();END IF;END $$;
SET LOCAL ROLE ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.notify_task_follower(),ase_private.notify_follower_importance_change(),ase_private.notify_follower_schedule_change() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.notify_task_follower(),ase_private.notify_follower_importance_change(),ase_private.notify_follower_schedule_change() TO ase_tenant_executor;
RESET ROLE;
REVOKE CREATE ON SCHEMA ase_private FROM ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_task_timeline(p_task uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=ase_private.current_org() AND id=p_task) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF NOT(public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id()) OR EXISTS(SELECT 1 FROM public.work_task_followers WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes consultar esta tarea'; END IF;
 WITH events AS (
  SELECT 'created:'||t.id::text id,'created' kind,'Tarea creada' title,t.title detail,'Sistema' actor_name,t.created_at FROM public.tasks t WHERE t.organization_id=ase_private.current_org() AND t.id=p_task
  UNION ALL SELECT 'assignment:'||e.id::text,'assignment_'||e.action,CASE e.action WHEN 'assigned' THEN 'Empleado asignado' ELSE 'Empleado retirado' END,e.employee_name,e.actor_name,e.created_at FROM public.work_task_assignment_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'importance:'||e.id::text,'importance','Importancia modificada',coalesce(CASE e.previous WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,'Creación')||' → '||CASE e.current_value WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,e.actor_name,e.created_at FROM public.work_importance_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'schedule:'||e.id::text,'schedule','Planificación modificada',CASE e.current_value->>'schedule_kind' WHEN 'anytime' THEN 'En cualquier momento' WHEN 'deadline' THEN 'Antes de una fecha' WHEN 'window' THEN 'Ventana de ejecución' WHEN 'scheduled' THEN 'Fecha u hora concreta' WHEN 'period' THEN 'Periodo planificado' ELSE 'Planificación actualizada' END,e.actor_name,e.created_at FROM public.work_execution_schedule_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
  UNION ALL SELECT 'state:'||e.id::text,'state','Estado modificado',CASE e.from_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' ELSE e.from_state END||' → '||CASE e.to_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' ELSE e.to_state END||' · '||e.reason,e.actor_name,e.created_at FROM public.work_board_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
 ),page AS(SELECT * FROM events ORDER BY created_at DESC,id DESC LIMIT 250) SELECT coalesce(jsonb_agg(to_jsonb(page) ORDER BY created_at DESC,id DESC),'[]'::jsonb) INTO result FROM page;RETURN result;END $$;

ALTER FUNCTION public.work_manage_task_roles(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[]) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_catalog() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_timeline(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_share_task_access(uuid,uuid[],integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_roles(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[]),public.work_task_catalog(),public.work_task_timeline(uuid),public.work_share_task_access(uuid,uuid[],integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_roles(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[]),public.work_task_catalog(),public.work_task_timeline(uuid),public.work_share_task_access(uuid,uuid[],integer) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025000300_required_evidence.sql ====
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS require_comment boolean NOT NULL DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS require_photo boolean NOT NULL DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS require_video boolean NOT NULL DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS require_file boolean NOT NULL DEFAULT false;
ALTER TABLE public.task_comments ADD COLUMN IF NOT EXISTS file_url text;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_manage_task_roles_evidence(
 p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,
 p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,
 p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],
 p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;
BEGIN
 result:=public.work_manage_task_roles(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers);
 UPDATE public.tasks SET require_comment=coalesce(p_require_comment,false),require_photo=coalesce(p_require_photo,false),
  require_video=coalesce(p_require_video,false),require_file=coalesce(p_require_file,false)
 WHERE organization_id=ase_private.current_org() AND id=result;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_checkin_evidence(p_checkin uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE c public.checkins%ROWTYPE;t public.tasks%ROWTYPE;result jsonb;
BEGIN
 SELECT * INTO c FROM public.checkins WHERE organization_id=ase_private.current_org() AND id=p_checkin;
 IF c.id IS NULL OR NOT(public.work_has_permission('tasks.view') OR c.user_id=ase_private.session_user_id()) THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible';
 END IF;
 SELECT * INTO t FROM public.tasks WHERE organization_id=c.organization_id AND id=c.task_id;
 SELECT jsonb_build_object(
  'required',jsonb_build_object('comment',t.require_comment,'photo',t.require_photo,'video',t.require_video,'file',t.require_file),
  'provided',jsonb_build_object(
   'comment',coalesce(bool_or(nullif(btrim(x.comment),'') IS NOT NULL),false),
   'photo',coalesce(bool_or(x.image_url IS NOT NULL),false),
   'video',coalesce(bool_or(x.video_url IS NOT NULL),false),
   'file',coalesce(bool_or(x.file_url IS NOT NULL),false))) INTO result
 FROM public.task_comments x WHERE x.organization_id=c.organization_id AND x.task_id=c.task_id AND x.user_id=c.user_id AND x.created_at>=c.checkin_time;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_require_evidence_on_close() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE required_row public.tasks%ROWTYPE;has_comment boolean;has_photo boolean;has_video boolean;has_file boolean;missing text[]:='{}'::text[];
BEGIN
 IF OLD.checkout_time IS NOT NULL OR NEW.checkout_time IS NULL THEN RETURN NEW;END IF;
 -- Un bloqueo detiene el contador, pero no completa el trabajo y no exige evidencias finales.
 IF NEW.work_plan_id IS NOT NULL AND EXISTS(SELECT 1 FROM public.work_incidents i WHERE i.organization_id=NEW.organization_id AND i.plan_id=NEW.work_plan_id AND i.blocks_work AND i.state<>'resolved') THEN RETURN NEW;END IF;
 SELECT * INTO required_row FROM public.tasks WHERE organization_id=NEW.organization_id AND id=NEW.task_id;
 SELECT coalesce(bool_or(nullif(btrim(x.comment),'') IS NOT NULL),false),coalesce(bool_or(x.image_url IS NOT NULL),false),coalesce(bool_or(x.video_url IS NOT NULL),false),coalesce(bool_or(x.file_url IS NOT NULL),false)
 INTO has_comment,has_photo,has_video,has_file FROM public.task_comments x WHERE x.organization_id=NEW.organization_id AND x.task_id=NEW.task_id AND x.user_id=NEW.user_id AND x.created_at>=NEW.checkin_time;
 IF required_row.require_comment AND NOT has_comment THEN missing:=array_append(missing,'comentario');END IF;
 IF required_row.require_photo AND NOT has_photo THEN missing:=array_append(missing,'foto');END IF;
 IF required_row.require_video AND NOT has_video THEN missing:=array_append(missing,'vídeo');END IF;
 IF required_row.require_file AND NOT has_file THEN missing:=array_append(missing,'archivo');END IF;
 IF cardinality(missing)>0 THEN RAISE EXCEPTION 'Antes de finalizar añade: %',array_to_string(missing,', ');END IF;
 RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS work_require_evidence_on_close ON public.checkins;
CREATE TRIGGER work_require_evidence_on_close BEFORE UPDATE OF checkout_time ON public.checkins
FOR EACH ROW EXECUTE FUNCTION public.work_require_evidence_on_close();

CREATE OR REPLACE FUNCTION public.sec04_validate_comment_attachment() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$
DECLARE v_ref text;v_actor uuid:=(SELECT auth.uid());v_prefix text;
BEGIN
 IF (SELECT auth.role()) IN('anon','authenticated') THEN
  IF v_actor IS NULL OR NEW.user_id IS DISTINCT FROM v_actor OR NEW.task_id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Comentario no autorizado';END IF;
  IF TG_OP='UPDATE' AND NEW.image_url IS NOT DISTINCT FROM OLD.image_url AND NEW.video_url IS NOT DISTINCT FROM OLD.video_url AND NEW.file_url IS NOT DISTINCT FROM OLD.file_url AND NEW.task_id IS NOT DISTINCT FROM OLD.task_id AND NEW.user_id IS NOT DISTINCT FROM OLD.user_id THEN RETURN NEW;END IF;
  v_prefix:='tasks/'||NEW.task_id::text||'/'||v_actor::text||'/';
  FOREACH v_ref IN ARRAY ARRAY[NEW.image_url,NEW.video_url,NEW.file_url] LOOP
   IF v_ref IS NOT NULL AND (left(v_ref,length(v_prefix))<>v_prefix OR v_ref !~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov|pdf|doc|docx|xls|xlsx|csv|txt)$') THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La referencia debe pertenecer a tu subida de esta tarea';END IF;
  END LOOP;
 END IF;RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_can_file(p_name text) RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE v_task uuid;
BEGIN
 IF NOT public.work_mode() OR public.sec06_is_admin() THEN RETURN true;END IF;
 IF p_name ~ '^tasks/[0-9a-f-]{36}/' THEN BEGIN v_task:=split_part(p_name,'/',2)::uuid;EXCEPTION WHEN invalid_text_representation THEN RETURN false;END;RETURN public.work_can_detail(v_task);END IF;
 RETURN EXISTS(SELECT 1 FROM public.task_comments c WHERE public.work_can_detail(c.task_id)
 AND (c.image_url=p_name OR c.video_url=p_name OR c.file_url=p_name OR split_part(c.image_url,'/storage/v1/object/public/task-files/',2)=p_name OR split_part(c.video_url,'/storage/v1/object/public/task-files/',2)=p_name OR split_part(c.file_url,'/storage/v1/object/public/task-files/',2)=p_name));
END $$;

DROP POLICY IF EXISTS task_files_insert ON storage.objects;
CREATE POLICY task_files_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK(
 bucket_id='task-files' AND name ~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov|pdf|doc|docx|xls|xlsx|csv|txt)$'
 AND split_part(name,'/',3)=ase_private.session_user_id()::text AND public.work_can_act(split_part(name,'/',2)::uuid));
DROP POLICY IF EXISTS incident_upload ON storage.objects;
CREATE POLICY incident_upload ON storage.objects FOR INSERT TO authenticated WITH CHECK(
 bucket_id='task-files' AND name ~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov|pdf|doc|docx|xls|xlsx|csv|txt)$'
 AND split_part(name,'/',3)=ase_private.session_user_id()::text AND public.work_incident_resolver(split_part(name,'/',2)::uuid));

ALTER FUNCTION public.work_manage_task_roles_evidence(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_checkin_evidence(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_require_evidence_on_close() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.sec04_validate_comment_attachment() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_can_file(text) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_roles_evidence(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean),public.work_checkin_evidence(uuid),public.work_require_evidence_on_close(),public.sec04_validate_comment_attachment(),public.work_can_file(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_roles_evidence(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean),public.work_checkin_evidence(uuid) TO authenticated,ase_tenant_executor;
GRANT EXECUTE ON FUNCTION public.work_require_evidence_on_close(),public.sec04_validate_comment_attachment(),public.work_can_file(text) TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025000400_task_time_estimates.sql ====
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS estimated_minutes integer;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='tasks_estimated_minutes_range' AND conrelid='public.tasks'::regclass) THEN ALTER TABLE public.tasks ADD CONSTRAINT tasks_estimated_minutes_range CHECK(estimated_minutes IS NULL OR estimated_minutes BETWEEN 1 AND 10080);END IF;END $$;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_manage_task_operational(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;BEGIN
 IF p_estimated_minutes IS NOT NULL AND p_estimated_minutes NOT BETWEEN 1 AND 10080 THEN RAISE EXCEPTION 'El tiempo estimado debe estar entre 1 minuto y 7 días';END IF;
 result:=public.work_manage_task_roles_evidence(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file);
 UPDATE public.tasks SET estimated_minutes=p_estimated_minutes WHERE organization_id=ase_private.current_org() AND id=result;
 RETURN result;
END $$;
CREATE OR REPLACE FUNCTION public.work_task_options() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN
 IF NOT(public.work_has_permission('tasks.view')OR public.work_has_permission('reports.view')OR public.work_has_permission('checkins.view'))THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso a las actividades';END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'title',title,'estimated_minutes',estimated_minutes)ORDER BY title,id),'[]'::jsonb)INTO result FROM public.tasks WHERE organization_id=ase_private.current_org();RETURN result;
END $$;
ALTER FUNCTION public.work_manage_task_operational(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_options() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_operational(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer),public.work_task_options() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_operational(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer),public.work_task_options() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025000500_task_review_approval.sql ====
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS requires_review boolean NOT NULL DEFAULT false;
ALTER TABLE public.work_day_plan DROP CONSTRAINT IF EXISTS work_day_plan_state_check;
ALTER TABLE public.work_day_plan ADD CONSTRAINT work_day_plan_state_check CHECK(state IN('pending','active','blocked','review','completed'));
CREATE TABLE IF NOT EXISTS public.work_review_events(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),id uuid NOT NULL DEFAULT gen_random_uuid(),plan_id uuid NOT NULL,actor_id uuid NOT NULL,
 decision text NOT NULL CHECK(decision IN('requested','approved','rejected')),reason text,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id),FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id)
);
ALTER TABLE public.work_review_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_review_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_review_events TO ase_tenant_executor;
DROP POLICY IF EXISTS review_events_executor ON public.work_review_events;
CREATE POLICY review_events_executor ON public.work_review_events TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_manage_task_review(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL,p_requires_review boolean DEFAULT false) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;BEGIN result:=public.work_manage_task_operational(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file,p_estimated_minutes);UPDATE public.tasks SET requires_review=coalesce(p_requires_review,false) WHERE organization_id=ase_private.current_org() AND id=result;RETURN result;END $$;
CREATE OR REPLACE FUNCTION public.work_route_completion_to_review() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN IF NEW.state='completed' AND OLD.state IS DISTINCT FROM 'completed' AND coalesce(current_setting('ase.review_approval',true),'off')<>'on' AND EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=NEW.organization_id AND t.id=NEW.task_id AND t.requires_review) THEN NEW.state:='review';END IF;RETURN NEW;END $$;
DROP TRIGGER IF EXISTS work_route_completion_to_review ON public.work_day_plan;
CREATE TRIGGER work_route_completion_to_review BEFORE UPDATE OF state ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION public.work_route_completion_to_review();
CREATE OR REPLACE FUNCTION public.work_record_review_request() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE admin_user uuid;title text;BEGIN IF NEW.state='review' AND OLD.state IS DISTINCT FROM 'review' THEN SELECT t.title INTO title FROM public.tasks t WHERE t.organization_id=NEW.organization_id AND t.id=NEW.task_id;INSERT INTO public.work_review_events(organization_id,plan_id,actor_id,decision,reason)VALUES(NEW.organization_id,NEW.id,NEW.user_id,'requested','Trabajo enviado para revisión');FOR admin_user IN SELECT id FROM ase_private.employee_profiles WHERE is_admin IS TRUE AND membership_status='active' LOOP INSERT INTO public.work_notifications(organization_id,user_id,message,kind,event_key)VALUES(NEW.organization_id,admin_user,'Revisión pendiente: '||coalesce(title,'Tarea'),'review_requested','review-requested:'||NEW.id::text||':'||NEW.board_version::text||':'||admin_user::text)ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;END LOOP;END IF;RETURN NEW;END $$;
DROP TRIGGER IF EXISTS work_record_review_request ON public.work_day_plan;
CREATE TRIGGER work_record_review_request AFTER UPDATE OF state ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION public.work_record_review_request();
CREATE OR REPLACE FUNCTION public.work_decide_review(p_plan uuid,p_decision text,p_reason text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;task_title text;stamp timestamptz:=clock_timestamp();BEGIN PERFORM public.work_assert_admin();IF p_decision NOT IN('approved','rejected')OR length(btrim(coalesce(p_reason,'')))NOT BETWEEN 5 AND 2000 THEN RAISE EXCEPTION 'Indica aprobar o devolver y un motivo de 5 a 2000 caracteres';END IF;SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan FOR UPDATE;IF p.id IS NULL OR p.state<>'review'THEN RAISE EXCEPTION 'La tarea ya no está pendiente de revisión';END IF;SELECT t.title INTO task_title FROM public.tasks t WHERE t.organization_id=p.organization_id AND t.id=p.task_id;IF p_decision='approved'THEN PERFORM set_config('ase.review_approval','on',true);UPDATE public.work_day_plan SET state='completed',finished_at=coalesce(finished_at,stamp) WHERE id=p.id;ELSE UPDATE public.work_day_plan SET state='pending',started_at=NULL,finished_at=NULL,board_reopened_at=stamp WHERE id=p.id;END IF;INSERT INTO public.work_review_events(organization_id,plan_id,actor_id,decision,reason)VALUES(p.organization_id,p.id,ase_private.session_user_id(),p_decision,btrim(p_reason));INSERT INTO public.work_notifications(organization_id,user_id,message,kind,event_key)VALUES(p.organization_id,p.user_id,CASE p_decision WHEN'approved'THEN'Trabajo aprobado: 'ELSE'Trabajo devuelto: 'END||coalesce(task_title,'Tarea')||' · '||left(btrim(p_reason),160),CASE p_decision WHEN'approved'THEN'review_approved'ELSE'review_rejected'END,'review-decision:'||p.id::text||':'||p.board_version::text)ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;RETURN jsonb_build_object('success',true,'state',CASE p_decision WHEN'approved'THEN'completed'ELSE'pending'END);END $$;
CREATE OR REPLACE FUNCTION public.work_review_queue() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('planning.view');SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'task_id',p.task_id,'title',t.title,'employee_id',p.user_id,'employee',coalesce(u.full_name,'Empleado no disponible'),'work_date',p.work_date,'finished_at',p.finished_at,'importance',t.importance,'estimated_minutes',t.estimated_minutes)ORDER BY p.finished_at,p.work_date,p.priority),'[]'::jsonb)INTO result FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org()AND p.state='review';RETURN result;END $$;
CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('planning.view');IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días';END IF;IF p_state IS NOT NULL AND p_state NOT IN('pending','active','blocked','review','completed')THEN RAISE EXCEPTION 'Estado no válido';END IF;IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida';END IF;WITH base AS(SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org()AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)AND(nullif(btrim(p_query),'')IS NULL OR concat_ws(' ',t.title,t.description,u.full_name)ILIKE'%'||btrim(p_query)||'%')),page AS(SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)SELECT jsonb_build_object('start',p_start,'end',p_end,'total',(SELECT count(*)FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object('pending',(SELECT count(*)FROM base WHERE state='pending'),'active',(SELECT count(*)FROM base WHERE state='active'),'blocked',(SELECT count(*)FROM base WHERE state='blocked'),'review',(SELECT count(*)FROM base WHERE state='review'),'completed',(SELECT count(*)FROM base WHERE state='completed')),'items',coalesce((SELECT jsonb_agg(to_jsonb(page)ORDER BY work_date,priority,employee,id)FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp())INTO result;RETURN result;END $$;
CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS(SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,p.state,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,(public.work_execution_eligibility(p.id)->>'can_start')::boolean eligible,public.work_incident_resolver(t.id)incident FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org()AND p.user_id=ase_private.session_user_id()AND p.state IN('pending','active','blocked','review','completed')AND(p.state='active'OR p.work_date BETWEEN public.work_today()-30 AND public.work_today()+365)),next_item AS(SELECT plan_id,task_id FROM items WHERE state='pending'AND eligible ORDER BY work_date,priority,plan_id LIMIT 1)SELECT jsonb_build_object('date',public.work_today(),'next_plan',(SELECT plan_id FROM next_item),'next_task',(SELECT task_id FROM next_item),'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',i.eligible AND(i.plan_id=(SELECT plan_id FROM next_item)OR i.incident),'can_finish',i.state='active')ORDER BY(i.state IN('completed','review')),(i.state='active')DESC,i.work_date,i.priority,i.plan_id)FROM items i),'[]'::jsonb)) $$;
ALTER FUNCTION public.work_manage_task_review(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_route_completion_to_review() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_record_review_request() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_decide_review(uuid,text,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_review_queue() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_queue() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_review(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean),public.work_route_completion_to_review(),public.work_record_review_request(),public.work_decide_review(uuid,text,text),public.work_review_queue(),public.work_planning_board_range(date,date,uuid,text,text,integer,integer),public.work_mobile_queue() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_review(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean),public.work_decide_review(uuid,text,text),public.work_review_queue(),public.work_planning_board_range(date,date,uuid,text,text,integer,integer),public.work_mobile_queue() TO authenticated,ase_tenant_executor;
GRANT EXECUTE ON FUNCTION public.work_route_completion_to_review(),public.work_record_review_request() TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025000600_task_cancellation.sql ====
-- ASE Work: cancel and reopen planned executions with an auditable reason.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

ALTER TABLE public.work_day_plan DROP CONSTRAINT IF EXISTS work_day_plan_state_check;
ALTER TABLE public.work_day_plan ADD CONSTRAINT work_day_plan_state_check CHECK(state IN('pending','active','blocked','review','completed','cancelled'));

CREATE OR REPLACE FUNCTION public.work_change_cancellation(p_plan uuid,p_action text,p_version bigint,p_reason text,p_request uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;e public.work_board_events%ROWTYPE;actor uuid:=ase_private.session_user_id();stamp timestamptz:=clock_timestamp();target text;version bigint;task_title text;
BEGIN
 PERFORM public.work_assert_admin();
 IF p_request IS NULL OR p_version IS NULL OR p_action NOT IN('cancel','reopen') OR length(btrim(coalesce(p_reason,''))) NOT BETWEEN 5 AND 2000 THEN RAISE EXCEPTION 'Indica cancelar o reabrir y un motivo de 5 a 2000 caracteres'; END IF;
 target:=CASE p_action WHEN 'cancel' THEN 'cancelled' ELSE 'pending' END;
 SELECT * INTO e FROM public.work_board_events WHERE organization_id=ase_private.current_org() AND id=p_request;
 IF FOUND THEN
  IF e.plan_id<>p_plan OR e.to_state<>target OR e.actor_id<>actor OR e.reason<>btrim(p_reason) THEN RAISE EXCEPTION 'Identificador de operación ya utilizado'; END IF;
  RETURN jsonb_build_object('success',true,'state',e.to_state,'version',e.applied_version,'repeated',true);
 END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan FOR UPDATE;
 IF NOT FOUND OR p.board_version<>p_version THEN RAISE EXCEPTION 'La tarjeta ha cambiado. Actualiza el tablero y vuelve a intentarlo'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=p.organization_id AND task_id=p.task_id AND user_id=p.user_id) THEN RAISE EXCEPTION 'La tarea ya no está asignada al empleado'; END IF;
 IF p_action='cancel' THEN
  IF p.state='cancelled' THEN RAISE EXCEPTION 'La ejecución ya está cancelada'; END IF;
  IF p.state IN('active','completed') THEN RAISE EXCEPTION 'Una ejecución en curso o completada no se cancela directamente'; END IF;
  IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=p.organization_id AND work_plan_id=p.id AND checkout_time IS NULL) THEN RAISE EXCEPTION 'Detén primero el fichaje activo'; END IF;
  UPDATE public.work_day_plan SET state='cancelled',finished_at=stamp WHERE organization_id=p.organization_id AND id=p.id;
 ELSE
  IF p.state<>'cancelled' THEN RAISE EXCEPTION 'Solo se puede reabrir una ejecución cancelada'; END IF;
  IF EXISTS(SELECT 1 FROM public.work_incidents WHERE organization_id=p.organization_id AND plan_id=p.id AND blocks_work AND state<>'resolved') THEN RAISE EXCEPTION 'Resuelve primero las incidencias que bloquean esta tarea'; END IF;
  UPDATE public.work_day_plan SET state='pending',started_at=NULL,finished_at=NULL,board_reopened_at=stamp WHERE organization_id=p.organization_id AND id=p.id;
 END IF;
 UPDATE public.work_station_tickets SET expires_at=stamp WHERE organization_id=p.organization_id AND plan_id=p.id AND result IS NULL;
 SELECT board_version INTO version FROM public.work_day_plan WHERE organization_id=p.organization_id AND id=p.id;
 INSERT INTO public.work_board_events(id,organization_id,plan_id,actor_id,actor_name,from_state,to_state,reason,applied_version)
 VALUES(p_request,p.organization_id,p.id,actor,coalesce((SELECT full_name FROM ase_private.employee_profiles WHERE id=actor),'Administrador'),p.state,target,btrim(p_reason),version);
 SELECT t.title INTO task_title FROM public.tasks t WHERE t.organization_id=p.organization_id AND t.id=p.task_id;
 INSERT INTO public.work_notifications(organization_id,user_id,message,kind,event_key)
 VALUES(p.organization_id,p.user_id,CASE p_action WHEN'cancel'THEN'Ejecución cancelada: 'ELSE'Ejecución reabierta: 'END||coalesce(task_title,'Tarea')||' · '||left(btrim(p_reason),160),CASE p_action WHEN'cancel'THEN'task_cancelled'ELSE'task_reopened'END,'cancellation:'||p_request::text)
 ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;
 RETURN jsonb_build_object('success',true,'state',target,'version',version);
END $$;

CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('planning.view');IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días';END IF;IF p_state IS NOT NULL AND p_state NOT IN('pending','active','blocked','review','completed','cancelled')THEN RAISE EXCEPTION 'Estado no válido';END IF;IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida';END IF;WITH base AS(SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org()AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)AND(nullif(btrim(p_query),'')IS NULL OR concat_ws(' ',t.title,t.description,u.full_name)ILIKE'%'||btrim(p_query)||'%')),page AS(SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)SELECT jsonb_build_object('start',p_start,'end',p_end,'total',(SELECT count(*)FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object('pending',(SELECT count(*)FROM base WHERE state='pending'),'active',(SELECT count(*)FROM base WHERE state='active'),'blocked',(SELECT count(*)FROM base WHERE state='blocked'),'review',(SELECT count(*)FROM base WHERE state='review'),'completed',(SELECT count(*)FROM base WHERE state='completed'),'cancelled',(SELECT count(*)FROM base WHERE state='cancelled')),'items',coalesce((SELECT jsonb_agg(to_jsonb(page)ORDER BY work_date,priority,employee,id)FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp())INTO result;RETURN result;END $$;

CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS(SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,p.state,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,(public.work_execution_eligibility(p.id)->>'can_start')::boolean eligible,public.work_incident_resolver(t.id)incident FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org()AND p.user_id=ase_private.session_user_id()AND p.state IN('pending','active','blocked','review','completed','cancelled')AND(p.state='active'OR p.work_date BETWEEN public.work_today()-30 AND public.work_today()+365)),next_item AS(SELECT plan_id,task_id FROM items WHERE state='pending'AND eligible ORDER BY work_date,priority,plan_id LIMIT 1)SELECT jsonb_build_object('date',public.work_today(),'next_plan',(SELECT plan_id FROM next_item),'next_task',(SELECT task_id FROM next_item),'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',i.eligible AND(i.plan_id=(SELECT plan_id FROM next_item)OR i.incident),'can_finish',i.state='active')ORDER BY(i.state IN('completed','review','cancelled')),(i.state='active')DESC,i.work_date,i.priority,i.plan_id)FROM items i),'[]'::jsonb)) $$;

ALTER FUNCTION public.work_change_cancellation(uuid,text,bigint,text,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_queue() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_change_cancellation(uuid,text,bigint,text,uuid),public.work_planning_board_range(date,date,uuid,text,text,integer,integer),public.work_mobile_queue() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_change_cancellation(uuid,text,bigint,text,uuid),public.work_planning_board_range(date,date,uuid,text,text,integer,integer),public.work_mobile_queue() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025000700_task_area_assignment.sql ====
-- ASE Work: assign a task to an area before choosing its responsible person.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_task_areas(
 organization_id uuid NOT NULL,task_id uuid NOT NULL,area_id uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,task_id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,area_id) REFERENCES public.work_areas(organization_id,id)
);
ALTER TABLE public.work_task_areas ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_areas FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_task_areas TO ase_tenant_executor;
DROP POLICY IF EXISTS task_areas_executor ON public.work_task_areas;
CREATE POLICY task_areas_executor ON public.work_task_areas TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

CREATE OR REPLACE FUNCTION public.work_manage_task_team(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL,p_requires_review boolean DEFAULT false,p_area uuid DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;org uuid:=ase_private.current_org();executors uuid[]:=CASE WHEN p_primary IS NULL THEN coalesce(p_collaborators,'{}'::uuid[]) ELSE ARRAY[p_primary]||coalesce(p_collaborators,'{}'::uuid[]) END;
BEGIN
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas WHERE organization_id=org AND id=p_area AND active) THEN RAISE EXCEPTION 'Selecciona un área activa'; END IF;
 IF p_area IS NOT NULL AND EXISTS(SELECT 1 FROM unnest(executors)u(id) WHERE NOT EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=org AND m.area_id=p_area AND m.user_id=u.id)) THEN RAISE EXCEPTION 'Responsable y colaboradores deben pertenecer al área seleccionada'; END IF;
 result:=public.work_manage_task_review(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file,p_estimated_minutes,p_requires_review);
 IF p_area IS NULL THEN DELETE FROM public.work_task_areas WHERE organization_id=org AND task_id=result;
 ELSE INSERT INTO public.work_task_areas(organization_id,task_id,area_id)VALUES(org,result,p_area)ON CONFLICT(organization_id,task_id)DO UPDATE SET area_id=excluded.area_id;END IF;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_task_catalog_team() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('tasks.view');
 SELECT coalesce(jsonb_agg(item||jsonb_build_object('area',coalesce((SELECT jsonb_build_object('id',a.id,'name',a.name)FROM public.work_task_areas x JOIN public.work_areas a ON a.organization_id=x.organization_id AND a.id=x.area_id WHERE x.organization_id=ase_private.current_org()AND x.task_id=(item->>'id')::uuid),'null'::jsonb)) ORDER BY item->>'created_at' DESC,item->>'id'),'[]'::jsonb)INTO result FROM jsonb_array_elements(public.work_task_catalog())item;
 RETURN result;
END $$;

ALTER FUNCTION public.work_manage_task_team(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_catalog_team() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_team(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid),public.work_task_catalog_team() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_team(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid),public.work_task_catalog_team() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025000800_state_reporting_consistency.sql ====
-- ASE Work: keep review and cancellation states visible in tabular reports.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_report_table_scope(p_kind text,p_start date,p_end date,p_search text,p_state text,p_method text,p_employee uuid,p_area uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 IF p_kind IS NULL OR p_kind NOT IN ('checkins','tasks','productivity','incidents','closures') OR p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR length(coalesce(p_search,''))>120 THEN RAISE EXCEPTION 'Selecciona un informe y un período de hasta 366 días'; END IF;
 IF p_employee IS NOT NULL AND p_area IS NOT NULL THEN RAISE EXCEPTION 'Selecciona un empleado o un área'; END IF;
 IF p_employee IS NOT NULL AND NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_employee) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas WHERE id=p_area AND active) THEN RAISE EXCEPTION 'Área no válida'; END IF;
 WITH source AS (
SELECT row FROM (SELECT jsonb_build_object('_at',c.checkin_time,'_state',CASE WHEN c.checkout_time IS NULL THEN 'open' ELSE 'closed' END,'_method',c.checkin_method,'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'start',c.checkin_time,'end',c.checkout_time,'minutes',round((extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)/60)::numeric,2),'method',c.checkin_method,'status',CASE WHEN c.checkout_time IS NULL THEN 'En curso' ELSE 'Cerrado' END) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id) dataset WHERE p_kind='checkins'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',(coalesce(p.work_date,t.schedule_date,(t.created_at AT TIME ZONE 'Europe/Madrid')::date)::timestamp AT TIME ZONE 'Europe/Madrid'),'_state',coalesce(p.state,'unplanned'),'_users',jsonb_build_array(a.user_id),'employee',u.full_name,'task',t.title,'date',coalesce(p.work_date,t.schedule_date),'priority',p.priority,'status',CASE p.state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'completed' THEN 'Completada' WHEN 'blocked' THEN 'Bloqueada' WHEN 'review' THEN 'En revisión' WHEN 'cancelled' THEN 'Cancelada' ELSE 'Sin planificación' END) row FROM public.tasks t LEFT JOIN public.task_assignments a ON a.task_id=t.id LEFT JOIN ase_private.employee_profiles u ON u.id=a.user_id LEFT JOIN public.work_day_plan p ON p.task_id=t.id AND p.user_id=a.user_id) dataset WHERE p_kind='tasks'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',((c.checkin_time AT TIME ZONE 'Europe/Madrid')::date::timestamp AT TIME ZONE 'Europe/Madrid'),'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'date',(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date,'count',count(*),'minutes',round(sum(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2),'average',round(avg(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2)) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id WHERE c.checkout_time>=c.checkin_time GROUP BY c.user_id,u.full_name,t.id,t.title,(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date) dataset WHERE p_kind='productivity'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',i.created_at,'_state',i.state,'_users',jsonb_build_array(i.reporter_id,i.assigned_user)||coalesce((SELECT jsonb_agg(m.user_id) FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id),'[]'::jsonb),'employee',u.full_name,'task',t.title,'subject',i.subject,'responsible',coalesce(a.name,v.full_name),'start',i.created_at,'updated',i.updated_at,'status',CASE i.state WHEN 'open' THEN 'Abierta' WHEN 'in_progress' THEN 'En atención' ELSE 'Resuelta' END,'blocked',CASE WHEN i.blocks_work THEN 'Sí' ELSE 'No' END,'resolution',i.resolution) row FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=i.reporter_id LEFT JOIN ase_private.employee_profiles v ON v.id=i.assigned_user LEFT JOIN public.work_areas a ON a.id=i.area_id) dataset WHERE p_kind='incidents'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',c.created_at,'_users',jsonb_build_array(p.user_id),'employee',u.full_name,'task',t.title,'actor',v.full_name,'start',c.created_at,'type',CASE c.kind WHEN 'admin_finish' THEN 'Cierre administrativo' ELSE 'Bloqueo por incidencia' END,'reason',c.reason) row FROM public.work_task_closures c JOIN public.work_day_plan p ON p.id=c.plan_id JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id LEFT JOIN ase_private.employee_profiles v ON v.id=c.actor_id) dataset WHERE p_kind='closures'
 ), filtered AS (
 SELECT row FROM source WHERE (row->>'_at')::timestamptz>=p_start::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (row->>'_at')::timestamptz<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (p_employee IS NULL OR row->'_users' @> jsonb_build_array(p_employee))
 AND (p_area IS NULL OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=p_area AND row->'_users' @> jsonb_build_array(m.user_id)))
 AND (p_state IS NULL OR row->>'_state'=p_state) AND (p_method IS NULL OR row->>'_method'=p_method)
 AND (coalesce(btrim(p_search),'')='' OR strpos(lower((row-'_at'-'_state'-'_method'-'_users')::text),lower(btrim(p_search)))>0)
 ), limited AS (SELECT row FROM filtered ORDER BY row->>'_at' DESC,row::text LIMIT 10001)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(row-'_at'-'_state'-'_method'-'_users') FROM limited),'[]'::jsonb),'as_of',now()) INTO result;
 IF (result->>'total')::integer>10000 THEN RAISE EXCEPTION 'Hay más de 10.000 filas. Reduce las fechas o utiliza el buscador antes de descargar'; END IF;
 RETURN result;
END $$;

ALTER FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025000900_pause_resume_execution.sql ====
-- ASE Work: pause and resume an execution without completing or blocking it.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

ALTER TABLE public.work_day_plan DROP CONSTRAINT IF EXISTS work_day_plan_state_check;
ALTER TABLE public.work_day_plan ADD CONSTRAINT work_day_plan_state_check CHECK(state IN('pending','active','paused','blocked','review','completed','cancelled'));

CREATE OR REPLACE FUNCTION public.work_mobile_plan_sync() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.work_plan_id IS NOT NULL THEN
  IF TG_OP='INSERT' THEN UPDATE public.work_day_plan SET state='active',started_at=coalesce(started_at,NEW.checkin_time),finished_at=NULL WHERE organization_id=NEW.organization_id AND id=NEW.work_plan_id AND user_id=NEW.user_id AND state IN('pending','paused');
  ELSIF OLD.checkout_time IS NULL AND NEW.checkout_time IS NOT NULL THEN
   UPDATE public.work_day_plan SET state=CASE WHEN coalesce(current_setting('ase.pause_execution',true),'off')='on' THEN 'paused' ELSE 'completed' END,finished_at=NEW.checkout_time WHERE organization_id=NEW.organization_id AND id=NEW.work_plan_id AND user_id=NEW.user_id AND state='active';
  END IF;
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_mobile_order_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb;incident uuid;queue jsonb;
BEGIN
 IF NEW.work_plan_id IS NULL AND NEW.location='Reanudación de ejecución' THEN RETURN NEW;END IF;
 IF coalesce(current_setting('ase.resume_execution',true),'off')='on' THEN RETURN NEW;END IF;
 IF public.work_mode() OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR public.sec06_is_admin() THEN RETURN NEW; END IF;
 IF NEW.user_id IS DISTINCT FROM ase_private.session_user_id() THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible'; END IF;
 PERFORM 1 FROM public.organization_memberships WHERE organization_id=ase_private.current_org() AND user_id=NEW.user_id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=NEW.organization_id AND user_id=NEW.user_id AND checkout_time IS NULL) THEN RAISE EXCEPTION 'Finaliza primero tu fichaje activo'; END IF;
 queue:=public.work_mobile_queue();
 SELECT x INTO item FROM jsonb_array_elements(queue->'items')x WHERE x->>'plan_id'=queue->>'next_plan'AND x->>'task_id'=NEW.task_id::text LIMIT 1;
 IF item IS NULL THEN SELECT x INTO item FROM jsonb_array_elements(queue->'items')x WHERE x->>'task_id'=NEW.task_id::text AND coalesce((x->>'incident')::boolean,false)ORDER BY(x->>'work_date')::date,(x->>'priority')::integer,x->>'plan_id'LIMIT 1;END IF;
 IF item IS NULL OR NOT coalesce((item->>'can_start')::boolean,false)THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Esta tarea está en consulta. Ficha en la siguiente ejecución según el orden del encargado';END IF;
 IF item->>'plan_id'=queue->>'next_plan'THEN NEW.work_plan_id:=(item->>'plan_id')::uuid;ELSE SELECT i.id INTO incident FROM public.work_incidents i WHERE i.organization_id=NEW.organization_id AND i.task_id=NEW.task_id AND i.state IN('open','in_progress')AND(i.assigned_user=NEW.user_id OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id AND m.user_id=NEW.user_id))ORDER BY i.created_at LIMIT 1;NEW.work_incident_id:=incident;END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_schedule_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE eligibility jsonb;BEGIN
 IF coalesce(current_setting('ase.resume_execution',true),'off')='on' THEN RETURN NEW;END IF;
 IF NEW.work_plan_id IS NULL THEN RETURN NEW;END IF;eligibility:=public.work_execution_eligibility(NEW.work_plan_id,coalesce(NEW.checkin_time,clock_timestamp()));IF NOT coalesce((eligibility->>'can_start')::boolean,false)THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE=CASE eligibility->>'reason' WHEN'too_early'THEN'Esta tarea todavía no está disponible'WHEN'overdue'THEN'La fecha límite ha pasado. Solicita al encargado que reprograme la tarea'WHEN'order'THEN'Respeta el orden de tareas del empleado'WHEN'open_checkin'THEN'El empleado ya tiene un fichaje activo'WHEN'assignment'THEN'La tarea ya no está asignada al empleado'ELSE'La tarea no puede iniciarse en este momento'END;END IF;RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_pause_execution(p_plan uuid,p_action text,p_reason text,p_request uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;c public.checkins%ROWTYPE;e public.work_board_events%ROWTYPE;actor uuid:=ase_private.session_user_id();stamp timestamptz:=clock_timestamp();target text;checkin uuid;version bigint;
BEGIN
 IF actor IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión';END IF;
 IF p_request IS NULL OR p_action NOT IN('pause','resume')OR length(btrim(coalesce(p_reason,'')))NOT BETWEEN 5 AND 500 THEN RAISE EXCEPTION 'Indica pausar o reanudar y un motivo de 5 a 500 caracteres';END IF;
 target:=CASE p_action WHEN'pause'THEN'paused'ELSE'active'END;
 SELECT * INTO e FROM public.work_board_events WHERE organization_id=ase_private.current_org()AND id=p_request;
 IF FOUND THEN IF e.plan_id<>p_plan OR e.to_state<>target OR e.actor_id<>actor OR e.reason<>btrim(p_reason)THEN RAISE EXCEPTION 'Identificador de operación ya utilizado';END IF;RETURN jsonb_build_object('success',true,'state',e.to_state,'version',e.applied_version,'repeated',true);END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org()AND id=p_plan FOR UPDATE;
 IF NOT FOUND OR (p.user_id<>actor AND NOT public.sec06_is_admin())THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes pausar esta ejecución';END IF;
 IF NOT public.sec06_is_admin()AND public.work_mode()THEN RAISE EXCEPTION 'Confirma esta acción en la tablet';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=p.organization_id AND task_id=p.task_id AND user_id=p.user_id)THEN RAISE EXCEPTION 'La tarea ya no está asignada al empleado';END IF;
 IF p_action='pause'THEN
  IF p.state<>'active'THEN RAISE EXCEPTION 'Solo se puede pausar una ejecución en curso';END IF;
  SELECT * INTO c FROM public.checkins WHERE organization_id=p.organization_id AND work_plan_id=p.id AND user_id=p.user_id AND checkout_time IS NULL FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'No se encontró el fichaje activo';END IF;
  PERFORM set_config('ase.pause_execution','on',true);UPDATE public.checkins SET checkout_time=stamp WHERE organization_id=c.organization_id AND id=c.id;checkin:=c.id;
 ELSE
  IF p.state<>'paused'THEN RAISE EXCEPTION 'Solo se puede reanudar una ejecución pausada';END IF;
  IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=p.organization_id AND user_id=p.user_id AND checkout_time IS NULL)THEN RAISE EXCEPTION 'Finaliza primero el otro fichaje activo';END IF;
  IF NOT coalesce((public.work_execution_timing(p.id,stamp)->>'can_start_time')::boolean,false)THEN RAISE EXCEPTION 'La ejecución no puede reanudarse fuera de su programación';END IF;
  PERFORM set_config('ase.resume_execution','on',true);
  INSERT INTO public.checkins(organization_id,task_id,user_id,checkin_time,checkin_method,location,work_plan_id)VALUES(p.organization_id,p.task_id,p.user_id,stamp,'manual','Reanudación de ejecución',NULL)RETURNING id INTO checkin;
  UPDATE public.checkins SET work_plan_id=p.id WHERE organization_id=p.organization_id AND id=checkin;
  UPDATE public.work_day_plan SET state='active',finished_at=NULL,board_reopened_at=stamp WHERE organization_id=p.organization_id AND id=p.id;
 END IF;
 SELECT board_version INTO version FROM public.work_day_plan WHERE organization_id=p.organization_id AND id=p.id;
 INSERT INTO public.work_board_events(id,organization_id,plan_id,actor_id,actor_name,from_state,to_state,reason,checkin_id,applied_version)VALUES(p_request,p.organization_id,p.id,actor,coalesce((SELECT full_name FROM ase_private.employee_profiles WHERE id=actor),'Empleado'),p.state,target,btrim(p_reason),checkin,version);
 RETURN jsonb_build_object('success',true,'state',target,'version',version,'checkin_id',checkin);
END $$;

CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('planning.view');IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días';END IF;IF p_state IS NOT NULL AND p_state NOT IN('pending','active','paused','blocked','review','completed','cancelled')THEN RAISE EXCEPTION 'Estado no válido';END IF;IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida';END IF;WITH base AS(SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org()AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)AND(nullif(btrim(p_query),'')IS NULL OR concat_ws(' ',t.title,t.description,u.full_name)ILIKE'%'||btrim(p_query)||'%')),page AS(SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)SELECT jsonb_build_object('start',p_start,'end',p_end,'total',(SELECT count(*)FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object('pending',(SELECT count(*)FROM base WHERE state='pending'),'active',(SELECT count(*)FROM base WHERE state='active'),'paused',(SELECT count(*)FROM base WHERE state='paused'),'blocked',(SELECT count(*)FROM base WHERE state='blocked'),'review',(SELECT count(*)FROM base WHERE state='review'),'completed',(SELECT count(*)FROM base WHERE state='completed'),'cancelled',(SELECT count(*)FROM base WHERE state='cancelled')),'items',coalesce((SELECT jsonb_agg(to_jsonb(page)ORDER BY work_date,priority,employee,id)FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp())INTO result;RETURN result;END $$;

CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS(SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,p.state,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,(public.work_execution_eligibility(p.id)->>'can_start')::boolean eligible,public.work_incident_resolver(t.id)incident FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org()AND p.user_id=ase_private.session_user_id()AND p.state IN('pending','active','paused','blocked','review','completed','cancelled')AND(p.state IN('active','paused')OR p.work_date BETWEEN public.work_today()-30 AND public.work_today()+365)),next_item AS(SELECT plan_id,task_id FROM items WHERE state='pending'AND eligible ORDER BY work_date,priority,plan_id LIMIT 1)SELECT jsonb_build_object('date',public.work_today(),'next_plan',(SELECT plan_id FROM next_item),'next_task',(SELECT task_id FROM next_item),'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',i.eligible AND(i.plan_id=(SELECT plan_id FROM next_item)OR i.incident),'can_resume',i.state='paused','can_finish',i.state='active')ORDER BY(i.state IN('completed','review','cancelled')),(i.state IN('active','paused'))DESC,i.work_date,i.priority,i.plan_id)FROM items i),'[]'::jsonb)) $$;

CREATE OR REPLACE FUNCTION public.work_my_day_v2() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=ase_private.session_user_id();items jsonb;BEGIN IF actor IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión';END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'task_id',p.task_id,'title',t.title,'state',p.state,'priority',p.priority,'work_date',p.work_date,'started_at',p.started_at,'finished_at',p.finished_at,'can_open',p.state IN('active','paused')AND public.work_can_detail(p.task_id))||public.work_deadline(p.work_date,p.state,p.finished_at)ORDER BY p.work_date,p.priority),'[]'::jsonb)INTO items FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org()AND p.user_id=actor AND(p.work_date=public.work_today()OR p.state IN('active','paused')OR(p.work_date<public.work_today()AND p.state='pending'))AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=p.organization_id AND a.task_id=p.task_id AND a.user_id=p.user_id);
 RETURN jsonb_build_object('date',public.work_today(),'items',items);
END $$;

-- Keep the new operational state visible and filterable in tabular reports.
CREATE OR REPLACE FUNCTION public.work_report_table_scope(p_kind text,p_start date,p_end date,p_search text,p_state text,p_method text,p_employee uuid,p_area uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 IF p_kind IS NULL OR p_kind NOT IN ('checkins','tasks','productivity','incidents','closures') OR p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR length(coalesce(p_search,''))>120 THEN RAISE EXCEPTION 'Selecciona un informe y un período de hasta 366 días'; END IF;
 IF p_employee IS NOT NULL AND p_area IS NOT NULL THEN RAISE EXCEPTION 'Selecciona un empleado o un área'; END IF;
 IF p_employee IS NOT NULL AND NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_employee) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas WHERE id=p_area AND active) THEN RAISE EXCEPTION 'Área no válida'; END IF;
 WITH source AS (
SELECT row FROM (SELECT jsonb_build_object('_at',c.checkin_time,'_state',CASE WHEN c.checkout_time IS NULL THEN 'open' ELSE 'closed' END,'_method',c.checkin_method,'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'start',c.checkin_time,'end',c.checkout_time,'minutes',round((extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)/60)::numeric,2),'method',c.checkin_method,'status',CASE WHEN c.checkout_time IS NULL THEN 'En curso' ELSE 'Cerrado' END) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id) dataset WHERE p_kind='checkins'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',(coalesce(p.work_date,t.schedule_date,(t.created_at AT TIME ZONE 'Europe/Madrid')::date)::timestamp AT TIME ZONE 'Europe/Madrid'),'_state',coalesce(p.state,'unplanned'),'_users',jsonb_build_array(a.user_id),'employee',u.full_name,'task',t.title,'date',coalesce(p.work_date,t.schedule_date),'priority',p.priority,'status',CASE p.state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'paused' THEN 'Pausada' WHEN 'completed' THEN 'Completada' WHEN 'blocked' THEN 'Bloqueada' WHEN 'review' THEN 'En revisión' WHEN 'cancelled' THEN 'Cancelada' ELSE 'Sin planificación' END) row FROM public.tasks t LEFT JOIN public.task_assignments a ON a.task_id=t.id LEFT JOIN ase_private.employee_profiles u ON u.id=a.user_id LEFT JOIN public.work_day_plan p ON p.task_id=t.id AND p.user_id=a.user_id) dataset WHERE p_kind='tasks'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',((c.checkin_time AT TIME ZONE 'Europe/Madrid')::date::timestamp AT TIME ZONE 'Europe/Madrid'),'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'date',(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date,'count',count(*),'minutes',round(sum(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2),'average',round(avg(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2)) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id WHERE c.checkout_time>=c.checkin_time GROUP BY c.user_id,u.full_name,t.id,t.title,(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date) dataset WHERE p_kind='productivity'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',i.created_at,'_state',i.state,'_users',jsonb_build_array(i.reporter_id,i.assigned_user)||coalesce((SELECT jsonb_agg(m.user_id) FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id),'[]'::jsonb),'employee',u.full_name,'task',t.title,'subject',i.subject,'responsible',coalesce(a.name,v.full_name),'start',i.created_at,'updated',i.updated_at,'status',CASE i.state WHEN 'open' THEN 'Abierta' WHEN 'in_progress' THEN 'En atención' ELSE 'Resuelta' END,'blocked',CASE WHEN i.blocks_work THEN 'Sí' ELSE 'No' END,'resolution',i.resolution) row FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=i.reporter_id LEFT JOIN ase_private.employee_profiles v ON v.id=i.assigned_user LEFT JOIN public.work_areas a ON a.id=i.area_id) dataset WHERE p_kind='incidents'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',c.created_at,'_users',jsonb_build_array(p.user_id),'employee',u.full_name,'task',t.title,'actor',v.full_name,'start',c.created_at,'type',CASE c.kind WHEN 'admin_finish' THEN 'Cierre administrativo' ELSE 'Bloqueo por incidencia' END,'reason',c.reason) row FROM public.work_task_closures c JOIN public.work_day_plan p ON p.id=c.plan_id JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id LEFT JOIN ase_private.employee_profiles v ON v.id=c.actor_id) dataset WHERE p_kind='closures'
 ), filtered AS (
 SELECT row FROM source WHERE (row->>'_at')::timestamptz>=p_start::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (row->>'_at')::timestamptz<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (p_employee IS NULL OR row->'_users' @> jsonb_build_array(p_employee))
 AND (p_area IS NULL OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=p_area AND row->'_users' @> jsonb_build_array(m.user_id)))
 AND (p_state IS NULL OR row->>'_state'=p_state) AND (p_method IS NULL OR row->>'_method'=p_method)
 AND (coalesce(btrim(p_search),'')='' OR strpos(lower((row-'_at'-'_state'-'_method'-'_users')::text),lower(btrim(p_search)))>0)
 ), limited AS (SELECT row FROM filtered ORDER BY row->>'_at' DESC,row::text LIMIT 10001)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(row-'_at'-'_state'-'_method'-'_users') FROM limited),'[]'::jsonb),'as_of',now()) INTO result;
 IF (result->>'total')::integer>10000 THEN RAISE EXCEPTION 'Hay más de 10.000 filas. Reduce las fechas o utiliza el buscador antes de descargar'; END IF;
 RETURN result;
END $$;

ALTER FUNCTION public.work_mobile_plan_sync() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_order_guard() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_guard() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_pause_execution(uuid,text,text,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_queue() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_my_day_v2() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_pause_execution(uuid,text,text,uuid),public.work_planning_board_range(date,date,uuid,text,text,integer,integer),public.work_mobile_queue(),public.work_my_day_v2(),public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_pause_execution(uuid,text,text,uuid),public.work_planning_board_range(date,date,uuid,text,text,integer,integer),public.work_mobile_queue(),public.work_my_day_v2(),public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) TO authenticated,ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_mobile_plan_sync(),public.work_mobile_order_guard(),public.work_execution_schedule_guard() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_mobile_plan_sync(),public.work_mobile_order_guard(),public.work_execution_schedule_guard() TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025001000_comment_notifications.sql ====
-- ASE Work: notify the task team when a new contextual comment is added.

GRANT CREATE ON SCHEMA ase_private TO ase_tenant_executor;
SET LOCAL ROLE ase_tenant_executor;

CREATE OR REPLACE FUNCTION ase_private.notify_task_comment() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid;task_title text;actor_name text;
BEGIN
 SELECT title INTO task_title FROM public.tasks WHERE organization_id=NEW.organization_id AND id=NEW.task_id;
 SELECT full_name INTO actor_name FROM public.organization_memberships WHERE organization_id=NEW.organization_id AND user_id=NEW.user_id;
 FOR recipient IN
  SELECT user_id FROM public.task_assignments WHERE organization_id=NEW.organization_id AND task_id=NEW.task_id AND user_id<>NEW.user_id
  UNION
  SELECT user_id FROM public.work_task_followers WHERE organization_id=NEW.organization_id AND task_id=NEW.task_id AND user_id<>NEW.user_id
 LOOP
  INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)
  VALUES(NEW.organization_id,recipient,NULL,'Nuevo comentario en: '||coalesce(task_title,'Tarea')||' · '||coalesce(actor_name,'Empleado'),'comment','comment:'||NEW.id::text||':'||recipient::text)
  ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;
 END LOOP;
 RETURN NEW;
END $$;

RESET ROLE;
DROP TRIGGER IF EXISTS work_notify_task_comment ON public.task_comments;
CREATE TRIGGER work_notify_task_comment AFTER INSERT ON public.task_comments FOR EACH ROW EXECUTE FUNCTION ase_private.notify_task_comment();
ALTER FUNCTION ase_private.notify_task_comment() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.notify_task_comment() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.notify_task_comment() TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA ase_private FROM ase_tenant_executor;

-- ==== 20261025001100_comment_mentions.sql ====
-- ASE Work: explicit, auditable mentions inside task comments.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_comment_mentions(
 organization_id uuid NOT NULL,comment_id uuid NOT NULL,task_id uuid NOT NULL,user_id uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,comment_id,user_id),
 FOREIGN KEY(comment_id) REFERENCES public.task_comments(id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id) ON DELETE CASCADE
);
ALTER TABLE public.work_comment_mentions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_comment_mentions FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_comment_mentions TO ase_tenant_executor;
DROP POLICY IF EXISTS comment_mentions_executor ON public.work_comment_mentions;
CREATE POLICY comment_mentions_executor ON public.work_comment_mentions TO ase_tenant_executor USING(organization_id=ase_private.current_org())WITH CHECK(organization_id=ase_private.current_org());

CREATE OR REPLACE FUNCTION public.sec04_validate_comment_attachment() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$
DECLARE v_ref text;v_actor uuid:=ase_private.session_user_id();v_prefix text;
BEGIN
 IF ase_private.session_role()IN('anon','authenticated')THEN
  IF v_actor IS NULL OR NEW.user_id IS DISTINCT FROM v_actor OR NEW.task_id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Comentario no autorizado';END IF;
  IF TG_OP='UPDATE'AND NEW.image_url IS NOT DISTINCT FROM OLD.image_url AND NEW.video_url IS NOT DISTINCT FROM OLD.video_url AND NEW.file_url IS NOT DISTINCT FROM OLD.file_url AND NEW.task_id IS NOT DISTINCT FROM OLD.task_id AND NEW.user_id IS NOT DISTINCT FROM OLD.user_id THEN RETURN NEW;END IF;
  v_prefix:='tasks/'||NEW.task_id::text||'/'||v_actor::text||'/';
  FOREACH v_ref IN ARRAY ARRAY[NEW.image_url,NEW.video_url,NEW.file_url]LOOP
   IF v_ref IS NOT NULL AND(left(v_ref,length(v_prefix))<>v_prefix OR v_ref!~'^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov|pdf|doc|docx|xls|xlsx|csv|txt)$')THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La referencia debe pertenecer a tu subida de esta tarea';END IF;
  END LOOP;
 END IF;RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_comment_recipients(p_task uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;actor uuid:=ase_private.session_user_id();
BEGIN
 IF actor IS NULL OR NOT public.work_can_detail(p_task) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes consultar esta tarea';END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',x.user_id,'name',x.full_name,'role',x.role)ORDER BY x.role,x.full_name,x.user_id),'[]'::jsonb)INTO result FROM(
  SELECT a.user_id,m.full_name,CASE a.responsibility_role WHEN'primary'THEN'Responsable'ELSE'Colaborador'END role FROM public.task_assignments a JOIN public.organization_memberships m ON m.organization_id=a.organization_id AND m.user_id=a.user_id WHERE a.organization_id=ase_private.current_org()AND a.task_id=p_task AND a.user_id<>actor
  UNION ALL
  SELECT f.user_id,m.full_name,'Seguidor' FROM public.work_task_followers f JOIN public.organization_memberships m ON m.organization_id=f.organization_id AND m.user_id=f.user_id WHERE f.organization_id=ase_private.current_org()AND f.task_id=p_task AND f.user_id<>actor
 )x;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_add_task_comment(p_task uuid,p_comment text,p_image text DEFAULT NULL,p_video text DEFAULT NULL,p_file text DEFAULT NULL,p_mentions uuid[] DEFAULT '{}'::uuid[]) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=ase_private.session_user_id();org uuid:=ase_private.current_org();comment_id uuid;recipient uuid;task_title text;actor_name text;
BEGIN
 p_mentions:=coalesce(p_mentions,'{}'::uuid[]);
 IF actor IS NULL OR p_task IS NULL OR length(btrim(coalesce(p_comment,'')))NOT BETWEEN 1 AND 5000 THEN RAISE EXCEPTION 'Escribe un comentario de hasta 5.000 caracteres';END IF;
 IF cardinality(p_mentions)>20 OR cardinality(p_mentions)<>(SELECT count(DISTINCT id)FROM unnest(p_mentions)u(id)) OR actor=ANY(p_mentions)THEN RAISE EXCEPTION 'Selecciona menciones válidas sin repetirte';END IF;
 IF EXISTS(SELECT 1 FROM unnest(p_mentions)u(id)WHERE NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=org AND a.task_id=p_task AND a.user_id=u.id UNION ALL SELECT 1 FROM public.work_task_followers f WHERE f.organization_id=org AND f.task_id=p_task AND f.user_id=u.id))THEN RAISE EXCEPTION 'Solo puedes mencionar al equipo de la tarea';END IF;
 INSERT INTO public.task_comments(organization_id,task_id,user_id,comment,image_url,video_url,file_url)VALUES(org,p_task,actor,btrim(p_comment),p_image,p_video,p_file)RETURNING id INTO comment_id;
 INSERT INTO public.work_comment_mentions(organization_id,comment_id,task_id,user_id)SELECT org,comment_id,p_task,u.id FROM unnest(p_mentions)u(id);
 SELECT title INTO task_title FROM public.tasks WHERE organization_id=org AND id=p_task;SELECT full_name INTO actor_name FROM public.organization_memberships WHERE organization_id=org AND user_id=actor;
 FOREACH recipient IN ARRAY p_mentions LOOP
  UPDATE public.work_notifications SET kind='mention',message='Te mencionaron en: '||coalesce(task_title,'Tarea')||' · '||coalesce(actor_name,'Empleado') WHERE organization_id=org AND user_id=recipient AND event_key='comment:'||comment_id::text||':'||recipient::text;
 END LOOP;
 RETURN comment_id;
END $$;

ALTER FUNCTION public.work_comment_recipients(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_add_task_comment(uuid,text,text,text,text,uuid[]) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.sec04_validate_comment_attachment() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_comment_recipients(uuid),public.work_add_task_comment(uuid,text,text,text,text,uuid[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_comment_recipients(uuid),public.work_add_task_comment(uuid,text,text,text,text,uuid[]) TO authenticated,ase_tenant_executor;
REVOKE ALL ON FUNCTION public.sec04_validate_comment_attachment() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.sec04_validate_comment_attachment() TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025001200_task_labels.sql ====
-- ASE Work: flexible task labels for classification and search.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_task_labels(
 organization_id uuid NOT NULL,task_id uuid NOT NULL,label text NOT NULL,normalized text NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,task_id,normalized),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 CHECK(length(label)BETWEEN 1 AND 40),CHECK(length(normalized)BETWEEN 1 AND 40)
);
ALTER TABLE public.work_task_labels ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_labels FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_task_labels TO ase_tenant_executor;
DROP POLICY IF EXISTS task_labels_executor ON public.work_task_labels;
CREATE POLICY task_labels_executor ON public.work_task_labels TO ase_tenant_executor USING(organization_id=ase_private.current_org())WITH CHECK(organization_id=ase_private.current_org());

CREATE OR REPLACE FUNCTION public.work_manage_task_labeled(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL,p_requires_review boolean DEFAULT false,p_area uuid DEFAULT NULL,p_labels text[] DEFAULT '{}'::text[]) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;org uuid:=ase_private.current_org();raw text;clean text;normal text;clean_labels text[]:='{}'::text[];normal_labels text[]:='{}'::text[];
BEGIN
 IF cardinality(coalesce(p_labels,'{}'::text[]))>10 THEN RAISE EXCEPTION 'Añade como máximo 10 etiquetas';END IF;
 FOREACH raw IN ARRAY coalesce(p_labels,'{}'::text[])LOOP
  clean:=regexp_replace(btrim(coalesce(raw,'')),'\s+',' ','g');normal:=lower(clean);
  IF length(clean)NOT BETWEEN 1 AND 40 THEN RAISE EXCEPTION 'Cada etiqueta debe tener entre 1 y 40 caracteres';END IF;
  IF normal=ANY(normal_labels)THEN RAISE EXCEPTION 'No repitas etiquetas';END IF;
  clean_labels:=array_append(clean_labels,clean);normal_labels:=array_append(normal_labels,normal);
 END LOOP;
 result:=public.work_manage_task_team(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file,p_estimated_minutes,p_requires_review,p_area);
 DELETE FROM public.work_task_labels l WHERE l.organization_id=org AND l.task_id=result AND NOT(l.normalized=ANY(normal_labels));
 INSERT INTO public.work_task_labels(organization_id,task_id,label,normalized)SELECT org,result,clean_labels[i],normal_labels[i]FROM generate_subscripts(clean_labels,1)i ON CONFLICT(organization_id,task_id,normalized)DO UPDATE SET label=excluded.label;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_task_catalog_labeled() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN
 SELECT coalesce(jsonb_agg(item||jsonb_build_object('labels',coalesce((SELECT jsonb_agg(l.label ORDER BY l.label,l.normalized)FROM public.work_task_labels l WHERE l.organization_id=ase_private.current_org()AND l.task_id=(item->>'id')::uuid),'[]'::jsonb))ORDER BY item->>'created_at'DESC,item->>'id'),'[]'::jsonb)INTO result FROM jsonb_array_elements(public.work_task_catalog_team())item;
 RETURN result;
END $$;

ALTER FUNCTION public.work_manage_task_labeled(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[]) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_catalog_labeled() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_labeled(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[]),public.work_task_catalog_labeled() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_labeled(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[]),public.work_task_catalog_labeled() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025001300_task_context.sql ====
-- ASE Work: operational location and generic ERP origin for tasks.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS source_module text;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS related_entity_type text;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS related_entity_reference text;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS related_entity_label text;

DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='tasks_source_module_length' AND conrelid='public.tasks'::regclass)THEN ALTER TABLE public.tasks ADD CONSTRAINT tasks_source_module_length CHECK(source_module IS NULL OR length(source_module)BETWEEN 1 AND 60);END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='tasks_related_type_length' AND conrelid='public.tasks'::regclass)THEN ALTER TABLE public.tasks ADD CONSTRAINT tasks_related_type_length CHECK(related_entity_type IS NULL OR length(related_entity_type)BETWEEN 1 AND 60);END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='tasks_related_reference_length' AND conrelid='public.tasks'::regclass)THEN ALTER TABLE public.tasks ADD CONSTRAINT tasks_related_reference_length CHECK(related_entity_reference IS NULL OR length(related_entity_reference)BETWEEN 1 AND 120);END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='tasks_related_label_length' AND conrelid='public.tasks'::regclass)THEN ALTER TABLE public.tasks ADD CONSTRAINT tasks_related_label_length CHECK(related_entity_label IS NULL OR length(related_entity_label)BETWEEN 1 AND 160);END IF;
END $$;

CREATE OR REPLACE FUNCTION public.work_manage_task_context(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL,p_requires_review boolean DEFAULT false,p_area uuid DEFAULT NULL,p_labels text[] DEFAULT '{}'::text[],p_location text DEFAULT NULL,p_source_module text DEFAULT NULL,p_entity_type text DEFAULT NULL,p_entity_reference text DEFAULT NULL,p_entity_label text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;clean_location text:=nullif(btrim(coalesce(p_location,'')),'');clean_source text:=nullif(btrim(coalesce(p_source_module,'')),'');clean_type text:=nullif(btrim(coalesce(p_entity_type,'')),'');clean_reference text:=nullif(btrim(coalesce(p_entity_reference,'')),'');clean_label text:=nullif(btrim(coalesce(p_entity_label,'')),'');
BEGIN
 IF length(coalesce(clean_location,''))>200 THEN RAISE EXCEPTION 'La ubicación no puede superar 200 caracteres';END IF;
 IF length(coalesce(clean_source,''))>60 OR length(coalesce(clean_type,''))>60 OR length(coalesce(clean_reference,''))>120 OR length(coalesce(clean_label,''))>160 THEN RAISE EXCEPTION 'El contexto relacionado es demasiado largo';END IF;
 IF (clean_type IS NULL)<>(clean_reference IS NULL)THEN RAISE EXCEPTION 'Indica el tipo y la referencia de la entidad relacionada';END IF;
 result:=public.work_manage_task_labeled(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file,p_estimated_minutes,p_requires_review,p_area,p_labels);
 UPDATE public.tasks SET location=clean_location,source_module=clean_source,related_entity_type=clean_type,related_entity_reference=clean_reference,related_entity_label=clean_label WHERE organization_id=ase_private.current_org()AND id=result;
 RETURN result;
END $$;

ALTER FUNCTION public.work_manage_task_context(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_context(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_context(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025001400_execution_results.sql ====
-- ASE Work: execution-specific result summary shared by mobile, NFC and station flows.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS result_summary text;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS result_updated_at timestamptz;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS result_updated_by uuid;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='work_plan_result_length' AND conrelid='public.work_day_plan'::regclass)THEN ALTER TABLE public.work_day_plan ADD CONSTRAINT work_plan_result_length CHECK(result_summary IS NULL OR length(result_summary)BETWEEN 3 AND 4000);END IF;END $$;

CREATE OR REPLACE FUNCTION public.work_save_execution_result(p_plan uuid,p_result text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;actor uuid:=ase_private.session_user_id();clean text:=nullif(btrim(coalesce(p_result,'')),'');BEGIN
 IF actor IS NULL OR clean IS NULL OR length(clean)NOT BETWEEN 3 AND 4000 THEN RAISE EXCEPTION 'Escribe un resultado de 3 a 4000 caracteres';END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org()AND id=p_plan FOR UPDATE;
 IF p.id IS NULL OR NOT(actor=p.user_id OR EXISTS(SELECT 1 FROM ase_private.employee_profiles e WHERE e.id=actor AND e.is_admin IS TRUE))THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes registrar el resultado de esta ejecución';END IF;
 IF p.state NOT IN('active','paused','review','completed')THEN RAISE EXCEPTION 'El resultado solo se registra durante o después de la ejecución';END IF;
 UPDATE public.work_day_plan SET result_summary=clean,result_updated_at=clock_timestamp(),result_updated_by=actor WHERE id=p.id;
 RETURN jsonb_build_object('success',true,'plan_id',p.id,'result',clean);
END $$;

CREATE OR REPLACE FUNCTION public.work_station_save_result(p_station text,p_ticket uuid,p_result text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.work_stations%ROWTYPE;k public.work_station_tickets%ROWTYPE;p public.work_day_plan%ROWTYPE;clean text:=nullif(btrim(coalesce(p_result,'')),'');BEGIN
 PERFORM ase_private.bind_station(p_station);IF clean IS NULL OR length(clean)NOT BETWEEN 3 AND 4000 THEN RAISE EXCEPTION 'Escribe un resultado de 3 a 4000 caracteres';END IF;
 SELECT * INTO s FROM public.work_stations WHERE token_hash=public.work_hash(p_station)AND active FOR SHARE;IF s.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto no disponible';END IF;
 SELECT * INTO k FROM public.work_station_tickets WHERE id=p_ticket AND station_id=s.id AND expected_action='finish'AND result IS NULL AND expires_at>clock_timestamp()FOR UPDATE;IF k.id IS NULL THEN RAISE EXCEPTION 'Vuelve a identificarte antes de guardar el resultado';END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=s.organization_id AND id=k.plan_id AND user_id=k.user_id AND state='active'FOR UPDATE;IF p.id IS NULL THEN RAISE EXCEPTION 'La ejecución ya no está activa';END IF;
 UPDATE public.work_day_plan SET result_summary=clean,result_updated_at=clock_timestamp(),result_updated_by=k.user_id WHERE id=p.id;
 RETURN jsonb_build_object('success',true,'plan_id',p.id);
END $$;

CREATE OR REPLACE FUNCTION public.work_review_queue() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('planning.view');SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'task_id',p.task_id,'title',t.title,'employee_id',p.user_id,'employee',coalesce(u.full_name,'Empleado no disponible'),'work_date',p.work_date,'finished_at',p.finished_at,'importance',t.importance,'estimated_minutes',t.estimated_minutes,'result_summary',p.result_summary)ORDER BY p.finished_at,p.work_date,p.priority),'[]'::jsonb)INTO result FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org()AND p.state='review';RETURN result;END $$;

ALTER FUNCTION public.work_save_execution_result(uuid,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_station_save_result(text,uuid,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_review_queue() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_save_execution_result(uuid,text),public.work_station_save_result(text,uuid,text),public.work_review_queue() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_save_execution_result(uuid,text),public.work_review_queue() TO authenticated,ase_tenant_executor;
GRANT EXECUTE ON FUNCTION public.work_station_save_result(text,uuid,text) TO anon,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025001500_required_execution_results.sql ====
-- ASE Work: configurable required execution result across all completion channels.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS require_result boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.work_manage_task_outcome(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL,p_requires_review boolean DEFAULT false,p_area uuid DEFAULT NULL,p_labels text[] DEFAULT '{}'::text[],p_location text DEFAULT NULL,p_source_module text DEFAULT NULL,p_entity_type text DEFAULT NULL,p_entity_reference text DEFAULT NULL,p_entity_label text DEFAULT NULL,p_require_result boolean DEFAULT false) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;BEGIN
 result:=public.work_manage_task_context(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file,p_estimated_minutes,p_requires_review,p_area,p_labels,p_location,p_source_module,p_entity_type,p_entity_reference,p_entity_label);
 UPDATE public.tasks SET require_result=coalesce(p_require_result,false)WHERE organization_id=ase_private.current_org()AND id=result;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_guard_required_result() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.state IN('completed','review')AND OLD.state IS DISTINCT FROM NEW.state AND EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=NEW.organization_id AND t.id=NEW.task_id AND t.require_result)AND nullif(btrim(coalesce(NEW.result_summary,'')),'')IS NULL THEN RAISE EXCEPTION 'Escribe el resultado del trabajo antes de finalizar';END IF;
 RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS work_guard_required_result ON public.work_day_plan;
CREATE TRIGGER work_guard_required_result BEFORE UPDATE OF state ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION public.work_guard_required_result();

CREATE OR REPLACE FUNCTION public.work_station_identify_result(p_station text,p_card text DEFAULT NULL,p_method text DEFAULT 'manual',p_user uuid DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;ticket uuid;required boolean:=false;BEGIN
 result:=public.work_station_identify_v2(p_station,p_card,p_method,p_user);ticket:=(result->>'ticket')::uuid;
 IF ticket IS NOT NULL THEN SELECT t.require_result INTO required FROM public.work_station_tickets k JOIN public.work_day_plan p ON p.id=k.plan_id JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE k.id=ticket;END IF;
 RETURN result||jsonb_build_object('require_result',coalesce(required,false));
END $$;

ALTER FUNCTION public.work_manage_task_outcome(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_guard_required_result() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_station_identify_result(text,text,text,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_outcome(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text,boolean),public.work_guard_required_result(),public.work_station_identify_result(text,text,text,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_outcome(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text,boolean),public.work_guard_required_result() TO authenticated,ase_tenant_executor;
GRANT EXECUTE ON FUNCTION public.work_station_identify_result(text,text,text,uuid) TO anon,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025001600_assignment_workload.sql ====
-- ASE Work: visible workload before assigning a task.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_assignment_workload(p_start date DEFAULT NULL,p_end date DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE from_day date:=coalesce(p_start,public.work_today());to_day date:=coalesce(p_end,public.work_today()+13);result jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF to_day<from_day OR to_day-from_day>31 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 32 días';END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',u.id,'full_name',u.full_name,'open_count',coalesce(x.open_count,0),'pending_count',coalesce(x.pending_count,0),'active_count',coalesce(x.active_count,0),'blocked_count',coalesce(x.blocked_count,0),'review_count',coalesce(x.review_count,0),'overdue_count',coalesce(x.overdue_count,0),'estimated_minutes',coalesce(x.estimated_minutes,0))ORDER BY coalesce(x.open_count,0),u.full_name,u.id),'[]'::jsonb)INTO result
 FROM ase_private.employee_profiles u LEFT JOIN LATERAL(
  SELECT count(*)FILTER(WHERE p.state IN('pending','active','paused','blocked','review'))::int open_count,count(*)FILTER(WHERE p.state='pending')::int pending_count,count(*)FILTER(WHERE p.state IN('active','paused'))::int active_count,count(*)FILTER(WHERE p.state='blocked')::int blocked_count,count(*)FILTER(WHERE p.state='review')::int review_count,count(*)FILTER(WHERE p.state='pending'AND p.work_date<public.work_today())::int overdue_count,coalesce(sum(t.estimated_minutes)FILTER(WHERE p.state IN('pending','active','paused','blocked','review')),0)::int estimated_minutes
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org()AND p.user_id=u.id AND p.work_date BETWEEN from_day AND to_day
 )x ON true WHERE u.is_admin IS FALSE AND u.membership_status='active';
 RETURN jsonb_build_object('start',from_day,'end',to_day,'employees',result,'as_of',clock_timestamp());
END $$;

ALTER FUNCTION public.work_assignment_workload(date,date) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_assignment_workload(date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_assignment_workload(date,date) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261025001700_duplicate_task.sql ====
-- ASE Work: create a clean task from an existing activity configuration.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_duplicate_task(p_task uuid,p_title text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE source public.tasks%ROWTYPE;result uuid;primary_user uuid;collaborators uuid[];followers uuid[];area uuid;labels text[];steps jsonb;new_title text;
BEGIN
 PERFORM public.work_assert_permission('tasks.create');
 SELECT * INTO source FROM public.tasks WHERE organization_id=ase_private.current_org()AND id=p_task FOR SHARE;
 IF source.id IS NULL THEN RAISE EXCEPTION 'La actividad ya no está disponible';END IF;
 new_title:=btrim(coalesce(nullif(p_title,''),source.title||' (copia)'));
 IF length(new_title)NOT BETWEEN 1 AND 200 THEN RAISE EXCEPTION 'El título debe tener entre 1 y 200 caracteres';END IF;
 SELECT user_id INTO primary_user FROM public.task_assignments WHERE organization_id=source.organization_id AND task_id=source.id AND responsibility_role='primary'ORDER BY user_id LIMIT 1;
 SELECT coalesce(array_agg(user_id ORDER BY user_id),'{}'::uuid[])INTO collaborators FROM public.task_assignments WHERE organization_id=source.organization_id AND task_id=source.id AND responsibility_role<>'primary';
 SELECT coalesce(array_agg(user_id ORDER BY user_id),'{}'::uuid[])INTO followers FROM public.work_task_followers WHERE organization_id=source.organization_id AND task_id=source.id;
 SELECT area_id INTO area FROM public.work_task_areas WHERE organization_id=source.organization_id AND task_id=source.id;
 SELECT coalesce(array_agg(label ORDER BY normalized),'{}'::text[])INTO labels FROM public.work_task_labels WHERE organization_id=source.organization_id AND task_id=source.id;
 result:=public.work_manage_task_outcome('create',source.importance,NULL,new_title,source.description,source.schedule_type,source.schedule_date,'pending',primary_user,collaborators,followers,source.require_comment,source.require_photo,source.require_video,source.require_file,source.estimated_minutes,source.requires_review,area,labels,source.location,source.source_module,source.related_entity_type,source.related_entity_reference,source.related_entity_label,source.require_result);
 SELECT c.steps INTO steps FROM public.work_checklist_templates c WHERE c.organization_id=source.organization_id AND c.task_id=source.id;
 IF steps IS NOT NULL THEN INSERT INTO public.work_checklist_templates(organization_id,task_id,steps)VALUES(source.organization_id,result,steps);END IF;
 RETURN result;
END $$;

ALTER FUNCTION public.work_duplicate_task(uuid,text) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_duplicate_task(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_duplicate_task(uuid,text) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026000100_execution_result_visibility.sql ====
-- ASE Work: expose every execution result in review, task history and reports.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_execution_result_events(
 id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
 organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
 plan_id uuid NOT NULL REFERENCES public.work_day_plan(id) ON DELETE CASCADE,
 task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
 actor_id uuid,
 result_summary text NOT NULL CHECK(length(result_summary) BETWEEN 3 AND 4000),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX IF NOT EXISTS work_execution_result_events_task ON public.work_execution_result_events(organization_id,task_id,created_at DESC,id DESC);
ALTER TABLE public.work_execution_result_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_execution_result_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_execution_result_events TO ase_tenant_executor;
GRANT USAGE,SELECT ON SEQUENCE public.work_execution_result_events_id_seq TO ase_tenant_executor;
DROP POLICY IF EXISTS work_execution_result_events_boundary ON public.work_execution_result_events;
DROP POLICY IF EXISTS work_execution_result_events_executor ON public.work_execution_result_events;
CREATE POLICY work_execution_result_events_boundary ON public.work_execution_result_events AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY work_execution_result_events_executor ON public.work_execution_result_events TO ase_tenant_executor USING(true) WITH CHECK(true);

INSERT INTO public.work_execution_result_events(organization_id,plan_id,task_id,actor_id,result_summary,created_at)
SELECT organization_id,id,task_id,result_updated_by,result_summary,coalesce(result_updated_at,finished_at,work_date::timestamp AT TIME ZONE 'Europe/Madrid')
FROM public.work_day_plan p WHERE result_summary IS NOT NULL AND NOT EXISTS(
 SELECT 1 FROM public.work_execution_result_events e WHERE e.organization_id=p.organization_id AND e.plan_id=p.id AND e.result_summary=p.result_summary
);

CREATE OR REPLACE FUNCTION public.work_record_execution_result() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.result_summary IS DISTINCT FROM OLD.result_summary AND NEW.result_summary IS NOT NULL THEN
  INSERT INTO public.work_execution_result_events(organization_id,plan_id,task_id,actor_id,result_summary)
  VALUES(NEW.organization_id,NEW.id,NEW.task_id,NEW.result_updated_by,NEW.result_summary);
 END IF;
 RETURN NEW;
END $$;
ALTER FUNCTION public.work_record_execution_result() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_record_execution_result() FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS work_execution_result_audit ON public.work_day_plan;
CREATE TRIGGER work_execution_result_audit AFTER UPDATE OF result_summary ON public.work_day_plan
 FOR EACH ROW EXECUTE FUNCTION public.work_record_execution_result();

CREATE OR REPLACE FUNCTION public.work_task_timeline(p_task uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=ase_private.current_org() AND id=p_task) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF NOT(public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id()) OR EXISTS(SELECT 1 FROM public.work_task_followers WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes consultar esta tarea'; END IF;
 WITH events AS (
  SELECT 'created:'||t.id::text id,'created' kind,'Tarea creada' title,t.title detail,'Sistema' actor_name,t.created_at FROM public.tasks t WHERE t.organization_id=ase_private.current_org() AND t.id=p_task
  UNION ALL SELECT 'assignment:'||e.id::text,'assignment_'||e.action,CASE e.action WHEN 'assigned' THEN 'Empleado asignado' ELSE 'Empleado retirado' END,e.employee_name,e.actor_name,e.created_at FROM public.work_task_assignment_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'importance:'||e.id::text,'importance','Importancia modificada',coalesce(CASE e.previous WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,'Creación')||' → '||CASE e.current_value WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,e.actor_name,e.created_at FROM public.work_importance_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'schedule:'||e.id::text,'schedule','Planificación modificada',CASE e.current_value->>'schedule_kind' WHEN 'anytime' THEN 'En cualquier momento' WHEN 'deadline' THEN 'Antes de una fecha' WHEN 'window' THEN 'Ventana de ejecución' WHEN 'scheduled' THEN 'Fecha u hora concreta' WHEN 'period' THEN 'Periodo planificado' ELSE 'Planificación actualizada' END,e.actor_name,e.created_at FROM public.work_execution_schedule_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
  UNION ALL SELECT 'state:'||e.id::text,'state','Estado modificado',CASE e.from_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'paused' THEN 'Pausada' WHEN 'review' THEN 'En revisión' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' WHEN 'cancelled' THEN 'Cancelada' ELSE e.from_state END||' → '||CASE e.to_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'paused' THEN 'Pausada' WHEN 'review' THEN 'En revisión' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' WHEN 'cancelled' THEN 'Cancelada' ELSE e.to_state END||' · '||e.reason,e.actor_name,e.created_at FROM public.work_board_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
  UNION ALL SELECT 'result:'||e.id::text,'execution_result','Resultado de la ejecución registrado',e.result_summary,coalesce(u.full_name,'Sistema'),e.created_at FROM public.work_execution_result_events e LEFT JOIN ase_private.employee_profiles u ON u.id=e.actor_id WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
 ),page AS(SELECT * FROM events ORDER BY created_at DESC,id DESC LIMIT 250) SELECT coalesce(jsonb_agg(to_jsonb(page) ORDER BY created_at DESC,id DESC),'[]'::jsonb) INTO result FROM page;RETURN result;END $$;
ALTER FUNCTION public.work_task_timeline(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_task_timeline(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_timeline(uuid) TO authenticated,ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_report_table_scope(p_kind text,p_start date,p_end date,p_search text,p_state text,p_method text,p_employee uuid,p_area uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 IF p_kind IS NULL OR p_kind NOT IN ('checkins','tasks','productivity','incidents','closures') OR p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR length(coalesce(p_search,''))>120 THEN RAISE EXCEPTION 'Selecciona un informe y un período de hasta 366 días'; END IF;
 IF p_employee IS NOT NULL AND p_area IS NOT NULL THEN RAISE EXCEPTION 'Selecciona un empleado o un área'; END IF;
 IF p_employee IS NOT NULL AND NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_employee) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas WHERE id=p_area AND active) THEN RAISE EXCEPTION 'Área no válida'; END IF;
 WITH source AS (
SELECT row FROM (SELECT jsonb_build_object('_at',c.checkin_time,'_state',CASE WHEN c.checkout_time IS NULL THEN 'open' ELSE 'closed' END,'_method',c.checkin_method,'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'start',c.checkin_time,'end',c.checkout_time,'minutes',round((extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)/60)::numeric,2),'method',c.checkin_method,'status',CASE WHEN c.checkout_time IS NULL THEN 'En curso' ELSE 'Cerrado' END) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id) dataset WHERE p_kind='checkins'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',(coalesce(p.work_date,t.schedule_date,(t.created_at AT TIME ZONE 'Europe/Madrid')::date)::timestamp AT TIME ZONE 'Europe/Madrid'),'_state',coalesce(p.state,'unplanned'),'_users',jsonb_build_array(a.user_id),'employee',u.full_name,'task',t.title,'date',coalesce(p.work_date,t.schedule_date),'priority',p.priority,'status',CASE p.state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'paused' THEN 'Pausada' WHEN 'completed' THEN 'Completada' WHEN 'blocked' THEN 'Bloqueada' WHEN 'review' THEN 'En revisión' WHEN 'cancelled' THEN 'Cancelada' ELSE 'Sin planificación' END,'result',p.result_summary) row FROM public.tasks t LEFT JOIN public.task_assignments a ON a.task_id=t.id LEFT JOIN ase_private.employee_profiles u ON u.id=a.user_id LEFT JOIN public.work_day_plan p ON p.task_id=t.id AND p.user_id=a.user_id) dataset WHERE p_kind='tasks'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',((c.checkin_time AT TIME ZONE 'Europe/Madrid')::date::timestamp AT TIME ZONE 'Europe/Madrid'),'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'date',(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date,'count',count(*),'minutes',round(sum(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2),'average',round(avg(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2)) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id WHERE c.checkout_time>=c.checkin_time GROUP BY c.user_id,u.full_name,t.id,t.title,(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date) dataset WHERE p_kind='productivity'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',i.created_at,'_state',i.state,'_users',jsonb_build_array(i.reporter_id,i.assigned_user)||coalesce((SELECT jsonb_agg(m.user_id) FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id),'[]'::jsonb),'employee',u.full_name,'task',t.title,'subject',i.subject,'responsible',coalesce(a.name,v.full_name),'start',i.created_at,'updated',i.updated_at,'status',CASE i.state WHEN 'open' THEN 'Abierta' WHEN 'in_progress' THEN 'En atención' ELSE 'Resuelta' END,'blocked',CASE WHEN i.blocks_work THEN 'Sí' ELSE 'No' END,'resolution',i.resolution) row FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=i.reporter_id LEFT JOIN ase_private.employee_profiles v ON v.id=i.assigned_user LEFT JOIN public.work_areas a ON a.id=i.area_id) dataset WHERE p_kind='incidents'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',c.created_at,'_users',jsonb_build_array(p.user_id),'employee',u.full_name,'task',t.title,'actor',v.full_name,'start',c.created_at,'type',CASE c.kind WHEN 'admin_finish' THEN 'Cierre administrativo' ELSE 'Bloqueo por incidencia' END,'reason',c.reason) row FROM public.work_task_closures c JOIN public.work_day_plan p ON p.id=c.plan_id JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id LEFT JOIN ase_private.employee_profiles v ON v.id=c.actor_id) dataset WHERE p_kind='closures'
 ), filtered AS (
 SELECT row FROM source WHERE (row->>'_at')::timestamptz>=p_start::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (row->>'_at')::timestamptz<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (p_employee IS NULL OR row->'_users' @> jsonb_build_array(p_employee))
 AND (p_area IS NULL OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=p_area AND row->'_users' @> jsonb_build_array(m.user_id)))
 AND (p_state IS NULL OR row->>'_state'=p_state) AND (p_method IS NULL OR row->>'_method'=p_method)
 AND (coalesce(btrim(p_search),'')='' OR strpos(lower((row-'_at'-'_state'-'_method'-'_users')::text),lower(btrim(p_search)))>0)
 ), limited AS (SELECT row FROM filtered ORDER BY row->>'_at' DESC,row::text LIMIT 10001)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(row-'_at'-'_state'-'_method'-'_users') FROM limited),'[]'::jsonb),'as_of',now()) INTO result;
 IF (result->>'total')::integer>10000 THEN RAISE EXCEPTION 'Hay más de 10.000 filas. Reduce las fechas o utiliza el buscador antes de descargar'; END IF;
 RETURN result;
END $$;
ALTER FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) TO authenticated,ase_tenant_executor;

REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026000200_admin_time_adjustments.sql ====
-- ASE Work: auditable administrative creation and correction of closed time records.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE public.work_time_adjustments(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_id uuid NOT NULL,
 checkin_id uuid NOT NULL,
 actor_id uuid NOT NULL,
 request_id uuid NOT NULL,
 action text NOT NULL CHECK(action IN('create','correct')),
 reason text NOT NULL CHECK(char_length(reason) BETWEEN 5 AND 2000),
 previous_values jsonb,
 new_values jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(organization_id,request_id),
 FOREIGN KEY(checkin_id) REFERENCES public.checkins(id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
ALTER TABLE public.work_time_adjustments ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_time_adjustments FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_time_adjustments TO ase_tenant_executor;
CREATE POLICY work_time_adjustments_executor ON public.work_time_adjustments TO ase_tenant_executor
 USING(organization_id=ase_private.current_org())
 WITH CHECK(organization_id=ase_private.current_org() AND actor_id=auth.uid());

CREATE OR REPLACE FUNCTION public.work_admin_adjust_time(p_checkin uuid,p_user uuid,p_task uuid,p_start timestamptz,p_end timestamptz,p_reason text,p_request uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid;actor uuid;old_row public.checkins%rowtype;target uuid;existing uuid;action text;
BEGIN
 PERFORM public.work_assert_admin();org:=ase_private.current_org();actor:=auth.uid();
 IF p_request IS NULL OR p_start IS NULL OR p_end IS NULL OR p_end<=p_start OR p_end-p_start>interval '7 days' OR p_end>clock_timestamp()+interval '5 minutes' OR char_length(btrim(coalesce(p_reason,''))) NOT BETWEEN 5 AND 2000 THEN RAISE EXCEPTION 'Revisa las horas y escribe un motivo de 5 a 2000 caracteres';END IF;
 SELECT checkin_id INTO existing FROM public.work_time_adjustments WHERE organization_id=org AND request_id=p_request;
 IF existing IS NOT NULL THEN RETURN jsonb_build_object('id',existing,'already_applied',true);END IF;
 IF p_checkin IS NULL THEN
  action:='create';
  IF p_user IS NULL OR p_task IS NULL OR NOT EXISTS(SELECT 1 FROM public.organization_memberships m WHERE m.organization_id=org AND m.user_id=p_user AND m.status='active') OR NOT EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=org AND t.id=p_task) THEN RAISE EXCEPTION 'Selecciona un empleado y una tarea válidos';END IF;
  IF EXISTS(SELECT 1 FROM public.checkins c WHERE c.organization_id=org AND c.user_id=p_user AND tstzrange(c.checkin_time,coalesce(c.checkout_time,'infinity'::timestamptz),'[)')&&tstzrange(p_start,p_end,'[)')) THEN RAISE EXCEPTION 'El período se solapa con otro fichaje del empleado';END IF;
  INSERT INTO public.checkins(organization_id,task_id,user_id,checkin_time,checkout_time,checkin_method,location) VALUES(org,p_task,p_user,p_start,p_end,'manual','Ajuste administrativo') RETURNING id INTO target;
  INSERT INTO public.work_time_adjustments(organization_id,checkin_id,actor_id,request_id,action,reason,new_values) VALUES(org,target,actor,p_request,action,btrim(p_reason),jsonb_build_object('user_id',p_user,'task_id',p_task,'start',p_start,'end',p_end));
 ELSE
  action:='correct';
  SELECT * INTO old_row FROM public.checkins WHERE organization_id=org AND id=p_checkin FOR UPDATE;
  IF old_row.id IS NULL THEN RAISE EXCEPTION 'El fichaje no existe';END IF;
  IF old_row.checkout_time IS NULL THEN RAISE EXCEPTION 'Detén primero el fichaje activo';END IF;
  IF p_user IS NOT NULL AND p_user<>old_row.user_id OR p_task IS NOT NULL AND p_task<>old_row.task_id THEN RAISE EXCEPTION 'Una corrección no puede cambiar empleado ni tarea';END IF;
  IF EXISTS(SELECT 1 FROM public.checkins c WHERE c.organization_id=org AND c.user_id=old_row.user_id AND c.id<>old_row.id AND tstzrange(c.checkin_time,coalesce(c.checkout_time,'infinity'::timestamptz),'[)')&&tstzrange(p_start,p_end,'[)')) THEN RAISE EXCEPTION 'El período se solapa con otro fichaje del empleado';END IF;
  UPDATE public.checkins SET checkin_time=p_start,checkout_time=p_end WHERE organization_id=org AND id=old_row.id;target:=old_row.id;
  INSERT INTO public.work_time_adjustments(organization_id,checkin_id,actor_id,request_id,action,reason,previous_values,new_values) VALUES(org,target,actor,p_request,action,btrim(p_reason),jsonb_build_object('start',old_row.checkin_time,'end',old_row.checkout_time),jsonb_build_object('start',p_start,'end',p_end));
 END IF;
 RETURN jsonb_build_object('id',target,'already_applied',false);
END $$;

CREATE OR REPLACE FUNCTION public.work_time_adjustment_history(p_checkin uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',h.id,'action',h.action,'reason',h.reason,'previous',h.previous_values,'new',h.new_values,'actor',coalesce(u.full_name,'Administrador'),'created_at',h.created_at) ORDER BY h.created_at DESC,h.id),'[]'::jsonb)
 FROM public.work_time_adjustments h LEFT JOIN ase_private.employee_profiles u ON u.id=h.actor_id
 WHERE h.organization_id=ase_private.current_org() AND h.checkin_id=p_checkin AND (public.work_has_permission('checkins.view') OR h.actor_id=auth.uid())
$$;

ALTER FUNCTION public.work_admin_adjust_time(uuid,uuid,uuid,timestamptz,timestamptz,text,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_time_adjustment_history(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_admin_adjust_time(uuid,uuid,uuid,timestamptz,timestamptz,text,uuid),public.work_time_adjustment_history(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_admin_adjust_time(uuid,uuid,uuid,timestamptz,timestamptz,text,uuid),public.work_time_adjustment_history(uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026000300_employee_absences.sql ====
-- ASE Work: employee absences and planning/check-in safeguards.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_employee_absences(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_id uuid NOT NULL,
 user_id uuid NOT NULL,
 kind text NOT NULL CHECK(kind IN('vacation','leave','sick','unavailable')),
 start_date date NOT NULL,
 end_date date NOT NULL,
 note text,
 created_by uuid NOT NULL DEFAULT auth.uid(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 cancelled_by uuid,
 cancelled_at timestamptz,
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id),
 CHECK(end_date>=start_date),
 CHECK(end_date-start_date<=366),
 CHECK(note IS NULL OR length(note)<=500)
);
CREATE INDEX IF NOT EXISTS work_employee_absences_period ON public.work_employee_absences(organization_id,user_id,start_date,end_date) WHERE cancelled_at IS NULL;
ALTER TABLE public.work_employee_absences ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_employee_absences FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE ON public.work_employee_absences TO ase_tenant_executor;
DROP POLICY IF EXISTS work_employee_absences_executor ON public.work_employee_absences;
CREATE POLICY work_employee_absences_executor ON public.work_employee_absences TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

CREATE OR REPLACE FUNCTION public.work_absence_directory(p_start date,p_end date) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_admin();
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>366 THEN RAISE EXCEPTION 'Selecciona un período de hasta 367 días';END IF;
 SELECT jsonb_build_object(
  'start',p_start,'end',p_end,
  'people',coalesce((SELECT jsonb_agg(jsonb_build_object('id',u.id,'full_name',u.full_name)ORDER BY u.full_name,u.id)FROM ase_private.employee_profiles u WHERE NOT u.is_admin AND u.membership_status='active'),'[]'::jsonb),
  'absences',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'user_id',a.user_id,'employee',u.full_name,'kind',a.kind,'start_date',a.start_date,'end_date',a.end_date,'note',a.note,'created_at',a.created_at,'cancelled_at',a.cancelled_at,'planned_days',(SELECT count(DISTINCT p.work_date)FROM public.work_day_plan p WHERE p.organization_id=a.organization_id AND p.user_id=a.user_id AND p.work_date BETWEEN a.start_date AND a.end_date AND p.state IN('pending','active','paused','blocked','review')))ORDER BY a.start_date,a.end_date,u.full_name,a.id)FROM public.work_employee_absences a JOIN ase_private.employee_profiles u ON u.id=a.user_id WHERE a.start_date<=p_end AND a.end_date>=p_start),'[]'::jsonb),
  'as_of',clock_timestamp()) INTO result;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_save_absence(p_id uuid,p_user uuid,p_kind text,p_start date,p_end date,p_note text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();result uuid:=coalesce(p_id,gen_random_uuid());clean_note text:=nullif(btrim(coalesce(p_note,'')),'');
BEGIN
 PERFORM public.work_assert_admin();
 IF p_kind IS NULL OR p_kind NOT IN('vacation','leave','sick','unavailable')THEN RAISE EXCEPTION 'Tipo de ausencia no válido';END IF;
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>366 THEN RAISE EXCEPTION 'Selecciona un período válido de hasta 367 días';END IF;
 IF clean_note IS NOT NULL AND length(clean_note)>500 THEN RAISE EXCEPTION 'El motivo admite hasta 500 caracteres';END IF;
 PERFORM 1 FROM ase_private.employee_profiles u WHERE u.id=p_user AND NOT u.is_admin AND u.membership_status='active';
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible';END IF;
 IF p_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_employee_absences a WHERE a.organization_id=org AND a.id=p_id AND a.cancelled_at IS NULL)THEN RAISE EXCEPTION 'Ausencia no disponible';END IF;
 IF EXISTS(SELECT 1 FROM public.work_employee_absences a WHERE a.organization_id=org AND a.user_id=p_user AND a.cancelled_at IS NULL AND a.id<>result AND daterange(a.start_date,a.end_date,'[]')&&daterange(p_start,p_end,'[]'))THEN RAISE EXCEPTION 'El empleado ya tiene una ausencia que coincide con esas fechas';END IF;
 INSERT INTO public.work_employee_absences(id,organization_id,user_id,kind,start_date,end_date,note)
 VALUES(result,org,p_user,p_kind,p_start,p_end,clean_note)
 ON CONFLICT(id)DO UPDATE SET user_id=excluded.user_id,kind=excluded.kind,start_date=excluded.start_date,end_date=excluded.end_date,note=excluded.note
 WHERE work_employee_absences.organization_id=org AND work_employee_absences.cancelled_at IS NULL;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_cancel_absence(p_id uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_admin();
 UPDATE public.work_employee_absences SET cancelled_at=clock_timestamp(),cancelled_by=auth.uid()
 WHERE organization_id=ase_private.current_org()AND id=p_id AND cancelled_at IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Ausencia no disponible';END IF;
END $$;

CREATE OR REPLACE FUNCTION public.work_absence_plan_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.state='pending' AND (TG_OP='INSERT' OR NEW.user_id IS DISTINCT FROM OLD.user_id OR NEW.work_date IS DISTINCT FROM OLD.work_date)
 AND EXISTS(SELECT 1 FROM public.work_employee_absences a WHERE a.organization_id=NEW.organization_id AND a.user_id=NEW.user_id AND a.cancelled_at IS NULL AND NEW.work_date BETWEEN a.start_date AND a.end_date)
 THEN RAISE EXCEPTION 'No se puede planificar: el empleado tiene una ausencia en esa fecha';END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_absence_checkin_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.checkout_time IS NULL AND (TG_OP='INSERT' OR OLD.checkout_time IS NOT NULL)
 AND EXISTS(SELECT 1 FROM public.work_employee_absences a WHERE a.organization_id=NEW.organization_id AND a.user_id=NEW.user_id AND a.cancelled_at IS NULL AND public.work_today()BETWEEN a.start_date AND a.end_date)
 THEN RAISE EXCEPTION 'No se puede iniciar el fichaje durante una ausencia registrada';END IF;
 RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS work_absence_plan_guard ON public.work_day_plan;
CREATE TRIGGER work_absence_plan_guard BEFORE INSERT OR UPDATE OF user_id,work_date,state ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION public.work_absence_plan_guard();
DROP TRIGGER IF EXISTS work_absence_checkin_guard ON public.checkins;
CREATE TRIGGER work_absence_checkin_guard BEFORE INSERT OR UPDATE OF checkout_time ON public.checkins FOR EACH ROW EXECUTE FUNCTION public.work_absence_checkin_guard();

ALTER FUNCTION public.work_absence_directory(date,date) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_absence(uuid,uuid,text,date,date,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_cancel_absence(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_absence_plan_guard() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_absence_checkin_guard() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_absence_directory(date,date),public.work_save_absence(uuid,uuid,text,date,date,text),public.work_cancel_absence(uuid),public.work_absence_plan_guard(),public.work_absence_checkin_guard() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_absence_directory(date,date),public.work_save_absence(uuid,uuid,text,date,date,text),public.work_cancel_absence(uuid) TO authenticated,ase_tenant_executor;
GRANT EXECUTE ON FUNCTION public.work_absence_plan_guard(),public.work_absence_checkin_guard() TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026000400_employee_own_absences.sql ====
-- ASE Work: read-only personal absence calendar.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_my_absences(p_start date DEFAULT NULL,p_end date DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE from_day date:=coalesce(p_start,public.work_today()-365);to_day date:=coalesce(p_end,public.work_today()+365);result jsonb;
BEGIN
 IF auth.uid() IS NULL OR ase_private.current_org() IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Sesión no disponible';END IF;
 IF to_day<from_day OR to_day-from_day>1095 THEN RAISE EXCEPTION 'Selecciona un período de hasta tres años';END IF;
 SELECT jsonb_build_object('today',public.work_today(),'start',from_day,'end',to_day,'items',coalesce(jsonb_agg(jsonb_build_object('id',a.id,'kind',a.kind,'start_date',a.start_date,'end_date',a.end_date,'note',a.note,'cancelled_at',a.cancelled_at)ORDER BY a.start_date DESC,a.end_date DESC,a.id),'[]'::jsonb),'as_of',clock_timestamp())INTO result
 FROM public.work_employee_absences a WHERE a.organization_id=ase_private.current_org()AND a.user_id=auth.uid()AND a.start_date<=to_day AND a.end_date>=from_day;
 RETURN result;
END $$;

ALTER FUNCTION public.work_my_absences(date,date) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_my_absences(date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_my_absences(date,date) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026000500_team_calendar.sql ====
-- ASE Work: multi-employee planning and availability calendar.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_team_calendar(p_start date,p_end date,p_area uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>31 THEN RAISE EXCEPTION 'Selecciona un período de hasta 32 días';END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas a WHERE a.organization_id=ase_private.current_org()AND a.id=p_area AND a.active)THEN RAISE EXCEPTION 'Área no disponible';END IF;
 WITH people AS(
  SELECT u.id,u.full_name FROM ase_private.employee_profiles u
  WHERE NOT u.is_admin AND u.membership_status='active' AND(p_area IS NULL OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=ase_private.current_org()AND m.area_id=p_area AND m.user_id=u.id))
 )
 SELECT jsonb_build_object(
  'start',p_start,'end',p_end,
  'areas',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'name',a.name)ORDER BY a.name,a.id)FROM public.work_areas a WHERE a.organization_id=ase_private.current_org()AND a.active),'[]'::jsonb),
  'employees',coalesce(jsonb_agg(jsonb_build_object('id',person.id,'full_name',person.full_name,'days',(
   SELECT jsonb_agg(jsonb_build_object('date',d.work_day,'absent',EXISTS(SELECT 1 FROM public.work_employee_absences x WHERE x.organization_id=ase_private.current_org()AND x.user_id=person.id AND x.cancelled_at IS NULL AND d.work_day BETWEEN x.start_date AND x.end_date),'total',coalesce(p.total,0),'pending',coalesce(p.pending,0),'active',coalesce(p.active,0),'paused',coalesce(p.paused,0),'blocked',coalesce(p.blocked,0),'review',coalesce(p.review,0),'completed',coalesce(p.completed,0))ORDER BY d.work_day)
   FROM(SELECT generate_series(p_start,p_end,'1 day'::interval)::date AS work_day)d
   LEFT JOIN LATERAL(SELECT count(*)::int total,count(*)FILTER(WHERE state='pending')::int pending,count(*)FILTER(WHERE state='active')::int active,count(*)FILTER(WHERE state='paused')::int paused,count(*)FILTER(WHERE state='blocked')::int blocked,count(*)FILTER(WHERE state='review')::int review,count(*)FILTER(WHERE state='completed')::int completed FROM public.work_day_plan w WHERE w.organization_id=ase_private.current_org()AND w.user_id=person.id AND w.work_date=d.work_day)p ON true
  ))ORDER BY person.full_name,person.id),'[]'::jsonb),
  'as_of',clock_timestamp())INTO result FROM people person;
 RETURN result;
END $$;

ALTER FUNCTION public.work_team_calendar(date,date,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_team_calendar(date,date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_team_calendar(date,date,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026000600_edit_recurrences.sql ====
-- ASE Work: safely edit future recurrence settings while preserving generated work.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_recurrence_events(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 recurrence_id uuid NOT NULL,actor_id uuid NOT NULL,previous_value jsonb NOT NULL,current_value jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 FOREIGN KEY(organization_id,recurrence_id) REFERENCES public.work_recurrences(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
ALTER TABLE public.work_recurrence_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_recurrence_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_recurrence_events TO ase_tenant_executor;
DROP POLICY IF EXISTS recurrence_events_scope ON public.work_recurrence_events;
CREATE POLICY recurrence_events_scope ON public.work_recurrence_events TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

CREATE OR REPLACE FUNCTION public.work_update_recurrence(p_id uuid,p_start date,p_frequency text,p_every integer,p_basis text,p_notice integer) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE;before_value jsonb;after_value jsonb;new_next date;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 IF p_id IS NULL OR p_start IS NULL OR p_start<public.work_today() OR p_start>public.work_today()+3650
  OR p_frequency NOT IN('daily','weekly','monthly','yearly') OR p_every NOT BETWEEN 1 AND 365
  OR p_basis NOT IN('fixed','completion') OR p_notice NOT BETWEEN 0 AND 365 THEN
  RAISE EXCEPTION 'Revisa la próxima fecha, frecuencia y aviso';
 END IF;
 SELECT * INTO r FROM public.work_recurrences WHERE organization_id=ase_private.current_org() AND id=p_id FOR UPDATE;
 IF r.id IS NULL THEN RAISE EXCEPTION 'Repetición no disponible';END IF;
 before_value:=jsonb_build_object('start',r.anchor,'frequency',r.frequency,'every',r.every_n,'basis',r.basis,'notice',r.notice_days,'next_due',r.next_due);
 new_next:=p_start;
 IF p_basis='completion' AND EXISTS(
  SELECT 1 FROM public.work_recurrence_runs x JOIN public.work_day_plan p ON p.organization_id=x.organization_id AND p.id=x.plan_id
  WHERE x.organization_id=r.organization_id AND x.recurrence_id=r.id AND p.state<>'completed'
 ) THEN new_next:=NULL;END IF;
 UPDATE public.work_recurrences SET anchor=p_start,next_due=new_next,frequency=p_frequency,every_n=p_every,basis=p_basis,
  notice_days=p_notice,cursor_n=0,last_error=NULL WHERE organization_id=r.organization_id AND id=r.id;
 after_value:=jsonb_build_object('start',p_start,'frequency',p_frequency,'every',p_every,'basis',p_basis,'notice',p_notice,'next_due',new_next);
 IF before_value IS DISTINCT FROM after_value THEN
  INSERT INTO public.work_recurrence_events(organization_id,recurrence_id,actor_id,previous_value,current_value)
  VALUES(r.organization_id,r.id,ase_private.session_user_id(),before_value,after_value);
 END IF;
 IF r.active THEN PERFORM ase_private.run_recurrences(r.organization_id,public.work_today());END IF;
END $$;

ALTER FUNCTION public.work_update_recurrence(uuid,date,text,integer,text,integer) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_update_recurrence(uuid,date,text,integer,text,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_update_recurrence(uuid,date,text,integer,text,integer) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026000700_board_card_indicators.sql ====
-- ASE Work: execution-specific indicators for Kanban cards.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días';END IF;
 IF p_state IS NOT NULL AND p_state NOT IN('pending','active','paused','blocked','review','completed','cancelled')THEN RAISE EXCEPTION 'Estado no válido';END IF;
 IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida';END IF;
 WITH base AS(
  SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,
   (public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,
   coalesce(jsonb_array_length(run.steps),jsonb_array_length(template.steps),0) checklist_total,
   coalesce((SELECT count(*)::int FROM jsonb_array_elements(coalesce(run.steps,'[]'::jsonb)) step WHERE coalesce((step->>'done')::boolean,false)),0) checklist_done,
   coalesce(content.comments_count,0) comments_count,coalesce(content.attachments_count,0) attachments_count,
   t.require_comment::int+t.require_photo::int+t.require_video::int+t.require_file::int evidence_required,
   (CASE WHEN t.require_comment AND coalesce(content.has_comment,false) THEN 1 ELSE 0 END+CASE WHEN t.require_photo AND coalesce(content.has_photo,false) THEN 1 ELSE 0 END+CASE WHEN t.require_video AND coalesce(content.has_video,false) THEN 1 ELSE 0 END+CASE WHEN t.require_file AND coalesce(content.has_file,false) THEN 1 ELSE 0 END) evidence_provided
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
  LEFT JOIN public.work_checklist_templates template ON template.organization_id=p.organization_id AND template.task_id=p.task_id
  LEFT JOIN LATERAL(SELECT c.id,c.checkin_time FROM public.checkins c WHERE c.organization_id=p.organization_id AND c.work_plan_id=p.id ORDER BY c.checkin_time DESC,c.id DESC LIMIT 1) checkin ON true
  LEFT JOIN public.work_checklist_runs run ON run.organization_id=p.organization_id AND run.checkin_id=checkin.id
  LEFT JOIN LATERAL(SELECT count(*)::int comments_count,count(*)FILTER(WHERE x.image_url IS NOT NULL OR x.video_url IS NOT NULL OR x.file_url IS NOT NULL)::int attachments_count,bool_or(nullif(btrim(x.comment),'')IS NOT NULL)has_comment,bool_or(x.image_url IS NOT NULL)has_photo,bool_or(x.video_url IS NOT NULL)has_video,bool_or(x.file_url IS NOT NULL)has_file FROM public.task_comments x WHERE x.organization_id=p.organization_id AND x.task_id=p.task_id AND x.user_id=p.user_id AND x.created_at>=checkin.checkin_time)content ON true
  WHERE p.organization_id=ase_private.current_org()AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)AND(nullif(btrim(p_query),'')IS NULL OR concat_ws(' ',t.title,t.description,u.full_name)ILIKE'%'||btrim(p_query)||'%')
 ),page AS(SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)
 SELECT jsonb_build_object('start',p_start,'end',p_end,'total',(SELECT count(*)FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object('pending',(SELECT count(*)FROM base WHERE state='pending'),'active',(SELECT count(*)FROM base WHERE state='active'),'paused',(SELECT count(*)FROM base WHERE state='paused'),'blocked',(SELECT count(*)FROM base WHERE state='blocked'),'review',(SELECT count(*)FROM base WHERE state='review'),'completed',(SELECT count(*)FROM base WHERE state='completed'),'cancelled',(SELECT count(*)FROM base WHERE state='cancelled')),'items',coalesce((SELECT jsonb_agg(to_jsonb(page)ORDER BY work_date,priority,employee,id)FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp())INTO result;
 RETURN result;
END $$;

ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026000800_board_labels.sql ====
-- ASE Work: show existing task labels on Kanban cards.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días';END IF;
 IF p_state IS NOT NULL AND p_state NOT IN('pending','active','paused','blocked','review','completed','cancelled')THEN RAISE EXCEPTION 'Estado no válido';END IF;
 IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida';END IF;
 WITH base AS(
  SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,
   (public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,
   coalesce(jsonb_array_length(run.steps),jsonb_array_length(template.steps),0) checklist_total,
   coalesce((SELECT count(*)::int FROM jsonb_array_elements(coalesce(run.steps,'[]'::jsonb)) step WHERE coalesce((step->>'done')::boolean,false)),0) checklist_done,
   coalesce(content.comments_count,0) comments_count,coalesce(content.attachments_count,0) attachments_count,coalesce(labels.items,'[]'::jsonb) labels,
   t.require_comment::int+t.require_photo::int+t.require_video::int+t.require_file::int evidence_required,
   (CASE WHEN t.require_comment AND coalesce(content.has_comment,false) THEN 1 ELSE 0 END+CASE WHEN t.require_photo AND coalesce(content.has_photo,false) THEN 1 ELSE 0 END+CASE WHEN t.require_video AND coalesce(content.has_video,false) THEN 1 ELSE 0 END+CASE WHEN t.require_file AND coalesce(content.has_file,false) THEN 1 ELSE 0 END) evidence_provided
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
  LEFT JOIN public.work_checklist_templates template ON template.organization_id=p.organization_id AND template.task_id=p.task_id
  LEFT JOIN LATERAL(SELECT c.id,c.checkin_time FROM public.checkins c WHERE c.organization_id=p.organization_id AND c.work_plan_id=p.id ORDER BY c.checkin_time DESC,c.id DESC LIMIT 1) checkin ON true
  LEFT JOIN public.work_checklist_runs run ON run.organization_id=p.organization_id AND run.checkin_id=checkin.id
  LEFT JOIN LATERAL(SELECT jsonb_agg(l.label ORDER BY l.label,l.normalized)items FROM public.work_task_labels l WHERE l.organization_id=p.organization_id AND l.task_id=p.task_id)labels ON true
  LEFT JOIN LATERAL(SELECT count(*)::int comments_count,count(*)FILTER(WHERE x.image_url IS NOT NULL OR x.video_url IS NOT NULL OR x.file_url IS NOT NULL)::int attachments_count,bool_or(nullif(btrim(x.comment),'')IS NOT NULL)has_comment,bool_or(x.image_url IS NOT NULL)has_photo,bool_or(x.video_url IS NOT NULL)has_video,bool_or(x.file_url IS NOT NULL)has_file FROM public.task_comments x WHERE x.organization_id=p.organization_id AND x.task_id=p.task_id AND x.user_id=p.user_id AND x.created_at>=checkin.checkin_time)content ON true
  WHERE p.organization_id=ase_private.current_org()AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)AND(nullif(btrim(p_query),'')IS NULL OR concat_ws(' ',t.title,t.description,u.full_name)ILIKE'%'||btrim(p_query)||'%' OR EXISTS(SELECT 1 FROM public.work_task_labels searched WHERE searched.organization_id=p.organization_id AND searched.task_id=p.task_id AND searched.label ILIKE'%'||btrim(p_query)||'%'))
 ),page AS(SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)
 SELECT jsonb_build_object('start',p_start,'end',p_end,'labels',coalesce((SELECT jsonb_agg(DISTINCT l.label ORDER BY l.label)FROM public.work_task_labels l WHERE l.organization_id=ase_private.current_org()),'[]'::jsonb),'total',(SELECT count(*)FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object('pending',(SELECT count(*)FROM base WHERE state='pending'),'active',(SELECT count(*)FROM base WHERE state='active'),'paused',(SELECT count(*)FROM base WHERE state='paused'),'blocked',(SELECT count(*)FROM base WHERE state='blocked'),'review',(SELECT count(*)FROM base WHERE state='review'),'completed',(SELECT count(*)FROM base WHERE state='completed'),'cancelled',(SELECT count(*)FROM base WHERE state='cancelled')),'items',coalesce((SELECT jsonb_agg(to_jsonb(page)ORDER BY work_date,priority,employee,id)FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp())INTO result;
 RETURN result;
END $$;

ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026000900_board_area_filter.sql ====
-- ASE Work: filter the planning board by work area.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_area uuid DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días';END IF;
 IF p_state IS NOT NULL AND p_state NOT IN('pending','active','paused','blocked','review','completed','cancelled')THEN RAISE EXCEPTION 'Estado no válido';END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas a WHERE a.organization_id=ase_private.current_org()AND a.id=p_area AND a.active)THEN RAISE EXCEPTION 'Área no disponible';END IF;
 IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida';END IF;
 WITH base AS(
  SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,a.id area_id,a.name area_name,
   (public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,
   coalesce(jsonb_array_length(run.steps),jsonb_array_length(template.steps),0) checklist_total,
   coalesce((SELECT count(*)::int FROM jsonb_array_elements(coalesce(run.steps,'[]'::jsonb)) step WHERE coalesce((step->>'done')::boolean,false)),0) checklist_done,
   coalesce(content.comments_count,0) comments_count,coalesce(content.attachments_count,0) attachments_count,coalesce(labels.items,'[]'::jsonb) labels,
   t.require_comment::int+t.require_photo::int+t.require_video::int+t.require_file::int evidence_required,
   (CASE WHEN t.require_comment AND coalesce(content.has_comment,false) THEN 1 ELSE 0 END+CASE WHEN t.require_photo AND coalesce(content.has_photo,false) THEN 1 ELSE 0 END+CASE WHEN t.require_video AND coalesce(content.has_video,false) THEN 1 ELSE 0 END+CASE WHEN t.require_file AND coalesce(content.has_file,false) THEN 1 ELSE 0 END) evidence_provided
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
  LEFT JOIN public.work_task_areas ta ON ta.organization_id=p.organization_id AND ta.task_id=p.task_id
  LEFT JOIN public.work_areas a ON a.organization_id=ta.organization_id AND a.id=ta.area_id
  LEFT JOIN public.work_checklist_templates template ON template.organization_id=p.organization_id AND template.task_id=p.task_id
  LEFT JOIN LATERAL(SELECT c.id,c.checkin_time FROM public.checkins c WHERE c.organization_id=p.organization_id AND c.work_plan_id=p.id ORDER BY c.checkin_time DESC,c.id DESC LIMIT 1) checkin ON true
  LEFT JOIN public.work_checklist_runs run ON run.organization_id=p.organization_id AND run.checkin_id=checkin.id
  LEFT JOIN LATERAL(SELECT jsonb_agg(l.label ORDER BY l.label,l.normalized)items FROM public.work_task_labels l WHERE l.organization_id=p.organization_id AND l.task_id=p.task_id)labels ON true
  LEFT JOIN LATERAL(SELECT count(*)::int comments_count,count(*)FILTER(WHERE x.image_url IS NOT NULL OR x.video_url IS NOT NULL OR x.file_url IS NOT NULL)::int attachments_count,bool_or(nullif(btrim(x.comment),'')IS NOT NULL)has_comment,bool_or(x.image_url IS NOT NULL)has_photo,bool_or(x.video_url IS NOT NULL)has_video,bool_or(x.file_url IS NOT NULL)has_file FROM public.task_comments x WHERE x.organization_id=p.organization_id AND x.task_id=p.task_id AND x.user_id=p.user_id AND x.created_at>=checkin.checkin_time)content ON true
  WHERE p.organization_id=ase_private.current_org()AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)
   AND(p_area IS NULL OR ta.area_id=p_area OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=p.organization_id AND m.area_id=p_area AND m.user_id=p.user_id))
   AND(nullif(btrim(p_query),'')IS NULL OR concat_ws(' ',t.title,t.description,u.full_name,a.name)ILIKE'%'||btrim(p_query)||'%' OR EXISTS(SELECT 1 FROM public.work_task_labels searched WHERE searched.organization_id=p.organization_id AND searched.task_id=p.task_id AND searched.label ILIKE'%'||btrim(p_query)||'%'))
 ),page AS(SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)
 SELECT jsonb_build_object('start',p_start,'end',p_end,'labels',coalesce((SELECT jsonb_agg(DISTINCT l.label ORDER BY l.label)FROM public.work_task_labels l WHERE l.organization_id=ase_private.current_org()),'[]'::jsonb),'total',(SELECT count(*)FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object('pending',(SELECT count(*)FROM base WHERE state='pending'),'active',(SELECT count(*)FROM base WHERE state='active'),'paused',(SELECT count(*)FROM base WHERE state='paused'),'blocked',(SELECT count(*)FROM base WHERE state='blocked'),'review',(SELECT count(*)FROM base WHERE state='review'),'completed',(SELECT count(*)FROM base WHERE state='completed'),'cancelled',(SELECT count(*)FROM base WHERE state='cancelled')),'items',coalesce((SELECT jsonb_agg(to_jsonb(page)ORDER BY work_date,priority,employee,id)FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp())INTO result;
 RETURN result;
END $$;

DROP FUNCTION IF EXISTS public.work_planning_board_range(date,date,uuid,text,text,integer,integer);
ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,uuid,integer,integer) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,uuid,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,uuid,integer,integer) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026001000_task_template_library.sql ====
-- ASE Work: shared reusable task template library.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_task_templates(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 id uuid NOT NULL DEFAULT gen_random_uuid(),
 source_task_id uuid NOT NULL,
 name text NOT NULL,
 description text,
 created_by uuid NOT NULL DEFAULT ase_private.session_user_id(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id),
 FOREIGN KEY(organization_id,source_task_id)REFERENCES public.tasks(organization_id,id)ON DELETE CASCADE,
 CHECK(length(btrim(name))BETWEEN 1 AND 120),
 CHECK(description IS NULL OR length(description)<=500)
);
CREATE UNIQUE INDEX IF NOT EXISTS work_task_templates_name_unique ON public.work_task_templates(organization_id,lower(btrim(name)));
ALTER TABLE public.work_task_templates ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.work_task_template_events(
 organization_id uuid NOT NULL,
 id bigint GENERATED ALWAYS AS IDENTITY,
 template_id uuid NOT NULL,
 actor_id uuid NOT NULL,
 action text NOT NULL CHECK(action IN('created','updated','used','deleted')),
 detail jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id)
);
ALTER TABLE public.work_task_template_events ENABLE ROW LEVEL SECURITY;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_task_templates,public.work_task_template_events TO ase_tenant_executor;
GRANT USAGE,SELECT ON SEQUENCE public.work_task_template_events_id_seq TO ase_tenant_executor;
DROP POLICY IF EXISTS work_task_templates_executor ON public.work_task_templates;
CREATE POLICY work_task_templates_executor ON public.work_task_templates TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_template_events_executor ON public.work_task_template_events;
CREATE POLICY work_task_template_events_executor ON public.work_task_template_events TO ase_tenant_executor USING(true)WITH CHECK(true);

CREATE OR REPLACE FUNCTION public.work_task_template_directory()RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',x.id,'name',x.name,'description',x.description,'source_task_id',x.source_task_id,'source_title',t.title,'importance',t.importance,'updated_at',x.updated_at)ORDER BY x.name,x.id)FROM public.work_task_templates x JOIN public.tasks t ON t.organization_id=x.organization_id AND t.id=x.source_task_id WHERE x.organization_id=ase_private.current_org()),'[]'::jsonb);
END $$;

CREATE OR REPLACE FUNCTION public.work_save_task_template(p_action text,p_id uuid DEFAULT NULL,p_task uuid DEFAULT NULL,p_name text DEFAULT NULL,p_description text DEFAULT NULL)RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();result uuid;old_row public.work_task_templates%ROWTYPE;
BEGIN
 PERFORM public.work_assert_permission(CASE WHEN p_action='delete' THEN 'tasks.edit' ELSE 'tasks.create' END);
 IF p_action IN('create','update')THEN
  IF p_task IS NULL OR NOT EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=org AND t.id=p_task)THEN RAISE EXCEPTION 'Selecciona una actividad disponible';END IF;
  IF length(btrim(coalesce(p_name,'')))NOT BETWEEN 1 AND 120 THEN RAISE EXCEPTION 'El nombre debe tener entre 1 y 120 caracteres';END IF;
  IF length(coalesce(p_description,''))>500 THEN RAISE EXCEPTION 'La descripción admite hasta 500 caracteres';END IF;
 END IF;
 IF p_action='create'THEN
  INSERT INTO public.work_task_templates(organization_id,source_task_id,name,description)VALUES(org,p_task,btrim(p_name),nullif(btrim(p_description),''))RETURNING id INTO result;
  INSERT INTO public.work_task_template_events(organization_id,template_id,actor_id,action,detail)VALUES(org,result,ase_private.session_user_id(),'created',jsonb_build_object('task_id',p_task,'name',btrim(p_name)));
 ELSIF p_action='update'THEN
  SELECT * INTO old_row FROM public.work_task_templates WHERE organization_id=org AND id=p_id FOR UPDATE;
  IF old_row.id IS NULL THEN RAISE EXCEPTION 'La plantilla ya no está disponible';END IF;
  UPDATE public.work_task_templates SET source_task_id=p_task,name=btrim(p_name),description=nullif(btrim(p_description),''),updated_at=clock_timestamp()WHERE organization_id=org AND id=p_id RETURNING id INTO result;
  INSERT INTO public.work_task_template_events(organization_id,template_id,actor_id,action,detail)VALUES(org,result,ase_private.session_user_id(),'updated',jsonb_build_object('before',jsonb_build_object('task_id',old_row.source_task_id,'name',old_row.name),'after',jsonb_build_object('task_id',p_task,'name',btrim(p_name))));
 ELSIF p_action='delete'THEN
  SELECT * INTO old_row FROM public.work_task_templates WHERE organization_id=org AND id=p_id FOR UPDATE;
  IF old_row.id IS NULL THEN RAISE EXCEPTION 'La plantilla ya no está disponible';END IF;
  INSERT INTO public.work_task_template_events(organization_id,template_id,actor_id,action,detail)VALUES(org,old_row.id,ase_private.session_user_id(),'deleted',jsonb_build_object('task_id',old_row.source_task_id,'name',old_row.name));
  DELETE FROM public.work_task_templates WHERE organization_id=org AND id=old_row.id;result:=old_row.id;
 ELSE RAISE EXCEPTION 'Acción no válida';END IF;
 RETURN result;
EXCEPTION WHEN unique_violation THEN RAISE EXCEPTION 'Ya existe una plantilla con ese nombre';
END $$;

CREATE OR REPLACE FUNCTION public.work_create_task_from_template(p_template uuid,p_title text DEFAULT NULL)RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item public.work_task_templates%ROWTYPE;result uuid;
BEGIN
 PERFORM public.work_assert_permission('tasks.create');
 SELECT * INTO item FROM public.work_task_templates WHERE organization_id=ase_private.current_org()AND id=p_template FOR SHARE;
 IF item.id IS NULL THEN RAISE EXCEPTION 'La plantilla ya no está disponible';END IF;
 result:=public.work_duplicate_task(item.source_task_id,coalesce(nullif(btrim(p_title),''),item.name));
 INSERT INTO public.work_task_template_events(organization_id,template_id,actor_id,action,detail)VALUES(item.organization_id,item.id,ase_private.session_user_id(),'used',jsonb_build_object('created_task_id',result,'title',coalesce(nullif(btrim(p_title),''),item.name)));
 RETURN result;
END $$;

ALTER FUNCTION public.work_task_template_directory() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_task_template(text,uuid,uuid,text,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_create_task_from_template(uuid,text) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON TABLE public.work_task_templates,public.work_task_template_events FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.work_task_template_directory(),public.work_save_task_template(text,uuid,uuid,text,text),public.work_create_task_from_template(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_template_directory(),public.work_save_task_template(text,uuid,uuid,text,text),public.work_create_task_from_template(uuid,text) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026001100_task_subtasks.sql ====
-- ASE Work: independent tasks linked as subtasks of another activity.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_task_subtasks(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 parent_task_id uuid NOT NULL,
 child_task_id uuid NOT NULL,
 position integer NOT NULL DEFAULT 1 CHECK(position>0),
 created_by uuid NOT NULL DEFAULT ase_private.session_user_id(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,parent_task_id,child_task_id),
 FOREIGN KEY(organization_id,parent_task_id)REFERENCES public.tasks(organization_id,id)ON DELETE CASCADE,
 FOREIGN KEY(organization_id,child_task_id)REFERENCES public.tasks(organization_id,id)ON DELETE CASCADE,
 CHECK(parent_task_id<>child_task_id)
);
ALTER TABLE public.work_task_subtasks ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.work_task_subtask_events(
 organization_id uuid NOT NULL,
 id bigint GENERATED ALWAYS AS IDENTITY,
 parent_task_id uuid NOT NULL,
 child_task_id uuid NOT NULL,
 actor_id uuid NOT NULL,
 action text NOT NULL CHECK(action IN('linked','unlinked')),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id)
);
ALTER TABLE public.work_task_subtask_events ENABLE ROW LEVEL SECURITY;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_task_subtasks,public.work_task_subtask_events TO ase_tenant_executor;
GRANT USAGE,SELECT ON SEQUENCE public.work_task_subtask_events_id_seq TO ase_tenant_executor;
DROP POLICY IF EXISTS work_task_subtasks_executor ON public.work_task_subtasks;
CREATE POLICY work_task_subtasks_executor ON public.work_task_subtasks TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_subtask_events_executor ON public.work_task_subtask_events;
CREATE POLICY work_task_subtask_events_executor ON public.work_task_subtask_events TO ase_tenant_executor USING(true)WITH CHECK(true);

CREATE OR REPLACE FUNCTION public.work_task_subtask_directory(p_task uuid)RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 IF NOT EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=org AND t.id=p_task)THEN RAISE EXCEPTION 'La actividad principal ya no está disponible';END IF;
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',t.id,'title',t.title,'description',t.description,'importance',t.importance,'status',t.status,'schedule_type',t.schedule_type,'schedule_date',t.schedule_date,'position',x.position,'assigned',coalesce((SELECT string_agg(u.full_name,', 'ORDER BY u.full_name)FROM public.task_assignments a JOIN ase_private.employee_profiles u ON u.id=a.user_id WHERE a.organization_id=org AND a.task_id=t.id),'Sin asignar'))ORDER BY x.position,t.title,t.id)FROM public.work_task_subtasks x JOIN public.tasks t ON t.organization_id=x.organization_id AND t.id=x.child_task_id WHERE x.organization_id=org AND x.parent_task_id=p_task),'[]'::jsonb);
END $$;

CREATE OR REPLACE FUNCTION public.work_manage_task_subtask(p_action text,p_parent uuid,p_child uuid)RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();next_position integer;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_action NOT IN('link','unlink')THEN RAISE EXCEPTION 'Acción no válida';END IF;
 IF p_parent IS NULL OR p_child IS NULL OR p_parent=p_child THEN RAISE EXCEPTION 'Selecciona dos actividades diferentes';END IF;
 IF(SELECT count(*)FROM public.tasks t WHERE t.organization_id=org AND t.id IN(p_parent,p_child))<>2 THEN RAISE EXCEPTION 'Alguna actividad ya no está disponible';END IF;
 IF p_action='link'THEN
  IF EXISTS(WITH RECURSIVE descendants(id)AS(SELECT s.child_task_id FROM public.work_task_subtasks s WHERE s.organization_id=org AND s.parent_task_id=p_child UNION SELECT s.child_task_id FROM public.work_task_subtasks s JOIN descendants d ON d.id=s.parent_task_id WHERE s.organization_id=org)SELECT 1 FROM descendants WHERE id=p_parent)THEN RAISE EXCEPTION 'La relación formaría un ciclo entre subtareas';END IF;
  SELECT coalesce(max(position),0)+1 INTO next_position FROM public.work_task_subtasks WHERE organization_id=org AND parent_task_id=p_parent;
  INSERT INTO public.work_task_subtasks(organization_id,parent_task_id,child_task_id,position)VALUES(org,p_parent,p_child,next_position)ON CONFLICT DO NOTHING;
  IF FOUND THEN INSERT INTO public.work_task_subtask_events(organization_id,parent_task_id,child_task_id,actor_id,action)VALUES(org,p_parent,p_child,ase_private.session_user_id(),'linked');END IF;
 ELSE
  DELETE FROM public.work_task_subtasks WHERE organization_id=org AND parent_task_id=p_parent AND child_task_id=p_child;
  IF FOUND THEN INSERT INTO public.work_task_subtask_events(organization_id,parent_task_id,child_task_id,actor_id,action)VALUES(org,p_parent,p_child,ase_private.session_user_id(),'unlinked');END IF;
 END IF;
END $$;

ALTER FUNCTION public.work_task_subtask_directory(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_manage_task_subtask(text,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON TABLE public.work_task_subtasks,public.work_task_subtask_events FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.work_task_subtask_directory(uuid),public.work_manage_task_subtask(text,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_subtask_directory(uuid),public.work_manage_task_subtask(text,uuid,uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026001200_task_dependencies.sql ====
-- ASE Work: task dependencies enforced for every execution start.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_task_dependencies(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 task_id uuid NOT NULL,
 prerequisite_task_id uuid NOT NULL,
 created_by uuid NOT NULL DEFAULT ase_private.session_user_id(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,task_id,prerequisite_task_id),
 FOREIGN KEY(organization_id,task_id)REFERENCES public.tasks(organization_id,id)ON DELETE CASCADE,
 FOREIGN KEY(organization_id,prerequisite_task_id)REFERENCES public.tasks(organization_id,id)ON DELETE CASCADE,
 CHECK(task_id<>prerequisite_task_id)
);
ALTER TABLE public.work_task_dependencies ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.work_task_dependency_events(
 organization_id uuid NOT NULL,id bigint GENERATED ALWAYS AS IDENTITY,task_id uuid NOT NULL,prerequisite_task_id uuid NOT NULL,actor_id uuid NOT NULL,
 action text NOT NULL CHECK(action IN('linked','unlinked')),created_at timestamptz NOT NULL DEFAULT clock_timestamp(),PRIMARY KEY(organization_id,id)
);
ALTER TABLE public.work_task_dependency_events ENABLE ROW LEVEL SECURITY;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_task_templates,public.work_task_template_events,public.work_task_subtasks,public.work_task_subtask_events,public.work_task_dependencies,public.work_task_dependency_events TO ase_tenant_executor;
GRANT USAGE,SELECT ON SEQUENCE public.work_task_template_events_id_seq,public.work_task_subtask_events_id_seq,public.work_task_dependency_events_id_seq TO ase_tenant_executor;
DROP POLICY IF EXISTS work_task_templates_executor ON public.work_task_templates;
CREATE POLICY work_task_templates_executor ON public.work_task_templates TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_template_events_executor ON public.work_task_template_events;
CREATE POLICY work_task_template_events_executor ON public.work_task_template_events TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_subtasks_executor ON public.work_task_subtasks;
CREATE POLICY work_task_subtasks_executor ON public.work_task_subtasks TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_subtask_events_executor ON public.work_task_subtask_events;
CREATE POLICY work_task_subtask_events_executor ON public.work_task_subtask_events TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_dependencies_executor ON public.work_task_dependencies;
CREATE POLICY work_task_dependencies_executor ON public.work_task_dependencies TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_dependency_events_executor ON public.work_task_dependency_events;
CREATE POLICY work_task_dependency_events_executor ON public.work_task_dependency_events TO ase_tenant_executor USING(true)WITH CHECK(true);

CREATE OR REPLACE FUNCTION public.work_task_dependency_directory(p_task uuid)RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 IF NOT EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=org AND t.id=p_task)THEN RAISE EXCEPTION 'La actividad ya no está disponible';END IF;
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',t.id,'title',t.title,'importance',t.importance,'latest_date',latest.work_date,'latest_state',latest.state)ORDER BY t.title,t.id)FROM public.work_task_dependencies d JOIN public.tasks t ON t.organization_id=d.organization_id AND t.id=d.prerequisite_task_id LEFT JOIN LATERAL(SELECT p.work_date,p.state FROM public.work_day_plan p WHERE p.organization_id=d.organization_id AND p.task_id=d.prerequisite_task_id ORDER BY p.work_date DESC,p.priority DESC,p.id DESC LIMIT 1)latest ON true WHERE d.organization_id=org AND d.task_id=p_task),'[]'::jsonb);
END $$;

CREATE OR REPLACE FUNCTION public.work_manage_task_dependency(p_action text,p_task uuid,p_prerequisite uuid)RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_action NOT IN('link','unlink')THEN RAISE EXCEPTION 'Acción no válida';END IF;
 IF p_task IS NULL OR p_prerequisite IS NULL OR p_task=p_prerequisite THEN RAISE EXCEPTION 'Selecciona dos actividades diferentes';END IF;
 IF(SELECT count(*)FROM public.tasks t WHERE t.organization_id=org AND t.id IN(p_task,p_prerequisite))<>2 THEN RAISE EXCEPTION 'Alguna actividad ya no está disponible';END IF;
 IF p_action='link'THEN
  IF EXISTS(WITH RECURSIVE requirements(id)AS(SELECT d.prerequisite_task_id FROM public.work_task_dependencies d WHERE d.organization_id=org AND d.task_id=p_prerequisite UNION SELECT d.prerequisite_task_id FROM public.work_task_dependencies d JOIN requirements r ON r.id=d.task_id WHERE d.organization_id=org)SELECT 1 FROM requirements WHERE id=p_task)THEN RAISE EXCEPTION 'La dependencia formaría un ciclo';END IF;
  INSERT INTO public.work_task_dependencies(organization_id,task_id,prerequisite_task_id)VALUES(org,p_task,p_prerequisite)ON CONFLICT DO NOTHING;
  IF FOUND THEN INSERT INTO public.work_task_dependency_events(organization_id,task_id,prerequisite_task_id,actor_id,action)VALUES(org,p_task,p_prerequisite,ase_private.session_user_id(),'linked');END IF;
 ELSE
  DELETE FROM public.work_task_dependencies WHERE organization_id=org AND task_id=p_task AND prerequisite_task_id=p_prerequisite;
  IF FOUND THEN INSERT INTO public.work_task_dependency_events(organization_id,task_id,prerequisite_task_id,actor_id,action)VALUES(org,p_task,p_prerequisite,ase_private.session_user_id(),'unlinked');END IF;
 END IF;
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_eligibility(p_plan uuid,p_moment timestamptz DEFAULT clock_timestamp()) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;start_limit timestamptz;end_limit timestamptz;temporal boolean;earlier boolean;assigned boolean;opened boolean;dependency_blocked boolean;dependency_names jsonb;reason text;
BEGIN
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org()AND id=p_plan;
 IF NOT FOUND THEN RAISE EXCEPTION 'Ejecución no disponible';END IF;
 start_limit:=CASE p.schedule_kind WHEN'window'THEN p.available_from WHEN'period'THEN p.available_from WHEN'scheduled'THEN CASE WHEN p.strict_schedule THEN p.scheduled_for END END;
 end_limit:=CASE p.schedule_kind WHEN'deadline'THEN p.due_at WHEN'window'THEN p.due_at WHEN'scheduled'THEN p.due_at WHEN'period'THEN coalesce(p.due_at,p.planned_end)END;
 temporal:=(start_limit IS NULL OR p_moment>=start_limit)AND(end_limit IS NULL OR p_moment<end_limit);
 assigned:=EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=p.organization_id AND a.task_id=p.task_id AND a.user_id=p.user_id);
 opened:=EXISTS(SELECT 1 FROM public.checkins c WHERE c.organization_id=p.organization_id AND c.user_id=p.user_id AND c.checkout_time IS NULL AND c.work_plan_id IS DISTINCT FROM p.id);
 earlier:=EXISTS(SELECT 1 FROM public.work_day_plan x WHERE x.organization_id=p.organization_id AND x.user_id=p.user_id AND x.state='pending'AND x.id<>p.id AND x.priority<p.priority AND x.work_date=p.work_date);
 WITH requirements AS(SELECT d.prerequisite_task_id,t.title,(SELECT x.state FROM public.work_day_plan x WHERE x.organization_id=p.organization_id AND x.task_id=d.prerequisite_task_id AND x.work_date<=p.work_date ORDER BY x.work_date DESC,x.priority DESC,x.id DESC LIMIT 1)latest_state FROM public.work_task_dependencies d JOIN public.tasks t ON t.organization_id=d.organization_id AND t.id=d.prerequisite_task_id WHERE d.organization_id=p.organization_id AND d.task_id=p.task_id)
 SELECT coalesce(bool_or(latest_state IS DISTINCT FROM'completed'),false),coalesce(jsonb_agg(title ORDER BY title)FILTER(WHERE latest_state IS DISTINCT FROM'completed'),'[]'::jsonb)INTO dependency_blocked,dependency_names FROM requirements;
 reason:=CASE WHEN p.state<>'pending'THEN'state'WHEN NOT assigned THEN'assignment'WHEN opened THEN'open_checkin'WHEN dependency_blocked THEN'dependency'WHEN earlier THEN'order'WHEN start_limit IS NOT NULL AND p_moment<start_limit THEN'too_early'WHEN end_limit IS NOT NULL AND p_moment>=end_limit THEN'overdue'ELSE NULL END;
 RETURN ase_private.execution_schedule_json(p)||jsonb_build_object('kind',p.schedule_kind,'strict',p.strict_schedule,'can_start',reason IS NULL,'can_start_time',temporal,'reason',reason,'waiting_for',dependency_names,'overdue',p.state IN('pending','active')AND end_limit IS NOT NULL AND p_moment>=end_limit,'starts_later',p.state='pending'AND start_limit IS NOT NULL AND p_moment<start_limit,'start_limit',start_limit,'end_limit',end_limit);
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_schedule_guard()RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE eligibility jsonb;
BEGIN
 IF NEW.work_plan_id IS NULL THEN RETURN NEW;END IF;
 eligibility:=public.work_execution_eligibility(NEW.work_plan_id,coalesce(NEW.checkin_time,clock_timestamp()));
 IF NOT coalesce((eligibility->>'can_start')::boolean,false)THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE=CASE eligibility->>'reason' WHEN'too_early'THEN'Esta tarea todavía no está disponible'WHEN'overdue'THEN'La fecha límite ha pasado. Solicita al encargado que reprograme la tarea'WHEN'dependency'THEN'Debes completar primero: '||coalesce((SELECT string_agg(value,', ')FROM jsonb_array_elements_text(eligibility->'waiting_for')), 'otra tarea')WHEN'order'THEN'Respeta el orden de tareas del empleado'WHEN'open_checkin'THEN'El empleado ya tiene un fichaje activo'WHEN'assignment'THEN'La tarea ya no está asignada al empleado'ELSE'La tarea no puede iniciarse en este momento'END;END IF;
 RETURN NEW;
END $$;

ALTER FUNCTION public.work_task_dependency_directory(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_manage_task_dependency(text,uuid,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_eligibility(uuid,timestamptz) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_guard() OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON TABLE public.work_task_dependencies,public.work_task_dependency_events FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.work_task_dependency_directory(uuid),public.work_manage_task_dependency(text,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_dependency_directory(uuid),public.work_manage_task_dependency(text,uuid,uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261026001300_estimate_variance_report.sql ====
-- ASE Work: compare expected and recorded time without evaluating work quality.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_report_estimate_variance(
  p_start date,
  p_end date,
  p_employee uuid DEFAULT NULL,
  p_area uuid DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $function$
DECLARE result jsonb;
BEGIN
  PERFORM public.work_assert_permission('reports.view');
  IF p_start IS NULL OR p_end IS NULL OR p_end < p_start OR p_end - p_start > 365 THEN
    RAISE EXCEPTION 'Selecciona un período de hasta 366 días';
  END IF;
  IF p_employee IS NOT NULL AND p_area IS NOT NULL THEN
    RAISE EXCEPTION 'Selecciona un empleado o un área';
  END IF;
  IF p_employee IS NOT NULL AND NOT EXISTS(
    SELECT 1 FROM ase_private.employee_profiles WHERE id=p_employee
  ) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
  IF p_area IS NOT NULL AND NOT EXISTS(
    SELECT 1 FROM public.work_areas WHERE id=p_area AND active
  ) THEN RAISE EXCEPTION 'Área no válida'; END IF;

  WITH samples AS (
    SELECT c.user_id, coalesce(u.full_name,'Empleado no disponible') employee,
      c.task_id, t.title task, t.estimated_minutes,
      extract(epoch FROM c.checkout_time-c.checkin_time)/60.0 actual_minutes
    FROM public.checkins c
    JOIN public.tasks t ON t.id=c.task_id AND t.organization_id=ase_private.current_org()
    LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id
    WHERE t.estimated_minutes IS NOT NULL
      AND c.checkin_time IS NOT NULL AND c.checkout_time>c.checkin_time
      AND c.checkout_time>=p_start::timestamp AT TIME ZONE 'Europe/Madrid'
      AND c.checkout_time<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
      AND (p_employee IS NULL OR c.user_id=p_employee)
      AND (p_area IS NULL OR EXISTS(
        SELECT 1 FROM public.work_area_members m
        WHERE m.organization_id=ase_private.current_org()
          AND m.area_id=p_area AND m.user_id=c.user_id
      ))
  ), grouped AS (
    SELECT user_id,employee,task_id,task,count(*)::int work_count,
      estimated_minutes,
      round(sum(estimated_minutes)::numeric,2) estimated_total,
      round(sum(actual_minutes)::numeric,2) actual_total,
      round((sum(actual_minutes)-sum(estimated_minutes))::numeric,2) variance,
      round(avg(actual_minutes)::numeric,2) actual_average
    FROM samples
    GROUP BY user_id,employee,task_id,task,estimated_minutes
  )
  SELECT jsonb_build_object(
    'summary',jsonb_build_object(
      'work_count',coalesce((SELECT sum(work_count) FROM grouped),0),
      'estimated_total',coalesce((SELECT sum(estimated_total) FROM grouped),0),
      'actual_total',coalesce((SELECT sum(actual_total) FROM grouped),0),
      'variance',coalesce((SELECT sum(variance) FROM grouped),0),
      'within_estimate',coalesce((SELECT sum(work_count) FROM grouped WHERE variance<=0),0)
    ),
    'items',coalesce((SELECT jsonb_agg(to_jsonb(g) ORDER BY abs(g.variance) DESC,g.employee,g.task) FROM grouped g),'[]'::jsonb),
    'as_of',now()
  ) INTO result;
  RETURN result;
END $function$;

ALTER FUNCTION public.work_report_estimate_variance(date,date,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_report_estimate_variance(date,date,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_report_estimate_variance(date,date,uuid,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261027000100_notification_consistency.sql ====
-- ASE Work: complete assignment notifications and normalize legacy incident events.

GRANT CREATE ON SCHEMA ase_private TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION ase_private.notify_removed_assignment() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE task_title text;
BEGIN
  SELECT title INTO task_title FROM public.tasks
   WHERE organization_id=OLD.organization_id AND id=OLD.task_id;
  IF task_title IS NULL THEN RETURN OLD; END IF;
  INSERT INTO public.work_notifications(
    organization_id,user_id,incident_id,message,kind,event_key
  ) VALUES(
    OLD.organization_id,OLD.user_id,NULL,
    'Ya no estás asignado a: '||task_title,
    'assignment_removed',
    'assignment-removed:'||OLD.task_id::text||':'||OLD.user_id::text||':'||txid_current()::text
  ) ON CONFLICT(organization_id,user_id,event_key)
    WHERE event_key IS NOT NULL DO NOTHING;
  RETURN OLD;
END $function$;

CREATE OR REPLACE FUNCTION ase_private.normalize_legacy_incident_notification() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
BEGIN
  IF NEW.incident_id IS NOT NULL AND NEW.event_key IS NULL THEN
    NEW.kind:=CASE
      WHEN NEW.message LIKE 'Nueva incidencia:%' THEN 'incident_created'
      ELSE 'incident_updated'
    END;
    NEW.event_key:='incident-legacy:'||NEW.incident_id::text||':'||NEW.user_id::text||':'||
      md5(NEW.message)||':'||txid_current()::text;
  END IF;
  RETURN NEW;
END $function$;

DROP TRIGGER IF EXISTS work_notify_removed_assignment ON public.task_assignments;
CREATE TRIGGER work_notify_removed_assignment
AFTER DELETE ON public.task_assignments FOR EACH ROW
EXECUTE FUNCTION ase_private.notify_removed_assignment();

DROP TRIGGER IF EXISTS work_normalize_legacy_incident_notification ON public.work_notifications;
CREATE TRIGGER work_normalize_legacy_incident_notification
BEFORE INSERT ON public.work_notifications FOR EACH ROW
EXECUTE FUNCTION ase_private.normalize_legacy_incident_notification();

ALTER FUNCTION ase_private.notify_removed_assignment() OWNER TO ase_tenant_executor;
ALTER FUNCTION ase_private.normalize_legacy_incident_notification() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.notify_removed_assignment(),ase_private.normalize_legacy_incident_notification()
  FROM PUBLIC,anon,authenticated;
REVOKE CREATE ON SCHEMA ase_private FROM ase_tenant_executor;

-- ==== 20261027000200_organization_user_capacity.sql ====
-- ASE Work: enforce the contracted user capacity per organization.

-- PostgreSQL requires the destination owner to have CREATE on the function's
-- schema while ownership is transferred. Keep this privilege transactional
-- and revoke it again before committing.
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

ALTER TABLE public.organizations
 ADD COLUMN IF NOT EXISTS user_limit integer NOT NULL DEFAULT 30;

DO $$
BEGIN
 IF NOT EXISTS (
  SELECT 1 FROM pg_constraint
  WHERE conrelid='public.organizations'::regclass
    AND conname='organizations_user_limit_check'
 ) THEN
  ALTER TABLE public.organizations
   ADD CONSTRAINT organizations_user_limit_check
   CHECK (user_limit BETWEEN 1 AND 10000);
 END IF;
END $$;

CREATE OR REPLACE FUNCTION public.work_organization_capacity()
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
 v_org uuid:=ase_private.current_org();
 v_limit integer;
 v_used integer;
BEGIN
 PERFORM public.work_assert_admin();
 SELECT user_limit INTO v_limit
 FROM public.organizations
 WHERE id=v_org AND status='active';
 IF NOT FOUND THEN RAISE EXCEPTION 'Empresa no disponible'; END IF;

 SELECT count(*)::integer INTO v_used
 FROM public.organization_memberships
 WHERE organization_id=v_org AND status IN ('active','invited');

 RETURN jsonb_build_object(
  'limit',v_limit,
  'used',v_used,
  'available',greatest(v_limit-v_used,0),
  'can_add',v_used<v_limit
 );
END $function$;

ALTER FUNCTION public.work_organization_capacity() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_organization_capacity() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_organization_capacity() TO authenticated,ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.mt_attach_created_employee(
 p_actor uuid,p_org uuid,p_user uuid,p_nonce text,p_name text,p_whatsapp text,p_role uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
 v_limit integer;
 v_used integer;
BEGIN
 -- Callable only with the backend service role. The Edge Function verifies the actor's JWT.
 PERFORM pg_advisory_xact_lock(hashtextextended(p_org::text,1702));
 PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,1701));
 IF NOT EXISTS(SELECT 1 FROM public.organization_memberships m JOIN public.organizations o ON o.id=m.organization_id
  WHERE m.user_id=p_actor AND m.organization_id=p_org AND m.role IN ('owner','admin') AND m.status='active' AND o.status='active') THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Administración no disponible';
 END IF;
 SELECT user_limit INTO v_limit FROM public.organizations WHERE id=p_org AND status='active';
 SELECT count(*)::integer INTO v_used FROM public.organization_memberships
  WHERE organization_id=p_org AND status IN ('active','invited');
 IF v_used>=v_limit THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='La empresa ha alcanzado su límite de usuarios';
 END IF;
 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 150 OR (p_whatsapp IS NOT NULL AND p_whatsapp !~ '^\+?[0-9]{7,15}$') THEN
  RAISE EXCEPTION 'Datos del empleado no válidos';
 END IF;
 IF p_nonce IS NULL OR length(p_nonce)<32 OR NOT EXISTS(SELECT 1 FROM auth.users WHERE id=p_user AND raw_user_meta_data->>'ase_onboarding_nonce'=p_nonce)
 OR EXISTS(SELECT 1 FROM public.organization_memberships WHERE user_id=p_user) THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No se confirmó una cuenta nueva para este empleado';
 END IF;
 IF p_role IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_roles WHERE id=p_role AND organization_id=p_org AND active) THEN RAISE EXCEPTION 'Rol no disponible'; END IF;
 INSERT INTO public.organization_memberships(organization_id,user_id,role,full_name,whatsapp)
 VALUES(p_org,p_user,'member',trim(p_name),p_whatsapp);
 IF p_role IS NOT NULL THEN
  INSERT INTO public.work_employee_roles(organization_id,user_id,role_id) VALUES(p_org,p_user,p_role);
 END IF;
 RETURN jsonb_build_object('id',p_user,'full_name',trim(p_name),'whatsapp',p_whatsapp,'role_id',p_role);
END $function$;

REVOKE ALL ON FUNCTION public.mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid) TO service_role;

REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261027000300_remove_organization_user_capacity.sql ====
-- ASE Work: remove the premature commercial user cap without touching users.

DROP FUNCTION IF EXISTS public.work_organization_capacity();

CREATE OR REPLACE FUNCTION public.mt_attach_created_employee(
 p_actor uuid,p_org uuid,p_user uuid,p_nonce text,p_name text,p_whatsapp text,p_role uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
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
 INSERT INTO public.organization_memberships(organization_id,user_id,role,full_name,whatsapp)
 VALUES(p_org,p_user,'member',trim(p_name),p_whatsapp);
 IF p_role IS NOT NULL THEN
  INSERT INTO public.work_employee_roles(organization_id,user_id,role_id) VALUES(p_org,p_user,p_role);
 END IF;
 RETURN jsonb_build_object('id',p_user,'full_name',trim(p_name),'whatsapp',p_whatsapp,'role_id',p_role);
END $function$;

REVOKE ALL ON FUNCTION public.mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid) TO service_role;

ALTER TABLE public.organizations DROP COLUMN IF EXISTS user_limit;

NOTIFY pgrst,'reload schema';

-- ==== 20261027000400_task_projects.sql ====
-- ASE Work: optional projects that group activities without changing execution.

CREATE TABLE IF NOT EXISTS public.work_projects(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_id uuid NOT NULL DEFAULT ase_private.current_org() REFERENCES public.organizations(id),
 name text NOT NULL CHECK(length(trim(name)) BETWEEN 1 AND 150),
 description text CHECK(description IS NULL OR length(description)<=2000),
 status text NOT NULL DEFAULT 'active' CHECK(status IN ('planned','active','completed','archived')),
 start_date date,end_date date,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(organization_id,id),CHECK(end_date IS NULL OR start_date IS NULL OR end_date>=start_date)
);
CREATE UNIQUE INDEX IF NOT EXISTS work_projects_name_unique ON public.work_projects(organization_id,lower(name));

CREATE TABLE IF NOT EXISTS public.work_project_tasks(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),project_id uuid NOT NULL,task_id uuid NOT NULL,
 linked_at timestamptz NOT NULL DEFAULT clock_timestamp(),linked_by uuid NOT NULL DEFAULT ase_private.session_user_id(),
 PRIMARY KEY(organization_id,task_id),
 FOREIGN KEY(organization_id,project_id) REFERENCES public.work_projects(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,linked_by) REFERENCES public.organization_memberships(organization_id,user_id)
);

ALTER TABLE public.work_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_project_tasks ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_projects,public.work_project_tasks FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_projects,public.work_project_tasks TO ase_tenant_executor;

CREATE POLICY work_projects_boundary ON public.work_projects AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY work_projects_executor ON public.work_projects TO ase_tenant_executor USING(true) WITH CHECK(true);
CREATE POLICY work_project_tasks_boundary ON public.work_project_tasks AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY work_project_tasks_executor ON public.work_project_tasks TO ase_tenant_executor USING(true) WITH CHECK(true);

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_projects_overview()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 SELECT jsonb_build_object(
  'projects',coalesce((SELECT jsonb_agg(to_jsonb(p)||jsonb_build_object(
   'task_ids',coalesce((SELECT jsonb_agg(x.task_id ORDER BY x.linked_at,x.task_id) FROM public.work_project_tasks x WHERE x.project_id=p.id),'[]'::jsonb)
  ) ORDER BY CASE p.status WHEN 'active' THEN 1 WHEN 'planned' THEN 2 WHEN 'completed' THEN 3 ELSE 4 END,p.name,p.id) FROM public.work_projects p),'[]'::jsonb)
 ) INTO result;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_save_project(p_id uuid,p_name text,p_description text,p_status text,p_start date,p_end date)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE result uuid;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 150 OR length(coalesce(p_description,''))>2000
  OR p_status NOT IN ('planned','active','completed','archived') OR (p_start IS NOT NULL AND p_end IS NOT NULL AND p_end<p_start) THEN
  RAISE EXCEPTION 'Revisa los datos del proyecto';
 END IF;
 IF p_id IS NULL THEN
  INSERT INTO public.work_projects(name,description,status,start_date,end_date)
  VALUES(trim(p_name),nullif(trim(coalesce(p_description,'')),''),p_status,p_start,p_end) RETURNING id INTO result;
 ELSE
  UPDATE public.work_projects SET name=trim(p_name),description=nullif(trim(coalesce(p_description,'')),''),status=p_status,start_date=p_start,end_date=p_end,updated_at=clock_timestamp()
  WHERE id=p_id RETURNING id INTO result;
  IF result IS NULL THEN RAISE EXCEPTION 'Proyecto no disponible'; END IF;
 END IF;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_set_task_project(p_task uuid,p_project uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE id=p_task) THEN RAISE EXCEPTION 'Actividad no disponible'; END IF;
 IF p_project IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_projects WHERE id=p_project AND status<>'archived') THEN RAISE EXCEPTION 'Proyecto no disponible'; END IF;
 DELETE FROM public.work_project_tasks WHERE task_id=p_task;
 IF p_project IS NOT NULL THEN INSERT INTO public.work_project_tasks(project_id,task_id) VALUES(p_project,p_task); END IF;
END $function$;

ALTER FUNCTION public.work_projects_overview() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_project(uuid,text,text,text,date,date) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_set_task_project(uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_projects_overview(),public.work_save_project(uuid,text,text,text,date,date),public.work_set_task_project(uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_projects_overview(),public.work_save_project(uuid,text,text,text,date,date),public.work_set_task_project(uuid,uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261027000500_project_milestones.sql ====
-- ASE Work: project milestones for intermediate delivery tracking.

CREATE TABLE IF NOT EXISTS public.work_project_milestones(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_id uuid NOT NULL DEFAULT ase_private.current_org() REFERENCES public.organizations(id),
 project_id uuid NOT NULL,
 title text NOT NULL CHECK(length(trim(title)) BETWEEN 1 AND 160),
 due_date date,
 completed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 created_by uuid NOT NULL DEFAULT ase_private.session_user_id(),
 UNIQUE(organization_id,id),
 FOREIGN KEY(organization_id,project_id) REFERENCES public.work_projects(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,created_by) REFERENCES public.organization_memberships(organization_id,user_id)
);

ALTER TABLE public.work_project_milestones ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_project_milestones FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_project_milestones TO ase_tenant_executor;

DO $policy$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_project_milestones' AND policyname='work_project_milestones_boundary') THEN
  CREATE POLICY work_project_milestones_boundary ON public.work_project_milestones AS RESTRICTIVE TO PUBLIC
   USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_project_milestones' AND policyname='work_project_milestones_executor') THEN
  CREATE POLICY work_project_milestones_executor ON public.work_project_milestones TO ase_tenant_executor USING(true) WITH CHECK(true);
 END IF;
END $policy$;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_projects_overview()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 SELECT jsonb_build_object(
  'projects',coalesce((SELECT jsonb_agg(to_jsonb(p)||jsonb_build_object(
   'task_ids',coalesce((SELECT jsonb_agg(x.task_id ORDER BY x.linked_at,x.task_id) FROM public.work_project_tasks x WHERE x.project_id=p.id),'[]'::jsonb),
   'milestones',coalesce((SELECT jsonb_agg(to_jsonb(m) ORDER BY m.completed_at IS NOT NULL,m.due_date NULLS LAST,m.created_at,m.id) FROM public.work_project_milestones m WHERE m.project_id=p.id),'[]'::jsonb)
  ) ORDER BY CASE p.status WHEN 'active' THEN 1 WHEN 'planned' THEN 2 WHEN 'completed' THEN 3 ELSE 4 END,p.name,p.id) FROM public.work_projects p),'[]'::jsonb)
 ) INTO result;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_save_project_milestone(p_id uuid,p_project uuid,p_title text,p_due date,p_completed boolean DEFAULT false)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE result uuid;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_title IS NULL OR length(trim(p_title)) NOT BETWEEN 1 AND 160
  OR NOT EXISTS(SELECT 1 FROM public.work_projects WHERE id=p_project AND status<>'archived') THEN
  RAISE EXCEPTION 'Revisa los datos del hito';
 END IF;
 IF p_id IS NULL THEN
  INSERT INTO public.work_project_milestones(project_id,title,due_date,completed_at)
  VALUES(p_project,trim(p_title),p_due,CASE WHEN p_completed THEN clock_timestamp() END)
  RETURNING id INTO result;
 ELSE
  UPDATE public.work_project_milestones SET title=trim(p_title),due_date=p_due,
   completed_at=CASE WHEN p_completed THEN coalesce(completed_at,clock_timestamp()) ELSE NULL END
  WHERE id=p_id AND project_id=p_project RETURNING id INTO result;
  IF result IS NULL THEN RAISE EXCEPTION 'Hito no disponible'; END IF;
 END IF;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_delete_project_milestone(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 DELETE FROM public.work_project_milestones WHERE id=p_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Hito no disponible'; END IF;
END $function$;

ALTER FUNCTION public.work_projects_overview() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_project_milestone(uuid,uuid,text,date,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_delete_project_milestone(uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_save_project_milestone(uuid,uuid,text,date,boolean),public.work_delete_project_milestone(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_save_project_milestone(uuid,uuid,text,date,boolean),public.work_delete_project_milestone(uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261027000600_project_owner.sql ====
-- ASE Work: optional project owner, independent from task executors.

ALTER TABLE public.work_projects ADD COLUMN IF NOT EXISTS owner_user_id uuid;
DO $constraint$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.work_projects'::regclass AND conname='work_projects_owner_membership_fk') THEN
  ALTER TABLE public.work_projects ADD CONSTRAINT work_projects_owner_membership_fk
   FOREIGN KEY(organization_id,owner_user_id) REFERENCES public.organization_memberships(organization_id,user_id);
 END IF;
END $constraint$;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_projects_overview()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 SELECT jsonb_build_object(
  'projects',coalesce((SELECT jsonb_agg(to_jsonb(p)||jsonb_build_object(
   'owner_name',(SELECT m.full_name FROM public.organization_memberships m WHERE m.organization_id=p.organization_id AND m.user_id=p.owner_user_id),
   'task_ids',coalesce((SELECT jsonb_agg(x.task_id ORDER BY x.linked_at,x.task_id) FROM public.work_project_tasks x WHERE x.project_id=p.id),'[]'::jsonb),
   'milestones',coalesce((SELECT jsonb_agg(to_jsonb(m) ORDER BY m.completed_at IS NOT NULL,m.due_date NULLS LAST,m.created_at,m.id) FROM public.work_project_milestones m WHERE m.project_id=p.id),'[]'::jsonb)
  ) ORDER BY CASE p.status WHEN 'active' THEN 1 WHEN 'planned' THEN 2 WHEN 'completed' THEN 3 ELSE 4 END,p.name,p.id) FROM public.work_projects p),'[]'::jsonb)
 ) INTO result;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_save_project_v2(p_id uuid,p_name text,p_description text,p_status text,p_start date,p_end date,p_owner uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE result uuid;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 150 OR length(coalesce(p_description,''))>2000
  OR p_status NOT IN ('planned','active','completed','archived') OR (p_start IS NOT NULL AND p_end IS NOT NULL AND p_end<p_start)
  OR (p_owner IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.organization_memberships WHERE user_id=p_owner AND status='active')) THEN
  RAISE EXCEPTION 'Revisa los datos del proyecto';
 END IF;
 IF p_id IS NULL THEN
  INSERT INTO public.work_projects(name,description,status,start_date,end_date,owner_user_id)
  VALUES(trim(p_name),nullif(trim(coalesce(p_description,'')),''),p_status,p_start,p_end,p_owner) RETURNING id INTO result;
 ELSE
  UPDATE public.work_projects SET name=trim(p_name),description=nullif(trim(coalesce(p_description,'')),''),status=p_status,start_date=p_start,end_date=p_end,owner_user_id=p_owner,updated_at=clock_timestamp()
  WHERE id=p_id RETURNING id INTO result;
  IF result IS NULL THEN RAISE EXCEPTION 'Proyecto no disponible'; END IF;
 END IF;
 RETURN result;
END $function$;

ALTER FUNCTION public.work_projects_overview() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_project_v2(uuid,text,text,text,date,date,uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_save_project_v2(uuid,text,text,text,date,date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_save_project_v2(uuid,text,text,text,date,date,uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261027000700_concurrency_hardening.sql ====
-- ASE Work: atomic task commands and idempotent manual check-in starts.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS version bigint NOT NULL DEFAULT 1;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.tasks'::regclass AND conname='tasks_version_positive') THEN
  ALTER TABLE public.tasks ADD CONSTRAINT tasks_version_positive CHECK(version>0);
 END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.work_task_commands(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 request_id uuid NOT NULL,
 task_id uuid NOT NULL,
 actor_id uuid NOT NULL DEFAULT ase_private.session_user_id(),
 action text NOT NULL CHECK(action IN('create','edit')),
 payload jsonb NOT NULL,
 resulting_version bigint NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,request_id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
ALTER TABLE public.work_task_commands ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_commands FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_task_commands TO ase_tenant_executor;
CREATE POLICY work_task_commands_boundary ON public.work_task_commands AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY work_task_commands_executor ON public.work_task_commands TO ase_tenant_executor USING(true) WITH CHECK(true);

CREATE TABLE IF NOT EXISTS public.work_manual_checkin_commands(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 request_id uuid NOT NULL,
 task_id uuid NOT NULL,
 checkin_id uuid NOT NULL,
 actor_id uuid NOT NULL DEFAULT ase_private.session_user_id(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,request_id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id),
 FOREIGN KEY(organization_id,checkin_id) REFERENCES public.checkins(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
ALTER TABLE public.work_manual_checkin_commands ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_manual_checkin_commands FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_manual_checkin_commands TO ase_tenant_executor;
CREATE POLICY work_manual_commands_boundary ON public.work_manual_checkin_commands AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY work_manual_commands_executor ON public.work_manual_checkin_commands TO ase_tenant_executor USING(true) WITH CHECK(true);

CREATE TABLE IF NOT EXISTS public.work_manual_finish_commands(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),request_id uuid NOT NULL,checkin_id uuid NOT NULL,
 actor_id uuid NOT NULL DEFAULT ase_private.session_user_id(),payload jsonb NOT NULL,result jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),PRIMARY KEY(organization_id,request_id),
 FOREIGN KEY(organization_id,checkin_id) REFERENCES public.checkins(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
ALTER TABLE public.work_manual_finish_commands ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_manual_finish_commands FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_manual_finish_commands TO ase_tenant_executor;
CREATE POLICY work_manual_finish_boundary ON public.work_manual_finish_commands AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY work_manual_finish_executor ON public.work_manual_finish_commands TO ase_tenant_executor USING(true) WITH CHECK(true);

CREATE OR REPLACE FUNCTION public.work_manage_task_atomic(
 p_action text,p_importance text,p_id uuid,p_title text,p_description text,p_schedule text,p_date date,p_status text,
 p_primary uuid,p_collaborators uuid[],p_followers uuid[],p_require_comment boolean,p_require_photo boolean,
 p_require_video boolean,p_require_file boolean,p_estimated_minutes integer,p_requires_review boolean,p_area uuid,
 p_labels text[],p_location text,p_source_module text,p_entity_type text,p_entity_reference text,p_entity_label text,
 p_require_result boolean,p_project uuid,p_expected_version bigint,p_request uuid
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE
 org uuid:=ase_private.current_org(); existing public.work_task_commands%ROWTYPE; current_version bigint;
 result uuid; result_version bigint; command_payload jsonb;
BEGIN
 IF org IS NULL OR p_request IS NULL OR p_action NOT IN('create','edit') THEN RAISE EXCEPTION 'Operación de tarea no válida'; END IF;
 command_payload:=jsonb_build_object('action',p_action,'id',p_id,'importance',p_importance,'title',p_title,'description',p_description,
  'schedule',p_schedule,'date',p_date,'status',p_status,'primary',p_primary,'collaborators',coalesce(p_collaborators,'{}'::uuid[]),
  'followers',coalesce(p_followers,'{}'::uuid[]),'require_comment',p_require_comment,'require_photo',p_require_photo,
  'require_video',p_require_video,'require_file',p_require_file,'estimated_minutes',p_estimated_minutes,'requires_review',p_requires_review,
  'area',p_area,'labels',coalesce(p_labels,'{}'::text[]),'location',p_location,'source_module',p_source_module,'entity_type',p_entity_type,
  'entity_reference',p_entity_reference,'entity_label',p_entity_label,'require_result',p_require_result,'project',p_project,
  'expected_version',p_expected_version);
 PERFORM pg_advisory_xact_lock(hashtextextended(p_request::text,2707));
 SELECT * INTO existing FROM public.work_task_commands WHERE organization_id=org AND request_id=p_request;
 IF FOUND THEN
  IF existing.payload IS DISTINCT FROM command_payload THEN RAISE EXCEPTION 'Identificador de operación ya utilizado'; END IF;
  RETURN jsonb_build_object('id',existing.task_id,'version',existing.resulting_version,'repeated',true);
 END IF;
 IF p_action='edit' THEN
  IF p_id IS NULL OR p_expected_version IS NULL THEN RAISE EXCEPTION 'La edición requiere la versión de la tarea'; END IF;
  SELECT version INTO current_version FROM public.tasks WHERE organization_id=org AND id=p_id FOR UPDATE;
  IF current_version IS NULL THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
  IF current_version<>p_expected_version THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='La tarea fue modificada por otra persona. Actualiza los datos antes de guardar'; END IF;
 END IF;
 result:=public.work_manage_task_outcome(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,
  coalesce(p_collaborators,'{}'::uuid[]),coalesce(p_followers,'{}'::uuid[]),p_require_comment,p_require_photo,p_require_video,
  p_require_file,p_estimated_minutes,p_requires_review,p_area,coalesce(p_labels,'{}'::text[]),p_location,p_source_module,
  p_entity_type,p_entity_reference,p_entity_label,p_require_result);
 PERFORM public.work_set_task_project(result,p_project);
 IF p_action='edit' THEN UPDATE public.tasks SET version=version+1 WHERE organization_id=org AND id=result RETURNING version INTO result_version;
 ELSE SELECT version INTO result_version FROM public.tasks WHERE organization_id=org AND id=result; END IF;
 INSERT INTO public.work_task_commands(organization_id,request_id,task_id,action,payload,resulting_version)
 VALUES(org,p_request,result,p_action,command_payload,result_version);
 RETURN jsonb_build_object('id',result,'version',result_version,'repeated',false);
END $function$;

CREATE OR REPLACE FUNCTION public.work_finish_manual_checkin_atomic(
 p_checkin uuid,p_plan uuid,p_result text,p_request uuid
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE
 actor uuid:=ase_private.session_user_id();org uuid:=ase_private.current_org();existing public.work_manual_finish_commands%ROWTYPE;
 checkin_row public.checkins%ROWTYPE;command_payload jsonb;outcome jsonb;
BEGIN
 IF actor IS NULL OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR org IS NULL THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión para fichar';
 END IF;
 IF p_checkin IS NULL OR p_request IS NULL THEN RAISE EXCEPTION 'Operación de cierre no válida'; END IF;
 command_payload:=jsonb_build_object('checkin',p_checkin,'plan',p_plan,'result',nullif(btrim(coalesce(p_result,'')),''));
 PERFORM pg_advisory_xact_lock(hashtextextended(p_request::text,2709));
 SELECT * INTO existing FROM public.work_manual_finish_commands WHERE organization_id=org AND request_id=p_request;
 IF FOUND THEN
  IF existing.payload IS DISTINCT FROM command_payload OR existing.actor_id<>actor THEN RAISE EXCEPTION 'Identificador de operación ya utilizado'; END IF;
  RETURN existing.result||jsonb_build_object('repeated',true);
 END IF;
 SELECT * INTO checkin_row FROM public.checkins WHERE organization_id=org AND id=p_checkin AND user_id=actor FOR UPDATE;
 IF checkin_row.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible para esta cuenta'; END IF;
 IF p_plan IS DISTINCT FROM checkin_row.work_plan_id THEN RAISE EXCEPTION 'La ejecución no corresponde al fichaje'; END IF;
 IF nullif(btrim(coalesce(p_result,'')),'') IS NOT NULL THEN PERFORM public.work_save_execution_result(p_plan,p_result); END IF;
 outcome:=public.finish_manual_checkin(p_checkin)::jsonb;
 INSERT INTO public.work_manual_finish_commands(organization_id,request_id,checkin_id,actor_id,payload,result)
 VALUES(org,p_request,p_checkin,actor,command_payload,outcome);
 RETURN outcome||jsonb_build_object('repeated',false);
END $function$;

CREATE OR REPLACE FUNCTION public.work_start_manual_checkin(
 p_task uuid,p_request uuid,p_latitude numeric DEFAULT NULL,p_longitude numeric DEFAULT NULL,p_location text DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE
 actor uuid:=ase_private.session_user_id();org uuid:=ase_private.current_org();existing public.work_manual_checkin_commands%ROWTYPE;
 result public.checkins%ROWTYPE;
BEGIN
 IF actor IS NULL OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR org IS NULL THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión para fichar';
 END IF;
 IF p_task IS NULL OR p_request IS NULL THEN RAISE EXCEPTION 'Operación de fichaje no válida'; END IF;
 IF public.work_mode() THEN RAISE EXCEPTION 'Está activo el modo exclusivo de punto compartido. Confirma allí el fichaje'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(p_request::text,2708));
 SELECT * INTO existing FROM public.work_manual_checkin_commands WHERE organization_id=org AND request_id=p_request;
 IF FOUND THEN
  IF existing.task_id<>p_task OR existing.actor_id<>actor THEN RAISE EXCEPTION 'Identificador de operación ya utilizado'; END IF;
  SELECT * INTO result FROM public.checkins WHERE organization_id=org AND id=existing.checkin_id;
  RETURN jsonb_build_object('success',true,'checkin',to_jsonb(result),'repeated',true);
 END IF;
 -- This membership lock serializes all starts for one employee. The existing
 -- BEFORE INSERT guard remains authoritative for order, assignment and plan identity.
 PERFORM 1 FROM public.organization_memberships WHERE organization_id=org AND user_id=actor AND status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Sesión no disponible'; END IF;
 PERFORM 1 FROM public.task_checkin_config c JOIN public.task_assignments a ON a.organization_id=org AND a.task_id=c.task_id AND a.user_id=actor
  WHERE c.organization_id=org AND c.task_id=p_task AND c.manual_enabled FOR SHARE OF c;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='El fichaje manual no está disponible para esta tarea'; END IF;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=org AND user_id=actor AND checkout_time IS NULL) THEN
  RAISE EXCEPTION 'Ya tienes un fichaje abierto. Finalízalo antes de iniciar otro';
 END IF;
 INSERT INTO public.checkins(task_id,user_id,checkin_method,location,latitude,longitude,qr_code,checkin_time)
 VALUES(p_task,actor,'manual',nullif(btrim(coalesce(p_location,'')),''),p_latitude,p_longitude,'Manual',clock_timestamp())
 RETURNING * INTO result;
 UPDATE public.tasks SET status='in_progress',last_checkin=result.checkin_time WHERE organization_id=org AND id=p_task AND status='pending';
 INSERT INTO public.work_manual_checkin_commands(organization_id,request_id,task_id,checkin_id,actor_id)
 VALUES(org,p_request,p_task,result.id,actor);
 RETURN jsonb_build_object('success',true,'checkin',to_jsonb(result),'repeated',false);
END $function$;

CREATE INDEX IF NOT EXISTS task_comments_stable_order ON public.task_comments(organization_id,task_id,created_at DESC,id DESC);
CREATE INDEX IF NOT EXISTS checkins_open_employee_lookup ON public.checkins(organization_id,user_id,checkin_time DESC) WHERE checkout_time IS NULL;

ALTER FUNCTION public.work_manage_task_atomic(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text,boolean,uuid,bigint,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_start_manual_checkin(uuid,uuid,numeric,numeric,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_finish_manual_checkin_atomic(uuid,uuid,text,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_atomic(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text,boolean,uuid,bigint,uuid),public.work_start_manual_checkin(uuid,uuid,numeric,numeric,text),public.work_finish_manual_checkin_atomic(uuid,uuid,text,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_atomic(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text,boolean,uuid,bigint,uuid),public.work_start_manual_checkin(uuid,uuid,numeric,numeric,text),public.work_finish_manual_checkin_atomic(uuid,uuid,text,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261027000800_safe_task_deletion.sql ====
-- ASE Work: idempotent deletion for unused tasks; operational history is preserved.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
GRANT DELETE ON public.work_importance_events,public.work_task_assignment_events TO ase_tenant_executor;
CREATE POLICY work_importance_delete_unused ON public.work_importance_events FOR DELETE TO ase_tenant_executor
 USING(organization_id=ase_private.current_org());

CREATE TABLE IF NOT EXISTS public.work_task_delete_commands(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),request_id uuid NOT NULL,
 task_id uuid NOT NULL,actor_id uuid NOT NULL DEFAULT ase_private.session_user_id(),
 expected_version bigint NOT NULL,result jsonb NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,request_id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
ALTER TABLE public.work_task_delete_commands ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_delete_commands FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_task_delete_commands TO ase_tenant_executor;
CREATE POLICY work_task_delete_boundary ON public.work_task_delete_commands AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY work_task_delete_executor ON public.work_task_delete_commands TO ase_tenant_executor USING(true) WITH CHECK(true);

CREATE OR REPLACE FUNCTION public.work_delete_task_safe(p_task uuid,p_expected_version bigint,p_request uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE org uuid:=ase_private.current_org();actor uuid:=ase_private.session_user_id();current_version bigint;has_recurrence boolean:=false;
 existing public.work_task_delete_commands%ROWTYPE;outcome jsonb;
BEGIN
 IF org IS NULL OR actor IS NULL OR p_task IS NULL OR p_expected_version IS NULL OR p_request IS NULL THEN
  RAISE EXCEPTION 'Operación de eliminación no válida';
 END IF;
 PERFORM public.work_assert_permission('tasks.delete');
 PERFORM pg_advisory_xact_lock(hashtextextended(p_request::text,2710));
 SELECT * INTO existing FROM public.work_task_delete_commands WHERE organization_id=org AND request_id=p_request;
 IF FOUND THEN
  IF existing.task_id<>p_task OR existing.actor_id<>actor OR existing.expected_version<>p_expected_version THEN
   RAISE EXCEPTION 'Identificador de operación ya utilizado';
  END IF;
  RETURN existing.result||jsonb_build_object('repeated',true);
 END IF;
 SELECT version INTO current_version FROM public.tasks WHERE organization_id=org AND id=p_task FOR UPDATE;
 IF current_version IS NULL THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF current_version<>p_expected_version THEN
  RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='La tarea fue modificada por otra persona. Actualiza los datos antes de eliminar';
 END IF;
 IF to_regclass('public.work_recurrences') IS NOT NULL THEN
  EXECUTE 'SELECT EXISTS(SELECT 1 FROM public.work_recurrences WHERE organization_id=$1 AND task_id=$2)' INTO has_recurrence USING org,p_task;
 END IF;
 IF EXISTS(SELECT 1 FROM public.work_day_plan WHERE organization_id=org AND task_id=p_task)
 OR EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=org AND task_id=p_task)
 OR EXISTS(SELECT 1 FROM public.task_comments WHERE organization_id=org AND task_id=p_task)
 OR EXISTS(SELECT 1 FROM public.work_incidents WHERE organization_id=org AND task_id=p_task)
 OR has_recurrence THEN
  RAISE EXCEPTION 'Esta actividad ya tiene historial operativo y no se puede eliminar. Conserva sus registros para auditoría';
 END IF;
 -- Assignment/importance events are catalog audit for an activity that was never
 -- executed. Remove them with the unused catalog item; operational history above
 -- is never removed. Delete assignments explicitly because their audit trigger
 -- would otherwise create a new FK reference during the task cascade.
 DELETE FROM public.work_importance_events WHERE organization_id=org AND task_id=p_task;
 DELETE FROM public.task_assignments WHERE organization_id=org AND task_id=p_task;
 DELETE FROM public.work_task_assignment_events WHERE organization_id=org AND task_id=p_task;
 DELETE FROM public.tasks WHERE organization_id=org AND id=p_task;
 IF NOT FOUND THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 outcome:=jsonb_build_object('success',true,'task_id',p_task,'deleted_at',clock_timestamp());
 INSERT INTO public.work_task_delete_commands(organization_id,request_id,task_id,actor_id,expected_version,result)
 VALUES(org,p_request,p_task,actor,p_expected_version,outcome);
 RETURN outcome||jsonb_build_object('repeated',false);
END $function$;

ALTER FUNCTION public.work_delete_task_safe(uuid,bigint,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_delete_task_safe(uuid,bigint,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_delete_task_safe(uuid,bigint,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261027000900_task_archiving.sql ====
-- ASE Work: reversible task archiving that preserves operational history.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
GRANT CREATE ON SCHEMA ase_private TO ase_tenant_executor;

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS archived_at timestamptz;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS archived_by uuid;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.tasks'::regclass AND conname='tasks_archived_by_membership')THEN
 ALTER TABLE public.tasks ADD CONSTRAINT tasks_archived_by_membership FOREIGN KEY(organization_id,archived_by)
  REFERENCES public.organization_memberships(organization_id,user_id);
END IF;END $$;

CREATE TABLE IF NOT EXISTS public.work_task_archive_events(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),id uuid NOT NULL DEFAULT gen_random_uuid(),
 task_id uuid NOT NULL,actor_id uuid NOT NULL DEFAULT ase_private.session_user_id(),request_id uuid NOT NULL,
 action text NOT NULL CHECK(action IN('archive','restore')),reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 5 AND 1000),
 resulting_version bigint NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id),UNIQUE(organization_id,request_id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
ALTER TABLE public.work_task_archive_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_archive_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_task_archive_events TO ase_tenant_executor;
DROP POLICY IF EXISTS work_task_archive_boundary ON public.work_task_archive_events;
DROP POLICY IF EXISTS work_task_archive_executor ON public.work_task_archive_events;
CREATE POLICY work_task_archive_boundary ON public.work_task_archive_events AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY work_task_archive_executor ON public.work_task_archive_events TO ase_tenant_executor USING(true) WITH CHECK(true);

CREATE OR REPLACE FUNCTION ase_private.guard_archived_task() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
BEGIN
 IF OLD.archived_at IS NOT NULL AND coalesce(current_setting('ase.archive_command',true),'off')<>'on' THEN
  RAISE EXCEPTION 'La actividad está archivada. Restáurala antes de modificarla';
 END IF;
 RETURN NEW;
END $function$;
DROP TRIGGER IF EXISTS work_guard_archived_task ON public.tasks;
CREATE TRIGGER work_guard_archived_task BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION ase_private.guard_archived_task();
ALTER FUNCTION ase_private.guard_archived_task() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.guard_archived_task() FROM PUBLIC,anon,authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA ase_private FROM ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_change_task_archive(
 p_task uuid,p_action text,p_expected_version bigint,p_reason text,p_request uuid
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE org uuid:=ase_private.current_org();actor uuid:=ase_private.session_user_id();row_value public.tasks%ROWTYPE;
 existing public.work_task_archive_events%ROWTYPE;clean_reason text:=btrim(coalesce(p_reason,''));has_active_recurrence boolean:=false;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF org IS NULL OR actor IS NULL OR p_task IS NULL OR p_action NOT IN('archive','restore') OR p_expected_version IS NULL
  OR p_request IS NULL OR length(clean_reason)NOT BETWEEN 5 AND 1000 THEN RAISE EXCEPTION 'Revisa la acción y escribe un motivo de al menos 5 caracteres';END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(p_request::text,2711));
 SELECT * INTO existing FROM public.work_task_archive_events WHERE organization_id=org AND request_id=p_request;
 IF FOUND THEN
  IF existing.task_id<>p_task OR existing.actor_id<>actor OR existing.action<>p_action OR existing.reason<>clean_reason THEN RAISE EXCEPTION 'Identificador de operación ya utilizado';END IF;
  RETURN jsonb_build_object('success',true,'task_id',p_task,'archived',p_action='archive','version',existing.resulting_version,'repeated',true);
 END IF;
 SELECT * INTO row_value FROM public.tasks WHERE organization_id=org AND id=p_task FOR UPDATE;
 IF row_value.id IS NULL THEN RAISE EXCEPTION 'La tarea ya no existe';END IF;
 IF row_value.version<>p_expected_version THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='La tarea fue modificada por otra persona. Actualiza los datos antes de continuar';END IF;
 IF p_action='archive' THEN
  IF row_value.archived_at IS NOT NULL THEN RAISE EXCEPTION 'La actividad ya está archivada';END IF;
  IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=org AND task_id=p_task AND checkout_time IS NULL)
   OR EXISTS(SELECT 1 FROM public.work_day_plan WHERE organization_id=org AND task_id=p_task AND state NOT IN('completed','cancelled')) THEN
   RAISE EXCEPTION 'Finaliza o cancela primero las ejecuciones pendientes, activas o bloqueadas';
  END IF;
  IF to_regclass('public.work_recurrences')IS NOT NULL THEN
   EXECUTE 'SELECT EXISTS(SELECT 1 FROM public.work_recurrences WHERE organization_id=$1 AND task_id=$2 AND active)' INTO has_active_recurrence USING org,p_task;
  END IF;
  IF has_active_recurrence THEN RAISE EXCEPTION 'Pausa primero las repeticiones activas de esta actividad';END IF;
 END IF;
 PERFORM set_config('ase.archive_command','on',true);
 UPDATE public.tasks SET archived_at=CASE WHEN p_action='archive'THEN clock_timestamp()ELSE NULL END,
  archived_by=CASE WHEN p_action='archive'THEN actor ELSE NULL END,version=version+1
 WHERE organization_id=org AND id=p_task RETURNING * INTO row_value;
 IF p_action='archive'THEN UPDATE public.task_access_codes SET is_active=false WHERE organization_id=org AND task_id=p_task AND is_active;END IF;
 INSERT INTO public.work_task_archive_events(organization_id,task_id,actor_id,request_id,action,reason,resulting_version)
 VALUES(org,p_task,actor,p_request,p_action,clean_reason,row_value.version);
 RETURN jsonb_build_object('success',true,'task_id',p_task,'archived',p_action='archive','version',row_value.version,'repeated',false);
END $function$;

ALTER FUNCTION public.work_change_task_archive(uuid,text,bigint,text,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_change_task_archive(uuid,text,bigint,text,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_change_task_archive(uuid,text,bigint,text,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261102000100_archived_task_boundaries.sql ====
-- ASE Work: archived activities remain historical and cannot receive new operational links.

GRANT CREATE ON SCHEMA ase_private TO ase_tenant_executor;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION ase_private.guard_archived_task_reference() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE field_name text;task_value uuid;task_archived timestamptz;
BEGIN
 FOREACH field_name IN ARRAY TG_ARGV LOOP
  task_value:=nullif(to_jsonb(NEW)->>field_name,'')::uuid;
  IF task_value IS NULL THEN CONTINUE;END IF;
  SELECT archived_at INTO task_archived FROM public.tasks
   WHERE organization_id=NEW.organization_id AND id=task_value;
  IF NOT FOUND THEN RAISE EXCEPTION 'La actividad ya no está disponible';END IF;
  IF task_archived IS NOT NULL THEN
   RAISE EXCEPTION 'La actividad está archivada. Restáurala antes de volver a utilizarla';
  END IF;
 END LOOP;
 RETURN NEW;
END $function$;

DO $block$
DECLARE item record;trigger_name text;columns_sql text;
BEGIN
 FOR item IN SELECT * FROM(VALUES
  ('task_assignments',ARRAY['task_id']::text[]),
  ('task_access_codes',ARRAY['task_id']::text[]),
  ('nfc_cards',ARRAY['task_id']::text[]),
  ('work_day_plan',ARRAY['task_id']::text[]),
  ('work_recurrences',ARRAY['task_id']::text[]),
  ('work_project_tasks',ARRAY['task_id']::text[]),
  ('work_checklist_templates',ARRAY['task_id']::text[]),
  ('work_task_areas',ARRAY['task_id']::text[]),
  ('work_task_labels',ARRAY['task_id']::text[]),
  ('work_task_followers',ARRAY['task_id']::text[]),
  ('work_task_templates',ARRAY['source_task_id']::text[]),
  ('work_task_subtasks',ARRAY['parent_task_id','child_task_id']::text[]),
  ('work_task_dependencies',ARRAY['task_id','prerequisite_task_id']::text[])
 )v(table_name,field_names)
 LOOP
  IF to_regclass('public.'||item.table_name)IS NULL THEN CONTINUE;END IF;
  trigger_name:='work_guard_archived_reference_'||item.table_name;
  columns_sql:=array_to_string(ARRAY(SELECT format('%I',x)FROM unnest(item.field_names)x),',');
  EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I',trigger_name,item.table_name);
  EXECUTE format('CREATE TRIGGER %I BEFORE INSERT OR UPDATE OF %s ON public.%I FOR EACH ROW EXECUTE FUNCTION ase_private.guard_archived_task_reference(%s)',
   trigger_name,columns_sql,item.table_name,array_to_string(ARRAY(SELECT quote_literal(x)FROM unnest(item.field_names)x),','));
 END LOOP;
END $block$;

ALTER FUNCTION ase_private.guard_archived_task_reference() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.guard_archived_task_reference() FROM PUBLIC,anon,authenticated,ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_duplicate_task(p_task uuid,p_title text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE source public.tasks%ROWTYPE;result uuid;primary_user uuid;collaborators uuid[];followers uuid[];area uuid;labels text[];steps jsonb;new_title text;
BEGIN
 PERFORM public.work_assert_permission('tasks.create');
 SELECT * INTO source FROM public.tasks WHERE organization_id=ase_private.current_org()AND id=p_task AND archived_at IS NULL FOR SHARE;
 IF source.id IS NULL THEN RAISE EXCEPTION 'La actividad no está disponible o se encuentra archivada';END IF;
 new_title:=btrim(coalesce(nullif(p_title,''),source.title||' (copia)'));
 IF length(new_title)NOT BETWEEN 1 AND 200 THEN RAISE EXCEPTION 'El título debe tener entre 1 y 200 caracteres';END IF;
 SELECT user_id INTO primary_user FROM public.task_assignments WHERE organization_id=source.organization_id AND task_id=source.id AND responsibility_role='primary'ORDER BY user_id LIMIT 1;
 SELECT coalesce(array_agg(user_id ORDER BY user_id),'{}'::uuid[])INTO collaborators FROM public.task_assignments WHERE organization_id=source.organization_id AND task_id=source.id AND responsibility_role<>'primary';
 SELECT coalesce(array_agg(user_id ORDER BY user_id),'{}'::uuid[])INTO followers FROM public.work_task_followers WHERE organization_id=source.organization_id AND task_id=source.id;
 SELECT area_id INTO area FROM public.work_task_areas WHERE organization_id=source.organization_id AND task_id=source.id;
 SELECT coalesce(array_agg(label ORDER BY normalized),'{}'::text[])INTO labels FROM public.work_task_labels WHERE organization_id=source.organization_id AND task_id=source.id;
 result:=public.work_manage_task_outcome('create',source.importance,NULL,new_title,source.description,source.schedule_type,source.schedule_date,'pending',primary_user,collaborators,followers,source.require_comment,source.require_photo,source.require_video,source.require_file,source.estimated_minutes,source.requires_review,area,labels,source.location,source.source_module,source.related_entity_type,source.related_entity_reference,source.related_entity_label,source.require_result);
 SELECT c.steps INTO steps FROM public.work_checklist_templates c WHERE c.organization_id=source.organization_id AND c.task_id=source.id;
 IF steps IS NOT NULL THEN INSERT INTO public.work_checklist_templates(organization_id,task_id,steps)VALUES(source.organization_id,result,steps);END IF;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_task_template_directory()RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $function$
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',x.id,'name',x.name,'description',x.description,'source_task_id',x.source_task_id,'source_title',t.title,'source_archived',t.archived_at IS NOT NULL,'importance',t.importance,'updated_at',x.updated_at)ORDER BY x.name,x.id)FROM public.work_task_templates x JOIN public.tasks t ON t.organization_id=x.organization_id AND t.id=x.source_task_id WHERE x.organization_id=ase_private.current_org()),'[]'::jsonb);
END $function$;

ALTER FUNCTION public.work_duplicate_task(uuid,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_template_directory() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_duplicate_task(uuid,text),public.work_task_template_directory() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_duplicate_task(uuid,text),public.work_task_template_directory() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE CREATE ON SCHEMA ase_private FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261102000200_archive_timeline.sql ====
-- ASE Work: include archive and restore events in the complete task timeline.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_task_timeline(p_task uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $function$
DECLARE result jsonb;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=ase_private.current_org() AND id=p_task) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF NOT(public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id()) OR EXISTS(SELECT 1 FROM public.work_task_followers WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes consultar esta tarea'; END IF;
 WITH events AS (
  SELECT 'created:'||t.id::text id,'created' kind,'Tarea creada' title,t.title detail,'Sistema' actor_name,t.created_at FROM public.tasks t WHERE t.organization_id=ase_private.current_org() AND t.id=p_task
  UNION ALL SELECT 'assignment:'||e.id::text,'assignment_'||e.action,CASE e.action WHEN 'assigned' THEN 'Empleado asignado' ELSE 'Empleado retirado' END,e.employee_name,e.actor_name,e.created_at FROM public.work_task_assignment_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'importance:'||e.id::text,'importance','Importancia modificada',coalesce(CASE e.previous WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,'Creación')||' → '||CASE e.current_value WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,e.actor_name,e.created_at FROM public.work_importance_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'schedule:'||e.id::text,'schedule','Planificación modificada',CASE e.current_value->>'schedule_kind' WHEN 'anytime' THEN 'En cualquier momento' WHEN 'deadline' THEN 'Antes de una fecha' WHEN 'window' THEN 'Ventana de ejecución' WHEN 'scheduled' THEN 'Fecha u hora concreta' WHEN 'period' THEN 'Periodo planificado' ELSE 'Planificación actualizada' END,e.actor_name,e.created_at FROM public.work_execution_schedule_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
  UNION ALL SELECT 'state:'||e.id::text,'state','Estado modificado',CASE e.from_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'paused' THEN 'Pausada' WHEN 'review' THEN 'En revisión' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' WHEN 'cancelled' THEN 'Cancelada' ELSE e.from_state END||' → '||CASE e.to_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'paused' THEN 'Pausada' WHEN 'review' THEN 'En revisión' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' WHEN 'cancelled' THEN 'Cancelada' ELSE e.to_state END||' · '||e.reason,e.actor_name,e.created_at FROM public.work_board_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
  UNION ALL SELECT 'result:'||e.id::text,'execution_result','Resultado de la ejecución registrado',e.result_summary,coalesce(u.full_name,'Sistema'),e.created_at FROM public.work_execution_result_events e LEFT JOIN ase_private.employee_profiles u ON u.id=e.actor_id WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'archive:'||e.id::text,'archive_'||e.action,CASE e.action WHEN 'archive' THEN 'Actividad archivada' ELSE 'Actividad restaurada' END,e.reason,coalesce(m.full_name,'Sistema'),e.created_at FROM public.work_task_archive_events e LEFT JOIN public.organization_memberships m ON m.organization_id=e.organization_id AND m.user_id=e.actor_id WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
 ),page AS(SELECT * FROM events ORDER BY created_at DESC,id DESC LIMIT 250)
 SELECT coalesce(jsonb_agg(to_jsonb(page) ORDER BY created_at DESC,id DESC),'[]'::jsonb) INTO result FROM page;
 RETURN result;
END $function$;

ALTER FUNCTION public.work_task_timeline(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_task_timeline(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_timeline(uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261102000300_strict_unused_task_deletion.sql ====
-- ASE Work: permanent deletion is reserved for genuinely unused catalog mistakes.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_delete_task_safe(p_task uuid,p_expected_version bigint,p_request uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE org uuid:=ase_private.current_org();actor uuid:=ase_private.session_user_id();current_version bigint;has_recurrence boolean:=false;has_catalog_link boolean:=false;
 existing public.work_task_delete_commands%ROWTYPE;outcome jsonb;
BEGIN
 IF org IS NULL OR actor IS NULL OR p_task IS NULL OR p_expected_version IS NULL OR p_request IS NULL THEN RAISE EXCEPTION 'Operación de eliminación no válida';END IF;
 PERFORM public.work_assert_permission('tasks.delete');
 PERFORM pg_advisory_xact_lock(hashtextextended(p_request::text,2710));
 SELECT * INTO existing FROM public.work_task_delete_commands WHERE organization_id=org AND request_id=p_request;
 IF FOUND THEN
  IF existing.task_id<>p_task OR existing.actor_id<>actor OR existing.expected_version<>p_expected_version THEN RAISE EXCEPTION 'Identificador de operación ya utilizado';END IF;
  RETURN existing.result||jsonb_build_object('repeated',true);
 END IF;
 SELECT version INTO current_version FROM public.tasks WHERE organization_id=org AND id=p_task FOR UPDATE;
 IF current_version IS NULL THEN RAISE EXCEPTION 'La tarea ya no existe';END IF;
 IF current_version<>p_expected_version THEN RAISE EXCEPTION USING ERRCODE='40001',MESSAGE='La tarea fue modificada por otra persona. Actualiza los datos antes de eliminar';END IF;
 IF EXISTS(SELECT 1 FROM public.work_task_archive_events WHERE organization_id=org AND task_id=p_task)THEN
  RAISE EXCEPTION 'Esta actividad tiene historial de archivado y no se puede eliminar. Consérvala para auditoría';
 END IF;
 IF to_regclass('public.work_recurrences')IS NOT NULL THEN EXECUTE 'SELECT EXISTS(SELECT 1 FROM public.work_recurrences WHERE organization_id=$1 AND task_id=$2)'INTO has_recurrence USING org,p_task;END IF;
 IF EXISTS(SELECT 1 FROM public.work_day_plan WHERE organization_id=org AND task_id=p_task)
 OR EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=org AND task_id=p_task)
 OR EXISTS(SELECT 1 FROM public.task_comments WHERE organization_id=org AND task_id=p_task)
 OR EXISTS(SELECT 1 FROM public.work_incidents WHERE organization_id=org AND task_id=p_task)
 OR has_recurrence THEN RAISE EXCEPTION 'Esta actividad ya tiene historial operativo y no se puede eliminar. Archívala para conservar sus registros';END IF;
 IF to_regclass('public.work_task_templates')IS NOT NULL THEN EXECUTE 'SELECT EXISTS(SELECT 1 FROM public.work_task_templates WHERE organization_id=$1 AND source_task_id=$2)'INTO has_catalog_link USING org,p_task;END IF;
 IF NOT has_catalog_link AND to_regclass('public.work_project_tasks')IS NOT NULL THEN EXECUTE 'SELECT EXISTS(SELECT 1 FROM public.work_project_tasks WHERE organization_id=$1 AND task_id=$2)'INTO has_catalog_link USING org,p_task;END IF;
 IF NOT has_catalog_link AND to_regclass('public.work_task_subtasks')IS NOT NULL THEN EXECUTE 'SELECT EXISTS(SELECT 1 FROM public.work_task_subtasks WHERE organization_id=$1 AND(parent_task_id=$2 OR child_task_id=$2))'INTO has_catalog_link USING org,p_task;END IF;
 IF NOT has_catalog_link AND to_regclass('public.work_task_dependencies')IS NOT NULL THEN EXECUTE 'SELECT EXISTS(SELECT 1 FROM public.work_task_dependencies WHERE organization_id=$1 AND(task_id=$2 OR prerequisite_task_id=$2))'INTO has_catalog_link USING org,p_task;END IF;
 IF has_catalog_link THEN RAISE EXCEPTION 'Retira primero esta actividad de plantillas, proyectos, subtareas o dependencias';END IF;
 DELETE FROM public.work_importance_events WHERE organization_id=org AND task_id=p_task;
 DELETE FROM public.task_assignments WHERE organization_id=org AND task_id=p_task;
 DELETE FROM public.work_task_assignment_events WHERE organization_id=org AND task_id=p_task;
 DELETE FROM public.tasks WHERE organization_id=org AND id=p_task;
 IF NOT FOUND THEN RAISE EXCEPTION 'La tarea ya no existe';END IF;
 outcome:=jsonb_build_object('success',true,'task_id',p_task,'deleted_at',clock_timestamp());
 INSERT INTO public.work_task_delete_commands(organization_id,request_id,task_id,actor_id,expected_version,result)VALUES(org,p_request,p_task,actor,p_expected_version,outcome);
 RETURN outcome||jsonb_build_object('repeated',false);
END $function$;

ALTER FUNCTION public.work_delete_task_safe(uuid,bigint,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_delete_task_safe(uuid,bigint,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_delete_task_safe(uuid,bigint,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261102000400_active_task_selectors.sql ====
-- ASE Work: archived activities stay in history but cannot be selected for new work.

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_planning_assignments(p_user uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',t.id,'title',t.title) ORDER BY t.title,t.id),'[]'::jsonb)
 INTO result
 FROM public.tasks t
 WHERE t.organization_id=ase_private.current_org()
   AND t.archived_at IS NULL
   AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=t.id AND a.user_id=p_user);
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_recurrence_list()
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 RETURN jsonb_build_object(
  'automation_ready',ase_private.recurrence_scheduler_ready(),
  'areas',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'name',a.name,'members',(SELECT coalesce(jsonb_agg(user_id),'[]'::jsonb) FROM public.work_area_members WHERE area_id=a.id))) FROM public.work_areas a WHERE active),'[]'::jsonb),
  'tasks',coalesce((SELECT jsonb_agg(jsonb_build_object('id',id,'title',title) ORDER BY title) FROM public.tasks WHERE organization_id=ase_private.current_org() AND archived_at IS NULL),'[]'::jsonb),
  'items',coalesce((SELECT jsonb_agg(to_jsonb(r)||jsonb_build_object('title',t.title,'employee',u.full_name,'area_name',a.name,'runs',
   (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.due DESC),'[]'::jsonb) FROM (
    SELECT x.due,p.id plan_id,p.user_id,p.state,p.finished_at,x.notified_at,u.full_name employee FROM public.work_recurrence_runs x JOIN public.work_day_plan p ON p.id=x.plan_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE x.recurrence_id=r.id
    UNION ALL SELECT d.due,NULL::uuid,NULL::uuid,'unassigned'::text,NULL::timestamptz,d.notified_at,NULL::text FROM public.work_area_recurrence_due d WHERE d.recurrence_id=r.id AND d.plan_id IS NULL ORDER BY due DESC
   ) x)) ORDER BY r.created_at DESC)
   FROM public.work_recurrences r JOIN public.tasks t ON t.id=r.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=r.user_id LEFT JOIN public.work_areas a ON a.id=r.area_id),'[]'::jsonb)
 );
END $function$;

ALTER FUNCTION public.work_planning_assignments(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_recurrence_list() OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_assignments(uuid),public.work_recurrence_list() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_assignments(uuid),public.work_recurrence_list() TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';

-- ==== 20261102000500_lock_trigger_function_execution.sql ====
-- ASE Work: trigger helpers are internal and must not be callable through the API.

REVOKE ALL ON FUNCTION public.work_execution_schedule_defaults() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_execution_schedule_defaults() TO ase_tenant_executor;

NOTIFY pgrst,'reload schema';

-- ==== 20261102000600_lock_private_schema_execution.sql ====
-- ASE Work: the private schema is deny-by-default for API roles.

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA ase_private FROM PUBLIC,anon,authenticated;

-- Policies need the organization context for authenticated requests.
GRANT EXECUTE ON FUNCTION ase_private.current_org() TO authenticated,ase_tenant_executor;

-- Hosted Auth is exposed only through these identity helpers.
GRANT EXECUTE ON FUNCTION ase_private.session_user_id(),ase_private.session_role()
 TO anon,authenticated,ase_tenant_executor;

NOTIFY pgrst,'reload schema';

-- ==== 20261102000700_complete_tenant_boundaries.sql ====
-- ASE Work: every organization-owned relation has its own tenant boundary.

DROP POLICY IF EXISTS work_task_templates_executor ON public.work_task_templates;
CREATE POLICY work_task_templates_executor ON public.work_task_templates TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

DROP POLICY IF EXISTS work_task_template_events_executor ON public.work_task_template_events;
CREATE POLICY work_task_template_events_executor ON public.work_task_template_events TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

DROP POLICY IF EXISTS work_task_subtasks_executor ON public.work_task_subtasks;
CREATE POLICY work_task_subtasks_executor ON public.work_task_subtasks TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

DROP POLICY IF EXISTS work_task_subtask_events_executor ON public.work_task_subtask_events;
CREATE POLICY work_task_subtask_events_executor ON public.work_task_subtask_events TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

DROP POLICY IF EXISTS work_task_dependencies_executor ON public.work_task_dependencies;
CREATE POLICY work_task_dependencies_executor ON public.work_task_dependencies TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

DROP POLICY IF EXISTS work_task_dependency_events_executor ON public.work_task_dependency_events;
CREATE POLICY work_task_dependency_events_executor ON public.work_task_dependency_events TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

NOTIFY pgrst,'reload schema';

-- ==== 20261102000800_complete_tenant_foreign_keys.sql ====
-- ASE Work: tenant-owned relations cannot reference a row from another organization.

DO $audit$
BEGIN
 IF EXISTS(SELECT 1 FROM public.work_comment_mentions x JOIN public.task_comments y ON y.id=x.comment_id WHERE x.organization_id<>y.organization_id) THEN
  RAISE EXCEPTION 'Hay menciones enlazadas con comentarios de otra empresa';
 END IF;
 IF EXISTS(SELECT 1 FROM public.work_execution_result_events x JOIN public.work_day_plan y ON y.id=x.plan_id WHERE x.organization_id<>y.organization_id) THEN
  RAISE EXCEPTION 'Hay resultados enlazados con ejecuciones de otra empresa';
 END IF;
 IF EXISTS(SELECT 1 FROM public.work_execution_result_events x JOIN public.tasks y ON y.id=x.task_id WHERE x.organization_id<>y.organization_id) THEN
  RAISE EXCEPTION 'Hay resultados enlazados con tareas de otra empresa';
 END IF;
 IF EXISTS(SELECT 1 FROM public.work_time_adjustments x JOIN public.checkins y ON y.id=x.checkin_id WHERE x.organization_id<>y.organization_id) THEN
  RAISE EXCEPTION 'Hay ajustes enlazados con fichajes de otra empresa';
 END IF;
END $audit$;

ALTER TABLE public.task_comments
 ADD CONSTRAINT task_comments_org_id_key UNIQUE(organization_id,id);

ALTER TABLE public.work_comment_mentions
 DROP CONSTRAINT work_comment_mentions_comment_id_fkey,
 ADD CONSTRAINT work_comment_mentions_comment_org_fkey
  FOREIGN KEY(organization_id,comment_id) REFERENCES public.task_comments(organization_id,id) ON DELETE CASCADE;

ALTER TABLE public.work_execution_result_events
 DROP CONSTRAINT work_execution_result_events_plan_id_fkey,
 DROP CONSTRAINT work_execution_result_events_task_id_fkey,
 ADD CONSTRAINT work_execution_result_events_plan_org_fkey
  FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id) ON DELETE CASCADE,
 ADD CONSTRAINT work_execution_result_events_task_org_fkey
  FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE;

ALTER TABLE public.work_time_adjustments
 DROP CONSTRAINT work_time_adjustments_checkin_id_fkey,
 ADD CONSTRAINT work_time_adjustments_checkin_org_fkey
  FOREIGN KEY(organization_id,checkin_id) REFERENCES public.checkins(organization_id,id);

NOTIFY pgrst,'reload schema';

-- ==== 20261102000900_index_foreign_keys.sql ====
-- ASE Work: add supporting indexes for every public foreign key.

DO $indexes$
DECLARE
 relation record;
BEGIN
 FOR relation IN
  SELECT
   source_schema.nspname AS schema_name,
   source.relname AS table_name,
   c.conname AS constraint_name,
   string_agg(quote_ident(attribute.attname),',' ORDER BY key_column.position) AS columns_sql
  FROM pg_constraint c
  JOIN pg_class source ON source.oid=c.conrelid
  JOIN pg_namespace source_schema ON source_schema.oid=source.relnamespace
  CROSS JOIN LATERAL unnest(c.conkey) WITH ORDINALITY AS key_column(attribute_number,position)
  JOIN pg_attribute attribute ON attribute.attrelid=c.conrelid AND attribute.attnum=key_column.attribute_number
  WHERE c.contype='f' AND source_schema.nspname='public'
   AND NOT EXISTS(
    SELECT 1
    FROM pg_index i
    WHERE i.indrelid=c.conrelid
     AND i.indisvalid
     AND i.indisready
     AND i.indpred IS NULL
     AND i.indnkeyatts>=cardinality(c.conkey)
     AND NOT EXISTS(
      SELECT 1
      FROM generate_subscripts(c.conkey,1) position
      WHERE i.indkey[position-1]<>c.conkey[position]
     )
   )
  GROUP BY source_schema.nspname,source.relname,c.conname
  ORDER BY source.relname,c.conname
 LOOP
  EXECUTE format(
   'CREATE INDEX %I ON %I.%I (%s)',
   'ase_fk_'||substr(md5(relation.table_name||':'||relation.constraint_name),1,20),
   relation.schema_name,
   relation.table_name,
   relation.columns_sql
  );
 END LOOP;
END $indexes$;

-- ==== 20261102001000_secure_default_privileges.sql ====
-- ASE Work: future functions start private instead of executable by PUBLIC.

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
 REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA ase_private
 REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE ase_tenant_executor IN SCHEMA public
 REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE ase_tenant_executor IN SCHEMA ase_private
 REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
COMMIT;
