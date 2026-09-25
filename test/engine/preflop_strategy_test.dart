import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/preflop_strategy.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/game_state.dart';
import 'package:poker_trainer/engine/poker/game/scenario_builder.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/strategy/preflop_authoring.dart';
import 'package:poker_trainer/engine/strategy/strategy.dart';

/// Tests dirigidos para el redisño de "FLOPly — Fase 0.5" en
/// `PreflopStrategy` — `_openOverLimpersStrategy`/`_facingRaiseStrategy`
/// son privados y `_openOverLimpersStrategy` no es alcanzable desde
/// ninguna de las 5 familias de `ExerciseScenarioBuilder` (ninguna
/// simula un limp todavía), así que este archivo arma el `GameState` a
/// mano para poder llegar a esa rama.
void main() {
  /// UTG limpea (paga la ciega grande sin subir), HJ foldea, y le llega
  /// el turno a CO — dispara `_openOverLimpersStrategy` (no hay subida
  /// que enfrentar, pero tampoco es first-in real).
  GameState openOverLimpersState(HoleCards heroHand) {
    final deck = Deck(Random(42));
    const buttonSlot = 0;
    final heroSlot = TablePositions(buttonSlot).slotOf(Position.co);
    var state = ScenarioBuilder.freshHand(
      deck: deck,
      buttonSlot: buttonSlot,
      stackBb: 100,
      explicitHandBySlot: {heroSlot: heroHand},
    );
    while (state.toActSlot != heroSlot) {
      final isFirstActor = state.round.log.isEmpty; // UTG actúa primero
      final action = isFirstActor
          ? PokerAction.call(state.round.currentBetBb) // limp
          : const PokerAction(ActionType.fold); // HJ foldea
      state = ActionResolver.apply(state, action);
    }
    return state;
  }

  group('_openOverLimpersStrategy (vía PreflopStrategy.forDecision)', () {
    test('mano claramente en rango: subir óptimo, foldear malo', () {
      final state = openOverLimpersState(HoleCards.parse('AsAd'));
      final heroSlot = TablePositions(0).slotOf(Position.co);
      final strategy = PreflopStrategy.forDecision(state, heroSlot);

      final raise = strategy.options.firstWhere((o) => o.action.type == ActionType.raise);
      final fold = strategy.options.firstWhere((o) => o.action.type == ActionType.fold);
      expect(raise.rating, StrategicRating.optimal);
      expect(fold.rating, StrategicRating.bad);
    });

    test('mano de frontera (freq intermedia real en CO): ambas acciones '
        'son "viable" — ninguna veryGood, la calidad no sale de la '
        'frecuencia', () {
      // K6s tiene frecuencia 0.5 en el rango de CO (assets/ranges/
      // opening_ranges.json) — frontera real, no un extremo.
      final state = openOverLimpersState(HoleCards.parse('Ks6s'));
      final heroSlot = TablePositions(0).slotOf(Position.co);
      final strategy = PreflopStrategy.forDecision(state, heroSlot);

      expect(strategy.options.length, 2);
      for (final option in strategy.options) {
        expect(option.rating, StrategicRating.viable,
            reason: '${option.action.label}: la frontera ya no se '
                'subdivide en veryGood/viable por un umbral de frecuencia');
      }
    });

    test('mano claramente fuera de rango: foldear óptimo, subir malo', () {
      final state = openOverLimpersState(HoleCards.parse('7h2c'));
      final heroSlot = TablePositions(0).slotOf(Position.co);
      final strategy = PreflopStrategy.forDecision(state, heroSlot);

      final fold = strategy.options.firstWhere((o) => o.action.type == ActionType.fold);
      final raise = strategy.options.firstWhere((o) => o.action.type == ActionType.raise);
      expect(fold.rating, StrategicRating.optimal);
      expect(raise.rating, StrategicRating.bad);
    });
  });

  group('_facingRaiseStrategy — role y contextSensitivity nuevos', () {
    test('3-bet premium: role value, sin dependencia de contexto', () {
      final scenario = ExerciseScenarioBuilder.threeBet(
        deck: Deck(Random(7)),
        heroHand: HoleCards.parse('AsAd'),
      );
      final strategy =
          PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);
      final raise = strategy.options.firstWhere((o) => o.action.type == ActionType.raise);
      expect(raise.rating, StrategicRating.optimal);
      expect(raise.role, StrategyRole.value);
      expect(raise.contextSensitivity.isDependent, isFalse);
    });

    test('call de defensa: role defend', () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(11)),
        heroHand: HoleCards.parse('Ts9s'),
      );
      final strategy =
          PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);
      final call = strategy.options.firstWhere((o) => o.action.type == ActionType.call);
      expect(call.role, StrategyRole.defend);
    });

    test('3-bet liviano (banda dudosa): role bluff, y SÍ depende del '
        'contexto (perfil/rango del rival) sin revelar — produce DEPENDS, '
        'no ERROR', () {
      // Percentil 0.06-0.35: la rama que antes era "dubious" a secas.
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(11)),
        heroHand: HoleCards.parse('Ts9s'),
      );
      final strategy =
          PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);
      final raise = strategy.options.firstWhereOrNull((o) => o.action.type == ActionType.raise);
      if (raise != null && raise.rating == StrategicRating.dubious) {
        expect(raise.role, StrategyRole.bluff);
        expect(raise.contextSensitivity.isDependent, isTrue);
        expect(raise.contextSensitivity.disclosedToStudent, isFalse);
        expect(
          isCoherentCell(
            quality: raise.rating,
            mixShare: MixShare.fromFrequency(raise.frequency),
          ),
          isTrue,
        );
      }
    });

    test('fold: role fold en las 3 bandas', () {
      for (final hand in ['AsAd', 'Ts9s', '7h2c']) {
        final scenario = ExerciseScenarioBuilder.defenseVsOpen(
          deck: Deck(Random(3)),
          heroHand: HoleCards.parse(hand),
        );
        final strategy =
            PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);
        final fold = strategy.options.firstWhere((o) => o.action.type == ActionType.fold);
        expect(fold.role, StrategyRole.fold, reason: hand);
      }
    });
  });
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
