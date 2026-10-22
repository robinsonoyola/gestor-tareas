-- Exact public business schema captured 2026-10-22. Fresh database only, NOT for the existing project.

SET search_path=public,pg_catalog;

CREATE TABLE public."checkins" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "task_id" uuid,
 "user_id" uuid,
 "checkin_time" timestamp with time zone DEFAULT now(),
 "location" text,
 "latitude" numeric(10,8),
 "longitude" numeric(11,8),
 "qr_code" text,
 "checkout_time" timestamp with time zone,
 "checkin_method" character varying(20) DEFAULT 'manual'::character varying,
 "nfc_card_id" uuid,
 "work_plan_id" uuid,
 "work_station_id" uuid,
 "employee_card_id" uuid
);

CREATE TABLE public."nfc_cards" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "card_uid" character varying(255) NOT NULL,
 "card_name" character varying(100),
 "task_id" uuid,
 "is_active" boolean DEFAULT true,
 "created_at" timestamp with time zone DEFAULT now(),
 "assigned_at" timestamp with time zone,
 "notes" text
);

CREATE TABLE public."task_access_codes" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "task_id" uuid NOT NULL,
 "access_code" text NOT NULL,
 "created_at" timestamp with time zone DEFAULT now(),
 "expires_at" timestamp with time zone,
 "is_active" boolean DEFAULT true,
 "created_by" uuid
);

CREATE TABLE public."task_assignments" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "task_id" uuid,
 "user_id" uuid,
 "assigned_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE public."task_checkin_config" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "task_id" uuid,
 "nfc_enabled" boolean DEFAULT false,
 "qr_enabled" boolean DEFAULT true,
 "manual_enabled" boolean DEFAULT true,
 "created_at" timestamp with time zone DEFAULT now(),
 "updated_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE public."task_comments" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "task_id" uuid NOT NULL,
 "user_id" uuid NOT NULL,
 "comment" text NOT NULL,
 "image_url" text,
 "video_url" text,
 "created_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE public."tasks" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "title" text NOT NULL,
 "description" text,
 "status" text DEFAULT 'pending'::text,
 "schedule_date" date,
 "schedule_type" text,
 "schedule_interval" integer,
 "schedule_days" text,
 "expected_latitude" numeric(10,8),
 "expected_longitude" numeric(11,8),
 "location_radius" integer DEFAULT 50,
 "qr_code" text,
 "last_checkin" timestamp with time zone,
 "incident_description" text,
 "incident_image" text,
 "checkin_location" text,
 "checkin_latitude" numeric(10,8),
 "checkin_longitude" numeric(11,8),
 "created_at" timestamp with time zone DEFAULT now(),
 "location" text
);

CREATE TABLE public."users" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "email" text NOT NULL,
 "full_name" text NOT NULL,
 "whatsapp" text,
 "is_admin" boolean DEFAULT false,
 "created_at" timestamp with time zone DEFAULT now()
);

CREATE TABLE public."work_day_plan" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "user_id" uuid NOT NULL,
 "task_id" uuid NOT NULL,
 "work_date" date NOT NULL,
 "priority" integer NOT NULL,
 "state" text DEFAULT 'pending'::text NOT NULL,
 "started_at" timestamp with time zone,
 "finished_at" timestamp with time zone,
 "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public."work_employee_card_keys" (
 "card_id" uuid NOT NULL,
 "token" text NOT NULL,
 "saved_at" timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);

CREATE TABLE public."work_employee_cards" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "user_id" uuid NOT NULL,
 "label" text NOT NULL,
 "token_hash" text NOT NULL,
 "active" boolean DEFAULT true NOT NULL,
 "created_at" timestamp with time zone DEFAULT now() NOT NULL,
 "archived_at" timestamp with time zone
);

CREATE TABLE public."work_employee_roles" (
 "user_id" uuid NOT NULL,
 "role_id" uuid NOT NULL
);

CREATE TABLE public."work_roles" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "name" text NOT NULL,
 "description" text DEFAULT ''::text NOT NULL,
 "active" boolean DEFAULT true NOT NULL,
 "created_at" timestamp with time zone DEFAULT now() NOT NULL,
 "permissions" text[] DEFAULT '{}'::text[] NOT NULL
);

CREATE TABLE public."work_settings" (
 "singleton" boolean DEFAULT true NOT NULL,
 "enabled" boolean DEFAULT false NOT NULL
);

CREATE TABLE public."work_station_keys" (
 "station_id" uuid NOT NULL,
 "token" text NOT NULL,
 "saved_at" timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);

CREATE TABLE public."work_station_tickets" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "station_id" uuid NOT NULL,
 "card_id" uuid NOT NULL,
 "user_id" uuid NOT NULL,
 "plan_id" uuid,
 "expected_action" text NOT NULL,
 "expires_at" timestamp with time zone DEFAULT (now() + '00:01:00'::interval) NOT NULL,
 "result" jsonb
);

CREATE TABLE public."work_stations" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "name" text NOT NULL,
 "token_hash" text NOT NULL,
 "active" boolean DEFAULT true NOT NULL,
 "reader_mode" text DEFAULT 'simulation'::text NOT NULL,
 "created_at" timestamp with time zone DEFAULT now() NOT NULL,
 "archived_at" timestamp with time zone
);

ALTER TABLE public."checkins" ADD CONSTRAINT "checkins_pkey" PRIMARY KEY (id);

ALTER TABLE public."nfc_cards" ADD CONSTRAINT "nfc_cards_pkey" PRIMARY KEY (id);

ALTER TABLE public."task_access_codes" ADD CONSTRAINT "task_access_codes_pkey" PRIMARY KEY (id);

ALTER TABLE public."task_assignments" ADD CONSTRAINT "task_assignments_pkey" PRIMARY KEY (id);

ALTER TABLE public."task_checkin_config" ADD CONSTRAINT "task_checkin_config_pkey" PRIMARY KEY (id);

ALTER TABLE public."task_comments" ADD CONSTRAINT "task_comments_pkey" PRIMARY KEY (id);

ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_pkey" PRIMARY KEY (id);

ALTER TABLE public."users" ADD CONSTRAINT "users_pkey" PRIMARY KEY (id);

ALTER TABLE public."work_day_plan" ADD CONSTRAINT "work_day_plan_pkey" PRIMARY KEY (id);

ALTER TABLE public."work_employee_card_keys" ADD CONSTRAINT "work_employee_card_keys_pkey" PRIMARY KEY (card_id);

ALTER TABLE public."work_employee_cards" ADD CONSTRAINT "work_employee_cards_pkey" PRIMARY KEY (id);

ALTER TABLE public."work_employee_roles" ADD CONSTRAINT "work_employee_roles_pkey" PRIMARY KEY (user_id);

ALTER TABLE public."work_roles" ADD CONSTRAINT "work_roles_pkey" PRIMARY KEY (id);

ALTER TABLE public."work_settings" ADD CONSTRAINT "work_settings_pkey" PRIMARY KEY (singleton);

ALTER TABLE public."work_station_keys" ADD CONSTRAINT "work_station_keys_pkey" PRIMARY KEY (station_id);

ALTER TABLE public."work_station_tickets" ADD CONSTRAINT "work_station_tickets_pkey" PRIMARY KEY (id);

ALTER TABLE public."work_stations" ADD CONSTRAINT "work_stations_pkey" PRIMARY KEY (id);

ALTER TABLE public."nfc_cards" ADD CONSTRAINT "nfc_cards_card_uid_key" UNIQUE (card_uid);

ALTER TABLE public."task_access_codes" ADD CONSTRAINT "task_access_codes_access_code_key" UNIQUE (access_code);

ALTER TABLE public."task_assignments" ADD CONSTRAINT "task_assignments_task_id_user_id_key" UNIQUE (task_id, user_id);

ALTER TABLE public."task_checkin_config" ADD CONSTRAINT "task_checkin_config_task_id_key" UNIQUE (task_id);

ALTER TABLE public."users" ADD CONSTRAINT "users_email_key" UNIQUE (email);

ALTER TABLE public."work_day_plan" ADD CONSTRAINT "work_day_plan_user_id_task_id_work_date_key" UNIQUE (user_id, task_id, work_date);

ALTER TABLE public."work_day_plan" ADD CONSTRAINT "work_day_plan_user_id_work_date_priority_key" UNIQUE (user_id, work_date, priority) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE public."work_employee_cards" ADD CONSTRAINT "work_employee_cards_token_hash_key" UNIQUE (token_hash);

ALTER TABLE public."work_stations" ADD CONSTRAINT "work_stations_token_hash_key" UNIQUE (token_hash);

ALTER TABLE public."checkins" ADD CONSTRAINT "checkins_checkin_method_check" CHECK (checkin_method::text = ANY (ARRAY['nfc'::character varying, 'qr'::character varying, 'manual'::character varying]::text[]));

ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_status_check" CHECK (status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'completed'::text]));

ALTER TABLE public."work_day_plan" ADD CONSTRAINT "work_day_plan_priority_check" CHECK (priority > 0);

ALTER TABLE public."work_day_plan" ADD CONSTRAINT "work_day_plan_state_check" CHECK (state = ANY (ARRAY['pending'::text, 'active'::text, 'completed'::text]));

ALTER TABLE public."work_employee_cards" ADD CONSTRAINT "work_archived_card_inactive" CHECK (archived_at IS NULL OR active = false);

ALTER TABLE public."work_employee_cards" ADD CONSTRAINT "work_employee_cards_label_check" CHECK (length(label) >= 1 AND length(label) <= 100);

ALTER TABLE public."work_roles" ADD CONSTRAINT "work_roles_description_check" CHECK (length(description) <= 500);

ALTER TABLE public."work_roles" ADD CONSTRAINT "work_roles_name_check" CHECK (length(TRIM(BOTH FROM name)) >= 1 AND length(TRIM(BOTH FROM name)) <= 80);

ALTER TABLE public."work_settings" ADD CONSTRAINT "work_settings_singleton_check" CHECK (singleton);

ALTER TABLE public."work_station_tickets" ADD CONSTRAINT "work_station_tickets_expected_action_check" CHECK (expected_action = ANY (ARRAY['start'::text, 'finish'::text, 'none'::text]));

ALTER TABLE public."work_stations" ADD CONSTRAINT "work_archived_station_inactive" CHECK (archived_at IS NULL OR active = false);

ALTER TABLE public."work_stations" ADD CONSTRAINT "work_stations_name_check" CHECK (length(name) >= 1 AND length(name) <= 100);

ALTER TABLE public."work_stations" ADD CONSTRAINT "work_stations_reader_mode_check" CHECK (reader_mode = 'simulation'::text);

ALTER TABLE public."checkins" ADD CONSTRAINT "checkins_employee_card_id_fkey" FOREIGN KEY (employee_card_id) REFERENCES work_employee_cards(id);

ALTER TABLE public."checkins" ADD CONSTRAINT "checkins_nfc_card_id_fkey" FOREIGN KEY (nfc_card_id) REFERENCES nfc_cards(id);

ALTER TABLE public."checkins" ADD CONSTRAINT "checkins_task_id_fkey" FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;

ALTER TABLE public."checkins" ADD CONSTRAINT "checkins_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE public."checkins" ADD CONSTRAINT "checkins_work_plan_id_fkey" FOREIGN KEY (work_plan_id) REFERENCES work_day_plan(id);

ALTER TABLE public."checkins" ADD CONSTRAINT "checkins_work_station_id_fkey" FOREIGN KEY (work_station_id) REFERENCES work_stations(id);

ALTER TABLE public."nfc_cards" ADD CONSTRAINT "nfc_cards_task_id_fkey" FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL;

ALTER TABLE public."task_access_codes" ADD CONSTRAINT "task_access_codes_created_by_fkey" FOREIGN KEY (created_by) REFERENCES users(id);

ALTER TABLE public."task_access_codes" ADD CONSTRAINT "task_access_codes_task_id_fkey" FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;

ALTER TABLE public."task_assignments" ADD CONSTRAINT "task_assignments_task_id_fkey" FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;

ALTER TABLE public."task_assignments" ADD CONSTRAINT "task_assignments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE public."task_checkin_config" ADD CONSTRAINT "task_checkin_config_task_id_fkey" FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;

ALTER TABLE public."task_comments" ADD CONSTRAINT "task_comments_task_id_fkey" FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;

ALTER TABLE public."task_comments" ADD CONSTRAINT "task_comments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE public."work_day_plan" ADD CONSTRAINT "work_day_plan_task_id_fkey" FOREIGN KEY (task_id) REFERENCES tasks(id);

ALTER TABLE public."work_day_plan" ADD CONSTRAINT "work_day_plan_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE public."work_employee_card_keys" ADD CONSTRAINT "work_employee_card_keys_card_id_fkey" FOREIGN KEY (card_id) REFERENCES work_employee_cards(id);

ALTER TABLE public."work_employee_cards" ADD CONSTRAINT "work_employee_cards_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE public."work_employee_roles" ADD CONSTRAINT "work_employee_roles_role_id_fkey" FOREIGN KEY (role_id) REFERENCES work_roles(id) ON DELETE RESTRICT;

ALTER TABLE public."work_employee_roles" ADD CONSTRAINT "work_employee_roles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE public."work_station_keys" ADD CONSTRAINT "work_station_keys_station_id_fkey" FOREIGN KEY (station_id) REFERENCES work_stations(id);

ALTER TABLE public."work_station_tickets" ADD CONSTRAINT "work_station_tickets_card_id_fkey" FOREIGN KEY (card_id) REFERENCES work_employee_cards(id);

ALTER TABLE public."work_station_tickets" ADD CONSTRAINT "work_station_tickets_plan_id_fkey" FOREIGN KEY (plan_id) REFERENCES work_day_plan(id) ON DELETE SET NULL;

ALTER TABLE public."work_station_tickets" ADD CONSTRAINT "work_station_tickets_station_id_fkey" FOREIGN KEY (station_id) REFERENCES work_stations(id);

ALTER TABLE public."work_station_tickets" ADD CONSTRAINT "work_station_tickets_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id);

CREATE INDEX idx_checkins_checkout_time ON public.checkins USING btree (checkout_time);

CREATE INDEX idx_checkins_method ON public.checkins USING btree (checkin_method);

CREATE UNIQUE INDEX sec02_checkins_one_open_per_task_user ON public.checkins USING btree (task_id, user_id) WHERE ((checkout_time IS NULL) AND (task_id IS NOT NULL) AND (user_id IS NOT NULL));

CREATE UNIQUE INDEX work_checkin_per_plan ON public.checkins USING btree (work_plan_id) WHERE (work_plan_id IS NOT NULL);

CREATE INDEX idx_nfc_cards_task ON public.nfc_cards USING btree (task_id) WHERE (is_active = true);

CREATE INDEX idx_nfc_cards_uid ON public.nfc_cards USING btree (card_uid);

CREATE INDEX idx_task_access_codes_access_code ON public.task_access_codes USING btree (access_code);

CREATE INDEX idx_task_access_codes_active ON public.task_access_codes USING btree (is_active);

CREATE INDEX idx_task_access_codes_task_id ON public.task_access_codes USING btree (task_id);

CREATE INDEX idx_task_comments_created_at ON public.task_comments USING btree (created_at DESC);

CREATE INDEX idx_task_comments_task_id ON public.task_comments USING btree (task_id);

CREATE INDEX idx_task_comments_user_id ON public.task_comments USING btree (user_id);

CREATE UNIQUE INDEX work_one_active_per_employee ON public.work_day_plan USING btree (user_id) WHERE (state = 'active'::text);

CREATE UNIQUE INDEX work_one_active_card_per_employee ON public.work_employee_cards USING btree (user_id) WHERE active;

CREATE UNIQUE INDEX work_role_name_unique ON public.work_roles USING btree (lower(TRIM(BOTH FROM name)));

SET check_function_bodies=off;

CREATE OR REPLACE FUNCTION public.create_task_checkin_config()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$

BEGIN

  INSERT INTO task_checkin_config (task_id, qr_enabled, manual_enabled)

  VALUES (NEW.id, true, true)

  ON CONFLICT (task_id) DO NOTHING;

  RETURN NEW;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.finish_manual_checkin(p_checkin_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE

 v_actor uuid := (SELECT auth.uid());

 v_row public.checkins%ROWTYPE;

 v_closed_at timestamptz;

BEGIN

 IF v_actor IS NULL OR (SELECT auth.role()) IS DISTINCT FROM 'authenticated' THEN

   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Se requiere sesion autenticada';

 END IF;

 SELECT * INTO v_row FROM public.checkins c

 WHERE c.id=p_checkin_id AND c.user_id=v_actor FOR UPDATE;

 IF NOT FOUND THEN

   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible para esta cuenta';

 END IF;

 IF v_row.checkin_method IS DISTINCT FROM 'manual' THEN

   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Este cierre solo permite fichajes manuales';

 END IF;

 PERFORM 1 FROM public.task_assignments a

 WHERE a.task_id=v_row.task_id AND a.user_id=v_actor FOR KEY SHARE;

 IF NOT FOUND THEN

   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No estas asignado a esta tarea';

 END IF;

 -- Reintentar devuelve la salida existente sin cambiar la hora.

 IF v_row.checkout_time IS NOT NULL THEN

   RETURN pg_catalog.json_build_object('success',true,'checkin_id',v_row.id,'checkout_time',v_row.checkout_time,'already_closed',true);

 END IF;

 -- Permite finalizar una sesion propia ya abierta aunque se haya deshabilitado

 -- manual_enabled despues de la entrada. No permite iniciar sesiones.

 IF v_row.checkin_time IS NULL OR v_row.checkin_time>pg_catalog.clock_timestamp() THEN

   RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='Hora de entrada no valida; requiere revision';

 END IF;

 v_closed_at:=pg_catalog.clock_timestamp();

 UPDATE public.checkins SET checkout_time=v_closed_at WHERE id=v_row.id;

 RETURN pg_catalog.json_build_object('success',true,'checkin_id',v_row.id,'checkout_time',v_closed_at,'already_closed',false);

END;

$function$
;

CREATE OR REPLACE FUNCTION public.generate_task_access_code(p_task_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE

 v_actor uuid := (SELECT auth.uid());

 v_code text;

BEGIN

 IF v_actor IS NULL OR (SELECT auth.role()) IS DISTINCT FROM 'authenticated' THEN

   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Se requiere una sesion de usuario autenticada';

 END IF;

 IF NOT EXISTS(SELECT 1 FROM public.users u WHERE u.id=v_actor AND u.is_admin IS TRUE) THEN

   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Solo administradores pueden generar codigos';

 END IF;

 IF p_task_id IS NULL THEN

   RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Tarea obligatoria';

 END IF;

 PERFORM 1 FROM public.tasks t WHERE t.id=p_task_id FOR KEY SHARE;

 IF NOT FOUND THEN

   RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Tarea no disponible';

 END IF;

 -- UUID aleatorio completo; no usar MD5(random()) truncado como credencial.

 v_code := 'TASK-' || pg_catalog.upper(pg_catalog.replace(pg_catalog.gen_random_uuid()::text,'-',''));

 INSERT INTO public.task_access_codes(id,task_id,access_code,created_by,created_at,is_active,expires_at)

 VALUES(pg_catalog.gen_random_uuid(),p_task_id,v_code,v_actor,pg_catalog.now(),true,NULL);

 RETURN v_code;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$

BEGIN

  INSERT INTO public.users (id, email, full_name, is_admin)

  VALUES (

    NEW.id,

    NEW.email,

    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario Nuevo'),

    FALSE

  );

  RETURN NEW;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.sec01_guard_is_admin()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$

BEGIN

  -- No confiar en campos enviados por el navegador.

  -- auth.role() procede del contexto JWT validado por la API.

  -- Los cambios reales por anon/authenticated quedan bloqueados incluso

  -- cuando la cuenta tiene is_admin=true en public.users.

  IF NEW.is_admin IS DISTINCT FROM OLD.is_admin

     AND (SELECT auth.role()) IN ('anon', 'authenticated') THEN

    RAISE EXCEPTION USING

      ERRCODE = '42501',

      MESSAGE = 'El rol de administrador solo puede cambiarse mediante un canal administrativo seguro';

  END IF;

  RETURN NEW;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.sec04_validate_comment_attachment()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$

DECLARE v_ref text; v_actor uuid := (SELECT auth.uid()); v_prefix text;

BEGIN

 IF (SELECT auth.role()) IN ('anon','authenticated') THEN

   IF v_actor IS NULL OR NEW.user_id IS DISTINCT FROM v_actor OR NEW.task_id IS NULL THEN

     RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Comentario no autorizado';

   END IF;

   IF TG_OP='UPDATE' THEN

     IF NEW.image_url IS NOT DISTINCT FROM OLD.image_url

       AND NEW.video_url IS NOT DISTINCT FROM OLD.video_url

       AND NEW.task_id IS NOT DISTINCT FROM OLD.task_id

       AND NEW.user_id IS NOT DISTINCT FROM OLD.user_id THEN

       RETURN NEW;

     END IF;

   END IF;

   v_prefix:='tasks/'||NEW.task_id::text||'/'||v_actor::text||'/';

   FOREACH v_ref IN ARRAY ARRAY[NEW.image_url,NEW.video_url] LOOP

     IF v_ref IS NOT NULL AND (

       pg_catalog.left(v_ref,pg_catalog.length(v_prefix))<>v_prefix

       OR v_ref !~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov)$'

     ) THEN

       RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La referencia debe pertenecer a tu subida de esta tarea';

     END IF;

   END LOOP;

 END IF;

 RETURN NEW;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.sec06_is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

 SELECT (SELECT auth.role())='authenticated'

   AND EXISTS(SELECT 1 FROM public.users u WHERE u.id=(SELECT auth.uid()) AND u.is_admin IS TRUE);

$function$
;

CREATE OR REPLACE FUNCTION public.sec06_task_actor_names(p_task_id uuid)
 RETURNS TABLE(id uuid, full_name text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

 IF NOT public.work_can_detail(p_task_id) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Abre solo tu tarea en curso'; END IF;

 RETURN QUERY SELECT * FROM public.work_legacy_actor_names(p_task_id);

END $function$
;

CREATE OR REPLACE FUNCTION public.sync_confirmed_auth_email()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

  IF NEW.email IS NOT NULL AND NEW.email IS DISTINCT FROM OLD.email THEN

    UPDATE public.users SET email = NEW.email WHERE id = NEW.id;

  END IF;

  RETURN NEW;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.validate_nfc_checkin(p_card_uid character varying, p_task_id uuid, p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE

 v_actor uuid := (SELECT auth.uid());

 v_card public.nfc_cards%ROWTYPE;

 v_last public.checkins%ROWTYPE;

 v_id uuid;

 v_type text;

BEGIN

 IF v_actor IS NULL OR (SELECT auth.role()) IS DISTINCT FROM 'authenticated' THEN

   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Se requiere una sesion de usuario autenticada';

 END IF;

 IF p_user_id IS DISTINCT FROM v_actor THEN

   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='No se permite fichar por otra persona';

 END IF;

 IF p_task_id IS NULL OR p_card_uid IS NULL OR pg_catalog.btrim(p_card_uid)='' THEN

   RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Tarea y tarjeta obligatorias';

 END IF;

 -- Serializa operaciones NFC de una misma tarea. El indice protege ademas

 -- contra duplicados que intenten crear otros caminos de escritura.

 PERFORM 1 FROM public.tasks t WHERE t.id=p_task_id FOR UPDATE;

 IF NOT FOUND THEN

   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Tarea no disponible o no autorizada';

 END IF;

 PERFORM 1 FROM public.task_assignments a

 WHERE a.task_id=p_task_id AND a.user_id=v_actor FOR KEY SHARE;

 IF NOT FOUND THEN

   RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Tarea no disponible o no autorizada';

 END IF;

 SELECT * INTO v_card FROM public.nfc_cards c

 WHERE c.card_uid=p_card_uid AND c.is_active IS TRUE AND c.task_id=p_task_id

 FOR SHARE;

 IF NOT FOUND THEN

   RETURN pg_catalog.json_build_object('success',false,'message','Tarjeta no valida para esta tarea');

 END IF;

 PERFORM 1 FROM public.task_checkin_config c

 WHERE c.task_id=p_task_id AND c.nfc_enabled IS TRUE FOR SHARE;

 IF NOT FOUND THEN

   RETURN pg_catalog.json_build_object('success',false,'message','Fichaje NFC no habilitado');

 END IF;

 SELECT * INTO v_last FROM public.checkins c

 WHERE c.task_id=p_task_id AND c.user_id=v_actor AND c.checkout_time IS NULL

 FOR UPDATE;

 IF FOUND THEN

   -- checkins.updated_at no existe en el esquema auditado.

   UPDATE public.checkins SET checkout_time=pg_catalog.now() WHERE id=v_last.id;

   v_id:=v_last.id;

   v_type:='checkout';

 ELSE

   INSERT INTO public.checkins(id,task_id,user_id,checkin_method,nfc_card_id,checkin_time)

   VALUES(pg_catalog.gen_random_uuid(),p_task_id,v_actor,'nfc',v_card.id,pg_catalog.now())

   RETURNING id INTO v_id;

   v_type:='checkin';

 END IF;

 RETURN pg_catalog.json_build_object(

   'success',true,'type',v_type,'checkin_id',v_id,

   'message',CASE WHEN v_type='checkin' THEN 'Fichaje iniciado con NFC' ELSE 'Fichaje finalizado con NFC' END

 );

END;

$function$
;

CREATE OR REPLACE FUNCTION public.work_admin_metrics(p_start date, p_end date, p_user uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_states jsonb; v_days jsonb; v_people jsonb; v_from timestamptz; v_to timestamptz;

BEGIN

 PERFORM public.work_assert_permission('reports.view');

 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 THEN RAISE EXCEPTION 'Selecciona hasta 366 días'; END IF;

 IF p_user IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.users WHERE id=p_user AND is_admin IS FALSE) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;

 v_from:=p_start::timestamp AT TIME ZONE 'Europe/Madrid';

 v_to:=(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid';

 SELECT jsonb_build_object('total',count(*),'pending',count(*) FILTER(WHERE state='pending'),'active',count(*) FILTER(WHERE state='active'),

  'completed',count(*) FILTER(WHERE state='completed'),'overdue',count(*) FILTER(WHERE state IN ('pending','active') AND work_date<public.work_today()),

  'late',count(*) FILTER(WHERE state='completed' AND finished_at >= (work_date+1)::timestamp AT TIME ZONE 'Europe/Madrid'))

 INTO v_states FROM public.work_day_plan WHERE work_date BETWEEN p_start AND p_end AND (p_user IS NULL OR user_id=p_user);

 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.date),'[]'::jsonb) INTO v_days FROM (

  SELECT d::date AS date,count(p.id) AS total,count(p.id) FILTER(WHERE p.state='completed') AS completed,

   count(p.id) FILTER(WHERE p.state IN ('pending','active') AND p.work_date<public.work_today()) AS overdue

  FROM generate_series(p_start::timestamp,p_end::timestamp,interval '1 day') d

  LEFT JOIN public.work_day_plan p ON p.work_date=d::date AND (p_user IS NULL OR p.user_id=p_user)

  GROUP BY d

 ) q;

 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.seconds DESC,q.name,q.id),'[]'::jsonb) INTO v_people FROM (

  SELECT u.id,u.full_name AS name,

   (SELECT count(*) FROM public.work_day_plan p WHERE p.user_id=u.id AND p.work_date BETWEEN p_start AND p_end) AS total,

   (SELECT count(*) FROM public.work_day_plan p WHERE p.user_id=u.id AND p.work_date BETWEEN p_start AND p_end AND p.state='completed') AS completed,

   (SELECT count(*) FROM public.work_day_plan p WHERE p.user_id=u.id AND p.work_date BETWEEN p_start AND p_end AND p.state IN ('pending','active') AND p.work_date<public.work_today()) AS overdue,

   (SELECT coalesce(sum(greatest(0,extract(epoch FROM least(coalesce(c.checkout_time,now()),v_to,now())-greatest(c.checkin_time,v_from)))),0) FROM public.checkins c

    WHERE c.user_id=u.id AND c.checkin_time<v_to AND coalesce(c.checkout_time,now())>v_from) AS seconds,

   (SELECT count(*) FROM public.checkins c WHERE c.user_id=u.id AND c.checkout_time IS NULL AND c.checkin_time<least(v_to,now()) AND now()>v_from) AS open

  FROM public.users u WHERE u.is_admin IS FALSE AND (p_user IS NULL OR u.id=p_user)

 ) q;

 RETURN jsonb_build_object('states',v_states,'days',v_days,'employees',v_people,'as_of',now());

END $function$
;

CREATE OR REPLACE FUNCTION public.work_admin_overview(p_user uuid, p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$



DECLARE v_plan jsonb; v_cards jsonb; v_stations jsonb; v_overdue jsonb;



BEGIN



 PERFORM public.work_assert_permission('planning.view');



 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'task_id',p.task_id,'title',t.title,'priority',p.priority,'state',p.state,'work_date',p.work_date) || public.work_deadline(p.work_date,p.state,p.finished_at) ORDER BY p.priority),'[]'::jsonb)



 INTO v_plan FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id WHERE p.user_id=p_user AND p.work_date=p_date;



 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'user_id',user_id,'label',label,'active',active)),'[]'::jsonb) INTO v_cards FROM public.work_employee_cards WHERE archived_at IS NULL;



 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'active',active,'reader_mode',reader_mode)),'[]'::jsonb) INTO v_stations FROM public.work_stations WHERE archived_at IS NULL;



 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'title',t.title,'work_date',p.work_date,'state',p.state) ORDER BY p.work_date,p.priority),'[]'::jsonb)

 INTO v_overdue FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id

 WHERE p.user_id=p_user AND p.work_date<public.work_today() AND p.state IN ('pending','active');

 RETURN jsonb_build_object('overdue',v_overdue,'enabled',public.work_mode(),'plan',v_plan,'cards',CASE WHEN public.sec06_is_admin() THEN v_cards ELSE '[]'::jsonb END,'stations',CASE WHEN public.sec06_is_admin() THEN v_stations ELSE '[]'::jsonb END);



END $function$
;

CREATE OR REPLACE FUNCTION public.work_admin_productivity(p_start date, p_end date, p_task uuid, p_user uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_from timestamptz; v_to timestamptz; result jsonb;

BEGIN

 PERFORM public.work_assert_permission('reports.view');

 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 THEN RAISE EXCEPTION 'Selecciona hasta 366 días'; END IF;

 IF p_task IS NULL OR NOT EXISTS(SELECT 1 FROM public.tasks WHERE id=p_task) THEN RAISE EXCEPTION 'Selecciona una actividad'; END IF;

 IF p_user IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.users WHERE id=p_user AND is_admin IS FALSE) THEN RAISE EXCEPTION 'Empleado no válido'; END IF;

 v_from:=p_start::timestamp AT TIME ZONE 'Europe/Madrid'; v_to:=(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid';

 WITH samples AS (

  SELECT c.id,c.user_id,u.full_name AS name,c.checkin_time,c.checkout_time,

   (c.checkout_time AT TIME ZONE 'Europe/Madrid')::date AS day,

   extract(epoch FROM c.checkout_time-c.checkin_time)::double precision AS seconds

  FROM public.checkins c JOIN public.users u ON u.id=c.user_id AND u.is_admin IS FALSE

  WHERE c.task_id=p_task AND (p_user IS NULL OR c.user_id=p_user)

   AND c.checkout_time>=v_from AND c.checkout_time<v_to AND c.checkin_time IS NOT NULL AND c.checkout_time>c.checkin_time

 ), people AS (

  SELECT user_id AS id,name,count(*) AS count,sum(seconds) AS total,avg(seconds) AS average,

   percentile_cont(0.5) WITHIN GROUP(ORDER BY seconds) AS median,min(seconds) AS minimum,max(seconds) AS maximum

  FROM samples GROUP BY user_id,name

 ), daily AS (

  SELECT day,count(*) AS count,avg(seconds) AS average FROM samples GROUP BY day

 ), recent AS (

  SELECT id,user_id,name,checkin_time,checkout_time,seconds FROM samples ORDER BY checkout_time DESC,id LIMIT 200

 )

 SELECT jsonb_build_object(

  'summary',(SELECT jsonb_build_object('count',count(*),'total',coalesce(sum(seconds),0),'average',avg(seconds),'median',percentile_cont(0.5) WITHIN GROUP(ORDER BY seconds)) FROM samples),

  'employees',coalesce((SELECT jsonb_agg(to_jsonb(p) ORDER BY p.name,p.id) FROM people p),'[]'::jsonb),

  'days',coalesce((SELECT jsonb_agg(to_jsonb(d) ORDER BY d.day) FROM daily d),'[]'::jsonb),

  'recent',coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.checkout_time DESC,r.id) FROM recent r),'[]'::jsonb),

  'invalid',(SELECT count(*) FROM public.checkins c JOIN public.users u ON u.id=c.user_id AND u.is_admin IS FALSE WHERE c.task_id=p_task AND (p_user IS NULL OR c.user_id=p_user) AND c.checkout_time>=v_from AND c.checkout_time<v_to AND (c.checkin_time IS NULL OR c.checkout_time<=c.checkin_time)),

  'as_of',now()) INTO result;

 RETURN result;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_assert_admin()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

 IF NOT coalesce(public.sec06_is_admin(),false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Solo administración'; END IF;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_assert_permission(p_key text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN IF NOT public.work_has_permission(p_key) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tu rol no tiene autorización para esta acción'; END IF; END $function$
;

CREATE OR REPLACE FUNCTION public.work_can_detail(p_task_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

 SELECT public.sec06_is_admin() OR (NOT public.work_mode()) OR EXISTS(

  SELECT 1 FROM public.work_day_plan p JOIN public.checkins c ON c.work_plan_id=p.id

  JOIN public.task_assignments a ON a.task_id=p.task_id AND a.user_id=p.user_id

  WHERE p.user_id=auth.uid() AND p.task_id=p_task_id AND p.state='active' AND c.checkout_time IS NULL

 )

$function$
;

CREATE OR REPLACE FUNCTION public.work_can_file(p_name text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_task uuid;

BEGIN

 IF NOT public.work_mode() OR public.sec06_is_admin() THEN RETURN true; END IF;

 IF p_name ~ '^tasks/[0-9a-f-]{36}/' THEN

  BEGIN v_task:=split_part(p_name,'/',2)::uuid; EXCEPTION WHEN invalid_text_representation THEN RETURN false; END;

  RETURN public.work_can_detail(v_task);

 END IF;

 RETURN EXISTS(SELECT 1 FROM public.task_comments c WHERE public.work_can_detail(c.task_id)

 AND (c.image_url=p_name OR c.video_url=p_name

 OR split_part(c.image_url,'/storage/v1/object/public/task-files/',2)=p_name

 OR split_part(c.video_url,'/storage/v1/object/public/task-files/',2)=p_name));

END $function$
;

CREATE OR REPLACE FUNCTION public.work_checkin_history(p_start date, p_end date, p_user uuid DEFAULT NULL::uuid, p_task uuid DEFAULT NULL::uuid, p_only_open boolean DEFAULT false, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50, p_personal boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE result jsonb; target_user uuid;

BEGIN

 IF auth.uid() IS NULL OR p_personal IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;

 IF p_personal THEN target_user:=auth.uid(); ELSE PERFORM public.work_assert_permission('checkins.view'); target_user:=p_user; END IF;

 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 OR p_offset IS NULL OR p_offset<0 OR p_limit IS NULL OR p_limit<1 OR p_limit>100 OR p_only_open IS NULL THEN RAISE EXCEPTION 'Filtros no válidos'; END IF;

 WITH filtered AS (

 SELECT c.id,c.task_id,c.user_id,coalesce(u.full_name,'Empleado eliminado') AS employee,t.title,c.checkin_time,c.checkout_time,c.checkin_method,c.location,

 greatest(0,extract(epoch FROM coalesce(c.checkout_time,now())-c.checkin_time)) AS seconds

 FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN public.users u ON u.id=c.user_id

 WHERE (target_user IS NULL OR c.user_id=target_user) AND (p_task IS NULL OR c.task_id=p_task)

 AND (NOT p_only_open OR c.checkout_time IS NULL)

 AND c.checkin_time>=p_start::timestamp AT TIME ZONE 'Europe/Madrid' AND c.checkin_time<(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid'

 ), page AS (SELECT * FROM filtered ORDER BY checkin_time DESC,id OFFSET p_offset LIMIT p_limit)

 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(to_jsonb(p) ORDER BY p.checkin_time DESC,p.id) FROM page p),'[]'::jsonb),'as_of',now()) INTO result;

 RETURN result;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_create_credential(p_kind text, p_name text, p_user uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_result jsonb;

BEGIN

 PERFORM public.work_assert_admin();

 v_result:=public.work_create_hashed_credential(p_kind,p_name,p_user);

 IF p_kind='station' THEN

  INSERT INTO public.work_station_keys(station_id,token) VALUES((v_result->>'id')::uuid,v_result->>'token');

 ELSIF p_kind='card' THEN

  INSERT INTO public.work_employee_card_keys(card_id,token) VALUES((v_result->>'id')::uuid,v_result->>'token');

 END IF;

 RETURN v_result;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_create_hashed_credential(p_kind text, p_name text, p_user uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_token text:='ASE-'||replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-',''); v_id uuid;

BEGIN

 PERFORM public.work_assert_admin();

 IF p_kind='card' THEN

  PERFORM 1 FROM public.users WHERE id=p_user AND is_admin IS FALSE FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no válido'; END IF;

  IF EXISTS(SELECT 1 FROM public.work_employee_cards WHERE user_id=p_user AND active) THEN

   RAISE EXCEPTION 'El empleado ya tiene una tarjeta activa. Desactívala antes de crear otra';

  END IF;

  INSERT INTO public.work_employee_cards(user_id,label,token_hash) VALUES(p_user,trim(p_name),public.work_hash(v_token)) RETURNING id INTO v_id;

 ELSIF p_kind='station' THEN

  INSERT INTO public.work_stations(name,token_hash) VALUES(trim(p_name),public.work_hash(v_token)) RETURNING id INTO v_id;

 ELSE RAISE EXCEPTION 'Tipo no válido'; END IF;

 RETURN jsonb_build_object('id',v_id,'token',v_token,'kind',p_kind);

END $function$
;

CREATE OR REPLACE FUNCTION public.work_deadline(p_day date, p_state text, p_finished timestamp with time zone)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$

 SELECT jsonb_build_object(

  'due_at',(p_day+1)::timestamp AT TIME ZONE 'Europe/Madrid',

  'overdue',p_state IN ('pending','active') AND now()>=(p_day+1)::timestamp AT TIME ZONE 'Europe/Madrid',

  'completed_late',p_state='completed' AND p_finished>=(p_day+1)::timestamp AT TIME ZONE 'Europe/Madrid')

$function$
;

CREATE OR REPLACE FUNCTION public.work_delete_credential(p_kind text, p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

 PERFORM public.work_assert_admin();

 IF p_kind='card' THEN

  UPDATE public.work_employee_cards SET active=false,archived_at=coalesce(archived_at,clock_timestamp()) WHERE id=p_id;

  IF NOT FOUND THEN RAISE EXCEPTION 'Tarjeta no disponible'; END IF;

  UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE card_id=p_id AND result IS NULL;

 ELSIF p_kind='station' THEN

  UPDATE public.work_stations SET active=false,archived_at=coalesce(archived_at,clock_timestamp()) WHERE id=p_id;

  IF NOT FOUND THEN RAISE EXCEPTION 'Punto no disponible'; END IF;

  UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE station_id=p_id AND result IS NULL;

 ELSE RAISE EXCEPTION 'Tipo no válido'; END IF;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_delete_role(p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

 PERFORM public.work_assert_admin();

 PERFORM 1 FROM public.work_roles WHERE id=p_id FOR UPDATE;

 IF NOT FOUND THEN RAISE EXCEPTION 'El rol ya no existe'; END IF;

 IF EXISTS(SELECT 1 FROM public.work_employee_roles WHERE role_id=p_id) THEN RAISE EXCEPTION 'Hay empleados con este rol. Reasígnalos antes de eliminarlo o desactiva el rol'; END IF;

 DELETE FROM public.work_roles WHERE id=p_id;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_detail_access(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

 SELECT jsonb_build_object('enabled',public.work_mode(),'allowed',auth.uid() IS NOT NULL AND public.work_can_detail(p_task_id))

$function$
;

CREATE OR REPLACE FUNCTION public.work_employee_directory()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE result jsonb;

BEGIN

 IF NOT (public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view') OR public.work_has_permission('reports.view') OR public.work_has_permission('checkins.view')) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso al directorio'; END IF;

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'full_name',full_name) ORDER BY full_name,id),'[]'::jsonb) INTO result FROM public.users WHERE is_admin IS FALSE;

 RETURN result;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_get_card_key(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_hash text; v_token text;

BEGIN

 PERFORM public.work_assert_admin();

 SELECT token_hash INTO v_hash FROM public.work_employee_cards WHERE id=p_id AND archived_at IS NULL;

 IF NOT FOUND THEN RAISE EXCEPTION 'Tarjeta no disponible'; END IF;

 SELECT token INTO v_token FROM public.work_employee_card_keys WHERE card_id=p_id;

 IF v_token IS NULL OR public.work_hash(v_token)<>v_hash THEN RETURN jsonb_build_object('available',false); END IF;

 RETURN jsonb_build_object('available',true,'token',v_token);

END $function$
;

CREATE OR REPLACE FUNCTION public.work_get_station_key(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_hash text; v_token text;

BEGIN

 PERFORM public.work_assert_admin();

 SELECT token_hash INTO v_hash FROM public.work_stations WHERE id=p_id AND archived_at IS NULL;

 IF NOT FOUND THEN RAISE EXCEPTION 'Punto no disponible'; END IF;

 SELECT token INTO v_token FROM public.work_station_keys WHERE station_id=p_id;

 IF v_token IS NULL OR public.work_hash(v_token)<>v_hash THEN RETURN jsonb_build_object('available',false); END IF;

 RETURN jsonb_build_object('available',true,'token',v_token);

END $function$
;

CREATE OR REPLACE FUNCTION public.work_guard_assignment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

 PERFORM 1 FROM public.users WHERE id=OLD.user_id FOR UPDATE;

 IF public.work_mode() AND EXISTS(SELECT 1 FROM public.work_day_plan WHERE task_id=OLD.task_id AND user_id=OLD.user_id AND state='active') THEN

  RAISE EXCEPTION 'Finaliza la tarea en la tablet antes de cambiar su asignación';

 END IF;

 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_guard_checkin()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

 PERFORM 1 FROM public.work_settings WHERE singleton FOR SHARE;

 IF public.work_mode() AND coalesce(auth.role(),'') IN ('anon','authenticated')

 AND coalesce(current_setting('ase.tablet_write',true),'')<>'on' THEN

  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='El inicio y fin de tarea se realizan en la tablet';

 END IF;

 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_has_permission(p_key text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

 SELECT auth.uid() IS NOT NULL AND (public.sec06_is_admin() OR EXISTS(

  SELECT 1 FROM public.work_employee_roles a JOIN public.work_roles r ON r.id=a.role_id

  WHERE a.user_id=auth.uid() AND r.active AND p_key=ANY(r.permissions)));

$function$
;

CREATE OR REPLACE FUNCTION public.work_hash(p_value text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$

 SELECT encode(sha256(convert_to(p_value,'UTF8')),'hex')

$function$
;

CREATE OR REPLACE FUNCTION public.work_home_summary()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE counts jsonb:='{}'; active_items jsonb:='[]'; overdue jsonb:='null';

BEGIN

 IF NOT(public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view') OR public.work_has_permission('reports.view') OR public.work_has_permission('checkins.view')) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso al resumen'; END IF;

 IF public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view') OR public.work_has_permission('reports.view') THEN

 SELECT jsonb_build_object('planned',count(*),'completed',count(*) FILTER(WHERE state='completed'),'active',count(*) FILTER(WHERE state='active'),'pending',count(*) FILTER(WHERE state='pending')) INTO counts FROM public.work_day_plan WHERE work_date=public.work_today();

 END IF;

 IF public.work_has_permission('checkins.view') THEN

 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.checkin_time),'[]'::jsonb) INTO active_items FROM (SELECT c.id,c.user_id,c.checkin_time,t.title,u.full_name AS employee FROM public.checkins c JOIN public.tasks t ON t.id=c.task_id LEFT JOIN public.users u ON u.id=c.user_id WHERE c.checkout_time IS NULL ORDER BY c.checkin_time LIMIT 100) q;

 END IF;

 IF public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view') THEN overdue:=public.work_overdue_items(5); END IF;

 RETURN jsonb_build_object('date',public.work_today(),'counts',counts,'working',active_items,'overdue',overdue,'as_of',now());

END $function$
;

CREATE OR REPLACE FUNCTION public.work_legacy_actor_names(p_task_id uuid)
 RETURNS TABLE(id uuid, full_name text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_actor uuid := (SELECT auth.uid());

BEGIN

 IF v_actor IS NULL OR (SELECT auth.role()) IS DISTINCT FROM 'authenticated' THEN

   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Sesion autenticada obligatoria';

 END IF;

 IF NOT public.sec06_is_admin()

 AND NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=p_task_id AND a.user_id=v_actor) THEN

   RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarea no disponible para esta cuenta';

 END IF;

 RETURN QUERY

 SELECT u.id,u.full_name FROM public.users u

 WHERE u.id IN (

   SELECT c.user_id FROM public.checkins c WHERE c.task_id=p_task_id

   UNION

   SELECT c.user_id FROM public.task_comments c WHERE c.task_id=p_task_id

 ) ORDER BY u.id;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.work_manage_task(p_action text, p_id uuid DEFAULT NULL::uuid, p_title text DEFAULT NULL::text, p_description text DEFAULT NULL::text, p_schedule text DEFAULT 'daily'::text, p_date date DEFAULT NULL::date, p_status text DEFAULT 'pending'::text, p_users uuid[] DEFAULT '{}'::uuid[])
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE result uuid;

BEGIN

 IF p_action IS NULL OR p_action NOT IN ('create','edit','delete') THEN RAISE EXCEPTION 'Acción no válida'; END IF;

 PERFORM public.work_assert_permission('tasks.'||p_action);

 IF p_action<>'create' THEN

  PERFORM 1 FROM public.tasks WHERE id=p_id FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'La tarea ya no existe'; END IF;

 END IF;

 IF p_action='delete' THEN

  IF EXISTS(SELECT 1 FROM public.checkins WHERE task_id=p_id AND checkout_time IS NULL) THEN RAISE EXCEPTION 'No puedes eliminar una tarea con fichajes abiertos'; END IF;

  DELETE FROM public.tasks WHERE id=p_id; RETURN p_id;

 END IF;

 IF p_title IS NULL OR length(trim(p_title)) NOT BETWEEN 1 AND 200 OR p_status IS NULL OR p_status NOT IN ('pending','in_progress','completed') OR p_schedule IS NULL OR p_schedule NOT IN ('daily','weekly','monthly','custom_date') OR (p_schedule='custom_date' AND p_date IS NULL) THEN RAISE EXCEPTION 'Datos de tarea no válidos'; END IF;

 IF p_users IS NULL OR cardinality(p_users)>100 OR EXISTS(SELECT 1 FROM unnest(p_users) x WHERE x IS NULL OR NOT EXISTS(SELECT 1 FROM public.users WHERE id=x AND is_admin IS FALSE)) THEN RAISE EXCEPTION 'Selecciona empleados válidos'; END IF;

 IF p_action='create' THEN

  INSERT INTO public.tasks(title,description,schedule_type,schedule_date,status) VALUES(trim(p_title),p_description,p_schedule,p_date,p_status) RETURNING id INTO result;

 ELSE

  UPDATE public.tasks SET title=trim(p_title),description=p_description,schedule_type=p_schedule,schedule_date=p_date,status=p_status WHERE id=p_id RETURNING id INTO result;

 END IF;

 DELETE FROM public.task_assignments WHERE task_id=result AND NOT user_id=ANY(p_users);

 INSERT INTO public.task_assignments(task_id,user_id) SELECT result,x FROM (SELECT DISTINCT unnest(p_users) x) v

 WHERE NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE task_id=result AND user_id=x);

 RETURN result;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_mode()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

 SELECT enabled FROM public.work_settings WHERE singleton

$function$
;

CREATE OR REPLACE FUNCTION public.work_my_day()
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



END $function$
;

CREATE OR REPLACE FUNCTION public.work_my_permissions()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE result jsonb;

BEGIN

 IF auth.uid() IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión'; END IF;

 IF public.sec06_is_admin() THEN RETURN jsonb_build_object('role','Administrador','permissions',ARRAY['tasks.view','tasks.create','tasks.edit','tasks.delete','planning.view','planning.edit','reports.view','checkins.view']); END IF;

 SELECT jsonb_build_object('role',r.name,'permissions',CASE WHEN r.active THEN r.permissions ELSE '{}'::text[] END) INTO result

 FROM public.work_employee_roles a JOIN public.work_roles r ON r.id=a.role_id WHERE a.user_id=auth.uid();

 RETURN coalesce(result,jsonb_build_object('role',null,'permissions','[]'::jsonb));

END $function$
;

CREATE OR REPLACE FUNCTION public.work_overdue_items(p_limit integer DEFAULT 200)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE result jsonb;

BEGIN

 IF NOT(public.work_has_permission('tasks.view') OR public.work_has_permission('planning.view')) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso al seguimiento'; END IF;

 IF p_limit IS NULL OR p_limit<1 OR p_limit>1000 THEN RAISE EXCEPTION 'Límite no válido'; END IF;

 WITH filtered AS (SELECT p.id,p.task_id,p.user_id,p.work_date,p.state,p.priority,t.title,u.full_name AS employee FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id JOIN public.users u ON u.id=p.user_id WHERE p.state IN ('pending','active') AND p.work_date<public.work_today()), page AS (SELECT * FROM filtered ORDER BY work_date,priority,id LIMIT p_limit)

 SELECT jsonb_build_object('total',(SELECT count(*) FROM filtered),'items',coalesce((SELECT jsonb_agg(to_jsonb(p) ORDER BY p.work_date,p.priority,p.id) FROM page p),'[]'::jsonb)) INTO result;

 RETURN result;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_planning_assignments(p_user uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE result jsonb;

BEGIN

 PERFORM public.work_assert_permission('planning.view');

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',t.id,'title',t.title) ORDER BY t.title,t.id),'[]'::jsonb) INTO result FROM public.tasks t WHERE EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=t.id AND a.user_id=p_user);

 RETURN result;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_planning_calendar(p_user uuid, p_start date, p_end date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE result jsonb;

BEGIN

 PERFORM public.work_assert_permission('planning.view');

 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>41 THEN RAISE EXCEPTION 'Selecciona hasta 42 días'; END IF;

 SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.day),'[]'::jsonb) INTO result FROM (SELECT work_date AS day,count(*) AS total,count(*) FILTER(WHERE state='completed') AS completed,count(*) FILTER(WHERE state='active') AS active,count(*) FILTER(WHERE state IN ('pending','active') AND work_date<public.work_today()) AS overdue FROM public.work_day_plan WHERE user_id=p_user AND work_date BETWEEN p_start AND p_end GROUP BY work_date) q;

 RETURN result;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_revoke_credential(p_kind text, p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

 PERFORM public.work_assert_admin();

 IF p_kind='card' THEN UPDATE public.work_employee_cards SET active=false WHERE id=p_id;

 ELSIF p_kind='station' THEN UPDATE public.work_stations SET active=false WHERE id=p_id;

 ELSE RAISE EXCEPTION 'Tipo no válido'; END IF;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_roles_overview()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE roles jsonb; assignments jsonb;

BEGIN

 PERFORM public.work_assert_admin();

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',r.id,'name',r.name,'description',r.description,'active',r.active,'permissions',r.permissions,

  'employees',(SELECT count(*) FROM public.work_employee_roles a WHERE a.role_id=r.id)) ORDER BY r.active DESC,r.name,r.id),'[]'::jsonb)

 INTO roles FROM public.work_roles r;

 SELECT coalesce(jsonb_agg(jsonb_build_object('user_id',user_id,'role_id',role_id)),'[]'::jsonb) INTO assignments FROM public.work_employee_roles;

 RETURN jsonb_build_object('roles',roles,'assignments',assignments);

END $function$
;

CREATE OR REPLACE FUNCTION public.work_rotate_card_key(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_token text:='ASE-'||replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-','');

BEGIN

 PERFORM public.work_assert_admin();

 UPDATE public.work_employee_cards SET token_hash=public.work_hash(v_token) WHERE id=p_id AND archived_at IS NULL;

 IF NOT FOUND THEN RAISE EXCEPTION 'Tarjeta no disponible'; END IF;

 INSERT INTO public.work_employee_card_keys(card_id,token) VALUES(p_id,v_token)

 ON CONFLICT(card_id) DO UPDATE SET token=EXCLUDED.token,saved_at=clock_timestamp();

 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE card_id=p_id AND result IS NULL;

 RETURN jsonb_build_object('available',true,'token',v_token);

END $function$
;

CREATE OR REPLACE FUNCTION public.work_rotate_station_key(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_token text:='ASE-'||replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-','');

BEGIN

 PERFORM public.work_assert_admin();

 UPDATE public.work_stations SET token_hash=public.work_hash(v_token) WHERE id=p_id AND archived_at IS NULL;

 IF NOT FOUND THEN RAISE EXCEPTION 'Punto no disponible'; END IF;

 INSERT INTO public.work_station_keys(station_id,token) VALUES(p_id,v_token)

 ON CONFLICT(station_id) DO UPDATE SET token=EXCLUDED.token,saved_at=clock_timestamp();

 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE station_id=p_id AND result IS NULL;

 RETURN jsonb_build_object('available',true,'token',v_token);

END $function$
;

CREATE OR REPLACE FUNCTION public.work_save_card_key(p_id uuid, p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_hash text;

BEGIN

 PERFORM public.work_assert_admin();

 SELECT token_hash INTO v_hash FROM public.work_employee_cards WHERE id=p_id AND archived_at IS NULL FOR UPDATE;

 IF NOT FOUND THEN RAISE EXCEPTION 'Tarjeta no disponible'; END IF;

 IF p_token IS NULL OR length(p_token)>128 OR public.work_hash(trim(p_token))<>v_hash THEN

  RAISE EXCEPTION 'El código no corresponde a este registro';

 END IF;

 INSERT INTO public.work_employee_card_keys(card_id,token) VALUES(p_id,trim(p_token))

 ON CONFLICT(card_id) DO UPDATE SET token=EXCLUDED.token,saved_at=clock_timestamp();

 RETURN jsonb_build_object('available',true,'token',trim(p_token));

END $function$
;

CREATE OR REPLACE FUNCTION public.work_save_employee_profile(p_user uuid, p_name text, p_whatsapp text, p_role uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_existing_role uuid; role_enabled boolean;

BEGIN

 PERFORM public.work_assert_admin();

 PERFORM 1 FROM public.users WHERE id=p_user AND is_admin IS FALSE FOR UPDATE;

 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;

 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 150 THEN RAISE EXCEPTION 'Introduce un nombre de hasta 150 caracteres'; END IF;

 IF p_whatsapp IS NOT NULL AND p_whatsapp !~ '^\+?[0-9]{7,15}$' THEN RAISE EXCEPTION 'WhatsApp no válido'; END IF;

 SELECT role_id INTO v_existing_role FROM public.work_employee_roles WHERE user_id=p_user;

 IF p_role IS NOT NULL THEN

  SELECT active INTO role_enabled FROM public.work_roles WHERE id=p_role FOR SHARE;

  IF NOT FOUND THEN RAISE EXCEPTION 'El rol seleccionado ya no existe'; END IF;

  IF NOT role_enabled AND p_role IS DISTINCT FROM v_existing_role THEN RAISE EXCEPTION 'El rol está desactivado. Selecciona otro rol activo'; END IF;

  INSERT INTO public.work_employee_roles(user_id,role_id) VALUES(p_user,p_role) ON CONFLICT(user_id) DO UPDATE SET role_id=EXCLUDED.role_id;

 ELSE DELETE FROM public.work_employee_roles WHERE user_id=p_user;

 END IF;

 UPDATE public.users SET full_name=trim(p_name),whatsapp=p_whatsapp WHERE id=p_user;

 RETURN jsonb_build_object('id',p_user,'role_id',p_role);

END $function$
;

CREATE OR REPLACE FUNCTION public.work_save_plan(p_user uuid, p_date date, p_tasks uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$



BEGIN



 PERFORM public.work_assert_permission('planning.edit');



 PERFORM 1 FROM public.users WHERE id=p_user AND is_admin IS FALSE FOR UPDATE;



 IF NOT FOUND OR p_date IS NULL OR p_tasks IS NULL OR cardinality(p_tasks)>100 THEN RAISE EXCEPTION 'Plan no válido'; END IF;



 IF cardinality(p_tasks)<>(SELECT count(DISTINCT x) FROM unnest(p_tasks) x)



 OR EXISTS(SELECT 1 FROM unnest(p_tasks) x WHERE x IS NULL OR NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.user_id=p_user AND a.task_id=x)) THEN



  RAISE EXCEPTION 'Solo tareas asignadas, sin duplicados';



 END IF;



 IF EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.user_id=p_user AND p.work_date=p_date AND p.state<>'pending' AND NOT p.task_id=ANY(p_tasks)) THEN



  RAISE EXCEPTION 'No se pueden retirar tareas iniciadas o completadas';



 END IF;



 -- Conservar el historial y no colocar pendientes antes de las ya iniciadas.



 IF EXISTS(SELECT 1 FROM public.work_day_plan p WHERE p.user_id=p_user AND p.work_date=p_date AND p.state<>'pending'



  AND array_position(p_tasks,p.task_id) IS DISTINCT FROM p.priority) THEN



  RAISE EXCEPTION 'El orden de las tareas iniciadas o completadas está bloqueado';



 END IF;



 DELETE FROM public.work_day_plan WHERE user_id=p_user AND work_date=p_date AND state='pending' AND NOT task_id=ANY(p_tasks);



 INSERT INTO public.work_day_plan(user_id,task_id,work_date,priority)



 SELECT p_user,x,p_date,n::integer FROM unnest(p_tasks) WITH ORDINALITY AS v(x,n)



 ON CONFLICT(user_id,task_id,work_date) DO UPDATE SET priority=EXCLUDED.priority;



END $function$
;

CREATE OR REPLACE FUNCTION public.work_save_plan_range(p_user uuid, p_start date, p_end date, p_tasks uuid[], p_weekdays integer[], p_existing text DEFAULT 'empty'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE d date; existing_tasks uuid[]; merged uuid[]; changed integer:=0; skipped integer:=0;

BEGIN

 PERFORM public.work_assert_permission('planning.edit');

 PERFORM 1 FROM public.users WHERE id=p_user AND is_admin IS FALSE FOR UPDATE;

 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no válido'; END IF;

 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365 THEN RAISE EXCEPTION 'Selecciona un intervalo de hasta 366 días'; END IF;

 IF p_existing IS NULL OR p_existing NOT IN ('empty','append') THEN RAISE EXCEPTION 'Opción no válida'; END IF;

 IF p_tasks IS NULL OR cardinality(p_tasks)=0 OR cardinality(p_tasks)>100 OR cardinality(p_tasks)<>(SELECT count(DISTINCT x) FROM unnest(p_tasks) x)

 OR EXISTS(SELECT 1 FROM unnest(p_tasks) x WHERE x IS NULL OR NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.user_id=p_user AND a.task_id=x)) THEN RAISE EXCEPTION 'Selecciona tareas asignadas sin duplicados'; END IF;

 IF p_weekdays IS NULL OR cardinality(p_weekdays)=0 OR EXISTS(SELECT 1 FROM unnest(p_weekdays) x WHERE x IS NULL OR x<1 OR x>7) THEN RAISE EXCEPTION 'Selecciona días de la semana'; END IF;

 FOR d IN SELECT p_start+i FROM generate_series(0,p_end-p_start) i LOOP

  IF NOT extract(isodow FROM d)::integer=ANY(p_weekdays) THEN CONTINUE; END IF;

  SELECT coalesce(array_agg(task_id ORDER BY priority),'{}'::uuid[]) INTO existing_tasks FROM public.work_day_plan WHERE user_id=p_user AND work_date=d;

  IF cardinality(existing_tasks)>0 AND p_existing='empty' THEN skipped:=skipped+1; CONTINUE; END IF;

  SELECT existing_tasks || coalesce(array_agg(x ORDER BY n),'{}'::uuid[]) INTO merged FROM unnest(p_tasks) WITH ORDINALITY v(x,n) WHERE NOT x=ANY(existing_tasks);

  IF merged=existing_tasks THEN skipped:=skipped+1; CONTINUE; END IF;

  PERFORM public.work_save_plan(p_user,d,merged);

  changed:=changed+1;

 END LOOP;

 RETURN jsonb_build_object('changed',changed,'skipped',skipped);

END $function$
;

CREATE OR REPLACE FUNCTION public.work_save_role(p_id uuid, p_name text, p_description text, p_active boolean DEFAULT true)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE result uuid;

BEGIN

 PERFORM public.work_assert_admin();

 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 80 OR length(coalesce(p_description,''))>500 OR p_active IS NULL THEN RAISE EXCEPTION 'Introduce un nombre de hasta 80 caracteres y una descripción de hasta 500'; END IF;

 IF p_id IS NULL THEN

  INSERT INTO public.work_roles(name,description,active) VALUES(trim(p_name),trim(coalesce(p_description,'')),p_active) RETURNING id INTO result;

 ELSE

  UPDATE public.work_roles SET name=trim(p_name),description=trim(coalesce(p_description,'')),active=p_active WHERE id=p_id RETURNING id INTO result;

  IF result IS NULL THEN RAISE EXCEPTION 'El rol ya no existe'; END IF;

 END IF;

 RETURN result;

EXCEPTION WHEN unique_violation THEN RAISE EXCEPTION 'Ya existe un rol con ese nombre';

END $function$
;

CREATE OR REPLACE FUNCTION public.work_save_station_key(p_id uuid, p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_hash text;

BEGIN

 PERFORM public.work_assert_admin();

 SELECT token_hash INTO v_hash FROM public.work_stations WHERE id=p_id AND archived_at IS NULL FOR UPDATE;

 IF NOT FOUND THEN RAISE EXCEPTION 'Punto no disponible'; END IF;

 IF p_token IS NULL OR length(p_token)>128 OR public.work_hash(trim(p_token))<>v_hash THEN

  RAISE EXCEPTION 'El código no corresponde a este registro';

 END IF;

 INSERT INTO public.work_station_keys(station_id,token) VALUES(p_id,trim(p_token))

 ON CONFLICT(station_id) DO UPDATE SET token=EXCLUDED.token,saved_at=clock_timestamp();

 RETURN jsonb_build_object('available',true,'token',trim(p_token));

END $function$
;

CREATE OR REPLACE FUNCTION public.work_set_card_active(p_id uuid, p_active boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_user uuid;

BEGIN

 PERFORM public.work_assert_admin();

 IF p_active IS NULL THEN RAISE EXCEPTION 'Estado no vÃ¡lido'; END IF;

 -- Mismo orden de bloqueo que una confirmaciÃ³n de fichaje: tarjeta y empleado.

 SELECT user_id INTO v_user FROM public.work_employee_cards WHERE id=p_id AND archived_at IS NULL FOR UPDATE;

 IF v_user IS NULL THEN RAISE EXCEPTION 'Tarjeta no disponible'; END IF;

 PERFORM 1 FROM public.users WHERE id=v_user AND is_admin IS FALSE FOR UPDATE;

 IF NOT FOUND THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;

 IF p_active AND EXISTS(SELECT 1 FROM public.work_employee_cards WHERE user_id=v_user AND active AND id<>p_id) THEN

  RAISE EXCEPTION 'Desactiva primero la otra tarjeta activa del empleado';

 END IF;

 UPDATE public.work_employee_cards SET active=p_active WHERE id=p_id;

 -- Una identificaciÃ³n emitida antes del cambio no se puede reutilizar al reactivar.

 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second'

 WHERE card_id=p_id AND result IS NULL;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_set_mode(p_enabled boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

 PERFORM public.work_assert_admin();

 -- También lo toman los RPC de fichaje; evita activar/desactivar durante una escritura.

 PERFORM 1 FROM public.work_settings WHERE singleton FOR UPDATE;

 IF p_enabled IS NULL THEN RAISE EXCEPTION 'Modo no válido'; END IF;

 IF EXISTS(SELECT 1 FROM public.checkins WHERE checkout_time IS NULL)

 OR EXISTS(SELECT 1 FROM public.work_day_plan WHERE state='active') THEN

  RAISE EXCEPTION 'Finaliza primero todos los fichajes abiertos';

 END IF;

 UPDATE public.work_settings SET enabled=p_enabled WHERE singleton;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_set_role_permissions(p_id uuid, p_permissions text[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE keys text[];

BEGIN

 PERFORM public.work_assert_admin();

 IF p_permissions IS NULL OR EXISTS(SELECT 1 FROM unnest(p_permissions) x WHERE x IS NULL OR x NOT IN ('tasks.view','tasks.create','tasks.edit','tasks.delete','planning.view','planning.edit','reports.view','checkins.view')) THEN RAISE EXCEPTION 'Autorización no válida'; END IF;

 keys:=p_permissions;

 IF keys && ARRAY['tasks.create','tasks.edit','tasks.delete'] THEN keys:=array_append(keys,'tasks.view'); END IF;

 IF 'planning.edit'=ANY(keys) THEN keys:=array_append(keys,'planning.view'); END IF;

 SELECT coalesce(array_agg(DISTINCT x),'{}'::text[]) INTO keys FROM unnest(keys) x;

 UPDATE public.work_roles SET permissions=keys WHERE id=p_id;

 IF NOT FOUND THEN RAISE EXCEPTION 'El rol ya no existe'; END IF;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_set_station_active(p_id uuid, p_active boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

BEGIN

 PERFORM public.work_assert_admin();

 IF p_active IS NULL THEN RAISE EXCEPTION 'Estado no vÃ¡lido'; END IF;

 UPDATE public.work_stations SET active=p_active WHERE id=p_id AND archived_at IS NULL;

 IF NOT FOUND THEN RAISE EXCEPTION 'Punto no disponible'; END IF;

 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second'

 WHERE station_id=p_id AND result IS NULL;

 -- No modifica checkins ni estados de tareas en curso.

END $function$
;

CREATE OR REPLACE FUNCTION public.work_station_confirm(p_station text, p_ticket uuid, p_action text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$



DECLARE s public.work_stations%ROWTYPE; k public.work_station_tickets%ROWTYPE; p public.work_day_plan%ROWTYPE;



 v_checkin uuid; v_time timestamptz:=clock_timestamp(); v_result jsonb;



BEGIN



 PERFORM 1 FROM public.work_settings WHERE singleton FOR SHARE;



 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;



 SELECT * INTO s FROM public.work_stations WHERE token_hash=public.work_hash(p_station) AND active FOR SHARE;



 IF s.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto no disponible'; END IF;



 SELECT * INTO k FROM public.work_station_tickets WHERE id=p_ticket AND station_id=s.id FOR UPDATE;



 IF k.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Vuelve a pasar tu tarjeta'; END IF;



 IF p_action IS NULL OR p_action NOT IN ('start','finish') OR p_action<>k.expected_action THEN RAISE EXCEPTION 'Acción no válida'; END IF;



 IF k.result IS NOT NULL THEN RETURN k.result; END IF;



 IF k.expires_at<=v_time THEN RAISE EXCEPTION 'La identificación ha caducado. Vuelve a pasar tu tarjeta'; END IF;



 PERFORM 1 FROM public.work_employee_cards WHERE id=k.card_id AND user_id=k.user_id AND active FOR SHARE;



 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarjeta desactivada'; END IF;



 PERFORM 1 FROM public.users WHERE id=k.user_id AND is_admin IS FALSE FOR UPDATE;



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



  VALUES(p.task_id,p.user_id,v_time,'manual','Tablet · lectura por código',p.id,s.id,k.card_id) RETURNING id INTO v_checkin;



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



END $function$
;

CREATE OR REPLACE FUNCTION public.work_station_day(p_station text, p_ticket uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE v_user uuid; v_items jsonb; v_name text;

BEGIN

 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;

 SELECT k.user_id,u.full_name INTO v_user,v_name

 FROM public.work_station_tickets k

 JOIN public.work_stations s ON s.id=k.station_id AND s.active

 JOIN public.work_employee_cards c ON c.id=k.card_id AND c.active AND c.user_id=k.user_id

 JOIN public.users u ON u.id=k.user_id AND u.is_admin IS FALSE

 WHERE k.id=p_ticket AND s.token_hash=public.work_hash(p_station) AND k.expires_at>clock_timestamp();

 IF v_user IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Vuelve a identificarte para consultar tus tareas'; END IF;

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'title',t.title,'state',p.state,

  'priority',p.priority,'work_date',p.work_date) || public.work_deadline(p.work_date,p.state,p.finished_at) ORDER BY p.work_date,p.priority),'[]'::jsonb)

 INTO v_items FROM public.work_day_plan p JOIN public.tasks t ON t.id=p.task_id

 WHERE p.user_id=v_user AND (p.work_date=public.work_today() OR p.state='active' OR (p.work_date<public.work_today() AND p.state='pending'))

 AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.task_id=p.task_id AND a.user_id=p.user_id);

 RETURN jsonb_build_object('employee',v_name,'date',public.work_today(),'items',v_items);

END $function$
;

CREATE OR REPLACE FUNCTION public.work_station_identify(p_station text, p_card text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE s public.work_stations%ROWTYPE; c public.work_employee_cards%ROWTYPE; p public.work_day_plan%ROWTYPE;

 v_ticket uuid; v_action text:='none'; v_name text; v_title text; v_description text;

BEGIN

 IF NOT public.work_mode() THEN RAISE EXCEPTION 'El modo tablet no está activo'; END IF;

 SELECT * INTO s FROM public.work_stations WHERE token_hash=public.work_hash(p_station) AND active FOR UPDATE;

 SELECT * INTO c FROM public.work_employee_cards WHERE token_hash=public.work_hash(p_card) AND active;

 IF s.id IS NULL OR c.id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Punto o tarjeta no disponible'; END IF;

 SELECT full_name INTO v_name FROM public.users WHERE id=c.user_id AND is_admin IS FALSE;

 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarjeta no disponible'; END IF;

 SELECT * INTO p FROM public.work_day_plan WHERE user_id=c.user_id AND state='active';

 IF p.id IS NOT NULL THEN v_action:='finish';

 ELSE

  SELECT x.* INTO p FROM public.work_day_plan x WHERE x.user_id=c.user_id AND x.work_date=public.work_today() AND x.state='pending'

   ORDER BY x.priority LIMIT 1;

  IF p.id IS NOT NULL THEN v_action:='start'; END IF;

 END IF;

 IF p.id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.task_assignments WHERE user_id=c.user_id AND task_id=p.task_id) THEN

  RAISE EXCEPTION 'La asignación cambió. Consulta al encargado';

 END IF;

 SELECT title,description INTO v_title,v_description FROM public.tasks WHERE id=p.task_id;

 UPDATE public.work_station_tickets SET expires_at=clock_timestamp()-interval '1 second' WHERE station_id=s.id AND result IS NULL;

 DELETE FROM public.work_station_tickets WHERE expires_at<now()-interval '7 days';

 INSERT INTO public.work_station_tickets(station_id,card_id,user_id,plan_id,expected_action)

 VALUES(s.id,c.id,c.user_id,p.id,v_action) RETURNING id INTO v_ticket;

 RETURN jsonb_build_object('ticket',v_ticket,'employee',v_name,'title',v_title,'description',v_description,'action',v_action,

  'started_at',p.started_at,'reader_mode',s.reader_mode);

END $function$
;

CREATE OR REPLACE FUNCTION public.work_task_catalog()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE result jsonb;

BEGIN

 PERFORM public.work_assert_permission('tasks.view');

 SELECT coalesce(jsonb_agg(to_jsonb(t)||jsonb_build_object('assigned_users',coalesce((SELECT jsonb_agg(jsonb_build_object('id',u.id,'full_name',u.full_name) ORDER BY u.full_name,u.id) FROM public.task_assignments a JOIN public.users u ON u.id=a.user_id WHERE a.task_id=t.id),'[]'::jsonb)) ORDER BY t.created_at DESC,t.id),'[]'::jsonb) INTO result FROM public.tasks t;

 RETURN result;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_task_options()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$

DECLARE result jsonb;

BEGIN

 IF NOT (public.work_has_permission('tasks.view') OR public.work_has_permission('reports.view') OR public.work_has_permission('checkins.view')) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No tienes acceso a las actividades'; END IF;

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'title',title) ORDER BY title,id),'[]'::jsonb) INTO result FROM public.tasks;

 RETURN result;

END $function$
;

CREATE OR REPLACE FUNCTION public.work_today()
 RETURNS date
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$

 SELECT (now() AT TIME ZONE 'Europe/Madrid')::date

$function$
;

SET check_function_bodies=on;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER sync_confirmed_auth_email AFTER UPDATE OF email ON auth.users FOR EACH ROW EXECUTE FUNCTION sync_confirmed_auth_email();

CREATE TRIGGER work_guard_checkin BEFORE INSERT OR DELETE OR UPDATE ON checkins FOR EACH ROW EXECUTE FUNCTION work_guard_checkin();

CREATE TRIGGER work_guard_assignment BEFORE DELETE OR UPDATE ON task_assignments FOR EACH ROW EXECUTE FUNCTION work_guard_assignment();

CREATE TRIGGER sec04_validate_comment_attachment BEFORE INSERT OR UPDATE ON task_comments FOR EACH ROW EXECUTE FUNCTION sec04_validate_comment_attachment();

CREATE TRIGGER after_task_insert AFTER INSERT ON tasks FOR EACH ROW EXECUTE FUNCTION create_task_checkin_config();

CREATE TRIGGER sec01_guard_is_admin BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION sec01_guard_is_admin();

ALTER TABLE public."checkins" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."nfc_cards" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."task_access_codes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."task_assignments" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."task_checkin_config" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."task_comments" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."tasks" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."users" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."work_day_plan" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."work_employee_card_keys" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."work_employee_cards" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."work_employee_roles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."work_roles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."work_settings" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."work_station_keys" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."work_station_tickets" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."work_stations" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable delete for admins" ON public."checkins" AS PERMISSIVE FOR DELETE TO PUBLIC USING ((( SELECT users.is_admin
   FROM users
  WHERE (users.id = auth.uid())) = true));

CREATE POLICY "sec05_insert_own_assigned_manual_checkin" ON public."checkins" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND (task_id IS NOT NULL) AND ((checkin_method)::text = 'manual'::text) AND (checkout_time IS NULL) AND (nfc_card_id IS NULL) AND (EXISTS ( SELECT 1
   FROM task_assignments a
  WHERE ((a.task_id = checkins.task_id) AND (a.user_id = ( SELECT auth.uid() AS uid))))) AND (EXISTS ( SELECT 1
   FROM task_checkin_config c
  WHERE ((c.task_id = checkins.task_id) AND (c.manual_enabled IS TRUE))))));

CREATE POLICY "sec05_read_assigned_checkins_or_admin" ON public."checkins" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = ( SELECT auth.uid() AS uid)) AND (u.is_admin IS TRUE)))) OR (EXISTS ( SELECT 1
   FROM task_assignments a
  WHERE ((a.task_id = checkins.task_id) AND (a.user_id = ( SELECT auth.uid() AS uid)))))));

CREATE POLICY "work_checkins_detail" ON public."checkins" AS RESTRICTIVE FOR SELECT TO "authenticated" USING (((NOT work_mode()) OR sec06_is_admin() OR ((user_id = auth.uid()) AND work_can_detail(task_id))));

CREATE POLICY "Admins can manage NFC cards" ON public."nfc_cards" AS PERMISSIVE FOR ALL TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.is_admin = true)))));

CREATE POLICY "Employees can view NFC cards for assigned tasks" ON public."nfc_cards" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM task_assignments
  WHERE ((task_assignments.task_id = nfc_cards.task_id) AND (task_assignments.user_id = auth.uid())))));

CREATE POLICY "Admins can manage access codes" ON public."task_access_codes" AS PERMISSIVE FOR ALL TO PUBLIC USING ((( SELECT users.is_admin
   FROM users
  WHERE (users.id = auth.uid())) = true));

CREATE POLICY "Users can view active codes for their tasks" ON public."task_access_codes" AS PERMISSIVE FOR SELECT TO PUBLIC USING (((is_active = true) AND (EXISTS ( SELECT 1
   FROM task_assignments
  WHERE ((task_assignments.task_id = task_access_codes.task_id) AND (task_assignments.user_id = auth.uid()))))));

CREATE POLICY "Enable delete for admins" ON public."task_assignments" AS PERMISSIVE FOR DELETE TO PUBLIC USING ((( SELECT users.is_admin
   FROM users
  WHERE (users.id = auth.uid())) = true));

CREATE POLICY "Enable insert for admins" ON public."task_assignments" AS PERMISSIVE FOR INSERT TO PUBLIC WITH CHECK ((( SELECT users.is_admin
   FROM users
  WHERE (users.id = auth.uid())) = true));

CREATE POLICY "sec05_read_own_assignments_or_admin" ON public."task_assignments" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = ( SELECT auth.uid() AS uid)) AND (u.is_admin IS TRUE))))));

CREATE POLICY "work_permission_assignment_delete" ON public."task_assignments" AS RESTRICTIVE FOR DELETE TO "authenticated" USING (sec06_is_admin());

CREATE POLICY "work_permission_assignment_insert" ON public."task_assignments" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK (sec06_is_admin());

CREATE POLICY "work_permission_assignment_update" ON public."task_assignments" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING (sec06_is_admin()) WITH CHECK (sec06_is_admin());

CREATE POLICY "Admins can manage checkin config" ON public."task_checkin_config" AS PERMISSIVE FOR ALL TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.is_admin = true)))));

CREATE POLICY "Employees can view checkin config for assigned tasks" ON public."task_checkin_config" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM task_assignments
  WHERE ((task_assignments.task_id = task_checkin_config.task_id) AND (task_assignments.user_id = auth.uid())))));

CREATE POLICY "work_config_detail" ON public."task_checkin_config" AS RESTRICTIVE FOR SELECT TO "authenticated" USING (work_can_detail(task_id));

CREATE POLICY "Users can insert comments on their tasks" ON public."task_comments" AS PERMISSIVE FOR INSERT TO PUBLIC WITH CHECK (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM task_assignments
  WHERE ((task_assignments.task_id = task_comments.task_id) AND (task_assignments.user_id = auth.uid()))))));

CREATE POLICY "Users can view comments on their tasks" ON public."task_comments" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((EXISTS ( SELECT 1
   FROM task_assignments
  WHERE ((task_assignments.task_id = task_comments.task_id) AND (task_assignments.user_id = auth.uid())))));

CREATE POLICY "work_comments_detail" ON public."task_comments" AS RESTRICTIVE FOR ALL TO "authenticated" USING (work_can_detail(task_id)) WITH CHECK (work_can_detail(task_id));

CREATE POLICY "Enable delete for admins" ON public."tasks" AS PERMISSIVE FOR DELETE TO PUBLIC USING ((( SELECT users.is_admin
   FROM users
  WHERE (users.id = auth.uid())) = true));

CREATE POLICY "Enable insert for admins" ON public."tasks" AS PERMISSIVE FOR INSERT TO PUBLIC WITH CHECK ((( SELECT users.is_admin
   FROM users
  WHERE (users.id = auth.uid())) = true));

CREATE POLICY "Enable update for admins and assigned employees" ON public."tasks" AS PERMISSIVE FOR UPDATE TO PUBLIC USING (((( SELECT users.is_admin
   FROM users
  WHERE (users.id = auth.uid())) = true) OR (EXISTS ( SELECT 1
   FROM task_assignments
  WHERE ((task_assignments.task_id = tasks.id) AND (task_assignments.user_id = auth.uid()))))));

CREATE POLICY "sec05_read_assigned_tasks_or_admin" ON public."tasks" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = ( SELECT auth.uid() AS uid)) AND (u.is_admin IS TRUE)))) OR (EXISTS ( SELECT 1
   FROM task_assignments a
  WHERE ((a.task_id = tasks.id) AND (a.user_id = ( SELECT auth.uid() AS uid)))))));

CREATE POLICY "work_permission_task_delete" ON public."tasks" AS RESTRICTIVE FOR DELETE TO "authenticated" USING (sec06_is_admin());

CREATE POLICY "work_permission_task_insert" ON public."tasks" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK (sec06_is_admin());

CREATE POLICY "work_permission_task_update" ON public."tasks" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING (sec06_is_admin()) WITH CHECK (sec06_is_admin());

CREATE POLICY "work_task_detail" ON public."tasks" AS RESTRICTIVE FOR SELECT TO "authenticated" USING (work_can_detail(id));

CREATE POLICY "work_task_update" ON public."tasks" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING (((NOT work_mode()) OR sec06_is_admin())) WITH CHECK (((NOT work_mode()) OR sec06_is_admin()));

CREATE POLICY "sec06_delete_admin" ON public."users" AS PERMISSIVE FOR DELETE TO "authenticated" USING (( SELECT sec06_is_admin() AS sec06_is_admin));

CREATE POLICY "sec06_insert_admin" ON public."users" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (( SELECT sec06_is_admin() AS sec06_is_admin));

CREATE POLICY "sec06_read_self_or_admin" ON public."users" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((id = ( SELECT auth.uid() AS uid)) OR ( SELECT sec06_is_admin() AS sec06_is_admin)));

CREATE POLICY "sec06_update_self_or_admin" ON public."users" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (((id = ( SELECT auth.uid() AS uid)) OR ( SELECT sec06_is_admin() AS sec06_is_admin))) WITH CHECK (((id = ( SELECT auth.uid() AS uid)) OR ( SELECT sec06_is_admin() AS sec06_is_admin)));

GRANT DELETE ON public."checkins" TO "anon";

GRANT INSERT ON public."checkins" TO "anon";

GRANT REFERENCES ON public."checkins" TO "anon";

GRANT SELECT ON public."checkins" TO "anon";

GRANT TRIGGER ON public."checkins" TO "anon";

GRANT TRUNCATE ON public."checkins" TO "anon";

GRANT UPDATE ON public."checkins" TO "anon";

GRANT DELETE ON public."checkins" TO "authenticated";

GRANT INSERT ON public."checkins" TO "authenticated";

GRANT REFERENCES ON public."checkins" TO "authenticated";

GRANT SELECT ON public."checkins" TO "authenticated";

GRANT TRIGGER ON public."checkins" TO "authenticated";

GRANT TRUNCATE ON public."checkins" TO "authenticated";

GRANT UPDATE ON public."checkins" TO "authenticated";

GRANT DELETE ON public."checkins" TO "service_role";

GRANT INSERT ON public."checkins" TO "service_role";

GRANT REFERENCES ON public."checkins" TO "service_role";

GRANT SELECT ON public."checkins" TO "service_role";

GRANT TRIGGER ON public."checkins" TO "service_role";

GRANT TRUNCATE ON public."checkins" TO "service_role";

GRANT UPDATE ON public."checkins" TO "service_role";

GRANT DELETE ON public."nfc_cards" TO "anon";

GRANT INSERT ON public."nfc_cards" TO "anon";

GRANT REFERENCES ON public."nfc_cards" TO "anon";

GRANT SELECT ON public."nfc_cards" TO "anon";

GRANT TRIGGER ON public."nfc_cards" TO "anon";

GRANT TRUNCATE ON public."nfc_cards" TO "anon";

GRANT UPDATE ON public."nfc_cards" TO "anon";

GRANT DELETE ON public."nfc_cards" TO "authenticated";

GRANT INSERT ON public."nfc_cards" TO "authenticated";

GRANT REFERENCES ON public."nfc_cards" TO "authenticated";

GRANT SELECT ON public."nfc_cards" TO "authenticated";

GRANT TRIGGER ON public."nfc_cards" TO "authenticated";

GRANT TRUNCATE ON public."nfc_cards" TO "authenticated";

GRANT UPDATE ON public."nfc_cards" TO "authenticated";

GRANT DELETE ON public."nfc_cards" TO "service_role";

GRANT INSERT ON public."nfc_cards" TO "service_role";

GRANT REFERENCES ON public."nfc_cards" TO "service_role";

GRANT SELECT ON public."nfc_cards" TO "service_role";

GRANT TRIGGER ON public."nfc_cards" TO "service_role";

GRANT TRUNCATE ON public."nfc_cards" TO "service_role";

GRANT UPDATE ON public."nfc_cards" TO "service_role";

GRANT DELETE ON public."task_access_codes" TO "anon";

GRANT INSERT ON public."task_access_codes" TO "anon";

GRANT REFERENCES ON public."task_access_codes" TO "anon";

GRANT SELECT ON public."task_access_codes" TO "anon";

GRANT TRIGGER ON public."task_access_codes" TO "anon";

GRANT TRUNCATE ON public."task_access_codes" TO "anon";

GRANT UPDATE ON public."task_access_codes" TO "anon";

GRANT DELETE ON public."task_access_codes" TO "authenticated";

GRANT INSERT ON public."task_access_codes" TO "authenticated";

GRANT REFERENCES ON public."task_access_codes" TO "authenticated";

GRANT SELECT ON public."task_access_codes" TO "authenticated";

GRANT TRIGGER ON public."task_access_codes" TO "authenticated";

GRANT TRUNCATE ON public."task_access_codes" TO "authenticated";

GRANT UPDATE ON public."task_access_codes" TO "authenticated";

GRANT DELETE ON public."task_access_codes" TO "service_role";

GRANT INSERT ON public."task_access_codes" TO "service_role";

GRANT REFERENCES ON public."task_access_codes" TO "service_role";

GRANT SELECT ON public."task_access_codes" TO "service_role";

GRANT TRIGGER ON public."task_access_codes" TO "service_role";

GRANT TRUNCATE ON public."task_access_codes" TO "service_role";

GRANT UPDATE ON public."task_access_codes" TO "service_role";

GRANT DELETE ON public."task_assignments" TO "anon";

GRANT INSERT ON public."task_assignments" TO "anon";

GRANT REFERENCES ON public."task_assignments" TO "anon";

GRANT SELECT ON public."task_assignments" TO "anon";

GRANT TRIGGER ON public."task_assignments" TO "anon";

GRANT TRUNCATE ON public."task_assignments" TO "anon";

GRANT UPDATE ON public."task_assignments" TO "anon";

GRANT DELETE ON public."task_assignments" TO "authenticated";

GRANT INSERT ON public."task_assignments" TO "authenticated";

GRANT REFERENCES ON public."task_assignments" TO "authenticated";

GRANT SELECT ON public."task_assignments" TO "authenticated";

GRANT TRIGGER ON public."task_assignments" TO "authenticated";

GRANT TRUNCATE ON public."task_assignments" TO "authenticated";

GRANT UPDATE ON public."task_assignments" TO "authenticated";

GRANT DELETE ON public."task_assignments" TO "service_role";

GRANT INSERT ON public."task_assignments" TO "service_role";

GRANT REFERENCES ON public."task_assignments" TO "service_role";

GRANT SELECT ON public."task_assignments" TO "service_role";

GRANT TRIGGER ON public."task_assignments" TO "service_role";

GRANT TRUNCATE ON public."task_assignments" TO "service_role";

GRANT UPDATE ON public."task_assignments" TO "service_role";

GRANT DELETE ON public."task_checkin_config" TO "anon";

GRANT INSERT ON public."task_checkin_config" TO "anon";

GRANT REFERENCES ON public."task_checkin_config" TO "anon";

GRANT SELECT ON public."task_checkin_config" TO "anon";

GRANT TRIGGER ON public."task_checkin_config" TO "anon";

GRANT TRUNCATE ON public."task_checkin_config" TO "anon";

GRANT UPDATE ON public."task_checkin_config" TO "anon";

GRANT DELETE ON public."task_checkin_config" TO "authenticated";

GRANT INSERT ON public."task_checkin_config" TO "authenticated";

GRANT REFERENCES ON public."task_checkin_config" TO "authenticated";

GRANT SELECT ON public."task_checkin_config" TO "authenticated";

GRANT TRIGGER ON public."task_checkin_config" TO "authenticated";

GRANT TRUNCATE ON public."task_checkin_config" TO "authenticated";

GRANT UPDATE ON public."task_checkin_config" TO "authenticated";

GRANT DELETE ON public."task_checkin_config" TO "service_role";

GRANT INSERT ON public."task_checkin_config" TO "service_role";

GRANT REFERENCES ON public."task_checkin_config" TO "service_role";

GRANT SELECT ON public."task_checkin_config" TO "service_role";

GRANT TRIGGER ON public."task_checkin_config" TO "service_role";

GRANT TRUNCATE ON public."task_checkin_config" TO "service_role";

GRANT UPDATE ON public."task_checkin_config" TO "service_role";

GRANT DELETE ON public."task_comments" TO "anon";

GRANT INSERT ON public."task_comments" TO "anon";

GRANT REFERENCES ON public."task_comments" TO "anon";

GRANT SELECT ON public."task_comments" TO "anon";

GRANT TRIGGER ON public."task_comments" TO "anon";

GRANT TRUNCATE ON public."task_comments" TO "anon";

GRANT UPDATE ON public."task_comments" TO "anon";

GRANT DELETE ON public."task_comments" TO "authenticated";

GRANT INSERT ON public."task_comments" TO "authenticated";

GRANT REFERENCES ON public."task_comments" TO "authenticated";

GRANT SELECT ON public."task_comments" TO "authenticated";

GRANT TRIGGER ON public."task_comments" TO "authenticated";

GRANT TRUNCATE ON public."task_comments" TO "authenticated";

GRANT UPDATE ON public."task_comments" TO "authenticated";

GRANT DELETE ON public."task_comments" TO "service_role";

GRANT INSERT ON public."task_comments" TO "service_role";

GRANT REFERENCES ON public."task_comments" TO "service_role";

GRANT SELECT ON public."task_comments" TO "service_role";

GRANT TRIGGER ON public."task_comments" TO "service_role";

GRANT TRUNCATE ON public."task_comments" TO "service_role";

GRANT UPDATE ON public."task_comments" TO "service_role";

GRANT DELETE ON public."tasks" TO "anon";

GRANT INSERT ON public."tasks" TO "anon";

GRANT REFERENCES ON public."tasks" TO "anon";

GRANT SELECT ON public."tasks" TO "anon";

GRANT TRIGGER ON public."tasks" TO "anon";

GRANT TRUNCATE ON public."tasks" TO "anon";

GRANT UPDATE ON public."tasks" TO "anon";

GRANT DELETE ON public."tasks" TO "authenticated";

GRANT INSERT ON public."tasks" TO "authenticated";

GRANT REFERENCES ON public."tasks" TO "authenticated";

GRANT SELECT ON public."tasks" TO "authenticated";

GRANT TRIGGER ON public."tasks" TO "authenticated";

GRANT TRUNCATE ON public."tasks" TO "authenticated";

GRANT UPDATE ON public."tasks" TO "authenticated";

GRANT DELETE ON public."tasks" TO "service_role";

GRANT INSERT ON public."tasks" TO "service_role";

GRANT REFERENCES ON public."tasks" TO "service_role";

GRANT SELECT ON public."tasks" TO "service_role";

GRANT TRIGGER ON public."tasks" TO "service_role";

GRANT TRUNCATE ON public."tasks" TO "service_role";

GRANT UPDATE ON public."tasks" TO "service_role";

GRANT DELETE ON public."users" TO "anon";

GRANT INSERT ON public."users" TO "anon";

GRANT REFERENCES ON public."users" TO "anon";

GRANT SELECT ON public."users" TO "anon";

GRANT TRIGGER ON public."users" TO "anon";

GRANT TRUNCATE ON public."users" TO "anon";

GRANT UPDATE ON public."users" TO "anon";

GRANT DELETE ON public."users" TO "authenticated";

GRANT INSERT ON public."users" TO "authenticated";

GRANT REFERENCES ON public."users" TO "authenticated";

GRANT SELECT ON public."users" TO "authenticated";

GRANT TRIGGER ON public."users" TO "authenticated";

GRANT TRUNCATE ON public."users" TO "authenticated";

GRANT UPDATE ON public."users" TO "authenticated";

GRANT DELETE ON public."users" TO "service_role";

GRANT INSERT ON public."users" TO "service_role";

GRANT REFERENCES ON public."users" TO "service_role";

GRANT SELECT ON public."users" TO "service_role";

GRANT TRIGGER ON public."users" TO "service_role";

GRANT TRUNCATE ON public."users" TO "service_role";

GRANT UPDATE ON public."users" TO "service_role";

GRANT DELETE ON public."work_day_plan" TO "service_role";

GRANT INSERT ON public."work_day_plan" TO "service_role";

GRANT REFERENCES ON public."work_day_plan" TO "service_role";

GRANT SELECT ON public."work_day_plan" TO "service_role";

GRANT TRIGGER ON public."work_day_plan" TO "service_role";

GRANT TRUNCATE ON public."work_day_plan" TO "service_role";

GRANT UPDATE ON public."work_day_plan" TO "service_role";

GRANT DELETE ON public."work_employee_card_keys" TO "service_role";

GRANT INSERT ON public."work_employee_card_keys" TO "service_role";

GRANT REFERENCES ON public."work_employee_card_keys" TO "service_role";

GRANT SELECT ON public."work_employee_card_keys" TO "service_role";

GRANT TRIGGER ON public."work_employee_card_keys" TO "service_role";

GRANT TRUNCATE ON public."work_employee_card_keys" TO "service_role";

GRANT UPDATE ON public."work_employee_card_keys" TO "service_role";

GRANT DELETE ON public."work_employee_cards" TO "service_role";

GRANT INSERT ON public."work_employee_cards" TO "service_role";

GRANT REFERENCES ON public."work_employee_cards" TO "service_role";

GRANT SELECT ON public."work_employee_cards" TO "service_role";

GRANT TRIGGER ON public."work_employee_cards" TO "service_role";

GRANT TRUNCATE ON public."work_employee_cards" TO "service_role";

GRANT UPDATE ON public."work_employee_cards" TO "service_role";

GRANT DELETE ON public."work_employee_roles" TO "service_role";

GRANT INSERT ON public."work_employee_roles" TO "service_role";

GRANT REFERENCES ON public."work_employee_roles" TO "service_role";

GRANT SELECT ON public."work_employee_roles" TO "service_role";

GRANT TRIGGER ON public."work_employee_roles" TO "service_role";

GRANT TRUNCATE ON public."work_employee_roles" TO "service_role";

GRANT UPDATE ON public."work_employee_roles" TO "service_role";

GRANT DELETE ON public."work_roles" TO "service_role";

GRANT INSERT ON public."work_roles" TO "service_role";

GRANT REFERENCES ON public."work_roles" TO "service_role";

GRANT SELECT ON public."work_roles" TO "service_role";

GRANT TRIGGER ON public."work_roles" TO "service_role";

GRANT TRUNCATE ON public."work_roles" TO "service_role";

GRANT UPDATE ON public."work_roles" TO "service_role";

GRANT DELETE ON public."work_settings" TO "service_role";

GRANT INSERT ON public."work_settings" TO "service_role";

GRANT REFERENCES ON public."work_settings" TO "service_role";

GRANT SELECT ON public."work_settings" TO "service_role";

GRANT TRIGGER ON public."work_settings" TO "service_role";

GRANT TRUNCATE ON public."work_settings" TO "service_role";

GRANT UPDATE ON public."work_settings" TO "service_role";

GRANT DELETE ON public."work_station_keys" TO "service_role";

GRANT INSERT ON public."work_station_keys" TO "service_role";

GRANT REFERENCES ON public."work_station_keys" TO "service_role";

GRANT SELECT ON public."work_station_keys" TO "service_role";

GRANT TRIGGER ON public."work_station_keys" TO "service_role";

GRANT TRUNCATE ON public."work_station_keys" TO "service_role";

GRANT UPDATE ON public."work_station_keys" TO "service_role";

GRANT DELETE ON public."work_station_tickets" TO "service_role";

GRANT INSERT ON public."work_station_tickets" TO "service_role";

GRANT REFERENCES ON public."work_station_tickets" TO "service_role";

GRANT SELECT ON public."work_station_tickets" TO "service_role";

GRANT TRIGGER ON public."work_station_tickets" TO "service_role";

GRANT TRUNCATE ON public."work_station_tickets" TO "service_role";

GRANT UPDATE ON public."work_station_tickets" TO "service_role";

GRANT DELETE ON public."work_stations" TO "service_role";

GRANT INSERT ON public."work_stations" TO "service_role";

GRANT REFERENCES ON public."work_stations" TO "service_role";

GRANT SELECT ON public."work_stations" TO "service_role";

GRANT TRIGGER ON public."work_stations" TO "service_role";

GRANT TRUNCATE ON public."work_stations" TO "service_role";

GRANT UPDATE ON public."work_stations" TO "service_role";

REVOKE ALL ON FUNCTION public.create_task_checkin_config() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.create_task_checkin_config() TO anon;

GRANT EXECUTE ON FUNCTION public.create_task_checkin_config() TO authenticated;

REVOKE ALL ON FUNCTION public.finish_manual_checkin(p_checkin_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.finish_manual_checkin(p_checkin_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.generate_task_access_code(p_task_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.generate_task_access_code(p_task_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon;

GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;

REVOKE ALL ON FUNCTION public.sec01_guard_is_admin() FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION public.sec04_validate_comment_attachment() FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION public.sec06_is_admin() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.sec06_is_admin() TO authenticated;

REVOKE ALL ON FUNCTION public.sec06_task_actor_names(p_task_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.sec06_task_actor_names(p_task_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.sync_confirmed_auth_email() FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION public.validate_nfc_checkin(p_card_uid character varying, p_task_id uuid, p_user_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.validate_nfc_checkin(p_card_uid character varying, p_task_id uuid, p_user_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_admin_metrics(p_start date, p_end date, p_user uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_admin_metrics(p_start date, p_end date, p_user uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_admin_overview(p_user uuid, p_date date) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_admin_overview(p_user uuid, p_date date) TO authenticated;

REVOKE ALL ON FUNCTION public.work_admin_productivity(p_start date, p_end date, p_task uuid, p_user uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_admin_productivity(p_start date, p_end date, p_task uuid, p_user uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_assert_admin() FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION public.work_assert_permission(p_key text) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_assert_permission(p_key text) TO authenticated;

REVOKE ALL ON FUNCTION public.work_can_detail(p_task_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_can_detail(p_task_id uuid) TO anon;

GRANT EXECUTE ON FUNCTION public.work_can_detail(p_task_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_can_file(p_name text) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_can_file(p_name text) TO anon;

GRANT EXECUTE ON FUNCTION public.work_can_file(p_name text) TO authenticated;

REVOKE ALL ON FUNCTION public.work_checkin_history(p_start date, p_end date, p_user uuid, p_task uuid, p_only_open boolean, p_offset integer, p_limit integer, p_personal boolean) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_checkin_history(p_start date, p_end date, p_user uuid, p_task uuid, p_only_open boolean, p_offset integer, p_limit integer, p_personal boolean) TO authenticated;

REVOKE ALL ON FUNCTION public.work_create_credential(p_kind text, p_name text, p_user uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_create_credential(p_kind text, p_name text, p_user uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_create_hashed_credential(p_kind text, p_name text, p_user uuid) FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION public.work_deadline(p_day date, p_state text, p_finished timestamp with time zone) FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION public.work_delete_credential(p_kind text, p_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_delete_credential(p_kind text, p_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_delete_role(p_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_delete_role(p_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_detail_access(p_task_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_detail_access(p_task_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_employee_directory() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_employee_directory() TO authenticated;

REVOKE ALL ON FUNCTION public.work_get_card_key(p_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_get_card_key(p_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_get_station_key(p_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_get_station_key(p_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_guard_assignment() FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION public.work_guard_checkin() FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION public.work_has_permission(p_key text) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_has_permission(p_key text) TO authenticated;

REVOKE ALL ON FUNCTION public.work_hash(p_value text) FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION public.work_home_summary() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_home_summary() TO authenticated;

REVOKE ALL ON FUNCTION public.work_legacy_actor_names(p_task_id uuid) FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION public.work_manage_task(p_action text, p_id uuid, p_title text, p_description text, p_schedule text, p_date date, p_status text, p_users uuid[]) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_manage_task(p_action text, p_id uuid, p_title text, p_description text, p_schedule text, p_date date, p_status text, p_users uuid[]) TO authenticated;

REVOKE ALL ON FUNCTION public.work_mode() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_mode() TO anon;

GRANT EXECUTE ON FUNCTION public.work_mode() TO authenticated;

REVOKE ALL ON FUNCTION public.work_my_day() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_my_day() TO authenticated;

REVOKE ALL ON FUNCTION public.work_my_permissions() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_my_permissions() TO authenticated;

REVOKE ALL ON FUNCTION public.work_overdue_items(p_limit integer) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_overdue_items(p_limit integer) TO authenticated;

REVOKE ALL ON FUNCTION public.work_planning_assignments(p_user uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_planning_assignments(p_user uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_planning_calendar(p_user uuid, p_start date, p_end date) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_planning_calendar(p_user uuid, p_start date, p_end date) TO authenticated;

REVOKE ALL ON FUNCTION public.work_revoke_credential(p_kind text, p_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_revoke_credential(p_kind text, p_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_roles_overview() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_roles_overview() TO authenticated;

REVOKE ALL ON FUNCTION public.work_rotate_card_key(p_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_rotate_card_key(p_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_rotate_station_key(p_id uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_rotate_station_key(p_id uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_save_card_key(p_id uuid, p_token text) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_save_card_key(p_id uuid, p_token text) TO authenticated;

REVOKE ALL ON FUNCTION public.work_save_employee_profile(p_user uuid, p_name text, p_whatsapp text, p_role uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_save_employee_profile(p_user uuid, p_name text, p_whatsapp text, p_role uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_save_plan(p_user uuid, p_date date, p_tasks uuid[]) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_save_plan(p_user uuid, p_date date, p_tasks uuid[]) TO authenticated;

REVOKE ALL ON FUNCTION public.work_save_plan_range(p_user uuid, p_start date, p_end date, p_tasks uuid[], p_weekdays integer[], p_existing text) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_save_plan_range(p_user uuid, p_start date, p_end date, p_tasks uuid[], p_weekdays integer[], p_existing text) TO authenticated;

REVOKE ALL ON FUNCTION public.work_save_role(p_id uuid, p_name text, p_description text, p_active boolean) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_save_role(p_id uuid, p_name text, p_description text, p_active boolean) TO authenticated;

REVOKE ALL ON FUNCTION public.work_save_station_key(p_id uuid, p_token text) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_save_station_key(p_id uuid, p_token text) TO authenticated;

REVOKE ALL ON FUNCTION public.work_set_card_active(p_id uuid, p_active boolean) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_set_card_active(p_id uuid, p_active boolean) TO authenticated;

REVOKE ALL ON FUNCTION public.work_set_mode(p_enabled boolean) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_set_mode(p_enabled boolean) TO authenticated;

REVOKE ALL ON FUNCTION public.work_set_role_permissions(p_id uuid, p_permissions text[]) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_set_role_permissions(p_id uuid, p_permissions text[]) TO authenticated;

REVOKE ALL ON FUNCTION public.work_set_station_active(p_id uuid, p_active boolean) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_set_station_active(p_id uuid, p_active boolean) TO authenticated;

REVOKE ALL ON FUNCTION public.work_station_confirm(p_station text, p_ticket uuid, p_action text) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_station_confirm(p_station text, p_ticket uuid, p_action text) TO anon;

GRANT EXECUTE ON FUNCTION public.work_station_confirm(p_station text, p_ticket uuid, p_action text) TO authenticated;

REVOKE ALL ON FUNCTION public.work_station_day(p_station text, p_ticket uuid) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_station_day(p_station text, p_ticket uuid) TO anon;

GRANT EXECUTE ON FUNCTION public.work_station_day(p_station text, p_ticket uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.work_station_identify(p_station text, p_card text) FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_station_identify(p_station text, p_card text) TO anon;

GRANT EXECUTE ON FUNCTION public.work_station_identify(p_station text, p_card text) TO authenticated;

REVOKE ALL ON FUNCTION public.work_task_catalog() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_task_catalog() TO authenticated;

REVOKE ALL ON FUNCTION public.work_task_options() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_task_options() TO authenticated;

REVOKE ALL ON FUNCTION public.work_today() FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION public.work_today() TO anon;

GRANT EXECUTE ON FUNCTION public.work_today() TO authenticated;
