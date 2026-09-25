// QA de la Fase 1 + Fase 1.5 (stress test) del prototipo visual "Sala
// Verde" — NO es un test de producto (son pantallas de prueba, ver
// docs/design/FLOPLY_PROTOTYPE_PHASE_1.md y
// docs/design/FLOPLY_VISUAL_STRESS_TEST.md). Mismo espíritu que
// `test/ui/table_persistence_test.dart`: barrer varios anchos reales y no
// asumir "si no hay overflow, está responsive".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/dev/design_playground/academy_theory_prototype_preview.dart';
import 'package:poker_trainer/dev/design_playground/home_prototype_preview.dart';
import 'package:poker_trainer/dev/design_playground/laboratory_exercise_prototype_preview.dart';
import 'package:poker_trainer/dev/design_playground/proto_components.dart';
import 'package:poker_trainer/dev/design_playground/proto_tokens.dart';
import 'package:poker_trainer/dev/design_playground/tools_prototype_preview.dart';

// Fase 1.5, Prueba 5: barrido más agresivo que la Fase 1 (que solo cubría
// 320/360/390/430). Se agregan 375/414 (iPhone reales comunes) y los
// extremos 300/480 pedidos explícitamente ("si el entorno permite otros
// tamaños relevantes, incluirlos").
const _widths = [300.0, 320.0, 360.0, 375.0, 390.0, 414.0, 430.0, 480.0];

// Alturas cortas reales (iPhone SE 1ª gen = 320x568) — la Fase 1 solo
// barrió ancho a una altura fija; acá se agrega el eje vertical
// explícitamente para las pantallas con una zona de tamaño fijo (la mesa
// embebida de Laboratorio, los inputs de Tools).
const _shortHeights = [568.0, 640.0];

Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
  Widget Function() buildPreview,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: buildPreview()));
  await tester.pumpAndSettle();
}

void main() {
  group('Home — 5 casos de contenido (Fase 1.5, Prueba 3)', () {
    final cases = {
      'A. usuario nuevo': previewHomeNewUser,
      'B. mucho progreso': previewHomeHighProgress,
      'C. texto largo': previewHomeLongText,
      'D. texto corto': previewHomeShortText,
      'E. estado secundario vacío': previewHomeEmptySecondary,
    };

    for (final entry in cases.entries) {
      for (final width in _widths) {
        testWidgets('${entry.key} — ${width}x844 sin overflow', (tester) async {
          await _pumpAt(tester, Size(width, 844), entry.value);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Academia — teoría corta vs. larga (Fase 1 + Fase 1.5 Prueba 1)', () {
    final theories = {
      'T093 corta': previewAcademyTheoryPrototype,
      'TN10 larga (7 secciones)': previewAcademyTheoryLongPrototype,
    };

    for (final entry in theories.entries) {
      for (final width in _widths) {
        testWidgets('${entry.key} — ${width}x844 sin overflow', (tester) async {
          await _pumpAt(tester, Size(width, 844), entry.value);
          expect(tester.takeException(), isNull);
        });
      }
      // Altura corta: la teoría larga es la que realmente puede chocar
      // contra los botones ATRÁS/PRACTICAR si el scroll no cede espacio.
      for (final height in _shortHeights) {
        testWidgets('${entry.key} — 375x$height (altura corta) sin overflow',
            (tester) async {
          await _pumpAt(tester, Size(375, height), entry.value);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('la teoría larga realmente produce scroll (7 secciones visibles)',
        (tester) async {
      await _pumpAt(tester, const Size(390, 844), previewAcademyTheoryLongPrototype);
      expect(find.text('CUÁNDO NO'), findsOneWidget); // sección que T093 no tiene
      expect(find.text('IDEA CLAVE'), findsOneWidget);
    });
  });

  group('Tools · Pot Odds (Fase 1.5, Prueba 2)', () {
    for (final width in _widths) {
      testWidgets('${width}x844 — estado inicial válido, sin overflow', (tester) async {
        await _pumpAt(tester, Size(width, 844), previewToolsPrototype);
        expect(tester.takeException(), isNull);
      });
    }
    for (final height in _shortHeights) {
      testWidgets('375x$height (altura corta) sin overflow', (tester) async {
        await _pumpAt(tester, Size(375, height), previewToolsPrototype);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('cálculo real: pot 15 + call 5 = 25% equity necesaria (25.0)',
        (tester) async {
      await _pumpAt(tester, const Size(390, 844), previewToolsPrototype);
      // Semilla real del engine (pot 15bb, call 5bb -> finalPot 20, 25%).
      expect(find.text('25.0%'), findsOneWidget);
      expect(find.text('20.0 BB'), findsOneWidget);
      // potOddsRatio = potBeforeCallBb / callAmountBb = 15 / 5 = 3.0.
      expect(find.text('3.0:1'), findsOneWidget);
    });

    testWidgets('input inválido (negativo) muestra el error real de AppStrings',
        (tester) async {
      await _pumpAt(tester, const Size(390, 844), previewToolsPrototype);
      await tester.enterText(find.byType(TextField).first, '-5');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ingresá números válidos (0 o más).'), findsOneWidget);
    });

    testWidgets('input no numérico también resuelve a error, no crashea',
        (tester) async {
      await _pumpAt(tester, const Size(390, 844), previewToolsPrototype);
      await tester.enterText(find.byType(TextField).first, 'abc');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ingresá números válidos (0 o más).'), findsOneWidget);
    });
  });

  group('Laboratorio — estados explícitos (Fase 1.5, Prueba 4)', () {
    final states = {
      '1. antes de decidir': previewLaboratoryExercisePrototype,
      '2. eligiendo tamaño': previewLaboratoryChoosingSize,
      '3. feedback mejor jugada': previewLaboratoryFeedbackBest,
      '4. feedback aceptable': previewLaboratoryFeedbackAcceptable,
      '5. feedback no es lo mejor': previewLaboratoryFeedbackPoor,
    };

    for (final entry in states.entries) {
      for (final width in _widths) {
        testWidgets('${entry.key} — ${width}x844 sin overflow', (tester) async {
          await _pumpAt(tester, Size(width, 844), entry.value);
          expect(tester.takeException(), isNull);
        });
      }
      for (final height in _shortHeights) {
        testWidgets('${entry.key} — 375x$height (altura corta) sin overflow',
            (tester) async {
          await _pumpAt(tester, Size(375, height), entry.value);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('flujo completo: elegir ABRIR → tamaño → feedback → reset',
        (tester) async {
      await _pumpAt(tester, const Size(390, 844), previewLaboratoryExercisePrototype);

      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ELEGÍ EL TAMAÑO'), findsOneWidget);

      await tester.tap(find.text('2.5 BB'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('MEJOR JUGADA'), findsOneWidget);

      await tester.tap(find.text('SIGUIENTE EJERCICIO'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('FOLD'), findsOneWidget);
    });

    testWidgets('elegir tamaño aceptable (2 BB) resuelve ACEPTABLE', (tester) async {
      await _pumpAt(tester, const Size(390, 844), previewLaboratoryExercisePrototype);
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 BB'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ACEPTABLE'), findsOneWidget);
    });

    testWidgets('elegir FOLD resuelve directo, sin paso de tamaño', (tester) async {
      await _pumpAt(tester, const Size(390, 844), previewLaboratoryExercisePrototype);
      await tester.tap(find.text('FOLD'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('NO ES LO MEJOR'), findsOneWidget);
    });
  });

  group('Contenido extremo (Fase 1.5, Prueba 6) — componentes atómicos', () {
    Widget stage(Widget child) => MaterialApp(
          home: ColoredBox(
            color: ProtoColor.background,
            child: Padding(padding: const EdgeInsets.all(ProtoSpace.lg), child: child),
          ),
        );

    testWidgets('ProtoChipNumeric con valores límite (999 BB, 0.4%) no desborda',
        (tester) async {
      await tester.pumpWidget(stage(const Wrap(
        spacing: ProtoSpace.sm,
        runSpacing: ProtoSpace.sm,
        children: [
          ProtoChipNumeric(value: '2 BB', label: 'MIN'),
          ProtoChipNumeric(value: '12.5 BB', label: 'MEDIO'),
          ProtoChipNumeric(value: '100 BB', label: 'STACK'),
          ProtoChipNumeric(value: '999 BB', label: 'EXTREMO'),
          ProtoChipNumeric(value: '42.7%', label: 'EQUITY'),
          ProtoChipNumeric(value: '87.3%', label: 'EQUITY'),
          ProtoChipNumeric(value: '0.4%', label: 'RARA'),
        ],
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProtoButtonPrimary con label muy largo no desborda a 320dp',
        (tester) async {
      tester.view.physicalSize = const Size(320, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(stage(
        ProtoButtonPrimary(
          label: 'ESTA ES UNA ETIQUETA DE BOTÓN DELIBERADAMENTE MUY LARGA',
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProtoCalloutAccent con cuerpo muy largo hace scroll, no desborda',
        (tester) async {
      await tester.pumpWidget(stage(const SingleChildScrollView(
        child: ProtoCalloutAccent(
          eyebrow: 'ERROR COMÚN',
          body:
              'Este es un cuerpo de texto deliberadamente largo, repetido varias '
              'veces para forzar varias líneas de ancho completo y comprobar '
              'que ProtoCalloutAccent no desborda ni recorta el contenido '
              'incluso cuando el texto real de una teoría es mucho más '
              'extenso de lo habitual, algo que sí ocurre en teorías como '
              'TN10 "Implied odds" del currículo real de Academia.',
          color: ProtoColor.brassDeep,
        ),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProtoChipStatus con las 3 variantes semánticas no desborda',
        (tester) async {
      await tester.pumpWidget(stage(const Wrap(
        spacing: ProtoSpace.sm,
        children: [
          ProtoChipStatus(label: 'MEJOR JUGADA', icon: Icons.check_rounded, color: ProtoColor.success),
          ProtoChipStatus(label: 'ACEPTABLE', icon: Icons.remove_rounded, color: ProtoColor.warning),
          ProtoChipStatus(
              label: 'NO ES LO MEJOR', icon: Icons.close_rounded, color: ProtoColor.errorBright),
        ],
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
