# Informes y análisis y buscador de registros

La nueva ruta /admin/reports exige reports.view en el navegador y en el servidor. Reúne tablas de fichajes, tareas por asignación/planificación, productividad por empleado/tarea/día de inicio, incidencias y cierres/bloqueos. Las secciones operativas anteriores se mantienen.

Filtros de fechas (Madrid, máximo 366 días), texto y, donde procede, estado y método. Las columnas se ordenan sobre el conjunto completo cargado, con paginación visual de 50 filas. Excel y CSV incluyen todas las filas filtradas y ordenadas. Los informes superiores a 10.000 filas se rechazan con un mensaje para reducir el rango, sin truncamiento silencioso. Productividad incluye solo fichajes terminados con duración válida; no mide calidad. Tareas sin planificación se incluyen por fecha de creación.

El historial de fichajes incorpora búsqueda en servidor antes de contar/paginar, además de método y estado. En la vista personal se ignora cualquier usuario solicitado y se utiliza siempre la identidad autenticada. El RPC anterior se conserva sin cambiar su firma. La descarga antigua del historial sigue indicando expresamente que contiene una página; el apartado Informes ofrece la descarga completa.

Exportación XLSX mediante contenedor OOXML/ZIP con CRC, texto inline y números tipados. No se generan fórmulas a partir del contenido del usuario. CSV protegido frente a prefijos de fórmula. Los archivos no incluyen claves, PIN, correos ni datos de autenticación.

Activación confirmada por el usuario en ASE Work - Pruebas: los informes muestran datos. Para otras instalaciones, ejecutar solo deployment/activar-informes-y-buscador.sql; no repetir el instalador completo.

Verificación: compilación correcta; 107 comprobaciones SQL acumuladas, incluyendo permisos, aislamiento, búsqueda, filtros, ámbito personal y límite de filas; seis comprobaciones Chromium de tablas/ordenación/exportación/filtros/responsivo y tres del buscador del historial. Exportación de 125 filas comprobada mediante bytes ZIP/XML, CRC, orden y celdas numéricas. La descarga nativa en el navegador automatizado fue cancelada por el entorno; queda pendiente comprobar guardar/abrir el archivo en el móvil o PC real tras la activación. No se han modificado datos alojados.


## Tablas dinámicas y filtro compartido de empleado

La vista inicial es una tabla dinámica configurable: dimensión de filas, dimensión de columnas y medida (recuento, minutos totales o media; en productividad también fichajes terminados). Los totales de medias se ponderan por la cantidad de fichajes; no se suman medias. La comparación mensual incluye meses sin actividad en el período, con cero para recuentos/sumas y sin media inventada. Hasta 100 columnas; se solicita reducir el rango o cambiar de agrupación si se supera.

El filtro Empleado se conserva al cambiar de conjunto de datos o de vista (registros/tabla dinámica). Se aplica en SQL antes de devolver los registros, junto a fechas, búsqueda, método y estado. Las incidencias incluyen las comunicadas por esa persona y las asignadas directamente o a su área; cierres filtra por el empleado afectado. No permite ver miembros de otra empresa.

Ejemplo validado: Productividad de Pepe, 1 marzo–31 mayo, filas Tarea, columnas Mes y valores minutos o media. El Excel/CSV exporta el resultado calculado de la configuración actual, incluido total general; no un objeto PivotTable nativo de Excel. Ver registros permite exportar los datos de origen.

Activación: el archivo actualizado deployment/activar-informes-y-buscador.sql incluye la búsqueda, las tablas y el filtro de empleado; admite aplicación inicial y actualización del archivo anterior de informes mediante CREATE OR REPLACE. No repetir el instalador completo. Comprobadas 117 aserciones SQL acumuladas, incluyendo aplicación dos veces del activador; prueba matemática de la tabla dinámica y cinco pruebas Chromium del ejemplo Pepe/marzo-mayo, persistencia del filtro y exportación de totales. Pendiente guardar/abrir archivo en un dispositivo real.


Productividad conserva su pantalla original de gráficos y resumen. Su acceso está dentro de Informes y análisis, junto al botón de la tabla Productividad; se retira la entrada independiente del menú lateral. Compilación completada tras el ajuste.
