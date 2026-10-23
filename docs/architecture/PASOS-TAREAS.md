# Pasos de tareas

## Uso
En Tareas, el encargado con tasks.edit abre Pasos en una actividad ya creada. Puede añadir hasta 50 pasos de 200 caracteres, ordenarlos y marcar su obligatoriedad. Guardar usa comparación de la versión anterior para detectar ediciones concurrentes. No se pueden modificar plantillas mientras haya fichajes abiertos de esa actividad.

Cada nuevo fichaje recibe una copia de la plantilla, sin marcas previas. En el móvil los pasos están después del contador y antes del historial y los comentarios. Solo el dueño del fichaje abierto puede marcarlos. Los fichajes anteriores tienen consulta y cronología de marcas/desmarcas con identidad y fecha. Las tareas sin pasos siguen su flujo habitual. Los fichajes completados anteriores a la activación no reciben pasos retroactivos.

El punto compartido permite consultar y marcar pasos al identificarse para finalizar. Reutiliza comprobación de clave, tarjeta/PIN, pertenencia activa y caducidad del ticket de la estación. Al interactuar se ofrecen 60 segundos en pantalla; el ticket conserva su caducidad de servidor, sin ampliación. Tras finalizar vuelve al contador normal de 10 segundos.

## Protección
Tablas sin privilegios directos para authenticated/anon; funciones con ámbito de empresa y propietario ase_tenant_executor sin BYPASSRLS. Cambios y cierres serializados por el bloqueo del fichaje. Los pasos de una ejecución cerrada no se modifican. Marcas repetidas son idempotentes. Las plantillas no aceptan marcas precompletadas.

Un trigger diferido impide el cierre normal por cualquier vía si faltan pasos obligatorios, revirtiendo también la finalización del plan. Se conserva el cierre excepcional auditado por incidencia (bloqueado, no completado) y por administrador (motivo obligatorio). La consulta de pasos de otro trabajador exige tasks.view o checkins.view dentro de la misma empresa; el trabajador ordinario consulta sus propias ejecuciones.

## Activación y verificación
Solo en ASE Work - Pruebas: deployment/activar-pasos-tareas.sql. Es incremental e idempotente; no repetir el instalador completo. Activación confirmada por el usuario en ASE Work - Pruebas. También confirmó que el cierre se bloquea con un paso obligatorio pendiente y se permite después de completarlo.

142 comprobaciones SQL acumuladas con datos sintéticos: plantilla, permisos, aislamiento, edición concurrente, ficha propia, auditoría, idempotencia, bloqueo obligatorio, opcionales, historial inmutable, nueva ejecución limpia, incidente bloqueante y estación anónima con ticket válido/incorrecto/consumido. Siete comprobaciones del editor y móvil; cuatro del punto compartido. Compilación local correcta. No sustituyen la validación física de NFC ni las pruebas de empresas aplazadas por el usuario.
