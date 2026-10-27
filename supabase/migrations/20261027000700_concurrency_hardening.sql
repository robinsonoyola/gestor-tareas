-- ASE Work: atomic task commands and idempotent manual check-in starts.
BEGIN;
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
COMMIT;
