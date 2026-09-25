import '../poker/game/game_state.dart';
import '../poker/street.dart';
import '../strategy/strategy.dart';
import 'postflop_strategy.dart';
import 'preflop_strategy.dart';

/// Único punto de despacho entre `PreflopStrategy` y `PostflopStrategy`
/// según la calle de [state] — para que `AnswerEvaluator`/
/// `ExerciseScenarioAdapter` nunca tengan que repetir el mismo `if` dos
/// veces ni acoplarse a cuál de las dos clases corresponde. Ninguna
/// lógica de estrategia propia acá, solo el switch.
class ScenarioStrategy {
  const ScenarioStrategy._();

  static Strategy forDecision(GameState state, int heroSlot) =>
      state.street == Street.preflop
          ? PreflopStrategy.forDecision(state, heroSlot)
          : PostflopStrategy.forDecision(state, heroSlot);
}
