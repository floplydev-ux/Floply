import '../poker/card.dart';
import '../poker/hole_cards.dart';
import '../poker/poker_action.dart';
import '../poker/position.dart';
import '../poker/street.dart';

/// Una situación concreta de póker: la "foto" sobre la que el usuario
/// tiene que decidir. Es el output del generador y el input del motor
/// estratégico y del evaluador.
class PokerSituation {
  PokerSituation({
    required this.heroPosition,
    required this.heroCards,
    required this.street,
    required this.effectiveStackBb,
    this.board = const [],
    this.actionHistory = const [],
    this.potBb = 1.5,
    this.toCallBb = 0.0,
    List<PokerAction>? availableActions,
    List<double>? availableRaiseSizes,
    this.maxPlayers = 6,
  })  : availableActions = availableActions ?? const [],
        availableRaiseSizes = availableRaiseSizes ?? const [];

  final Position heroPosition;
  final HoleCards heroCards;
  final Street street;
  final double effectiveStackBb;

  /// Cartas comunitarias (vacío en preflop).
  final List<Card> board;

  /// Acciones previas a la decisión del héroe, en orden.
  final List<PriorAction> actionHistory;

  final double potBb;
  final double toCallBb;

  /// Acciones que el ejercicio ofrece como opciones (si aplica).
  final List<PokerAction> availableActions;

  /// Tamaños de subida ofrecidos (para ejercicios de sizing).
  final List<double> availableRaiseSizes;

  final int maxPlayers;

  /// `true` si nadie puso fichas voluntariamente todavía: todos foldearon
  /// hasta el héroe (situación de "open raise first in").
  bool get isFirstIn =>
      street == Street.preflop &&
      actionHistory.every((a) => a.action.type == ActionType.fold);

  /// Todas las cartas conocidas (héroe + board): sirve para validar que
  /// no haya duplicados.
  List<Card> get knownCards => [...heroCards.cards, ...board];

  /// Descripción textual del historial previo, para el enunciado.
  String get actionHistoryDescription {
    if (actionHistory.isEmpty) return 'Sos el primero en actuar.';
    if (isFirstIn) {
      final n = actionHistory.length;
      return n == 1
          ? '${actionHistory.first.position.abbreviation} foldea.'
          : 'Todos foldean hasta vos ($n jugadores).';
    }
    return actionHistory.map((a) => a.toString()).join(', ');
  }

  PokerSituation copyWith({
    List<PokerAction>? availableActions,
    List<double>? availableRaiseSizes,
  }) {
    return PokerSituation(
      heroPosition: heroPosition,
      heroCards: heroCards,
      street: street,
      effectiveStackBb: effectiveStackBb,
      board: board,
      actionHistory: actionHistory,
      potBb: potBb,
      toCallBb: toCallBb,
      availableActions: availableActions ?? this.availableActions,
      availableRaiseSizes: availableRaiseSizes ?? this.availableRaiseSizes,
      maxPlayers: maxPlayers,
    );
  }

  @override
  String toString() =>
      '${heroPosition.abbreviation} ${heroCards.notation} '
      '(${effectiveStackBb.toStringAsFixed(0)}bb, ${street.label})';
}
