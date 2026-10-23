# Prueba de NFC asociado a una tarea

Código preparado el 23 de octubre de 2026. Falta instalar esta ampliación y hacer la prueba física en Supabase de pruebas. No se ha cambiado el modo de la empresa desde el código.

## Qué cambia
- El empleado autenticado abre una tarea asignada, pulsa NFC y acerca su móvil a la tarjeta de esa tarea.
- La lectura únicamente prepara la acción. Debe confirmar expresamente iniciar o finalizar el fichaje.
- La finalización identifica el registro exacto; reintentar el cierre no inicia uno nuevo ni duplica registros.
- El UID puede introducirse con dos puntos, espacios o guiones; se compara normalizado.
- No se escribe en la tarjeta física y el código personal NFC guardado en ella permanece igual.
- El endpoint antiguo que alternaba automáticamente inicio y cierre queda retirado de escritura.
- Se registra tiempo por empleado y tarea; no se completa automáticamente el estado global de una tarea compartida.

## Activación en pruebas
1. Ejecutar deployment/activar-nfc-por-tarea.sql en SQL Editor de ASE Work - Pruebas. No ejecutar el instalador completo sobre la base ya migrada.
2. Recargar la aplicación. Terminar los fichajes abiertos antes de cambiar de modo.
3. En Configuración / modo tablet, desactivar el modo exclusivo mediante su botón. El servidor rechaza el cambio mientras haya fichajes abiertos. Mientras ese modo esté desactivado no se podrá iniciar/finalizar desde el punto compartido.
4. Registrar en Accesos y credenciales / Tarjetas asociadas a tareas una tarjeta por su UID físico y asignarla a una tarea de ensayo. No sobrescribir el contenido de la tarjeta.
5. En Configuración / métodos de fichaje, habilitar NFC para esa tarea. Asignarla a un empleado de pruebas.
6. En otro navegador del Android, iniciar sesión con ese empleado y abrir la tarea. No utilizar la pestaña configurada como punto compartido: esa pestaña conserva su sesión de punto.
7. Leer y cancelar: debe haber cero escrituras. Leer y confirmar inicio: un registro abierto. Leer otra vez sin confirmar: sigue abierto. Confirmar finalización: mismo registro cerrado.
8. Verificar en Fichajes un solo registro del empleado con método NFC y horas correctas. Probar también tarjeta errónea y otra cuenta sin asignación.
9. Para retomar las pruebas de planificación e incidencias del punto compartido, cerrar todos los fichajes de ensayo y activar otra vez el modo tablet.

## Alcance de seguridad y pruebas
La lectura utiliza el UID que comunica el navegador; no es una prueba criptográfica de presencia ni una protección contra clonación de tarjetas. El servidor verifica empresa, cuenta autenticada, asignación, tarjeta activa, método habilitado y acción solicitada. No se amplían permisos sobre esquemas gestionados por Supabase. La instalación se prueba sin superusuario y deja retirado CREATE del rol interno. Las pruebas automatizadas usan datos y lectores simulados; no sustituyen la prueba física.


## Carga de tarjetas y tareas
La administración obtiene las tarjetas y el catálogo de tareas en dos consultas protegidas por la empresa seleccionada, sin depender de una relación embebida ambigua entre las claves antiguas y las compuestas. Los nombres se relacionan por el identificador de tarea. Un fallo muestra un error con reintento y no se presenta como cero tarjetas; no permite registrar nuevas tarjetas mientras falla la carga.
