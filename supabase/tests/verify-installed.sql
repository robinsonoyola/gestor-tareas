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
 'almacenamiento_rls_seguro',(
   SELECT c.relrowsecurity
   FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
   WHERE n.nspname='storage' AND c.relname='objects'
  ) AND (
   SELECT count(*)=9
    AND count(*) FILTER(WHERE policyname<>ALL(ARRAY['incident_upload','sec04_read_assigned_task_files','sec04_upload_own_assigned_task_files','task_files_insert','work_files_insert','work_files_read','work_incident_attachment_executor','work_incident_file_read','work_upload_active_checkin']))=0
    AND count(*) FILTER(WHERE roles&&ARRAY['anon','public']::name[])=0
   FROM pg_policies WHERE schemaname='storage' AND tablename='objects'
  ),
 'funciones_privilegiadas_seguras',(
   SELECT count(*)=208
    AND count(*) FILTER(WHERE r.rolname='ase_tenant_executor')=185
    AND count(*) FILTER(WHERE r.rolname='postgres')=23
    AND count(*) FILTER(WHERE r.rolname NOT IN ('ase_tenant_executor','postgres'))=0
    AND count(*) FILTER(WHERE NOT ('search_path=""'=ANY(coalesce(p.proconfig,ARRAY[]::text[]))))=0
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid=p.pronamespace
   JOIN pg_roles r ON r.oid=p.proowner
   WHERE n.nspname IN ('public','ase_private') AND p.prosecdef
  ),
 'rol_ejecutor_restringido',EXISTS(
  SELECT 1 FROM pg_roles
  WHERE rolname='ase_tenant_executor' AND NOT rolsuper AND NOT rolcreaterole AND NOT rolcreatedb
   AND NOT rolcanlogin AND NOT rolreplication AND NOT rolbypassrls
 ),
 'propiedad_relaciones_segura',NOT EXISTS(
  SELECT 1 FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  JOIN pg_roles owner ON owner.oid=c.relowner
  WHERE n.nspname IN ('public','ase_private','storage') AND c.relkind IN ('r','p','v','m','S')
   AND owner.rolname IN ('anon','authenticated','service_role','ase_tenant_executor')
 ),
 'membresias_roles_seguras',NOT EXISTS(
  SELECT 1 FROM pg_auth_members membership
  JOIN pg_roles member_role ON member_role.oid=membership.member
  JOIN pg_roles granted_role ON granted_role.oid=membership.roleid
  WHERE member_role.rolname IN ('anon','authenticated','service_role','ase_tenant_executor')
   AND granted_role.rolname IN ('postgres','service_role','ase_tenant_executor')
 ),
 'superficie_postgres_segura',(SELECT count(*)=7
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles owner ON owner.oid=p.proowner
  WHERE n.nspname IN ('public','ase_private') AND p.prosecdef AND owner.rolname='postgres'
   AND (has_function_privilege('anon',p.oid,'EXECUTE') OR has_function_privilege('authenticated',p.oid,'EXECUTE'))
 ) AND NOT EXISTS(
  SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles owner ON owner.oid=p.proowner
  WHERE n.nspname IN ('public','ase_private') AND p.prosecdef AND owner.rolname='postgres'
   AND (has_function_privilege('anon',p.oid,'EXECUTE') OR has_function_privilege('authenticated',p.oid,'EXECUTE'))
   AND (NOT p.oid=ANY(ARRAY['ase_private.current_org()'::regprocedure,'ase_private.session_role()'::regprocedure,'ase_private.session_user_id()'::regprocedure,'public.mt_context()'::regprocedure,'public.mt_create_organization(text,text)'::regprocedure,'public.mt_prepare_email_change(uuid,text)'::regprocedure,'public.mt_resolve_task_access(text)'::regprocedure])
    OR NOT has_function_privilege('authenticated',p.oid,'EXECUTE')
    OR (has_function_privilege('anon',p.oid,'EXECUTE') AND NOT p.oid=ANY(ARRAY['ase_private.session_role()'::regprocedure,'ase_private.session_user_id()'::regprocedure])))
 ),
 'permisos_tablas_api_seguros',NOT EXISTS(
   SELECT 1 FROM information_schema.role_table_grants
   WHERE grantee='anon' AND table_schema IN ('public','storage','ase_private')
  ) AND NOT EXISTS(
   SELECT 1 FROM information_schema.role_table_grants
   WHERE grantee IN ('anon','authenticated')
     AND table_schema IN ('public','storage','ase_private')
     AND privilege_type IN ('TRUNCATE','REFERENCES','TRIGGER')
  ),
 'limites_empresa_completos',NOT EXISTS(
   SELECT 1 FROM information_schema.columns c
   WHERE c.table_schema='public' AND c.column_name='organization_id'
     AND NOT EXISTS(
      SELECT 1 FROM pg_policies p
      WHERE p.schemaname='public' AND p.tablename=c.table_name
        AND (coalesce(p.qual,'') LIKE '%current_org()%' OR coalesce(p.with_check,'') LIKE '%current_org()%')
     )
  ),
 'estructura_tablas_valida',NOT EXISTS(
  SELECT 1 FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public' AND c.relkind IN ('r','p')
   AND NOT EXISTS(SELECT 1 FROM pg_constraint constraint_definition WHERE constraint_definition.conrelid=c.oid AND constraint_definition.contype='p')
 ) AND NOT EXISTS(
  SELECT 1 FROM pg_constraint constraint_definition
  JOIN pg_class c ON c.oid=constraint_definition.conrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public' AND NOT constraint_definition.convalidated
 ) AND NOT EXISTS(
  SELECT 1 FROM pg_index index_definition
  JOIN pg_class c ON c.oid=index_definition.indrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public' AND (NOT index_definition.indisvalid OR NOT index_definition.indisready)
 ),
 'integridad_relacional_empresa',NOT EXISTS(
   SELECT 1 FROM information_schema.columns
   WHERE table_schema='public' AND column_name='organization_id' AND is_nullable<>'NO'
  ) AND NOT EXISTS(
   SELECT 1
   FROM pg_constraint c
   JOIN pg_class source ON source.oid=c.conrelid
   JOIN pg_namespace source_schema ON source_schema.oid=source.relnamespace
   JOIN pg_class target ON target.oid=c.confrelid
   JOIN pg_namespace target_schema ON target_schema.oid=target.relnamespace
   JOIN pg_attribute source_org ON source_org.attrelid=source.oid AND source_org.attname='organization_id'
   JOIN pg_attribute target_org ON target_org.attrelid=target.oid AND target_org.attname='organization_id'
   WHERE c.contype='f' AND source_schema.nspname='public' AND target_schema.nspname='public'
     AND NOT EXISTS(SELECT 1 FROM pg_constraint safe WHERE safe.contype='f' AND safe.conrelid=c.conrelid AND safe.confrelid=c.confrelid AND source_org.attnum=ANY(safe.conkey) AND target_org.attnum=ANY(safe.confkey))
  ),
 'indices_claves_foraneas',NOT EXISTS(
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class source ON source.oid=c.conrelid
  JOIN pg_namespace source_schema ON source_schema.oid=source.relnamespace
  WHERE c.contype='f' AND source_schema.nspname='public'
   AND NOT EXISTS(
    SELECT 1 FROM pg_index i
    WHERE i.indrelid=c.conrelid AND i.indisvalid AND i.indisready AND i.indpred IS NULL
     AND i.indnkeyatts>=cardinality(c.conkey)
     AND NOT EXISTS(SELECT 1 FROM generate_subscripts(c.conkey,1) position WHERE i.indkey[position-1]<>c.conkey[position])
   )
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
