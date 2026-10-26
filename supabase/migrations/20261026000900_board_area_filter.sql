-- ASE Work: filter the planning board by work area.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_planning_board_range(p_start date,p_end date,p_user uuid DEFAULT NULL,p_state text DEFAULT NULL,p_query text DEFAULT NULL,p_area uuid DEFAULT NULL,p_limit integer DEFAULT 100,p_offset integer DEFAULT 0) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
 PERFORM public.work_assert_permission('planning.view');
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>92 THEN RAISE EXCEPTION 'Selecciona un periodo de hasta 93 días';END IF;
 IF p_state IS NOT NULL AND p_state NOT IN('pending','active','paused','blocked','review','completed','cancelled')THEN RAISE EXCEPTION 'Estado no válido';END IF;
 IF p_area IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_areas a WHERE a.organization_id=ase_private.current_org()AND a.id=p_area AND a.active)THEN RAISE EXCEPTION 'Área no disponible';END IF;
 IF p_limit IS NULL OR p_limit<1 OR p_limit>200 OR p_offset IS NULL OR p_offset<0 OR p_offset>10000 THEN RAISE EXCEPTION 'Paginación no válida';END IF;
 WITH base AS(
  SELECT p.id,p.task_id,p.user_id employee_id,coalesce(u.full_name,'Empleado no disponible')employee,t.title,t.description,t.importance,p.priority,p.state,p.work_date,p.board_version version,p.started_at,p.finished_at,p.schedule_kind,p.available_from,p.scheduled_for,p.due_at,p.planned_end,p.strict_schedule,a.id area_id,a.name area_name,
   (public.work_execution_eligibility(p.id)->>'overdue')::boolean overdue,(public.work_execution_eligibility(p.id)->>'starts_later')::boolean starts_later,
   coalesce(jsonb_array_length(run.steps),jsonb_array_length(template.steps),0) checklist_total,
   coalesce((SELECT count(*)::int FROM jsonb_array_elements(coalesce(run.steps,'[]'::jsonb)) step WHERE coalesce((step->>'done')::boolean,false)),0) checklist_done,
   coalesce(content.comments_count,0) comments_count,coalesce(content.attachments_count,0) attachments_count,coalesce(labels.items,'[]'::jsonb) labels,
   t.require_comment::int+t.require_photo::int+t.require_video::int+t.require_file::int evidence_required,
   (CASE WHEN t.require_comment AND coalesce(content.has_comment,false) THEN 1 ELSE 0 END+CASE WHEN t.require_photo AND coalesce(content.has_photo,false) THEN 1 ELSE 0 END+CASE WHEN t.require_video AND coalesce(content.has_video,false) THEN 1 ELSE 0 END+CASE WHEN t.require_file AND coalesce(content.has_file,false) THEN 1 ELSE 0 END) evidence_provided
  FROM public.work_day_plan p JOIN public.tasks t ON t.organization_id=p.organization_id AND t.id=p.task_id
  LEFT JOIN ase_private.employee_profiles u ON u.id=p.user_id
  LEFT JOIN public.work_task_areas ta ON ta.organization_id=p.organization_id AND ta.task_id=p.task_id
  LEFT JOIN public.work_areas a ON a.organization_id=ta.organization_id AND a.id=ta.area_id
  LEFT JOIN public.work_checklist_templates template ON template.organization_id=p.organization_id AND template.task_id=p.task_id
  LEFT JOIN LATERAL(SELECT c.id,c.checkin_time FROM public.checkins c WHERE c.organization_id=p.organization_id AND c.work_plan_id=p.id ORDER BY c.checkin_time DESC,c.id DESC LIMIT 1) checkin ON true
  LEFT JOIN public.work_checklist_runs run ON run.organization_id=p.organization_id AND run.checkin_id=checkin.id
  LEFT JOIN LATERAL(SELECT jsonb_agg(l.label ORDER BY l.label,l.normalized)items FROM public.work_task_labels l WHERE l.organization_id=p.organization_id AND l.task_id=p.task_id)labels ON true
  LEFT JOIN LATERAL(SELECT count(*)::int comments_count,count(*)FILTER(WHERE x.image_url IS NOT NULL OR x.video_url IS NOT NULL OR x.file_url IS NOT NULL)::int attachments_count,bool_or(nullif(btrim(x.comment),'')IS NOT NULL)has_comment,bool_or(x.image_url IS NOT NULL)has_photo,bool_or(x.video_url IS NOT NULL)has_video,bool_or(x.file_url IS NOT NULL)has_file FROM public.task_comments x WHERE x.organization_id=p.organization_id AND x.task_id=p.task_id AND x.user_id=p.user_id AND x.created_at>=checkin.checkin_time)content ON true
  WHERE p.organization_id=ase_private.current_org()AND p.work_date BETWEEN p_start AND p_end AND(p_user IS NULL OR p.user_id=p_user)
   AND(p_area IS NULL OR ta.area_id=p_area OR EXISTS(SELECT 1 FROM public.work_area_members m WHERE m.organization_id=p.organization_id AND m.area_id=p_area AND m.user_id=p.user_id))
   AND(nullif(btrim(p_query),'')IS NULL OR concat_ws(' ',t.title,t.description,u.full_name,a.name)ILIKE'%'||btrim(p_query)||'%' OR EXISTS(SELECT 1 FROM public.work_task_labels searched WHERE searched.organization_id=p.organization_id AND searched.task_id=p.task_id AND searched.label ILIKE'%'||btrim(p_query)||'%'))
 ),page AS(SELECT * FROM base WHERE p_state IS NULL OR state=p_state ORDER BY work_date,priority,employee,id LIMIT p_limit OFFSET p_offset)
 SELECT jsonb_build_object('start',p_start,'end',p_end,'labels',coalesce((SELECT jsonb_agg(DISTINCT l.label ORDER BY l.label)FROM public.work_task_labels l WHERE l.organization_id=ase_private.current_org()),'[]'::jsonb),'total',(SELECT count(*)FROM base WHERE p_state IS NULL OR state=p_state),'counts',jsonb_build_object('pending',(SELECT count(*)FROM base WHERE state='pending'),'active',(SELECT count(*)FROM base WHERE state='active'),'paused',(SELECT count(*)FROM base WHERE state='paused'),'blocked',(SELECT count(*)FROM base WHERE state='blocked'),'review',(SELECT count(*)FROM base WHERE state='review'),'completed',(SELECT count(*)FROM base WHERE state='completed'),'cancelled',(SELECT count(*)FROM base WHERE state='cancelled')),'items',coalesce((SELECT jsonb_agg(to_jsonb(page)ORDER BY work_date,priority,employee,id)FROM page),'[]'::jsonb),'limit',p_limit,'offset',p_offset,'as_of',clock_timestamp())INTO result;
 RETURN result;
END $$;

DROP FUNCTION IF EXISTS public.work_planning_board_range(date,date,uuid,text,text,integer,integer);
ALTER FUNCTION public.work_planning_board_range(date,date,uuid,text,text,uuid,integer,integer) OWNER TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,uuid,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_planning_board_range(date,date,uuid,text,text,uuid,integer,integer) TO authenticated,ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
