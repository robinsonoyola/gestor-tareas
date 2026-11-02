import fs from 'node:fs'

const app = fs.readFileSync(new URL('../src/App.tsx', import.meta.url), 'utf8')
const boundary = fs.readFileSync(new URL('../src/components/auth/RouteErrorBoundary.tsx', import.meta.url), 'utf8')

for (const marker of ['<RouteErrorBoundary', '<Suspense', '<Routes>']) {
  if (!app.includes(marker)) throw new Error(`Falta la protección ${marker}`)
}
for (const marker of ['getDerivedStateFromError', 'componentDidCatch', 'Recargar ASE Work', 'window.location.reload()', 'Tu sesión y tus datos no se han borrado']) {
  if (!boundary.includes(marker)) throw new Error(`La recuperación no incluye ${marker}`)
}

console.log(JSON.stringify({ passed: true, routeLoading: true, routeRecovery: true }))
