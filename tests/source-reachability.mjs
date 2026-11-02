import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const sourceRoot = path.join(root, 'src')
const extensions = ['.js', '.jsx', '.ts', '.tsx']

function sourceFiles(directory) {
  return fs.readdirSync(directory, {withFileTypes:true}).flatMap(entry => {
    const file = path.join(directory, entry.name)
    if (entry.isDirectory()) return sourceFiles(file)
    return extensions.includes(path.extname(entry.name)) && !entry.name.endsWith('.d.ts') ? [file] : []
  })
}

function resolveModule(from, request) {
  if (!request.startsWith('.') && !request.startsWith('@/')) return null
  const base = request.startsWith('@/')
    ? path.join(sourceRoot, request.slice(2))
    : path.resolve(path.dirname(from), request)
  const candidates = [base, ...extensions.map(extension => base + extension), ...extensions.map(extension => path.join(base, 'index' + extension))]
  return candidates.find(candidate => fs.existsSync(candidate) && fs.statSync(candidate).isFile()) || null
}

function dependencies(file) {
  const text = fs.readFileSync(file, 'utf8')
  const requests = [
    ...text.matchAll(/(?:import|export)\s+(?:[^'";]+?\s+from\s+)?['"]([^'"]+)['"]/g),
    ...text.matchAll(/import\(\s*['"]([^'"]+)['"]\s*\)/g)
  ].map(match => match[1])
  return requests.map(request => resolveModule(file, request)).filter(Boolean)
}

const reachable = new Set()
const pending = [path.join(sourceRoot, 'main.tsx')]
while (pending.length) {
  const file = pending.pop()
  if (reachable.has(file)) continue
  reachable.add(file)
  for (const dependency of dependencies(file)) if (!reachable.has(dependency)) pending.push(dependency)
}

const unreachable = sourceFiles(sourceRoot).filter(file => !reachable.has(file)).map(file => path.relative(root, file).replaceAll('\\','/')).sort()
if (unreachable.length) {
  console.error(JSON.stringify({passed:false,reachable:reachable.size,unreachable}, null, 2))
  process.exit(1)
}

console.log(JSON.stringify({passed:true,reachable:reachable.size,unreachable:0}))
