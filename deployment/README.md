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
- `manifest.json`, con inventario, primera y última migración y SHA-256.

Este archivo sirve únicamente para actualizar una copia de la base heredada capturada el 22/10/2026. No es todavía el alta de una empresa nueva y no debe ejecutarse sobre una base ya actualizada. Antes de usarlo se exige copia verificada y ensayo en un entorno restaurado.

Una instalación nueva tendrá su propio bootstrap y reutilizará después exactamente esta misma secuencia de migraciones. No se mantendrá una segunda lista manual.
