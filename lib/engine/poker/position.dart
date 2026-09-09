/// Posiciones en una mesa 6-max de No-Limit Hold'em.
///
/// El orden del enum es el orden de acción *preflop* (UTG actúa primero,
/// BB último). Ese orden se usa para reconstruir el historial de folds
/// previos a la decisión del héroe.
enum Position {
  utg('UTG', 'Under the Gun'),
  hj('HJ', 'Hijack'),
  co('CO', 'Cutoff'),
  btn('BTN', 'Button'),
  sb('SB', 'Small Blind'),
  bb('BB', 'Big Blind');

  const Position(this.abbreviation, this.fullName);

  final String abbreviation;
  final String fullName;

  bool get isBlind => this == Position.sb || this == Position.bb;

  /// Si esta posición actúa después del flop con posición (última en
  /// hablar postflop es BTN; las ciegas son las primeras).
  bool get hasPostflopPosition => this == Position.btn;

  /// Orden de apertura ("open raise first-in"): posiciones que pueden ser
  /// las primeras en entrar al bote. BB nunca abre (si todos foldean,
  /// gana el bote sin jugar).
  static List<Position> get openers =>
      const [Position.utg, Position.hj, Position.co, Position.btn, Position.sb];

  /// Las posiciones que actúan antes que [this] en el preflop.
  List<Position> get earlierPositions =>
      Position.values.where((p) => p.index < index).toList(growable: false);

  /// Cuántos jugadores actúan antes (número de folds cuando el héroe abre
  /// primero).
  int get playersBefore => index;

  /// `true` si [this] abre un rango más amplio que [other] en una
  /// estrategia RFI estándar (más tardío = más amplio, salvo la BB).
  bool opensWiderThan(Position other) => _openWidthRank > other._openWidthRank;

  /// Ranking relativo de amplitud del rango de apertura (mayor = más
  /// manos). La SB abre más ancho que CO pero menos que BTN.
  int get _openWidthRank {
    switch (this) {
      case Position.utg:
        return 0;
      case Position.hj:
        return 1;
      case Position.co:
        return 2;
      case Position.sb:
        return 3;
      case Position.btn:
        return 4;
      case Position.bb:
        return -1;
    }
  }
}
