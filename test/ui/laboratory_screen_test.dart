import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/laboratory/lab_session_controller.dart';
import 'package:poker_trainer/screens/laboratory/laboratory_screen.dart';

void main() {
  testWidgets('el Laboratorio arranca, muestra un ejercicio y da feedback',
      (tester) async {
    final controller = LabSessionController(
      engine: PokerTrainerEngine(seed: 1),
      sessionLength: 3,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LaboratoryScreen(controller: controller)),
    ));

    expect(find.text('EMPEZAR A PRACTICAR'), findsOneWidget);

    await tester.tap(find.text('EMPEZAR A PRACTICAR'));
    await tester.pumpAndSettle();

    // Hay un ejercicio con opciones y el botón de confirmar.
    expect(find.text('CONFIRMAR'), findsOneWidget);
    expect(controller.current, isNotNull);

    // Elegir la primera opción y confirmar.
    final firstOption = controller.current!.options.first;
    await tester.tap(find.text(firstOption.label).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRMAR'));
    await tester.pumpAndSettle();

    // Aparece feedback (no solo "Correcto"/"Incorrecto").
    expect(controller.lastResult, isNotNull);
    expect(find.text('SIGUIENTE'), findsOneWidget);
  });
}
