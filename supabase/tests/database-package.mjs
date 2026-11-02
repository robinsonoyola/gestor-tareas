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

  console.log(JSON.stringify({
    passed: true,
    migrationCount: migrations.length,
    lastMigration: migrations.at(-1),
    checks: state
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
