-- ASE Work - Pruebas: automatic code identification; NFC credentials unchanged.
BEGIN;
CREATE OR REPLACE FUNCTION public.work_pin_settings(p_user uuid,p_pin text DEFAULT NULL,p_active boolean DEFAULT true) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE value text;BEGIN
 PERFORM public.work_assert_admin();
 PERFORM pg_advisory_xact_lock(hashtextextended(ase_private.current_org()::text,0));
 PERFORM 1 FROM ase_private.employee_profiles WHERE id=p_user AND NOT is_admin AND membership_status='active' FOR UPDATE;
 IF NOT FOUND OR p_active IS NULL THEN RAISE EXCEPTION 'Empleado no disponible'; END IF;
 IF NOT p_active THEN UPDATE public.work_personal_pins SET active=false WHERE user_id=p_user;RETURN jsonb_build_object('active',false);END IF;
 value:=coalesce(nullif(btrim(p_pin),''),lpad((('x'||encode(extensions.gen_random_bytes(4),'hex'))::bit(32)::bigint % 100000)::text,5,'0'));
 IF value !~ '^[0-9]{5}$' THEN RAISE EXCEPTION 'El PIN debe tener exactamente 5 dígitos'; END IF;
 IF EXISTS(SELECT 1 FROM public.work_personal_pins WHERE active AND user_id<>p_user AND pin_hash=extensions.crypt(value,pin_hash)) THEN RAISE EXCEPTION 'Ese código ya está asignado. Elige otro código de 5 dígitos'; END IF;
 INSERT INTO public.work_personal_pins(user_id,pin_hash) VALUES(p_user,extensions.crypt(value,extensions.gen_salt('bf',10)))
 ON CONFLICT(organization_id,user_id) DO UPDATE SET pin_hash=EXCLUDED.pin_hash,active=true,failures=0,locked_until=NULL,updated_at=clock_timestamp();
 RETURN jsonb_build_object('active',true,'pin',value);
END $$;
CREATE OR REPLACE FUNCTION public.work_station_identify_v2(p_station text, p_card text DEFAULT NULL, p_method text DEFAULT 'manual', p_user uuid DEFAULT NULL)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE s public.work_stations%ROWTYPE; c public.work_employee_cards%ROWTYPE; p public.work_day_plan%ROWTYPE;
 v_ticket uuid; v_action text:='none'; v_name text; v_title text; v_description text; pin public.work_personal_pins%ROWTYPE; attempt_row public.work_pin_attempts%ROWTYPE; selected_user uuid; matches uuid[];
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
  IF p_user IS NULL THEN
   IF p_card IS NOT NULL AND p_card ~ '^[0-9]{5}$' THEN
    SELECT array_agg(candidate.user_id) INTO matches FROM (
     SELECT x.user_id FROM public.work_personal_pins x
     JOIN ase_private.employee_profiles u ON u.id=x.user_id AND u.membership_status='active' AND NOT u.is_admin
     WHERE x.active AND x.pin_hash=extensions.crypt(p_card,x.pin_hash) LIMIT 2
    ) candidate;
   END IF;
   IF coalesce(cardinality(matches),0)<>1 THEN
    UPDATE public.work_pin_attempts SET attempts=attempts+1 WHERE station_id=s.id;
    RETURN jsonb_build_object('error','Código no disponible. Comprueba los 5 dígitos o consulta al administrador.');
   END IF;
   p_user:=matches[1];
  END IF;
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

ALTER FUNCTION public.work_pin_settings(uuid,text,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_station_identify_v2(text,text,text,uuid) OWNER TO ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
