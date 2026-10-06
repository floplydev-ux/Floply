import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/ads/rewarded_ad_service.dart';
import '../../../services/economy/economy_access_service.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// "Te quedaste sin tiempo disponible" — la única UI de bloqueo
/// económico de toda la app (Tools, Coach, entrenamiento extra): se usa
/// tanto para el gate de entrada (no se pudo ni empezar) como para el
/// aviso que aparece ENCIMA de una sesión que se quedó sin Coins a mitad
/// de camino (ver `EconomyGate`) — mismo contenido, mismo
/// comportamiento, nunca dos pantallas de bloqueo distintas.
///
/// Nunca un error silencioso: siempre explica el motivo (anuncio
/// disponible o no, y por qué) y ofrece las dos salidas reales —
/// publicidad o esperar la regeneración — nunca más que eso.
class EconomyBlockedView extends StatefulWidget {
  const EconomyBlockedView({
    super.key,
    required this.access,
    required this.decision,
    required this.title,
    required this.body,
    required this.onAdResult,
    this.onWait,
  });

  final EconomyAccessService access;
  final EconomyAccessDecision decision;
  final String title;
  final String body;

  /// El resultado real del anuncio, para que quien envuelve esta vista
  /// decida si corresponde volver a chequear el acceso (p. ej.
  /// [EconomyGate] recalcula y sale del estado bloqueado si ya alcanza).
  final ValueChanged<RewardedAdShowResult> onAdResult;

  /// "Esperar regeneración" — puramente informativo (nunca dispara una
  /// acción económica): `null` cuando no hace falta nada más que mostrar
  /// el texto (el botón queda sin `onTap`, deshabilitado).
  final VoidCallback? onWait;

  @override
  State<EconomyBlockedView> createState() => _EconomyBlockedViewState();
}

class _EconomyBlockedViewState extends State<EconomyBlockedView> {
  bool _watching = false;
  String? _statusMessage;

  Future<void> _watchAd() async {
    setState(() {
      _watching = true;
      _statusMessage = AppStrings.economyWatchingAd;
    });
    final result = await widget.access.watchRewardedAd();
    if (!mounted) return;
    setState(() {
      _watching = false;
      _statusMessage = switch (result) {
        RewardedAdShowResult.rewardGranted => AppStrings.economyAdRewardGranted,
        RewardedAdShowResult.rewardRejectedByEconomy => AppStrings.economyAdRewardRejected,
        RewardedAdShowResult.dismissedWithoutReward => AppStrings.economyAdDismissed,
        RewardedAdShowResult.notAvailable ||
        RewardedAdShowResult.unsupportedPlatform =>
          AppStrings.economyAdNotAvailable,
      };
    });
    widget.onAdResult(result);
  }

  /// `null` cuando el botón debe quedar habilitado. Solo se llama cuando
  /// [EconomyAccessDecision.canWatchRewardedAd] ya es `false` — acá solo
  /// hace falta distinguir POR QUÉ (nunca "porque sí").
  String _adDisabledReason() => widget.decision.rewardedAdsRemainingInWindow <= 0
      ? AppStrings.economyAdUnavailableLimit
      : AppStrings.economyAdUnavailableNotReady;

  String? _regenerationHint() {
    final at = widget.decision.nextRegenerationAt;
    if (at == null) return null;
    return AppStrings.economyNextRegenerationInline(_relativeTime(at));
  }

  @override
  Widget build(BuildContext context) {
    final canWatch = widget.decision.canWatchRewardedAd && !_watching;
    final regenHint = _regenerationHint();

    return SvSurfacePanel(
      borderColor: SalaVerdeColors.warning.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_off_rounded,
                  size: 18, color: SalaVerdeColors.warning),
              const SizedBox(width: SalaVerdeSpace.sm),
              Expanded(
                child: Text(widget.title, style: SalaVerdeType.bodyStrong()),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(widget.body,
              style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary)),
          if (regenHint != null) ...[
            const SizedBox(height: 6),
            Text(regenHint,
                style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted)),
          ],
          const SizedBox(height: SalaVerdeSpace.md),
          SvButtonPrimary(
            label: _watching ? AppStrings.economyWatchingAd : AppStrings.economyWatchAdCta,
            onTap: canWatch ? _watchAd : null,
          ),
          if (!widget.decision.canWatchRewardedAd && !_watching) ...[
            const SizedBox(height: 4),
            Text(_adDisabledReason(),
                style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted)),
          ],
          const SizedBox(height: SalaVerdeSpace.sm),
          SvButtonSecondary(
            label: AppStrings.economyWaitRegenerationCta,
            onTap: widget.onWait,
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: SalaVerdeSpace.sm),
            Text(_statusMessage!,
                textAlign: TextAlign.center,
                style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// "en 12 min" / "en 1h 5min" / "en un momento" — sin `intl` (el proyecto
/// no lo usa): aritmética simple sobre la diferencia real contra el
/// reloj del dispositivo, suficiente para una pista aproximada.
String _relativeTime(DateTime target) {
  final diff = target.difference(DateTime.now());
  if (diff.inMinutes <= 0) return 'en un momento';
  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  if (hours > 0) {
    return minutes > 0 ? 'en ${hours}h ${minutes}min' : 'en ${hours}h';
  }
  return 'en $minutes min';
}
