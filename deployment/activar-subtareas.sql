-- ASE Work: independent tasks linked as subtasks of another activity.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_task_subtasks(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 parent_task_id uuid NOT NULL,
 child_task_id uuid NOT NULL,
 position integer NOT NULL DEFAULT 1 CHECK(position>0),
 created_by uuid NOT NULL DEFAULT ase_private.session_user_id(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,parent_task_id,child_task_id),
 FOREIGN KEY(organization_id,parent_task_id)REFERENCES public.tasks(organization_id,id)ON DELETE CASCADE,
 FOREIGN KEY(organization_id,child_task_id)REFERENCES public.tasks(organization_id,id)ON DELETE CASCADE,
 CHECK(parent_task_id<>child_task_id)
);
ALTER TABLE public.work_task_subtasks ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.work_task_subtask_events(
 organization_id uuid NOT NULL,
 id bigint GENERATED ALWAYS AS IDENTITY,
 parent_task_id uuid NOT NULL,
 child_task_id uuid NOT NULL,
 actor_id uuid NOT NULL,
 action text NOT NULL CHECK(action IN('linked','unlinked')),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id)
);
ALTER TABLE public.work_task_subtask_events ENABLE ROW LEVEL SECURITY;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_task_subtasks,public.work_task_subtask_events TO ase_tenant_executor;
GRANT USAGE,SELECT ON SEQUENCE public.work_task_subtask_events_id_seq TO ase_tenant_executor;
DROP POLICY IF EXISTS work_task_subtasks_executor ON public.work_task_subtasks;
CREATE POLICY work_task_subtasks_executor ON public.work_task_subtasks TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_subtask_events_executor ON public.work_task_subtask_events;
CREATE POLICY work_task_subtask_events_executor ON public.work_task_subtask_events TO ase_tenant_executor USING(true)WITH CHECK(true);

CREATE OR REPLACE FUNCTION public.work_task_subtask_directory(p_task uuid)RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 IF NOT EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=org AND t.id=p_task)THEN RAISE EXCEPTION 'La actividad principal ya no está disponible';END IF;
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',t.id,'title',t.title,'description',t.description,'importance',t.importance,'status',t.status,'schedule_type',t.schedule_type,'schedule_date',t.schedule_date,'position',x.position,'assigned',coalesce((SELECT string_agg(u.full_name,', 'ORDER BY u.full_name)FROM public.task_assignments a JOIN ase_private.employee_profiles u ON u.id=a.user_id WHERE a.organization_id=org AND a.task_id=t.id),'Sin asignar'))ORDER BY x.position,t.title,t.id)FROM public.work_task_subtasks x JOIN public.tasks t ON t.organization_id=x.organization_id AND t.id=x.child_task_id WHERE x.organization_id=org AND x.parent_task_id=p_task),'[]'::jsonb);
END $$;

CREATE OR REPLACE FUNCTION public.work_manage_task_subtask(p_action text,p_parent uuid,p_child uuid)RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();next_position integer;
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_action NOT IN('link','unlink')THEN RAISE EXCEPTION 'Acción no válida';END IF;
 IF p_parent IS NULL OR p_child IS NULL OR p_parent=p_child THEN RAISE EXCEPTION 'Selecciona dos actividades diferentes';END IF;
 IF(SELECT count(*)FROM public.tasks t WHERE t.organization_id=org AND t.id IN(p_parent,p_child))<>2 THEN RAISE EXCEPTION 'Alguna actividad ya no está disponible';END IF;
 IF p_action='link'THEN
  IF EXISTS(WITH RECURSIVE descendants(id)AS(SELECT s.child_task_id FROM public.work_task_subtasks s WHERE s.organization_id=org AND s.parent_task_id=p_child UNION SELECT s.child_task_id FROM public.work_task_subtasks s JOIN descendants d ON d.id=s.parent_task_id WHERE s.organization_id=org)SELECT 1 FROM descendants WHERE id=p_parent)THEN RAISE EXCEPTION 'La relación formaría un ciclo entre subtareas';END IF;
  SELECT coalesce(max(position),0)+1 INTO next_position FROM public.work_task_subtasks WHERE organization_id=org AND parent_task_id=p_parent;
  INSERT INTO public.work_task_subtasks(organization_id,parent_task_id,child_task_id,position)VALUES(org,p_parent,p_child,next_position)ON CONFLICT DO NOTHING;
  IF FOUND THEN INSERT INTO public.work_task_subtask_events(organization_id,parent_task_id,child_task_id,actor_id,action)VALUES(org,p_parent,p_child,ase_private.session_user_id(),'linked');END IF;
 ELSE
  DELETE FROM public.work_task_subtasks WHERE organization_id=org AND parent_task_id=p_parent AND child_task_id=p_child;
  IF FOUND THEN INSERT INTO public.work_task_subtask_events(organization_id,parent_task_id,child_task_id,actor_id,action)VALUES(org,p_parent,p_child,ase_private.session_user_id(),'unlinked');END IF;
 END IF;
END $$;

ALTER FUNCTION public.work_task_subtask_directory(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_manage_task_subtask(text,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON TABLE public.work_task_subtasks,public.work_task_subtask_events FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.work_task_subtask_directory(uuid),public.work_manage_task_subtask(text,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_subtask_directory(uuid),public.work_manage_task_subtask(text,uuid,uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

