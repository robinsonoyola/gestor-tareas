-- ASE Work: create a clean task from an existing activity configuration.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_duplicate_task(p_task uuid,p_title text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE source public.tasks%ROWTYPE;result uuid;primary_user uuid;collaborators uuid[];followers uuid[];area uuid;labels text[];steps jsonb;new_title text;
BEGIN
 PERFORM public.work_assert_permission('tasks.create');
 SELECT * INTO source FROM public.tasks WHERE organization_id=ase_private.current_org()AND id=p_task FOR SHARE;
 IF source.id IS NULL THEN RAISE EXCEPTION 'La actividad ya no está disponible';END IF;
 new_title:=btrim(coalesce(nullif(p_title,''),source.title||' (copia)'));
 IF length(new_title)NOT BETWEEN 1 AND 200 THEN RAISE EXCEPTION 'El título debe tener entre 1 y 200 caracteres';END IF;
 SELECT user_id INTO primary_user FROM public.task_assignments WHERE organization_id=source.organization_id AND task_id=source.id AND responsibility_role='primary'ORDER BY user_id LIMIT 1;
 SELECT coalesce(array_agg(user_id ORDER BY user_id),'{}'::uuid[])INTO collaborators FROM public.task_assignments WHERE organization_id=source.organization_id AND task_id=source.id AND responsibility_role<>'primary';
 SELECT coalesce(array_agg(user_id ORDER BY user_id),'{}'::uuid[])INTO followers FROM public.work_task_followers WHERE organization_id=source.organization_id AND task_id=source.id;
 SELECT area_id INTO area FROM public.work_task_areas WHERE organization_id=source.organization_id AND task_id=source.id;
 SELECT coalesce(array_agg(label ORDER BY normalized),'{}'::text[])INTO labels FROM public.work_task_labels WHERE organization_id=source.organization_id AND task_id=source.id;
 result:=public.work_manage_task_outcome('create',source.importance,NULL,new_title,source.description,source.schedule_type,source.schedule_date,'pending',primary_user,collaborators,followers,source.require_comment,source.require_photo,source.require_video,source.require_file,source.estimated_minutes,source.requires_review,area,labels,source.location,source.source_module,source.related_entity_type,source.related_entity_reference,source.related_entity_label,source.require_result);
 SELECT c.steps INTO steps FROM public.work_checklist_templates c WHERE c.organization_id=source.organization_id AND c.task_id=source.id;
 IF steps IS NOT NULL THEN INSERT INTO public.work_checklist_templates(organization_id,task_id,steps)VALUES(source.organization_id,result,steps);END IF;
 RETURN result;
END $$;

ALTER FUNCTION public.work_duplicate_task(uuid,text) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_duplicate_task(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_duplicate_task(uuid,text) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

