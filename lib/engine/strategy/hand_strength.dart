import '../poker/card.dart';
import '../poker/hole_cards.dart';

/// Puntaje de fuerza preflop de una mano (variante de la fórmula de Chen).
///
/// No es una equity exacta, pero ordena las 169 clases de mano de forma
/// razonable, que es lo que necesita el motor para:
///  * ejercicios de "¿qué mano es mejor?";
///  * decidir si una subida fuera de rango es dudosa o directamente mala.
class HandStrength {
  HandStrength._();

  /// Puntaje de Chen para una clase de mano (`'AKs'`, `'77'`).
  static double chenScore(String notation) {
    final hi = Rank.fromLetter(notation[0]);
    final isPair = notation.length == 2;
    final lo = isPair ? hi : Rank.fromLetter(notation[1]);
    final suited = notation.endsWith('s');

    double base(Rank r) {
      switch (r) {
        case Rank.ace:
          return 10;
        case Rank.king:
          return 8;
        case Rank.queen:
          return 7;
        case Rank.jack:
          return 6;
        default:
          return r.value / 2;
      }
    }

    double score = base(hi);

    if (isPair) {
      score = (score * 2).clamp(5, double.infinity);
      return score;
    }

    if (suited) score += 2;

    final gap = hi.value - lo.value - 1;
    if (gap == 1) {
      score -= 1;
    } else if (gap == 2) {
      score -= 2;
    } else if (gap == 3) {
      score -= 4;
    } else if (gap >= 4) {
      score -= 5;
    }

    // Bonus de escalera: cartas conectadas o con 1 de gap, ambas por
    // debajo de Q.
    if (gap <= 1 && hi.value < Rank.queen.value) {
      score += 1;
    }

    return score;
  }

  static double chenScoreOf(HoleCards hand) => chenScore(hand.notation);

  /// Ranking de percentil (0 = la mejor mano, 1 = la peor) de una clase
  /// dentro de las 169, ponderando por número de combos.
  static double percentile(String notation) {
    _ensureRanking();
    return _percentileByNotation[notation]!;
  }

  static double percentileOf(HoleCards hand) => percentile(hand.notation);

  /// Compara dos clases de mano. Devuelve > 0 si [a] es más fuerte.
  static int compare(String a, String b) =>
      chenScore(a).compareTo(chenScore(b));

  static final Map<String, double> _percentileByNotation = {};

  static void _ensureRanking() {
    if (_percentileByNotation.isNotEmpty) return;
    final classes = HandClass.all();
    classes.sort((a, b) => chenScore(b.notation).compareTo(chenScore(a.notation)));

    var cumulative = 0;
    const totalCombos = 1326;
    for (final hc in classes) {
      cumulative += hc.combos;
      _percentileByNotation[hc.notation] = cumulative / totalCombos;
    }
  }
}
