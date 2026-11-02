import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const lock = JSON.parse(fs.readFileSync(path.join(root, 'package-lock.json'), 'utf8'))
const direct = new Set(Object.keys(lock.packages?.['']?.dependencies || {}))
const components = Object.entries(lock.packages || {})
  .filter(([location, entry]) => location.includes('node_modules/') && entry.version && entry.dev !== true)
  .map(([location, entry]) => {
    const marker = 'node_modules/'
    const name = location.slice(location.lastIndexOf(marker) + marker.length)
    return {
      name,
      version: entry.version,
      direct: direct.has(name),
      optional: entry.optional === true,
      license: entry.license || 'UNKNOWN',
      integrity: entry.integrity || null,
    }
  })
  .sort((left, right) => left.name.localeCompare(right.name, 'en') || left.version.localeCompare(right.version, 'en'))
const licenses = Object.fromEntries([...new Set(components.map(item => item.license))]
  .sort((left, right) => left.localeCompare(right, 'en'))
  .map(license => [license, components.filter(item => item.license === license).length]))

const inventory = {
  format: 1,
  component: 'ase-work-task-manager-candidate',
  scope: 'production',
  lockfileVersion: lock.lockfileVersion,
  licenses,
  components,
}
const output = path.join(root, 'deployment', 'generated', 'dependency-inventory.json')
fs.writeFileSync(output, `${JSON.stringify(inventory, null, 2)}\n`)
console.log(JSON.stringify({ ok: true, productionComponents: components.length, direct: components.filter(item => item.direct).length }))
