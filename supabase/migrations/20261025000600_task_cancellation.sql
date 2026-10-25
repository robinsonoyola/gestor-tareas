-- ASE Work: cancel and reopen planned executions with an auditable reason.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

ALTER TABLE public.work_day_plan DROP CONSTRAINT IF EXISTS work_day_plan_state_check;
ALTER TABLE public.work_day_plan ADD CONSTRAINT work_day_plan_state_check CHECK(state IN('pending','active','blocked','review','completed','cancelled'));

CREATE OR REPLACE FUNCTION public.work_change_cancellation(p_plan uuid,p_action text,p_version bigint,p_reason text,p_request uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;e public.work_board_events%ROWTYPE;actor uuid:=ase_private.session_user_id();stamp timestamptz:=clock_timestamp();target text;version bigint;task_title text;
BEGIN
 PERFORM public.work_assert_admin();
 IF p_request IS NULL OR p_version IS NULL OR p_action NOT IN('cancel','reopen') OR length(btrim(coalesce(p_reason,''))) NOT BETWEEN 5 AND 2000 THEN RAISE EXCEPTION 'Indica cancelar o reabrir y un motivo de 5 a 2000 caracteres'; END IF;
 target:=CASE p_action WHEN 'cancel' THEN 'cancelled' ELSE 'pending' END;
 SELECT * INTO e FROM public.work_board_events WHERE organization_id=ase_private.current_org() AND id=p_request;
 IF FOUND THEN
  IF e.plan_id<>p_plan OR e.to_state<>target OR e.actor_id<>actor OR e.reason<>btrim(p_reason) THEN RAISE EXCEPTION 'Identificador de operación ya utilizado'; END IF;
  RETURN jsonb_build_object('success',true,'state',e.to_state,'version',e.applied_version,'repeated',true);
 END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan FOR UPDATE;
 IF NOT FOUND OR p.board_version<>p_version THEN RAISE EXCEPTION 'La tarjeta ha cambiado. Actualiza el tablero y vuelve a intentarlo'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=p.organization_id AND task_id=p.task_id AND user_id=p.user_id) THEN RAISE EXCEPTION 'La tarea ya no está asignada al empleado'; END IF;
 IF p_action='cancel' THEN
  IF p.state='cancelled' THEN RAISE EXCEPTION 'La ejecución ya está cancelada'; END IF;
  IF p.state IN('active','completed') THEN RAISE EXCEPTION 'Una ejecución en curso o completada no se cancela directamente'; END IF;
  IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=p.organization_id AND work_plan_id=p.id AND checkout_time IS NULL) THEN RAISE EXCEPTION 'Detén primero el fichaje activo'; END IF;
  UPDATE public.work_day_plan SET state='cancelled',finished_at=stamp WHERE organization_id=p.organization_id AND id=p.id;
 ELSE
  IF p.state<>'cancelled' THEN RAISE EXCEPTION 'Solo se puede reabrir una ejecución cancelada'; END IF;
  IF EXISTS(SELECT 1 FROM public.work_incidents WHERE organization_id=p.organization_id AND plan_id=p.id AND blocks_work AND state<>'resolved') THEN RAISE EXCEPTION 'Resuelve primero las incidencias que bloquean esta tarea'; END IF;
  UPDATE public.work_day_plan SET state='pending',started_at=NULL,finished_at=NULL,board_reopened_at=stamp WHERE organization_id=p.organization_id AND id=p.id;
 END IF;
 UPDATE public.work_station_tickets SET expires_at=stamp WHERE organization_id=p.organization_id AND plan_id=p.id AND result IS NULL;
 SELECT board_version INTO version FROM public.work_day_plan WHERE organization_id=p.organization_id AND id=p.id;
 INSERT INTO public.work_board_events(id,organization_id,plan_id,actor_id,actor_name,from_state,to_state,reason,applied_version)
 VALUES(p_request,p.organization_id,p.id,actor,coalesce((SELECT full_name FROM ase_private.employee_profiles WHERE id=actor),'Administrador'),p.state,target,btrim(p_reason),version);
 SELECT t.title INTO task_title FROM public.tasks t WHERE t.organization_id=p.organization_id AND t.id=p.task_id;
 INSERT INTO public.work_notifications(organization_id,user_id,message,kind,event_key)
 VALUES(p.organization_id,p.user_id,CASE p_action WHEN'cancel'THEN'Ejecución cancelada: 'ELSE'Ejecución reabierta: 'END||coalesce(task_title,'Tarea')||' · '||left(btrim(p_reason),160),CASE p_action WHEN'cancel'THEN'task_cancelled'ELSE'task_reopened'END,'cancellation:'||p_request::text)
 ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;
 RETURN jsonb_build_object('success',true,'state',target,'version',version);
END $$;

CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('planning.view');IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días';END IF;IF p_state IS NOT NULL AND p_state NOT IN('pending','active','blocked','review','completed','cancelled')THEN RAISE EXCEPTION 'Estado no válido';END IF;IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida';END IF;WITH base AS(SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org()AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)AND(nullif(btrim(p_query),'')IS NULL OR concat_ws(' ',t.title,t.description,u.full_name)ILIKE'%'||btrim(p_query)||'%')),page AS(SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)SELECT jsonb_build_object('start',p_start,'end',p_end,'total',(SELECT count(*)FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object('pending',(SELECT count(*)FROM base WHERE state='pending'),'active',(SELECT count(*)FROM base WHERE state='active'),'blocked',(SELECT count(*)FROM base WHERE state='blocked'),'review',(SELECT count(*)FROM base WHERE state='review'),'completed',(SELECT count(*)FROM base WHERE state='completed'),'cancelled',(SELECT count(*)FROM base WHERE state='cancelled')),'items',coalesce((SELECT jsonb_agg(to_jsonb(page)ORDER BY work_date,priority,employee,id)FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp())INTO result;RETURN result;END $$;

CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS(SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,p.state,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,(public.work_execution_eligibility(p.id)->>'can_start')::boolean eligible,public.work_incident_resolver(t.id)incident FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org()AND p.user_id=ase_private.session_user_id()AND p.state IN('pending','active','blocked','review','completed','cancelled')AND(p.state='active'OR p.work_date BETWEEN public.work_today()-30 AND public.work_today()+365)),next_item AS(SELECT plan_id,task_id FROM items WHERE state='pending'AND eligible ORDER BY work_date,priority,plan_id LIMIT 1)SELECT jsonb_build_object('date',public.work_today(),'next_plan',(SELECT plan_id FROM next_item),'next_task',(SELECT task_id FROM next_item),'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',i.eligible AND(i.plan_id=(SELECT plan_id FROM next_item)OR i.incident),'can_finish',i.state='active')ORDER BY(i.state IN('completed','review','cancelled')),(i.state='active')DESC,i.work_date,i.priority,i.plan_id)FROM items i),'[]'::jsonb)) $$;

ALTER FUNCTION public.work_change_cancellation(uuid,text,bigint,text,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_queue() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_change_cancellation(uuid,text,bigint,text,uuid),public.work_planning_board_range(date,date,uuid,text,text,integer,integer),public.work_mobile_queue() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_change_cancellation(uuid,text,bigint,text,uuid),public.work_planning_board_range(date,date,uuid,text,text,integer,integer),public.work_mobile_queue() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

