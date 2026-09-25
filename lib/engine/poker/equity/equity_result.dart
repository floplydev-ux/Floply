/// El resultado de enumerar todos los runouts posibles entre dos manos (o
/// una mano y un rango) en un board dado: cuántos terminan ganando,
/// empatando o perdiendo para el primer jugador (`hero` en
/// `EquityEngine`).
///
/// `total` es siempre `wins + ties + losses` — no es un campo aparte que
/// alguien podría dejar desincronizado, es un getter derivado, así que la
/// invariante `wins + ties + losses == total` nunca puede romperse.
class EquityResult {
  const EquityResult({
    required this.wins,
    required this.ties,
    required this.losses,
  })  : assert(wins >= 0, 'wins no puede ser negativo'),
        assert(ties >= 0, 'ties no puede ser negativo'),
        assert(losses >= 0, 'losses no puede ser negativo');

  /// Resultado neutro para acumular (`handVsRange` arranca acá y va
  /// sumando un [EquityResult] por combo rival).
  static const EquityResult zero = EquityResult(wins: 0, ties: 0, losses: 0);

  final int wins;
  final int ties;
  final int losses;

  int get total => wins + ties + losses;

  /// `0.0` si `total == 0` (ningún runout válido) en vez de `NaN` — un
  /// engine matemático no debería poder devolver `NaN` por una división
  /// por cero silenciosa.
  double get winProbability => total == 0 ? 0.0 : wins / total;
  double get tieProbability => total == 0 ? 0.0 : ties / total;
  double get lossProbability => total == 0 ? 0.0 : losses / total;

  /// Equity heads-up: el empate reparte el bote a la mitad.
  double get equity => winProbability + tieProbability / 2;

  EquityResult operator +(EquityResult other) => EquityResult(
        wins: wins + other.wins,
        ties: ties + other.ties,
        losses: losses + other.losses,
      );

  @override
  String toString() =>
      'EquityResult(wins: $wins, ties: $ties, losses: $losses, '
      'total: $total, equity: ${(equity * 100).toStringAsFixed(2)}%)';
}
