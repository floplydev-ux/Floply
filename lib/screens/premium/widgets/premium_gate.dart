import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/premium/premium_service.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../premium_paywall_screen.dart';

/// Envuelve contenido Premium — muestra [builder] cuando el usuario tiene
/// acceso, un indicador de carga mientras RC resuelve el estado inicial,
/// o una pantalla de bloqueo con CTA al paywall si no tiene Premium.
///
/// Se usa tanto en el IndexedStack de [AppShell] (tab Coach) como en rutas
/// modales empujadas desde Home — en ambos casos el comportamiento es
/// idéntico: la pantalla real nunca llega a montarse si el usuario no es
/// Premium.
class PremiumGate extends StatelessWidget {
  const PremiumGate({
    super.key,
    required this.premium,
    required this.builder,
  });

  final PremiumService premium;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: premium,
      builder: (context, _) {
        if (premium.isLoading) {
          return const _PremiumLoadingView();
        }
        if (premium.isPremium) {
          return builder(context);
        }
        return _PremiumLockedView(premium: premium);
      },
    );
  }
}

class _PremiumLoadingView extends StatelessWidget {
  const _PremiumLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: SalaVerdeColors.brassBright,
          ),
        ),
      ),
    );
  }
}

class _PremiumLockedView extends StatelessWidget {
  const _PremiumLockedView({required this.premium});

  final PremiumService premium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      appBar: AppBar(
        backgroundColor: SalaVerdeColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: SalaVerdeColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SalaVerdeSpace.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.sports_rounded,
                color: SalaVerdeColors.brass,
                size: 52,
              ),
              const SizedBox(height: SalaVerdeSpace.lg),
              Text(
                AppStrings.premiumLockedTitle,
                style: SalaVerdeType.headline(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SalaVerdeSpace.sm),
              Text(
                AppStrings.premiumLockedBody,
                style:
                    SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SalaVerdeSpace.xl),
              SvButtonPrimary(
                label: AppStrings.premiumLockedCta,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PremiumPaywallScreen(premium: premium),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
