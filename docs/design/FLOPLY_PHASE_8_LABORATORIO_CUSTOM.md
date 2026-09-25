# FLOPly — Fase 8: nuevo modelo de Laboratorio (Fácil · Medio · Experto · Custom)

Se agrega Custom como cuarta modalidad del Laboratorio: el usuario elige
explícitamente qué familias de escenario practicar, en vez de aceptar una
dificultad preconfigurada. Cambio de arquitectura real, no una migración
visual — Sala Verde ya estaba resuelta desde la Fase 7.

## A. Motivación

El selector Fácil/Medio/Experto decide QUÉ practicar por el usuario.
Custom invierte eso: el usuario decide, FLOPly ejecuta.

## B. Arquitectura anterior

`LaboratoryDifficulty` (Fácil/Medio/Experto) YA era, sin saberlo hasta
auditar, un sistema de presets: cada valor expone `allowedScenarioKinds`
(`List<PreflopScenarioKind>`) y `handBias` (`DifficultyLevel`).
`LabSessionController.loadNewEnginePreflopExercise()` ya filtraba vía
`Deck.pick(allowedKinds)` — semántica OR nativa, sin necesidad de
cambiarla.

## C. Arquitectura nueva

Se generalizó la FUENTE de `allowedKinds`, sin tocar el mecanismo:

```dart
final allowedKinds = activeCustomScenarioKinds
    ?? activeLabDifficulty?.allowedScenarioKinds
    ?? PreflopScenarioKind.values;
```

`activeCustomScenarioKinds` (nuevo campo, `List<PreflopScenarioKind>?`)
y `activeLabDifficulty` son mutuamente excluyentes — `startNewEngineSession`
limpia el que no corresponda. `sessionLength` pasó de `final` a mutable
(Custom lo fija antes de arrancar; Fácil/Medio/Experto siguen con el
default de siempre, sin cambio de comportamiento). **Cero cambios en
`PokerTrainerEngine`/`ExerciseScenarioBuilder`/`StudentTurnController`/
`exercise_generator.dart`** — la Sección 24 del prompt de fase se cumple
literalmente, no por interpretación laxa.

La UI de "elegir categorías" (`LaboratoryCustomSelector`) es un
sub-estado puramente local de `_LaboratoryScreenState`
(`_showingCustom`), no un `LabPhase` nuevo — "configurando Custom" sigue
siendo `LabPhase.idle` (ningún dato de sesión existe todavía), la misma
razón por la que la Sección 34 del prompt permitía no tocar la máquina
de estados existente.

## D. Fácil / E. Medio / F. Experto

Sin cambios de comportamiento. Confirmado por regresión: los tests
existentes (`laboratory_difficulty_test.dart`, `laboratory_new_engine_test.dart`,
`fab_avoidance_test.dart`) pasan sin modificar ninguna aserción.

| Dificultad | `allowedScenarioKinds` | `handBias` |
|---|---|---|
| Fácil | `[openRaise]` | `easy` |
| Medio | `[openRaise, defenseVsOpen, shortStack]` | `standard` |
| Experto | los 6 valores | `hard` |

## G. Custom

`LaboratoryCustomSelector`: header (CUSTOM / "Elegí qué querés
practicar"), 6 tiles multi-select (checkbox + `kind.label`), 4 chips de
cantidad (5/10/15/20, default 10), resumen ("N áreas · M ejercicios") o
hint de selección vacía, CTA COMENZAR (deshabilitado sin selección — la
Sección 18 del prompt se resuelve en la UI, nunca llega al controller una
lista vacía). "ATRÁS" vuelve a la lista de dificultades sin tocar el
controller — no hay estado que deshacer porque nada se escribió todavía
(Sección 33).

## H. Categorías disponibles

Las 6 reales, en lenguaje de jugador: Open Raise, Defensa de ciegas,
3-Bet, Encarar un 3-Bet, Stack corto, C-Bet. Promovidas a
`PreflopScenarioKind.label` (getter en el propio enum, mismo criterio
que `LaboratoryDifficulty.label` ya usaba) — antes vivían duplicadas como
`_kindLabel` privado de `preflop_session_summary_view.dart` (Fase 7);
esa duplicación se eliminó al promoverlas.

## I. Categorías descartadas y por qué

Ninguna de las 6 familias reales fue descartada — la auditoría confirmó
que las 6 son igual de generables por `ExerciseScenarioBuilder`
(incluida `cbetDecision`, hoy gateada a Experto solo por progresión
pedagógica asumida, no por limitación técnica: en Custom el usuario
elige explícitamente, así que esa progresión no aplica). Turn, river,
equity/EV/pot-odds/blockers como "escenario generable" no existen en el
motor hoy (existen como herramientas en Tools, un concepto distinto) —
correctamente fuera del selector, no se muestran como opciones ficticias
ni como "próximamente" sin justificación de UX.

## J. Motor

Sin cambios. `Deck.pick(allowedKinds)` es el único punto de contacto
entre la selección del usuario y el motor — recibe una lista más
específica, nunca una lógica nueva.

## K. Generador

Estrategia B del Checkpoint de auditoría ("el controller puede filtrar
escenarios antes de generarlos") — ya existía, se generalizó su fuente.
No hizo falta ninguna de las estrategias A/C/D.

## L. Randomización

`Deck.pick` intacto — `nextInt(items.length)`, semilla real. Verificado
con test de motor (no solo de UI): 40 intentos con 2 categorías
seleccionadas ven las 2, nunca una tercera (`laboratory_custom_test.dart`,
grupo "multi-selección").

## M. Tests

11 nuevos, 0 modificados en su aserción (1 test existente,
`laboratory_screen_test.dart`, necesitó un `ensureVisible()` adicional
porque la 4ª tarjeta empujó el botón hacia abajo — mismo patrón que sus
tests hermanos ya usaban, ninguna aserción cambiada):

- `laboratory_custom_test.dart` (7, motor/controller): aislamiento
  (openRaise solo, cbetDecision solo), multi-selección real (A∪B, 40
  intentos), session length exacto (10 → summary justo después del
  décimo), Custom no toca el motor clásico, `customScenarioKinds` vacía
  prohibida por `assert`, limpieza cruzada Custom↔dificultad.
- `laboratory_custom_flow_test.dart` (4, UI real sobre `LaboratoryScreen`):
  Custom aparece y abre el selector, ATRÁS cancela sin arrancar nada,
  selección vacía no arranca, selección múltiple + cantidad arrancan con
  exactamente esos datos.

## N. Web

Recorrido completo en Chromium: entrada → CUSTOM → 2 áreas + 20
ejercicios → COMENZAR → mesa real (`PlayableTableExerciseView`, sin
cambios) → progreso "1/10" en `steelBlueBright`. Sin excepciones de
consola. Custom **no reproduce** el bug de `exercise_generator.dart`
(Fase 7) — confirmado por diseño (usa exclusivamente el motor nuevo) y
por QA real.

## O. Responsive

300–480dp + 375×568 cubiertos por la suite existente (FAB/dificultad) +
inspección visual real en 390 y 320dp del selector Custom completo (6
checkboxes + 4 chips + resumen + CTA) — sin overflow en ningún ancho.

## P. Accessibility

`_AreaTile`/`_LengthChip` usan `Semantics(selected:, button:)` explícito
— el estado seleccionado no depende solo del color (check azul + borde +
peso de fuente + `Semantics.selected`). Touch targets ≥44px. Contraste:
mismo `steelBlueBright` ya validado en la Fase 7 (6.29–7.22:1 según la
superficie).

## Q. Visual QA

Chromium real: entrada con las 4 tarjetas, selector Custom vacío (CTA
deshabilitado + hint), con 2 selecciones (CTA habilitado + resumen),
sesión iniciada con esas 2 categorías y 20 ejercicios. 390 y 320dp.

## R. Bugs

Ninguno introducido. El bug de `exercise_generator.dart:133`
(`RangeError`, Fase 7) permanece documentado, sin tocar — Custom no pasa
por ese código (usa el motor nuevo exclusivamente), así que no lo agrava
ni lo esconde.

## S. Deuda restante

El bug de Fase 7 sigue sin resolver — sigue siendo la recomendación más
fuerte para la próxima fase. `ConceptMasteryBar`/Tools/`theory_view.dart`
sin migrar (sin relación con esta fase). Custom no expone `handBias`
(usa `DifficultyLevel.standard` por defecto) ni perfil de rival
(`OpponentProfile.balanced`) — MVP deliberadamente chico (Sección 14 del
prompt); ampliar esos ejes queda como posible trabajo futuro, no una
omisión.
