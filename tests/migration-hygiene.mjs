import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const directory = path.join(root, 'supabase', 'migrations')
const files = fs.readdirSync(directory).filter(file => file.endsWith('.sql')).sort()
if (files.length !== 77 || files.some(file => !/^\d{14}_[a-z0-9_]+\.sql$/.test(file))) throw new Error('El inventario o nombre de las migraciones no es el esperado')

let privilegedFunctions = 0
for (const file of files) {
  const sql = fs.readFileSync(path.join(directory, file), 'utf8')
  if (!/^\s*(?:--[^\r\n]*\r?\n\s*)*BEGIN\s*;/i.test(sql) || !/COMMIT\s*;\s*$/i.test(sql)) throw new Error(`${file} no está encerrada en una transacción completa`)
  if (/GRANT\b[^;]*\bTO\s+PUBLIC\b/i.test(sql)) throw new Error(`${file} concede permisos a PUBLIC`)
  if (sql.includes('xfzkfhxdrotczbsxxztr')) throw new Error(`${file} contiene la referencia de producción`)

  for (const match of sql.matchAll(/SECURITY\s+DEFINER/gi)) {
    privilegedFunctions += 1
    const declaration = sql.slice(Math.max(0, match.index - 300), Math.min(sql.length, match.index + 300))
    if (!/SET\s+search_path\s*(?:TO|=)\s*''/i.test(declaration)) throw new Error(`${file} contiene SECURITY DEFINER sin search_path vacío cerca de ${match.index}`)
  }

  const lastGrant = sql.toUpperCase().lastIndexOf('GRANT CREATE ON SCHEMA PUBLIC TO ASE_TENANT_EXECUTOR')
  if (lastGrant >= 0 && sql.toUpperCase().lastIndexOf('REVOKE CREATE ON SCHEMA PUBLIC FROM ASE_TENANT_EXECUTOR') < lastGrant) throw new Error(`${file} no revoca el permiso temporal de creación`)
}

const defaultPrivileges = fs.readFileSync(path.join(directory, '20261102001000_secure_default_privileges.sql'), 'utf8')
if ((defaultPrivileges.match(/ALTER DEFAULT PRIVILEGES FOR ROLE (?:postgres|ase_tenant_executor) IN SCHEMA (?:public|ase_private)\s+REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC/gi) || []).length !== 4) throw new Error('Los privilegios predeterminados de funciones no cubren propietarios y esquemas operativos')

console.log(JSON.stringify({ passed: true, migrations: files.length, transactions: files.length, privilegedFunctions, publicGrants: 0, productionReferences: 0 }))
