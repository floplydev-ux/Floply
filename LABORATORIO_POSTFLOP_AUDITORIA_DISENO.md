# FLOPly — Auditoría y definición de alcance para "Laboratorio Postflop"

**Fecha:** 2026-09-19
**Alcance de esta tarea:** solo lectura + diseño, mismo formato que `EV_AVANZADO_AUDITORIA_DISENO.md`. No se modificó ningún archivo de `lib/`, `test/` ni `assets/` — únicamente se creó este documento.

**Validación de baseline:**
```
flutter analyze              → 0 issues
flutter test --concurrency=1 → 892/892
```

**Disparador**: `AUDITORIA_CHECKLIST_2026-09-18.md`, §3, marca "Laboratorio" como 🟡 P0 — "motor y sesión sólidos, pero centrado en preflop, falta postflop completo". Es el único ítem P0 con trabajo de código real pendiente (Android release depende de acciones externas; el resto de P0 ya está ✅).

---

## 1. Estado actual — qué existe hoy y qué se puede reutilizar

### 1.1 Dos motores de ejercicio coexisten, los dos preflop-only

`lib/screens/laboratory/lab_session_controller.dart` orquesta **dos** sistemas en paralelo (confirmado leyendo el archivo completo, no una suposición):

| Motor | Piezas | Alcance |
|---|---|---|
| "Viejo" | `PokerTrainerEngine`/`Exercise`/`adaptToTable` (`lib/engine/exercises/exercise.dart`, `templates/*`) | Preguntas de RFI/sizing/comparación de manos — sin fold/call/3-bet, sin postflop |
| "Nuevo" (el que usa el selector de dificultad, el CTA principal) | `ExerciseScenarioBuilder` → `ExerciseScenario` → `StudentTurnController` → `AnswerEvaluator`, sobre `GameState`/`ActionResolver` reales | 5 familias, **todas preflop** (`PreflopScenarioKind`: `openRaise`, `defenseVsOpen`, `threeBet`, `facingThreeBet`, `shortStack`) |

Esto ya está documentado explícitamente en el propio código: el doc-comment de `LaboratoryDifficulty` (`lib/engine/exercises/laboratory_difficulty.dart`) dice literalmente *"hoy `ExerciseScenarioBuilder` solo genera situaciones preflop — no hay postflop, equity, pot odds ni lectura de board todavía... 'Experto' acá significa todo lo que el motor puede generar hoy, no la integración completa que describe la visión de producto"*. No es un hallazgo nuevo de esta auditoría — ya estaba señalado, sin resolver.

### 1.2 Cada ejercicio es UNA decisión, no una mano jugada de punta a punta

Hallazgo estructural clave, verificado en `student_turn_controller.dart` y en `lab_session_controller.onPlayableResolved`: `StudentTurnController.applyHeroAction` aplica exactamente una acción del héroe vía `ActionResolver`, y el controller evalúa esa acción **inmediatamente** (`AnswerEvaluator.evaluate(scenario, action)`) sin nunca llamar a `ActionResolver.advanceStreet` ni volver a hacer decidir a ningún rival después. El motor de mano completa (`GameState`/`ActionResolver`, ver el informe de EV Avanzado §1.2) puede avanzar calles — pero **nada en Laboratorio lo usa para eso hoy**. Cada ejercicio es un "snapshot con una sola bifurcación", nunca una mano jugada hasta el final.

Esto significa que "agregar postflop" no es solo "agregar familias de escenario nuevas" — es agregar un tipo de flujo de sesión que hoy no existe en ningún lado: una decisión que puede tener una continuación (el rival responde, la calle avanza, el héroe decide de nuevo).

### 1.3 `ExerciseScenarioBuilder`: cómo se arma un escenario hoy (patrón 100% reutilizable, pieza por pieza)

Leído completo (`lib/engine/exercises/exercise_scenario_builder.dart`). Cada método (`openRaise`, `defenseVsOpen`, etc.) hace lo mismo en el fondo:
1. `ScenarioBuilder.freshHand` reparte cartas.
2. `_resolveBackgroundActors` avanza a cualquier jugador "de fondo": si tiene mano conocida, decide vía `OpponentPolicy.decide`; si no, foldea automáticamente.
3. Se aplican una o dos acciones "de guion" (p. ej. el héroe abre, un rival 3-betea) vía `ActionResolver.apply` + `OpponentPolicy.decide`.
4. `_finish` arma el `ExerciseScenario` en el punto exacto de decisión del héroe.

Esta receta es exactamente la que un postflop scenario builder necesitaría reutilizar — el patrón ya está probado y es sólido. El bloqueo no es de patrón, es de una pieza puntual: el paso 2/3 depende de `OpponentPolicy.decide`, que **lanza `UnsupportedError` si `state.street != Street.preflop`** (`game/opponent_policy.dart`, verificado línea por línea). Cualquier escenario que necesite que un rival actúe después del flop no se puede armar con el código actual, sin excepción.

### 1.4 `OpponentPolicy`: mismo gap que ya identificó `EV_AVANZADO_AUDITORIA_DISENO.md`

Cito el informe anterior porque el hallazgo es literalmente el mismo problema, no una coincidencia de redacción: **no existe en ningún lado del proyecto un modelo de qué tan seguido un rival haría fold/call/raise postflop**. `OpponentProfile` (`balanced`/`passive`/`tag`) solo tiene campos preflop (`openFrequency`, `threeBetPercentile`, `callPercentile`, `threeBetMultiplier`) — ninguno aplica después del flop. Esto bloquea **dos features a la vez**: EV Avanzado Modelo B (multi-calle) y cualquier postflop de Laboratorio. Ver la sección 10 de este informe para la implicancia de diseño que esto tiene.

### 1.5 El bloqueo de contenido — corregido tras un error de método en la primera versión de este informe

**Corrección explícita**: la primera versión de esta sección concluía, incorrectamente, que 9 de los 10 conceptos postflop no tenían ningún contenido real, basándose en `grep -rn "ConceptIds.<id>"` sobre `lib/`. Ese grep solo encuentra usos del **símbolo Dart** — y el contenido real de Academia no vive en Dart, vive en `assets/curriculum/curriculum_spec.json`, donde cada teoría etiqueta sus conceptos como **strings planos** (`"cbet"`, `"board_texture"`, ...), nunca como `ConceptIds.cbet`. El grep original nunca podía encontrar ese contenido porque buscaba el símbolo equivocado. Repetido correctamente contra el JSON:

| Concepto postflop | Ocurrencias reales en `curriculum_spec.json` |
|---|---|
| `cbet` | 18 |
| `board_texture` | 18 |
| `polarization` | 10 |
| `value_bet` | 9 |
| `bluff` | 8 |
| `range_advantage` / `nut_advantage` | 5 cada uno |
| `bluff_catcher` | 4 |
| `blockers` | 3 |
| `overbet` | 0 |

`board_texture` tiene un subnivel completo con `estado_redaccion: "listo"` (T075-T086+, nivel 4, subniveles 4.3-4.4) y `cbet` tiene un **nivel entero** ("El flop: c-bet", nivel 8, subniveles "La iniciativa y la c-bet", "C-bet por valor, farol y con proyecto", "C-bet según el board", "C-bet según la posición", frecuencia y tamaño) — contenido real, publicado, parte de las 326 teorías ya confirmadas. Solo `overbet` (que no hace falta para la familia recomendada) está genuinamente vacío.

**Conclusión corregida de 1.5**: para la familia que este informe termina recomendando (§10 — c-bet en un board que favorece al agresor), el contenido de Academia que la respalda **ya existe y ya está publicado** (nivel 4 para board texture, nivel 8 para c-bet). El bloqueo real de "Laboratorio postflop" es de **motor** (`OpponentPolicy`, §1.4), no de currículo — al revés de lo que decía la primera versión de esta sección. Sigue siendo cierto que `overbet` (y, en menor medida, contenido específicamente enfocado en *decisiones* de c-bet en vez de *teoría* de c-bet) tiene huecos, pero no es el bloqueo principal que se describía acá.

**Nota aparte, menor**: `Concept.introducedAtLevel` en `concept_registry.dart` dice `'4.1'` tanto para `cbet` como para `boardTexture` — pero el contenido real de `cbet` vive en el nivel **8**, no el 4 (`board_texture` sí coincide, nivel 4). Es una metadata desactualizada en el registro (no afecta el gating real, que se hace por `taughtConcepts`, no por este campo), pero vale la pena señalarla como inconsistencia menor a corregir en algún momento.

### 1.6 Deuda técnica ya identificada y ya aprobada, pero sin implementar — adyacente, no la misma tarea

La memoria del proyecto (`laboratorio-motor-preflop`, sesión previa, Fase 0.5 cerrada, Fase 1 sin arrancar) documenta un problema **distinto** pero relacionado, ya auditado y con especificación aprobada por el usuario: `PreflopStrategy._facingRaiseStrategy` (verificado en el código actual, `lib/engine/exercises/preflop_strategy.dart` líneas ~143-183) sigue evaluando **toda** decisión de encarar una subida con un único número (percentil Chen de la mano), ignorando posición, rango real del rival y sizing — y `facingThreeBet` sigue generando al rival con un rango fijo `{AA,KK,AKs}` en vez de un rango real. Esto es trabajo ya spec'd (`PreflopRangeBook`, `DefenseVsOpenStrategy`, `FacingThreeBetStrategy`) que no depende de nada de lo que este informe propone, y que mejora la calidad de lo que YA existe (preflop) sin necesitar ni una línea de contenido nuevo ni tocar `OpponentPolicy` postflop. Lo señalo porque es el candidato más barato y ya aprobado de "seguir mejorando Laboratorio" si el postflop completo resulta demasiado grande para encarar ahora — ver la Recomendación.

---

## 2. Problema de definición — qué significaría "Laboratorio postflop" en concreto

A diferencia de EV Avanzado (una fórmula que se generaliza), acá "postflop" implica al menos tres capas independientes, cada una con su propio costo:

1. **Motor**: que un rival pueda actuar después del flop (`OpponentPolicy` extendida) y que una sesión pueda encadenar más de una decisión del héroe (loop de sesión nuevo).
2. **Autoría pedagógica**: qué es "correcto" en un board concreto — a diferencia de preflop (169 clases de mano, tabla finita y ya recorrida por el proyecto), postflop depende del board (texturas casi infinitas), la posición, la acción previa y el rango que llegó a esa calle. No hay una tabla de 169 filas equivalente; hace falta una heurística de autoría (categorías de textura × rango de continuación × sizing) bastante más grande que `OpeningRanges`/`PreflopRangeBook`.
3. **Currículo**: las teorías de Academia que enseñan esos conceptos antes de que Laboratorio los evalúe. **Corrección tras verificar el JSON real (§1.5): para c-bet/board texture específicamente esta capa ya existe y está publicada** — no es un bloqueo general, sigue siéndolo solo para conceptos puntuales sin contenido (`overbet`) o para familias futuras que toquen otros conceptos.

Cualquier alcance que se elija tiene que decidir explícitamente cuánto de estas capas necesita tocar — construir motor sin que el currículo correspondiente exista (cuando no exista) deja ejercicios que evalúan conceptos no enseñados (regla rota); para c-bet/board texture, en cambio, la capa 3 ya está resuelta y el trabajo real es la 1 y la 2.

---

## 3. Alternativas de alcance

### Modelo A — Una sola decisión postflop, board conocido, sin encadenar calles

Igual que las 5 familias preflop de hoy, pero el punto de decisión del héroe es en el flop (o turn/river, fijo, no elegido por el alumno): p. ej. "está tu turno de decidir si haces c-bet" o "el rival apostó el flop, ¿pagás/subís/foldeás?". Un board conocido, una decisión, feedback, listo — misma forma que ya tiene cada ejercicio de hoy.

**Qué hace falta que hoy no existe:**
- `OpponentPolicy` postflop **acotada al mínimo indispensable**: para la familia recomendada (el héroe decide si c-apuesta), lo único que un rival de fondo necesitaría decidir es un **check** al llegar al flop (para que le vuelva a tocar al héroe) — no necesita reaccionar DESPUÉS de la decisión del héroe, porque el ejercicio termina ahí (igual que hoy termina en la decisión del héroe en preflop). Es la extensión más chica posible: ni siquiera necesita modelar fold/call/raise, solo "check al agresor preflop".
- Una heurística de autoría postflop, acotada a **una** familia bien definida por vez (p. ej. empezar solo por "¿hacés c-bet en un board seco, como preflop-raiser, sin resistencia?" — el caso más simple de política postflop real: c-bet de rango completo en un board que favorece al agresor).
- **Contenido de Academia: ya existe** para `cbet` (nivel 8, "El flop: c-bet") y `board_texture` (nivel 4) — ver §1.5, corregido. No hace falta escribir teoría nueva para esta familia.

### Modelo B — Multi-calle dentro de un mismo ejercicio (el héroe puede decidir en más de una calle)

El héroe decide en el flop; según su elección y la del rival, la mano puede seguir al turn/river con una decisión nueva dentro del MISMO ejercicio.

**Qué hace falta que A no necesita:**
- `OpponentPolicy` postflop que reaccione DESPUÉS de la decisión del héroe, en cada calle — no solo antes.
- Un loop de sesión nuevo en `LabSessionController`/`StudentTurnController` (hoy asume una sola decisión por ejercicio, ver §1.2) — cambio de arquitectura real, no solo una familia de escenario más.
- Un modelo de evaluación para una SECUENCIA de decisiones, no una sola — `AnswerEvaluator`/`AnswerResult`/`PreflopSessionSummary` (que ya asume una tupla `(kind, result)` por ejercicio) necesitarían repensarse.
- Contenido de Academia para muchos más conceptos (c-bet, turn barrel, river decisions, cada uno con su propia teoría).

### Modelo C — Currículo primero (relevante solo para los conceptos que de verdad faltan, ya no para c-bet/board texture)

Con el error de §1.5 corregido, este modelo ya no aplica a la familia recomendada (su currículo ya existe). Sigue siendo la respuesta correcta si en el futuro se quisiera construir una familia que dependa de un concepto genuinamente sin contenido (`overbet` es el único caso confirmado hoy, o cualquier concepto nuevo que no esté ya en `concept_registry.dart`): escribir la teoría de Academia antes de construir el motor/ejercicio que la evalúe.

---

## 4. El problema del rival postflop — separando quién pone cada dato

Mismo criterio que ya estableció `EV_AVANZADO_AUDITORIA_DISENO.md` §4, aplicado acá — y con la misma conclusión: **nada de esto se infiere en runtime sin una fuente citable.**

| Dato | ¿Quién lo define? | Nota |
|---|---|---|
| Qué board sale | **FLOPly genera**, con `BoardGenerator` (ya filtra por textura mecánica: paired/monotone/two-tone/rainbow) | Reutilizable tal cual, sin cambios |
| Si el board "favorece" al agresor o al defensor (para decidir si c-bet es correcto) | **Necesita autoría nueva** — `BoardGenerator` explícitamente NO clasifica esto ("textura... no heurísticas de peligroso/seguro: eso es juicio pedagógico", su propio doc-comment) | No es un dato que el motor ya sepa calcular; hay que escribirlo |
| Con qué frecuencia el rival c-apuesta/paga/sube en cada situación | **Tiene que salir de una tabla de autoría explícita** (mismo patrón que `OpeningRanges`/el `PreflopRangeBook` ya spec'd), nunca de un número inventado en runtime | Ningún dato de este tipo existe hoy en el proyecto para postflop |
| Qué mano tiene el rival en cada punto | **FLOPly ya sabe hacerlo** vía `HandRange.sample`/`ScenarioBuilder`, iguales a como arma las manos preflop hoy | Reutilizable |
| Si la decisión del héroe fue correcta | **Necesita autoría nueva** — un `PostflopRangeBook`/heurística equivalente a `PreflopRangeBook`, pero contra board concreto en vez de 169 clases fijas | El trabajo de diseño más grande de todo este informe |

---

## 5. UX propuesta (solo si se avanza con Modelo A)

Mínima, reutilizando la mesa que ya existe (`PlayableTableExerciseView`, compartida con Academia — nada nuevo de UI): el héroe ve su mano, el board (3 cartas), el historial de acciones previas (ya lo muestra `DecisionContext`/la mesa hoy), y decide entre las acciones legales que ya calcula `LegalActionEngine` (ahora incluyendo `check`/`bet` reales, no solo fold/call/raise preflop). Mismo patrón de feedback que ya tiene cada ejercicio (veredicto + explicación) — nada nuevo de UI, todo el trabajo nuevo es de motor y contenido.

Nada de UI para Modelo B/C se detalla acá: ambos necesitan resolver primero sus respectivos bloqueos de motor/contenido antes de que una pantalla tenga sentido.

---

## 6. Comparación de las 3 propuestas

| Alcance | Descripción | Complejidad | Riesgo de supuestos | Utilidad |
|---|---|---|---|---|
| **A — Una decisión postflop** | Board conocido, una familia bien acotada (ej. c-bet en board seco), sin encadenar calles | Media — reutiliza el patrón entero de `ExerciseScenarioBuilder`/mesa/feedback; lo nuevo es una extensión mínima de `OpponentPolicy` (un simple "check" de fondo) + una heurística de autoría chica. El currículo de la familia recomendada ya existe (§1.5, corregido) | Medio — cualquier heurística de "board favorece a X" es autoría pedagógica explícita, con la misma disciplina que ya usa `PreflopRangeBook` (tabla citable, no inferencia en runtime) | Cierra la brecha P0 del checklist de forma incremental y verificable, con un alcance chico y concreto que se puede ampliar familia por familia (mismo patrón que ya funcionó con las 5 de preflop) |
| **B — Multi-calle** | El héroe puede decidir en más de una calle dentro del mismo ejercicio | Alta — necesita `OpponentPolicy` postflop reactiva, un loop de sesión nuevo, y repensar cómo se evalúa una secuencia de decisiones | Alto — cada calle agrega su propia tabla de frecuencias/rango, multiplicando la superficie de autoría necesaria | Más fiel a una mano real, pero es una reescritura de la arquitectura de sesión, no una extensión |
| **C — Currículo primero** | Escribir teoría de Academia para un concepto postflop que todavía no la tenga (hoy: solo `overbet`) antes de tocar el motor interactivo que lo evalúe | Baja en código, alta en contenido si aplica — no aplica a la familia recomendada (su currículo ya existe) | Bajo desde el motor — el riesgo se traslada por completo a la calidad del contenido nuevo, si hiciera falta escribirlo | Solo relevante para familias futuras atadas a conceptos sin contenido — no es un paso necesario para empezar con A |

---

## 7. Compatibilidad con la filosofía de FLOPly

| Restricción | Modelo A | Modelo B | Modelo C |
|---|---|---|---|
| No evaluar conceptos no enseñados (`UserKnowledge.isTaught`) | ✅ el contenido de la familia recomendada (cbet/board_texture) ya está publicado — se cumple automáticamente vía el mismo filtro que ya usa `ExerciseScenarioAdapter.adapt` | 🔴 multiplica cuántos conceptos hace falta enseñar antes de poder evaluarlos | ✅ es exactamente lo que este modelo resuelve, para lo que todavía haga falta |
| No inventar frecuencias/comportamiento rival sin fuente | ✅ si la tabla de autoría se cita igual que `PreflopRangeBook` | ⚠️ más tablas, mismo riesgo multiplicado | ✅ no aplica todavía (sin motor) |
| No duplicar motores/UI existentes | ✅ reutiliza `GameState`/`ActionResolver`/`LegalActionEngine`/mesa jugable tal cual | ✅ igual, aunque con más cambios estructurales | ✅ no toca motor |
| Explicable pedagógicamente | ✅ una familia bien acotada se explica igual que las 5 de hoy | ⚠️ una secuencia de 2-3 decisiones es más difícil de resumir en un solo feedback | ✅ es contenido, diseñado para explicarse por definición |
| Testeable deterministamente | ✅ mismo patrón que los tests actuales de `ExerciseScenarioBuilder` | 🟡 más estados intermedios que cubrir | N/A (sin motor) |
| Se integra limpio con la arquitectura actual | ✅ extiende `OpponentPolicy` (mismo patrón condicional por calle que ya usa para preflop) | 🟡 necesita un loop de sesión nuevo en `LabSessionController` | ✅ no toca `lib/engine/exercises`/`lib/screens/laboratory` en absoluto |

---

## 8. Tests necesarios (según alcance, sin implementarlos)

Comunes a cualquier alcance que toque motor (A o B):
- `OpponentPolicy` postflop: decide correctamente para cada perfil (`balanced`/`passive`/`tag`) en el board/situación de la familia elegida.
- `OpponentPolicy` sigue lanzando `UnsupportedError` para calles/perfiles fuera de lo que la extensión cubre — nunca degrada en silencio a una decisión inventada.
- `ExerciseScenarioBuilder` (nuevo método postflop): arma el `GameState` real en el punto de decisión, con el board/historial esperado — mismo patrón que los tests actuales de las 5 familias preflop.
- Regla de conceptos: un escenario nunca declara `evaluableConcepts` que el usuario no tenga en `taughtConcepts` — test de integración con `UserKnowledge`, análogo a los que ya existen para preflop.
- `isCoherentCell`-equivalente para la tabla de autoría postflop nueva, si aplica (mismo patrón que preflop, ver `preflop_authoring.dart`).

Solo si se implementa B:
- Secuencia de 2+ decisiones del héroe en el mismo ejercicio, con el pot/stack acumulado correcto entre calles (verificable contra `GameState`/`ActionResolver`, que ya tienen su propia suite).
- Evaluación agregada de una secuencia — qué pasa si la decisión del flop fue "best" pero la del turn fue "poor" (necesita una regla de agregación, hoy inexistente).

Solo si se implementa C:
- Tests de currículo (`curriculum_spec_test.dart`, `theory_content_test.dart`) extendidos para las teorías nuevas — mismo patrón que ya cubre las 326 actuales, sin motor nuevo que testear.

---

## 9. Riesgos de arquitectura

- **Extender `OpponentPolicy` sin las mismas garantías que preflop**: el riesgo real. Hoy `OpponentPolicy._decidePreflop` se apoya en tablas citables (`OpeningRanges`, `HandStrength`) — una extensión postflop apurada podría terminar con un `if` heurístico sin fuente, exactamente lo que el pedido de EV Avanzado (y este) pide evitar. Mitigación: cualquier extensión tiene que citar su fuente igual que `OpponentProfile` ya lo hace para preflop (su doc-comment dice "comportamiento original Fase 4"), o quedar marcada explícitamente como heurística provisional de baja confianza (mismo patrón que la tabla piloto BB-vs-CO de la memoria del proyecto, con "niveles de confianza declarados por fila").
- **Reescribir el loop de sesión (`LabSessionController`) sin necesidad**: si se elige Modelo A, no hace falta tocar `LabSessionController.onPlayableResolved`/`StudentTurnController` en absoluto — el patrón de "una decisión por ejercicio" ya sirve. Solo Modelo B lo requiere; no adelantarlo si se elige A.
- **Evaluar conceptos no enseñados**: el riesgo más fácil de cometer por apuro — construir el motor de una familia postflop antes de que exista la teoría de Academia que la respalda. La regla `UserKnowledge.isTaught` ya existe para prevenir esto automáticamente (un ejercicio que evalúa un concepto no enseñado para el usuario actual simplemente no se genera, ver `ExerciseScenarioAdapter.adapt`), así que el riesgo real no es "se rompe en producción" sino "el contenido nunca se termina de escribir y la familia queda inutilizable para usuarios nuevos" — otra razón para no separar motor y contenido por mucho tiempo.
- **Duplicar `BoardGenerator`/`ComboEngine`/`EquityEngine`**: bajo riesgo si cualquier heurística postflop nueva los reutiliza tal cual (ya lo hacen Blocker Explorer y el resto de Tools) en vez de reinventar generación de boards o card removal.
- **Acoplamiento con Tools/EV Avanzado**: el hallazgo de §1.4 sugiere una oportunidad, no un riesgo — si se termina construyendo una `OpponentPolicy` postflop mínima para Laboratorio Modelo A, esa misma pieza (o su tabla de autoría) podría alimentar después el Modelo B de EV Avanzado (fold%/call% "sugeridos, citables, editables" en vez de solo campos en blanco) — sin que ninguna de las dos features dependa de la otra para funcionar hoy.

---

## 10. Recomendación técnica

**Modelo A, acotado a una sola familia postflop bien elegida**, es lo único que se sostiene con la evidencia reunida sin comprometer las reglas ya establecidas del proyecto (`isTaught`, no inventar comportamiento rival). Con el error de §1.5 corregido, su tamaño real de trabajo es **más chico de lo que la primera versión de este informe estimaba**: el motor (`GameState`/`ActionResolver`/`LegalActionEngine`/mesa jugable) ya está listo, el currículo de la familia recomendada (`cbet`/`board_texture`) ya está publicado — lo único genuinamente nuevo es una extensión mínima de `OpponentPolicy` (un "check" de fondo, nada de fold/call/raise todavía) y la heurística de autoría de "qué board favorece al agresor" para esa única familia. Mismo patrón incremental que ya funcionó para construir preflop familia por familia, y Tools calculadora por calculadora.

**Modelo B** no debería empezar hasta que A esté construido y haya al menos una familia postflop funcionando de punta a punta — reescribir el loop de sesión para encadenar calles sin tener todavía ninguna heurística postflop probada sería resolver el problema más difícil primero.

**Modelo C** ya no es un prerrequisito de A (era la conclusión errónea de la primera versión de este informe) — sigue siendo la respuesta correcta únicamente si una familia futura depende de un concepto sin contenido real (hoy, solo `overbet`).

**Recomendación de secuencia concreta**, si se decide avanzar:
1. Elegir UNA familia postflop mínima: c-bet de rango completo como preflop-raiser en un board que lo favorece, sin resistencia del rival — análoga en simplicidad a `openRaise`, la primera familia preflop que se construyó. El ejercicio termina en la decisión del héroe (c-apostar o no), igual que hoy termina cada ejercicio preflop en la decisión del héroe — no hace falta modelar qué pasa después.
2. Verificar el contenido de Academia ya publicado (`cbet` nivel 8, `board_texture` nivel 4) alcanza para justificar el veredicto de esta familia, o si hace falta una teoría puntual adicional — chequeo acotado, no autoría desde cero.
3. Extender `OpponentPolicy` con la pieza mínima necesaria: que un rival de fondo sin parte en la decisión pedagógica pueda "checkear" al llegar al flop (para que la acción vuelva al héroe) — nada de fold/call/raise postflop todavía, eso queda para una familia futura que sí lo necesite (p. ej. "enfrentás un c-bet").
4. Construir la familia en `ExerciseScenarioBuilder` reutilizando el patrón exacto de las 5 preflop (ver §1.3).
5. Recién ahí evaluar si vale la pena una segunda familia, y considerar en paralelo si conviene resolver primero la deuda ya aprobada de `PreflopStrategy`/`PreflopRangeBook` (§1.6) — no depende de nada de esto y sigue mejorando lo que ya existe.

---

## 11. Preguntas que necesitan tu aprobación

**Aprobadas por el usuario el 2026-09-19, con la salvedad de la corrección de §1.5**: Modelo A acotado a una sola familia, y la premisa "yo redacto el contenido nuevo de Academia" — que, tras la corrección, resulta ser un paso mucho más chico de lo previsto (verificar/completar el contenido ya publicado de `cbet`/`board_texture`, no escribir un nivel entero desde cero).

Preguntas que siguen abiertas:
1. **¿Cuál familia primero?** La recomendación (c-bet de rango completo, sin resistencia del rival) es deliberadamente la más simple — ¿de acuerdo, o preferís empezar por otra (ej. "el héroe enfrenta un c-bet" en vez de "el héroe hace el c-bet")?
2. **¿Se prioriza también la deuda ya aprobada de `PreflopStrategy`/`PreflopRangeBook`** (§1.6, memoria del proyecto, Fase 1 sin arrancar) — antes, en paralelo, o después de esto?
