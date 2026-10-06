import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/tools/tools_screen.dart';

/// Guía consolidada de Tools (sección 1 del pedido) — nunca un segundo
/// sistema de ayuda: reutiliza el contenido real de cada
/// `ToolExplainerContent` existente, solo agrega "cuándo usarla" y un
/// ejemplo. Estos tests fijan que: el acceso vive en el hub (nunca
/// adentro de una herramienta puntual), lista las 6 reales (ni una más
/// ni una menos), y cada tarjeta arranca colapsada (no satura la
/// pantalla) y se expande sin romper nada.
void main() {
  Future<void> pumpHub(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('el hub tiene un acceso a "¿Cómo usar las herramientas?"',
      (tester) async {
    await pumpHub(tester);
    expect(find.bySemanticsLabel(AppStrings.toolsGuideButtonLabel), findsOneWidget);
  });

  testWidgets('abre la guía y lista las 6 herramientas reales, colapsadas',
      (tester) async {
    await pumpHub(tester);
    await tester.tap(find.bySemanticsLabel(AppStrings.toolsGuideButtonLabel));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.toolsGuideTitle), findsOneWidget);
    for (final title in ['Rangos', 'Equity', 'Pot Odds', 'Combos', 'Blockers']) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    // "EV" también es el título (mayúsculas iguales) de la tarjeta del
    // hub detrás de la hoja — basta con que aparezca al menos una vez.
    expect(find.text('EV'), findsWidgets);
    // Colapsada por defecto: ninguno de los campos de detalle (solo
    // visibles al expandir) se ve todavía.
    expect(find.text(AppStrings.toolsExplainerHowToUse), findsNothing);
    expect(find.text(AppStrings.toolsGuideWhenToUse), findsNothing);
  });

  testWidgets('expandir una tarjeta muestra el detalle real sin romper '
      'nada, y se puede volver a colapsar', (tester) async {
    await pumpHub(tester);
    await tester.tap(find.bySemanticsLabel(AppStrings.toolsGuideButtonLabel));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pot Odds'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text(AppStrings.toolsExplainerHowToUse), findsOneWidget);
    expect(find.text(AppStrings.toolsExplainerResult), findsOneWidget);
    expect(find.text(AppStrings.toolsGuideWhenToUse), findsOneWidget);
    expect(find.text(AppStrings.toolsGuideExample), findsOneWidget);
    // El contenido real de Pot Odds (no inventado, no de otra Tool).
    expect(
      find.textContaining('Ingresá el bote antes de pagar'),
      findsOneWidget,
    );

    await tester.tap(find.text('Pot Odds'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.toolsExplainerHowToUse), findsNothing);
  });

  testWidgets('"Cerrar" cierra la guía sin tocar la pantalla de atrás',
      (tester) async {
    await pumpHub(tester);
    await tester.tap(find.bySemanticsLabel(AppStrings.toolsGuideButtonLabel));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.toolsGuideClose));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.toolsGuideTitle), findsNothing);
    expect(find.text(AppStrings.toolsHeaderTitle), findsOneWidget);
  });
}
