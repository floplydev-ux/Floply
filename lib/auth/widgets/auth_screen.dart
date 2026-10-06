import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import '../auth_controller.dart';
import 'account_conflict_sheet.dart';

/// Pantalla de acceso — métodos disponibles: Google y Email+Contraseña.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _busy = false;
  bool _showEmailForm = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _emailAuthError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _signInWithEmail() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    setState(() => _emailAuthError = null);
    await _run(
      () => widget.controller.signInWithEmailPassword(email, password),
    );
    if (!mounted) return;
    final failure = widget.controller.lastFailure;
    if (failure != null) {
      setState(() => _emailAuthError = authErrorMessage(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
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
                          _ProviderButton(
                            label: AppStrings.authContinueGoogle,
                            glyph: 'G',
                            background: Colors.white,
                            foreground: Colors.black87,
                            busy: _busy,
                            onTap: () =>
                                _run(widget.controller.signInWithGoogle),
                          ),
                          const SizedBox(height: 24),
                          const _DividerOr(),
                          const SizedBox(height: 20),
                          if (!_showEmailForm)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showEmailForm = true),
                              child: const Text(
                                AppStrings.authSignInWithEmail,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.textSecondary,
                                ),
                              ),
                            )
                          else
                            _EmailForm(
                              emailCtrl: _emailCtrl,
                              passwordCtrl: _passwordCtrl,
                              busy: _busy,
                              error: _emailAuthError,
                              onSubmit: _signInWithEmail,
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

// ---------------------------------------------------------------------------
// Wordmark
// ---------------------------------------------------------------------------

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
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Divisor "─ o bien ─"
// ---------------------------------------------------------------------------

class _DividerOr extends StatelessWidget {
  const _DividerOr();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.surfaceBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o bien',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.surfaceBorder)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Formulario Email + Contraseña
// ---------------------------------------------------------------------------

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.busy,
    required this.onSubmit,
    this.error,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool busy;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    const inputDecoration = InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF7C6DEF), width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
    );

    return Theme(
      data: Theme.of(context).copyWith(inputDecorationTheme: inputDecoration),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              labelText: AppStrings.authEmailLabel,
              hintText: AppStrings.authEmailHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              labelText: AppStrings.authPasswordLabel,
              hintText: AppStrings.authPasswordHint,
            ),
            onSubmitted: (_) => busy ? null : onSubmit(),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          _ProviderButton(
            label: AppStrings.authSignInButton,
            background: const Color(0xFF7C6DEF),
            foreground: Colors.white,
            busy: busy,
            onTap: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Botón de proveedor (Google, Email)
// ---------------------------------------------------------------------------

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.busy,
    required this.onTap,
    this.glyph,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool busy;
  final VoidCallback onTap;
  final String? glyph;

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
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
