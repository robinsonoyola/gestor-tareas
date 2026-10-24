# Repeticiones de tareas — 24/10/2026

## Alcance
Planificación → Repeticiones. Reglas diarias, semanales, mensuales y anuales, intervalo entero de 1 a 365 unidades. Un encargado activo, previamente asignado a la tarea. Una regla por tarea y empleado. La primera fecha se indica explícitamente (hoy o futura, hasta diez años). No convierte automáticamente las etiquetas daily/weekly/monthly antiguas en reglas: evita generar trabajo inesperado.

Fecha fija: calcula desde el ancla original, sin deriva de fin de mes. 31/01 → 28/02 → 31/03; 29/02 anual se ajusta al último día válido en años no bisiestos. Desde finalización: espera a que el plan se complete realmente; un bloqueo no avanza el plazo. Reabrir y cerrar una ejecución ya registrada no vuelve a modificar la siguiente fecha. Cada plan y fichaje conserva su historial y checklist de ejecución.

Ejemplo piscina: última limpieza 23/10/2026; configurar próxima fecha 23/10/2027, cada 1 año, calendario fijo y aviso 15 días antes. No se fabrica ni altera el fichaje de 2026.

## Generación y avisos
Se preparan los planes dentro de un horizonte de max(30, días de aviso), anexándolos al orden del empleado. Si ya existe el mismo plan tarea/persona/fecha, se reutiliza sin cambiar su prioridad ni estado. Los reintentos no duplican planes ni avisos. El modo desde finalización mantiene una ejecución pendiente a la vez. Si la asignación deja de existir o el encargado está inactivo, se muestra un error y no se reasigna trabajo silenciosamente. No se inicia ningún fichaje al generar un plan.

Los avisos son internos de ASE Work y aparecen en la campana y en Incidencias y notificaciones; no se envía correo ni push externo. Cada ejecución recibe un solo aviso al entrar en su plazo; las completadas no reciben avisos nuevos. La primera activación recupera fechas pendientes sin cambiar a hoy sus fechas originales. Más de 400 ejecuciones pendientes por regla exige revisión, no se omite el historial.

Pausar evita nuevas generaciones y avisos. Conserva los planes ya generados y el historial. Reactivar no descarta fechas pendientes. En esta entrega la configuración de la regla queda fijada al crearla: se puede pausar/reactivar, pero no editar intervalos ni trasladar el encargado desde esta pantalla. La frecuencia semanal usa el día de la primera ejecución, no varios días de la semana.

## Seguridad
Tablas con RLS y FK compuestas de organización. Lectura requiere planning.view y cambios planning.edit, en servidor. Funciones públicas con propietario ase_tenant_executor y search_path vacío. Worker interno privilegiado, inaccesible a anon/authenticated, con filtros explícitos por organización en todas las consultas de negocio. Se bloquea primero al empleado y después a la regla, como los fichajes. Bloqueo asesor por organización serializa el proceso. Trigger solo adelanta la regla cuando se completa el plan asociado y no al bloquearlo.

## Activación inicial confirmada por el usuario en ASE Work - Pruebas
1. Ejecutar deployment/activar-repeticiones.sql en SQL Editor. Actualización transaccional, sin repetir instalador completo.
2. Ejecutar deployment/activar-automatizacion-repeticiones.sql como postgres. Activa pg_cron y crea/reemplaza un trabajo horario al minuto 17 UTC, con cálculo de fechas Europe/Madrid. Sin contraseñas ni tokens almacenados. Ejecuta una primera pasada. Si cron no se activa, la interfaz lo advierte; Preparar próximas ejecuciones permite una pasada manual autorizada.
3. Confirmar jobname ase-work-recurrences, active true. La aplicación mostrará el estado de activación.

El worker continúa ejecutándose con el navegador cerrado si pg_cron está activado y la base de datos está disponible. No funciona durante una suspensión del proyecto; al reanudar recupera los pendientes. Los planes generados conservan las restricciones NFC/orden/pasos existentes.

## Validación
193 aserciones acumuladas en PostgreSQL sintético, incluidas 17 de recurrencias: fecha anual, aviso, no duplicación, pausa, plazo desde cierre real, bloqueo, reapertura, fin de mes, bisiestos, permisos y separación de empresas. Seis comprobaciones de interfaz: formulario anual, aviso de cron no activo, búsqueda, pausa confirmada, error sin perder formulario y ancho móvil. Compilación verificada. Sin escrituras en Supabase alojado ni nuevas pruebas físicas NFC. Activación real de pg_cron pendiente del usuario.


## Ampliación: responsabilidad por área
Nueva opción Empleado / Área. Una regla por área mantiene user_id nulo; cada vencimiento crea una entrada pendiente de asignación, sin fichaje, plan de empleado ni elección automática de una persona antigua. Administración y los miembros activos del área reciben un aviso interno en la fecha de aviso. Sin miembros, administración sigue recibiéndolo. El área queda visible en el buscador y la tarjeta.

En Repeticiones, expandir Ejecuciones y pendientes de asignación, elegir un empleado actual del área y confirmar Asignar ejecución. Requiere planning.edit; ser miembro del área por sí solo no concede permisos de planificación. Se crea la asignación de la tarea y un plan al final del orden del día, o se reutiliza el mismo plan si ya existe. Se guardan assigned_by y assigned_at. Un reintento para la misma persona no duplica el plan ni la notificación; otro destinatario exige revisar la planificación. Empleados inactivos o ajenos al área son rechazados en servidor.

La siguiente repetición del área vuelve a quedar sin persona, aunque la anterior la ejecutase alguien concreto. Desde finalización espera al cierre real del plan asignado; un bloqueo no avanza. Un plan no puede apropiarse de una ejecución de otra regla. Se conserva el historial previo de reglas individuales y el trabajo cron existente.

Para reglas individuales, si el encargado pierde la membresía activa o la asignación de la tarea, se registra error y se avisa a administradores una vez por cambio de error, sin inundar la campana en cada pasada. No se asigna automáticamente a otra persona.

Activación adicional pendiente: deployment/activar-repeticiones-por-area.sql. No repetir las dos activaciones iniciales ni configurar cron otra vez. La ampliación tiene tablas con RLS, claves de organización y validación de permisos y pertenencia. Ninguna escritura alojada realizada por el agente. Pruebas SQL de separación, permisos, empleado inactivo, recordatorios sin duplicar, asignación idempotente, siguiente fecha sin empleado heredado y reactivación de migración; ocho comprobaciones de interfaz y compilación.
