// This is request context, never authorization. PostgreSQL validates every selection.
let identity = null
let organization = null
let epoch = 0
let mode = 'checking'
const requests = new Set()
export const tenantMode = () => mode === 'tenant'
export const setTenantMode = value => { mode = value }
export const currentOrganization = () => organization
export function savedOrganization(userId) {
  try { return sessionStorage.getItem(`ase-organization:${userId}`) || null } catch { return null }
}
export function setOrganizationScope(userId, value) {
  if (identity === userId && organization === value) return
  for (const controller of requests) controller.abort()
  requests.clear()
  epoch++
  identity = userId
  organization = value || null
  if (userId) {
    try {
      const key = `ase-organization:${userId}`
      if (value) sessionStorage.setItem(key,value)
      else sessionStorage.removeItem(key)
    } catch { /* Memory context remains usable if storage is unavailable. */ }
  }
}
export async function organizationFetch(input, init = {}) {
  const url = typeof input === 'string' ? input : input.url
  if (!/\/(rest|storage|functions)\/v1\//.test(url)) return fetch(input,init)
  const started = epoch
  const controller = new AbortController()
  const inherited = init.signal || (typeof input === 'object' ? input.signal : null)
  const abort = () => controller.abort()
  if (inherited?.aborted) abort()
  inherited?.addEventListener('abort',abort,{once:true})
  const headers = new Headers(init.headers || (typeof input === 'object' ? input.headers : undefined))
  headers.delete('x-ase-organization-id')
  if (organization) headers.set('x-ase-organization-id',organization)
  requests.add(controller)
  try {
    const response = await fetch(input,{...init,headers,signal:controller.signal})
    if (started !== epoch) throw new DOMException('Organization changed','AbortError')
    return response
  } finally {
    requests.delete(controller)
    inherited?.removeEventListener('abort',abort)
  }
}
