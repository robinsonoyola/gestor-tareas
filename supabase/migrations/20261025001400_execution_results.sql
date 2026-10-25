-- ASE Work: execution-specific result summary shared by mobile, NFC and station flows.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS result_summary text;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS result_updated_at timestamptz;
ALTER TABLE public.work_day_plan ADD COLUMN IF NOT EXISTS result_updated_by uuid;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='work_plan_result_length' AND conrelid='public.work_day_plan'::regclass)THEN ALTER TABLE public.work_day_plan ADD CONSTRAINT work_plan_result_length CHECK(result_summary IS NULL OR length(result_summary)BETWEEN 3 AND 4000);END IF;END $$;

CREATE OR REPLACE FUNCTION public.work_save_execution_result(p_plan uuid,p_result text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;actor uuid:=ase_private.session_user_id();clean text:=nullif(btrim(coalesce(p_result,'')),'');BEGIN
 IF actor IS NULL OR clean IS NULL OR length(clean)NOT BETWEEN 3 AND 4000 THEN RAISE EXCEPTION 'Escribe un resultado de 3 a 4000 caracteres';END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org()AND id=p_plan FOR UPDATE;
 IF p.id IS NULL OR NOT(actor=p.user_id OR EXISTS(SELECT 1 FROM ase_private.employee_profiles e WHERE e.id=actor AND e.is_admin IS TRUE))THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes registrar el resultado de esta ejecución';END IF;
 IF p.state NOT IN('active','paused','review','completed')THEN RAISE EXCEPTION 'El resultado solo se registra durante o después de la ejecución';END IF;
 UPDATE public.work_day_plan SET result_summary=clean,result_updated_at=clock_timestamp(),result_updated_by=actor WHERE id=p.id;
 RETURN jsonb_build_object('success',true,'plan_id',p.id,'result',clean);
END $$;

CREATE OR REPLACE FUNCTION public.work_station_save_result(p_station text,p_ticket uuid,p_result text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.work_stations%ROWTYPE;k public.work_station_tickets%ROWTYPE;p public.work_day_plan%ROWTYPE;clean text:=nullif(btrim(coalesce(p_result,'')),'');BEGIN
 PERFORM ase_private.bind_station(p_station);IF clean IS NULL OR length(clean)NOT BETWEEN 3 AND 4000 THEN RAISE EXCEPTION 'Escribe un resultado de 3 a 4000 caracteres';END IF;
 SELECT * INTO s FROM public.work_stations WHERE token_hash=public.work_hash(p_station)AND active FOR SHARE;IF s.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto no disponible';END IF;
 SELECT * INTO k FROM public.work_station_tickets WHERE id=p_ticket AND station_id=s.id AND expected_action='finish'AND result IS NULL AND expires_at>clock_timestamp()FOR UPDATE;IF k.id IS NULL THEN RAISE EXCEPTION 'Vuelve a identificarte antes de guardar el resultado';END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=s.organization_id AND id=k.plan_id AND user_id=k.user_id AND state='active'FOR UPDATE;IF p.id IS NULL THEN RAISE EXCEPTION 'La ejecución ya no está activa';END IF;
 UPDATE public.work_day_plan SET result_summary=clean,result_updated_at=clock_timestamp(),result_updated_by=k.user_id WHERE id=p.id;
 RETURN jsonb_build_object('success',true,'plan_id',p.id);
END $$;

CREATE OR REPLACE FUNCTION public.work_review_queue() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('planning.view');SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'task_id',p.task_id,'title',t.title,'employee_id',p.user_id,'employee',coalesce(u.full_name,'Empleado no disponible'),'work_date',p.work_date,'finished_at',p.finished_at,'importance',t.importance,'estimated_minutes',t.estimated_minutes,'result_summary',p.result_summary)ORDER BY p.finished_at,p.work_date,p.priority),'[]'::jsonb)INTO result FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.organization_id=ase_private.current_org()AND p.state='review';RETURN result;END $$;

ALTER FUNCTION public.work_save_execution_result(uuid,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_station_save_result(text,uuid,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_review_queue() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_save_execution_result(uuid,text),public.work_station_save_result(text,uuid,text),public.work_review_queue() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_save_execution_result(uuid,text),public.work_review_queue() TO authenticated,ase_tenant_executor;
GRANT EXECUTE ON FUNCTION public.work_station_save_result(text,uuid,text) TO anon,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

