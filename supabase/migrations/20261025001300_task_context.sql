-- ASE Work: operational location and generic ERP origin for tasks.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS source_module text;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS related_entity_type text;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS related_entity_reference text;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS related_entity_label text;

DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='tasks_source_module_length' AND conrelid='public.tasks'::regclass)THEN ALTER TABLE public.tasks ADD CONSTRAINT tasks_source_module_length CHECK(source_module IS NULL OR length(source_module)BETWEEN 1 AND 60);END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='tasks_related_type_length' AND conrelid='public.tasks'::regclass)THEN ALTER TABLE public.tasks ADD CONSTRAINT tasks_related_type_length CHECK(related_entity_type IS NULL OR length(related_entity_type)BETWEEN 1 AND 60);END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='tasks_related_reference_length' AND conrelid='public.tasks'::regclass)THEN ALTER TABLE public.tasks ADD CONSTRAINT tasks_related_reference_length CHECK(related_entity_reference IS NULL OR length(related_entity_reference)BETWEEN 1 AND 120);END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='tasks_related_label_length' AND conrelid='public.tasks'::regclass)THEN ALTER TABLE public.tasks ADD CONSTRAINT tasks_related_label_length CHECK(related_entity_label IS NULL OR length(related_entity_label)BETWEEN 1 AND 160);END IF;
END $$;

CREATE OR REPLACE FUNCTION public.work_manage_task_context(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL,p_requires_review boolean DEFAULT false,p_area uuid DEFAULT NULL,p_labels text[] DEFAULT '{}'::text[],p_location text DEFAULT NULL,p_source_module text DEFAULT NULL,p_entity_type text DEFAULT NULL,p_entity_reference text DEFAULT NULL,p_entity_label text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;clean_location text:=nullif(btrim(coalesce(p_location,'')),'');clean_source text:=nullif(btrim(coalesce(p_source_module,'')),'');clean_type text:=nullif(btrim(coalesce(p_entity_type,'')),'');clean_reference text:=nullif(btrim(coalesce(p_entity_reference,'')),'');clean_label text:=nullif(btrim(coalesce(p_entity_label,'')),'');
BEGIN
 IF length(coalesce(clean_location,''))>200 THEN RAISE EXCEPTION 'La ubicación no puede superar 200 caracteres';END IF;
 IF length(coalesce(clean_source,''))>60 OR length(coalesce(clean_type,''))>60 OR length(coalesce(clean_reference,''))>120 OR length(coalesce(clean_label,''))>160 THEN RAISE EXCEPTION 'El contexto relacionado es demasiado largo';END IF;
 IF (clean_type IS NULL)<>(clean_reference IS NULL)THEN RAISE EXCEPTION 'Indica el tipo y la referencia de la entidad relacionada';END IF;
 result:=public.work_manage_task_labeled(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file,p_estimated_minutes,p_requires_review,p_area,p_labels);
 UPDATE public.tasks SET location=clean_location,source_module=clean_source,related_entity_type=clean_type,related_entity_reference=clean_reference,related_entity_label=clean_label WHERE organization_id=ase_private.current_org()AND id=result;
 RETURN result;
END $$;

ALTER FUNCTION public.work_manage_task_context(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_context(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_context(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[],text,text,text,text,text) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

