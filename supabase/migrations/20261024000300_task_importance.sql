BEGIN;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS importance text NOT NULL DEFAULT 'normal';
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='task_importance_valid' AND conrelid='public.tasks'::regclass) THEN
 ALTER TABLE public.tasks ADD CONSTRAINT task_importance_valid CHECK(importance IN ('low','normal','high','urgent'));
END IF; END $$;
CREATE TABLE IF NOT EXISTS public.work_importance_events(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL REFERENCES public.organizations(id),task_id uuid NOT NULL,
 actor_id uuid,actor_name text NOT NULL,previous text,current_value text NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id),
 CHECK(previous IS NULL OR previous IN ('low','normal','high','urgent')),
 CHECK(current_value IN ('low','normal','high','urgent')));
CREATE INDEX IF NOT EXISTS work_importance_events_task ON public.work_importance_events(organization_id,task_id,created_at DESC,id);
ALTER TABLE public.work_importance_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_importance_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_importance_events TO ase_tenant_executor;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_importance_events' AND policyname='importance_scope') THEN
 CREATE POLICY importance_scope ON public.work_importance_events FOR SELECT TO ase_tenant_executor USING(organization_id=ase_private.current_org());
END IF; END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_importance_events' AND policyname='importance_insert') THEN
 CREATE POLICY importance_insert ON public.work_importance_events FOR INSERT TO ase_tenant_executor WITH CHECK(organization_id=ase_private.current_org());
END IF; END $$;
CREATE OR REPLACE FUNCTION ase_private.log_task_importance() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=ase_private.session_user_id(); actor_name text; BEGIN
 IF coalesce(current_setting('ase.suppress_importance_audit',true),'off')='on' THEN RETURN NEW; END IF;
 IF TG_OP='UPDATE' AND OLD.importance=NEW.importance THEN RETURN NEW; END IF;
 SELECT full_name INTO actor_name FROM public.organization_memberships WHERE organization_id=NEW.organization_id AND user_id=actor;
 INSERT INTO public.work_importance_events(organization_id,task_id,actor_id,actor_name,previous,current_value)
 VALUES(NEW.organization_id,NEW.id,actor,coalesce(actor_name,'Sistema'),CASE WHEN TG_OP='UPDATE' THEN OLD.importance ELSE NULL END,NEW.importance);
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION ase_private.log_task_importance() FROM PUBLIC,anon,authenticated,ase_tenant_executor;
DROP TRIGGER IF EXISTS task_importance_audit ON public.tasks;
CREATE TRIGGER task_importance_audit AFTER INSERT OR UPDATE OF importance ON public.tasks FOR EACH ROW EXECUTE FUNCTION ase_private.log_task_importance();
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_manage_task_importance(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_users uuid[] DEFAULT '{}'::uuid[]) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid; previous_value text; actor uuid:=ase_private.session_user_id(); actor_name text; org uuid:=ase_private.current_org(); old_flag text:=coalesce(current_setting('ase.suppress_importance_audit',true),'off'); BEGIN
 IF p_importance IS NULL OR p_importance NOT IN ('low','normal','high','urgent') THEN RAISE EXCEPTION 'Importancia no válida'; END IF;
 IF p_action IS NULL OR p_action NOT IN ('create','edit') THEN RAISE EXCEPTION 'Acción no válida'; END IF;
 PERFORM set_config('ase.suppress_importance_audit','on',true);
 result:=public.work_manage_task(p_action,p_id,p_title,p_description,p_schedule,p_date,p_status,p_users);
 SELECT importance INTO previous_value FROM public.tasks WHERE organization_id=org AND id=result FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 UPDATE public.tasks SET importance=p_importance WHERE organization_id=org AND id=result;
 PERFORM set_config('ase.suppress_importance_audit',old_flag,true);
 IF p_action='create' OR previous_value IS DISTINCT FROM p_importance THEN
  SELECT full_name INTO actor_name FROM public.organization_memberships WHERE organization_id=org AND user_id=actor;
  INSERT INTO public.work_importance_events(organization_id,task_id,actor_id,actor_name,previous,current_value)
  VALUES(org,result,actor,coalesce(actor_name,'Sistema'),CASE WHEN p_action='edit' THEN previous_value ELSE NULL END,p_importance);
 END IF;
 RETURN result;
END $$;
ALTER FUNCTION public.work_manage_task_importance(text,text,uuid,text,text,text,date,text,uuid[]) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_importance(text,text,uuid,text,text,text,date,text,uuid[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_importance(text,text,uuid,text,text,text,date,text,uuid[]) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_importance_history(p_task uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=ase_private.current_org() AND id=p_task) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF NOT (public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION 'No puedes consultar esta tarea'; END IF;
 RETURN coalesce((SELECT jsonb_agg(to_jsonb(e) ORDER BY created_at DESC,id) FROM(SELECT id,actor_name,previous,current_value,created_at FROM public.work_importance_events WHERE organization_id=ase_private.current_org() AND task_id=p_task ORDER BY created_at DESC,id LIMIT 100) e),'[]'::jsonb);
END $$;
ALTER FUNCTION public.work_importance_history(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_importance_history(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_importance_history(uuid) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_mobile_queue() RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS (
 SELECT t.id task_id,t.title,t.importance,p.id plan_id,p.priority,p.work_date,
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
 SELECT count(*) INTO total FROM public.work_day_plan WHERE organization_id=ase_private.current_org() AND work_date=p_date AND (p_user IS NULL OR user_id=p_user);
 IF total>10000 THEN RAISE EXCEPTION 'Hay demasiadas tareas para mostrar. Selecciona un empleado'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object(
  'id',p.id,'task_id',p.task_id,'employee_id',p.user_id,'employee',coalesce(u.full_name,'Empleado no disponible'),
  'title',t.title,'description',t.description,'importance',t.importance,'priority',p.priority,'state',p.state,'work_date',p.work_date,
  'version',p.board_version,'started_at',p.started_at,'finished_at',p.finished_at) || public.work_deadline(p.work_date,p.state,p.finished_at)
  ORDER BY p.priority,u.full_name,p.id),'[]'::jsonb) INTO items
 FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
 WHERE p.organization_id=ase_private.current_org() AND p.work_date=p_date AND (p_user IS NULL OR p.user_id=p_user);
 RETURN jsonb_build_object('date',p_date,'items',items,'total',total,'as_of',now());
END $$;
ALTER FUNCTION public.work_planning_board(date,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board(date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_board(date,uuid) TO authenticated,ase_tenant_executor;

REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
