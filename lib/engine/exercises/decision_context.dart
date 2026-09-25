import '../poker/card.dart';
import '../poker/game/betting_round.dart' show StreetAction;
import '../poker/game/game_state.dart';
import '../poker/game/legal_action_engine.dart';
import '../poker/hole_cards.dart';
import '../poker/poker_action.dart';
import '../poker/position.dart';
import '../poker/street.dart';

/// Describe exactamente qué tiene que decidir el alumno — no calcula
/// estrategia ni juzga la decisión, solo la describe.
///
/// Todo sale de [GameState] y [LegalActionEngine] (la fuente de verdad
/// del motor): nada acá se recalcula a mano ni duplica una regla que ya
/// vive en el Poker Engine.
class DecisionContext {
  const DecisionContext({
    required this.heroSlot,
    required this.heroPosition,
    required this.street,
    required this.heroCards,
    required this.board,
    required this.actionHistory,
    required this.lastActingSlot,
    required this.currentBetBb,
    required this.toCallBb,
    required this.potBb,
    required this.effectiveStackBb,
    required this.legalActions,
    required this.minRaiseToBb,
    required this.maxRaiseToBb,
  });

  final int heroSlot;
  final Position heroPosition;
  final Street street;

  /// Las cartas privadas conocidas del héroe.
  final HoleCards heroCards;

  /// Cartas comunitarias (vacío en preflop).
  final List<Card> board;

  /// Acciones previas de esta calle, en orden — el mismo historial que
  /// ya lleva `GameState.round.log`, no una copia paralela.
  final List<StreetAction> actionHistory;

  /// El slot que generó la última acción previa, si hay alguna.
  final int? lastActingSlot;

  final double currentBetBb;

  /// Cuánto le falta al héroe para igualar (`currentBetBb -
  /// investedThisStreetBb`).
  final double toCallBb;

  final double potBb;

  /// Stack del héroe — **no** el mínimo entre todos los jugadores vivos
  /// (la definición estricta de "stack efectivo"). Simplificación
  /// deliberada: quien de verdad determina qué es legal es
  /// [LegalActionEngine], no este número; acá solo describe la
  /// situación.
  final double effectiveStackBb;

  /// Las acciones legales para el héroe ahora mismo —
  /// `LegalActionEngine.legalActionTypes(state)`, nunca reinventadas.
  final Set<ActionType> legalActions;

  /// `null` si `raise`/`bet` no es una acción legal.
  final double? minRaiseToBb;
  final double? maxRaiseToBb;

  /// Arma el contexto para el jugador en turno. Lanza [StateError] si no
  /// es el turno de [heroSlot] o si su mano no se conoce — un
  /// `DecisionContext` solo tiene sentido para una decisión real.
  factory DecisionContext.fromGameState(GameState state, {required int heroSlot}) {
    if (state.toActSlot != heroSlot) {
      throw StateError(
          'DecisionContext: no es el turno del slot $heroSlot en este '
          'estado (le toca a ${state.toActSlot}).');
    }
    final hero = state.seatAt(heroSlot);
    final hand = hero.holeCards;
    if (hand == null) {
      throw StateError(
          'DecisionContext: el slot $heroSlot no tiene una mano conocida.');
    }

    final legal = LegalActionEngine.legalActionTypes(state);
    final canRaise =
        legal.contains(ActionType.raise) || legal.contains(ActionType.bet);

    return DecisionContext(
      heroSlot: heroSlot,
      heroPosition: state.positionOf(heroSlot),
      street: state.street,
      heroCards: hand,
      board: state.board,
      actionHistory: state.round.log,
      lastActingSlot:
          state.round.log.isEmpty ? null : state.round.log.last.slot,
      currentBetBb: state.round.currentBetBb,
      toCallBb: state.round.currentBetBb - hero.investedThisStreetBb,
      potBb: state.pot.totalBb,
      effectiveStackBb: hero.stackBb,
      legalActions: legal,
      minRaiseToBb: canRaise ? LegalActionEngine.minRaiseToBb(state) : null,
      maxRaiseToBb: legal.isEmpty ? null : LegalActionEngine.maxRaiseToBb(state),
    );
  }
}
