-- ASE Work: reversible task archiving that preserves operational history.
BEGIN;
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
COMMIT;
