import '../poker/position.dart';
import 'hand_range.dart';

/// Rangos de referencia para "enfrentar una apertura" (call / 3-bet por
/// valor / 3-bet como farol), anclados a un par de posiciones concreto
/// — mismo criterio pedagógico que [OpeningRanges] (rangos coherentes y
/// ampliamente aceptados para 6-max ~100bb cash, nunca una solución
/// GTO exacta), pero para el lado de la defensa en vez del lado de la
/// apertura.
class PreflopRangeAnchor {
  const PreflopRangeAnchor({
    required this.heroPosition,
    required this.villainPosition,
    required this.callRange,
    required this.threeBetValueRange,
    required this.threeBetBluffRange,
  });

  final Position heroPosition;
  final Position villainPosition;

  /// Manos con las que el héroe paga la apertura del rival — el "piso"
  /// de la defensa, sin pretensión de re-subir.
  final HandRange callRange;

  /// Manos con las que el héroe re-sube buscando valor: tienen que
  /// quedar genuinamente adelante de lo que puede mostrar el rango de
  /// apertura real del rival (`OpeningRanges`) — verificado por test al
  /// autorar la tabla, nunca recalculado en runtime. Ver
  /// `test/engine/preflop_range_book_test.dart`.
  final HandRange threeBetValueRange;

  /// Manos con las que el héroe re-sube como farol — nunca "porque son
  /// fuertes": la justificación es bloqueadores + jugabilidad + fold
  /// equity (ver el doc-comment de `StrategyRole.bluff`). Se solapa a
  /// propósito con manos que también son un call razonable — cuál de
  /// las dos líneas es mejor depende del perfil del rival, algo que el
  /// ejercicio no le muestra al alumno (de ahí que la opción de 3-bet
  /// quede marcada `ContextSensitivity.dependent` en
  /// `DefenseVsOpenStrategy`, no acá).
  final HandRange threeBetBluffRange;
}

/// Rango de referencia para "encarar un 3-bet" (fold / call / 4-bet por
/// valor) — el héroe ya fue el agresor preflop y ahora un rival le
/// re-sube. Tipo separado de [PreflopRangeAnchor] a propósito: 4-bet no
/// es "otro 3-bet" (concepto distinto, `ConceptIds.threeBet` no aplica
/// acá), y esta pasada no modela un 4-bet como farol (ver
/// `FacingThreeBetStrategy` — deuda reconocida, no silenciada).
class PreflopFacingThreeBetAnchor {
  const PreflopFacingThreeBetAnchor({
    required this.heroPosition,
    required this.threeBettorPosition,
    required this.callRange,
    required this.fourBetValueRange,
  });

  final Position heroPosition;
  final Position threeBettorPosition;

  /// Manos con las que el héroe paga el 3-bet, sin re-subir.
  final HandRange callRange;

  /// Manos con las que el héroe re-sube (4-bet) buscando valor —
  /// verificadas por test contra el rango de 3-bet real de
  /// [threeBettorPosition] ([PreflopRangeBook.anchorFor] del 3-bettor
  /// contra la apertura del héroe).
  final HandRange fourBetValueRange;
}

/// Rango de referencia para "empujar o foldear" a stack corto — el
/// héroe encara una apertura con un stack lo bastante corto como para
/// que flatear sea generalmente peor que jugarse todo o retirarse
/// (teoría estándar de push/fold). Deliberadamente **una sola
/// profundidad** (la que usa `ExerciseScenarioBuilder.
/// shortStackFacingOpen` por default, ~8bb) — no hay todavía tiers por
/// profundidad de stack (deuda reconocida en la memoria del proyecto).
class PreflopShortStackAnchor {
  const PreflopShortStackAnchor({
    required this.heroPosition,
    required this.villainPosition,
    required this.shoveRange,
  });

  final Position heroPosition;
  final Position villainPosition;

  /// Manos con las que el héroe se juega todo el stack.
  final HandRange shoveRange;
}

/// Alcance deliberado (Fase 1 del rediseño del motor preflop del
/// Laboratorio — ver la memoria del proyecto `laboratorio-motor-preflop`
/// para la auditoría/especificación completas): anclas reales solo para
/// los pares/situaciones que usan por default cada método de
/// `ExerciseScenarioBuilder` (`defenseVsOpen`→BB vs CO,
/// `threeBet`→BTN vs UTG, `facingThreeBet`→CO agresor / BTN 3-bettor,
/// `shortStackFacingOpen`→BB vs CO a ~8bb). Cualquier otra combinación
/// no tiene ancla propia todavía — cada `xxxFor` devuelve `null`, y
/// `PreflopStrategy.forDecision` cae de vuelta a la heurística de
/// percentil anterior en vez de inventar un rango sin fuente (ver su
/// doc-comment).
class PreflopRangeBook {
  const PreflopRangeBook._();

  static final Map<(Position, Position), PreflopRangeAnchor> _anchors = {
    (Position.bb, Position.co): _bbVsCo,
    (Position.btn, Position.utg): _btnVsUtg,
    (Position.btn, Position.co): _btnVsCo,
  };

  static final Map<(Position, Position), PreflopFacingThreeBetAnchor>
      _facingThreeBetAnchors = {
    (Position.co, Position.btn): _coFacingBtnThreeBet,
  };

  static final Map<(Position, Position), PreflopShortStackAnchor>
      _shortStackAnchors = {
    (Position.bb, Position.co): _bbVsCoShortStack,
  };

  /// La ancla para `hero` defendiendo contra la apertura de `villain`,
  /// o `null` si todavía no existe una tabla real para ese par.
  static PreflopRangeAnchor? anchorFor(Position hero, Position villain) =>
      _anchors[(hero, villain)];

  /// La ancla para `hero` (agresor preflop) encarando un 3-bet real de
  /// `threeBettor`, o `null` si todavía no existe una tabla real para
  /// ese par.
  static PreflopFacingThreeBetAnchor? facingThreeBetAnchorFor(
          Position hero, Position threeBettor) =>
      _facingThreeBetAnchors[(hero, threeBettor)];

  /// La ancla de empuje-o-fold para `hero` a stack corto encarando la
  /// apertura de `villain`, o `null` si todavía no existe una tabla
  /// real para ese par.
  static PreflopShortStackAnchor? shortStackAnchorFor(
          Position hero, Position villain) =>
      _shortStackAnchors[(hero, villain)];

  /// BB defendiendo contra un open de CO (rango real: `OpeningRanges.
  /// forPosition(Position.co)`, ~27% de las manos) — el par de default
  /// de `ExerciseScenarioBuilder.defenseVsOpen`.
  static final PreflopRangeAnchor _bbVsCo = PreflopRangeAnchor(
    heroPosition: Position.bb,
    villainPosition: Position.co,
    threeBetValueRange: HandRange.parse(const ['QQ+', 'AKs', 'AKo']),
    threeBetBluffRange: HandRange.parse(const ['A5s-A2s']),
    callRange: HandRange.parse(const [
      '22', '33', '44', '55', '66', '77', '88', '99', 'TT', 'JJ',
      'ATs-AQs', 'KTs+', 'QTs+', 'JTs', 'T9s', '98s', '87s', '76s', '65s', '54s',
      // Hasta AQo, nunca AKo — ese ya es 3-bet de valor (ver arriba); lo
      // mismo para KJo+/QJo, que no llegan a pisar ningún As.
      'AQo-ATo', 'KJo+', 'QJo',
    ]),
  );

  /// BTN defendiendo contra un open de UTG (rango real: `OpeningRanges.
  /// forPosition(Position.utg)`, el más angosto de la mesa) — el par de
  /// default de `ExerciseScenarioBuilder.threeBet`. Más angosto que BB
  /// vs CO a propósito: UTG abre mucho más fuerte que CO, así que tanto
  /// el call range como el 3-bet de valor suben el piso.
  static final PreflopRangeAnchor _btnVsUtg = PreflopRangeAnchor(
    heroPosition: Position.btn,
    villainPosition: Position.utg,
    threeBetValueRange: HandRange.parse(const ['JJ+', 'AKs', 'AKo']),
    threeBetBluffRange: HandRange.parse(const ['A5s-A2s']),
    callRange: HandRange.parse(const [
      '22', '33', '44', '55', '66', '77', '88', '99', 'TT',
      'ATs-AQs', 'KTs+', 'QTs+', 'JTs', 'T9s', '98s', '87s', '76s',
      // Hasta AQo, nunca AKo — ese ya es 3-bet de valor (ver arriba).
      'AQo-AJo', 'KQo',
    ]),
  );

  /// BTN defendiendo contra un open de CO (rango real: `OpeningRanges.
  /// forPosition(Position.co)`, ~27%, el mismo que ve BB). Reutilizada
  /// también como el rango de 3-bet REAL con el que
  /// `ExerciseScenarioBuilder.facingThreeBet` samplea la mano del
  /// 3-bettor (BTN) — antes un fijo `{AA,KK,AKs}` sin relación con
  /// ningún rango de verdad.
  static final PreflopRangeAnchor _btnVsCo = PreflopRangeAnchor(
    heroPosition: Position.btn,
    villainPosition: Position.co,
    threeBetValueRange: HandRange.parse(const ['JJ+', 'AKs', 'AKo']),
    threeBetBluffRange: HandRange.parse(const ['A5s-A2s']),
    callRange: HandRange.parse(const [
      '22', '33', '44', '55', '66', '77', '88', '99', 'TT',
      'ATs-AQs', 'K9s+', 'QTs+', 'JTs', 'T9s', '98s', '87s', '76s', '65s',
      'AQo-ATo', 'KJo+', 'QJo',
    ]),
  );

  /// CO (agresor preflop) encarando un 3-bet real de BTN — el par de
  /// default de `ExerciseScenarioBuilder.facingThreeBet`. El 4-bet de
  /// valor queda deliberadamente angosto (KK+/AKs, sin QQ): el rango de
  /// 3-bet de BTN acá (`_btnVsCo.threeBetValueRange` ∪
  /// `.threeBetBluffRange`) ya incluye JJ+, así que QQ no está
  /// claramente adelante — no se fuerza a entrar solo para llenar la
  /// categoría (ver el test de coherencia contra el rango real).
  static final PreflopFacingThreeBetAnchor _coFacingBtnThreeBet =
      PreflopFacingThreeBetAnchor(
    heroPosition: Position.co,
    threeBettorPosition: Position.btn,
    fourBetValueRange: HandRange.parse(const ['KK+', 'AKs']),
    callRange: HandRange.parse(const ['QQ', 'JJ', 'AKo', 'AQs']),
  );

  /// BB a stack corto (~8bb, el default de `ExerciseScenarioBuilder.
  /// shortStackFacingOpen`) encarando un open de CO — empuje-o-fold
  /// deliberadamente ancho: con tan poco stack detrás, la fold equity y
  /// la equity de showdown contra un caller ya hacen rentable empujar
  /// mucho más ancho que cualquier 3-bet de 100bb (teoría estándar de
  /// push/fold, simplificada — no sale de un solver Nash real).
  static final PreflopShortStackAnchor _bbVsCoShortStack =
      PreflopShortStackAnchor(
    heroPosition: Position.bb,
    villainPosition: Position.co,
    shoveRange: HandRange.parse(const [
      '22+',
      'A2s+', 'K5s+', 'Q8s+', 'J8s+', 'T8s+', '97s+', '86s+', '76s', '65s', '54s',
      'A2o+', 'K9o+', 'QTo+', 'JTo',
    ]),
  );
}
