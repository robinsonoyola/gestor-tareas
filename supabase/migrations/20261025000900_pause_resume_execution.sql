-- ASE Work: pause and resume an execution without completing or blocking it.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

ALTER TABLE public.work_day_plan DROP CONSTRAINT IF EXISTS work_day_plan_state_check;
ALTER TABLE public.work_day_plan ADD CONSTRAINT work_day_plan_state_check CHECK(state IN('pending','active','paused','blocked','review','completed','cancelled'));

CREATE OR REPLACE FUNCTION public.work_mobile_plan_sync() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.work_plan_id IS NOT NULL THEN
  IF TG_OP='INSERT' THEN UPDATE public.work_day_plan SET state='active',started_at=coalesce(started_at,NEW.checkin_time),finished_at=NULL WHERE organization_id=NEW.organization_id AND id=NEW.work_plan_id AND user_id=NEW.user_id AND state IN('pending','paused');
  ELSIF OLD.checkout_time IS NULL AND NEW.checkout_time IS NOT NULL THEN
   UPDATE public.work_day_plan SET state=CASE WHEN coalesce(current_setting('ase.pause_execution',true),'off')='on' THEN 'paused' ELSE 'completed' END,finished_at=NEW.checkout_time WHERE organization_id=NEW.organization_id AND id=NEW.work_plan_id AND user_id=NEW.user_id AND state='active';
  END IF;
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_mobile_order_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb;incident uuid;queue jsonb;
BEGIN
 IF NEW.work_plan_id IS NULL AND NEW.location='Reanudación de ejecución' THEN RETURN NEW;END IF;
 IF coalesce(current_setting('ase.resume_execution',true),'off')='on' THEN RETURN NEW;END IF;
 IF public.work_mode() OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR public.sec06_is_admin() THEN RETURN NEW; END IF;
 IF NEW.user_id IS DISTINCT FROM ase_private.session_user_id() THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible'; END IF;
 PERFORM 1 FROM public.organization_memberships WHERE organization_id=ase_private.current_org() AND user_id=NEW.user_id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=NEW.organization_id AND user_id=NEW.user_id AND checkout_time IS NULL) THEN RAISE EXCEPTION 'Finaliza primero tu fichaje activo'; END IF;
 queue:=public.work_mobile_queue();
 SELECT x INTO item FROM jsonb_array_elements(queue->'items')x WHERE x->>'plan_id'=queue->>'next_plan'AND x->>'task_id'=NEW.task_id::text LIMIT 1;
 IF item IS NULL THEN SELECT x INTO item FROM jsonb_array_elements(queue->'items')x WHERE x->>'task_id'=NEW.task_id::text AND coalesce((x->>'incident')::boolean,false)ORDER BY(x->>'work_date')::date,(x->>'priority')::integer,x->>'plan_id'LIMIT 1;END IF;
 IF item IS NULL OR NOT coalesce((item->>'can_start')::boolean,false)THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Esta tarea está en consulta. Ficha en la siguiente ejecución según el orden del encargado';END IF;
 IF item->>'plan_id'=queue->>'next_plan'THEN NEW.work_plan_id:=(item->>'plan_id')::uuid;ELSE SELECT i.id INTO incident FROM public.work_incidents i WHERE i.organization_id=NEW.organization_id AND i.task_id=NEW.task_id AND i.state IN('open','in_progress')AND(i.assigned_user=NEW.user_id OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id AND m.user_id=NEW.user_id))ORDER BY i.created_at LIMIT 1;NEW.work_incident_id:=incident;END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_schedule_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE eligibility jsonb;BEGIN
 IF coalesce(current_setting('ase.resume_execution',true),'off')='on' THEN RETURN NEW;END IF;
 IF NEW.work_plan_id IS NULL THEN RETURN NEW;END IF;eligibility:=public.work_execution_eligibility(NEW.work_plan_id,coalesce(NEW.checkin_time,clock_timestamp()));IF NOT coalesce((eligibility->>'can_start')::boolean,false)THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE=CASE eligibility->>'reason' WHEN'too_early'THEN'Esta tarea todavía no está disponible'WHEN'overdue'THEN'La fecha límite ha pasado. Solicita al encargado que reprograme la tarea'WHEN'order'THEN'Respeta el orden de tareas del empleado'WHEN'open_checkin'THEN'El empleado ya tiene un fichaje activo'WHEN'assignment'THEN'La tarea ya no está asignada al empleado'ELSE'La tarea no puede iniciarse en este momento'END;END IF;RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_pause_execution(p_plan uuid,p_action text,p_reason text,p_request uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;c public.checkins%ROWTYPE;e public.work_board_events%ROWTYPE;actor uuid:=ase_private.session_user_id();stamp timestamptz:=clock_timestamp();target text;checkin uuid;version bigint;
BEGIN
 IF actor IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión';END IF;
 IF p_request IS NULL OR p_action NOT IN('pause','resume')OR length(btrim(coalesce(p_reason,'')))NOT BETWEEN 5 AND 500 THEN RAISE EXCEPTION 'Indica pausar o reanudar y un motivo de 5 a 500 caracteres';END IF;
 target:=CASE p_action WHEN'pause'THEN'paused'ELSE'active'END;
 SELECT * INTO e FROM public.work_board_events WHERE organization_id=ase_private.current_org()AND id=p_request;
 IF FOUND THEN IF e.plan_id<>p_plan OR e.to_state<>target OR e.actor_id<>actor OR e.reason<>btrim(p_reason)THEN RAISE EXCEPTION 'Identificador de operación ya utilizado';END IF;RETURN jsonb_build_object('success',true,'state',e.to_state,'version',e.applied_version,'repeated',true);END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org()AND id=p_plan FOR UPDATE;
 IF NOT FOUND OR (p.user_id<>actor AND NOT public.sec06_is_admin())THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes pausar esta ejecución';END IF;
 IF NOT public.sec06_is_admin()AND public.work_mode()THEN RAISE EXCEPTION 'Confirma esta acción en la tablet';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=p.organization_id AND task_id=p.task_id AND user_id=p.user_id)THEN RAISE EXCEPTION 'La tarea ya no está asignada al empleado';END IF;
 IF p_action='pause'THEN
  IF p.state<>'active'THEN RAISE EXCEPTION 'Solo se puede pausar una ejecución en curso';END IF;
  SELECT * INTO c FROM public.checkins WHERE organization_id=p.organization_id AND work_plan_id=p.id AND user_id=p.user_id AND checkout_time IS NULL FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'No se encontró el fichaje activo';END IF;
  PERFORM set_config('ase.pause_execution','on',true);UPDATE public.checkins SET checkout_time=stamp WHERE organization_id=c.organization_id AND id=c.id;checkin:=c.id;
 ELSE
  IF p.state<>'paused'THEN RAISE EXCEPTION 'Solo se puede reanudar una ejecución pausada';END IF;
  IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=p.organization_id AND user_id=p.user_id AND checkout_time IS NULL)THEN RAISE EXCEPTION 'Finaliza primero el otro fichaje activo';END IF;
  IF NOT coalesce((public.work_execution_timing(p.id,stamp)->>'can_start_time')::boolean,false)THEN RAISE EXCEPTION 'La ejecución no puede reanudarse fuera de su programación';END IF;
  PERFORM set_config('ase.resume_execution','on',true);
  INSERT INTO public.checkins(organization_id,task_id,user_id,checkin_time,checkin_method,location,work_plan_id)VALUES(p.organization_id,p.task_id,p.user_id,stamp,'manual','Reanudación de ejecución',NULL)RETURNING id INTO checkin;
  UPDATE public.checkins SET work_plan_id=p.id WHERE organization_id=p.organization_id AND id=checkin;
  UPDATE public.work_day_plan SET state='active',finished_at=NULL,board_reopened_at=stamp WHERE organization_id=p.organization_id AND id=p.id;
 END IF;
 SELECT board_version INTO version FROM public.work_day_plan WHERE organization_id=p.organization_id AND id=p.id;
 INSERT INTO public.work_board_events(id,organization_id,plan_id,actor_id,actor_name,from_state,to_state,reason,checkin_id,applied_version)VALUES(p_request,p.organization_id,p.id,actor,coalesce((SELECT full_name FROM ase_private.employee_profiles WHERE id=actor),'Empleado'),p.state,target,btrim(p_reason),checkin,version);
 RETURN jsonb_build_object('success',true,'state',target,'version',version,'checkin_id',checkin);
END $$;

CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('planning.view');IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días';END IF;IF p_state IS NOT NULL AND p_state NOT IN('pending','active','paused','blocked','review','completed','cancelled')THEN RAISE EXCEPTION 'Estado no válido';END IF;IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida';END IF;WITH base AS(SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org()AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)AND(nullif(btrim(p_query),'')IS NULL OR concat_ws(' ',t.title,t.description,u.full_name)ILIKE'%'||btrim(p_query)||'%')),page AS(SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)SELECT jsonb_build_object('start',p_start,'end',p_end,'total',(SELECT count(*)FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object('pending',(SELECT count(*)FROM base WHERE state='pending'),'active',(SELECT count(*)FROM base WHERE state='active'),'paused',(SELECT count(*)FROM base WHERE state='paused'),'blocked',(SELECT count(*)FROM base WHERE state='blocked'),'review',(SELECT count(*)FROM base WHERE state='review'),'completed',(SELECT count(*)FROM base WHERE state='completed'),'cancelled',(SELECT count(*)FROM base WHERE state='cancelled')),'items',coalesce((SELECT jsonb_agg(to_jsonb(page)ORDER BY work_date,priority,employee,id)FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp())INTO result;RETURN result;END $$;

CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS(SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,p.state,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,(public.work_execution_eligibility(p.id)->>'can_start')::boolean eligible,public.work_incident_resolver(t.id)incident FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org()AND p.user_id=ase_private.session_user_id()AND p.state IN('pending','active','paused','blocked','review','completed','cancelled')AND(p.state IN('active','paused')OR p.work_date BETWEEN public.work_today()-30 AND public.work_today()+365)),next_item AS(SELECT plan_id,task_id FROM items WHERE state='pending'AND eligible ORDER BY work_date,priority,plan_id LIMIT 1)SELECT jsonb_build_object('date',public.work_today(),'next_plan',(SELECT plan_id FROM next_item),'next_task',(SELECT task_id FROM next_item),'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',i.eligible AND(i.plan_id=(SELECT plan_id FROM next_item)OR i.incident),'can_resume',i.state='paused','can_finish',i.state='active')ORDER BY(i.state IN('completed','review','cancelled')),(i.state IN('active','paused'))DESC,i.work_date,i.priority,i.plan_id)FROM items i),'[]'::jsonb)) $$;

CREATE OR REPLACE FUNCTION public.work_my_day_v2() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=ase_private.session_user_id();items jsonb;BEGIN IF actor IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión';END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'task_id',p.task_id,'title',t.title,'state',p.state,'priority',p.priority,'work_date',p.work_date,'started_at',p.started_at,'finished_at',p.finished_at,'can_open',p.state IN('active','paused')AND public.work_can_detail(p.task_id))||public.work_deadline(p.work_date,p.state,p.finished_at)ORDER BY p.work_date,p.priority),'[]'::jsonb)INTO items FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org()AND p.user_id=actor AND(p.work_date=public.work_today()OR p.state IN('active','paused')OR(p.work_date<public.work_today()AND p.state='pending'))AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=p.organization_id AND a.task_id=p.task_id AND a.user_id=p.user_id);
 RETURN jsonb_build_object('date',public.work_today(),'items',items);
END $$;

-- Keep the new operational state visible and filterable in tabular reports.
CREATE OR REPLACE FUNCTION public.work_report_table_scope(p_kind text,p_start date,p_end date,p_search text,p_state text,p_method text,p_employee uuid,p_area uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('reports.view');
 IF p_kind IS NULL OR p_kind NOT IN ('checkins','tasks','productivity','incidents','closures') OR p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR length(coalesce(p_search,''))>120 THEN RAISE EXCEPTION 'Selecciona un informe y un período de hasta 366 días'; END IF;
 IF p_employee IS NOT NULL AND p_area IS NOT NULL THEN RAISE EXCEPTION 'Selecciona un empleado o un área'; END IF;
 IF p_employee IS NOT NULL AND NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_employee) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas WHERE id=p_area AND active) THEN RAISE EXCEPTION 'Área no válida'; END IF;
 WITH source AS (
SELECT row FROM (SELECT jsonb_build_object('_at',c.checkin_time,'_state',CASE WHEN c.checkout_time IS NULL THEN 'open' ELSE 'closed' END,'_method',c.checkin_method,'_users',jsonb_build_array(c.user_id),'employee',u.full_name,'task',t.title,'start',c.checkin_time,'end',c.checkout_time,'minutes',round((extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)/60)::numeric,2),'method',c.checkin_method,'status',CASE WHEN c.checkout_time IS NULL THEN 'En curso' ELSE 'Cerrado' END) row FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=c.user_id) dataset WHERE p_kind='checkins'
 UNION ALL
SELECT row FROM (SELECT jsonb_build_object('_at',(coalesce(p.work_date,t.schedule_date,(t.created_at AT TIME ZONE 'Europe/Madrid')::date)::timestamp AT TIME ZONE 'Europe/Madrid'),'_state',coalesce(p.state,'unplanned'),'_users',jsonb_build_array(a.user_id),'employee',u.full_name,'task',t.title,'date',coalesce(p.work_date,t.schedule_date),'priority',p.priority,'status',CASE p.state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'paused' THEN 'Pausada' WHEN 'completed' THEN 'Completada' WHEN 'blocked' THEN 'Bloqueada' WHEN 'review' THEN 'En revisión' WHEN 'cancelled' THEN 'Cancelada' ELSE 'Sin planificación' END) row FROM public.tasks t LEFT JOIN public.task_assignments a ON a.task_id=t.id LEFT JOIN ase_private.employee_profiles u ON u.id=a.user_id LEFT JOIN public.work_day_plan p ON p.task_id=t.id AND p.user_id=a.user_id) dataset WHERE p_kind='tasks'
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
 AND (p_area IS NULL OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=p_area AND row->'_users' @> jsonb_build_array(m.user_id)))
 AND (p_state IS NULL OR row->>'_state'=p_state) AND (p_method IS NULL OR row->>'_method'=p_method)
 AND (coalesce(btrim(p_search),'')='' OR strpos(lower((row-'_at'-'_state'-'_method'-'_users')::text),lower(btrim(p_search)))>0)
 ), limited AS (SELECT row FROM filtered ORDER BY row->>'_at' DESC,row::text LIMIT 10001)
 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(row-'_at'-'_state'-'_method'-'_users') FROM limited),'[]'::jsonb),'as_of',now()) INTO result;
 IF (result->>'total')::integer>10000 THEN RAISE EXCEPTION 'Hay más de 10.000 filas. Reduce las fechas o utiliza el buscador antes de descargar'; END IF;
 RETURN result;
END $$;

ALTER FUNCTION public.work_mobile_plan_sync() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_order_guard() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_guard() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_pause_execution(uuid,text,text,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,integer,integer) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_queue() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_my_day_v2() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_pause_execution(uuid,text,text,uuid),public.work_planning_board_range(date,date,uuid,text,text,integer,integer),public.work_mobile_queue(),public.work_my_day_v2(),public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_pause_execution(uuid,text,text,uuid),public.work_planning_board_range(date,date,uuid,text,text,integer,integer),public.work_mobile_queue(),public.work_my_day_v2(),public.work_report_table_scope(text,date,date,text,text,text,uuid,uuid) TO authenticated,ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_mobile_plan_sync(),public.work_mobile_order_guard(),public.work_execution_schedule_guard() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_mobile_plan_sync(),public.work_mobile_order_guard(),public.work_execution_schedule_guard() TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

