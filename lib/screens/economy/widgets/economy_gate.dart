import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/economy/coins_economy_state.dart';
import '../../../services/economy/economy_access_service.dart';
import '../../../services/ads/rewarded_ad_service.dart';
import '../../../services/economy/economy_session.dart';
import '../../../services/economy/floply_coins_service.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import 'economy_blocked_view.dart';

/// Envuelve una pantalla paga (Herramienta o Coach — "mismo gate de
/// entrada, mismo costo por minuto, mismo comportamiento en 0 Coins",
/// pedido explícito) con el chequeo de acceso + la sesión de consumo de
/// tiempo real ([EconomySession]) — el único mecanismo reutilizable para
/// ambas, nunca una copia por pantalla.
///
/// Se usa envolviendo el `builder` que arma la pantalla real en el sitio
/// donde hoy se la empuja (`Navigator.push`) — la pantalla envuelta
/// (cualquiera de las 6 calculadoras de Tools, o `CoachTableScreen`) no
/// sabe nada de economía ni cambia una sola línea.
///
/// Premium salta por completo esta clase: ni gate ni sesión (pedido
/// explícito, sección 14) — [EconomyAccessService.checkTimedAccess] ya
/// devuelve `premium` directo, sin consumir nada.
///
/// No bloquea el render mientras [FloplyCoinsService] todavía está
/// hidratando desde disco: el estado en memoria ya arranca en
/// `CoinsEconomyState.initial` (completo) de forma síncrona, así que la
/// decisión de acceso es segura incluso antes de que `load()` resuelva
/// — la única consecuencia de no esperar es una ventana mínima (el
/// tiempo de una lectura de archivo) en la que, para una cuenta que
/// vuelve con saldo bajo, se podría ver el gate conceder acceso un
/// instante antes de que el saldo real persistido se aplique; ningún
/// cobro real ocurre en esa ventana (el primer checkpoint tarda
/// [EconomySession.checkpointInterval]), así que no hay forma de
/// explotarlo para "gastar" tiempo que no se tiene.
class EconomyGate extends StatefulWidget {
  const EconomyGate({
    super.key,
    required this.access,
    required this.coins,
    required this.builder,
    required this.blockedTitle,
    required this.blockedBody,
  });

  final EconomyAccessService access;
  final FloplyCoinsService coins;
  final WidgetBuilder builder;

  /// Texto del aviso de bloqueo — varía según si es Tools, Coach o
  /// entrenamiento extra (mismo widget de bloqueo, texto contextual).
  final String blockedTitle;
  final String blockedBody;

  @override
  State<EconomyGate> createState() => _EconomyGateState();
}

class _EconomyGateState extends State<EconomyGate> with WidgetsBindingObserver {
  EconomySession? _session;

  /// Tiempo restante mostrado en el overlay — fuente de verdad es
  /// [FloplyCoinsService.availableTime]; este valor se actualiza cada
  /// segundo por [_displayTimer] y se re-sincroniza desde la fuente real
  /// cuando la diferencia supera 5 s (después del cobro del checkpoint
  /// de 60 s de [EconomySession]).
  Duration _displayTime = Duration.zero;
  Timer? _displayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maybeStartSession();
  }

  /// Arranca la sesión económica si corresponde (acceso concedido Y
  /// consume Coins) — no-op si ya hay una activa (una pantalla tiene
  /// como máximo una sesión económica a la vez, pedido explícito).
  void _maybeStartSession() {
    if (_session != null) return;
    final decision = widget.access.checkTimedAccess();
    if (decision.consumesCoins) {
      _session = EconomySession(coins: widget.coins)..start();
      _startDisplayTimer();
    }
  }

  /// Tiempo residual de la moneda activa: `availableTime % timePerCoin`.
  /// Esta es la única fuente de verdad del cronómetro visual; comparar
  /// contra `availableTime` TOTAL sería incorrecto — un rewarded ad
  /// suma 15 min al pool y haría saltar el sync, reiniciando el timer.
  /// Caso especial: si el módulo es exactamente 0 (pool múltiplo de
  /// 15 min), devuelve `timePerCoin` (inicio de moneda nueva / pool lleno).
  Duration _partialCoinTime() {
    final total = widget.coins.availableTime;
    if (total <= Duration.zero) return Duration.zero;
    final mod = total.inSeconds % CoinsEconomyState.timePerCoin.inSeconds;
    return Duration(
      seconds: mod > 0 ? mod : CoinsEconomyState.timePerCoin.inSeconds,
    );
  }

  /// Arranca el timer visual de 1 segundo — solo mueve la UI, nunca
  /// cobra tiempo (eso lo hace [EconomySession]). Re-sincroniza
  /// [_displayTime] con [_partialCoinTime] cuando la diferencia supera
  /// 5 s (desfase por el checkpoint de 60 s de [EconomySession]).
  /// Un rewarded ad no dispara la re-sincronización porque
  /// `availableTime % timePerCoin` no cambia al sumar un coin completo.
  void _startDisplayTimer() {
    _displayTime = _partialCoinTime();
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final actual = _partialCoinTime();
      setState(() {
        if ((_displayTime - actual).abs() > const Duration(seconds: 5)) {
          _displayTime = actual;
        } else {
          final next = _displayTime - const Duration(seconds: 1);
          _displayTime = next.isNegative ? Duration.zero : next;
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = _session;
    if (session == null || !session.isActive) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        session.pause();
      case AppLifecycleState.resumed:
        session.resume();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _displayTimer?.cancel();
    _session?.dispose();
    super.dispose();
  }

  void _showCoinRecovery(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CoinRecoverySheet(
        access: widget.access,
        coins: widget.coins,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.coins,
      builder: (context, _) {
        final decision = widget.access.checkTimedAccess();

        if (!decision.isGranted && _session == null) {
          // Bloqueado desde el principio — nunca llegó a abrir la
          // pantalla real.
          return Scaffold(
            backgroundColor: SalaVerdeColors.background,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(SalaVerdeSpace.lg),
                  child: EconomyBlockedView(
                    access: widget.access,
                    decision: decision,
                    title: widget.blockedTitle,
                    body: widget.blockedBody,
                    onAdResult: (_) => setState(_maybeStartSession),
                    onWait: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
          );
        }

        final session = _session;
        if (session == null) {
          // Premium o entrenamiento gratis — acceso directo, sin sesión.
          return widget.builder(context);
        }

        // Chequeo en vivo (nunca una bandera histórica): si el usuario
        // mira un anuncio y recupera tiempo, el aviso se retira solo en
        // el próximo rebuild.
        final outOfCoinsNow =
            session.isActive && widget.coins.availableTime <= Duration.zero;

        final sessionActive = session.isActive;
        return Stack(
          children: [
            widget.builder(context),
            // Overlay de Coins + cronómetro — solo mientras la sesión
            // está activa y queda tiempo. Visible en la esquina superior
            // derecha para no tapar el contenido principal.
            if (sessionActive && !outOfCoinsNow)
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(SalaVerdeSpace.sm),
                    child: _CoinTimerBadge(
                      coins: widget.coins.coins,
                      maxCoins: CoinsEconomyState.maxCoins,
                      displayTime: _displayTime,
                      canEarnCoin: decision.canWatchRewardedAd,
                      onTap: () => _showCoinRecovery(context),
                    ),
                  ),
                ),
              ),
            if (sessionActive && outOfCoinsNow)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(SalaVerdeSpace.lg),
                    child: EconomyBlockedView(
                      access: widget.access,
                      decision: widget.access.checkTimedAccess(),
                      title: AppStrings.economyRanOutMidSessionTitle,
                      body: AppStrings.economyRanOutMidSessionBody,
                      onAdResult: (_) => setState(() {}),
                      onWait: () => setState(() {}),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Overlay badge ─────────────────────────────────────────────────────────────

/// Pill superior-derecho que muestra `coins/maxCoins` y el cronómetro
/// `MM:SS` mientras hay una sesión activa. Cuando el usuario puede ganar
/// un Coin extra (hay un rewarded ad disponible y no alcanzó el límite),
/// añade un ícono `+` como affordance táctil — el toque abre
/// [_CoinRecoverySheet].
class _CoinTimerBadge extends StatelessWidget {
  const _CoinTimerBadge({
    required this.coins,
    required this.maxCoins,
    required this.displayTime,
    required this.canEarnCoin,
    required this.onTap,
  });

  final int coins;
  final int maxCoins;
  final Duration displayTime;
  final bool canEarnCoin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = (displayTime.inMinutes % 60).toString().padLeft(2, '0');
    final s = (displayTime.inSeconds % 60).toString().padLeft(2, '0');

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          SalaVerdeColors.brass.withValues(alpha: 0.15),
          SalaVerdeColors.surfaceElevated,
        ),
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        border: Border.all(
          color: canEarnCoin
              ? SalaVerdeColors.brass.withValues(alpha: 0.7)
              : SalaVerdeColors.brass.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$coins/$maxCoins',
            style: SalaVerdeType.numeric(
                size: 12, color: SalaVerdeColors.brass),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.timer_rounded,
              size: 12, color: SalaVerdeColors.textSecondary),
          const SizedBox(width: 2),
          Text(
            '$m:$s',
            style: SalaVerdeType.numeric(
                size: 12, color: SalaVerdeColors.textPrimary),
          ),
          if (canEarnCoin) ...[
            const SizedBox(width: 4),
            const Icon(Icons.add_circle_outline_rounded,
                size: 12, color: SalaVerdeColors.brass),
          ],
        ],
      ),
    );

    return GestureDetector(onTap: onTap, child: badge);
  }
}

// ── Recovery sheet ────────────────────────────────────────────────────────────

/// Bottom sheet que aparece al tocar el [_CoinTimerBadge]: muestra el
/// saldo actual y ofrece ver un rewarded ad para recuperar 1 Coin.
/// Mismo patrón de estado que [EconomyBlockedView] — nunca duplica la
/// lógica de economía, solo delega en [EconomyAccessService.watchRewardedAd].
class _CoinRecoverySheet extends StatefulWidget {
  const _CoinRecoverySheet({
    required this.access,
    required this.coins,
  });

  final EconomyAccessService access;
  final FloplyCoinsService coins;

  @override
  State<_CoinRecoverySheet> createState() => _CoinRecoverySheetState();
}

class _CoinRecoverySheetState extends State<_CoinRecoverySheet> {
  bool _watching = false;
  String? _statusMessage;

  Future<void> _watchAd() async {
    setState(() {
      _watching = true;
      _statusMessage = AppStrings.economyWatchingAd;
    });
    final result = await widget.access.watchRewardedAd();
    if (!mounted) return;
    if (result == RewardedAdShowResult.rewardGranted) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _watching = false;
      _statusMessage = switch (result) {
        RewardedAdShowResult.rewardRejectedByEconomy =>
          AppStrings.economyAdRewardRejected,
        RewardedAdShowResult.dismissedWithoutReward =>
          AppStrings.economyAdDismissed,
        RewardedAdShowResult.notAvailable ||
        RewardedAdShowResult.unsupportedPlatform =>
          AppStrings.economyAdNotAvailable,
        RewardedAdShowResult.rewardGranted => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.coins,
      builder: (context, _) {
        final decision = widget.access.checkTimedAccess();
        final canWatch = decision.canWatchRewardedAd && !_watching;
        final adsRemaining = decision.rewardedAdsRemainingInWindow;

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              SalaVerdeSpace.md,
              0,
              SalaVerdeSpace.md,
              SalaVerdeSpace.md,
            ),
            padding: const EdgeInsets.all(SalaVerdeSpace.lg),
            decoration: BoxDecoration(
              color: SalaVerdeColors.surface,
              borderRadius: BorderRadius.circular(SalaVerdeRadius.panel),
              border: Border.all(color: SalaVerdeColors.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.coins.coins}/${CoinsEconomyState.maxCoins} '
                      '${AppStrings.economyCoinsSuffix}',
                      style: SalaVerdeType.bodyStrong(),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: SalaVerdeColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: SalaVerdeSpace.sm),
                Text(
                  AppStrings.economyCoinRecoveryDescription,
                  style: SalaVerdeType.caption(
                      color: SalaVerdeColors.textSecondary),
                ),
                const SizedBox(height: SalaVerdeSpace.xs),
                Text(
                  AppStrings.economyAdsRemainingInWindow(
                      adsRemaining,
                      CoinsEconomyState.maxRewardedAdsPerWindow),
                  style: SalaVerdeType.caption(
                      color: adsRemaining > 0
                          ? SalaVerdeColors.brass
                          : SalaVerdeColors.textMuted),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: SalaVerdeSpace.sm),
                  Text(
                    _statusMessage!,
                    style: SalaVerdeType.caption(
                        color: SalaVerdeColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: SalaVerdeSpace.md),
                SvButtonPrimary(
                  label: AppStrings.economyWatchAdCta,
                  onTap: canWatch ? _watchAd : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
