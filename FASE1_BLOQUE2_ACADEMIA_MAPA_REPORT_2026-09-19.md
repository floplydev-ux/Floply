# BLOQUE 2 — Academia: Mapa y Navegación

## Estado

**PASS.** Los 4 P1 del audit resueltos en orden, con gate completo después de cada uno. **972/972, `All tests passed!`**, `flutter analyze`: 0 issues. No se tocó lógica de unlock/progress — todos los cambios son de presentación e interacción, como exigía la regla del bloque.

## Hallazgos iniciales

- **P0:** 0
- **P1:** 4 — `available`/`inProgress` visualmente idénticos, `_ProgressStrip`/`_LevelCard` sin usar `GlassCard`, sin `Semantics` de estado, contraste predicho (`textMuted` sobre fondo oscuro)
- **P2:** 3 — sin tocar (tap fantasma en lecciones bloqueadas, gradiente de progreso inconsistente, `Opacity(0.5)` en filas bloqueadas)

## Cambios realizados

**P1-1 — Estados de nivel.** `_LevelCard` ahora muestra "EN CURSO · X/Y" cuando `level.state == LevelState.inProgress` (antes indistinguible de `available`). El conteo sale de `level.lessons`, sin tocar el engine.

**P1-2 — Cards.** `_ProgressStrip` y `_LevelCard` migraron de `Container`+`BoxDecoration` a `GlassCard` — mismo patrón que P1-A de Bloque 1, segunda superficie donde aparece la misma duplicación.

**P1-3 — Semantics.** `_LevelCard` (header de nivel) y `_LessonRow` ahora anuncian su estado en palabras ("Bloqueado"/"Disponible"/"En curso"/"Completado", más el puntaje si corresponde y una pista de qué falta si está bloqueada) — antes el único diferenciador era el ícono. Se creó `test/accessibility/academy_level_map_accessibility_test.dart` (no existía cobertura de accesibilidad para Academia hasta ahora).

**P1-4 — Contraste (confirmado, no solo predicho).** El nuevo test de accesibilidad confirmó el hallazgo predicho: "X de Y lecciones completadas" en `_ProgressStrip` fallaba WCAG AA (3.84:1). Mismo fix que en Bloque 1: `textMuted` → `textSecondary`.

## Componentes creados/modificados

- `lib/screens/academy/widgets/level_map.dart` — los 4 cambios de arriba
- `lib/l10n/app_strings.dart` — agrega `academyLevelInProgress`, `academyStateLocked/Available/InProgress/Completed`, `academyLockedLessonHint`
- `test/accessibility/academy_level_map_accessibility_test.dart` — nuevo, 2 tests

## Tests ejecutados

- `flutter analyze`: 0 issues en cada uno de los 4 pasos
- `test/ui/academy_screen_test.dart` + `academy_level1/2/3_test.dart`: verdes en cada paso, sin ajustar ningún `expect` (buscan por texto/comportamiento del árbol de widgets, no por semantics ni estilos — el `excludeSemantics: true` de P1-3 no los afecta)
- Suite completa corrida 4 veces (una por P1): 970/970 (P1-1), 970/970 (P1-2), 970/970 + 2 accessibility nuevos ya en verde salvo el contraste predicho (P1-3), **972/972 (P1-4, final)**

## Golden changes

`academy_screen_level_map`: sin diff en P1-1 (usuario nuevo del golden no tiene ningún nivel `inProgress`, el pill nunca se renderiza en ese estado exacto); 9.61% en P1-2 (boxShadow nuevo de `GlassCard`, inspeccionado visualmente — nada roto); sin diff en P1-3 (Semantics no pinta píxeles); 0.79% en P1-4 (un color de texto). Los otros 4 goldens (`home_screen`, `tools_screen`, `bankroll_screen`, `laboratory_screen_start`) sin cambios en todo el bloque — ninguno de los 4 P1 los tocó.

## Accessibility results

Antes de este bloque, Academia no tenía NINGÚN test de accesibilidad. Ahora tiene 2, ambos verdes: las 4 guidelines (tap target Android/iOS, labeled, contraste) sobre `AcademyScreen`, y una verificación específica de que las lecciones anuncian "Disponible"/"Bloqueado" en palabras.

## UX/UI re-audit

- ¿Se distingue `available` de `inProgress`? Sí, con el pill "EN CURSO · X/Y".
- ¿Se resolvió la duplicación de cards? Sí — mismo principio de Bloque 1, aplicado acá.
- ¿Los estados son accesibles ahora? Sí, verificado con un test real, no solo con el cambio de código.
- ¿El contraste pasa? Sí, confirmado empíricamente (no solo el fix — el propio test que antes fallaba).
- Ningún P0/P1 nuevo detectado en el re-audit.

## Problemas restantes

Los 3 P2 originales (tap fantasma en lecciones bloqueadas, gradiente de progreso inconsistente Home/Academia, `Opacity(0.5)` reduciendo contraste en filas bloqueadas) — sin tocar, quedan para una segunda pasada.

## Riesgos

Ninguno pendiente — los 4 cambios están cubiertos por tests+golden+accessibility, y la suite completa confirma cero regresiones en las 4 corridas.

## Regression status

**972/972, `All tests passed!`. `flutter analyze`: 0 issues.**
