import fs from 'node:fs'
import path from 'node:path'
import { createHash } from 'node:crypto'
import { fileURLToPath } from 'node:url'
import { build } from 'esbuild'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const output = path.join(root, 'deployment', 'generated', 'functions')
const checkOnly = process.argv.includes('--check')
const names = ['create-employee', 'update-employee-email']
const manifest = { format: 1, functions: {} }

for (const name of names) {
  const entry = path.join(root, 'supabase', 'functions', name, 'index.ts')
  if (!fs.existsSync(entry)) throw new Error(`Falta la función ${name}`)
  const result = await build({
    entryPoints: [entry],
    bundle: true,
    platform: 'neutral',
    format: 'esm',
    target: 'es2022',
    external: ['npm:*'],
    write: false,
    logLevel: 'silent'
  })
  const bundled = result.outputFiles[0].text
  for (const required of ['ALLOWED_ORIGINS', 'auth.getUser', 'mt_context', 'x-ase-organization-id']) {
    if (!bundled.includes(required)) throw new Error(`${name} no contiene el control ${required}`)
  }
  const sha256 = createHash('sha256').update(bundled).digest('hex').toUpperCase()
  manifest.functions[name] = { file: `${name}/index.ts`, sha256, verifyJwtAtGateway: false, verifiesJwtInCode: true }
  if (!checkOnly) {
    const dir = path.join(output, name)
    fs.mkdirSync(dir, { recursive: true })
    fs.writeFileSync(path.join(dir, 'index.ts'), bundled)
  }
}

if (!checkOnly) {
  fs.mkdirSync(output, { recursive: true })
  fs.writeFileSync(path.join(output, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`)
}
console.log(JSON.stringify({ ok: true, checkOnly, ...manifest }))
