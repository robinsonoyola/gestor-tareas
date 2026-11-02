import assert from 'node:assert/strict'
import { reauthenticateCurrentUser, validateNewPassword } from '../src/lib/accountSecurity.js'

const calls = []
const client = {
  auth: {
    async signInWithPassword(credentials) {
      calls.push(credentials)
      if (credentials.password === 'incorrecta') return { data: null, error: { code: 'invalid_credentials' } }
      return { data: { user: { id: 'user-1' } }, error: null }
    },
  },
}

const user = await reauthenticateCurrentUser(client, {
  email: ' persona@empresa.com ',
  password: 'correcta',
  expectedUserId: 'user-1',
})
assert.equal(user.id, 'user-1')
assert.deepEqual(calls[0], { email: 'persona@empresa.com', password: 'correcta' })

await assert.rejects(
  () => reauthenticateCurrentUser(client, { email: 'persona@empresa.com', password: 'incorrecta', expectedUserId: 'user-1' }),
  error => error.code === 'reauth_failed' && !error.message.includes('invalid_credentials'),
)
await assert.rejects(
  () => reauthenticateCurrentUser(client, { email: 'persona@empresa.com', password: 'correcta', expectedUserId: 'user-2' }),
  error => error.code === 'reauth_identity_mismatch',
)
await assert.rejects(
  () => reauthenticateCurrentUser(client, { email: 'persona@empresa.com', password: '', expectedUserId: 'user-1' }),
  error => error.code === 'reauth_required',
)

assert.equal(validateNewPassword({ currentPassword: 'anterior1', newPassword: 'nueva-segura-2', confirmation: 'nueva-segura-2' }), true)
assert.throws(() => validateNewPassword({ currentPassword: 'anterior1', newPassword: 'corta', confirmation: 'corta' }), error => error.code === 'password_too_short')
assert.throws(() => validateNewPassword({ currentPassword: 'anterior1', newPassword: 'nueva-segura-2', confirmation: 'otra-segura-3' }), error => error.code === 'password_mismatch')
assert.throws(() => validateNewPassword({ currentPassword: 'misma-segura', newPassword: 'misma-segura', confirmation: 'misma-segura' }), error => error.code === 'password_reused')

console.log(JSON.stringify({ passed: true, checks: 8 }))
