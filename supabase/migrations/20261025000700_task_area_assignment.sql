-- ASE Work: assign a task to an area before choosing its responsible person.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_task_areas(
 organization_id uuid NOT NULL,task_id uuid NOT NULL,area_id uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,task_id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,area_id) REFERENCES public.work_areas(organization_id,id)
);
ALTER TABLE public.work_task_areas ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_areas FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_task_areas TO ase_tenant_executor;
DROP POLICY IF EXISTS task_areas_executor ON public.work_task_areas;
CREATE POLICY task_areas_executor ON public.work_task_areas TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

CREATE OR REPLACE FUNCTION public.work_manage_task_team(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL,p_requires_review boolean DEFAULT false,p_area uuid DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;org uuid:=ase_private.current_org();executors uuid[]:=CASE WHEN p_primary IS NULL THEN coalesce(p_collaborators,'{}'::uuid[]) ELSE ARRAY[p_primary]||coalesce(p_collaborators,'{}'::uuid[]) END;
BEGIN
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas WHERE organization_id=org AND id=p_area AND active) THEN RAISE EXCEPTION 'Selecciona un área activa'; END IF;
 IF p_area IS NOT NULL AND EXISTS(SELECT 1 FROM unnest(executors)u(id) WHERE NOT EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=org AND m.area_id=p_area AND m.user_id=u.id)) THEN RAISE EXCEPTION 'Responsable y colaboradores deben pertenecer al área seleccionada'; END IF;
 result:=public.work_manage_task_review(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file,p_estimated_minutes,p_requires_review);
 IF p_area IS NULL THEN DELETE FROM public.work_task_areas WHERE organization_id=org AND task_id=result;
 ELSE INSERT INTO public.work_task_areas(organization_id,task_id,area_id)VALUES(org,result,p_area)ON CONFLICT(organization_id,task_id)DO UPDATE SET area_id=excluded.area_id;END IF;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_task_catalog_team() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('tasks.view');
 SELECT coalesce(jsonb_agg(item||jsonb_build_object('area',coalesce((SELECT jsonb_build_object('id',a.id,'name',a.name)FROM public.work_task_areas x JOIN public.work_areas a ON a.organization_id=x.organization_id AND a.id=x.area_id WHERE x.organization_id=ase_private.current_org()AND x.task_id=(item->>'id')::uuid),'null'::jsonb)) ORDER BY item->>'created_at' DESC,item->>'id'),'[]'::jsonb)INTO result FROM jsonb_array_elements(public.work_task_catalog())item;
 RETURN result;
END $$;

ALTER FUNCTION public.work_manage_task_team(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_catalog_team() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_team(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid),public.work_task_catalog_team() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_team(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid),public.work_task_catalog_team() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

