BEGIN;
-- A reopened plan retains prior closed checkins, with at most one open execution.
DROP INDEX IF EXISTS public.work_checkin_per_plan;
CREATE UNIQUE INDEX work_checkin_per_plan ON public.checkins(organization_id,work_plan_id) WHERE work_plan_id IS NOT NULL AND checkout_time IS NULL;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS board_version bigint NOT NULL DEFAULT 0;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS board_reopened_at timestamptz;
CREATE TABLE IF NOT EXISTS public.work_board_events(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),id uuid NOT NULL,plan_id uuid NOT NULL,actor_id uuid NOT NULL,actor_name text NOT NULL,
 from_state text NOT NULL,to_state text NOT NULL,reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 5 AND 2000),
 checkin_id uuid,incident_id uuid,responsible_id uuid,applied_version bigint NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id),FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id),
 FOREIGN KEY(organization_id,checkin_id) REFERENCES public.checkins(organization_id,id),
 FOREIGN KEY(organization_id,incident_id) REFERENCES public.work_incidents(organization_id,id));
ALTER TABLE public.work_board_events ADD COLUMN IF NOT EXISTS responsible_id uuid;
CREATE INDEX IF NOT EXISTS work_board_events_plan ON public.work_board_events(organization_id,plan_id,created_at,id);
ALTER TABLE public.work_board_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_board_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_board_events TO ase_tenant_executor;
DROP POLICY IF EXISTS board_events_executor ON public.work_board_events;
CREATE POLICY board_events_executor ON public.work_board_events TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_board_version() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$ BEGIN
 NEW.board_version:=OLD.board_version+1; RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS work_board_version ON public.work_day_plan;
CREATE TRIGGER work_board_version BEFORE UPDATE ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION public.work_board_version();
CREATE OR REPLACE FUNCTION public.work_move_board(p_plan uuid,p_state text,p_version bigint,p_reason text,p_request uuid,p_responsible uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;c public.checkins%ROWTYPE;e public.work_board_events%ROWTYPE;
 actor uuid:=ase_private.session_user_id();person uuid;stamp timestamptz:=clock_timestamp();incident uuid;checkin uuid;version bigint;old_flag text:=coalesce(current_setting('ase.tablet_write',true),'off');
BEGIN
 PERFORM public.work_assert_admin();
 IF p_request IS NULL OR p_version IS NULL OR p_state IS NULL OR p_state NOT IN ('pending','active','blocked','completed') OR p_reason IS NULL OR length(btrim(p_reason)) NOT BETWEEN 5 AND 2000 THEN RAISE EXCEPTION 'Indica un motivo de 5 a 2000 caracteres y un estado válido'; END IF;
 SELECT * INTO e FROM public.work_board_events WHERE id=p_request;
 IF FOUND THEN
  IF e.plan_id<>p_plan OR e.to_state<>p_state OR e.actor_id<>actor OR e.reason<>btrim(p_reason) OR e.responsible_id IS DISTINCT FROM (CASE WHEN p_state='blocked' THEN p_responsible ELSE NULL END) THEN RAISE EXCEPTION 'Identificador de operación ya utilizado'; END IF;
  RETURN jsonb_build_object('success',true,'state',e.to_state,'version',e.applied_version,'repeated',true);
 END IF;
 SELECT user_id INTO person FROM public.work_day_plan WHERE id=p_plan;
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=person AND membership_status='active' AND is_admin IS FALSE FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado o planificación no disponible'; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE id=p_plan FOR UPDATE;
 IF NOT FOUND OR p.board_version<>p_version THEN RAISE EXCEPTION 'La tarjeta ha cambiado. Actualiza el tablero y vuelve a intentarlo'; END IF;
 IF p.state=p_state THEN RAISE EXCEPTION 'La tarea ya está en ese estado'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=p.task_id AND user_id=p.user_id) THEN RAISE EXCEPTION 'La tarea ya no está asignada al empleado'; END IF;
 IF p.state='active' AND p_state='pending' OR p.state='pending' AND p_state='completed' OR p.state='blocked' AND p_state='completed' THEN RAISE EXCEPTION 'Para completar debe existir un fichaje activo. Para detener trabajo utiliza Bloqueadas'; END IF;
 IF p.state IN ('blocked','completed') AND p_state IN ('pending','active') AND EXISTS(SELECT 1 FROM public.work_incidents WHERE plan_id=p.id AND blocks_work AND state<>'resolved') THEN RAISE EXCEPTION 'Resuelve primero las incidencias que bloquean esta tarea'; END IF;
 SELECT * INTO c FROM public.checkins WHERE work_plan_id=p.id AND user_id=p.user_id AND checkout_time IS NULL FOR UPDATE;
 PERFORM set_config('ase.tablet_write','on',true);
 IF p_state='active' THEN
  IF p.work_date<>public.work_today() THEN RAISE EXCEPTION 'Solo se puede iniciar trabajo planificado para hoy'; END IF;
  IF EXISTS(SELECT 1 FROM public.checkins WHERE user_id=p.user_id AND checkout_time IS NULL) OR EXISTS(SELECT 1 FROM public.work_day_plan WHERE user_id=p.user_id AND state='active') THEN RAISE EXCEPTION 'El empleado ya tiene un fichaje activo'; END IF;
  IF EXISTS(SELECT 1 FROM public.work_day_plan WHERE user_id=p.user_id AND work_date=p.work_date AND state='pending' AND priority<p.priority AND id<>p.id) THEN RAISE EXCEPTION 'Respeta el orden de tareas del empleado o revisa su planificación'; END IF;
  IF p.state<>'pending' THEN UPDATE public.work_day_plan SET state='pending',started_at=NULL,finished_at=NULL,board_reopened_at=stamp WHERE id=p.id; END IF;
  INSERT INTO public.checkins(task_id,user_id,checkin_time,checkin_method,location,work_plan_id)
   VALUES(p.task_id,p.user_id,stamp,'manual','Inicio administrativo desde tablero',p.id) RETURNING id INTO checkin;
  UPDATE public.work_day_plan SET state='active',started_at=stamp,finished_at=NULL WHERE id=p.id;
 ELSIF p_state='completed' THEN
  IF p.state<>'active' OR c.id IS NULL THEN RAISE EXCEPTION 'No hay un fichaje activo que finalizar'; END IF;
  IF EXISTS(SELECT 1 FROM public.work_checklist_runs r CROSS JOIN LATERAL jsonb_array_elements(r.steps) item WHERE r.checkin_id=c.id AND (item->>'required')::boolean AND NOT coalesce((item->>'done')::boolean,false)) THEN RAISE EXCEPTION 'Completa los pasos obligatorios antes de finalizar la tarea'; END IF;
  checkin:=ase_private.close_work(p.id,btrim(p_reason),'admin_finish',NULL);
 ELSIF p_state='blocked' THEN
  IF p_responsible IS NULL OR NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_responsible AND membership_status='active') THEN RAISE EXCEPTION 'Selecciona quién resolverá la incidencia'; END IF;
  IF p.state='active' AND c.id IS NULL THEN RAISE EXCEPTION 'No se encontró el fichaje activo. Revisa la planificación'; END IF;
  INSERT INTO public.work_incidents(task_id,plan_id,reporter_id,assigned_user,subject,description,blocks_work)
   VALUES(p.task_id,p.id,actor,p_responsible,'Bloqueo desde tablero',btrim(p_reason),true) RETURNING id INTO incident;
  INSERT INTO public.work_notifications(user_id,incident_id,message) VALUES(p_responsible,incident,'Nueva incidencia: '||left(p_reason,120));
  IF c.id IS NOT NULL THEN
   UPDATE public.checkins SET checkout_time=stamp WHERE id=c.id;
   INSERT INTO public.work_task_closures(plan_id,checkin_id,actor_id,reason,kind,incident_id)
    VALUES(p.id,c.id,actor,btrim(p_reason),'incident_block',incident);
   checkin:=c.id;
  END IF;
  UPDATE public.work_day_plan SET state='blocked',finished_at=CASE WHEN c.id IS NOT NULL THEN stamp ELSE finished_at END WHERE id=p.id;
 ELSIF p_state='pending' THEN
  IF c.id IS NOT NULL THEN RAISE EXCEPTION 'Detén primero el fichaje antes de devolverla a pendientes'; END IF;
  UPDATE public.work_day_plan SET state='pending',started_at=NULL,finished_at=NULL,board_reopened_at=stamp WHERE id=p.id;
 END IF;
 UPDATE public.work_station_tickets SET expires_at=stamp WHERE plan_id=p.id AND result IS NULL;
 SELECT board_version INTO version FROM public.work_day_plan WHERE id=p.id;
 INSERT INTO public.work_board_events(id,plan_id,actor_id,actor_name,from_state,to_state,reason,checkin_id,incident_id,responsible_id,applied_version)
  VALUES(p_request,p.id,actor,coalesce((SELECT full_name FROM ase_private.employee_profiles WHERE id=actor),'Administrador'),p.state,p_state,btrim(p_reason),checkin,incident,CASE WHEN p_state='blocked' THEN p_responsible ELSE NULL END,version);
 PERFORM set_config('ase.tablet_write',old_flag,true);
 RETURN jsonb_build_object('success',true,'state',p_state,'version',version,'checkin_id',checkin,'incident_id',incident);
END $$;
CREATE OR REPLACE FUNCTION public.work_board_history(p_plan uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 SELECT coalesce(jsonb_agg(to_jsonb(e) ORDER BY e.created_at DESC,e.id),'[]') INTO result
 FROM(SELECT id,actor_name,from_state,to_state,reason,created_at FROM public.work_board_events WHERE plan_id=p_plan ORDER BY created_at DESC,id LIMIT 200) e;
 RETURN result;
END $$;
ALTER FUNCTION public.work_board_version() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_move_board(uuid,text,bigint,text,uuid,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_board_history(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_board_version() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.work_move_board(uuid,text,bigint,text,uuid,uuid),public.work_board_history(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_move_board(uuid,text,bigint,text,uuid,uuid),public.work_board_history(uuid) TO authenticated,ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS (
 SELECT t.id task_id,t.title,p.id plan_id,p.priority,p.work_date,
 CASE WHEN o.id IS NOT NULL THEN 'active' WHEN p.state IN ('completed','blocked') THEN p.state
 WHEN c.id IS NOT NULL AND (p.id IS NULL OR c.checkin_time>=greatest(p.created_at,coalesce(p.board_reopened_at,p.created_at))) THEN 'completed'
 WHEN p.state IS NOT NULL THEN p.state ELSE 'unplanned' END state,
 public.work_incident_resolver(t.id) incident
 FROM public.tasks t
 LEFT JOIN LATERAL (SELECT * FROM public.work_day_plan x WHERE x.organization_id=t.organization_id AND x.task_id=t.id
 AND x.user_id=ase_private.session_user_id() AND (x.work_date=public.work_today() OR x.state='active')
 ORDER BY (x.state='active') DESC,x.work_date DESC LIMIT 1) p ON true
 LEFT JOIN LATERAL (SELECT id FROM public.checkins x WHERE x.organization_id=t.organization_id AND x.task_id=t.id AND x.user_id=ase_private.session_user_id()
 AND x.checkout_time IS NULL LIMIT 1) o ON true
 LEFT JOIN LATERAL (SELECT id,checkin_time FROM public.checkins x WHERE x.organization_id=t.organization_id AND x.task_id=t.id AND x.user_id=ase_private.session_user_id()
 AND x.checkout_time IS NOT NULL AND (x.checkin_time AT TIME ZONE 'Europe/Madrid')::date=public.work_today() ORDER BY x.checkin_time DESC LIMIT 1) c ON true
 WHERE t.organization_id=ase_private.current_org() AND (EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=t.organization_id AND a.task_id=t.id AND a.user_id=ase_private.session_user_id()) OR public.work_incident_resolver(t.id))
 ), next_item AS (SELECT task_id FROM items WHERE state='pending' AND work_date=public.work_today() ORDER BY priority,task_id LIMIT 1),
 opened AS (SELECT EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=ase_private.current_org() AND user_id=ase_private.session_user_id() AND checkout_time IS NULL) v)
 SELECT jsonb_build_object('date',public.work_today(),'next_task',(SELECT task_id FROM next_item),
 'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',NOT opened.v AND (i.task_id=(SELECT task_id FROM next_item) OR i.incident),
 'can_finish',i.state='active') ORDER BY (i.state='completed'),(i.state='active') DESC,i.priority NULLS LAST,i.task_id) FROM items i CROSS JOIN opened),'[]'::jsonb))
$$;
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
  'version',p.board_version,'started_at',p.started_at,'finished_at',p.finished_at) || public.work_deadline(p.work_date,p.state,p.finished_at)
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
