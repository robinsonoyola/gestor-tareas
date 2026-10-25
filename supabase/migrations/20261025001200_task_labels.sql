-- ASE Work: flexible task labels for classification and search.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_task_labels(
 organization_id uuid NOT NULL,task_id uuid NOT NULL,label text NOT NULL,normalized text NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,task_id,normalized),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 CHECK(length(label)BETWEEN 1 AND 40),CHECK(length(normalized)BETWEEN 1 AND 40)
);
ALTER TABLE public.work_task_labels ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_labels FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_task_labels TO ase_tenant_executor;
DROP POLICY IF EXISTS task_labels_executor ON public.work_task_labels;
CREATE POLICY task_labels_executor ON public.work_task_labels TO ase_tenant_executor USING(organization_id=ase_private.current_org())WITH CHECK(organization_id=ase_private.current_org());

CREATE OR REPLACE FUNCTION public.work_manage_task_labeled(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false,p_estimated_minutes integer DEFAULT NULL,p_requires_review boolean DEFAULT false,p_area uuid DEFAULT NULL,p_labels text[] DEFAULT '{}'::text[]) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;org uuid:=ase_private.current_org();raw text;clean text;normal text;clean_labels text[]:='{}'::text[];normal_labels text[]:='{}'::text[];
BEGIN
 IF cardinality(coalesce(p_labels,'{}'::text[]))>10 THEN RAISE EXCEPTION 'Añade como máximo 10 etiquetas';END IF;
 FOREACH raw IN ARRAY coalesce(p_labels,'{}'::text[])LOOP
  clean:=regexp_replace(btrim(coalesce(raw,'')),'\s+',' ','g');normal:=lower(clean);
  IF length(clean)NOT BETWEEN 1 AND 40 THEN RAISE EXCEPTION 'Cada etiqueta debe tener entre 1 y 40 caracteres';END IF;
  IF normal=ANY(normal_labels)THEN RAISE EXCEPTION 'No repitas etiquetas';END IF;
  clean_labels:=array_append(clean_labels,clean);normal_labels:=array_append(normal_labels,normal);
 END LOOP;
 result:=public.work_manage_task_team(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers,p_require_comment,p_require_photo,p_require_video,p_require_file,p_estimated_minutes,p_requires_review,p_area);
 DELETE FROM public.work_task_labels l WHERE l.organization_id=org AND l.task_id=result AND NOT(l.normalized=ANY(normal_labels));
 INSERT INTO public.work_task_labels(organization_id,task_id,label,normalized)SELECT org,result,clean_labels[i],normal_labels[i]FROM generate_subscripts(clean_labels,1)i ON CONFLICT(organization_id,task_id,normalized)DO UPDATE SET label=excluded.label;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_task_catalog_labeled() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN
 SELECT coalesce(jsonb_agg(item||jsonb_build_object('labels',coalesce((SELECT jsonb_agg(l.label ORDER BY l.label,l.normalized)FROM public.work_task_labels l WHERE l.organization_id=ase_private.current_org()AND l.task_id=(item->>'id')::uuid),'[]'::jsonb))ORDER BY item->>'created_at'DESC,item->>'id'),'[]'::jsonb)INTO result FROM jsonb_array_elements(public.work_task_catalog_team())item;
 RETURN result;
END $$;

ALTER FUNCTION public.work_manage_task_labeled(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[]) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_catalog_labeled() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_labeled(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[]),public.work_task_catalog_labeled() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_labeled(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean,integer,boolean,uuid,text[]),public.work_task_catalog_labeled() TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

