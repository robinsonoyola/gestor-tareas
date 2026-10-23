BEGIN;
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
COMMIT;
