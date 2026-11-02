import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const read = file => fs.readFileSync(path.join(root, file), 'utf8')

const app = read('src/App.tsx')
const sidebar = read('src/components/layout/Sidebar.jsx')
const sections = read('src/components/layout/SectionNavigation.jsx')

const routes = [...app.matchAll(/\bpath\s*=\s*"([^"]+)"/g)].map(match => match[1])
const menuPaths = [
  ...sidebar.matchAll(/\bpath\s*:\s*'([^']+)'/g),
  ...sections.matchAll(/\[['"][^'"]+['"]\s*,\s*['"]([^'"]+)['"]/g)
].map(match => match[1])

const routePattern = route => new RegExp(`^${route
  .replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  .replace(/\\:([A-Za-z0-9_]+)/g, '[^/]+')}$`)

const missing = [...new Set(menuPaths)]
  .map(value => value.split('?')[0])
  .filter(value => !routes.some(route => route === '*' || routePattern(route).test(value)))

if (missing.length) throw new Error(`El menú contiene rutas que no existen en App.tsx: ${missing.join(', ')}`)

const required = ['/login', '/station', '/admin', '/admin/tasks', '/admin/planning', '/admin/reports', '/employee', '/employee/tasks', '/reset-password', '*']
const absent = required.filter(route => !routes.includes(route))
if (absent.length) throw new Error(`Faltan rutas esenciales de ASE Work: ${absent.join(', ')}`)

const lazyModules = [...app.matchAll(/lazy\(\(\)\s*=>\s*import\("([^"]+)"\)\)/g)].map(match => match[1])
const unresolved = lazyModules.filter(module => {
  const base = path.resolve(root, 'src', module)
  return !['.js', '.jsx', '.ts', '.tsx'].some(extension => fs.existsSync(base + extension))
})
if (unresolved.length) throw new Error(`Hay pantallas diferidas que no existen: ${unresolved.join(', ')}`)

console.log(JSON.stringify({passed:true,routes:routes.length,menuDestinations:new Set(menuPaths).size,lazyScreens:lazyModules.length}))
