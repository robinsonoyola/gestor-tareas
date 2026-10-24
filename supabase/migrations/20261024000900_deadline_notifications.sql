-- ASE Work: one reminder in the last 24 hours and one overdue notification.
BEGIN;

CREATE OR REPLACE FUNCTION ase_private.run_deadline_notifications(p_org uuid,p_now timestamptz) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE changed integer:=0; inserted integer;
BEGIN
 IF p_org IS NULL OR p_now IS NULL THEN RAISE EXCEPTION 'Contexto de avisos no válido'; END IF;
 WITH candidates AS (
  SELECT p.id,p.user_id,t.title,coalesce(p.due_at,p.planned_end) deadline
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  WHERE p.organization_id=p_org AND p.state IN('pending','active') AND coalesce(p.due_at,p.planned_end)>p_now AND coalesce(p.due_at,p.planned_end)<=p_now+interval '24 hours'
 )
 INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)
 SELECT p_org,user_id,NULL,'Próxima fecha límite: '||title||' · '||to_char(deadline AT TIME ZONE 'Europe/Madrid','DD/MM/YYYY HH24:MI'),'deadline_soon','deadline-soon:'||id::text||':'||extract(epoch FROM deadline)::bigint::text FROM candidates
 ON CONFLICT(organization_id,user_id,event_key) WHERE event_key IS NOT NULL DO NOTHING;
 GET DIAGNOSTICS inserted=ROW_COUNT; changed:=changed+inserted;
 WITH candidates AS (
  SELECT p.id,p.user_id,t.title,coalesce(p.due_at,p.planned_end) deadline
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  WHERE p.organization_id=p_org AND p.state IN('pending','active') AND coalesce(p.due_at,p.planned_end)<=p_now
 )
 INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)
 SELECT p_org,user_id,NULL,'Tarea vencida: '||title||' · límite '||to_char(deadline AT TIME ZONE 'Europe/Madrid','DD/MM/YYYY HH24:MI'),'overdue','deadline-overdue:'||id::text||':'||extract(epoch FROM deadline)::bigint::text FROM candidates
 ON CONFLICT(organization_id,user_id,event_key) WHERE event_key IS NOT NULL DO NOTHING;
 GET DIAGNOSTICS inserted=ROW_COUNT; changed:=changed+inserted;
 RETURN changed;
END $$;

CREATE OR REPLACE FUNCTION ase_private.schedule_deadline_notifications() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid; moment timestamptz:=clock_timestamp();
BEGIN
 FOR org IN SELECT id FROM public.organizations WHERE status='active' LOOP
  PERFORM ase_private.run_deadline_notifications(org,moment);
 END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.work_run_deadline_notifications() RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 RETURN ase_private.run_deadline_notifications(ase_private.current_org(),clock_timestamp());
END $$;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
ALTER FUNCTION public.work_run_deadline_notifications() OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.run_deadline_notifications(uuid,timestamptz),ase_private.schedule_deadline_notifications() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.run_deadline_notifications(uuid,timestamptz) TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_run_deadline_notifications() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_run_deadline_notifications() TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
