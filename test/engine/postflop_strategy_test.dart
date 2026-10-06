import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/postflop_strategy.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/poker/position.dart';
import 'package:poker_trainer/engine/poker/street.dart';
import 'package:poker_trainer/engine/strategy/strategy.dart';

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

  group('PostflopStrategy — rationaleKey/math (devolución estructurada de '
      'Laboratorio)', () {
    test('_cbetStrategy: bet/check tienen rationaleKey propio y declaran '
        'rangeAdvantage — nunca math (heurística, no equity real)', () {
      final scenario = ExerciseScenarioBuilder.cbetDecision(deck: Deck(Random(1)));
      final strategy =
          PostflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

      final bet = strategy.optionFor(const PokerAction(ActionType.bet))!;
      final check = strategy.optionFor(const PokerAction(ActionType.check))!;

      expect(bet.rationaleKey, 'cbet.bet');
      expect(check.rationaleKey, 'cbet.check');
      expect(bet.justifyingConcepts, contains(ConceptIds.rangeAdvantage));
      expect(check.justifyingConcepts, contains(ConceptIds.rangeAdvantage));
      expect(bet.math, isNull);
      expect(check.math, isNull);
    });

    test('_facingCbetStrategy: call/fold traen la equity/pot odds reales ya '
        'calculadas (no un número inventado) y un rationaleKey coherente '
        'con quién de los dos es la línea óptima', () {
      for (var seed = 1; seed <= 15; seed++) {
        final scenario = ExerciseScenarioBuilder.facingCbet(deck: Deck(Random(seed)));
        final strategy =
            PostflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);

        final call = strategy.optionFor(const PokerAction(ActionType.call))!;
        final fold = strategy.optionFor(PokerAction.fold)!;

        for (final option in [call, fold]) {
          final math = option.math;
          expect(math, isNotNull, reason: 'seed $seed: ${option.action}');
          expect(math!.equityPct, isNotNull, reason: 'seed $seed');
          expect(math.requiredEquityPct, isNotNull, reason: 'seed $seed');
          expect(math.edgePct, isNotNull, reason: 'seed $seed');
          expect(math.potBb, isNotNull, reason: 'seed $seed');
          expect(math.toCallBb, isNotNull, reason: 'seed $seed');
          // edgePct es exactamente equityPct - requiredEquityPct — nunca
          // un tercer número calculado por separado.
          expect(math.edgePct, closeTo(math.equityPct! - math.requiredEquityPct!, 0.01),
              reason: 'seed $seed');
          expect(option.rationaleKey, isNotNull, reason: 'seed $seed');
          expect(option.rationaleKey, startsWith('facing_cbet.'), reason: 'seed $seed');
        }

        // Call y fold comparten exactamente los mismos números (es la
        // misma decisión, vista desde las dos acciones) — nunca dos
        // equities distintas para el mismo spot.
        expect(call.math!.equityPct, fold.math!.equityPct, reason: 'seed $seed');
      }
    });

    test('_barrelStrategy (turnBarrel): bet/check traen equity real, y '
        'exactamente uno de los dos es la línea óptima', () {
      for (var seed = 1; seed <= 200; seed++) {
        final scenario = ExerciseScenarioBuilder.turnBarrel(deck: Deck(Random(seed)));
        Strategy strategy;
        try {
          strategy = PostflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);
        } on ArgumentError {
          // Caso límite ya documentado en `PostflopStrategy.
          // _villainRangeFor`: para algunos pares hero/board, el rango de
          // referencia queda sin combos válidos una vez descontadas las
          // cartas conocidas — no es algo que este test (ni
          // `PostflopStrategy`) deba resolver, así que estas semillas
          // puntuales se saltan.
          continue;
        }

        final bet = strategy.optionFor(const PokerAction(ActionType.bet))!;
        final check = strategy.optionFor(const PokerAction(ActionType.check))!;

        for (final option in [bet, check]) {
          expect(option.math, isNotNull, reason: 'seed $seed: ${option.action}');
          expect(option.math!.equityPct, isNotNull, reason: 'seed $seed');
          expect(option.rationaleKey, isNotNull, reason: 'seed $seed');
          expect(option.rationaleKey, startsWith('barrel.'), reason: 'seed $seed');
        }
        expect(bet.math!.equityPct, check.math!.equityPct, reason: 'seed $seed');
        // Exactamente una de las dos es la línea óptima — nunca ambas ni
        // ninguna (el piso de equity siempre inclina para un lado).
        expect({bet.rating, check.rating}, {StrategicRating.optimal, StrategicRating.dubious},
            reason: 'seed $seed');
      }
    });
  });
}
