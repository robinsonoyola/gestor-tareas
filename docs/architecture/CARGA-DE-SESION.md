# Carga de sesión acotada

El indicador general de ProtectedRoute dependía de que getSession y las llamadas mt_context/work_my_permissions terminasen. Una promesa sin respuesta mantenía el indicador indefinidamente.

OrganizationProvider limita cada verificación completa a 15 segundos. El vencimiento invalida la generación, elimina el contexto con permisos y muestra una recuperación explícita con reintento. Respuestas tardías no pueden restaurar permisos de una generación anterior. No se usa una identidad almacenada como autorización alternativa.

Los eventos de autenticación se procesan fuera del callback de Supabase con la identidad entregada por el propio evento; no vuelven a esperar getSession dentro de ese recorrido. El cierre de sesión con identidad nula se procesa de inmediato. Las comprobaciones de organización y permisos siguen siendo obligatorias.

Verificación Chromium con proveedor y ruta reales: 4 casos de llamadas bloqueadas, recuperación y respuesta obsoleta; 7 casos de conservación de borradores, actualización de permisos, cambio de cuenta y cierre de sesión. No se ha reproducido la conexión del teléfono físico; queda pendiente recarga y comprobación del usuario. No requiere SQL.
