import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import '../auth_controller.dart';

/// Pantalla de verificación SMS. Recibe el `verificationId` de Firebase,
/// muestra el código enmascarado del teléfono y deja ingresar los 6 dígitos.
/// Al confirmar, llama a [AuthController.createAccountWithPhone] y cierra.
class SmsVerificationScreen extends StatefulWidget {
  const SmsVerificationScreen({
    super.key,
    required this.controller,
    required this.phoneNumber,
    required this.verificationId,
    required this.name,
    required this.email,
    required this.password,
  });

  final AuthController controller;
  final String phoneNumber;
  final String verificationId;
  final String name;
  final String email;
  final String password;

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  static const _resendCooldown = 60;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final id = await widget.controller
        .sendSmsVerificationCode(widget.phoneNumber);
    if (!mounted) return;
    setState(() => _busy = false);
    if (id == null || id.isEmpty) {
      setState(() => _error = AppStrings.authSmsSendFailed);
    } else {
      _startTimer();
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = AppStrings.authSmsCodeInvalid);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final ok = await widget.controller.createAccountWithPhone(
      name: widget.name,
      email: widget.email,
      password: widget.password,
      phoneVerificationId: widget.verificationId,
      smsCode: code,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      // Cuenta creada — la autenticación ya ocurrió; AuthGate llevará al
      // AppShell automáticamente cuando el estado cambie.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final failure = widget.controller.lastFailure;
      setState(() {
        _error = failure != null
            ? authErrorMessage(failure)
            : AppStrings.authSmsVerifyFailed;
      });
      if (failure != null) widget.controller.clearLastFailure();
    }
  }

  String _maskPhone(String phone) {
    if (phone.length < 5) return phone;
    final visible = phone.substring(phone.length - 4);
    return '•••• $visible';
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
              _NavBar(
                onBack: _busy ? null : () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        AppStrings.authSmsTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.authSmsBody(_maskPhone(widget.phoneNumber)),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _CodeField(
                        controller: _codeCtrl,
                        enabled: !_busy,
                        onSubmitted: (_) => _verify(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _InlineError(message: _error!),
                      ],
                      const SizedBox(height: 24),
                      _VerifyButton(busy: _busy, onTap: _verify),
                      const SizedBox(height: 20),
                      _ResendRow(
                        secondsLeft: _secondsLeft,
                        busy: _busy,
                        onResend: _resend,
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: PressableScale(
                          onTap: _busy
                              ? () {}
                              : () => Navigator.of(context).maybePop(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            child: Text(
                              AppStrings.authSmsWrongNumber,
                              style: TextStyle(
                                fontSize: 13,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Componentes privados
// ---------------------------------------------------------------------------

class _NavBar extends StatelessWidget {
  const _NavBar({required this.onBack});

  final VoidCallback? onBack;

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

class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

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
        enabled: enabled,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        onSubmitted: onSubmitted,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 12,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          hintText: AppStrings.authSmsCodeHint,
          hintStyle: TextStyle(
            fontSize: 28,
            letterSpacing: 12,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.busy, required this.onTap});

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
                  AppStrings.authSmsVerifyButton,
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

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.secondsLeft,
    required this.busy,
    required this.onResend,
  });

  final int secondsLeft;
  final bool busy;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final canResend = secondsLeft <= 0 && !busy;
    return Center(
      child: PressableScale(
        onTap: canResend ? onResend : () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Text(
            secondsLeft > 0
                ? AppStrings.authSmsResendIn(secondsLeft)
                : AppStrings.authSmsResend,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: canResend ? AppColors.violetSoft : AppColors.textMuted,
              decoration: canResend ? TextDecoration.underline : null,
              decorationColor: AppColors.violetSoft,
            ),
          ),
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
