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
const commonRequired = [
  'ALLOWED_ORIGINS', 'allowed.includes(origin)', 'auth.getUser', 'mt_context',
  'x-ase-organization-id', 'request.method !== "POST"', 'persistSession: false',
  'autoRefreshToken: false', 'detectSessionInUrl: false', 'SUPABASE_SERVICE_ROLE_KEY',
]
const functionRequired = {
  'create-employee': ['mt_identity_email_exists', 'getUserById', 'mt_attach_created_employee', 'ase_onboarding_nonce', 'password.length < 8'],
  'update-employee-email': ['mt_prepare_email_change', 'mt_email_change_grant', 'updateUserById', 'mt_finish_email_change'],
}

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
  for (const required of [...commonRequired, ...functionRequired[name]]) {
    if (!bundled.includes(required)) throw new Error(`${name} no contiene el control ${required}`)
  }
  if (/Access-Control-Allow-Origin["']?\s*:\s*["']\*/.test(bundled)) throw new Error(`${name} permite cualquier origen`)
  if (/sb_secret_[A-Za-z0-9_-]{16,}|-----BEGIN [^-]*(?:PRIVATE|OPENSSH) KEY-----/.test(bundled)) throw new Error(`${name} contiene un secreto embebido`)
  const sha256 = createHash('sha256').update(bundled).digest('hex').toUpperCase()
  manifest.functions[name] = { file: `${name}/index.ts`, sha256, verifyJwtAtGateway: false, verifiesJwtInCode: true, securityChecks: commonRequired.length + functionRequired[name].length + 2 }
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
