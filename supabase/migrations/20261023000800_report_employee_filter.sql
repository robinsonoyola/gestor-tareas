BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE FUNCTION public.work_report_table(p_kind text,p_start date,p_end date,p_search text,p_state text,p_method text,p_employee uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 IF p_kind IS NULL OR p_kind NOT IN ('checkins','tasks','productivity','incidents','closures') OR p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR length(coalesce(p_search,''))>120 THEN RAISE EXCEPTION 'Selecciona un informe y un período de hasta 366 días'; END IF;
 WITH source AS (
SELECT row FROM (SELECT jsonb_build_object('_at',c.checkin_time,'_state',CASE WHEN c.checkout_time IS NULL THEN 'open' ELSE 'closed' END,'_method',c.checkin_method,'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'start',c.checkin_time,'end',c.checkout_time,'minutes',round((extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)/60)::numeric,2),'method',c.checkin_method,'status',CASE WHEN c.checkout_time IS NULL THEN 'En curso' ELSE 'Cerrado' END) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id) dataset WHERE p_kind='checkins'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',(coalesce(p.work_date,t.schedule_date,(t.created_at AT TIME ZONE 'Europe/Madrid')::date)::timestamp AT TIME ZONE 'Europe/Madrid'),'_state',coalesce(p.state,'unplanned'),'_users',jsonb_build_array(a.user_id),'employee',u.full_name,'task',t.title,'date',coalesce(p.work_date,t.schedule_date),'priority',p.priority,'status',CASE p.state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'completed' THEN 'Completada' WHEN 'blocked' THEN 'Bloqueada' ELSE 'Sin planificación' END) row FROM public.tasks t LEFT JOIN public.task_assignments a ON a.task_id=t.id LEFT JOIN ase_private.employee_profiles u ON u.id=a.user_id LEFT JOIN public.work_day_plan p ON p.task_id=t.id AND p.user_id=a.user_id) dataset WHERE p_kind='tasks'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',((c.checkin_time AT TIME ZONE 'Europe/Madrid')::date::timestamp AT TIME ZONE 'Europe/Madrid'),'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'date',(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date,'count',count(*),'minutes',round(sum(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2),'average',round(avg(extract(epoch FROM c.checkout_time-c.checkin_time)/60)::numeric,2)) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id WHERE c.checkout_time>=c.checkin_time GROUP BY c.user_id,u.full_name,t.id,t.title,(c.checkin_time AT TIME ZONE 'Europe/Madrid')::date) dataset WHERE p_kind='productivity'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',i.created_at,'_state',i.state,'_users',jsonb_build_array(i.reporter_id,i.assigned_user)||coalesce((SELECT jsonb_agg(m.user_id) FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id),'[]'::jsonb),'employee',u.full_name,'task',t.title,'subject',i.subject,'responsible',coalesce(a.name,v.full_name),'start',i.created_at,'updated',i.updated_at,'status',CASE i.state WHEN 'open' THEN 'Abierta' WHEN 'in_progress' THEN 'En atención' ELSE 'Resuelta' END,'blocked',CASE WHEN i.blocks_work THEN 'Sí' ELSE 'No' END,'resolution',i.resolution) row FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=i.reporter_id LEFT JOIN ase_private.employee_profiles v ON v.id=i.assigned_user LEFT JOIN public.work_areas a ON a.id=i.area_id) dataset WHERE p_kind='incidents'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',c.created_at,'_users',jsonb_build_array(p.user_id),'employee',u.full_name,'task',t.title,'actor',v.full_name,'start',c.created_at,'type',CASE c.kind WHEN 'admin_finish' THEN 'Cierre administrativo' ELSE 'Bloqueo por incidencia' END,'reason',c.reason) row FROM public.work_task_closures c JOIN public.work_day_plan p ON p.id=c.plan_id JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id LEFT JOIN ase_private.employee_profiles v ON v.id=c.actor_id) dataset WHERE p_kind='closures'
 ), filtered AS (
 SELECT row FROM source WHERE (row->>'_at')::timestamptz>=p_start::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (row->>'_at')::timestamptz<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'
 AND (p_employee IS NULL OR row->'_users' @> jsonb_build_array(p_employee))
 AND (p_state IS NULL OR row->>'_state'=p_state) AND (p_method IS NULL OR row->>'_method'=p_method)
 AND (coalesce(btrim(p_search),'')='' OR strpos(lower((row-'_at'-'_state'-'_method'-'_users')::text),lower(btrim(p_search)))>0)
 ), limited AS (SELECT row FROM filtered ORDER BY row->>'_at' DESC,row::text LIMIT 10001)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(row-'_at'-'_state'-'_method'-'_users') FROM limited),'[]'::jsonb),'as_of',now()) INTO result;
 IF (result->>'total')::integer>10000 THEN RAISE EXCEPTION 'Hay más de 10.000 filas. Reduce las fechas o utiliza el buscador antes de descargar'; END IF;
 RETURN result;
END $$;
ALTER FUNCTION public.work_report_table(text,date,date,text,text,text,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_report_table(text,date,date,text,text,text,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_report_table(text,date,date,text,text,text,uuid) TO authenticated,ase_tenant_executor;
CREATE FUNCTION public.work_report_employees() RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',id,'full_name',full_name,'status',membership_status) ORDER BY full_name,id) FROM ase_private.employee_profiles),'[]'::jsonb);
END $$;
ALTER FUNCTION public.work_report_employees() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_report_employees() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_report_employees() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
