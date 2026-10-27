-- ASE Work: idempotent deletion for unused tasks; operational history is preserved.
BEGIN;
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
COMMIT;
