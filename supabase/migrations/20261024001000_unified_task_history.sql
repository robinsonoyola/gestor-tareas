BEGIN;

CREATE TABLE IF NOT EXISTS public.work_task_assignment_events(
 organization_id uuid NOT NULL,
 id uuid NOT NULL DEFAULT gen_random_uuid(),
 task_id uuid NOT NULL,
 user_id uuid NOT NULL,
 actor_id uuid,
 actor_name text NOT NULL,
 employee_name text NOT NULL,
 action text NOT NULL CHECK(action IN('assigned','unassigned')),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id)
);
CREATE INDEX IF NOT EXISTS work_task_assignment_events_task ON public.work_task_assignment_events(organization_id,task_id,created_at DESC,id);
ALTER TABLE public.work_task_assignment_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_assignment_events FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_task_assignment_events TO ase_tenant_executor;
DROP POLICY IF EXISTS task_assignment_events_executor ON public.work_task_assignment_events;
CREATE POLICY task_assignment_events_executor ON public.work_task_assignment_events TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

GRANT CREATE ON SCHEMA ase_private TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION ase_private.log_task_assignment_event() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE row_value public.task_assignments%ROWTYPE; actor uuid:=ase_private.session_user_id();
BEGIN
 row_value:=CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
 INSERT INTO public.work_task_assignment_events(organization_id,task_id,user_id,actor_id,actor_name,employee_name,action)
 VALUES(row_value.organization_id,row_value.task_id,row_value.user_id,actor,
  coalesce((SELECT full_name FROM public.organization_memberships WHERE organization_id=row_value.organization_id AND user_id=actor),'Sistema'),
  coalesce((SELECT full_name FROM public.organization_memberships WHERE organization_id=row_value.organization_id AND user_id=row_value.user_id),'Empleado no disponible'),
  CASE WHEN TG_OP='DELETE' THEN 'unassigned' ELSE 'assigned' END);
 RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END $$;
DROP TRIGGER IF EXISTS work_log_task_assignment ON public.task_assignments;
CREATE TRIGGER work_log_task_assignment AFTER INSERT OR DELETE ON public.task_assignments FOR EACH ROW EXECUTE FUNCTION ase_private.log_task_assignment_event();
ALTER FUNCTION ase_private.log_task_assignment_event() OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA ase_private FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.log_task_assignment_event() FROM PUBLIC,anon,authenticated,ase_tenant_executor;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_task_timeline(p_task uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=ase_private.current_org() AND id=p_task) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF NOT(public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes consultar esta tarea'; END IF;
 WITH events AS (
  SELECT 'created:'||t.id::text id,'created' kind,'Tarea creada' title,t.title detail,'Sistema' actor_name,t.created_at
  FROM public.tasks t WHERE t.organization_id=ase_private.current_org() AND t.id=p_task
  UNION ALL
  SELECT 'assignment:'||e.id::text,'assignment_'||e.action,
   CASE e.action WHEN 'assigned' THEN 'Empleado asignado' ELSE 'Empleado retirado' END,e.employee_name,e.actor_name,e.created_at
  FROM public.work_task_assignment_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL
  SELECT 'importance:'||e.id::text,'importance','Importancia modificada',
   coalesce(CASE e.previous WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,'Creación')||' → '||
   CASE e.current_value WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,
   e.actor_name,e.created_at FROM public.work_importance_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL
  SELECT 'schedule:'||e.id::text,'schedule','Planificación modificada',
   CASE e.current_value->>'schedule_kind' WHEN 'anytime' THEN 'En cualquier momento' WHEN 'deadline' THEN 'Antes de una fecha' WHEN 'window' THEN 'Ventana de ejecución' WHEN 'scheduled' THEN 'Fecha u hora concreta' WHEN 'period' THEN 'Periodo planificado' ELSE 'Planificación actualizada' END,
   e.actor_name,e.created_at FROM public.work_execution_schedule_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id
   WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
  UNION ALL
  SELECT 'state:'||e.id::text,'state','Estado modificado',
   CASE e.from_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' ELSE e.from_state END||' → '||
   CASE e.to_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' ELSE e.to_state END||' · '||e.reason,
   e.actor_name,e.created_at FROM public.work_board_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id
   WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
 ), page AS (SELECT * FROM events ORDER BY created_at DESC,id DESC LIMIT 250)
 SELECT coalesce(jsonb_agg(to_jsonb(page) ORDER BY created_at DESC,id DESC),'[]'::jsonb) INTO result FROM page;
 RETURN result;
END $$;
ALTER FUNCTION public.work_task_timeline(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_task_timeline(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_task_timeline(uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;

NOTIFY pgrst,'reload schema';
COMMIT;
