import fs from 'node:fs'

const inventory = JSON.parse(fs.readFileSync(new URL('../deployment/generated/dependency-inventory.json', import.meta.url), 'utf8'))
const allowedLicenses = new Set(['0BSD', 'Apache-2.0', 'BSD-2-Clause', 'BSD-3-Clause', 'ISC', 'MIT'])
if (inventory.format !== 1 || inventory.component !== 'ase-work-task-manager-candidate' || inventory.scope !== 'production') throw new Error('Inventario de dependencias no reconocido')
if (!Array.isArray(inventory.components) || inventory.components.length < 50) throw new Error('El inventario de producción está incompleto')
if (!inventory.components.some(item => item.direct && item.name === 'react') || !inventory.components.some(item => item.direct && item.name === '@supabase/supabase-js')) throw new Error('Faltan dependencias directas esenciales')
if (inventory.components.some(item => !item.name || !item.version || !item.license || !('integrity' in item))) throw new Error('Hay componentes sin identificación suficiente')
if (inventory.components.some(item => ['vite', 'eslint', 'typescript'].includes(item.name))) throw new Error('El inventario de producción contiene herramientas de desarrollo')
const unapproved = inventory.components.filter(item => !allowedLicenses.has(item.license))
if (unapproved.length) throw new Error(`Hay licencias sin aprobación comercial: ${unapproved.map(item => `${item.name} (${item.license})`).join(', ')}`)
const summaryCount = Object.values(inventory.licenses || {}).reduce((total, count) => total + count, 0)
if (summaryCount !== inventory.components.length) throw new Error('El resumen de licencias no coincide con el inventario')

console.log(JSON.stringify({ passed: true, productionComponents: inventory.components.length, direct: inventory.components.filter(item => item.direct).length, licenses: inventory.licenses }))
