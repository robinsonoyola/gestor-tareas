BEGIN;
-- Checklist templates and immutable per-checkin copies. Existing completed records are unchanged.
CREATE TABLE IF NOT EXISTS public.work_checklist_templates (
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(), task_id uuid NOT NULL, steps jsonb NOT NULL DEFAULT '[]',
 PRIMARY KEY(organization_id,task_id), FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 CHECK(jsonb_typeof(steps)='array' AND jsonb_array_length(steps)<=50));
CREATE TABLE IF NOT EXISTS public.work_checklist_runs (
 organization_id uuid NOT NULL, checkin_id uuid NOT NULL, steps jsonb NOT NULL DEFAULT '[]',
 PRIMARY KEY(organization_id,checkin_id), FOREIGN KEY(organization_id,checkin_id) REFERENCES public.checkins(organization_id,id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS public.work_checklist_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,checkin_id uuid NOT NULL,step_id uuid NOT NULL,
 actor_id uuid NOT NULL,done boolean NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 FOREIGN KEY(organization_id,checkin_id) REFERENCES public.work_checklist_runs(organization_id,checkin_id) ON DELETE CASCADE);
CREATE INDEX IF NOT EXISTS work_checklist_events_history ON public.work_checklist_events(organization_id,checkin_id,created_at,id);
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['work_checklist_templates','work_checklist_runs','work_checklist_events'] LOOP
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
  EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC,anon,authenticated',t);
  EXECUTE format('GRANT SELECT,INSERT,UPDATE ON public.%I TO ase_tenant_executor',t);
  EXECUTE format('DROP POLICY IF EXISTS checklist_executor ON public.%I',t);
  EXECUTE format('CREATE POLICY checklist_executor ON public.%I TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org())',t);
 END LOOP;
END $$;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_save_checklist(p_task uuid,p_steps jsonb,p_previous jsonb) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb; normalized jsonb:='[]'; existing jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 PERFORM 1 FROM public.tasks WHERE id=p_task FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Tarea no disponible'; END IF;
 SELECT steps INTO existing FROM public.work_checklist_templates WHERE task_id=p_task;
 IF coalesce(existing,'[]') IS DISTINCT FROM p_previous THEN RAISE EXCEPTION 'Los pasos han cambiado. Cierra y vuelve a abrir la lista antes de guardar'; END IF;
 IF p_steps IS NULL OR jsonb_typeof(p_steps)<>'array' THEN RAISE EXCEPTION 'Lista de pasos no válida'; END IF;
 IF jsonb_array_length(p_steps)>50 THEN RAISE EXCEPTION 'Máximo 50 pasos por tarea'; END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(p_steps) LOOP
  IF jsonb_typeof(item)<>'object' OR jsonb_typeof(item->'title') IS DISTINCT FROM 'string' OR length(btrim(item->>'title')) NOT BETWEEN 1 AND 200 OR jsonb_typeof(item->'required') IS DISTINCT FROM 'boolean' OR item->>'id' IS NULL THEN RAISE EXCEPTION 'Cada paso necesita título, identificador y obligatoriedad'; END IF;
  normalized:=normalized||jsonb_build_array(jsonb_build_object('id',(item->>'id')::uuid,'title',btrim(item->>'title'),'required',(item->>'required')::boolean));
 END LOOP;
 IF (SELECT count(DISTINCT value->>'id') FROM jsonb_array_elements(normalized))<>jsonb_array_length(normalized) THEN RAISE EXCEPTION 'No repitas identificadores de pasos'; END IF;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE task_id=p_task AND checkout_time IS NULL) THEN RAISE EXCEPTION 'Espera a que finalicen los fichajes abiertos para modificar los pasos'; END IF;
 INSERT INTO public.work_checklist_templates(organization_id,task_id,steps) VALUES(ase_private.current_org(),p_task,normalized)
 ON CONFLICT(organization_id,task_id) DO UPDATE SET steps=EXCLUDED.steps;
END $$;
CREATE OR REPLACE FUNCTION public.work_snapshot_checklist() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE items jsonb;
BEGIN
 PERFORM 1 FROM public.tasks WHERE id=NEW.task_id FOR SHARE;
 SELECT steps INTO items FROM public.work_checklist_templates WHERE task_id=NEW.task_id;
 INSERT INTO public.work_checklist_runs(organization_id,checkin_id,steps)
 VALUES(NEW.organization_id,NEW.id,coalesce(items,'[]')) ON CONFLICT DO NOTHING;
 RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS work_checklist_snapshot ON public.checkins;
CREATE TRIGGER work_checklist_snapshot AFTER INSERT ON public.checkins FOR EACH ROW EXECUTE FUNCTION public.work_snapshot_checklist();
-- Bootstrap only open checkins. Empty templates make existing execution compatible.
INSERT INTO public.work_checklist_runs(organization_id,checkin_id,steps)
 SELECT c.organization_id,c.id,coalesce(t.steps,'[]') FROM public.checkins c LEFT JOIN public.work_checklist_templates t ON t.organization_id=c.organization_id AND t.task_id=c.task_id
 WHERE c.checkout_time IS NULL ON CONFLICT DO NOTHING;
CREATE OR REPLACE FUNCTION public.work_get_checklist(p_task uuid,p_checkin uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE c public.checkins%ROWTYPE; items jsonb; events jsonb; manager boolean;
BEGIN
 IF ase_private.session_user_id() IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;
 manager:=public.work_has_permission('tasks.view') OR public.work_has_permission('checkins.view');
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE id=p_task) OR NOT (manager OR public.work_incident_resolver(p_task) OR EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarea no disponible'; END IF;
 IF p_checkin IS NULL THEN
  SELECT steps INTO items FROM public.work_checklist_templates WHERE task_id=p_task;
  RETURN jsonb_build_object('steps',coalesce(items,'[]'),'editable',false,'events','[]'::jsonb);
 END IF;
 SELECT * INTO c FROM public.checkins WHERE id=p_checkin AND task_id=p_task;
 IF NOT FOUND OR NOT(manager OR c.user_id=ase_private.session_user_id()) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible'; END IF;
 SELECT steps INTO items FROM public.work_checklist_runs WHERE checkin_id=c.id;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',e.id,'step_id',e.step_id,'done',e.done,'at',e.created_at,'actor',coalesce(u.full_name,'Empleado')) ORDER BY e.created_at,e.id),'[]') INTO events
 FROM public.work_checklist_events e LEFT JOIN ase_private.employee_profiles u ON u.id=e.actor_id WHERE e.checkin_id=c.id;
 RETURN jsonb_build_object('steps',coalesce(items,'[]'),'editable',c.user_id=ase_private.session_user_id() AND c.checkout_time IS NULL,'events',events);
END $$;
CREATE OR REPLACE FUNCTION public.work_mark_checklist(p_checkin uuid,p_step uuid,p_done boolean) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE c public.checkins%ROWTYPE;items jsonb;position integer;
BEGIN
 SELECT * INTO c FROM public.checkins WHERE id=p_checkin FOR UPDATE;
 IF NOT FOUND OR c.user_id IS DISTINCT FROM ase_private.session_user_id() OR c.checkout_time IS NOT NULL OR p_done IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Solo puedes marcar pasos durante tu fichaje activo'; END IF;
 SELECT steps INTO items FROM public.work_checklist_runs WHERE checkin_id=c.id FOR UPDATE;
 SELECT (ordinality-1)::integer INTO position FROM jsonb_array_elements(items) WITH ORDINALITY WHERE value->>'id'=p_step::text;
 IF position IS NULL THEN RAISE EXCEPTION 'Paso no disponible'; END IF;
 IF coalesce((items->position->>'done')::boolean,false)=p_done THEN RETURN; END IF;
 items:=jsonb_set(items,ARRAY[position::text,'done'],to_jsonb(p_done));
 UPDATE public.work_checklist_runs SET steps=items WHERE checkin_id=c.id;
 INSERT INTO public.work_checklist_events(organization_id,checkin_id,step_id,actor_id,done) VALUES(c.organization_id,c.id,p_step,ase_private.session_user_id(),p_done);
END $$;
CREATE OR REPLACE FUNCTION public.work_guard_checklist_completion() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 -- Exceptional administrative/incident closures retain their separate, mandatory reason and audit.
 IF EXISTS(SELECT 1 FROM public.work_task_closures WHERE checkin_id=NEW.id AND kind IN ('incident_block','admin_finish')) THEN RETURN NEW; END IF;
 IF EXISTS(SELECT 1 FROM public.work_checklist_runs r CROSS JOIN LATERAL jsonb_array_elements(r.steps) item WHERE r.checkin_id=NEW.id AND (item->>'required')::boolean AND NOT coalesce((item->>'done')::boolean,false)) THEN
  RAISE EXCEPTION 'Completa los pasos obligatorios antes de finalizar la tarea';
 END IF;
 RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS work_checklist_completion ON public.checkins;
CREATE CONSTRAINT TRIGGER work_checklist_completion AFTER UPDATE ON public.checkins DEFERRABLE INITIALLY DEFERRED
 FOR EACH ROW WHEN(OLD.checkout_time IS NULL AND NEW.checkout_time IS NOT NULL) EXECUTE FUNCTION public.work_guard_checklist_completion();
ALTER FUNCTION public.work_save_checklist(uuid,jsonb,jsonb) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_snapshot_checklist() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_get_checklist(uuid,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_mark_checklist(uuid,uuid,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_guard_checklist_completion() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_save_checklist(uuid,jsonb,jsonb),public.work_get_checklist(uuid,uuid),public.work_mark_checklist(uuid,uuid,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_save_checklist(uuid,jsonb,jsonb),public.work_get_checklist(uuid,uuid),public.work_mark_checklist(uuid,uuid,boolean) TO authenticated,ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_snapshot_checklist(),public.work_guard_checklist_completion() FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION public.work_station_checklist(p_station text,p_ticket uuid,p_step uuid DEFAULT NULL,p_done boolean DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE k public.work_station_tickets%ROWTYPE;c public.checkins%ROWTYPE;items jsonb;position integer;
BEGIN
 -- Reuse station binding, card/PIN revocation, membership and expiry validation.
 PERFORM public.work_station_day_v2(p_station,p_ticket);
 SELECT * INTO k FROM public.work_station_tickets WHERE id=p_ticket FOR UPDATE;
 IF NOT FOUND OR k.expires_at<=clock_timestamp() OR k.result IS NOT NULL OR k.expected_action<>'finish' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Vuelve a identificarte para consultar tus pasos'; END IF;
 SELECT * INTO c FROM public.checkins WHERE user_id=k.user_id AND work_plan_id=k.plan_id AND checkout_time IS NULL FOR UPDATE;
 IF NOT FOUND OR NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=c.task_id AND user_id=k.user_id) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes esta tarea en curso'; END IF;
 SELECT steps INTO items FROM public.work_checklist_runs WHERE checkin_id=c.id FOR UPDATE;
 IF p_step IS NOT NULL THEN
  IF p_done IS NULL THEN RAISE EXCEPTION 'Marca un estado válido'; END IF;
  SELECT (ordinality-1)::integer INTO position FROM jsonb_array_elements(items) WITH ORDINALITY WHERE value->>'id'=p_step::text;
  IF position IS NULL THEN RAISE EXCEPTION 'Paso no disponible'; END IF;
  IF coalesce((items->position->>'done')::boolean,false) IS DISTINCT FROM p_done THEN
   items:=jsonb_set(items,ARRAY[position::text,'done'],to_jsonb(p_done));
   UPDATE public.work_checklist_runs SET steps=items WHERE checkin_id=c.id;
   INSERT INTO public.work_checklist_events(organization_id,checkin_id,step_id,actor_id,done) VALUES(c.organization_id,c.id,p_step,k.user_id,p_done);
  END IF;
 END IF;
 RETURN jsonb_build_object('steps',coalesce(items,'[]'),'checkin_id',c.id);
END $$;
ALTER FUNCTION public.work_station_checklist(text,uuid,uuid,boolean) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_station_checklist(text,uuid,uuid,boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.work_station_checklist(text,uuid,uuid,boolean) TO anon,authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
