-- ASE Work: safely edit future recurrence settings while preserving generated work.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_recurrence_events(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 recurrence_id uuid NOT NULL,actor_id uuid NOT NULL,previous_value jsonb NOT NULL,current_value jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 FOREIGN KEY(organization_id,recurrence_id) REFERENCES public.work_recurrences(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
ALTER TABLE public.work_recurrence_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_recurrence_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_recurrence_events TO ase_tenant_executor;
DROP POLICY IF EXISTS recurrence_events_scope ON public.work_recurrence_events;
CREATE POLICY recurrence_events_scope ON public.work_recurrence_events TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

CREATE OR REPLACE FUNCTION public.work_update_recurrence(p_id uuid,p_start date,p_frequency text,p_every integer,p_basis text,p_notice integer) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.work_recurrences%ROWTYPE;before_value jsonb;after_value jsonb;new_next date;
BEGIN
 PERFORM public.work_assert_permission('planning.edit');
 IF p_id IS NULL OR p_start IS NULL OR p_start<public.work_today() OR p_start>public.work_today()+3650
  OR p_frequency NOT IN('daily','weekly','monthly','yearly') OR p_every NOT BETWEEN 1 AND 365
  OR p_basis NOT IN('fixed','completion') OR p_notice NOT BETWEEN 0 AND 365 THEN
  RAISE EXCEPTION 'Revisa la próxima fecha, frecuencia y aviso';
 END IF;
 SELECT * INTO r FROM public.work_recurrences WHERE organization_id=ase_private.current_org() AND id=p_id FOR UPDATE;
 IF r.id IS NULL THEN RAISE EXCEPTION 'Repetición no disponible';END IF;
 before_value:=jsonb_build_object('start',r.anchor,'frequency',r.frequency,'every',r.every_n,'basis',r.basis,'notice',r.notice_days,'next_due',r.next_due);
 new_next:=p_start;
 IF p_basis='completion' AND EXISTS(
  SELECT 1 FROM public.work_recurrence_runs x JOIN public.work_day_plan p ON p.organization_id=x.organization_id AND p.id=x.plan_id
  WHERE x.organization_id=r.organization_id AND x.recurrence_id=r.id AND p.state<>'completed'
 ) THEN new_next:=NULL;END IF;
 UPDATE public.work_recurrences SET anchor=p_start,next_due=new_next,frequency=p_frequency,every_n=p_every,basis=p_basis,
  notice_days=p_notice,cursor_n=0,last_error=NULL WHERE organization_id=r.organization_id AND id=r.id;
 after_value:=jsonb_build_object('start',p_start,'frequency',p_frequency,'every',p_every,'basis',p_basis,'notice',p_notice,'next_due',new_next);
 IF before_value IS DISTINCT FROM after_value THEN
  INSERT INTO public.work_recurrence_events(organization_id,recurrence_id,actor_id,previous_value,current_value)
  VALUES(r.organization_id,r.id,ase_private.session_user_id(),before_value,after_value);
 END IF;
 IF r.active THEN PERFORM ase_private.run_recurrences(r.organization_id,public.work_today());END IF;
END $$;

ALTER FUNCTION public.work_update_recurrence(uuid,date,text,integer,text,integer) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_update_recurrence(uuid,date,text,integer,text,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_update_recurrence(uuid,date,text,integer,text,integer) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
