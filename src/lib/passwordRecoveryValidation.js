export function normalizeRecoveryEmail(email) {
  const normalized = String(email || '').trim().toLowerCase()
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized) || normalized.length > 254) {
    throw new Error('Introduce un email válido.')
  }
  return normalized
}

export function recoveryCredentials(href) {
  const url = new URL(href)
  const hash = new URLSearchParams(url.hash.slice(1))
  if (url.searchParams.has('error') || hash.has('error') || hash.has('error_code')) {
    throw new Error('El enlace no es válido o ha expirado. Solicita uno nuevo.')
  }
  if (url.searchParams.get('type') === 'recovery' && url.searchParams.get('token_hash')) {
    return { tokenHash: url.searchParams.get('token_hash') }
  }
  if (hash.get('type') === 'recovery' && hash.get('access_token') && hash.get('refresh_token')) {
    return { accessToken: hash.get('access_token'), refreshToken: hash.get('refresh_token') }
  }
  throw new Error('Abre el enlace completo del correo de recuperación. Esta página por sí sola no permite cambiar la contraseña.')
}

export function validateRecoveryPassword(password, confirmation) {
  if (password.length < 8) throw new Error('Usa una contraseña de al menos 8 caracteres.')
  if (password !== confirmation) throw new Error('Las contraseñas no coinciden.')
  return true
}
