import fs from 'node:fs'
import { fileURLToPath, pathToFileURL } from 'node:url'

const root = fileURLToPath(new URL('../../', import.meta.url)).replaceAll('\\', '/')
let pglite
let cryptoExtension
try {
  pglite = await import('@electric-sql/pglite')
  cryptoExtension = await import('@electric-sql/pglite/contrib/pgcrypto')
} catch {
  pglite = await import(pathToFileURL(`${root}../../sec01-test/node_modules/@electric-sql/pglite/dist/index.js`))
  cryptoExtension = await import(pathToFileURL(`${root}../../sec01-test/node_modules/@electric-sql/pglite/dist/contrib/pgcrypto.js`))
}

const { PGlite } = pglite
const { pgcrypto } = cryptoExtension
const db = new PGlite({ extensions: { pgcrypto } })
const owner = '00000000-0000-0000-0000-000000000001'
const worker = '00000000-0000-0000-0000-000000000002'

try {
  await db.exec(fs.readFileSync(`${root}supabase/tests/bootstrap.sql`, 'utf8'))
  await db.exec(fs.readFileSync(`${root}supabase/baseline/20261022_installed_public.sql`, 'utf8'))
  await db.exec(fs.readFileSync(`${root}supabase/tests/storage-baseline.sql`, 'utf8'))
  await db.exec(`
    CREATE SCHEMA extensions;
    CREATE EXTENSION pgcrypto WITH SCHEMA extensions;
    INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
      ('${owner}','owner@example.test','{"full_name":"Owner"}'),
      ('${worker}','worker@example.test','{"full_name":"Worker"}');
    UPDATE public.users SET is_admin=true WHERE id='${owner}';
    INSERT INTO public.work_settings VALUES(true,false);
  `)

  const migrations = fs.readdirSync(`${root}supabase/migrations`)
    .filter(name => name.endsWith('.sql'))
    .sort((a, b) => a.localeCompare(b, 'en'))

  for (const name of migrations) {
    await db.exec(fs.readFileSync(`${root}supabase/migrations/${name}`, 'utf8'))
  }

  const final = await db.query(`
    SELECT
      to_regclass('public.organizations') IS NOT NULL AS organizations,
      to_regclass('public.work_task_archive_events') IS NOT NULL AS archive_events,
      EXISTS(SELECT 1 FROM public.organization_memberships WHERE user_id=$1 AND role IN ('owner','admin') AND status='active') AS administrator_ready,
      NOT has_schema_privilege('ase_tenant_executor','public','CREATE') AS executor_locked,
      EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tasks' AND column_name='archived_at') AS archive_column
  `, [owner])
  const state = final.rows[0]
  if (!Object.values(state).every(Boolean)) throw new Error(`Estado final incompleto: ${JSON.stringify(state)}`)

  const tables = await db.query(`
    SELECT c.relname AS name,c.relrowsecurity AS rls
    FROM pg_class c
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relkind IN ('r','p')
    ORDER BY c.relname
  `)
  const withoutRls = tables.rows.filter(table => !table.rls).map(table => table.name)
  if (withoutRls.length) throw new Error(`Tablas públicas sin aislamiento RLS: ${withoutRls.join(', ')}`)

  const tablesWithoutPrimaryKey = await db.query(`
    SELECT c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relkind IN ('r','p')
      AND NOT EXISTS(
        SELECT 1 FROM pg_constraint constraint_definition
        WHERE constraint_definition.conrelid=c.oid AND constraint_definition.contype='p'
      )
    ORDER BY c.relname
  `)
  if (tablesWithoutPrimaryKey.rows.length) throw new Error(`Tablas sin clave primaria: ${tablesWithoutPrimaryKey.rows.map(table => table.table_name).join(', ')}`)

  const invalidConstraints = await db.query(`
    SELECT c.relname AS table_name,constraint_definition.conname AS constraint_name
    FROM pg_constraint constraint_definition
    JOIN pg_class c ON c.oid=constraint_definition.conrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND NOT constraint_definition.convalidated
    ORDER BY c.relname,constraint_definition.conname
  `)
  if (invalidConstraints.rows.length) throw new Error(`Restricciones sin validar: ${invalidConstraints.rows.map(item => `${item.table_name}.${item.constraint_name}`).join(', ')}`)

  const invalidIndexes = await db.query(`
    SELECT c.relname AS table_name,i.relname AS index_name
    FROM pg_index index_definition
    JOIN pg_class c ON c.oid=index_definition.indrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    JOIN pg_class i ON i.oid=index_definition.indexrelid
    WHERE n.nspname='public' AND (NOT index_definition.indisvalid OR NOT index_definition.indisready)
    ORDER BY c.relname,i.relname
  `)
  if (invalidIndexes.rows.length) throw new Error(`Índices inválidos: ${invalidIndexes.rows.map(item => `${item.table_name}.${item.index_name}`).join(', ')}`)

  const routines = await db.query(`
    SELECT p.oid::regprocedure::text AS name
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND has_function_privilege('public',p.oid,'EXECUTE')
    ORDER BY 1
  `)
  if (routines.rows.length) throw new Error(`Funciones ejecutables por PUBLIC: ${routines.rows.map(routine => routine.name).join(', ')}`)

  const privateSchema = await db.query(`
    SELECT
      NOT has_schema_privilege('public','ase_private','USAGE') AS public_blocked,
      has_schema_privilege('anon','ase_private','USAGE') AS anon_context,
      has_schema_privilege('authenticated','ase_private','USAGE') AS authenticated_context
  `)
  if (!Object.values(privateSchema.rows[0]).every(Boolean)) throw new Error(`Acceso incorrecto al esquema privado: ${JSON.stringify(privateSchema.rows[0])}`)

  const exposedPrivateRelations = await db.query(`
    SELECT c.relname AS name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='ase_private' AND c.relkind IN ('r','p','v','m')
      AND (has_table_privilege('anon',c.oid,'SELECT,INSERT,UPDATE,DELETE')
        OR has_table_privilege('authenticated',c.oid,'SELECT,INSERT,UPDATE,DELETE'))
    ORDER BY c.relname
  `)
  if (exposedPrivateRelations.rows.length) throw new Error(`Relaciones privadas expuestas al API: ${exposedPrivateRelations.rows.map(relation => relation.name).join(', ')}`)

  const publicPrivateRoutines = await db.query(`
    SELECT p.oid::regprocedure::text AS name
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='ase_private'
      AND has_function_privilege('public',p.oid,'EXECUTE')
    ORDER BY 1
  `)
  if (publicPrivateRoutines.rows.length) throw new Error(`Funciones privadas expuestas a PUBLIC: ${publicPrivateRoutines.rows.map(routine => routine.name).join(', ')}`)

  const apiPrivateRoutines = await db.query(`
    SELECT p.proname AS name,
      has_function_privilege('anon',p.oid,'EXECUTE') AS anon,
      has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='ase_private'
      AND (has_function_privilege('anon',p.oid,'EXECUTE') OR has_function_privilege('authenticated',p.oid,'EXECUTE'))
    ORDER BY p.proname
  `)
  const anonRoutines = apiPrivateRoutines.rows.filter(routine => routine.anon).map(routine => routine.name)
  const authenticatedRoutines = apiPrivateRoutines.rows.filter(routine => routine.authenticated).map(routine => routine.name)
  if (JSON.stringify(anonRoutines) !== JSON.stringify(['session_role','session_user_id'])) throw new Error(`Funciones privadas anónimas inesperadas: ${anonRoutines.join(', ')}`)
  if (JSON.stringify(authenticatedRoutines) !== JSON.stringify(['current_org','session_role','session_user_id'])) throw new Error(`Funciones privadas autenticadas inesperadas: ${authenticatedRoutines.join(', ')}`)

  const anonymousPublicRoutines = await db.query(`
    SELECT p.oid::regprocedure::text AS name
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND has_function_privilege('anon',p.oid,'EXECUTE')
    ORDER BY 1
  `)
  const anonymousApi = anonymousPublicRoutines.rows.map(routine => routine.name)
  const expectedAnonymousApi = [
    'work_station_checklist(text,uuid,uuid,boolean)',
    'work_station_confirm(text,uuid,text)',
    'work_station_confirm_v2(text,uuid,text)',
    'work_station_day(text,uuid)',
    'work_station_day_v2(text,uuid)',
    'work_station_identify(text,text)',
    'work_station_identify_result(text,text,text,uuid)',
    'work_station_identify_v2(text,text,text,uuid)',
    'work_station_people(text)',
    'work_station_save_result(text,uuid,text)',
    'work_usability_ready()'
  ]
  if (JSON.stringify(anonymousApi) !== JSON.stringify(expectedAnonymousApi)) throw new Error(`Superficie anónima inesperada: ${anonymousApi.join(', ')}`)

  const servicePublicRoutines = await db.query(`
    SELECT p.oid::regprocedure::text AS name
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND has_function_privilege('service_role',p.oid,'EXECUTE')
    ORDER BY 1
  `)
  const serviceApi = servicePublicRoutines.rows.map(routine => routine.name)
  const expectedServiceApi = [
    'mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid)',
    'mt_email_change_grant(uuid)',
    'mt_finish_email_change(uuid)',
    'mt_identity_email_exists(text)'
  ].sort()
  if (JSON.stringify(serviceApi) !== JSON.stringify(expectedServiceApi)) throw new Error(`Superficie de servicio inesperada: ${serviceApi.join(', ')}`)

  const storagePolicies = await db.query(`
    SELECT policyname,cmd,permissive,roles::text AS roles
    FROM pg_policies
    WHERE schemaname='storage' AND tablename='objects'
    ORDER BY policyname
  `)
  const storagePolicySurface = storagePolicies.rows.map(policy => `${policy.policyname}:${policy.cmd}:${policy.permissive}:${policy.roles}`)
  const expectedStoragePolicySurface = [
    'incident_upload:INSERT:PERMISSIVE:{authenticated}',
    'sec04_read_assigned_task_files:SELECT:PERMISSIVE:{authenticated}',
    'sec04_upload_own_assigned_task_files:INSERT:PERMISSIVE:{authenticated}',
    'task_files_insert:INSERT:PERMISSIVE:{authenticated}',
    'work_files_insert:INSERT:RESTRICTIVE:{authenticated}',
    'work_files_read:SELECT:RESTRICTIVE:{authenticated}',
    'work_incident_attachment_executor:SELECT:PERMISSIVE:{ase_tenant_executor}',
    'work_incident_file_read:SELECT:PERMISSIVE:{authenticated}',
    'work_upload_active_checkin:INSERT:RESTRICTIVE:{authenticated}'
  ]
  if (JSON.stringify(storagePolicySurface) !== JSON.stringify(expectedStoragePolicySurface)) throw new Error(`Políticas de almacenamiento inesperadas: ${storagePolicySurface.join(', ')}`)
  const storageRls = await db.query(`SELECT c.relrowsecurity AS enabled FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='storage' AND c.relname='objects'`)
  if (storageRls.rows[0]?.enabled !== true) throw new Error('storage.objects no tiene RLS activo')

  const privilegedOwners = await db.query(`
    SELECT r.rolname AS owner,count(*)::integer AS functions
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    JOIN pg_roles r ON r.oid=p.proowner
    WHERE n.nspname IN ('public','ase_private') AND p.prosecdef
    GROUP BY r.rolname
    ORDER BY r.rolname
  `)
  if (JSON.stringify(privilegedOwners.rows) !== JSON.stringify([{ owner: 'ase_tenant_executor', functions: 189 }, { owner: 'postgres', functions: 23 }])) throw new Error(`Propietarios privilegiados inesperados: ${JSON.stringify(privilegedOwners.rows)}`)

  const executorRole = await db.query(`
    SELECT NOT rolsuper AS not_superuser,
      NOT rolcreaterole AS cannot_create_roles,
      NOT rolcreatedb AS cannot_create_databases,
      NOT rolcanlogin AS cannot_login,
      NOT rolreplication AS cannot_replicate,
      NOT rolbypassrls AS cannot_bypass_rls
    FROM pg_roles
    WHERE rolname='ase_tenant_executor'
  `)
  if (executorRole.rows.length !== 1 || !Object.values(executorRole.rows[0]).every(Boolean)) throw new Error(`El rol ejecutor conserva atributos elevados: ${JSON.stringify(executorRole.rows[0] || null)}`)

  const unsafeRelationOwners = await db.query(`
    SELECT n.nspname AS schema_name,c.relname AS relation_name,owner.rolname AS owner
    FROM pg_class c
    JOIN pg_namespace n ON n.oid=c.relnamespace
    JOIN pg_roles owner ON owner.oid=c.relowner
    WHERE n.nspname IN ('public','ase_private','storage') AND c.relkind IN ('r','p','v','m','S')
      AND owner.rolname IN ('anon','authenticated','service_role','ase_tenant_executor')
    ORDER BY n.nspname,c.relname
  `)
  if (unsafeRelationOwners.rows.length) throw new Error(`Relaciones propiedad de roles del API o ejecutor: ${JSON.stringify(unsafeRelationOwners.rows)}`)

  const unsafeRoleMemberships = await db.query(`
    SELECT member_role.rolname AS member,granted_role.rolname AS granted_role
    FROM pg_auth_members membership
    JOIN pg_roles member_role ON member_role.oid=membership.member
    JOIN pg_roles granted_role ON granted_role.oid=membership.roleid
    WHERE member_role.rolname IN ('anon','authenticated','service_role','ase_tenant_executor')
      AND granted_role.rolname IN ('postgres','service_role','ase_tenant_executor')
    ORDER BY member_role.rolname,granted_role.rolname
  `)
  if (unsafeRoleMemberships.rows.length) throw new Error(`Membresías privilegiadas inesperadas: ${JSON.stringify(unsafeRoleMemberships.rows)}`)

  const unsafeSchemaCreate = await db.query(`
    SELECT role.rolname AS role_name,n.nspname AS schema_name
    FROM pg_roles role
    CROSS JOIN pg_namespace n
    WHERE role.rolname IN ('anon','authenticated','service_role','ase_tenant_executor')
      AND n.nspname IN ('public','ase_private','storage')
      AND has_schema_privilege(role.rolname,n.oid,'CREATE')
    ORDER BY role.rolname,n.nspname
  `)
  if (unsafeSchemaCreate.rows.length) throw new Error(`Roles con permiso de crear objetos en esquemas operativos: ${JSON.stringify(unsafeSchemaCreate.rows)}`)

  const unsafeSequencePrivileges = await db.query(`
    SELECT grantee,object_schema,object_name,privilege_type
    FROM information_schema.role_usage_grants
    WHERE grantee IN ('anon','authenticated')
      AND object_type='SEQUENCE'
      AND object_schema IN ('public','ase_private','storage')
    ORDER BY grantee,object_schema,object_name,privilege_type
  `)
  if (unsafeSequencePrivileges.rows.length) throw new Error(`El API conserva acceso directo a secuencias: ${JSON.stringify(unsafeSequencePrivileges.rows)}`)

  const postgresOwnedApiRoutines = await db.query(`
    SELECT p.oid::regprocedure::text AS name,
      has_function_privilege('anon',p.oid,'EXECUTE') AS anon,
      has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    JOIN pg_roles owner ON owner.oid=p.proowner
    WHERE n.nspname IN ('public','ase_private') AND p.prosecdef AND owner.rolname='postgres'
      AND (has_function_privilege('anon',p.oid,'EXECUTE') OR has_function_privilege('authenticated',p.oid,'EXECUTE'))
    ORDER BY 1
  `)
  const expectedPostgresOwnedApiRoutines = [
    { name: 'ase_private.current_org()', anon: false, authenticated: true },
    { name: 'ase_private.session_role()', anon: true, authenticated: true },
    { name: 'ase_private.session_user_id()', anon: true, authenticated: true },
    { name: 'mt_context()', anon: false, authenticated: true },
    { name: 'mt_create_organization(text,text)', anon: false, authenticated: true },
    { name: 'mt_prepare_email_change(uuid,text)', anon: false, authenticated: true },
    { name: 'mt_resolve_task_access(text)', anon: false, authenticated: true }
  ]
  if (JSON.stringify(postgresOwnedApiRoutines.rows) !== JSON.stringify(expectedPostgresOwnedApiRoutines)) throw new Error(`Superficie privilegiada de postgres inesperada: ${JSON.stringify(postgresOwnedApiRoutines.rows)}`)
  const unsafePrivilegedRoutines = await db.query(`
    SELECT p.oid::regprocedure::text AS name
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname IN ('public','ase_private') AND p.prosecdef
      AND NOT ('search_path=""'=ANY(coalesce(p.proconfig,ARRAY[]::text[])))
    ORDER BY 1
  `)
  if (unsafePrivilegedRoutines.rows.length) throw new Error(`Funciones privilegiadas sin search_path vacío: ${unsafePrivilegedRoutines.rows.map(routine => routine.name).join(', ')}`)

  const anonymousTablePrivileges = await db.query(`
    SELECT table_schema,table_name,privilege_type
    FROM information_schema.role_table_grants
    WHERE grantee='anon' AND table_schema IN ('public','storage','ase_private')
    ORDER BY table_schema,table_name,privilege_type
  `)
  const dangerousApiPrivileges = await db.query(`
    SELECT grantee,table_schema,table_name,privilege_type
    FROM information_schema.role_table_grants
    WHERE grantee IN ('anon','authenticated')
      AND table_schema IN ('public','storage','ase_private')
      AND privilege_type IN ('TRUNCATE','REFERENCES','TRIGGER')
    ORDER BY grantee,table_schema,table_name,privilege_type
  `)
  if (anonymousTablePrivileges.rows.length) throw new Error(`El rol anónimo tiene permisos directos sobre tablas: ${JSON.stringify(anonymousTablePrivileges.rows)}`)
  if (dangerousApiPrivileges.rows.length) throw new Error(`El API tiene permisos peligrosos sobre tablas: ${JSON.stringify(dangerousApiPrivileges.rows)}`)

  const authenticatedMutations = await db.query(`
    SELECT table_schema,table_name,string_agg(privilege_type,',' ORDER BY privilege_type) AS privileges
    FROM information_schema.role_table_grants
    WHERE grantee='authenticated' AND table_schema IN ('public','ase_private')
      AND privilege_type IN ('INSERT','UPDATE','DELETE')
    GROUP BY table_schema,table_name
    ORDER BY table_schema,table_name
  `)
  const expectedAuthenticatedMutations = []
  if (JSON.stringify(authenticatedMutations.rows) !== JSON.stringify(expectedAuthenticatedMutations)) throw new Error(`Superficie de escritura autenticada inesperada: ${JSON.stringify(authenticatedMutations.rows)}`)

  const tenantBoundaries = await db.query(`
    SELECT c.table_name,
      EXISTS(
        SELECT 1 FROM pg_policies p
        WHERE p.schemaname='public' AND p.tablename=c.table_name
          AND (coalesce(p.qual,'') LIKE '%current_org()%' OR coalesce(p.with_check,'') LIKE '%current_org()%')
      ) AS protected
    FROM information_schema.columns c
    WHERE c.table_schema='public' AND c.column_name='organization_id'
    ORDER BY c.table_name
  `)
  const unprotectedTenantTables = tenantBoundaries.rows.filter(table => !table.protected).map(table => table.table_name)
  if (unprotectedTenantTables.length) throw new Error(`Tablas sin límite de empresa propio: ${unprotectedTenantTables.join(', ')}`)

  const nullableTenantColumns = await db.query(`
    SELECT table_name
    FROM information_schema.columns
    WHERE table_schema='public' AND column_name='organization_id' AND is_nullable<>'NO'
    ORDER BY table_name
  `)
  const crossTenantForeignKeys = await db.query(`
    SELECT DISTINCT source.relname AS source_table,target.relname AS target_table
    FROM pg_constraint c
    JOIN pg_class source ON source.oid=c.conrelid
    JOIN pg_namespace source_schema ON source_schema.oid=source.relnamespace
    JOIN pg_class target ON target.oid=c.confrelid
    JOIN pg_namespace target_schema ON target_schema.oid=target.relnamespace
    JOIN pg_attribute source_org ON source_org.attrelid=source.oid AND source_org.attname='organization_id'
    JOIN pg_attribute target_org ON target_org.attrelid=target.oid AND target_org.attname='organization_id'
    WHERE c.contype='f' AND source_schema.nspname='public' AND target_schema.nspname='public'
      AND NOT EXISTS(
        SELECT 1 FROM pg_constraint safe
        WHERE safe.contype='f' AND safe.conrelid=c.conrelid AND safe.confrelid=c.confrelid
          AND source_org.attnum=ANY(safe.conkey) AND target_org.attnum=ANY(safe.confkey)
      )
    ORDER BY source.relname,target.relname
  `)
  if (nullableTenantColumns.rows.length) throw new Error(`Columnas de empresa que admiten NULL: ${nullableTenantColumns.rows.map(column => column.table_name).join(', ')}`)
  if (crossTenantForeignKeys.rows.length) throw new Error(`Relaciones sin clave compuesta de empresa: ${crossTenantForeignKeys.rows.map(relation => `${relation.source_table}->${relation.target_table}`).join(', ')}`)

  const foreignKeysWithoutIndex = await db.query(`
    SELECT source.relname AS source_table,c.conname AS constraint_name
    FROM pg_constraint c
    JOIN pg_class source ON source.oid=c.conrelid
    JOIN pg_namespace source_schema ON source_schema.oid=source.relnamespace
    WHERE c.contype='f' AND source_schema.nspname='public'
      AND NOT EXISTS(
        SELECT 1 FROM pg_index i
        WHERE i.indrelid=c.conrelid AND i.indisvalid AND i.indisready AND i.indpred IS NULL
          AND i.indnkeyatts>=cardinality(c.conkey)
          AND NOT EXISTS(
            SELECT 1 FROM generate_subscripts(c.conkey,1) position
            WHERE i.indkey[position-1]<>c.conkey[position]
          )
      )
    ORDER BY source.relname,c.conname
  `)
  if (foreignKeysWithoutIndex.rows.length) throw new Error(`Claves foráneas sin índice de apoyo: ${foreignKeysWithoutIndex.rows.map(item => `${item.source_table}.${item.constraint_name}`).join(', ')}`)

  console.log(JSON.stringify({
    passed: true,
    migrationCount: migrations.length,
    lastMigration: migrations.at(-1),
    checks: state,
    isolation: { tables: tables.rows.length, withoutRls: 0, tablesWithoutPrimaryKey: 0, invalidConstraints: 0, invalidIndexes: 0, publicRoutines: 0, privateRelationsExposed: 0, anonymousPrivateHelpers: anonRoutines.length, authenticatedPrivateHelpers: authenticatedRoutines.length, anonymousApi, serviceApi, storageRls: true, storagePolicies: storagePolicies.rows.length, privilegedOwners: privilegedOwners.rows, executorRoleRestricted: true, unsafeRelationOwners: 0, unsafeRoleMemberships: 0, unsafeSchemaCreate: 0, unsafeSequencePrivileges: 0, authenticatedMutationTables: authenticatedMutations.rows.length, postgresOwnedApiRoutines: postgresOwnedApiRoutines.rows.length, anonymousTablePrivileges: 0, dangerousApiPrivileges: 0, tenantBoundaries: tenantBoundaries.rows.length, tenantTablesWithoutBoundary: 0, nullableTenantColumns: 0, crossTenantForeignKeys: 0, foreignKeysWithoutIndex: 0 }
  }))
} finally {
  await db.close()
}

const freshDb = new PGlite({ extensions: { pgcrypto } })
try {
  await freshDb.exec(fs.readFileSync(`${root}supabase/tests/bootstrap.sql`, 'utf8'))
  await freshDb.exec(`INSERT INTO auth.users(id,email,raw_user_meta_data,email_confirmed_at) VALUES('${owner}','owner@example.test','{"full_name":"Empresa Nueva"}',now())`)
  const template = fs.readFileSync(`${root}deployment/generated/instalacion-nueva-plantilla.sql`, 'utf8')
  const automation = fs.readFileSync(`${root}deployment/generated/activar-automatizaciones.sql`, 'utf8')
  const verification = fs.readFileSync(`${root}deployment/generated/verificar-instalacion.sql`, 'utf8')
  const healthCheck = fs.readFileSync(`${root}deployment/generated/comprobar-salud.sql`, 'utf8')
  if (!automation.includes("ase-work-recurrences") || !automation.includes("ase-work-deadline-notifications") || !automation.includes('cron.unschedule')) throw new Error('Paquete de automatización incompleto')
  if (!verification.includes("'ASE Work listo'") || !verification.includes('Automatizaciones horarias incompletas')) throw new Error('Verificador alojado incompleto')
  if (!healthCheck.includes("'fichajes_abiertos_mas_24h'") || !healthCheck.includes("'recurrencias_con_error'") || !healthCheck.includes("'fallos_24h'") || !healthCheck.includes('No muestra nombres, correos, títulos ni contenido')) throw new Error('Diagnóstico operativo incompleto')
  const configured = template
    .replaceAll('__ASE_OWNER_EMAIL__', 'owner@example.test')
    .replaceAll('__ASE_COMPANY_NAME__', 'Empresa Nueva')
    .replaceAll('__ASE_COMPANY_SLUG__', 'empresa-nueva')
  await freshDb.exec(configured)
  const installed = await freshDb.query(`
    SELECT o.name,o.slug,m.role,m.status,
      (SELECT public IS FALSE FROM storage.buckets WHERE id='task-files') AS private_bucket,
      NOT has_schema_privilege('ase_tenant_executor','public','CREATE') AS executor_locked
    FROM public.organizations o
    JOIN public.organization_memberships m ON m.organization_id=o.id
    WHERE m.user_id=$1
  `, [owner])
  const row = installed.rows[0]
  if (!row || row.name!=='Empresa Nueva' || row.slug!=='empresa-nueva' || row.role!=='owner' || row.status!=='active' || !row.private_bucket || !row.executor_locked) {
    throw new Error(`Instalación nueva incompleta: ${JSON.stringify(row)}`)
  }
  console.log(JSON.stringify({ passed: true, freshInstall: row }))
} finally {
  await freshDb.close()
}
