-- ASE Work: internal authorization and scheduling helpers are not browser RPCs.
BEGIN;

REVOKE ALL ON FUNCTION
 public.work_assert_admin(),
 public.work_assert_permission(text),
 public.validate_nfc_checkin(character varying,uuid,uuid),
 public.work_execution_timing(uuid,timestamptz),
 public.work_execution_eligibility(uuid,timestamptz)
FROM PUBLIC,anon,authenticated;

GRANT EXECUTE ON FUNCTION
 public.work_assert_admin(),
 public.work_assert_permission(text),
 public.validate_nfc_checkin(character varying,uuid,uuid),
 public.work_execution_timing(uuid,timestamptz),
 public.work_execution_eligibility(uuid,timestamptz)
TO ase_tenant_executor;

NOTIFY pgrst,'reload schema';
COMMIT;
