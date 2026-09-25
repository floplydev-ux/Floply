import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

/// Accessibility para el mapa de niveles de Academia (Fase 1, Bloque 2,
/// P1-3/P1-4) — no existía cobertura de accesibilidad para esta pantalla
/// hasta ahora (el único accessibility test previo cubría AppShell/Home y
/// ToolsScreen, ver Fase 0/Bloque 1).
void main() {
  testWidgets('AcademyScreen (mapa de niveles) cumple tap targets y contraste',
      (tester) async {
    final controller = AcademyController(
      engine: PokerTrainerEngine(seed: 1),
      store: InMemoryAcademyStore(),
    );
    await controller.load();

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: controller)),
    ));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    handle.dispose();
  });

  testWidgets(
      'las lecciones bloqueadas/disponibles anuncian su estado en palabras',
      (tester) async {
    final controller = AcademyController(
      engine: PokerTrainerEngine(seed: 1),
      store: InMemoryAcademyStore(),
    );
    await controller.load();

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: controller)),
    ));
    await tester.pumpAndSettle();

    // Usuario nuevo: la primera lección del Nivel 1 está "Disponible", el
    // resto "Bloqueado" — antes esto solo se veía por ícono (Fase 1,
    // Bloque 2, P1-3).
    expect(
      find.bySemanticsLabel(RegExp('Disponible')),
      findsWidgets,
      reason: 'ninguna lección se anuncia como disponible',
    );
    expect(
      find.bySemanticsLabel(RegExp('Bloqueado')),
      findsWidgets,
      reason: 'ninguna lección se anuncia como bloqueada',
    );

    handle.dispose();
  });
}
