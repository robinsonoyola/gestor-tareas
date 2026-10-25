-- ASE Work: notify the task team when a new contextual comment is added.
BEGIN;

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

COMMIT;

