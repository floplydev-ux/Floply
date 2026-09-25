import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/tools/pot_odds_calculator_screen.dart';

import '../../test/support/app_harness.dart';

/// Smoke E2E (Fase 0): prueba que el harness de `integration_test` en sí
/// funciona sobre esta app — Home → Tools → una calculadora → volver — NO
/// que ya exista cobertura E2E completa. Corre sobre el mismo harness sin
/// Firebase real (`testAppShell`, invitado) que ya usan los widget tests:
/// un flujo con Firebase real es un paso deliberadamente posterior (ver
/// Baseline Document, sección de Integration Baseline), no algo que haga
/// falta para probar que la infraestructura de `integration_test` corre.
///
/// Se puede correr hoy en Windows desktop o Chrome (los únicos targets
/// disponibles en este entorno — no hay emulador/dispositivo Android
/// configurado). En un dispositivo Android/iOS real, este mismo archivo
/// corre igual; lo que hoy no se puede ejercitar es la automatización
/// NATIVA de Patrol (permisos, diálogos del sistema), que necesita ese
/// dispositivo.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home → Tools (link card) → Pot Odds → volver', (tester) async {
    await tester.pumpWidget(testAppShell());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.toolsTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.toolsPotOddsTitle));
    await tester.pumpAndSettle();

    expect(find.byType(PotOddsCalculatorScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(PotOddsCalculatorScreen), findsNothing);
  });
}
