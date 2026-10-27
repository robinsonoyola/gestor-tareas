-- ASE Work: project milestones for intermediate delivery tracking.
BEGIN;

CREATE TABLE IF NOT EXISTS public.work_project_milestones(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_id uuid NOT NULL DEFAULT ase_private.current_org() REFERENCES public.organizations(id),
 project_id uuid NOT NULL,
 title text NOT NULL CHECK(length(trim(title)) BETWEEN 1 AND 160),
 due_date date,
 completed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 created_by uuid NOT NULL DEFAULT ase_private.session_user_id(),
 UNIQUE(organization_id,id),
 FOREIGN KEY(organization_id,project_id) REFERENCES public.work_projects(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,created_by) REFERENCES public.organization_memberships(organization_id,user_id)
);

ALTER TABLE public.work_project_milestones ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_project_milestones FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_project_milestones TO ase_tenant_executor;

DO $policy$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_project_milestones' AND policyname='work_project_milestones_boundary') THEN
  CREATE POLICY work_project_milestones_boundary ON public.work_project_milestones AS RESTRICTIVE TO PUBLIC
   USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='work_project_milestones' AND policyname='work_project_milestones_executor') THEN
  CREATE POLICY work_project_milestones_executor ON public.work_project_milestones TO ase_tenant_executor USING(true) WITH CHECK(true);
 END IF;
END $policy$;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_projects_overview()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $function$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 SELECT jsonb_build_object(
  'projects',coalesce((SELECT jsonb_agg(to_jsonb(p)||jsonb_build_object(
   'task_ids',coalesce((SELECT jsonb_agg(x.task_id ORDER BY x.linked_at,x.task_id) FROM public.work_project_tasks x WHERE x.project_id=p.id),'[]'::jsonb),
   'milestones',coalesce((SELECT jsonb_agg(to_jsonb(m) ORDER BY m.completed_at IS NOT NULL,m.due_date NULLS LAST,m.created_at,m.id) FROM public.work_project_milestones m WHERE m.project_id=p.id),'[]'::jsonb)
  ) ORDER BY CASE p.status WHEN 'active' THEN 1 WHEN 'planned' THEN 2 WHEN 'completed' THEN 3 ELSE 4 END,p.name,p.id) FROM public.work_projects p),'[]'::jsonb)
 ) INTO result;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_save_project_milestone(p_id uuid,p_project uuid,p_title text,p_due date,p_completed boolean DEFAULT false)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
DECLARE result uuid;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_title IS NULL OR length(trim(p_title)) NOT BETWEEN 1 AND 160
  OR NOT EXISTS(SELECT 1 FROM public.work_projects WHERE id=p_project AND status<>'archived') THEN
  RAISE EXCEPTION 'Revisa los datos del hito';
 END IF;
 IF p_id IS NULL THEN
  INSERT INTO public.work_project_milestones(project_id,title,due_date,completed_at)
  VALUES(p_project,trim(p_title),p_due,CASE WHEN p_completed THEN clock_timestamp() END)
  RETURNING id INTO result;
 ELSE
  UPDATE public.work_project_milestones SET title=trim(p_title),due_date=p_due,
   completed_at=CASE WHEN p_completed THEN coalesce(completed_at,clock_timestamp()) ELSE NULL END
  WHERE id=p_id AND project_id=p_project RETURNING id INTO result;
  IF result IS NULL THEN RAISE EXCEPTION 'Hito no disponible'; END IF;
 END IF;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION public.work_delete_project_milestone(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $function$
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 DELETE FROM public.work_project_milestones WHERE id=p_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Hito no disponible'; END IF;
END $function$;

ALTER FUNCTION public.work_projects_overview() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_project_milestone(uuid,uuid,text,date,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_delete_project_milestone(uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_save_project_milestone(uuid,uuid,text,date,boolean),public.work_delete_project_milestone(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_save_project_milestone(uuid,uuid,text,date,boolean),public.work_delete_project_milestone(uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
