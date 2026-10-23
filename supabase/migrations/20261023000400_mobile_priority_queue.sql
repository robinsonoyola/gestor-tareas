BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
CREATE FUNCTION public.work_incident_resolver(p_task uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.work_incidents i WHERE i.organization_id=ase_private.current_org()
 AND i.task_id=p_task AND i.state IN ('open','in_progress') AND
 (i.assigned_user=ase_private.session_user_id() OR EXISTS(SELECT 1 FROM public.work_area_members m
 WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id AND m.user_id=ase_private.session_user_id())))
$$;
CREATE FUNCTION public.work_mobile_queue() RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 WITH items AS (
 SELECT t.id task_id,t.title,p.id plan_id,p.priority,p.work_date,
 CASE WHEN o.id IS NOT NULL THEN 'active' WHEN p.state IN ('completed','blocked') THEN p.state
 WHEN c.id IS NOT NULL AND (p.id IS NULL OR c.checkin_time>=p.created_at) THEN 'completed'
 WHEN p.state IS NOT NULL THEN p.state ELSE 'unplanned' END state,
 public.work_incident_resolver(t.id) incident
 FROM public.tasks t
 LEFT JOIN LATERAL (SELECT * FROM public.work_day_plan x WHERE x.organization_id=t.organization_id AND x.task_id=t.id
 AND x.user_id=ase_private.session_user_id() AND (x.work_date=public.work_today() OR x.state='active')
 ORDER BY (x.state='active') DESC,x.work_date DESC LIMIT 1) p ON true
 LEFT JOIN LATERAL (SELECT id FROM public.checkins x WHERE x.organization_id=t.organization_id AND x.task_id=t.id AND x.user_id=ase_private.session_user_id()
 AND x.checkout_time IS NULL LIMIT 1) o ON true
 LEFT JOIN LATERAL (SELECT id,checkin_time FROM public.checkins x WHERE x.organization_id=t.organization_id AND x.task_id=t.id AND x.user_id=ase_private.session_user_id()
 AND x.checkout_time IS NOT NULL AND (x.checkin_time AT TIME ZONE 'Europe/Madrid')::date=public.work_today() ORDER BY x.checkin_time DESC LIMIT 1) c ON true
 WHERE t.organization_id=ase_private.current_org() AND (EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=t.organization_id AND a.task_id=t.id AND a.user_id=ase_private.session_user_id()) OR public.work_incident_resolver(t.id))
 ), next_item AS (SELECT task_id FROM items WHERE state='pending' AND work_date=public.work_today() ORDER BY priority,task_id LIMIT 1),
 opened AS (SELECT EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=ase_private.current_org() AND user_id=ase_private.session_user_id() AND checkout_time IS NULL) v)
 SELECT jsonb_build_object('date',public.work_today(),'next_task',(SELECT task_id FROM next_item),
 'items',coalesce((SELECT jsonb_agg(to_jsonb(i)||jsonb_build_object('can_start',NOT opened.v AND (i.task_id=(SELECT task_id FROM next_item) OR i.incident),
 'can_finish',i.state='active') ORDER BY (i.state='completed'),(i.state='active') DESC,i.priority NULLS LAST,i.task_id) FROM items i CROSS JOIN opened),'[]'::jsonb))
$$;
ALTER TABLE public.checkins ADD COLUMN work_incident_id uuid;
ALTER TABLE public.checkins ADD CONSTRAINT checkin_incident_scope FOREIGN KEY(organization_id,work_incident_id) REFERENCES public.work_incidents(organization_id,id);
CREATE FUNCTION public.work_mobile_order_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb;incident uuid;
BEGIN
 IF public.work_mode() OR ase_private.session_role() IS DISTINCT FROM 'authenticated' OR public.sec06_is_admin() THEN RETURN NEW; END IF;
 IF NEW.user_id IS DISTINCT FROM ase_private.session_user_id() THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible'; END IF;
 PERFORM 1 FROM public.organization_memberships WHERE organization_id=ase_private.current_org() AND user_id=NEW.user_id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.checkins WHERE organization_id=NEW.organization_id AND user_id=NEW.user_id AND checkout_time IS NULL) THEN RAISE EXCEPTION 'Finaliza primero tu fichaje activo'; END IF;
 SELECT x INTO item FROM jsonb_array_elements(public.work_mobile_queue()->'items') x WHERE x->>'task_id'=NEW.task_id::text;
 IF item IS NULL OR NOT coalesce((item->>'can_start')::boolean,false) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Esta tarea está en consulta. Ficha en la siguiente tarea según el orden del encargado'; END IF;
 IF item->>'task_id'=public.work_mobile_queue()->>'next_task' THEN NEW.work_plan_id:=(item->>'plan_id')::uuid;
 ELSE
  SELECT i.id INTO incident FROM public.work_incidents i WHERE i.organization_id=NEW.organization_id AND i.task_id=NEW.task_id AND i.state IN ('open','in_progress')
  AND (i.assigned_user=NEW.user_id OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=i.organization_id AND m.area_id=i.area_id AND m.user_id=NEW.user_id)) ORDER BY i.created_at LIMIT 1;
  NEW.work_incident_id:=incident;
 END IF;
 RETURN NEW;
END $$;
CREATE FUNCTION public.work_mobile_plan_sync() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NEW.work_plan_id IS NOT NULL THEN
  IF TG_OP='INSERT' THEN UPDATE public.work_day_plan SET state='active',started_at=NEW.checkin_time,finished_at=NULL WHERE organization_id=NEW.organization_id AND id=NEW.work_plan_id AND user_id=NEW.user_id AND state='pending';
  ELSIF OLD.checkout_time IS NULL AND NEW.checkout_time IS NOT NULL THEN
   UPDATE public.work_day_plan SET state='completed',finished_at=NEW.checkout_time WHERE organization_id=NEW.organization_id AND id=NEW.work_plan_id AND user_id=NEW.user_id AND state='active';
  END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER work_mobile_order BEFORE INSERT ON public.checkins FOR EACH ROW EXECUTE FUNCTION public.work_mobile_order_guard();
CREATE TRIGGER work_mobile_sync AFTER INSERT OR UPDATE OF checkout_time ON public.checkins FOR EACH ROW EXECUTE FUNCTION public.work_mobile_plan_sync();
-- Assigned employees may consult details and history without reopening their work.
CREATE OR REPLACE FUNCTION public.work_can_detail(p_task_id uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT ase_private.session_user_id() IS NOT NULL AND (public.sec06_is_admin() OR EXISTS(SELECT 1 FROM public.task_assignments WHERE organization_id=ase_private.current_org() AND task_id=p_task_id AND user_id=ase_private.session_user_id()) OR public.work_incident_resolver(p_task_id))
$$;
CREATE POLICY mobile_manual_insert ON public.checkins FOR INSERT TO authenticated WITH CHECK(user_id=ase_private.session_user_id() AND checkin_method='manual' AND checkout_time IS NULL AND work_station_id IS NULL AND employee_card_id IS NULL AND nfc_card_id IS NULL AND work_plan_id IS NOT NULL AND EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=checkins.organization_id AND a.task_id=checkins.task_id AND a.user_id=ase_private.session_user_id()));
CREATE POLICY incident_task_read ON public.tasks FOR SELECT TO authenticated USING(public.work_incident_resolver(id));
CREATE POLICY incident_config_read ON public.task_checkin_config FOR SELECT TO authenticated USING(public.work_incident_resolver(task_id));
CREATE POLICY incident_checkins_read ON public.checkins FOR SELECT TO authenticated USING(public.work_incident_resolver(task_id));
CREATE POLICY incident_comments_read ON public.task_comments FOR SELECT TO authenticated USING(public.work_incident_resolver(task_id));
CREATE POLICY incident_comments_insert ON public.task_comments FOR INSERT TO authenticated WITH CHECK(user_id=ase_private.session_user_id() AND public.work_incident_resolver(task_id));
CREATE POLICY incident_upload ON storage.objects FOR INSERT TO authenticated WITH CHECK(bucket_id='task-files' AND name ~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov)$' AND split_part(name,'/',3)=ase_private.session_user_id()::text AND public.work_incident_resolver(split_part(name,'/',2)::uuid));
DO $$ DECLARE f text; BEGIN
 FOREACH f IN ARRAY ARRAY['work_incident_resolver(uuid)','work_mobile_queue()','work_mobile_order_guard()','work_mobile_plan_sync()'] LOOP
 EXECUTE 'ALTER FUNCTION public.'||f||' OWNER TO ase_tenant_executor';
 EXECUTE 'REVOKE ALL ON FUNCTION public.'||f||' FROM PUBLIC,anon,authenticated';
 END LOOP;
END $$;
GRANT EXECUTE ON FUNCTION public.work_incident_resolver(uuid),public.work_mobile_queue() TO authenticated,ase_tenant_executor;
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
 PERFORM 1 FROM public.tasks t LEFT JOIN public.task_assignments a ON a.task_id=t.id AND a.organization_id=t.organization_id AND a.user_id=actor
 WHERE t.id=p_task AND (a.user_id=actor OR public.work_incident_resolver(p_task)) FOR SHARE OF t;
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

REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
