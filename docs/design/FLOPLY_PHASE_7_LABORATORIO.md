# FLOPly — Fase 7: migración completa del Laboratorio

Migración a "Sala Verde" del Laboratorio de práctica estratégica, con
identidad propia (`steelBlue`/`steelBlueBright`) distinta de la de
Academia (`feltGreen`), sin tocar motor, sesiones, scoring ni pedagogía.

## A. Arquitectura encontrada

`LaboratoryScreen` (shell) + `LabSessionController` (`ChangeNotifier` con
el mixin `PlayableExerciseController`, compartido con Academia). 4 fases
(`LabPhase`: idle/question/feedback/summary). Dos motores coexisten
dentro del mismo controller: el viejo (`Exercise`/`PokerTrainerEngine.
submit`, camino "Modo clásico") y el nuevo (`ExerciseScenario`/
`StudentTurnController`, camino normal Fácil/Medio/Experto). Cualquiera
de los dos puede resolver un ítem como **mesa jugable** (`adaptToTable`/
`ExerciseScenarioAdapter`, `isTableExercise == true`) o como **tarjeta de
texto** (`ExerciseCard`/`FeedbackPanel`) — la elección la hace el motor
según el tipo de ejercicio, no la pantalla.

## B. Flujo real

```text
idle (LaboratoryDifficultySelector: Fácil/Medio/Experto + Modo clásico)
  → question (PlayableTableExerciseView si es mesa, si no ExerciseCard)
  → feedback (misma mesa con devolución, si no FeedbackPanel)
  → (repite hasta sessionLength)
  → summary (PreflopSessionSummaryView si es sesión del motor nuevo,
             si no SessionSummary — camino clásico)
```

**Hallazgo real:** el entrypoint normal (Fácil/Medio/Experto) siempre usa
el motor nuevo, y `loadNewEnginePreflopExercise()` siempre produce una
adaptación de mesa — en la práctica, la mayoría de los usuarios reales
solo ven `PlayableTableExerciseView`. El camino "tarjeta de texto"
(`ExerciseCard`/`FeedbackPanel`) es real pero vive específicamente en
"Modo clásico" (`EMPEZAR A PRACTICAR`, motor viejo) cuando el ejercicio
elegido no tiene adaptación de mesa (comparar manos, ordenar posiciones).
A diferencia de Academia (Fase 5: 0 lecciones reales usan `.engine`/
`.check`), acá SÍ hay contenido real y alcanzable.

## C. Componentes

Migrados: `laboratory_screen.dart` (header, idle, pregunta/feedback,
progreso, botones), `laboratory_difficulty_selector.dart`,
`exercise_card.dart`, `feedback_panel.dart`, `poker_bits.dart`,
`session_summary.dart`, `preflop_session_summary_view.dart`. Extendido
con justificación: `playable_table_exercise_view.dart` (ver §L).

## D. Consumidores (mapa real)

| Componente | Laboratorio | Academia | Tools | Compartido |
|---|---|---|---|---|
| `ExerciseCard` | ✓ (real, modo clásico) | ✓ (Fase 5, sin contenido real hoy) | — | Sí — migrado, beneficia a los dos |
| `FeedbackPanel` | ✓ (real) | ✓ (Fase 5, sin contenido real hoy) | — | Sí — migrado |
| `PlayableTableExerciseView` | ✓ (real, mayoría de usuarios) | ✓ (Fase 5/6) | — | Sí — extendido con `progressAccent`/`pendingAccent` (ver §L) |
| `ConceptMasteryBar` | ✓ (`SessionSummary`) | — | — | Sí, con `stats_screen.dart` (fuera de alcance) — **no tocado** |
| `LessonNavControls`/`SvLessonNavControls` | — | ✓ | — | Sin relación con Laboratorio |

## E. Estados

`idle`, `question` (mesa o tarjeta), `feedback` (mesa con devolución o
`FeedbackPanel`), `summary` (motor nuevo o clásico), disabled (CONFIRMAR
sin opción elegida), selected (opción/razonamiento). Todos migrados; no
se inventó ningún estado nuevo.

## F. Motor protegido

`LabSessionController`, `PokerTrainerEngine`, `ExerciseScenarioBuilder`,
`StudentTurnController`, `AnswerEvaluator`, `exercise_generator.dart` —
ninguno se tocó. Ver §T sobre el bug preexistente encontrado (no
corregido, fuera de alcance).

## G. Entrada

`LaboratoryDifficultySelector`: 3 tarjetas Fácil/Medio/Experto con rampa
semántica `success`/`warning`/`errorBright` (una escala de intensidad
real, no decoración — no es la identidad de sección). Header
(`_LabHeader`) migrado a reutilizar `SvSectionHeader(variant: laboratory)`
en vez de un ícono en círculo propio — mismo componente "AppBar de
sección" que ya usa el mapa de Academia.

## H. Configuración

No hay pantalla de configuración de sesión separada — la dificultad
elegida en la entrada YA arranca la sesión. Sin cambios de comportamiento.

## I. Sesión

Header con `steelBlueBright`, `SvItemProgress` (extendido con `color`
opcional, Laboratorio pasa `steelBlueBright`) en el camino de tarjeta de
texto. La mesa (`PlayableTableExerciseView`) ya traía su propio progreso
migrado desde la Fase 5 — ver §L para el ajuste real que hizo falta.

## J. Ejercicio

`ExerciseCard`: `SvSurfacePanel`, `_SituationView` con `SvChipNumericGroup`
(reemplaza `InfoChip` local — mismo patrón guardrail que ya usa Academia,
nunca trunca el valor), `_OptionTile` con acento `steelBlueBright`.
`HeroHandView`/`MiniCard` (`poker_bits.dart`): cara de carta real
(blanco/tinta) sin re-tematizar — es una carta física, mismo criterio que
protege `PokerTableView`.

## K. Acciones

Sin cambios de callbacks/valores/orden. `_OptionTile`/`_ReasoningChip`
migrados a `steelBlueBright`. Las acciones de póker de
`PlayableTableExerciseView` (FOLD/CHECK/BET/RAISE) mantienen su
tratamiento semántico universal (fold=rojo, bet/raise=verde) — es un
semáforo de acción, no la identidad de sección; cambiarlo por sección
haría que "subir" dejara de leerse como "avanzar/agresión" en Laboratorio,
rompiendo la semántica que Academia ya validó (Fases 5/6).

## L. Feedback — el hallazgo real de la fase

`FeedbackPanel`: `StrategicRating` (5 valores) agrupado en 3 bandas
semánticas (`success`/`warning`/`errorBright`) — no hay 5 tokens
semánticos distintos y las etiquetas/emojis (sin tocar) ya comunican las
5 categorías reales.

**`PlayableTableExerciseView` necesitó una extensión real, no anticipada
en el diseño de la Fase 5:** al usarlo desde Laboratorio, la barra de
progreso y el ícono de "ya respondiste" seguían en `feltGreenBright`
(identidad de Academia) dentro de una pantalla con header/UI azul —
encontrado en QA visual real, no en el diseño de antemano. Se agregaron
dos parámetros opcionales, `progressAccent`/`pendingAccent`
(default `feltGreenBright`/`feltGreen`, cero cambio visual para Academia),
y `laboratory_screen.dart` pasa `steelBlueBright` en los dos. De paso se
corrigió un bug de semántica real: el veredicto "best" usaba
`feltGreenBright` (identidad de Academia) en vez de `success` (semántico
universal) — invisible mientras solo existía un consumidor, visible en
cuanto Laboratorio expuso el mismo código con otra identidad. Cambiado a
`success` para los dos consumidores (Academia y Laboratorio) — impacto
visual en Academia prácticamente nulo (`0x32B277` vs `0x3FA66B`, dos
verdes muy cercanos).

## M. Resultado

`PreflopSessionSummaryView` (motor nuevo, la pantalla de resultado real
para la mayoría de usuarios): `AnswerVerdict` (best/acceptable/dependent/
poor) — `success`/`warning`/`steelBlueBright`/`errorBright`
respectivamente (`dependent` usa la identidad de sección: no hay un
semántico "neutral pero real" mejor para "depende del contexto").
`SessionSummary` (motor clásico): mismo criterio, `ConceptMasteryBar` sin
tocar (protegida, ver §D).

## N. Responsive

300–480dp + 375×568 cubiertos por la suite existente
(`fab_avoidance_test.dart`: 320/360/390/412/430;
`preflop_session_summary_view_test.dart`: 320/390/430) + inspección
visual real en 390 y 320dp (Chromium): idle, ejercicio de mesa (mesa +
acciones), feedback, resumen completo — sin overflow, sin recorte por el
FAB (ya cubierto por `kFabAvoidanceWidth`, Fase 5, reutilizado sin
cambios).

## O. Accessibility

Sin cambios de semántica ni de labels. Contraste real calculado —
`steelBlueBright` (el único color realmente nuevo en juego en esta fase)
mide 7.22:1 contra `background`, 6.83:1 contra `surface`, 6.29:1 contra
`surfaceElevated` — todos muy por encima del mínimo. Sin base `steelBlue`
(fill) en el sistema de tokens: se usó la variante `Bright` también para
roles de relleno silencioso (barra de progreso, tinte de opción
seleccionada) — mismo criterio ya usado para `feltGreenBright` como
relleno de barra de progreso desde la Fase 3.

## P. Visual QA

Chromium real vía scratch temporal (`AppTheme.dark`, borrado al
terminar). Recorrido completo: entrada → Fácil → mesa (acción, tamaño,
devolución con rating) → resumen del motor nuevo, en 390 y 320dp. Ver
§T sobre el bloqueo real encontrado al intentar QA visual del camino
"Modo clásico" (`ExerciseCard`).

## Q. Goldens

Uno solo existe para Laboratorio: `laboratory_screen_start` (pantalla de
inicio, 390dp). Afectado como se esperaba (header/dificultades/botones
cambiaron) — inspeccionado visualmente (acento azul del ícono, MEDIO
ahora ámbar en vez de dorado puro, botones con la tipografía Sala Verde)
antes de regenerar. `HomeScreen`/`ToolsScreen`/`BankrollScreen`/
`AcademyScreen (mapa)` sin cambios.

## R. Tests

Leídos antes de tocar código (1314 líneas en 6 archivos):
`lab_session_controller_test.dart`, `laboratory_difficulty_test.dart`,
`laboratory_new_engine_test.dart`, `laboratory_screen_test.dart`,
`preflop_session_summary_view_test.dart`, `fab_avoidance_test.dart` — más
`academy_exercise_flow_test.dart`/`academy_playable_exercise_visual_test.dart`
como regresión cruzada de los componentes compartidos. Todos pasan sin
cambios tras la migración (ningún assert de texto/lógica se tocó). No se
agregaron tests nuevos: la cobertura existente ya ejercita cada estado
real (idle, ambos motores, ambos tipos de ítem, ambos resúmenes,
responsive, FAB) con aserciones de contenido real — agregar tests
puramente visuales encima no hubiera aportado cobertura genuina distinta
(Sección 43 del prompt de fase).

## S. Regresión

`flutter analyze`: 0 issues. `flutter test`: base 1227 (Fase 6) → **ver
informe final para el total ejecutado** (sin tests nuevos esta fase, solo
corrección de la deuda del golden de Laboratorio). `flutter build web`:
ver informe final.

## T. Bugs encontrados (no corregidos — fuera de alcance)

**Bug preexistente real en el motor clásico, encontrado en QA visual:**
al abrir "Modo clásico" (`EMPEZAR A PRACTICAR`) en un build web
(`flutter run -d web-server`), `exercise_generator.dart:133`
(`_random.nextInt(template.supportedDifficulties.length)`) lanza
`RangeError: max must be in range 0 < max ≤ 2^32, was 0` — un template
elegible termina con `supportedDifficulties` vacío. Reproducido con 3
semillas distintas (1, 3, 42) en web; **no** reproduce en el test nativo
`laboratory_screen_test.dart` (semilla 1, `flutter test`, VM) — la
diferencia de comportamiento entre VM y web/DDC para el mismo seed es
conocida en Dart (el algoritmo de `Random(seed)` no está garantizado
idéntico entre backends). Causa raíz no diagnosticada a fondo (fuera de
alcance: es lógica pura del generador de ejercicios, protegida por la
Sección 4 del prompt de esta fase). **No se tocó `exercise_generator.dart`
ni ningún archivo de motor.** Se recomienda una investigación dedicada
—ver §Y.

Este bug bloqueó la captura de un screenshot real de `ExerciseCard` en
esta sesión de QA visual — la validación de ese camino se apoya en
`laboratory_screen_test.dart`/`laboratory_difficulty_test.dart` (ambos
verdes, ejercitan selección de opción, confirmar, y feedback real).

## U. Bugs corregidos

`PlayableTableExerciseView` mostraba la identidad de Academia
(`feltGreenBright`) en la barra de progreso y el eco de respuesta al
usarse desde Laboratorio — agregados `progressAccent`/`pendingAccent`
(ver §L). El veredicto "best" usaba `feltGreenBright` en vez de `success`
— corregido para los dos consumidores.

## V. Componentes nuevos/reutilizados

Nuevo: ninguno de superficie. Extendidos: `SvItemProgress` (`color`
opcional), `PlayableTableExerciseView` (`progressAccent`/`pendingAccent`).
Reutilizados: `SvSectionHeader` (variant `laboratory`, ya reservado desde
Fase 3), `SvSurfacePanel`, `SvButtonPrimary`, `SvButtonSecondary`,
`SvChipNumeric`/`SvChipNumericGroup`.

## W. Deuda restante

El bug de §T queda documentado, no resuelto. `ConceptMasteryBar`
(compartida con `stats_screen.dart`) sigue sin migrar — la única
superficie de `SessionSummary` en el lenguaje visual viejo.
`theory_view.dart` sigue como deuda de Academia, sin tocar. Tools sigue
sin migrar.

## X. Recomendación para Fase 8

Sin decidir nada: (a) investigar y corregir el bug de `exercise_generator.dart`
(§T) — no es una fase de diseño, es un bug funcional real que puede estar
afectando usuarios de "Modo clásico" en web hoy; (b) Tools, la sección de
producto más grande sin migrar; (c) `theory_view.dart`, deuda chica y
acotada. Decisión del usuario.
