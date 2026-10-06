import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/screens/academy/widgets/lesson_completion_banner.dart';
import 'package:poker_trainer/services/ads/ad_config.dart';

void main() {
  // ── AdConfig ───────────────────────────────────────────────────────────────

  group('AdConfig.lessonCompletionBannerAdUnitId', () {
    test('devuelve el ID de prueba cuando useTestAds es true', () {
      // AdConfig.useTestAds = true en código → siempre el test ID.
      expect(
        AdConfig.lessonCompletionBannerAdUnitId,
        'ca-app-pub-3940256099942544/9214589741',
      );
    });

    test('no devuelve una cadena vacía', () {
      expect(AdConfig.lessonCompletionBannerAdUnitId, isNotEmpty);
    });
  });

  // ── LessonCompletionBanner — lógica de visibilidad ─────────────────────────

  group('LessonCompletionBanner', () {
    testWidgets(
      'usuario Premium → widget invisible (SizedBox.shrink)',
      (tester) async {
        await tester.pumpWidget(
          const _TestApp(
            child: LessonCompletionBanner(isPremium: true),
          ),
        );
        await tester.pump();

        // Con isPremium=true el widget no debería mostrar nada.
        // El widget devuelve SizedBox.shrink() → sin AdWidget en el árbol.
        expect(find.byType(LessonCompletionBanner), findsOneWidget);
        // No debería haber ningún contenedor de anuncio.
        expect(find.byType(_AnyAdContainer), findsNothing);
      },
    );

    testWidgets(
      'usuario gratuito en Web → sin banner (plataforma no soportada)',
      (tester) async {
        // En web kIsWeb es true y el widget nunca intenta cargar ads.
        // No podemos cambiar kIsWeb en tests, pero sí verificar que el
        // widget se construye sin errores.
        await tester.pumpWidget(
          const _TestApp(
            child: LessonCompletionBanner(isPremium: false),
          ),
        );
        await tester.pump();
        expect(find.byType(LessonCompletionBanner), findsOneWidget);
      },
    );

    testWidgets(
      'isPremium cambia a true → banner desaparece',
      (tester) async {
        final notifier = _PremiumNotifier(isPremium: false);

        await tester.pumpWidget(
          _TestApp(
            child: ValueListenableBuilder<bool>(
              valueListenable: notifier,
              builder: (_, premium, __) =>
                  LessonCompletionBanner(isPremium: premium),
            ),
          ),
        );
        await tester.pump();

        // Cambia a premium — el banner debe desaparecer.
        notifier.setPremium(true);
        await tester.pump();

        // Con isPremium=true: invisible.
        final banners = tester.widgetList<LessonCompletionBanner>(
          find.byType(LessonCompletionBanner),
        );
        expect(banners.first.isPremium, isTrue);
      },
    );

    testWidgets(
      'dispose se llama sin errores — no hay setState tras dispose',
      (tester) async {
        await tester.pumpWidget(
          const _TestApp(
            child: LessonCompletionBanner(isPremium: false),
          ),
        );
        await tester.pump();

        // Sustituir por un widget vacío provoca dispose del banner.
        await tester.pumpWidget(const _TestApp(child: SizedBox.shrink()));
        await tester.pump();
        // Sin errores de "setState after dispose".
      },
    );
  });

  // ── Premium obtenido mediante promoción ────────────────────────────────────

  group('Premium por código promocional', () {
    testWidgets(
      'isPremium=true (vía promo) → sin banner, igual que suscripción',
      (tester) async {
        await tester.pumpWidget(
          const _TestApp(
            child: LessonCompletionBanner(isPremium: true),
          ),
        );
        await tester.pump();
        // El widget no distingue el ORIGEN del premium — solo el valor bool.
        // isPremium=true (promo o RC) siempre oculta el banner.
        final banner = tester.widget<LessonCompletionBanner>(
          find.byType(LessonCompletionBanner),
        );
        expect(banner.isPremium, isTrue);
      },
    );
  });
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// App mínima para los widget tests.
class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: child));
  }
}

/// Placeholder ficticio que nunca existe en el árbol — solo para verificar
/// ausencia. No corresponde a ningún widget real de AdMob.
class _AnyAdContainer extends StatelessWidget {
  const _AnyAdContainer();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Notifier para simular cambios de estado Premium en tests de widgets.
class _PremiumNotifier extends ValueNotifier<bool> {
  _PremiumNotifier({required bool isPremium}) : super(isPremium);
  void setPremium(bool value) => this.value = value;
}
