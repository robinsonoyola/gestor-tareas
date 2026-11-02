-- ASE Work: trigger helpers are internal and must not be callable through the API.
BEGIN;

REVOKE ALL ON FUNCTION public.work_execution_schedule_defaults() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.work_execution_schedule_defaults() TO ase_tenant_executor;

NOTIFY pgrst,'reload schema';
COMMIT;
