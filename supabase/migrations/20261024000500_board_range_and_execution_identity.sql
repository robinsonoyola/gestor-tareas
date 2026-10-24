BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

-- Replace the temporary hosted wrapper with the definitive normalized API.
CREATE OR REPLACE FUNCTION public.work_set_execution_schedule(p_plan uuid,p_kind text,p_available_from timestamptz DEFAULT NULL,p_scheduled_for timestamptz DEFAULT NULL,p_due_at timestamptz DEFAULT NULL,p_planned_end timestamptz DEFAULT NULL,p_strict boolean DEFAULT false,p_version bigint DEFAULT NULL,p_request uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE; before_value jsonb; after_value jsonb; existing public.work_execution_schedule_events%ROWTYPE; result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 p_available_from:=CASE WHEN p_kind IN('window','period') THEN p_available_from END;
 p_scheduled_for:=CASE WHEN p_kind='scheduled' THEN p_scheduled_for END;
 p_due_at:=CASE WHEN p_kind IN('deadline','window','scheduled','period') THEN p_due_at END;
 p_planned_end:=CASE WHEN p_kind='period' THEN p_planned_end END;
 p_strict:=p_kind='scheduled' AND coalesce(p_strict,false);
 IF p_request IS NOT NULL THEN SELECT * INTO existing FROM public.work_execution_schedule_events WHERE organization_id=ase_private.current_org() AND request_id=p_request; IF FOUND THEN IF existing.plan_id<>p_plan OR existing.current_value IS DISTINCT FROM jsonb_build_object('schedule_kind',p_kind,'available_from',p_available_from,'scheduled_for',p_scheduled_for,'due_at',p_due_at,'planned_end',p_planned_end,'strict_schedule',p_strict) THEN RAISE EXCEPTION 'Identificador de operación ya utilizado'; END IF; RETURN existing.current_value||jsonb_build_object('id',p_plan,'repeated',true); END IF; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'La ejecución ya no existe'; END IF;
 IF p_version IS NOT NULL AND p.board_version<>p_version THEN RAISE EXCEPTION 'La ejecución ha cambiado. Actualiza la planificación'; END IF;
 IF p.state IN ('completed','blocked') THEN RAISE EXCEPTION 'No se cambian las fechas de una ejecución cerrada o bloqueada'; END IF;
 before_value:=ase_private.execution_schedule_json(p);
 IF NOT ((p_kind='anytime' AND p_available_from IS NULL AND p_scheduled_for IS NULL AND p_due_at IS NULL AND p_planned_end IS NULL AND NOT p_strict) OR (p_kind='deadline' AND p_available_from IS NULL AND p_scheduled_for IS NULL AND p_due_at IS NOT NULL AND p_planned_end IS NULL AND NOT p_strict) OR (p_kind='window' AND p_available_from IS NOT NULL AND p_scheduled_for IS NULL AND p_due_at IS NOT NULL AND p_planned_end IS NULL AND NOT p_strict AND p_available_from<p_due_at) OR (p_kind='scheduled' AND p_available_from IS NULL AND p_scheduled_for IS NOT NULL AND p_planned_end IS NULL AND (p_due_at IS NULL OR p_scheduled_for<p_due_at)) OR (p_kind='period' AND p_available_from IS NOT NULL AND p_scheduled_for IS NULL AND p_planned_end IS NOT NULL AND NOT p_strict AND p_available_from<p_planned_end AND (p_due_at IS NULL OR p_available_from<p_due_at))) THEN RAISE EXCEPTION 'Las fechas no corresponden al tipo de planificación'; END IF;
 UPDATE public.work_day_plan SET schedule_kind=p_kind,available_from=p_available_from,scheduled_for=p_scheduled_for,due_at=p_due_at,planned_end=p_planned_end,strict_schedule=p_strict WHERE organization_id=p.organization_id AND id=p.id RETURNING * INTO p;
 after_value:=ase_private.execution_schedule_json(p);
 IF before_value IS DISTINCT FROM after_value THEN INSERT INTO public.work_execution_schedule_events(organization_id,plan_id,request_id,actor_id,actor_name,previous,current_value) VALUES(p.organization_id,p.id,p_request,ase_private.session_user_id(),coalesce((SELECT full_name FROM ase_private.employee_profiles WHERE id=ase_private.session_user_id()),'Administración'),before_value,after_value); END IF;
 result:=public.work_execution_eligibility(p.id); RETURN result||jsonb_build_object('id',p.id,'version',p.board_version);
END $$;
DROP FUNCTION IF EXISTS public.work_set_execution_schedule_raw(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid);

-- A queue entry is an execution (work_day_plan), not a catalogue task. The
-- same recurring task can therefore occur more than once without one row
-- replacing or enabling another.
CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS (
  SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,p.state,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,
   (public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,
   (public.work_execution_eligibility(p.id)->>'can_start')::boolean eligible,public.work_incident_resolver(t.id) incident
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  WHERE p.organization_id=ase_private.current_org() AND p.user_id=ase_private.session_user_id() AND p.state IN('pending','active','blocked','completed')
   AND (p.state='active' OR p.work_date BETWEEN public.work_today()-30 AND public.work_today()+365)
 ), next_item AS (SELECT plan_id,task_id FROM items WHERE state='pending' AND eligible ORDER BY work_date,priority,plan_id LIMIT 1)
 SELECT jsonb_build_object('date',public.work_today(),'next_plan',(SELECT plan_id FROM next_item),'next_task',(SELECT task_id FROM next_item),'items',
  coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',i.eligible AND (i.plan_id=(SELECT plan_id FROM next_item) OR i.incident),'can_finish',i.state='active')
   ORDER BY (i.state='completed'),(i.state='active') DESC,i.work_date,i.priority,i.plan_id) FROM items i),'[]'::jsonb))
$$;

CREATE OR REPLACE FUNCTION public.work_mobile_order_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb;incident uuid;queue jsonb;
BEGIN
 IF public.work_mode() OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR public.sec06_is_admin() THEN RETURN NEW; END IF;
 IF NEW.user_id IS DISTINCT FROM ase_private.session_user_id() THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible'; END IF;
 PERFORM 1 FROM public.organization_memberships WHERE organization_id=ase_private.current_org() AND user_id=NEW.user_id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=NEW.organization_id AND user_id=NEW.user_id AND checkout_time IS NULL) THEN RAISE EXCEPTION 'Finaliza primero tu fichaje activo'; END IF;
 queue:=public.work_mobile_queue();
 SELECT x INTO item FROM jsonb_array_elements(queue->'items') x
  WHERE x->>'plan_id'=queue->>'next_plan' AND x->>'task_id'=NEW.task_id::text LIMIT 1;
 IF item IS NULL THEN
  SELECT x INTO item FROM jsonb_array_elements(queue->'items') x
   WHERE x->>'task_id'=NEW.task_id::text AND coalesce((x->>'incident')::boolean,false) ORDER BY (x->>'work_date')::date,(x->>'priority')::integer,x->>'plan_id' LIMIT 1;
 END IF;
 IF item IS NULL OR NOT coalesce((item->>'can_start')::boolean,false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Esta tarea está en consulta. Ficha en la siguiente ejecución según el orden del encargado'; END IF;
 IF item->>'plan_id'=queue->>'next_plan' THEN NEW.work_plan_id:=(item->>'plan_id')::uuid;
 ELSE
  SELECT i.id INTO incident FROM public.work_incidents i WHERE i.organization_id=NEW.organization_id AND i.task_id=NEW.task_id AND i.state IN ('open','in_progress')
  AND (i.assigned_user=NEW.user_id OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id AND m.user_id=NEW.user_id)) ORDER BY i.created_at LIMIT 1;
  NEW.work_incident_id:=incident;
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días'; END IF;
 IF p_state IS NOT NULL AND p_state NOT IN('pending','active','blocked','completed') THEN RAISE EXCEPTION 'Estado no válido'; END IF;
 IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida'; END IF;
 WITH base AS (
  SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible') employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,
   (public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
  WHERE p.organization_id=ase_private.current_org() AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)
   AND(nullif(btrim(p_query),'') IS NULL OR concat_ws(' ',t.title,t.description,u.full_name) ILIKE '%'||btrim(p_query)||'%')
 ), page AS (SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)
 SELECT jsonb_build_object('start',p_start,'end',p_end,'total',(SELECT count(*) FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object(
  'pending',(SELECT count(*) FROM base WHERE state='pending'),'active',(SELECT count(*) FROM base WHERE state='active'),'blocked',(SELECT count(*) FROM base WHERE state='blocked'),'completed',(SELECT count(*) FROM base WHERE state='completed')),
  'items',coalesce((SELECT jsonb_agg(to_jsonb(page) ORDER BY work_date,priority,employee,id) FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp()) INTO result;
 RETURN result;
END $$;

ALTER FUNCTION public.work_mobile_queue() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_order_guard() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) TO authenticated,ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
