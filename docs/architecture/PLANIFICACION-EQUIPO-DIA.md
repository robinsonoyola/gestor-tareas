# Planificación del equipo por día

La planificación conserva su calendario y editor por empleado. La nueva vista del equipo muestra recuentos de pendientes, activas, bloqueadas y completadas para la fecha seleccionada, búsqueda por nombre, filtro por estado o sin planificación y acceso directo al orden de cada persona. Los datos utilizan work_admin_overview, con sus permisos y aislamiento existentes; hasta tres solicitudes simultáneas y cancelación de resultados obsoletos. Un error de carga se muestra expresamente, sin sustituirlo por ceros. Actualización manual y después de guardar; no hay actualización periódica automática.

Se añade selección de posición para pendientes dentro de un tramo contiguo de pendientes. No se atraviesan posiciones de tareas activas, completadas ni bloqueadas. Tampoco se permite retirar una pendiente si desplazaría una posición fija posterior. El servidor sigue validando el orden al guardar con work_save_plan. Se indica si hay cambios locales y se confirma descartarlos antes de usar el acceso a otro empleado desde la vista de equipo.

Validación local: compilación correcta y seis comprobaciones de navegador con datos simulados: recuentos, errores parciales, filtros, límites del movimiento, orden enviado al guardar y anchura móvil de 390 px. No se modificaron datos alojados ni se necesitan migraciones SQL.
