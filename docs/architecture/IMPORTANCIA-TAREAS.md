# Importancia de tareas — 24/10/2026

## Decisión operativa

La importancia y el orden de ejecución son datos distintos. Una tarea puede ser Baja, Normal, Alta o Urgente. Urgente se destaca visualmente en rojo, pero no cambia la posición decidida por el encargado, no se convierte en la siguiente tarea y no permite fichar fuera de orden.

El orden diario continúa guardado en `work_day_plan.priority`. La cola móvil elige la siguiente tarea exclusivamente por ese orden. El inicio manual desde el tablero y el fichaje del empleado conservan las comprobaciones de tareas anteriores pendientes.

## Interfaz

El catálogo permite elegir y filtrar por importancia. Las vistas de catálogo, empleado, detalle y tablero muestran una etiqueta independiente del orden. El formulario explica expresamente que la importancia no altera la secuencia. La edición muestra un historial de cambios con actor y fecha.

## Seguridad y auditoría

`tasks.importance` admite únicamente `low`, `normal`, `high` y `urgent`, con `normal` como valor inicial para los datos existentes. Crear o editar utiliza una función transaccional que conserva las validaciones y permisos de gestión de tareas. Un valor inválido revierte toda la operación.

El historial es de solo lectura para la aplicación, está aislado por empresa mediante RLS, claves foráneas compuestas y filtros explícitos. La creación registra un único evento con el valor elegido; las ediciones solo registran cambios reales. La reactivación de la migración no borra ni duplica el historial.

## Activación y validación

La activación incremental es `deployment/activar-importancia-tareas.sql` y debe ejecutarse únicamente en ASE Work - Pruebas. No se repite el instalador completo y no se modifica producción.

La validación sintética cubre permisos, separación entre empresas, valores inválidos, atomicidad, auditoría, reactivación y la regla central: una segunda tarea urgente sigue detrás de una primera tarea normal y su fichaje fuera de orden es rechazado. La interfaz se comprueba en escritorio y móvil, incluidos formulario, filtro, historial, etiquetas y conservación del formulario ante un rechazo del servidor.
