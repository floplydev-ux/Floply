import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/models/app_user.dart';
import 'package:poker_trainer/persistence/coins_economy_store.dart';
import 'package:poker_trainer/persistence/training_quota_store.dart';
import 'package:poker_trainer/screens/home/widgets/home_top_bar.dart';
import 'package:poker_trainer/services/economy/coins_economy_state.dart';
import 'package:poker_trainer/services/economy/floply_coins_service.dart';
import 'package:poker_trainer/services/economy/training_quota_service.dart';
import 'package:poker_trainer/services/economy/training_quota_state.dart';
/// Header modular del Home (sección "navbar superior — diseño modular"):
/// 4 bloques independientes (Coins, Entrenamiento, Notificaciones,
/// Configuración), cada uno con su propio fondo — nunca una única barra
/// sólida. Estos tests fijan: los 4 módulos existen, nunca desbordan (ni
/// con un nombre larguísimo en el ancho más angosto que soporta el
/// proyecto), los valores de economía son siempre los reales (nunca
/// hardcodeados) y cada módulo dispara su navegación real.
void main() {
  late FloplyCoinsService coins;
  late TrainingQuotaService training;

  setUp(() {
    coins = FloplyCoinsService(store: InMemoryCoinsEconomyStore());
    training = TrainingQuotaService(store: InMemoryTrainingQuotaStore());
  });

  tearDown(() {
    coins.dispose();
    training.dispose();
  });

  Future<void> pumpBar(
    WidgetTester tester, {
    VoidCallback? onOpenSettings,
  }) async {
    await coins.load();
    await training.load();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeTopBar(
          coins: coins,
          training: training,
          onOpenSettings: onOpenSettings ?? () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('HomeTopBar — 4 módulos independientes', () {
    testWidgets('los 4 módulos existen: Coins, Entrenamiento, '
        'notificaciones y configuración', (tester) async {
      AppUser.current = const AppUser(displayName: 'Juan');
      await pumpBar(tester);

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.contains('economy_coin_icon')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.contains('economy_training_icon')),
        findsOneWidget,
      );
    });

    testWidgets('tocar el módulo Configuración llama a onOpenSettings',
        (tester) async {
      AppUser.current = const AppUser(displayName: 'Juan');
      var tapped = false;
      await pumpBar(tester, onOpenSettings: () => tapped = true);
      await tester.tap(find.byIcon(Icons.settings_rounded));
      expect(tapped, isTrue);
    });

    testWidgets('tocar Notificaciones no dispara onOpenSettings '
        '(son acciones separadas)', (tester) async {
      AppUser.current = const AppUser(displayName: 'Juan');
      var settingsTapped = false;
      await pumpBar(tester, onOpenSettings: () => settingsTapped = true);
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      expect(settingsTapped, isFalse);
    });
  });

  group('HomeTopBar — valores reales, nunca hardcodeados', () {
    testWidgets('muestra el conteo real de Coins (con "/máximo" en ancho '
        'suficiente)', (tester) async {
      AppUser.current = const AppUser(displayName: 'Juan');
      await tester.binding.setSurfaceSize(const Size(430, 90));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpBar(tester);
      await coins.consumeTime(CoinsEconomyState.timePerCoin * 2);
      await tester.pumpAndSettle();

      expect(find.text('${coins.coins}/${CoinsEconomyState.maxCoins}'), findsOneWidget);
    });

    testWidgets('muestra el cupo real de Entrenamiento (con "/máximo" en '
        'ancho suficiente)', (tester) async {
      AppUser.current = const AppUser(displayName: 'Juan');
      await tester.binding.setSurfaceSize(const Size(430, 90));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpBar(tester);
      await training.consumeTraining();
      await tester.pumpAndSettle();

      expect(
        find.text('${training.remaining}/${TrainingQuotaState.dailyFreeTrainings}'),
        findsOneWidget,
      );
    });

    testWidgets('en ancho angosto, oculta "/máximo" pero sigue mostrando '
        'el número real', (tester) async {
      AppUser.current = const AppUser(displayName: 'Juan');
      await tester.binding.setSurfaceSize(const Size(320, 90));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpBar(tester);
      await coins.consumeTime(CoinsEconomyState.timePerCoin * 2);
      await tester.pumpAndSettle();

      expect(find.text('${coins.coins}'), findsWidgets);
      expect(find.text('${coins.coins}/${CoinsEconomyState.maxCoins}'), findsNothing);
    });
  });

  group('HomeTopBar — responsive: nunca desborda', () {
    for (final width in [300.0, 320.0, 360.0, 390.0, 430.0]) {
      for (final name in ['Juan', 'Juan Ignacio González']) {
        testWidgets('$width dp, nombre "$name" — sin overflow', (tester) async {
          AppUser.current = AppUser(displayName: name);
          await tester.binding.setSurfaceSize(Size(width, 90));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await pumpBar(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
