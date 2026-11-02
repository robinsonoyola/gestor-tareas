function accountError(message, code) {
  return Object.assign(new Error(message), { code })
}

export async function reauthenticateCurrentUser(client, { email, password, expectedUserId }) {
  if (!client?.auth?.signInWithPassword) throw accountError('No se pudo comprobar la identidad.', 'reauth_unavailable')
  if (!email?.trim() || !password) throw accountError('Introduce tu contraseña actual.', 'reauth_required')

  const { data, error } = await client.auth.signInWithPassword({ email: email.trim(), password })
  if (error || !data?.user) throw accountError('La contraseña actual no es correcta.', 'reauth_failed')
  if (expectedUserId && data.user.id !== expectedUserId) {
    throw accountError('La sesión no corresponde a esta cuenta.', 'reauth_identity_mismatch')
  }

  return data.user
}

export function validateNewPassword({ currentPassword, newPassword, confirmation }) {
  if (!newPassword || newPassword.length < 8) throw accountError('La contraseña nueva debe tener al menos 8 caracteres.', 'password_too_short')
  if (newPassword !== confirmation) throw accountError('Las contraseñas nuevas no coinciden.', 'password_mismatch')
  if (currentPassword === newPassword) throw accountError('La contraseña nueva debe ser diferente de la actual.', 'password_reused')
  return true
}
