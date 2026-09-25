import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/user_avatar.dart';
import '../auth_controller.dart';
import '../models/auth_provider_type.dart';
import '../models/auth_state.dart';
import '../models/floply_user.dart';
import 'account_conflict_sheet.dart';
import 'auth_screen.dart';
import 'email_link_screen.dart';

/// Perfil → Cuenta (Fase 8/16/17/18): métodos de acceso vinculados,
/// cerrar sesión, eliminar cuenta. Reemplaza al `ComingSoonScreen` del
/// tab Perfil — ese placeholder está documentado para intercambiarse así
/// apenas exista la pantalla real.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _busy = false;

  Future<void> _link(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      final conflict = widget.controller.pendingConflict;
      if (conflict != null) {
        await showAccountConflictSheet(context, widget.controller, conflict);
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ConfirmDialog(
        title: AppStrings.accountSignOut,
        body: AppStrings.accountSignOutConfirm,
        confirmLabel: AppStrings.accountSignOut,
        danger: false,
      ),
    );
    if (confirmed == true) await widget.controller.signOut();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ConfirmDialog(
        title: AppStrings.accountDelete,
        body: AppStrings.accountDeleteWarning,
        confirmLabel: AppStrings.accountDeleteConfirm,
        danger: true,
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    final ok = await widget.controller.deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok && widget.controller.lastFailure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(authErrorMessage(widget.controller.lastFailure!))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.backgroundGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: state is AuthAuthenticated
                ? _AuthenticatedBody(
                    controller: widget.controller,
                    user: state.user,
                    busy: _busy,
                    onLink: _link,
                    onSignOut: _confirmSignOut,
                    onDelete: _confirmDelete,
                  )
                : _GuestBody(controller: widget.controller),
          ),
        );
      },
    );
  }
}

class _GuestBody extends StatelessWidget {
  const _GuestBody({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violetPrimary.withValues(alpha: 0.18),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  size: 34, color: AppColors.violetSoft),
            ),
            const SizedBox(height: 18),
            const Text(
              AppStrings.accountGuestTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.accountGuestBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            PressableScale(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AuthScreen(controller: controller),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient:
                      const LinearGradient(colors: AppColors.violetGradient),
                ),
                child: const Text(
                  AppStrings.accountCreateCta,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthenticatedBody extends StatelessWidget {
  const _AuthenticatedBody({
    required this.controller,
    required this.user,
    required this.busy,
    required this.onLink,
    required this.onSignOut,
    required this.onDelete,
  });

  final AuthController controller;
  final FloplyUser user;
  final bool busy;
  final Future<void> Function(Future<bool> Function()) onLink;
  final VoidCallback onSignOut;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.accountTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              UserAvatar(
                displayName: user.displayName,
                photoUrl: user.avatarUrl,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (user.email != null)
                      Text(
                        user.email!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            AppStrings.accountMethodsTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.accountMethodsBody,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          for (final type in AuthProviderType.values) ...[
            _MethodRow(
              type: type,
              linked: user.hasProvider(type),
              busy: busy,
              onLink: () => onLink(() => switch (type) {
                    AuthProviderType.google => controller.linkGoogle(),
                    AuthProviderType.apple => controller.linkApple(),
                    AuthProviderType.email => Navigator.of(context)
                        .push<bool>(MaterialPageRoute(
                          builder: (_) => EmailLinkScreen(
                            controller: controller,
                            mode: EmailLinkMode.link,
                          ),
                        ))
                        .then((_) => true),
                  }),
              onUnlink: () => controller.unlink(type),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 24),
          _ActionRow(
            icon: Icons.logout_rounded,
            label: AppStrings.accountSignOut,
            onTap: onSignOut,
          ),
          const SizedBox(height: 8),
          _ActionRow(
            icon: Icons.delete_outline_rounded,
            label: AppStrings.accountDelete,
            onTap: onDelete,
            danger: true,
          ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.type,
    required this.linked,
    required this.busy,
    required this.onLink,
    required this.onUnlink,
  });

  final AuthProviderType type;
  final bool linked;
  final bool busy;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  String get _label => switch (type) {
        AuthProviderType.google => 'Google',
        AuthProviderType.apple => 'Apple',
        AuthProviderType.email => 'Email',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(
            linked ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: linked ? AppColors.neonGreenBright : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Opacity(
            opacity: busy ? 0.5 : 1,
            child: PressableScale(
              onTap: busy ? () {} : (linked ? onUnlink : onLink),
              child: Text(
                linked ? AppStrings.accountUnlink : AppStrings.accountLink,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: linked ? AppColors.textMuted : AppColors.violetBright,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: danger
                ? AppColors.danger.withValues(alpha: 0.35)
                : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.danger,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      content:
          Text(body, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.accountCancel,
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: danger ? AppColors.danger : AppColors.violetBright,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
