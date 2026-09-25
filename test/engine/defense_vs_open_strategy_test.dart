import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/answer_evaluator.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/preflop_strategy.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/scenario_builder.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/strategy/preflop_authoring.dart';
import 'package:poker_trainer/engine/strategy/strategy.dart';

void main() {
  group('DefenseVsOpenStrategy (vía PreflopStrategy.forDecision) — BB vs CO', () {
    test('mano de valor (QQ): raise óptimo/value, call viable/defend, '
        'fold malo/fold', () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(1)),
        heroHand: HoleCards.parse('QsQd'),
      );
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      final raise = strategy.options.firstWhere((o) => o.action.type == ActionType.raise);
      expect(raise.rating, StrategicRating.optimal);
      expect(raise.role, StrategyRole.value);
      expect(raise.rationaleKey, 'defense_vs_open.raise.value');

      final call = strategy.options.firstWhere((o) => o.action.type == ActionType.call);
      expect(call.rating, StrategicRating.viable);
      expect(call.role, StrategyRole.defend);

      final fold = strategy.options.firstWhere((o) => o.action.type == ActionType.fold);
      expect(fold.rating, StrategicRating.bad);
      expect(fold.role, StrategyRole.fold);
    });

    test('mano de farol (A4s): call óptimo/defend, raise dudoso/bluff '
        'dependiente de contexto, fold malo', () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(1)),
        heroHand: HoleCards.parse('Ah4h'),
      );
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      final call = strategy.options.firstWhere((o) => o.action.type == ActionType.call);
      expect(call.rating, StrategicRating.optimal);
      expect(call.role, StrategyRole.defend);

      final raise = strategy.options.firstWhere((o) => o.action.type == ActionType.raise);
      expect(raise.rating, StrategicRating.dubious);
      expect(raise.role, StrategyRole.bluff);
      expect(raise.contextSensitivity.isDependent, isTrue);
      expect(raise.contextSensitivity.disclosedToStudent, isFalse);

      // Vía AnswerEvaluator: el 3-bet acá da DEPENDS, no ERROR — es
      // defendible según info que el ejercicio no le muestra al alumno.
      final result = AnswerEvaluator.evaluate(scenario, raise.action);
      expect(result.verdict, AnswerVerdict.dependent);
    });

    test('mano de call estándar (T9s): call óptimo/defend, raise y fold '
        'malos', () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(1)),
        heroHand: HoleCards.parse('Ts9s'),
      );
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      final call = strategy.options.firstWhere((o) => o.action.type == ActionType.call);
      expect(call.rating, StrategicRating.optimal);
      expect(call.role, StrategyRole.defend);

      final raise = strategy.options.firstWhere((o) => o.action.type == ActionType.raise);
      expect(raise.rating, StrategicRating.bad);
      // Una subida sin ningún mérito de valor/farol no representa un
      // rol real de la estrategia.
      expect(raise.role, isNull);

      final fold = strategy.options.firstWhere((o) => o.action.type == ActionType.fold);
      expect(fold.rating, StrategicRating.bad);
    });

    test('mano claramente fuera de rango (72o): fold óptimo, call y '
        'raise malos', () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(1)),
        heroHand: HoleCards.parse('7c2d'),
      );
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      final fold = strategy.options.firstWhere((o) => o.action.type == ActionType.fold);
      expect(fold.rating, StrategicRating.optimal);
      expect(fold.role, StrategyRole.fold);

      final call = strategy.options.firstWhere((o) => o.action.type == ActionType.call);
      expect(call.rating, StrategicRating.bad);

      final raise = strategy.options.firstWhere((o) => o.action.type == ActionType.raise);
      expect(raise.rating, StrategicRating.bad);
    });
  });

  group('PreflopStrategy.forDecision — fallback explícito (sin ancla o '
      'stack corto)', () {
    test('facingThreeBet (CO vs BTN, el default) nunca usa '
        'DefenseVsOpenStrategy — encarar un 3-bet es FacingThreeBetStrategy, '
        'una situación distinta', () {
      final scenario = ExerciseScenarioBuilder.facingThreeBet(deck: Deck(Random(1)));
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      for (final option in strategy.options) {
        expect(option.rationaleKey, isNot(startsWith('defense_vs_open.')));
      }
    });

    test('facingThreeBet sin ancla real (HJ vs BTN) cae al fallback viejo '
        '— ni DefenseVsOpenStrategy ni FacingThreeBetStrategy', () {
      final scenario = ExerciseScenarioBuilder.facingThreeBet(
        deck: Deck(Random(1)),
        heroPosition: Position.hj,
        threeBettorPosition: Position.btn,
      );
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      for (final option in strategy.options) {
        expect(option.rationaleKey, isNot(startsWith('defense_vs_open.')));
        expect(option.rationaleKey, isNot(startsWith('facing_three_bet.')));
      }
    });

    test('shortStackFacingOpen (BB vs CO, mismo par que la ancla real de '
        '100bb, pero a 8bb) usa ShortStackStrategy, nunca '
        'DefenseVsOpenStrategy', () {
      final scenario =
          ExerciseScenarioBuilder.shortStackFacingOpen(deck: Deck(Random(1)));
      final strategy = PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      for (final option in strategy.options) {
        expect(option.rationaleKey, isNot(startsWith('defense_vs_open.')),
            reason: 'la tabla de 100bb no aplica a un stack de 8bb');
        expect(option.rationaleKey, startsWith('short_stack.'),
            reason: 'BB vs CO a 8bb sí tiene ancla propia de empuje-o-fold');
      }
    });

    test('un héroe que ya fue el agresor de esta calle (encarando su '
        'propio 3-bet) nunca usa DefenseVsOpenStrategy aunque el par de '
        'posiciones coincida con una ancla real', () {
      // `ExerciseScenarioBuilder.facingThreeBet` exige que heroPosition
      // actúe antes que threeBettorPosition preflop — BTN nunca puede
      // "abrir antes" que UTG en ese sentido, así que este colisión
      // real (BTN agresor, luego re-subido por UTG — exactamente el
      // par de la ancla BTN-vs-UTG) no es alcanzable vía esa fábrica.
      // Se arma a mano, mismo patrón que ya usa
      // `preflop_strategy_test.dart` para `_openOverLimpersStrategy`:
      // UTG limpea, HJ/CO foldean, BTN (héroe) sube aislando el limp,
      // SB/BB foldean, y UTG re-sube sobre esa subida — recién ahí
      // BTN, ya agresor de esta calle, enfrenta la re-subida.
      const buttonSlot = 0;
      final positions = TablePositions(buttonSlot);
      final utgSlot = positions.slotOf(Position.utg);
      final heroSlot = positions.slotOf(Position.btn);

      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(3)),
        buttonSlot: buttonSlot,
        stackBb: 100,
        explicitHandBySlot: {
          utgSlot: HoleCards.parse('7c2d'),
          heroSlot: HoleCards.parse('QsQd'),
        },
      );
      while (state.toActSlot != heroSlot) {
        final action = state.toActSlot == utgSlot
            ? PokerAction.call(state.round.currentBetBb) // UTG limpea
            : const PokerAction(ActionType.fold); // HJ/CO foldean
        state = ActionResolver.apply(state, action);
      }
      state = ActionResolver.apply(state, PokerAction.raiseTo(3)); // BTN aísla
      while (state.toActSlot != utgSlot) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold)); // SB/BB
      }
      state = ActionResolver.apply(state, PokerAction.raiseTo(9)); // UTG re-sube

      expect(state.toActSlot, heroSlot,
          reason: 'BTN, ya agresor de esta calle, tiene que volver a '
              'decidir — esta vez enfrentando la re-subida de UTG');

      final strategy = PreflopStrategy.forDecision(state, heroSlot);
      for (final option in strategy.options) {
        expect(option.rationaleKey, isNot(startsWith('defense_vs_open.')));
        // Tampoco FacingThreeBetStrategy: no hay ancla para BTN
        // encarando un 3-bet de UTG (solo existe para CO encarando uno
        // de BTN) — tiene que caer al fallback viejo, de verdad.
        expect(option.rationaleKey, isNot(startsWith('facing_three_bet.')));
        expect(option.rationaleKey, startsWith('facing_raise.'));
      }
    });
  });
}
