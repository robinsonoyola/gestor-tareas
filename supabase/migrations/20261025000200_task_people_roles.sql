BEGIN;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_guard_assignment() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF TG_OP='UPDATE' AND NEW.organization_id=OLD.organization_id AND NEW.task_id=OLD.task_id AND NEW.user_id=OLD.user_id THEN RETURN NEW;END IF;
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=OLD.user_id FOR UPDATE;
 IF public.work_mode()AND EXISTS(SELECT 1 FROM public.work_day_plan WHERE task_id=OLD.task_id AND user_id=OLD.user_id AND state='active')THEN RAISE EXCEPTION 'Finaliza la tarea en la tablet antes de cambiar su asignación';END IF;
 IF TG_OP='DELETE'THEN RETURN OLD;END IF;RETURN NEW;
END $$;
ALTER FUNCTION public.work_guard_assignment() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_guard_assignment() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_guard_assignment() TO ase_tenant_executor;

ALTER TABLE public.task_assignments ADD COLUMN IF NOT EXISTS responsibility_role text NOT NULL DEFAULT 'collaborator';
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='task_assignment_responsibility_role' AND conrelid='public.task_assignments'::regclass) THEN ALTER TABLE public.task_assignments ADD CONSTRAINT task_assignment_responsibility_role CHECK(responsibility_role IN('primary','collaborator')); END IF; END $$;
WITH ranked AS(SELECT organization_id,task_id,user_id,row_number() OVER(PARTITION BY organization_id,task_id ORDER BY user_id) n FROM public.task_assignments)
UPDATE public.task_assignments a SET responsibility_role='primary' FROM ranked r WHERE r.organization_id=a.organization_id AND r.task_id=a.task_id AND r.user_id=a.user_id AND r.n=1 AND NOT EXISTS(SELECT 1 FROM public.task_assignments x WHERE x.organization_id=a.organization_id AND x.task_id=a.task_id AND x.responsibility_role='primary');
CREATE UNIQUE INDEX IF NOT EXISTS task_assignments_one_primary ON public.task_assignments(organization_id,task_id) WHERE responsibility_role='primary';

CREATE TABLE IF NOT EXISTS public.work_task_followers(
 organization_id uuid NOT NULL,task_id uuid NOT NULL,user_id uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,task_id,user_id),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id) ON DELETE CASCADE
);
ALTER TABLE public.work_task_followers ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_task_followers FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,DELETE ON public.work_task_followers TO ase_tenant_executor;
DROP POLICY IF EXISTS task_followers_executor ON public.work_task_followers;
CREATE POLICY task_followers_executor ON public.work_task_followers TO ase_tenant_executor USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_manage_task_roles(p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[]) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;org uuid:=ase_private.current_org();executors uuid[];blocked_names text;
BEGIN
 p_collaborators:=coalesce(p_collaborators,'{}'::uuid[]);p_followers:=coalesce(p_followers,'{}'::uuid[]);
 IF cardinality(p_collaborators)>99 OR cardinality(p_followers)>100 OR (p_primary IS NULL AND cardinality(p_collaborators)>0) THEN RAISE EXCEPTION 'Selecciona un responsable principal para los colaboradores'; END IF;
 executors:=CASE WHEN p_primary IS NULL THEN '{}'::uuid[] ELSE ARRAY[p_primary]||p_collaborators END;
 IF cardinality(executors)<>(SELECT count(DISTINCT id) FROM unnest(executors)u(id)) OR cardinality(p_followers)<>(SELECT count(DISTINCT id) FROM unnest(p_followers)u(id)) OR executors&&p_followers THEN RAISE EXCEPTION 'Una persona no puede repetir ni tener dos funciones en la misma tarea'; END IF;
 IF EXISTS(SELECT 1 FROM unnest(executors||p_followers)u(id) WHERE id IS NULL OR NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles e WHERE e.id=u.id AND e.is_admin IS FALSE AND e.membership_status='active')) THEN RAISE EXCEPTION 'Selecciona empleados activos'; END IF;
 IF p_action='edit' THEN
  SELECT string_agg(coalesce(e.full_name,'Empleado'),', ' ORDER BY e.full_name) INTO blocked_names FROM public.task_assignments a LEFT JOIN ase_private.employee_profiles e ON e.id=a.user_id WHERE a.organization_id=org AND a.task_id=p_id AND NOT(a.user_id=ANY(executors)) AND EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.organization_id=org AND p.task_id=p_id AND p.user_id=a.user_id AND p.state IN('pending','active','blocked'));
  IF blocked_names IS NOT NULL THEN RAISE EXCEPTION 'No puedes retirar a %: tiene planificación pendiente, activa o bloqueada',blocked_names; END IF;
 END IF;
 result:=public.work_manage_task_importance(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,executors);
 UPDATE public.task_assignments SET responsibility_role=CASE WHEN user_id=p_primary THEN 'primary' ELSE 'collaborator' END WHERE organization_id=org AND task_id=result;
 DELETE FROM public.work_task_followers WHERE organization_id=org AND task_id=result AND NOT(user_id=ANY(p_followers));
 INSERT INTO public.work_task_followers(organization_id,task_id,user_id) SELECT org,result,u.id FROM unnest(p_followers)u(id) ON CONFLICT DO NOTHING;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_task_catalog() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN PERFORM public.work_assert_permission('tasks.view');
 SELECT coalesce(jsonb_agg(to_jsonb(t)||jsonb_build_object(
  'assigned_users',coalesce((SELECT jsonb_agg(jsonb_build_object('id',u.id,'full_name',u.full_name,'role',a.responsibility_role) ORDER BY (a.responsibility_role='primary') DESC,u.full_name,u.id) FROM public.task_assignments a JOIN ase_private.employee_profiles u ON u.id=a.user_id WHERE a.organization_id=t.organization_id AND a.task_id=t.id),'[]'::jsonb),
  'followers',coalesce((SELECT jsonb_agg(jsonb_build_object('id',u.id,'full_name',u.full_name) ORDER BY u.full_name,u.id) FROM public.work_task_followers f JOIN ase_private.employee_profiles u ON u.id=f.user_id WHERE f.organization_id=t.organization_id AND f.task_id=t.id),'[]'::jsonb)
 ) ORDER BY t.created_at DESC,t.id),'[]'::jsonb) INTO result FROM public.tasks t WHERE t.organization_id=ase_private.current_org();RETURN result;END $$;

CREATE OR REPLACE FUNCTION public.work_share_task_access(p_task uuid,p_users uuid[],p_expires_days integer DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid:=ase_private.current_org();code text;expires_at timestamptz;blocked_names text;BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF p_task IS NULL OR NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=org AND id=p_task FOR KEY SHARE) THEN RAISE EXCEPTION 'La tarea ya no existe';END IF;
 IF p_users IS NULL OR cardinality(p_users)<1 OR cardinality(p_users)>100 OR cardinality(p_users)<>(SELECT count(DISTINCT id)FROM unnest(p_users)u(id)) OR EXISTS(SELECT 1 FROM unnest(p_users)u(id)WHERE id IS NULL OR NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles e WHERE e.id=u.id AND e.is_admin IS FALSE AND e.membership_status='active'))THEN RAISE EXCEPTION 'Selecciona al menos un empleado activo';END IF;
 IF p_expires_days IS NOT NULL AND p_expires_days NOT IN(1,7,30,90)THEN RAISE EXCEPTION 'Caducidad no válida';END IF;
 SELECT string_agg(coalesce(e.full_name,'Empleado'),', ' ORDER BY e.full_name)INTO blocked_names FROM public.task_assignments a LEFT JOIN ase_private.employee_profiles e ON e.id=a.user_id WHERE a.organization_id=org AND a.task_id=p_task AND NOT(a.user_id=ANY(p_users))AND EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.organization_id=org AND p.task_id=p_task AND p.user_id=a.user_id AND p.state IN('pending','active','blocked'));
 IF blocked_names IS NOT NULL THEN RAISE EXCEPTION 'No puedes retirar a %: tiene planificación pendiente, activa o bloqueada',blocked_names;END IF;
 DELETE FROM public.task_assignments a WHERE a.organization_id=org AND a.task_id=p_task AND NOT(a.user_id=ANY(p_users));
 INSERT INTO public.task_assignments(organization_id,task_id,user_id,responsibility_role)SELECT org,p_task,u.id,'collaborator' FROM unnest(p_users)u(id)WHERE NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=org AND a.task_id=p_task AND a.user_id=u.id);
 IF NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=org AND task_id=p_task AND responsibility_role='primary')THEN UPDATE public.task_assignments SET responsibility_role='primary' WHERE organization_id=org AND task_id=p_task AND user_id=(SELECT min(user_id)FROM public.task_assignments WHERE organization_id=org AND task_id=p_task);END IF;
 code:='TASK-'||upper(replace(gen_random_uuid()::text,'-',''));expires_at:=CASE WHEN p_expires_days IS NULL THEN NULL ELSE clock_timestamp()+make_interval(days=>p_expires_days)END;
 INSERT INTO public.task_access_codes(organization_id,id,task_id,access_code,created_by,created_at,is_active,expires_at)VALUES(org,gen_random_uuid(),p_task,code,ase_private.session_user_id(),clock_timestamp(),true,expires_at);
 RETURN jsonb_build_object('code',code,'expires_at',expires_at,'assigned',cardinality(p_users));END $$;

GRANT CREATE ON SCHEMA ase_private TO ase_tenant_executor;
SET LOCAL ROLE ase_tenant_executor;
CREATE OR REPLACE FUNCTION ase_private.notify_task_follower() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)VALUES(NEW.organization_id,NEW.user_id,NULL,'Ahora sigues la tarea: '||coalesce((SELECT title FROM public.tasks WHERE organization_id=NEW.organization_id AND id=NEW.task_id),'Tarea'),'assignment','follower:'||NEW.task_id::text||':'||NEW.user_id::text||':'||txid_current()::text)ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;RETURN NEW;END $$;
CREATE OR REPLACE FUNCTION ase_private.notify_follower_importance_change() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid;task_title text;label text;BEGIN SELECT title INTO task_title FROM public.tasks WHERE organization_id=NEW.organization_id AND id=NEW.task_id;label:=CASE NEW.current_value WHEN 'urgent'THEN'Urgente' WHEN'high'THEN'Alta' WHEN'low'THEN'Baja' ELSE'Normal'END;
 FOR recipient IN SELECT user_id FROM public.work_task_followers WHERE organization_id=NEW.organization_id AND task_id=NEW.task_id LOOP INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)VALUES(NEW.organization_id,recipient,NULL,'Importancia actualizada: '||coalesce(task_title,'Tarea')||' · '||label,'importance','importance:'||NEW.id::text||':'||recipient::text)ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;END LOOP;RETURN NEW;END $$;
CREATE OR REPLACE FUNCTION ase_private.notify_follower_schedule_change() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid;task uuid;task_title text;schedule_label text;BEGIN SELECT p.task_id,t.title INTO task,task_title FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id WHERE p.organization_id=NEW.organization_id AND p.id=NEW.plan_id;schedule_label:=CASE NEW.current_value->>'schedule_kind' WHEN'window'THEN'ventana de ejecución' WHEN'deadline'THEN'fecha límite' WHEN'scheduled'THEN'fecha programada' WHEN'period'THEN'período planificado' ELSE'sin fecha'END;
 FOR recipient IN SELECT user_id FROM public.work_task_followers WHERE organization_id=NEW.organization_id AND task_id=task LOOP INSERT INTO public.work_notifications(organization_id,user_id,incident_id,message,kind,event_key)VALUES(NEW.organization_id,recipient,NULL,'Planificación actualizada: '||coalesce(task_title,'Tarea')||' · '||schedule_label,'schedule','schedule:'||NEW.id::text||':'||recipient::text)ON CONFLICT(organization_id,user_id,event_key)WHERE event_key IS NOT NULL DO NOTHING;END LOOP;RETURN NEW;END $$;
RESET ROLE;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_trigger WHERE tgname='work_notify_task_follower' AND tgrelid='public.work_task_followers'::regclass)THEN CREATE TRIGGER work_notify_task_follower AFTER INSERT ON public.work_task_followers FOR EACH ROW EXECUTE FUNCTION ase_private.notify_task_follower();END IF;END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_trigger WHERE tgname='work_notify_follower_importance' AND tgrelid='public.work_importance_events'::regclass)THEN CREATE TRIGGER work_notify_follower_importance AFTER INSERT ON public.work_importance_events FOR EACH ROW EXECUTE FUNCTION ase_private.notify_follower_importance_change();END IF;END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM pg_trigger WHERE tgname='work_notify_follower_schedule' AND tgrelid='public.work_execution_schedule_events'::regclass)THEN CREATE TRIGGER work_notify_follower_schedule AFTER INSERT ON public.work_execution_schedule_events FOR EACH ROW EXECUTE FUNCTION ase_private.notify_follower_schedule_change();END IF;END $$;
SET LOCAL ROLE ase_tenant_executor;
REVOKE ALL ON FUNCTION ase_private.notify_task_follower(),ase_private.notify_follower_importance_change(),ase_private.notify_follower_schedule_change() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.notify_task_follower(),ase_private.notify_follower_importance_change(),ase_private.notify_follower_schedule_change() TO ase_tenant_executor;
RESET ROLE;
REVOKE CREATE ON SCHEMA ase_private FROM ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_task_timeline(p_task uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=ase_private.current_org() AND id=p_task) THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;
 IF NOT(public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id()) OR EXISTS(SELECT 1 FROM public.work_task_followers WHERE organization_id=ase_private.current_org() AND task_id=p_task AND user_id=ase_private.session_user_id())) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes consultar esta tarea'; END IF;
 WITH events AS (
  SELECT 'created:'||t.id::text id,'created' kind,'Tarea creada' title,t.title detail,'Sistema' actor_name,t.created_at FROM public.tasks t WHERE t.organization_id=ase_private.current_org() AND t.id=p_task
  UNION ALL SELECT 'assignment:'||e.id::text,'assignment_'||e.action,CASE e.action WHEN 'assigned' THEN 'Empleado asignado' ELSE 'Empleado retirado' END,e.employee_name,e.actor_name,e.created_at FROM public.work_task_assignment_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'importance:'||e.id::text,'importance','Importancia modificada',coalesce(CASE e.previous WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,'Creación')||' → '||CASE e.current_value WHEN 'low' THEN 'Baja' WHEN 'normal' THEN 'Normal' WHEN 'high' THEN 'Alta' WHEN 'urgent' THEN 'Urgente' END,e.actor_name,e.created_at FROM public.work_importance_events e WHERE e.organization_id=ase_private.current_org() AND e.task_id=p_task
  UNION ALL SELECT 'schedule:'||e.id::text,'schedule','Planificación modificada',CASE e.current_value->>'schedule_kind' WHEN 'anytime' THEN 'En cualquier momento' WHEN 'deadline' THEN 'Antes de una fecha' WHEN 'window' THEN 'Ventana de ejecución' WHEN 'scheduled' THEN 'Fecha u hora concreta' WHEN 'period' THEN 'Periodo planificado' ELSE 'Planificación actualizada' END,e.actor_name,e.created_at FROM public.work_execution_schedule_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
  UNION ALL SELECT 'state:'||e.id::text,'state','Estado modificado',CASE e.from_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' ELSE e.from_state END||' → '||CASE e.to_state WHEN 'pending' THEN 'Pendiente' WHEN 'active' THEN 'En curso' WHEN 'blocked' THEN 'Bloqueada' WHEN 'completed' THEN 'Completada' ELSE e.to_state END||' · '||e.reason,e.actor_name,e.created_at FROM public.work_board_events e JOIN public.work_day_plan p ON p.organization_id=e.organization_id AND p.id=e.plan_id WHERE e.organization_id=ase_private.current_org() AND p.task_id=p_task
 ),page AS(SELECT * FROM events ORDER BY created_at DESC,id DESC LIMIT 250) SELECT coalesce(jsonb_agg(to_jsonb(page) ORDER BY created_at DESC,id DESC),'[]'::jsonb) INTO result FROM page;RETURN result;END $$;

ALTER FUNCTION public.work_manage_task_roles(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[]) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_catalog() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_task_timeline(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_share_task_access(uuid,uuid[],integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_roles(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[]),public.work_task_catalog(),public.work_task_timeline(uuid),public.work_share_task_access(uuid,uuid[],integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_roles(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[]),public.work_task_catalog(),public.work_task_timeline(uuid),public.work_share_task_access(uuid,uuid[],integer) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
