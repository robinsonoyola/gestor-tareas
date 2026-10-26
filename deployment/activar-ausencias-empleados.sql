-- ASE Work: employee absences and planning/check-in safeguards.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_employee_absences(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_id uuid NOT NULL,
 user_id uuid NOT NULL,
 kind text NOT NULL CHECK(kind IN('vacation','leave','sick','unavailable')),
 start_date date NOT NULL,
 end_date date NOT NULL,
 note text,
 created_by uuid NOT NULL DEFAULT auth.uid(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 cancelled_by uuid,
 cancelled_at timestamptz,
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id),
 CHECK(end_date>=start_date),
 CHECK(end_date-start_date<=366),
 CHECK(note IS NULL OR length(note)<=500)
);
CREATE INDEX IF NOT EXISTS work_employee_absences_period ON public.work_employee_absences(organization_id,user_id,start_date,end_date) WHERE cancelled_at IS NULL;
ALTER TABLE public.work_employee_absences ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_employee_absences FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE ON public.work_employee_absences TO ase_tenant_executor;
DROP POLICY IF EXISTS work_employee_absences_executor ON public.work_employee_absences;
CREATE POLICY work_employee_absences_executor ON public.work_employee_absences TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

CREATE OR REPLACE FUNCTION public.work_absence_directory(p_start date,p_end date) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_admin();
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>366 THEN RAISE EXCEPTION 'Selecciona un período de hasta 367 días';END IF;
 SELECT jsonb_build_object(
  'start',p_start,'end',p_end,
  'people',coalesce((SELECT jsonb_agg(jsonb_build_object('id',u.id,'full_name',u.full_name)ORDER BY u.full_name,u.id)FROM ase_private.employee_profiles u WHERE NOT u.is_admin AND u.membership_status='active'),'[]'::jsonb),
  'absences',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'user_id',a.user_id,'employee',u.full_name,'kind',a.kind,'start_date',a.start_date,'end_date',a.end_date,'note',a.note,'created_at',a.created_at,'cancelled_at',a.cancelled_at,'planned_days',(SELECT count(DISTINCT p.work_date)FROM public.work_day_plan p WHERE p.organization_id=a.organization_id AND p.user_id=a.user_id AND p.work_date BETWEEN a.start_date AND a.end_date AND p.state IN('pending','active','paused','blocked','review')))ORDER BY a.start_date,a.end_date,u.full_name,a.id)FROM public.work_employee_absences a JOIN ase_private.employee_profiles u ON u.id=a.user_id WHERE a.start_date<=p_end AND a.end_date>=p_start),'[]'::jsonb),
  'as_of',clock_timestamp()) INTO result;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_save_absence(p_id uuid,p_user uuid,p_kind text,p_start date,p_end date,p_note text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();result uuid:=coalesce(p_id,gen_random_uuid());clean_note text:=nullif(btrim(coalesce(p_note,'')),'');
BEGIN
 PERFORM public.work_assert_admin();
 IF p_kind IS NULL OR p_kind NOT IN('vacation','leave','sick','unavailable')THEN RAISE EXCEPTION 'Tipo de ausencia no válido';END IF;
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>366 THEN RAISE EXCEPTION 'Selecciona un período válido de hasta 367 días';END IF;
 IF clean_note IS NOT NULL AND length(clean_note)>500 THEN RAISE EXCEPTION 'El motivo admite hasta 500 caracteres';END IF;
 PERFORM 1 FROM ase_private.employee_profiles u WHERE u.id=p_user AND NOT u.is_admin AND u.membership_status='active';
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible';END IF;
 IF p_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_employee_absences a WHERE a.organization_id=org AND a.id=p_id AND a.cancelled_at IS NULL)THEN RAISE EXCEPTION 'Ausencia no disponible';END IF;
 IF EXISTS(SELECT 1 FROM public.work_employee_absences a WHERE a.organization_id=org AND a.user_id=p_user AND a.cancelled_at IS NULL AND a.id<>result AND daterange(a.start_date,a.end_date,'[]')&&daterange(p_start,p_end,'[]'))THEN RAISE EXCEPTION 'El empleado ya tiene una ausencia que coincide con esas fechas';END IF;
 INSERT INTO public.work_employee_absences(id,organization_id,user_id,kind,start_date,end_date,note)
 VALUES(result,org,p_user,p_kind,p_start,p_end,clean_note)
 ON CONFLICT(id)DO UPDATE SET user_id=excluded.user_id,kind=excluded.kind,start_date=excluded.start_date,end_date=excluded.end_date,note=excluded.note
 WHERE work_employee_absences.organization_id=org AND work_employee_absences.cancelled_at IS NULL;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_cancel_absence(p_id uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_admin();
 UPDATE public.work_employee_absences SET cancelled_at=clock_timestamp(),cancelled_by=auth.uid()
 WHERE organization_id=ase_private.current_org()AND id=p_id AND cancelled_at IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Ausencia no disponible';END IF;
END $$;

CREATE OR REPLACE FUNCTION public.work_absence_plan_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.state='pending' AND (TG_OP='INSERT' OR NEW.user_id IS DISTINCT FROM OLD.user_id OR NEW.work_date IS DISTINCT FROM OLD.work_date)
 AND EXISTS(SELECT 1 FROM public.work_employee_absences a WHERE a.organization_id=NEW.organization_id AND a.user_id=NEW.user_id AND a.cancelled_at IS NULL AND NEW.work_date BETWEEN a.start_date AND a.end_date)
 THEN RAISE EXCEPTION 'No se puede planificar: el empleado tiene una ausencia en esa fecha';END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_absence_checkin_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.checkout_time IS NULL AND (TG_OP='INSERT' OR OLD.checkout_time IS NOT NULL)
 AND EXISTS(SELECT 1 FROM public.work_employee_absences a WHERE a.organization_id=NEW.organization_id AND a.user_id=NEW.user_id AND a.cancelled_at IS NULL AND public.work_today()BETWEEN a.start_date AND a.end_date)
 THEN RAISE EXCEPTION 'No se puede iniciar el fichaje durante una ausencia registrada';END IF;
 RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS work_absence_plan_guard ON public.work_day_plan;
CREATE TRIGGER work_absence_plan_guard BEFORE INSERT OR UPDATE OF user_id,work_date,state ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION public.work_absence_plan_guard();
DROP TRIGGER IF EXISTS work_absence_checkin_guard ON public.checkins;
CREATE TRIGGER work_absence_checkin_guard BEFORE INSERT OR UPDATE OF checkout_time ON public.checkins FOR EACH ROW EXECUTE FUNCTION public.work_absence_checkin_guard();

ALTER FUNCTION public.work_absence_directory(date,date) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_absence(uuid,uuid,text,date,date,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_cancel_absence(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_absence_plan_guard() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_absence_checkin_guard() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_absence_directory(date,date),public.work_save_absence(uuid,uuid,text,date,date,text),public.work_cancel_absence(uuid),public.work_absence_plan_guard(),public.work_absence_checkin_guard() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_absence_directory(date,date),public.work_save_absence(uuid,uuid,text,date,date,text),public.work_cancel_absence(uuid) TO authenticated,ase_tenant_executor;
GRANT EXECUTE ON FUNCTION public.work_absence_plan_guard(),public.work_absence_checkin_guard() TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
