import { supabase } from '@/lib/supabase'

const canonicalPath = /^tasks\/[0-9a-f-]{36}\/[0-9a-f-]{36}\/[0-9a-f-]{36}\.(?:png|jpg|jpeg|gif|webp|mp4|webm|mov)$/
const legacyPath = /^(?:images|videos)\/[0-9a-f-]{36}-[0-9]+\.[a-z0-9]+$/

export function taskAttachmentPath(reference, baseUrl = import.meta.env.VITE_SUPABASE_URL) {
  if (typeof reference !== 'string' || !reference) return null
  if (canonicalPath.test(reference)) return reference
  try {
    const url = new URL(reference)
    const base = new URL(baseUrl)
    const prefix = '/storage/v1/object/public/task-files/'
    if (url.origin !== base.origin || !url.pathname.startsWith(prefix)) return null
    const path = decodeURIComponent(url.pathname.slice(prefix.length))
    return legacyPath.test(path) || canonicalPath.test(path) ? path : null
  } catch {
    return null
  }
}

export async function signedTaskAttachment(reference) {
  const path = taskAttachmentPath(reference)
  if (!path) throw new Error('Referencia de adjunto no reconocida')
  const { data, error } = await supabase.storage.from('task-files').createSignedUrl(path, 900)
  if (error || !data?.signedUrl) throw error || new Error('No se pudo obtener acceso al adjunto')
  return data.signedUrl
}

export function taskAttachmentExtension(file, type) {
  const images = { 'image/png': 'png', 'image/jpeg': 'jpg', 'image/gif': 'gif', 'image/webp': 'webp' }
  const videos = { 'video/mp4': 'mp4', 'video/webm': 'webm', 'video/quicktime': 'mov' }
  const extension = (type === 'image' ? images : type === 'video' ? videos : {})[file?.type]
  if (!extension) throw new Error('Formato no permitido. Usa PNG, JPG, GIF, WebP, MP4, WebM o MOV.')
  const maxSize = (type === 'image' ? 5 : 50) * 1024 * 1024
  if (!Number.isFinite(file.size) || file.size <= 0 || file.size > maxSize) {
    throw new Error(`El archivo debe tener contenido y no superar ${type === 'image' ? 5 : 50} MB.`)
  }
  return extension
}

// UUID v4 remains compatible with the attachment path rules on local HTTP.
export function taskAttachmentId(cryptoApi = globalThis.crypto) {
  if (typeof cryptoApi?.randomUUID === 'function') return cryptoApi.randomUUID()
  if (typeof cryptoApi?.getRandomValues !== 'function') {
    throw new Error('El navegador no permite generar el identificador del archivo. Actualízalo o utiliza la dirección HTTPS de ASE Work.')
  }
  const bytes = new Uint8Array(16)
  cryptoApi.getRandomValues(bytes)
  bytes[6] = (bytes[6] & 0x0f) | 0x40
  bytes[8] = (bytes[8] & 0x3f) | 0x80
  const hex = Array.from(bytes, byte => byte.toString(16).padStart(2, '0')).join('')
  return `${hex.slice(0,8)}-${hex.slice(8,12)}-${hex.slice(12,16)}-${hex.slice(16,20)}-${hex.slice(20)}`
}
