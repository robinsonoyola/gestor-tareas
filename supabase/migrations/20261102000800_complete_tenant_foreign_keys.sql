-- ASE Work: tenant-owned relations cannot reference a row from another organization.
BEGIN;

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
COMMIT;
