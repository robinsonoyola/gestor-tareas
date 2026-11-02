import assert from 'node:assert/strict'
import { reauthenticateCurrentUser } from '../src/lib/accountSecurity.js'

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

console.log(JSON.stringify({ passed: true, checks: 4 }))
