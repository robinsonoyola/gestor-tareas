# ASE Work

ASE Work es un gestor operativo de tareas para microempresas. Separa empresas y permisos, organiza el orden diario de cada empleado y registra la ejecución mediante fichajes, pasos, evidencias, incidencias e historial.

## Alcance actual

- Empresas aisladas con administradores, encargados, empleados, roles y áreas.
- Catálogo, asignaciones, responsable, colaboradores, seguidores e importancia.
- Planificación diaria, tablero, orden obligatorio y fechas de ejecución.
- Repeticiones personales o por área y avisos internos.
- Fichaje manual, por punto o NFC, pausas, pasos y evidencias obligatorias.
- Comentarios, archivos, menciones, incidencias, revisión y cancelación.
- Proyectos, hitos, dependencias, subtareas, etiquetas y plantillas.
- Informes, productividad, indicadores y exportaciones CSV/Excel.
- Archivo seguro de actividades con conservación del historial.
- Interfaz adaptable, tema claro/oscuro y vistas por perfil.

Los siguientes módulos empresariales no forman parte de esta entrega: ventas, facturación, inventario, contabilidad, nóminas y CRM completo.

## Tecnología

- React 18 y Vite.
- Supabase: PostgreSQL, Auth, Storage y Edge Functions.
- Radix UI, Tailwind CSS y Lucide.
- Pruebas PostgreSQL aisladas mediante PGlite.

La compilación web fija la base ampliamente disponible de Vite 8: Safari/iOS 16.4, Chrome/Edge 111 y Firefox 114 o posteriores.

## Desarrollo local

1. Instalar Node.js 20.19 o posterior compatible (22.13+ o 24+) y las dependencias con `npm install`.
2. Crear un `.env` local con `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` del entorno autorizado.
3. Iniciar con `npm run dev -- --host 0.0.0.0`.

Nunca incluir `service_role`, contraseñas, copias de bases ni claves privadas en archivos `VITE_*` o en Git.

## Control de la versión candidata

Ejecutar:

```powershell
npm run test:release
```

Este control valida seguridad multiempresa sintética, las 77 migraciones, aislamiento de tablas, funciones y esquema privado, instalación nueva, funciones administrativas, recuperación, exportaciones y compilación. Las pruebas reales aplazadas se enumeran en `docs/operations/CONTROL-VERSION-CANDIDATA.md`.

## Instalación y operación

- `deployment/README.md`: generación e instalación de los paquetes.
- `docs/architecture/ENSAYO-Y-ACTIVACION.md`: ensayo alojado actual.
- `docs/operations/DESPLIEGUE-Y-RECUPERACION.md`: copias, restauración y diagnóstico.
- `docs/manuals`: manuales por perfil.

No ejecutar archivos históricos de activación de forma aislada sobre una instalación actual. La fuente oficial son las migraciones versionadas y los archivos de `deployment/generated`.
