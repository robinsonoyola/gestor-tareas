function jwtRole(value) {
  try {
    const payload = value.split('.')[1]
    if (!payload) return null
    const normalized = payload.replace(/-/g, '+').replace(/_/g, '/')
    const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=')
    return JSON.parse(atob(padded)).role || null
  } catch {
    return null
  }
}

export function validateRuntimeConfig(env = import.meta.env) {
  const url = String(env?.VITE_SUPABASE_URL || '').trim()
  const key = String(env?.VITE_SUPABASE_ANON_KEY || '').trim()
  const problems = []

  try {
    const parsed = new URL(url)
    if (!['https:', 'http:'].includes(parsed.protocol)) problems.push('La URL de Supabase no utiliza HTTP o HTTPS.')
  } catch {
    problems.push('Falta una URL válida de Supabase.')
  }

  if (!key || key.includes('YOUR_PUBLIC_ANON_KEY')) problems.push('Falta la clave pública de Supabase.')
  if (key.startsWith('sb_secret_') || jwtRole(key) === 'service_role') problems.push('Se ha configurado una clave privada de servidor en el frontend.')

  return { ok: problems.length === 0, problems }
}
