# Tablero Kanban de planificación y movimientos

Ruta /admin/planning/board, accesible desde Planificación → Tablero. Exige planning.view en la interfaz y en work_planning_board(date,uuid). Cuatro columnas: pendientes (amarillo), en curso (azul), bloqueadas (rojo) y completadas (verde). Se conservan estilos, tipografías e identidad visual del resto de la app.

La consulta operativa ampliada usa `work_planning_board_range`: admite Día, Semana, Mes o un rango personalizado de hasta 93 días, empleado, estado, búsqueda y paginación (máximo 200 ejecuciones por página). Los contadores se calculan en servidor sobre el periodo, empleado y búsqueda, antes del filtro de estado. Cada tarjeta conserva el `id` de ejecución, además del `task_id`, para que las recurrencias nunca colisionen.

En móvil las columnas se apilan; solo se muestran dos columnas cuando existe anchura suficiente y cuatro en pantallas amplias. El detalle reúne programación, edición de fechas para ejecuciones abiertas, cambio de estado e historial. Reabrir una completada sigue siendo una transición explícita mediante el diálogo, con motivo, confirmación, versión de concurrencia, identificador idempotente y auditoría.

Cada tarjeta es una aparición diaria por empleado, identificada por el plan, no el estado genérico del catálogo. Permite filtros de fecha/empleado y búsqueda por título, instrucciones o nombre. El detalle muestra instrucciones, persona, prioridad, fecha, inicio/cierre e historial administrativo. El enlace a planificación conserva empleado y fecha. La misma actividad para varias personas conserva tarjetas independientes.

## Movimientos
Solo administración puede cambiar estados, manteniendo la restricción existente sobre cierres de fichajes. Los usuarios con planning.view consultan el tablero. Arrastre HTML con ratón entre columnas y alternativa Cambiar estado para móvil/teclado. Cada cambio pide motivo de 5 a 2000 caracteres y confirmación. No hay cambio optimista antes de la respuesta del servidor. Se pausa la consulta automática al arrastrar o confirmar.

- En curso: abre un fichaje manual identificado como Inicio administrativo desde tablero. Nunca lo registra como lectura NFC. Solo se inicia trabajo de hoy, asignado, respetando prioridad y sin otro fichaje abierto del empleado.
- Completada: exige ficha activa y todos los pasos obligatorios completos; usa el cierre administrativo auditado existente.
- Bloqueada: exige responsable; crea incidencia y notificación interna. Si estaba activa, cierra su fichaje sin completarla. Un bloqueo de una tarea aún no iniciada no fabrica un fichaje.
- Pendiente: permite reabrir una completada o bloqueada, con motivo y sin incidencias bloqueantes abiertas. No se descarta el historial de las ejecuciones anteriores. Una activa debe detenerse o finalizarse antes; no puede devolverse directamente a pendientes.

La reapertura guarda board_reopened_at sin alterar created_at. La cola móvil utiliza ese límite para no confundir el fichaje anterior cerrado con la nueva ejecución pendiente. Se sustituye el índice único de un fichaje total por plan por uno de un fichaje abierto por plan, conservando los controles de orden y simultaneidad existentes. Cada ficha nueva conserva su propia lista de pasos.

work_move_board exige administrador, bloquea empleado y plan, comprueba una versión de tarjeta actualizada por trigger en cada cambio del plan y utiliza un identificador idempotente. Los reintentos de una operación confirmada no duplican fichajes ni incidencias. No pueden cambiarse el actor, motivo, destino o responsable de la operación confirmada. El historial guarda quién, cuándo, estado anterior/nuevo, motivo y enlaces al fichaje/incidencia. Sin permisos directos de escritura sobre el historial para roles API.

## Actualización y protección
Consulta de solo lectura cada 30 segundos con la pestaña visible y al recuperar foco, sin consultas solapadas. Respuestas de filtros anteriores se descartan. Cada carga tiene límite de 15 segundos y permite reintentar; un fallo en la actualización automática conserva el último resultado con aviso. El panel del empleado revisa su cola cada 10 segundos; el detalle detecta cierres externos, detiene el contador y vuelve a sus tareas tanto en móvil como en modo tablet. Un error de conexión no elimina borradores ni interpreta una ficha como cerrada.

La consulta usa una sola función por fecha, con límite explícito de 10.000 que solicita filtrar por empleado si se excede. Funciones con search_path vacío, SECURITY DEFINER y propietario ase_tenant_executor; RLS y comprobaciones de rol mantienen ámbito de empresa. Se revoca CREATE al terminar.

## Activación y validación
Pendiente por el usuario en ASE Work - Pruebas: deployment/activar-tablero-planificacion.sql, actualizado para incluir 010 y 011 en una transacción y admitir tanto instalación inicial como actualización del tablero anterior. No repetir el instalador completo. El activador combinado fue aplicado dos veces sobre datos sintéticos sin perder eventos.

176 aserciones SQL acumuladas y una adicional del activador combinado (177); aislamiento, permisos, fecha/prioridad, fichaje único abierto, pasos obligatorios, bloqueo/notificación, reapertura, idempotencia, versión concurrente y auditoría. Ocho comprobaciones de consulta del tablero, ocho de colores/arrastre/confirmación/móvil/solo lectura, tres de sincronización con el empleado y siete de regresión del menú de estados. Compilación correcta y seis archivos visuales originales intactos. Sin cambios alojados ni nuevas pruebas físicas de NFC.
