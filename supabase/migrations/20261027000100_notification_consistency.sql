-- ASE Work: complete assignment notifications and normalize legacy incident events.
BEGIN;
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
COMMIT;
