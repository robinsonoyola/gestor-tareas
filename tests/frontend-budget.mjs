import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const dist = path.join(root, 'dist')
const files = fs.readdirSync(path.join(dist, 'assets')).map(name => ({ name, bytes: fs.statSync(path.join(dist, 'assets', name)).size }))
const javascript = files.filter(item => item.name.endsWith('.js'))
const styles = files.filter(item => item.name.endsWith('.css'))
const forbidden = files.filter(item => item.name.endsWith('.map') || /(?:^|\.)env(?:\.|$)|\.(?:key|p12|pfx|backup|dump)$/i.test(item.name))
if (forbidden.length) throw new Error(`La entrega contiene archivos no publicables: ${forbidden.map(item => item.name).join(', ')}`)

const html = fs.readFileSync(path.join(dist, 'index.html'), 'utf8')
const initialNames = [...html.matchAll(/(?:src|href)="\/?assets\/([^"]+)"/g)].map(match => match[1])
const initialBytes = initialNames.reduce((total, name) => total + (files.find(item => item.name === name)?.bytes || 0), 0)
const javascriptBytes = javascript.reduce((total, item) => total + item.bytes, 0)
const styleBytes = styles.reduce((total, item) => total + item.bytes, 0)
const largestJavascript = Math.max(0, ...javascript.map(item => item.bytes))

if (initialBytes > 500 * 1024) throw new Error(`La carga inicial supera 500 KB: ${initialBytes} bytes`)
if (largestJavascript > 400 * 1024) throw new Error(`Un bloque JavaScript supera 400 KB: ${largestJavascript} bytes`)
if (javascriptBytes > 1500 * 1024) throw new Error(`El JavaScript total supera 1,5 MB: ${javascriptBytes} bytes`)
if (styleBytes > 160 * 1024) throw new Error(`Los estilos superan 160 KB: ${styleBytes} bytes`)
if (files.length > 100) throw new Error(`La entrega contiene demasiados recursos: ${files.length}`)

console.log(JSON.stringify({ passed: true, initialBytes, javascriptBytes, styleBytes, largestJavascript, assetFiles: files.length }))
