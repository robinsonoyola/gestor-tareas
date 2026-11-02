import fs from 'node:fs'
import path from 'node:path'
import { createHash } from 'node:crypto'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const dist = path.join(root, 'dist')
const generated = path.join(root, 'deployment', 'generated')
const operationalPaths = [
  'docs/manuals/ADMINISTRADOR.md',
  'docs/manuals/ENCARGADO.md',
  'docs/manuals/EMPLEADO.md',
  'docs/operations/CONTROL-VERSION-CANDIDATA.md',
  'docs/operations/DESPLIEGUE-Y-RECUPERACION.md',
  'scripts/backup-database.ps1',
  'scripts/restore-database-test.ps1',
  'supabase/tests/verify-installed.sql',
]

function sha256(content) {
  return createHash('sha256').update(content).digest('hex').toUpperCase()
}

function filesBelow(directory, prefix = '') {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const relative = path.posix.join(prefix, entry.name)
    const absolute = path.join(directory, entry.name)
    return entry.isDirectory() ? filesBelow(absolute, relative) : [{ relative, absolute }]
  })
}

if (!fs.existsSync(path.join(dist, 'index.html'))) throw new Error('Compila el frontend antes de crear el manifiesto')

const frontendFiles = filesBelow(dist)
  .sort((a, b) => a.relative.localeCompare(b.relative, 'en'))
  .map(file => {
    const content = fs.readFileSync(file.absolute)
    return { file: file.relative, bytes: content.length, sha256: sha256(content) }
  })

const databaseManifest = fs.readFileSync(path.join(generated, 'manifest.json'))
const functionsManifest = fs.readFileSync(path.join(generated, 'functions', 'manifest.json'))
const operationalFiles = operationalPaths.map(file => {
  const content = fs.readFileSync(path.join(root, ...file.split('/')))
  return { file, bytes: content.length, sha256: sha256(content) }
})
const frontendIdentity = frontendFiles.map(file => `${file.file}\0${file.sha256}`).join('\n')
const manifest = {
  format: 1,
  component: 'ase-work-task-manager-candidate',
  databaseManifestSha256: sha256(databaseManifest),
  functionsManifestSha256: sha256(functionsManifest),
  frontendSha256: sha256(frontendIdentity),
  frontendFiles,
  operationalFiles,
}

fs.writeFileSync(path.join(generated, 'release-manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`)
console.log(JSON.stringify({ ok: true, frontendFiles: frontendFiles.length, frontendSha256: manifest.frontendSha256 }))
