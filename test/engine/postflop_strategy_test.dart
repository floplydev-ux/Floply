import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/postflop_strategy.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/poker/position.dart';
import 'package:poker_trainer/engine/poker/street.dart';

Card _c(String code) => Card.parse(code);

void main() {
  group('PostflopStrategy.boardFavorsAggressor', () {
    test('board seco, rainbow, con Rey — favorece al agresor', () {
      expect(
          PostflopStrategy.boardFavorsAggressor([_c('Ks'), _c('7d'), _c('2c')]),
          isTrue);
    });

    test('board seco, rainbow, con As — favorece al agresor', () {
      expect(
          PostflopStrategy.boardFavorsAggressor([_c('As'), _c('Kd'), _c('2c')]),
          isTrue);
    });

    test('board pareado no favorece al agresor (aunque tenga Rey)', () {
      expect(
          PostflopStrategy.boardFavorsAggressor([_c('Ks'), _c('Kd'), _c('2c')]),
          isFalse);
    });

    test('board monotone no favorece al agresor (aunque tenga Rey)', () {
      expect(
          PostflopStrategy.boardFavorsAggressor([_c('Ks'), _c('7s'), _c('2s')]),
          isFalse);
    });

    test('board two-tone no favorece al agresor (aunque tenga Rey)', () {
      expect(
          PostflopStrategy.boardFavorsAggressor([_c('Ks'), _c('7s'), _c('2c')]),
          isFalse);
    });

    test('board seco y rainbow sin carta alta no favorece al agresor', () {
      expect(
          PostflopStrategy.boardFavorsAggressor([_c('Qs'), _c('7d'), _c('2c')]),
          isFalse);
    });

    test('un board de 5 cartas (river) nunca califica — esta familia solo '
        'cubre el flop', () {
      expect(
          PostflopStrategy.boardFavorsAggressor(
              [_c('Ks'), _c('7d'), _c('2c'), _c('9h'), _c('3s')]),
          isFalse);
    });
  });

  group('PostflopStrategy.forDecision — validación de alcance', () {
    test('lanza UnsupportedError si la calle no es el flop', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(1)));
      expect(
        () => PostflopStrategy.forDecision(scenario.initialState, scenario.heroSlot),
        throwsUnsupportedError,
      );
    });
  });

  group('ExerciseScenarioBuilder.cbetDecision — construcción real', () {
    test('el board generado siempre favorece al agresor (barrido de '
        'semillas)', () {
      for (var seed = 1; seed <= 30; seed++) {
        final scenario = ExerciseScenarioBuilder.cbetDecision(deck: Deck(Random(seed)));
        expect(scenario.initialState.street, Street.flop, reason: 'seed $seed');
        expect(scenario.initialState.board.length, 3, reason: 'seed $seed');
        expect(
          PostflopStrategy.boardFavorsAggressor(scenario.initialState.board),
          isTrue,
          reason: 'seed $seed: board ${scenario.initialState.board}',
        );
      }
    });

    test('el héroe llega a decidir con las acciones legales reales '
        '(check/bet), habiendo sido el agresor preflop', () {
      final scenario = ExerciseScenarioBuilder.cbetDecision(deck: Deck(Random(1)));
      final state = scenario.initialState;

      expect(scenario.objective, PreflopScenarioKind.cbetDecision);
      expect(state.toActSlot, scenario.heroSlot);
      expect(state.seatAt(scenario.heroSlot).holeCards, isNotNull);
      expect(scenario.decisionContext.legalActions, {ActionType.check, ActionType.bet});
      // El rival ya checkeó de guion — un solo registro en el log de esta
      // calle, y no es el héroe quien lo generó.
      expect(state.round.log, hasLength(1));
      expect(state.round.log.single.action.type, ActionType.check);
      expect(state.round.log.single.slot, isNot(scenario.heroSlot));
      // El héroe fue realmente el agresor preflop.
      expect(state.streetHistory.single.lastAggressorSlot, scenario.heroSlot);
    });

    test('evaluableConcepts incluye cbet y board_texture', () {
      final scenario = ExerciseScenarioBuilder.cbetDecision(deck: Deck(Random(1)));
      expect(scenario.evaluableConcepts, contains('cbet'));
      expect(scenario.evaluableConcepts, contains('board_texture'));
    });

    test('heroPosition igual a villainPosition lanza ArgumentError', () {
      expect(
        () => ExerciseScenarioBuilder.cbetDecision(
          deck: Deck(Random(1)),
          heroPosition: Position.btn,
          villainPosition: Position.btn,
        ),
        throwsArgumentError,
      );
    });

    test('villainPosition sin posición postflop sobre heroPosition lanza '
        'ArgumentError (acá, heroPosition sin ventaja real)', () {
      // BTN siempre tiene posición sobre BB postflop — invertir los
      // roles (héroe = BB, rival = BTN) tiene que fallar la validación.
      expect(
        () => ExerciseScenarioBuilder.cbetDecision(
          deck: Deck(Random(1)),
          heroPosition: Position.bb,
          villainPosition: Position.btn,
        ),
        throwsArgumentError,
      );
    });
  });
}
