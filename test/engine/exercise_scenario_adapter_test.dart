import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/concepts/user_knowledge.dart';
import 'package:poker_trainer/engine/exercises/answer_evaluator.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_adapter.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/student_turn_controller.dart';
import 'package:poker_trainer/engine/pedagogy/playable_exercise.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart' show Position;
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';

/// UserKnowledge con exactamente estos conceptos enseñados (el resto
/// queda `locked`).
UserKnowledge _knowledgeWith(ConceptRegistry registry, Iterable<String> taught) {
  final k = UserKnowledge(registry);
  for (final id in taught) {
    k.teach(id);
  }
  return k;
}

void main() {
  final registry = ConceptRegistry.standard();

  group('ExerciseScenarioAdapter.adapt — conversión válida', () {
    test('arma un PlayableTableExercise con la mano y el pot reales del '
        'escenario', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.btn,
      );
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
      final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry);

      expect(adaptation, isNotNull);
      final table = adaptation!.tableExercise;
      final heroSeat = table.situation.seatAt(scenario.heroSlot);
      expect(heroSeat.isHero, isTrue);
      expect(heroSeat.cards.length, 2);
      expect(table.situation.potBb, scenario.initialState.pot.totalBb);
      expect(table.situation.buttonSlot, scenario.initialState.buttonSlot);
    });

    test('las cartas de los rivales nunca se muestran', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(1)));
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
      final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry)!;
      for (final seat in adaptation.tableExercise.situation.seats) {
        if (seat.isHero) continue;
        expect(seat.cards, isEmpty, reason: 'slot ${seat.slot}');
      }
    });

    test('las ActionChoice corresponden 1:1 a DecisionContext.legalActions', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(1)));
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
      final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry)!;

      final actionTypes = adaptation.tableExercise.actions.map((a) => a.action).toSet();
      expect(actionTypes, scenario.decisionContext.legalActions);
    });

    test('el tamaño de RAISE ofrecido siempre está dentro de '
        '[minRaiseToBb, maxRaiseToBb]', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(1)));
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
      final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry)!;

      final raiseChoice =
          adaptation.tableExercise.actions.firstWhere((a) => a.action == ActionType.raise);
      expect(raiseChoice.sizeOptions, isNotEmpty);
      final size = adaptation.actionFor(raiseChoice, raiseChoice.sizeOptions.first).sizeBb!;
      expect(size, greaterThanOrEqualTo(scenario.decisionContext.minRaiseToBb!));
      expect(size, lessThanOrEqualTo(scenario.decisionContext.maxRaiseToBb!));
    });

    test('el rating de cada opción coincide con evaluarla por separado '
        'con AnswerEvaluator', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(1)));
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
      final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry)!;

      for (final choice in adaptation.tableExercise.actions) {
        final action = choice.needsSizing
            ? adaptation.actionFor(choice, choice.sizeOptions.first)
            : adaptation.actionFor(choice, null);
        final independent = AnswerEvaluator.evaluate(scenario, action);
        final expectedRating = switch (independent.verdict) {
          AnswerVerdict.best => ExerciseRating.best,
          AnswerVerdict.acceptable || AnswerVerdict.dependent => ExerciseRating.acceptable,
          AnswerVerdict.poor => ExerciseRating.poor,
        };
        expect(choice.rating, expectedRating, reason: choice.action.name);
      }
    });
  });

  group('ExerciseScenarioAdapter.adapt — sizings (Fase 8.4)', () {
    test('ofrece 3 tamaños reales y distintos para un Open Raise — nunca '
        'hardcodeados, surgen de OpeningRanges para la posición real',
        () {
      // UTG con mano premium: siempre debería abrir, con graduación real
      // de tamaño (mínimo defendible / ideal / máximo defendible de
      // OpeningRanges) — nunca un solo tamaño "tómalo o déjalo" ni 3
      // números fijos iguales para cualquier posición.
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.utg,
        heroHand: HoleCards.parse('AsAd'),
      );
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
      final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry)!;

      final raiseChoice =
          adaptation.tableExercise.actions.firstWhere((a) => a.action == ActionType.raise);
      expect(raiseChoice.sizeOptions.length, 3);
      final sizes = raiseChoice.sizeOptions
          .map((s) => adaptation.actionFor(raiseChoice, s).sizeBb)
          .toSet();
      expect(sizes.length, 3, reason: 'los 3 tamaños ofrecidos son distintos');
      for (final size in sizes) {
        expect(size, greaterThanOrEqualTo(scenario.decisionContext.minRaiseToBb!));
        expect(size, lessThanOrEqualTo(scenario.decisionContext.maxRaiseToBb!));
      }

      // Corrección de Open Raise: NINGUNO de los 3 tamaños reales y
      // razonables debería marcarse como error (`poor`) solo por no ser
      // el único tamaño "ideal" exacto — la mano es premium, abrir con
      // cualquiera de estos 3 tamaños es correcto.
      for (final sizeOption in raiseChoice.sizeOptions) {
        final action = adaptation.actionFor(raiseChoice, sizeOption);
        final result = AnswerEvaluator.evaluate(scenario, action);
        expect(result.verdict, isNot(AnswerVerdict.poor), reason: '${action.sizeBb} bb');
      }
    });

    test('ofrece hasta 3 tamaños para RAISE aunque la opción primaria de '
        'la estrategia no sea RAISE/BET — igual deben ser legales y '
        'distintos entre sí', () {
      // Mano muy débil enfrentando un open: la opción primaria de
      // PreflopStrategy es fold/call, no 3-bet — aun así RAISE sigue
      // siendo legal (siempre se puede 3-betear con chips), y el pedido
      // de "siempre 3 opciones de sizing" no depende de que 3-betear sea
      // la jugada recomendada.
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(3)),
        heroHand: HoleCards.parse('7c2d'),
      );
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
      final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry)!;

      final raiseChoice = adaptation.tableExercise.actions
          .where((a) => a.action == ActionType.raise)
          .firstOrNull;
      if (raiseChoice == null) return; // RAISE no legal acá, nada que revisar.
      final sizes = raiseChoice.sizeOptions
          .map((s) => adaptation.actionFor(raiseChoice, s).sizeBb)
          .toSet();
      expect(sizes.length, raiseChoice.sizeOptions.length,
          reason: 'los tamaños ofrecidos son todos distintos entre sí');
      expect(sizes.length, lessThanOrEqualTo(3));
      for (final size in sizes) {
        expect(size, greaterThanOrEqualTo(scenario.decisionContext.minRaiseToBb!));
        expect(size, lessThanOrEqualTo(scenario.decisionContext.maxRaiseToBb!));
      }
    });
  });

  group('ExerciseScenarioAdapter.adapt — filtrado contra UserKnowledge', () {
    test('scenario concepts [A,B,C], user sabe [A,C] → el feedback nunca '
        'menciona B', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(5)),
        heroHand: null,
      );
      // Fuerzo un escenario con al menos 3 conceptos evaluables reales
      // (openRaise declara positionAdvantage/openingRange/openRaise).
      expect(scenario.evaluableConcepts.length, greaterThanOrEqualTo(3));
      final a = scenario.evaluableConcepts[0];
      final b = scenario.evaluableConcepts[1];
      final c = scenario.evaluableConcepts[2];
      final knowledge = _knowledgeWith(registry, [a, c]);

      final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry);
      expect(adaptation, isNotNull);
      final bName = registry.byId(b).name;
      for (final choice in adaptation!.tableExercise.actions) {
        expect(choice.feedback.contains(bName), isFalse,
            reason: 'no debería mencionar "$bName" (no enseñado)');
      }
    });

    test('scenario concepts [A,B], user no sabe nada → adapt devuelve null '
        '(no inventa una evaluación)', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(6)));
      expect(scenario.evaluableConcepts, isNotEmpty);
      final knowledge = UserKnowledge(registry); // nada enseñado
      final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry);
      expect(adaptation, isNull);
    });
  });

  group('Integración de punta a punta — sin mocks del motor', () {
    test('ExerciseScenarioBuilder → ExerciseScenario → adapter → '
        'StudentTurnController → LegalActionEngine → ActionResolver → '
        'AnswerEvaluator → AnswerResult', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(7)),
        heroPosition: Position.utg,
      );
      final knowledge = _knowledgeWith(registry, scenario.evaluableConcepts);
      final adaptation = ExerciseScenarioAdapter.adapt(scenario, knowledge, registry)!;

      // El alumno "toca" la primera acción legal que ofrece la mesa.
      final chosen = adaptation.tableExercise.actions.first;
      final chosenSize = chosen.needsSizing ? chosen.sizeOptions.first : null;
      final realAction = adaptation.actionFor(chosen, chosenSize);

      final controller = StudentTurnController(scenario);
      expect(controller.legalActions, contains(realAction.type));

      final nextState = controller.applyHeroAction(realAction);
      expect(nextState.toActSlot, isNot(scenario.heroSlot));

      final result = AnswerEvaluator.evaluate(scenario, realAction);
      expect(result.verdict, isA<AnswerVerdict>());
      expect(result.justifyingConcepts.every(scenario.evaluableConcepts.contains), isTrue);
    });
  });
}
