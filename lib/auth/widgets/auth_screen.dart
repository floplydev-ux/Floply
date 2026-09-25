import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import '../auth_controller.dart';
import 'account_conflict_sheet.dart';
import 'email_link_screen.dart';

/// Pantalla de acceso (Fase 22): simple, moderna, sin convertirse en una
/// pantalla enorme. Solo habla con [AuthController] — nunca con Firebase
/// directo (Fase 24).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _busy = false;

  Future<void> _run(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final conflict = widget.controller.pendingConflict;
    if (conflict != null && mounted) {
      await showAccountConflictSheet(context, widget.controller, conflict);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final failure = widget.controller.lastFailure;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.backgroundGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Wordmark(),
                          const SizedBox(height: 48),
                          if (failure != null) ...[
                            _ErrorBanner(
                              message: authErrorMessage(failure),
                              onDismiss: widget.controller.clearLastFailure,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _ProviderButton(
                            label: AppStrings.authContinueGoogle,
                            glyph: 'G',
                            background: Colors.white,
                            foreground: Colors.black87,
                            busy: _busy,
                            onTap: () =>
                                _run(widget.controller.signInWithGoogle),
                          ),
                          const SizedBox(height: 12),
                          _ProviderButton(
                            label: AppStrings.authContinueApple,
                            icon: Icons.apple_rounded,
                            background: Colors.black,
                            foreground: Colors.white,
                            busy: _busy,
                            onTap: () =>
                                _run(widget.controller.signInWithApple),
                          ),
                          const SizedBox(height: 20),
                          const _OrDivider(),
                          const SizedBox(height: 20),
                          _ProviderButton(
                            label: AppStrings.authContinueEmail,
                            icon: Icons.mail_outline_rounded,
                            background: AppColors.surfaceElevated,
                            foreground: AppColors.textPrimary,
                            outline: true,
                            busy: _busy,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EmailLinkScreen(
                                    controller: widget.controller,
                                    mode: EmailLinkMode.signIn,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: PressableScale(
                              onTap: _busy
                                  ? () {}
                                  : () => widget.controller.continueAsGuest(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                child: Text(
                                  AppStrings.authContinueWithoutAccount,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: AppColors.violetGradient,
          ).createShader(bounds),
          child: const Text(
            'FLOPly',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          AppStrings.authTagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.surfaceBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            AppStrings.authOr.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.surfaceBorder)),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.busy,
    required this.onTap,
    this.icon,
    this.glyph,
    this.outline = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool busy;
  final VoidCallback onTap;
  final IconData? icon;
  final String? glyph;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: PressableScale(
        onTap: busy ? () {} : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: outline ? Border.all(color: AppColors.surfaceBorder) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, size: 20, color: foreground),
              if (glyph != null)
                Text(
                  glyph!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: foreground,
                  ),
                ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: foreground,
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
            ),
          ),
          PressableScale(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
