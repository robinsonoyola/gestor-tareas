export function boardViewsStorageKey(userId, organizationId) {
  if (!userId || !organizationId) return null
  return `ase-work-board-views-v2:${userId}:${organizationId}`
}

export const legacyBoardViewsStorageKey = 'ase-work-board-views-v1'
