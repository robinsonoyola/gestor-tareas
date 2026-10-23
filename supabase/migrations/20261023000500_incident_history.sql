BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE TABLE public.work_incident_history(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_id uuid NOT NULL,
 incident_id uuid NOT NULL,
 actor_id uuid,
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 kind text NOT NULL CHECK(kind IN ('created','updated','snapshot')),
 previous_state text,
 state text NOT NULL,
 note text NOT NULL DEFAULT '',
 FOREIGN KEY(organization_id,incident_id) REFERENCES public.work_incidents(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
CREATE INDEX incident_history_timeline ON public.work_incident_history(organization_id,incident_id,recorded_at,id);
ALTER TABLE public.work_incident_history ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_incident_history FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_incident_history TO ase_tenant_executor;
CREATE POLICY incident_history_boundary ON public.work_incident_history AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY incident_history_executor ON public.work_incident_history TO ase_tenant_executor USING(true) WITH CHECK(true);
-- Keep only the known current state of existing records, without inventing earlier transitions.
INSERT INTO public.work_incident_history(organization_id,incident_id,kind,state,note)
 SELECT organization_id,id,'snapshot',state,coalesce(resolution,'') FROM public.work_incidents;
CREATE FUNCTION public.work_record_incident_history() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF TG_OP='INSERT' THEN
  INSERT INTO public.work_incident_history(organization_id,incident_id,actor_id,kind,state,note)
  VALUES(NEW.organization_id,NEW.id,ase_private.session_user_id(),'created',NEW.state,coalesce(NEW.resolution,''));
 ELSIF NEW.state IS DISTINCT FROM OLD.state OR NEW.resolution IS DISTINCT FROM OLD.resolution
 OR NEW.assigned_user IS DISTINCT FROM OLD.assigned_user OR NEW.area_id IS DISTINCT FROM OLD.area_id THEN
  INSERT INTO public.work_incident_history(organization_id,incident_id,actor_id,kind,previous_state,state,note)
  VALUES(NEW.organization_id,NEW.id,ase_private.session_user_id(),'updated',OLD.state,NEW.state,coalesce(NEW.resolution,''));
 END IF;
 RETURN NEW;
END $$;
ALTER FUNCTION public.work_record_incident_history() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_record_incident_history() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER work_incident_timeline AFTER INSERT OR UPDATE ON public.work_incidents
 FOR EACH ROW EXECUTE FUNCTION public.work_record_incident_history();
CREATE FUNCTION public.work_incident_history(p_incident uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE allowed boolean;events jsonb;
BEGIN
 SELECT true INTO allowed FROM public.work_incidents i
 WHERE i.organization_id=ase_private.current_org() AND i.id=p_incident
 AND (public.sec06_is_admin() OR i.reporter_id=ase_private.session_user_id() OR i.assigned_user=ase_private.session_user_id()
 OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id AND m.user_id=ase_private.session_user_id()));
 IF ase_private.session_user_id() IS NULL OR allowed IS DISTINCT FROM true THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Incidencia no disponible';
 END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',h.id,'at',h.recorded_at,'kind',h.kind,
 'previous_state',h.previous_state,'state',h.state,'note',h.note,'actor',u.full_name) ORDER BY h.recorded_at,h.id),'[]'::jsonb)
 INTO events FROM public.work_incident_history h LEFT JOIN ase_private.employee_profiles u ON u.id=h.actor_id
 WHERE h.organization_id=ase_private.current_org() AND h.incident_id=p_incident;
 RETURN events;
END $$;
ALTER FUNCTION public.work_incident_history(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_incident_history(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_incident_history(uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
