export function boardViewsStorageKey(userId, organizationId) {
  if (!userId || !organizationId) return null
  return `ase-work-board-views-v2:${userId}:${organizationId}`
}
