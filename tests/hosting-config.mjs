import fs from 'node:fs'

const netlify = fs.readFileSync(new URL('../netlify.toml', import.meta.url), 'utf8')
const headers = fs.readFileSync(new URL('../public/_headers', import.meta.url), 'utf8')
const redirects = fs.readFileSync(new URL('../public/_redirects', import.meta.url), 'utf8')

for (const [name, content] of [['netlify.toml', netlify], ['_headers', headers]]) {
  for (const marker of ['no-cache, no-store, must-revalidate', 'public, max-age=31536000, immutable', 'X-Content-Type-Options', 'X-Frame-Options', 'Referrer-Policy', 'Permissions-Policy', 'camera=(self)', 'geolocation=(self)', 'microphone=()', 'nfc=(self)', 'payment=()', 'usb=()', 'X-Permitted-Cross-Domain-Policies', 'Content-Security-Policy', "script-src 'self'", "connect-src 'self' https://*.supabase.co wss://*.supabase.co", "frame-ancestors 'none'", "base-uri 'self'", 'Strict-Transport-Security']) {
    if (!content.includes(marker)) throw new Error(`${name} no incluye ${marker}`)
  }
}
if (!redirects.includes('/*') || !redirects.includes('/index.html') || !netlify.includes('status = 200')) throw new Error('Falta la recuperación de rutas SPA')

console.log(JSON.stringify({ passed: true, spaFallback: true, freshHtml: true, immutableAssets: true, securityHeaders: true, contentSecurityPolicy: true, permissionsPolicy: true, httpsOnly: true }))
