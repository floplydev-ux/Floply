# FLOPly — Fase 9: eliminación del Modo Clásico del Laboratorio

El Laboratorio queda con únicamente cuatro modalidades: Fácil, Medio,
Experto y Custom. El Modo Clásico (motor viejo wireado directamente
dentro de `LabSessionController`) y el atajo de desarrollo "PRACTICAR
(MOTOR NUEVO)" se eliminaron por completo — ni botón, ni ruta, ni campo
inaccesible.

## A. Motivación

Fase 8 dejó cuatro entradas visibles: Fácil/Medio/Experto/Custom (motor
nuevo) y, debajo de un divisor "MODO CLÁSICO (DESARROLLO)", dos botones
más — uno hacia el motor viejo real, otro hacia el motor nuevo sin
restricción de dificultad (un atajo de desarrollo). Ninguno de los dos
era un modo de producto: el primero es el origen del `RangeError`
documentado en Fase 7; el segundo nunca tuvo entidad propia, solo
existía para poder probar el motor nuevo antes de que Fácil/Medio/
Experto/Custom existieran. Esta fase los elimina y deja el Laboratorio
conceptualmente simple.

## B. Estado anterior

```
LaboratoryScreen._IdleView
 ├── LaboratoryDifficultySelector (Fácil/Medio/Experto/Custom)
 ├── _ClassicModeDivider ("MODO CLÁSICO (DESARROLLO)")
 ├── botón "EMPEZAR A PRACTICAR"      → LabSessionController.start()
 └── botón "PRACTICAR (MOTOR NUEVO)"  → startNewEngineSession() sin restricción
```

`start()`/`_loadNext()` usaban `PokerTrainerEngine.nextExercise(knowledge)`
**sin** `concept`/`difficulty` — dejaba que `PedagogicalEngine.nextGoal`
eligiera ambos automáticamente. Ese patrón de llamada, exclusivo de
Laboratorio, es el que originaba el `RangeError` de Fase 7.

## C. Arquitectura anterior (auditoría de consumidores, Sección 4)

Antes de borrar nada se armó la matriz de consumidores real (no supuesta):

| Código | Consumidor real | ¿Exclusivo de Modo Clásico? | Decisión |
|---|---|---|---|
| `LabSessionController.start()`/`_loadNext()` | Solo Laboratorio | Sí | **REMOVE** |
| `table_exercise_adapter.dart` (`TableExerciseAdaptation`/`adaptToTable`) | Solo `LabSessionController._loadNext()` (doc-comment del propio archivo lo confirmaba) | Sí | **REMOVE** |
| `session_summary.dart` (`SessionSummary` widget) | Solo la rama `!isNewEngineSession` de `LaboratoryScreen` | Sí | **REMOVE** |
| `exercise_generator.dart` / `exercise.dart` (`Exercise`, `ExerciseGenerator`, templates) | **`AcademyController.startRecovery()`** (recuperación) y la práctica de cualquier lesson con `content.practice` sin script interactivo (`AcademyExerciseScripts.forLesson(id) == null`) — ambos llaman `engine.nextExercise(knowledge, concept:, difficulty:)`/`engine.submit(...)` | **No** — el comentario del archivo decía lo contrario y estaba desactualizado | **KEEP** |
| `PokerTrainerEngine.nextExercise`/`.submit` | Academia (arriba) | No | **KEEP** |
| `ExerciseCard`/`FeedbackPanel` (widgets) | Academia (`exercise_view.dart`/`feedback_view.dart`) además de Laboratorio | No | **KEEP** (su uso dentro de Laboratorio sí era exclusivo de Modo Clásico y se eliminó) |
| `PokerTrainerEngine`, `ExerciseScenarioBuilder`, `StudentTurnController`, `LabSessionController` (motor nuevo) | Fácil/Medio/Experto/Custom | — | **KEEP, intacto** |

### Hallazgo real de la auditoría

`exercise.dart` y `exercise_generator.dart` tenían un comentario "LEGACY
(Fase 8.8): ... La Academia no usa nada de este archivo" — **falso**,
verificado leyendo `academy_controller.dart` directamente
(`startRecovery()` línea ~814, práctica de lesson línea ~902,
`_gradeEngineItem` línea ~925). El comentario se corrigió en el propio
código (Sección 4 de esta fase existe exactamente para atrapar este
tipo de error antes de borrar algo compartido). `exercise_generator.dart`
y `exercise.dart` **no se tocaron más que ese comentario**.

## D. Arquitectura final

```
LaboratoryScreen._IdleView
 └── LaboratoryDifficultySelector (Fácil/Medio/Experto/Custom) — nada más
```

`LabSessionController` quedó con un solo motor: `ExerciseScenarioBuilder`
→ `StudentTurnController` → `ExerciseScenarioAdapter` →
`PlayableExerciseController`. `currentPlayable`/`isTableExercise` ya no
tienen una rama `_adaptation` (motor viejo) — solo `_newAdaptation`.
`onPlayableResolved`/`advancePlayable` perdieron el `if (_newAdaptation
!= null) {...} else {...}`: ahora el cuerpo que antes era el `if` es
incondicional (el motor nuevo es el único que existe).

## E. Qué se eliminó

- `LabSessionController.start()`, `_loadNext()`, `confirm()`,
  `toggleOption()`, `toggleReasoning()`, `toggleAdvanced()`, `next()`.
- Campos: `current` (`Exercise?`), `lastResult`, `_adaptation`
  (`TableExerciseAdaptation?`), `results`, `selectedOptionIds`,
  `selectedReasoningIds`, `showAdvanced`, `sessionDecisionScore`,
  `sessionReasoningScore`, `reasoningResults`, `recovery` (getter local
  de Laboratorio — `engine.suggestedRecovery` en sí sigue existiendo,
  Academia lo sigue necesitando).
- `lib/screens/laboratory/widgets/session_summary.dart` (archivo
  completo — resumen del motor viejo, sin otro consumidor).
- `lib/engine/exercises/table_exercise_adapter.dart` (archivo completo
  — `TableExerciseAdaptation`/`adaptToTable`, sin otro consumidor).
- `LaboratoryScreen._ClassicModeDivider`, `_QuestionView`,
  `_FeedbackView` (widgets exclusivos del camino de texto del motor
  viejo).
- Botones "EMPEZAR A PRACTICAR" y "PRACTICAR (MOTOR NUEVO)", y el
  divisor "MODO CLÁSICO (DESARROLLO)".
- Strings: `labStartSession`, `labStartNewEngine`, `labClassicModeLabel`,
  `labAgain`, `labConfirm`, `labNext` (verificado uno por uno: cero
  consumidores fuera de lo eliminado).
- Tests exclusivos de Modo Clásico (detalle en sección I).

## F. Qué se conservó

- `exercise.dart`, `exercise_generator.dart`, templates,
  `PokerTrainerEngine.nextExercise`/`.submit` — Academia los sigue
  necesitando (recuperación + práctica sin script interactivo).
- `ExerciseCard`/`FeedbackPanel` (`exercise_card.dart`/
  `feedback_panel.dart`) — compartidos con Academia
  (`exercise_view.dart`/`feedback_view.dart`); ya no los usa
  Laboratorio, pero el archivo no se toca.
- `labYourReasoning`, `labShowAdvanced`, `labDecision`, `labReasoning`,
  `labSessionSummary` — viven en `feedback_panel.dart`/
  `exercise_card.dart`/`PreflopSessionSummaryView`, con consumidor real
  fuera de lo eliminado.
- `LaboratoryDifficulty`, `PreflopScenarioKind`, `ExerciseScenarioBuilder`,
  `StudentTurnController`, Custom completo (Fase 8) — sin cambios.
- `PokerTableView` — sin tocar (ver Sección N).
- Academia, Bankroll, Tools, `theory_view.dart` — sin tocar.

## G. `exercise_generator.dart`

Caso B de la Sección 9 del prompt de fase ("tiene consumidores
legítimos del motor actual → conservarlo"). Se mantiene íntegro; el
único cambio fue corregir su comentario de cabecera, que afirmaba
incorrectamente que Academia no lo usaba.

## H. Bug RangeError (Fase 7)

El patrón de llamada que lo originaba —
`engine.nextExercise(knowledge)` sin `concept`/`difficulty`, dejando que
`PedagogicalEngine.nextGoal` elija ambos— era exclusivo de
`LabSessionController.start()`/`_loadNext()`, ya eliminado. Academia
**nunca** llama `nextExercise` sin `concept`/`difficulty` explícitos
(siempre pasa `session.conceptId`/`spec.targetConcept` y
`session.difficulty`/`spec.difficulty`), así que no hereda el riesgo.
No se invirtió tiempo en diagnosticar la causa exacta del `RangeError`
en sí (por qué VM y web/DDC divergen con la misma semilla) — la
Sección 10 del prompt de fase pedía explícitamente no hacerlo. Se
documenta como: **el patrón de llamada que lo origina desapareció al
eliminar el camino funcional que lo usaba**, no "se arregló".

## I. Tests eliminados

19 tests eliminados en total — todos exclusivos del Modo Clásico o de
piezas que dejaron de tener consumidor:

- `test/ui/laboratory_screen_test.dart` — **archivo completo** (1 test):
  probaba el flujo de UI del Modo Clásico de punta a punta.
- `test/engine/table_exercise_adapter_test.dart` — **archivo completo**
  (7 tests): único consumidor de `adaptToTable`/`TableExerciseAdaptation`,
  eliminados junto con el archivo que prueban.
- `test/ui/lab_session_controller_test.dart` (8 tests): "el camino
  viejo (start()) sigue llegando a summary...", "start() (camino viejo)
  resetea opponentProfile/difficulty...", "el flujo idle→question→
  feedback→summary funciona" (usaba `start()`/`toggleOption()`/
  `confirm()`), "no se puede confirmar sin elegir una opción", el grupo
  completo "ejercicios de mesa (ver TableExerciseAdaptation)" (3 tests:
  usaban `start()` + `skipToTableExercise` sobre el motor viejo),
  "elegir mal repetidamente deja constancia de conceptos débiles".
- `test/ui/laboratory_difficulty_test.dart` (2 tests): "start() (camino
  viejo) resetea la dificultad de Laboratorio a null", "también
  funciona para el camino viejo (start())" (dentro del grupo
  `exitSession`).
- `test/ui/preflop_session_summary_view_test.dart` (1 test): "el camino
  viejo sigue mostrando el resumen viejo sin cambios (regresión)".

Ninguna aserción de un test **conservado** se debilitó — donde un test
tapeaba el botón "PRACTICAR (MOTOR NUEVO)" eliminado, se reescribió
para tapear una dificultad real (Experto, que da el mismo alcance sin
restricción de familias) en vez de borrar la cobertura.

## J. Tests conservados

Todos los tests del motor nuevo (`loadNewEnginePreflopExercise`,
`startNewEngineSession`, Custom, dificultades, `exitSession`/
`returnToIdle` del motor nuevo, Fase 10 opponentProfile/difficulty) se
mantienen con sus aserciones originales intactas. Se reescribieron
(sin tocar aserciones sobre el motor) los puntos de entrada que usaban
el botón "PRACTICAR (MOTOR NUEVO)" eliminado:

- `laboratory_new_engine_test.dart` "Test 1": ahora tapea EXPERTO.
- `preflop_session_summary_view_test.dart`: `playFullSession()` ahora
  tapea EXPERTO (con `ensureVisible` — ver bug encontrado en QA).
- `laboratory_custom_test.dart`: el test que verificaba que `start()`
  limpiaba `activeCustomScenarioKinds` se reescribió para verificar que
  `startNewEngineSession(labDifficulty:)` (la única forma real de
  arrancar Fácil/Medio/Experto) hace esa misma limpieza — la garantía
  de exclusión mutua sigue probada, solo que contra el motor que
  realmente queda.

## K. Tests nuevos

- Garantía negativa (Sección 23 del prompt): `laboratory_difficulty_test.dart`
  ahora verifica que el selector muestra exactamente Fácil/Medio/
  Experto/Custom y que ningún texto "CLÁSICO"/"CLASSIC"/"MOTOR NUEVO"
  aparece en pantalla.
- Flujo real completo reemplazando al del camino viejo:
  `laboratory_difficulty_test.dart` — FÁCIL → ejercicio → respuesta →
  feedback → summary → volver al selector, con el motor nuevo de
  punta a punta vía tap real.

## L. Custom

Sin cambios de comportamiento ni de categorías — sigue siendo
exactamente lo de Fase 8: 6 familias reales, selección múltiple,
5/10/15/20 ejercicios, CTA deshabilitado sin selección, cancelación sin
efectos secundarios.

## M. Motor nuevo

Intacto: `PokerTrainerEngine`, `ExerciseScenarioBuilder`,
`StudentTurnController` no se tocaron. `LabSessionController` perdió
únicamente el código del motor viejo — su API pública hacia el motor
nuevo (`startNewEngineSession`, `loadNewEnginePreflopExercise`,
`onPlayableResolved`, `advancePlayable`, `exitSession`, `returnToIdle`)
tiene el mismo comportamiento observable de antes, con las ramas
muertas (`if (_newAdaptation != null) {...} else {/* motor viejo */}`)
eliminadas.

## N. Web (QA visual real, Chromium)

Recorrido real en `flutter run -d web-server`, 390×844, cero errores de
consola en todo el recorrido:

- **Fácil**: arranca en BTN open-raise, resuelve con FOLD, feedback real
  ("NO ES LA MEJOR", concepto "Ventaja posicional"), sale limpio al
  selector.
- **Medio**: arranca correctamente (mismo patrón de mesa).
- **Experto**: recorrido completo de 10 ejercicios (incluyó un escenario
  de `cbetDecision` con board de flop y CHECK/BET, confirmando que
  Experto expone las 6 familias) hasta `RESUMEN DE LA SESIÓN` real
  (10 ejercicios, 88 de calidad, 8 BEST/2 POOR, conceptos practicados y
  "para seguir trabajando" con datos reales) y vuelta al selector con
  "VOLVER AL LABORATORIO".
- **Custom**: selector con 6 checkboxes + 4 chips de cantidad; elegir
  Open Raise + 3-Bet mostró "2 áreas · 10 ejercicios" y arrancó una
  mesa real perteneciente a esas familias.
- En ningún punto del recorrido apareció "Modo Clásico" ni el botón de
  desarrollo.

## O. Responsive

Cubierto por la suite existente (`laboratory_difficulty_test.dart`,
`laboratory_custom_flow_test.dart`, golden CI) — el layout del selector
al perder el divisor + 2 botones queda **más corto**, no más overflow;
confirmado también por inspección visual del golden regenerado.

## P. Accessibility

Sin cambios: `Semantics(selected:, button:)` de `_AreaTile`/`_LengthChip`
(Custom) intactos; el selector de dificultad no tenía semántica propia
para el divisor eliminado (era decorativo).

## Q. Regresión

```
Tests antes (Fase 8):     1238
Tests eliminados:           19  (Modo Clásico y su único consumidor de prueba)
Tests nuevos:                0  (cobertura reemplazada, no sumada — mismos
                                  escenarios ahora contra el motor que queda)
Tests finales:             1219
Passed:                   1219
Failed:                      0
```

`flutter analyze`: 0 issues. `flutter build web`: ver Sección R.

Durante la propia regresión de esta fase se encontró y corrigió un bug
introducido por mí mismo (no confundir con deuda pre-existente): el
helper `playFullSession` de `preflop_session_summary_view_test.dart`
tapeaba "EXPERTO" sin `ensureVisible` primero, y en el escenario de
320×640 el tap caía fuera de la mesa de render — arreglado agregando el
mismo `ensureVisible` que ya usan los tests hermanos.

## R. Git audit

Baseline (`git status --porcelain`) tomado antes de tocar cualquier
archivo. El diff contra esa baseline, después de todos los cambios de
esta fase, es exactamente:

```
 M lib/screens/laboratory/widgets/session_summary.dart  →  D (eliminado)
 M test/ui/laboratory_screen_test.dart                   →  D (eliminado)
?? lib/engine/exercises/table_exercise_adapter.dart       →  (eliminado, deja de listarse)
?? test/engine/table_exercise_adapter_test.dart           →  (eliminado, deja de listarse)
```

Todo lo demás que `git status` muestra (Academia, Bankroll, Tools,
`written_theory_view.dart`, etc.) ya estaba presente en la baseline
—no es de esta fase— y se clasifica **PREEXISTING**. No hay ningún
archivo **UNEXPECTED**. `poker_table_view.dart` sigue con el mismo
`git diff --stat` de siempre: `96 insertions(+), 909 deletions(-)`.

## S. Deuda restante

- **Hallazgo real de esta fase, no corregido (fuera de alcance):**
  `LabSessionController.sessionLength` es mutable desde Fase 8 (Custom
  la fija). `startNewEngineSession(labDifficulty:)` solo la pisa si se
  pasa `customSessionLength` — si un usuario juega una sesión Custom de
  N ejercicios y después, **sin recargar la pantalla**, elige Fácil/
  Medio/Experto, esa sesión hereda la cantidad N de la sesión Custom
  anterior en vez del default de 8. Reproducido en vivo durante el QA
  de esta fase (Custom 10 → Experto mostró "1/10", no "1/8"). No es un
  bug introducido por Fase 9 (el mecanismo es idéntico al de Fase 8,
  sin relación con el Modo Clásico eliminado) — se documenta como
  candidato a una futura fase, no se toca acá.
- El `RangeError` de Fase 7 no se "arregló" en sentido estricto — el
  único camino que lo producía ya no existe (ver Sección H).
- `ConceptMasteryBar`/Tools/`theory_view.dart` siguen sin migrar a Sala
  Verde — sin relación con esta fase.
