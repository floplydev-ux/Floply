// Fase 4 — migración de LessonFlowHeader (lib/screens/academy/widgets/
// lesson_widgets.dart) a "Sala Verde". Cubre lo que
// docs/design/FLOPLY_PHASE_4_LESSON_FLOW_HEADER.md pide como obligatorio:
// las dos variantes reales (academy/bankroll), que el acento de cada una
// sea la correcta, back real, y overflow con título/subtítulo largos en
// el barrido responsive 300-480dp.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/screens/academy/widgets/lesson_widgets.dart';
import 'package:poker_trainer/theme/sala_verde/sala_verde_tokens.dart';

const _widths = [300.0, 320.0, 360.0, 375.0, 390.0, 412.0, 414.0, 430.0, 480.0];

Widget _stage(Widget child, {double width = 390}) => MaterialApp(
      home: ColoredBox(
        color: SalaVerdeColors.background,
        child: SizedBox(
          width: width,
          child: Padding(padding: const EdgeInsets.all(SalaVerdeSpace.lg), child: child),
        ),
      ),
    );

void main() {
  group('LessonFlowHeader — variantes', () {
    testWidgets('variant academy es la default (sin cambios en el call site de Academia)',
        (tester) async {
      await tester.pumpWidget(_stage(LessonFlowHeader(
        title: '4.5  Set',
        subtitle: 'Teoría',
        onBack: () {},
      )));
      final header = tester.widget<LessonFlowHeader>(find.byType(LessonFlowHeader));
      expect(header.variant, LessonFlowHeaderVariant.academy);
      expect(LessonFlowHeaderVariant.academy.accent, SalaVerdeColors.feltGreenBright);
    });

    testWidgets('variant bankroll es explícita y usa brassBright (no brassDeep)',
        (tester) async {
      await tester.pumpWidget(_stage(LessonFlowHeader(
        title: 'BANKROLL',
        subtitle: 'Módulo complementario',
        onBack: () {},
        variant: LessonFlowHeaderVariant.bankroll,
      )));
      expect(LessonFlowHeaderVariant.bankroll.accent, SalaVerdeColors.brassBright);
      // brassDeep es solo para texto sobre superficie clara (surfaceReading);
      // el header vive sobre `background` oscuro.
      expect(LessonFlowHeaderVariant.bankroll.accent, isNot(SalaVerdeColors.brassDeep));
    });

    testWidgets('back real dispara el callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_stage(LessonFlowHeader(
        title: 'T',
        subtitle: 'S',
        onBack: () => tapped = true,
      )));
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('LessonFlowHeader — responsive 300-480dp', () {
    for (final width in _widths) {
      for (final variant in LessonFlowHeaderVariant.values) {
        testWidgets('$width dp, variant ${variant.name} — sin overflow con título largo',
            (tester) async {
          await tester.pumpWidget(_stage(
            LessonFlowHeader(
              title: '6.5  Implied odds y la corrección a las pot odds por cartas futuras',
              subtitle: 'Recuperación de una lección interrumpida',
              onBack: () {},
              variant: variant,
            ),
            width: width,
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
