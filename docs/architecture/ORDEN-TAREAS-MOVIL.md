# Orden del trabajo móvil

Todas las asignaciones son visibles. Solo la primera tarea pendiente de la planificación de hoy puede iniciarse; cualquier fichaje abierto impide iniciar otro. Las finalizadas se ordenan abajo y solo permiten consultar el historial. La siguiente tarea se consulta de nuevo al terminar; no se calcula con una lista antigua del navegador.

La excepción de reparación exige una incidencia abierta o en curso asignada al empleado o a su área, dentro de la misma empresa. Su fichaje queda vinculado a esa incidencia y no reabre ni modifica la planificación completada de otro empleado. Resolver la incidencia retira la excepción para nuevos inicios; un fichaje ya abierto se puede cerrar.

Las asignaciones sin planificación no reciben prioridad inventada. Las fechas futuras no se pueden adelantar. La tarea diaria del día siguiente usa una nueva fila de planificación, sin reabrir la ocurrencia finalizada.

Migración pendiente en servidor: 20261023000400_mobile_priority_queue.sql, después de 20261023000300_active_checkin_actions.sql. Aplicar solo el SQL incremental de deployment/activar-orden-tareas-movil.sql en ASE Work - Pruebas, sin repetir el instalador completo.

Verificación: 70 comprobaciones PostgreSQL aisladas, incluyendo prioridad, cambio de prioridad, no repetición, avance, excepción de incidencia, lectura sin asignación ordinaria y separación entre organizaciones. Interfaz compilada; pendiente prueba física en Android.

El listado resalta solo next_task (o la tarea activa). El resto usa botón de consulta y abre view=history; esa ruta no muestra fichaje, formularios ni incidencias, incluso si conserva un fichaje activo en memoria. La autorización para iniciar compara next_task, id del detalle y can_start=true. Verificación Chromium: cuatro pruebas de botón único, estilo de consulta y destino de navegación, con una respuesta sintética adversa que marca varias tareas can_start. Cambio solo de interfaz; no requiere SQL adicional.
