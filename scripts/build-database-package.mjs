import fs from 'node:fs'
import path from 'node:path'
import { createHash } from 'node:crypto'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const migrationsDir = path.join(root, 'supabase', 'migrations')
const outputDir = path.join(root, 'deployment', 'generated')
const checkOnly = process.argv.includes('--check')
const migrationPattern = /^\d{14}_[a-z0-9_]+\.sql$/

const files = fs.readdirSync(migrationsDir)
  .filter(name => name.endsWith('.sql'))
  .sort((a, b) => a.localeCompare(b, 'en'))

if (!files.length) throw new Error('No hay migraciones para empaquetar.')
const invalidNames = files.filter(name => !migrationPattern.test(name))
if (invalidNames.length) throw new Error(`Migraciones con nombre no versionado: ${invalidNames.join(', ')}`)
if (new Set(files.map(name => name.slice(0, 14))).size !== files.length) throw new Error('Hay dos migraciones con la misma versión.')

function migrationBody(name) {
  const sql = fs.readFileSync(path.join(migrationsDir, name), 'utf8').replace(/^\uFEFF/, '')
  const begins = sql.match(/^BEGIN;\s*$/gm) || []
  const commits = sql.match(/^COMMIT;\s*$/gm) || []
  if (begins.length !== 1 || commits.length !== 1) {
    throw new Error(`${name} debe contener exactamente un BEGIN y un COMMIT.`)
  }
  return sql.replace(/^BEGIN;\s*$/m, '').replace(/^COMMIT;\s*$/m, '').trim()
}

const bodies = files.map(name => `\n-- ==== ${name} ====\n${migrationBody(name)}`)
const combined = [
  '-- ASE Work - actualización completa desde la captura heredada del 22/10/2026.',
  '-- No es el instalador de una empresa nueva. Requiere copia verificada y la captura indicada.',
  '-- Todas las migraciones se ejecutan en una sola transacción.',
  'BEGIN;',
  ...bodies,
  'COMMIT;',
  ''
].join('\n')

const sha256 = createHash('sha256').update(combined).digest('hex').toUpperCase()
const manifest = {
  format: 1,
  purpose: 'legacy-upgrade',
  migrationCount: files.length,
  firstMigration: files[0],
  lastMigration: files.at(-1),
  migrations: files,
  combinedSqlSha256: sha256
}

const baseline = fs.readFileSync(path.join(root, 'supabase', 'baseline', '20261022_installed_public.sql'), 'utf8').replace(/^\uFEFF/, '')
const storageBaseline = fs.readFileSync(path.join(root, 'supabase', 'tests', 'storage-baseline.sql'), 'utf8').replace(/^\uFEFF/, '')
const freshInstall = [
  '-- ASE Work - instalación de una empresa nueva en un proyecto Supabase vacío.',
  '-- Antes de ejecutar: crea y confirma el primer usuario en Authentication > Users.',
  '-- Sustituye exactamente los tres valores __ASE_*__ siguientes. Si queda alguno, la instalación se detiene.',
  'BEGIN;',
  "CREATE TEMP TABLE ase_install_config(owner_email text NOT NULL,company_name text NOT NULL,company_slug text NOT NULL) ON COMMIT DROP;",
  "INSERT INTO ase_install_config VALUES('__ASE_OWNER_EMAIL__','__ASE_COMPANY_NAME__','__ASE_COMPANY_SLUG__');",
  "DO $validate$ DECLARE c ase_install_config%ROWTYPE; BEGIN SELECT * INTO c FROM ase_install_config; IF c.owner_email LIKE '%__ASE_%' OR c.company_name LIKE '%__ASE_%' OR c.company_slug LIKE '%__ASE_%' THEN RAISE EXCEPTION 'Configura correo, empresa e identificador antes de ejecutar'; END IF; IF c.owner_email !~* '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' OR length(c.company_name) NOT BETWEEN 1 AND 150 OR c.company_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' OR length(c.company_slug)>80 THEN RAISE EXCEPTION 'Configuración inicial no válida'; END IF; IF (SELECT count(*) FROM auth.users WHERE lower(email)=lower(c.owner_email))<>1 THEN RAISE EXCEPTION 'Debe existir exactamente un usuario Auth con el correo indicado'; END IF; END $validate$;",
  'CREATE SCHEMA IF NOT EXISTS extensions;',
  'CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;',
  baseline,
  "DO $bucket$ BEGIN IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='storage' AND table_name='buckets' AND column_name='name') THEN INSERT INTO storage.buckets(id,name,public) VALUES('task-files','task-files',false) ON CONFLICT(id) DO UPDATE SET public=false; ELSE INSERT INTO storage.buckets(id,public) VALUES('task-files',false) ON CONFLICT(id) DO UPDATE SET public=false; END IF; END $bucket$;",
  storageBaseline,
  "INSERT INTO public.users(id,email,full_name,is_admin) SELECT id,email,coalesce(nullif(btrim(raw_user_meta_data->>'full_name'),''),split_part(email,'@',1)),true FROM auth.users u CROSS JOIN ase_install_config c WHERE lower(u.email)=lower(c.owner_email);",
  'INSERT INTO public.work_settings(singleton,enabled) VALUES(true,false);',
  ...bodies,
  "DO $finish$ DECLARE c ase_install_config%ROWTYPE; owner_id uuid; org_id uuid; BEGIN SELECT * INTO c FROM ase_install_config; SELECT id INTO STRICT owner_id FROM auth.users WHERE lower(email)=lower(c.owner_email); SELECT organization_id INTO STRICT org_id FROM public.organization_memberships WHERE user_id=owner_id AND status='active'; UPDATE public.organization_memberships SET role='owner' WHERE organization_id=org_id AND user_id=owner_id; UPDATE public.organizations SET name=c.company_name,slug=c.company_slug WHERE id=org_id; END $finish$;",
  'COMMIT;',
  ''
].join('\n')
const freshSha256 = createHash('sha256').update(freshInstall).digest('hex').toUpperCase()
manifest.freshInstallTemplateSha256 = freshSha256
const automation = `-- ASE Work - automatizaciones internas independientes del navegador.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname IN ('ase-work-recurrences','ase-work-deadline-notifications');
SELECT cron.schedule('ase-work-recurrences','17 * * * *','SELECT ase_private.schedule_recurrences()');
SELECT cron.schedule('ase-work-deadline-notifications','27 * * * *','SELECT ase_private.schedule_deadline_notifications()');
COMMIT;
SELECT jobname,schedule,active FROM cron.job WHERE jobname IN ('ase-work-recurrences','ase-work-deadline-notifications') ORDER BY jobname;
`
const verification = `-- ASE Work - verificación posterior a instalación. No modifica datos.
DO $verify$
DECLARE failures text[]:='{}';
BEGIN
 IF to_regclass('public.organizations') IS NULL OR to_regclass('public.work_task_archive_events') IS NULL OR to_regclass('public.work_projects') IS NULL THEN failures:=array_append(failures,'Faltan tablas del gestor'); END IF;
 IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tasks' AND column_name='archived_at') THEN failures:=array_append(failures,'Falta archivo de actividades'); END IF;
 IF NOT EXISTS(SELECT 1 FROM public.organization_memberships WHERE role='owner' AND status='active') THEN failures:=array_append(failures,'Falta propietario activo'); END IF;
 IF NOT EXISTS(SELECT 1 FROM storage.buckets WHERE id='task-files' AND public IS FALSE) THEN failures:=array_append(failures,'El almacenamiento task-files no es privado'); END IF;
 IF has_schema_privilege('ase_tenant_executor','public','CREATE') OR has_schema_privilege('ase_tenant_executor','ase_private','CREATE') THEN failures:=array_append(failures,'El ejecutor conserva CREATE'); END IF;
 IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname IN ('anon','authenticated') AND (rolsuper OR rolbypassrls)) THEN failures:=array_append(failures,'Rol API con privilegios elevados'); END IF;
 IF has_schema_privilege('public','ase_private','USAGE') THEN failures:=array_append(failures,'El esquema privado permite acceso público'); END IF;
 IF EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='ase_private' AND c.relkind IN ('r','p','v','m') AND (has_table_privilege('anon',c.oid,'SELECT,INSERT,UPDATE,DELETE') OR has_table_privilege('authenticated',c.oid,'SELECT,INSERT,UPDATE,DELETE'))) THEN failures:=array_append(failures,'Hay relaciones privadas expuestas al API'); END IF;
 IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='ase_private' AND has_function_privilege('public',p.oid,'EXECUTE')) THEN failures:=array_append(failures,'Hay funciones privadas expuestas a PUBLIC'); END IF;
 IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND has_function_privilege('anon',p.oid,'EXECUTE'))<>11 OR EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND has_function_privilege('anon',p.oid,'EXECUTE') AND NOT p.oid=ANY(ARRAY['public.work_station_checklist(text,uuid,uuid,boolean)'::regprocedure,'public.work_station_confirm(text,uuid,text)'::regprocedure,'public.work_station_confirm_v2(text,uuid,text)'::regprocedure,'public.work_station_day(text,uuid)'::regprocedure,'public.work_station_day_v2(text,uuid)'::regprocedure,'public.work_station_identify(text,text)'::regprocedure,'public.work_station_identify_result(text,text,text,uuid)'::regprocedure,'public.work_station_identify_v2(text,text,text,uuid)'::regprocedure,'public.work_station_people(text)'::regprocedure,'public.work_station_save_result(text,uuid,text)'::regprocedure,'public.work_usability_ready()'::regprocedure])) THEN failures:=array_append(failures,'La superficie anónima del API no coincide con los puntos de fichaje'); END IF;
 IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND has_function_privilege('service_role',p.oid,'EXECUTE'))<>4 OR EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND has_function_privilege('service_role',p.oid,'EXECUTE') AND NOT p.oid=ANY(ARRAY['public.mt_attach_created_employee(uuid,uuid,uuid,text,text,text,uuid)'::regprocedure,'public.mt_email_change_grant(uuid)'::regprocedure,'public.mt_finish_email_change(uuid)'::regprocedure,'public.mt_identity_email_exists(text)'::regprocedure])) THEN failures:=array_append(failures,'La superficie de service_role no coincide con las funciones administrativas'); END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='storage' AND c.relname='objects' AND c.relrowsecurity) THEN failures:=array_append(failures,'storage.objects no tiene RLS activo'); END IF;
 IF (SELECT count(*) FROM pg_policies WHERE schemaname='storage' AND tablename='objects')<>9 OR EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='storage' AND tablename='objects' AND (policyname<>ALL(ARRAY['incident_upload','sec04_read_assigned_task_files','sec04_upload_own_assigned_task_files','task_files_insert','work_files_insert','work_files_read','work_incident_attachment_executor','work_incident_file_read','work_upload_active_checkin']) OR roles&&ARRAY['anon','public']::name[])) THEN failures:=array_append(failures,'Las políticas de almacenamiento no coinciden con la lista segura'); END IF;
 IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','ase_private') AND p.prosecdef)<>208 OR EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles r ON r.oid=p.proowner WHERE n.nspname IN ('public','ase_private') AND p.prosecdef AND (r.rolname NOT IN ('ase_tenant_executor','postgres') OR NOT ('search_path=""'=ANY(coalesce(p.proconfig,ARRAY[]::text[]))))) THEN failures:=array_append(failures,'Las funciones privilegiadas no coinciden con la propiedad y configuración seguras'); END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='ase_tenant_executor' AND NOT rolsuper AND NOT rolcreaterole AND NOT rolcreatedb AND NOT rolcanlogin AND NOT rolreplication AND NOT rolbypassrls) THEN failures:=array_append(failures,'El rol ejecutor conserva atributos elevados'); END IF;
 IF EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace JOIN pg_roles owner ON owner.oid=c.relowner WHERE n.nspname IN ('public','ase_private','storage') AND c.relkind IN ('r','p','v','m','S') AND owner.rolname IN ('anon','authenticated','service_role','ase_tenant_executor')) THEN failures:=array_append(failures,'Hay relaciones propiedad de roles del API o del ejecutor'); END IF;
 IF EXISTS(SELECT 1 FROM pg_auth_members membership JOIN pg_roles member_role ON member_role.oid=membership.member JOIN pg_roles granted_role ON granted_role.oid=membership.roleid WHERE member_role.rolname IN ('anon','authenticated','service_role','ase_tenant_executor') AND granted_role.rolname IN ('postgres','service_role','ase_tenant_executor')) THEN failures:=array_append(failures,'Hay membresías privilegiadas entre roles del servicio'); END IF;
 IF EXISTS(SELECT 1 FROM pg_roles role CROSS JOIN pg_namespace n WHERE role.rolname IN ('anon','authenticated','service_role','ase_tenant_executor') AND n.nspname IN ('public','ase_private','storage') AND has_schema_privilege(role.rolname,n.oid,'CREATE')) THEN failures:=array_append(failures,'Un rol del servicio puede crear objetos en un esquema operativo'); END IF;
 IF EXISTS(SELECT 1 FROM information_schema.role_usage_grants WHERE grantee IN ('anon','authenticated') AND object_type='SEQUENCE' AND object_schema IN ('public','ase_private','storage')) THEN failures:=array_append(failures,'El API conserva acceso directo a secuencias'); END IF;
 IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles owner ON owner.oid=p.proowner WHERE n.nspname IN ('public','ase_private') AND p.prosecdef AND owner.rolname='postgres' AND (has_function_privilege('anon',p.oid,'EXECUTE') OR has_function_privilege('authenticated',p.oid,'EXECUTE')))<>7 OR EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles owner ON owner.oid=p.proowner WHERE n.nspname IN ('public','ase_private') AND p.prosecdef AND owner.rolname='postgres' AND (has_function_privilege('anon',p.oid,'EXECUTE') OR has_function_privilege('authenticated',p.oid,'EXECUTE')) AND (NOT p.oid=ANY(ARRAY['ase_private.current_org()'::regprocedure,'ase_private.session_role()'::regprocedure,'ase_private.session_user_id()'::regprocedure,'public.mt_context()'::regprocedure,'public.mt_create_organization(text,text)'::regprocedure,'public.mt_prepare_email_change(uuid,text)'::regprocedure,'public.mt_resolve_task_access(text)'::regprocedure]) OR NOT has_function_privilege('authenticated',p.oid,'EXECUTE') OR (has_function_privilege('anon',p.oid,'EXECUTE') AND NOT p.oid=ANY(ARRAY['ase_private.session_role()'::regprocedure,'ase_private.session_user_id()'::regprocedure])))) THEN failures:=array_append(failures,'La superficie privilegiada de postgres no coincide con la lista segura'); END IF;
 IF EXISTS(SELECT 1 FROM information_schema.role_table_grants WHERE grantee='anon' AND table_schema IN ('public','storage','ase_private')) THEN failures:=array_append(failures,'El rol anónimo conserva permisos directos sobre tablas'); END IF;
 IF EXISTS(SELECT 1 FROM information_schema.role_table_grants WHERE grantee IN ('anon','authenticated') AND table_schema IN ('public','storage','ase_private') AND privilege_type IN ('TRUNCATE','REFERENCES','TRIGGER')) THEN failures:=array_append(failures,'Los roles API conservan permisos peligrosos sobre tablas'); END IF;
 IF EXISTS(SELECT 1 FROM information_schema.columns c WHERE c.table_schema='public' AND c.column_name='organization_id' AND NOT EXISTS(SELECT 1 FROM pg_policies p WHERE p.schemaname='public' AND p.tablename=c.table_name AND (coalesce(p.qual,'') LIKE '%current_org()%' OR coalesce(p.with_check,'') LIKE '%current_org()%'))) THEN failures:=array_append(failures,'Hay tablas de empresa sin un límite RLS propio'); END IF;
 IF EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relkind IN ('r','p') AND NOT EXISTS(SELECT 1 FROM pg_constraint constraint_definition WHERE constraint_definition.conrelid=c.oid AND constraint_definition.contype='p')) THEN failures:=array_append(failures,'Hay tablas sin clave primaria'); END IF;
 IF EXISTS(SELECT 1 FROM pg_constraint constraint_definition JOIN pg_class c ON c.oid=constraint_definition.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND NOT constraint_definition.convalidated) THEN failures:=array_append(failures,'Hay restricciones de tabla sin validar'); END IF;
 IF EXISTS(SELECT 1 FROM pg_index index_definition JOIN pg_class c ON c.oid=index_definition.indrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND (NOT index_definition.indisvalid OR NOT index_definition.indisready)) THEN failures:=array_append(failures,'Hay índices inválidos o incompletos'); END IF;
 IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND column_name='organization_id' AND is_nullable<>'NO') THEN failures:=array_append(failures,'Hay columnas de empresa que admiten NULL'); END IF;
 IF EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class source ON source.oid=c.conrelid JOIN pg_namespace source_schema ON source_schema.oid=source.relnamespace JOIN pg_class target ON target.oid=c.confrelid JOIN pg_namespace target_schema ON target_schema.oid=target.relnamespace JOIN pg_attribute source_org ON source_org.attrelid=source.oid AND source_org.attname='organization_id' JOIN pg_attribute target_org ON target_org.attrelid=target.oid AND target_org.attname='organization_id' WHERE c.contype='f' AND source_schema.nspname='public' AND target_schema.nspname='public' AND NOT EXISTS(SELECT 1 FROM pg_constraint safe WHERE safe.contype='f' AND safe.conrelid=c.conrelid AND safe.confrelid=c.confrelid AND source_org.attnum=ANY(safe.conkey) AND target_org.attnum=ANY(safe.confkey))) THEN failures:=array_append(failures,'Hay relaciones entre tablas sin una clave compuesta de empresa'); END IF;
 IF EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class source ON source.oid=c.conrelid JOIN pg_namespace source_schema ON source_schema.oid=source.relnamespace WHERE c.contype='f' AND source_schema.nspname='public' AND NOT EXISTS(SELECT 1 FROM pg_index i WHERE i.indrelid=c.conrelid AND i.indisvalid AND i.indisready AND i.indpred IS NULL AND i.indnkeyatts>=cardinality(c.conkey) AND NOT EXISTS(SELECT 1 FROM generate_subscripts(c.conkey,1) position WHERE i.indkey[position-1]<>c.conkey[position]))) THEN failures:=array_append(failures,'Hay claves foráneas sin índice de apoyo'); END IF;
 IF (SELECT count(*) FROM cron.job WHERE active AND jobname IN ('ase-work-recurrences','ase-work-deadline-notifications'))<>2 THEN failures:=array_append(failures,'Automatizaciones horarias incompletas'); END IF;
 IF cardinality(failures)>0 THEN RAISE EXCEPTION 'Instalación incompleta: %',array_to_string(failures,'; '); END IF;
END $verify$;
SELECT 'ASE Work listo' AS resultado,
 (SELECT count(*) FROM public.organizations WHERE status='active') AS empresas_activas,
 (SELECT count(*) FROM cron.job WHERE active AND jobname IN ('ase-work-recurrences','ase-work-deadline-notifications')) AS automatizaciones_activas;
`
const healthCheck = `-- ASE Work - diagnóstico operativo de solo lectura.
-- Puede ejecutarse en el editor SQL cuando soporte necesite comprobar el servicio.
-- No muestra nombres, correos, títulos ni contenido de clientes.
SELECT 'configuracion' AS bloque,
 jsonb_build_object(
  'empresas_activas',(SELECT count(*) FROM public.organizations WHERE status='active'),
  'propietarios_activos',(SELECT count(*) FROM public.organization_memberships WHERE role='owner' AND status='active'),
  'almacenamiento_privado',EXISTS(SELECT 1 FROM storage.buckets WHERE id='task-files' AND public IS FALSE),
  'ejecutor_bloqueado',NOT has_schema_privilege('ase_tenant_executor','public','CREATE') AND NOT has_schema_privilege('ase_tenant_executor','ase_private','CREATE')
 ) AS estado
UNION ALL
SELECT 'automatizaciones',
 jsonb_build_object(
  'esperadas',2,
  'activas',(SELECT count(*) FROM cron.job WHERE active AND jobname IN ('ase-work-recurrences','ase-work-deadline-notifications')),
  'ultima_ejecucion',(SELECT max(end_time) FROM cron.job_run_details WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname IN ('ase-work-recurrences','ase-work-deadline-notifications'))),
  'fallos_24h',(SELECT count(*) FROM cron.job_run_details WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname IN ('ase-work-recurrences','ase-work-deadline-notifications')) AND status<>'succeeded' AND start_time>=now()-interval '24 hours')
 )
UNION ALL
SELECT 'operacion',
 jsonb_build_object(
  'fichajes_abiertos',(SELECT count(*) FROM public.checkins WHERE checkout_time IS NULL),
  'fichajes_abiertos_mas_24h',(SELECT count(*) FROM public.checkins WHERE checkout_time IS NULL AND checkin_time<now()-interval '24 hours'),
  'recurrencias_con_error',(SELECT count(*) FROM public.work_recurrences WHERE last_error IS NOT NULL),
  'empresas_sin_propietario',(SELECT count(*) FROM public.organizations o WHERE o.status='active' AND NOT EXISTS(SELECT 1 FROM public.organization_memberships m WHERE m.organization_id=o.id AND m.role='owner' AND m.status='active'))
 );

SELECT jobname,schedule,active
FROM cron.job
WHERE jobname IN ('ase-work-recurrences','ase-work-deadline-notifications')
ORDER BY jobname;
`
manifest.automationSha256 = createHash('sha256').update(automation).digest('hex').toUpperCase()
manifest.verificationSha256 = createHash('sha256').update(verification).digest('hex').toUpperCase()
manifest.healthCheckSha256 = createHash('sha256').update(healthCheck).digest('hex').toUpperCase()

if (!checkOnly) {
  fs.mkdirSync(outputDir, { recursive: true })
  fs.writeFileSync(path.join(outputDir, 'actualizacion-completa.sql'), combined)
  fs.writeFileSync(path.join(outputDir, 'instalacion-nueva-plantilla.sql'), freshInstall)
  fs.writeFileSync(path.join(outputDir, 'activar-automatizaciones.sql'), automation)
  fs.writeFileSync(path.join(outputDir, 'verificar-instalacion.sql'), verification)
  fs.writeFileSync(path.join(outputDir, 'comprobar-salud.sql'), healthCheck)
  fs.writeFileSync(path.join(outputDir, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`)
}

const expectedLast = process.env.ASE_EXPECTED_LAST_MIGRATION
if (expectedLast && expectedLast !== manifest.lastMigration) {
  throw new Error(`El paquete termina en ${manifest.lastMigration}, no en ${expectedLast}.`)
}

console.log(JSON.stringify({ ok: true, checkOnly, ...manifest }))
