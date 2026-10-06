import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../services/premium/premium_service.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import '../../widgets/user_avatar.dart';
import '../academy/academy_controller.dart';
import '../home/widgets/home_progress_section.dart';
import '../premium/premium_paywall_screen.dart';
import 'settings_screen.dart';

/// Perfil — tab 4 de [AppBottomNavigation]. Identidad del usuario +
/// tipo de cuenta + progreso + configuración + cerrar sesión.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.authController,
    required this.academyController,
    required this.premium,
    required this.onGoToAcademy,
    required this.onGoToLaboratory,
  });

  final AuthController authController;
  final AcademyController academyController;
  final PremiumService premium;
  final VoidCallback onGoToAcademy;
  final VoidCallback onGoToLaboratory;

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SalaVerdeColors.surface,
        title: Text(AppStrings.accountSignOut, style: SalaVerdeType.headline()),
        content: Text(AppStrings.accountSignOutConfirm, style: SalaVerdeType.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.accountCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              AppStrings.accountSignOut,
              style: TextStyle(color: SalaVerdeColors.errorBright),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await authController.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([authController, academyController, premium]),
          builder: (context, _) {
            final displayName = AppUser.current.displayName;
            final photoUrl = AppUser.current.photoUrl;

            return LayoutBuilder(builder: (context, constraints) {
              final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pad, 20, pad, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _IdentityCard(
                      displayName: displayName,
                      photoUrl: photoUrl,
                      email: authController.currentUser?.email,
                    ),
                    const SizedBox(height: SalaVerdeSpace.lg),
                    _AccountTypeSection(premium: premium),
                    const SizedBox(height: SalaVerdeSpace.lg),
                    HomeProgressSection(
                      controller: academyController,
                      onGoToAcademy: onGoToAcademy,
                      onGoToLaboratory: onGoToLaboratory,
                    ),
                    const SizedBox(height: SalaVerdeSpace.lg),
                    const _LanguageOption(),
                    const SizedBox(height: SalaVerdeSpace.lg),
                    _SettingsEntry(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SettingsScreen(controller: authController),
                        ),
                      ),
                    ),
                    const SizedBox(height: SalaVerdeSpace.xl),
                    _SignOutButton(onTap: () => _confirmSignOut(context)),
                  ],
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.displayName,
    required this.photoUrl,
    required this.email,
  });

  final String displayName;
  final String? photoUrl;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return SvSurfacePanel(
      child: Column(
        children: [
          UserAvatar(displayName: displayName, photoUrl: photoUrl, size: 84),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(displayName, style: SalaVerdeType.headline()),
          if (email != null) ...[
            const SizedBox(height: 4),
            Text(
              email!,
              style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountTypeSection extends StatelessWidget {
  const _AccountTypeSection({required this.premium});

  final PremiumService premium;

  @override
  Widget build(BuildContext context) {
    final isPremium = premium.isPremium;
    return SvSurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                AppStrings.profileAccountType,
                style: SalaVerdeType.caption(
                    color: SalaVerdeColors.textSecondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPremium
                      ? SalaVerdeColors.brass.withValues(alpha: 0.15)
                      : SalaVerdeColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isPremium
                        ? SalaVerdeColors.brass
                        : SalaVerdeColors.textMuted.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  isPremium
                      ? AppStrings.profileAccountPremium
                      : AppStrings.profileAccountFree,
                  style: SalaVerdeType.caption(
                    color: isPremium
                        ? SalaVerdeColors.brass
                        : SalaVerdeColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (!isPremium) ...[
            const SizedBox(height: SalaVerdeSpace.md),
            SvButtonPrimary(
              label: AppStrings.profileUpgradeCta,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PremiumPaywallScreen(premium: premium),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption();

  @override
  Widget build(BuildContext context) {
    return SvSurfacePanel(
      child: Row(
        children: [
          const Icon(Icons.language_rounded,
              color: SalaVerdeColors.textSecondary, size: 22),
          const SizedBox(width: SalaVerdeSpace.md),
          Expanded(
            child: Text(
              AppStrings.profileLanguageLabel,
              style: SalaVerdeType.bodyStrong(),
            ),
          ),
          Text(
            AppStrings.toolsComingSoonLabel,
            style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SvTappableCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.settings_rounded,
              color: SalaVerdeColors.brassBright, size: 22),
          const SizedBox(width: SalaVerdeSpace.md),
          Expanded(
            child: Text(
              AppStrings.profileSettingsCta,
              style: SalaVerdeType.bodyStrong(),
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: SalaVerdeColors.textMuted),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SvTappableCard(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout_rounded,
              color: SalaVerdeColors.errorBright, size: 20),
          const SizedBox(width: SalaVerdeSpace.sm),
          Text(
            AppStrings.accountSignOut,
            style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.errorBright),
          ),
        ],
      ),
    );
  }
}
