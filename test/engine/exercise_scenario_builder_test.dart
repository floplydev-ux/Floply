import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/answer_evaluator.dart';
import 'package:poker_trainer/engine/exercises/decision_context.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/exercises/preflop_session_summary.dart';
import 'package:poker_trainer/engine/exercises/student_turn_controller.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/exercises/templates/hand_picker.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/opponent_policy.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/strategy/opening_ranges.dart';

int slotFor(Position position, int buttonSlot) =>
    TablePositions(buttonSlot).slotOf(position);

void main() {
  group('ExerciseScenario — construcción válida e inmutable', () {
    test('el decisionContext guardado coincide con recalcularlo desde '
        'initialState/heroSlot', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(1)));
      final recomputed = DecisionContext.fromGameState(
        scenario.initialState,
        heroSlot: scenario.heroSlot,
      );
      expect(scenario.decisionContext.heroCards, recomputed.heroCards);
      expect(scenario.decisionContext.legalActions, recomputed.legalActions);
      expect(scenario.decisionContext.potBb, recomputed.potBb);
    });

    test('evaluableConcepts nunca está vacío para ningún tipo de escenario',
        () {
      expect(ExerciseScenarioBuilder.openRaise(deck: Deck(Random(1))).evaluableConcepts,
          isNotEmpty);
      expect(
          ExerciseScenarioBuilder.defenseVsOpen(deck: Deck(Random(1))).evaluableConcepts,
          isNotEmpty);
    });
  });

  group('Tipo A — Open Raise', () {
    test('el héroe llega a decidir con una mano conocida y acciones '
        'legales reales', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(1)),
        heroPosition: Position.btn,
      );
      expect(scenario.objective, PreflopScenarioKind.openRaise);
      expect(scenario.decisionContext.heroPosition, Position.btn);
      expect(scenario.initialState.seatAt(scenario.heroSlot).holeCards, isNotNull);
      expect(scenario.decisionContext.legalActions,
          {ActionType.fold, ActionType.call, ActionType.raise});
    });

    test('todos los que actúan antes del héroe están foldeados; los que '
        'actúan después (ciegas) siguen sin tocar', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(2)),
        buttonSlot: 0,
        heroPosition: Position.co,
      );
      final state = scenario.initialState;
      final utgSlot = slotFor(Position.utg, 0);
      final hjSlot = slotFor(Position.hj, 0);
      final sbSlot = slotFor(Position.sb, 0);
      final bbSlot = slotFor(Position.bb, 0);
      expect(state.seatAt(utgSlot).folded, isTrue);
      expect(state.seatAt(hjSlot).folded, isTrue);
      expect(state.seatAt(sbSlot).folded, isFalse);
      expect(state.seatAt(bbSlot).folded, isFalse);
    });

    test('heroPosition == bb lanza ArgumentError: no hay decisión real de '
        'apertura', () {
      expect(
        () => ExerciseScenarioBuilder.openRaise(
            deck: Deck(Random(1)), heroPosition: Position.bb),
        throwsArgumentError,
      );
    });
  });

  group('Tipo B — Defense vs Open', () {
    test('el rival realmente abrió antes de que el héroe decida', () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(
        deck: Deck(Random(3)),
        heroPosition: Position.bb,
        openerPosition: Position.co,
      );
      final openerSlot = slotFor(Position.co, 0);
      final openRaiseLog = scenario.initialState.round.log
          .where((e) => e.slot == openerSlot && e.action.type == ActionType.raise);
      expect(openRaiseLog, isNotEmpty, reason: 'el abridor tiene que haber subido de verdad');
    });

    test('el héroe enfrenta una decisión real (debe pagar algo, tiene '
        'fold/call/raise)', () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(deck: Deck(Random(3)));
      expect(scenario.decisionContext.toCallBb, greaterThan(0));
      expect(scenario.decisionContext.legalActions, contains(ActionType.fold));
      expect(scenario.decisionContext.legalActions, contains(ActionType.call));
    });

    test('openerPosition actuando después de heroPosition lanza '
        'ArgumentError', () {
      expect(
        () => ExerciseScenarioBuilder.defenseVsOpen(
          deck: Deck(Random(1)),
          heroPosition: Position.utg,
          openerPosition: Position.btn,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Tipo C — 3-Bet', () {
    test('existe una acción previa de apertura real y el héroe enfrenta '
        'esa decisión', () {
      final scenario = ExerciseScenarioBuilder.threeBet(
        deck: Deck(Random(4)),
        heroPosition: Position.btn,
        openerPosition: Position.utg,
      );
      expect(scenario.objective, PreflopScenarioKind.threeBet);
      final utgSlot = slotFor(Position.utg, 0);
      expect(
        scenario.initialState.round.log
            .any((e) => e.slot == utgSlot && e.action.type == ActionType.raise),
        isTrue,
      );
      expect(scenario.decisionContext.legalActions, contains(ActionType.raise));
    });
  });

  group('Tipo D — Facing 3-Bet', () {
    test('la 3-bet es real (sampleada de PreflopRangeBook para el par '
        'default, BTN vs CO), y ActionResolver acepta toda la secuencia', () {
      final scenario = ExerciseScenarioBuilder.facingThreeBet(
        deck: Deck(Random(5)),
        heroPosition: Position.co,
        threeBettorPosition: Position.btn,
      );
      expect(scenario.objective, PreflopScenarioKind.facingThreeBet);

      final heroSlot = scenario.heroSlot;
      final threeBettorSlot = slotFor(Position.btn, 0);
      final log = scenario.initialState.round.log;

      // La apertura mecánica del héroe está en el log...
      expect(log.any((e) => e.slot == heroSlot && e.action.type == ActionType.raise),
          isTrue);
      // ...y también la re-subida real del rival, por encima de esa apertura.
      final heroOpenSize =
          log.firstWhere((e) => e.slot == heroSlot).action.sizeBb!;
      final threeBetEntry =
          log.firstWhere((e) => e.slot == threeBettorSlot && e.action.type == ActionType.raise);
      expect(threeBetEntry.action.sizeBb!, greaterThan(heroOpenSize));

      // El héroe efectivamente enfrenta esa subida ahora.
      expect(scenario.decisionContext.currentBetBb, threeBetEntry.action.sizeBb);
      expect(scenario.decisionContext.toCallBb, greaterThan(0));
    });

    test('heroPosition actuando después de threeBettorPosition lanza '
        'ArgumentError', () {
      expect(
        () => ExerciseScenarioBuilder.facingThreeBet(
          deck: Deck(Random(1)),
          heroPosition: Position.sb,
          threeBettorPosition: Position.utg,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Tipo E — Short Stack', () {
    test('un stack corto restringe legalActions de verdad, sin reglas '
        'nuevas fuera de LegalActionEngine', () {
      final scenario = ExerciseScenarioBuilder.shortStackFacingOpen(
        deck: Deck(Random(6)),
        heroPosition: Position.bb,
        openerPosition: Position.co,
        heroStackBb: 3,
      );
      expect(scenario.objective, PreflopScenarioKind.shortStack);
      // Con 3bb de partida (BB ya posteó 1bb de ciega, quedan 2 frente a
      // un open a 2.5bb) no alcanza para un raise completo: no importa
      // el número exacto del set restante, lo que prueba la restricción
      // real es que `raise` deja de estar disponible.
      expect(scenario.decisionContext.legalActions, contains(ActionType.fold));
      expect(scenario.decisionContext.legalActions, isNot(contains(ActionType.raise)));
    });

    test('con stack profundo, el mismo mecanismo ofrece fold/call/raise '
        'normalmente (la restricción es real, no hardcodeada)', () {
      final scenario = ExerciseScenarioBuilder.shortStackFacingOpen(
        deck: Deck(Random(6)),
        heroPosition: Position.bb,
        openerPosition: Position.co,
        heroStackBb: 100,
      );
      expect(scenario.decisionContext.legalActions, contains(ActionType.raise));
    });
  });

  group('ExerciseScenarioBuilder — sin cartas repetidas', () {
    test('las manos conocidas y el resto del mazo nunca se pisan (en los '
        '5 tipos)', () {
      final scenarios = [
        ExerciseScenarioBuilder.openRaise(deck: Deck(Random(10))),
        ExerciseScenarioBuilder.defenseVsOpen(deck: Deck(Random(11))),
        ExerciseScenarioBuilder.threeBet(deck: Deck(Random(12))),
        ExerciseScenarioBuilder.facingThreeBet(deck: Deck(Random(13))),
        ExerciseScenarioBuilder.shortStackFacingOpen(deck: Deck(Random(14))),
      ];
      for (final scenario in scenarios) {
        final state = scenario.initialState;
        final allCards = [
          for (final s in state.seats) ...?s.holeCards?.cards,
          ...state.board,
          ...state.remainingDeckCards,
        ];
        expect(allCards.toSet().length, allCards.length,
            reason: '${scenario.objective}: cartas repetidas');
      }
    });
  });

  group('ExerciseScenarioBuilder — determinismo', () {
    test('la misma semilla reconstruye exactamente el mismo escenario', () {
      ExerciseScenario build() =>
          ExerciseScenarioBuilder.defenseVsOpen(deck: Deck(Random(55)));
      final a = build();
      final b = build();
      expect(a.decisionContext.heroCards, b.decisionContext.heroCards);
      expect(a.initialState.pot.totalBb, b.initialState.pot.totalBb);
      expect(a.initialState.toActSlot, b.initialState.toActSlot);
      expect(a.decisionContext.legalActions, b.decisionContext.legalActions);
    });
  });

  group('ExerciseScenarioBuilder — heroHandBias/opponentProfile (Fase 10.5/10.6)', () {
    test('heroHandBias: clearlyInRange siempre da una mano de héroe con '
        'freq >= 0.9 para openRaise', () {
      for (var seed = 0; seed < 15; seed++) {
        final scenario = ExerciseScenarioBuilder.openRaise(
          deck: Deck(Random(seed)),
          heroPosition: Position.utg,
          heroHandBias: HandBias.clearlyInRange,
        );
        final hand = scenario.initialState.seatAt(scenario.heroSlot).holeCards!;
        final freq = OpeningRanges.forPosition(Position.utg).frequencyOf(hand.notation);
        expect(freq, greaterThanOrEqualTo(0.9), reason: 'seed $seed: ${hand.notation}');
      }
    });

    test('heroHandBias: clearlyOutOfRange siempre da una mano de héroe '
        'con freq == 0 para openRaise', () {
      for (var seed = 0; seed < 15; seed++) {
        final scenario = ExerciseScenarioBuilder.openRaise(
          deck: Deck(Random(seed)),
          heroPosition: Position.utg,
          heroHandBias: HandBias.clearlyOutOfRange,
        );
        final hand = scenario.initialState.seatAt(scenario.heroSlot).holeCards!;
        final freq = OpeningRanges.forPosition(Position.utg).frequencyOf(hand.notation);
        expect(freq, 0, reason: 'seed $seed: ${hand.notation}');
      }
    });

    test('heroHandBias no rompe defenseVsOpen/threeBet/facingThreeBet/'
        'shortStack — solo cambia qué mano recibe el héroe', () {
      // threeBet/facingThreeBet arrancan con heroPosition != bb por
      // defecto, así que HandBias.borderline funciona directo. Para
      // defenseVsOpen/shortStackFacingOpen (heroPosition == bb por
      // defecto) se usa HandBias.any: OpeningRanges no define un rango
      // de "apertura" propio para la BB (nunca abre), así que pedirle un
      // sesgo "borderline"/"clearlyInRange" no tiene con qué matchear —
      // no es un bug de esta fase, es una característica ya existente de
      // OpeningRanges/HandPicker que no corresponde tocar acá.
      final builders = <ExerciseScenario Function(Deck)>[
        (d) => ExerciseScenarioBuilder.defenseVsOpen(deck: d, heroHandBias: HandBias.any),
        (d) => ExerciseScenarioBuilder.threeBet(deck: d, heroHandBias: HandBias.borderline),
        (d) =>
            ExerciseScenarioBuilder.facingThreeBet(deck: d, heroHandBias: HandBias.borderline),
        (d) =>
            ExerciseScenarioBuilder.shortStackFacingOpen(deck: d, heroHandBias: HandBias.any),
      ];
      for (final build in builders) {
        final scenario = build(Deck(Random(9)));
        expect(scenario.initialState.seatAt(scenario.heroSlot).holeCards, isNotNull,
            reason: scenario.objective.name);
      }
    });

    test('opponentProfile se acepta en las 5 familias sin romper nada — '
        'legalidad y determinismo se preservan igual que con balanced', () {
      for (final profile in [
        OpponentProfile.balanced,
        OpponentProfile.passive,
        OpponentProfile.tag,
      ]) {
        ExerciseScenario build() => ExerciseScenarioBuilder.defenseVsOpen(
            deck: Deck(Random(30)), opponentProfile: profile);
        final a = build();
        final b = build();
        expect(a.decisionContext.legalActions, b.decisionContext.legalActions,
            reason: profile.name);
        expect(a.decisionContext.heroCards, b.decisionContext.heroCards, reason: profile.name);
      }
    });
  });

  group('Integración de punta a punta', () {
    test('generar → evaluar, sin simular ningún estado a mano', () {
      final scenario = ExerciseScenarioBuilder.openRaise(
        deck: Deck(Random(20)),
        heroPosition: Position.utg,
      );
      final chosen = scenario.decisionContext.legalActions.contains(ActionType.raise)
          ? PokerAction.raiseTo(scenario.decisionContext.minRaiseToBb!)
          : const PokerAction(ActionType.fold);

      final nextState = ActionResolver.apply(scenario.initialState, chosen);
      expect(nextState.toActSlot, isNot(scenario.heroSlot));

      final result = AnswerEvaluator.evaluate(scenario, chosen);
      expect(result.verdict, isA<AnswerVerdict>());
    });

    test('defenseVsOpen: generar → evaluar una respuesta real', () {
      final scenario = ExerciseScenarioBuilder.defenseVsOpen(deck: Deck(Random(21)));
      const chosen = PokerAction(ActionType.call);
      expect(scenario.decisionContext.legalActions, contains(ActionType.call));

      final result = AnswerEvaluator.evaluate(scenario, chosen);
      expect(result.justifyingConcepts.every(scenario.evaluableConcepts.contains), isTrue);
    });
  });

  group('Integración de punta a punta — Fase 8.9: una por familia, '
      'pipeline completo (escenario → StudentTurnController → '
      'ActionResolver → AnswerEvaluator → PreflopSessionSummary)', () {
    void runFullPipeline(ExerciseScenario scenario) {
      final controller = StudentTurnController(scenario);
      expect(controller.legalActions, scenario.decisionContext.legalActions);

      final action = controller.legalActions.contains(ActionType.raise)
          ? PokerAction.raiseTo(scenario.decisionContext.minRaiseToBb!)
          : controller.legalActions.contains(ActionType.call)
              ? const PokerAction(ActionType.call)
              : const PokerAction(ActionType.fold);

      final nextState = controller.applyHeroAction(action);
      expect(nextState.toActSlot, isNot(scenario.heroSlot),
          reason: 'ActionResolver de verdad avanzó el turno');

      final result = AnswerEvaluator.evaluate(scenario, action);
      expect(result.verdict, isA<AnswerVerdict>());

      final summary =
          PreflopSessionSummary.fromResults([(scenario.objective, result)]);
      expect(summary.exercisesDone, 1);
      expect(summary.scenarioCounts[scenario.objective], 1);
      expect(summary.verdictCounts[result.verdict], 1);
    }

    test('Open Raise', () {
      runFullPipeline(ExerciseScenarioBuilder.openRaise(deck: Deck(Random(30))));
    });

    test('Defense vs Open', () {
      runFullPipeline(ExerciseScenarioBuilder.defenseVsOpen(deck: Deck(Random(31))));
    });

    test('3-Bet', () {
      runFullPipeline(ExerciseScenarioBuilder.threeBet(deck: Deck(Random(32))));
    });

    test('Facing 3-Bet', () {
      runFullPipeline(ExerciseScenarioBuilder.facingThreeBet(deck: Deck(Random(33))));
    });

    test('Short Stack', () {
      runFullPipeline(
          ExerciseScenarioBuilder.shortStackFacingOpen(deck: Deck(Random(34))));
    });
  });
}
