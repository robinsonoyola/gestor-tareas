# Paquetes de base de datos de ASE Work

Las migraciones de `supabase/migrations` son la fuente oficial y se ejecutan por nombre, en orden ascendente.

## Comprobar que ninguna migración queda fuera

```powershell
npm run test:database-package
```

La comprobación falla si una migración no tiene versión, si dos comparten versión o si sus límites de transacción no son seguros para generar el paquete.

## Generar la actualización heredada

```powershell
npm run package:database
```

Genera en `deployment/generated`:

- `actualizacion-completa.sql`
- `instalacion-nueva-plantilla.sql`
- `manifest.json`, con inventario, primera y última migración y SHA-256.

Este archivo sirve únicamente para actualizar una copia de la base heredada capturada el 22/10/2026. No es todavía el alta de una empresa nueva y no debe ejecutarse sobre una base ya actualizada. Antes de usarlo se exige copia verificada y ensayo en un entorno restaurado.

## Instalar una empresa nueva

`instalacion-nueva-plantilla.sql` parte de un proyecto Supabase vacío y reutiliza exactamente la misma secuencia de migraciones. Antes de ejecutarlo:

1. Crear y confirmar en Supabase Authentication el usuario propietario.
2. Sustituir en el SQL `__ASE_OWNER_EMAIL__`, `__ASE_COMPANY_NAME__` y `__ASE_COMPANY_SLUG__`.
3. Mantener `task-files` privado y no introducir claves `service_role` en el frontend.
4. Ejecutar el archivo completo una sola vez. Todo se confirma o revierte en una única transacción.

El instalador se detiene si queda un marcador sin sustituir, el correo no corresponde exactamente a un usuario Auth o el identificador de empresa no es válido. Al terminar, ese usuario queda como propietario activo.
