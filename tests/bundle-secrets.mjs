import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const files = []
const walk = directory => {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name)
    if (entry.isDirectory()) walk(file)
    else files.push(file)
  }
}
walk(path.join(root, 'dist'))
const content = files.map(file => fs.readFileSync(file, 'utf8')).join('\n')

const forbidden = [
  [/-----BEGIN [^-]*(?:PRIVATE|OPENSSH) KEY-----/i, 'clave privada'],
  [/postgres(?:ql)?:\/\/[^\s"']+/i, 'URL directa de base de datos'],
  [/sb_secret_[A-Za-z0-9_-]{16,}/, 'clave secreta de Supabase'],
  [/SUPABASE_SERVICE_ROLE_KEY\s*[:=]\s*["'][^"']+/i, 'variable service_role'],
]
for (const [pattern, label] of forbidden) {
  if (pattern.test(content)) throw new Error(`La compilación contiene ${label}`)
}

const tokens = content.match(/eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/g) || []
for (const token of tokens) {
  try {
    const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString('utf8'))
    if (payload.role === 'service_role' || payload.role === 'supabase_admin') throw new Error('La compilación contiene un JWT administrativo')
  } catch (error) {
    if (error.message.includes('JWT administrativo')) throw error
  }
}

console.log(JSON.stringify({ passed: true, files: files.length, privateKeys: 0, databaseUrls: 0, secretKeys: 0, administrativeTokens: 0 }))
