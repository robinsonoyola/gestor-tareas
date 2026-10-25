BEGIN;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS estimated_minutes integer;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='tasks_estimated_minutes_range' AND conrelid='public.tasks'::regclass) THEN ALTER TABLE public.tasks ADD CONSTRAINT tasks_estimated_minutes_range CHECK(estimated_minutes IS NULL OR estimated_minutes BETWEEN 1 AND 10080);END IF;END $$;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_manage_task_operational(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;BEGIN
 IF p_estimated_minutes IS NOT NULL AND p_estimated_minutes NOT BETWEEN 1 AND 10080 THEN RAISE EXCEPTION 'El tiempo estimado debe estar entre 1 minuto y 7 días';END IF;
 result:=public.work_manage_task_roles_evidence(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file);
 UPDATE public.tasks SET estimated_minutes=p_estimated_minutes WHERE organization_id=ase_private.current_org() AND id=result;
 RETURN result;
END $$;
CREATE OR REPLACE FUNCTION public.work_task_options() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN
 IF NOT(public.work_has_permission('tasks.view')OR public.work_has_permission('reports.view')OR public.work_has_permission('checkins.view'))THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso a las actividades';END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'title',title,'estimated_minutes',estimated_minutes)ORDER BY title,id),'[]'::jsonb)INTO result FROM public.tasks WHERE organization_id=ase_private.current_org();RETURN result;
END $$;
ALTER FUNCTION public.work_manage_task_operational(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_options() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_operational(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer),public.work_task_options() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_operational(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer),public.work_task_options() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
