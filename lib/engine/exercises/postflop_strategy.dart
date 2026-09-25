import '../concepts/concept_ids.dart';
import '../poker/card.dart';
import '../poker/game/game_state.dart';
import '../poker/poker_action.dart';
import '../poker/street.dart';
import '../strategy/strategy.dart';

/// La estrategia "ground truth" para decisiones POSTFLOP — hermana de
/// `PreflopStrategy` (`preflop_strategy.dart`), nunca la reemplaza ni la
/// extiende: preflop (169 clases de mano, tabla fija) y postflop (board
/// concreto, texturas casi infinitas) son problemas de autoría
/// distintos, así que viven en clases separadas desde el arranque en
/// vez de forzar el nombre "preflop" a cubrir algo que no es. Ver
/// `LABORATORIO_POSTFLOP_AUDITORIA_DISENO.md` para la justificación
/// completa de diseño.
///
/// **Alcance de esta pasada — una única familia real**: solo la
/// decisión de c-apostar o no en el flop, siendo el agresor preflop,
/// antes de cualquier apuesta de esta calle, en un board que favorece
/// al agresor ([boardFavorsAggressor]). Cualquier otra situación
/// postflop lanza [UnsupportedError] — mismo criterio de honestidad que
/// ya usa `OpponentPolicy` (que decide no fingir cubrir postflop en vez
/// de inventar una regla sin fundamento): esta clase es honesta sobre
/// cubrir solo esta única situación, no "postflop en general".
class PostflopStrategy {
  const PostflopStrategy._();

  /// La estrategia para la decisión del jugador en turno ([heroSlot]) en
  /// [state]. Lanza [UnsupportedError] si [state] no es exactamente la
  /// única situación que esta pasada cubre (ver el doc-comment de la
  /// clase) — nunca degrada a una heurística genérica sin fundamento.
  static Strategy forDecision(GameState state, int heroSlot) {
    if (state.street != Street.flop) {
      throw UnsupportedError(
          'PostflopStrategy: todavía solo cubre decisiones en el flop '
          '(street actual: ${state.street}).');
    }
    if (state.streetHistory.isEmpty ||
        state.streetHistory.last.lastAggressorSlot != heroSlot) {
      throw UnsupportedError(
          'PostflopStrategy: todavía solo cubre al agresor preflop '
          'decidiendo si c-apuesta — el slot $heroSlot no fue el '
          'agresor preflop de esta mano.');
    }
    // Exactamente una entrada (el check del rival) — nunca una apuesta
    // real: eso ya sería una decisión distinta ("¿pagás/subís un
    // c-bet?"), fuera de lo que esta pasada cubre.
    final log = state.round.log;
    if (log.length != 1 || log.single.action.type != ActionType.check) {
      throw UnsupportedError(
          'PostflopStrategy: todavía solo cubre la decisión de c-bet tras '
          'un check del rival, antes de cualquier apuesta en esta calle.');
    }
    if (!boardFavorsAggressor(state.board)) {
      throw UnsupportedError(
          'PostflopStrategy: todavía solo cubre boards que favorecen al '
          'agresor preflop (ver boardFavorsAggressor) — este board no '
          'califica.');
    }

    return Strategy([
      // Sin `sizeBb`: la lección de esta familia es "hay que c-apostar",
      // no "con qué tamaño exacto" — cualquier tamaño de apuesta que
      // ofrezca la UI (ver `ExerciseScenarioAdapter._recommendedSizes`)
      // tiene que calificar igual de bien (`PokerAction.matches` trata
      // `sizeBb: null` como "cualquier tamaño sirve").
      const StrategyOption(
        action: PokerAction(ActionType.bet),
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: [ConceptIds.cbet, ConceptIds.boardTexture],
      ),
      const StrategyOption(
        action: PokerAction(ActionType.check),
        frequency: 0.0,
        rating: StrategicRating.dubious,
        justifyingConcepts: [ConceptIds.cbet, ConceptIds.boardTexture],
      ),
    ]);
  }

  /// Heurística deliberadamente simple y citable de cuándo un flop
  /// favorece lo bastante al rango del agresor preflop como para
  /// justificar una c-bet de rango completo — el ejemplo más repetido
  /// en teoría de póker introductoria: un flop sin pares, sin proyecto
  /// de color (rainbow) y con la carta más alta As o Rey (p. ej.
  /// K♠7♦2♣). No es una clasificación general de texturas de board —
  /// boards conectados, con proyecto, o sin carta alta quedan fuera de
  /// lo que esta pasada sabe evaluar a propósito, no por descuido. Ver
  /// `LABORATORIO_POSTFLOP_AUDITORIA_DISENO.md` §3/§10 para el alcance
  /// deliberado y sus límites.
  static bool boardFavorsAggressor(List<Card> board) {
    if (board.length != 3) return false;
    final ranks = board.map((c) => c.rank).toSet();
    final suits = board.map((c) => c.suit).toSet();
    final isUnpaired = ranks.length == board.length;
    final isRainbow = suits.length == board.length;
    final hasHighCard = board.any((c) => c.rank == Rank.ace || c.rank == Rank.king);
    return isUnpaired && isRainbow && hasHighCard;
  }
}
