# Acciones del empleado con fichaje activo

El detalle permite consultar historial sin fichaje. Comentarios, archivos e incidencias solo aparecen con un fichaje propio abierto en esa tarea; administración conserva sus permisos.

Aplicar únicamente la migración 20261023000300_active_checkin_actions.sql en ASE Work - Pruebas. No repetir el instalador completo. La interfaz está compilada; la protección de servidor queda pendiente de aplicar este SQL.

Inicio móvil: planificación del día de work_my_day_v2, fecha explícita y fichajes abiertos primero. Otras asignaciones se consultan mediante el botón inferior. No se inventan ocurrencias para tareas que carecen de planificación.

Verificación: compilación correcta y 53 comprobaciones aisladas de PostgreSQL, incluyendo comentarios, archivos e incidencias rechazados sin fichaje, permitidos durante el fichaje, separación entre personas y empresas, cierre e idempotencia NFC. Falta validación física de este cambio en Android.
