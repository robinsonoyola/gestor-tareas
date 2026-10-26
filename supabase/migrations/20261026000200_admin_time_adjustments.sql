-- ASE Work: auditable administrative creation and correction of closed time records.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE public.work_time_adjustments(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_id uuid NOT NULL,
 checkin_id uuid NOT NULL,
 actor_id uuid NOT NULL,
 request_id uuid NOT NULL,
 action text NOT NULL CHECK(action IN('create','correct')),
 reason text NOT NULL CHECK(char_length(reason) BETWEEN 5 AND 2000),
 previous_values jsonb,
 new_values jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(organization_id,request_id),
 FOREIGN KEY(checkin_id) REFERENCES public.checkins(id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES public.organization_memberships(organization_id,user_id)
);
ALTER TABLE public.work_time_adjustments ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_time_adjustments FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_time_adjustments TO ase_tenant_executor;
CREATE POLICY work_time_adjustments_executor ON public.work_time_adjustments TO ase_tenant_executor
 USING(organization_id=ase_private.current_org())
 WITH CHECK(organization_id=ase_private.current_org() AND actor_id=auth.uid());

CREATE OR REPLACE FUNCTION public.work_admin_adjust_time(p_checkin uuid,p_user uuid,p_task uuid,p_start timestamptz,p_end timestamptz,p_reason text,p_request uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE org uuid;actor uuid;old_row public.checkins%rowtype;target uuid;existing uuid;action text;
BEGIN
 PERFORM public.work_assert_admin();org:=ase_private.current_org();actor:=auth.uid();
 IF p_request IS NULL OR p_start IS NULL OR p_end IS NULL OR p_end<=p_start OR p_end-p_start>interval '7 days' OR p_end>clock_timestamp()+interval '5 minutes' OR char_length(btrim(coalesce(p_reason,''))) NOT BETWEEN 5 AND 2000 THEN RAISE EXCEPTION 'Revisa las horas y escribe un motivo de 5 a 2000 caracteres';END IF;
 SELECT checkin_id INTO existing FROM public.work_time_adjustments WHERE organization_id=org AND request_id=p_request;
 IF existing IS NOT NULL THEN RETURN jsonb_build_object('id',existing,'already_applied',true);END IF;
 IF p_checkin IS NULL THEN
  action:='create';
  IF p_user IS NULL OR p_task IS NULL OR NOT EXISTS(SELECT 1 FROM public.organization_memberships m WHERE m.organization_id=org AND m.user_id=p_user AND m.status='active') OR NOT EXISTS(SELECT 1 FROM public.tasks t WHERE t.organization_id=org AND t.id=p_task) THEN RAISE EXCEPTION 'Selecciona un empleado y una tarea válidos';END IF;
  IF EXISTS(SELECT 1 FROM public.checkins c WHERE c.organization_id=org AND c.user_id=p_user AND tstzrange(c.checkin_time,coalesce(c.checkout_time,'infinity'::timestamptz),'[)')&&tstzrange(p_start,p_end,'[)')) THEN RAISE EXCEPTION 'El período se solapa con otro fichaje del empleado';END IF;
  INSERT INTO public.checkins(organization_id,task_id,user_id,checkin_time,checkout_time,checkin_method,location) VALUES(org,p_task,p_user,p_start,p_end,'manual','Ajuste administrativo') RETURNING id INTO target;
  INSERT INTO public.work_time_adjustments(organization_id,checkin_id,actor_id,request_id,action,reason,new_values) VALUES(org,target,actor,p_request,action,btrim(p_reason),jsonb_build_object('user_id',p_user,'task_id',p_task,'start',p_start,'end',p_end));
 ELSE
  action:='correct';
  SELECT * INTO old_row FROM public.checkins WHERE organization_id=org AND id=p_checkin FOR UPDATE;
  IF old_row.id IS NULL THEN RAISE EXCEPTION 'El fichaje no existe';END IF;
  IF old_row.checkout_time IS NULL THEN RAISE EXCEPTION 'Detén primero el fichaje activo';END IF;
  IF p_user IS NOT NULL AND p_user<>old_row.user_id OR p_task IS NOT NULL AND p_task<>old_row.task_id THEN RAISE EXCEPTION 'Una corrección no puede cambiar empleado ni tarea';END IF;
  IF EXISTS(SELECT 1 FROM public.checkins c WHERE c.organization_id=org AND c.user_id=old_row.user_id AND c.id<>old_row.id AND tstzrange(c.checkin_time,coalesce(c.checkout_time,'infinity'::timestamptz),'[)')&&tstzrange(p_start,p_end,'[)')) THEN RAISE EXCEPTION 'El período se solapa con otro fichaje del empleado';END IF;
  UPDATE public.checkins SET checkin_time=p_start,checkout_time=p_end WHERE organization_id=org AND id=old_row.id;target:=old_row.id;
  INSERT INTO public.work_time_adjustments(organization_id,checkin_id,actor_id,request_id,action,reason,previous_values,new_values) VALUES(org,target,actor,p_request,action,btrim(p_reason),jsonb_build_object('start',old_row.checkin_time,'end',old_row.checkout_time),jsonb_build_object('start',p_start,'end',p_end));
 END IF;
 RETURN jsonb_build_object('id',target,'already_applied',false);
END $$;

CREATE OR REPLACE FUNCTION public.work_time_adjustment_history(p_checkin uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',h.id,'action',h.action,'reason',h.reason,'previous',h.previous_values,'new',h.new_values,'actor',coalesce(u.full_name,'Administrador'),'created_at',h.created_at) ORDER BY h.created_at DESC,h.id),'[]'::jsonb)
 FROM public.work_time_adjustments h LEFT JOIN ase_private.employee_profiles u ON u.id=h.actor_id
 WHERE h.organization_id=ase_private.current_org() AND h.checkin_id=p_checkin AND (public.work_has_permission('checkins.view') OR h.actor_id=auth.uid())
$$;

ALTER FUNCTION public.work_admin_adjust_time(uuid,uuid,uuid,timestamptz,timestamptz,text,uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_time_adjustment_history(uuid) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_admin_adjust_time(uuid,uuid,uuid,timestamptz,timestamptz,text,uuid),public.work_time_adjustment_history(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_admin_adjust_time(uuid,uuid,uuid,timestamptz,timestamptz,text,uuid),public.work_time_adjustment_history(uuid) TO authenticated,ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
