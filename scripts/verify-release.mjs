import { spawnSync } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')

function run(label, command, args) {
  console.log(`\n[ASE Work] ${label}`)
  const result = spawnSync(command, args, { cwd: root, stdio: 'inherit', shell: false })
  if (result.error) throw result.error
  if (result.status !== 0) throw new Error(`${label} terminó con código ${result.status}`)
}

function trackedFiles() {
  const result = spawnSync('git', ['ls-files', '-z'], { cwd: root, encoding: 'utf8', shell: false })
  if (result.status !== 0) throw new Error('No se pudo revisar el inventario Git')
  return result.stdout.split('\0').filter(Boolean)
}

const forbiddenTracked = trackedFiles().filter(file =>
  /(^|\/)(\.env($|\.)|.*\.(dump|backup|p12|pfx|key))$/i.test(file) && file !== '.env.example'
)
if (forbiddenTracked.length) throw new Error(`Hay secretos o copias rastreados por Git: ${forbiddenTracked.join(', ')}`)

const required = [
  'deployment/generated/instalacion-nueva-plantilla.sql',
  'deployment/generated/activar-automatizaciones.sql',
  'deployment/generated/verificar-instalacion.sql',
  'deployment/generated/comprobar-salud.sql',
  'deployment/generated/functions/manifest.json',
  'deployment/generated/dependency-inventory.json',
  'docs/manuals/ADMINISTRADOR.md',
  'docs/manuals/ENCARGADO.md',
  'docs/manuals/EMPLEADO.md',
  'docs/architecture/README.md',
  'docs/operations/DESPLIEGUE-Y-RECUPERACION.md',
  'supabase/tests/verify-installed.sql'
]
const missing = required.filter(file => !fs.existsSync(path.join(root, file)))
if (missing.length) throw new Error(`Faltan entregables de la versión: ${missing.join(', ')}`)

const hostedVerification = fs.readFileSync(path.join(root, 'supabase/tests/verify-installed.sql'), 'utf8')
for (const marker of ['work_task_archive_events', 'work_planning_assignments(uuid)', 'automatizaciones_activas', 'empresas_sin_propietario', 'esquema_privado_seguro', 'superficie_anonima_segura', 'superficie_servicio_segura', 'TRANSACTION READ ONLY']) {
  if (!hostedVerification.includes(marker)) throw new Error(`La verificación alojada no incluye ${marker}`)
}

run('Seguridad multiempresa sintética', process.execPath, ['supabase/tests/security.mjs'])
run('Higiene de migraciones SQL', process.execPath, ['tests/migration-hygiene.mjs'])
run('Generación del paquete de base de datos', process.execPath, ['scripts/build-database-package.mjs'])
run('Paquete e instalación de base de datos', process.execPath, ['supabase/tests/database-package.mjs'])
run('Funciones administrativas', process.execPath, ['scripts/build-edge-package.mjs'])
run('Copias y restauración', process.execPath, ['tests/operations-package.mjs'])
run('Recuperación de pantallas', process.execPath, ['tests/route-recovery.mjs'])
run('Integridad de navegación', process.execPath, ['tests/navigation-integrity.mjs'])
run('Hosting y caché', process.execPath, ['tests/hosting-config.mjs'])
run('Configuración pública del frontend', process.execPath, ['tests/runtime-config.mjs'])
run('Línea base de dependencias', process.execPath, ['tests/dependency-baseline.mjs'])
run('Integridad del bloqueo de dependencias', process.execPath, ['tests/lockfile-integrity.mjs'])
run('Inventario de dependencias de producción', process.execPath, ['scripts/build-dependency-inventory.mjs'])
run('Integridad del inventario de dependencias', process.execPath, ['tests/dependency-inventory.mjs'])
run('Higiene del frontend', process.execPath, ['tests/frontend-hygiene.mjs'])
run('Alcance del código fuente', process.execPath, ['tests/source-reachability.mjs'])
run('Análisis estático del código', process.execPath, ['node_modules/eslint/bin/eslint.js', '.'])
run('Accesibilidad y uso táctil', process.execPath, ['tests/accessibility-baseline.mjs'])
run('Exportaciones e informes', process.execPath, ['tests/report-export.mjs'])
run('Compilación del frontend', process.execPath, ['node_modules/vite/bin/vite.js', 'build'])
run('Ausencia de secretos en la compilación', process.execPath, ['tests/bundle-secrets.mjs'])
run('Presupuesto de carga móvil', process.execPath, ['tests/frontend-budget.mjs'])
run('Manifiesto de la entrega', process.execPath, ['scripts/build-release-manifest.mjs'])
run('Integridad de la entrega', process.execPath, ['tests/release-manifest.mjs'])

console.log('\nASE WORK: VERSIÓN CANDIDATA APTA EN COMPROBACIONES AUTOMÁTICAS')
console.log('Pendientes manuales deliberados: dos empresas alojadas, correo real, dispositivos/NFC y restauración real en un proyecto vacío.')
