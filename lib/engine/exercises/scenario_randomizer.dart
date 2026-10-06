import '../poker/deck.dart';
import '../poker/position.dart';

/// Arma combinaciones de posición/stack variadas para cada familia de
/// escenario — la pieza que faltaba para que el Laboratorio no repita
/// siempre la misma pareja de posiciones. Antes de esto,
/// `LabSessionController` llamaba a cada método de
/// `ExerciseScenarioBuilder` sin pisar ninguno de sus valores por
/// default, así que `openRaise` SIEMPRE era BTN, `defenseVsOpen` SIEMPRE
/// BB vs CO, `cbetDecision` SIEMPRE BTN vs BB, etc. — la variedad real
/// quedaba limitada a qué mano tocaba, nunca a la situación en sí.
///
/// Esta clase solo ELIGE qué parámetros pasarle al builder — nunca
/// decide legalidad ni estrategia. Cada combinación que arma ya es
/// válida por construcción (mismas reglas de orden de acción que
/// `ExerciseScenarioBuilder._requireActsBefore` ya exige), así que nunca
/// hace falta reintentar tras un `ArgumentError`.
///
/// Todo el azar sale de [Deck] (`pick`/`intInRange`) — el mismo único
/// funnel de aleatoriedad que ya usa el resto del motor (ver el
/// doc-comment de `Deck` y de `ScenarioBuilder.freshHand`).
class ScenarioRandomizer {
  const ScenarioRandomizer._();

  /// Asiento del botón — variar esto varía qué asiento físico se ve en
  /// cada posición, aunque la posición relativa del héroe sea la misma.
  static int buttonSlot(Deck deck) => deck.intInRange(0, 5);

  /// [heroPosition] para `openRaise`: cualquier posición que puede abrir
  /// first-in (nunca la BB — ver `ExerciseScenarioBuilder.openRaise`).
  static Position openRaiseHeroPosition(Deck deck) =>
      deck.pick(Position.openers);

  /// Pareja (opener, hero) para `defenseVsOpen`/`threeBet`/`shortStack`:
  /// [Position] abre, el héroe responde — tiene que actuar después
  /// preflop. El orden del enum ya es el orden de acción preflop (ver el
  /// doc-comment de [Position]), así que "actuar después" es simplemente
  /// un índice mayor.
  static (Position opener, Position hero) facingOpenPositions(Deck deck) {
    final opener = deck.pick(Position.openers);
    final later =
        Position.values.where((p) => p.index > opener.index).toList();
    return (opener, deck.pick(later));
  }

  /// Pareja (hero, threeBettor) para `facingThreeBet`: el héroe abre,
  /// quien re-sube tiene que actuar después preflop.
  static (Position hero, Position threeBettor) facingThreeBetPositions(Deck deck) {
    final hero = deck.pick(Position.openers);
    final later =
        Position.values.where((p) => p.index > hero.index).toList();
    return (hero, deck.pick(later));
  }

  /// Pares (héroe, rival) válidos para las familias donde el héroe fue
  /// el agresor preflop Y tiene posición postflop (`cbetDecision`,
  /// `turnBarrel`, `riverBarrel`): el rival tiene que poder actuar
  /// DESPUÉS del héroe preflop (para que pagar la subida del héroe
  /// tenga sentido — si actuara antes, `ExerciseScenarioBuilder`
  /// tendría que dejarlo decidir vía `OpponentPolicy` en preflop antes
  /// de que el héroe llegue a abrir, rompiendo el guion) pero ANTES que
  /// el héroe en cada calle postflop (para que la decisión del héroe
  /// sea real, con posición). Verificado a mano contra el orden de
  /// acción real (`Position.index` = preflop, `TablePositions.
  /// order(Street.flop)` = postflop): la intersección de ambas
  /// condiciones únicamente se cumple cuando el rival es una ciega —
  /// exactamente la pareja que ya usaban los defaults fijos de
  /// `cbetDecision` (BTN abre, BB defiende) antes de esta randomización.
  ///
  /// De esas 8 combinaciones posibles (héroe ∈ {utg,hj,co,btn} × rival ∈
  /// {sb,bb}), se excluyen (utg,bb)/(hj,bb)/(btn,bb): `PostflopStrategy`
  /// necesita un rango real con el que describir la mano del rival para
  /// calcular equity, y `OpeningRanges.forPosition(bb)` está vacío por
  /// definición (la BB nunca "abre") — sin una tabla de
  /// `PreflopRangeBook` específica para ese par (solo existe para
  /// `(bb,co)`), no hay ningún rango no vacío que usar sin inventarlo.
  static const List<(Position hero, Position villain)> _aggressorWithPositionPairs = [
    (Position.utg, Position.sb),
    (Position.hj, Position.sb),
    (Position.co, Position.sb),
    (Position.co, Position.bb),
    (Position.btn, Position.sb),
  ];

  static (Position hero, Position villain) aggressorWithPositionPositions(Deck deck) =>
      deck.pick(_aggressorWithPositionPairs);

  /// Pares (agresor, héroe) válidos para `facingCbet`: el agresor tiene
  /// que actuar antes que el héroe TANTO preflop (para poder abrir antes
  /// de que el héroe pague) COMO en cada calle postflop (para que la
  /// apuesta real que encara el héroe tenga sentido con el héroe
  /// respondiendo con posición, no al revés). Misma verificación manual
  /// que [_aggressorWithPositionPairs], condición opuesta.
  static const List<(Position aggressor, Position hero)> _facingCbetPairs = [
    (Position.utg, Position.hj),
    (Position.utg, Position.co),
    (Position.utg, Position.btn),
    (Position.hj, Position.co),
    (Position.hj, Position.btn),
    (Position.co, Position.btn),
    (Position.sb, Position.bb),
  ];

  static (Position aggressor, Position hero) facingCbetPositions(Deck deck) =>
      deck.pick(_facingCbetPairs);

  /// Stack efectivo (BB) para las familias de profundidad normal —
  /// variado dentro de una banda realista de cash 6-max, nunca fijo en
  /// 100bb.
  static double normalStackBb(Deck deck) => deck.intInRange(40, 150).toDouble();

  /// Stack corto para `shortStackFacingOpen` — variado dentro de la
  /// banda donde el juego relevante es empuje-o-fold (bajo el umbral de
  /// 20bb que ya usa `PreflopStrategy`/`ShortStackStrategy`).
  static double shortStackBb(Deck deck) => deck.intInRange(6, 18).toDouble();

  /// Fracción de bote para una apuesta guionada (el c-bet que enfrenta el
  /// héroe en `facingCbet`, o los barriles mecánicos de flop/turn en
  /// `turnBarrel`/`riverBarrel`) — variado en vez de fijo en un único
  /// tamaño, dentro de una banda de sizing real (un tercio a bote lleno).
  static double betPotFraction(Deck deck) =>
      deck.pick(const [0.33, 0.5, 0.66, 0.75, 1.0]);
}
