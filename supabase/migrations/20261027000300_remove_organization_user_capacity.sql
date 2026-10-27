-- ASE Work: remove the premature commercial user cap without touching users.
BEGIN;

DROP FUNCTION IF EXISTS public.work_organization_capacity();

CREATE OR REPLACE FUNCTION public.mt_attach_created_employee(
 p_actor uuid,p_org uuid,p_user uuid,p_nonce text,p_name text,p_whatsapp text,p_role uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
 -- Callable only with the backend service role. The Edge Function verifies the actor's JWT.
 PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,1701));
 IF NOT EXISTS(SELECT 1 FROM public.organization_memberships m JOIN public.organizations o ON o.id=m.organization_id
  WHERE m.user_id=p_actor AND m.organization_id=p_org AND m.role IN ('owner','admin') AND m.status='active' AND o.status='active') THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Administración no disponible';
 END IF;
 IF p_name IS NULL OR length(trim(p_name)) NOT BETWEEN 1 AND 150 OR (p_whatsapp IS NOT NULL AND p_whatsapp !~ '^\+?[0-9]{7,15}$') THEN
  RAISE EXCEPTION 'Datos del empleado no válidos';
 END IF;
 IF p_nonce IS NULL OR length(p_nonce)<32 OR NOT EXISTS(SELECT 1 FROM auth.users WHERE id=p_user AND raw_user_meta_data->>'ase_onboarding_nonce'=p_nonce)
 OR EXISTS(SELECT 1 FROM public.organization_memberships WHERE user_id=p_user) THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='No se confirmó una cuenta nueva para este empleado';
 END IF;
 IF p_role IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.work_roles WHERE id=p_role AND organization_id=p_org AND active) THEN RAISE EXCEPTION 'Rol no disponible'; END IF;
 INSERT INTO public.organization_memberships(organization_id,user_id,role,full_name,whatsapp)
 VALUES(p_org,p_user,'member',trim(p_name),p_whatsapp);
 IF p_role IS NOT NULL THEN
  INSERT INTO public.work_employee_roles(organization_id,user_id,role_id) VALUES(p_org,p_user,p_role);
 END IF;
 RETURN jsonb_build_object('id',p_user,'full_name',trim(p_name),'whatsapp',p_whatsapp,'role_id',p_role);
END $function$;

REVOKE ALL ON FUNCTION public.mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid) TO service_role;

ALTER TABLE public.organizations DROP COLUMN IF EXISTS user_limit;

NOTIFY pgrst,'reload schema';
COMMIT;
