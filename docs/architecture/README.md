# Documentos de arquitectura

Esta carpeta conserva decisiones y comprobaciones acumuladas durante el desarrollo de ASE Work. Muchos archivos describen el estado exacto de una entrega intermedia y pueden contener frases como «activación pendiente» o nombres de antiguos activadores incrementales.

Esas indicaciones se conservan como historial técnico, pero **no son instrucciones vigentes de despliegue**.

Para instalar, actualizar o verificar la versión actual deben utilizarse exclusivamente:

- `deployment/README.md`;
- los archivos generados en `deployment/generated`;
- `docs/architecture/ENSAYO-Y-ACTIVACION.md`;
- `docs/operations/DESPLIEGUE-Y-RECUPERACION.md`;
- `docs/operations/CONTROL-VERSION-CANDIDATA.md`.

Las migraciones de `supabase/migrations` son la fuente oficial. No se deben ejecutar activadores históricos sueltos ni repetir parcialmente un instalador para intentar corregir un fallo.
