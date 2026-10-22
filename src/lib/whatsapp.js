// Syntactic phone validation only; it does not confirm a WhatsApp account exists.
export function normalizeWhatsApp(value) {
  const input = String(value ?? '').trim()
  if (!input) return null
  const invalid = message => {
    const error = new Error(message)
    error.code = 'INVALID_WHATSAPP'
    throw error
  }
  if (!/^\+?[0-9\s()-]+$/.test(input)) {
    invalid('WhatsApp solo admite números, un + inicial, espacios, guiones y paréntesis.')
  }
  let parentheses = 0
  for (const char of input) {
    if (char === '(') parentheses++
    if (char === ')') parentheses--
    if (parentheses < 0 || parentheses > 1) invalid('Revisa los paréntesis del número de WhatsApp.')
  }
  if (parentheses !== 0) invalid('Revisa los paréntesis del número de WhatsApp.')
  const normalized = input.replace(/[\s()-]/g, '')
  const digits = normalized.replace(/^\+/, '')
  if (!/^[0-9]{7,15}$/.test(digits)) {
    invalid('El número de WhatsApp debe contener entre 7 y 15 dígitos.')
  }
  return normalized
}
