BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_planning_board(p_date date,p_user uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE items jsonb; total integer;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_date IS NULL THEN RAISE EXCEPTION 'Selecciona una fecha válida'; END IF;
 SELECT count(*) INTO total FROM public.work_day_plan WHERE work_date=p_date AND (p_user IS NULL OR user_id=p_user);
 IF total>10000 THEN RAISE EXCEPTION 'Hay demasiadas tareas para mostrar. Selecciona un empleado'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object(
  'id',p.id,'task_id',p.task_id,'employee_id',p.user_id,'employee',coalesce(u.full_name,'Empleado no disponible'),
  'title',t.title,'description',t.description,'priority',p.priority,'state',p.state,'work_date',p.work_date,
  'started_at',p.started_at,'finished_at',p.finished_at) || public.work_deadline(p.work_date,p.state,p.finished_at)
  ORDER BY p.priority,u.full_name,p.id),'[]'::jsonb) INTO items
 FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
 WHERE p.work_date=p_date AND (p_user IS NULL OR p.user_id=p_user);
 RETURN jsonb_build_object('date',p_date,'items',items,'total',total,'as_of',now());
END $$;
ALTER FUNCTION public.work_planning_board(date,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board(date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_board(date,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
