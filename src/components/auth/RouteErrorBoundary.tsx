import { Component, type ErrorInfo, type ReactNode } from "react";

type Props = { children: ReactNode };
type State = { failed: boolean };

export default class RouteErrorBoundary extends Component<Props, State> {
  state: State = { failed: false };

  static getDerivedStateFromError(): State {
    return { failed: true };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error("ASE Work no pudo cargar la pantalla", error.name, info.componentStack);
  }

  render() {
    if (!this.state.failed) return this.props.children;

    return (
      <main className="flex min-h-screen items-center justify-center bg-background p-6 text-foreground">
        <section role="alert" className="w-full max-w-lg rounded-2xl border border-border bg-card p-6 shadow-lg">
          <h1 className="text-2xl font-semibold">No se pudo cargar esta pantalla</h1>
          <p className="mt-3 text-muted-foreground">
            Puede deberse a una interrupción de red o a que ASE Work acaba de actualizarse. Tu sesión y tus datos no se han borrado.
          </p>
          <button
            type="button"
            className="mt-6 w-full rounded-xl bg-primary px-4 py-3 font-semibold text-primary-foreground"
            onClick={() => window.location.reload()}
          >
            Recargar ASE Work
          </button>
        </section>
      </main>
    );
  }
}
