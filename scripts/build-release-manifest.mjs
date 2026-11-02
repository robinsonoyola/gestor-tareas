import fs from 'node:fs'
import path from 'node:path'
import { createHash } from 'node:crypto'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const dist = path.join(root, 'dist')
const generated = path.join(root, 'deployment', 'generated')
const packageMetadata = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'))
const packageLock = JSON.parse(fs.readFileSync(path.join(root, 'package-lock.json'), 'utf8'))
const operationalPaths = [
  'docs/manuals/ADMINISTRADOR.md',
  'docs/manuals/ENCARGADO.md',
  'docs/manuals/EMPLEADO.md',
  'docs/operations/CONTROL-VERSION-CANDIDATA.md',
  'docs/operations/DESPLIEGUE-Y-RECUPERACION.md',
  'docs/operations/NOTAS-VERSION-1.0.0-RC.1.md',
  'docs/operations/VALIDACION-LOCAL-2026-11-02.md',
  'scripts/backup-database.ps1',
  'scripts/restore-database-test.ps1',
  'supabase/tests/verify-installed.sql',
]
const buildInputPaths = ['package.json', 'package-lock.json', 'vite.config.ts', 'netlify.toml']

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
if (!packageMetadata.version || packageMetadata.version !== packageLock.version || packageMetadata.version !== packageLock.packages?.['']?.version) {
  throw new Error('La versión del proyecto y su bloqueo de dependencias no coinciden')
}

const frontendFiles = filesBelow(dist)
  .sort((a, b) => a.relative.localeCompare(b.relative, 'en'))
  .map(file => {
    const content = fs.readFileSync(file.absolute)
    return { file: file.relative, bytes: content.length, sha256: sha256(content) }
  })

const databaseManifest = fs.readFileSync(path.join(generated, 'manifest.json'))
const functionsManifest = fs.readFileSync(path.join(generated, 'functions', 'manifest.json'))
const dependencyInventory = fs.readFileSync(path.join(generated, 'dependency-inventory.json'))
const operationalFiles = operationalPaths.map(file => {
  const content = fs.readFileSync(path.join(root, ...file.split('/')))
  return { file, bytes: content.length, sha256: sha256(content) }
})
const buildInputs = buildInputPaths.map(file => {
  const content = fs.readFileSync(path.join(root, file))
  return { file, bytes: content.length, sha256: sha256(content) }
})
const frontendIdentity = frontendFiles.map(file => `${file.file}\0${file.sha256}`).join('\n')
const manifest = {
  format: 1,
  component: 'ase-work-task-manager-candidate',
  version: packageMetadata.version,
  databaseManifestSha256: sha256(databaseManifest),
  functionsManifestSha256: sha256(functionsManifest),
  dependencyInventorySha256: sha256(dependencyInventory),
  frontendSha256: sha256(frontendIdentity),
  frontendFiles,
  operationalFiles,
  build: { node: process.versions.node, inputs: buildInputs },
}

fs.writeFileSync(path.join(generated, 'release-manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`)
console.log(JSON.stringify({ ok: true, version: manifest.version, frontendFiles: frontendFiles.length, frontendSha256: manifest.frontendSha256 }))
