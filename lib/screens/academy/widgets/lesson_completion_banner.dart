import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../services/ads/ad_config.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';

/// Banner AdMob que aparece en la pantalla de lección completada.
///
/// Solo visible cuando [isPremium] es `false`. Si el anuncio no carga
/// (sin conexión, sin inventario, error) la pantalla sigue funcionando
/// normalmente — el widget se vuelve invisible sin ruido ni bloqueo.
///
/// Ciclo de vida: carga una sola vez en [didChangeDependencies] y libera
/// el objeto en [dispose]. No crea un anuncio nuevo en cada rebuild.
class LessonCompletionBanner extends StatefulWidget {
  const LessonCompletionBanner({super.key, required this.isPremium});

  final bool isPremium;

  @override
  State<LessonCompletionBanner> createState() => _LessonCompletionBannerState();
}

class _LessonCompletionBannerState extends State<LessonCompletionBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _disposed = false;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.isPremium && !_loadStarted && !kIsWeb) {
      _loadStarted = true;
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final adSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (adSize == null || _disposed) return;

    final ad = BannerAd(
      adUnitId: AdConfig.lessonCompletionBannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (_disposed) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failedAd, _) {
          failedAd.dispose();
          // _loaded permanece false → widget sigue invisible, sin bloqueo.
        },
      ),
    );

    if (_disposed) return;
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _disposed = true;
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPremium || kIsWeb || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: SalaVerdeSpace.lg),
      child: Center(
        child: SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
