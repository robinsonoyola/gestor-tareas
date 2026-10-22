# Estado de ASE Work — 22 de octubre de 2026

Esta rama guarda la copia candidata ensayada en ASE Work - Pruebas. No instala cambios en hotel-tareas ni acredita un despliegue de producción.

## Comprobado por el usuario en pruebas
- Acceso del administrador después de cerrar y abrir sesión; empleados y tareas visibles.
- Identificación NFC en Android, inicio y finalización de tarea y registro visible en Fichajes.
- PIN de cinco dígitos; posteriormente identificación automática por código sin seleccionar nombre ni método.
- Vuelta al inicio del punto en diez segundos; no finaliza automáticamente la tarea.

## Base alojada
Se aplicaron las migraciones 001 y 002 y luego las correcciones 003 (identidad en Supabase alojado) y 004 (código automático). Las funciones create-employee y update-employee-email fueron desplegadas por el usuario. La actualización de base generó una copia local previa, excluida de esta rama. No volver a ejecutar la instalación inicial sobre la base ya migrada.

## Pendiente
- Probar incidencias, destinatarios por área/persona y sus avisos internos.
- Validar en el proyecto alojado buscador, filtros, desplazamiento a detalle del día, cierre administrativo e importación Excel.
- Crear una segunda empresa y comprobar aislamiento con sesiones reales, archivos y funciones externas.
- Recuperación de contraseña, aplazada por el usuario.

## Validación local guardada
Las pruebas de base usan datos sintéticos y PGlite; no sustituyen las pruebas alojadas. Desde supabase/tests: npm ci y npm test. Incluyen regresión de empresa, PIN, incidencias, aislamiento, búsqueda y límites de acceso. Los resultados de navegador proceden de componentes React con servicios simulados y pantallas de varios tamaños; el equipo de pruebas local conserva su ejecutor.

Los estilos y recursos de marca se conservaron, comprobados mediante los seis hashes de ui-baseline-sha256.json. No se incluyen certificados privados, claves, .env, datos de usuarios ni copias de bases.
