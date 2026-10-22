# CORE-MULTITENANCY-A1

Fecha: 22 de octubre de 2026. Estado: **PARTIAL**. Código y migración preparados y probados localmente; no instalados en Supabase.

## 1. Summary

Se implementa una primera frontera de organización para ASE Work, conservando sus acciones, rutas, orden diario, tablet compartida, comentarios, adjuntos, informes, colores, tipografía y logo. La autorización de empresa se exige en PostgreSQL, no solo en React.

El inventario proporcionado contiene 17 tablas públicas de aplicación, 60 funciones públicas y 37 policies entre public y storage. Se reconstruyó el esquema empresarial capturado para las pruebas. No es una copia de los registros ni de los servicios gestionados de Supabase.

## 2. Files Changed

- `supabase/baseline/20261022_installed_public.sql`: esquema empresarial anterior, reconstruido a partir del inventario. Solo referencia histórica y preparación de bases vacías de ensayo; **no ejecutar sobre la base existente**.
- `supabase/migrations/20261022000100_core_multitenancy_a1.sql`: migración atómica con preflight de definiciones de RPC y policies, tablas de organizaciones, backfill, integridad, RLS, RPC y servicios de identidad.
- `supabase/functions/_shared/tenant.ts`: validación de JWT con Auth, organización y administrador; CORS con orígenes explícitos.
- `supabase/functions/create-employee/index.ts`: alta con comprobación de identidad nueva y pertenencia por servicio autorizado.
- `supabase/functions/update-employee-email/index.ts`: sustitución propuesta del servicio no disponible localmente; limita cambios administrativos a identidades de una sola organización.
- `supabase/tests/`: esquema sintético de Auth/Storage, regresiones y aislamiento, transporte de contexto, fallos de migración, resultados y dependencia bloqueada de PGlite.
- `src/lib/organizationScope.js`, `src/components/auth/OrganizationProvider.jsx`: contexto, limpieza de peticiones y revalidación de permisos.
- `src/hooks/useAuth.js` y `useLegacyAuth.js`: autorización por membresía con compatibilidad explícita antes de instalar la migración.
- `src/lib/supabase.js`, `createEmployee.js`, `passwordRecovery.js`: envío de contexto y contratos de empleados por organización.
- `src/main.tsx`, `src/App.tsx`, `ProtectedRoute.jsx`: proveedor y desmontaje de vistas al cambiar de empresa, manteniendo BrowserRouter.
- `Layout.jsx`, `OrganizationSelector.jsx`, `OrganizationChoice.jsx`: selector solo cuando hay varias empresas y elección cuando no existe contexto válido.
- `Login.jsx`, `EmployeeManager.jsx`, `TaskAccessLogin.jsx`: lectura de perfil empresarial, empleados y resolución segura de enlaces.

No se modifican los archivos CSS ni los recursos de public. La comparación del Layout renderizado con datos sintéticos conserva el mismo marcado en modo anterior y con una sola organización, normalizando únicamente identificadores generados por React.

## 3. Database Changes

`organizations`: UUID, nombre, slug único, estado active/suspended y fechas. `organization_memberships`: identidad de auth.users, organización, rol owner/admin/member, estado active/invited/disabled y datos laborales de nombre/WhatsApp. La combinación organización/usuario es única.

Se añade organization_id obligatorio a 16 tablas empresariales: tasks, task_assignments, checkins, task_comments, task_access_codes, task_checkin_config, nfc_cards, work_day_plan, work_employee_cards, work_employee_card_keys, work_stations, work_station_keys, work_station_tickets, work_roles, work_employee_roles y work_settings.

La identidad global permanece en auth.users y public.users. La vista privada employee_profiles combina identidad con datos laborales de la organización. No se convierte auth.users en empleado.

Las FK compuestas impiden relacionar tarea, plan, punto, tarjeta, empleado, comentario, clave y rol de empresas distintas. Se verifica también la coherencia usuario/tarea del plan y usuario de la tarjeta. La inserción y reasignación de registros de empleados requiere membresía activa; la desactivación conserva el historial.

El modo tablet, los roles por empleado, el nombre de rol, la tarjeta activa y la tarea activa pasan a tener alcance por organización. Los códigos secretos mantienen unicidad global para evitar una credencial ambigua; el UID de las etiquetas de tarea se registra por organización.

Índices: organization_id para las fronteras RLS, membresías por usuario/estado/organización, planificación por organización/empleado/día e historial por organización/inicio. Se conservan los índices anteriores compatibles; no se añaden índices de futuros módulos.

## 4. RLS Changes

Cada tabla empresarial incorpora una policy **restrictive** que exige la organización validada en servidor tanto en USING como en WITH CHECK. Las reglas funcionales de detalle de tarea, comentarios, fichajes y archivos continúan aplicándose a las llamadas autenticadas.

Se sustituyen las policies permisivas antiguas que consultaban users.is_admin global por equivalentes que comprueban administración dentro de la organización. Se mantienen las restricciones existentes de tarea en curso. La inserción manual directa no puede fabricar referencias a punto, tarjeta personal o plan de tablet.

El rol interno ase_tenant_executor es NOLOGIN, NOBYPASSRLS y no posee tablas. No se concede a anon, authenticated ni authenticator. Las RPC empresariales ejecutan como ese rol, con una policy interna permisiva para conservar su lógica y una frontera restrictiva de organización que también las limita. El rol no puede actualizar la columna role de las membresías ni crear funciones después de la migración.

Este punto es esencial: una función SECURITY DEFINER propiedad del dueño de las tablas podría saltarse RLS. Cambiar únicamente policies no habría aislado las RPC existentes.

Se revocan privilegios innecesarios de anon y privilegios TRUNCATE/REFERENCES/TRIGGER de los roles de API sobre las tablas de negocio. public.users pasa a permitir lectura de identidad propia y cambios limitados de nombre/WhatsApp propios; los compañeros se obtienen por RPC empresarial.

Storage mantiene sus rutas y bucket privado. Las policies de archivos consultan asignaciones/tareas sometidas a la frontera empresarial. Se requiere comprobar el bucket y el transporte del contexto en el servicio Storage real durante el ensayo externo.

## 5. RPC Changes

Se conservan las firmas de las 60 funciones capturadas cuando pertenecen a los recorridos existentes. Las RPC de negocio pasan a ejecutar bajo el rol limitado por RLS. Los nombres laborales y las comprobaciones de administrador usan el perfil de organización, no el atributo global anterior.

Cambios específicos: scope compuesto en los upserts de planificación y rol; contexto de estación derivado de su clave en las tres RPC anónimas; membresía activa del empleado de tablet; comprobación de pertenencia/asignación en work_can_detail; schema explícito en el trigger de configuración automática de tarea. Se endurecen search_path y grants de los triggers nativos de Auth.

validate_nfc_checkin conserva p_user_id por compatibilidad, pero sigue rechazando cualquier valor distinto de auth.uid(). generate_task_access_code comprueba el administrador y la tarea dentro del contexto validado.

Funciones nuevas: mt_context, mt_create_organization, mt_employees, mt_employee_reset_target, mt_delete_employee, mt_attach_created_employee, mt_prepare_email_change, mt_email_change_grant, mt_finish_email_change, mt_resolve_task_access y mt_identity_email_exists.

Las funciones elevadas propiedad de postgres se limitan a helpers privados, triggers nativos de identidad, contexto propio, creación de organización para el actor, resolución de código asignado y operaciones de identidad expresamente autorizadas. Los endpoints de servicio requieren service_role y no admiten ejecución de authenticated/anon. Esa clave solo se obtiene de variables del servidor, nunca de Vite.

## 6. Migration

Una sola transacción valida que las definiciones de RPC y policies coinciden con el inventario recibido, crea la organización inicial ASE Work, traslada las pertenencias existentes, añade columnas nullable, hace el backfill y después aplica NOT NULL, FK, índices y RLS. No borra fichajes ni modifica su inicio, fin, método u orden.

Los administradores existentes se conservan como admin de la organización inicial. No se inventa un propietario distinto. El endpoint de creación de organizaciones genera owner para su propio actor autenticado.

Se retira el poder del atributo global users.is_admin poniéndolo a false después de trasladar la autorización. Sus valores originales se conservan en ase_private.legacy_admin_flags. Este cambio es deliberado y necesario; la interfaz recibe el mismo indicador de administrador, ahora derivado de su membresía.

Las pruebas comparan todos los campos anteriores de las 16 tablas empresariales antes/después, descontando exclusivamente la nueva columna de organización. También prueban que cambios de esquema y relaciones antiguas incoherentes detienen y revierten la transacción sin borrar datos.

No hay rollback automático que elimine empresas nuevas. Para recuperar un ensayo sin nuevas escrituras se restaura la copia verificada y el código anterior; después de admitir nuevas organizaciones se necesita un plan de recuperación o corrección hacia delante, sin descartar sus datos.

**No se ha ejecutado esta migración sobre la base real.**

## 7. Frontend

El servidor devuelve las organizaciones activas de la identidad. Una sola se selecciona automáticamente; varias requieren contexto válido y permiten cambiarlo. La preferencia se guarda por identidad en sessionStorage, independiente de otras pestañas. No es autorización.

El cliente envía x-ase-organization-id, pero el servidor vuelve a comprobar membresía y organización activas. La tablet usa su cliente anónimo separado y deriva la empresa de la credencial del punto; no depende de la selección del administrador.

Cambiar de empresa aborta peticiones pendientes, descarta respuestas obsoletas, retira canales y desmonta las vistas para limpiar formularios, modales, listados y temporizadores. Los permisos se vuelven a obtener y se revalidan cada 30 segundos/al recuperar foco.

Antes de instalar la migración, solo un error explícito de RPC inexistente permite el modo anterior. Un error de red o autorización no se convierte en permiso ni en administrador global. Una vez instalada, la frontera de base de datos no depende de ese mecanismo de compatibilidad.

El alta utiliza el nuevo servicio de servidor únicamente en modo multiempresa; en el estado anterior sigue el recorrido existente. Retirar a un empleado retira su acceso a esa empresa y sus roles vigentes, conservando su identidad y el historial de otras empresas. Los cambios administrativos de correo se rechazan si la identidad pertenece a varias empresas: su titular conserva la gestión de su cuenta global.

## 8. Security Tests

El detalle Test/Expected/Actual/PASS está en SECURITY-TESTS.md y los JSON de supabase/tests. Resultado local: 114 comprobaciones PostgreSQL, 8 de transporte de contexto, 3 escenarios de aborto/recuperación y 3 comprobaciones de marcado del Layout. El análisis de TypeScript de tres archivos de Edge Functions pasa; no equivale a ejecutar Deno o Auth HTTP.

Incluye miembros y administradores A/B, identidad compartida, administrador A que es solo miembro B, manipulación de cabecera/organization_id, CRUD cruzado, asignaciones inválidas, fotos privadas, rol delegado, código expirado por servidor, fichaje manual anterior, recorrido de tablet, reintento idempotente, credencial desactivada, membresía invitada/desactivada y organización suspendida.

## 9. Automated Tests

Desde el proyecto, con Node/npm y las dependencias disponibles:

```text
npm --prefix supabase/tests ci
npm --prefix supabase/tests test
npm run build
```

Los tests de PostgreSQL usan PGlite 0.5.10 con identidades sintéticas y un esquema empresarial reconstruido del inventario. Los helpers auth.uid/auth.role y las tablas de Auth/Storage del harness son sustitutos de pruebas. No se ha probado el JWT real, la plataforma Storage, CORS gestionado, el runtime Deno ni el permiso efectivo de todos los roles administrativos del alojamiento.

La compilación de revisión se ejecutó con Vite y las dependencias existentes, sin instalar paquetes de red. Se mantiene la advertencia anterior sobre tamaño del bundle.

## 10. Remaining Risks

1. Falta restaurar una copia completa en otro proyecto Supabase y probar allí la migración, los roles del alojamiento y los recorridos HTTP reales.
2. Falta comprobar copia de seguridad y restauración. El inventario no contiene los datos ni es un backup.
3. La implementación que está desplegada de update-employee-email no está disponible localmente. Se proporciona una sustitución, pero debe desplegarse y auditarse junto con create-employee. El código local por sí solo no reemplaza servicios remotos.
4. Falta configurar ALLOWED_ORIGINS y verificar Auth, confirmación de correo, recuperación, límites de alta y SMTP en el proyecto de ensayo. No se registran contraseñas ni claves en el código.
5. Falta verificar subida y firma de archivos con una identidad que pertenezca a dos organizaciones en el Storage gestionado. El [código upstream de Storage](https://github.com/supabase/storage/blob/master/src/internal/database/postgres/scope.ts) establece request.headers, pero eso no prueba la versión/configuración del proyecto alojado. Debe verificarse el transporte concreto de la cabecera y CORS.
6. No hay publicaciones Realtime de tablas en el inventario. Se conservan los refrescos por consulta; una futura suscripción Realtime necesitará su propio contexto verificable y pruebas, sin asumir que recibe cabeceras HTTP.
7. El alta de identidad y su pertenencia no pueden compartir una transacción con Auth HTTP. Un fallo parcial devuelve un error explícito y requiere reconciliar esa identidad antes de repetir el alta; no se borra automáticamente.
8. El cambio de correo es una operación de identidad global. Se reserva el objetivo y se impiden cambios concurrentes de sus membresías mientras dura la solicitud, con caducidad. Falta probar fallos de Auth y concurrencia en el alojamiento real.
9. No se ha certificado rendimiento con volumen de producción ni revocación de URLs firmadas antes de su caducidad. Una URL ya firmada mantiene la validez concedida hasta que expire.
10. Git no pudo acceder al directorio de trabajo del escritorio en este entorno, incluso tras conceder permisos. No se hizo commit ni push en el repositorio original. Se entrega el diff de los cambios y los archivos listos para registrar.

## 11. Legacy Items

- users.is_admin se conserva como campo histórico sin autoridad empresarial. useLegacyAuth/createEmployee/passwordRecovery mantienen ramas anteriores solo mientras no exista mt_context en el servidor. Las RPC y policies migradas no dependen de ese campo para conceder administración.
- Quedan archivos de interfaz antiguos no alcanzados por el recorrido activo que consultan users directamente. La nueva RLS no les permite administrar otras identidades; no se eliminan ni se refactorizan como parte de este checkpoint.
- Europe/Madrid sigue siendo la zona horaria de planificación: no se añade configuración por empresa ni se cambia la funcionalidad.
- La integración de lector NFC físico sigue pendiente, como antes; identificar mediante código no se presenta como lectura física.
- Los backups audit_recovery existentes continúan privados y corresponden al estado anterior de la organización inicial. No se publican como tablas multiempresa.
- No se implementan CRM, facturación, suscripciones, entitlements complejos, contabilidad multiempresa ni invitaciones completas a identidades existentes.

## 12. Git Diff Summary

DIFF-SUMMARY.json enumera los 16 archivos de aplicación nuevos/modificados frente a la copia inicial. Los archivos de base de datos, pruebas y documentación son nuevos. CORE-MULTITENANCY-A1.patch permite revisar los cambios de código. Ningún archivo CSS ni recurso del logo cambia.

## 13. Final Status

**PARTIAL**

Implementación local y pruebas preparadas. Pendientes instalación y ensayos en Supabase separado, despliegue de servicios de identidad, comprobación de backup/restauración, registro en Git y auditoría externa. No se declara producción segura ni migración real completada.

## MULTI-TENANT SECURITY INVARIANTS

- Cada registro empresarial tiene organización coherente con sus padres y empleados.
- Toda petición de negocio autenticada requiere membresía y organización activas, además del permiso funcional existente.
- Las cabeceras y la selección del navegador aportan contexto, nunca autorización por sí solas.
- RLS también limita las RPC de negocio: su propietario no posee tablas ni puede saltarse RLS.
- Un administrador A no recibe administración B; un empleado no puede abrir arbitrariamente todas las tareas de su empresa.
- Una tablet opera solo en la organización de su punto y comprueba su credencial, tarjeta, ticket y acción explícita.
- La identidad global no se elimina ni se modifica desde una empresa perjudicando a otra.
- Los servicios privilegiados y las excepciones nativas de Auth requieren su auditoría y grants mínimos; service_role nunca se entrega al navegador.


## Ajustes funcionales posteriores

La referencia de marcado visual de este informe corresponde al primer checkpoint, antes de los botones y módulos solicitados después. El estado actual y sus verificaciones se describen en `USABILIDAD-Y-FICHAJE.md`. Los seis archivos de estilo y marca conservan sus hashes; la interfaz añade los controles autorizados. El paquete de activación de pruebas combina la base multiempresa y las nuevas funciones en una transacción. Sigue pendiente la instalación y auditoría alojadas.
