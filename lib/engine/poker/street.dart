/// Las cuatro calles de una mano de Hold'em y cuántas cartas comunitarias
/// hay en cada una.
enum Street {
  preflop('Preflop', 0),
  flop('Flop', 3),
  turn('Turn', 4),
  river('River', 5);

  const Street(this.label, this.boardCards);

  final String label;

  /// Número de cartas comunitarias visibles en esta calle.
  final int boardCards;
}
