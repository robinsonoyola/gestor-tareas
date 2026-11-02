import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8')
const css = fs.readFileSync(path.join(root, 'src', 'index.css'), 'utf8')

const checks = [
  ['idioma español declarado', /<html\s+lang=["']es["']/.test(html)],
  ['vista móvil configurada', /name=["']viewport["']/.test(html)],
  ['foco de teclado visible', /:focus-visible\s*\{[^}]*outline:/s.test(css)],
  ['movimiento reducido respetado', /@media\s*\(prefers-reduced-motion:\s*reduce\)/.test(css)],
  ['controles táctiles de 44 px', /pointer:\s*coarse[\s\S]*?min-height:\s*44px/.test(css)],
  ['gestos táctiles sin retraso', /touch-action:\s*manipulation/.test(css)]
]

const failed = checks.filter(([, passed]) => !passed).map(([name]) => name)
if (failed.length) throw new Error(`Falla la base de accesibilidad: ${failed.join(', ')}`)

console.log(JSON.stringify({ passed: true, checks: checks.length }))
