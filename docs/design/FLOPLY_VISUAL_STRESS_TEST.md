# FLOPly — Fase 1.5: Stress Test Visual de "Sala Verde"

Registro adversarial: se intentó romper el lenguaje visual antes de autorizar cualquier migración, extendiendo el prototipo aislado de la Fase 1 (`lib/dev/design_playground/`) con contenido más largo, una pantalla nueva (Tools), más estados de Laboratorio, un barrido responsive mucho más agresivo, mediciones de contraste reales y una investigación de tipografía. Sigue siendo prototipo — no se migró nada.

## A. Objetivo

Comprobar si "Sala Verde" escala a FLOPly completa o se rompe bajo condiciones reales: teoría larga, alta densidad funcional (Tools), estados variables de Home y Laboratorio, anchos/alturas extremas, contenido extremo, y auditoría honesta de contraste, motion, anti-casino y anti-SaaS.

## B. Entorno probado

`flutter analyze` (proyecto completo) + `flutter test` (proyecto completo, 1116 tests) + un test dedicado nuevo, `test/dev/design_playground_prototype_test.dart` (131 casos), corriendo sobre los 4 archivos de `lib/dev/design_playground/` (3 de Fase 1, extendidos, + 1 nuevo de Tools). Sin dispositivo físico ni `flutter widget-preview start` en este entorno — validación por `flutter_test` con `tester.view.physicalSize` variable, más cómputo directo de contraste WCAG (fórmula de luminancia relativa) para cada par de color relevante.

## C. Pantallas probadas

1. Home — 5 variantes de contenido (`_HomeCase`).
2. Academia — 2 teorías reales (T093 corta, TN10 larga).
3. Tools — Pot Odds (nueva en esta fase).
4. Laboratorio — 5 estados explícitos + 2 flujos interactivos completos.

## D. Teoría larga utilizada

**TN10 "Implied odds"** (nivel 6, subnivel 6.5, INTERMEDIO — `lib/engine/pedagogy/curriculum_spec_data.g.dart:1890`). Se eligió deliberadamente entre las teorías más largas de todo el currículo (medido por longitud de la línea `'contenido': {...}` en el archivo generado — TN10 fue la 2ª más larga de las ~10 primeras candidatas, y la única de esas con las 7 secciones completas incluyendo "CUÁNDO NO", que T093 no tiene). Texto copiado verbatim, sin acortar ni editorializar.

## E. Tool utilizada

**Pot Odds** (`lib/engine/poker/pot_odds/pot_odds_engine.dart` + `pot_odds_result.dart`) — el mismo motor puro que usa `pot_odds_calculator_screen.dart` en producción, con el copy real de `AppStrings.potOdds*`/`toolsPotOdds*`. Se construyó `lib/dev/design_playground/tools_prototype_preview.dart`, un chrome nuevo sobre ese motor real (inputs numéricos, resultado, estado de error), sin tocar la pantalla real ni `tool_widgets.dart`.

## F. Estados de Laboratorio probados

1. Antes de decidir (FOLD/ABRIR visibles, nada elegido).
2. Eligiendo tamaño (tras ABRIR, 3 chips de tamaño).
3. Feedback "MEJOR JUGADA" (ABRIR + 2.5 BB).
4. Feedback "ACEPTABLE" (ABRIR + 2 BB).
5. Feedback "NO ES LO MEJOR" (FOLD, resuelve sin paso de tamaño).

Más 2 flujos interactivos completos (ABRIR→tamaño→feedback→reset; FOLD directo) ejecutados de punta a punta contra los widgets reales, no solo capturas estáticas.

## G. Responsive

Barrido: **300, 320, 360, 375, 390, 414, 430, 480 dp** de ancho (Fase 1 solo cubría 320/360/390/430) + alturas cortas **568 y 640** (iPhone SE-clase) para Academia, Tools y Laboratorio (las 3 pantallas con una zona de altura semi-fija: mesa embebida, inputs). Home no se probó en altura corta porque es 100% scrolleable sin ninguna zona fija — no tiene el mismo riesgo.

**Hallazgo metodológico importante** (no de la app, del propio arnés de prueba): los 4 `_stage()` del playground envolvían su contenido en un `SizedBox(width: 390, height: 844)` fijo. Contra un viewport de prueba más angosto, ese `SizedBox` se comprime correctamente (por eso Fase 1 sí detectó el overflow real de Home a 320/360dp) — pero contra un viewport más ancho (414/430/480dp) el contenido se quedaba plantado en 390dp con espacio muerto alrededor, es decir, **esa mitad del barrido de Fase 1 y del inicio de esta fase no estaba probando nada nuevo**. Corregido: los 4 `_stage()` ahora usan `LayoutBuilder` y ocupan el ancho real disponible, con 430dp como techo (mayor ancho de teléfono común) solo para que el visor de Widget Preview no estire el contenido a ancho de escritorio. Ver §O/§P para el detalle.

Con el barrido ya corregido, se encontró y corrigió un overflow real nuevo: el chip "EQUITY NECESARIA" de Tools desbordaba 10px a 300dp (ver §O.3).

## H. Tipografía

Investigación (sin instalar nada, tal como exige esta fase):

| Rol | Candidata | Ventajas | Problemas | Licencia | Android | Web | iOS |
|---|---|---|---|---|---|---|---|
| Display/Headline | **Fraunces** (Google Fonts) | Serif contemporánea con "ejes" ópticos, carácter editorial fuerte sin ser clásica/aburrida; variable font (un solo asset cubre varios pesos) | Peso display puede leerse "decorativo" en tamaños de UI chicos si no se limita a títulos | SIL OFL 1.1 (uso comercial libre) | Sí, vía asset embebido | Sí (`@font-face`/`google_fonts` si se usara Flutter Web) | Sí |
| Display/Headline (alternativa más conservadora) | **Source Serif 4** | Más neutra/legible que Fraunces en tamaños intermedios, buen soporte de acentos españoles | Menos "personalidad" — se acerca más a "libro de texto genérico" | SIL OFL 1.1 | Sí | Sí | Sí |
| UI/Body | **Public Sans** | Alta legibilidad en pantalla, ejes ópticos, diseñada para gobierno de EE.UU. (accesibilidad como prioridad de diseño) | Personalidad neutra a propósito — no aporta identidad por sí sola (correcto: ese rol lo cumple Display) | SIL OFL 1.1 | Sí | Sí | Sí |
| UI/Body (alternativa) | **Inter** | Muy probada, tabular figures nativas, excelente en pantallas chicas | Extremadamente común (usada por gran parte del ecosistema de apps) — el "menos distintivo" de las 4 opciones | SIL OFL 1.1 | Sí | Sí | Sí |
| Numérica | **IBM Plex Mono** | Cifras tabulares reales, buena distinción 1/l/I y 0/O, familia con carácter técnico consistente con "instrumento de precisión" | Ancho de carácter alto — números grandes (`numericDisplay`, 24sp) ocupan más espacio horizontal que una tabular de una sans | SIL OFL 1.1 — uso comercial libre. **Corrección (Fase 1.75):** esta tabla decía "Apache 2.0"; verificado contra el archivo de licencia real del repositorio (`IBM/plex`), es SIL OFL 1.1 — Apache se ofreció brevemente en 2018 y fue retirada. Ver `FLOPLY_DESIGN_DECISIONS.md` #3. | Sí | Sí | Sí |
| Numérica (alternativa) | **JetBrains Mono** | Muy legible a tamaños chicos (diseñada para código), tabular | Voz más "developer tool" que "mesa de póker" — encaja mejor con Tools que con Academia/Bankroll | SIL OFL 1.1 (no Apache 2.0 pese a que muchos sitios de terceros lo listan así — verificado contra la fuente oficial de JetBrains) | Sí | Sí | Sí |

Este prototipo **siguió usando la fuente de sistema** en las 4 pantallas, con `FontFeature.tabularFigures()` en los 3 roles numéricos como única aproximación real a la firma tipográfica — tal como estableció `FLOPLY_DESIGN_TOKENS.md` como fuera de alcance. Evaluación honesta: sin una familia Display real, el "IDEA CLAVE"/título de teoría en `ProtoType.display` (peso 700, fuente de sistema) no logra la voz editorial que el documento de lenguaje describe — se ve "bold grande", no "editorial". Esto es esperado, no un fallo del sistema de color/spacing/forma.

**Recomendación:** Fraunces (display) + Public Sans (UI) + IBM Plex Mono (numérica) — las 3 con licencia SIL OFL 1.1 (comercial libre, verificado contra fuente primaria, no de memoria), buen soporte de español, y already-variable-font donde aplica (menos peso de assets). **Cerrado en Fase 1.75** — ver `FLOPLY_DESIGN_DECISIONS.md` #3 para la decisión final, la corrección de licencia, y el resultado honesto del intento de validación visual (bloqueado por una limitación del entorno de test, no de las fuentes).

## I. Motion

Deriva encontrada en Fase 1: `PressableScale` real usa 110ms fijos; los tokens del prototipo definen `instant=100ms`/`quick=160ms`. Resolución conceptual de esta fase: **110ms pasa a ser el valor canónico de "instant"** (no 100) — es el que ya vive en producción, en un widget usado en cientos de lugares; cambiar el token para que coincida con el código real cuesta cero migración, mientras que cambiar `PressableScale` para que coincida con el token tocaría un primitivo compartido fuera de alcance de esta fase. Sistema resultante (documentado, no aplicado a código productivo todavía):

| Nombre | Valor | De dónde sale |
|---|---|---|
| `instant` | **110ms** | Valor real de `PressableScale` — se adopta tal cual, no se inventa uno nuevo. |
| `quick` | 160ms | Sin cambios (selección de opción/tamaño). |
| `settle` | 220ms | Sin cambios. |
| `reveal` | 320ms | Sin cambios. |

Ninguna animación del prototipo se agregó "porque se ve bien": cada una (`ProtoProgressLinear` al cambiar de valor, `_SizeChip` al seleccionar, `PressableScale` al tocar) tiene una función de feedback/continuidad ya documentada en `FLOPLY_MOTION.md`. No se encontró ninguna animación superflua en las 4 pantallas.

## J. Contraste

Se midió contraste real (fórmula WCAG de luminancia relativa) para 20+ pares de color realmente usados en el prototipo — no una revisión visual ("se ve bien"). Resultado: **6 fallas reales encontradas y corregidas en código**, más 1 de menor severidad documentada sin corregir.

| Par | Ratio | Resultado | Uso real que lo disparó | Corrección aplicada |
|---|---|---|---|---|
| `brass` texto/ícono sobre `surfaceReading` | 2.17:1 | **FALLA** | "IDEA CLAVE" en Academia | → `brassDeep` (5.39:1) |
| `feltGreen` texto/ícono sobre `surfaceElevated`/`background` | 2.73-3.13:1 | **FALLA/borderline** | Eyebrow y chips del hero de Home; header/progreso de Academia | → `feltGreenBright` (6.2-7.2:1) |
| `steelBlue` texto/ícono sobre `surfaceElevated`/`background` | 3.08-3.54:1 | **FALLA** (texto normal) | Título de Practice Room Card; header de Laboratorio; texto de `_SizeChip` seleccionado; texto de botón "ABRIR" | → `steelBlueBright` (6.2-7.2:1) para texto/ícono; el FILL del botón queda en `steelBlue` base (ver fila siguiente) |
| `background` (texto oscuro fijo) sobre relleno `steelBlue` | 3.54:1 | **FALLA** | `ProtoButtonPrimary` con acento no-brass ("ABRIR") | → color de texto elegido por luminancia real del relleno (`Color.computeLuminance()`), no fijo — con `steelBlue` de relleno ahora usa `textPrimary` (4.66:1) |
| `graphiteSteel` texto/ícono sobre `surfaceElevated`/`background` | 2.02-2.32:1 | **FALLA** | Ícono de Tools en Home; header de Tools | → `graphiteSteelBright` (6.3-7.4:1) |
| `error` texto sobre `background`/`surface` | 3.31:1 | **FALLA** (texto 12.5sp negrita) | Chip/callout "NO ES LO MEJOR" en Laboratorio | → `errorBright` (5.2-5.5:1) |
| `disabled` sobre `background` | 2.07:1 | FALLA, no corregida | Ningún uso real en las 4 pantallas de esta fase (solo documentado en `proto_tokens.dart`) | Pendiente — mismo orden de magnitud que el problema ya conocido de `textMuted` en producción; se deja para revisión de tokens en Fase 2, no bloquea esta fase |
| `feltGreen`/`steelBlue` como texto sobre `surfaceReading` | 5.27-4.67:1 | PASA | "OBJETIVO" en Academia (feltGreen sobre marfil) | Sin cambios — confirma que el problema es específico de `surfaceElevated`/`background`, no de los colores en sí |
| `inkPrimary`/`inkSecondary` sobre `surfaceReading` | 14.05 / 6.65:1 | PASA | Cuerpo de teoría | Sin cambios |
| `success`/`warning` sobre `background` | 6.36 / 5.86:1 | PASA | Feedback "MEJOR JUGADA"/"ACEPTABLE" | Sin cambios |

**Patrón detrás de las 6 fallas:** ninguno de los 3 colores de temperatura de sección (`feltGreen`/`steelBlue`/`graphiteSteel`) tenía una variante "Bright" — a diferencia de `brass`, que ya había sido diseñado con 3 variantes desde `FLOPLY_DESIGN_LANGUAGE.md` original. Es decir, el documento de diseño aplicó la disciplina de variantes de contraste de forma inconsistente (solo al metal de marca), y el prototipo lo heredó literalmente hasta que la medición real lo expuso. Se agregaron `feltGreenBright`/`steelBlueBright`/`graphiteSteelBright`/`errorBright` a `proto_tokens.dart`, cada uno preservando la proporción R:G:B del color base (mismo hue, más luminancia) para que se lean como "el mismo color, más claro", no como un color nuevo sin relación.

## J.1 Identidad sin color (escala de grises)

Revisión conceptual de las 4 pantallas quitando mentalmente `feltGreen`/`steelBlue`/`graphiteSteel`/`brass`/semánticos: lo que sobrevive es la separación `background`/`surface`/`surfaceElevated`/`surfaceReading` (4 valores de gris/crudo distintos, discriminables sin hue), la tipografía numérica tabular (se distingue por familia/alineación, no por color), la regla vertical de `ProtoCalloutAccent` (visible como forma, no solo como color) y la jerarquía de radios (`sharp`/`panel`/`control`/`pill` siguen comunicando tocable-vs-legible-vs-instrumento sin necesitar hue). Lo que **no** sobrevive del todo: la diferenciación entre Academia/Laboratorio/Tools depende hoy casi enteramente del acento de temperatura — en gris puro, las 3 pantallas se verían más parecidas entre sí de lo que el sistema pretende. Esto no es un fallo nuevo: ya estaba señalado como riesgo en `FLOPLY_DESIGN_QA.md` ("¿la jerarquía sigue funcionando en escala de grises?"); esta fase lo confirma con las pantallas reales en vez de solo con el documento.

## J.2 Identidad sin logo

Comparando las 4 pantallas sin nombre/ícono de marca: Academia (superficie marfil + tipografía numérica) y Laboratorio (franja de fieltro acotada + mesa real + doctrina de acento único por pantalla) siguen siendo difíciles de confundir con una app genérica. Home y Tools son los eslabones más débiles — Home porque es la pantalla de menor densidad material por diseño (nada que la distinga salvo el brass puntual del CTA y la tipografía numérica de los chips), y Tools porque una calculadora con inputs+resultado es, estructuralmente, parecida a cualquier calculadora. Ninguna de las dos "podría ser cualquier app" (ambas ya usan el vocabulario de superficies/radios/tipografía consistente), pero tampoco tienen todavía un elemento tan inconfundible como la mesa o el marfil de lectura. Se documenta como reserva abierta, no como fallo — coincide con lo ya anotado en `FLOPLY_PROTOTYPE_PHASE_1.md` §D.4 de la Fase 0.5/1.

## K. Anti-generic

Sin hallazgos nuevos de "parece SaaS/Material 3 de fábrica" en las 4 pantallas. Tools —la más expuesta a este riesgo por ser la más "utilitaria"— se mantuvo dentro del sistema de 9 componentes sin necesitar ni un `StatCard`, ni una flechita de tendencia, ni un badge "PRO". El único ajuste real de Tools fue de contraste y de un componente ya existente (`ProtoChipNumeric`), no de composición.

## L. Anti-casino

Búsqueda activa en las 4 pantallas: sin textura de madera/veta, sin vignette de fieltro renderizado, sin brillo especular fuera de `PokerTableView`. `surfaceFelt` aparece exactamente una vez en las 4 pantallas (la franja acotada detrás de la mesa embebida en Laboratorio) — nunca como fondo de pantalla completa. `brass` aparece como relleno de superficie como máximo una vez por pantalla (el CTA principal de Home/Academia, "SIGUIENTE EJERCICIO" en Laboratorio) — nunca dos veces en la misma pantalla, y nunca en Tools (que no tiene ningún elemento en brass). La regla de materialidad graduada de la Fase 0.5 sobrevivió el contacto con código real y contenido real, no solo con el documento.

## M. Anti-SaaS

Revisión específica: radio uniforme (evitado — las 4 pantallas usan la escala de 5 valores documentada, nunca un sexto), exceso de badges (no — `ProtoChipStatus` aparece solo en el momento de evaluación de Laboratorio, no decorativamente en otro lado), sombras idénticas en todo (no — la mayoría de la superficie vive en elevación 0, solo las cards tocables y el CTA usan elevación 1), cards accent-border (evitadas deliberadamente — `ProtoCalloutAccent` es una regla vertical de 3px, no una caja completa con borde de color, precisamente para no caer en el patrón "card con borde de acento" que la auditoría original encontró 6 veces en el código real). Único punto de atención, no un fallo: `ProtoSectionHeader` se usa de forma IDÉNTICA en Academia/Laboratorio/Tools (mismo layout ícono+título+subtítulo) — hoy es coherencia intencional, pero si el sistema crece a 20 pantallas sin ninguna variación entre headers, ese mismo patrón podría empezar a sentirse "de plantilla". Vale revisitarlo en Fase 2 cuando haya más pantallas para juzgarlo con evidencia real, no ahora con solo 3 casos.

## N. Componentes

Se revisaron los 9 componentes de Fase 1 contra una pantalla de un dominio de contenido completamente distinto (Tools: números/inputs, no prosa ni decisión de póker). **Resultado: cero componentes nuevos fueron necesarios para Tools** — se reutilizaron `ProtoSectionHeader`, `ProtoChipNumeric`, `ProtoCalloutAccent`, `ProtoSurfacePanel` tal cual, más un input de texto simple (`TextField` + `Container` con los tokens de superficie, no un componente nuevo — es la única pieza de UI verdaderamente nueva que Tools necesitó, y es un input de formulario genérico, no algo que amerite entrar al sistema de diseño). Esta es la evidencia más fuerte a favor de la escalabilidad del sistema: 4 pantallas, 4 dominios de contenido distintos (navegación, lectura, decisión, cálculo), 9 componentes, cero duplicados. Los dos únicos cambios reales a componentes existentes fueron correcciones (contraste de `ProtoButtonPrimary`, overflow de `ProtoChipNumeric`), no nuevas variantes.

## O. Problemas encontrados y P. soluciones aplicadas

```text
Problema 1:
"IDEA CLAVE" en Academia era ilegible — brass sobre marfil mide 2.17:1.
↓ Causa:
brass fue diseñado para fondo oscuro; nunca se midió contra surfaceReading.
↓ Impacto:
el único callout dorado del sistema, en la única superficie clara, fallaba.
↓ Solución mínima:
usar brassDeep (ya existía en el token, pensado para "bordes sobre
superficies claras" pero no se aplicaba a texto) en vez de brass.
↓ Nueva prueba:
brassDeep/surfaceReading medido: 5.39:1. Pasa.
```

```text
Problema 2:
El barrido responsive ≥390dp de Fase 1 no probaba nada nuevo.
↓ Causa:
_stage() en los 4 archivos usaba SizedBox(width: 390) fijo — un viewport
de prueba más ancho que 390 dejaba el contenido plantado en 390dp con
espacio muerto, en vez de usar el ancho real disponible.
↓ Impacto:
414/430/480dp del barrido de Fase 1 y del inicio de esta fase eran
cobertura falsa — parecía que se probaban 8 anchos, en la práctica solo
5 (300-390) hacían algo distinto.
↓ Solución mínima:
LayoutBuilder + clamp(0, 430) en vez de un ancho fijo, en los 4 archivos.
↓ Nueva prueba:
re-correr el barrido de 8 anchos — expuso el problema 3 (antes oculto).
```

```text
Problema 3:
Chip "EQUITY NECESARIA" de Tools desbordaba 10px a 300dp.
↓ Causa:
ProtoChipNumeric.label era un Text suelto dentro de un Row sin Flexible
— un label real y largo (AppStrings.potOddsRequiredEquityLabel, 16
caracteres) no tenía cómo ceder espacio.
↓ Impacto:
la calculadora de Tools era inusable en un teléfono angosto real con
esta etiqueta real — no un caso hipotético, es el copy de producción.
↓ Solución mínima:
envolver el label en Flexible + TextOverflow.ellipsis; el VALOR numérico
nunca se trunca (sigue siendo la firma del sistema).
↓ Nueva prueba:
300dp con las 3 etiquetas reales de Pot Odds (BOTE FINAL / EQUITY
NECESARIA / POT ODDS) — sin overflow.
```

```text
Problema 4:
TextField de Tools crasheaba (debugCheckHasMaterial) y producía un
overflow reportado de ~200.000px.
↓ Causa:
_stage() de Tools no tenía un ancestro Material — único de los 4 archivos
con un widget Material interactivo real (los otros 3 solo usan
PressableScale/GestureDetector, que no lo exigen).
↓ Impacto:
Tools era literalmente inutilizable en el playground — ni un test podía
tocar el campo de texto.
↓ Solución mínima:
envolver el contenido en Material(color: ProtoColor.background, ...)
dentro de _stage(), solo en tools_prototype_preview.dart.
↓ Nueva prueba:
enterText real en el campo — funciona; el overflow gigante desapareció
por completo (era síntoma de este problema, no un bug de spacing aparte).
```

Además, 6 correcciones de contraste (ver §J) siguiendo el mismo patrón Problema→Causa→Solución, y una corrección de `ProtoButtonPrimary` para elegir el color de texto según la luminancia real del relleno en vez de asumir texto oscuro fijo.

## Q. Problemas pendientes

- Tipografía real: sin decidir (deliberado, ver §H).
- Motion: decisión conceptual tomada (§I), no aplicada a `PressableScale` productivo (fuera de alcance).
- `disabled` (2.07:1) sin corregir — sin uso real en esta fase, no bloquea, pero debe revisarse antes de usarlo para algo que el usuario deba leer.
- Solo se probó **una** Tool (Pot Odds, la más simple); Equity/EV/Range Explorer (más densas) quedan sin probar.
- El test de "identidad sin logo" (§ver informe final) sigue mostrando a Home y Tools como los eslabones más débiles — mitigado, no resuelto.

## R. Clasificación

| Dimensión | Clasificación |
|---|---|
| 1. Identidad | VALIDADO CON RESERVAS |
| 2. Academia | VALIDADO |
| 3. Home | VALIDADO CON RESERVAS |
| 4. Tools | VALIDADO CON RESERVAS |
| 5. Laboratorio | VALIDADO |
| 6. Responsive | VALIDADO CON RESERVAS |
| 7. Tipografía | NO VALIDADO (deliberado) |
| 8. Motion | VALIDADO CON RESERVAS |
| 9. Accesibilidad | VALIDADO CON RESERVAS |
| 10. Anti-generic | VALIDADO |
| 11. Anti-casino | VALIDADO |
| 12. Escalabilidad | VALIDADO CON RESERVAS |

Justificación breve de cada una en las secciones A-N de arriba. Ningún ítem cayó en **FALLA** — los 4 problemas estructurales reales encontrados (§O) ya fueron corregidos dentro de esta misma fase y re-verificados.

## S. Recomendación para Fase 2

No migrar todavía globalmente, pero el sistema ya tiene evidencia suficiente para empezar por **Home** (ver informe final, sección R) una vez resueltos: (1) selección real de tipografía, (2) aplicar el patrón "label de chip con Flexible" como regla dura del componente en `FLOPLY_COMPONENTS.md` (no solo en este código de prototipo), (3) decidir formalmente `instant = 110ms` en `FLOPLY_MOTION.md`. Antes de dar por buena a Tools en particular, probar al menos una calculadora más densa (Equity o EV) — Pot Odds era la más simple de las 6 disponibles.
