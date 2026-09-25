import '../poker/game/action_resolver.dart';
import '../poker/game/game_state.dart';
import '../poker/game/legal_action_engine.dart';
import '../poker/poker_action.dart';
import 'exercise_scenario.dart';

/// Envuelve el turno del héroe de un [ExerciseScenario]: expone qué
/// puede hacer y ejecuta lo que decide, siempre a través del motor real
/// — nunca decide por su cuenta si una acción es legal ni muta
/// stack/pot/currentBet a mano.
///
/// Vive en `lib/engine/` (dominio puro, sin Flutter) — la reactividad de
/// UI (`notifyListeners`) es responsabilidad de quien lo use desde
/// `lib/screens/`, igual que el resto de esta capa.
class StudentTurnController {
  StudentTurnController(this.scenario) : _state = scenario.initialState;

  final ExerciseScenario scenario;
  GameState _state;

  /// El estado actual — arranca en `scenario.initialState` y cambia
  /// solamente a través de [applyHeroAction].
  GameState get state => _state;

  int get heroSlot => scenario.heroSlot;

  /// Nunca reinventadas: siempre las mismas que devolvería
  /// `LegalActionEngine.legalActionTypes(state)` en este momento.
  Set<ActionType> get legalActions => LegalActionEngine.legalActionTypes(_state);

  /// `null` si `raise`/`bet` no es legal ahora mismo.
  double? get minRaiseToBb =>
      (legalActions.contains(ActionType.raise) || legalActions.contains(ActionType.bet))
          ? LegalActionEngine.minRaiseToBb(_state)
          : null;

  double? get maxRaiseToBb =>
      legalActions.isEmpty ? null : LegalActionEngine.maxRaiseToBb(_state);

  /// Aplica la acción del héroe vía [ActionResolver] — la única fuente
  /// de verdad de ejecución. Lanza [IllegalActionException] (sin
  /// reinterpretarla) si no es legal en este estado; como
  /// `ActionResolver.apply` es puro (construye un estado nuevo o lanza,
  /// nunca muta a medias), [state] queda exactamente como estaba si
  /// lanza.
  GameState applyHeroAction(PokerAction action) {
    if (_state.toActSlot != heroSlot) {
      throw StateError(
          'StudentTurnController: no es el turno del héroe (slot $heroSlot; '
          'le toca a ${_state.toActSlot}).');
    }
    _state = ActionResolver.apply(_state, action);
    return _state;
  }
}
