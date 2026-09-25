import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/game_state.dart';
import 'package:poker_trainer/engine/poker/game/opponent_policy.dart';
import 'package:poker_trainer/engine/poker/game/scenario_builder.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';

/// El rival simulado (`OpponentPolicy`) tiene que decidir exactamente lo
/// mismo que el evaluador del alumno para la misma situación — ver el
/// doc-comment de `OpponentPolicy._decideFromRangeBook` y la memoria del
/// proyecto `laboratorio-motor-preflop`. Estos tests arman el `GameState`
/// a mano (CO abre, BB — jugada por `OpponentPolicy` — decide) para
/// probar la consulta a `PreflopRangeBook` directamente, sin pasar por
/// `ExerciseScenarioBuilder` (que nunca pone a `OpponentPolicy` a decidir
/// por el lado de la defensa, solo por el lado del agresor).
void main() {
  GameState bbFacingCoOpen(HoleCards bbHand) {
    const buttonSlot = 0;
    final positions = TablePositions(buttonSlot);
    final coSlot = positions.slotOf(Position.co);
    final bbSlot = positions.slotOf(Position.bb);

    var state = ScenarioBuilder.freshHand(
      deck: Deck(Random(7)),
      buttonSlot: buttonSlot,
      stackBb: 100,
      explicitHandBySlot: {coSlot: HoleCards.parse('9h8h'), bbSlot: bbHand},
    );
    while (state.toActSlot != coSlot) {
      state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
    }
    state = ActionResolver.apply(state, PokerAction.raiseTo(2.5));
    while (state.toActSlot != bbSlot) {
      state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
    }
    return state;
  }

  group('OpponentPolicy.decide (perfil balanced) consulta PreflopRangeBook '
      'para BB vs CO', () {
    test('mano de 3-bet de valor (QQ): re-sube', () {
      final state = bbFacingCoOpen(HoleCards.parse('QsQd'));
      final action = OpponentPolicy.decide(state);
      expect(action.type, ActionType.raise);
    });

    test('mano de call estándar (T9s): paga', () {
      final state = bbFacingCoOpen(HoleCards.parse('Ts9s'));
      final action = OpponentPolicy.decide(state);
      expect(action.type, ActionType.call);
    });

    test('mano claramente fuera de rango (72o): foldea', () {
      final state = bbFacingCoOpen(HoleCards.parse('7c2d'));
      final action = OpponentPolicy.decide(state);
      expect(action.type, ActionType.fold);
    });

    test('perfil passive/tag NO consulta PreflopRangeBook (sin tabla '
        'propia) — sigue con el percentil de siempre, puede diferir de '
        'balanced', () {
      // 72o está fuera del rango de cualquier perfil — pero esto prueba
      // que passive/tag no explota consultando una tabla que no tienen,
      // simplemente nunca entra a `_decideFromRangeBook`.
      final state = bbFacingCoOpen(HoleCards.parse('7c2d'));
      expect(
        () => OpponentPolicy.decide(state, profile: OpponentProfile.passive),
        returnsNormally,
      );
      expect(
        () => OpponentPolicy.decide(state, profile: OpponentProfile.tag),
        returnsNormally,
      );
    });
  });
}
