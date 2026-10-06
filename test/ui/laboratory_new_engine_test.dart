import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/user_concept_mastery.dart';
import 'package:poker_trainer/engine/exercises/laboratory_difficulty.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/legal_action_engine.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/laboratory/lab_session_controller.dart';
import 'package:poker_trainer/screens/laboratory/laboratory_screen.dart';

/// Fase 6/6.5: el motor nuevo (`ExerciseScenarioBuilder` →
/// `ExerciseScenarioAdapter`) renderizado por la pantalla REAL del
/// Laboratorio — sin mocks del motor de póker ni de la mesa. Desde la
/// Fase 9 (eliminación del Modo Clásico) es el único motor que existe
/// acá — `laboratory_screen_test.dart` (camino viejo) se eliminó.
void main() {
  testWidgets(
      'un ejercicio preflop del motor nuevo se renderiza en la mesa real, '
      'muestra las acciones legales reales, y responder da feedback sin '
      'ninguna excepción', (tester) async {
    final controller = LabSessionController(
      engine: PokerTrainerEngine(seed: 1),
      sessionLength: 3,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LaboratoryScreen(controller: controller)),
    ));
    await tester.pumpAndSettle();

    // Todavía el camino viejo (idle) — confirmamos que arrancar el motor
    // nuevo no depende de tocar "EMPEZAR A PRACTICAR".
    expect(controller.isTableExercise, isFalse);

    controller.loadNewEnginePreflopExercise(deck: Deck(Random(3)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.isTableExercise, isTrue);
    final exercise = controller.currentPlayable!;

    // La mesa real (PokerTableView, vía PlayableTableExerciseView) está
    // en pantalla, y muestra exactamente las acciones legales reales —
    // ninguna más, ninguna menos.
    for (final action in exercise.actions) {
      expect(find.text(action.label), findsOneWidget, reason: action.label);
    }

    // FOLD siempre está entre las legales de un open-raise y nunca
    // necesita elegir tamaño — el camino más simple para probar el tap
    // real sin depender del paso de sizing.
    final foldChoice = exercise.actions.firstWhere((a) => a.label == 'FOLD');
    expect(foldChoice.needsSizing, isFalse);

    await tester.tap(find.text('FOLD'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.lastPlayableFeedback, isNotNull);
    expect(controller.phase, LabPhase.feedback);
    // El feedback mostrado (la devolución estructurada de Laboratorio,
    // ver `LabFeedbackBuilder`) es exactamente el que ya se había
    // calificado con AnswerEvaluator al armar la mesa — no se re-evalúa
    // nada acá.
    expect(foldChoice.richFeedback, isNotNull);
    expect(find.textContaining(foldChoice.richFeedback!.whyText), findsWidgets);
  });

  testWidgets(
      'la corrección aparece después de CADA ejercicio, no solo el '
      'primero (regresión real: el paso de explicación de un ejercicio '
      'dejaba "pegado" el siguiente en texto genérico)', (tester) async {
    final controller = LabSessionController(
      engine: PokerTrainerEngine(seed: 20),
      sessionLength: 3,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LaboratoryScreen(controller: controller)),
    ));
    await tester.pumpAndSettle();
    controller.loadNewEnginePreflopExercise(deck: Deck(Random(21)));
    await tester.pumpAndSettle();

    Future<void> resolveAndCheckFeedback() async {
      final exercise = controller.currentPlayable!;
      final foldChoice = exercise.actions.firstWhere((a) => a.label == 'FOLD',
          orElse: () => exercise.actions.first);
      await tester.tap(find.text(foldChoice.label));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.phase, LabPhase.feedback);
      final rich = foldChoice.richFeedback;
      expect(rich, isNotNull);
      // La devolución real (POR QUÉ real del ejercicio) tiene que estar
      // en pantalla — nunca reemplazada por el texto genérico fijo
      // "Conceptos en juego acá: …" del paso de explicación de un
      // ejercicio anterior.
      expect(find.textContaining(rich!.whyText), findsWidgets);
    }

    // Ejercicio 1: responde y confirma la devolución real.
    await resolveAndCheckFeedback();

    // Avanza un paso más (el paso de explicación de ESTE ejercicio, con
    // "CONTINUAR") y recién con el siguiente tap ("SIGUIENTE") pasa al
    // ejercicio 2 — exactamente el camino real que exponía el bug (el
    // `_explainIndex` quedaba pegado en 1 para el ejercicio siguiente).
    await tester.tap(find.text(AppStrings.academyContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.academyNext));
    await tester.pumpAndSettle();
    expect(controller.phase, LabPhase.question);

    // Ejercicio 2: la devolución real tiene que volver a aparecer — antes
    // de la corrección, acá se veía el texto genérico "Conceptos en
    // juego…" en su lugar.
    await resolveAndCheckFeedback();
  });

  testWidgets(
      'Test 1 — tocar una dificultad real arranca el (único) motor nuevo',
      (tester) async {
    final controller = LabSessionController(
      engine: PokerTrainerEngine(seed: 2),
      sessionLength: 3,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LaboratoryScreen(controller: controller)),
    ));
    await tester.pumpAndSettle();

    for (final d in LaboratoryDifficulty.values) {
      expect(find.text(d.label), findsOneWidget, reason: d.name);
    }

    await tester.tap(find.text(LaboratoryDifficulty.expert.label));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.isTableExercise, isTrue);
    expect(controller.newEngineScenario, isNotNull);
    expect(controller.isNewEngineSession, isTrue);
  });

  testWidgets(
      'Test 3 — las acciones mostradas son exactamente las legales de '
      'LegalActionEngine, ni una más ni una menos', (tester) async {
    final controller = LabSessionController(engine: PokerTrainerEngine(seed: 3));
    addTearDown(controller.dispose);
    controller.loadNewEnginePreflopExercise(deck: Deck(Random(9)));

    final shown = controller.currentPlayable!.actions.map((a) => a.action).toSet();
    final legal = LegalActionEngine.legalActionTypes(controller.newEngineGameState!);
    expect(shown, legal);
  });

  testWidgets(
      'Test 7/8 — "siguiente" genera un escenario nuevo de verdad, no la '
      'misma instancia', (tester) async {
    final controller = LabSessionController(engine: PokerTrainerEngine(seed: 4));
    addTearDown(controller.dispose);

    controller.loadNewEnginePreflopExercise(deck: Deck(Random(11)));
    final firstScenario = controller.newEngineScenario;
    expect(firstScenario, isNotNull);

    // Resuelve con FOLD si está (nunca necesita tamaño) o, si no está
    // entre las legales de esta familia (p. ej. cbetDecision, solo
    // check/bet), con la primera acción — para llegar a "feedback"
    // cualquier acción legal alcanza.
    final foldIndex =
        controller.currentPlayable!.actions.indexWhere((a) => a.label == 'FOLD');
    controller.choosePlayableAction(foldIndex >= 0 ? foldIndex : 0);
    expect(controller.phase, LabPhase.feedback);

    controller.advancePlayable();

    expect(controller.phase, LabPhase.question);
    expect(controller.isTableExercise, isTrue);
    final secondScenario = controller.newEngineScenario;
    expect(secondScenario, isNotNull);
    expect(secondScenario, isNot(same(firstScenario)),
        reason: 'tiene que ser una instancia de ExerciseScenario nueva, no '
            'la reutilizada');
  });

  testWidgets(
      'Test 6 — el feedback nunca menciona un concepto que el usuario no '
      'tiene enseñado', (tester) async {
    final controller = LabSessionController(engine: PokerTrainerEngine(seed: 5));
    addTearDown(controller.dispose);
    // El usuario de Laboratorio (engine.newUser()) tiene cada concepto ya
    // enseñado; acá lo vaciamos a propósito para forzar el caso límite.
    for (final id in controller.knowledge.taughtConcepts.toList()) {
      controller.knowledge.setState(id, MasteryState.locked);
    }

    controller.loadNewEnginePreflopExercise(deck: Deck(Random(13)));
    // Sin ningún concepto enseñado, ExerciseScenarioAdapter.adapt debe
    // haber devuelto null — no hay ejercicio de mesa que mostrar.
    expect(controller.isTableExercise, isFalse);
  });

  testWidgets(
      'Fase 8.6 — resolver una decisión real escribe en UserKnowledge '
      '(recordAttempt), y acumula en newEngineSummary', (tester) async {
    final controller = LabSessionController(engine: PokerTrainerEngine(seed: 6));
    addTearDown(controller.dispose);

    controller.loadNewEnginePreflopExercise(deck: Deck(Random(15)));
    final scenario = controller.newEngineScenario!;
    final taughtConcepts = scenario.evaluableConcepts
        .where(controller.knowledge.taughtConcepts.contains)
        .toList();
    expect(taughtConcepts, isNotEmpty,
        reason: 'el usuario de Laboratorio tiene todo lo de Academia '
            'enseñado — tiene que haber al menos uno');

    final attemptsBefore = {
      for (final id in taughtConcepts) id: controller.knowledge.masteryOf(id).attempts,
    };
    expect(controller.newEngineResults, isEmpty);

    final foldIndex =
        controller.currentPlayable!.actions.indexWhere((a) => a.label == 'FOLD');
    controller.choosePlayableAction(foldIndex >= 0 ? foldIndex : 0);

    for (final id in taughtConcepts) {
      expect(controller.knowledge.masteryOf(id).attempts, attemptsBefore[id]! + 1,
          reason: 'concepto "$id" tendría que sumar un intento más');
    }

    expect(controller.newEngineResults, hasLength(1));
    expect(controller.newEngineResults.single.$1, scenario.objective);
    expect(controller.newEngineSummary.exercisesDone, 1);
  });

  testWidgets(
      'Fase 8.6 — el sistema viejo (Academia/engine.newUser inicial) no se '
      've afectado por escribir en el motor nuevo', (tester) async {
    final untouched = PokerTrainerEngine(seed: 7).newAcademyUser();
    final controller = LabSessionController(engine: PokerTrainerEngine(seed: 7));
    addTearDown(controller.dispose);

    controller.loadNewEnginePreflopExercise(deck: Deck(Random(16)));
    final foldIndex =
        controller.currentPlayable!.actions.indexWhere((a) => a.label == 'FOLD');
    controller.choosePlayableAction(foldIndex >= 0 ? foldIndex : 0);

    // Un UserKnowledge en blanco de otra sesión (como la Academia arranca)
    // nunca se ve tocado por lo que le pasa a controller.knowledge.
    expect(untouched.taughtConcepts, isEmpty);
  });
}
