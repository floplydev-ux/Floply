# FLOPly — Auditoría y definición de alcance para "EV Avanzado" (Tools V2)

**Fecha:** 2026-09-19
**Alcance de esta tarea:** solo lectura + diseño. No se modificó ningún archivo de `lib/`, `test/` ni `assets/` durante esta auditoría — únicamente se creó este documento. Ninguna pantalla, ningún `AppString`, ningún motor, ningún test.

**Validación de baseline** (estado del repo al momento de esta auditoría, sin tocar nada):
```
flutter analyze              → 0 issues
flutter test --concurrency=1 → 862/862
```

---

## 1. Estado actual — qué existe hoy y qué se puede reutilizar

La conclusión más importante de esta auditoría: **FLOPly no tiene un motor de EV "de una línea" porque nunca lo necesitó** — pero tiene, sin usar para este fin, casi todas las piezas de bajo nivel que un motor así necesitaría. La única pieza que falta de verdad es conceptual, no técnica: **un modelo de cómo se comporta el rival después de la primera calle**, y ese modelo no existe en ningún lado del código, ni siquiera como aproximación.

### 1.1 Matemática determinista (motor `poker/`) — todo reutilizable tal cual

| Pieza | Archivo | Responsabilidad | Input → Output | Reutilizable | Necesita extensión |
|---|---|---|---|---|---|
| `Card`/`Suit`/`Rank` | `poker/card.dart` | Primitivas de carta | — | ✅ tal cual | no |
| `HoleCards`/`HandClass` | `poker/hole_cards.dart` | Notación de mano (169 clases) | texto ↔ objeto | ✅ tal cual | no |
| `HandEvaluator` | `poker/evaluator/` | Mejor mano de 5 entre 7 cartas, comparación | `(HoleCards, board)` → ranking | ✅ tal cual | no |
| `ComboEngine` | `poker/combos/combo_engine.dart` | Enumera combos físicos de una clase/rango con card removal | `(HandClass\|HandRange, deadCards)` → `List<HoleCards>` | ✅ tal cual | no |
| `EquityEngine` | `poker/equity/equity_engine.dart` | Equity por enumeración exacta: mano-mano, mano-rango, rango-rango | `(hero, villain\|villainRange, board 3/4/5)` → `EquityResult(wins/ties/losses)` | ✅ tal cual | no — **preflop (board vacío) está explícitamente fuera de su alcance**, ver su propio doc-comment |
| `PotOddsEngine` | `poker/pot_odds/pot_odds_engine.dart` | Equity necesaria / pot odds de un call | `(potBeforeCallBb, callAmountBb)` → `requiredEquity`, `potOddsRatio` | ✅ tal cual | no |
| `EVEngine` | `poker/ev/ev_engine.dart` | EV de **pagar un call**, nada más | `(equity, finalPotBb, callAmountBb)` → `evBb` | ✅ tal cual como building block | **sí** — no tiene ningún método para EV de apostar/subir (ver 1.4) |
| `BetSizingEngine` | `poker/sizing/bet_sizing_engine.dart` | Conversión BB ↔ fracción de pot | `potBb, fraction` ↔ `sizeBb` | ✅ tal cual | no |
| `OpeningRanges`/`HandRange` | `strategy/` | Rangos con frecuencia por clase, notación con tokens (`77+`, `ATs+`, `A5s-A2s`, `KQo(0.5)`) | texto → `HandRange` | ✅ tal cual | no |

Estas 10 piezas son las que ya reutilizaron, sin tocar el motor, las 6 calculadoras de Tools V1/V2 (Pot Odds, EV-de-un-call, Equity en 3 modos, Combos, Rangos, Blockers). **EV Avanzado, cualquiera sea el alcance elegido, debería seguir exactamente ese mismo patrón: consumir estas piezas, no reimplicarlas.**

### 1.2 El motor de mano completa (`poker/game/`) — existe, está probado, y hoy no lo usa nadie postflop

Este es el hallazgo que más cambia el análisis de viabilidad. `lib/engine/poker/game/` es un motor de reglas de No-Limit Hold'em **completo y determinista**, mano entera preflop→river, con tests propios (`test/engine/game_state_test.dart`, `game_state_invariants_test.dart`, `action_resolver_test.dart`, `action_resolver_hardening_test.dart`, `opponent_policy_test.dart`):

| Pieza | Archivo | Responsabilidad | Reutilizable para EV Avanzado |
|---|---|---|---|
| `GameState` | `game_state.dart` | Estado inmutable de una mano en curso: asientos, stacks, calle, board, bote, quién actúa | ✅ — ya modela pot/stack/calle exactamente como haría falta |
| `ActionResolver` | `action_resolver.dart` | `(GameState, PokerAction) → GameState`, función pura, sin RNG | ✅ — dado un árbol de acciones ya sabe calcular el pot/stack resultante de cada rama, con reglas reales (all-in corto vs. raise completo, reapertura de acción, etc.) |
| `LegalActionEngine` | `legal_action_engine.dart` | Acciones legales + min/max raise para quien tiene el turno | ✅ — para no dejar que el usuario arme una línea con un tamaño de apuesta ilegal |
| `BettingRound`/`PotManager`/`PlayerState`/`Street`/`PokerAction` | `game/*.dart` | Bookkeeping de la ronda, el bote, el jugador, la calle, la acción | ✅ — modelo de datos ya resuelto |
| `DecisionContext` | `exercises/decision_context.dart` | "Foto" de una única decisión derivada de `GameState` (pot/toCall/stack/legales), ya usada por Laboratorio | ✅ — es literalmente el nodo de un árbol de decisión, ya con el patrón "se deriva de `GameState`, no se recalcula a mano" |
| `ScenarioBuilder` | `game/scenario_builder.dart` | Arma una mano nueva; usa `Deck`/RNG para repartir manos de un rango | ⚠️ parcial — su parte de RNG (`HandRange.sample`) es Monte Carlo, filosofía distinta a la de `EquityEngine` (enumeración exacta); su parte de bookkeeping (ciegas, primer turno) sí es reutilizable |
| `OpponentPolicy` | `game/opponent_policy.dart` | Decide una acción concreta para el rival | 🔴 **explícitamente solo preflop** — lanza `UnsupportedError` si `street != preflop`, con un doc-comment que dice literalmente que decidir postflop "necesitaría comparar la mano contra el board... fuera de alcance de esta fase" |

**Nota sobre ese doc-comment de `OpponentPolicy`**: fue escrito en una fase anterior a que existieran `HandEvaluator`/`EquityEngine` (que sí se completaron después, en esta misma sesión). Técnicamente ya no es cierto que "falte el evaluador" — existe. Lo que sigue faltando, y es un problema distinto y más difícil, es **un modelo de qué tan seguido un rival haría cada cosa postflop** (fold/call/raise en función de su mano/rango, el board, y el tamaño de la apuesta). Eso no es un evaluador de manos — es una política de decisión, y ese es precisamente el problema conceptual del punto 3.

**Importante para el riesgo de acoplamiento**: `lib/screens/laboratory/lab_session_controller.dart` ya usa `GameState`/`ActionResolver` en producción. Grepeando el árbol de ejercicios (`lib/engine/exercises/templates/`), solo un template toca calles distintas de preflop (`hand_ranking_template.dart`, y no para simular una línea, solo para mostrar un board de river ya hecho). **En la práctica, hoy nadie ejercita este motor más allá de preflop en una UI real** — EV Avanzado (si elige un modelo multi-calle) sería el primer consumidor real de ese camino, lo cual es una oportunidad (encontraría bugs latentes) y un riesgo (nadie los encontró todavía).

### 1.3 La capa pedagógica preflop — filosofía directamente aplicable

`lib/engine/strategy/preflop_authoring.dart` ya resolvió, para decisiones preflop, exactamente el problema que el punto 3/7 de este pedido plantea para EV Avanzado: **qué hacer cuando una decisión depende de algo que el motor no puede calcular con certeza** (el rango real del rival, su perfil). La solución que adoptó, y que es un precedente directo a seguir:

- `ContextFactor` (`villainRange`, `opponentProfile`, `stackDepth`, ...) — nombra explícitamente de qué depende una decisión.
- `ContextSensitivity.dependent([...])` — un veredicto puede ser `DEPENDS` en vez de forzar una respuesta única, y **siempre tiene que nombrar el factor concreto** (`assert(factors.isNotEmpty)` en el constructor).
- Nunca hay un número de frecuencia rival inventado en la capa preflop — `StrategyOption.frequency`/`MixShare` son datos de teoría documentada (consenso/heurística citada), nunca un valor inferido en runtime.

Esto importa directamente para el punto 3 de este pedido: **la respuesta a "¿el sistema debería inferir frecuencias?" ya la contestó el propio proyecto, en otro lugar, con un "no" consistente.** Cualquier propuesta de EV Avanzado que infiera fold%/call%/raise% sin que el usuario los haya puesto sería la primera vez que el proyecto rompe ese precedente.

### 1.4 Lo que específicamente falta (y no es poco)

- `EVEngine` **solo tiene `calculateCall`**. No existe ningún método para EV de **apostar o subir** — que es matemáticamente distinto porque tiene un término que `calculateCall` no necesita: la **fold equity** (la probabilidad de que el rival se retire y el héroe se lleve el bote sin showdown). Esto es una laguna real y concreta, no una interpretación: `grep -r "foldEquity\|fold equity"` en `lib/` no da ningún resultado fuera de los tres archivos que yo mismo toqué hoy (Blockers/Equity/ComboEngine no lo mencionan; no hay ningún resultado real).
- No existe ningún modelo de **rango posterior a una acción** ("el rango de villain después de que paga" / "después de que sube"). `HandRange` no tiene ningún método que tome un rango y una acción y devuelva un rango más angosto.
- No existe ninguna estructura de datos para **una línea de apuestas con ramas de villain por calle** (ni en `poker/`, ni en `exercises/`, ni en `pedagogy/`).
- No existe ningún dato, en ningún lado del código o del contenido de Academia, de **frecuencias postflop de un rival tipo** (ej. "un jugador balanced foldea X% a un c-bet en flop"). El único lugar donde existe una noción de "perfil de rival" con números es `OpponentProfile` (`game/opponent_policy.dart`), y es **exclusivamente preflop** (`openFrequency`, `threeBetPercentile`, `callPercentile`, `threeBetMultiplier` — ninguno aplica después del flop).
- Academia ya tiene los conceptos `ev` y `outs` como ids de currículo (`lib/engine/concepts/concept_ids.dart`) — es decir, EV ya se **enseña** en teoría — pero el contenido pedagógico actual, por lo que expone el motor, solo puede estar enseñando EV de una decisión puntual (la única fórmula que existe es `equity * pot - call`), nunca de una línea completa. Cualquier alcance elegido para la herramienta debería poder explicarse con el mismo vocabulario que ya usa Academia, no uno nuevo en paralelo.

---

## 2. Problema de definición — qué significa técnicamente "EV de una línea completa"

Matemáticamente, el EV de una línea es una **suma ponderada de resultados**, no una fórmula única:

```
EV(línea) = Σ P(rama_i) × resultado_bb(rama_i)
```

Donde cada `resultado_bb` puede ser: el bote ganado sin showdown (villain foldeó), o `equity_en_ese_punto × pot_final - inversión_del_héroe` (se llegó a showdown o se asume que se llega). Lo que cambia entre los 3 modelos que pidió auditar no es la fórmula — es **de dónde salen las `P(rama_i)`** y **cuántas ramas hay**.

Esto es la clave de todo el resto del informe: **`EVEngine.calculateCall` ya es un caso particular de esta fórmula** con una sola rama (el héroe paga, se llega a showdown con la equity conocida). "EV de una línea" no es una herramienta nueva conceptualmente — es la misma fórmula generalizada a más de una rama, más de una calle, y (opcionalmente) fold equity.

---

## 3. Los 3 modelos, con precisión técnica

### Modelo A — Línea corta (una decisión del héroe, con respuesta probabilística del rival)

Una sola bifurcación: el héroe hace UNA acción (bet/raise) en una calle, el rival responde con una de {fold, call, raise-que-el-héroe-no-sigue-jugando}, y se calcula el EV de esa apuesta puntual.

```
EV(bet) = P(fold) × pot_actual
        + P(call) × (equity_si_paga × pot_final_call - inversión_del_héroe)
        + P(raise) × valor_asignado_a_esa_rama  ← ver más abajo
```

**Qué información hace falta que no está en `EVEngine` hoy:**
- `P(fold)`, `P(call)`, `P(raise)` — deben sumar 1, y **tienen que venir del usuario** (ver punto 4). No hay ninguna fuente en el motor que los calcule.
- La equity del héroe si el rival paga — esto **sí** lo calcula `EquityEngine.handVsRange` tal cual existe hoy, dado el rango de continuación del rival (que el usuario debe indicar como un rango aparte, ver punto 4 — no es automáticamente "el rango original menos algo").
- Qué hacer con la rama `raise`: la opción más honesta es que el usuario decida su valor a mano (ej. "asumo que foldeo y pierdo mi apuesta", o un EV que él mismo estima) — automatizar esa rama ya es empezar a construir el Modelo C.

**Complejidad de implementación:** baja. Reutiliza `EquityEngine.handVsRange` + `PotOddsEngine`/`BetSizingEngine` (para pot/tamaños) tal cual existen. La única pieza nueva de motor es un método de `EVEngine` (o una clase hermana) que sepa combinar fold%/call%/equity — matemáticamente trivial, ver 1.4.

### Modelo B — Línea multi-calle parametrizada (el usuario arma una secuencia fija)

El usuario describe una secuencia completa: "flop: bet 50% / villain call; turn: bet 66% / villain call; river: bet pot / villain fold-o-call con X%" — una única línea, sin ramas alternativas por calle (no hay "¿y si villain sube en el turn?").

**Qué hace falta que Modelo A no necesita:**
- Progresión real de pot/stack calle a calle — **esto ya lo resuelve `GameState`/`ActionResolver`/`PotManager` tal cual existen** (ver 1.2). No hay que reinventar el bookkeeping.
- El rango de villain tiene que **angostarse** en cada calle donde continúa (si pagó el flop con "un rango amplio", su rango en el turn ya no es el mismo). Acá aparece el hueco real: **no existe ningún método que angoste un `HandRange`** — el usuario tendría que reintroducir manualmente el rango de villain en cada calle (una entrada de texto por calle, como ya hace el Equity Calculator con rangos), lo cual es honesto (no inventa nada) pero le pide al usuario un trabajo de estimación considerable, calle por calle.
- Fold equity por calle: cada apuesta del héroe tiene su propia `P(fold)` independiente — el usuario la pone para cada calle donde apuesta.
- Board: el usuario fija las cartas de cada calle (no es una distribución de runouts — es una línea concreta con un board concreto, igual que hoy hace el Equity Calculator con "board conocido").

**Complejidad de implementación:** media-alta. El cálculo en sí sigue siendo la misma suma ponderada del punto 2, aplicada calle por calle y acumulada — pero la superficie de entrada crece mucho (un rango + una probabilidad de fold + un tamaño de apuesta, por cada calle que el héroe apuesta) y hay que decidir seriamente el modelo de UX (punto 5) para que no se sienta como llenar un formulario de 15 campos.

### Modelo C — Árbol de decisiones completo

Como B, pero en cada calle donde el rival puede actuar, se abren **múltiples ramas** (fold / call / raise), y cada una de esas ramas puede a su vez abrir sub-ramas en la calle siguiente (¿el héroe qué hace si villain sube? ¿paga, sube, foldea?). El EV total es la suma ponderada de **todas las hojas del árbol**.

**Qué hace falta que B no necesita:**
- Una estructura de árbol recursiva real (no una secuencia lineal) — técnicamente no es difícil de modelar (un `DecisionNode` con hijos, apoyado en `GameState`/`ActionResolver` para cada rama), pero la **entrada de datos crece exponencialmente**: cada nodo nuevo pide su propio rango + sus propias probabilidades. Un árbol de 3 calles con 3 ramas por nodo del rival ya son potencialmames 3×3×3 = 27 hojas a las que el usuario tendría que asignarles sentido.
- Decisiones del héroe **dentro** del árbol (no solo del rival) — ahí el problema dejar de ser "calcular el EV de una línea dada" y pasa a ser "encontrar la línea de mayor EV", que es un problema de optimización/solver, no de calculadora.

**¿Corresponde esto a una herramienta de Tools V2?** Con la evidencia reunida, no: el checklist ya tiene, correctamente pospuesta en P2, la línea "GTO Decision / Postflop GTO / Coach / Adaptativo" (`AUDITORIA_CHECKLIST_2026-09-18.md`, tabla de prioridades). Un árbol completo con optimización de decisiones del héroe **es** ese ítem P2, no una extensión de Tools. Ver más en la Recomendación (punto 10).

---

## 4. El problema de los rangos — separando quién pone cada dato

Esta es la sección que el pedido marcó como "fundamental", y con razón: es donde más fácil es que una herramienta termine inventando números sin que el usuario se dé cuenta.

| Dato | ¿Quién lo pone? | Justificación |
|---|---|---|
| Rango inicial de villain | **Usuario**, como texto (`77+,ATs+,AKo`, mismo formato que ya usan Equity/Blockers) | Ya es el patrón establecido en Tools V2; `HandRange.parse` ya lo resuelve |
| Rango de villain **después de** una acción (call/raise) | **Usuario**, reintroducido a mano por calle | No existe ningún método en el motor que angoste un rango automáticamente — inventar una regla ("villain paga con el 60% inferior de su rango") sería exactamente el tipo de supuesto GTO no fundamentado que el pedido pide evitar. Angostar el rango es una decisión estratégica del propio usuario, no un cálculo |
| `P(fold)` / `P(call)` / `P(raise)` en cada nodo donde decide villain | **Usuario**, con la restricción dura de que sumen 1.0 (validación determinista, no una estimación) | No hay ninguna fuente de datos real en el proyecto (ni motor, ni contenido de Academia, ni un dataset) de la que salga un número de este tipo — inventar un "42% en el turn" por default sería fabricar una estadística sin sustento, exactamente lo que el pedido prohíbe |
| Equity del héroe dado un rango de villain y un board | **FLOPly calcula**, con `EquityEngine.handVsRange` (enumeración exacta, ya probado) | Esto es matemática determinista pura, no una estimación |
| Pot/stack/tamaños de apuesta en cada calle | **FLOPly calcula**, con `GameState`/`ActionResolver`/`PotManager`/`BetSizingEngine` | Bookkeeping determinista, ya existe |
| Combos bloqueados por las cartas del héroe/board en el rango de villain | **FLOPly calcula**, con `ComboEngine` (ya usado por Blocker Explorer) | Card removal, matemática determinista |
| EV final de la línea | **FLOPly calcula**, combinando los puntos anteriores con la fórmula del punto 2 | Una vez que el usuario puso rangos y probabilidades, todo lo demás es aritmética |

**Ninguna versión de esta herramienta debería, en ningún momento, calcular un `P(fold)`/`P(call)`/`P(raise)` por sí sola.** Si en algún momento se quisiera ofrecer un "valor sugerido" (ej. "un rival balanced suele foldear ~X% acá"), eso tendría que:
1. Citar una fuente explícita (igual que hoy `StrategyOption.frequency` en la capa preflop cita "consenso teórico simplificado o heurística documentada", nunca un número sin origen), y
2. Quedar 100% editable y claramente marcado como sugerencia, nunca como el valor que usa el cálculo por default sin que el usuario lo confirme.

Esto es coherente con `OpponentProfile` (`game/opponent_policy.dart`): esa clase sí tiene números preflop con nombre y justificación en el doc-comment ("comportamiento original Fase 4", etc.) — pero deliberadamente **no** se extiende a postflop en ningún lado del código actual. Extenderla sin evidencia sería la primera vez que el proyecto inventa una heurística de comportamiento rival sin ese mismo nivel de justificación.

---

## 5. Qué puede calcular FLOPly de forma exacta (y qué no debería inventar)

### Matemática determinista (FLOPly la calcula siempre, cero incertidumbre)
- Pot antes/después de cada acción, tamaño de call, tamaño de apuesta como fracción de pot y viceversa (`PotOddsEngine`, `BetSizingEngine`, `PotManager`).
- Equity exacta del héroe contra una mano, un rango, o rango-vs-rango, en un board conocido (`EquityEngine`) — **preflop queda afuera de esto también acá**, igual que en el resto de Tools; una línea que empieza preflop necesitaría equity heurística (`HandStrength`) en vez de equity real, y esa distinción tiene que quedar visible en la UI, nunca mezclada como si fuera el mismo número.
- Combos bloqueados por las cartas conocidas (`ComboEngine`).
- EV dado un conjunto de probabilidades ya provisto por el usuario — pura aritmética, una vez que las probabilidades existen.

### Información que necesita una estimación (el usuario la pone, FLOPly nunca la calcula)
- Frecuencia de fold/call/raise de villain, en cualquier calle.
- Rango de continuación de villain después de cada una de sus acciones.
- Qué línea futura asume el héroe si villain sube (Modelo B/C).

### Información estratégica que NO debería inventarse bajo ningún alcance
- Cualquier "frecuencia típica" de un perfil de rival postflop (ej. "el rival medio foldea 42% al turn") sin una fuente citable — no existe ese dato en el proyecto hoy, y fabricarlo sería literalmente inventar una estadística de póker, algo que ninguna otra pieza del motor hace (`OpponentProfile` es honesto y limitado a preflop justamente por esto).
- Cualquier regla automática de "cómo se angosta un rango" tras una acción — es una decisión estratégica (depende de la lectura del jugador sobre su rival), no un cálculo.

---

## 6. UX propuesta (independiente del modelo elegido, con variantes por alcance)

### Entrada mínima (Modelo A)
1. Board conocido (reutiliza el mismo campo de texto que Equity Calculator).
2. Mano del héroe.
3. Rango de villain en ese punto (reutiliza el mismo campo que Blockers/Equity).
4. Pot antes de la apuesta del héroe + tamaño de la apuesta propuesta (o fracción de pot, con `BetSizingEngine`).
5. `P(fold)` del rival a esa apuesta.
6. Rango de continuación de villain SI paga (puede ser el mismo rango de (3) o uno más angosto que el usuario tipee de nuevo).

### Entrada avanzada (Modelo A, opcional)
- Comparar 2+ tamaños de apuesta a la vez (¿bet 33% vs. 75% vs. pot, con la misma `P(fold)` estimada o una por tamaño?) — reutiliza el mismo cálculo, una vez por tamaño; es una extensión de UI, no de motor.
- Rama de "villain sube": un campo de texto libre (no calculado) donde el usuario anota qué asume que pasa ahí, sin que el número entre en el cálculo agregado — trazabilidad sin pretender resolver esa rama.

### Entrada (Modelo B)
Todo lo de A, repetido por calle, con navegación tipo wizard (Flop → Turn → River), donde cada paso muestra el pot acumulado que ya calculó `GameState`/`ActionResolver` a partir de las calles anteriores — igual que el propio Laboratorio ya usa ese motor internamente, para que el usuario nunca tenga que sumar el pot a mano.

### Resultado (ambos modelos)
Imprescindible:
- EV total de la línea, en BB.
- Desglose: cuánto EV aporta la fold equity vs. cuánto aporta jugar a showdown.
- Pot final asumido, inversión total del héroe.
- Equity usada en el cálculo (para que el usuario pueda auditar el número, no solo confiar en él).

Avanzado (opcional, no imprescindible):
- EV por rama/calle (en Modelo B).
- Comparación lado a lado de 2 líneas o 2 tamaños de apuesta.
- Combos bloqueados del rango de villain en ese punto (reutilizando el mismo chip visual que ya tiene Blocker Explorer).

---

## 7. Comparación de las 3 propuestas

| Alcance | Descripción | Complejidad | Riesgo de supuestos | Utilidad |
|---|---|---|---|---|
| **A — Línea corta** | Una apuesta del héroe, fold%/call% del usuario, EV de esa apuesta puntual | Baja — reutiliza `EquityEngine`/`PotOddsEngine`/`BetSizingEngine` tal cual, un método nuevo de EV con fold equity | Bajo — 2-3 números que el usuario pone explícitamente, ningún dato inferido | Cubre la laguna real y concreta de hoy (`EVEngine` no sabe de bets/raises, solo de calls) |
| **B — Multi-calle parametrizado** | Secuencia fija de 1 a 3 calles, con rango/fold%/tamaño reintroducidos por calle | Media-alta — el cálculo reutiliza A por calle, pero la superficie de entrada y la UX (wizard multi-paso) son trabajo nuevo real | Medio — cada calle agrega 2-3 números más que el usuario tiene que estimar; el riesgo no es que el sistema invente nada, es que la herramienta le pida al usuario estimar mucho para un resultado que solo es tan bueno como esas estimaciones | Útil para el caso "quiero saber si vale la pena esta línea completa que tengo pensada", un uso real de mesa |
| **C — Árbol completo** | Ramas fold/call/raise en cada nodo, potencialmente con decisiones del héroe adentro | Alta — estructura recursiva, más el problema de que optimizar la decisión del héroe ya es otro problema (solver, no calculadora) | Alto — la cantidad de estimaciones del usuario crece exponencialmente con la profundidad, y mezclar "el héroe decide óptimamente" empieza a pisar terreno de GTO | Se superpone con el ítem ya pospuesto del checklist ("GTO Decision / Postflop GTO", P2) — no está claro que agregue algo que esa iniciativa, cuando exista, no vaya a cubrir mejor |

(Sin ranking — la tabla es para decidir, no decide por sí sola.)

---

## 8. Compatibilidad con la filosofía de FLOPly

| Restricción | Modelo A | Modelo B | Modelo C |
|---|---|---|---|
| Herramienta de cálculo, no caja negra | ✅ cada número de entrada es visible y editable | ✅ igual, con más campos | ⚠️ un árbol grande empieza a sentirse opaco aunque cada número sea editable — demasiadas entradas para auditar de un vistazo |
| El usuario entiende qué supuestos introduce | ✅ 2-3 supuestos, fáciles de nombrar en la UI | ✅ más supuestos, pero cada uno sigue siendo nombrable | ⚠️ difícil de comunicar con claridad cuántos supuestos hay metidos en un árbol de 20+ hojas |
| No inventar frecuencias rivales | ✅ | ✅ | ✅ (en los 3, siempre que se respete la regla del punto 4 — esto no depende del alcance, depende de la implementación) |
| No mezclar GTO con cálculo matemático | ✅ | ✅ | ⚠️ si en algún momento se optimiza la decisión del héroe, deja de ser "cálculo" y pasa a ser "estrategia sugerida" — la línea se cruza fácil |
| No duplicar herramientas existentes | ✅ extiende `EVEngine`, no lo reemplaza | ✅ reutiliza A como building block | ✅ en teoría, pero en la práctica se superpone con el ítem P2 ya planeado |
| No introducir complejidad innecesaria | ✅ | 🟡 justificable si el usuario realmente lo quiere | 🔴 la complejidad no es solo de código — es de UX y de carga cognitiva para quien usa la herramienta |
| Explicable pedagógicamente | ✅ misma fórmula que Academia ya nombra (`ev`, `outs`) | ✅ es la misma fórmula aplicada varias veces | ⚠️ un árbol completo ya no se explica en una pantalla, se parece más a un curso que a una calculadora |
| Testeable deterministamente | ✅ dado un input fijo, un output fijo — igual que las 6 calculadoras que ya existen | ✅ igual, con más combinaciones de input a cubrir | 🟡 el número de combinaciones de árbol a testear crece rápido |
| Se integra limpio con la arquitectura actual | ✅ un método nuevo en `EVEngine` (o una clase hermana), cero cambios a motores existentes | ✅ reutiliza `GameState`/`ActionResolver` que ya existen y ya están probados | 🟡 necesitaría una estructura de árbol nueva que hoy no existe en ningún lado |

---

## 9. Tests necesarios (según alcance, sin implementarlos)

Comunes a cualquier alcance (motor):
- EV positivo conocido (fold% alto → EV cercano al pot completo).
- EV negativo conocido (fold% bajo, equity baja al ser pagado).
- Break-even exacto (mismo criterio de tolerancia por epsilon que ya usa `EVResult.isBreakEven`).
- `P(fold) + P(call) + P(raise) == 1.0` — rechazar si no suma (con la misma tolerancia de punto flotante que ya usa el resto del motor).
- Probabilidades inválidas (negativas, > 1, NaN/infinito) — mismo patrón de validación que `EVEngine._validateEquity`.
- Fold puro (`P(fold) = 1`) — EV = pot actual, sin necesidad de equity.
- Call puro / villain nunca foldea (`P(fold) = 0`) — se reduce exactamente a `EVEngine.calculateCall` ya existente; un test de esta forma serviría además como test de regresión cruzada entre el motor viejo y el nuevo.
- Combos bloqueados por hero/board reduciendo el rango de villain a cero combos válidos — mismo `ArgumentError` que ya lanza `EquityEngine.handVsRange`.
- Rango de villain vacío o con notación inválida — mismo patrón de validación que ya usan Equity/Blockers.

Solo si se implementa B (o C):
- Multi-calle con pot acumulado correcto entre calles (verificable contra `GameState`/`ActionResolver`, que ya tienen su propia suite).
- Stack insuficiente para el tamaño de apuesta pedido en alguna calle (debería degradar a all-in o rechazar, coherente con `LegalActionEngine`).
- All-in en alguna calle (corta la línea — no hay calles después de un all-in que cubre todo el stack).
- Distintos stacks efectivos entre héroe/villain.

Solo si se implementa C:
- Árbol con múltiples ramas por nodo, verificando que las probabilidades de las ramas de un mismo nodo sumen 1.0 independientemente entre nodos.
- Suma de EV ponderado de todas las hojas coincide con el EV total reportado (invariante de agregación).

**Los tests de "combos bloqueados", "rango inválido" y "probabilidades inválidas" son necesarios bajo cualquier alcance** — son la superficie donde más fácil es que una implementación apurada termine devolviendo un número silenciosamente incorrecto, exactamente el tipo de error que esta sesión ya evitó varias veces en las calculadoras anteriores (ver p. ej. la validación explícita de duplicados en Blocker Explorer).

---

## 10. Riesgos de arquitectura

- **Duplicar `ComboEngine`/`EquityEngine`/cálculo de pot**: bajo riesgo real, siempre que la implementación efectivamente llame a esas clases en vez de reescribir su lógica — el patrón ya está establecido y probado 6 veces en Tools V1/V2.
- **Lógica matemática dentro de widgets**: mismo riesgo que en cualquier calculadora anterior — mitigado si se seguye el patrón ya usado (el motor calcula, la pantalla solo parsea texto y muestra `Result`).
- **Modelos paralelos innecesarios**: el riesgo real y concreto está acá — es tentador crear una clase `BettingLine`/`DecisionTree` nueva que reimplique lo que `GameState`/`ActionResolver`/`DecisionContext` ya hacen. Si se elige Modelo B o C, el diseño concreto debería apoyarse en esas clases, no crear un modelo de "línea de apuestas" paralelo al que ya existe en `poker/game/`.
- **Dependencia con Laboratorio**: baja si se respeta la restricción del pedido de no tocar `lib/screens/laboratory/` — pero técnica, no de producto: como `GameState`/`ActionResolver` son compartidos con Laboratorio, cualquier extensión a esas clases (si hiciera falta alguna, cosa que el análisis de 1.2 sugiere que no) tendría que revalidarse contra la suite de Laboratorio también.
- **Acoplamiento con Academia**: ninguno necesario — Academia no necesita saber que esta herramienta existe, y esta herramienta no necesita leer currículo. La única conexión deseable es de vocabulario (usar los mismos términos que ya usan los conceptos `ev`/`outs`), no de código.
- **¿Hace falta modificar algún motor existente?** Con la evidencia reunida: **no, para Modelo A** (alcanza con una clase nueva, p. ej. `EVEngine.calculateBet(...)` o una clase hermana, que combine piezas existentes). **No debería hacer falta tampoco para Modelo B** — `GameState`/`ActionResolver`/`DecisionContext` ya exponen todo lo necesario; lo que falta es una UI que los recorra, no un cambio de esas clases. Ningún alcance de los tres analizados necesita tocar `HandEvaluator`, `EquityEngine`, `ComboEngine`, `PotOddsEngine`, `OpeningRanges` ni `HandRange`.

---

## 11. Recomendación técnica

**Modelo A** es el que se sostiene mejor contra los tres criterios que más importan acá: cierra una laguna real y ya identificada (`EVEngine` literalmente no sabe calcular el EV de apostar/subir, solo de pagar), no requiere ninguna pieza de motor que no exista, y mantiene el mismo nivel de rigor (2-3 supuestos nombrados y editables, nada inferido) que ya tienen las 6 calculadoras de Tools. Es además el único de los tres que puede explicarse en una sola pantalla sin que dejar de sentirse "una calculadora".

**Modelo B** es arquitectónicamente viable hoy mismo — no porque haga falta construir nada nuevo de bajo nivel, sino porque `GameState`/`ActionResolver`/`DecisionContext` ya resuelven exactamente el bookkeeping multi-calle que necesitaría. Pero es un salto de producto más grande que de motor: le pide al usuario estimar rangos y frecuencias calle por calle, y esa carga de estimación (no de código) es el verdadero costo. Tiene sentido como una extensión posterior de A (mismo cálculo, aplicado varias veces, con Modelo A ya como building block probado), no como punto de partida.

**Modelo C** no parece corresponder a Tools V2 con la evidencia reunida: el checklist ya tiene un ítem separado y correctamente pospuesto (P2, "GTO Decision / Postflop GTO") que es, en sustancia, lo mismo que un árbol completo con optimización de decisiones — construirlo acá sería adelantar ese trabajo bajo otro nombre, sin la discusión de producto que ese ítem probablemente merece por separado.

Si la decisión final fuera avanzar, el orden que mejor protege contra sorpresas es: **A primero, evaluar uso real, después decidir si B se justifica** — exactamente el mismo criterio incremental que ya se usó para construir Tools V1 calculadora por calculadora en vez de todas a la vez.

---

## 12. Preguntas que necesitan tu aprobación

1. **¿Alcance a implementar?** A (línea corta), B (multi-calle), o "A ahora, B más adelante si hace falta" (la recomendación de este informe) — ¿o alguna otra combinación?
2. **La rama "villain sube"** en Modelo A: ¿el cálculo la ignora (el usuario ve el EV asumiendo fold/call solamente, y anota aparte qué asume si sube), o preferís que desde el arranque el cálculo incluya un tercer término con un valor que vos mismo le asignás a mano a esa rama?
3. **Preflop**: ¿la herramienta debería poder arrancar preflop (usando `HandStrength`, heurística, no equity real) o queda limitada a cuando ya hay board conocido (igual que Equity Calculator hoy)? Esto cambia qué tan honesto puede ser el número de equity que se muestra.
4. **Ubicación en el Hub**: ¿una calculadora nueva en Tools (7ma tarjeta), o una extensión del EV Calculator existente con un modo nuevo (mismo patrón que usó Equity Calculator para sus 3 modos)?
