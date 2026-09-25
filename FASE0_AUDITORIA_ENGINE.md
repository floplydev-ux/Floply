# FLOPly — FASE 0: Auditoría del Poker Engine y arquitectura para Tools
**Fecha:** 2026-09-18
**Alcance:** solo lectura + diseño. No se modificó ningún archivo de `lib/`, `test/` ni `assets/` durante esta auditoría — únicamente se creó este documento.

---

## 0. Validación de baseline (§28 del pedido)

```
flutter analyze              → PASS (0 issues)
flutter test --concurrency=1 → 601/601
```

Corridos en esta misma sesión, sobre el estado actual del repo (que incluye cambios sin commitear de sesiones previas — rename de package a `com.floply.app`, etc., ninguno de los cuales se tocó acá). Cero fallos preexistentes ocultados.

---

## A. Estado actual — qué tenemos realmente

El poker engine de FLOPly **no es uno solo, son dos capas superpuestas**, y eso es la señal más importante de toda esta auditoría:

1. **Un motor de reglas mecánicas genuinamente bueno** (`lib/engine/poker/`): cartas, mazo, mesa, calles, pot, y sobre todo un **motor de apuestas multi-calle completo y correcto** (`GameState` + `ActionResolver` + `LegalActionEngine`) — fold/check/call/bet/raise/all-in, reapertura de acción, all-in corto vs. raise completo, todo con invariantes que explotan en release si algo queda inconsistente. Esto está mucho más desarrollado de lo que yo esperaba antes de leer el código: **no es un motor "solo preflop"**, es un motor de mano completa (preflop→river) al que **le falta exactamente una pieza para ser usable end-to-end: un evaluador de manos hechas** (ver §C.1).

2. **Una capa de estrategia/pedagogía deliberadamente acotada a preflop** (`lib/engine/strategy/`, `lib/engine/exercises/`): rangos de apertura por posición, un puntaje heurístico de fuerza de mano (Chen), y generación de escenarios de decisión preflop. Todo el código es explícito y honesto sobre dónde termina: los propios doc-comments dicen "esta pasada no incluye un evaluador de manos", "todavía no decide postflop", "Fase 4", etc. No encontré ni un solo lugar donde el motor finja tener algo que no tiene.

No existe **nada** de Equity/Pot Odds/EV/Combos como motor reutilizable de propósito general. Lo que hoy se llama "EV" en el código es *scoring pedagógico de una decisión* (`decisionScore`, `StrategicRating`), no valor esperado en fichas — ver §C.2, es importante no confundirlos.

### A.1 Inventario por componente

| Componente | Archivo(s) | Estado | Reutilizable para Tools | Dependencias | Problemas |
|---|---|---|---|---|---|
| Card/Suit/Rank | `poker/card.dart` | COMPLETO | ✅ sí, tal cual | ninguna | ninguno |
| Deck (con RNG sembrado) | `poker/deck.dart` | COMPLETO | ✅ sí, tal cual | `card.dart` | ninguno |
| HoleCards / HandClass (169 clases) | `poker/hole_cards.dart` | COMPLETO | ✅ sí, tal cual | `card.dart` | ninguno |
| HandCategory (ranking pedagógico) | `poker/hand_category.dart` | PROVISIONAL | ⚠️ parcial — es solo un enum descriptivo (label/ejemplo), **no calcula nada a partir de cartas concretas** | ninguna | no confundir con un evaluador real (ver C.1) |
| **Hand evaluator (7 cartas → mejor mano)** | — no existe — | **FALTANTE** | — | — | bloquea Equity, EV, showdown multi-calle |
| HandStrength (fórmula de Chen) | `strategy/hand_strength.dart` | COMPLETO (para lo que hace) | ⚠️ parcial — ordena las 169 clases preflop, no sirve postflop ni para equity real | `hole_cards.dart` | nombre puede confundir ("strength" ≠ equity) |
| HandRange (parser + frecuencias + combos) | `strategy/hand_range.dart` | COMPLETO | ✅ sí, base sólida para Range Explorer | `deck.dart`, `hole_cards.dart` | no tiene combo-removal contra board/mano rival (ver C.5) |
| OpeningRanges (5 rangos RFI fijos) | `strategy/opening_ranges.dart` | COMPLETO pero de contenido fijo | 🟡 sirve como *seed* de Preflop Charts, no como motor genérico | `hand_range.dart`, `position.dart` | rangos hardcodeados para un único perfil de juego (6-max 100bb) |
| BoardGenerator (texturas: paired/monotone/two-tone/rainbow) | `poker/board_generator.dart` | COMPLETO | ✅ sí, tal cual | `deck.dart` | ninguno |
| Position (6-max, orden de acción) | `poker/position.dart` | COMPLETO | ✅ sí, tal cual | ninguna | ninguno |
| TablePositions (slot↔posición) | `pedagogy/table_position.dart` | COMPLETO | ✅ sí — re-exporta `Position`/`Street`, no los duplica | `poker/position.dart` | ninguno — buen ejemplo de "no duplicar" |
| Street | `poker/street.dart` | COMPLETO | ✅ sí | ninguna | ninguno |
| PlayerState (stack/invested/folded/all-in) | `poker/game/player_state.dart` | COMPLETO | ✅ sí | `hole_cards.dart` | ninguno |
| PotManager / Pot | `poker/game/pot_manager.dart` | PARCIAL (documentado) | ✅ sí para bote único | ninguna | **sin side pots** — `Pot.eligibleSlots` ya está pensado para agregarlos sin romper la API pública |
| BettingRound | `poker/game/betting_round.dart` | COMPLETO | ✅ sí | `poker_action.dart`, `street.dart` | ninguno |
| GameState | `poker/game/game_state.dart` | COMPLETO (con hueco documentado) | ✅ sí, es la pieza central | pot/player/betting_round/street/card | `needsShowdown` queda sin resolver (ver C.1) |
| LegalActionEngine | `poker/game/legal_action_engine.dart` | COMPLETO | ✅ sí | `game_state.dart` | ninguno |
| ActionResolver | `poker/game/action_resolver.dart` | COMPLETO | ✅ sí, la pieza más sólida de todo el motor | `game_state.dart`, `legal_action_engine.dart` | ninguno funcional |
| PokerAction / ActionType / PriorAction | `poker/poker_action.dart` | COMPLETO | ✅ sí | `position.dart` | ninguno |
| OpponentPolicy (bot preflop, 3 perfiles) | `poker/game/opponent_policy.dart` | PARCIAL (documentado) | 🟡 sirve como referencia de "decisor" pero **lanza `UnsupportedError` en postflop** | `hand_strength.dart`, `opening_ranges.dart` | scope preflop-only, explícito |
| StrategyEngine (RFI graduado) | `strategy/strategy_engine.dart` | COMPLETO (scope acotado) | 🟡 reutilizable como *capa pedagógica*, no como motor matemático | `hand_range.dart`, `opening_ranges.dart`, `hand_strength.dart` | solo cubre open-raise first-in |
| PreflopStrategy (extiende StrategyEngine) | `exercises/preflop_strategy.dart` | COMPLETO (scope acotado) | igual que arriba | `strategy_engine.dart` + piezas de bajo nivel | cubre las 2 situaciones que `StrategyEngine` no cubre (open-over-limpers, facing-raise) — capa correcta, no duplicación |
| ExerciseScenarioBuilder | `exercises/exercise_scenario_builder.dart` | COMPLETO (preflop-only) | 🟡 patrón reutilizable para Tools ("armar una situación real jugando el motor"), pero el nombre y el scope son preflop | `game_state`, `action_resolver`, `opponent_policy` | el nombre de la clase ya declara el límite: "Genera ExerciseScenarios **preflop** reales" |
| DecisionContext | `exercises/decision_context.dart` | COMPLETO | ✅ excelente ejemplo a copiar: nunca recalcula nada, todo sale de `GameState`/`LegalActionEngine` | — | ninguno |
| **`evaluation/answer_evaluator.dart`** (`AnswerEvaluator`, instancia) | `evaluation/` | COMPLETO, pero **LEGACY** | ✅ solo para no romper el camino viejo | `Exercise`/`EvaluationResult`/`StrategicRating` (5 niveles) | ver §C.6 — coexiste con el de abajo |
| **`exercises/answer_evaluator.dart`** (`AnswerEvaluator`, estático) | `exercises/` | COMPLETO, es el motor nuevo | ✅ sí, y ya trae `AnswerVerdict.best/acceptable/poor/dependent` | `PreflopStrategy`, `ExerciseScenario` | mismo nombre de clase que el de arriba — confuso pero no roto (namespaces distintos) |
| ConceptRegistry / UserKnowledge | `concepts/` | COMPLETO | ✅ sí, ideal para conectar Tools↔Academia | ninguna | ninguno |
| ExerciseHistory (anti-repetición) | `exercises/exercise_history.dart` | COMPLETO | 🟡 patrón reutilizable si Tools genera ejercicios, no aplica a calculadoras | `exercise.dart` (legacy) | ninguno |

### A.2 Lo que NO existe (ninguno de estos tiene ni un archivo provisional)
- Hand evaluator de 7 cartas (showdown real)
- Equity engine (exacto o Monte Carlo)
- Pot Odds engine
- EV engine (matemático, en fichas — distinto del scoring pedagógico)
- Combo engine dedicado (combos/removal como módulo, hoy es lógica implícita en `HandRange`/`HandClass.combos`)
- Bet sizing engine genérico (solo hay sizing de apertura preflop en `OpeningRanges`)
- Cualquier UI o pantalla de Tools

---

## B. Qué está incompleto (más allá de "no existe")

1. **`GameState.needsShowdown`** queda `true` sin resolver — el motor de mano completa llega hasta ahí y se detiene. Es la pieza más valiosa a destrabar porque **una vez que exista un evaluador de 7 cartas, todo el resto del motor de calles ya está listo para consumirlo** — no hace falta tocar `ActionResolver` ni `GameState`.
2. **`OpponentPolicy.decide`** lanza `UnsupportedError` en cualquier calle que no sea preflop. Bloquea que Laboratorio ofrezca manos postflop completas contra un rival "vivo".
3. **`PotManager`** no arma side pots (documentado, API ya preparada).
4. **Bet sizing** solo existe para apertura preflop (`OpeningRanges.sizingFor`); no hay un motor de sizing para bet/3-bet/4-bet/shove postflop ni un "% del pot" genérico.
5. **`OpeningRanges`** es un único perfil fijo (6-max, ~100bb, cash) hardcodeado como constantes Dart — no hay forma de cargar otro set de rangos (por stack depth, por formato) sin editar código. Para un Range Explorer / Preflop Charts real esto tiene que volverse *datos*, no constantes.
6. **`HandRange`** no tiene combo-removal: sabe cuántos combos representa una clase en abstracto (`HandClass.combos`), pero no "cuántos combos de esta clase quedan disponibles dados el board + la mano del héroe + otra rango rival". Eso hoy vive parcialmente en `Deck.dealHandOfClass`/`tryDealMatching` (que sí evitan cartas ya repartidas), pero no como una consulta reutilizable tipo `range.combosGiven(deadCards)`.
7. **Migración de Laboratorio a medio camino** (ver duplicación C.6): dos sistemas de ejercicios/evaluación conviven a propósito, documentado como transición, no como descuido.

---

## C. Duplicaciones y decisiones semánticas a resolver

### C.1 No hay evaluador de manos — es el hueco más importante de todo el motor
Confirmado en 3 lugares independientes, todos documentados honestamente:
- `HandCategory` (poker/hand_category.dart) es solo un enum pedagógico con ejemplos fijos, no compara cartas reales.
- `GameState.needsShowdown` (game_state.dart:167-176): doc-comment explícito: *"esta pasada no incluye un evaluador de manos... `winnerSlots` queda `null`"*.
- `OpponentPolicy.decide` (opponent_policy.dart:107-112): lanza `UnsupportedError` en postflop por la misma razón, citando literalmente "un evaluador de manos hechas" como lo que falta.

**Esto no es un bug ni un olvido — es una frontera de alcance repetida y consistente en todo el código.** Construir esto es el prerrequisito real de Equity/EV/showdown multi-calle, no solo de Tools.

### C.2 "EV" ya se usa con dos significados distintos — riesgo de choque semántico real
- **EV pedagógico** (`decisionScore` en `EvaluationResult`, `StrategicRating.score`): qué tan buena es una decisión en una escala 0..1 curada a mano por el diseño de la estrategia de referencia. No es dinero, no es valor esperado en fichas.
- **EV matemático** (a diseñar en §F): `EV(acción) = Σ P(resultado) × payoff(resultado)`, en BB. Necesita equity real.

El pedido detectó correctamente este riesgo antes de que yo leyera una línea de código. Confirmado: **hoy solo existe el primero**. Cuando se construya el segundo, la recomendación es nombrarlo sin ninguna palabra en común reutilizable a simple vista — ver la convención de nombres en §E.

### C.3 `HandStrength` vs. un futuro equity real
`HandStrength.chenScore`/`percentile` es una heurística preflop (fórmula de Chen), no equity. Hoy se usa para: ordenar 169 clases, decidir 3-bet/call/fold del bot, y feedback de "¿qué mano es mejor?". Es correcto que siga existiendo — resolver "¿AKs es más fuerte que 77 en abstracto?" no necesita equity real, es más barato y ya está bien probado. El riesgo es que alguien intente usarlo para responder "¿qué equity tiene esta mano en este board?" — no puede, no ve el board. Documentar esa frontera cuando se agregue `EquityEngine`.

### C.4 `evaluation/AnswerEvaluator` vs. `exercises/AnswerEvaluator` — duplicación real, pero **documentada y en transición activa**, no un descuido
Dos clases con el mismo nombre, en namespaces distintos, evaluando lo mismo con modelos distintos:

| | `evaluation/answer_evaluator.dart` (viejo) | `exercises/answer_evaluator.dart` (nuevo) |
|---|---|---|
| Input | `Exercise` + `UserAnswer` (texto/opción) | `ExerciseScenario` + `PokerAction` (motor real) |
| Output | `EvaluationResult` | `AnswerResult` |
| Escala | `StrategicRating` (5: optimal/veryGood/viable/dubious/bad) | `AnswerVerdict` (4: **best/acceptable/poor/dependent** — exactamente la nomenclatura que pedía el checklist maestro) |
| Quién lo usa hoy | `PokerTrainerEngine.submit()` — camino viejo de Laboratorio (`LabSessionController._loadNext()`) | `ExerciseScenarioAdapter`, `TableExerciseAdaptation`, y **directamente** `LabSessionController` (línea 364) |
| Usado por Academia | **no** — Academia usa su propio sistema (`AcademyPlayableScripts`/`InteractiveTableExercise`), que a su vez llama al motor nuevo vía `TableExerciseAdaptation`/`ExerciseScenarioAdapter` | — |

El propio código lo etiqueta: `exercise.dart` línea 5 dice literalmente **"LEGACY (Fase 8.8)"** y explica que convive con el motor nuevo *"hasta que Laboratorio migre por completo"*. No es una duplicación accidental — es una migración a medio terminar, correctamente aislada (dos módulos separados, sin mezclar tipos entre ellos). **Recomendación para esta fase: no tocarla** (regla explícita del pedido), pero señalarla como la primera candidata a resolver *después* de Tools V1, porque construir `EVEngine`/`EquityEngine` nuevos sin resolver esta ambigüedad primero puede tentar a alguien a enganchar el motor matemático nuevo al lado legacy por error.

### C.5 Combos: no hay motor propio, es lógica dispersa — confirmado
Búsqueda dirigida: `combos` como concepto vive en tres lugares que no se hablan entre sí:
- `HandClass.combos` (hole_cards.dart): cuenta fija por clase (6/4/12), sin contexto de mesa.
- `HandRange.comboCount`: suma `HandClass.combos * frecuencia`, sigue sin contexto de mesa (no resta combos bloqueados).
- `Deck.dealHandOfClass`/`tryDealMatching`: sí respetan qué cartas ya se repartieron, pero como efecto colateral de repartir, no como una consulta ("¿cuántos combos de AKs quedan dado este board?").

No hay ningún sitio que responda hoy "cuántos combos de una clase/rango siguen vivos dados board + cartas muertas + rango rival". Confirma la necesidad de `ComboEngine` (§F).

### C.6 Posiciones: sin duplicación real (falso positivo a descartar)
Vale la pena decirlo explícitamente porque el pedido pide buscar "duplicate Card/Hand/Range/Action models": **no encontré ninguno**. `TablePositions` (pedagogy) re-exporta `Position`/`Street` del engine en vez de redefinirlos, con un doc-comment que dice literalmente "no reemplaza nada existente". Mismo patrón sano en `PriorAction` vs. `StreetAction` (betting_round.dart:6-10): son dos tipos distintos a propósito (uno indexa por `Position`, el otro por `slot`), con un comentario que explica por qué no se unificaron (cambiar `PriorAction` rompería 12 sitios de uso del motor de una sola decisión sin necesidad real).

### C.7 `AcademyEngine`/`LaboratoryEngine`/`ToolsEngine` — no existen como motores separados
`PokerTrainerEngine` es la única fachada, y la consumen tanto `academy_controller.dart` como `lab_session_controller.dart`. Dentro de ella, `AcademyEngine` (`engine/academy/academy_engine.dart`) es una pieza *de progreso/desbloqueo*, no un motor de reglas de póker paralelo — no evalúa manos ni decide estrategia, solo qué lección sigue. Esto cumple exactamente la regla 15/24 del pedido: no hay motores redundantes por feature.

---

## D. Riesgos si se avanza sin resolver lo anterior

1. **Construir Equity/EV sin el evaluador de manos primero es imposible de verificar de verdad** — se podría "hacer trampa" con equity aproximada por rango de Chen, pero no daría números correctos ni comparables con ningún estándar externo. El evaluador de 7 cartas es la base de todo lo demás (§F, Fase 1 real).
2. **Si `ComboEngine` no nace desde el principio consciente de removal contra board + mano rival**, cualquier Equity Calculator "Hand vs Range" o "Range vs Range" va a sobrecontar combos imposibles — es el error más común y más silencioso en implementaciones de equity caseras.
3. **Si el nuevo `EVEngine` matemático no se nombra y ubica de forma inconfundible respecto al scoring pedagógico existente** (`decisionScore`/`StrategicRating`), alguien va a terminar mezclando "esta decisión tuvo 0.88 de EV" (pedagógico, 0..1) con "esta decisión tuvo +2.3 BB de EV" (matemático) en el mismo widget. Ver convención de nombres en §E.
4. **Si `OpeningRanges` sigue siendo constantes Dart hardcodeadas** cuando se construya Preflop Charts/Range Explorer, cualquier ajuste de rango obliga a shippear una build nueva. Hay que decidir *antes* de Fase 7 si los rangos pasan a vivir como datos (JSON, como ya se hizo con el currículo) — incluso sin llegar a GTO, esto ya es una mejora de mantenibilidad independiente.
5. **Rendimiento de Range vs Range**: sin evaluador, hoy es un no-problema. En cuanto exista, 1326×1326 combos (hasta ~1.7M pares antes de aplicar removal) por cada consulta en un board fijo es perfectamente enumerable exacto en Dart puro para post-flop con board conocido (no requiere Monte Carlo — ver §I). El riesgo real es placement: correrlo en el isolate principal bloquearía el frame de UI en un cálculo de decenas de miles de evaluaciones de 7 cartas.

---

## E. Arquitectura propuesta

Reutilizando lo que ya existe (no se propone mover nada en esta fase, solo dónde debería vivir lo nuevo):

```text
lib/engine/poker/                    (existente, sin cambios)
├── card.dart                        ✅ reutilizar tal cual
├── deck.dart                        ✅ reutilizar tal cual
├── hole_cards.dart                  ✅ reutilizar tal cual (HandClass.combos ya sirve de base)
├── hand_category.dart               ✅ mantener (uso pedagógico, no lo reemplaza el evaluator)
├── board_generator.dart             ✅ reutilizar tal cual
├── position.dart / street.dart      ✅ reutilizar tal cual
├── poker_action.dart                ✅ reutilizar tal cual
└── game/                            ✅ reutilizar tal cual (GameState/ActionResolver/LegalActionEngine/PotManager/PlayerState/BettingRound)

lib/engine/poker/evaluator/          ← NUEVO (Fase 1)
├── five_card_hand.dart              rank de 5 cartas + tiebreakers
└── hand_evaluator.dart              HandEvaluator.best7(List<Card>) → FiveCardHand

lib/engine/poker/combos/             ← NUEVO (Fase 2)
└── combo_engine.dart                ComboEngine (ver API en §F)

lib/engine/poker/equity/             ← NUEVO (Fase 3, depende de evaluator + combos)
├── equity_engine.dart
└── equity_result.dart

lib/engine/poker/pot_odds/           ← NUEVO (Fase 4, sin dependencias nuevas — solo aritmética sobre GameState/pot)
├── pot_odds_engine.dart
└── pot_odds_result.dart

lib/engine/poker/ev/                 ← NUEVO (Fase 5, depende de equity + pot_odds)
├── ev_engine.dart
└── ev_result.dart

lib/engine/poker/sizing/             ← NUEVO (Fase 6, sin dependencias nuevas)
└── bet_sizing_engine.dart

lib/engine/strategy/                 (existente — OpeningRanges migra su CONTENIDO a datos en Fase 6.5,
                                       sin cambiar su API pública: sigue siendo la fuente para
                                       Academia/Laboratorio, Tools la consume igual)
```

No se propone una carpeta `lib/engine/ranges/` nueva: `HandRange` (`strategy/hand_range.dart`) ya cumple ese rol y está bien hecha — se le agregan métodos (`combosGiven(...)`, ver §F.1) en vez de reemplazarla. Mover archivos de lugar no es necesario para que Tools funcione; se documenta como posible limpieza futura, no como parte de esta fase.

---

## F. API propuesta

### F.1 `ComboEngine` (Fase 2)

```dart
/// Combos concretos de una CLASE de mano ("AKs", "QQ"), sin contexto de
/// mesa — pura combinatoria sobre las 52 cartas.
class ComboEngine {
  const ComboEngine._();

  /// Las combinaciones concretas (HoleCards) que representa una clase.
  /// AKs -> 4 combos, QQ -> 6 combos, AKo -> 12 combos.
  static List<HoleCards> combosForHandClass(String notation);

  /// Combos de [notation] que siguen disponibles dado un conjunto de
  /// cartas ya vistas (board + hole cards conocidas de cualquier jugador).
  /// Nunca asume cuáles están "vivas": la respuesta es siempre relativa a
  /// [deadCards].
  static List<HoleCards> combosForHandClass(String notation, {required Set<Card> deadCards});

  /// Todos los combos (HoleCards) que representa un HandRange completo,
  /// ponderados por su frecuencia — devuelve pares (combo, frecuencia),
  /// no una lista plana, para no perder la información de rangos mixtos.
  static Map<HoleCards, double> combosForRange(HandRange range, {Set<Card> deadCards});

  /// Cuenta (no lista) — atajo para UI que solo necesita el número.
  static int comboCountForHandClass(String notation, {Set<Card> deadCards});
  static double comboCountForRange(HandRange range, {Set<Card> deadCards});

  /// Remueve de [range] cualquier combo que use una carta de [blockers]
  /// (mano conocida del héroe, o cartas de board) — devuelve un nuevo
  /// mapa combo→frecuencia, nunca muta [range].
  static Map<HoleCards, double> removeBlocked(
    Map<HoleCards, double> combos, {
    required Set<Card> blockers,
  });
}
```

Invariantes: la suma de `combosForRange` sin `deadCards` para "todas las manos" da exactamente 1326 (ya verificable hoy contra `HandRange.comboCount`, que debe coincidir). Errores: `ArgumentError` si `notation` no es una clase válida (reutilizar `HandClass.isValid`).

### F.2 `HandEvaluator` (Fase 1 — la pieza que desbloquea todo lo demás)

```dart
enum FiveCardHandCategory { highCard, pair, twoPair, trips, straight, flush, fullHouse, quads, straightFlush }
// Reutiliza los mismos 9 valores y el mismo orden que ya tiene
// `HandCategory` (poker/hand_category.dart) — incluso podría ser el
// mismo enum, evaluado: no crear una jerarquía paralela de nombres.

/// La mejor mano de 5 cartas posible, con desempate completo.
class FiveCardHand implements Comparable<FiveCardHand> {
  final FiveCardHandCategory category;
  /// Rangos ordenados de mayor a menor peso para el desempate DENTRO de
  /// la categoría (ej. full house: [rango del trío, rango del par]).
  final List<Rank> tiebreakers;
  final List<Card> cards; // las 5 cartas exactas que forman la mano

  @override
  int compareTo(FiveCardHand other); // >0 gana this, 0 empate exacto
}

class HandEvaluator {
  const HandEvaluator._();

  /// La mejor mano de 5 cartas posible combinando [holeCards] + [board]
  /// (board de 3, 4 o 5 cartas — típicamente flop/turn/river).
  static FiveCardHand best(HoleCards holeCards, List<Card> board);

  /// Compara directamente dos manos en el mismo board. Atajo sobre
  /// [best] + [FiveCardHand.compareTo] para el caso más común de UI.
  static int compare(HoleCards a, HoleCards b, List<Card> board);

  /// Resuelve el/los ganador(es) entre N manos en el mismo board —
  /// puede haber empate (más de un slot). Reemplaza a `GameState.
  /// winnerSlots == null` cuando `needsShowdown` es true.
  static Set<int> winners(Map<int, HoleCards> handsBySlot, List<Card> board);
}
```

Validaciones: lanza `ArgumentError` si `board.length` no es 0/3/4/5 (reutilizar `Street.boardCards` como referencia), o si hay cartas repetidas entre `holeCards` y `board` (reutilizar el mismo patrón de `checkUnique` que ya usa `GameState`). Complejidad: evaluar las C(7,5)=21 combinaciones de 5 cartas de un set de 7 y quedarse con la mejor es trivial en performance (no hace falta una tabla de lookup tipo "2+2 evaluator" para el volumen de FLOPly — ver §I).

### F.3 `EquityEngine` (Fase 3)

```dart
enum EquityMethod { exactEnumeration, monteCarlo }

class EquityResult {
  final double heroEquityPct;      // 0..100, incluye la porción de empates
  final double villainEquityPct;   // heroEquityPct + villainEquityPct == 100 (heads-up)
  final double heroWinPct;
  final double heroTiePct;
  final int scenariosEvaluated;    // combinaciones exactas evaluadas, o simulaciones si Monte Carlo
  final EquityMethod method;
  // Para rango vs rango: equity por combo del héroe, para permitir
  // pintar la matriz de rangos con gradiente de equity por celda.
  final Map<HoleCards, double>? heroEquityByCombo;
}

class EquityEngine {
  const EquityEngine._();

  /// Caso A: mano vs mano, cualquier street (board 0/3/4/5 cartas).
  static EquityResult handVsHand(HoleCards hero, HoleCards villain, {List<Card> board = const []});

  /// Caso B: mano vs rango.
  static EquityResult handVsRange(HoleCards hero, HandRange villainRange, {List<Card> board = const []});

  /// Caso C: rango vs rango.
  static EquityResult rangeVsRange(HandRange heroRange, HandRange villainRange, {List<Card> board = const []});

  // Los casos D/E del pedido ("Hand vs Range + Board", "Range vs Range +
  // Board") son handVsRange/rangeVsRange con `board` no vacío — no
  // necesitan métodos separados, el parámetro ya lo cubre.
}
```

**Decisión de método — enumeración exacta, no Monte Carlo, para el 100% de los casos de FLOPly** (ver justificación completa en §I). `EquityMethod` queda en el resultado como metadata informativa, no porque haya que elegir entre los dos en la práctica.

### F.4 `PotOddsEngine` (Fase 4)

```dart
class PotOddsResult {
  final double potBeforeCallBb;   // pot actual, antes de que el héroe pague
  final double callAmountBb;      // lo que el héroe tiene que poner
  final double potAfterCallBb;    // potBeforeCallBb + callAmountBb
  final double requiredEquityPct; // callAmountBb / potAfterCallBb * 100
  final double potOddsRatio;      // potBeforeCallBb : callAmountBb, como ratio (ej. 3:1)
}

class PotOddsEngine {
  const PotOddsEngine._();

  static PotOddsResult calculate({
    required double potBb,
    required double betBb,     // lo que apostó el rival (0 si no hay bet que enfrentar)
    required double callBb,    // lo que le cuesta al héroe igualar (puede ser < betBb si es all-in corto)
  });

  /// Atajo: arma el resultado directamente desde un GameState real (Tools
  /// "en vivo" contra una situación jugable) — nunca reinventa la
  /// aritmética, delega a `calculate` con los números que ya calcula
  /// `DecisionContext`.
  static PotOddsResult fromDecisionContext(DecisionContext context);
}
```

Fórmula: `requiredEquity = callBb / (potBb + betBb + callBb)` — el pot final incluye el propio call del héroe (ver §H). No side pots ni rake en V1 (mismo alcance que `PotManager` hoy: bote único).

### F.5 `EVEngine` (Fase 5)

```dart
/// EV matemático en BB — deliberadamente sin ningún campo ni tipo en
/// común con `EvaluationResult`/`StrategicRating` (scoring pedagógico).
/// Ver §C.2: son dos conceptos distintos y no deben compartir vocabulario.
class ChipEvResult {
  final double evBb;              // valor esperado en BB (puede ser negativo)
  final double equityPct;         // la equity usada para el cálculo
  final double? foldEquityPct;    // null si no aplica (ej. EV de un call)
  final String action;            // descripción de qué acción se evaluó
}

class EVEngine {
  const EVEngine._();

  /// EV de pagar una apuesta: equity * potFinal - costoDelCall.
  static ChipEvResult ofCall({
    required double potBb,
    required double callBb,
    required double heroEquityPct,
  });

  /// EV de retirarse: siempre 0 (no se pierde nada adicional a lo ya
  /// invertido, que es hundido — no entra en este cálculo).
  static ChipEvResult ofFold();

  /// EV de apostar/subir: combina el caso "el rival se retira" (gana el
  /// pot actual, ponderado por foldEquityPct) con el caso "el rival paga"
  /// (heroEquityPct sobre el pot final), igual que la fórmula estándar.
  static ChipEvResult ofBet({
    required double potBb,
    required double betBb,
    required double foldEquityPct,
    required double heroEquityPct, // equity de hero cuando el rival SÍ paga
  });
}
```

### F.6 `BetSizingEngine` (Fase 6)

```dart
enum BetSizingContext { openRaise, threeBet, fourBet, continuationBet, shove }

class BetSizingSuggestion {
  final double sizeBb;
  final double? percentOfPot;   // null si no aplica (ej. sizing preflop en BB no se piensa en % de pot)
  final String rationale;       // texto corto, reutilizando el mismo patrón de `rationaleKey` que ya usa Strategy
}

class BetSizingEngine {
  const BetSizingEngine._();

  /// Delega en OpeningRanges.sizingFor para el caso que YA existe —
  /// nunca reimplementa esa regla en paralelo.
  static double openRaiseSizing(Position position) => OpeningRanges.sizingFor(position);

  /// Nuevo: sizing como % del pot, para contextos postflop.
  static double potSizedBet(double potBb, {double fraction = 1.0}) => potBb * fraction;

  /// Valida si un sizing propuesto es "razonable" para el contexto —
  /// mismo patrón que ya usa `OpeningRanges.isReasonableSizing`.
  static bool isReasonable(BetSizingContext context, double sizeBb, {required double potBb});
}
```

---

## G. Modelos de datos nuevos (resumen)

| Clase | Ubicación | Para qué |
|---|---|---|
| `FiveCardHand` | `poker/evaluator/five_card_hand.dart` | resultado de evaluar 7→5 cartas, comparable |
| `EquityResult` | `poker/equity/equity_result.dart` | resultado de cualquier cálculo de equity |
| `PotOddsResult` | `poker/pot_odds/pot_odds_result.dart` | resultado de pot odds |
| `ChipEvResult` | `poker/ev/ev_result.dart` | resultado de EV matemático (nombre deliberadamente distinto a `EvaluationResult`) |
| `BetSizingSuggestion` | `poker/sizing/bet_sizing_engine.dart` | resultado de sugerencia de sizing |

Todos siguen el mismo patrón que ya usa el resto del motor: inmutables, sin lógica de UI, `toString()` legible para debug, sin `Equatable`/paquetes externos (el proyecto no usa ninguno — coherente con la superficie mínima de dependencias que ya tiene `pubspec.yaml`).

---

## H. Fórmulas

### Equity
```
heroEquity% = (heroWins + heroTies / numJugadoresEnElEmpate) / totalEscenarios × 100
```
Sobre TODOS los boards posibles restantes (enumeración exacta) o sobre N boards muestreados (Monte Carlo) — ver §I para cuál usa FLOPly en cada caso.

### Pot Odds
```
potFinal = potActual + betDelRival + callDelHéroe
requiredEquity% = callDelHéroe / potFinal × 100
```
Equivalente a la razón `potOddsRatio = potActual+betDelRival : callDelHéroe`. **Nunca** se calcula sin sumar el propio call del héroe al pot final — es el error más común al implementar esto (usar `potActual / call` en vez de `potActual+call / call`... en realidad el error típico es *olvidar* sumar el call propio al denominador).

### EV (call)
```
EV(call) = heroEquity% × potFinal − callDelHéroe × (1 − heroEquity%)
```
equivalente a la forma más común `EV = P(ganar) × ganancia − P(perder) × costo`.

### EV (bet/raise, con fold equity)
```
EV(bet) = foldEquity% × potActual + (1 − foldEquity%) × [heroEquityCuandoPagan% × potFinal − betSize × (1 − heroEquityCuandoPagan%)]
```

Estas fórmulas son estándar de teoría de póker (no específicas de FLOPly) — se documentan acá para que la implementación tenga una única fuente de verdad escrita, en vez de que cada método las repita con una variación sutil.

---

## I. Precisión matemática: enumeración exacta vs. Monte Carlo

**Recomendación: enumeración exacta para el 100% de los casos que Tools V1/V2 necesita.** Justificación con números reales, no una elección por defecto:

- **Hand vs Hand, cualquier calle**: con board conocido de 3/4/5 cartas, quedan como máximo 47 cartas por repartir para completar hasta el river en los casos preflop/flop — C(47,2)=1081 combinaciones en preflop (peor caso), bajando a C(46,1)=46 en turn y 1 en river. Esto es instantáneo.
- **Hand vs Range**: 1 mano del héroe vs hasta 169 clases del rival (≤1326 combos crudos, bajando tras remover bloqueos del héroe/board) × hasta C(47,2) runouts en preflop. El peor caso real (preflop, rango amplio) son unos pocos millones de evaluaciones de 5-de-7 — perfectamente enumerable en un isolate en un tiempo razonable (ver más abajo sobre dónde correrlo).
- **Range vs Range preflop**: es el caso más pesado — hasta ~1326×1326 pares de combos (antes de remover los que comparten carta, que se descartan) × runouts. Es el único caso donde vale la pena **cachear por combinación de rango**, no cambiar de método. Con board ya conocido (post-flop) el espacio de runouts se reduce drásticamente y dejar de ser un problema.

Monte Carlo introduciría **ruido no determinista** exactamente en un producto educativo donde la app le está enseñando al usuario "esta es tu equity real" — un resultado que cambia un poco cada vez que se recalcula mina la confianza pedagógica sin necesidad, cuando la alternativa exacta es computacionalmente viable. Se descarta activamente, no por default.

### Performance — qué sí hace falta resolver
- **Isolates**: el cálculo de Range vs Range preflop (el único caso pesado) debe correr en un `Isolate` separado (`compute()` de Flutter), nunca en el isolate de UI — esto es lo único que realmente hace falta decidir *antes* de construir el Equity Calculator, no una optimización prematura: sin esto, la UI se congela visiblemente en ese caso concreto.
- **Memoization/caching**: cachear `EquityResult` por la tupla `(heroRangeOrHand, villainRangeOrHand, board)` dentro de una sesión de Tools evita recalcular si el usuario solo cambia una carta y vuelve — razonable para Fase 7 (Tools V1), no antes.
- **Nada de tablas de lookup precomputadas** (tipo "2+2 hand evaluator" con tablas de 32M entradas): a la escala de FLOPly (evaluaciones puntuales bajo demanda del usuario, no miles de manos por segundo para un solver) la evaluación directa de C(7,5)=21 combinaciones por mano es más que suficiente y mucho más simple de mantener/testear.

---

## J. Testing

Estrategia por engine nuevo, con foco en casos deterministas (todos los casos de abajo son 100% deterministas — no dependen de una semilla porque son enumeración exacta, no Monte Carlo):

### `HandEvaluator`
- Las 9 categorías reconocidas correctamente desde 7 cartas (una por categoría, con kickers que importan).
- Desempates: dos manos de la misma categoría, distinto tiebreaker (ej. dos tríos con kicker distinto).
- Empate exacto (board juega: ej. board de escalera donde ambos juegan las 5 del board).
- Casos "trampa" clásicos: la mano que "parece" mejor pero no lo es (ej. dos pares en mano vs. trío usando el board).
- Wheel (A-2-3-4-5, el As juega bajo) — caso especial de escalera que suele romper implementaciones ingenuas.
- straight flush vs. flush + straight sueltos en el mismo board (debe reconocer straight flush, no dos manos separadas).

### `ComboEngine`
- `combosForHandClass('AA')` → 6 combos exactos.
- `combosForHandClass('AKs')` → 4, `('AKo')` → 12.
- Suma total sobre las 169 clases = 1326.
- `deadCards` con la propia mano del héroe: remueve exactamente los combos que comparten una carta.
- Rango vacío tras removal total (ej. rango = solo `AsKs`, board ya tiene `As`) → 0 combos, sin excepción.

### `EquityEngine`
Casos de referencia con valores conocidos externamente (poder verificar contra una calculadora de equity de referencia, no solo contra el propio código):
- `AA vs KK` preflop (~82% vs ~18%).
- `AKs vs QQ` preflop (~coinflip, ligeramente a favor de QQ).
- `AA vs mano random` preflop (~85%).
- Nut flush vs. set en un board de color (equity fuertemente a favor del flush, pero no 100% — el set tiene outs a full house).
- Straight vs. flush en un board con ambos proyectos completos (la flush gana, equity 100/0 en ese board exacto).
- Empate exacto por board (ej. board de escalera que juega para ambos sin que ninguna mano lo mejore) → heroEquity% = villainEquity% = 50 (o el reparto que corresponda entre N jugadores empatados).
- Combos bloqueados: la equity de un rango vs. una mano que contiene cartas del propio rango debe excluir esos combos, no solo ponderarlos en 0 silenciosamente (verificar `scenariosEvaluated` para confirmar que de verdad se excluyeron, no que se contaron con equity 0).

### `PotOddsEngine`
- Ejemplo del propio pedido: pot 10bb, bet 5bb → requiredEquity = 5/(10+5+5) = 25%.
- Call de 0 (check-through, no debería llamarse en este caso — validar que lance o devuelva un resultado degenerado explícito, no NaN).
- All-in corto (call menor al bet nominal del rival porque el héroe no tiene stack suficiente).

### `EVEngine`
- EV de fold siempre 0.
- EV de call con equity exacta conocida de un caso de `EquityEngine` ya testeado (para que los dos módulos se validen cruzados).
- EV de bet con fold equity 0% (el rival nunca se retira) debe colapsar a la misma fórmula que EV de call desde la perspectiva de quien paga.
- EV de bet con fold equity 100% debe dar exactamente `potActual` (el bet siempre gana el pot actual sin showdown).

### Pot / Actions / Sizing
Ya cubiertos hoy por `game_state_test.dart`, `action_resolver_test.dart`, `action_resolver_hardening_test.dart`, `legal_action_engine_test.dart` — no hace falta rehacer esta suite, solo extenderla cuando `BetSizingEngine`/side pots se implementen.

---

## K. Integración con Academia / Laboratorio / Tools / Coach / Stats

```text
                         PokerEngine (existente + nuevo)
                                    │
       ┌────────────────┬──────────┼──────────┬─────────────────┐
       │                │          │          │                 │
    Academia       Laboratorio   Tools      Coach            Stats
```

- **Academia**: no toca nada de lo nuevo en esta fase (regla explícita del pedido). A futuro, `HandEvaluator` podría reemplazar los showdowns *guionados* que hoy arma `TableBuilder`/`table_lesson.dart` a mano por resultados calculados — pero eso es una decisión de contenido, no de motor, y está fuera de esta fase.
- **Laboratorio**: es quien más se beneficia de `HandEvaluator`/`OpponentPolicy` postflop — desbloquea manos completas preflop→river contra un rival "vivo" en vez de terminar la mano en la decisión preflop. No depende de que Tools exista.
- **Tools**: consume los engines nuevos directamente (Range Explorer → `HandRange`+`ComboEngine`; Equity Calculator → `EquityEngine`; Pot Odds/EV Calculator → `PotOddsEngine`/`EVEngine`). No necesita nada de Academia/Laboratorio.
- **Coach** (futuro): el patrón ya existe y funciona hoy —
  ```
  Equity Calculator (Tools) → concepto "equity" (ya existe en ConceptIds.equity)
                             → ConceptRegistry.byId('equity')
                             → UserKnowledge.masteryOf('equity')
                             → si es floja, RecoverySession.forWeakestConcept ya sabe sugerir repaso
  ```
  Es decir: **no hace falta diseñar nada nuevo para esta integración**, `ConceptRegistry`/`UserKnowledge`/`RecoverySession` ya son genéricos y Tools solo necesita, cuando exista su UI, llamar `knowledge.recordAttempt('equity', ...)` cuando corresponda (p. ej. si Tools en algún momento incluye "practicar" y no solo "consultar" — para V1, que es pura consulta, ni siquiera hace falta esto).
- **Stats**: no existe la pantalla (confirmado en la auditoría del checklist maestro, sesión anterior), pero las fuentes de datos (`AcademyProgress`, `UserKnowledge`, `ExerciseHistory`) ya están listas para alimentarla — Tools no agrega nueva complejidad acá porque V1 es solo consulta, sin historial.

---

## L. Plan de implementación (fases pequeñas)

```text
FASE 1 — HandEvaluator — HECHO
  poker/evaluator/{five_card_hand,hand_evaluator}.dart + 35 tests.
  Desbloqueó GameState.needsShowdown (integración pendiente, documentada,
  no hecha — ver el informe original) y es prerrequisito de todo lo de
  abajo.

FASE 2 — ComboEngine — HECHO
  poker/combos/combo_engine.dart + 26 tests.

FASE 3 — EquityEngine — HECHO (las 3 variantes)
  poker/equity/{equity_engine,equity_result}.dart. handVsHand +
  handVsRange + rangeVsRange, enumeración exacta, 29 tests con casos de
  referencia (dominación, chop, wheel, card removal, rangos que se
  bloquean entre sí). rangeVsRange nunca lanza si algún combo puntual del
  héroe deja al rival sin combos — lo excluye del total; solo lanza si
  NINGÚN combo del héroe deja algo jugable. Medido (no optimizado de
  antemano): handVsRange de 34 combos en flop, ~2.2s — confirma que
  Range vs Range en Tools va a necesitar isolate/compute(), tal como
  anticipaba este informe (§I) — decisión de UI, no del engine.

FASE 4 — PotOddsEngine — HECHO
  poker/pot_odds/{pot_odds_engine,pot_odds_result}.dart + 12 tests.
  Nota (2026-09-18): esta fase se perdió de una compactación de contexto
  y por un momento quedó sobreescrita con una API distinta (con `betBb`
  como tercer parámetro) al reimplementarla sin saber que ya existía —
  se detectó al instante porque rompió `ev_engine_test.dart`, y se
  reconstruyó la API original (`calculate({potBeforeCallBb, callAmountBb})`,
  `requiredEquity` en escala 0..1) a partir de ese archivo y de los
  doc-comments de EVEngine, que sí seguían intactos. Los 55 tests
  cruzados de Equity+PotOdds+EV confirman que la reconstrucción es fiel.

FASE 5 — EVEngine — HECHO (calculateCall)
  poker/ev/{ev_engine,ev_result}.dart. Solo `calculateCall` (no
  `ofFold`/`ofBet` del diseño original — `ofFold` es trivial, `ofBet`
  queda para cuando haga falta de verdad). 22 tests, incluida
  coherencia cruzada con PotOddsEngine (equity == requiredEquity da
  EV=0 exacto, por encima da EV>0, por debajo EV<0).

FASE 6 — BetSizingEngine — HECHO (alcance acotado a postflop)
  poker/sizing/bet_sizing_engine.dart + 10 tests. Decisión tomada al
  implementarla: NO envuelve `OpeningRanges.sizingFor`/
  `isReasonableSizing` — esa sigue siendo la única fuente de verdad para
  sizing preflop, ya probada e integrada en todo el motor. Envolverla acá
  hubiera creado una segunda forma de pedir el mismo número (justo lo que
  la regla 19 del pedido de auditoría general pide evitar). Esta clase es
  específicamente el complemento que faltaba: conversión bet-en-BB ↔
  fracción del bote, para sizing postflop (que hoy no existe en ningún
  otro lado del motor).

FASE 6.5 — OpeningRanges → datos — HECHO (2026-09-18, fuera del orden original)
  Implementado antes de lo planeado, a pedido explícito, como bloque P2
  de la auditoría general. assets/ranges/opening_ranges.json es ahora la
  fuente de verdad (mismo patrón que assets/curriculum/curriculum_spec.json:
  JSON legible/editable → tool/ranges/gen_opening_ranges.dart compila a
  lib/engine/strategy/opening_ranges_data.g.dart, que la clase carga de
  forma síncrona). API pública de OpeningRanges sin cambios — cero
  callers tocados (StrategyEngine/OpponentPolicy/PreflopStrategy siguen
  llamando exactamente los mismos 3 métodos). 11 tests nuevos
  (test/engine/opening_ranges_test.dart) fijan los valores de referencia
  para que un cambio accidental en el JSON se note. flutter analyze: 0
  issues. flutter test completo: sin regresiones. flutter build web: OK.

FASE 7 — Tools V1 (UI)
  Range Explorer + Preflop Charts + Equity Calculator + Pot Odds Calculator,
  consumiendo Fases 1-6 tal cual. Primera vez que se toca lib/screens/ para
  Tools. Fuera del alcance de ESTA fase (Fase 0), que es solo auditoría/diseño.

FASE 8+ — Tools V2 (Hand vs Range, Range vs Range, EV Calculator, Combo
  Calculator, Blocker Explorer) — mismo motor, más superficie de UI.

FUERA DE ALCANCE por ahora (correctamente pospuesto, coherente con la
regla 11 del pedido): GTO Preflop/Decision/Postflop. La arquitectura de
arriba no lo bloquea — Range/Combo/Equity/Board/Action/BetSizing/EV quedan
en forma de poder alimentar frecuencias mixtas y un futuro import de
soluciones precomputadas sin rehacerse.
```

---

## Restricciones respetadas durante esta fase

No se modificó: curriculum, IDs, unlocks, navegación, progreso, mentor lessons, Academia, Laboratorio, ni se creó ninguna pantalla, Table Mode, ni código de GTO. No se duplicó ningún motor nuevo — todo lo propuesto en §E/§F es sobre carpetas que hoy no existen, reutilizando en cada API las piezas ya auditadas en §A. Único archivo nuevo: este informe.
