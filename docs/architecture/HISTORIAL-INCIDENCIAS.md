# Evolución de incidencias

En Incidencias cada registro incluye un desplegable compacto con su evolución cronológica. Muestra creación, cambios de estado, seguimiento o solución, fecha y autor. Se carga al desplegar; se actualiza cuando cambia updated_at. El bloque tiene altura máxima y desplazamiento para móviles.

La tabla work_incident_history es append-only para el rol ejecutor y no tiene acceso directo para usuarios. Un trigger conserva eventos ante inserción, cambios de estado, nota o destinatario, dentro de la misma transacción. El RPC de lectura permite únicamente administración, informante, responsable o integrantes del área, en la organización activa. Los empleados no pueden crear, modificar ni borrar eventos.

Los registros anteriores a esta función reciben una instantánea etiquetada con su estado actual y fecha de incorporación al historial. No se reconstruyen transiciones antiguas que nunca se almacenaron.

Activación pendiente en ASE Work - Pruebas: ejecutar solo deployment/activar-historial-incidencias.sql. No repetir el instalador completo. Pruebas: 80 comprobaciones PostgreSQL acumuladas, incluyendo acceso por informante/responsable, rechazo entre organizaciones, rechazo para terceros de la misma empresa e historial no falsificable. Cinco comprobaciones de interfaz en Chromium: carga bajo demanda, cronología, refresco, anchos 320/390/768 y reintento.
