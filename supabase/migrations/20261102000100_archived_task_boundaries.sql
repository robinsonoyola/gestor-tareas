-- ASE Work: archived activities remain historical and cannot receive new operational links.
BEGIN;
GRANT CREATE ON SCHEMA ase_private TO ase_tenant_executor;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION ase_private.guard_archived_task_reference() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE field_name text;task_value uuid;task_archived timestamptz;
BEGIN
 FOREACH field_name IN ARRAY TG_ARGV LOOP
  task_value:=nullif(to_jsonb(NEW)->>field_name,'')::uuid;
  IF task_value IS NULL THEN CONTINUE;END IF;
  SELECT archived_at INTO task_archived FROM public.tasks
   WHERE organization_id=NEW.organization_id AND id=task_value;
  IF NOT FOUND THEN RAISE EXCEPTION 'La actividad ya no está disponible';END IF;
  IF task_archived IS NOT NULL THEN
   RAISE EXCEPTION 'La actividad está archivada. Restáurala antes de volver a utilizarla';
  END IF;
 END LOOP;
 RETURN NEW;
END $function$;

DO $block$
DECLARE item record;trigger_name text;columns_sql text;
BEGIN
 FOR item IN SELECT * FROM(VALUES
  ('task_assignments',ARRAY['task_id']::text[]),
  ('task_access_codes',ARRAY['task_id']::text[]),
  ('nfc_cards',ARRAY['task_id']::text[]),
  ('work_day_plan',ARRAY['task_id']::text[]),
  ('work_recurrences',ARRAY['task_id']::text[]),
  ('work_project_tasks',ARRAY['task_id']::text[]),
  ('work_checklist_templates',ARRAY['task_id']::text[]),
  ('work_task_areas',ARRAY['task_id']::text[]),
  ('work_task_labels',ARRAY['task_id']::text[]),
  ('work_task_followers',ARRAY['task_id']::text[]),
  ('work_task_templates',ARRAY['source_task_id']::text[]),
  ('work_task_subtasks',ARRAY['parent_task_id','child_task_id']::text[]),
  ('work_task_dependencies',ARRAY['task_id','prerequisite_task_id']::text[])
 )v(table_name,field_names)
 LOOP
  IF to_regclass('public.'||item.table_name)IS NULL THEN CONTINUE;END IF;
  trigger_name:='work_guard_archived_reference_'||item.table_name;
  columns_sql:=array_to_string(ARRAY(SELECT format('%I',x)FROM unnest(item.field_names)x),',');
  EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I',trigger_name,item.table_name);
  EXECUTE format('CREATE TRIGGER %I BEFORE INSERT OR UPDATE OF %s ON public.%I FOR EACH ROW EXECUTE FUNCTION ase_private.guard_archived_task_reference(%s)',
   trigger_name,columns_sql,item.table_name,array_to_string(ARRAY(SELECT quote_literal(x)FROM unnest(item.field_names)x),','));
 END LOOP;
END $block$;

ALTER FUNCTION ase_private.guard_archived_task_reference() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.guard_archived_task_reference() FROM PUBLIC,anon,authenticated,ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_duplicate_task(p_task uuid,p_title text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE source public.tasks%ROWTYPE;result uuid;primary_user uuid;collaborators uuid[];followers uuid[];area uuid;labels text[];steps jsonb;new_title text;
BEGIN
 PERFORM public.work_assert_permission('tasks.create');
 SELECT * INTO source FROM public.tasks WHERE organization_id=ase_private.current_org()AND id=p_task AND archived_at IS NULL FOR SHARE;
 IF source.id IS NULL THEN RAISE EXCEPTION 'La actividad no está disponible o se encuentra archivada';END IF;
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
END $function$;

CREATE OR REPLACE FUNCTION public.work_task_template_directory()RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $function$
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',x.id,'name',x.name,'description',x.description,'source_task_id',x.source_task_id,'source_title',t.title,'source_archived',t.archived_at IS NOT NULL,'importance',t.importance,'updated_at',x.updated_at)ORDER BY x.name,x.id)FROM public.work_task_templates x JOIN public.tasks t ON t.organization_id=x.organization_id AND t.id=x.source_task_id WHERE x.organization_id=ase_private.current_org()),'[]'::jsonb);
END $function$;

ALTER FUNCTION public.work_duplicate_task(uuid,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_template_directory() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_duplicate_task(uuid,text),public.work_task_template_directory() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_duplicate_task(uuid,text),public.work_task_template_directory() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE CREATE ON SCHEMA ase_private FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
