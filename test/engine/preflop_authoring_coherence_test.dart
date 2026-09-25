import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/preflop_strategy.dart';
import 'package:poker_trainer/engine/exercises/templates/situation_factory.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/position.dart';
import 'package:poker_trainer/engine/strategy/preflop_authoring.dart';
import 'package:poker_trainer/engine/strategy/strategy.dart';
import 'package:poker_trainer/engine/strategy/strategy_engine.dart';

/// Guarda de propiedad para "FLOPly — Fase 0.5": todo lo que los
/// generadores REALES de estrategia (`StrategyEngine`, `PreflopStrategy`)
/// producen tiene que respetar [isCoherentCell] — nunca una opción
/// `QualityTier.top` con [MixShare.negligible] (afirmar "esta es la mejor
/// jugada posible" y, en el mismo aliento, "casi nunca se juega" es una
/// contradicción de autoría).
///
/// Esto es lo que [isCoherentCell] (`strategy/preflop_authoring.dart`)
/// está pensada para detectar — antes de esta suite, esa función solo se
/// probaba con datos sintéticos (`preflop_authoring_test.dart`), nunca
/// contra la salida real del motor.
void main() {
  const engine = StrategyEngine();

  void expectCoherent(Strategy strategy, String reason) {
    for (final option in strategy.options) {
      final mixShare = MixShare.fromFrequency(option.frequency);
      expect(
        isCoherentCell(quality: option.rating, mixShare: mixShare),
        isTrue,
        reason: '$reason — ${option.action.label} freq=${option.frequency} '
            'rating=${option.rating} mixShare=$mixShare',
      );
    }
  }

  group('StrategyEngine.openRaiseStrategy — coherente para las 169 clases '
      'x 5 posiciones', () {
    test('ninguna celda es top + negligible', () {
      for (final hc in HandClass.all()) {
        for (final pos in [
          Position.utg,
          Position.hj,
          Position.co,
          Position.btn,
          Position.sb,
        ]) {
          final deck = Deck(Random(hc.notation.hashCode));
          final hand = deck.dealHandOfClass(hc.notation);
          if (hand == null) continue;
          final situation = SituationFactory.firstIn(
            heroPosition: pos,
            heroCards: hand,
            effectiveStackBb: 100,
            availableRaiseSizes: const [2.5, 3.0],
          );
          final strategy = engine.openRaiseStrategy(situation);
          expectCoherent(strategy, '${pos.abbreviation} ${hc.notation}');
        }
      }
    });
  });

  group('PreflopStrategy.forDecision — coherente en las 5 familias de '
      'ExerciseScenarioBuilder', () {
    test('openRaise', () {
      for (var seed = 0; seed < 60; seed++) {
        final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(seed)));
        final strategy =
            PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);
        expectCoherent(strategy, 'openRaise seed=$seed');
      }
    });

    test('defenseVsOpen', () {
      for (var seed = 0; seed < 60; seed++) {
        final scenario =
            ExerciseScenarioBuilder.defenseVsOpen(deck: Deck(Random(seed)));
        final strategy =
            PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);
        expectCoherent(strategy, 'defenseVsOpen seed=$seed');
      }
    });

    test('threeBet', () {
      for (var seed = 0; seed < 60; seed++) {
        final scenario = ExerciseScenarioBuilder.threeBet(deck: Deck(Random(seed)));
        final strategy =
            PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);
        expectCoherent(strategy, 'threeBet seed=$seed');
      }
    });

    test('facingThreeBet', () {
      for (var seed = 0; seed < 60; seed++) {
        final scenario =
            ExerciseScenarioBuilder.facingThreeBet(deck: Deck(Random(seed)));
        final strategy =
            PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);
        expectCoherent(strategy, 'facingThreeBet seed=$seed');
      }
    });

    test('shortStackFacingOpen', () {
      for (var seed = 0; seed < 60; seed++) {
        final scenario =
            ExerciseScenarioBuilder.shortStackFacingOpen(deck: Deck(Random(seed)));
        final strategy =
            PreflopStrategy.forDecision(scenario.initialState, scenario.heroSlot);
        expectCoherent(strategy, 'shortStackFacingOpen seed=$seed');
      }
    });
  });
}
