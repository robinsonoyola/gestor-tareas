-- NFC attached to a task: explicit action, authenticated user and expected check-in.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE OR REPLACE FUNCTION public.work_task_nfc_checkin(p_card_uid text,p_task uuid,p_action text,p_expected_checkin uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=ase_private.session_user_id(); card public.nfc_cards%ROWTYPE;
 current_checkin public.checkins%ROWTYPE; result_id uuid; normalized text; matches integer; closed_at timestamptz;
BEGIN
 IF actor IS NULL OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR ase_private.current_org() IS NULL THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Inicia sesión para fichar';
 END IF;
 IF public.work_mode() THEN RAISE EXCEPTION 'Está activo el modo exclusivo de punto compartido. Confirma allí el fichaje'; END IF;
 IF p_action IS NULL OR p_action NOT IN ('checkin','checkout') OR p_task IS NULL THEN RAISE EXCEPTION 'Acción de fichaje no válida'; END IF;
 normalized:=lower(regexp_replace(coalesce(p_card_uid,''),'[[:space:]:-]','','g'));
 IF normalized !~ '^([0-9a-f]{2}){4,16}$' THEN RAISE EXCEPTION 'No se pudo leer el UID físico de la tarjeta'; END IF;
 -- Serialize a user's mobile NFC requests before checking open records.
 PERFORM 1 FROM public.organization_memberships WHERE user_id=actor AND organization_id=ase_private.current_org() AND status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Sesión no disponible'; END IF;
 PERFORM 1 FROM public.tasks t JOIN public.task_assignments a ON a.task_id=t.id AND a.organization_id=t.organization_id
 WHERE t.id=p_task AND a.user_id=actor FOR SHARE OF t,a;
 IF NOT FOUND THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Tarea no disponible o no asignada'; END IF;
 PERFORM 1 FROM public.task_checkin_config WHERE task_id=p_task AND nfc_enabled FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'El NFC no está habilitado para esta tarea'; END IF;
 SELECT count(*) INTO matches FROM public.nfc_cards c WHERE c.task_id=p_task AND c.is_active
 AND lower(regexp_replace(c.card_uid,'[[:space:]:-]','','g'))=normalized;
 IF matches<>1 THEN RAISE EXCEPTION 'Tarjeta no disponible para esta tarea'; END IF;
 SELECT * INTO card FROM public.nfc_cards c WHERE c.task_id=p_task AND c.is_active
 AND lower(regexp_replace(c.card_uid,'[[:space:]:-]','','g'))=normalized FOR SHARE;
 IF p_action='checkin' THEN
  IF p_expected_checkin IS NOT NULL THEN RAISE EXCEPTION 'Actualiza el estado del fichaje antes de iniciar'; END IF;
  PERFORM 1 FROM public.checkins WHERE user_id=actor AND checkout_time IS NULL FOR UPDATE;
  IF FOUND THEN RAISE EXCEPTION 'Ya tienes un fichaje abierto. Finalízalo antes de iniciar otro'; END IF;
  INSERT INTO public.checkins(task_id,user_id,checkin_method,nfc_card_id,checkin_time)
  VALUES(p_task,actor,'nfc',card.id,clock_timestamp()) RETURNING id INTO result_id;
 ELSE
  IF p_expected_checkin IS NULL THEN RAISE EXCEPTION 'Actualiza el estado del fichaje antes de finalizar'; END IF;
  SELECT * INTO current_checkin FROM public.checkins WHERE id=p_expected_checkin AND task_id=p_task AND user_id=actor FOR UPDATE;
  IF current_checkin.id IS NULL OR current_checkin.checkin_method<>'nfc' OR current_checkin.nfc_card_id IS DISTINCT FROM card.id THEN
   RAISE EXCEPTION 'Ese fichaje no corresponde a esta tarjeta y tarea';
  END IF;
  -- Retrying a confirmed close returns the same record, never starts a new one.
  IF current_checkin.checkout_time IS NOT NULL THEN
   RETURN jsonb_build_object('success',true,'type','checkout','checkin_id',current_checkin.id,'checkout_time',current_checkin.checkout_time,'already_closed',true);
  END IF;
  closed_at:=clock_timestamp();
  UPDATE public.checkins SET checkout_time=closed_at WHERE id=current_checkin.id;
  result_id:=current_checkin.id;
 END IF;
 RETURN jsonb_build_object('success',true,'type',p_action,'checkin_id',result_id,'checkout_time',closed_at);
END $$;
ALTER FUNCTION public.work_task_nfc_checkin(text,uuid,text,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_task_nfc_checkin(text,uuid,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_task_nfc_checkin(text,uuid,text,uuid) TO authenticated,ase_tenant_executor;
-- Retire the old toggle endpoint, which could close a record merely by reading twice.
CREATE OR REPLACE FUNCTION public.validate_nfc_checkin(p_card_uid character varying,p_task_id uuid,p_user_id uuid)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 RETURN json_build_object('success',false,'message','Actualiza la aplicación y confirma expresamente el inicio o la finalización del fichaje NFC');
END $$;
ALTER FUNCTION public.validate_nfc_checkin(character varying,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.validate_nfc_checkin(character varying,uuid,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.validate_nfc_checkin(character varying,uuid,uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
