# Ajustes de funcionamiento de ASE Work

## Estado de entrega

Preparados en la copia de código de pruebas. No instalados todavía en la base Supabase. El servidor actualmente abierto sirve la compilación anterior hasta que se reinicie. No se han modificado el código ni la conexión del proyecto original del Escritorio.

Las seis hojas de estilo y archivos de marca incluidos en la referencia visual conservan su SHA-256. No se han modificado colores de marca, fuentes, logo, reglas CSS ni puntos de adaptación a móvil. Los controles nuevos utilizan los componentes y clases existentes. La interfaz tiene nuevos elementos funcionales, por lo que no se afirma que su marcado HTML sea idéntico al anterior.

## Navegación y uso diario

- Revisar este día y elegir un día del calendario cargan la fecha y, cuando llegan sus datos, desplazan el panel hasta su detalle y colocan allí el foco. La fecha aparece en el encabezado del orden.
- Atrás en la estructura común de las pantallas, con regreso al inicio propio cuando no hay una ruta anterior interna. En el punto compartido se vuelve al inicio del punto, no a la administración. Las páginas públicas de contraseña y error mantienen una salida explícita.
- Tarea activa primero en Mis tareas. Los números y prioridades originales se conservan: mostrarla primero no reordena la planificación del administrador. Filtros de pendientes, en curso, completadas y bloqueadas.
- Icono para mostrar u ocultar el valor que se está escribiendo en los campos de contraseña. No permite consultar contraseñas ya guardadas.

## Búsqueda por palabras

Disponible en Inicio y Mis tareas tras instalar el SQL. Busca automáticamente al escribir, con una breve espera; también admite el botón Buscar. Ignora respuestas que llegan tarde de búsquedas anteriores.

Expresiones reconocidas: tarea iniciada, en curso, en progreso, pendientes, completadas, bloqueadas, incidencias pendientes o resueltas, personas y empleados. Los otros términos se combinan: piscina Juan busca ambos. Se normalizan mayúsculas y acentos. Es un buscador con sinónimos definidos, no una promesa de comprender cualquier frase mediante IA.

Resultados agrupados de tareas, personas e incidencias, hasta 100 por grupo. Se aplican los permisos y la empresa seleccionada en la base de datos; una coincidencia no concede permiso para abrir otra tarea.

## PIN personal y tarjetas

- La tarjeta NFC conserva su código largo. El PIN manual es independiente y sirve cuando no se lleva tarjeta.
- En la tablet se elige el empleado y se introducen cinco dígitos. Ningún PIN inicia ni finaliza automáticamente el trabajo.
- Administración puede introducir un PIN propio, generar uno o desactivarlo. El código se muestra solo al crearlo o reemplazarlo. En la base se guarda un hash con sal bcrypt, no el PIN recuperable.
- Cinco fallos bloquean el PIN durante 15 minutos. También existe un límite de 20 fallos por punto en una ventana de 15 minutos. Un reinicio del navegador no borra estos contadores.
- Cambiar o desactivar el PIN invalida la confirmación de los tickets pendientes asociados al PIN anterior. No modifica la tarjeta NFC.
- El registro distingue la entrada por PIN, código manual de tarjeta o lectura NFC declarada por el navegador. La etiqueta NFC no es una prueba criptográfica de presencia física ni impide copiar el contenido de una tarjeta.

Importación Excel XLSX o CSV: primera hoja, columnas empleado y pin, hasta 200 filas, archivo de hasta 5 MB. Empleado es el correo o UUID del empleado dentro de esa empresa. Se deben guardar los PIN como texto para conservar ceros iniciales. Se muestran empleados reconocidos y errores antes de aplicar. El servidor vuelve a validar al confirmar y rechaza archivos con filas duplicadas, empleados de otra empresa o PIN de longitud incorrecta. No se ejecutan fórmulas; se rechazan libros con fórmulas. El formato XLS antiguo y libros cifrados no se admiten. No se añadió una dependencia de Excel al proyecto original.

## Incidencias y áreas

Equipo incluye Áreas y responsables. Se administran por separado de los roles de autorización.

En una tarea disponible, el empleado puede indicar título, descripción, área o persona, y hasta tres imágenes de 5 MB. Solo puede adjuntar archivos propios de esa tarea. Los responsables activos reciben una notificación interna de ASE Work. La campana se actualiza cada 30 segundos y al recuperar el foco; no implica correo, notificación push ni aviso fuera de la aplicación.

La incidencia tiene estados abierta, en atención y resuelta. El autor, el responsable, los miembros del área y administración pueden consultar lo que les corresponde. Gestionarla o resolverla requiere ser responsable, miembro del área o administrador. La resolución necesita una explicación y notifica al autor.

El empleado puede indicar explícitamente que el problema impide continuar. En ese caso se cierra su contador y la planificación queda **bloqueada**, sin contabilizarse como completada. El motivo y la identidad quedan registrados. Las fotos de la incidencia siguen disponibles para sus destinatarios y el autor, incluso después del bloqueo, con enlaces firmados y sin volver público el depósito.

Resolver una incidencia no marca la tarea como completada ni reinicia el fichaje. El administrador debe revisar la continuación y su planificación.

## Cierre administrativo

En Fichajes, solo administración puede finalizar por un empleado una tarea en curso, indicando un motivo y confirmando. Se conserva la hora real del cierre; no se inventa una hora retroactiva. Hay un historial de los últimos 50 cierres administrativos y bloqueos por incidencia, con actor, empleado y motivo.

Las comprobaciones se ejecutan en la base de datos, no solo ocultando botones. El modo tablet sigue impidiendo que el empleado finalice una tarea desde su móvil.

## Verificación realizada

- 62 comprobaciones aisladas en PostgreSQL, incluyendo conservación de datos de referencia, límites entre dos empresas, PIN, bloqueos, importación, lectura de adjuntos por responsables, notificaciones, cierre administrativo y NFC con confirmación explícita.
- 11 escenarios de navegador con componentes React reales y servicios sintéticos: visibilidad de contraseña, búsqueda automática y respuestas tardías, CSV, XLSX comprimido, rechazo de fórmulas, ceros iniciales, prioridad visual de tarea activa, filtros, desplazamiento al detalle, incidencia y cierre con motivo. Incluyen 24 combinaciones de pantalla/tamaño sin desbordamiento horizontal del documento: 320, 390, 768 y 1440 px.
- Las 114 comprobaciones originales también pasan después de aplicar ambas migraciones en la base aislada.
- Instalador combinado comprobado: un fallo inyectado revierte ambas migraciones; sin el fallo se instalan ambas.
- Compilación Vite y comprobaciones de búsquedas y archivos.
- Comparación SHA-256 de los seis archivos visuales originales, sin cambios.

Los escenarios de navegador no equivalen a una prueba física de todos los dispositivos. Falta instalar en Supabase de pruebas, probar con JWT reales, repetir la lectura NFC física con las funciones nuevas y verificar roles y dos empresas allí. La recuperación de contraseña y el fallo intermitente de comprobación de empresa siguen pendientes; no se dan por resueltos mediante estos ajustes.

## Activación

El paquete `work/core-multitenancy-a1/deployment` contiene instrucciones, las dos funciones externas preparadas como archivos únicos, el SQL combinado y el instalador con copia previa y validación del destino. Incluye la migración por empresa porque los nuevos registros de PIN, áreas, incidencias y notificaciones ya deben nacer separados por empresa.

No se ha ejecutado ese instalador remoto ni creado un commit o publicado cambios del proyecto original.


## Identificación sin selector de método
El punto mantiene el lector NFC y un campo de código. Un PIN de cinco dígitos identifica automáticamente al empleado, sin seleccionar nombre ni método. La migración 20261022000400 añade búsqueda acotada a la empresa y conserva el límite de intentos del punto. Los nuevos PIN activos no pueden duplicar otro PIN activo en la empresa. Ante PIN históricos duplicados, la identificación automática se rechaza sin escoger una identidad. Los códigos siguen cifrados mediante hash bcrypt; la búsqueda verifica esos hashes. La lectura NFC y la introducción del PIN nunca confirman por sí mismas un inicio o cierre. Ejecutar deployment/activar-codigo-automatico.sql en pruebas antes de usar la nueva pantalla.


## Clave manual al crear un punto (23 de octubre)
En Puntos de fichaje se puede escribir una clave propia de 8 a 128 caracteres o dejar el campo vacío para generación automática. Solo administración puede crear puntos. La clave configura el dispositivo y es independiente del PIN de empleados y de las tarjetas NFC. Las claves repetidas se rechazan sin revelar el punto ni la empresa que las utiliza. Los puntos existentes mantienen sus claves. Para activar esta ampliación en la base ya instalada de pruebas, ejecutar deployment/activar-clave-manual-punto.sql, sin repetir el instalador completo. Pendiente prueba manual alojada.
