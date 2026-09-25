# FLOPly — Design Language ("Sala Verde")

Especificación del lenguaje visual elegido en `FLOPLY_DESIGN_BRIEF.md`. Este documento define **qué es cada cosa y por qué**, no cómo se codifica (eso es `FLOPLY_DESIGN_TOKENS.md`) ni el detalle de movimiento (eso es `FLOPLY_MOTION.md`, referenciado aquí solo como resumen en §5.7).

Regla de lectura de esta sección: cada valor tiene un **uso permitido** y un **uso prohibido**. Un valor sin regla de prohibición no es un token, es un color suelto.

---

## 5.1 Color

### Principio

El sistema tiene tres familias de superficie (no una sola escala de grises) y un único metal de acento (dorado/latón), en vez de "un color de marca por sección". La diferenciación entre Academia/Laboratorio/Tools se resuelve con **temperatura** (qué tan cálida o fría es la superficie), no con hues nuevos sin relación. Esto reemplaza el patrón actual de "violeta = Academia, verde = Laboratorio, lo que sea = Tools" por un sistema donde las tres siguen bajo el mismo cielo, solo con iluminación distinta.

### Principio — presupuesto de materialidad (añadido tras revisión crítica, ver `FLOPLY_DESIGN_BRIEF.md` §D)

La materialidad (madera, fieltro con vignette, brillo especular de latón) es **un recurso escaso, no un fondo por defecto**. Se gradúa por frecuencia de exposición, no por sección:

- **Superficies de alto uso/lectura prolongada** (teoría, bloque de ejercicio, cualquier pantalla que el usuario mira decenas de veces): quedan **planas**, sin textura ni gradiente — `surfaceReading` es papel liso, no papel con veta. La materialidad decorativa en una superficie que se lee cientos de veces cansa la vista y agrega ruido cognitivo, no identidad (ver test pedagógico, `FLOPLY_DESIGN_BRIEF.md` §D).
- **Momentos de baja frecuencia y alta carga emocional** (la mesa real, una pantalla de logro/resultado, la voz del mentor): ahí sí se permite el tratamiento material completo — es precisamente donde ya vive hoy (`PokerTableView`) y donde tiene sentido gastarlo.
- Regla dura: ninguna superficie fuera de `PokerTableView` usa textura de veta de madera o vignette de fieltro renderizado; `surfaceFelt` y `brass` se usan como **color plano**, nunca reproduciendo el efecto de iluminación radial o el brillo especular de la mesa.
- **Frontera cerrada en Fase 1.75, confirmada con código real (Fase 1.5):** *Global* (Home/Academia/Tools/Laboratorio, todo lo que no es la mesa) permite superficies planas, los 2 niveles de profundidad de §5.5, y contraste mate/brillo sutil (p. ej. `brassBright` como highlight de estado pressed) — nunca textura renderizada. *Específico de mesa* (`PokerTableView`/`TableMaterial` únicamente) permite textura, vignette, veta de madera y materialidad física intensa — esa frontera no se cruzó ni una vez en las 4 pantallas construidas hasta ahora (`surfaceFelt` apareció como máximo una vez por pantalla, siempre en franja acotada, nunca como fondo completo ni con textura).

### Superficies base

| Token | HEX | RGB | Contraste esperado (sobre texto primario) | Uso permitido | Uso prohibido |
|---|---|---|---|---|---|
| `background` | `#0E0D0B` | 14,13,11 | — (es el fondo) | Fondo raíz de toda pantalla. Grafito cálido, no azul-negro. | Nunca usarlo como color de texto ni de ícono. |
| `backgroundRecede` | `#070706` | 7,7,6 | — | Zonas que deben sentirse "detrás" (fondo de modal, scrim). | No usarlo como fondo de pantalla completa (se siente vacío sin la superficie principal encima). |
| `surface` | `#17140F` | 23,20,15 | — | Superficie estándar de contenido (paneles, listas). | No usarlo para texto. |
| `surfaceElevated` | `#211C15` | 33,28,21 | — | Un nivel de elevación por encima de `surface` (headers fijos, sheets, la card activa dentro de una lista). Máximo 2 niveles de elevación en toda la app (ver §5.5). | No apilar más de 2 niveles; no usarlo como "card default" si `surface` alcanza. |
| `surfaceReading` (marfil) | `#F3ECDD` | 243,236,221 | 13.8:1 con `inkPrimary` | **Exclusivo de paneles de lectura larga** (cuerpo de teoría escrita, callouts de "ejemplo"). Es la superficie "papel". | No usarlo en botones, chips, ni en Laboratorio/Tools — es de lectura, no de chrome. |
| `surfaceFelt` (fieltro) | `#123B29` | 18,59,41 | — | **Franja acotada**, nunca fondo de pantalla completa: la cabecera de una pregunta de Laboratorio, el área inmediatamente detrás de una mesa embebida. Color plano — sin vignette ni textura (ver "presupuesto de materialidad" arriba). | No usarlo como color de texto ni de ícono; **no usarlo como fondo de pantalla completa bajo ninguna circunstancia** (máx. ~1 franja por pantalla, altura acotada) — cubrir toda la pantalla de fieltro es exactamente el paso que convierte una app de entrenamiento en una imitación de mesa de casino. |

#### `surfaceReading` — cuándo aparece, cuándo no (cerrado en Fase 1.75)

- **Aparece** cuando el contenido es prosa continua que el alumno debe leer de corrido: el cuerpo completo de una teoría (todas sus secciones dentro de UNA sola `ProtoReadingCard`/`card.reading`, no una por sección), un callout de "ejemplo" largo, el contenido de Bankroll. Validado con una teoría corta (T093, 6 secciones) y una larga (TN10, 7 secciones, párrafos más extensos) usando exactamente el mismo componente sin ningún ajuste estructural — ver `FLOPLY_VISUAL_STRESS_TEST.md` §D.
- **No aparece** en Laboratorio ni Tools (no son lugares de lectura prolongada), ni en chrome/navegación, ni envolviendo un solo dato puntual (ahí va `chip.numeric`/`callout.accent`, no una superficie de lectura completa).
- **Regla anti-fragmentación (dura):** una teoría con N secciones es **una** `surfaceReading` con N bloques tipográficos adentro (eyebrow + cuerpo, sin color ni ícono por sección) — nunca N cards separadas. El patrón `sección → card → card → card → card` es exactamente lo que este componente reemplaza (la auditoría original encontró ese patrón repetido con 7 combinaciones ícono+color en `_SectionView` real). Cuándo una superficie adicional SÍ se justifica dentro de una teoría: solo para un callout con función distinta a la prosa (el "OBJETIVO" al inicio, la "IDEA CLAVE" al final) — nunca para separar secciones del cuerpo entre sí.
- **Cuándo una teoría debería convertirse en flujo editorial continuo en vez de secciones fijas:** esta fase no encontró evidencia de que haga falta — TN10 (la más larga probada) sostuvo la estructura fija de 7 eyebrows sin sentirse fragmentada, gracias a que las secciones viven en la misma superficie sin separadores visuales fuertes entre ellas (solo espaciado). Si una teoría futura resulta sustancialmente más larga que TN10, repetir esta prueba antes de asumir que la estructura fija sigue alcanzando (ver pendiente en `FLOPLY_PROTOTYPE_PHASE_1.md`/`FLOPLY_VISUAL_STRESS_TEST.md`).

### Metal de acento (único, con 3 temperaturas)

| Token | HEX | RGB | Uso permitido | Uso prohibido |
|---|---|---|---|---|
| `brass` (latón — acento primario global) | `#C89B4A` | 200,155,74 | CTA principal, ícono de marca, elemento seleccionado, progreso completado. Reemplaza el rol que hoy cumple `violetPrimary`. | No usarlo para fondos grandes (>15% del área visible); nunca dos tonos de brass distintos en el mismo componente; **como máximo un elemento de superficie (no ícono, no borde fino) en `brass` por pantalla** — si aparece en el CTA, no vuelve a aparecer como fondo de otra card en la misma pantalla. Su escasez es lo que lo hace leerse como "esto es FLOPly", no decoración. |
| `brassBright` | `#E4C179` | 228,193,121 | Estado *hover/pressed* de `brass`, texto sobre `surfaceFelt`. | No usarlo como color de fondo de superficie. |
| `brassDeep` | `#7A5A22` | 122,90,34 | Bordes sutiles sobre superficies claras, sombra tintada de elementos de latón, **y texto/ícono de brass sobre `surfaceReading`** (mide 5.39:1 — `brass` puro ahí mide 2.17:1 y falla; hallazgo real de Fase 1.5, ej. el callout "IDEA CLAVE" de una teoría). | No usarlo como texto sobre `background` oscuro (contraste insuficiente ahí — es específicamente la variante para superficie CLARA). |

### Principio de contraste por contexto de uso (cerrado en Fase 1.75)

**Un color semántico o de temperatura no tiene un único valor universal.** Su variante correcta depende de (a) qué superficie tiene detrás y (b) si se usa como texto/ícono, borde, o relleno de superficie grande. La Fase 1.5 midió contraste real (WCAG) y encontró 6 fallas porque `feltGreen`/`steelBlue`/`graphiteSteel`/`error` solo tenían un valor, calibrado para relleno/superficie, y se estaban usando también como texto — algo que `brass` ya evitaba desde el principio por tener 3 variantes. La regla, ahora explícita para los 4 colores:

- **Como relleno de superficie grande o barra de progreso:** usar el valor **base** (`feltGreen`/`steelBlue`/`graphiteSteel`/`error`).
- **Como texto o ícono sobre `background`/`surface`/`surfaceElevated`:** usar la variante **`*Bright`** — nunca el valor base, que mide 2.0-3.5:1 ahí (falla AA).
- **Como texto o ícono sobre `surfaceReading` (marfil):** los valores base de `feltGreen`/`steelBlue` sí pasan (5.27:1 / 4.67:1) — la excepción es `brass`, que ahí necesita `brassDeep` (ver tabla de abajo).
- **Regla de escasez:** esto no es licencia para llenar el sistema de variantes — son exactamente 2 por color (base + Bright), nunca 3+, y `Bright` existe solo para los 4 colores donde la medición real encontró una falla, no preventivamente para todos.

### Acentos de temperatura (diferenciación por área — ver también §8 en `FLOPLY_UX_PATTERNS.md`)

| Token | HEX | Rol | Uso permitido | Uso prohibido |
|---|---|---|---|---|
| `feltGreen` | `#1F6E4A` | Cálido/aprender — Academia | Relleno de superficie/progreso; texto/ícono solo sobre `surfaceReading` (5.27:1). | Como texto/ícono sobre `background`/`surfaceElevated` (2.7-3.1:1, falla) — ahí usar `feltGreenBright`. No usarlo en Laboratorio como color de marca. |
| `feltGreenBright` | `#32B277` | Texto/ícono de Academia sobre fondo oscuro | Header, chips, progreso cuando el elemento es texto/ícono (no relleno). Mide 6.2-7.2:1 contra `background`/`surfaceElevated`. | No usarlo como relleno de superficie grande (para eso está `feltGreen` base). |
| `steelBlue` | `#3E6E8E` | Frío/decidir — Laboratorio | Relleno de botón/superficie de Laboratorio, borde. | Como texto/ícono sobre `background`/`surfaceElevated` (3.08-3.54:1, falla texto normal) — ahí usar `steelBlueBright`. No usarlo para éxito/error. |
| `steelBlueBright` | `#5DA5D5` | Texto/ícono de Laboratorio sobre fondo oscuro | Header, título de card, chip seleccionado. Mide 6.2-7.2:1. | No usarlo como relleno grande. |
| `graphiteSteel` | `#4A4E54` | Neutro/herramienta — Tools | Relleno/chrome de calculadoras. | Como texto/ícono (2.0-2.3:1, falla incluso el umbral de ícono 3:1) — ahí usar `graphiteSteelBright`. No usarlo como color de dato. |
| `graphiteSteelBright` | `#8C949F` | Texto/ícono de Tools sobre fondo oscuro | Header, íconos de instrumento. Mide 6.3-7.4:1. | No usarlo como relleno grande. |

### Semánticos (independientes de sección — significan lo mismo en toda la app)

| Token | HEX | Uso permitido | Uso prohibido |
|---|---|---|---|
| `success` | `#3FA66B` | Respuesta correcta, jugada óptima, meta alcanzada (texto e ícono: mide 6.36:1, no necesita variante Bright). | No usarlo como acento decorativo de Academia (eso es `feltGreen`, distinto valor a propósito para que "correcto" siempre sea inconfundible). |
| `warning` | `#C97A3B` | Jugada aceptable-pero-no-óptima, aviso no bloqueante (texto e ícono: mide 5.86:1). | No usarlo para errores duros. |
| `error` | `#B23B3B` | Relleno/borde de estado de error. | Como texto de 12.5sp negrita u otro tamaño chico (3.31:1, falla) — ahí usar `errorBright`. No usarlo en rojo saturado tipo "alarma". |
| `errorBright` | `#F04F4F` | Texto/ícono de error en chips/callouts chicos. Mide 5.2-5.5:1. | No usarlo como relleno de superficie grande — sigue siendo más "alarma" que `error` base, reservarlo a texto puntual. |
| `information` | `#4E8CA6` | Notas, ayudas contextuales, tooltips. | No usarlo intercambiado con `steelBlue` de Laboratorio — son conceptualmente distintos aunque cercanos en hue; `information` es siempre neutral/UI, `steelBlue` es siempre de sección. |
| `disabled` | `#4A463C` @ 45% opacidad sobre su superficie | Controles inactivos, contenido bloqueado. | No bajar la opacidad de todo el bloque (texto+ícono+fondo) — solo del contenido. **Pendiente (Fase 1.5/1.75):** mide 2.07:1 contra `background` incluso sin la opacidad reducida — no se corrigió por no tener uso real medido todavía; no usar para nada que el usuario deba leer para actuar hasta revisar este valor. |

### Texto

| Token | HEX (sobre `background`/`surface`) | Contraste sobre `background` | Uso |
|---|---|---|---|
| `textPrimary` | `#F1ECE0` | 15.1:1 | Títulos, cuerpo principal. |
| `textSecondary` | `#B9AF9C` | 7.9:1 | Subtítulos, metadatos. |
| `textMuted` | `#7C7568` | 4.6:1 (mínimo AA para texto normal) | Placeholder, texto deshabilitado — **nunca** para información que el usuario deba leer para actuar (repite el error de contraste ya documentado en el código actual). |
| `inkPrimary` (sobre `surfaceReading`) | `#241E14` | 13.8:1 | Único color de texto permitido sobre superficie marfil. |
| `inkSecondary` (sobre `surfaceReading`) | `#5A5140` | 7.1:1 | Metadatos sobre superficie marfil. |

### Bordes y separadores

| Token | HEX | Uso |
|---|---|---|
| `borderSubtle` | `#2B271E` | Borde por defecto de una superficie sobre `background`/`surface`. |
| `borderFocus` | `brass` a 60% | Foco de teclado/selección — nunca decorativo. |
| `separator` | `#241F17` | Líneas divisoras dentro de una lista (preferidas a envolver cada fila en su propia card — ver `FLOPLY_ANTI_GENERIC.md`). |

### Comportamiento contextual (cómo conviven Academia/Laboratorio/Tools)

El fondo raíz (`background`) es **el mismo en las tres**. Lo que cambia es (a) el acento de temperatura del header/CTA de esa sección y (b) qué tan seguido aparece `surfaceFelt` vs. `surfaceReading` vs. superficies neutras:
- Academia: predominan `surfaceReading` (teoría, plana) y `feltGreen` como acento de progreso/header — nunca como fondo de pantalla.
- Laboratorio: predomina `surface`/`surfaceElevated` neutro con acento `steelBlue` en header/CTA/progreso; `surfaceFelt` aparece **solo** como franja acotada alrededor de una mesa embebida, nunca como fondo de la pantalla completa (ver "presupuesto de materialidad"); casi nunca `surfaceReading` (no es un lugar de lectura larga). La identidad de Laboratorio es densidad de datos + frialdad de acento, no "todo verde fieltro".
- Tools: predomina `graphiteSteel`, sin `surfaceReading` ni `surfaceFelt` — es la sección más "neutra en temperatura" a propósito, porque es una caja de herramientas, no un lugar con clima propio.

### Migración conceptual desde la paleta actual

| Hoy (`AppColors`) | Rol nuevo |
|---|---|
| `violetPrimary/Bright/Deep/Soft` | Se retira como color de marca global. Su función de "acento de Academia" pasa a `feltGreen`; su función de "acento de progreso" pasa a `brass`. |
| `neonGreen/Bright/Deep` | Se retira como neón. Su función de "acento de Laboratorio" pasa a `steelBlue`; su función semántica de "correcto" pasa a `success` (un verde más terroso, no neón). |
| `gold` | Se formaliza y se refina como `brass`/`brassBright`/`brassDeep`. |
| `diamondBlue` | Se retira; su rol informativo pasa a `information`. |
| `danger`/`warning` | Se conservan como concepto, se retonan a `error`/`warning` terrosos (menos saturados, menos "alarma de sistema"). |
| `TableMaterial` (paleta de la mesa) | Se convierte en la **fuente primaria** del sistema — `surfaceFelt`, `brass`, `surfaceReading` (marfil de las cartas) nacen de ahí, no al revés. |

---

## 5.2 Tipografía

### Familias

- **Display/Headline — una serif o slab con carácter editorial** (concepto: algo con el peso y la personalidad de una *Fraunces*, *Tiempos* o *Source Serif* — a definir en fase de implementación entre 2-3 candidatas con licencia adecuada). Se usa en: título de nivel/lección, título de teoría, momentos de "IDEA CLAVE", pantalla de resultado. Comunica autoridad editorial (Fase 2 del brief) sin recurrir a mayúsculas gritadas.
- **UI/Body — una sans neutra de alta legibilidad en pantalla** (concepto: peso variable, ejes ópticos para texto chico — tipo *Inter*, *Public Sans* o la que ya use el sistema si se decide no sumar una fuente nueva a esta familia). Se usa en: navegación, botones, prosa de cuerpo, labels.
- **Numérica — monoespaciada tabular dedicada** (concepto: tipo *IBM Plex Mono*, *JetBrains Mono* o cualquier monoespaciada con cifras tabulares reales). Se usa **exclusivamente** para: stacks en BB, %, EV, pot odds, frecuencias, saldos de Bankroll, contadores de progreso ("4/6"). Esta es la firma tipográfica más importante del sistema (ver Fase 2 del brief, "cifras como firma visual") — es lo que distingue a FLOPly de cualquier competidor visualmente, incluso en un screenshot sin logo.

### Escala

| Rol | Tamaño | Peso | Line-height | Letter-spacing | Casing | Familia |
|---|---|---|---|---|---|---|
| Display | 28sp | 700 | 1.15 | 0 | Sentence case | Display |
| Headline | 22sp | 700 | 1.2 | 0 | Sentence case | Display |
| Title | 17sp | 700 | 1.25 | 0 | Sentence case | UI |
| Body | 15sp | 400 | 1.5 | 0 | Sentence case | UI |
| Body strong | 15sp | 600 | 1.5 | 0 | Sentence case | UI |
| Label | 12.5sp | 700 | 1.3 | 0.4 | UPPERCASE | UI |
| Caption | 11.5sp | 500 | 1.35 | 0.2 | Sentence case | UI |
| Numeric — display (pot, stacks grandes) | 24sp | 600 | 1.1 | 0 | — | Numérica |
| Numeric — inline (chips, filas) | 14sp | 600 | 1.2 | 0 | — | Numérica |
| Numeric — micro (metadatos, %) | 11.5sp | 500 | 1.2 | 0 | — | Numérica |

Reglas de jerarquía: nunca más de 3 tamaños en una misma pantalla fuera de Label/Caption. El peso 800/900 (hoy usado en `level_map.dart` y varios lugares) se elimina del sistema — la jerarquía se logra con familia (Display vs UI) y tamaño, no con pesos extremos, que es un recurso típico de UI genérica.

---

## 5.3 Spacing

Unidad base: **4px**. Escala geométrica moderada (no puramente ×2, para tener valores intermedios útiles en mobile):

| Token | Valor | Uso típico |
|---|---|---|
| `space.xs` | 4px | Separación entre ícono y su label inline. |
| `space.sm` | 8px | Padding interno de chips, separación entre líneas relacionadas. |
| `space.md` | 12px | Padding interno de controles chicos, separación entre elementos de una lista densa. |
| `space.lg` | 16px | Padding interno estándar de un panel/superficie. |
| `space.xl` | 24px | Separación entre bloques dentro de una pantalla. |
| `space.xxl` | 32px | Separación entre secciones mayores. |
| `space.section` | 48px | Separación entre el header de una pantalla y su contenido; entre el final de un flujo y el siguiente. |

Regla: ningún valor de padding/margin fuera de esta escala. Si una pantalla "necesita" un valor intermedio, es señal de que la jerarquía de la pantalla no está bien resuelta con densidad/tipografía — no se resuelve inventando un `14px` nuevo.

---

## 5.4 Shape Language

Principio: **el radio comunica si algo se toca o se lee**. No existe un radio único "porque sí".

| Token | Valor | Uso |
|---|---|---|
| `radius.sharp` | 2px | Chips numéricos, badges de estado, elementos "de instrumento" (Tools). |
| `radius.panel` | 10px | Paneles de contenido, superficies (`surface`, `surfaceReading`, `surfaceFelt`). |
| `radius.control` | 14px | Botones, inputs, tarjetas tocables de lista (lección, tool, nivel). |
| `radius.pill` | 999px | Exclusivo de: badges de estado puntual (correcto/incorrecto), tabs segmentados. **No** para botones primarios grandes (hoy varios CTA son pill-like; se reserva el pill para elementos pequeños de estado, para que no compita con el radio de control). |
| `radius.sheet` | 20px (solo esquinas superiores) | Bottom sheets y modales. |

Reglas duras:
- Nunca dos radios distintos en el mismo componente salvo pill sobre control (ej. un badge pill dentro de una card `control`).
- Los íconos de marca/instrumento (ver §5.6) tienen **esquinas ligeramente cortadas** (chaflán de 1-2px en las puntas), no completamente rectas ni completamente redondeadas — es el detalle de forma que diferencia a FLOPly de Material 3 "de fábrica" en el nivel más pequeño de detalle.

---

## 5.5 Depth

Principio: **profundidad = objetos físicos apoyados, no blur decorativo**. Máximo 2 niveles de elevación reales en toda la app (evita el "todo flota" típico de glassmorphism):

| Nivel | Mecanismo | Cuándo |
|---|---|---|
| 0 — En la mesa | Sin sombra, solo `borderSubtle` o `separator`. | Contenido normal dentro de una superficie (la mayoría de la UI). |
| 1 — Apoyado | Sombra de contacto corta y dura: offset (0, 2), blur 6, `background` a 35% — imita objeto físico apoyado sobre la mesa, no luz ambiental difusa. | Cards tocables que necesitan distinguirse de su fondo (tool card, lesson card, CTA principal). |
| 2 — Flotante | Sombra más larga: offset (0, 8), blur 20, `background` a 45%, **solo** para elementos que literalmente flotan sobre el contenido (bottom sheet, burbuja de diálogo sobre la mesa, modal). | Overlays reales únicamente. |

Prohibido: `BoxShadow` con color de acento (glow de color) fuera del mecanismo de foco descrito en §5.7/`FLOPLY_MOTION.md` (el "glow" de foco es movimiento, no elevación estática); blur/glassmorphism (`BackdropFilter` decorativo) en cualquier superficie que no sea explícitamente un overlay de vidrio esmerilado sobre la mesa (si se usa alguna vez, es exclusivo de overlays de mesa, nunca de chrome de app).

---

## 5.6 Iconografía

- **Estilo:** trazo (outline), no relleno sólido salvo para el estado "activo/seleccionado" (relleno = seleccionado es la única regla de alternancia permitida).
- **Stroke:** 1.5px a tamaño base 24dp (escala proporcional).
- **Tamaño:** 20dp (inline con texto), 24dp (estándar de control/nav), 32dp (destacado en header).
- **Peso:** uniforme — nunca mezclar un set "rounded" grueso con uno fino en la misma pantalla (hoy se usa la familia `_rounded` de Material de forma consistente; se mantiene el principio pero se recomienda una familia de íconos con el chaflán descrito en §5.4 para los íconos de marca — navegación inferior y headers de sección — y Material rounded solo para íconos utilitarios genéricos dentro de contenido).
- **Uso:** funcional primero — un ícono nunca es puramente decorativo; si se puede quitar sin perder información, se quita (ver `FLOPLY_ANTI_GENERIC.md`).
- **Estados:** outline (default) → relleno + `brass`/acento de sección (seleccionado) → outline a `disabled` (inactivo). Nunca más de 3 estados visuales por ícono.
- **Iconos principales del sistema:** navegación (home, academia, laboratorio, tools, cuenta), estado de lección (bloqueado/disponible/en curso/completado — reutilizar el set ya validado de `level_map.dart`, que es semánticamente correcto), estado de respuesta (correcto/aceptable/incorrecto), FAB de mesa rápida.

---

## 5.7 Motion (resumen — detalle completo en `FLOPLY_MOTION.md`)

Principio: el movimiento **informa, no decora**. Dos familias de curva:

- **Asentarse** (`ease-out`, 220-320ms): algo llega y se queda — apertura de panel, entrada de teoría, feedback de acierto. Comunica "esto ya es verdad".
- **Responder** (`ease-in-out` corto, 100-160ms): confirmación táctil inmediata — press de botón, selección de chip. Comunica "tu toque tuvo efecto".

No existe una tercera familia "decorativa" (nada de rebote tipo `elasticOut` para elementos neutros — el pequeño overshoot físico se reserva para fichas/cartas que ya lo usan hoy en la mesa, como refuerzo de la metáfora de objeto físico, no como firma de toda la UI).

---

## Ver también

- `FLOPLY_DESIGN_TOKENS.md` para la traducción de esta especificación a estructura `color.*`, `type.*`, `space.*`, `radius.*`, `elevation.*`, `motion.*`.
- `FLOPLY_COMPONENTS.md` para cómo estos valores se aplican componente por componente.
