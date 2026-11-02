import fs from 'node:fs'

const project = JSON.parse(fs.readFileSync(new URL('../package.json', import.meta.url), 'utf8'))
const lock = JSON.parse(fs.readFileSync(new URL('../package-lock.json', import.meta.url), 'utf8'))
const root = lock.packages?.['']
if (lock.lockfileVersion !== 3 || !root) throw new Error('El bloqueo de npm no usa el formato reproducible esperado')

for (const group of ['dependencies', 'devDependencies', 'optionalDependencies']) {
  const expected = project[group] || {}
  const locked = root[group] || {}
  const names = new Set([...Object.keys(expected), ...Object.keys(locked)])
  const different = [...names].filter(name => expected[name] !== locked[name])
  if (different.length) throw new Error(`${group} no coincide con package-lock.json: ${different.join(', ')}`)
}
if (JSON.stringify(root.engines || {}) !== JSON.stringify(project.engines || {})) throw new Error('El requisito de Node no coincide en el bloqueo')

const packages = Object.entries(lock.packages).filter(([location]) => location)
const unsafeSources = packages.filter(([, entry]) => entry.resolved && !entry.resolved.startsWith('https://registry.npmjs.org/'))
if (unsafeSources.length) throw new Error(`Hay dependencias fuera del registro npm por HTTPS: ${unsafeSources.map(([location]) => location).join(', ')}`)
const missingIntegrity = packages.filter(([, entry]) => entry.resolved && !entry.integrity)
if (missingIntegrity.length) throw new Error(`Hay dependencias sin huella de integridad: ${missingIntegrity.map(([location]) => location).join(', ')}`)

console.log(JSON.stringify({ passed: true, lockfileVersion: lock.lockfileVersion, packages: packages.length, registry: 'https://registry.npmjs.org/', integrity: true }))
