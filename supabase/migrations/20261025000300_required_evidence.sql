BEGIN;

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS require_comment boolean NOT NULL DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS require_photo boolean NOT NULL DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS require_video boolean NOT NULL DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS require_file boolean NOT NULL DEFAULT false;
ALTER TABLE public.task_comments ADD COLUMN IF NOT EXISTS file_url text;

GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.work_manage_task_roles_evidence(
 p_action text,p_importance text,p_id uuid DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,
 p_schedule text DEFAULT 'daily',p_date date DEFAULT NULL,p_status text DEFAULT 'pending',p_primary uuid DEFAULT NULL,
 p_collaborators uuid[] DEFAULT '{}'::uuid[],p_followers uuid[] DEFAULT '{}'::uuid[],
 p_require_comment boolean DEFAULT false,p_require_photo boolean DEFAULT false,p_require_video boolean DEFAULT false,p_require_file boolean DEFAULT false
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;
BEGIN
 result:=public.work_manage_task_roles(p_action,p_importance,p_id,p_title,p_description,p_schedule,p_date,p_status,p_primary,p_collaborators,p_followers);
 UPDATE public.tasks SET require_comment=coalesce(p_require_comment,false),require_photo=coalesce(p_require_photo,false),
  require_video=coalesce(p_require_video,false),require_file=coalesce(p_require_file,false)
 WHERE organization_id=ase_private.current_org() AND id=result;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_checkin_evidence(p_checkin uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE c public.checkins%ROWTYPE;t public.tasks%ROWTYPE;result jsonb;
BEGIN
 SELECT * INTO c FROM public.checkins WHERE organization_id=ase_private.current_org() AND id=p_checkin;
 IF c.id IS NULL OR NOT(public.work_has_permission('tasks.view') OR c.user_id=ase_private.session_user_id()) THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Fichaje no disponible';
 END IF;
 SELECT * INTO t FROM public.tasks WHERE organization_id=c.organization_id AND id=c.task_id;
 SELECT jsonb_build_object(
  'required',jsonb_build_object('comment',t.require_comment,'photo',t.require_photo,'video',t.require_video,'file',t.require_file),
  'provided',jsonb_build_object(
   'comment',coalesce(bool_or(nullif(btrim(x.comment),'') IS NOT NULL),false),
   'photo',coalesce(bool_or(x.image_url IS NOT NULL),false),
   'video',coalesce(bool_or(x.video_url IS NOT NULL),false),
   'file',coalesce(bool_or(x.file_url IS NOT NULL),false))) INTO result
 FROM public.task_comments x WHERE x.organization_id=c.organization_id AND x.task_id=c.task_id AND x.user_id=c.user_id AND x.created_at>=c.checkin_time;
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.work_require_evidence_on_close() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE required_row public.tasks%ROWTYPE;has_comment boolean;has_photo boolean;has_video boolean;has_file boolean;missing text[]:='{}'::text[];
BEGIN
 IF OLD.checkout_time IS NOT NULL OR NEW.checkout_time IS NULL THEN RETURN NEW;END IF;
 -- Un bloqueo detiene el contador, pero no completa el trabajo y no exige evidencias finales.
 IF NEW.work_plan_id IS NOT NULL AND EXISTS(SELECT 1 FROM public.work_incidents i WHERE i.organization_id=NEW.organization_id AND i.plan_id=NEW.work_plan_id AND i.blocks_work AND i.state<>'resolved') THEN RETURN NEW;END IF;
 SELECT * INTO required_row FROM public.tasks WHERE organization_id=NEW.organization_id AND id=NEW.task_id;
 SELECT coalesce(bool_or(nullif(btrim(x.comment),'') IS NOT NULL),false),coalesce(bool_or(x.image_url IS NOT NULL),false),coalesce(bool_or(x.video_url IS NOT NULL),false),coalesce(bool_or(x.file_url IS NOT NULL),false)
 INTO has_comment,has_photo,has_video,has_file FROM public.task_comments x WHERE x.organization_id=NEW.organization_id AND x.task_id=NEW.task_id AND x.user_id=NEW.user_id AND x.created_at>=NEW.checkin_time;
 IF required_row.require_comment AND NOT has_comment THEN missing:=array_append(missing,'comentario');END IF;
 IF required_row.require_photo AND NOT has_photo THEN missing:=array_append(missing,'foto');END IF;
 IF required_row.require_video AND NOT has_video THEN missing:=array_append(missing,'vídeo');END IF;
 IF required_row.require_file AND NOT has_file THEN missing:=array_append(missing,'archivo');END IF;
 IF cardinality(missing)>0 THEN RAISE EXCEPTION 'Antes de finalizar añade: %',array_to_string(missing,', ');END IF;
 RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS work_require_evidence_on_close ON public.checkins;
CREATE TRIGGER work_require_evidence_on_close BEFORE UPDATE OF checkout_time ON public.checkins
FOR EACH ROW EXECUTE FUNCTION public.work_require_evidence_on_close();

CREATE OR REPLACE FUNCTION public.sec04_validate_comment_attachment() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$
DECLARE v_ref text;v_actor uuid:=(SELECT auth.uid());v_prefix text;
BEGIN
 IF (SELECT auth.role()) IN('anon','authenticated') THEN
  IF v_actor IS NULL OR NEW.user_id IS DISTINCT FROM v_actor OR NEW.task_id IS NULL THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Comentario no autorizado';END IF;
  IF TG_OP='UPDATE' AND NEW.image_url IS NOT DISTINCT FROM OLD.image_url AND NEW.video_url IS NOT DISTINCT FROM OLD.video_url AND NEW.file_url IS NOT DISTINCT FROM OLD.file_url AND NEW.task_id IS NOT DISTINCT FROM OLD.task_id AND NEW.user_id IS NOT DISTINCT FROM OLD.user_id THEN RETURN NEW;END IF;
  v_prefix:='tasks/'||NEW.task_id::text||'/'||v_actor::text||'/';
  FOREACH v_ref IN ARRAY ARRAY[NEW.image_url,NEW.video_url,NEW.file_url] LOOP
   IF v_ref IS NOT NULL AND (left(v_ref,length(v_prefix))<>v_prefix OR v_ref !~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov|pdf|doc|docx|xls|xlsx|csv|txt)$') THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='La referencia debe pertenecer a tu subida de esta tarea';END IF;
  END LOOP;
 END IF;RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.work_can_file(p_name text) RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE v_task uuid;
BEGIN
 IF NOT public.work_mode() OR public.sec06_is_admin() THEN RETURN true;END IF;
 IF p_name ~ '^tasks/[0-9a-f-]{36}/' THEN BEGIN v_task:=split_part(p_name,'/',2)::uuid;EXCEPTION WHEN invalid_text_representation THEN RETURN false;END;RETURN public.work_can_detail(v_task);END IF;
 RETURN EXISTS(SELECT 1 FROM public.task_comments c WHERE public.work_can_detail(c.task_id)
 AND (c.image_url=p_name OR c.video_url=p_name OR c.file_url=p_name OR split_part(c.image_url,'/storage/v1/object/public/task-files/',2)=p_name OR split_part(c.video_url,'/storage/v1/object/public/task-files/',2)=p_name OR split_part(c.file_url,'/storage/v1/object/public/task-files/',2)=p_name));
END $$;

DROP POLICY IF EXISTS task_files_insert ON storage.objects;
CREATE POLICY task_files_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK(
 bucket_id='task-files' AND name ~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov|pdf|doc|docx|xls|xlsx|csv|txt)$'
 AND split_part(name,'/',3)=ase_private.session_user_id()::text AND public.work_can_act(split_part(name,'/',2)::uuid));
DROP POLICY IF EXISTS incident_upload ON storage.objects;
CREATE POLICY incident_upload ON storage.objects FOR INSERT TO authenticated WITH CHECK(
 bucket_id='task-files' AND name ~ '^tasks/[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(png|jpg|jpeg|gif|webp|mp4|webm|mov|pdf|doc|docx|xls|xlsx|csv|txt)$'
 AND split_part(name,'/',3)=ase_private.session_user_id()::text AND public.work_incident_resolver(split_part(name,'/',2)::uuid));

ALTER FUNCTION public.work_manage_task_roles_evidence(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_checkin_evidence(uuid) OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_require_evidence_on_close() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.sec04_validate_comment_attachment() OWNER TO ase_tenant_executor;
ALTER FUNCTION public.work_can_file(text) OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_manage_task_roles_evidence(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean),public.work_checkin_evidence(uuid),public.work_require_evidence_on_close(),public.sec04_validate_comment_attachment(),public.work_can_file(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_manage_task_roles_evidence(text,text,uuid,text,text,text,date,text,uuid,uuid[],uuid[],boolean,boolean,boolean,boolean),public.work_checkin_evidence(uuid) TO authenticated,ase_tenant_executor;
GRANT EXECUTE ON FUNCTION public.work_require_evidence_on_close(),public.sec04_validate_comment_attachment(),public.work_can_file(text) TO ase_tenant_executor;
REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
