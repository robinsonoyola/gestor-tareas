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

const retiredFrontend = [
  'src/App.js',
  'src/pages/QRGenerator.jsx',
  'src/pages/admin/QRGenerator.jsx',
  'src/pages/employee/TaskDetailPage.jsx',
  'src/components/auth/LoginForm.jsx',
  'src/components/layout/Header.jsx',
  'src/components/admin/TaskForm.jsx',
  'src/components/admin/TaskCheckinMethodsConfig.tsx',
  'src/components/ui/accordion.tsx',
  'src/components/ui/calendar.tsx',
  'src/components/ui/popover.tsx',
  'src/components/ui/separator.tsx',
  'src/components/ui/tabs.tsx'
]
const restoredLegacy = retiredFrontend.filter(file => fs.existsSync(path.join(root, file)))
if (restoredLegacy.length) throw new Error(`Se restauraron pantallas antiguas que ya no forman parte de ASE Work: ${restoredLegacy.join(', ')}`)

const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8')
for (const marker of ['name="description"', 'name="theme-color"', 'name="mobile-web-app-capable"', 'name="apple-mobile-web-app-capable"', 'name="apple-mobile-web-app-title"', '/ase-icon.svg']) {
  if (!html.includes(marker)) throw new Error(`El documento inicial no incluye ${marker}`)
}
if (html.includes('<link href="/src/index.css"')) throw new Error('El CSS se estaba cargando dos veces')

const vite = fs.readFileSync(path.join(root, 'vite.config.ts'), 'utf8')
if (!vite.includes('drop_console: true') || !vite.includes('drop_debugger: true')) throw new Error('La compilación comercial conserva registros de consola o debugger')
if (!vite.includes("target: 'baseline-widely-available'")) throw new Error('La compatibilidad mínima de navegadores no está fijada')

console.log(JSON.stringify({ passed: true, debugLogs: 0, productionConsole: false, unusedTemplateAssets: 0, retiredFrontend: retiredFrontend.length, metadata: true }))
