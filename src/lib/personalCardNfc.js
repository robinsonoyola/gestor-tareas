export function personalCodeFromNdef(message) {
  const codes = new Set()
  for (const record of message?.records || []) {
    if (record.recordType !== 'text') continue
    try {
      const code = new TextDecoder(record.encoding || 'utf-8', {fatal:true}).decode(record.data).trim()
      if (/^ASE-[A-Za-z0-9_-]{8,250}$/.test(code)) codes.add(code)
    } catch { /* Ignore unreadable records, never execute tag content. */ }
  }
  if (codes.size !== 1) throw new Error('La tarjeta debe contener un único código personal ASE- como registro de texto NDEF.')
  return [...codes][0]
}

export async function startPersonalCardReader({onCode,onError,signal}, platform = globalThis) {
  if (!platform.isSecureContext) throw new Error('La lectura NFC necesita abrir este punto mediante HTTPS.')
  if (!platform.NDEFReader) throw new Error('Este navegador no ofrece lectura NFC. Usa Chrome en Android con NFC activado.')
  const reader = new platform.NDEFReader()
  reader.onreading = event => {
    if (signal.aborted) return
    try { onCode(personalCodeFromNdef(event.message)) } catch(error) { onError(error.message) }
  }
  reader.onreadingerror = () => { if (!signal.aborted) onError('No se pudo leer la tarjeta. Acércala de nuevo y comprueba que contiene texto NDEF.') }
  signal.addEventListener('abort',()=>{reader.onreading=null;reader.onreadingerror=null},{once:true})
  await reader.scan({signal})
  return reader
}
