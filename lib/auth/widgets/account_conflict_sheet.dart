import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import '../auth_controller.dart';
import '../models/account_conflict.dart';
import '../models/auth_provider_type.dart';

/// Fase 9: el método que se acaba de intentar ya está asociado a otra
/// cuenta Floply. Nunca se fusiona nada solo — se lo decimos al usuario y
/// dejamos elegir explícitamente: volver a intentar con ese mismo método
/// (que va a entrar a la cuenta que ya existe) o cancelar.
Future<void> showAccountConflictSheet(
  BuildContext context,
  AuthController controller,
  AccountConflict conflict,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _AccountConflictSheetBody(
      controller: controller,
      conflict: conflict,
    ),
  ).whenComplete(controller.dismissConflict);
}

class _AccountConflictSheetBody extends StatefulWidget {
  const _AccountConflictSheetBody({
    required this.controller,
    required this.conflict,
  });

  final AuthController controller;
  final AccountConflict conflict;

  @override
  State<_AccountConflictSheetBody> createState() =>
      _AccountConflictSheetBodyState();
}

class _AccountConflictSheetBodyState extends State<_AccountConflictSheetBody> {
  bool _busy = false;

  Future<void> _signInToExisting() async {
    setState(() => _busy = true);
    final provider = widget.conflict.attemptedProvider;
    final ok = switch (provider) {
      AuthProviderType.google => await widget.controller.signInWithGoogle(),
      AuthProviderType.apple => await widget.controller.signInWithApple(),
      // El email ya pasó por su propia pantalla — reintentar acá no
      // aplica del mismo modo; se cierra y el usuario reintenta desde ahí.
      AuthProviderType.email => false,
    };
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: AppColors.surfaceBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Icon(Icons.info_outline_rounded,
              color: AppColors.gold, size: 28),
          const SizedBox(height: 12),
          const Text(
            AppStrings.accountConflictTitle,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.accountConflictBody(widget.conflict.existingEmail),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          Opacity(
            opacity: _busy ? 0.6 : 1,
            child: PressableScale(
              onTap: _busy ? () {} : _signInToExisting,
              child: Container(
                constraints: const BoxConstraints(minHeight: 50),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient:
                      const LinearGradient(colors: AppColors.violetGradient),
                ),
                child: const Text(
                  AppStrings.accountConflictSignIn,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          PressableScale(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              alignment: Alignment.center,
              child: const Text(
                AppStrings.accountConflictCancel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
