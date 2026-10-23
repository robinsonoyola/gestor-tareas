# Formularios al volver a la ventana

Corrección del 23 de octubre de 2026, solo de frontend. No requiere SQL.

## Causa reproducida
Supabase puede emitir SIGNED_IN al volver a una pestaña que ya conserva sesión. OrganizationProvider limpiaba el perfil, los permisos y la empresa activa ante ese aviso, incluso si la identidad no había cambiado. ProtectedRoute mostraba carga y App cambiaba la clave de la navegación, desmontando la pantalla y su formulario.

## Comportamiento corregido
Con la misma cuenta, el aviso vuelve a consultar el contexto y los permisos en segundo plano, conservando la pantalla y los valores sin guardar. La comprobación al recuperar foco y la revisión periódica de 30 segundos se mantienen. Cerrar sesión, cambiar de cuenta o empresa y perder permisos siguen retirando el contexto protegido anterior. No se guardan borradores de credenciales en localStorage.

## Ensayo
El ejecutor local work/test-auth-focus.cjs reprodujo primero la pérdida con la implementación anterior. Después verifica el proveedor, la ruta protegida y el diálogo real de nueva tarjeta en Chromium con autenticación simulada: foco y SIGNED_IN repetido, renovación de token, actualización de perfil, revisión periódica, cambio de empresa, salida de sesión, cambio de cuenta y retirada de administración. Los resultados se guardan en supabase/tests/auth-focus-results.json. No se accede a cuentas reales durante el ensayo automatizado.

Una recarga completa del navegador, un fallo real de autorización o navegar fuera del formulario pueden seguir descartando cambios no guardados; esta corrección evita el reinicio causado por la revalidación de una sesión que sigue siendo la misma.
