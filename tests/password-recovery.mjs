import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { normalizeRecoveryEmail, recoveryCredentials, validateRecoveryPassword } from '../src/lib/passwordRecoveryValidation.js'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')

assert.equal(normalizeRecoveryEmail(' Persona@Empresa.COM '), 'persona@empresa.com')
assert.throws(() => normalizeRecoveryEmail('correo-invalido'), /email válido/)
assert.deepEqual(
  recoveryCredentials('https://work.example/reset-password?type=recovery&token_hash=hash-seguro'),
  { tokenHash: 'hash-seguro' },
)
assert.deepEqual(
  recoveryCredentials('https://work.example/reset-password#type=recovery&access_token=acceso&refresh_token=renovacion'),
  { accessToken: 'acceso', refreshToken: 'renovacion' },
)
assert.throws(() => recoveryCredentials('https://work.example/reset-password?error=access_denied&type=recovery&token_hash=ignorado'), /no es válido/)
assert.throws(() => recoveryCredentials('https://work.example/reset-password?type=invite&token_hash=incorrecto'), /enlace completo/)
assert.equal(validateRecoveryPassword('nueva-segura', 'nueva-segura'), true)
assert.throws(() => validateRecoveryPassword('corta', 'corta'), /8 caracteres/)
assert.throws(() => validateRecoveryPassword('nueva-segura', 'distinta-segura'), /no coinciden/)
const recoveryScreen = fs.readFileSync(path.join(root, 'src/pages/ResetPassword.jsx'), 'utf8')
assert.ok(recoveryScreen.includes("setError('No se pudo actualizar la contraseña. Solicita otro enlace si este ha expirado.')"))
assert.ok(!recoveryScreen.includes("setError(failure.message || 'No se pudo actualizar la contraseña"))

console.log(JSON.stringify({ passed: true, checks: 11 }))
