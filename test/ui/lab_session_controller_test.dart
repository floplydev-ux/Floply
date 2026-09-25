import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/difficulty_level.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/legal_action_engine.dart';
import 'package:poker_trainer/engine/poker/game/opponent_policy.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/laboratory/lab_session_controller.dart';

void main() {
  group('loadNewEnginePreflopExercise — dispatch de las 5 familias (Fase 8.1)', () {
    test('pedir cada PreflopScenarioKind explícitamente genera esa familia '
        'exacta, siempre con acciones legales reales', () {
      final c = LabSessionController(engine: PokerTrainerEngine(seed: 20));
      addTearDown(c.dispose);

      for (final kind in PreflopScenarioKind.values) {
        c.loadNewEnginePreflopExercise(deck: Deck(Random(kind.index + 1)), kind: kind);
        final scenario = c.newEngineScenario!;
        expect(scenario.objective, kind, reason: kind.name);

        final legal = LegalActionEngine.legalActionTypes(c.newEngineGameState!);
        expect(scenario.decisionContext.legalActions, legal, reason: kind.name);
      }
    });

    test('sin especificar kind, rota entre todas las familias vía '
        'Deck.pick (nunca una segunda fuente de Random)', () {
      final c = LabSessionController(engine: PokerTrainerEngine(seed: 21));
      addTearDown(c.dispose);

      final seen = <PreflopScenarioKind>{};
      for (var i = 0; i < 80 && seen.length < PreflopScenarioKind.values.length; i++) {
        c.loadNewEnginePreflopExercise(deck: Deck(Random(100 + i)));
        seen.add(c.newEngineScenario!.objective);
      }
      expect(seen, PreflopScenarioKind.values.toSet(),
          reason: 'en 80 intentos con semillas distintas deberían aparecer '
              'todas las familias');
    });
  });

  /// Resuelve el ejercicio del motor nuevo actualmente en pantalla —
  /// con FOLD si está disponible (siempre legal y nunca necesita
  /// tamaño, en las 5 familias preflop), o con la primera acción legal
  /// si no (p. ej. `cbetDecision`, que solo ofrece check/bet). A estos
  /// tests no les importa qué tan buena es la respuesta, solo que la
  /// sesión avance de fase — cualquier acción legal sirve.
  void resolveWithFold(LabSessionController c) {
    final actions = c.currentPlayable!.actions;
    final foldIndex = actions.indexWhere((a) => a.label == 'FOLD');
    c.choosePlayableAction(foldIndex >= 0 ? foldIndex : 0);
  }

  group('Fase 9.9/9.10 — fin de sesión del motor nuevo', () {
    test('startNewEngineSession + resolver sessionLength ejercicios llega '
        'a LabPhase.summary con isNewEngineSession == true', () {
      final c = LabSessionController(
        engine: PokerTrainerEngine(seed: 30),
        sessionLength: 3,
      );
      addTearDown(c.dispose);

      c.startNewEngineSession();
      expect(c.isNewEngineSession, isTrue);

      for (var i = 0; i < 3; i++) {
        expect(c.phase, LabPhase.question, reason: 'ejercicio #$i');
        resolveWithFold(c);
        expect(c.phase, LabPhase.feedback);
        c.advancePlayable();
      }

      expect(c.phase, LabPhase.summary);
      expect(c.isNewEngineSession, isTrue);
      expect(c.newEngineSummary.exercisesDone, 3);
    });

    test('startNewEngineSession tras una sesión previa completa resetea '
        'answered/newEngineResults — la sesión nueva no arranca ya '
        '"terminada"', () {
      final c = LabSessionController(
        engine: PokerTrainerEngine(seed: 31),
        sessionLength: 2,
      );
      addTearDown(c.dispose);

      c.startNewEngineSession();
      for (var i = 0; i < 2; i++) {
        resolveWithFold(c);
        c.advancePlayable();
      }
      expect(c.phase, LabPhase.summary);

      c.startNewEngineSession();
      expect(c.phase, LabPhase.question,
          reason: 'una sesión nueva arranca en question, no vuelve a summary');
      expect(c.newEngineResults, isEmpty);
      expect(c.answered, 0);
    });

    test('returnToIdle vuelve a LabPhase.idle sin tocar los datos de la '
        'sesión recién terminada', () {
      final c = LabSessionController(
        engine: PokerTrainerEngine(seed: 32),
        sessionLength: 1,
      );
      addTearDown(c.dispose);

      c.startNewEngineSession();
      resolveWithFold(c);
      c.advancePlayable();
      expect(c.phase, LabPhase.summary);

      final resultsBefore = c.newEngineResults.length;
      c.returnToIdle();
      expect(c.phase, LabPhase.idle);
      expect(c.newEngineResults.length, resultsBefore,
          reason: 'volver a idle no descarta los resultados ya registrados');
    });

    test('cruzar a LabPhase.summary no registra ningún intento extra en '
        'UserKnowledge (Fase 9.11 — el resumen es puramente lector)', () {
      final c = LabSessionController(
        engine: PokerTrainerEngine(seed: 33),
        sessionLength: 1,
      );
      addTearDown(c.dispose);

      c.startNewEngineSession();
      resolveWithFold(c);
      final conceptId = c.newEngineScenario == null
          ? null
          : c.newEngineResults.isNotEmpty
              ? c.newEngineResults.first.$2.justifyingConcepts.firstOrNull
              : null;

      final attemptsBefore = conceptId == null
          ? null
          : c.knowledge.masteryOf(conceptId).attempts;

      c.advancePlayable(); // cruza a LabPhase.summary
      expect(c.phase, LabPhase.summary);

      if (conceptId != null) {
        expect(c.knowledge.masteryOf(conceptId).attempts, attemptsBefore,
            reason: 'llegar al resumen no debería sumar otro intento');
      }
    });
  });

  group('Fase 10 — opponentProfile/difficulty en startNewEngineSession', () {
    test('sin argumentos, arranca en balanced/standard (comportamiento '
        'idéntico al de antes de Fase 10)', () {
      final c = LabSessionController(engine: PokerTrainerEngine(seed: 40));
      addTearDown(c.dispose);

      c.startNewEngineSession();
      expect(c.activeOpponentProfile, OpponentProfile.balanced);
      expect(c.activeDifficulty, DifficultyLevel.standard);
    });

    test('pasar opponentProfile/difficulty los fija para toda la sesión, '
        'y llega hasta el escenario generado', () {
      final c = LabSessionController(engine: PokerTrainerEngine(seed: 41));
      addTearDown(c.dispose);

      c.startNewEngineSession(
        opponentProfile: OpponentProfile.tag,
        difficulty: DifficultyLevel.hard,
      );
      expect(c.activeOpponentProfile, OpponentProfile.tag);
      expect(c.activeDifficulty, DifficultyLevel.hard);
      expect(c.newEngineScenario, isNotNull);

      // Sigue activo en el siguiente ejercicio de la MISMA sesión (no
      // vuelve a balanced/standard entre ejercicios).
      resolveWithFold(c);
      c.advancePlayable();
      expect(c.activeOpponentProfile, OpponentProfile.tag);
      expect(c.activeDifficulty, DifficultyLevel.hard);
    });

    test('easy/hard nunca rompen ninguna de las 5 familias — regresión: '
        'defenseVsOpen/shortStack tienen heroPosition == bb por defecto, '
        'donde HandBias distinto de any no puede satisfacerse (hallazgo '
        'real de esta fase)', () {
      final c = LabSessionController(engine: PokerTrainerEngine(seed: 44));
      addTearDown(c.dispose);

      for (final difficulty in DifficultyLevel.values) {
        for (final kind in PreflopScenarioKind.values) {
          expect(() {
            c.startNewEngineSession(difficulty: difficulty);
            c.loadNewEnginePreflopExercise(
                deck: Deck(Random(kind.index + difficulty.index * 10)), kind: kind);
          }, returnsNormally, reason: '${difficulty.name}/${kind.name}');
        }
      }
    });

    test('end-to-end: escenario → perfil real del rival → decisión del '
        'alumno → evaluación → PreflopSessionSummary, con un perfil/'
        'dificultad explícitos', () {
      final c = LabSessionController(
        engine: PokerTrainerEngine(seed: 43),
        sessionLength: 2,
      );
      addTearDown(c.dispose);

      c.startNewEngineSession(
        opponentProfile: OpponentProfile.passive,
        difficulty: DifficultyLevel.hard,
      );
      for (var i = 0; i < 2; i++) {
        expect(c.phase, LabPhase.question);
        resolveWithFold(c);
        expect(c.phase, LabPhase.feedback);
        expect(c.lastPlayableFeedback, isNotNull);
        c.advancePlayable();
      }

      expect(c.phase, LabPhase.summary);
      expect(c.isNewEngineSession, isTrue);
      final summary = c.newEngineSummary;
      expect(summary.exercisesDone, 2);
      expect(summary.bestCount + summary.acceptableCount + summary.dependentCount +
          summary.poorCount, 2);
    });
  });
}
