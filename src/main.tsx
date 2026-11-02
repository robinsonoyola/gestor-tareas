import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import { validateRuntimeConfig } from './config/runtime.js'

const root = createRoot(document.getElementById('root')!)

function StartupProblem({ title, details }: { title: string; details: string[] }) {
  return (
    <main className="flex min-h-screen items-center justify-center bg-background p-6 text-foreground">
      <section role="alert" className="w-full max-w-lg rounded-2xl border border-border bg-card p-6 shadow-lg">
        <h1 className="text-2xl font-semibold">{title}</h1>
        <p className="mt-3 text-muted-foreground">ASE Work no ha intentado conectarse. Revisa la configuración del entorno y vuelve a cargar.</p>
        {details.length > 0 && <ul className="mt-4 list-disc space-y-2 pl-5">{details.map(detail => <li key={detail}>{detail}</li>)}</ul>}
        <p className="mt-5 text-center text-xs text-muted-foreground">ASE Work v{import.meta.env.ASE_WORK_VERSION}</p>
      </section>
    </main>
  )
}

async function bootstrap() {
  const configuration = validateRuntimeConfig()
  if (!configuration.ok) {
    root.render(<StartupProblem title="ASE Work necesita configuración" details={configuration.problems} />)
    return
  }

  try {
    const [{ default: App }, { default: OrganizationProvider }] = await Promise.all([
      import('./App.tsx'),
      import('./components/auth/OrganizationProvider.jsx')
    ])
    root.render(
      <StrictMode>
        <OrganizationProvider><App /></OrganizationProvider>
      </StrictMode>
    )
  } catch (error) {
    console.error('ASE Work no pudo iniciar', error instanceof Error ? error.name : 'Error')
    root.render(<StartupProblem title="No se pudo iniciar ASE Work" details={["Comprueba la conexión y recarga la página."]} />)
  }
}

void bootstrap()
