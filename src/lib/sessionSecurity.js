export async function signOutCurrentBrowser(client) {
  if (!client?.auth?.signOut) throw Object.assign(new Error('No se pudo cerrar la sesión.'), { code: 'signout_unavailable' })
  const { error } = await client.auth.signOut({ scope: 'local' })
  if (error) throw Object.assign(new Error('No se pudo cerrar la sesión. Comprueba la conexión y vuelve a intentarlo.'), { code: 'signout_failed' })
  return true
}
