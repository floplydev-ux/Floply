// Fase 4 — migración visual de Bankroll a "Sala Verde", sobre la pantalla
// de PRODUCCIÓN real (BankrollScreen), mismo criterio que
// test/ui/academy_visual_migration_test.dart para Academia: responsive
// 300-480dp + altura reducida, navegación real ATRÁS/CONTINUAR/VER
// RESULTADO, contenido real de los 7 temas, y la pantalla final.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/bankroll/bankroll_topic.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/bankroll/bankroll_screen.dart';

const _widths = [300.0, 320.0, 360.0, 375.0, 390.0, 412.0, 414.0, 430.0, 480.0];

Future<void> _pumpBankrollAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: BankrollScreen()));
  await tester.pumpAndSettle();
}

void main() {
  group('Bankroll — responsive 300-480dp + altura reducida (Fase 4)', () {
    for (final width in _widths) {
      testWidgets('$width dp — sin overflow, primer tema visible', (tester) async {
        await _pumpBankrollAt(tester, Size(width, 844));
        expect(tester.takeException(), isNull);
        expect(find.text(BankrollTopics.all.first.titulo), findsOneWidget);
      });
    }

    testWidgets('375x568 (altura corta) — sin overflow', (tester) async {
      await _pumpBankrollAt(tester, const Size(375, 568));
      expect(tester.takeException(), isNull);
    });
  });

  group('Bankroll — contenido real, sin color/ícono por sección (Fase 4)', () {
    testWidgets('el primer tema muestra sus secciones reales', (tester) async {
      await _pumpBankrollAt(tester, const Size(390, 844));
      expect(find.text('QUÉ ES'), findsOneWidget);
      expect(find.text('OBJETIVO'), findsOneWidget);
      // Contenido real — bankroll_topic.dart, _t1.
      expect(find.text(BankrollTopics.all.first.titulo), findsOneWidget);
    });

    testWidgets('header usa el título/subtítulo reales de Bankroll', (tester) async {
      await _pumpBankrollAt(tester, const Size(390, 844));
      expect(find.text(AppStrings.bankrollTitle), findsOneWidget);
      expect(find.text(AppStrings.bankrollScreenSubtitle.toUpperCase()), findsOneWidget);
    });
  });

  group('Bankroll — navegación real (Fase 4)', () {
    testWidgets('CONTINUAR avanza entre los 7 temas y llega a VER RESULTADO en el último',
        (tester) async {
      await _pumpBankrollAt(tester, const Size(390, 844));
      final total = BankrollTopics.all.length;

      for (var i = 0; i < total - 1; i++) {
        expect(find.text(BankrollTopics.all[i].titulo), findsOneWidget);
        await tester.tap(find.text(AppStrings.academyContinue));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      expect(find.text(BankrollTopics.all.last.titulo), findsOneWidget);
      expect(find.text(AppStrings.academySeeResult), findsOneWidget);
    });

    testWidgets('VER RESULTADO en el último tema muestra la pantalla final', (tester) async {
      await _pumpBankrollAt(tester, const Size(390, 844));
      final total = BankrollTopics.all.length;
      for (var i = 0; i < total; i++) {
        final label =
            i == total - 1 ? AppStrings.academySeeResult : AppStrings.academyContinue;
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.bankrollDone), findsOneWidget);
      expect(find.text(AppStrings.academyBackToMap), findsOneWidget);
    });

    testWidgets('ATRÁS real vuelve al tema anterior', (tester) async {
      await _pumpBankrollAt(tester, const Size(390, 844));
      await tester.tap(find.text(AppStrings.academyContinue));
      await tester.pumpAndSettle();
      expect(find.text(BankrollTopics.all[1].titulo), findsOneWidget);

      await tester.tap(find.text(AppStrings.academyBack));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(BankrollTopics.all[0].titulo), findsOneWidget);
    });
  });
}
