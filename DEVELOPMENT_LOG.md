# Development log — Motor de ejercicios de póker

Fecha: 2026-09-09
Etapa: construcción del **motor de generación y evaluación de ejercicios**
(vertical slice: *posición + apertura preflop*), sobre la interfaz visual
ya existente (Home + navegación por pestañas).

---

## 1. Qué se implementó

Un motor completo, testeable sin UI, con las cinco responsabilidades
separadas que pedía el brief:

| Responsabilidad | Dónde vive |
|---|---|
| **Pedagogical Engine** — qué practicar/evaluar | `lib/engine/pedagogy/` |
| **Strategic Engine** — estrategia razonable de una situación | `lib/engine/strategy/` |
| **Exercise Generator** — genera situaciones desde plantillas | `lib/engine/exercises/` |
| **Answer Evaluator** — evalúa la respuesta | `lib/engine/evaluation/` |
| **Feedback Engine** — explica el porqué (progresivo) | `lib/engine/evaluation/feedback_engine.dart` |
| Fachada que une todo | `lib/engine/poker_trainer_engine.dart` |

### Modelo de valoración (no binario)

`StrategicRating`: `optimal` 🟢 / `veryGood` 🟢 / `viable` 🟡 / `dubious` 🟠 /
`bad` 🔴, con `score` 0..1. Cada `Strategy` es una lista de `StrategyOption`
(acción + **frecuencia** + rating + conceptos que la justifican). Soporta
estrategias mixtas: p. ej. una mano de frontera en BTN devuelve
`RAISE 50% (muy buena)` + `FOLD 50% (viable)` — elegir la menos frecuente
**no** se marca como incorrecto.

### Conceptos y knowledge graph

- `Concept` (id, nombre, descripción, nivel donde se introduce,
  prerrequisitos, dificultad) — `lib/engine/concepts/concept.dart`.
- `ConceptRegistry.standard()` trae **37 conceptos** (los del slice +
  matemáticas + postflop + GTO, declarados para que el grafo sea real).
  Valida en construcción: sin referencias colgantes, **sin ciclos**.
  Expone `allPrerequisites` (transitivos), `isUnlockable`,
  `topologicalOrder`.
- `UserConceptMastery`: estado `locked / introduced / practicing / mastered`
  + métricas `mastery`, `decisionAccuracy`, `reasoningAccuracy`,
  `attempts`, `mistakes`, `lastPracticed`. Transiciona sola al registrar
  intentos.
- `UserKnowledge`: fuente de verdad de la **regla fundamental** —
  `isTaught(concept)` decide si se puede exigir. Serializable
  (`toJson` / `fromJson`), sin base de datos.

### Regla fundamental (solo se evalúa lo enseñado)

Aplicada en **tres capas** independientes, para que sea imposible saltársela:

1. `PedagogicalEngine.nextGoal` solo elige objetivos sobre conceptos
   enseñados **y** con cobertura de ejercicios (`practiceable`).
2. `ExerciseTemplate.isEligible` descarta plantillas cuyos
   `evaluatedConcepts` / `requiredConcepts` no estén todos enseñados.
3. `ExerciseValidator` vuelve a chequearlo antes de entregar el ejercicio;
   si falla, se regenera.

El `StrategyEngine` **sí** usa conceptos avanzados internamente (equity
realization, EV) para construir una estrategia coherente, pero el
`FeedbackEngine` solo muestra la explicación avanzada si
`explanation.advancedConcepts` están todos enseñados. Feedback progresivo.

### Plantillas (no preguntas fijas)

`ExerciseTemplate` define conceptos evaluados/requeridos/opcionales,
dificultades soportadas, street, tipo y una `generate(GenerationContext)`.
Seis plantillas para el slice inicial:

| id | tipo | qué evalúa |
|---|---|---|
| `open_raise_decision` | chooseAction | abrir o no desde cada posición |
| `hand_in_opening_range` | handInRange | reconocer el rango de apertura |
| `widest_opening_range` | compareRangeWidth | posición ↔ amplitud de rango |
| `open_sizing` | chooseSizing | tamaño de apertura estándar |
| `compare_hands_for_open` | compareHands | ranking de manos aplicado a abrir |
| `full_open_decision` | fullDecision | challenge: BTN/CO/SB vs ciegas + razonamiento |

Cada una genera **variantes automáticas**: mano, posición, stack, sizing,
orden de opciones y sesgo de dificultad se sortean de forma controlada.

### Randomización controlada

`ExerciseGenerator.next()` sigue el pipeline pedido:
concepto → objetivo pedagógico → dificultad → plantilla elegible (peso) →
`GenerationContext` con `Deck` **sembrado** → situación → validación →
anti-repetición → ejercicio. Reintenta hasta 30 veces; nunca loop infinito.

- `Deck` (baraja con semilla): **toda** la aleatoriedad pasa por acá,
  nunca `Random()` suelto. `dealHandOfClass('AKs')`, `pick`, `shuffled`.
- Nunca cartas duplicadas, nunca folds imposibles, historial de acciones
  coherente con la posición (lo arma `SituationFactory`).

### Anti-memorización

`ExerciseHistory` guarda `ExerciseSignature` (template, concepto, posición,
clase y notación de mano, bucket de stack, respuesta correcta y un
`variantKey` de contenido). `similarityTo` da 0..1; `isTooSimilar` bloquea
repetir la misma mano+template reciente o un ejercicio ≥ 0.8 de similitud
con los últimos 6. Además `PedagogicalEngine` **rota** entre conceptos de
la misma prioridad para no machacar siempre el mismo.

### Evaluación separada

`EvaluationResult` distingue `decisionScore` de `reasoningScore`
(+`strategicRating`, `matchedConcepts`, `missingConcepts`, `feedback`,
`advancedFeedback`). Detecta “acertó de casualidad”
(`luckyGuess` = decisión fuerte + razonamiento < 0.5). El razonamiento se
evalúa con chips de “¿por qué?” que son **subconjunto de conceptos
enseñados**.

### Currículo y adaptación

- `Curriculum.standard()`: niveles 1 y 2 detallados con sus 5 sub-niveles
  (teoría / básico / intermedio / challenge / evaluación); estructura lista
  para 40 niveles y revisión cada 5 (`Curriculum.reviewEvery`).
- `RecoverySession.forWeakestConcept`: arma “Práctica de recuperación:
  {concepto}” con N ejercicios sobre el concepto débil, sin repetir el
  nivel entero.
- Dificultad 1..5; escala por más variables (posiciones, stacks no
  estándar, manos de borde, mixtas), no solo “pregunta más difícil”.

### Integración con la UI existente

- **No se tocó** el diseño ni las pantallas existentes salvo:
  - `lib/screens/root/app_shell.dart`: la pestaña Laboratorio pasa de
    `ComingSoonScreen` a `LaboratoryScreen` (un renglón).
  - `lib/l10n/app_strings.dart`: strings nuevos del Laboratorio.
- `LaboratoryScreen` + `LabSessionController` (un `ChangeNotifier`, sin
  paquetes): flujo idle → pregunta → feedback → resumen. Pide ejercicios
  al motor, muestra la situación (cartas, posición, stack, historial),
  toma la respuesta + razonamiento, evalúa, muestra feedback con desglose
  de estrategia y explicación avanzada plegable, y cierra con dominio por
  concepto + recuperación sugerida.
- El botón **PRACTICAR AHORA** de la Home ya navegaba a esa pestaña: ahora
  cae en el motor real, sin cambios en la Home.

---

## 2. Archivos

### Creados — motor (`lib/engine/`, 41 archivos, ~4.8k LOC)

```
poker/            card, hole_cards, position, poker_action, street, deck
strategy/         hand_range, opening_ranges, hand_strength, strategy, strategy_engine
concepts/         concept, concept_ids, concept_registry, user_concept_mastery,
                  user_knowledge, mastery_bucket
exercises/        exercise, poker_situation, exercise_template, generation_context,
                  exercise_history, exercise_validator, exercise_generator
exercises/templates/  situation_factory, hand_picker,
                      open_raise_decision_template, hand_in_range_template,
                      widest_range_template, open_sizing_template,
                      compare_hands_template, full_open_decision_template
evaluation/       user_answer, evaluation_result, answer_evaluator, feedback_engine
pedagogy/         curriculum, pedagogical_engine, recovery_session
poker_trainer_engine.dart   (fachada)
```

### Creados — UI del Laboratorio (`lib/screens/laboratory/`)

```
lab_session_controller.dart
laboratory_screen.dart
widgets/  poker_bits, exercise_card, feedback_panel, session_summary
```

### Modificados

- `lib/screens/root/app_shell.dart` — engancha `LaboratoryScreen`.
- `lib/l10n/app_strings.dart` — strings del Laboratorio.

### Tests (`test/`, 9 archivos, 56 casos)

```
engine/poker_primitives_test.dart      cartas, manos, 169 clases, baraja sembrada
engine/hand_range_test.dart            parser de rangos, rangos de apertura
engine/concept_graph_test.dart         grafo, prerrequisitos, regla fundamental, mastery
engine/strategy_engine_test.dart       apertura, mixtas, sizing, frecuencias ~1
engine/exercise_generator_test.dart    validez, sin cartas dup., variedad, anti-repetición,
                                       conceptos bloqueados, dificultad
engine/answer_evaluator_test.dart      decisión vs razonamiento, mixtas, feedback progresivo
engine/poker_trainer_engine_test.dart  flujo completo, anti-memorización, recuperación
ui/lab_session_controller_test.dart    flujo de sesión sin widgets
ui/laboratory_screen_test.dart         smoke test de la pantalla real
```

---

## 3. Decisiones de arquitectura

- **Tres capas para la regla fundamental** en vez de una: pedagogía filtra,
  plantilla filtra, validador verifica. Redundante a propósito.
- **Rangos de apertura explícitos con notación** (`'ATs+'`, `'A5s-A2s'`,
  `'K7o(0.5)'`) en `OpeningRanges`, parseados por `HandRange`. Curados a
  mano, con fines pedagógicos (no pretende ser GTO exacto). Se afinan sin
  tocar el motor. Las manos con `(0.5)` son la frontera → estrategias
  mixtas.
- **Fuerza de mano** vía fórmula de Chen (`HandStrength`) solo para ordenar
  manos y medir “qué tan lejos” del rango está una mano fuera de rango
  (dudosa vs mala). No se usa como equity.
- **Toda la aleatoriedad por `Deck`** con `Random` sembrado → ejercicios
  reproducibles en tests (`ExerciseGenerator(seed: ...)`).
- **Sin dependencias nuevas.** Solo `dart:math`. El controlador de la UI es
  un `ChangeNotifier` de Flutter, sin provider/riverpod/bloc.
- **Datos en Dart, no en JSON/DB.** Conceptos, currículo y rangos son
  estructuras Dart. `UserKnowledge` serializa a JSON para persistir después
  sin backend.
- **`ExerciseType` extensible**: 10 tipos declarados, 6 implementados
  (chooseAction, chooseSizing, handInRange, compareRangeWidth, compareHands,
  fullDecision). Agregar un tipo = agregar una plantilla, no tocar el motor.
- **Feedback progresivo por datos, no por `if`s**: cada `ExerciseExplanation`
  trae `basic` + `advanced` + `advancedConcepts`; el `FeedbackEngine` decide
  qué mostrar según `UserKnowledge`.

---

## 4. Qué funciona (verificado)

- `flutter analyze`: **0 errores, 0 warnings**. Quedan 43 `info` lints
  **preexistentes** en los widgets de la Home original (`withOpacity`
  deprecado, `prefer_const`), no tocados por decisión de alcance. El código
  nuevo (`lib/engine`, `lib/screens/laboratory`) da **“No issues found”**.
- `flutter test`: **56/56 pasan** (~2 s).
- El generador produce ejercicios variados (>18 enunciados distintos en 40
  tiradas, >8 manos distintas) y nunca dos idénticos seguidos.
- Nunca evalúa un concepto no enseñado (test con 60 ejercicios).
- Nunca genera cartas duplicadas (test con 80 ejercicios).
- Estrategias mixtas: la acción menos frecuente sale “viable”, no
  “incorrecta”.
- La Home y el resto de la navegación siguen intactas; la pestaña
  Laboratorio ahora corre el motor real.

---

## 5. Qué queda pendiente / cómo continuar

### Contenido (sin tocar el motor)

- **Más plantillas**: defensa de BB (call/fold/3-bet), pot odds, outs,
  c-bet, comparación de rangos por combos. Cada una es un archivo nuevo en
  `exercises/templates/` + alta en `ExerciseGenerator.defaultTemplates`.
- **Afinar los rangos** de `OpeningRanges` con una fuente GTO y ampliar las
  manos de frecuencia mixta.
- **Completar el currículo** (`Curriculum._levels`) hacia los 40 niveles;
  la estructura ya lo soporta.
- **Tipos de ejercicio** faltantes: `orderActions`, `selectCombos`,
  `calculation`, `multipleChoice` genérico.

### Motor

- `StrategyEngine` hoy solo cubre apertura preflop (RFI) y su sizing.
  Falta: enfrentar un open (defensa/3-bet), postflop. La forma
  (`Strategy` + `StrategyOption`) ya está lista para eso.
- Evaluación de razonamiento: hoy compara conjuntos de conceptos. Se puede
  hacer más fino (conceptos “clave” vs “de apoyo”, peso por concepto).
- `equity` real (Monte Carlo o tabla) para ejercicios de matemáticas.

### UI / producto

- Pantalla de **Academia**: recorrido por niveles usando `Curriculum` +
  `PedagogicalEngine.applyLesson`. Hoy sigue en “Próximamente”.
- **Persistencia**: `UserKnowledge.toJson` → `shared_preferences` o archivo
  local. Hoy el progreso vive en memoria por sesión.
- Conectar la tarjeta “ÚLTIMA SESIÓN” de la Home al resultado real de la
  última sesión de Laboratorio.
- Pantalla de **recuperación** dedicada (el motor ya la sugiere vía
  `PokerTrainerEngine.suggestedRecovery`).
- Teoría previa a cada bloque de ejercicios (`LessonKind.theory`).

### Punto de entrada para seguir

`lib/engine/poker_trainer_engine.dart` es la fachada. Un consumidor nuevo
hace:

```dart
final engine = PokerTrainerEngine();
final user = engine.newUser();               // conceptos del slice enseñados
final ex = engine.nextExercise(user);        // Exercise
final result = engine.submit(ex, answer, user); // EvaluationResult + actualiza mastery
```

---
---

# Development log — Academia 1–5 (progresión pedagógica)

Fecha: 2026-09-09
Etapa: primera versión real de la **Academia** sobre el motor ya
existente. El Laboratorio (práctica libre) queda intacto.

## 1. Qué se implementó

- **Currículo 1–5 real** (`lib/engine/pedagogy/curriculum.dart`). Se
  reemplazó la estructura de 2 niveles del slice por 5 niveles de 5
  sub-niveles cada uno, con la forma pedida
  (teoría → básico → intermedio → challenge → evaluación):

  | Nivel | Tema | Concepto(s) que introduce |
  |---|---|---|
  | 1 · Fundamentos | Cómo funciona una mano | `rules` |
  | 2 · Ranking de manos | Reconocer y comparar manos | `hand_ranking` |
  | 3 · Posición | Por qué la posición cambia todo | `position_names`, `blinds`, `utg/hj/co/btn`, `position_advantage` |
  | 4 · Rangos | No decidir solo con tu mano | `opening_range`, `range_width` |
  | 5 · Open raise | Integrar posición + rango + acción + sizing | `open_raise`, `open_sizing` |

  El orden de introducción respeta el grafo de prerrequisitos del
  `ConceptRegistry`. **No** se agregaron conceptos avanzados: 3-bet,
  defensa BB, pot odds, equity, postflop y GTO siguen bloqueados.

- **Modelo de contenido reutilizable** (`lib/engine/pedagogy/lesson_content.dart`):
  `LessonContent` (objetivo, teoría, checks, práctica), `TheoryBlock`
  (concepto / explicación / ejemplo / para-recordar), `ComprehensionCheck`
  (pregunta autoral) y `PracticeSpec` (qué pedirle al generador). Ningún
  widget hardcodea texto: todo el contenido de los 25 sub-niveles vive en
  `lib/engine/pedagogy/academy_content.dart`.

- **Motor de Academia** (`lib/engine/academy/`):
  - `AcademyProgress` — estado por lesson (`locked/available/completed`,
    `bestScore`, `attempts`, `passed`) + `lastActivity`. Serializable.
  - `AcademyEngine` — **no genera ni evalúa ejercicios**: decide qué está
    desbloqueado, enseña los conceptos de cada lesson al abrirlo
    (`openLesson` aplica los lessons 0..N para que la regla fundamental se
    cumpla siempre), calcula aprobados (evaluación ≥ 70%), arma la vista de
    niveles (`overview`) y un `snapshot` de progreso. Consume
    `PokerTrainerEngine` para todo lo demás.
  - `AcademySaveData` + `AcademyStore` (`InMemoryAcademyStore`) —
    persistencia reutilizando `UserKnowledge.toJson`.

- **Usuario nuevo real vs. usuario de prueba**
  (`PokerTrainerEngine`):
  - `newUser()` (Laboratorio / tests) ahora enseña **todos** los conceptos
    del currículo 1–5 (antes: un subconjunto hardcodeado). Sigue
    aceptando `taughtLessons` para control fino.
  - `newAcademyUser()` **nuevo**: usuario sin nada enseñado; la Academia le
    abre solo el lesson 1.1 y va enseñando a medida que avanza.

- **Dos plantillas nuevas en el generador** (era el camino de extensión
  previsto en el log anterior), para que los niveles 2 y 3 tengan
  ejercicios reales del motor:
  - `HandRankingTemplate` (`lib/engine/exercises/templates/hand_ranking_template.dart`) —
    "¿qué mano gana en el showdown?", evalúa solo `hand_ranking`. Usa
    `HandCategory` (nuevo enum en `lib/engine/poker/hand_category.dart`).
  - `PositionOrderTemplate` (`.../position_order_template.dart`) — "¿quién
    actúa antes/después en el preflop?", evalúa solo `position_names`.
  Ambas de peso bajo (0.6) para no desplazar a las de apertura.

- **UI de la Academia** (`lib/screens/academy/`):
  - `AcademyController` (`ChangeNotifier`, sin paquetes de estado) — carga
    y guarda el progreso, abre lessons, pide ejercicios al motor, corre el
    flujo teoría → ejercicio → feedback → resultado, maneja recuperación y
    reintentos.
  - `AcademyScreen` — mapa de 5 niveles con sus lessons
    (locked/available/completed) y una barra de progreso global.
  - `widgets/lesson_flow.dart` — teoría (bloques tipados), ejercicio
    (reutiliza `ExerciseCard` del Laboratorio para los del motor; tarjeta
    propia para los checks), feedback (reutiliza `FeedbackPanel`) y
    resultado (aprobado / a recuperar, con conceptos flojos +
    "Practicar recuperación" + "Reintentar").
  - `lib/persistence/file_academy_store.dart` — `FileAcademyStore` con
    `path_provider` (ya era dependencia) → archivo JSON en el directorio de
    documentos. **Sin backend, sin login, sin Firebase, sin dependencias
    nuevas.**
  - `app_shell.dart`: la pestaña Academia pasa de `ComingSoonScreen` a
    `AcademyScreen` (un renglón). Home y Laboratorio intactos.

## 2. Flujo de la Academia

```
AcademyScreen (mapa)
  └─ tocar lesson disponible
      └─ AcademyController.openLesson(id)
          ├─ AcademyEngine.openLesson  → enseña conceptos (pedagogy.applyLesson 0..N)
          ├─ phase = theory  → TheoryBlock[]  → "Continuar"
          ├─ phase = exercise
          │    ├─ engine:  engine.nextExercise(concept, difficulty) → ExerciseCard
          │    └─ check:   ComprehensionCheck autoral
          ├─ confirm → engine.submit / comparación → feedback (FeedbackPanel / texto)
          ├─ next → repetir hasta terminar los N ítems
          └─ phase = result
               └─ AcademyEngine.submitLesson(run)
                    ├─ evaluación: passed = score ≥ 0.70
                    ├─ otros: passed = true
                    ├─ passed → completed + desbloquea el siguiente
                    └─ !passed → RecoverySession + conceptos flojos
                         ├─ "Practicar recuperación" → N ejercicios del concepto débil
                         └─ "Reintentar evaluación"
  (cada paso persiste con AcademyStore.save)
```

Regla de aprobación (simple, a propósito): **evaluación ≥ 70%**. Si falla,
recuperación enfocada en el concepto más flojo (`RecoverySession`
existente) + reintento. No se repite el nivel entero.

## 3. Persistencia

- Blob JSON: `{ version, knowledge: UserKnowledge.toJson(), academy: AcademyProgress.toJson() }`.
- `FileAcademyStore` lo escribe en `<app-docs>/academy_progress.json`.
- Al reabrir la app, `AcademyController.load()` restaura conocimiento +
  progreso; si no hay archivo, arranca `newAcademyUser()` + progreso vacío.
- `resetProgress()` borra todo (para "empezar de cero" / pruebas).
- Tests con `InMemoryAcademyStore` (no tocan disco).

## 4. Regla fundamental (solo se evalúa lo enseñado)

Se mantiene en las 3 capas del motor y se **agrega una 4ª en la Academia**:
`AcademyEngine.openLesson` enseña los conceptos de todos los lessons hasta
el actual antes de generar ningún ejercicio. Los `ComprehensionCheck`
registran mastery vía `knowledge.recordAttempt` (que ya es no-op si el
concepto está bloqueado). En lessons de teoría la mini pregunta es
formativa: no registra ni bloquea.

Test dedicado (`academy_engine_test.dart`): recorre los 25 sub-niveles en
orden, genera los ejercicios de cada uno y verifica que
`ex.evaluatedConcepts ⊆ conceptsTaughtUpTo(lessonId)`; al terminar,
`three_bet`, `pot_odds`, `gto` siguen sin enseñarse.

## 5. Archivos

### Creados — motor
```
engine/poker/hand_category.dart
engine/exercises/templates/hand_ranking_template.dart
engine/exercises/templates/position_order_template.dart
engine/pedagogy/lesson_content.dart
engine/pedagogy/academy_content.dart          (contenido de los 25 sub-niveles)
engine/academy/academy_progress.dart
engine/academy/academy_engine.dart
engine/academy/academy_store.dart
```

### Creados — UI / persistencia
```
screens/academy/academy_controller.dart
screens/academy/academy_screen.dart
screens/academy/widgets/lesson_flow.dart
persistence/file_academy_store.dart
```

### Modificados
- `engine/pedagogy/curriculum.dart` — `_levels` reescrito a 5 niveles;
  `Curriculum.lessonOrder` nuevo.
- `engine/poker_trainer_engine.dart` — `academy` (AcademyEngine),
  `newUser()` enseña todo el currículo, `newAcademyUser()` nuevo.
- `engine/exercises/exercise_generator.dart` — 2 templates nuevas en
  `defaultTemplates`.
- `engine/evaluation/feedback_engine.dart` — `multipleChoice` es
  "factual"; el feedback factual agrega la explicación concreta del
  ejercicio; 2 rationale keys nuevas.
- `screens/root/app_shell.dart` — engancha `AcademyScreen`.
- `l10n/app_strings.dart` — strings de la Academia.
- `test/engine/answer_evaluator_test.dart`, `test/engine/exercise_generator_test.dart` —
  el helper `sliceUser()` aplica todos los lessons del currículo (antes:
  7 ids hardcodeados que ya no equivalen al slice de apertura).

## 6. Tests

`flutter test`: **80/80 pasan** (56 previos + 24 nuevos). `flutter analyze`:
**0 errores, 0 warnings, 0 issues nuevos**; siguen los 43 `info` lints
preexistentes de los widgets de la Home (`withOpacity`, `prefer_const`),
fuera de alcance.

Nuevos:
```
engine/academy_engine_test.dart    usuario nuevo, desbloqueos, evaluación
                                   aprobada/desaprobada, recuperación,
                                   regla fundamental en todo el currículo,
                                   completar la Academia entera
engine/academy_content_test.dart   5×5, estructura, contenido de cada
                                   sub-nivel, conceptos no evaluados antes
                                   de enseñarse, cobertura en el generador
engine/academy_store_test.dart     persistencia ida y vuelta, clear, vacío
ui/academy_controller_test.dart    flujo completo por el controlador,
                                   ejercicios del motor, evaluación
                                   desaprobada + recuperación + reintento,
                                   progreso sobrevive al "reinicio",
                                   resetProgress
ui/academy_screen_test.dart        smoke test de la pantalla real
```
El Laboratorio sigue cubierto por `ui/lab_session_controller_test.dart` y
`ui/laboratory_screen_test.dart` (sin cambios, siguen verdes).

## 7. Decisiones de arquitectura

- **La Academia consume el motor, no lo duplica.** `AcademyEngine` no
  genera ni evalúa: orquesta desbloqueos y contenido. Los ejercicios
  salen de `PokerTrainerEngine.nextExercise/submit`.
- **Contenido como datos, no en widgets.** `academy_content.dart` es un
  mapa `lessonId → LessonContent`. Se amplía/traduce sin tocar la UI.
- **Checks autorales solo donde el motor todavía no llega** (Nivel 1 ·
  reglas). No son un "segundo motor": son preguntas fijas de comprensión,
  parte de la teoría. Niveles 2–5 usan ejercicios generados.
- **Regla de aprobación mínima** (70%, reintento con recuperación
  enfocada). Nada de un sistema complejo todavía.
- **`newUser()` = usuario de prueba** (todo enseñado, para el Laboratorio y
  los tests); **`newAcademyUser()` = usuario real** (nada enseñado). Así no
  se rompió ningún test y la Academia arranca "de cero" de verdad.
- **Persistencia partida**: `AcademyStore`/`InMemoryAcademyStore` en
  `lib/engine` (Dart puro, testeable); `FileAcademyStore` en
  `lib/persistence` (usa `dart:io` + `path_provider`).

## 8. Problemas encontrados

- Las plantillas de apertura exigen `position_advantage` (y a veces
  `range_width`) como `requiredConcepts`, así que **ningún** concepto de
  los niveles 1–3 era "practicable" con el generador original → se sumaron
  2 plantillas chicas (`hand_ranking`, `position_order`) con
  `requiredConcepts` mínimos. Nivel 1 (`rules`) sigue sin plantilla: usa
  checks autorales (pendiente abajo).
- Los helpers `sliceUser()` de 2 tests dependían de ids de lesson
  concretos (`'1.1'..'2.3'`) que en el currículo nuevo ya no cubren el
  slice de apertura → ahora aplican todos los lessons del currículo. La
  intención del test (un usuario que ya sabe abrir preflop) se conserva.

## 9. Qué queda pendiente / cómo seguir

- **Plantilla de `rules`** (Nivel 1) para que también tenga ejercicios
  generados y no solo checks autorales (p. ej. `orderStreets`,
  "¿quién ganó esta mano?").
- **Conectar la Home con el progreso real**: hoy `HomeScreen` usa
  `UserProgress.mock()`. `AcademyEngine.snapshot` ya da nivel actual, %,
  lessons completados, conceptos dominados y última actividad; falta
  cargarlo (un `AcademyController` compartido o un provider chico) y pasar
  ese dato a `AcademyCard` / "ÚLTIMA SESIÓN".
- **`position_advantage` practicable de forma aislada**: hoy solo se
  ejercita dentro de `widest_range` / `full_open_decision` (que piden más
  conceptos). En Nivel 3 se practica con checks. Una plantilla propia
  ("¿quién juega con ventaja postflop, X o Y?") lo resolvería.
- **Niveles 6+**: la estructura (`MainLevel`/`Lesson`/`LessonContent`) ya
  escala; falta el contenido y, para postflop, ampliar `StrategyEngine`.
- **Revisión integrada cada 5 niveles** (`Curriculum.reviewEvery`) todavía
  no se usa en la Academia.
- **UI de progreso dedicada** (pestaña Estadísticas / Perfil) usando
  `masteryBuckets` + `AcademyProgressSnapshot`.
- Animaciones de desbloqueo / celebración al aprobar un nivel.

## 10. Fix responsive (mismo día)

Síntoma: al entrar a un ejercicio la pantalla "crasheaba" (overlay rojo de
Flutter) en ancho de celular. Causa: `RenderFlex overflowed` en dos
widgets reutilizados del Laboratorio, que solo se probaban a 800px:

- `feedback_panel.dart` — el header (rating + pills de Decisión/
  Razonamiento) era un `Row` con `Spacer`: overflow al angostar. Ahora es
  un `Wrap` (los pills bajan de línea si no entran) + padding 18→15.
- `exercise_card.dart` — la etiqueta de tipo de ejercicio
  ("COMPARAR AMPLITUD DE RANGOS") era un `Text` fijo tras un `Spacer`.
  Ahora `Expanded` + `ellipsis` + alineada a la derecha.

`AcademyController.load/_persist` envueltos en try/catch (si el disco
falla, la sesión sigue en memoria en vez de tirar una excepción async).

Test nuevo `ui/academy_exercise_flow_test.dart`: recorre **todo** el
currículo (teoría + ejercicio + feedback + resultado de los 25 sub-niveles)
a **320 / 360 / 390 / 430 dp** y verifica `tester.takeException() == null`
en cada paso. **85 tests pasan**, `flutter analyze` sin issues nuevos.

## 11. Lecciones interactivas sobre la mesa (mismo día)

Nuevo **motor de lecciones interactivas** que se enchufa DENTRO de la fase
de teoría existente: no toca el mapa de niveles, la navegación, el progreso
ni los desbloqueos. En vez de mostrar solo tarjetas de texto, ciertas
lecciones teóricas muestran una **mesa de póker que se desarrolla paso a
paso** con **burbujas educativas contextuales, una por una**.

### Modelo (`lib/engine/pedagogy/`, Dart puro)
- `table_lesson.dart` — `SeatState`, `TableSnapshot` (6 asientos fijos,
  board, bote, botón), `TableAnchor` (seat / bet / pot / board / heroCards),
  `TableStep` (foto de la mesa + texto de burbuja + ancla + resaltados +
  `dimOthers`), `TableLessonScript`.
- `academy_table_scripts.dart` — 5 guiones autorales:
  `1.1` (una mano completa hasta el showdown), `3.1` (las 6 posiciones y su
  orden), `3.3` (ventaja posicional: quién actúa último postflop),
  `4.1` (qué es un rango), `5.1` (abrir o foldear desde el BTN).
  Convención de slots: 0 = héroe abajo-centro; el orden de acción preflop
  recorre 0 → 5 → 4 → 3 → 2 → 1.

### UI (`lib/screens/academy/widgets/`)
- `poker_table_view.dart` — `TableLayout` (geometría compartida: dónde cae
  cada asiento / bote / board / fichas, y el punto al que apunta cada
  burbuja) + la mesa dibujada con `CustomPaint` (paño ovalado, riel de
  madera), asientos con avatar + posición + stack + cartas, fichas
  apostadas, botón del dealer, bote y cartas comunitarias. Resaltado con
  halo; `dimOthers` baja la opacidad de lo secundario. **Responsive**:
  todo posicionado por fracciones del área disponible.
- `educational_bubble.dart` — burbuja con número de paso, conectada por una
  línea + punto al ancla. Posicionamiento mobile-safe: se clampea para no
  salir de pantalla; si el ancla está arriba, la burbuja va abajo y
  viceversa; ancho acotado (200–300) para texto legible sin zoom.
- `interactive_table_lesson.dart` — orquesta el guion: barra de pasos
  (dots), mesa (`Expanded`), burbuja (una sola, `AnimatedSwitcher`
  fade+scale), y abajo `ATRÁS` / `3 / 8` / `CONTINUAR` (último paso →
  `PRACTICAR`). Avance **siempre manual**. Animación de entrada por paso
  con `TweenAnimationBuilder` (one-shot, sin ticker que quede corriendo).

### Integración
- `AcademyController`: `tableStep`, `tableScript` (lo resuelve por
  `lessonId`), `isInteractiveTheory`, `nextTableStep()` / `prevTableStep()`.
  En el último paso, `nextTableStep()` llama al `startExercises()` que ya
  existía → **el resto del flujo (ejercicios → feedback → resultado →
  desbloqueo) queda igual**.
- `lesson_flow.dart`: si `isInteractiveTheory`, la mesa ocupa toda la
  altura (fuera del scroll); si no, se muestra la teoría en tarjetas como
  antes. Lessons de teoría sin guion (p. ej. 2.1) no cambian.
- El texto de teoría (`TheoryBlock`) se conserva en el modelo como
  respaldo; hoy no se muestra en los lessons con guion.

### Infraestructura reutilizable para ejercicios
`TableSnapshot` / `PokerTableView` / `EducationalBubble` están pensados para
que los **ejercicios** también se presenten sobre la mesa (situación →
el usuario decide → burbujas explican). Pendiente: hoy los ejercicios
siguen usando `ExerciseCard`.

### Tests
- `engine/table_lesson_test.dart` — guiones bien formados: 6 asientos por
  paso, un solo héroe, anclas a slots válidos, cartas parseables, el bote
  no baja, burbujas ≤ 180 chars.
- `ui/interactive_table_lesson_test.dart` — recorre cada uno de los 5
  guiones en la pantalla real (320/360 dp), sin overflow ni excepciones;
  `ATRÁS` retrocede.

**94 tests pasan.** `flutter analyze`: 0 errores / warnings / issues
nuevos. `flutter build web` OK.

## 12. Ejercicios interactivos sobre la mesa (mismo día)

Segunda etapa: los ejercicios de la Academia también pueden usar la mesa
interactiva, **sin reemplazar `ExerciseCard`**. Integración progresiva:

```
lesson con set interactivo  → InteractiveTableExercise
lesson sin set              → ExerciseCard / preguntas autorales (igual que antes)
```

### Modelo (`lib/engine/pedagogy/table_exercise.dart`, Dart puro)
- `InteractiveTableExercise` — situación (`TableSnapshot`), pregunta +
  `questionAnchor` + `situationHighlight`, `choices`, `afterDecision`
  (mesa tras la decisión), `explanation` (pasos de burbuja), `concept`,
  `strategyDependent`.
- `ExerciseChoice` — label + `ExerciseRating` (**best / acceptable /
  poor**, no binario) + feedback propio.
- `ExerciseExplainStep` — burbuja tras responder (texto + anchor +
  highlight + tabla opcional).
- `InteractiveExerciseSet` — la lista de ejercicios de un lesson.

### Datos (`academy_exercise_scripts.dart`)
3 ejercicios piloto en el lesson **`5.4`** (challenge "Decisión completa"):
1. **Posición** — Hero BTN, UTG subió; ¿el BTN juega con ventaja postflop?
2. **Open/Fold** — Hero BTN con A♠7♠, todos foldean; FOLD / OPEN / ALL-IN.
3. **3-bet** — Hero BTN con A♠J♠ vs open de UTG; FOLD / CALL / 3-BET.
   Marcado `strategyDependent`: CALL es "también válido", 3-BET la "mejor
   elección pedagógica" — el ejercicio deja claro que la línea real puede
   variar según el rango. `concept: null` (3-bet es un adelanto del
   próximo nivel; nunca toca el mastery → regla fundamental intacta).

### Motor (`AcademyController`)
- `AcademyItem.interactive`, `exerciseSet`, `currentInteractive`,
  `isInteractiveExercise`, `interactiveChoice`.
- `answerInteractive(i)` — bloquea, puntúa (best 1.0 / acceptable 0.72 /
  poor 0.15), arma el feedback; `recordAttempt` solo si el concepto está
  enseñado.
- `advanceInteractive()` → `nextItem()` → siguiente ejercicio o
  `_finishLesson()` (**vuelve al flujo de resultados existente**).
- `_buildItems()` chequea el set interactivo primero; si no hay, todo
  sigue como antes (motor / checks).

### UI (`lib/screens/academy/widgets/interactive_table_exercise.dart`)
Reutiliza `PokerTableView` + `EducationalBubble` + `TableLayout`. Estados:
situación (mesa + pregunta + 3 botones grandes abajo) → respondido (mesa
completa + chip de resultado ✓/≈/✕ + feedback de la opción + "Tu
decisión: X" + CONTINUAR) → explicación (burbujas una por una) →
siguiente. `lesson_flow.dart` ramifica igual que la teoría interactiva
(mesa a toda la altura). Animaciones one-shot (`TweenAnimationBuilder`),
sin ticker corriendo.

### Tests
- `test/ui/interactive_table_exercise_test.dart` — set bien formado; flujo
  completo (mesa → decisión → bloqueo de opciones → resultado → feedback →
  explicaciones → siguiente ejercicio → resultado del lesson → "VOLVER AL
  MAPA"); sin overflow a **320/360/390/412 dp**.
- `academy_exercise_flow_test.dart` actualizado para recorrer también
  ejercicios interactivos.

**100 tests pasan.** `flutter analyze`: 0 nuevos. `flutter build web` OK.
Los lessons sin set interactivo (todos menos 5.4) siguen exactamente
igual.

## 13. Etapa 3 — Nivel 1 completo sobre la mesa (mismo día)

Objetivo: que toda la Academia use la mesa como lenguaje visual. Se
arranca por el **Nivel 1**, sin tocar mapa / orden / desbloqueos /
progreso / mastery / flujo de resultados.

### Reorganización de scripts
`academy_table_scripts.dart` y `academy_exercise_scripts.dart` pasan a ser
**agregadores finos**; el contenido vive por nivel en
`pedagogy/scripts/`:
```
scripts/
 ├── script_builders.dart      (TableScript.seats + convención de slots)
 ├── level_1_lessons.dart      1.1 · 1.2 · 1.3   (teoría interactiva)
 ├── level_3_lessons.dart      3.1 · 3.3
 ├── level_4_lessons.dart      4.1
 ├── level_5_lessons.dart      5.1
 ├── level_1_exercises.dart    1.1 · 1.2 · 1.3 · 1.4 · 1.5
 └── level_5_exercises.dart    5.4
```
Los agregadores exponen además `lessonIds` / `all` para los tests. Un solo
modelo (`TableSnapshot`, `TableAnchor`, `InteractiveTableExercise`…), sin
duplicar mesa.

### Nivel 1 — todo sobre la mesa
| Lección | Antes | Ahora |
|---|---|---|
| 1.1 | teoría interactiva + 1 check | teoría interactiva (8 pasos) + **1 ejercicio interactivo** (cómo se gana el bote) |
| 1.2 | 4 checks de texto | **teoría interactiva** (stack/ciegas/bote, 4 pasos) + **3 ejercicios** (¿cuánto hay en el bote?, pérdida máxima, para qué sirven las ciegas) |
| 1.3 | teoría texto + 4 checks | **teoría interactiva** (calles apareciendo una a una, 6 pasos) + **3 ejercicios** (siguiente calle, check, call) |
| 1.4 | 4 checks | **3 ejercicios interactivos** que juegan UNA mano completa: abrir con KK → apostar el trío en el flop → showdown |
| 1.5 (eval) | 5 checks | **5 ejercicios interactivos** con respuesta clara (bote, orden de calles, check, ganar por fold, ciegas) |

Todos con `concept: rules` (ya enseñado desde 1.1) → el mastery avanza
igual que antes. Ninguno adelanta conceptos.

### Cambio mínimo en el flujo
- `AcademyController.openLesson`: entra en fase teoría si el lesson tiene
  bloques de texto **o** un guion de mesa (así 1.2, que no tenía teoría en
  texto, muestra su teoría interactiva antes de los ejercicios).
- Nada más cambió: `startExercises` → `_buildItems` prioriza el set
  interactivo, y el resto (feedback → resultado → desbloqueo → guardado)
  es idéntico.

### Responsive
`_AnsweredBar` del ejercicio interactivo pasó a `Flexible` + ellipsis
(overflow de 1,8 px a 320 dp con etiquetas largas tipo "100 BB (TU
STACK)").

### Tests (108 en total, +8)
- `engine/table_lesson_test.dart` — reescrito: itera **todos** los guiones
  (no una lista fija), verifica que ningún guion apunte a un lessonId
  inexistente, pasos bien formados, anclas válidas, cartas parseables.
- `engine/academy_exercise_scripts_test.dart` — **nuevo**: todos los sets
  interactivos bien formados, exactamente una opción `best`, concepto
  enseñado-hasta-ese-lesson o `null`, mesas 6-max coherentes, anclas OK.
- `ui/academy_level1_test.dart` — **nuevo**: recorre **el Nivel 1 entero**
  por la pantalla real (5 lecciones, teoría + ejercicios + resultado +
  "VOLVER AL MAPA") a **320 / 360 / 390 / 412 dp**, sin overflow ni
  excepciones; verifica que desbloquea el Nivel 2, que el mastery de
  `rules` sube y que no se enseña nada adelantado.
- Ajustados `academy_controller_test`, `academy_screen_test`,
  `academy_exercise_flow_test` para las modalidades interactivas.

`flutter test`: **108/108**. `flutter analyze`: 0 nuevos. `flutter build
web` OK.

### Pendiente (próximos bloques)
Nivel 2 (ranking — showdowns reales en la mesa), Nivel 3 (3.2 · 3.4 · 3.5),
Nivel 4 (4.2 · 4.3 · 4.4 · 4.5 + teoría 4.3), Nivel 5 (5.2 · 5.3 · 5.5 +
teoría 5.3). Los guiones de teoría de 2.1 / 4.3 / 5.3 todavía usan texto.

## 14. Identidad de jugadores en la mesa (mismo día)

Se eliminan los términos genéricos "Hero" / "Villain": el usuario aparece
con su nombre real y los rivales son personajes con nombre + avatar.

### Modelo
- `models/app_user.dart` — `AppUser.current` (mutable): **fuente única**
  del nombre del usuario. Hoy default `'Juan'` (coincide con
  `UserProgress.mock().name`); un futuro perfil solo reemplaza esa
  referencia, sin tocar scripts.
- `engine/pedagogy/academy_players.dart` — `AcademyPlayer` (name +
  avatarId) y `AcademyPlayers`: elenco de 10 (Nico, Sofi, Mateo, Lara,
  Bruno, Valen, Tomi, Mica, Fran, Agus) + `pick(seed, count)` determinista
  + `seedFor(lessonId)`.
- `SeatState` — nuevos campos opcionales `name` / `avatarId` (los scripts
  NO los setean; compatible con todo lo existente).
- `TableSnapshot.withCast(userName, seed)` — completa nombres/avatares: el
  asiento del usuario usa `userName`; los rivales, personajes del elenco
  elegidos por lección (mismo elenco en toda la lección; distinto entre
  lecciones).
- `resolveTableText(raw, casted)` — plantillas en los textos pedagógicos:
  `{me}` → nombre del usuario; `{UTG}` / `{BTN}` / `{SB}` / `{BB}` / `{HJ}`
  / `{CO}` → nombre del jugador en esa posición. Un texto sin `{}` pasa
  igual.

### Integración
- `AcademyController`: `userName` (param opcional, default
  `AppUser.current.firstName`), `castTable()`, `resolveText()`,
  `currentBubbleText`, `resolveInteractive()`, `interactiveQuestionText`.
- `interactive_table_lesson.dart` / `interactive_table_exercise.dart`
  castean la mesa y resuelven burbujas / preguntas / opciones / feedback
  antes de renderizar.
- `poker_table_view.dart`: el asiento muestra **nombre** (línea 1) +
  `posición · stack` (línea 2); avatar con gradiente propio por
  `avatarId` (el usuario en verde, cada personaje con su color).

### Guiones actualizados
Reemplazadas ~20 referencias de tipo "El BTN paga" / "UTG foldea" por
`{BTN} paga` / `{UTG} foldea` (niveles 1, 3, 5 · teoría y ejercicios). Las
referencias **conceptuales** a una posición ("desde el BTN se abre más
ancho", "las ciegas actúan primeras") se mantienen como están.

### Tests (+7, total 115)
- `engine/academy_players_test.dart` — elenco sin placeholders/"Hero";
  `pick` determinista y sin repetidos; `withCast` en **todos** los guiones
  resuelve nombres y no deja marcadores `{...}`.
- `ui/academy_identity_test.dart` — el nombre del usuario está en su
  asiento; cambiarlo se refleja sin tocar el guion; no aparece
  "HERO"/"VILLAIN"/"TÚ" como nombre; hay personajes del elenco sentados;
  la burbuja de 5.1 usa el nombre de un personaje, no "{UTG}".
- Ajustados los tests de texto (`interactive_table_*`, `academy_screen`)
  para comparar contra el texto **resuelto**.

`flutter test`: **115/115**. `flutter analyze`: 0 nuevos. `flutter build
web` OK.

## 15. Nivel 2 sobre la mesa — showdowns reales (mismo día)

`scripts/level_2_lessons.dart` + `scripts/level_2_exercises.dart`.

- **2.1 (teoría)** — `_hierarchy()`: 8 pasos, cada uno un showdown real
  (board + las dos manos boca arriba); se resalta la mano ganadora y la
  burbuja nombra las categorías (pareja < doble pareja < trío < escalera <
  color < full < póker …). Cierra con la regla "primero la categoría".
- **2.2 / 2.3 / 2.4 / 2.5** — `InteractiveTableExercise`: el usuario ve un
  showdown (sus cartas · las del rival · el board) y elige **quién gana**.
  Opciones tipo `{me} · color` / `{UTG} · escalera` / `EMPATE`. Dificultad
  creciente: 2.2 categorías lejanas, 2.4 categorías adyacentes
  (escalera vs color, full vs póker), 2.5 evaluación mixta (6 situaciones).
  22 showdowns en total, mezclando manos ganadoras y perdedoras del
  usuario. `concept: hand_ranking` (enseñado en 2.1) → el mastery avanza.
- Los `PracticeSpec` del motor de 2.2–2.5 quedan de respaldo (no se usan,
  `_buildItems` prioriza el set interactivo).

Los `hand_ranking_compare` del generador siguen existiendo (los usa el
Laboratorio y `academy_engine_test`).

### Tests (+9, total 119)
- `engine/table_lesson_test.dart` + `academy_exercise_scripts_test.dart` —
  ahora también verifican **cartas sin duplicar** en cada mesa (board +
  ambas manos): las 22 situaciones de Nivel 2 pasan.
- `ui/academy_level2_test.dart` — **nuevo**: recorre el Nivel 2 entero por
  la pantalla real (teoría + 4 sets de ejercicios + resultado) a
  **320/360/390/412 dp**, sin overflow; verifica que el nombre del usuario
  está en la mesa, que desbloquea el Nivel 3 y que sube el mastery de
  `hand_ranking`.
- `academy_controller_test` — el test "consume del engine" pasó de 2.2 a
  **3.2** (aún sin migrar).

`flutter test`: **119/119**. `flutter analyze`: 0 nuevos. `flutter build
web` OK.

### Estado de la migración a la mesa
| Nivel | Teoría interactiva | Ejercicios interactivos |
|---|---|---|
| 1 · Fundamentos | ✅ 1.1 · 1.2 · 1.3 | ✅ 1.1–1.5 |
| 2 · Ranking | ✅ 2.1 | ✅ 2.1–2.5 |
| 3 · Posición | ✅ 3.1 · 3.3 | ⬜ 3.2 · 3.4 · 3.5 (motor) |
| 4 · Rangos | ✅ 4.1 · ⬜ 4.3 | ⬜ 4.2 · 4.4 · 4.5 (motor) |
| 5 · Open raise | ✅ 5.1 · ⬜ 5.3 | ✅ 5.4 · ⬜ 5.2 · 5.5 (motor) |

Próximo bloque: Nivel 3 (3.2 · 3.4 · 3.5).
