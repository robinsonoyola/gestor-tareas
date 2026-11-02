# Despliegue y recuperación de ASE Work

## Principios

- Desarrollo, pruebas y producción son entornos diferentes.
- Nunca usar `service_role` en el frontend.
- Toda actualización comienza con una copia verificable.
- La base y el frontend deben poder volver a su versión anterior.
- Los archivos de clientes no se incluyen en repositorios ni registros de soporte.

## Empresa nueva

1. Crear el proyecto Supabase y el primer usuario confirmado.
2. Generar el paquete con `npm run package:database`.
3. Configurar los tres marcadores de `deployment/generated/instalacion-nueva-plantilla.sql`.
4. Ejecutar la instalación completa en SQL Editor.
5. Ejecutar `activar-automatizaciones.sql`.
6. Ejecutar `verificar-instalacion.sql`.
7. Generar las funciones con `npm run package:functions` y desplegarlas con sus nombres exactos.
8. Configurar `ALLOWED_ORIGINS` solo con dominios HTTPS autorizados.
9. Publicar el frontend con URL y clave anon del proyecto correspondiente.
10. Crear un empleado de ensayo, una tarea, una planificación y un fichaje completo antes de entregar.

## Actualización

1. Anunciar una ventana breve sin cambios administrativos.
2. Crear una copia de PostgreSQL y verificar que puede leerse.
3. Respaldar por separado el bucket privado.
4. Registrar commit, manifiesto y hash del paquete.
5. Ensayar la actualización sobre una restauración.
6. Aplicarla en una sola transacción.
7. Ejecutar el verificador y una prueba de humo por rol.
8. Vigilar errores, cron y fichajes durante la ventana posterior.

## Vuelta atrás

Si la transacción SQL falla antes de `COMMIT`, no continuar con fragmentos: corregir el paquete y repetir sobre una restauración limpia. Si el fallo se descubre después:

1. Detener nuevas escrituras.
2. Conservar registros y hora exacta del incidente sin incluir secretos.
3. Restaurar base y Storage del mismo punto temporal.
4. Volver a publicar el frontend compatible con esa copia.
5. Ejecutar verificación y prueba de humo.
6. Documentar causa, alcance y acciones preventivas.

## Copias mínimas recomendadas

- Copia diaria de PostgreSQL.
- Copia periódica del Storage privado.
- Conservación diaria, semanal y mensual definida por contrato y normativa.
- Ensayo programado de restauración, no solo comprobación del archivo.
- Cifrado y acceso limitado a responsables autorizados.

## Diagnóstico respetuoso con la privacidad

Recoger fecha, entorno, organización técnica, ruta, código de error y un identificador de operación. No pedir contraseñas, JWT, service_role, contenido de archivos laborales ni volcados completos de clientes para resolver un problema ordinario.

Ejecutar `deployment/generated/comprobar-salud.sql` en el editor SQL del entorno afectado. Este diagnóstico solo devuelve contadores y estados técnicos. Permite revisar las dos automatizaciones, sus fallos durante las últimas 24 horas, recurrencias con error, fichajes abiertos durante más de 24 horas, empresas sin propietario y la configuración privada del almacenamiento.

## Prueba de humo posterior

- Login y selección de empresa.
- Alta de empleado.
- Creación y planificación de tarea.
- Inicio y cierre respetando orden.
- Evidencia y checklist.
- Incidencia bloqueante.
- Informe y exportación.
- Repetición y jobs activos.
- Acceso denegado desde otra empresa.
