-- ASE Work: include archive and restore events in the complete task timeline.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_task_timeline(p_task uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $function$
DECLARE result jsonb;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=ase_private.current_org() AND id=p_task) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF NOT(public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id()) OR EXISTS(SELECT 1 FROM public.work_task_followers WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes consultar esta tarea'; END IF;
 WITH events AS (
  SELECT 'created:'||t.id::text id,'created' kind,'Tarea creada' title,t.title detail,'Sistema' actor_name,t.created_at FROM public.tasks t WHERE t.organization_id=ase_private.current_org() AND t.id=p_task
  UNION ALL SELECT 'assignment:'||e.id::text,'assignment_'||e.action,CASE e.action WHEN 'assigned' THEN 'Empleado asignado' ELSE 'Empleado retirado' END,e.employee_name,e.actor_name,e.created_at FROM public.work_task_assignment_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'importance:'||e.id::text,'importance','Importancia modificada',coalesce(CASE e.previous WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,'Creación')||' → '||CASE e.current_value WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,e.actor_name,e.created_at FROM public.work_importance_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'schedule:'||e.id::text,'schedule','Planificación modificada',CASE e.current_value->>'schedule_kind' WHEN 'anytime' THEN 'En cualquier momento' WHEN 'deadline' THEN 'Antes de una fecha' WHEN 'window' THEN 'Ventana de ejecución' WHEN 'scheduled' THEN 'Fecha u hora concreta' WHEN 'period' THEN 'Periodo planificado' ELSE 'Planificación actualizada' END,e.actor_name,e.created_at FROM public.work_execution_schedule_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
  UNION ALL SELECT 'state:'||e.id::text,'state','Estado modificado',CASE e.from_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'paused' THEN 'Pausada' WHEN 'review' THEN 'En revisión' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' WHEN 'cancelled' THEN 'Cancelada' ELSE e.from_state END||' → '||CASE e.to_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'paused' THEN 'Pausada' WHEN 'review' THEN 'En revisión' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' WHEN 'cancelled' THEN 'Cancelada' ELSE e.to_state END||' · '||e.reason,e.actor_name,e.created_at FROM public.work_board_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
  UNION ALL SELECT 'result:'||e.id::text,'execution_result','Resultado de la ejecución registrado',e.result_summary,coalesce(u.full_name,'Sistema'),e.created_at FROM public.work_execution_result_events e LEFT JOIN ase_private.employee_profiles u ON u.id=e.actor_id WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'archive:'||e.id::text,'archive_'||e.action,CASE e.action WHEN 'archive' THEN 'Actividad archivada' ELSE 'Actividad restaurada' END,e.reason,coalesce(m.full_name,'Sistema'),e.created_at FROM public.work_task_archive_events e LEFT JOIN public.organization_memberships m ON m.organization_id=e.organization_id AND m.user_id=e.actor_id WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
 ),page AS(SELECT * FROM events ORDER BY created_at DESC,id DESC LIMIT 250)
 SELECT coalesce(jsonb_agg(to_jsonb(page) ORDER BY created_at DESC,id DESC),'[]'::jsonb) INTO result FROM page;
 RETURN result;
END $function$;

ALTER FUNCTION public.work_task_timeline(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_task_timeline(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_timeline(uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
