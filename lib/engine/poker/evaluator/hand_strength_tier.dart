import '../card.dart';
import '../hand_category.dart';
import '../hole_cards.dart';
import 'hand_evaluator.dart';

/// Qué tan fuerte es una mano postflop, en 4 bandas — la clasificación
/// rápida que usan tanto [PostflopBotPolicy] (decisiones de los bots en
/// vivo, en cada calle de cada mano) como `CoachAnalyzer` (comentario del
/// mentor). Deliberadamente NO usa `EquityEngine` (equity real contra un
/// rango): ese cálculo, exacto por enumeración, puede tardar más de un
/// segundo con un rango ancho en el flop (ver el hallazgo de rendimiento
/// del Laboratorio, `postflop_strategy.dart`) — en la Mesa con Coach hay
/// hasta 5 bots decidiendo en cada una de 3 calles postflop, mano tras
/// mano: correr una enumeración exacta ahí sería, en la práctica,
/// inutilizable. En cambio, [classify] usa [HandEvaluator.best] (una
/// sola evaluación de 5 cartas entre como máximo 21 combinaciones,
/// microsegundos) más una detección simple y real de proyectos —
/// rápido, siempre exacto sobre la mano concreta, nunca inventado.
enum HandStrengthTier {
  /// Ni pareja ni proyecto relevante.
  air,

  /// Pareja por debajo de la carta más alta del board (no top pair), o
  /// un proyecto (color o escalera) sin nada hecho todavía.
  weakOrDrawing,

  /// Top pair (pareja con la carta más alta del board) o superior sin
  /// llegar a dos parejas.
  decent,

  /// Dos parejas o mejor.
  strong;

  bool get isAtLeastDecent => index >= HandStrengthTier.decent.index;
}

/// El resultado completo de clasificar una mano contra un board — la
/// categoría real (para texto de mentor: "tenés un par", "tenés color")
/// más los flags de proyecto, y la banda resumen ([tier]) que usan las
/// decisiones automáticas.
class HandStrengthReading {
  const HandStrengthReading({
    required this.category,
    required this.topPair,
    required this.flushDraw,
    required this.straightDraw,
    required this.tier,
  });

  final HandCategory category;

  /// La pareja hecha es con la carta más alta del board (no un par de
  /// bolsillo por debajo, ni una pareja con una carta baja del board).
  final bool topPair;

  final bool flushDraw;

  /// Proyecto de escalera, abierto o por un solo lado (gutshot) — esta
  /// clasificación no distingue entre ambos, ver el doc-comment de
  /// [HandStrengthTier].
  final bool straightDraw;

  final HandStrengthTier tier;

  bool get hasAnyDraw => flushDraw || straightDraw;
}

class HandStrengthClassifier {
  const HandStrengthClassifier._();

  /// Clasifica [hand] contra [board] — [board] tiene que tener 3, 4 o 5
  /// cartas (flop/turn/río, mismo requisito que [HandEvaluator.best]).
  static HandStrengthReading classify(HoleCards hand, List<Card> board) {
    final best = HandEvaluator.best(hand, board);
    final topBoardRank =
        board.map((c) => c.rank).reduce((a, b) => a.value > b.value ? a : b);
    final topPair = best.category == HandCategory.pair &&
        best.tiebreakers.isNotEmpty &&
        best.tiebreakers.first == topBoardRank;
    final flushDraw = _hasFlushDraw(hand, board);
    final straightDraw = _hasStraightDraw(hand, board);

    final HandStrengthTier tier;
    if (best.category.strength >= HandCategory.twoPair.strength) {
      tier = HandStrengthTier.strong;
    } else if (best.category == HandCategory.pair && topPair) {
      tier = HandStrengthTier.decent;
    } else if (best.category == HandCategory.pair ||
        flushDraw ||
        straightDraw) {
      tier = HandStrengthTier.weakOrDrawing;
    } else {
      tier = HandStrengthTier.air;
    }

    return HandStrengthReading(
      category: best.category,
      topPair: topPair,
      flushDraw: flushDraw,
      straightDraw: straightDraw,
      tier: tier,
    );
  }

  /// `true` si [hand] tiene 4 cartas de un mismo palo entre sus 2 cartas
  /// y [board] (proyecto de color) sin llegar a las 5 (que ya sería
  /// color hecho, cubierto por `best.category` en vez de esto).
  static bool _hasFlushDraw(HoleCards hand, List<Card> board) {
    final all = [...hand.cards, ...board];
    final bySuit = <Suit, int>{};
    for (final c in all) {
      bySuit[c.suit] = (bySuit[c.suit] ?? 0) + 1;
    }
    final heroSuits = hand.cards.map((c) => c.suit).toSet();
    return bySuit.entries.any((e) => heroSuits.contains(e.key) && e.value == 4);
  }

  /// `true` si existe algún rango que, de aparecer, completaría una
  /// escalera de 5 valores consecutivos usando al menos una carta de
  /// [hand] — cubre proyectos abiertos y por un lado (gutshot) por
  /// igual, sin distinguirlos (ver el doc-comment de [HandStrengthTier]).
  /// Contempla el As jugando bajo (rueda, A-2-3-4-5).
  static bool _hasStraightDraw(HoleCards hand, List<Card> board) {
    final knownValues = {
      for (final c in [...hand.cards, ...board]) c.rank.value,
    };
    final heroValues = {for (final c in hand.cards) c.rank.value};
    if (knownValues.contains(14)) {
      knownValues.add(1);
      if (heroValues.contains(14)) heroValues.add(1);
    }

    for (var missing = 1; missing <= 14; missing++) {
      if (knownValues.contains(missing)) continue;
      final withMissing = {...knownValues, missing};
      for (var start = missing - 4; start <= missing; start++) {
        if (start < 1) continue;
        final window = [for (var v = start; v < start + 5; v++) v];
        if (!window.every(withMissing.contains)) continue;
        final heroContributes =
            window.any((v) => v != missing && heroValues.contains(v));
        if (heroContributes) return true;
      }
    }
    return false;
  }
}
