# Incidencia resuelta: solo consulta

La transición a resolved conserva la solución y el historial y cierra definitivamente la edición. Un trigger de base de datos rechaza cualquier UPDATE o DELETE posterior sobre esa incidencia, incluso por administración. La resolución inicial de una incidencia abierta o en atención sigue permitida.

El RPC de bandeja devuelve can_manage=false para incidencias resueltas. La interfaz también comprueba el estado por si recibe permisos antiguos: oculta el botón de gestionar, oculta formularios abiertos y conserva historia y adjuntos de consulta. Un refresco de la bandeja cierra la edición si otro responsable ha resuelto el registro.

Activación pendiente: deployment/bloquear-incidencias-resueltas.sql en ASE Work - Pruebas. No repetir el instalador completo. Verificación: 89 comprobaciones PostgreSQL acumuladas, incluyendo bloqueo del responsable y administración, prohibición de borrado, conservación íntegra del registro e historial y ausencia de notificaciones por intentos rechazados. Tres comprobaciones Chromium verifican botón oculto, consulta conservada y eliminación del formulario obsoleto. Compilación correcta.
