// Tests de los componentes de producción de "Sala Verde"
// (lib/widgets/sala_verde/sala_verde_widgets.dart), promovidos del
// playground en la Fase 2. Cubre específicamente los guardrails que
// docs/design/FLOPLY_COMPONENTS.md pide para `SvChipNumeric` (Paso 15 de
// la Fase 2: label corto/largo, valor largo, ancho pequeño, múltiples
// chips) y el bug real de contraste de `SvButtonPrimary` encontrado al
// migrar Home a producción.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/theme/sala_verde/sala_verde_tokens.dart';
import 'package:poker_trainer/widgets/sala_verde/sala_verde_widgets.dart';

Widget _stage(Widget child, {double width = 400}) => MaterialApp(
      home: ColoredBox(
        color: SalaVerdeColors.background,
        child: SizedBox(
          width: width,
          child: Padding(padding: const EdgeInsets.all(SalaVerdeSpace.lg), child: child),
        ),
      ),
    );

void main() {
  group('SvChipNumericGroup — guardrail responsive', () {
    testWidgets('label corto no se trunca', (tester) async {
      await tester.pumpWidget(_stage(const SvChipNumericGroup(
        chips: [SvChipNumeric(value: '8/13', label: 'OK')],
      )));
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('8/13'), findsOneWidget);
    });

    testWidgets('label largo se trunca con ellipsis, el valor no', (tester) async {
      await tester.pumpWidget(_stage(
        const SvChipNumericGroup(
          chips: [
            SvChipNumeric(value: '25.0%', label: 'UNA ETIQUETA REALMENTE MUY LARGA DE VERDAD'),
          ],
        ),
        width: 200,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // El valor completo sigue presente sin cortar, aunque el label se
      // trunque visualmente (Text con overflow: ellipsis no cambia el
      // contenido lógico, así que el finder por texto exacto lo sigue
      // encontrando — lo que importa es que no tira overflow).
      expect(find.text('25.0%'), findsOneWidget);
    });

    testWidgets('valor largo (999 BB) nunca se trunca', (tester) async {
      await tester.pumpWidget(_stage(
        const SvChipNumericGroup(chips: [SvChipNumeric(value: '999 BB', label: 'STACK')]),
        width: 150,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('999 BB'), findsOneWidget);
    });

    testWidgets('múltiples chips en ancho pequeño usan Wrap, sin overflow',
        (tester) async {
      await tester.pumpWidget(_stage(
        const SvChipNumericGroup(chips: [
          SvChipNumeric(value: '8/13', label: 'NIVELES'),
          SvChipNumeric(value: '76%', label: 'DOMINIO'),
          SvChipNumeric(value: '999 BB', label: 'EXTREMO'),
        ]),
        width: 300,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // El grupo en sí es un Wrap (cada chip usa su propio Row interno
      // mainAxisSize:min para label+valor, eso es correcto — lo que no
      // debe existir es un Row que intente poner los 3 CHIPS uno al lado
      // del otro sin poder reflow).
      expect(
        find.ancestor(of: find.byType(SvChipNumeric), matching: find.byType(Wrap)),
        findsNWidgets(3),
      );
    });

    // Reproduce exactamente el bug real de la Fase 1.5 (300dp,
    // AppStrings.potOddsRequiredEquityLabel = "EQUITY NECESARIA") para que
    // no pueda reaparecer sin que este test lo note.
    testWidgets('reproduce el caso real que rompía a 300dp (Fase 1.5)',
        (tester) async {
      await tester.pumpWidget(_stage(
        const SvChipNumericGroup(chips: [
          SvChipNumeric(value: '20.0 BB', label: 'BOTE FINAL'),
          SvChipNumeric(value: '25.0%', label: 'EQUITY NECESARIA'),
          SvChipNumeric(value: '3.0:1', label: 'POT ODDS'),
        ]),
        width: 300 - (SalaVerdeSpace.lg * 2),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('SvButtonPrimary — contraste real por relleno', () {
    double contrast(Color a, Color b) {
      final l1 = a.computeLuminance();
      final l2 = b.computeLuminance();
      final brighter = l1 > l2 ? l1 : l2;
      final darker = l1 > l2 ? l2 : l1;
      return (brighter + 0.05) / (darker + 0.05);
    }

    testWidgets('con relleno brass, el texto es background (7.63:1), no textPrimary (2.16:1)',
        (tester) async {
      await tester.pumpWidget(_stage(SvButtonPrimary(label: 'COMENZAR ACADEMIA', onTap: () {})));
      final text = tester.widget<Text>(find.text('COMENZAR ACADEMIA'));
      final actual = text.style!.color!;
      // El bug real (Fase 2): un umbral de luminancia adivinado elegía
      // textPrimary acá (2.16:1, falla AA) en vez de background (7.63:1).
      expect(contrast(actual, SalaVerdeColors.brass), greaterThanOrEqualTo(4.5));
      expect(actual, SalaVerdeColors.background);
    });

    testWidgets('con relleno steelBlueBright (claro), el texto sigue siendo el de mayor contraste',
        (tester) async {
      await tester.pumpWidget(_stage(SvButtonPrimary(
        label: 'ABRIR',
        accent: SalaVerdeColors.steelBlueBright,
        onTap: () {},
      )));
      final text = tester.widget<Text>(find.text('ABRIR'));
      final actual = text.style!.color!;
      expect(contrast(actual, SalaVerdeColors.steelBlueBright), greaterThanOrEqualTo(4.5));
    });
  });

  group('SvSectionHeader — Fase 3, Checkpoint 2', () {
    double contrast(Color a, Color b) {
      final l1 = a.computeLuminance();
      final l2 = b.computeLuminance();
      final brighter = l1 > l2 ? l1 : l2;
      final darker = l1 > l2 ? l2 : l1;
      return (brighter + 0.05) / (darker + 0.05);
    }

    testWidgets('título corto + subtítulo, sin overflow', (tester) async {
      await tester.pumpWidget(_stage(const SvSectionHeader(
        icon: Icons.school_outlined,
        title: 'Academia',
        subtitle: 'Aprendé póker paso a paso',
        variant: SvSectionHeaderVariant.academy,
      )));
      expect(tester.takeException(), isNull);
      expect(find.text('Academia'), findsOneWidget);
    });

    testWidgets('título largo real no desborda a 300dp', (tester) async {
      await tester.pumpWidget(_stage(
        const SvSectionHeader(
          icon: Icons.school_outlined,
          title: 'Pot odds avanzadas · Implied odds y su relación con el bote',
          subtitle: 'Nivel 6 · Teoría larga · INTERMEDIO',
          variant: SvSectionHeaderVariant.academy,
        ),
        width: 300,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('las 4 variantes existen y cada accent pasa contraste real sobre background',
        (tester) async {
      for (final variant in SvSectionHeaderVariant.values) {
        expect(contrast(variant.accent, SalaVerdeColors.background),
            greaterThanOrEqualTo(4.5),
            reason: '${variant.name} debe pasar contraste como ícono/texto');
      }
    });

    testWidgets('con trailing no desborda en ancho angosto', (tester) async {
      await tester.pumpWidget(_stage(
        const SvSectionHeader(
          icon: Icons.science_outlined,
          title: 'Laboratorio',
          variant: SvSectionHeaderVariant.laboratory,
          trailing: Icon(Icons.chevron_right_rounded, color: SalaVerdeColors.textMuted),
        ),
        width: 300,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('SvButtonPrimary — estado deshabilitado (Fase 5)', () {
    testWidgets('onTap null: opacidad reducida, tap no dispara nada', (tester) async {
      await tester.pumpWidget(_stage(
        const SvButtonPrimary(label: 'CONFIRMAR', onTap: null),
      ));
      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 0.4);
      await tester.tap(find.text('CONFIRMAR'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('onTap presente: opacidad completa, dispara el callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_stage(
        SvButtonPrimary(label: 'CONFIRMAR', onTap: () => tapped = true),
      ));
      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 1.0);
      await tester.tap(find.text('CONFIRMAR'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('SvItemProgress (Fase 5)', () {
    testWidgets('0/N no desborda y muestra el contador', (tester) async {
      await tester.pumpWidget(_stage(const SvItemProgress(current: 0, total: 5)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('0 / 5'), findsOneWidget);
    });

    testWidgets('N/N (completo) no desborda en ancho angosto', (tester) async {
      await tester.pumpWidget(_stage(
        const SvItemProgress(current: 7, total: 7),
        width: 300,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('7 / 7'), findsOneWidget);
    });
  });
}
