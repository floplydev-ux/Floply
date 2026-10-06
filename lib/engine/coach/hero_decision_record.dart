import '../poker/game/game_state.dart';
import '../poker/poker_action.dart';
import '../poker/street.dart';

/// Una decisión real del héroe en la Mesa con Coach, tal como ocurrió —
/// nada inventado ni recalculado más tarde. [HandTableController] guarda
/// una de estas por cada acción del héroe (nunca de los bots) durante la
/// mano en curso, y las descarta al empezar la siguiente
/// ([HandTableController.startNewHand]).
///
/// Es la base de datos que usa [CoachAnalyzer] para el análisis de
/// **fin de mano** (sección 2 del pedido de evolución): como ya no hay
/// comentario en vivo después de cada decisión, el Coach necesita poder
/// reconstruir, una vez que la mano terminó, qué pasó en cada paso.
class HeroDecisionRecord {
  const HeroDecisionRecord({
    required this.before,
    required this.action,
    required this.after,
    required this.street,
  });

  /// El estado justo antes de aplicar [action] — de acá sale todo lo que
  /// hacía falta saber en ese momento (posición, mano, pot odds, board).
  final GameState before;

  /// La acción real que tomó el héroe.
  final PokerAction action;

  /// El estado ya resuelto — se usa solo para el bote resultante.
  final GameState after;

  /// La calle en la que ocurrió esta decisión (siempre `before.street`,
  /// guardada aparte para no tener que releerla de [before] en cada uso).
  final Street street;
}
