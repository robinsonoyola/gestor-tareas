-- ASE Work: all operational mutations go through audited tenant-scoped functions.
BEGIN;

CREATE OR REPLACE FUNCTION public.work_manage_nfc_card(
 p_action text,p_id uuid DEFAULT NULL,p_uid text DEFAULT NULL,p_name text DEFAULT NULL,
 p_task uuid DEFAULT NULL,p_notes text DEFAULT NULL,p_active boolean DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $function$
DECLARE v_org uuid:=ase_private.current_org();v_id uuid;v_uid text:=lower(regexp_replace(coalesce(p_uid,''),'[[:space:]:-]','','g'));
BEGIN
 PERFORM public.work_assert_admin();
 IF p_action NOT IN('create','edit','state','delete') THEN RAISE EXCEPTION 'Acción no válida';END IF;
 IF p_task IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=v_org AND id=p_task AND archived_at IS NULL) THEN RAISE EXCEPTION 'Tarea no disponible';END IF;
 IF p_name IS NOT NULL AND length(trim(p_name))>100 THEN RAISE EXCEPTION 'Nombre demasiado largo';END IF;
 IF p_notes IS NOT NULL AND length(trim(p_notes))>2000 THEN RAISE EXCEPTION 'Notas demasiado largas';END IF;
 IF p_action='create' THEN
  IF length(v_uid) NOT BETWEEN 8 AND 32 OR length(v_uid)%2<>0 OR v_uid !~ '^[0-9a-f]+$' THEN RAISE EXCEPTION 'UID de tarjeta no válido';END IF;
  INSERT INTO public.nfc_cards(organization_id,card_uid,card_name,task_id,notes,assigned_at)
  VALUES(v_org,v_uid,nullif(trim(p_name),''),p_task,nullif(trim(p_notes),''),CASE WHEN p_task IS NULL THEN NULL ELSE now() END)
  RETURNING id INTO v_id;
 ELSIF p_action='edit' THEN
  UPDATE public.nfc_cards SET card_name=nullif(trim(p_name),''),task_id=p_task,notes=nullif(trim(p_notes),''),assigned_at=CASE WHEN p_task IS NULL THEN NULL ELSE now() END
  WHERE organization_id=v_org AND id=p_id RETURNING id INTO v_id;
 ELSIF p_action='state' THEN
  IF p_active IS NULL THEN RAISE EXCEPTION 'Estado no válido';END IF;
  UPDATE public.nfc_cards SET is_active=p_active WHERE organization_id=v_org AND id=p_id RETURNING id INTO v_id;
 ELSE
  DELETE FROM public.nfc_cards WHERE organization_id=v_org AND id=p_id RETURNING id INTO v_id;
 END IF;
 IF v_id IS NULL THEN RAISE EXCEPTION 'Tarjeta no disponible';END IF;
 RETURN v_id;
END $function$;

CREATE OR REPLACE FUNCTION public.work_set_task_access_active(p_id uuid,p_active boolean) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $function$
BEGIN
 PERFORM public.work_assert_admin();
 UPDATE public.task_access_codes SET is_active=p_active WHERE organization_id=ase_private.current_org() AND id=p_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Código no disponible';END IF;
END $function$;

CREATE OR REPLACE FUNCTION public.work_save_checkin_methods(p_task uuid,p_nfc boolean,p_qr boolean,p_manual boolean) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $function$
BEGIN
 PERFORM public.work_assert_admin();
 IF NOT EXISTS(SELECT 1 FROM public.tasks WHERE organization_id=ase_private.current_org() AND id=p_task AND archived_at IS NULL) THEN RAISE EXCEPTION 'Tarea no disponible';END IF;
 UPDATE public.task_checkin_config SET nfc_enabled=coalesce(p_nfc,false),qr_enabled=coalesce(p_qr,false),manual_enabled=coalesce(p_manual,false),updated_at=now()
 WHERE organization_id=ase_private.current_org() AND task_id=p_task;
 IF NOT FOUND THEN RAISE EXCEPTION 'Configuración no disponible';END IF;
END $function$;

CREATE OR REPLACE FUNCTION public.work_set_task_location(p_task uuid,p_latitude numeric,p_longitude numeric,p_radius integer DEFAULT 50) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $function$
BEGIN
 PERFORM public.work_assert_permission('tasks.edit');
 IF (p_latitude IS NULL)<>(p_longitude IS NULL) OR p_latitude NOT BETWEEN -90 AND 90 OR p_longitude NOT BETWEEN -180 AND 180 OR p_radius NOT BETWEEN 1 AND 100000 THEN RAISE EXCEPTION 'Ubicación no válida';END IF;
 UPDATE public.tasks SET expected_latitude=p_latitude,expected_longitude=p_longitude,location_radius=p_radius
 WHERE organization_id=ase_private.current_org() AND id=p_task AND archived_at IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Tarea no disponible';END IF;
END $function$;

ALTER FUNCTION public.work_manage_nfc_card(text,uuid,text,text,uuid,text,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_set_task_access_active(uuid,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_save_checkin_methods(uuid,boolean,boolean,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_set_task_location(uuid,numeric,numeric,integer) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_nfc_card(text,uuid,text,text,uuid,text,boolean),public.work_set_task_access_active(uuid,boolean),public.work_save_checkin_methods(uuid,boolean,boolean,boolean),public.work_set_task_location(uuid,numeric,numeric,integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_manage_nfc_card(text,uuid,text,text,uuid,text,boolean),public.work_set_task_access_active(uuid,boolean),public.work_save_checkin_methods(uuid,boolean,boolean,boolean),public.work_set_task_location(uuid,numeric,numeric,integer) TO authenticated,ase_tenant_executor;

REVOKE INSERT,UPDATE,DELETE ON TABLE public.nfc_cards,public.task_access_codes,public.task_checkin_config,public.tasks FROM authenticated;

NOTIFY pgrst,'reload schema';
COMMIT;
