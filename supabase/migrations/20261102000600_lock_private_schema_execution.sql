-- ASE Work: the private schema is deny-by-default for API roles.
BEGIN;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA ase_private FROM PUBLIC,anon,authenticated;

-- Policies need the organization context for authenticated requests.
GRANT EXECUTE ON FUNCTION ase_private.current_org() TO authenticated,ase_tenant_executor;

-- Hosted Auth is exposed only through these identity helpers.
GRANT EXECUTE ON FUNCTION ase_private.session_user_id(),ase_private.session_role()
 TO anon,authenticated,ase_tenant_executor;

NOTIFY pgrst,'reload schema';
COMMIT;
