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

if (!checkOnly) {
  fs.mkdirSync(outputDir, { recursive: true })
  fs.writeFileSync(path.join(outputDir, 'actualizacion-completa.sql'), combined)
  fs.writeFileSync(path.join(outputDir, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`)
}

const expectedLast = process.env.ASE_EXPECTED_LAST_MIGRATION
if (expectedLast && expectedLast !== manifest.lastMigration) {
  throw new Error(`El paquete termina en ${manifest.lastMigration}, no en ${expectedLast}.`)
}

console.log(JSON.stringify({ ok: true, checkOnly, ...manifest }))
