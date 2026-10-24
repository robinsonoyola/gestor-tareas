BEGIN;
ALTER TABLE public.work_recurrences ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.work_recurrences ADD COLUMN IF NOT EXISTS area_id uuid;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='recurrence_area_fk') THEN
 ALTER TABLE public.work_recurrences ADD CONSTRAINT recurrence_area_fk FOREIGN KEY(organization_id,area_id) REFERENCES public.work_areas(organization_id,id);
 ALTER TABLE public.work_recurrences ADD CONSTRAINT recurrence_one_target CHECK((user_id IS NOT NULL)::integer+(area_id IS NOT NULL)::integer=1);
END IF; END $$;
CREATE UNIQUE INDEX IF NOT EXISTS recurrence_per_area ON public.work_recurrences(organization_id,task_id,area_id) WHERE area_id IS NOT NULL;
CREATE TABLE IF NOT EXISTS public.work_area_recurrence_due(
 organization_id uuid NOT NULL,recurrence_id uuid NOT NULL,due date NOT NULL,plan_id uuid,assigned_by uuid,assigned_at timestamptz,notified_at timestamptz,
 PRIMARY KEY(organization_id,recurrence_id,due),
 FOREIGN KEY(organization_id,recurrence_id) REFERENCES public.work_recurrences(organization_id,id),
 FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id),
 FOREIGN KEY(organization_id,assigned_by) REFERENCES public.organization_memberships(organization_id,user_id));
ALTER TABLE public.work_area_recurrence_due ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_area_recurrence_due FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE ON public.work_area_recurrence_due TO ase_tenant_executor;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_area_recurrence_due' AND policyname='area_due_scope') THEN
 CREATE POLICY area_due_scope ON public.work_area_recurrence_due TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
END IF; END $$;
CREATE OR REPLACE FUNCTION ase_private.run_area_recurrences(p_org uuid,p_today date) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE rule public.work_recurrences%ROWTYPE; x record; recipient uuid; iteration integer; BEGIN
 FOR rule IN SELECT * FROM public.work_recurrences WHERE organization_id=p_org AND active AND area_id IS NOT NULL ORDER BY id FOR UPDATE LOOP
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM public.work_areas WHERE organization_id=p_org AND id=rule.area_id AND active) THEN RAISE EXCEPTION 'Área inactiva. Revisa sus responsables'; END IF;
   iteration:=0;
   WHILE rule.next_due IS NOT NULL AND rule.next_due<=p_today+greatest(30,rule.notice_days) LOOP
    iteration:=iteration+1;IF iteration>400 THEN RAISE EXCEPTION 'Demasiadas fechas pendientes. Revisa la repetición'; END IF;
    INSERT INTO public.work_area_recurrence_due(organization_id,recurrence_id,due) VALUES(p_org,rule.id,rule.next_due) ON CONFLICT DO NOTHING;
    IF rule.basis='completion' THEN rule.next_due:=NULL;EXIT; END IF;
    rule.cursor_n:=rule.cursor_n+1;rule.next_due:=ase_private.recurrence_date(rule.anchor,rule.frequency,rule.cursor_n*rule.every_n);
   END LOOP;
   UPDATE public.work_recurrences SET next_due=rule.next_due,cursor_n=rule.cursor_n,last_error=NULL WHERE organization_id=p_org AND id=rule.id;
  EXCEPTION WHEN OTHERS THEN UPDATE public.work_recurrences SET last_error=left(SQLERRM,500) WHERE organization_id=p_org AND id=rule.id; END;
 END LOOP;
 FOR x IN SELECT d.*,a.name,t.title FROM public.work_area_recurrence_due d JOIN public.work_recurrences r ON r.organization_id=d.organization_id AND r.id=d.recurrence_id
 JOIN public.work_areas a ON a.organization_id=r.organization_id AND a.id=r.area_id JOIN public.tasks t ON t.organization_id=r.organization_id AND t.id=r.task_id
 WHERE d.organization_id=p_org AND r.active AND d.plan_id IS NULL AND d.notified_at IS NULL AND d.due-r.notice_days<=p_today LOOP
  FOR recipient IN SELECT m.user_id FROM public.organization_memberships m WHERE m.organization_id=p_org AND m.status='active' AND (m.role IN ('admin','owner') OR EXISTS(SELECT 1 FROM public.work_area_members am JOIN public.work_recurrences r ON r.organization_id=am.organization_id AND r.area_id=am.area_id WHERE am.organization_id=p_org AND am.user_id=m.user_id AND r.id=x.recurrence_id)) LOOP
   INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message) VALUES(p_org,recipient,NULL,'Pendiente de asignación: '||x.title||' · Área '||x.name||' · '||to_char(x.due,'DD/MM/YYYY'));
  END LOOP;
  UPDATE public.work_area_recurrence_due SET notified_at=clock_timestamp() WHERE organization_id=p_org AND recurrence_id=x.recurrence_id AND due=x.due;
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION ase_private.run_area_recurrences(uuid,date) FROM PUBLIC,anon,authenticated,ase_tenant_executor;
CREATE OR REPLACE FUNCTION ase_private.run_recurrences(p_org uuid,p_today date) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE; candidate record; plan uuid; n integer; generated integer:=0; iteration integer; finished timestamptz;
BEGIN
 IF p_org IS NULL OR p_today IS NULL OR NOT pg_try_advisory_xact_lock(hashtextextended('recurrences:'||p_org::text,0)) THEN RETURN 0; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.organizations WHERE id=p_org AND status='active') THEN RETURN 0; END IF;
 FOR candidate IN SELECT id,user_id FROM public.work_recurrences WHERE organization_id=p_org AND active AND user_id IS NOT NULL ORDER BY user_id,id LOOP
  -- Same employee-first lock order as normal planning/check-ins.
  PERFORM 1 FROM public.users WHERE id=candidate.user_id FOR UPDATE;
  SELECT * INTO r FROM public.work_recurrences WHERE organization_id=p_org AND id=candidate.id FOR UPDATE;
  IF NOT r.active THEN CONTINUE; END IF;
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM public.organization_memberships WHERE organization_id=p_org AND user_id=r.user_id AND status='active' AND role NOT IN ('admin','owner'))
    OR NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=p_org AND task_id=r.task_id AND user_id=r.user_id) THEN
    RAISE EXCEPTION 'El encargado no está activo o ya no tiene asignada la tarea';
   END IF;
   iteration:=0;
   WHILE r.next_due IS NOT NULL AND r.next_due<=p_today+greatest(30,r.notice_days) LOOP
    iteration:=iteration+1;
    IF iteration>400 THEN RAISE EXCEPTION 'Hay demasiadas ejecuciones atrasadas. Revisa la repetición'; END IF;
    SELECT id INTO plan FROM public.work_day_plan WHERE organization_id=p_org AND user_id=r.user_id AND task_id=r.task_id AND work_date=r.next_due;
    IF plan IS NULL THEN
     SELECT coalesce(max(priority),0)+1 INTO n FROM public.work_day_plan WHERE organization_id=p_org AND user_id=r.user_id AND work_date=r.next_due;
     INSERT INTO public.work_day_plan(organization_id,user_id,task_id,work_date,priority) VALUES(p_org,r.user_id,r.task_id,r.next_due,n) RETURNING id INTO plan;
     generated:=generated+1;
    END IF;
    INSERT INTO public.work_recurrence_runs(organization_id,recurrence_id,due,plan_id) VALUES(p_org,r.id,r.next_due,plan) ON CONFLICT DO NOTHING;
    r.last_plan:=plan;
    IF r.basis='completion' THEN
     SELECT finished_at INTO finished FROM public.work_day_plan WHERE organization_id=p_org AND id=plan AND state='completed';
     IF finished IS NULL THEN r.next_due:=NULL;
     ELSE
      r.next_due:=ase_private.recurrence_date((finished AT TIME ZONE 'Europe/Madrid')::date,r.frequency,r.every_n);
      UPDATE public.work_recurrence_runs SET completed_at=finished WHERE organization_id=p_org AND plan_id=plan;
     END IF;
     EXIT;
    ELSE
     r.cursor_n:=r.cursor_n+1;
     r.next_due:=ase_private.recurrence_date(r.anchor,r.frequency,r.cursor_n*r.every_n);
    END IF;
   END LOOP;
   UPDATE public.work_recurrences SET next_due=r.next_due,cursor_n=r.cursor_n,last_plan=r.last_plan,last_error=NULL WHERE organization_id=p_org AND id=r.id;
  EXCEPTION WHEN OTHERS THEN
   IF r.last_error IS DISTINCT FROM left(SQLERRM,500) THEN
    INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message)
     SELECT p_org,m.user_id,NULL,'Repetición pendiente de revisión: '||t.title||'. Revisa el encargado y su asignación.'
     FROM public.organization_memberships m JOIN public.tasks t ON t.organization_id=m.organization_id AND t.id=r.task_id
     WHERE m.organization_id=p_org AND m.status='active' AND m.role IN ('admin','owner');
   END IF;
   UPDATE public.work_recurrences SET last_error=left(SQLERRM,500) WHERE organization_id=p_org AND id=r.id;
  END;
 END LOOP;
 -- Exactly one advance reminder per occurrence, including tasks generated on earlier runs.
 FOR candidate IN SELECT x.*,p.user_id,t.title FROM public.work_recurrence_runs x JOIN public.work_recurrences rule ON rule.organization_id=x.organization_id AND rule.id=x.recurrence_id
 JOIN public.tasks t ON t.organization_id=rule.organization_id AND t.id=rule.task_id
 JOIN public.work_day_plan p ON p.organization_id=x.organization_id AND p.id=x.plan_id
 WHERE x.organization_id=p_org AND rule.active AND x.notified_at IS NULL AND x.due-rule.notice_days<=p_today AND p.state IN ('pending','active') AND EXISTS(SELECT 1 FROM public.organization_memberships m WHERE m.organization_id=p_org AND m.user_id=p.user_id AND m.status='active')
 LOOP
  INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message) VALUES(p_org,candidate.user_id,NULL,'Tarea programada: '||candidate.title||' · '||to_char(candidate.due,'DD/MM/YYYY'));
  UPDATE public.work_recurrence_runs SET notified_at=clock_timestamp() WHERE organization_id=p_org AND recurrence_id=candidate.recurrence_id AND due=candidate.due;
 END LOOP;
 PERFORM ase_private.run_area_recurrences(p_org,p_today);
 RETURN generated;
END $$;
REVOKE ALL ON FUNCTION ase_private.run_recurrences(uuid,date) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.run_recurrences(uuid,date) TO ase_tenant_executor;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_create_area_recurrence(p_id uuid,p_task uuid,p_area uuid,p_start date,p_frequency text,p_every integer,p_basis text,p_notice integer) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 PERFORM 1 FROM public.work_areas WHERE id=p_area AND active FOR UPDATE;
 IF NOT FOUND OR p_id IS NULL OR p_start IS NULL OR p_start<public.work_today() OR p_start>public.work_today()+3650 OR p_frequency IS NULL OR p_frequency NOT IN ('daily','weekly','monthly','yearly') OR p_every IS NULL OR p_every NOT BETWEEN 1 AND 365 OR p_basis IS NULL OR p_basis NOT IN ('fixed','completion') OR p_notice IS NULL OR p_notice NOT BETWEEN 0 AND 365 THEN RAISE EXCEPTION 'Revisa el encargado, la fecha y la repetición'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE id=p_task) THEN RAISE EXCEPTION 'Tarea no disponible'; END IF;
 SELECT * INTO r FROM public.work_recurrences WHERE id=p_id;
 IF r.id IS NOT NULL THEN
  IF r.task_id=p_task AND r.area_id=p_area AND r.anchor=p_start AND r.frequency=p_frequency AND r.every_n=p_every AND r.basis=p_basis AND r.notice_days=p_notice THEN RETURN r.id; END IF;
  RAISE EXCEPTION 'La solicitud ya se utilizó con otros datos';
 END IF;
 INSERT INTO public.work_recurrences(id,task_id,area_id,anchor,next_due,frequency,every_n,basis,notice_days,created_by)
 VALUES(p_id,p_task,p_area,p_start,p_start,p_frequency,p_every,p_basis,p_notice,ase_private.session_user_id());
 PERFORM ase_private.run_recurrences(ase_private.current_org(),public.work_today());
 RETURN p_id;
END $$;
ALTER FUNCTION public.work_create_area_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_create_area_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_create_area_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_assign_area_recurrence(p_id uuid,p_due date,p_user uuid) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE; d public.work_area_recurrence_due%ROWTYPE; plan uuid; n integer; finished timestamptz; BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND NOT is_admin AND membership_status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 SELECT * INTO r FROM public.work_recurrences WHERE id=p_id AND area_id IS NOT NULL FOR UPDATE;
 IF r.id IS NULL OR NOT r.active THEN RAISE EXCEPTION 'Repetición no disponible o pausada'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.work_area_members WHERE area_id=r.area_id AND user_id=p_user) THEN RAISE EXCEPTION 'El empleado debe pertenecer al área'; END IF;
 SELECT * INTO d FROM public.work_area_recurrence_due WHERE recurrence_id=r.id AND due=p_due FOR UPDATE;
 IF d.recurrence_id IS NULL THEN RAISE EXCEPTION 'Fecha pendiente no disponible'; END IF;
 IF d.plan_id IS NOT NULL THEN
  IF EXISTS(SELECT 1 FROM public.work_day_plan WHERE id=d.plan_id AND user_id=p_user) THEN RETURN d.plan_id; END IF;
  RAISE EXCEPTION 'Esta ejecución ya se asignó. Revisa la planificación';
 END IF;
 INSERT INTO public.task_assignments(task_id,user_id) VALUES(r.task_id,p_user) ON CONFLICT DO NOTHING;
 SELECT id,finished_at INTO plan,finished FROM public.work_day_plan WHERE task_id=r.task_id AND user_id=p_user AND work_date=p_due;
 IF plan IS NULL THEN
  SELECT coalesce(max(priority),0)+1 INTO n FROM public.work_day_plan WHERE user_id=p_user AND work_date=p_due;
  INSERT INTO public.work_day_plan(task_id,user_id,work_date,priority) VALUES(r.task_id,p_user,p_due,n) RETURNING id INTO plan;
 END IF;
 IF EXISTS(SELECT 1 FROM public.work_recurrence_runs WHERE plan_id=plan AND recurrence_id<>r.id) THEN RAISE EXCEPTION 'Ese empleado ya tiene la misma tarea recurrente en esa fecha'; END IF;
 INSERT INTO public.work_recurrence_runs(organization_id,recurrence_id,due,plan_id,completed_at) VALUES(ase_private.current_org(),r.id,p_due,plan,finished) ON CONFLICT DO NOTHING;
 UPDATE public.work_area_recurrence_due SET plan_id=plan,assigned_by=ase_private.session_user_id(),assigned_at=clock_timestamp() WHERE recurrence_id=r.id AND due=p_due;
 UPDATE public.work_recurrences SET last_plan=plan,next_due=CASE WHEN basis='completion' AND finished IS NOT NULL THEN ase_private.recurrence_date((finished AT TIME ZONE 'Europe/Madrid')::date,frequency,every_n) ELSE next_due END WHERE id=r.id;
 INSERT INTO public.work_notifications(user_id,incident_id,message) SELECT p_user,NULL,'Nueva tarea del área: '||title||' · '||to_char(p_due,'DD/MM/YYYY') FROM public.tasks WHERE id=r.task_id;
 RETURN plan;
END $$;
ALTER FUNCTION public.work_assign_area_recurrence(uuid,date,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_assign_area_recurrence(uuid,date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_assign_area_recurrence(uuid,date,uuid) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_recurrence_list() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 RETURN jsonb_build_object('automation_ready',ase_private.recurrence_scheduler_ready(),'areas',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'name',a.name,'members',(SELECT coalesce(jsonb_agg(user_id),'[]'::jsonb) FROM public.work_area_members WHERE area_id=a.id))) FROM public.work_areas a WHERE active),'[]'::jsonb),
 'tasks',coalesce((SELECT jsonb_agg(jsonb_build_object('id',id,'title',title) ORDER BY title) FROM public.tasks),'[]'::jsonb),
 'items',coalesce((SELECT jsonb_agg(to_jsonb(r)||jsonb_build_object('title',t.title,'employee',u.full_name,'area_name',a.name,'runs',
 (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.due DESC),'[]'::jsonb) FROM (
 SELECT x.due,p.id plan_id,p.user_id,p.state,p.finished_at,x.notified_at,u.full_name employee FROM public.work_recurrence_runs x JOIN public.work_day_plan p ON p.id=x.plan_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE x.recurrence_id=r.id
 UNION ALL SELECT d.due,NULL::uuid,NULL::uuid,'unassigned'::text,NULL::timestamptz,d.notified_at,NULL::text FROM public.work_area_recurrence_due d WHERE d.recurrence_id=r.id AND d.plan_id IS NULL ORDER BY due DESC) x)) ORDER BY r.created_at DESC)
 FROM public.work_recurrences r JOIN public.tasks t ON t.id=r.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=r.user_id LEFT JOIN public.work_areas a ON a.id=r.area_id),'[]'::jsonb));
END $$;
ALTER FUNCTION public.work_recurrence_list() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_recurrence_list() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_recurrence_list() TO authenticated;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
