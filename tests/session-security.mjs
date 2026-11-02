import assert from 'node:assert/strict'
import { signOutCurrentBrowser } from '../src/lib/sessionSecurity.js'

const calls = []
assert.equal(await signOutCurrentBrowser({ auth: { async signOut(options) { calls.push(options); return { error: null } } } }), true)
assert.deepEqual(calls, [{ scope: 'local' }])
await assert.rejects(
  () => signOutCurrentBrowser({ auth: { async signOut() { return { error: { message: 'technical provider detail' } } } } }),
  error => error.code === 'signout_failed' && !error.message.includes('technical provider detail'),
)
await assert.rejects(
  () => signOutCurrentBrowser(null),
  error => error.code === 'signout_unavailable',
)

console.log(JSON.stringify({ passed: true, checks: 4 }))
