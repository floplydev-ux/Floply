import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/screens/tools/tools_screen.dart';

import '../support/app_harness.dart';

/// Accessibility baseline (Fase 0): lo que SÍ es automatizable con los
/// matchers oficiales de `flutter_test` (`meetsGuideline`) — tamaño de tap
/// targets, contraste de texto, y que todo elemento tocable tenga label.
/// Lo que esto NO cubre (documentado, no automatizado en esta fase):
/// el orden real de lectura de un screen reader, si un anuncio dinámico
/// (ej. feedback de un ejercicio) realmente se lee en voz alta, y el
/// juicio de si un label tiene sentido en español natural — eso requiere
/// inspección humana o un pase con `accessibility-audit-flutter`.
void main() {
  testWidgets('AppShell (Home, invitado) cumple tap targets y contraste',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(testAppShell());
    await tester.pumpAndSettle();

    // El hallazgo de Fase 0 (botón de settings de 38x38dp) se corrigió en
    // Fase 1 Bloque 1 P1-D (home_header.dart). Al arreglarlo, esta misma
    // assertion destapó una capa de hallazgos de CONTRASTE que el
    // tap-target rojo tapaba antes (el primer `expectLater` que falla
    // corta la ejecución del resto): "Teoría"/"COMENZAR ACADEMIA" del hero
    // y las labels inactivas de la bottom nav no llegaban al contraste
    // WCAG AA (4.5:1) — corregidos en la misma pasada (continue_learning_
    // card.dart, bottom_navigation.dart). Las 4 guidelines pasan hoy.
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    handle.dispose();
  });

  testWidgets('ToolsScreen (hub) cumple tap targets y contraste',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    handle.dispose();
  });
}
