-- READ ONLY. Run only AFTER migration on the staging project.
BEGIN TRANSACTION READ ONLY;
SELECT jsonb_build_object(
 'organizations_installed',to_regclass('public.organizations') IS NOT NULL,
 'business_rls_boundaries',(SELECT count(*) FROM pg_policies WHERE schemaname='public' AND policyname='mt_boundary' AND permissive='RESTRICTIVE'),
 'feature_rls_boundaries',(SELECT count(*) FROM pg_policies WHERE schemaname='public' AND policyname='work_feature_boundary' AND permissive='RESTRICTIVE'),
 'mandatory_tenant_columns',(SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND column_name='organization_id' AND table_name<>'organization_memberships' AND is_nullable='NO'),
 'invalid_constraints',(SELECT count(*) FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace WHERE n.nspname='public' AND NOT c.convalidated),
 'executor_not_login_or_bypass',(SELECT NOT rolcanlogin AND NOT rolbypassrls AND NOT rolsuper FROM pg_roles WHERE rolname='ase_tenant_executor'),
 'authenticated_cannot_assume_executor',NOT pg_has_role('authenticated','ase_tenant_executor','MEMBER'),
 'anon_cannot_assume_executor',NOT pg_has_role('anon','ase_tenant_executor','MEMBER'),
 'private_bucket',(SELECT public IS FALSE FROM storage.buckets WHERE id='task-files'),
 'global_admin_flags_retired',(SELECT count(*)=0 FROM public.users WHERE is_admin IS TRUE),
 'business_null_tenant_rows',(
SELECT sum(n) FROM (SELECT count(*) n FROM public.tasks WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.task_assignments WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.checkins WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.task_comments WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.task_access_codes WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.task_checkin_config WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.nfc_cards WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.work_day_plan WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.work_employee_cards WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.work_employee_card_keys WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.work_stations WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.work_station_keys WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.work_station_tickets WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.work_roles WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.work_employee_roles WHERE organization_id IS NULL
UNION ALL
SELECT count(*) n FROM public.work_settings WHERE organization_id IS NULL) counts)
) AS comprobacion;
COMMIT;
