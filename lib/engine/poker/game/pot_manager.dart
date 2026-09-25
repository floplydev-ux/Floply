/// Un bote (principal o lateral) y quiénes pueden ganarlo.
class Pot {
  Pot({required this.amountBb, required Set<int> eligibleSlots})
      : eligibleSlots = Set.unmodifiable(eligibleSlots) {
    if (amountBb < 0) {
      throw ArgumentError.value(
          amountBb, 'amountBb', 'el bote no puede ser negativo');
    }
  }

  final double amountBb;

  /// Slots que siguen en juego por este bote (no foldeados). Un jugador
  /// all-in por menos queda fuera de los botes laterales que se arman por
  /// encima de su aporte.
  final Set<int> eligibleSlots;

  Pot copyWith({double? amountBb, Set<int>? eligibleSlots}) => Pot(
        amountBb: amountBb ?? this.amountBb,
        eligibleSlots: eligibleSlots ?? this.eligibleSlots,
      );

  @override
  String toString() => 'Pot($amountBb bb, eligible: $eligibleSlots)';
}

/// Administra el o los botes de una mano.
///
/// **Alcance de esta pasada: solo bote principal.** [fromInvestments]
/// siempre arma un único [Pot] con todo lo invertido, elegible para todos
/// los jugadores que no foldearon — no separa botes laterales todavía. La
/// forma de [Pot] (con `eligibleSlots`) ya queda lista para eso: cuando se
/// implementen side pots reales, esta API pública no debería cambiar.
class PotManager {
  PotManager(List<Pot> pots) : pots = List.unmodifiable(pots);

  final List<Pot> pots;

  double get totalBb => pots.fold(0, (sum, p) => sum + p.amountBb);

  /// Arma el bote a partir de lo que cada jugador lleva invertido en la
  /// mano (`investedTotalBb`) y quiénes siguen activos (no foldeados).
  factory PotManager.fromInvestments(Map<int, double> investedTotalBb,
      {required Set<int> activeSlots}) {
    final total = investedTotalBb.values.fold(0.0, (sum, v) => sum + v);
    return PotManager([Pot(amountBb: total, eligibleSlots: activeSlots)]);
  }

  PotManager copyWith({List<Pot>? pots}) => PotManager(pots ?? this.pots);

  @override
  String toString() => 'PotManager($pots)';
}
