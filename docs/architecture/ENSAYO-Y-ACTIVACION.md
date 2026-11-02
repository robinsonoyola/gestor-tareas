# Ensayo alojado y activación

Este procedimiento corresponde al paquete completo actual. No aplicar migraciones sueltas ni usar el baseline manualmente en Supabase.

## Proyecto temporal vacío

1. Crear un proyecto Supabase gratuito vacío y distinto de producción.
2. Crear y confirmar en Authentication el usuario que será propietario.
3. Ejecutar `npm run test:release` en la copia candidata.
4. Generar el paquete con `npm run package:database`.
5. Configurar únicamente los tres marcadores de `deployment/generated/instalacion-nueva-plantilla.sql`.
6. Ejecutar ese instalador completo una sola vez en el proyecto vacío.
7. Ejecutar `deployment/generated/activar-automatizaciones.sql`.
8. Desplegar las dos funciones de `deployment/generated/functions` y configurar `ALLOWED_ORIGINS` con el origen de ensayo.
9. Ejecutar `deployment/generated/verificar-instalacion.sql`, `deployment/generated/comprobar-salud.sql` y `supabase/tests/verify-installed.sql`.

El baseline y `bootstrap.sql` pertenecen exclusivamente a las pruebas aisladas. No deben pegarse por separado en Supabase.

## Restauración de una copia

La restauración se realiza en otro proyecto vacío, nunca sobre el origen. Usar las utilidades y confirmaciones descritas en `docs/operations/DESPLIEGUE-Y-RECUPERACION.md`. Después de restaurar, repetir las tres verificaciones alojadas y la prueba de humo.

## Prueba funcional alojada

- Crear administrador, encargado y empleados sintéticos.
- Crear áreas, tarea, pasos, evidencias y planificación.
- Confirmar que la importancia no modifica el orden de ejecución.
- Iniciar, pausar, reanudar y cerrar fichajes respetando el orden.
- Revisar incidencias, comentarios, archivos, repeticiones y notificaciones.
- Archivar y restaurar una actividad; comprobar que no aparece en nuevos selectores mientras está archivada.
- Descargar y abrir CSV y Excel.
- Probar recuperación de contraseña con correo real cuando se autorice.
- Probar móvil, tablet y NFC cuando estén disponibles.

## Aislamiento real

Crear una segunda empresa y usuarios exclusivamente sintéticos. Comprobar con sesiones diferentes que REST, RPC, Storage y funciones administrativas no permiten leer ni modificar datos ajenos. El filtrado visual por sí solo no acredita aislamiento.

## Condición de cierre

Registrar fecha, commit, manifiestos, resultados y cualquier incidencia. Un fallo se corrige en código o migración y se repite desde un proyecto limpio; no se salta manualmente una restricción. El proyecto de producción no participa en este ensayo.
