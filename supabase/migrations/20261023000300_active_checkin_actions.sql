BEGIN;
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
COMMIT;
