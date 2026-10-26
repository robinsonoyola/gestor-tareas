-- ASE Work: read-only personal absence calendar.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_my_absences(p_start date DEFAULT NULL,p_end date DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE from_day date:=coalesce(p_start,public.work_today()-365);to_day date:=coalesce(p_end,public.work_today()+365);result jsonb;
BEGIN
 IF auth.uid() IS NULL OR ase_private.current_org() IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Sesión no disponible';END IF;
 IF to_day<from_day OR to_day-from_day>1095 THEN RAISE EXCEPTION 'Selecciona un período de hasta tres años';END IF;
 SELECT jsonb_build_object('today',public.work_today(),'start',from_day,'end',to_day,'items',coalesce(jsonb_agg(jsonb_build_object('id',a.id,'kind',a.kind,'start_date',a.start_date,'end_date',a.end_date,'note',a.note,'cancelled_at',a.cancelled_at)ORDER BY a.start_date DESC,a.end_date DESC,a.id),'[]'::jsonb),'as_of',clock_timestamp())INTO result
 FROM public.work_employee_absences a WHERE a.organization_id=ase_private.current_org()AND a.user_id=auth.uid()AND a.start_date<=to_day AND a.end_date>=from_day;
 RETURN result;
END $$;

ALTER FUNCTION public.work_my_absences(date,date) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_my_absences(date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_my_absences(date,date) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
