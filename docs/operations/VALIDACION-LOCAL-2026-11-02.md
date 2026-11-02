# Validación local de la versión candidata · 2 de noviembre de 2026

## Identidad comprobada

- Versión: `1.0.0-rc.1`.
- Rama: `pruebas/multitenancy-usabilidad-2026-10-22`.
- Candidata identificada: commit publicado `3246c3c8`.
- Frontend SHA-256 conjunto: `EA461B3A5FCB5768F1927C996AA305910366156CE5DA814FD86638D3172D8CC6`.
- Dirección local: `http://192.168.1.114:5174`.

## Resultado

- La ruta `/login` terminó en estado `complete`.
- Formulario, textos y controles del acceso presentes.
- Cuerpo con contenido; no se reprodujo pantalla blanca.
- Ningún error de consola durante la recarga.
- La ruta pública diferida `/station` cargó su fragmento, mostró la configuración del punto y no dejó visible el estado intermedio.
- Ningún error de consola durante la carga de `/station`.

## Alcance

Esta comprobación acredita la carga local de la entrada y de una ruta separada después de la optimización. No inició sesión, no transmitió credenciales y no modificó datos. Las pruebas autenticadas por perfil, alojadas, físicas y de correo continúan en el listado manual de la versión candidata.
