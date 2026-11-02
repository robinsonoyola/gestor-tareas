# Control de versión candidata de ASE Work

## Comprobación automática

Ejecutar `npm run test:release`. El control se detiene en el primer fallo y valida:

- ausencia de copias, claves y archivos de entorno rastreados por Git;
- entregables de instalación, automatización, diagnóstico, funciones y manuales;
- aislamiento multiempresa sintético;
- migraciones transaccionales, sin permisos públicos, referencias de producción ni funciones privilegiadas inseguras;
- las 69 migraciones, el aislamiento RLS de todas las tablas y una instalación nueva aislada;
- paquetes de funciones administrativas;
- funciones administrativas sin CORS abierto, secretos embebidos ni sesiones persistentes;
- protecciones de copia y restauración;
- rutas esenciales, menús y carga diferida de pantallas;
- ausencia de pantallas y componentes desconectados del arranque real;
- versiones mínimas corregidas de las dependencias críticas de producción y compilación;
- versión de Node compatible declarada y comprobada antes de una instalación;
- bloqueo de npm coherente, con registro HTTPS autorizado y huellas de integridad;
- inventario verificable de las dependencias incluidas en producción, con versión, licencia e integridad;
- rechazo de componentes con licencia desconocida o fuera de la lista comercial revisada;
- exportaciones CSV y Excel;
- compilación final del frontend;
- presupuesto de carga móvil y ausencia de mapas de código o archivos sensibles en la entrega;
- compatibilidad mínima de navegadores fijada y metadatos para accesos móviles guardados;
- inspección del paquete final contra claves privadas, conexiones directas y tokens administrativos;
- política de permisos del navegador limitada a las capacidades operativas necesarias;
- manifiesto SHA-256 del frontend, base de datos y funciones que forman la entrega.

Un resultado apto significa que la versión candidata es internamente coherente. No acredita por sí solo el funcionamiento de servicios externos ni sustituye las pruebas manuales.

El archivo `deployment/generated/release-manifest.json` identifica exactamente los recursos compilados, los paquetes asociados, los manuales, las utilidades operativas y las entradas utilizadas para compilar, incluido el bloqueo de dependencias y la versión de Node. Debe conservarse con la versión publicada para comprobar una entrega, reproducirla o preparar una vuelta atrás.

## Pruebas manuales que siguen separadas

Estas pruebas permanecen pendientes hasta que se autoricen y existan los entornos o dispositivos necesarios:

- aislamiento real entre dos empresas alojadas;
- recuperación de contraseña mediante correo real;
- recorridos completos de administrador, encargado y empleado;
- Android, iPhone, ordenador, tablet y NFC;
- apertura real de descargas CSV y Excel en aplicaciones de usuario;
- restauración real en un proyecto Supabase vacío.

## Decisión de publicación

Solo etiquetar una versión para clientes cuando el control automático sea apto, las pruebas manuales aplicables estén registradas y exista una copia restaurable. Un fallo no se omite: se corrige y se repite el control completo.
