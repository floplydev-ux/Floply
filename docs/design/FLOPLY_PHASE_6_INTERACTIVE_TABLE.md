# FLOPly — Fase 6: migración de `InteractiveTableExerciseView` + `InteractiveTableLesson`

Migración a "Sala Verde" del sistema de ejercicios interactivos de
Academia — la mayor costura visual pendiente, identificada en la
auditoría de la Fase 5.

## A. Objetivo

Que toda instancia real de `InteractiveTableExerciseView` use el
lenguaje Sala Verde al presentarse en Academia, y que
`InteractiveTableLesson` quede alineado con el resto del recorrido.
Sin reescribir el motor, sin cambiar currículo/pedagogía/progreso, sin
sustituir Interactive por Playable automáticamente.

## B. Arquitectura encontrada

Un solo widget real de exercise se llama `InteractiveTableExerciseView`
(el nombre del modelo de dominio, `InteractiveTableExercise`, ya estaba
tomado — 15+ referencias en `engine/pedagogy/table_exercise.dart`). Se
construye en un único sitio real: `lesson_flow.dart:106`, como *fallback*
de `_fullHeightBody()` cuando el ítem no es playable. `InteractiveTableLesson`
se construye en un único sitio real (`lesson_flow.dart`, rama
`isInteractiveTheory`). Ambos delegan la mesa+burbuja en
`TableExplanationView`, que a su vez usa `PokerTableView` y
`EducationalPanel` — las mismas superficies protegidas identificadas en
la Fase 5, ahora confirmadas también consumidas por Interactive.

`InteractiveTableExerciseView` resultó **estructuralmente casi idéntico**
a `PlayableTableExerciseView` (Fase 5): mismo `_TopBar`/`_ResultChip`/
`_AnsweredBar`, con el propio doc-comment del archivo de Playable
diciendo explícitamente que son duplicados deliberados. La única
diferencia real es `_ChoiceButtons` (Interactive: opciones genéricas,
todas visualmente iguales, sin tamaño ni razonamiento) vs. las acciones
de póker con estilo por tipo de Playable.

## C. 88 instancias

Confirmado en la Fase 5 (`InteractiveTableExercise(`: 88 instancias en
15 archivos de `lib/engine/`) y re-verificado acá: el patrón `Playable`
prioriza sobre `Interactive` en `_buildItems()`, pero **no reemplaza
nada** — solo 4 subniveles (5.3/5.4/5.5/8.6) tienen script `Playable`
hoy; el resto de Interactive sigue activo. No se hizo ninguna sustitución
automática (Sección 5 del prompt) — se descartó explícitamente: los
contratos no son equivalentes (Interactive no tiene tamaño/razonamiento;
Playable sí, y su feedback combina 2-3 ratings distintos).

## D. Variantes

No hay "tipos" de `InteractiveTableExerciseView` en el sentido de
implementaciones distintas — es un solo widget parametrizado por el
contenido del ejercicio (`InteractiveTableExercise`: pregunta, N
choices, N pasos de explicación opcionales, `strategyDependent` opcional).
Las variantes reales observadas al recorrer contenido real: preguntas
cortas vs. largas, 2 vs. 3 choices, con y sin `explanation`, showdown
(cartas de rival visibles) vs. decisión preflop/postflop simple —
todas pasan por el mismo código, sin ramas especiales.

## E. Consumidores

Búsqueda amplia (no solo el nombre del widget): constructores, imports,
tests, previews. `InteractiveTableExerciseView` solo aparece como
construcción real en `lesson_flow.dart`; el resto de menciones
(`feedback_view.dart`, `lesson_widgets.dart`, `playable_table_exercise_view.dart`)
son doc-comments. `InteractiveTableLesson` igual: única construcción
real en `lesson_flow.dart`; menciones en `table_lesson.dart` y
`test/ui/table_demo_hand_test.dart` son doc-comments.

## F. Blast radius

| Componente | Consumidores en esta fase | Otros consumidores | Decisión |
|---|---|---|---|
| `TableExplanationView` | vía Interactive (solo el `accent` que se le pasa) | Playable, teoría | Protegido — sin editar |
| `EducationalPanel` (clase) | ídem | `feedback_view.dart` (Fase 5, uso propio) | Protegido — sin editar |
| `PokerTableView` | vía `TableExplanationView` | todo Academia | Protegido — diff idéntico al baseline |
| `ratingBadge()` | `interactive_table_exercise_view.dart` (texto) | `playable_table_exercise_view.dart`, `mentor_lesson_stage_view.dart` | Sin cambios; color recalculado localmente (mismo patrón que Fase 5) |
| `LessonNavControls` (legacy) | — (reemplazado) | `mentor_lesson_stage_view.dart`, `visual_theory_stage.dart` | No modificado; `SvLessonNavControls` (ya existente, extendido con `counter` opcional) en su lugar |
| `SvButtonPrimary` | `_ChoiceButtons`, `_AnsweredBar` | Exercise/Feedback/Result/Bankroll/teoría (Fases 3-5) | Extendido: `textAlign: center` agregado (necesario para opciones largas que envuelven a 2 líneas; sin efecto visible en los consumidores de una sola línea ya existentes) |

## G. Qué se migró

`interactive_table_exercise_view.dart` completo (`_TopBar`, `_ResultChip`,
`_ChoiceButtons`, `_AnsweredBar`, `_explanationStyle`) e
`interactive_table_lesson.dart` completo (`_StepDots`, controles de
navegación). `academy_exercise_flow_test.dart` actualizado para
contemplar `.isPlayable` (deuda de la Fase 5, ver §T).

## H. Qué quedó protegido

`PokerTableView`, `TableExplanationView`, `EducationalPanel` (clase),
`ratingBadge()`, `LessonNavControls` (clase), Laboratorio
(`ExerciseCard`/`FeedbackPanel`/pantallas), `theory_view.dart`,
`mentor_lesson_stage_view.dart`, `visual_theory_stage.dart`,
`AppShell`/FAB, currículo, engine, `AcademyPlayableScripts`/
`PlayableTableExerciseView` (Fase 5, sin tocar).

## I. Componentes reutilizados

`SvProgressLinear`, `SvButtonPrimary` (con su nuevo `textAlign: center`),
`SalaVerdeType`/`SalaVerdeColors`/`SalaVerdeSpace`/`SalaVerdeRadius`,
`SvLessonNavControls`.

## J. Componentes nuevos

Ninguno de superficie. Extensión: `SvLessonNavControls.counter` (opcional,
3er consumidor real).

## K. `InteractiveTableExerciseView`

`_TopBar` → `SvProgressLinear` (`feltGreenBright`) + `_ResultChip` (color
recalculado localmente: best→`feltGreenBright`, acceptable→`warning`,
poor→`errorBright`, mismo criterio que `PlayableTableExerciseView`).
`_ChoiceButtons` → columna de `SvButtonPrimary(accent: feltGreen)`, una
por opción (en vez de un `Container` a medida): las opciones de un
ejercicio interactivo son visualmente equivalentes entre sí, a diferencia
de las acciones de póker de Playable que sí distinguen fold/check/bet.
`_AnsweredBar` → eco en `surfaceElevated` + `SvButtonPrimary` para
avanzar. `_explanationStyle` → `feltGreen` (indeciso) /
`feltGreenBright`/`warning`/`errorBright` (según rating), pasado como
`accent` a `TableExplanationView` sin tocar esa clase.

## L. `InteractiveTableLesson`

`_StepDots` → `feltGreen`/`feltGreenBright` (antes violeta), misma
animación (`SalaVerdeMotion.normal`, antes 200ms hardcodeado).
`LessonNavControls` → `SvLessonNavControls` con `counter` (extensión
nueva). `TableExplanationView` recibe `accent: feltGreen` explícito
(antes usaba el default violeta de la clase).

## M. `TableExplanationView`

Sin cambios. Se confirmó que la integración correcta es la Opción A de
la Sección 17 del prompt ("puede integrarse desde el padre"): el
`accent`/`panelIcon` siempre fueron parámetros de esta clase, nunca
valores fijos — pasar `feltGreen`/`feltGreenBright`/`warning`/`errorBright`
desde Interactive (y ya desde Playable, Fase 5) tiñe la burbuja sin
tocar una sola línea de este archivo.

## N. `EducationalPanel`

Sin cambios (clase). Su Fase 5 ya lo protegió por ser compartido con
`feedback_view.dart`; esta fase confirma que también es compartido, vía
`TableExplanationView`, con Interactive/Playable/teoría — reforzando que
protegerlo fue la decisión correcta.

## O. Responsive

300–480dp + 375×568 validado por la suite existente
(`interactive_table_exercise_test.dart`: 320/360/390/412;
`table_persistence_test.dart`: 320/360/390/412/430 × 2 alturas) más
inspección visual real en 390 y 320dp (Chromium). Sin recorte por el FAB
de `AppShell` en 320×640 (fila de acciones + CONTINUAR visibles enteras).

## P. Accesibilidad

Sin cambios de semántica — mismos labels, mismo `ratingBadge()`. El
único color nuevo introducido en este archivo específico ya estaba
validado en la Fase 5 (`feltGreen`/`feltGreenBright`/`warning`/
`errorBright`, contraste real calculado esa fase: 5.26:1/6.02:1/5.54:1/
5.19:1 según el caso).

## Q. Visual QA

Chromium real vía scratch temporal (`AppTheme.dark`, borrado al
terminar). Lección 3.1 (`InteractiveTableLesson`, guion de 7 pasos) y
lección 7.2 (`InteractiveTableExerciseView`, 3 ejercicios reales,
incluido un choice con rating "poor" real) recorridas en 390 y 320dp.
Mesa y `EducationalPanel` confirmados sin cambios visuales salvo el
acento (verde en vez de violeta); botones de opción, contador, chip de
resultado y barra de "respondido" coherentes con el resto de Academia.

## R. Tests

Existentes, leídos antes de tocar código (Sección 34):
`interactive_table_exercise_test.dart` (6, incluye contenido real de la
lección 7.2 y aserciones de texto exacto — "CORRECTO"/"ELECCIÓN"/"VOLVER
AL MAPA"), `interactive_table_lesson_test.dart` (5, lecciones
1.2/2.1/3.1/3.3 reales), `table_persistence_test.dart` (44 casos,
mesa persistente + texto completo sin truncar + opciones largas
enteras). Los 3 archivos pasan sin cambios después de la migración —
confirman que la lógica/labels no se tocaron. No se creó un archivo de
"88 instancias" aparte: `academy_exercise_flow_test.dart` (§T), una vez
arreglado, recorre las 64 lecciones reales completas y por lo tanto las
88 instancias de ejercicio dentro de ellas, sin excepción.

## S. Goldens

Ninguno existe para `InteractiveTableExerciseView`/`InteractiveTableLesson`
(`test/golden/*.dart` solo cubre Home/Tools/Bankroll/mapa de Academia/
Laboratorio/`glass_card`/`app_bottom_navigation`/`home_link_card`).
Confirmado antes de tocar código y de nuevo al cerrar.

## T. Regresión

`flutter analyze`: 0 issues.

**Deuda de la Fase 5 cerrada:** `academy_exercise_flow_test.dart` no
contemplaba `.isPlayable` (caía en un `else` que asumía `.check`,
`item.check!.correctIndex` sobre un `check` nulo). Se agregó
`_answerPlayableBest()` (elige la acción, tamaño y razonamiento de mejor
rating, con fallback a índice 0) tanto en el recorrido de las 64
lecciones como en el test de recuperación de evaluación. Sin cambiar el
comportamiento para `.interactive`/`.engine`/`.check` — el fix es
puramente aditivo.

`flutter test`: base antes de Fase 6: 1227 (1225 passed, 2 failed
preexistentes). Esta fase no agrega tests nuevos — corrige el test
preexistente roto y migra producción. **Total ejecutado: 1227, 1227
passed, 0 failed.**

## U. Cambios preexistentes

`poker_table_view.dart`: `96 insertions(+), 909 deletions(-)`, idéntico
al baseline de las 5 fases anteriores — sin cambios de esta fase.
Laboratorio (`lab_session_controller.dart`, `laboratory_screen.dart`,
`poker_bits.dart`, `session_summary.dart` + 3 archivos nuevos no
trackeados) y `visual_theory_stage.dart`/`mentor_lesson_stage_view.dart`:
diffs preexistentes, ajenos a esta sesión, sin tocar.

## V. Problemas encontrados

`SvButtonPrimary` no centraba el texto (`textAlign` sin especificar) —
sin efecto visible en sus usos previos (una sola línea, el `Container`
ya centraba el bloque completo), pero relevante acá porque
`_ChoiceButtons` reutiliza este componente para opciones que a veces
envuelven a 2 líneas (la Sección 26 del prompt pide explícitamente
inspección visual real, no solo ausencia de overflow — así se encontró).

## W. Problemas corregidos

`textAlign: TextAlign.center` agregado a `SvButtonPrimary`. Deuda de
Fase 5 (`.isPlayable` no contemplado) cerrada en
`academy_exercise_flow_test.dart`.

## X. Deuda restante

`theory_view.dart` (anti-patrón de bloques con color propio, ya
detectado en la Fase 5, aún sin migrar — deliberadamente fuera de
alcance también en esta fase, Sección 47 del prompt). Laboratorio sigue
sin migrar (Sección 48, explícitamente fuera de alcance).

## Y. Recomendación para Fase 7

Sin decidir nada: con Exercise/Feedback/Result, Playable e Interactive
migrados, Academia ya no tiene un sistema visual legacy escondido en su
recorrido de ejercicios. Los candidatos que quedan son `theory_view.dart`
(deuda pequeña y acotada) o Laboratorio (la sección más grande sin
tocar). Decisión del usuario.
