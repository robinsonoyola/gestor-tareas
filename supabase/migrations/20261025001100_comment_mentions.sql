-- ASE Work: explicit, auditable mentions inside task comments.
BEGIN;
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE TABLE IF NOT EXISTS public.work_comment_mentions(
 organization_id uuid NOT NULL,comment_id uuid NOT NULL,task_id uuid NOT NULL,user_id uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(organization_id,comment_id,user_id),
 FOREIGN KEY(comment_id) REFERENCES public.task_comments(id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,task_id) REFERENCES public.tasks(organization_id,id) ON DELETE CASCADE,
 FOREIGN KEY(organization_id,user_id) REFERENCES public.organization_memberships(organization_id,user_id) ON DELETE CASCADE
);
ALTER TABLE public.work_comment_mentions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.work_comment_mentions FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.work_comment_mentions TO ase_tenant_executor;
DROP POLICY IF EXISTS comment_mentions_executor ON public.work_comment_mentions;
CREATE POLICY comment_mentions_executor ON public.work_comment_mentions TO ase_tenant_executor USING(organization_id=ase_private.current_org())WITH CHECK(organization_id=ase_private.current_org());

CREATE OR REPLACE FUNCTION public.sec04_validate_comment_attachment() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$
DECLARE v_ref text;v_actor uuid:=ase_private.session_user_id();v_prefix text;
BEGIN
 IF ase_private.session_role()IN('anon','authenticated')THEN
  IF v_actor IS NULL OR NEW.user_id IS DISTINCT FROM v_actor OR NEW.task_id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Comentario no autorizado';END IF;
  IF TG_OP='UPDATE'AND NEW.image_url IS NOT DISTINCT FROM OLD.image_url AND NEW.video_url IS NOT DISTINCT FROM OLD.video_url AND NEW.file_url IS NOT DISTINCT FROM OLD.file_url AND NEW.task_id IS NOT DISTINCT FROM OLD.task_id AND NEW.user_id IS NOT DISTINCT FROM OLD.user_id THEN RETURN NEW;END IF;
  v_prefix:='tasks/'||NEW.task_id::text||'/'||v_actor::text||'/';
  FOREACH v_ref IN ARRAY ARRAY[NEW.image_url,NEW.video_url,NEW.file_url]LOOP
   IF v_ref IS NOT NULL AND(left(v_ref,length(v_prefix))<>v_prefix OR v_ref!~'^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov|pdf|doc|docx|xls|xlsx|csv|txt)$')THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La referencia debe pertenecer a tu subida de esta tarea';END IF;
  END LOOP;
 END IF;RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_comment_recipients(p_task uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;actor uuid:=ase_private.session_user_id();
BEGIN
 IF actor IS NULL OR NOT public.work_can_detail(p_task) THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No puedes consultar esta tarea';END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',x.user_id,'name',x.full_name,'role',x.role)ORDER BY x.role,x.full_name,x.user_id),'[]'::jsonb)INTO result FROM(
  SELECT a.user_id,m.full_name,CASE a.responsibility_role WHEN'primary'THEN'Responsable'ELSE'Colaborador'END role FROM public.task_assignments a JOIN public.organization_memberships m ON m.organization_id=a.organization_id AND m.user_id=a.user_id WHERE a.organization_id=ase_private.current_org()AND a.task_id=p_task AND a.user_id<>actor
  UNION ALL
  SELECT f.user_id,m.full_name,'Seguidor' FROM public.work_task_followers f JOIN public.organization_memberships m ON m.organization_id=f.organization_id AND m.user_id=f.user_id WHERE f.organization_id=ase_private.current_org()AND f.task_id=p_task AND f.user_id<>actor
 )x;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_add_task_comment(p_task uuid,p_comment text,p_image text DEFAULT NULL,p_video text DEFAULT NULL,p_file text DEFAULT NULL,p_mentions uuid[] DEFAULT '{}'::uuid[]) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=ase_private.session_user_id();org uuid:=ase_private.current_org();comment_id uuid;recipient uuid;task_title text;actor_name text;
BEGIN
 p_mentions:=coalesce(p_mentions,'{}'::uuid[]);
 IF actor IS NULL OR p_task IS NULL OR length(btrim(coalesce(p_comment,'')))NOT BETWEEN 1 AND 5000 THEN RAISE EXCEPTION 'Escribe un comentario de hasta 5.000 caracteres';END IF;
 IF cardinality(p_mentions)>20 OR cardinality(p_mentions)<>(SELECT count(DISTINCT id)FROM unnest(p_mentions)u(id)) OR actor=ANY(p_mentions)THEN RAISE EXCEPTION 'Selecciona menciones válidas sin repetirte';END IF;
 IF EXISTS(SELECT 1 FROM unnest(p_mentions)u(id)WHERE NOT EXISTS(SELECT 1 FROM public.task_assignments a WHERE a.organization_id=org AND a.task_id=p_task AND a.user_id=u.id UNION ALL SELECT 1 FROM public.work_task_followers f WHERE f.organization_id=org AND f.task_id=p_task AND f.user_id=u.id))THEN RAISE EXCEPTION 'Solo puedes mencionar al equipo de la tarea';END IF;
 INSERT INTO public.task_comments(organization_id,task_id,user_id,comment,image_url,video_url,file_url)VALUES(org,p_task,actor,btrim(p_comment),p_image,p_video,p_file)RETURNING id INTO comment_id;
 INSERT INTO public.work_comment_mentions(organization_id,comment_id,task_id,user_id)SELECT org,comment_id,p_task,u.id FROM unnest(p_mentions)u(id);
 SELECT title INTO task_title FROM public.tasks WHERE organization_id=org AND id=p_task;SELECT full_name INTO actor_name FROM public.organization_memberships WHERE organization_id=org AND user_id=actor;
 FOREACH recipient IN ARRAY p_mentions LOOP
  UPDATE public.work_notifications SET kind='mention',message='Te mencionaron en: '||coalesce(task_title,'Tarea')||' · '||coalesce(actor_name,'Empleado') WHERE organization_id=org AND user_id=recipient AND event_key='comment:'||comment_id::text||':'||recipient::text;
 END LOOP;
 RETURN comment_id;
END $$;

ALTER FUNCTION public.work_comment_recipients(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_add_task_comment(uuid,text,text,text,text,uuid[]) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.sec04_validate_comment_attachment() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_comment_recipients(uuid),public.work_add_task_comment(uuid,text,text,text,text,uuid[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_comment_recipients(uuid),public.work_add_task_comment(uuid,text,text,text,text,uuid[]) TO authenticated,ase_tenant_executor;
REVOKE ALL ON FUNCTION public.sec04_validate_comment_attachment() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.sec04_validate_comment_attachment() TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;

