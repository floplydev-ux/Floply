import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/laboratory_difficulty.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/laboratory/lab_session_controller.dart';
import 'package:poker_trainer/screens/laboratory/laboratory_screen.dart';

/// Fase 9: el resumen de sesión del motor nuevo (`PreflopSessionSummaryView`),
/// renderizado por la pantalla real del Laboratorio — sin mocks. Desde
/// que la Fase 9 eliminó el Modo Clásico, es el único resumen que existe.
void main() {
  /// Arranca una sesión del motor nuevo (tap real en EXPERTO — cualquier
  /// dificultad real sirve; se usa Experto porque no restringe familias,
  /// mismo alcance que tenía el botón de desarrollo eliminado en Fase 9)
  /// y la resuelve entera con FOLD (siempre legal, nunca necesita tamaño
  /// en las 5 familias preflop) o, si no está entre las legales (p. ej.
  /// `cbetDecision`, solo check/bet), con la primera acción — hasta
  /// llegar a `LabPhase.summary`. Resuelve cada ejercicio vía los mismos
  /// métodos de controller que usa `PlayableTableExerciseView`
  /// internamente (`choosePlayableAction`/`advancePlayable`) — mismo
  /// patrón ya probado en `laboratory_new_engine_test.dart` — en vez de
  /// perseguir la cadena de botones "CONTINUAR"/"SIGUIENTE"/"VER
  /// RESULTADO" del paso de explicación compartido con Academia, que es
  /// código genérico ajeno al alcance de Fase 9.
  Future<LabSessionController> playFullSession(
    WidgetTester tester, {
    int sessionLength = 3,
  }) async {
    final controller = LabSessionController(sessionLength: sessionLength);
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LaboratoryScreen(controller: controller)),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(LaboratoryDifficulty.expert.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LaboratoryDifficulty.expert.label));
    await tester.pumpAndSettle();

    for (var i = 0; i < sessionLength; i++) {
      expect(controller.phase, LabPhase.question, reason: 'ejercicio #$i');
      final actions = controller.currentPlayable!.actions;
      final foldIndex = actions.indexWhere((a) => a.label == 'FOLD');
      controller.choosePlayableAction(foldIndex >= 0 ? foldIndex : 0);
      controller.advancePlayable();
      await tester.pumpAndSettle();
    }

    expect(controller.phase, LabPhase.summary);
    return controller;
  }

  testWidgets(
      'una sesión completa del motor nuevo termina mostrando '
      'PreflopSessionSummaryView, no el resumen viejo', (tester) async {
    final controller = await playFullSession(tester);

    expect(controller.isNewEngineSession, isTrue);
    expect(tester.takeException(), isNull);
    // Título de sección exclusivo del resumen nuevo.
    expect(find.text(AppStrings.labQualityHeader), findsOneWidget);
    // El resumen viejo (dominio por concepto) no debería aparecer acá.
    expect(find.text('DOMINIO POR CONCEPTO'), findsNothing);
  });

  testWidgets(
      'los conteos mostrados coinciden exactamente con newEngineSummary',
      (tester) async {
    final controller = await playFullSession(tester, sessionLength: 3);
    final summary = controller.newEngineSummary;
    expect(summary.exercisesDone, 3);

    // Cada conteo real (los que sean > 0) aparece como texto en pantalla.
    for (final count in [
      summary.bestCount,
      summary.acceptableCount,
      summary.dependentCount,
      summary.poorCount,
    ]) {
      if (count > 0) {
        expect(find.text('$count'), findsWidgets, reason: 'conteo $count visible');
      }
    }
  });

  testWidgets('conceptos practicados se muestran con su nombre real',
      (tester) async {
    final controller = await playFullSession(tester);
    final summary = controller.newEngineSummary;
    expect(summary.conceptsWorked, isNotEmpty);

    expect(find.text(AppStrings.labPracticedHeader), findsOneWidget);
    for (final id in summary.conceptsWorked) {
      expect(find.text(controller.conceptName(id)), findsWidgets, reason: id);
    }
  });

  testWidgets('"SEGUIR PRACTICANDO" arranca una sesión nueva de verdad',
      (tester) async {
    final controller = await playFullSession(tester, sessionLength: 2);
    final exercisesDoneBefore = controller.newEngineSummary.exercisesDone;
    expect(exercisesDoneBefore, 2);

    await tester.ensureVisible(find.text(AppStrings.labKeepPracticing));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.labKeepPracticing));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.phase, LabPhase.question);
    expect(controller.newEngineResults, isEmpty,
        reason: 'la sesión nueva no debería arrastrar resultados de la anterior');
  });

  testWidgets('"VOLVER AL LABORATORIO" vuelve a idle', (tester) async {
    final controller = await playFullSession(tester, sessionLength: 1);

    await tester.ensureVisible(find.text(AppStrings.labBackToLab));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.labBackToLab));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.phase, LabPhase.idle);
    // De vuelta en el selector real (Fase 9: ya no hay botones de Modo
    // Clásico a los que volver).
    expect(find.text(AppStrings.labChooseTitle), findsOneWidget);
  });

  group('QA visual (Fase 9.15) — mismo patrón multi-ancho que '
      'visual_theory_pilot_test.dart', () {
    for (final size in [
      (width: 320.0, height: 640.0),
      (width: 390.0, height: 844.0),
      (width: 430.0, height: 932.0),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()} — resumen '
          'del motor nuevo sin overflow', (tester) async {
        tester.view.physicalSize = Size(size.width * 3, size.height * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await playFullSession(tester, sessionLength: 4);

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.labKeepPracticing), findsOneWidget);
        expect(find.text(AppStrings.labBackToLab), findsOneWidget);
      });
    }
  });
}
