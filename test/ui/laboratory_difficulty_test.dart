import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/user_knowledge.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario.dart';
import 'package:poker_trainer/engine/exercises/laboratory_difficulty.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/laboratory/lab_session_controller.dart';
import 'package:poker_trainer/screens/laboratory/laboratory_screen.dart';

void main() {
  group('LabSessionController — filtrado por dificultad (controller, sin UI)', () {
    test('Fácil nunca genera una familia fuera de openRaise', () {
      final c = LabSessionController(engine: PokerTrainerEngine(seed: 50));
      addTearDown(c.dispose);
      c.startNewEngineSession(labDifficulty: LaboratoryDifficulty.easy);

      for (var i = 0; i < 20; i++) {
        c.loadNewEnginePreflopExercise(deck: Deck(Random(i)));
        expect(c.newEngineScenario!.objective, PreflopScenarioKind.openRaise,
            reason: 'intento #$i');
      }
    });

    test('Medio nunca genera threeBet ni facingThreeBet', () {
      final c = LabSessionController(engine: PokerTrainerEngine(seed: 51));
      addTearDown(c.dispose);
      c.startNewEngineSession(labDifficulty: LaboratoryDifficulty.medium);

      const forbidden = {
        PreflopScenarioKind.threeBet,
        PreflopScenarioKind.facingThreeBet,
      };
      for (var i = 0; i < 30; i++) {
        c.loadNewEnginePreflopExercise(deck: Deck(Random(100 + i)));
        expect(forbidden.contains(c.newEngineScenario!.objective), isFalse,
            reason: 'intento #$i: ${c.newEngineScenario!.objective}');
      }
    });

    test('Experto puede generar cualquiera de las 5 familias', () {
      final c = LabSessionController(engine: PokerTrainerEngine(seed: 52));
      addTearDown(c.dispose);
      c.startNewEngineSession(labDifficulty: LaboratoryDifficulty.expert);

      final seen = <PreflopScenarioKind>{};
      for (var i = 0; i < 60 && seen.length < PreflopScenarioKind.values.length; i++) {
        c.loadNewEnginePreflopExercise(deck: Deck(Random(200 + i)));
        seen.add(c.newEngineScenario!.objective);
      }
      expect(seen, PreflopScenarioKind.values.toSet());
    });

    test('sin labDifficulty ni customScenarioKinds, sigue rotando entre las '
        '6 sin restricción — comportamiento interno de startNewEngineSession, '
        'ya no expuesto por ningún botón desde que la Fase 9 eliminó el '
        'atajo de desarrollo que lo usaba', () {
      final c = LabSessionController(engine: PokerTrainerEngine(seed: 53));
      addTearDown(c.dispose);
      c.startNewEngineSession();
      expect(c.activeLabDifficulty, isNull);

      final seen = <PreflopScenarioKind>{};
      for (var i = 0; i < 60 && seen.length < PreflopScenarioKind.values.length; i++) {
        c.loadNewEnginePreflopExercise(deck: Deck(Random(300 + i)));
        seen.add(c.newEngineScenario!.objective);
      }
      expect(seen, PreflopScenarioKind.values.toSet());
    });

    test('ninguna dificultad puede exigir conceptos que UserKnowledge '
        'indique como no enseñados', () {
      final c = LabSessionController(engine: PokerTrainerEngine(seed: 54));
      addTearDown(c.dispose);
      // Usuario real sin ningún concepto enseñado todavía (a diferencia
      // del usuario sintético de práctica libre que arma el controller
      // por defecto) — ver el informe: hoy nada wirea esto solo, pero el
      // mecanismo de seguridad (`ExerciseScenarioAdapter.adapt` → null)
      // ya existe y tiene que sostenerse para cualquier dificultad.
      c.knowledge = UserKnowledge(c.engine.concepts);

      for (final difficulty in LaboratoryDifficulty.values) {
        c.startNewEngineSession(labDifficulty: difficulty);
        expect(c.currentPlayable, isNull, reason: difficulty.name);
        expect(c.isTableExercise, isFalse, reason: difficulty.name);
      }
    });

    test('"seguir practicando" mantiene la misma dificultad activa', () {
      final c = LabSessionController(
        engine: PokerTrainerEngine(seed: 55),
        sessionLength: 1,
      );
      addTearDown(c.dispose);
      c.startNewEngineSession(labDifficulty: LaboratoryDifficulty.easy);
      expect(c.activeLabDifficulty, LaboratoryDifficulty.easy);

      // Repetir la sesión (mismo patrón que usa la pantalla real desde
      // PreflopSessionSummaryView.onKeepPracticing).
      c.startNewEngineSession(
        opponentProfile: c.activeOpponentProfile,
        difficulty: c.activeDifficulty,
        labDifficulty: c.activeLabDifficulty,
      );
      expect(c.activeLabDifficulty, LaboratoryDifficulty.easy);
      expect(c.newEngineScenario!.objective, PreflopScenarioKind.openRaise);
    });

    group('exitSession — abandonar sin quedar atrapado', () {
      test('desde LabPhase.question vuelve a idle sin tocar resultados', () {
        final c = LabSessionController(engine: PokerTrainerEngine(seed: 57));
        addTearDown(c.dispose);
        c.startNewEngineSession(labDifficulty: LaboratoryDifficulty.easy);
        expect(c.phase, LabPhase.question);

        c.exitSession();
        expect(c.phase, LabPhase.idle);
        expect(c.newEngineResults, isEmpty);
        expect(c.currentPlayable, isNull);
      });

      test('desde LabPhase.feedback vuelve a idle sin descartar el intento '
          'ya registrado', () {
        final c = LabSessionController(
          engine: PokerTrainerEngine(seed: 58),
          sessionLength: 5,
        );
        addTearDown(c.dispose);
        c.startNewEngineSession(labDifficulty: LaboratoryDifficulty.easy);

        final actions = c.currentPlayable!.actions;
        final foldIndex = actions.indexWhere((a) => a.label == 'FOLD');
        c.choosePlayableAction(foldIndex);
        expect(c.phase, LabPhase.feedback);
        final resultsBefore = c.newEngineResults.length;

        c.exitSession();
        expect(c.phase, LabPhase.idle);
        expect(c.newEngineResults.length, resultsBefore,
            reason: 'el intento ya confirmado no se descarta al salir');
      });
    });
  });

  group('Navegación real de la pantalla (widgets)', () {
    testWidgets(
        'el selector muestra exactamente Fácil/Medio/Experto/Custom — Modo '
        'Clásico ya no existe (Fase 9, garantía negativa contra que vuelva '
        'una quinta modalidad escondida)', (tester) async {
      final controller = LabSessionController(engine: PokerTrainerEngine(seed: 60));
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LaboratoryScreen(controller: controller)),
      ));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.labChooseTitle), findsOneWidget);
      for (final d in LaboratoryDifficulty.values) {
        expect(find.text(d.label), findsOneWidget, reason: d.name);
      }
      expect(find.text(AppStrings.labCustomLabel), findsOneWidget);

      // Garantía negativa: ningún rastro textual de Modo Clásico.
      expect(find.textContaining('CLÁSICO', findRichText: true), findsNothing);
      expect(find.textContaining('CLASSIC', findRichText: true), findsNothing);
      expect(find.textContaining('MOTOR NUEVO', findRichText: true), findsNothing);
    });

    testWidgets('tocar FÁCIL arranca una sesión ya acotada a esa dificultad',
        (tester) async {
      final controller = LabSessionController(engine: PokerTrainerEngine(seed: 61));
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LaboratoryScreen(controller: controller)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LaboratoryDifficulty.easy.label));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.phase, LabPhase.question);
      expect(controller.activeLabDifficulty, LaboratoryDifficulty.easy);
      expect(controller.newEngineScenario!.objective, PreflopScenarioKind.openRaise);
    });

    testWidgets('el botón de salir vuelve al selector sin terminar la sesión',
        (tester) async {
      final controller = LabSessionController(
        engine: PokerTrainerEngine(seed: 62),
        sessionLength: 5,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LaboratoryScreen(controller: controller)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LaboratoryDifficulty.medium.label));
      await tester.pumpAndSettle();
      expect(controller.phase, LabPhase.question);

      expect(find.byTooltip(AppStrings.labExitTooltip), findsOneWidget);
      await tester.tap(find.byTooltip(AppStrings.labExitTooltip));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.phase, LabPhase.idle);
      // De vuelta en el selector, no en una pantalla inesperada.
      expect(find.text(AppStrings.labChooseTitle), findsOneWidget);
    });

    testWidgets(
        'flujo real completo: FÁCIL → ejercicio → respuesta → feedback → '
        'summary → volver al selector (Fase 9: reemplaza al test del '
        'camino viejo, ahora con el único motor que queda)',
        (tester) async {
      final controller = LabSessionController(
        engine: PokerTrainerEngine(seed: 63),
        sessionLength: 1,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LaboratoryScreen(controller: controller)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LaboratoryDifficulty.easy.label));
      await tester.pumpAndSettle();
      expect(controller.phase, LabPhase.question);

      final actions = controller.currentPlayable!.actions;
      final foldIndex = actions.indexWhere((a) => a.label == 'FOLD');
      controller.choosePlayableAction(foldIndex >= 0 ? foldIndex : 0);
      await tester.pumpAndSettle();
      expect(controller.phase, LabPhase.feedback);

      controller.advancePlayable();
      await tester.pumpAndSettle();

      expect(controller.phase, LabPhase.summary);
      await tester.ensureVisible(find.text(AppStrings.labBackToLab));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.labBackToLab));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.phase, LabPhase.idle);
      expect(find.text(AppStrings.labChooseTitle), findsOneWidget);
    });
  });
}
