import assert from 'node:assert/strict'
import { validateRuntimeConfig } from '../src/config/runtime.js'

const valid = validateRuntimeConfig({ VITE_SUPABASE_URL: 'https://example.supabase.co', VITE_SUPABASE_ANON_KEY: 'sb_publishable_example_public_key' })
assert.equal(valid.ok, true)

for (const env of [
  {},
  { VITE_SUPABASE_URL: 'not-a-url', VITE_SUPABASE_ANON_KEY: 'public-key' },
  { VITE_SUPABASE_URL: 'https://example.supabase.co', VITE_SUPABASE_ANON_KEY: 'YOUR_PUBLIC_ANON_KEY' },
  { VITE_SUPABASE_URL: 'https://example.supabase.co', VITE_SUPABASE_ANON_KEY: 'sb_secret_never_in_browser' }
]) {
  assert.equal(validateRuntimeConfig(env).ok, false)
}

console.log(JSON.stringify({ passed: true, missingConfig: true, invalidUrl: true, placeholderKey: true, secretKey: true }))
