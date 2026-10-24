-- ASE Work: deduplicated operational notifications.
BEGIN;

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

COMMIT;
