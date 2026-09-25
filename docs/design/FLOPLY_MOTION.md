# FLOPly — Motion Language

El movimiento en FLOPly comunica información (qué cambió, qué importa ahora, si algo fue aceptado o rechazado) — nunca decora. Este documento detalla lo resumido en `FLOPLY_DESIGN_LANGUAGE.md` §5.7.

**Sistema canónico cerrado en Fase 1.75** (ver `FLOPLY_DESIGN_DECISIONS.md` #5): las duraciones nombradas de acá en adelante son **`instant` / `fast` / `normal` / `emphasis`**, no un valor suelto por interacción. `instant = 110ms` — no 100ms — porque ese es el valor real que ya usa `PressableScale` en producción (`lib/widgets/pressable_scale.dart:40`) en cientos de sitios; se adoptó el token al código real en vez de forzar el código real a coincidir con un token inventado en el aire durante el prototipo. No se tocó `PressableScale` — esta es una decisión de documentación, la migración queda para Fase 2.

| Nombre | Duración | Familia | Uso | No usar cuando |
|---|---|---|---|---|
| `instant` | **110ms** | Responder | Escala de botón/chip al presionar (`PressableScale`). | Para revelar un resultado — se sentiría apresurado. |
| `fast` | 160ms | Responder | Cambio de borde/color al seleccionar una opción/tamaño, sin confirmar. | Para el instante de "peso" antes de un veredicto. |
| `normal` | 220ms | Asentarse | Apertura de panel, entrada de burbuja, revelación de un resultado de ejercicio. | Para feedback táctil inmediato (ahí va `instant`). |
| `emphasis` | 320ms | Asentarse | Contenido de pantalla completa: cambio de fase de lección, avance de barra de progreso, apertura de sheet/dialog. | Para cualquier interacción que se repite muchas veces por sesión (se sentiría lento). |

El resto del documento usa los nombres viejos (`instant`≈100/`settle`/`reveal`) en la prosa heredada de la Fase 0.5 — se mantienen como sinónimos de `fast`/`normal`/`emphasis` respectivamente hasta la próxima revisión editorial completa del documento; el valor que manda es el de esta tabla.

## Principio rector

Dos familias de curva únicamente. Ninguna tercera familia "decorativa" genérica (nada de `elasticOut`/rebote infantil, nada de confeti, nada de shake exagerado). El pequeño overshoot físico es exclusivo de objetos que ya se comportan como objetos físicos en el sistema (cartas, fichas) — no se generaliza a botones o cards de UI.

## Las dos familias

### 1. Asentarse (`motion.curve.settle`)
- **Curva:** ease-out, con un leve overshoot (2-4%) reservado solo para elementos "físicos" de la mesa (cartas, fichas) — el resto de la UI usa ease-out puro, sin overshoot.
- **Duración:** 220ms (`settle`) para elementos chicos, 320ms (`reveal`) para contenido de pantalla completa o transiciones de teoría→ejercicio.
- **Significado:** "esto ya es verdad, quedate con esta información". Se usa para: apertura de un panel/teoría, revelación de resultado de un ejercicio, avance de la barra de progreso, entrada de la burbuja pedagógica, entrada de cartas/fichas en la mesa.
- **Nunca** se usa para: feedback de un simple tap (demasiado lento — rompe la sensación de respuesta inmediata).

### 2. Responder (`motion.curve.respond`)
- **Curva:** ease-in-out corto.
- **Duración:** 110ms (`instant`) para escalado de botón/chip al presionar, 160ms (`fast`) para cambios de borde/color al seleccionar una opción.
- **Significado:** "tu toque tuvo efecto, ahora mismo". Se usa para: press de botones (`PressableScale`-equivalente, escala a 0.94-0.97), selección de una opción antes de confirmar, cambio de tab/segmented control, toggle de nav inferior.
- **Nunca** se usa para: revelar un resultado importante (se sentiría apresurado/poco considerado, contradice el patrón "Decidir → feedback" de `FLOPLY_UX_PATTERNS.md`, que pide un instante de peso antes de revelar).

## Tabla de aplicación

| Interacción | Familia | Duración | Notas |
|---|---|---|---|
| Press de botón/chip | Responder | 110ms (`instant`) | Escala 0.94-0.97, vuelve al soltar. |
| Selección de opción (sin confirmar) | Responder | 160ms | Cambio de borde/fondo, sin escala. |
| Confirmar respuesta → revelar resultado | Asentarse | 220-320ms | El "peso" de la decisión; nunca instantáneo. |
| Avance de barra de progreso | Asentarse | 320ms | Anima el valor, nunca salta. |
| Entrada de teoría / cambio de fase de lección | Asentarse | 320ms | Fade + slide leve (8-12px), nunca solo un corte. |
| Entrada de burbuja pedagógica | Asentarse | 220ms | Ya validado en el piloto visual — mantener. |
| Glow/pulso de foco sobre la mesa | Loop propio (no es settle/respond) | 520ms por ciclo | Mecanismo ya implementado (`Highlightable`) — se mantiene como excepción documentada: es un *loop de atención*, no una transición de estado. |
| Entrada de carta/ficha | Asentarse (con overshoot físico) | 260-300ms | Único lugar del sistema donde se permite el overshoot — refuerza la metáfora de objeto físico cayendo/deslizando a su lugar. |
| Apertura de bottom sheet / dialog | Asentarse | 320ms | Desde abajo (sheet) o fade+scale leve (dialog). |
| Cambio de tab/nav inferior | Responder | 110-160ms (`instant`/`fast`) | Instantáneo, funcional. |
| Transición entre pantallas raíz (Home↔Academia↔Laboratorio↔Tools↔Cuenta) | Ninguna (corte, `IndexedStack`) | — | Correcto mantenerlo así: son contextos distintos, no partes de un mismo flujo — animar la transición confundiría "cambiar de sección" con "avanzar en una tarea". |

## Estados de éxito/error

- **Éxito:** el color semántico entra con `settle` (220ms), sin movimiento adicional del layout (nada de "salta" el elemento) — la calma es parte del mensaje ("bien, esto era esperable"), no una fiesta.
- **Error:** mismo mecanismo (`settle`, mismo timing) — deliberadamente **sin** ninguna diferencia de velocidad o intensidad de motion entre acertar y errar. Si el error se moviera más rápido o "temblara", se leería como castigo. Esto es una regla dura del tono (Fase 2: "equivocarse nunca es vergüenza").

## Qué se elimina explícitamente del vocabulario de motion

- Confeti, partículas, fuegos artificiales de cualquier tipo.
- Rebote elástico (`elasticOut`/`bounceOut`) en elementos de UI no físicos.
- Shake/vibración visual como penalización de error.
- Parallax decorativo de fondo.
- Cualquier animación en loop continuo que no tenga una función de atención activa (el glow de foco es la única excepción, y solo mientras el paso pedagógico lo requiere — no debe quedar animando indefinidamente de fondo).
