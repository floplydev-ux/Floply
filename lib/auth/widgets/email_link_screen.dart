import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import '../auth_controller.dart';

/// Si esta pantalla se usa para el primer acceso, o para vincular email a
/// una cuenta ya autenticada (Fase 8) — el texto y qué método de
/// [AuthController] se llama cambian según esto, la mesa visual es la
/// misma.
enum EmailLinkMode { signIn, link }

/// Fase 5: email sin contraseña. Ingresar email → mandar link → "revisá
/// tu correo". Incluye un campo para pegar el link manualmente: hasta que
/// el dominio propio con App Links/Universal Links esté configurado (ver
/// `AUTH_SETUP.md`), el link abre en el navegador en vez de reabrir la
/// app sola — este campo es el fallback funcional mientras tanto.
class EmailLinkScreen extends StatefulWidget {
  const EmailLinkScreen({
    super.key,
    required this.controller,
    required this.mode,
  });

  final AuthController controller;
  final EmailLinkMode mode;

  @override
  State<EmailLinkScreen> createState() => _EmailLinkScreenState();
}

class _EmailLinkScreenState extends State<EmailLinkScreen> {
  final _emailController = TextEditingController();
  final _linkController = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  bool get _isValidEmail {
    final email = _emailController.text.trim();
    return email.contains('@') && email.contains('.') && email.length > 5;
  }

  Future<void> _send() async {
    if (!_isValidEmail) {
      setState(() => _localError = AppStrings.authEmailInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _localError = null;
    });
    final email = _emailController.text.trim();
    final ok = widget.mode == EmailLinkMode.signIn
        ? await widget.controller.sendEmailSignInLink(email)
        : await widget.controller.sendEmailLinkForLinking(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _sent = true;
    });
  }

  Future<void> _confirm() async {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;
    setState(() => _busy = true);
    final email = _emailController.text.trim();
    final ok = widget.mode == EmailLinkMode.signIn
        ? await widget.controller
            .confirmEmailSignInLink(email: email, link: link)
        : await widget.controller.confirmEmailLink(email: email, link: link);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final failure = widget.controller.lastFailure;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      PressableScale(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceElevated,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _sent
                        ? AppStrings.authEmailSentTitle
                        : AppStrings.authEmailTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sent
                        ? AppStrings.authEmailSentBody(
                            _emailController.text.trim())
                        : AppStrings.authEmailBody,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (failure != null) ...[
                    Text(
                      authErrorMessage(failure),
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.danger),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_localError != null) ...[
                    Text(
                      _localError!,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.danger),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!_sent) ...[
                    _EmailField(controller: _emailController, enabled: !_busy),
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      label: AppStrings.authEmailSend,
                      busy: _busy,
                      onTap: _send,
                    ),
                  ] else ...[
                    TextField(
                      controller: _linkController,
                      enabled: !_busy,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'https://…',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      label: AppStrings.authEmailSend,
                      busy: _busy,
                      onTap: _confirm,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: PressableScale(
                        onTap: _busy ? () {} : _send,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            AppStrings.authEmailResend,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.violetBright,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: AppStrings.authEmailHint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: PressableScale(
        onTap: busy ? () {} : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: AppColors.violetGradient),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
