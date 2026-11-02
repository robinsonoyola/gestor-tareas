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
