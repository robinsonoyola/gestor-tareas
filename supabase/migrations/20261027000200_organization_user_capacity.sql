-- ASE Work: enforce the contracted user capacity per organization.
BEGIN;

-- PostgreSQL requires the destination owner to have CREATE on the function's
-- schema while ownership is transferred. Keep this privilege transactional
-- and revoke it again before committing.
GRANT CREATE ON SCHEMA public TO ase_tenant_executor;

ALTER TABLE public.organizations
 ADD COLUMN IF NOT EXISTS user_limit integer NOT NULL DEFAULT 30;

DO $$
BEGIN
 IF NOT EXISTS (
  SELECT 1 FROM pg_constraint
  WHERE conrelid='public.organizations'::regclass
    AND conname='organizations_user_limit_check'
 ) THEN
  ALTER TABLE public.organizations
   ADD CONSTRAINT organizations_user_limit_check
   CHECK (user_limit BETWEEN 1 AND 10000);
 END IF;
END $$;

CREATE OR REPLACE FUNCTION public.work_organization_capacity()
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
 v_org uuid:=ase_private.current_org();
 v_limit integer;
 v_used integer;
BEGIN
 PERFORM public.work_assert_admin();
 SELECT user_limit INTO v_limit
 FROM public.organizations
 WHERE id=v_org AND status='active';
 IF NOT FOUND THEN RAISE EXCEPTION 'Empresa no disponible'; END IF;

 SELECT count(*)::integer INTO v_used
 FROM public.organization_memberships
 WHERE organization_id=v_org AND status IN ('active','invited');

 RETURN jsonb_build_object(
  'limit',v_limit,
  'used',v_used,
  'available',greatest(v_limit-v_used,0),
  'can_add',v_used<v_limit
 );
END $function$;

ALTER FUNCTION public.work_organization_capacity() OWNER TO ase_tenant_executor;
REVOKE ALL ON FUNCTION public.work_organization_capacity() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.work_organization_capacity() TO authenticated,ase_tenant_executor;

CREATE OR REPLACE FUNCTION public.mt_attach_created_employee(
 p_actor uuid,p_org uuid,p_user uuid,p_nonce text,p_name text,p_whatsapp text,p_role uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
 v_limit integer;
 v_used integer;
BEGIN
 -- Callable only with the backend service role. The Edge Function verifies the actor's JWT.
 PERFORM pg_advisory_xact_lock(hashtextextended(p_org::text,1702));
 PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,1701));
 IF NOT EXISTS(SELECT 1 FROM public.organization_memberships m JOIN public.organizations o ON o.id=m.organization_id
  WHERE m.user_id=p_actor AND m.organization_id=p_org AND m.role IN ('owner','admin') AND m.status='active' AND o.status='active') THEN
  RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='Administración no disponible';
 END IF;
 SELECT user_limit INTO v_limit FROM public.organizations WHERE id=p_org AND status='active';
 SELECT count(*)::integer INTO v_used FROM public.organization_memberships
  WHERE organization_id=p_org AND status IN ('active','invited');
 IF v_used>=v_limit THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='La empresa ha alcanzado su límite de usuarios';
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

REVOKE CREATE ON SCHEMA public FROM ase_tenant_executor;
NOTIFY pgrst,'reload schema';
COMMIT;
