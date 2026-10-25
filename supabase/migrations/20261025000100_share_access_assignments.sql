BEGIN;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_share_task_access(p_task uuid,p_users uuid[],p_expires_days integer DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org(); code text; expires_at timestamptz; blocked_names text;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_task IS NULL OR NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=org AND id=p_task FOR KEY SHARE) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF p_users IS NULL OR cardinality(p_users)<1 OR cardinality(p_users)>100 OR cardinality(p_users)<>(SELECT count(DISTINCT id) FROM unnest(p_users)u(id)) OR EXISTS(
  SELECT 1 FROM unnest(p_users)u(id) WHERE id IS NULL OR NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles e WHERE e.id=u.id AND e.is_admin IS FALSE AND e.membership_status='active')
 ) THEN RAISE EXCEPTION 'Selecciona al menos un empleado activo'; END IF;
 IF p_expires_days IS NOT NULL AND p_expires_days NOT IN(1,7,30,90) THEN RAISE EXCEPTION 'Caducidad no válida'; END IF;

 SELECT string_agg(coalesce(e.full_name,'Empleado'),', ' ORDER BY e.full_name) INTO blocked_names
 FROM public.task_assignments a LEFT JOIN ase_private.employee_profiles e ON e.id=a.user_id
 WHERE a.organization_id=org AND a.task_id=p_task AND NOT(a.user_id=ANY(p_users)) AND (
  EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.organization_id=org AND p.task_id=p_task AND p.user_id=a.user_id AND p.state IN('pending','active','blocked'))
  OR EXISTS(SELECT 1 FROM public.checkins c WHERE c.organization_id=org AND c.task_id=p_task AND c.user_id=a.user_id AND c.checkout_time IS NULL)
 );
 IF blocked_names IS NOT NULL THEN RAISE EXCEPTION 'No puedes retirar a %: tiene planificación pendiente, activa o bloqueada',blocked_names; END IF;

 DELETE FROM public.task_assignments a WHERE a.organization_id=org AND a.task_id=p_task AND NOT(a.user_id=ANY(p_users));
 INSERT INTO public.task_assignments(organization_id,task_id,user_id)
 SELECT org,p_task,u.id FROM unnest(p_users)u(id)
 WHERE NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=org AND a.task_id=p_task AND a.user_id=u.id);

 code:='TASK-'||upper(replace(gen_random_uuid()::text,'-',''));
 expires_at:=CASE WHEN p_expires_days IS NULL THEN NULL ELSE clock_timestamp()+make_interval(days=>p_expires_days) END;
 INSERT INTO public.task_access_codes(organization_id,id,task_id,access_code,created_by,created_at,is_active,expires_at)
 VALUES(org,gen_random_uuid(),p_task,code,ase_private.session_user_id(),clock_timestamp(),true,expires_at);
 RETURN jsonb_build_object('code',code,'expires_at',expires_at,'assigned',cardinality(p_users));
END $$;
ALTER FUNCTION public.work_share_task_access(uuid,uuid[],integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_share_task_access(uuid,uuid[],integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_share_task_access(uuid,uuid[],integer) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;

NOTIFY pgrst,'reload schema';
COMMIT;
