import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/l10n/app_strings.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/home/home_screen.dart';
import 'package:poker_trainer/screens/home/widgets/home_tools_banner.dart';

Future<AcademyController> _loadedController() async {
  final controller = AcademyController(
    engine: PokerTrainerEngine(seed: 1),
    store: InMemoryAcademyStore(),
  );
  await controller.load();
  return controller;
}

Widget _harness(AcademyController controller,
    {VoidCallback? onGoToAcademy, VoidCallback? onGoToLaboratory}) {
  return MaterialApp(
    home: HomeScreen(
      academyController: controller,
      onGoToAcademy: onGoToAcademy ?? () {},
      onGoToLaboratory: onGoToLaboratory ?? () {},
      onGoToProfile: () {},
      onGoToCoach: () {},
    ),
  );
}

void main() {
  testWidgets(
      'usuario nuevo: el hero invita a empezar y "Comenzar" abre la '
      'primera lección real', (tester) async {
    final controller = await _loadedController();
    var wentToAcademy = false;

    await tester.pumpWidget(
      _harness(controller, onGoToAcademy: () => wentToAcademy = true),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.continueLearningStartCta), findsOneWidget);
    expect(controller.activeLessonId, isNull);

    final firstLessonId = controller.currentLessonId;
    expect(firstLessonId, isNotNull);

    await tester.tap(find.text(AppStrings.continueLearningStartCta));
    await tester.pumpAndSettle();

    expect(controller.activeLessonId, firstLessonId);
    expect(wentToAcademy, isTrue);
  });

  testWidgets(
      'con progreso: el hero muestra la lección real y "Continuar" la abre',
      (tester) async {
    final controller = await _loadedController();
    controller.progress = AcademyProgress()..entry('1.1').completed = true;

    var wentToAcademy = false;
    await tester.pumpWidget(
      _harness(controller, onGoToAcademy: () => wentToAcademy = true),
    );
    await tester.pumpAndSettle();

    final lessonView = controller.currentLessonView!;
    expect(find.text(AppStrings.continueLabel), findsWidgets);

    await tester.tap(find.text(AppStrings.continueLabel).first);
    await tester.pumpAndSettle();

    expect(controller.activeLessonId, lessonView.lesson.id);
    expect(wentToAcademy, isTrue);
  });

  testWidgets(
      'Academia completa: el hero lo dice y sugiere practicar en vez de '
      'seguir aprendiendo', (tester) async {
    final controller = await _loadedController();
    for (final level in controller.levels) {
      for (final lesson in level.lessons) {
        controller.progress.entry(lesson.lesson.id).completed = true;
      }
    }
    expect(controller.currentLessonId, isNull);

    var wentToPractice = false;
    await tester.pumpWidget(
      _harness(controller, onGoToLaboratory: () => wentToPractice = true),
    );
    await tester.pumpAndSettle();

    expect(
        find.text(AppStrings.continueLearningCompletedBody), findsOneWidget);
    await tester.tap(find.text(AppStrings.practiceNowLabel).first);
    await tester.pumpAndSettle();

    expect(wentToPractice, isTrue);
  });

  testWidgets(
      'Campo de Entrenamiento reemplazó a Laboratorio en toda la Home',
      (tester) async {
    final controller = await _loadedController();
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.laboratoryTitle), findsOneWidget);
    expect(find.textContaining('LABORATORIO'), findsNothing);
    expect(find.textContaining('Laboratorio'), findsNothing);
  });

  testWidgets('el banner de Herramientas está debajo de Academia/Campo de '
      'Entrenamiento y abre Tools', (tester) async {
    final controller = await _loadedController();
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    final academyCard = tester.getTopLeft(find.text(AppStrings.academyTitle));
    final labCard = tester.getTopLeft(find.text(AppStrings.laboratoryTitle));
    final banner = tester.getTopLeft(find.byType(HomeToolsBanner));

    // Academia y Campo de Entrenamiento siguen a la misma altura (lado a
    // lado, sin cambios) y el banner va estrictamente debajo de ambos.
    expect(academyCard.dy, labCard.dy);
    expect(banner.dy, greaterThan(academyCard.dy));

    await tester.tap(find.byType(HomeToolsBanner));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.toolsHeaderTitle), findsOneWidget);
  });

  testWidgets('Bankroll, Tools y Coach navegan a sus pantallas reales',
      (tester) async {
    // Estas 3 tarjetas están más abajo que las anteriores: en el viewport
    // chico por defecto de flutter test quedan fuera de pantalla, así que
    // hay que scrollear hasta ellas antes de tocarlas (no alcanza con que
    // el finder las encuentre en el árbol).
    final controller = await _loadedController();
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    // ComingSoonScreen no tiene botón ATRÁS propio (es un placeholder de
    // contenido, no un paso de un flujo) y BankrollScreen usa su propio
    // botón dentro de LessonFlowHeader, no un AppBar/BackButton estándar
    // — así que se vuelve por Navigator directamente en vez de
    // `tester.pageBack()` (que espera un back button de Material/Cupertino).
    void popRoute() =>
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();

    await tester.ensureVisible(find.text(AppStrings.bankrollTitle));
    await tester.tap(find.text(AppStrings.bankrollTitle));
    await tester.pumpAndSettle();
    // LessonFlowHeader muestra el subtítulo en mayúsculas.
    expect(find.text(AppStrings.bankrollScreenSubtitle.toUpperCase()),
        findsOneWidget);
    popRoute();
    await tester.pumpAndSettle();

    // La vidriera de accesos individuales ("Ver todas") se eliminó del
    // Home (Tools pasó a ser un único bloque grande) — se entra tocando
    // el banner directamente, por su título (único en pantalla).
    await tester.ensureVisible(find.text(AppStrings.toolsTitle));
    await tester.tap(find.text(AppStrings.toolsTitle));
    await tester.pumpAndSettle();
    // Tools ya tiene pantalla real (ToolsScreen, con Pot Odds Calculator
    // como primera herramienta) — no el placeholder ComingSoonScreen.
    expect(find.text(AppStrings.toolsHeaderTitle), findsOneWidget);
    expect(find.text(AppStrings.toolsPotOddsTitle), findsOneWidget);
    popRoute();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(AppStrings.coachTitle));
    await tester.tap(find.text(AppStrings.coachTitle));
    await tester.pumpAndSettle();
    // Coach ya tiene pantalla real (CoachTableScreen, una mano jugable
    // completa) — no el placeholder ComingSoonScreen que solo mostraba
    // `AppStrings.navCoach`.
    expect(find.text(AppStrings.coachTableTitle), findsOneWidget);
  });

  // Fase 2: barrido ampliado de 320-430 a 300-480 (mismo rango que el
  // stress test del playground, docs/design/FLOPLY_VISUAL_STRESS_TEST.md
  // §G) — Home productiva no había probado los extremos 300/375/414/480.
  for (final width in [300.0, 320.0, 360.0, 375.0, 390.0, 412.0, 414.0, 430.0, 480.0]) {
    testWidgets('$width dp — la Home no desborda con progreso real',
        (tester) async {
      tester.view.physicalSize = Size(width * 3, 900 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final controller = await _loadedController();
      controller.progress = AcademyProgress()..entry('1.1').completed = true;

      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

  // Altura reducida (iPhone SE-clase, 375x568) — Paso 10 de la Fase 2 pide
  // probar al menos una; Home es 100% scrolleable así que el riesgo real
  // es menor que en Laboratorio/Tools, pero no se había verificado antes.
  for (final scenario in [
    ('usuario nuevo', null),
    ('con progreso', () => AcademyProgress()..entry('1.1').completed = true),
  ]) {
    testWidgets('375x568 (altura corta) — ${scenario.$1}, sin overflow',
        (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final controller = await _loadedController();
      final buildProgress = scenario.$2;
      if (buildProgress != null) controller.progress = buildProgress();

      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
