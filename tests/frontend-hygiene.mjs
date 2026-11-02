import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')

function sourceFiles(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const file = path.join(directory, entry.name)
    return entry.isDirectory() ? sourceFiles(file) : /\.(js|jsx|ts|tsx)$/.test(entry.name) ? [file] : []
  })
}

const debug = sourceFiles(path.join(root, 'src')).filter(file => /console\.(log|debug|info)\s*\(/.test(fs.readFileSync(file, 'utf8')))
if (debug.length) throw new Error(`Quedan registros de depuración: ${debug.map(file => path.relative(root, file)).join(', ')}`)
if (fs.existsSync(path.join(root, 'public', 'vite.svg')) || fs.existsSync(path.join(root, 'src', 'assets', 'react.svg'))) throw new Error('Quedan recursos de plantilla sin usar')

const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8')
for (const marker of ['name="description"', 'name="theme-color"', '/ase-icon.svg']) {
  if (!html.includes(marker)) throw new Error(`El documento inicial no incluye ${marker}`)
}
if (html.includes('<link href="/src/index.css"')) throw new Error('El CSS se estaba cargando dos veces')

const vite = fs.readFileSync(path.join(root, 'vite.config.ts'), 'utf8')
if (!vite.includes("drop: ['console', 'debugger']")) throw new Error('La compilación comercial conserva registros de consola')

console.log(JSON.stringify({ passed: true, debugLogs: 0, productionConsole: false, unusedTemplateAssets: 0, metadata: true }))
