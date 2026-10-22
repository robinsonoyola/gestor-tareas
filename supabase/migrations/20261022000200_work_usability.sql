-- Apply ONLY after CORE-MULTITENANCY-A1, first in the isolated staging project.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='120s';
DO $$ BEGIN
 IF to_regclass('public.organization_memberships') IS NULL OR to_regrole('ase_tenant_executor') IS NULL
 THEN RAISE EXCEPTION 'Instala primero CORE-MULTITENANCY-A1'; END IF;
END $$;
GRANT USAGE ON SCHEMA extensions TO ase_tenant_executor;
CREATE TABLE public.work_areas(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL DEFAULT ase_private.current_org() REFERENCES public.organizations(id),
 name text NOT NULL CHECK(length(btrim(name)) BETWEEN 2 AND 100),active boolean NOT NULL DEFAULT true,
 UNIQUE(organization_id,id),UNIQUE(organization_id,name));
CREATE TABLE public.work_area_members(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),area_id uuid NOT NULL,user_id uuid NOT NULL,
 PRIMARY KEY(organization_id,area_id,user_id),
 FOREIGN KEY(organization_id,area_id) REFERENCES public.work_areas(organization_id,id),
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id));
CREATE TABLE public.work_personal_pins(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),user_id uuid NOT NULL,
 pin_hash text NOT NULL,active boolean NOT NULL DEFAULT true,failures integer NOT NULL DEFAULT 0,locked_until timestamptz,
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),PRIMARY KEY(organization_id,user_id),
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id));
CREATE TABLE public.work_pin_attempts(
 organization_id uuid NOT NULL DEFAULT ase_private.current_org(),station_id uuid NOT NULL,attempts integer NOT NULL DEFAULT 0,
 window_start timestamptz NOT NULL DEFAULT clock_timestamp(),PRIMARY KEY(organization_id,station_id),
 FOREIGN KEY(organization_id,station_id) REFERENCES public.work_stations(organization_id,id));
CREATE TABLE public.work_incidents(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 task_id uuid NOT NULL,plan_id uuid,reporter_id uuid NOT NULL,assigned_user uuid,area_id uuid,
 subject text NOT NULL CHECK(length(btrim(subject)) BETWEEN 3 AND 160),description text NOT NULL CHECK(length(btrim(description)) BETWEEN 3 AND 5000),
 state text NOT NULL DEFAULT 'open' CHECK(state IN ('open','in_progress','resolved')),
 blocks_work boolean NOT NULL DEFAULT false,resolution text NOT NULL DEFAULT '',attachments text[] NOT NULL DEFAULT '{}',
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(organization_id,id),CHECK(assigned_user IS NOT NULL OR area_id IS NOT NULL),
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id),
 FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id),
 FOREIGN KEY(organization_id,reporter_id) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,assigned_user) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,area_id) REFERENCES public.work_areas(organization_id,id));
CREATE INDEX work_incidents_recipient ON public.work_incidents(organization_id,assigned_user,state,created_at);
CREATE TABLE public.work_notifications(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL DEFAULT ase_private.current_org(),user_id uuid NOT NULL,
 incident_id uuid NOT NULL,message text NOT NULL,seen boolean NOT NULL DEFAULT false,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,incident_id) REFERENCES public.work_incidents(organization_id,id));
CREATE INDEX work_notification_inbox ON public.work_notifications(organization_id,user_id,seen,created_at);
ALTER TABLE public.checkins ADD CONSTRAINT work_checkins_org_id_key UNIQUE(organization_id,id);
CREATE TABLE public.work_task_closures(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL DEFAULT ase_private.current_org(),
 plan_id uuid NOT NULL,checkin_id uuid NOT NULL,actor_id uuid NOT NULL,reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 5 AND 2000),
 kind text NOT NULL CHECK(kind IN ('admin_finish','incident_block')),incident_id uuid,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 FOREIGN KEY(organization_id,plan_id) REFERENCES public.work_day_plan(organization_id,id),
 FOREIGN KEY(organization_id,checkin_id) REFERENCES public.checkins(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id),
 FOREIGN KEY(organization_id,incident_id) REFERENCES public.work_incidents(organization_id,id));
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['work_areas','work_area_members','work_personal_pins','work_pin_attempts','work_incidents','work_notifications','work_task_closures'] LOOP
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
  EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC,anon,authenticated',t);
  EXECUTE format('GRANT SELECT,INSERT,UPDATE,DELETE ON public.%I TO ase_tenant_executor',t);
  EXECUTE format('CREATE POLICY work_feature_boundary ON public.%I AS RESTRICTIVE TO PUBLIC USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org())',t);
  EXECUTE format('CREATE POLICY work_feature_executor ON public.%I TO ase_tenant_executor USING(true) WITH CHECK(true)',t);
 END LOOP;
END $$;
ALTER TABLE public.work_day_plan DROP CONSTRAINT work_day_plan_state_check;
ALTER TABLE public.work_day_plan ADD CONSTRAINT work_day_plan_state_check CHECK(state IN ('pending','active','completed','blocked'));
ALTER TABLE public.work_station_tickets ALTER COLUMN card_id DROP NOT NULL;
ALTER TABLE public.work_station_tickets ADD COLUMN credential_version text;
ALTER TABLE public.work_station_tickets ADD COLUMN credential_method text NOT NULL DEFAULT 'manual' CHECK(credential_method IN ('manual','nfc','pin'));
ALTER TABLE public.work_station_tickets ADD CONSTRAINT work_ticket_credential_required CHECK((credential_method='pin' AND credential_version IS NOT NULL) OR (credential_method<>'pin' AND card_id IS NOT NULL));

CREATE FUNCTION ase_private.close_work(p_plan uuid,p_reason text,p_kind text,p_incident uuid DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql SET search_path='' AS $$
DECLARE p public.work_day_plan%ROWTYPE;c uuid;ts timestamptz:=clock_timestamp();u uuid;
BEGIN
 IF length(btrim(p_reason)) NOT BETWEEN 5 AND 2000 THEN RAISE EXCEPTION 'Escribe un motivo de entre 5 y 2000 caracteres'; END IF;
 SELECT user_id INTO u FROM public.work_day_plan WHERE id=p_plan;
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=u AND membership_status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE id=p_plan FOR UPDATE;
 IF p.state IS DISTINCT FROM 'active' THEN RAISE EXCEPTION 'La tarea ya no está en curso'; END IF;
 IF p_kind='admin_finish' THEN PERFORM public.work_assert_admin();
 ELSIF p_kind='incident_block' THEN
  IF p.user_id IS DISTINCT FROM auth.uid() OR p_incident IS NULL THEN RAISE EXCEPTION 'Incidencia no autorizada'; END IF;
 ELSE RAISE EXCEPTION 'Tipo de cierre no válido'; END IF;
 PERFORM set_config('ase.tablet_write','on',true);
 UPDATE public.checkins SET checkout_time=ts WHERE work_plan_id=p.id AND user_id=p.user_id AND checkout_time IS NULL AND checkin_time<=ts RETURNING id INTO c;
 IF c IS NULL THEN RAISE EXCEPTION 'No se encontró el fichaje activo'; END IF;
 UPDATE public.work_day_plan SET state=CASE WHEN p_kind='admin_finish' THEN 'completed' ELSE 'blocked' END,finished_at=ts WHERE id=p.id;
 INSERT INTO public.work_task_closures(plan_id,checkin_id,actor_id,reason,kind,incident_id) VALUES(p.id,c,auth.uid(),btrim(p_reason),p_kind,p_incident);
 UPDATE public.work_station_tickets SET expires_at=ts WHERE plan_id=p.id AND result IS NULL;
 PERFORM set_config('ase.tablet_write','off',true);
 RETURN c;
END $$;
REVOKE ALL ON FUNCTION ase_private.close_work(uuid,text,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION ase_private.close_work(uuid,text,text,uuid) TO ase_tenant_executor;

CREATE FUNCTION public.work_admin_finish(p_plan uuid,p_reason text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN PERFORM public.work_assert_admin();RETURN jsonb_build_object('checkin_id',ase_private.close_work(p_plan,p_reason,'admin_finish'));END $$;

CREATE FUNCTION public.work_area_directory() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL OR ase_private.current_org() IS NULL THEN RAISE EXCEPTION 'Inicia sesión'; END IF;
 RETURN jsonb_build_object('areas',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'name',a.name,'members',coalesce((SELECT jsonb_agg(m.user_id) FROM public.work_area_members m WHERE m.area_id=a.id),'[]'::jsonb)) ORDER BY a.name) FROM public.work_areas a WHERE a.active),'[]'::jsonb),
 'people',coalesce((SELECT jsonb_agg(jsonb_build_object('id',p.id,'full_name',p.full_name) ORDER BY p.full_name) FROM ase_private.employee_profiles p WHERE p.membership_status='active'),'[]'::jsonb));
END $$;
CREATE FUNCTION public.work_save_area(p_name text,p_members uuid[]) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE area uuid;u uuid;BEGIN
 PERFORM public.work_assert_admin();
 IF p_members IS NULL OR cardinality(p_members) NOT BETWEEN 1 AND 100 OR length(btrim(p_name)) NOT BETWEEN 2 AND 100 THEN RAISE EXCEPTION 'Escribe un área y selecciona responsables'; END IF;
 FOREACH u IN ARRAY p_members LOOP
  IF NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=u AND membership_status='active') THEN RAISE EXCEPTION 'Responsable no disponible en esta empresa'; END IF;
 END LOOP;
 INSERT INTO public.work_areas(name) VALUES(btrim(p_name)) ON CONFLICT(organization_id,name) DO UPDATE SET active=true RETURNING id INTO area;
 DELETE FROM public.work_area_members WHERE area_id=area;
 INSERT INTO public.work_area_members(area_id,user_id) SELECT area,unnest(p_members) ON CONFLICT DO NOTHING;
 RETURN area;
END $$;

GRANT USAGE ON SCHEMA storage TO ase_tenant_executor;
GRANT SELECT ON storage.objects TO ase_tenant_executor;
CREATE POLICY work_incident_attachment_executor ON storage.objects FOR SELECT TO ase_tenant_executor USING(bucket_id='task-files' AND split_part(name,'/',3)=auth.uid()::text AND public.work_can_file(name));

CREATE FUNCTION public.work_report_incident(p_task uuid,p_subject text,p_description text,p_user uuid DEFAULT NULL,p_area uuid DEFAULT NULL,p_block boolean DEFAULT false,p_files text[] DEFAULT '{}') RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE plan uuid;result uuid;path text;prefix text;BEGIN
 IF auth.uid() IS NULL OR NOT public.work_can_detail(p_task) OR p_block IS NULL THEN RAISE EXCEPTION 'Solo puedes reportar sobre una tarea disponible para ti'; END IF;
 IF p_user IS NULL AND p_area IS NULL THEN RAISE EXCEPTION 'Selecciona un área o responsable'; END IF;
 IF p_user IS NOT NULL AND NOT EXISTS(SELECT 1 FROM ase_private.employee_profiles WHERE id=p_user AND membership_status='active') THEN RAISE EXCEPTION 'Responsable no disponible'; END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas a JOIN public.work_area_members m ON m.area_id=a.id JOIN ase_private.employee_profiles u ON u.id=m.user_id AND u.membership_status='active' WHERE a.id=p_area AND a.active) THEN RAISE EXCEPTION 'Área sin responsables disponibles'; END IF;
 IF p_files IS NULL OR cardinality(p_files)>3 THEN RAISE EXCEPTION 'Adjunta hasta 3 imágenes'; END IF;
 prefix:='tasks/'||p_task::text||'/'||auth.uid()::text||'/';
 FOREACH path IN ARRAY p_files LOOP
  IF left(path,length(prefix))<>prefix OR path !~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp)$' OR NOT EXISTS(SELECT 1 FROM storage.objects WHERE bucket_id='task-files' AND name=path) THEN RAISE EXCEPTION 'Adjunto no disponible'; END IF;
 END LOOP;
 SELECT id INTO plan FROM public.work_day_plan WHERE task_id=p_task AND user_id=auth.uid() AND state='active';
 IF p_block AND plan IS NULL THEN RAISE EXCEPTION 'No tienes esta tarea en curso'; END IF;
 INSERT INTO public.work_incidents(task_id,plan_id,reporter_id,assigned_user,area_id,subject,description,blocks_work,attachments)
 VALUES(p_task,plan,auth.uid(),p_user,p_area,btrim(p_subject),btrim(p_description),p_block,p_files) RETURNING id INTO result;
 INSERT INTO public.work_notifications(user_id,incident_id,message)
 SELECT DISTINCT recipient,result,'Nueva incidencia: '||btrim(p_subject) FROM(
 SELECT p_user AS recipient WHERE p_user IS NOT NULL UNION SELECT m.user_id FROM public.work_area_members m JOIN ase_private.employee_profiles u ON u.id=m.user_id AND u.membership_status='active' WHERE m.area_id=p_area) x;
 IF p_block THEN PERFORM ase_private.close_work(plan,p_subject||': '||left(p_description,1500),'incident_block',result); END IF;
 RETURN result;
END $$;

CREATE FUNCTION public.work_incident_inbox() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL OR ase_private.current_org() IS NULL THEN RAISE EXCEPTION 'Inicia sesión'; END IF;
 RETURN jsonb_build_object('items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('task_title',t.title,'reporter',u.full_name,'assigned_name',v.full_name,'area_name',a.name,'can_manage',public.sec06_is_admin() OR i.assigned_user=auth.uid() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=auth.uid())) ORDER BY i.created_at DESC)
 FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=i.reporter_id LEFT JOIN ase_private.employee_profiles v ON v.id=i.assigned_user LEFT JOIN public.work_areas a ON a.id=i.area_id
 WHERE public.sec06_is_admin() OR i.reporter_id=auth.uid() OR i.assigned_user=auth.uid() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=auth.uid())),'[]'::jsonb),
 'notifications',coalesce((SELECT jsonb_agg(to_jsonb(n) ORDER BY n.created_at DESC) FROM (SELECT * FROM public.work_notifications WHERE user_id=auth.uid() ORDER BY created_at DESC LIMIT 100) n),'[]'::jsonb));
END $$;
CREATE FUNCTION public.work_update_incident(p_id uuid,p_state text,p_resolution text DEFAULT '') RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE i public.work_incidents%ROWTYPE;BEGIN
 SELECT * INTO i FROM public.work_incidents WHERE id=p_id FOR UPDATE;
 IF i.id IS NULL OR NOT coalesce(public.sec06_is_admin() OR i.assigned_user=auth.uid() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=auth.uid()),false) THEN RAISE EXCEPTION 'No puedes gestionar esta incidencia'; END IF;
 IF p_state NOT IN ('open','in_progress','resolved') OR p_state IS NULL OR p_resolution IS NULL OR length(p_resolution)>5000 OR (p_state='resolved' AND length(btrim(p_resolution))<5) THEN RAISE EXCEPTION 'Indica un estado y, al resolver, explica la solución'; END IF;
 UPDATE public.work_incidents SET state=p_state,resolution=btrim(p_resolution),updated_at=clock_timestamp() WHERE id=i.id;
 UPDATE public.work_notifications SET seen=true WHERE user_id=auth.uid() AND incident_id=i.id;
 INSERT INTO public.work_notifications(user_id,incident_id,message) VALUES(i.reporter_id,i.id,'Incidencia actualizada: '||i.subject);
END $$;
CREATE FUNCTION public.work_seen_notifications() RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$UPDATE public.work_notifications SET seen=true WHERE user_id=auth.uid()$$;

CREATE FUNCTION public.work_pin_settings(p_user uuid,p_pin text DEFAULT NULL,p_active boolean DEFAULT true) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE value text;BEGIN
 PERFORM public.work_assert_admin();
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND NOT is_admin AND membership_status='active' FOR UPDATE;
 IF NOT FOUND OR p_active IS NULL THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 IF NOT p_active THEN UPDATE public.work_personal_pins SET active=false WHERE user_id=p_user;RETURN jsonb_build_object('active',false);END IF;
 value:=coalesce(nullif(btrim(p_pin),''),lpad((('x'||encode(extensions.gen_random_bytes(4),'hex'))::bit(32)::bigint % 100000)::text,5,'0'));
 IF value !~ '^[0-9]{5}$' THEN RAISE EXCEPTION 'El PIN debe tener exactamente 5 dígitos'; END IF;
 INSERT INTO public.work_personal_pins(user_id,pin_hash) VALUES(p_user,extensions.crypt(value,extensions.gen_salt('bf',10)))
 ON CONFLICT(organization_id,user_id) DO UPDATE SET pin_hash=EXCLUDED.pin_hash,active=true,failures=0,locked_until=NULL,updated_at=clock_timestamp();
 RETURN jsonb_build_object('active',true,'pin',value);
END $$;
CREATE FUNCTION public.work_import_pins(p_rows jsonb,p_apply boolean DEFAULT false) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE row jsonb;u uuid;ids uuid[]:='{}';preview jsonb:='[]';errors jsonb:='[]';n integer:=0;BEGIN
 PERFORM public.work_assert_admin();
 IF p_rows IS NULL OR jsonb_typeof(p_rows)<>'array' OR jsonb_array_length(p_rows) NOT BETWEEN 1 AND 200 OR p_apply IS NULL THEN RAISE EXCEPTION 'Importa entre 1 y 200 empleados';END IF;
 FOR row IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
  n:=n+1;u:=NULL;
  SELECT id INTO u FROM ase_private.employee_profiles WHERE NOT is_admin AND membership_status='active' AND (id::text=row->>'employee' OR lower(email)=lower(row->>'employee'));
  IF u IS NULL OR u=ANY(ids) OR coalesce(row->>'pin','') !~ '^[0-9]{5}$' THEN errors:=errors||jsonb_build_object('row',n,'error','Empleado desconocido, duplicado o PIN distinto de 5 dígitos');
  ELSE ids:=array_append(ids,u);preview:=preview||jsonb_build_object('user_id',u,'employee',(SELECT full_name FROM ase_private.employee_profiles WHERE id=u),'row',n);END IF;
 END LOOP;
 IF p_apply AND jsonb_array_length(errors)>0 THEN RAISE EXCEPTION 'La importación tiene errores. Corrige la vista previa'; END IF;
 IF p_apply THEN n:=0;FOR row IN SELECT value FROM jsonb_array_elements(p_rows) LOOP n:=n+1;PERFORM public.work_pin_settings((preview->(n-1)->>'user_id')::uuid,row->>'pin',true);END LOOP;END IF;
 RETURN jsonb_build_object('preview',preview,'errors',errors,'applied',p_apply);
END $$;

CREATE FUNCTION public.work_station_people(p_station text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN PERFORM ase_private.bind_station(p_station);
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',u.id,'name',u.full_name) ORDER BY u.full_name) FROM public.work_personal_pins pin JOIN ase_private.employee_profiles u ON u.id=pin.user_id WHERE pin.active AND NOT u.is_admin AND u.membership_status='active'),'[]'::jsonb);END $$;

CREATE OR REPLACE FUNCTION public.work_station_identify_v2(p_station text, p_card text DEFAULT NULL, p_method text DEFAULT 'manual', p_user uuid DEFAULT NULL)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE s public.work_stations%ROWTYPE; c public.work_employee_cards%ROWTYPE; p public.work_day_plan%ROWTYPE;
 v_ticket uuid; v_action text:='none'; v_name text; v_title text; v_description text; pin public.work_personal_pins%ROWTYPE; attempt_row public.work_pin_attempts%ROWTYPE; selected_user uuid;
BEGIN
 PERFORM ase_private.bind_station(p_station);
 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;
 SELECT * INTO s FROM public.work_stations WHERE token_hash=public.work_hash(p_station) AND active FOR UPDATE;
 IF p_method IS NULL OR p_method NOT IN ('manual','nfc','pin') THEN RAISE EXCEPTION 'Método no válido';END IF;
 IF s.id IS NULL THEN RAISE EXCEPTION 'Punto no disponible';END IF;
 IF p_method='pin' THEN
  INSERT INTO public.work_pin_attempts(station_id) VALUES(s.id) ON CONFLICT DO NOTHING;
  SELECT * INTO attempt_row FROM public.work_pin_attempts WHERE station_id=s.id FOR UPDATE;
  IF attempt_row.window_start < clock_timestamp()-interval '15 minutes' THEN
   UPDATE public.work_pin_attempts SET attempts=0,window_start=clock_timestamp() WHERE station_id=s.id;attempt_row.attempts:=0;
  END IF;
  IF attempt_row.attempts>=20 THEN RETURN jsonb_build_object('error','Demasiados intentos en este punto. Espera 15 minutos.'); END IF;
  SELECT * INTO pin FROM public.work_personal_pins WHERE user_id=p_user FOR UPDATE;
  IF pin.locked_until>clock_timestamp() THEN RETURN jsonb_build_object('error','Identificación no disponible. Espera 15 minutos o consulta al administrador.');END IF;
  IF pin.user_id IS NULL OR NOT pin.active OR p_card IS NULL OR p_card !~ '^[0-9]{5}$' OR pin.pin_hash IS DISTINCT FROM extensions.crypt(p_card,pin.pin_hash) THEN
   UPDATE public.work_pin_attempts SET attempts=attempts+1 WHERE station_id=s.id;
   UPDATE public.work_personal_pins SET failures=failures+1,locked_until=CASE WHEN failures>=4 THEN clock_timestamp()+interval '15 minutes' ELSE locked_until END WHERE user_id=p_user;
   RETURN jsonb_build_object('error','Empleado o PIN no válido.');
  END IF;
  UPDATE public.work_personal_pins SET failures=0,locked_until=NULL WHERE user_id=p_user;
  selected_user:=pin.user_id;
 ELSE
  SELECT * INTO c FROM public.work_employee_cards WHERE token_hash=public.work_hash(p_card) AND active;
  selected_user:=c.user_id;
 END IF;
 IF s.id IS NULL OR selected_user IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto o tarjeta no disponible'; END IF;
 SELECT full_name INTO v_name FROM ase_private.employee_profiles WHERE id=selected_user AND is_admin IS FALSE AND membership_status='active';
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarjeta no disponible'; END IF;
 SELECT * INTO p FROM public.work_day_plan WHERE user_id=selected_user AND state='active';
 IF p.id IS NOT NULL THEN v_action:='finish';
 ELSE
  SELECT x.* INTO p FROM public.work_day_plan x WHERE x.user_id=selected_user AND x.work_date=public.work_today() AND x.state='pending'
   ORDER BY x.priority LIMIT 1;
  IF p.id IS NOT NULL THEN v_action:='start'; END IF;
 END IF;
 IF p.id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE user_id=selected_user AND task_id=p.task_id) THEN
  RAISE EXCEPTION 'La asignación cambió. Consulta al encargado';
 END IF;
 SELECT title,description INTO v_title,v_description FROM public.tasks WHERE id=p.task_id;
 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE station_id=s.id AND result IS NULL;
 DELETE FROM public.work_station_tickets WHERE expires_at<now()-interval '7 days';
 INSERT INTO public.work_station_tickets(station_id,card_id,user_id,plan_id,expected_action,credential_method,credential_version)
 VALUES(s.id,c.id,selected_user,p.id,v_action,p_method,pin.pin_hash) RETURNING id INTO v_ticket;
 RETURN jsonb_build_object('ticket',v_ticket,'employee',v_name,'title',v_title,'description',v_description,'action',v_action,
  'started_at',p.started_at,'reader_mode',s.reader_mode);
END $function$;
CREATE OR REPLACE FUNCTION public.work_station_confirm_v2(p_station text, p_ticket uuid, p_action text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE s public.work_stations%ROWTYPE; k public.work_station_tickets%ROWTYPE; p public.work_day_plan%ROWTYPE;

 v_checkin uuid; v_time timestamptz:=clock_timestamp(); v_result jsonb;

BEGIN
 PERFORM ase_private.bind_station(p_station);

 PERFORM 1 FROM public.work_settings WHERE singleton FOR SHARE;

 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;

 SELECT * INTO s FROM public.work_stations WHERE token_hash=public.work_hash(p_station) AND active FOR SHARE;

 IF s.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto no disponible'; END IF;

 SELECT * INTO k FROM public.work_station_tickets WHERE id=p_ticket AND station_id=s.id FOR UPDATE;

 IF k.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Vuelve a pasar tu tarjeta'; END IF;

 IF p_action IS NULL OR p_action NOT IN ('start','finish') OR p_action<>k.expected_action THEN RAISE EXCEPTION 'Acción no válida'; END IF;

 IF k.result IS NOT NULL THEN RETURN k.result; END IF;

 IF k.expires_at<=v_time THEN RAISE EXCEPTION 'La identificación ha caducado. Vuelve a pasar tu tarjeta'; END IF;

 IF k.credential_method='pin' THEN
  PERFORM 1 FROM public.work_personal_pins WHERE user_id=k.user_id AND active AND pin_hash=k.credential_version FOR SHARE;
 ELSE
  PERFORM 1 FROM public.work_employee_cards WHERE id=k.card_id AND user_id=k.user_id AND active FOR SHARE;
 END IF;

 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarjeta desactivada'; END IF;

 PERFORM 1 FROM ase_private.employee_profiles WHERE id=k.user_id AND is_admin IS FALSE AND membership_status='active' FOR UPDATE;

 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;

 SELECT * INTO p FROM public.work_day_plan WHERE id=k.plan_id AND user_id=k.user_id FOR UPDATE;

 IF p.id IS NULL OR NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=p.task_id AND user_id=p.user_id) THEN RAISE EXCEPTION 'Asignación no disponible'; END IF;

 PERFORM set_config('ase.tablet_write','on',true);

 IF p_action='start' THEN

  IF p.state<>'pending' OR p.work_date<>public.work_today()

  OR EXISTS(SELECT 1 FROM public.work_day_plan WHERE user_id=p.user_id AND state='active')

  OR EXISTS(SELECT 1 FROM public.checkins WHERE user_id=p.user_id AND checkout_time IS NULL)

  OR EXISTS(SELECT 1 FROM public.work_day_plan WHERE user_id=p.user_id AND work_date=p.work_date AND state='pending' AND priority<p.priority) THEN

   RAISE EXCEPTION 'El estado cambió. Vuelve a pasar tu tarjeta';

  END IF;

  -- La prueba del lector se registra honestamente como manual, nunca como NFC físico.

  INSERT INTO public.checkins(task_id,user_id,checkin_time,checkin_method,location,work_plan_id,work_station_id,employee_card_id)

  VALUES(p.task_id,p.user_id,v_time,CASE WHEN k.credential_method='nfc' THEN 'nfc' ELSE 'manual' END,CASE WHEN k.credential_method='pin' THEN 'Tablet · PIN personal' WHEN k.credential_method='nfc' THEN 'Tablet · lectura NFC' ELSE 'Tablet · lectura por código' END,p.id,s.id,k.card_id) RETURNING id INTO v_checkin;

  UPDATE public.work_day_plan SET state='active',started_at=v_time WHERE id=p.id;

 ELSE

  IF p.state<>'active' THEN RAISE EXCEPTION 'La tarea ya no está en curso. Vuelve a pasar tu tarjeta'; END IF;

  UPDATE public.checkins SET checkout_time=v_time WHERE work_plan_id=p.id AND user_id=p.user_id AND checkout_time IS NULL AND checkin_time<=v_time RETURNING id INTO v_checkin;

  IF v_checkin IS NULL THEN RAISE EXCEPTION 'No se pudo confirmar la salida'; END IF;

  UPDATE public.work_day_plan SET state='completed',finished_at=v_time WHERE id=p.id;

 END IF;

 PERFORM set_config('ase.tablet_write','off',true);

 v_result:=jsonb_build_object('success',true,'action',p_action,'checkin_id',v_checkin,'time',v_time);

 UPDATE public.work_station_tickets SET result=v_result WHERE id=k.id;

 RETURN v_result;

END $function$;
CREATE OR REPLACE FUNCTION public.work_station_day_v2(p_station text, p_ticket uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid; v_items jsonb; v_name text;
BEGIN
 PERFORM ase_private.bind_station(p_station);
 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;
 SELECT k.user_id,u.full_name INTO v_user,v_name
 FROM public.work_station_tickets k
 JOIN public.work_stations s ON s.id=k.station_id AND s.active
 LEFT JOIN public.work_employee_cards c ON c.id=k.card_id AND c.active AND c.user_id=k.user_id
 JOIN ase_private.employee_profiles u ON u.id=k.user_id AND u.is_admin IS FALSE AND u.membership_status='active'
 WHERE ((k.credential_method<>'pin' AND c.id IS NOT NULL) OR (k.credential_method='pin' AND EXISTS(SELECT 1 FROM public.work_personal_pins pin WHERE pin.user_id=k.user_id AND pin.active AND pin.pin_hash=k.credential_version))) AND k.id=p_ticket AND s.token_hash=public.work_hash(p_station) AND k.expires_at>clock_timestamp();
 IF v_user IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Vuelve a identificarte para consultar tus tareas'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'title',t.title,'state',p.state,
  'priority',p.priority,'work_date',p.work_date) || public.work_deadline(p.work_date,p.state,p.finished_at) ORDER BY p.work_date,p.priority),'[]'::jsonb)
 INTO v_items FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id
 WHERE p.user_id=v_user AND (p.work_date=public.work_today() OR p.state='active' OR (p.work_date<public.work_today() AND p.state='pending'))
 AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=p.task_id AND a.user_id=p.user_id);
 RETURN jsonb_build_object('employee',v_name,'date',public.work_today(),'items',v_items);
END $function$;
CREATE OR REPLACE FUNCTION public.work_my_day_v2()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_items jsonb;

BEGIN

 IF auth.uid() IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'task_id',p.task_id,'title',t.title,'state',p.state,

  'priority',p.priority,'work_date',p.work_date,'started_at',p.started_at,'finished_at',p.finished_at,

  'can_open',p.state='active' AND public.work_can_detail(p.task_id)) || public.work_deadline(p.work_date,p.state,p.finished_at) ORDER BY p.work_date,p.priority),'[]'::jsonb)

 INTO v_items FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id

 WHERE p.user_id=auth.uid() AND (p.work_date=public.work_today() OR p.state='active' OR (p.work_date<public.work_today() AND p.state='pending'))

 AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=p.task_id AND a.user_id=p.user_id);

 RETURN jsonb_build_object('date',public.work_today(),'items',v_items);

END $function$;

CREATE FUNCTION public.work_search(p_terms text[] DEFAULT '{}',p_state text DEFAULT NULL,p_kind text DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE tasks jsonb;people jsonb;incidents jsonb;BEGIN
 IF auth.uid() IS NULL OR ase_private.current_org() IS NULL THEN RAISE EXCEPTION 'Inicia sesión';END IF;
 IF p_terms IS NULL OR cardinality(p_terms)>10 OR EXISTS(SELECT 1 FROM unnest(p_terms) t WHERE length(t)>80) OR (p_state IS NOT NULL AND p_state NOT IN ('active','pending','completed','blocked','open','in_progress','resolved')) OR (p_kind IS NOT NULL AND p_kind NOT IN ('tasks','people','incidents')) THEN RAISE EXCEPTION 'Búsqueda no válida'; END IF;
 SELECT coalesce(jsonb_agg(x),'[]'::jsonb) INTO tasks FROM (
  SELECT p.id,p.task_id,t.title,u.full_name AS employee,p.state,p.work_date,public.work_can_detail(t.id) AS can_open
  FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id JOIN ase_private.employee_profiles u ON u.id=p.user_id
  WHERE (public.work_has_permission('planning.view') OR public.sec06_is_admin() OR p.user_id=auth.uid())
  AND (p_state IS NULL OR p.state=p_state) AND (p_kind IS NULL OR p_kind='tasks')
  AND NOT EXISTS(SELECT 1 FROM unnest(p_terms) term WHERE position(term IN translate(lower(t.title||' '||u.full_name),'áéíóúüñ','aeiouun'))=0)
  ORDER BY (p.state='active') DESC,p.work_date DESC,p.priority LIMIT 100) x;
 SELECT tasks||coalesce(jsonb_agg(x),'[]'::jsonb) INTO tasks FROM (
  SELECT t.id,t.id AS task_id,t.title,names.employee,
   CASE t.status WHEN 'in_progress' THEN 'active' ELSE t.status::text END AS state,NULL::date AS work_date,public.work_can_detail(t.id) AS can_open
  FROM public.tasks t CROSS JOIN LATERAL(SELECT string_agg(u.full_name,', ' ORDER BY u.full_name) AS employee FROM public.task_assignments a JOIN ase_private.employee_profiles u ON u.id=a.user_id WHERE a.task_id=t.id AND (public.work_has_permission('tasks.view') OR a.user_id=auth.uid())) names
  WHERE NOT EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.task_id=t.id)
  AND (public.work_has_permission('tasks.view') OR EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=t.id AND a.user_id=auth.uid()))
  AND (p_kind IS NULL OR p_kind='tasks') AND (p_state IS NULL OR (CASE t.status WHEN 'in_progress' THEN 'active' ELSE t.status::text END)=p_state)
  AND NOT EXISTS(SELECT 1 FROM unnest(p_terms) term WHERE position(term IN translate(lower(t.title||' '||coalesce(names.employee,'')),'áéíóúüñ','aeiouun'))=0)
  ORDER BY t.created_at DESC LIMIT 100) x;
 SELECT coalesce(jsonb_agg(value),'[]'::jsonb) INTO tasks FROM (SELECT value FROM jsonb_array_elements(tasks) WITH ORDINALITY e(value,n) ORDER BY n LIMIT 100) x;
 SELECT coalesce(jsonb_agg(x),'[]'::jsonb) INTO people FROM (
  SELECT u.id,u.full_name FROM ase_private.employee_profiles u WHERE public.sec06_is_admin() AND u.membership_status='active'
  AND p_state IS NULL AND (p_kind IS NULL OR p_kind='people')
  AND NOT EXISTS(SELECT 1 FROM unnest(p_terms) term WHERE position(term IN translate(lower(u.full_name||' '||u.email),'áéíóúüñ','aeiouun'))=0)
  ORDER BY full_name LIMIT 100) x;
 SELECT coalesce(jsonb_agg(x),'[]'::jsonb) INTO incidents FROM (
  SELECT i.id,i.subject,i.state,t.title FROM public.work_incidents i JOIN public.tasks t ON t.id=i.task_id
  WHERE (public.sec06_is_admin() OR i.reporter_id=auth.uid() OR i.assigned_user=auth.uid() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=auth.uid()))
  AND (p_state IS NULL OR i.state=CASE p_state WHEN 'pending' THEN 'open' WHEN 'active' THEN 'in_progress' WHEN 'completed' THEN 'resolved' ELSE p_state END)
  AND (p_kind IS NULL OR p_kind='incidents')
  AND NOT EXISTS(SELECT 1 FROM unnest(p_terms) term WHERE position(term IN translate(lower(i.subject||' '||i.description||' '||t.title),'áéíóúüñ','aeiouun'))=0)
  ORDER BY i.created_at DESC LIMIT 100) x;
 RETURN jsonb_build_object('tasks',tasks,'people',people,'incidents',incidents,'limit_per_group',100);
END $$;

CREATE FUNCTION public.work_incident_file_allowed(p_path text) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT auth.uid() IS NOT NULL AND EXISTS(SELECT 1 FROM public.work_incidents i WHERE p_path=ANY(i.attachments)
 AND (public.sec06_is_admin() OR i.reporter_id=auth.uid() OR i.assigned_user=auth.uid() OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=i.area_id AND m.user_id=auth.uid())))
$$;
CREATE POLICY work_incident_file_read ON storage.objects FOR SELECT TO authenticated USING(bucket_id='task-files' AND public.work_incident_file_allowed(name));
ALTER POLICY work_files_read ON storage.objects USING(bucket_id<>'task-files' OR public.work_can_file(name) OR public.work_incident_file_allowed(name));


CREATE FUNCTION public.work_usability_ready() RETURNS boolean LANGUAGE sql STABLE SET search_path='' AS $$SELECT true$$;
CREATE FUNCTION public.work_open_tasks() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN PERFORM public.work_assert_admin();RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',p.id,'title',t.title,'employee',u.full_name) ORDER BY p.started_at) FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id JOIN ase_private.employee_profiles u ON u.id=p.user_id WHERE p.state='active'),'[]'::jsonb);END $$;


CREATE FUNCTION public.work_pin_overview() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$BEGIN PERFORM public.work_assert_admin();RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('user_id',user_id,'active',active,'updated_at',updated_at)) FROM public.work_personal_pins),'[]'::jsonb);END $$;


CREATE FUNCTION public.work_closure_history() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN PERFORM public.work_assert_admin();RETURN coalesce((SELECT jsonb_agg(x ORDER BY x.created_at DESC) FROM(SELECT c.id,c.kind,c.reason,c.created_at,t.title,u.full_name AS employee,a.full_name AS actor FROM public.work_task_closures c JOIN public.work_day_plan p ON p.id=c.plan_id JOIN public.tasks t ON t.id=p.task_id LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id LEFT JOIN ase_private.employee_profiles a ON a.id=c.actor_id ORDER BY c.created_at DESC LIMIT 50)x),'[]'::jsonb);END $$;

-- No change to existing RPC signatures or their security snapshot.
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
DO $$ DECLARE f record;BEGIN
 FOR f IN SELECT p.oid::regprocedure AS signature FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname=ANY(ARRAY['work_admin_finish','work_area_directory','work_save_area','work_report_incident','work_incident_inbox','work_update_incident','work_seen_notifications','work_pin_settings','work_import_pins','work_station_people','work_station_identify_v2','work_station_confirm_v2','work_station_day_v2','work_my_day_v2','work_search','work_incident_file_allowed','work_usability_ready','work_open_tasks','work_pin_overview','work_closure_history']) LOOP
  EXECUTE format('ALTER FUNCTION %s OWNER TO ase_tenant_executor',f.signature);
  EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC,anon,authenticated',f.signature);
  EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated',f.signature);
 END LOOP;
END $$;
GRANT EXECUTE ON FUNCTION public.work_usability_ready() TO anon;
GRANT EXECUTE ON FUNCTION public.work_station_people(text),public.work_station_identify_v2(text,text,text,uuid),public.work_station_confirm_v2(text,uuid,text),public.work_station_day_v2(text,uuid) TO anon;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
