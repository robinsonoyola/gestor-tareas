-- ASE Work: trigger functions are internal database machinery, never browser RPCs.
BEGIN;

REVOKE ALL ON FUNCTION public.work_guard_required_result() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_guard_required_result() TO ase_tenant_executor;

NOTIFY pgrst,'reload schema';
COMMIT;
