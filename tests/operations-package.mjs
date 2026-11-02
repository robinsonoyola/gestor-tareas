import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const backup = fs.readFileSync(path.join(root, 'scripts', 'backup-database.ps1'), 'utf8')
const restore = fs.readFileSync(path.join(root, 'scripts', 'restore-database-test.ps1'), 'utf8')

const requiredBackup = ['ASE_BACKUP_DATABASE_URL', '--format=custom', 'pg_restore', '--list', 'Get-FileHash', 'SHA256']
const requiredRestore = ['ASE-WORK-TEST-RESTORE', 'IUnderstandThisErasesTargetDatabase', 'ASE_RESTORE_DATABASE_URL', 'Origen y destino son la misma base', 'xfzkfhxdrotczbsxxztr', '--exit-on-error']

for (const marker of requiredBackup) {
  if (!backup.includes(marker)) throw new Error(`La copia no contiene el control ${marker}`)
}
for (const marker of requiredRestore) {
  if (!restore.includes(marker)) throw new Error(`La restauración no contiene el control ${marker}`)
}
if (/service_role|SUPABASE_SERVICE_ROLE_KEY/.test(backup + restore)) throw new Error('Las utilidades no deben usar service_role')

console.log(JSON.stringify({ passed: true, backupControls: requiredBackup.length, restoreControls: requiredRestore.length }))
