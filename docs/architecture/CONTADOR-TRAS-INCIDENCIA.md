# Sincronización del fichaje tras una incidencia

El servidor ya cerraba el fichaje y bloqueaba la planificación, pero IncidentReporter solo actualizaba su propio mensaje. El detalle conservaba activeCheckin y su intervalo, de modo que el contador y los formularios seguían visibles hasta recargar.

Tras confirmar work_report_incident, el componente notifica al detalle. Si p_block=true, el detalle detiene inmediatamente el contador, elimina el fichaje activo y deshabilita acciones; conserva el mensaje de confirmación y el enlace a seguimiento. Consulta de nuevo el historial de fichajes y la cola. El estado local bloqueado protege la pantalla ante lecturas antiguas o errores de actualización. La etiqueta es Bloqueada por incidencia, nunca Completada.

El botón Reportar incidencia sigue debajo de Comentarios y archivos. Una incidencia no bloqueante no detiene el fichaje. Si el envío falla, no se modifica el contador.

Verificación Chromium con el detalle y reportador reales, servicios sintéticos: cuatro comprobaciones de fallo de envío, cierre sin recarga, acciones deshabilitadas/seguimiento conservado y reporte no bloqueante. Compilación correcta. No requiere SQL adicional. Pendiente comprobación física del usuario.

Comportamiento final validado: tras confirmar el bloqueo se detiene el contador y se vuelve automáticamente a /employee, con un aviso de tarea bloqueada, sin completarla. No espera a consultas de refresco para regresar al listado.
