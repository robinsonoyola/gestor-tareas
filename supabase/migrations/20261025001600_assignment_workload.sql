-- ASE Work: visible workload before assigning a task.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_assignment_workload(p_start date DEFAULT NULL,p_end date DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE from_day date:=coalesce(p_start,public.work_today());to_day date:=coalesce(p_end,public.work_today()+13);result jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF to_day<from_day OR to_day-from_day>31 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 32 días';END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',u.id,'full_name',u.full_name,'open_count',coalesce(x.open_count,0),'pending_count',coalesce(x.pending_count,0),'active_count',coalesce(x.active_count,0),'blocked_count',coalesce(x.blocked_count,0),'review_count',coalesce(x.review_count,0),'overdue_count',coalesce(x.overdue_count,0),'estimated_minutes',coalesce(x.estimated_minutes,0))ORDER BY coalesce(x.open_count,0),u.full_name,u.id),'[]'::jsonb)INTO result
 FROM ase_private.employee_profiles u LEFT JOIN LATERAL(
  SELECT count(*)FILTER(WHERE p.state IN('pending','active','paused','blocked','review'))::int open_count,count(*)FILTER(WHERE p.state='pending')::int pending_count,count(*)FILTER(WHERE p.state IN('active','paused'))::int active_count,count(*)FILTER(WHERE p.state='blocked')::int blocked_count,count(*)FILTER(WHERE p.state='review')::int review_count,count(*)FILTER(WHERE p.state='pending'AND p.work_date<public.work_today())::int overdue_count,coalesce(sum(t.estimated_minutes)FILTER(WHERE p.state IN('pending','active','paused','blocked','review')),0)::int estimated_minutes
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org()AND p.user_id=u.id AND p.work_date BETWEEN from_day AND to_day
 )x ON true WHERE u.is_admin IS FALSE AND u.membership_status='active';
 RETURN jsonb_build_object('start',from_day,'end',to_day,'employees',result,'as_of',clock_timestamp());
END $$;

ALTER FUNCTION public.work_assignment_workload(date,date) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_assignment_workload(date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_assignment_workload(date,date) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

