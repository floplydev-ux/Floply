import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import '../auth_controller.dart';
import 'sms_verification_screen.dart';

/// Formulario de creación de cuenta FLOPly.
/// Recoge nombre, email, contraseña y número de teléfono.
/// Al confirmar, envía el SMS y navega a [SmsVerificationScreen].
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty) return AppStrings.authNameRequired;
    if (email.isEmpty || !email.contains('@')) return AppStrings.authEmailInvalid;
    if (password.length < 6) return AppStrings.authPasswordTooShort;
    if (password != confirm) return AppStrings.authPasswordsDoNotMatch;
    if (phone.isEmpty) return AppStrings.authPhoneRequired;
    return null;
  }

  Future<void> _onNext() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final verificationId = await widget.controller.sendSmsVerificationCode(
      _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (verificationId == null || verificationId.isEmpty) {
      setState(() => _error = AppStrings.authSmsSendFailed);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmsVerificationScreen(
          controller: widget.controller,
          phoneNumber: _phoneCtrl.text.trim(),
          verificationId: verificationId,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NavBar(onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        AppStrings.authCreateAccountTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        AppStrings.authCreateAccountSubtitle,
                        style:
                            TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      _FormField(
                        controller: _nameCtrl,
                        label: AppStrings.authNameLabel,
                        hint: AppStrings.authNameHint,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: _emailCtrl,
                        label: AppStrings.authEmailLabel,
                        hint: AppStrings.authEmailHint,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_busy,
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: _passwordCtrl,
                        label: AppStrings.authPasswordLabel,
                        hint: AppStrings.authPasswordHint,
                        obscureText: !_passwordVisible,
                        enabled: !_busy,
                        suffix: _eyeIcon(
                          visible: _passwordVisible,
                          onTap: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: _confirmCtrl,
                        label: AppStrings.authConfirmPasswordLabel,
                        hint: AppStrings.authPasswordHint,
                        obscureText: !_confirmVisible,
                        enabled: !_busy,
                        suffix: _eyeIcon(
                          visible: _confirmVisible,
                          onTap: () => setState(
                              () => _confirmVisible = !_confirmVisible),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: _phoneCtrl,
                        label: AppStrings.authPhoneLabel,
                        hint: AppStrings.authPhoneHint,
                        keyboardType: TextInputType.phone,
                        enabled: !_busy,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _InlineError(message: _error!),
                      ],
                      const SizedBox(height: 24),
                      _SubmitButton(busy: _busy, onTap: _onNext),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eyeIcon({required bool visible, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 20,
        color: AppColors.textMuted,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Componentes privados
// ---------------------------------------------------------------------------

class _NavBar extends StatelessWidget {
  const _NavBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final bool enabled;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: enabled,
        textCapitalization: textCapitalization,
        style:
            const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          labelText: label,
          labelStyle:
              const TextStyle(fontSize: 12, color: AppColors.textMuted),
          hintStyle:
              const TextStyle(fontSize: 14, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: PressableScale(
        onTap: busy ? () {} : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.violetPrimary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  AppStrings.authNextButton,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
        ),
      ),
    );
  }
}
