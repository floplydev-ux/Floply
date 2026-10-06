import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/strategy/hand_range.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/tools/range/range_practice_view.dart';

/// Replica exacta de `_pickNotation` (mismo algoritmo, mismo seed) para
/// saber de antemano qué mano va a mostrar el widget sin depender de la
/// UI para descubrirlo.
String _expectedFirstNotation(int seed) {
  final classes = HandClass.all();
  return classes[Random(seed).nextInt(classes.length)].notation;
}

Widget _harness(HandRange range, {int seed = 7, void Function(String, {required bool correct})? onConceptPracticed}) {
  return MaterialApp(
    home: Scaffold(
      body: RangePracticeView(
        range: range,
        random: Random(seed),
        onConceptPracticed: onConceptPracticed,
      ),
    ),
  );
}

void main() {
  test('isPracticeAnswerCorrect: 100% solo acepta Raise', () {
    expect(isPracticeAnswerCorrect(frequency: 1.0, answeredRaise: true), isTrue);
    expect(isPracticeAnswerCorrect(frequency: 1.0, answeredRaise: false), isFalse);
  });

  test('isPracticeAnswerCorrect: 0% solo acepta Fold', () {
    expect(isPracticeAnswerCorrect(frequency: 0.0, answeredRaise: false), isTrue);
    expect(isPracticeAnswerCorrect(frequency: 0.0, answeredRaise: true), isFalse);
  });

  test('isPracticeAnswerCorrect: frecuencia mixta acepta cualquier respuesta', () {
    expect(isPracticeAnswerCorrect(frequency: 0.5, answeredRaise: true), isTrue);
    expect(isPracticeAnswerCorrect(frequency: 0.5, answeredRaise: false), isTrue);
  });

  testWidgets('responder RAISE a una mano que está 100% en el rango marca acierto',
      (tester) async {
    const seed = 7;
    final notation = _expectedFirstNotation(seed);
    final range = HandRange.parse(['$notation(1.0)']);

    await tester.pumpWidget(_harness(range, seed: seed));
    await tester.pumpAndSettle();

    expect(find.text(notation), findsOneWidget);

    await tester.tap(find.text(AppStrings.rangesPracticeRaise));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rangesPracticeCorrect), findsOneWidget);
    expect(find.text('${AppStrings.rangesPracticeScore}: 1/1'), findsOneWidget);
  });

  testWidgets('responder RAISE a una mano que no está en el rango marca error',
      (tester) async {
    const seed = 7;
    final notation = _expectedFirstNotation(seed);
    // Un rango que explícitamente NO incluye la mano que va a salir.
    final range = HandRange(
      Map.fromEntries(
        HandClass.all().where((c) => c.notation != notation).map((c) => MapEntry(c.notation, 1.0)),
      ),
    );

    await tester.pumpWidget(_harness(range, seed: seed));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.rangesPracticeRaise));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rangesPracticeIncorrect), findsOneWidget);
  });

  testWidgets('"Siguiente mano" limpia la respuesta y deja elegir de nuevo',
      (tester) async {
    const seed = 7;
    final notation = _expectedFirstNotation(seed);
    final range = HandRange.parse(['$notation(1.0)']);

    await tester.pumpWidget(_harness(range, seed: seed));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.rangesPracticeRaise));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.rangesPracticeNext));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.rangesPracticeRaise), findsOneWidget);
    expect(find.text(AppStrings.rangesPracticeFold), findsOneWidget);
  });

  testWidgets('notifica el resultado vía onConceptPracticed', (tester) async {
    const seed = 7;
    final notation = _expectedFirstNotation(seed);
    final range = HandRange.parse(['$notation(1.0)']);

    String? notifiedConcept;
    bool? notifiedCorrect;
    await tester.pumpWidget(_harness(
      range,
      seed: seed,
      onConceptPracticed: (id, {required correct}) {
        notifiedConcept = id;
        notifiedCorrect = correct;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.rangesPracticeRaise));
    await tester.pumpAndSettle();

    expect(notifiedConcept, 'openingRange');
    expect(notifiedCorrect, isTrue);
  });
}
