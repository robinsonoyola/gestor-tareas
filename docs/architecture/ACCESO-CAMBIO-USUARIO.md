# Acceso al cambiar de usuario

El formulario de acceso ya no consulta mt_context después de signInWithPassword: esa comprobación pertenece a OrganizationProvider. Tras autenticar, /login/complete queda protegido por la misma comprobación de empresa y permisos y dirige a administración o al panel del empleado. Se evita duplicar consultas de contexto durante los cambios de cuenta y los remontajes de la interfaz.

El formulario limita su espera de autenticación a 20 segundos. Si la promesa no responde, abandona el indicador de carga, muestra una explicación y ofrece Recargar acceso. No se permite otro intento concurrente sobre la misma solicitud pendiente. El límite no cancela la operación interna del SDK; una respuesta tardía no ejecuta la navegación del intento que ya venció. No se borran credenciales, sesiones guardadas ni datos de negocio. Las credenciales incorrectas muestran un mensaje y permiten reintentar. Se registra únicamente el código del error, sin el objeto de autenticación.

Verificación local: cuatro casos Chromium con el formulario, OrganizationProvider, ProtectedRoute y destino reales: acceso de empleado, acceso de administrador, credenciales incorrectas y autenticación sin respuesta. No son una confirmación de conectividad ni de credenciales de una cuenta alojada. No necesita migración SQL.

El usuario confirmó posteriormente que pudo entrar con la otra cuenta. Se retira el botón Atrás de la pantalla de acceso para que no aparezca tras cerrar sesión.
