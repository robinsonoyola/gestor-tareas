-- ASE Work: archived activities stay in history but cannot be selected for new work.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_planning_assignments(p_user uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',t.id,'title',t.title) ORDER BY t.title,t.id),'[]'::jsonb)
 INTO result
 FROM public.tasks t
 WHERE t.organization_id=ase_private.current_org()
   AND t.archived_at IS NULL
   AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=t.id AND a.user_id=p_user);
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_recurrence_list()
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 RETURN jsonb_build_object(
  'automation_ready',ase_private.recurrence_scheduler_ready(),
  'areas',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'name',a.name,'members',(SELECT coalesce(jsonb_agg(user_id),'[]'::jsonb) FROM public.work_area_members WHERE area_id=a.id))) FROM public.work_areas a WHERE active),'[]'::jsonb),
  'tasks',coalesce((SELECT jsonb_agg(jsonb_build_object('id',id,'title',title) ORDER BY title) FROM public.tasks WHERE organization_id=ase_private.current_org() AND archived_at IS NULL),'[]'::jsonb),
  'items',coalesce((SELECT jsonb_agg(to_jsonb(r)||jsonb_build_object('title',t.title,'employee',u.full_name,'area_name',a.name,'runs',
   (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.due DESC),'[]'::jsonb) FROM (
    SELECT x.due,p.id plan_id,p.user_id,p.state,p.finished_at,x.notified_at,u.full_name employee FROM public.work_recurrence_runs x JOIN public.work_day_plan p ON p.id=x.plan_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE x.recurrence_id=r.id
    UNION ALL SELECT d.due,NULL::uuid,NULL::uuid,'unassigned'::text,NULL::timestamptz,d.notified_at,NULL::text FROM public.work_area_recurrence_due d WHERE d.recurrence_id=r.id AND d.plan_id IS NULL ORDER BY due DESC
   ) x)) ORDER BY r.created_at DESC)
   FROM public.work_recurrences r JOIN public.tasks t ON t.id=r.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=r.user_id LEFT JOIN public.work_areas a ON a.id=r.area_id),'[]'::jsonb)
 );
END $function$;

ALTER FUNCTION public.work_planning_assignments(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_recurrence_list() OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_assignments(uuid),public.work_recurrence_list() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_assignments(uuid),public.work_recurrence_list() TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
