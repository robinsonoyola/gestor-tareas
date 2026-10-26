-- ASE Work: shared reusable task template library.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_task_templates(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 id uuid NOT NULL DEFAULT gen_random_uuid(),
 source_task_id uuid NOT NULL,
 name text NOT NULL,
 description text,
 created_by uuid NOT NULL DEFAULT ase_private.session_user_id(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id),
 FOREIGN KEY(organization_id,source_task_id)REFERENCES public.tasks(organization_id,id)ON DELETE CASCADE,
 CHECK(length(btrim(name))BETWEEN 1 AND 120),
 CHECK(description IS NULL OR length(description)<=500)
);
CREATE UNIQUE INDEX IF NOT EXISTS work_task_templates_name_unique ON public.work_task_templates(organization_id,lower(btrim(name)));
ALTER TABLE public.work_task_templates ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.work_task_template_events(
 organization_id uuid NOT NULL,
 id bigint GENERATED ALWAYS AS IDENTITY,
 template_id uuid NOT NULL,
 actor_id uuid NOT NULL,
 action text NOT NULL CHECK(action IN('created','updated','used','deleted')),
 detail jsonb NOT NULL DEFAULT '{}'::jsonb,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id)
);
ALTER TABLE public.work_task_template_events ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.work_task_template_directory()RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',x.id,'name',x.name,'description',x.description,'source_task_id',x.source_task_id,'source_title',t.title,'importance',t.importance,'updated_at',x.updated_at)ORDER BY x.name,x.id)FROM public.work_task_templates x JOIN public.tasks t ON t.organization_id=x.organization_id AND t.id=x.source_task_id WHERE x.organization_id=ase_private.current_org()),'[]'::jsonb);
END $$;

CREATE OR REPLACE FUNCTION public.work_save_task_template(p_action text,p_id uuid DEFAULT NULL,p_task uuid DEFAULT NULL,p_name text DEFAULT NULL,p_description text DEFAULT NULL)RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();result uuid;old_row public.work_task_templates%ROWTYPE;
BEGIN
 PERFORM public.work_assert_permission(CASE WHEN p_action='delete' THEN 'tasks.edit' ELSE 'tasks.create' END);
 IF p_action IN('create','update')THEN
  IF p_task IS NULL OR NOT EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=org AND t.id=p_task)THEN RAISE EXCEPTION 'Selecciona una actividad disponible';END IF;
  IF length(btrim(coalesce(p_name,'')))NOT BETWEEN 1 AND 120 THEN RAISE EXCEPTION 'El nombre debe tener entre 1 y 120 caracteres';END IF;
  IF length(coalesce(p_description,''))>500 THEN RAISE EXCEPTION 'La descripción admite hasta 500 caracteres';END IF;
 END IF;
 IF p_action='create'THEN
  INSERT INTO public.work_task_templates(organization_id,source_task_id,name,description)VALUES(org,p_task,btrim(p_name),nullif(btrim(p_description),''))RETURNING id INTO result;
  INSERT INTO public.work_task_template_events(organization_id,template_id,actor_id,action,detail)VALUES(org,result,ase_private.session_user_id(),'created',jsonb_build_object('task_id',p_task,'name',btrim(p_name)));
 ELSIF p_action='update'THEN
  SELECT * INTO old_row FROM public.work_task_templates WHERE organization_id=org AND id=p_id FOR UPDATE;
  IF old_row.id IS NULL THEN RAISE EXCEPTION 'La plantilla ya no está disponible';END IF;
  UPDATE public.work_task_templates SET source_task_id=p_task,name=btrim(p_name),description=nullif(btrim(p_description),''),updated_at=clock_timestamp()WHERE organization_id=org AND id=p_id RETURNING id INTO result;
  INSERT INTO public.work_task_template_events(organization_id,template_id,actor_id,action,detail)VALUES(org,result,ase_private.session_user_id(),'updated',jsonb_build_object('before',jsonb_build_object('task_id',old_row.source_task_id,'name',old_row.name),'after',jsonb_build_object('task_id',p_task,'name',btrim(p_name))));
 ELSIF p_action='delete'THEN
  SELECT * INTO old_row FROM public.work_task_templates WHERE organization_id=org AND id=p_id FOR UPDATE;
  IF old_row.id IS NULL THEN RAISE EXCEPTION 'La plantilla ya no está disponible';END IF;
  INSERT INTO public.work_task_template_events(organization_id,template_id,actor_id,action,detail)VALUES(org,old_row.id,ase_private.session_user_id(),'deleted',jsonb_build_object('task_id',old_row.source_task_id,'name',old_row.name));
  DELETE FROM public.work_task_templates WHERE organization_id=org AND id=old_row.id;result:=old_row.id;
 ELSE RAISE EXCEPTION 'Acción no válida';END IF;
 RETURN result;
EXCEPTION WHEN unique_violation THEN RAISE EXCEPTION 'Ya existe una plantilla con ese nombre';
END $$;

CREATE OR REPLACE FUNCTION public.work_create_task_from_template(p_template uuid,p_title text DEFAULT NULL)RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item public.work_task_templates%ROWTYPE;result uuid;
BEGIN
 PERFORM public.work_assert_permission('tasks.create');
 SELECT * INTO item FROM public.work_task_templates WHERE organization_id=ase_private.current_org()AND id=p_template FOR SHARE;
 IF item.id IS NULL THEN RAISE EXCEPTION 'La plantilla ya no está disponible';END IF;
 result:=public.work_duplicate_task(item.source_task_id,coalesce(nullif(btrim(p_title),''),item.name));
 INSERT INTO public.work_task_template_events(organization_id,template_id,actor_id,action,detail)VALUES(item.organization_id,item.id,ase_private.session_user_id(),'used',jsonb_build_object('created_task_id',result,'title',coalesce(nullif(btrim(p_title),''),item.name)));
 RETURN result;
END $$;

ALTER FUNCTION public.work_task_template_directory() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_task_template(text,uuid,uuid,text,text) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_create_task_from_template(uuid,text) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON TABLE public.work_task_templates,public.work_task_template_events FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.work_task_template_directory(),public.work_save_task_template(text,uuid,uuid,text,text),public.work_create_task_from_template(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_template_directory(),public.work_save_task_template(text,uuid,uuid,text,text),public.work_create_task_from_template(uuid,text) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
