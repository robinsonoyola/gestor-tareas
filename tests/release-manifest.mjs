import fs from 'node:fs'
import path from 'node:path'
import { createHash } from 'node:crypto'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'deployment', 'generated', 'release-manifest.json'), 'utf8'))
const sha256 = content => createHash('sha256').update(content).digest('hex').toUpperCase()
const executableText = source => {
  let result = '', quote = '', escaped = false
  for (const character of source) {
    if (quote) {
      if (escaped) escaped = false
      else if (character === '\\') escaped = true
      else if (character === quote) quote = ''
      result += ' '
    } else if (character === '"' || character === "'" || character === '`') {
      quote = character
      result += ' '
    } else result += character
  }
  return result
}

if (manifest.format !== 1 || manifest.component !== 'ase-work-task-manager-candidate') throw new Error('Manifiesto de entrega no reconocido')
if (!manifest.frontendFiles.some(item => item.file === 'index.html')) throw new Error('Falta index.html en la entrega')
if (!manifest.frontendFiles.some(item => item.file.endsWith('.js')) || !manifest.frontendFiles.some(item => item.file.endsWith('.css'))) throw new Error('Faltan recursos compilados')
if (!Array.isArray(manifest.operationalFiles) || manifest.operationalFiles.length < 8) throw new Error('Faltan manuales o utilidades operativas en el manifiesto')
if (!manifest.build?.node || !Array.isArray(manifest.build.inputs) || manifest.build.inputs.length < 4) throw new Error('Falta identificar el entorno o los archivos de compilación')

for (const item of manifest.frontendFiles) {
  const file = path.join(root, 'dist', ...item.file.split('/'))
  const content = fs.readFileSync(file)
  if (content.length !== item.bytes || sha256(content) !== item.sha256) throw new Error(`El recurso no coincide: ${item.file}`)
  if (item.file.endsWith('.js') && /\bconsole\.(log|debug|info|warn|error)\s*\(/.test(executableText(content.toString('utf8')))) throw new Error(`El recurso publicado conserva registros de consola: ${item.file}`)
}

for (const item of manifest.operationalFiles) {
  const file = path.join(root, ...item.file.split('/'))
  const content = fs.readFileSync(file)
  if (content.length !== item.bytes || sha256(content) !== item.sha256) throw new Error(`El archivo operativo no coincide: ${item.file}`)
}

for (const item of manifest.build.inputs) {
  const file = path.join(root, item.file)
  const content = fs.readFileSync(file)
  if (content.length !== item.bytes || sha256(content) !== item.sha256) throw new Error(`La entrada de compilación no coincide: ${item.file}`)
}

const database = fs.readFileSync(path.join(root, 'deployment', 'generated', 'manifest.json'))
const functions = fs.readFileSync(path.join(root, 'deployment', 'generated', 'functions', 'manifest.json'))
if (sha256(database) !== manifest.databaseManifestSha256) throw new Error('El paquete de base no coincide')
if (sha256(functions) !== manifest.functionsManifestSha256) throw new Error('El paquete de funciones no coincide')

const identity = manifest.frontendFiles.map(item => `${item.file}\0${item.sha256}`).join('\n')
if (sha256(identity) !== manifest.frontendSha256) throw new Error('La identidad del frontend no coincide')

console.log(JSON.stringify({ passed: true, frontendFiles: manifest.frontendFiles.length, operationalFiles: manifest.operationalFiles.length, buildInputs: manifest.build.inputs.length, node: manifest.build.node, frontendSha256: manifest.frontendSha256 }))
