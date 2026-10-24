BEGIN;
CREATE TABLE IF NOT EXISTS public.work_recurrences(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 task_id uuid NOT NULL,user_id uuid NOT NULL,anchor date NOT NULL,next_due date,
 frequency text NOT NULL CHECK(frequency IN ('daily','weekly','monthly','yearly')),
 every_n integer NOT NULL CHECK(every_n BETWEEN 1 AND 365),basis text NOT NULL CHECK(basis IN ('fixed','completion')),
 notice_days integer NOT NULL CHECK(notice_days BETWEEN 0 AND 365),active boolean NOT NULL DEFAULT true,
 cursor_n integer NOT NULL DEFAULT 0,last_plan uuid,last_error text,created_by uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(organization_id,id),UNIQUE(organization_id,task_id,user_id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id),
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,created_by) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,last_plan) REFERENCES public.work_day_plan(organization_id,id));
CREATE TABLE IF NOT EXISTS public.work_recurrence_runs(
 organization_id uuid NOT NULL,recurrence_id uuid NOT NULL,due date NOT NULL,plan_id uuid NOT NULL,
 notified_at timestamptz,completed_at timestamptz,PRIMARY KEY(organization_id,recurrence_id,due),
 UNIQUE(organization_id,plan_id),
 FOREIGN KEY(organization_id,recurrence_id) REFERENCES public.work_recurrences(organization_id,id),
 FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id));
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['work_recurrences','work_recurrence_runs'] LOOP
 EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
 EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC,anon,authenticated',t);
 EXECUTE format('GRANT SELECT,INSERT,UPDATE ON public.%I TO ase_tenant_executor',t);
 IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename=t AND policyname='recurrence_scope') THEN
 EXECUTE format('CREATE POLICY recurrence_scope ON public.%I TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org())',t);
 END IF;
 END LOOP;
END $$;
-- Reminders share the existing in-app inbox; an incident is optional for these notices.
ALTER TABLE public.work_notifications ALTER COLUMN incident_id DROP NOT NULL;
CREATE OR REPLACE FUNCTION ase_private.recurrence_date(p_anchor date,p_frequency text,p_n integer) RETURNS date
LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT CASE p_frequency WHEN 'daily' THEN p_anchor+p_n WHEN 'weekly' THEN p_anchor+7*p_n
 WHEN 'monthly' THEN (p_anchor+make_interval(months=>p_n))::date
 WHEN 'yearly' THEN (p_anchor+make_interval(years=>p_n))::date END
$$;
REVOKE ALL ON FUNCTION ase_private.recurrence_date(date,text,integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.recurrence_date(date,text,integer) TO ase_tenant_executor;
-- Owner-only scheduler worker. Every business lookup explicitly includes the organization.
CREATE OR REPLACE FUNCTION ase_private.run_recurrences(p_org uuid,p_today date) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE; candidate record; plan uuid; n integer; generated integer:=0; iteration integer; finished timestamptz;
BEGIN
 IF p_org IS NULL OR p_today IS NULL OR NOT pg_try_advisory_xact_lock(hashtextextended('recurrences:'||p_org::text,0)) THEN RETURN 0; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.organizations WHERE id=p_org AND status='active') THEN RETURN 0; END IF;
 FOR candidate IN SELECT id,user_id FROM public.work_recurrences WHERE organization_id=p_org AND active ORDER BY user_id,id LOOP
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
   UPDATE public.work_recurrences SET last_error=left(SQLERRM,500) WHERE organization_id=p_org AND id=r.id;
  END;
 END LOOP;
 -- Exactly one advance reminder per occurrence, including tasks generated on earlier runs.
 FOR candidate IN SELECT x.*,rule.user_id,t.title FROM public.work_recurrence_runs x JOIN public.work_recurrences rule ON rule.organization_id=x.organization_id AND rule.id=x.recurrence_id
 JOIN public.tasks t ON t.organization_id=rule.organization_id AND t.id=rule.task_id
 JOIN public.work_day_plan p ON p.organization_id=x.organization_id AND p.id=x.plan_id
 WHERE x.organization_id=p_org AND rule.active AND x.notified_at IS NULL AND x.due-rule.notice_days<=p_today AND p.state IN ('pending','active')
 LOOP
  INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message) VALUES(p_org,candidate.user_id,NULL,'Tarea programada: '||candidate.title||' · '||to_char(candidate.due,'DD/MM/YYYY'));
  UPDATE public.work_recurrence_runs SET notified_at=clock_timestamp() WHERE organization_id=p_org AND recurrence_id=candidate.recurrence_id AND due=candidate.due;
 END LOOP;
 RETURN generated;
END $$;
REVOKE ALL ON FUNCTION ase_private.run_recurrences(uuid,date) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.run_recurrences(uuid,date) TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION ase_private.recurrence_completed() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.state='completed' AND OLD.state IS DISTINCT FROM 'completed' AND NEW.finished_at IS NOT NULL THEN
  UPDATE public.work_recurrence_runs SET completed_at=NEW.finished_at WHERE organization_id=NEW.organization_id AND plan_id=NEW.id AND completed_at IS NULL;
  IF FOUND THEN
   UPDATE public.work_recurrences r SET next_due=ase_private.recurrence_date((NEW.finished_at AT TIME ZONE 'Europe/Madrid')::date,r.frequency,r.every_n)
    WHERE r.organization_id=NEW.organization_id AND r.last_plan=NEW.id AND r.basis='completion' AND r.next_due IS NULL;
  END IF;
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION ase_private.recurrence_completed() FROM PUBLIC,anon,authenticated,ase_tenant_executor;
DROP TRIGGER IF EXISTS recurrence_completed ON public.work_day_plan;
CREATE TRIGGER recurrence_completed AFTER UPDATE OF state ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION ase_private.recurrence_completed();
CREATE OR REPLACE FUNCTION ase_private.recurrence_scheduler_ready() RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE ready boolean; BEGIN
 IF to_regclass('cron.job') IS NULL THEN RETURN false; END IF;
 EXECUTE 'SELECT EXISTS(SELECT 1 FROM cron.job WHERE jobname=''ase-work-recurrences'' AND active AND command=''SELECT ase_private.schedule_recurrences()'' AND schedule=''17 * * * *'')' INTO ready;
 RETURN ready;
END $$;
REVOKE ALL ON FUNCTION ase_private.recurrence_scheduler_ready() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.recurrence_scheduler_ready() TO ase_tenant_executor;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_recurrence_list() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 RETURN jsonb_build_object('automation_ready',ase_private.recurrence_scheduler_ready(),'items',coalesce((SELECT jsonb_agg(to_jsonb(r)||jsonb_build_object('title',t.title,'employee',u.full_name,'runs',
  (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.due DESC),'[]'::jsonb) FROM (SELECT x.due,p.state,p.finished_at,x.notified_at FROM public.work_recurrence_runs x JOIN public.work_day_plan p ON p.id=x.plan_id WHERE x.recurrence_id=r.id ORDER BY x.due DESC LIMIT 24) x)) ORDER BY r.created_at DESC)
 FROM public.work_recurrences r JOIN public.tasks t ON t.id=r.task_id JOIN ase_private.employee_profiles u ON u.id=r.user_id),'[]'::jsonb));
END $$;
ALTER FUNCTION public.work_recurrence_list() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_recurrence_list() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_recurrence_list() TO authenticated;
CREATE OR REPLACE FUNCTION public.work_create_recurrence(p_id uuid,p_task uuid,p_user uuid,p_start date,p_frequency text,p_every integer,p_basis text,p_notice integer) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND NOT is_admin AND membership_status='active' FOR UPDATE;
 IF NOT FOUND OR p_id IS NULL OR p_start IS NULL OR p_start<public.work_today() OR p_start>public.work_today()+3650 OR p_frequency IS NULL OR p_frequency NOT IN ('daily','weekly','monthly','yearly') OR p_every IS NULL OR p_every NOT BETWEEN 1 AND 365 OR p_basis IS NULL OR p_basis NOT IN ('fixed','completion') OR p_notice IS NULL OR p_notice NOT BETWEEN 0 AND 365 THEN RAISE EXCEPTION 'Revisa el encargado, la fecha y la repetición'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=p_task AND user_id=p_user) THEN RAISE EXCEPTION 'Asigna primero la tarea al encargado'; END IF;
 SELECT * INTO r FROM public.work_recurrences WHERE id=p_id;
 IF r.id IS NOT NULL THEN
  IF r.task_id=p_task AND r.user_id=p_user AND r.anchor=p_start AND r.frequency=p_frequency AND r.every_n=p_every AND r.basis=p_basis AND r.notice_days=p_notice THEN RETURN r.id; END IF;
  RAISE EXCEPTION 'La solicitud ya se utilizó con otros datos';
 END IF;
 INSERT INTO public.work_recurrences(id,task_id,user_id,anchor,next_due,frequency,every_n,basis,notice_days,created_by)
 VALUES(p_id,p_task,p_user,p_start,p_start,p_frequency,p_every,p_basis,p_notice,ase_private.session_user_id());
 PERFORM ase_private.run_recurrences(ase_private.current_org(),public.work_today());
 RETURN p_id;
END $$;
ALTER FUNCTION public.work_create_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_create_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_create_recurrence(uuid,uuid,uuid,date,text,integer,text,integer) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_pause_recurrence(p_id uuid,p_active boolean) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 IF p_active IS NULL THEN RAISE EXCEPTION 'Estado no válido'; END IF;
 UPDATE public.work_recurrences SET active=p_active WHERE id=p_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Repetición no disponible'; END IF;
END $$;
ALTER FUNCTION public.work_pause_recurrence(uuid,boolean) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_pause_recurrence(uuid,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_pause_recurrence(uuid,boolean) TO authenticated;
CREATE OR REPLACE FUNCTION public.work_run_recurrences() RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 RETURN ase_private.run_recurrences(ase_private.current_org(),public.work_today());
END $$;
ALTER FUNCTION public.work_run_recurrences() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_run_recurrences() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_run_recurrences() TO authenticated;
-- Database scheduler only: no API key or user session is persisted.
CREATE OR REPLACE FUNCTION ase_private.schedule_recurrences() RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid; BEGIN
 FOR org IN SELECT id FROM public.organizations WHERE status='active' LOOP
  PERFORM ase_private.run_recurrences(org,(clock_timestamp() AT TIME ZONE 'Europe/Madrid')::date);
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION ase_private.schedule_recurrences() FROM PUBLIC,anon,authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
