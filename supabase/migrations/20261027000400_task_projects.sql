-- ASE Work: optional projects that group activities without changing execution.
BEGIN;

CREATE TABLE IF NOT EXISTS public.work_projects(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_id uuid NOT NULL DEFAULT ase_private.current_org() REFERENCES public.organizations(id),
 name text NOT NULL CHECK(length(trim(name)) BETWEEN 1 AND 150),
 description text CHECK(description IS NULL OR length(description)<=2000),
 status text NOT NULL DEFAULT 'active' CHECK(status IN ('planned','active','completed','archived')),
 start_date date,end_date date,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(organization_id,id),CHECK(end_date IS NULL OR start_date IS NULL OR end_date>=start_date)
);
CREATE UNIQUE INDEX IF NOT EXISTS work_projects_name_unique ON public.work_projects(organization_id,lower(name));

CREATE TABLE IF NOT EXISTS public.work_project_tasks(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),project_id uuid NOT NULL,task_id uuid NOT NULL,
 linked_at timestamptz NOT NULL DEFAULT clock_timestamp(),linked_by uuid NOT NULL DEFAULT ase_private.session_user_id(),
 PRIMARY KEY(organization_id,task_id),
 FOREIGN KEY(organization_id,project_id) REFERENCES public.work_projects(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,linked_by) REFERENCES public.organization_memberships(organization_id,user_id)
);

ALTER TABLE public.work_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_project_tasks ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_projects,public.work_project_tasks FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_projects,public.work_project_tasks TO ase_tenant_executor;

CREATE POLICY work_projects_boundary ON public.work_projects AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY work_projects_executor ON public.work_projects TO ase_tenant_executor USING(true) WITH CHECK(true);
CREATE POLICY work_project_tasks_boundary ON public.work_project_tasks AS RESTRICTIVE TO PUBLIC
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
CREATE POLICY work_project_tasks_executor ON public.work_project_tasks TO ase_tenant_executor USING(true) WITH CHECK(true);

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_projects_overview()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 SELECT jsonb_build_object(
  'projects',coalesce((SELECT jsonb_agg(to_jsonb(p)||jsonb_build_object(
   'task_ids',coalesce((SELECT jsonb_agg(x.task_id ORDER BY x.linked_at,x.task_id) FROM public.work_project_tasks x WHERE x.project_id=p.id),'[]'::jsonb)
  ) ORDER BY CASE p.status WHEN 'active' THEN 1 WHEN 'planned' THEN 2 WHEN 'completed' THEN 3 ELSE 4 END,p.name,p.id) FROM public.work_projects p),'[]'::jsonb)
 ) INTO result;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_save_project(p_id uuid,p_name text,p_description text,p_status text,p_start date,p_end date)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE result uuid;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 150 OR length(coalesce(p_description,''))>2000
  OR p_status NOT IN ('planned','active','completed','archived') OR (p_start IS NOT NULL AND p_end IS NOT NULL AND p_end<p_start) THEN
  RAISE EXCEPTION 'Revisa los datos del proyecto';
 END IF;
 IF p_id IS NULL THEN
  INSERT INTO public.work_projects(name,description,status,start_date,end_date)
  VALUES(trim(p_name),nullif(trim(coalesce(p_description,'')),''),p_status,p_start,p_end) RETURNING id INTO result;
 ELSE
  UPDATE public.work_projects SET name=trim(p_name),description=nullif(trim(coalesce(p_description,'')),''),status=p_status,start_date=p_start,end_date=p_end,updated_at=clock_timestamp()
  WHERE id=p_id RETURNING id INTO result;
  IF result IS NULL THEN RAISE EXCEPTION 'Proyecto no disponible'; END IF;
 END IF;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_set_task_project(p_task uuid,p_project uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE id=p_task) THEN RAISE EXCEPTION 'Actividad no disponible'; END IF;
 IF p_project IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_projects WHERE id=p_project AND status<>'archived') THEN RAISE EXCEPTION 'Proyecto no disponible'; END IF;
 DELETE FROM public.work_project_tasks WHERE task_id=p_task;
 IF p_project IS NOT NULL THEN INSERT INTO public.work_project_tasks(project_id,task_id) VALUES(p_project,p_task); END IF;
END $function$;

ALTER FUNCTION public.work_projects_overview() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_project(uuid,text,text,text,date,date) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_set_task_project(uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_projects_overview(),public.work_save_project(uuid,text,text,text,date,date),public.work_set_task_project(uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_projects_overview(),public.work_save_project(uuid,text,text,text,date,date),public.work_set_task_project(uuid,uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
