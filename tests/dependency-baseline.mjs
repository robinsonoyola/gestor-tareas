import fs from 'node:fs'

const lock = JSON.parse(fs.readFileSync(new URL('../package-lock.json', import.meta.url), 'utf8'))
const project = JSON.parse(fs.readFileSync(new URL('../package.json', import.meta.url), 'utf8'))
const installed = name => lock.packages?.[`node_modules/${name}`]?.version || ''
const compare = (left, right) => {
  const a = left.split('.').map(value => Number.parseInt(value, 10) || 0)
  const b = right.split('.').map(value => Number.parseInt(value, 10) || 0)
  for (let index=0; index<Math.max(a.length,b.length); index++) {
    if ((a[index]||0)!==(b[index]||0)) return (a[index]||0)-(b[index]||0)
  }
  return 0
}

const minimums = {
  'react-router': '7.18.0',
  'react-router-dom': '7.18.0',
  ws: '8.21.0',
  vite: '8.3.5',
  postcss: '8.5.23',
  rolldown: '1.2.16',
  esbuild: '0.28.2',
  eslint: '10.14.0'
}
const unsafe = Object.entries(minimums).filter(([name, minimum]) => !installed(name) || compare(installed(name),minimum)<0)
if (unsafe.length) throw new Error(`El bloqueo recuperó dependencias vulnerables: ${unsafe.map(([name,minimum])=>`${name} requiere ${minimum} o posterior`).join(', ')}`)
if (project.engines?.node !== '^20.19.0 || ^22.13.0 || >=24') throw new Error('El proyecto no declara las versiones de Node compatibles con la cadena de compilación')

console.log(JSON.stringify({passed:true,node:project.engines.node,versions:Object.fromEntries(Object.keys(minimums).map(name=>[name,installed(name)]))}))
