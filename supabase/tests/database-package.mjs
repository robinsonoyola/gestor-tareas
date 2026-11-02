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
