-- ASE Work: configurable required execution result across all completion channels.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS require_result boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.work_manage_task_outcome(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL,p_requires_review boolean DEFAULT false,p_area uuid DEFAULT NULL,p_labels text[] DEFAULT '{}'::text[],p_location text DEFAULT NULL,p_source_module text DEFAULT NULL,p_entity_type text DEFAULT NULL,p_entity_reference text DEFAULT NULL,p_entity_label text DEFAULT NULL,p_require_result boolean DEFAULT false) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;BEGIN
 result:=public.work_manage_task_context(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file,p_estimated_minutes,p_requires_review,p_area,p_labels,p_location,p_source_module,p_entity_type,p_entity_reference,p_entity_label);
 UPDATE public.tasks SET require_result=coalesce(p_require_result,false)WHERE organization_id=ase_private.current_org()AND id=result;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_guard_required_result() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.state IN('completed','review')AND OLD.state IS DISTINCT FROM NEW.state AND EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=NEW.organization_id AND t.id=NEW.task_id AND t.require_result)AND nullif(btrim(coalesce(NEW.result_summary,'')),'')IS NULL THEN RAISE EXCEPTION 'Escribe el resultado del trabajo antes de finalizar';END IF;
 RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS work_guard_required_result ON public.work_day_plan;
CREATE TRIGGER work_guard_required_result BEFORE UPDATE OF state ON public.work_day_plan FOR EACH ROW EXECUTE FUNCTION public.work_guard_required_result();

CREATE OR REPLACE FUNCTION public.work_station_identify_result(p_station text,p_card text DEFAULT NULL,p_method text DEFAULT 'manual',p_user uuid DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;ticket uuid;required boolean:=false;BEGIN
 result:=public.work_station_identify_v2(p_station,p_card,p_method,p_user);ticket:=(result->>'ticket')::uuid;
 IF ticket IS NOT NULL THEN SELECT t.require_result INTO required FROM public.work_station_tickets k JOIN public.work_day_plan p ON p.id=k.plan_id JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE k.id=ticket;END IF;
 RETURN result||jsonb_build_object('require_result',coalesce(required,false));
END $$;

ALTER FUNCTION public.work_manage_task_outcome(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_guard_required_result() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_station_identify_result(text,text,text,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_outcome(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text,boolean),public.work_guard_required_result(),public.work_station_identify_result(text,text,text,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_outcome(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text,boolean),public.work_guard_required_result() TO authenticated,ase_tenant_executor;
GRANT EXECUTE ON FUNCTION public.work_station_identify_result(text,text,text,uuid) TO anon,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

