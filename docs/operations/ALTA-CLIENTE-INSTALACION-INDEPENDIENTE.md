# Alta de cliente · instalación independiente

Usar una copia de esta ficha por cada cliente. No incluir contraseñas, JWT ni claves `service_role`.

## Identificación comercial

- Cliente:
- Contacto principal:
- Fecha de alta:
- Plan o alcance contratado:
- Estado: pendiente / en instalación / validación / entregado / suspendido

## Recursos separados

- Dominio:
- Hosting:
- URL pública:
- Proyecto Supabase:
- Región Supabase:
- Proyecto de correo:
- Ubicación de copias:

## Instalación

- [ ] Crear proyecto Supabase independiente.
- [ ] Confirmar el usuario propietario.
- [ ] Ejecutar `instalacion-nueva-plantilla.sql` con los datos del cliente.
- [ ] Ejecutar `activar-automatizaciones.sql`.
- [ ] Desplegar `create-employee` y `update-employee-email`.
- [ ] Configurar `ALLOWED_ORIGINS` con el dominio HTTPS del cliente.
- [ ] Configurar las variables públicas del frontend del proyecto correspondiente.
- [ ] Publicar el frontend y comprobar HTTPS, cabeceras y fallback SPA.

## Prueba de entrega

- [ ] Login del propietario.
- [ ] Alta de un empleado de ensayo.
- [ ] Crear y planificar una tarea.
- [ ] Iniciar y cerrar un fichaje respetando el orden.
- [ ] Crear una incidencia y comprobar su historial.
- [ ] Generar un informe y descargar CSV/Excel.
- [ ] Comprobar una repetición y los avisos automáticos.
- [ ] Crear la primera copia y verificar que puede leerse.
- [ ] Eliminar los datos de ensayo o identificarlos como datos de prueba.

## Entrega y mantenimiento

- [ ] Entregar URL y usuario propietario por un canal seguro.
- [ ] Registrar commit, manifiesto y fecha de publicación.
- [ ] Programar copias y revisión de salud.
- [ ] Explicar el procedimiento de soporte sin solicitar secretos.
- [ ] Registrar cualquier ampliación o suspensión sin mezclarla con otros clientes.
