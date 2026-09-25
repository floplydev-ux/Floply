# FLOPly — Components

Componentes fundamentales del sistema "Sala Verde". Para cada uno: propósito, anatomía, jerarquía, variantes, estados, spacing/typography/color (referenciando tokens de `FLOPLY_DESIGN_TOKENS.md`), motion, y cuándo usarlo/no usarlo. Especificación conceptual — sin código todavía.

Se marca entre paréntesis, cuando aplica, el equivalente actual auditado que este componente formaliza o reemplaza.

---

### AppBar / Section Header
*(reemplaza el patrón repetido "círculo-ícono + título + subtítulo" hoy hecho a mano en Home/Academia/Laboratorio/Tools)*

- **Propósito:** orientar — decir en qué sección y en qué pantalla está el usuario.
- **Anatomía:** ícono de sección (24-32dp, chaflanado, color `color.section.*` de esa área) + `type.headline` + `type.caption` de subtítulo opcional. Sin fondo propio — vive sobre `color.surface.background`.
- **Jerarquía:** el ícono nunca compite con el título en tamaño; es un acompañante, no el protagonista.
- **Variantes:** con acción trasera (back), con acción de cierre (modal), con progreso embebido (dentro de una lección).
- **Estados:** estático — no tiene estados interactivos propios (las acciones que contiene sí).
- **Spacing:** `space.lg` de margen inferior antes del contenido; `space.md` entre ícono y texto.
- **Motion:** ninguno propio; puede heredar `motion.duration.settle` si aparece con la pantalla.
- **Usar cuando:** siempre, como primer elemento de cualquier pantalla de nivel raíz.
- **No usar cuando:** dentro de un sheet/modal breve (usar un título simple en su lugar, sin ícono de sección).

---

### Navegación / Bottom Navigation
*(formaliza `AppBottomNavigation`)*

- **Propósito:** cambiar entre las 5 áreas principales.
- **Anatomía:** 5 destinos, ícono 24dp + label `type.caption` uppercase.
- **Jerarquía:** el ítem activo se distingue por relleno de ícono (ver §5.6 iconografía) + color `color.section.*` de esa área, nunca por tamaño.
- **Estados:** default (outline, `color.text.secondary`), activo (relleno, color de sección, escala 1.08x), deshabilitado (no aplica — las 5 áreas siempre están disponibles).
- **Color:** fondo `color.surface.elevated`, borde superior `color.border.subtle`.
- **Motion:** `motion.duration.instant` para el cambio de escala/relleno al tocar.
- **Usar cuando:** siempre visible en las 5 pantallas raíz.
- **No usar cuando:** dentro de flujos de lección/ejercicio/mesa (ya se oculta hoy correctamente vía `IndexedStack`+push; mantener ese criterio).

---

### FAB de Mesa Rápida
*(formalización del FAB actual "Table Mode")*

- **Propósito:** acceso instantáneo a una mesa de práctica desde cualquier lugar.
- **Anatomía:** círculo 56dp, ícono chaflanado, fondo `color.accent.brass` (reemplaza el violeta actual — es el único elemento de chrome fuera de la mesa que usa el metal de marca a pleno, reforzando que "esto te lleva a la mesa").
- **Estados:** default, pressed (`motion.duration.instant`, escala 0.94).
- **Elevación:** `elevation.level1`.
- **Usar cuando:** en las 5 pantallas raíz, siempre en la misma posición.
- **No usar cuando:** dentro de un flujo de lección/mesa activo (competiría con las acciones reales de esa mesa).

---

### Cards

Tres variantes distintas, no una sola "Card" genérica — la auditoría encontró que "convertir todo en card" es ya un riesgo real del sistema actual.

**1. `component.card.panel`** *(formaliza el uso correcto de `GlassCard` cuando envuelve contenido no tocable)*
- Propósito: agrupar contenido relacionado sin implicar que se puede tocar.
- Anatomía: `color.surface.base`, `radius.panel`, `elevation.level0` (sin sombra — vive plano, se distingue por color de superficie contra el fondo, no por elevación).
- Usar cuando: agrupar una sección de contenido de solo lectura.
- No usar cuando: el contenido es una sola línea de texto — ahí no hace falta card, un separador alcanza (ver `component.callout.accent`/`separator`).

**2. `component.card.tappable`** *(formaliza filas de `level_map.dart`, `tools_screen.dart`, `HomeLinkCard`)*
- Propósito: representar una entidad tocable que lleva a otra pantalla (lección, tool, nivel).
- Anatomía: `radius.control`, `elevation.level1` (sombra de contacto corta — comunica "esto se puede levantar/tocar"), ícono + título `type.title` + descripción `type.caption` + indicador de estado a la derecha (chevron o badge).
- Estados: default, pressed (`PressableScale`-equivalente, escala 0.97, `motion.duration.instant`), bloqueado (candado, opacidad reducida solo en el contenido interior, nunca en el borde/fondo — regla de accesibilidad de `FLOPLY_DESIGN_LANGUAGE.md` §5.1).
- Usar cuando: la card lleva a una pantalla o acción concreta.
- No usar cuando: no hay ninguna acción al tocarla — usar `component.card.panel`.

**3. `component.card.reading`** *(formaliza las secciones de `written_theory_view.dart`)*
- Propósito: presentar teoría/prosa larga con máxima legibilidad.
- Anatomía: `color.surface.reading` (marfil), `color.text.onReading.*`, `radius.panel`, sin borde de acento — la jerarquía interna es tipográfica (eyebrow label + cuerpo), no de color de borde por tipo de sección (elimina la necesidad de 7 colores de sección distintos que hoy existen en `_SectionView`).
- Usar cuando: cuerpo de una teoría completa.
- No usar cuando: un solo dato puntual — usar `component.chip.numeric` o `component.callout.accent`.

---

### Buttons

**Primary** *(formaliza `_CtaButton`/`LessonNavControls` botón "continuar")*
- Anatomía: `radius.control`, fondo `color.accent.brass` (o `color.section.*` si la acción es específica de esa sección, ej. "empezar sesión" en Laboratorio usa `steelBlue`), texto `type.bodyStrong` en `color.surface.background` (texto oscuro sobre metal claro, no blanco).
- Elevación: `elevation.level1`.
- Estados: default, pressed (`motion.duration.instant`, escala 0.97 + oscurecimiento 8%), disabled (`color.semantic.disabled`).
- Usar cuando: una sola acción principal por pantalla/paso.
- No usar cuando: hay más de una acción — la secundaria baja a `Secondary`.

**Secondary**
- Anatomía: sin relleno, borde `color.border.subtle`, texto `type.bodyStrong` en `color.text.primary`.
- Usar cuando: acción de "volver"/"cancelar" junto a una primaria.

**Icon Button**
- Anatomía: 44×44dp de área táctil mínima (aunque el ícono visual sea 24dp — replica el fix de accesibilidad ya aplicado en `UserAvatar`), sin fondo por defecto.
- Usar cuando: acción secundaria puntual en un header (ajustes, cerrar).

---

### Chips

**`component.chip.status`** *(formaliza `ratingBadge()`)*
- Anatomía: `radius.pill`, fondo del color semántico a 16% opacidad + borde al 45% + texto/ícono al 100%, `type.label`.
- Variantes: success/warning/error/information.
- Usar cuando: comunicar el resultado de una decisión puntual (correcto/aceptable/incorrecto).
- No usar cuando: el dato es continuo (un %, una frecuencia) — eso es `chip.numeric`, no `chip.status`.

**`component.chip.numeric`** *(nuevo — no existe hoy como componente unificado)*
- Anatomía: `radius.sharp`, fondo `color.surface.elevated`, valor en `type.numeric.inline`, label opcional en `type.caption` uppercase al lado.
- Usar cuando: mostrar BB/%/EV/frecuencia inline dentro de cualquier contexto (mesa, calculadora, resultado de Laboratorio, saldo de Bankroll).
- No usar cuando: el número es el protagonista único de la pantalla (usar `type.numeric.display` suelto, sin chip, para no enjaular el dato principal en una caja).
- **Regla dura de responsive (cerrada en Fase 1.75, tras un bug real — ver `FLOPLY_DESIGN_DECISIONS.md` #6):**
  1. Un grupo de 2 o más `chip.numeric` **siempre** se dispone en `Wrap`, nunca en `Row`. Nunca asumir que un conjunto de chips entra en una sola línea — un ejemplo real (`AppStrings.potOddsRequiredEquityLabel`, "EQUITY NECESARIA") desbordó una fila rígida a 300dp de ancho.
  2. Dentro de un chip, el **label es lo único que puede truncarse** (elipsis, una sola línea) si el espacio aprieta. El **valor numérico nunca se trunca ni se corta** — es la firma tipográfica del sistema (`FLOPLY_ANTI_GENERIC.md` regla 12); si no entra, el problema es de layout general de la pantalla, no algo que el chip deba resolver escondiendo el número.
  3. El componente debe funcionar correctamente en el ancho de mobile más angosto soportado (300dp), con el copy real de producción — no solo con valores cortos de ejemplo tipo "8/13".

---

### Badges
*(formaliza los íconos de estado de `level_map.dart`: candado/disponible/en curso/completado)*
- Anatomía: círculo 28dp, ícono 16dp centrado, color según estado (neutro/`color.section.*`/`color.semantic.success`).
- Usar cuando: comunicar el estado de progreso de una entidad (nivel, lección, tool).
- No usar cuando: el estado ya es evidente por otro medio (no duplicar candado + opacidad + texto "bloqueado" a la vez — elegir uno como principal y los demás como refuerzo sutil).
- **Nota de consolidación (Fase 0.5):** `Badge` y `chip.status` no son dos sistemas distintos — son la misma familia conceptual **Status Indicator** con dos variantes de forma: círculo para *progresión* (bloqueado/disponible/en curso/completado, algo que avanza en el tiempo) y pill para *evaluación* (correcto/aceptable/incorrecto, un juicio puntual sobre una decisión). Se documentan por separado porque resuelven dos preguntas distintas ("¿dónde estoy?" vs. "¿qué tan bien decidí?"), no porque sean componentes sin relación — implementarlos como una sola clase base con `shape: circle | pill` es preferible a dos clases independientes.

---

### Progress
*(unifica las 4 implementaciones duplicadas de barra de progreso)*
- **`component.progress.linear`:** track `color.surface.elevated` 6px, relleno `radius.sharp` en color de sección o `success` si es de dominio/maestría. Anima con `motion.duration.reveal` + `motion.curve.settle` al cambiar de valor (nunca salta instantáneo).
- Variante compacta (dentro de una card `tappable`, 4px) y variante de pantalla completa (dentro de un header de lección, 6-8px).
- No usar cuando: el progreso es binario (hecho/no hecho) — ahí un badge alcanza, no hace falta una barra al 0% o 100%.

---

### Lesson Cards / Theory Blocks / Exercise Blocks
Ya cubiertos como especialización de `card.tappable` (lesson card en el mapa de nivel) y `card.reading` (bloque de teoría). El bloque de ejercicio es su propio componente:

**`component.exercise.block`**
- Anatomía: situación (mesa o `poker_bits`) + `type.body` de la pregunta + lista de opciones.
- Opción individual: `radius.control`, borde `color.border.subtle` default → `color.accent.brass` + fondo a 12% cuando seleccionada (antes de confirmar) → color semántico cuando se revela el resultado.
- Estados: sin responder, seleccionado (no confirmado), confirmado-correcto, confirmado-aceptable, confirmado-incorrecto.
- Motion: `motion.duration.quick` en el cambio de borde al seleccionar; `motion.duration.settle` al revelar el resultado (nunca instantáneo — darle un instante de "peso" a la revelación, ver `FLOPLY_UX_PATTERNS.md` "Equivocarse").

---

### Answer States / Feedback Panels — también es `component.callout.accent`
*(formaliza `FeedbackPanel`/`EducationalPanel` en su modo de resultado)*
- Anatomía: ícono de estado (32dp) + `type.title` del veredicto + `type.body` de explicación + (opcional) desglose de `chip.numeric` con frecuencias/EV.
- Color: borde y acento en el color semántico correspondiente, fondo siempre `color.surface.base` (nunca tintar todo el fondo del panel de un color fuerte — mantiene el tono "calmado" del brief, evita la sensación de alarma).
- Usar cuando: siempre después de una respuesta, en Academia y Laboratorio.
- No usar cuando: es un simple ack de UI (ahí un `chip.status` inline alcanza, no hace falta un panel completo).
- **Nota de consolidación (Fase 0.5):** este componente **es** la implementación concreta de `component.callout.accent` (`FLOPLY_DESIGN_TOKENS.md`) — no son dos componentes distintos. `callout.accent` es el nombre del patrón genérico (regla vertical/borde de acento + label + cuerpo); "Answer States / Feedback Panel" es su variante con ícono de veredicto. Cualquier otro callout (objective pill, idea clave, caption de burbuja) es la misma base sin el ícono de veredicto — una sola implementación con props, no seis.

---

### Score / Progress (resultado de sesión) — patrón de composición, no un componente nuevo
*(formaliza `lesson_result_view.dart`/`session_summary.dart`)*
- **Nota de consolidación (Fase 0.5):** esto no es un átomo nuevo del sistema — es una **composición** de piezas ya existentes: `type.numeric.display` (el puntaje) + `chip.numeric`/`chip.status` (el desglose) + `button.primary`/`button.secondary` (reintentar/continuar). Se documenta acá como receta de composición, no como un componente a implementar desde cero.
- Anatomía: ícono grande de resultado (32-40dp) + `type.numeric.display` del puntaje si aplica + lista de `chip.numeric`/`chip.status` con el desglose + CTA primaria (reintentar/continuar).
- Sin celebración animada de partículas — el "logro" se comunica con la cifra exacta y un ícono estático, consistente con el tono "calmado, cifras exactas" del brief.

---

### Tabs / Segmented Controls
- Anatomía: `radius.pill`, track `color.surface.elevated`, selector con `elevation.level0` (sin sombra) + color de sección al 100%.
- Usar cuando: alternar entre 2-4 vistas del mismo nivel jerárquico (ej. modos de una calculadora de Tools).
- No usar cuando: son más de 4 opciones — usar una lista o un selector explícito en su lugar.

---

### Dialogs / Bottom Sheets
- Anatomía: `radius.sheet` (solo esquinas superiores en sheet, todas en dialog), `elevation.level2`, fondo `color.surface.elevated`, handle bar sutil en sheets.
- Motion: entrada con `motion.duration.reveal` + `motion.curve.settle` desde abajo (sheet) o con fade+scale leve (dialog).
- Usar cuando: una decisión o selección que no amerita una pantalla completa (Table Mode, confirmaciones).
- No usar cuando: el contenido requiere scroll largo — eso es una pantalla propia, no un sheet.

---

### Tool Cards
*(formaliza las filas de `tools_screen.dart`)*
- Es una especialización de `card.tappable` con acento `color.section.tools` (graphiteSteel) — deliberadamente **sin** un color de acento distinto por herramienta (hoy cada calculadora tiene su propio hue sin relación); la distinción entre herramientas es por ícono y texto, no por color, para reforzar Tools como "una sola caja de herramientas coherente" en vez de 5 apps sueltas.

---

### Bankroll Elements
- Reutiliza `card.reading` para la teoría (ya es correcto hoy) + `chip.numeric` con acento `color.accent.brass` para cualquier cifra (a diferencia de Academia/Laboratorio, en Bankroll el metal de marca sí puede usarse para datos, porque el rol semántico ahí es "valor/dinero", coherente con el significado de `brass`).

---

### Empty / Loading / Error States
- **Empty:** ícono outline grande (32-40dp) en `color.text.muted` + `type.body` explicando honestamente por qué está vacío (formaliza el criterio ya usado en `_LaboratoryEmptyCard` — no simular datos). Construido y probado por primera vez en Fase 1.5 (Home, caso E).
- **Loading:** sin spinners genéricos de Material — usar un pulso sutil (`motion.curve.settle` en loop lento) sobre la silueta del contenido esperado (skeleton simple en `color.surface.elevated`), coherente con "concentración sin ruido". Sin construir todavía en el playground.
- **Error:** ícono `color.semantic.error`, mensaje concreto (qué pasó) + acción de reintento — nunca un mensaje genérico tipo "algo salió mal". Construido y probado en Fase 1.5 (Tools, input inválido).

---

## Estado para producción (auditoría de Fase 1.75)

Los 9 componentes centrales del prototipo (`lib/dev/design_playground/proto_components.dart`), evaluados tras sostener 4 pantallas de dominios de contenido distintos sin necesitar ni un componente nuevo:

| Componente | Estado | Motivo |
|---|---|---|
| `ProtoSurfacePanel` | **A — listo** | Sin defectos encontrados en 4 pantallas; anatomía estable. |
| `ProtoTappableCard` | **A — listo** | Reutiliza `PressableScale` real sin fricción; validado en Home/Academia/Tools. |
| `ProtoReadingCard` | **A — listo** | Validado con teoría corta y larga (T093/TN10) sin ajuste estructural. |
| `ProtoButtonPrimary` | **A — listo** | Tenía un bug real (texto oscuro fijo, fallaba con relleno `steelBlue`) — corregido con selección de color de texto por luminancia real; ya generaliza a cualquier acento del sistema. |
| `ProtoButtonSecondary` | **A — listo** | Sin defectos encontrados. |
| `ProtoCalloutAccent` | **A — listo** | Validado en las 4 pantallas con 5 colores distintos (`feltGreen`, `brassDeep`, `success`/`warning`/`errorBright`, `graphiteSteel`) sin defecto propio — los 2 problemas de contraste que aparecieron eran del color elegido por quien lo llama, no del componente, y ya están documentados como regla (ver `FLOPLY_DESIGN_LANGUAGE.md` "Principio de contraste por contexto de uso"). |
| `ProtoChipStatus` | **A — listo** | Sin defecto propio encontrado; depende de que el color pasado sea la variante correcta (regla ya documentada, no reforzada en el tipo). |
| `ProtoSectionHeader` | **B — necesita un ajuste antes de producción** | Funciona, pero nada en su API impide pasar un color de temperatura base (no-Bright) como `accent` y reintroducir la falla de contraste ya corregida una vez — antes de producción, restringir el parámetro a un enum de acentos seguros o agregar un `assert` de luminancia mínima. |
| `ProtoChipNumeric` | **B — necesita confirmación adicional** | Tenía un bug real de overflow (label sin `Flexible`), ya corregido y probado en 8 anchos con las 3 etiquetas reales de Pot Odds — pero es el componente que más veces mostró fragilidad (2 problemas reales en 2 fases distintas); recomendado un pase de revisión de código dedicado antes de promoverlo, no solo los tests de ancho ya hechos. |

Ninguno quedó en **C** (exclusivo de playground) — los 9 sostuvieron 4 dominios de contenido reales sin necesitar una versión "solo para prototipo".
