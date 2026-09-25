import '../hole_cards.dart';

/// El estado de un jugador en un asiento durante una mano en curso.
///
/// No guarda su [Position] — se deriva del `slot` vía
/// `TablePositions(buttonSlot).positionOf(slot)` (ver [GameState.positionOf])
/// para no duplicar esa fuente de verdad.
class PlayerState {
  PlayerState({
    required this.slot,
    this.holeCards,
    required this.stackBb,
    this.investedThisStreetBb = 0,
    this.investedTotalBb = 0,
    this.folded = false,
    this.isAllIn = false,
    this.sittingOut = false,
  }) {
    // Chequeos reales, no `assert` — un stack o una inversión negativa acá
    // significaría plata que se creó o se destruyó sola, y tiene que
    // fallar también en release, no solo en debug.
    if (stackBb < 0) {
      throw ArgumentError.value(
          stackBb, 'stackBb', 'el stack no puede ser negativo (slot $slot)');
    }
    if (investedThisStreetBb < 0) {
      throw ArgumentError.value(investedThisStreetBb, 'investedThisStreetBb',
          'no puede ser negativo (slot $slot)');
    }
    if (investedTotalBb < 0) {
      throw ArgumentError.value(investedTotalBb, 'investedTotalBb',
          'no puede ser negativo (slot $slot)');
    }
    if (investedThisStreetBb > investedTotalBb) {
      throw ArgumentError(
          'slot $slot: investedThisStreetBb ($investedThisStreetBb) no '
          'puede superar investedTotalBb ($investedTotalBb)');
    }
  }

  /// Asiento (0..5), estable durante toda la mano.
  final int slot;

  /// `null` si el asiento está vacío o sus cartas no se conocen (rival en
  /// un ejercicio donde el héroe no ve sus cartas).
  final HoleCards? holeCards;

  final double stackBb;
  final double investedThisStreetBb;
  final double investedTotalBb;
  final bool folded;
  final bool isAllIn;

  /// Asiento vacío / jugador que no participa de esta mano.
  final bool sittingOut;

  /// Puede seguir actuando en la mano (no foldeado, no all-in, no afuera).
  bool get canAct => !folded && !isAllIn && !sittingOut;

  /// Sigue en juego por el bote (no foldeado, no afuera) aunque ya no
  /// pueda volver a actuar por estar all-in.
  bool get isActive => !folded && !sittingOut;

  PlayerState copyWith({
    HoleCards? holeCards,
    bool clearHoleCards = false,
    double? stackBb,
    double? investedThisStreetBb,
    double? investedTotalBb,
    bool? folded,
    bool? isAllIn,
    bool? sittingOut,
  }) =>
      PlayerState(
        slot: slot,
        holeCards: clearHoleCards ? null : (holeCards ?? this.holeCards),
        stackBb: stackBb ?? this.stackBb,
        investedThisStreetBb: investedThisStreetBb ?? this.investedThisStreetBb,
        investedTotalBb: investedTotalBb ?? this.investedTotalBb,
        folded: folded ?? this.folded,
        isAllIn: isAllIn ?? this.isAllIn,
        sittingOut: sittingOut ?? this.sittingOut,
      );

  @override
  String toString() =>
      'PlayerState(slot: $slot, stack: $stackBb, invested: $investedTotalBb, '
      'folded: $folded, allIn: $isAllIn)';
}
