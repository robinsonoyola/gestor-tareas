# Ensayo y activación pendiente

La migración no está instalada. No ejecutar el baseline ni la migración directamente en producción para intentar completar una prueba.

1. Disponer de un backup completo recuperable de la base y de los archivos de Storage. Comprobar restauración en un proyecto Supabase separado; el inventario JSON no sustituye ese backup.
2. Comprobar que no se han instalado cambios nuevos desde el inventario. La migración se detiene si cambian las definiciones de RPC o policies.
3. En la copia de ensayo, aplicar la única migración atómica `supabase/migrations/20261022000100_core_multitenancy_a1.sql`. El archivo de baseline sirve solo para reconstrucción de bases vacías y tests; no se aplica sobre tablas existentes.
4. Desplegar en ese proyecto create-employee y la sustitución de update-employee-email. Configurar los secretos exclusivamente de servidor y ALLOWED_ORIGINS con los orígenes reales de la aplicación de ensayo. No copiar service_role a un archivo VITE.
5. Usar la aplicación contra esa copia y verificar: administrador inicial, empleado inicial, orden diario, inicio/consulta/fin de tablet, notas, fotos, vídeos, QR/enlaces, cambio de correo, recuperación, roles, exportaciones y gráficos.
6. Crear una segunda organización de ensayo y usuarios sintéticos. Ejecutar ataques con sus JWT reales contra REST, RPC, Storage y los dos servicios de identidad, incluyendo una identidad en ambas empresas. No basta con que el selector visual filtre datos.
7. Ejecutar `supabase/tests/verify-installed.sql`, revisar el informe de seguridad y hacer auditoría externa. Comparar registros, relaciones y archivos antes/después del ensayo.
8. Solo con el ensayo aprobado, programar el corte de producción y repetir backup y verificación. Durante el corte evitar escrituras concurrentes y recargar las sesiones al finalizar. El código cliente es compatible con el estado anterior mientras no exista mt_context, pero no debe mezclarse un backend migrado con servicios de identidad antiguos sin revisar.

Si falla la transacción, no continuar con escrituras manuales para saltar un constraint: revisar la causa y reconciliar los registros conservando su historial. Los tests comprueban que relaciones antiguas incoherentes provocan rollback.

La reversión de un ensayo sin nuevas escrituras consiste en restaurar la copia verificada y el código anterior. Si ya se han creado organizaciones o registros nuevos, no quitar organization_id ni eliminar tablas como rollback: preparar recuperación o corrección hacia delante sin perder esos datos.

## Reconstrucción local de pruebas

`bootstrap.sql` solo se ejecuta en la base aislada creada por PGlite. No se debe pegar en Supabase: simula roles y tablas gestionadas de Auth/Storage.

El baseline conserva el esquema público capturado y sus funciones originales. Los tests lo cargan, insertan identidades y datos sintéticos y después aplican la migración completa. Esta reconstrucción no replica configuración SMTP, Auth, Storage físico ni los roles internos exactos del alojamiento.
