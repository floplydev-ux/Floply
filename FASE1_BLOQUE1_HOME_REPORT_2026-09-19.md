# BLOQUE 1 — Home + Navegación Global

## Estado

**PASS.** Los 4 hallazgos P1 originales están resueltos, sin regresiones. Al arreglar P1-D (settings), la propia suite de accesibilidad destapó una capa de hallazgos de contraste que antes quedaba oculta detrás del fallo de tap-target — se trataron como un 5º hallazgo (P1-E, ver abajo) y también quedaron resueltos y verificados. Suite completa: **970/970, `All tests passed!`** — primera vez en esta fase con el árbol 100% verde, incluyendo accessibility.

## Hallazgos iniciales

- **P0:** 0
- **P1:** 4 — redundancia de progreso (ContinueLearningCard + AcademyProgressCard), 6 elementos tocables compitiendo antes del scroll, 4 recetas de card distintas, settings 38×38dp
- **P2:** 6 — quedan sin tocar, registrados para una segunda pasada (según instrucción explícita)

## Cambios realizados

**P1-A — Cards.** `PracticeRoomCard` dejó de reimplementar su propio `Container`/`Row` y ahora delega en `HomeLinkCard` (ya generalizado, ya usado por Bankroll/Tools/Coach). Quedan 2 familias de card reales (`GlassCard` + `HomeLinkCard`) más el hero bespoke (`_HeroShell`, sin cambios — uso único, no ameritaba abstracción).

**P1-B — Progreso duplicado.** Se retiró `AcademyProgressCard` como card separada. Su información (lecciones completadas/total, conceptos dominados) pasó a vivir dentro de `ContinueLearningCard`, como una línea secundaria bajo el CTA — nunca una segunda barra de progreso. El % sigue mostrándose una sola vez.

**P1-C — Jerarquía.** Se agregó un eyebrow chico ("SEGUÍ EXPLORANDO") entre el hero y el grupo Laboratorio/Bankroll/Tools/Coach, para separar visualmente "lo que hay que hacer ahora" del resto de la app. Cero destinos ni navegación tocados.

**P1-D — Settings.** El botón de settings del header sigue midiendo 38×38 visualmente, pero el área tocable real ahora es 48×48 (`SizedBox` centrado alrededor del círculo existente) — cumple `androidTapTargetGuideline` e `iOSTapTargetGuideline`. Se agregó además un `Semantics(button: true, label: ...)` que antes no existía (el botón no tenía NINGÚN label de accesibilidad).

**P1-E — Contraste (hallazgo nuevo, no parte del audit original, resuelto en la misma pasada a pedido explícito del usuario).** 3 fixes puntuales, todos reusando tokens ya existentes en vez de inventar colores: el label "Teoría" pasó de `textMuted` a `textSecondary` (mismo tono que ya usa el label de nivel, arriba); el CTA principal del hero pasó de un gradiente ad-hoc `[violetBright, violetPrimary]` a `AppColors.violetGradient` (`[violetPrimary, violetDeep]`, ya usado en la barra de progreso de la misma card); las labels inactivas de la bottom nav pasaron de `textMuted` a `textSecondary`. Los tres verificados empíricamente contra el test real, no por cálculo manual.

## Componentes creados/modificados

- `lib/screens/home/widgets/practice_room_card.dart` — reescrito como delegación sobre `HomeLinkCard`
- `lib/screens/home/widgets/academy_progress_card.dart` — **eliminado** (retirado, no dejado muerto)
- `lib/screens/home/widgets/continue_learning_card.dart` — agrega `_ProgressSummaryLine` (lecciones + conceptos dominados) a `_ProgressBody`/`_CompletedBody`
- `lib/screens/home/widgets/home_header.dart` — hit-area de 48×48 + `Semantics` en el botón de settings
- `lib/screens/home/home_screen.dart` — quita `AcademyProgressCard`, agrega el eyebrow de sección
- `lib/l10n/app_strings.dart` — retira `academyProgressSectionTitle` (quedaba sin uso), agrega `homeMoreLabel` y `homeProfileButtonLabel`
- `lib/screens/stats/stats_screen.dart` — un doc-comment corregido (referenciaba a `AcademyProgressCard`, ya retirado)
- `lib/widgets/bottom_navigation.dart` — color del label inactivo (P1-E)
- `test/accessibility/core_screens_accessibility_test.dart` — comentario actualizado para reflejar el estado real (las 4 guidelines pasan)

## Tests ejecutados

- `flutter analyze`: 0 issues en las 4 implementaciones (P1-A/B/C/D), cada una verificada por separado
- `test/ui/home_screen_test.dart` + `test/ui/app_shell_test.dart`: 11/11 en cada paso, sin ningún ajuste necesario en los `expect` existentes (buscan por texto/comportamiento, no por estilos — sobrevivieron los 4 cambios sin tocarlos)
- Suite completa (`flutter test --concurrency=1`), corrida 5 veces (una por P1-A/B/C/D + P1-E): **969 corridos/968 passed en las primeras 4 (el hallazgo de contraste, ya conocido, todavía sin resolver), 970/970 en la última** (P1-E) — cero regresiones nuevas en ningún paso, y la primera corrida 100% verde de toda esta fase

## Golden changes

`test/golden/screens_golden_test.dart` → `home_screen`, actualizado 3 veces (una por cada cambio visual real):
1. P1-A: 6.46% diff (círculo de ícono de Laboratorio 44→40px, alpha 6%→8%)
2. P1-B: 57.08% diff (se eliminó una card completa, todo lo de abajo se reacomoda)
3. P1-D: 15.93% diff (corrimiento de pocos px del ícono de settings por el nuevo hit-area) — **inspeccionado visualmente** (`home_screen_masterImage.png` vs `_testImage.png`) antes de aceptarlo, no solo por el %.
4. P1-E: 3.59% diff (CTA más oscuro) — inspeccionado visualmente, confirmado que es solo el color.

`core_ui_golden_test.dart`: `GlassCard`/`HomeLinkCard` sin cambios en toda la fase — ninguno de los dos se tocó. `app_bottom_navigation` sí cambió en P1-E (18.87% diff, color del label inactivo) — inspeccionado visualmente antes de aceptar, confirmado que el tab activo no se movió.

## Accessibility results

**Las 4 guidelines pasan hoy** (`androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) en `AppShell` y en `ToolsScreen`.

- Settings: **resuelto** (P1-D).
- Contraste — 3 hallazgos reales, destapados al arreglar el tap-target (antes invisibles porque el test corta en el primer guideline que falla), **resueltos en la misma pasada (P1-E)**:

| Elemento | Contraste encontrado | Mínimo WCAG AA | Fix |
|---|---|---|---|
| "Teoría" (lessonKindLabel, hero) | 3.66:1 | 4.5:1 | `textMuted` → `textSecondary` |
| "COMENZAR ACADEMIA" (CTA del hero) | 3.38:1 | 4.5:1 | gradiente → `AppColors.violetGradient` |
| Labels inactivos de la bottom nav | 4.14:1 | 4.5:1 | `textMuted` → `textSecondary` |

El CTA del hero era el más severo (más lejos del mínimo, y es el botón principal de toda la Home) — verificado que ahora pasa, no asumido. Los labels de bottom nav confirmaban el P2 #9 que ya había salido en la auditoría original — ese P2 queda resuelto como efecto colateral de P1-E.

## UX/UI re-audit

- ¿Se resolvió la redundancia de progreso? Sí — un solo bloque, un solo % visible.
- ¿Se resolvió la dilución de acciones? Sí, parcialmente — de 6 a 5 elementos tocables, con separación visual clara entre "acción principal" y "el resto".
- ¿Se resolvió la duplicación de cards? Sí — 2 familias reales en vez de 4.
- ¿Se resolvió el tap target? Sí, verificado por el propio test automatizado.
- Ningún P0/P1 nuevo de UX/UI (los 3 hallazgos de contraste son de **accessibility**, no de composición/jerarquía).

## Problemas restantes

- **5 de los 6 P2 originales** — sin tocar, según instrucción explícita (doble CTA a Laboratorio, Bankroll solo desde Home, tipografía de título de card, idioma "Practice Room"/"Coach", breakpoint de 480px muerto).
- El P2 #9 (bottom nav sin assertion de contraste propia) quedó resuelto como efecto colateral de P1-E — ya no es un pendiente.

## Riesgos

Ninguno pendiente — todo lo tocado está cubierto por tests+golden+accessibility, y la suite completa confirma cero regresiones en las 5 implementaciones (P1-A/B/C/D/E).

## Regression status

**970/970, `All tests passed!`. `flutter analyze`: 0 issues.** Primera corrida 100% verde de toda la Fase 1, incluyendo accessibility.
