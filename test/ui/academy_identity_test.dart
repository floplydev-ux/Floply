import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/pedagogy/academy_players.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

AcademyProgress _upTo(String target) {
  final p = AcademyProgress();
  for (final id in Curriculum.lessonOrder) {
    if (id == target) break;
    p.entry(id).completed = true;
  }
  return p;
}

void main() {
  testWidgets('la mesa muestra el nombre del usuario en su asiento y '
      'nombres de personajes para los rivales', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final c = AcademyController(
      engine: PokerTrainerEngine(seed: 3),
      store: InMemoryAcademyStore(),
      userName: 'Camila',
    );
    await c.load();
    c.progress = _upTo('3.1');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: c)),
    ));
    await tester.pumpAndSettle();
    c.openLesson('3.1');
    await tester.pumpAndSettle();

    // 3.1 usa el flujo canónico: teoría escrita primero, mesa al cierre.
    // Avanzar por las fichas hasta llegar al ejemplo de cierre (la mesa).
    while (!c.isClosingExample) {
      c.advanceTheory();
      await tester.pumpAndSettle();
      if (c.phase != AcademyPhase.theory) break;
    }
    expect(c.isClosingExample, isTrue);

    // El nombre del usuario está en la mesa.
    expect(find.text('Camila'), findsWidgets);

    // No aparece "HERO" ni "VILLAIN" ni "TÚ" como nombre de jugador.
    expect(find.text('HERO'), findsNothing);
    expect(find.text('VILLAIN'), findsNothing);
    expect(find.text('Hero'), findsNothing);
    expect(find.text('TÚ'), findsNothing);

    // Al menos un personaje del elenco está sentado.
    final rosterFound = AcademyPlayers.roster
        .where((p) => find.text(p.name).evaluate().isNotEmpty)
        .length;
    expect(rosterFound, greaterThanOrEqualTo(2));

    // Cambiar el nombre del usuario se refleja sin tocar el guion.
    c.userName = 'Rodri';
    c.nextClosingExampleStep();
    await tester.pumpAndSettle();
    expect(find.text('Rodri'), findsWidgets);
    expect(find.text('Camila'), findsNothing);
  });

  testWidgets('la burbuja usa el nombre del personaje, no "Villain"',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final c = AcademyController(
      engine: PokerTrainerEngine(seed: 1),
      store: InMemoryAcademyStore(),
    );
    await c.load();
    c.progress = _upTo('3.3');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AcademyScreen(controller: c)),
    ));
    await tester.pumpAndSettle();
    c.openLesson('3.3');
    await tester.pumpAndSettle();

    // 3.3 usa el flujo canónico: teoría escrita primero (con clase de mentor
    // T020 intercalada), mesa al cierre. Avanzar hasta el ejemplo de cierre.
    while (!c.isClosingExample) {
      c.advanceTheory();
      await tester.pumpAndSettle();
      if (c.phase != AcademyPhase.theory) break;
    }
    expect(c.isClosingExample, isTrue);

    // Paso 1 del guion de cierre de N3.3: los marcadores resuelven a nombres
    // reales del elenco, no a etiquetas genéricas.
    final bubble = c.currentBubbleText!;
    expect(bubble.contains('{'), isFalse);
    expect(bubble.toLowerCase().contains('villain'), isFalse);
    expect(bubble.toLowerCase().contains('hero'), isFalse);
    // Contiene el nombre de algún personaje del elenco.
    expect(AcademyPlayers.roster.any((p) => bubble.contains(p.name)), isTrue,
        reason: bubble);
    expect(find.text(bubble), findsOneWidget);
  });
}
