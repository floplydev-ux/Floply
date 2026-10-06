import '../../engine/pedagogy/table_lesson.dart';
import '../../engine/poker/game/game_state.dart';
import '../../engine/poker/poker_action.dart';

/// Traduce el [GameState] real de [HandTableController] a un
/// [TableSnapshot] para [PokerTableView] — mismo patrón que
/// `ExerciseScenarioAdapter._toTableSnapshot`/`_toSeatState` (Laboratorio),
/// nunca una segunda mesa: es la misma [PokerTableView] de siempre, solo
/// alimentada por una mano jugable completa en vez de por un único
/// ejercicio.
///
/// **Revela cartas de los bots** solo si [revealAll] es `true` — el
/// showdown real de la mano (`HandTableController.isHandOver` con la
/// mano resuelta por comparación de manos, no por fold-out): mientras la
/// mano sigue en juego, cada rival se ve boca abajo, igual que en una
/// mesa real.
///
/// **Deal animation**: durante la fase de reparto, [dealProgress] controla
/// cuántos asientos (0..5, en orden de slot) ya tienen cartas visibles.
/// Los bots aparecen boca abajo (`['?', '?']`); el héroe, boca arriba.
/// Una vez que [dealProgress] llega a 6 (todos repartidos) los bots
/// siguen mostrando sus dorsos mientras la mano está en juego.
class CoachTableSnapshot {
  const CoachTableSnapshot._();

  static TableSnapshot from(
    GameState state, {
    required int heroSlot,
    required bool revealAll,
    Set<int> winnerSlots = const {},
    int dealProgress = 6,
  }) {
    return TableSnapshot(
      seats: [
        for (var slot = 0; slot < GameState.seatCount; slot++)
          _seatFor(state, slot,
              heroSlot: heroSlot,
              revealAll: revealAll,
              isWinner: winnerSlots.contains(slot),
              dealProgress: dealProgress)
      ],
      board: [for (final c in state.board) c.code],
      potBb: state.pot.totalBb,
      buttonSlot: state.buttonSlot,
    );
  }

  static SeatState _seatFor(
    GameState state,
    int slot, {
    required int heroSlot,
    required bool revealAll,
    required bool isWinner,
    required int dealProgress,
  }) {
    final player = state.seatAt(slot);
    final isHero = slot == heroSlot;
    final hand = player.holeCards;

    // Un asiento está "repartido" si slot < dealProgress (animación de
    // deal secuencial de izquierda a derecha por número de slot).
    final isDealt = slot < dealProgress;

    // Cartas visibles: hero siempre boca arriba (si repartido), rival
    // activo boca arriba en showdown, rival activo boca abajo durante
    // el juego (una vez repartido), rival foldado = sin cartas.
    final showFaceUp = hand != null &&
        isDealt &&
        (isHero || (revealAll && player.isActive));
    final showFaceDown = hand != null &&
        isDealt &&
        !isHero &&
        !revealAll &&
        !player.folded;

    final cards = showFaceUp
        ? [hand.high.code, hand.low.code]
        : showFaceDown
            ? const ['?', '?']
            : const <String>[];

    return SeatState(
      slot: slot,
      label: state.positionOf(slot).label,
      isHero: isHero,
      cards: cards,
      betBb: player.investedThisStreetBb,
      stackBb: player.stackBb,
      action: _lastActionLabel(state, slot),
      folded: player.folded,
      toAct: state.toActSlot == slot,
      winner: isWinner,
    );
  }

  /// Misma lógica que `ExerciseScenarioAdapter._lastActionLabel`: no hay
  /// "última acción" guardada por asiento, se deriva de `round.log`.
  static String? _lastActionLabel(GameState state, int slot) {
    final entries = state.round.log.where((e) => e.slot == slot);
    if (entries.isEmpty) {
      return state.seatAt(slot).investedThisStreetBb > 0 ? 'POST' : null;
    }
    return switch (entries.last.action.type) {
      ActionType.fold => 'FOLD',
      ActionType.check => 'CHECK',
      ActionType.call => 'CALL',
      ActionType.bet => 'BET',
      ActionType.raise => 'RAISE',
      ActionType.allIn => 'ALL-IN',
      ActionType.limp => 'CALL',
    };
  }
}
