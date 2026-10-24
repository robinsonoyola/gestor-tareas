BEGIN;

ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS schedule_kind text NOT NULL DEFAULT 'scheduled';
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS available_from timestamptz;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS scheduled_for timestamptz;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS due_at timestamptz;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS planned_end timestamptz;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS strict_schedule boolean NOT NULL DEFAULT true;

UPDATE public.work_day_plan
SET schedule_kind='scheduled',
    scheduled_for=work_date::timestamp AT TIME ZONE 'Europe/Madrid',
    due_at=(work_date+1)::timestamp AT TIME ZONE 'Europe/Madrid',
    strict_schedule=true
WHERE schedule_kind='scheduled' AND scheduled_for IS NULL;

DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='work_execution_schedule_kind' AND conrelid='public.work_day_plan'::regclass) THEN
  ALTER TABLE public.work_day_plan ADD CONSTRAINT work_execution_schedule_kind CHECK(schedule_kind IN ('anytime','deadline','window','scheduled','period'));
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='work_execution_schedule_shape' AND conrelid='public.work_day_plan'::regclass) THEN
  ALTER TABLE public.work_day_plan ADD CONSTRAINT work_execution_schedule_shape CHECK(
   (schedule_kind='anytime' AND available_from IS NULL AND scheduled_for IS NULL AND due_at IS NULL AND planned_end IS NULL AND strict_schedule IS FALSE)
   OR (schedule_kind='deadline' AND available_from IS NULL AND scheduled_for IS NULL AND due_at IS NOT NULL AND planned_end IS NULL AND strict_schedule IS FALSE)
   OR (schedule_kind='window' AND available_from IS NOT NULL AND scheduled_for IS NULL AND due_at IS NOT NULL AND planned_end IS NULL AND strict_schedule IS FALSE AND available_from<due_at)
   OR (schedule_kind='scheduled' AND available_from IS NULL AND scheduled_for IS NOT NULL AND planned_end IS NULL AND (due_at IS NULL OR scheduled_for<due_at))
   OR (schedule_kind='period' AND available_from IS NOT NULL AND scheduled_for IS NULL AND planned_end IS NOT NULL AND strict_schedule IS FALSE AND available_from<planned_end AND (due_at IS NULL OR available_from<due_at))
  );
 END IF;
END $$;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_execution_timing(p_plan uuid,p_moment timestamptz DEFAULT clock_timestamp()) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE; start_limit timestamptz; end_limit timestamptz; allowed boolean; overdue boolean;
BEGIN
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan;
 IF NOT FOUND THEN RAISE EXCEPTION 'Ejecución no disponible'; END IF;
 start_limit:=CASE p.schedule_kind WHEN 'window' THEN p.available_from WHEN 'period' THEN p.available_from WHEN 'scheduled' THEN CASE WHEN p.strict_schedule THEN p.scheduled_for END END;
 end_limit:=CASE p.schedule_kind WHEN 'deadline' THEN p.due_at WHEN 'window' THEN p.due_at WHEN 'scheduled' THEN p.due_at WHEN 'period' THEN coalesce(p.due_at,p.planned_end) END;
 overdue:=p.state IN ('pending','active') AND end_limit IS NOT NULL AND p_moment>=end_limit;
 allowed:=p.state='pending' AND (start_limit IS NULL OR p_moment>=start_limit) AND (end_limit IS NULL OR p_moment<end_limit);
 RETURN jsonb_build_object('kind',p.schedule_kind,'available_from',p.available_from,'scheduled_for',p.scheduled_for,'due_at',p.due_at,'planned_end',p.planned_end,'strict',p.strict_schedule,'can_start_time',allowed,'overdue',overdue,'starts_later',p.state='pending' AND start_limit IS NOT NULL AND p_moment<start_limit,'start_limit',start_limit,'end_limit',end_limit);
END $$;

DROP FUNCTION IF EXISTS public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid);
CREATE OR REPLACE FUNCTION public.work_set_execution_schedule(p_plan uuid,p_kind text,p_available_from timestamptz DEFAULT NULL,p_scheduled_for timestamptz DEFAULT NULL,p_due_at timestamptz DEFAULT NULL,p_planned_end timestamptz DEFAULT NULL,p_strict boolean DEFAULT false,p_version bigint DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE; result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 -- Normalise fields that are not part of the selected mode. This makes mode
 -- changes safe even when an older client submits values from hidden inputs.
 p_available_from:=CASE WHEN p_kind IN('window','period') THEN p_available_from END;
 p_scheduled_for:=CASE WHEN p_kind='scheduled' THEN p_scheduled_for END;
 p_due_at:=CASE WHEN p_kind IN('deadline','window','scheduled','period') THEN p_due_at END;
 p_planned_end:=CASE WHEN p_kind='period' THEN p_planned_end END;
 p_strict:=p_kind='scheduled' AND coalesce(p_strict,false);
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'La ejecución ya no existe'; END IF;
 IF p_version IS NOT NULL AND p.board_version<>p_version THEN RAISE EXCEPTION 'La ejecución ha cambiado. Actualiza la planificación'; END IF;
 IF p.state IN ('completed','blocked') THEN RAISE EXCEPTION 'No se cambian las fechas de una ejecución cerrada o bloqueada'; END IF;
 IF p_kind IS NULL OR p_kind NOT IN ('anytime','deadline','window','scheduled','period') THEN RAISE EXCEPTION 'Selecciona cuándo debe hacerse'; END IF;
 IF NOT (
  (p_kind='anytime' AND p_available_from IS NULL AND p_scheduled_for IS NULL AND p_due_at IS NULL AND p_planned_end IS NULL AND p_strict IS FALSE)
  OR (p_kind='deadline' AND p_available_from IS NULL AND p_scheduled_for IS NULL AND p_due_at IS NOT NULL AND p_planned_end IS NULL AND p_strict IS FALSE)
  OR (p_kind='window' AND p_available_from IS NOT NULL AND p_scheduled_for IS NULL AND p_due_at IS NOT NULL AND p_planned_end IS NULL AND p_strict IS FALSE AND p_available_from<p_due_at)
  OR (p_kind='scheduled' AND p_available_from IS NULL AND p_scheduled_for IS NOT NULL AND p_planned_end IS NULL AND (p_due_at IS NULL OR p_scheduled_for<p_due_at))
  OR (p_kind='period' AND p_available_from IS NOT NULL AND p_scheduled_for IS NULL AND p_planned_end IS NOT NULL AND p_strict IS FALSE AND p_available_from<p_planned_end AND (p_due_at IS NULL OR p_available_from<p_due_at))
 ) THEN RAISE EXCEPTION 'Las fechas no corresponden al tipo de planificación'; END IF;
 UPDATE public.work_day_plan SET schedule_kind=p_kind,available_from=p_available_from,scheduled_for=p_scheduled_for,due_at=p_due_at,planned_end=p_planned_end,strict_schedule=p_strict WHERE organization_id=p.organization_id AND id=p.id;
 SELECT public.work_execution_timing(p.id) INTO result;
 RETURN result||jsonb_build_object('id',p.id,'version',(SELECT board_version FROM public.work_day_plan WHERE id=p.id));
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_schedule_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE timing jsonb;
BEGIN
 IF NEW.work_plan_id IS NULL THEN RETURN NEW; END IF;
 SELECT public.work_execution_timing(NEW.work_plan_id,coalesce(NEW.checkin_time,clock_timestamp())) INTO timing;
 IF NOT coalesce((timing->>'can_start_time')::boolean,false) THEN
  IF coalesce((timing->>'starts_later')::boolean,false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Esta tarea todavía no está disponible'; END IF;
  IF coalesce((timing->>'overdue')::boolean,false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La fecha límite ha pasado. Solicita al encargado que reprograme la tarea'; END IF;
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La tarea no puede iniciarse en este momento';
 END IF;
 RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS zz_work_execution_schedule_guard ON public.checkins;
CREATE TRIGGER zz_work_execution_schedule_guard BEFORE INSERT ON public.checkins FOR EACH ROW EXECUTE FUNCTION public.work_execution_schedule_guard();

ALTER FUNCTION public.work_execution_timing(uuid,timestamptz) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_guard() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_execution_timing(uuid,timestamptz),public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint),public.work_execution_schedule_guard() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_execution_timing(uuid,timestamptz),public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint) TO authenticated,ase_tenant_executor;

REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
-- Complete execution-date contract. Kept in the same incremental migration so
-- the UI is never activated against the earlier foundation alone.

CREATE TABLE IF NOT EXISTS public.work_execution_schedule_events(
 organization_id uuid NOT NULL, id uuid NOT NULL DEFAULT gen_random_uuid(), plan_id uuid NOT NULL,
 request_id uuid, actor_id uuid, actor_name text NOT NULL, previous jsonb NOT NULL, current_value jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id), UNIQUE(organization_id,request_id),
 FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id)
);
ALTER TABLE public.work_execution_schedule_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_execution_schedule_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_execution_schedule_events TO ase_tenant_executor;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_execution_schedule_events' AND policyname='execution_schedule_scope') THEN
 CREATE POLICY execution_schedule_scope ON public.work_execution_schedule_events TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
END IF; END $$;

CREATE OR REPLACE FUNCTION ase_private.execution_schedule_json(p public.work_day_plan) RETURNS jsonb
LANGUAGE sql IMMUTABLE SET search_path='' AS $$ SELECT jsonb_build_object('schedule_kind',p.schedule_kind,'available_from',p.available_from,'scheduled_for',p.scheduled_for,'due_at',p.due_at,'planned_end',p.planned_end,'strict_schedule',p.strict_schedule) $$;

-- Every newly created execution, including personal and area recurrences, gets
-- dates derived from its own work_date. No catalog date is copied.
CREATE OR REPLACE FUNCTION public.work_execution_schedule_defaults() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$ BEGIN
 IF NEW.schedule_kind IS NULL THEN NEW.schedule_kind:='scheduled'; END IF;
 IF NEW.schedule_kind='scheduled' AND NEW.scheduled_for IS NULL THEN
  NEW.scheduled_for:=NEW.work_date::timestamp AT TIME ZONE 'Europe/Madrid';
  NEW.due_at:=coalesce(NEW.due_at,(NEW.work_date+1)::timestamp AT TIME ZONE 'Europe/Madrid');
  NEW.strict_schedule:=true;
 END IF;
 RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS aa_work_execution_schedule_defaults ON public.work_day_plan;
CREATE TRIGGER aa_work_execution_schedule_defaults BEFORE INSERT ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION public.work_execution_schedule_defaults();

-- One authoritative server decision for manual, NFC, tablet and board starts.
CREATE OR REPLACE FUNCTION public.work_execution_eligibility(p_plan uuid,p_moment timestamptz DEFAULT clock_timestamp()) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE; start_limit timestamptz; end_limit timestamptz; temporal boolean; earlier boolean; assigned boolean; opened boolean; reason text;
BEGIN
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan;
 IF NOT FOUND THEN RAISE EXCEPTION 'Ejecución no disponible'; END IF;
 start_limit:=CASE p.schedule_kind WHEN 'window' THEN p.available_from WHEN 'period' THEN p.available_from WHEN 'scheduled' THEN CASE WHEN p.strict_schedule THEN p.scheduled_for END END;
 end_limit:=CASE p.schedule_kind WHEN 'deadline' THEN p.due_at WHEN 'window' THEN p.due_at WHEN 'scheduled' THEN p.due_at WHEN 'period' THEN coalesce(p.due_at,p.planned_end) END;
 temporal:=(start_limit IS NULL OR p_moment>=start_limit) AND (end_limit IS NULL OR p_moment<end_limit);
 assigned:=EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=p.organization_id AND a.task_id=p.task_id AND a.user_id=p.user_id);
 opened:=EXISTS(SELECT 1 FROM public.checkins c WHERE c.organization_id=p.organization_id AND c.user_id=p.user_id AND c.checkout_time IS NULL AND c.work_plan_id IS DISTINCT FROM p.id);
 earlier:=EXISTS(SELECT 1 FROM public.work_day_plan x WHERE x.organization_id=p.organization_id AND x.user_id=p.user_id AND x.state='pending' AND x.id<>p.id AND x.priority<p.priority AND x.work_date=p.work_date);
 reason:=CASE WHEN p.state<>'pending' THEN 'state' WHEN NOT assigned THEN 'assignment' WHEN opened THEN 'open_checkin' WHEN earlier THEN 'order' WHEN start_limit IS NOT NULL AND p_moment<start_limit THEN 'too_early' WHEN end_limit IS NOT NULL AND p_moment>=end_limit THEN 'overdue' ELSE NULL END;
 RETURN ase_private.execution_schedule_json(p)||jsonb_build_object('kind',p.schedule_kind,'strict',p.strict_schedule,'can_start',reason IS NULL,'can_start_time',temporal,'reason',reason,'overdue',p.state IN ('pending','active') AND end_limit IS NOT NULL AND p_moment>=end_limit,'starts_later',p.state='pending' AND start_limit IS NOT NULL AND p_moment<start_limit,'start_limit',start_limit,'end_limit',end_limit);
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_timing(p_plan uuid,p_moment timestamptz DEFAULT clock_timestamp()) RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$ SELECT public.work_execution_eligibility(p_plan,p_moment) $$;

DROP FUNCTION IF EXISTS public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint);
CREATE FUNCTION public.work_set_execution_schedule(p_plan uuid,p_kind text,p_available_from timestamptz DEFAULT NULL,p_scheduled_for timestamptz DEFAULT NULL,p_due_at timestamptz DEFAULT NULL,p_planned_end timestamptz DEFAULT NULL,p_strict boolean DEFAULT false,p_version bigint DEFAULT NULL,p_request uuid DEFAULT NULL) RETURNS jsonb
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

CREATE OR REPLACE FUNCTION public.work_execution_schedule_history(p_plan uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF NOT EXISTS(SELECT 1 FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND id=p_plan) THEN RAISE EXCEPTION 'Ejecución no disponible'; END IF;
 RETURN coalesce((SELECT jsonb_agg(to_jsonb(e) ORDER BY created_at DESC,id) FROM(SELECT id,actor_name,previous,current_value,created_at FROM public.work_execution_schedule_events WHERE organization_id=ase_private.current_org() AND plan_id=p_plan ORDER BY created_at DESC,id LIMIT 100)e),'[]'::jsonb);
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_schedule_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE eligibility jsonb; BEGIN IF NEW.work_plan_id IS NULL THEN RETURN NEW; END IF; eligibility:=public.work_execution_eligibility(NEW.work_plan_id,coalesce(NEW.checkin_time,clock_timestamp())); IF NOT coalesce((eligibility->>'can_start')::boolean,false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE=CASE eligibility->>'reason' WHEN 'too_early' THEN 'Esta tarea todavía no está disponible' WHEN 'overdue' THEN 'La fecha límite ha pasado. Solicita al encargado que reprograme la tarea' WHEN 'order' THEN 'Respeta el orden de tareas del empleado' WHEN 'open_checkin' THEN 'El empleado ya tiene un fichaje activo' WHEN 'assignment' THEN 'La tarea ya no está asignada al empleado' ELSE 'La tarea no puede iniciarse en este momento' END; END IF; RETURN NEW; END $$;

CREATE OR REPLACE FUNCTION public.work_admin_overview(p_user uuid,p_date date) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE v_plan jsonb;v_cards jsonb;v_stations jsonb;v_overdue jsonb; BEGIN PERFORM public.work_assert_permission('planning.view');
 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.priority),'[]') INTO v_plan FROM(SELECT p.id,p.task_id,t.title,p.priority,p.state,p.work_date,p.board_version version,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org() AND p.user_id=p_user AND p.work_date=p_date)q;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'user_id',user_id,'label',label,'active',active)),'[]') INTO v_cards FROM public.work_employee_cards WHERE organization_id=ase_private.current_org() AND archived_at IS NULL; SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'active',active,'reader_mode',reader_mode)),'[]') INTO v_stations FROM public.work_stations WHERE organization_id=ase_private.current_org() AND archived_at IS NULL;
 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.due_at,q.priority),'[]') INTO v_overdue FROM(SELECT p.id,p.user_id,p.task_id,t.title,p.work_date,p.priority,p.state,p.due_at,p.schedule_kind FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=ase_private.current_org() AND p.user_id=p_user AND p.state IN('pending','active') AND (public.work_execution_eligibility(p.id)->>'overdue')::boolean)q;
 RETURN jsonb_build_object('overdue',v_overdue,'enabled',public.work_mode(),'plan',v_plan,'cards',CASE WHEN public.sec06_is_admin() THEN v_cards ELSE '[]'::jsonb END,'stations',CASE WHEN public.sec06_is_admin() THEN v_stations ELSE '[]'::jsonb END); END $$;

CREATE OR REPLACE FUNCTION public.work_planning_board(p_date date,p_user uuid DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ DECLARE items jsonb;total integer; BEGIN PERFORM public.work_assert_permission('planning.view');IF p_date IS NULL THEN RAISE EXCEPTION 'Selecciona una fecha válida';END IF;SELECT count(*) INTO total FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND work_date=p_date AND(p_user IS NULL OR user_id=p_user);SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.priority,q.employee,q.id),'[]') INTO items FROM(SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,(public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org() AND p.work_date=p_date AND(p_user IS NULL OR p.user_id=p_user))q;RETURN jsonb_build_object('date',p_date,'items',items,'total',total,'as_of',now());END $$;

CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS (
  SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,p.state,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,
   (public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,
   (public.work_execution_eligibility(p.id)->>'can_start')::boolean eligible,public.work_incident_resolver(t.id) incident
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  WHERE p.organization_id=ase_private.current_org() AND p.user_id=ase_private.session_user_id() AND p.state IN('pending','active','blocked','completed')
   AND (p.state='active' OR p.work_date BETWEEN public.work_today()-30 AND public.work_today()+365)
 ), next_item AS (SELECT plan_id,task_id FROM items WHERE state='pending' AND eligible ORDER BY work_date,priority,plan_id LIMIT 1)
 SELECT jsonb_build_object('date',public.work_today(),'next_plan',(SELECT plan_id FROM next_item),'next_task',(SELECT task_id FROM next_item),'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',i.eligible AND (i.plan_id=(SELECT plan_id FROM next_item) OR i.incident),'can_finish',i.state='active') ORDER BY (i.state='completed'),(i.state='active') DESC,i.work_date,i.priority,i.plan_id) FROM items i),'[]'::jsonb))
$$;

CREATE OR REPLACE FUNCTION public.work_planning_calendar(p_user uuid,p_start date,p_end date) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('planning.view');IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>41 THEN RAISE EXCEPTION 'Selecciona hasta 42 días';END IF;SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.day),'[]') INTO result FROM(SELECT work_date AS day,count(*) AS total,count(*) FILTER(WHERE state='completed') AS completed,count(*) FILTER(WHERE state='active') AS active,count(*) FILTER(WHERE state IN('pending','active') AND (public.work_execution_eligibility(id)->>'overdue')::boolean) AS overdue,count(*) FILTER(WHERE state='pending' AND (public.work_execution_eligibility(id)->>'starts_later')::boolean) AS upcoming FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND user_id=p_user AND work_date BETWEEN p_start AND p_end GROUP BY work_date)q;RETURN result;END $$;

CREATE OR REPLACE FUNCTION public.work_overdue_items(p_limit integer DEFAULT 200) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ DECLARE result jsonb;BEGIN IF NOT(public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view'))THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso al seguimiento';END IF;IF p_limit IS NULL OR p_limit<1 OR p_limit>1000 THEN RAISE EXCEPTION 'Límite no válido';END IF;WITH filtered AS(SELECT p.id,p.task_id,p.user_id,p.work_date,p.state,p.priority,p.schedule_kind,p.due_at,p.planned_end,t.title,u.full_name employee FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org() AND p.state IN('pending','active') AND(public.work_execution_eligibility(p.id)->>'overdue')::boolean),page AS(SELECT * FROM filtered ORDER BY coalesce(due_at,planned_end),work_date,priority,id LIMIT p_limit)SELECT jsonb_build_object('total',(SELECT count(*)FROM filtered),'items',coalesce((SELECT jsonb_agg(to_jsonb(p)ORDER BY coalesce(p.due_at,p.planned_end),p.work_date,p.priority,p.id)FROM page p),'[]'))INTO result;RETURN result;END $$;

ALTER FUNCTION ase_private.execution_schedule_json(public.work_day_plan) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_defaults() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_eligibility(uuid,timestamptz) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_timing(uuid,timestamptz) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_history(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_guard() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_admin_overview(uuid,date) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_board(date,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mobile_queue() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_planning_calendar(uuid,date,date) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_overdue_items(integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_execution_eligibility(uuid,timestamptz),public.work_execution_timing(uuid,timestamptz),public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid),public.work_execution_schedule_history(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_execution_eligibility(uuid,timestamptz),public.work_execution_timing(uuid,timestamptz),public.work_set_execution_schedule(uuid,text,timestamptz,timestamptz,timestamptz,timestamptz,boolean,bigint,uuid),public.work_execution_schedule_history(uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
