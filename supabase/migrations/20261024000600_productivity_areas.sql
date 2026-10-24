-- ASE Work: productivity reports filtered by work area.
BEGIN;

CREATE OR REPLACE FUNCTION public.work_admin_productivity_area(p_start date, p_end date, p_task uuid, p_area uuid)
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
 IF p_area IS NULL OR NOT EXISTS(SELECT 1 FROM public.work_areas WHERE id=p_area AND active) THEN RAISE EXCEPTION 'Área no válida'; END IF;
 v_from:=p_start::timestamp AT TIME ZONE 'Europe/Madrid'; v_to:=(p_end+1)::timestamp AT TIME ZONE 'Europe/Madrid';
 WITH samples AS (
  SELECT c.id,c.user_id,u.full_name AS name,c.checkin_time,c.checkout_time,
   (c.checkout_time AT TIME ZONE 'Europe/Madrid')::date AS day,
   extract(epoch FROM c.checkout_time-c.checkin_time)::double precision AS seconds
  FROM public.checkins c JOIN ase_private.employee_profiles u ON u.id=c.user_id AND u.is_admin IS FALSE
  WHERE c.task_id=p_task AND EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=p_area AND m.user_id=c.user_id)
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
  'invalid',(SELECT count(*) FROM public.checkins c JOIN ase_private.employee_profiles u ON u.id=c.user_id AND u.is_admin IS FALSE WHERE c.task_id=p_task AND EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.area_id=p_area AND m.user_id=c.user_id) AND c.checkout_time>=v_from AND c.checkout_time<v_to AND (c.checkin_time IS NULL OR c.checkout_time<=c.checkin_time)),
  'as_of',now()) INTO result;
 RETURN result;
END $function$;

-- PostgreSQL requires the future owner to be able to create objects in the
-- function's schema while ownership is transferred. Keep this privilege only
-- for the ALTER OWNER statement.
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;
ALTER FUNCTION public.work_admin_productivity_area(date,date,uuid,uuid) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_admin_productivity_area(date,date,uuid,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_admin_productivity_area(date,date,uuid,uuid) TO ase_tenant_executor,authenticated;

COMMIT;
