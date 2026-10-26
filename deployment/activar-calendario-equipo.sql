-- ASE Work: multi-employee planning and availability calendar.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_team_calendar(p_start date,p_end date,p_area uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>31 THEN RAISE EXCEPTION 'Selecciona un período de hasta 32 días';END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas a WHERE a.organization_id=ase_private.current_org()AND a.id=p_area AND a.active)THEN RAISE EXCEPTION 'Área no disponible';END IF;
 WITH people AS(
  SELECT u.id,u.full_name FROM ase_private.employee_profiles u
  WHERE NOT u.is_admin AND u.membership_status='active' AND(p_area IS NULL OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=ase_private.current_org()AND m.area_id=p_area AND m.user_id=u.id))
 )
 SELECT jsonb_build_object(
  'start',p_start,'end',p_end,
  'areas',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'name',a.name)ORDER BY a.name,a.id)FROM public.work_areas a WHERE a.organization_id=ase_private.current_org()AND a.active),'[]'::jsonb),
  'employees',coalesce(jsonb_agg(jsonb_build_object('id',person.id,'full_name',person.full_name,'days',(
   SELECT jsonb_agg(jsonb_build_object('date',d.work_day,'absent',EXISTS(SELECT 1 FROM public.work_employee_absences x WHERE x.organization_id=ase_private.current_org()AND x.user_id=person.id AND x.cancelled_at IS NULL AND d.work_day BETWEEN x.start_date AND x.end_date),'total',coalesce(p.total,0),'pending',coalesce(p.pending,0),'active',coalesce(p.active,0),'paused',coalesce(p.paused,0),'blocked',coalesce(p.blocked,0),'review',coalesce(p.review,0),'completed',coalesce(p.completed,0))ORDER BY d.work_day)
   FROM(SELECT generate_series(p_start,p_end,'1 day'::interval)::date AS work_day)d
   LEFT JOIN LATERAL(SELECT count(*)::int total,count(*)FILTER(WHERE state='pending')::int pending,count(*)FILTER(WHERE state='active')::int active,count(*)FILTER(WHERE state='paused')::int paused,count(*)FILTER(WHERE state='blocked')::int blocked,count(*)FILTER(WHERE state='review')::int review,count(*)FILTER(WHERE state='completed')::int completed FROM public.work_day_plan w WHERE w.organization_id=ase_private.current_org()AND w.user_id=person.id AND w.work_date=d.work_day)p ON true
  ))ORDER BY person.full_name,person.id),'[]'::jsonb),
  'as_of',clock_timestamp())INTO result FROM people person;
 RETURN result;
END $$;

ALTER FUNCTION public.work_team_calendar(date,date,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_team_calendar(date,date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_team_calendar(date,date,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
