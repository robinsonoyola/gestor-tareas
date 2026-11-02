-- ASE Work: new tasks inherit their organization in the automatic check-in configuration.
BEGIN;

CREATE OR REPLACE FUNCTION public.create_task_checkin_config()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
BEGIN
  INSERT INTO public.task_checkin_config(
    organization_id,task_id,nfc_enabled,qr_enabled,manual_enabled
  ) VALUES(
    NEW.organization_id,NEW.id,false,true,true
  )
  ON CONFLICT(task_id) DO NOTHING;
  RETURN NEW;
END
$function$;

ALTER FUNCTION public.create_task_checkin_config() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.create_task_checkin_config() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.create_task_checkin_config() TO ase_tenant_executor;

INSERT INTO public.task_checkin_config(
  organization_id,task_id,nfc_enabled,qr_enabled,manual_enabled
)
SELECT task.organization_id,task.id,false,true,true
FROM public.tasks task
WHERE NOT EXISTS(
  SELECT 1
  FROM public.task_checkin_config config
  WHERE config.organization_id=task.organization_id AND config.task_id=task.id
)
ON CONFLICT(task_id) DO NOTHING;

NOTIFY pgrst,'reload schema';
COMMIT;
