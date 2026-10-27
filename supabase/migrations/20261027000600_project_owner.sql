-- ASE Work: optional project owner, independent from task executors.
BEGIN;

ALTER TABLE public.work_projects ADD COLUMN IF NOT EXISTS owner_user_id uuid;
DO $constraint$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.work_projects'::regclass AND conname='work_projects_owner_membership_fk') THEN
  ALTER TABLE public.work_projects ADD CONSTRAINT work_projects_owner_membership_fk
   FOREIGN KEY(organization_id,owner_user_id) REFERENCES public.organization_memberships(organization_id,user_id);
 END IF;
END $constraint$;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_projects_overview()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 SELECT jsonb_build_object(
  'projects',coalesce((SELECT jsonb_agg(to_jsonb(p)||jsonb_build_object(
   'owner_name',(SELECT m.full_name FROM public.organization_memberships m WHERE m.organization_id=p.organization_id AND m.user_id=p.owner_user_id),
   'task_ids',coalesce((SELECT jsonb_agg(x.task_id ORDER BY x.linked_at,x.task_id) FROM public.work_project_tasks x WHERE x.project_id=p.id),'[]'::jsonb),
   'milestones',coalesce((SELECT jsonb_agg(to_jsonb(m) ORDER BY m.completed_at IS NOT NULL,m.due_date NULLS LAST,m.created_at,m.id) FROM public.work_project_milestones m WHERE m.project_id=p.id),'[]'::jsonb)
  ) ORDER BY CASE p.status WHEN 'active' THEN 1 WHEN 'planned' THEN 2 WHEN 'completed' THEN 3 ELSE 4 END,p.name,p.id) FROM public.work_projects p),'[]'::jsonb)
 ) INTO result;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_save_project_v2(p_id uuid,p_name text,p_description text,p_status text,p_start date,p_end date,p_owner uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE result uuid;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 150 OR length(coalesce(p_description,''))>2000
  OR p_status NOT IN ('planned','active','completed','archived') OR (p_start IS NOT NULL AND p_end IS NOT NULL AND p_end<p_start)
  OR (p_owner IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.organization_memberships WHERE user_id=p_owner AND status='active')) THEN
  RAISE EXCEPTION 'Revisa los datos del proyecto';
 END IF;
 IF p_id IS NULL THEN
  INSERT INTO public.work_projects(name,description,status,start_date,end_date,owner_user_id)
  VALUES(trim(p_name),nullif(trim(coalesce(p_description,'')),''),p_status,p_start,p_end,p_owner) RETURNING id INTO result;
 ELSE
  UPDATE public.work_projects SET name=trim(p_name),description=nullif(trim(coalesce(p_description,'')),''),status=p_status,start_date=p_start,end_date=p_end,owner_user_id=p_owner,updated_at=clock_timestamp()
  WHERE id=p_id RETURNING id INTO result;
  IF result IS NULL THEN RAISE EXCEPTION 'Proyecto no disponible'; END IF;
 END IF;
 RETURN result;
END $function$;

ALTER FUNCTION public.work_projects_overview() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_project_v2(uuid,text,text,text,date,date,uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_save_project_v2(uuid,text,text,text,date,date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_save_project_v2(uuid,text,text,text,date,date,uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
