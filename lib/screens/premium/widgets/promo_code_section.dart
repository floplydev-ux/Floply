import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/promo/promo_code_failure.dart';
import '../../../services/promo/promo_code_service.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// Bloque de canje de código promocional para [PremiumPaywallScreen].
///
/// Muestra un campo de texto y un botón "CANJEAR CÓDIGO". Gestiona
/// internamente los estados: inicial / cargando / éxito / error.
class PromoCodeSection extends StatefulWidget {
  const PromoCodeSection({super.key, required this.promoService});

  final PromoCodeService promoService;

  @override
  State<PromoCodeSection> createState() => _PromoCodeSectionState();
}

class _PromoCodeSectionState extends State<PromoCodeSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _busy = false;
  _PromoState _state = const _PromoIdle();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _busy) return;
    _focusNode.unfocus();
    setState(() {
      _busy = true;
      _state = const _PromoIdle();
    });
    final result = await widget.promoService.redeem(code);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _state = switch (result) {
        PromoCodeSuccess(:final benefitLabel) => _PromoSuccess(benefitLabel),
        PromoCodeFailure(:final reason) => _PromoError(_errorMessage(reason)),
      };
    });
  }

  String _errorMessage(PromoCodeFailureReason reason) => switch (reason) {
        PromoCodeFailureReason.notFound => AppStrings.promoErrorNotFound,
        PromoCodeFailureReason.inactive => AppStrings.promoErrorInactive,
        PromoCodeFailureReason.notStarted => AppStrings.promoErrorNotStarted,
        PromoCodeFailureReason.expired => AppStrings.promoErrorExpired,
        PromoCodeFailureReason.exhausted => AppStrings.promoErrorExhausted,
        PromoCodeFailureReason.alreadyRedeemed =>
          AppStrings.promoErrorAlreadyRedeemed,
        PromoCodeFailureReason.unauthenticated =>
          AppStrings.promoErrorUnauthenticated,
        PromoCodeFailureReason.serverError => AppStrings.promoErrorServer,
      };

  @override
  Widget build(BuildContext context) {
    return SvSurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 16,
                color: SalaVerdeColors.brassBright,
              ),
              const SizedBox(width: SalaVerdeSpace.sm),
              Text(
                AppStrings.promoSectionTitle,
                style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.brassBright),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          // Campo de texto
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            ],
            style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.textPrimary),
            decoration: InputDecoration(
              hintText: AppStrings.promoFieldHint,
              hintStyle: SalaVerdeType.body(color: SalaVerdeColors.textMuted),
              filled: true,
              fillColor: SalaVerdeColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: SalaVerdeSpace.lg,
                vertical: SalaVerdeSpace.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
                borderSide: const BorderSide(color: SalaVerdeColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
                borderSide: const BorderSide(color: SalaVerdeColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
                borderSide: const BorderSide(
                  color: SalaVerdeColors.brassBright,
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (_) => _redeem(),
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          // Botón
          SvButtonSecondary(
            label: _busy ? AppStrings.promoRedeeming : AppStrings.promoRedeemButton,
            onTap: _busy ? null : _redeem,
          ),
          // Feedback
          if (_state is _PromoSuccess) ...[
            const SizedBox(height: SalaVerdeSpace.md),
            _PromoSuccessView(benefit: (_state as _PromoSuccess).benefitLabel),
          ],
          if (_state is _PromoError) ...[
            const SizedBox(height: SalaVerdeSpace.sm),
            Text(
              (_state as _PromoError).message,
              style: SalaVerdeType.caption(color: SalaVerdeColors.errorBright),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _PromoSuccessView extends StatelessWidget {
  const _PromoSuccessView({required this.benefit});

  final String benefit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SalaVerdeSpace.lg,
        vertical: SalaVerdeSpace.sm,
      ),
      decoration: BoxDecoration(
        color: SalaVerdeColors.feltGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        border: Border.all(color: SalaVerdeColors.feltGreenBright.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: SalaVerdeColors.feltGreenBright,
              ),
              const SizedBox(width: SalaVerdeSpace.sm),
              Text(
                AppStrings.promoSuccessTitle,
                style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.feltGreenBright),
              ),
            ],
          ),
          if (benefit.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                benefit,
                style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Estados internos del widget
sealed class _PromoState {
  const _PromoState();
}

class _PromoIdle extends _PromoState {
  const _PromoIdle();
}

class _PromoSuccess extends _PromoState {
  const _PromoSuccess(this.benefitLabel);
  final String benefitLabel;
}

class _PromoError extends _PromoState {
  const _PromoError(this.message);
  final String message;
}
