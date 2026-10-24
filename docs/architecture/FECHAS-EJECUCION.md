# Fechas por ejecución - diseño funcional

## Principio

Las fechas pertenecen a cada ejecución planificada (`work_day_plan`), no al catálogo `tasks`. Una tarea recurrente genera ejecuciones independientes y cada una recibe sus propias fechas. Cambiar una ejecución no modifica la regla ni las apariciones anteriores o futuras.

`work_date` se conserva como día organizativo y clave de compatibilidad para calendario, orden diario y recurrencias existentes. No debe seguir interpretándose por sí solo como todos los tipos de fecha.

## Modos

| Modo | Significado | Datos principales |
| --- | --- | --- |
| `anytime` | Trabajo sin fecha comprometida | Sin restricción temporal |
| `deadline` | Puede empezar ya y debe terminar antes de un límite | `due_at` |
| `window` | Puede iniciarse dentro de una ventana y debe terminar antes del límite | `available_from`, `due_at` |
| `scheduled` | Está recomendado o exigido para una fecha/hora concreta | `scheduled_for`, `strict_schedule` y, si procede, `due_at` |
| `period` | Trabajo de varios días con comienzo y final previstos | `available_from`, `planned_end`; `due_at` puede añadir un límite distinto |

Las fechas sin hora se interpretan en `Europe/Madrid`: el inicio a las 00:00 y el límite/final al terminar el día. Las horas se guardan como instantes con zona horaria.

## Reglas de inicio

- `anytime`: se puede iniciar cuando el orden operativo lo permita.
- `deadline`: se puede iniciar desde su creación hasta `due_at`.
- `window`: no se puede iniciar antes de `available_from`; después de `due_at` queda vencida y requiere replanificación.
- `scheduled` flexible: se muestra en agenda en `scheduled_for`, pero puede iniciarse antes o después mientras no incumpla otras restricciones.
- `scheduled` estricta: no puede iniciarse antes de `scheduled_for`. Si solo se indicó fecha, puede iniciarse ese día. Si existe límite, tampoco puede iniciarse después de él.
- `period`: no puede iniciarse antes de `available_from`; puede permanecer en curso hasta `planned_end` o `due_at`.

La importancia nunca altera estas reglas ni el orden del encargado. Una tarea urgente no adelanta otra ejecución disponible anterior.

## Presentación

El formulario se titula "¿Cuándo debe hacerse?" y ofrece: En cualquier momento, Antes de una fecha, Entre dos fechas, En una fecha/hora concreta y Durante un periodo. La opción programada muestra Flexible/Estricta.

Las vistas distinguen de forma textual:

- `Programada · 12 nov, 08:00`
- `Disponible hasta 15 nov`
- `Disponible 10-15 nov`
- `En curso · periodo 10-18 nov`
- `Vence hoy` o `Vencida`

## Compatibilidad

- Las ejecuciones ya existentes se migran a `scheduled`, sin hora, estrictas durante su `work_date`; conservan el comportamiento validado.
- La planificación diaria y por periodos continúa creando ejecuciones programadas para cada día.
- Las recurrencias continúan usando su vencimiento calculado como `work_date` y crean una ejecución programada independiente; nunca reutilizan la fecha antigua del catálogo.
- Fichajes, tablet, NFC, tablero y cambios administrativos deben consultar la misma función de elegibilidad del servidor.
- Los estados iniciados, bloqueados y completados no se reescriben al cambiar fechas; toda edición temporal futura debe quedar auditada.

## Contrato de servidor implementado

`work_execution_eligibility` es la única decisión de inicio. Combina estado, asignación vigente, exclusividad de fichaje, orden del encargado y límites temporales. Un disparador sobre `checkins` hace que el mismo resultado se aplique a inicio manual, NFC, tablet y tablero, aunque un cliente antiguo no conozca los nuevos campos.

`work_set_execution_schedule` bloquea la ejecución para evitar carreras, comprueba `board_version`, valida la forma completa del modo y acepta un identificador de operación para reintentos idempotentes. Cada cambio real se añade a `work_execution_schedule_events`; la tabla no admite escrituras directas desde clientes y conserva actor, instante, valores anteriores y nuevos.

Al cambiar de modo, el servidor normaliza antes de validar: elimina los valores de campos que quedan ocultos y desactiva `strict_schedule` salvo en programación exacta. Así el contrato definitivo incorpora el hotfix probado sin depender de una función envoltorio temporal.

La cola identifica la siguiente unidad de trabajo mediante `next_plan` (`work_day_plan.id`). `next_task` se conserva solo por compatibilidad. Dos ejecuciones recurrentes del mismo catálogo pueden coexistir y no se sobrescriben ni habilitan entre sí.

Un disparador de inserción inicializa cada nueva ejecución como una programación estricta de su propio `work_date`. Esto cubre planificación diaria, períodos y recurrencias personales o de área sin copiar fechas desde el catálogo.

## Entrega segura

La implementación se activa de forma incremental en ASE Work - Pruebas mediante `deployment/activar-fechas-ejecucion.sql`. El frontend solo se reconstruye después de generar ese activador y comprobar la migración en PostgreSQL aislado.
