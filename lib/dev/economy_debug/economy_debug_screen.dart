import 'package:flutter/material.dart';

import '../../services/ads/admob_rewarded_ad_service.dart';
import '../../services/ads/rewarded_ad_service.dart';
import '../../services/economy/floply_coins_service.dart';
import '../../services/economy/training_quota_service.dart';
import '../../services/premium/premium_service.dart';

/// Pantalla de diagnóstico de la infraestructura de monetización (FLOPly
/// Coins + Rewarded Ads) — Fase 1. **Solo para desarrollo**: no forma
/// parte del producto, no está diseñada con Sala Verde, y no se muestra a
/// usuarios reales (nunca se referencia desde código de release; el único
/// acceso es el que agrega `ProfileScreen` bajo `kDebugMode`).
///
/// Construye sus propias instancias de los tres servicios — no comparte
/// las de ninguna pantalla "real" porque en esta fase ninguna pantalla
/// real las usa todavía (la conexión con Herramientas/Campo de
/// entrenamiento/Coach es Fase 2). Sirve para verificar a mano, contra un
/// dispositivo real, que:
///  * el estado de Coins/tiempo persiste entre reinicios de la app;
///  * el Rewarded Ad de PRUEBA de AdMob carga y muestra de verdad;
///  * la Coin solo aparece después de completar el anuncio.
class EconomyDebugScreen extends StatefulWidget {
  const EconomyDebugScreen({
    super.key,
    this.coins,
    this.training,
    this.premium,
    this.adsBuilder,
  });

  /// Permite inyectar instancias (tests — nunca se ejercita el SDK real de
  /// AdMob ni `path_provider` desde `flutter test`, ver
  /// `economy_debug_screen_test.dart`). Si no se pasan, arma las
  /// instancias reales de producción, igual que hace cualquier otra
  /// pantalla real de la app (mismo patrón que `AcademyController`).
  final FloplyCoinsService? coins;
  final TrainingQuotaService? training;
  final PremiumService? premium;

  /// Constructor de `RewardedAdService` a partir de la instancia real (o
  /// inyectada) de [coins] — así un test puede pasar un
  /// `FakeRewardedAdService` sin que esta pantalla sepa nada de AdMob.
  final RewardedAdService Function(FloplyCoinsService coins)? adsBuilder;

  @override
  State<EconomyDebugScreen> createState() => _EconomyDebugScreenState();
}

class _EconomyDebugScreenState extends State<EconomyDebugScreen> {
  late final FloplyCoinsService _coins = widget.coins ?? FloplyCoinsService();
  late final TrainingQuotaService _training = widget.training ?? TrainingQuotaService();
  late final PremiumService _premium = widget.premium ?? StubPremiumService();
  late final RewardedAdService _ads =
      widget.adsBuilder?.call(_coins) ?? AdMobRewardedAdService(coins: _coins);

  bool _loading = true;
  String? _lastAdResult;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_coins.load(), _training.load()]);
    await _ads.preload();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _coins.dispose();
    _training.dispose();
    super.dispose();
  }

  Future<void> _consume4Minutes() async {
    await _coins.consumeTime(const Duration(minutes: 4));
    setState(() {});
  }

  Future<void> _addCoinManually() async {
    await _coins.addCoin();
    setState(() {});
  }

  Future<void> _consumeTraining() async {
    await _training.consumeTraining();
    setState(() {});
  }

  Future<void> _showRewardedAd() async {
    setState(() => _lastAdResult = 'Cargando…');
    final result = await _ads.showForCoinReward();
    setState(() => _lastAdResult = result.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Economía — diagnóstico (debug)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: Listenable.merge([_coins, _training]),
              builder: (context, _) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('FLOPly Coins', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Coins: ${_coins.coins} / 6'),
                    Text('Tiempo disponible: ${_coins.availableMinutes} min'),
                    Text('Próxima regeneración: ${_coins.nextRegenerationAt ?? "— (al máximo)"}'),
                    Text('Anuncios usados (12h): ${_coins.rewardedAdsUsedInWindow} / 3'),
                    Text('¿Puede pedir recompensa?: ${_coins.canRequestAdReward}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _consume4Minutes,
                      child: const Text('Consumir 4 minutos'),
                    ),
                    ElevatedButton(
                      onPressed: _addCoinManually,
                      child: const Text('Sumar 1 Coin manualmente'),
                    ),
                    ElevatedButton(
                      onPressed: _showRewardedAd,
                      child: const Text('Ver anuncio (+1 Coin)'),
                    ),
                    if (_lastAdResult != null) Text('Resultado del anuncio: $_lastAdResult'),
                    const Divider(height: 32),
                    const Text('Entrenamientos diarios',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Disponibles hoy: ${_training.remaining} / 5'),
                    Text('Fecha del último reset: ${_training.resetDate}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _consumeTraining,
                      child: const Text('Consumir 1 entrenamiento'),
                    ),
                    const Divider(height: 32),
                    const Text('Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('isPremium: ${_premium.isPremium}'),
                  ],
                );
              },
            ),
    );
  }
}
