import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario.dart';
import 'package:poker_trainer/engine/exercises/laboratory_difficulty.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/laboratory/lab_session_controller.dart';

/// Fase 8 — modo Custom del Laboratorio: el usuario elige explícitamente
/// qué familias de escenario practicar (`PreflopScenarioKind`), en vez de
/// una dificultad preconfigurada. Estos son tests de MOTOR/controller —
/// no solo de UI — según lo pedido por la fase: "selected topics →
/// generated exercise → belongs to selected topics".
void main() {
  group('Custom — aislamiento (Fase 8, Sección 44)', () {
    testWidgets('seleccionar solo openRaise nunca genera otra familia',
        (tester) async {
      final controller = LabSessionController(engine: PokerTrainerEngine(seed: 1));
      addTearDown(controller.dispose);

      for (var seed = 0; seed < 30; seed++) {
        controller.startNewEngineSession(
          customScenarioKinds: const [PreflopScenarioKind.openRaise],
        );
        controller.loadNewEnginePreflopExercise(deck: Deck(Random(seed)));
        expect(controller.newEngineScenario!.objective, PreflopScenarioKind.openRaise,
            reason: 'seed $seed');
      }
    });

    testWidgets('seleccionar solo cbetDecision nunca genera otra familia',
        (tester) async {
      final controller = LabSessionController(engine: PokerTrainerEngine(seed: 2));
      addTearDown(controller.dispose);

      for (var seed = 0; seed < 30; seed++) {
        controller.startNewEngineSession(
          customScenarioKinds: const [PreflopScenarioKind.cbetDecision],
        );
        controller.loadNewEnginePreflopExercise(deck: Deck(Random(seed)));
        expect(controller.newEngineScenario!.objective, PreflopScenarioKind.cbetDecision,
            reason: 'seed $seed — cbetDecision, hoy gateada a Experto por '
                'progresión pedagógica pero técnicamente igual de real que '
                'las otras 5; Custom la expone porque el usuario elige '
                'explícitamente qué practicar (ver auditoría Checkpoint 1)');
      }
    });
  });

  group('Custom — multi-selección (Fase 8, Sección 45)', () {
    testWidgets('A ∪ B: cada ejercicio pertenece al conjunto elegido, y '
        'con suficientes intentos aparecen las dos', (tester) async {
      final controller = LabSessionController(engine: PokerTrainerEngine(seed: 3));
      addTearDown(controller.dispose);
      const selection = [
        PreflopScenarioKind.openRaise,
        PreflopScenarioKind.threeBet,
      ];

      final seen = <PreflopScenarioKind>{};
      for (var seed = 0; seed < 40; seed++) {
        controller.startNewEngineSession(customScenarioKinds: selection);
        controller.loadNewEnginePreflopExercise(deck: Deck(Random(seed)));
        final kind = controller.newEngineScenario!.objective;
        expect(selection, contains(kind), reason: 'seed $seed: "$kind" fuera del filtro');
        seen.add(kind);
      }

      expect(seen, selection.toSet(),
          reason: 'variedad real: 40 intentos tienen que alcanzar a ver las 2 '
              'familias elegidas, no solo una');
    });
  });

  group('Custom — session length (Fase 8, Sección 46)', () {
    testWidgets('10 ejercicios: la sesión llega a summary justo después del '
        'décimo, ni antes ni después', (tester) async {
      final controller = LabSessionController(engine: PokerTrainerEngine(seed: 4));
      addTearDown(controller.dispose);

      controller.startNewEngineSession(
        customScenarioKinds: const [PreflopScenarioKind.openRaise],
        customSessionLength: 10,
      );
      expect(controller.sessionLength, 10);

      for (var i = 1; i <= 10; i++) {
        expect(controller.phase, LabPhase.question, reason: 'ejercicio $i');
        final actions = controller.currentPlayable!.actions;
        final foldIdx = actions.indexWhere((a) => a.label == 'FOLD');
        controller.choosePlayableAction(foldIdx >= 0 ? foldIdx : 0);
        expect(controller.phase, LabPhase.feedback, reason: 'feedback $i');
        controller.advancePlayable();
      }

      expect(controller.phase, LabPhase.summary);
      expect(controller.newEngineSummary.exercisesDone, 10);
    });
  });

  group('Custom — no reproduce el bug de Fase 7 (Sección 56)', () {
    testWidgets('Custom arranca una mesa jugable real del motor nuevo',
        (tester) async {
      final controller = LabSessionController(engine: PokerTrainerEngine(seed: 5));
      addTearDown(controller.dispose);

      controller.startNewEngineSession(
        customScenarioKinds: const [PreflopScenarioKind.defenseVsOpen],
      );

      expect(controller.isTableExercise, isTrue);
      expect(controller.newEngineScenario!.objective,
          PreflopScenarioKind.defenseVsOpen);
    });

    test('customScenarioKinds vacía está prohibida en tiempo de desarrollo '
        '(assert) — Deck.pick([]) repetiría el RangeError conocido', () {
      final controller = LabSessionController(engine: PokerTrainerEngine(seed: 6));
      addTearDown(controller.dispose);

      expect(
        () => controller.startNewEngineSession(customScenarioKinds: const []),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Custom — no interfiere con Fácil/Medio/Experto (regresión)', () {
    testWidgets(
        'arrancar con labDifficulty limpia una selección Custom previa',
        (tester) async {
      final controller = LabSessionController(engine: PokerTrainerEngine(seed: 7));
      addTearDown(controller.dispose);

      controller.startNewEngineSession(
        customScenarioKinds: const [PreflopScenarioKind.cbetDecision],
      );
      expect(controller.activeCustomScenarioKinds, isNotEmpty);

      controller.startNewEngineSession(labDifficulty: LaboratoryDifficulty.easy);
      expect(controller.activeCustomScenarioKinds, isNull,
          reason: 'arrancar con labDifficulty (Fácil/Medio/Experto) debe '
              'limpiar cualquier selección Custom previa — mutuamente '
              'excluyentes.');
      expect(controller.activeLabDifficulty, LaboratoryDifficulty.easy);
    });
  });
}
