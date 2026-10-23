# Vistas del empleado por estado

Los cuadros Total/Pendientes/En progreso/Completadas se retiran del inicio. El menú conserva Mis Tareas para todas las asignaciones y añade Pendientes, En progreso y Completadas mediante parámetros de la ruta /employee. Los filtros no cambian la planificación, los permisos ni la tarea que puede ficharse. Las completadas se siguen abriendo solo para consultar historial y comentarios.

Los estados mostrados proceden de la cola por empleado; no del estado global compartido de la tarea. La selección del menú indica la vista actual y cierra el menú móvil. El modo de punto compartido también reconoce estos parámetros de filtro.

Verificado mediante siete comprobaciones en Chromium con datos sintéticos: sin cuadros, filtro pendiente, en progreso y completadas, opción activa, consulta sin fichaje y retorno a todas las tareas. Compilación correcta. No requiere SQL.
