-- ASE Work: compare expected and recorded time without evaluating work quality.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_report_estimate_variance(
  p_start date,
  p_end date,
  p_employee uuid DEFAULT NULL,
  p_area uuid DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $function$
DECLARE result jsonb;
BEGIN
  PERFORM public.work_assert_permission('reports.view');
  IF p_start IS NULL OR p_end IS NULL OR p_end < p_start OR p_end - p_start > 365 THEN
    RAISE EXCEPTION 'Selecciona un período de hasta 366 días';
  END IF;
  IF p_employee IS NOT NULL AND p_area IS NOT NULL THEN
    RAISE EXCEPTION 'Selecciona un empleado o un área';
  END IF;
  IF p_employee IS NOT NULL AND NOT EXISTS(
    SELECT 1 FROM ase_private.employee_profiles WHERE id=p_employee
  ) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
  IF p_area IS NOT NULL AND NOT EXISTS(
    SELECT 1 FROM public.work_areas WHERE id=p_area AND active
  ) THEN RAISE EXCEPTION 'Área no válida'; END IF;

  WITH samples AS (
    SELECT c.user_id, coalesce(u.full_name,'Empleado no disponible') employee,
      c.task_id, t.title task, t.estimated_minutes,
      extract(epoch FROM c.checkout_time-c.checkin_time)/60.0 actual_minutes
    FROM public.checkins c
    JOIN public.tasks t ON t.id=c.task_id AND t.organization_id=ase_private.current_org()
    LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id
    WHERE t.estimated_minutes IS NOT NULL
      AND c.checkin_time IS NOT NULL AND c.checkout_time>c.checkin_time
      AND c.checkout_time>=p_start::timestamp AT TIME ZONE 'Europe/Madrid'
      AND c.checkout_time<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
      AND (p_employee IS NULL OR c.user_id=p_employee)
      AND (p_area IS NULL OR EXISTS(
        SELECT 1 FROM public.work_area_members m
        WHERE m.organization_id=ase_private.current_org()
          AND m.area_id=p_area AND m.user_id=c.user_id
      ))
  ), grouped AS (
    SELECT user_id,employee,task_id,task,count(*)::int work_count,
      estimated_minutes,
      round(sum(estimated_minutes)::numeric,2) estimated_total,
      round(sum(actual_minutes)::numeric,2) actual_total,
      round((sum(actual_minutes)-sum(estimated_minutes))::numeric,2) variance,
      round(avg(actual_minutes)::numeric,2) actual_average
    FROM samples
    GROUP BY user_id,employee,task_id,task,estimated_minutes
  )
  SELECT jsonb_build_object(
    'summary',jsonb_build_object(
      'work_count',coalesce((SELECT sum(work_count) FROM grouped),0),
      'estimated_total',coalesce((SELECT sum(estimated_total) FROM grouped),0),
      'actual_total',coalesce((SELECT sum(actual_total) FROM grouped),0),
      'variance',coalesce((SELECT sum(variance) FROM grouped),0),
      'within_estimate',coalesce((SELECT sum(work_count) FROM grouped WHERE variance<=0),0)
    ),
    'items',coalesce((SELECT jsonb_agg(to_jsonb(g) ORDER BY abs(g.variance) DESC,g.employee,g.task) FROM grouped g),'[]'::jsonb),
    'as_of',now()
  ) INTO result;
  RETURN result;
END $function$;

ALTER FUNCTION public.work_report_estimate_variance(date,date,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_report_estimate_variance(date,date,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_report_estimate_variance(date,date,uuid,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
