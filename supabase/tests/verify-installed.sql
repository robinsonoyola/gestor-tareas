-- ASE Work: verificación alojada y de solo lectura tras instalar o restaurar.
BEGIN TRANSACTION READ ONLY;

SELECT jsonb_build_object(
 'tablas_nucleo',to_regclass('public.organizations') IS NOT NULL AND to_regclass('public.work_projects') IS NOT NULL,
 'archivo_tareas',to_regclass('public.work_task_archive_events') IS NOT NULL AND EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tasks' AND column_name='archived_at'),
 'selectores_activos',to_regprocedure('public.work_planning_assignments(uuid)') IS NOT NULL,
 'limites_rls_empresa',(SELECT count(*) FROM pg_policies WHERE schemaname='public' AND policyname='mt_boundary' AND permissive='RESTRICTIVE'),
 'limites_rls_funcionales',(SELECT count(*) FROM pg_policies WHERE schemaname='public' AND policyname='work_feature_boundary' AND permissive='RESTRICTIVE'),
 'restricciones_sin_validar',(SELECT count(*) FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace WHERE n.nspname='public' AND NOT c.convalidated),
 'ejecutor_seguro',(SELECT NOT rolcanlogin AND NOT rolbypassrls AND NOT rolsuper FROM pg_roles WHERE rolname='ase_tenant_executor'),
 'api_no_asume_ejecutor',NOT pg_has_role('authenticated','ase_tenant_executor','MEMBER') AND NOT pg_has_role('anon','ase_tenant_executor','MEMBER'),
 'ejecutor_sin_create',NOT has_schema_privilege('ase_tenant_executor','public','CREATE') AND NOT has_schema_privilege('ase_tenant_executor','ase_private','CREATE'),
 'esquema_privado_seguro',NOT has_schema_privilege('public','ase_private','USAGE')
   AND NOT EXISTS(
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='ase_private' AND c.relkind IN ('r','p','v','m')
      AND (has_table_privilege('anon',c.oid,'SELECT,INSERT,UPDATE,DELETE') OR has_table_privilege('authenticated',c.oid,'SELECT,INSERT,UPDATE,DELETE'))
   )
   AND NOT EXISTS(
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='ase_private' AND has_function_privilege('public',p.oid,'EXECUTE')
   ),
 'superficie_anonima_segura',(
   SELECT count(*)=11 AND count(*) FILTER(WHERE NOT p.oid=ANY(ARRAY[
    'public.work_station_checklist(text,uuid,uuid,boolean)'::regprocedure,
    'public.work_station_confirm(text,uuid,text)'::regprocedure,
    'public.work_station_confirm_v2(text,uuid,text)'::regprocedure,
    'public.work_station_day(text,uuid)'::regprocedure,
    'public.work_station_day_v2(text,uuid)'::regprocedure,
    'public.work_station_identify(text,text)'::regprocedure,
    'public.work_station_identify_result(text,text,text,uuid)'::regprocedure,
    'public.work_station_identify_v2(text,text,text,uuid)'::regprocedure,
    'public.work_station_people(text)'::regprocedure,
    'public.work_station_save_result(text,uuid,text)'::regprocedure,
    'public.work_usability_ready()'::regprocedure
   ]))=0
   FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND has_function_privilege('anon',p.oid,'EXECUTE')
  ),
 'superficie_servicio_segura',(
   SELECT count(*)=4 AND count(*) FILTER(WHERE NOT p.oid=ANY(ARRAY[
    'public.mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid)'::regprocedure,
    'public.mt_email_change_grant(uuid)'::regprocedure,
    'public.mt_finish_email_change(uuid)'::regprocedure,
    'public.mt_identity_email_exists(text)'::regprocedure
   ]))=0
   FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND has_function_privilege('service_role',p.oid,'EXECUTE')
  ),
 'bucket_privado',(SELECT public IS FALSE FROM storage.buckets WHERE id='task-files'),
 'propietario_activo',EXISTS(SELECT 1 FROM public.organization_memberships WHERE role='owner' AND status='active'),
 'automatizaciones_activas',(SELECT count(*) FROM cron.job WHERE active AND jobname IN ('ase-work-recurrences','ase-work-deadline-notifications')),
 'empresas_sin_propietario',(SELECT count(*) FROM public.organizations o WHERE o.status='active' AND NOT EXISTS(SELECT 1 FROM public.organization_memberships m WHERE m.organization_id=o.id AND m.role='owner' AND m.status='active')),
 'filas_sin_empresa',(
  SELECT sum(n) FROM (
   SELECT count(*) n FROM public.tasks WHERE organization_id IS NULL
   UNION ALL SELECT count(*) FROM public.task_assignments WHERE organization_id IS NULL
   UNION ALL SELECT count(*) FROM public.checkins WHERE organization_id IS NULL
   UNION ALL SELECT count(*) FROM public.task_comments WHERE organization_id IS NULL
   UNION ALL SELECT count(*) FROM public.work_day_plan WHERE organization_id IS NULL
   UNION ALL SELECT count(*) FROM public.work_recurrences WHERE organization_id IS NULL
   UNION ALL SELECT count(*) FROM public.work_projects WHERE organization_id IS NULL
  ) counts
 )
) AS comprobacion;

COMMIT;
