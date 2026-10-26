-- ASE Work: task dependencies enforced for every execution start.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_task_dependencies(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 task_id uuid NOT NULL,
 prerequisite_task_id uuid NOT NULL,
 created_by uuid NOT NULL DEFAULT ase_private.session_user_id(),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,task_id,prerequisite_task_id),
 FOREIGN KEY(organization_id,task_id)REFERENCES public.tasks(organization_id,id)ON DELETE CASCADE,
 FOREIGN KEY(organization_id,prerequisite_task_id)REFERENCES public.tasks(organization_id,id)ON DELETE CASCADE,
 CHECK(task_id<>prerequisite_task_id)
);
ALTER TABLE public.work_task_dependencies ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.work_task_dependency_events(
 organization_id uuid NOT NULL,id bigint GENERATED ALWAYS AS IDENTITY,task_id uuid NOT NULL,prerequisite_task_id uuid NOT NULL,actor_id uuid NOT NULL,
 action text NOT NULL CHECK(action IN('linked','unlinked')),created_at timestamptz NOT NULL DEFAULT clock_timestamp(),PRIMARY KEY(organization_id,id)
);
ALTER TABLE public.work_task_dependency_events ENABLE ROW LEVEL SECURITY;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.work_task_templates,public.work_task_template_events,public.work_task_subtasks,public.work_task_subtask_events,public.work_task_dependencies,public.work_task_dependency_events TO ase_tenant_executor;
GRANT USAGE,SELECT ON SEQUENCE public.work_task_template_events_id_seq,public.work_task_subtask_events_id_seq,public.work_task_dependency_events_id_seq TO ase_tenant_executor;
DROP POLICY IF EXISTS work_task_templates_executor ON public.work_task_templates;
CREATE POLICY work_task_templates_executor ON public.work_task_templates TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_template_events_executor ON public.work_task_template_events;
CREATE POLICY work_task_template_events_executor ON public.work_task_template_events TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_subtasks_executor ON public.work_task_subtasks;
CREATE POLICY work_task_subtasks_executor ON public.work_task_subtasks TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_subtask_events_executor ON public.work_task_subtask_events;
CREATE POLICY work_task_subtask_events_executor ON public.work_task_subtask_events TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_dependencies_executor ON public.work_task_dependencies;
CREATE POLICY work_task_dependencies_executor ON public.work_task_dependencies TO ase_tenant_executor USING(true)WITH CHECK(true);
DROP POLICY IF EXISTS work_task_dependency_events_executor ON public.work_task_dependency_events;
CREATE POLICY work_task_dependency_events_executor ON public.work_task_dependency_events TO ase_tenant_executor USING(true)WITH CHECK(true);

CREATE OR REPLACE FUNCTION public.work_task_dependency_directory(p_task uuid)RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();
BEGIN
 PERFORM public.work_assert_permission('tasks.view');
 IF NOT EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=org AND t.id=p_task)THEN RAISE EXCEPTION 'La actividad ya no está disponible';END IF;
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',t.id,'title',t.title,'importance',t.importance,'latest_date',latest.work_date,'latest_state',latest.state)ORDER BY t.title,t.id)FROM public.work_task_dependencies d JOIN public.tasks t ON t.organization_id=d.organization_id AND t.id=d.prerequisite_task_id LEFT JOIN LATERAL(SELECT p.work_date,p.state FROM public.work_day_plan p WHERE p.organization_id=d.organization_id AND p.task_id=d.prerequisite_task_id ORDER BY p.work_date DESC,p.priority DESC,p.id DESC LIMIT 1)latest ON true WHERE d.organization_id=org AND d.task_id=p_task),'[]'::jsonb);
END $$;

CREATE OR REPLACE FUNCTION public.work_manage_task_dependency(p_action text,p_task uuid,p_prerequisite uuid)RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_action NOT IN('link','unlink')THEN RAISE EXCEPTION 'Acción no válida';END IF;
 IF p_task IS NULL OR p_prerequisite IS NULL OR p_task=p_prerequisite THEN RAISE EXCEPTION 'Selecciona dos actividades diferentes';END IF;
 IF(SELECT count(*)FROM public.tasks t WHERE t.organization_id=org AND t.id IN(p_task,p_prerequisite))<>2 THEN RAISE EXCEPTION 'Alguna actividad ya no está disponible';END IF;
 IF p_action='link'THEN
  IF EXISTS(WITH RECURSIVE requirements(id)AS(SELECT d.prerequisite_task_id FROM public.work_task_dependencies d WHERE d.organization_id=org AND d.task_id=p_prerequisite UNION SELECT d.prerequisite_task_id FROM public.work_task_dependencies d JOIN requirements r ON r.id=d.task_id WHERE d.organization_id=org)SELECT 1 FROM requirements WHERE id=p_task)THEN RAISE EXCEPTION 'La dependencia formaría un ciclo';END IF;
  INSERT INTO public.work_task_dependencies(organization_id,task_id,prerequisite_task_id)VALUES(org,p_task,p_prerequisite)ON CONFLICT DO NOTHING;
  IF FOUND THEN INSERT INTO public.work_task_dependency_events(organization_id,task_id,prerequisite_task_id,actor_id,action)VALUES(org,p_task,p_prerequisite,ase_private.session_user_id(),'linked');END IF;
 ELSE
  DELETE FROM public.work_task_dependencies WHERE organization_id=org AND task_id=p_task AND prerequisite_task_id=p_prerequisite;
  IF FOUND THEN INSERT INTO public.work_task_dependency_events(organization_id,task_id,prerequisite_task_id,actor_id,action)VALUES(org,p_task,p_prerequisite,ase_private.session_user_id(),'unlinked');END IF;
 END IF;
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_eligibility(p_plan uuid,p_moment timestamptz DEFAULT clock_timestamp()) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;start_limit timestamptz;end_limit timestamptz;temporal boolean;earlier boolean;assigned boolean;opened boolean;dependency_blocked boolean;dependency_names jsonb;reason text;
BEGIN
 SELECT * INTO p FROM public.work_day_plan WHERE organization_id=ase_private.current_org()AND id=p_plan;
 IF NOT FOUND THEN RAISE EXCEPTION 'Ejecución no disponible';END IF;
 start_limit:=CASE p.schedule_kind WHEN'window'THEN p.available_from WHEN'period'THEN p.available_from WHEN'scheduled'THEN CASE WHEN p.strict_schedule THEN p.scheduled_for END END;
 end_limit:=CASE p.schedule_kind WHEN'deadline'THEN p.due_at WHEN'window'THEN p.due_at WHEN'scheduled'THEN p.due_at WHEN'period'THEN coalesce(p.due_at,p.planned_end)END;
 temporal:=(start_limit IS NULL OR p_moment>=start_limit)AND(end_limit IS NULL OR p_moment<end_limit);
 assigned:=EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=p.organization_id AND a.task_id=p.task_id AND a.user_id=p.user_id);
 opened:=EXISTS(SELECT 1 FROM public.checkins c WHERE c.organization_id=p.organization_id AND c.user_id=p.user_id AND c.checkout_time IS NULL AND c.work_plan_id IS DISTINCT FROM p.id);
 earlier:=EXISTS(SELECT 1 FROM public.work_day_plan x WHERE x.organization_id=p.organization_id AND x.user_id=p.user_id AND x.state='pending'AND x.id<>p.id AND x.priority<p.priority AND x.work_date=p.work_date);
 WITH requirements AS(SELECT d.prerequisite_task_id,t.title,(SELECT x.state FROM public.work_day_plan x WHERE x.organization_id=p.organization_id AND x.task_id=d.prerequisite_task_id AND x.work_date<=p.work_date ORDER BY x.work_date DESC,x.priority DESC,x.id DESC LIMIT 1)latest_state FROM public.work_task_dependencies d JOIN public.tasks t ON t.organization_id=d.organization_id AND t.id=d.prerequisite_task_id WHERE d.organization_id=p.organization_id AND d.task_id=p.task_id)
 SELECT coalesce(bool_or(latest_state IS DISTINCT FROM'completed'),false),coalesce(jsonb_agg(title ORDER BY title)FILTER(WHERE latest_state IS DISTINCT FROM'completed'),'[]'::jsonb)INTO dependency_blocked,dependency_names FROM requirements;
 reason:=CASE WHEN p.state<>'pending'THEN'state'WHEN NOT assigned THEN'assignment'WHEN opened THEN'open_checkin'WHEN dependency_blocked THEN'dependency'WHEN earlier THEN'order'WHEN start_limit IS NOT NULL AND p_moment<start_limit THEN'too_early'WHEN end_limit IS NOT NULL AND p_moment>=end_limit THEN'overdue'ELSE NULL END;
 RETURN ase_private.execution_schedule_json(p)||jsonb_build_object('kind',p.schedule_kind,'strict',p.strict_schedule,'can_start',reason IS NULL,'can_start_time',temporal,'reason',reason,'waiting_for',dependency_names,'overdue',p.state IN('pending','active')AND end_limit IS NOT NULL AND p_moment>=end_limit,'starts_later',p.state='pending'AND start_limit IS NOT NULL AND p_moment<start_limit,'start_limit',start_limit,'end_limit',end_limit);
END $$;

CREATE OR REPLACE FUNCTION public.work_execution_schedule_guard()RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE eligibility jsonb;
BEGIN
 IF NEW.work_plan_id IS NULL THEN RETURN NEW;END IF;
 eligibility:=public.work_execution_eligibility(NEW.work_plan_id,coalesce(NEW.checkin_time,clock_timestamp()));
 IF NOT coalesce((eligibility->>'can_start')::boolean,false)THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE=CASE eligibility->>'reason' WHEN'too_early'THEN'Esta tarea todavía no está disponible'WHEN'overdue'THEN'La fecha límite ha pasado. Solicita al encargado que reprograme la tarea'WHEN'dependency'THEN'Debes completar primero: '||coalesce((SELECT string_agg(value,', ')FROM jsonb_array_elements_text(eligibility->'waiting_for')), 'otra tarea')WHEN'order'THEN'Respeta el orden de tareas del empleado'WHEN'open_checkin'THEN'El empleado ya tiene un fichaje activo'WHEN'assignment'THEN'La tarea ya no está asignada al empleado'ELSE'La tarea no puede iniciarse en este momento'END;END IF;
 RETURN NEW;
END $$;

ALTER FUNCTION public.work_task_dependency_directory(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_manage_task_dependency(text,uuid,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_eligibility(uuid,timestamptz) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_execution_schedule_guard() OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON TABLE public.work_task_dependencies,public.work_task_dependency_events FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.work_task_dependency_directory(uuid),public.work_manage_task_dependency(text,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_dependency_directory(uuid),public.work_manage_task_dependency(text,uuid,uuid) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
