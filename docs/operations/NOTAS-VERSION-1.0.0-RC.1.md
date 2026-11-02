# ASE Work 1.0.0-rc.1

Primera versión candidata completa del gestor operativo de tareas para microempresas. No es todavía una publicación comercial definitiva y no modifica ningún entorno de producción.

## Incluye

- aislamiento por empresa, propietarios, administradores, encargados, empleados, roles, permisos y áreas;
- catálogo de actividades, importancia independiente del orden, responsables, colaboradores y seguidores;
- planificación diaria y por periodos, tablero móvil, secuencia obligatoria y fechas flexibles, estrictas o planificadas;
- repeticiones por persona o área, avisos internos y asignación posterior;
- fichaje manual, mediante punto o NFC, pausas, pasos, resultados y evidencias obligatorias;
- comentarios, archivos, menciones, incidencias, revisión, cancelación e historial auditable;
- proyectos, hitos, dependencias, subtareas, etiquetas, plantillas y archivo de tareas;
- informes, productividad, indicadores y exportaciones CSV y Excel;
- interfaz adaptable con tema claro y oscuro y vistas específicas por perfil.

## Verificación automática

El control `npm run test:release` finalizó correctamente el 2 de noviembre de 2026:

- 79 migraciones transaccionales;
- 114 comprobaciones sintéticas de PostgreSQL;
- 60 tablas con RLS y límites de empresa completos;
- 43 rutas, 24 destinos de menú y 24 pantallas de carga diferida;
- cero escrituras directas desde el navegador y cero ayudantes internos expuestos;
- instalación nueva sintética, funciones administrativas, copias, restauración, exportaciones, accesibilidad, compilación y manifiestos verificados;
- compilación sin claves privadas, conexiones directas, tokens administrativos ni mapas de código.

El manifiesto reproducible se encuentra en `deployment/generated/release-manifest.json`.

## Fuera de esta candidata

Ventas, facturación, inventario, contabilidad, nóminas y CRM completo pertenecen a módulos ERP posteriores.

## Validaciones manuales aplazadas

Antes de convertir esta candidata en una versión comercial deben registrarse las pruebas reales acordadas: dos empresas alojadas, recuperación por correo, recorridos por perfil, Android/iPhone/ordenador/tablet/NFC, apertura de CSV y Excel y restauración en un proyecto Supabase vacío.

