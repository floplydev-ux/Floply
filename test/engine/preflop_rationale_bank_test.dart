import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/concepts/user_knowledge.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_adapter.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/preflop_rationale_bank.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';

void main() {
  group('PreflopRationaleBank.textFor', () {
    test('devuelve texto real para una clave nueva conocida', () {
      expect(PreflopRationaleBank.textFor('defense_vs_open.raise.value'),
          isNotNull);
      expect(PreflopRationaleBank.textFor('short_stack.shove.value'), isNotNull);
      expect(PreflopRationaleBank.textFor('facing_three_bet.raise.value'),
          isNotNull);
    });

    test('devuelve null para una clave vieja todavía sin texto propio '
        '(cobertura deliberadamente parcial)', () {
      expect(PreflopRationaleBank.textFor('facing_raise.raise.premium'), isNull);
      expect(PreflopRationaleBank.textFor('open_over_limpers.raise.in_range'),
          isNull);
    });

    test('devuelve null si rationaleKey es null', () {
      expect(PreflopRationaleBank.textFor(null), isNull);
    });
  });

  test('ExerciseScenarioAdapter.adapt usa el texto del banco para una '
      'decisión real de DefenseVsOpenStrategy (BB vs CO, mano de valor)',
      () {
    final scenario = ExerciseScenarioBuilder.defenseVsOpen(
      deck: Deck(Random(1)),
      heroHand: HoleCards.parse('QsQd'),
    );
    final registry = ConceptRegistry.standard();
    final knowledge = UserKnowledge(registry)
      ..teachAll(['call', 'bb_defense', 'three_bet', 'three_bet_value']);

    final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry)!;
    final raiseChoice =
        adaptation.tableExercise.actions.firstWhere((a) => a.action == ActionType.raise);
    // El botón de la acción en sí (`raiseChoice.feedback`) refleja el
    // tamaño MÍNIMO ofrecido, que no matchea la opción de valor de
    // `DefenseVsOpenStrategy` (un raise de 3x) — el tamaño recomendado
    // real está en `sizeOptions` (`_recommendedSizes` siempre ofrece
    // `[mínimo, recomendado]` cuando difieren).
    final recommendedSize = raiseChoice.sizeOptions.last;

    expect(
      recommendedSize.feedback,
      startsWith(PreflopRationaleBank.textFor('defense_vs_open.raise.value')!),
    );
  });
}
