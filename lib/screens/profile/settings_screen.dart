import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../auth/widgets/account_screen.dart';
import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import 'avatar_picker.dart';
import 'edit_name_sheet.dart';

/// Configuración — pushed desde Perfil (nunca una pestaña propia: "no
/// rutas duplicadas ni sistemas paralelos de navegación"). Vuelve a Perfil
/// con el back nativo del `MaterialPageRoute` — no hace falta nada más.
///
/// Categorías reales únicamente (ver el pedido: "toda opción debe tener
/// comportamiento real"). Deliberadamente NO incluye Apariencia/Sonido/
/// Notificaciones/preferencias de Academia: hoy no hay tema claro, ni
/// infraestructura de audio, ni de notificaciones, ni una preferencia de
/// aprendizaje real que ajustar (ver el resumen que acompaña este cambio)
/// — agregar esas secciones sería exactamente los "controles que no hacen
/// nada" que el pedido pide evitar.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AuthController controller;

  String _ownerId() => controller.currentUser?.id ?? '';

  Future<void> _changePhoto(BuildContext context) async {
    final path = await pickAndSaveAvatar(context, ownerId: _ownerId());
    if (path == null) return;
    await controller.updateAvatarPath(path);
  }

  Future<void> _editName(BuildContext context) async {
    final current = controller.currentUser?.displayName ?? '';
    final name = await showEditNameSheet(context, currentName: current);
    if (name == null) return;
    await controller.updateDisplayName(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final authenticated = controller.isAuthenticated;
            return LayoutBuilder(builder: (context, constraints) {
              final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: SalaVerdeColors.textPrimary),
                        ),
                        const SizedBox(width: 4),
                        Text(AppStrings.settingsTitle, style: SalaVerdeType.title()),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(pad, 8, pad, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _CategoryHeader(label: AppStrings.settingsSectionAccount),
                          const SizedBox(height: SalaVerdeSpace.sm),
                          SvSurfacePanel(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                _SettingsRow(
                                  icon: Icons.badge_rounded,
                                  label: AppStrings.settingsEditName,
                                  onTap: () => _editName(context),
                                ),
                                const _RowDivider(),
                                _SettingsRow(
                                  icon: Icons.photo_camera_rounded,
                                  label: AppStrings.settingsChangePhoto,
                                  onTap: () => _changePhoto(context),
                                ),
                                if (authenticated) ...[
                                  const _RowDivider(),
                                  _SettingsRow(
                                    icon: Icons.shield_rounded,
                                    label: AppStrings.settingsAccountManage,
                                    subtitle: AppStrings.settingsAccountManageBody,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AccountScreen(controller: controller),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: SalaVerdeSpace.xl),
                          const _CategoryHeader(label: AppStrings.settingsSectionPrivacy),
                          const SizedBox(height: SalaVerdeSpace.sm),
                          SvSurfacePanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppStrings.settingsPrivacyDataTitle,
                                  style: SalaVerdeType.bodyStrong(),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppStrings.settingsPrivacyDataBody,
                                  style: SalaVerdeType.caption(
                                    color: SalaVerdeColors.textSecondary,
                                  ),
                                ),
                                if (authenticated) ...[
                                  const SizedBox(height: SalaVerdeSpace.md),
                                  _SettingsRow(
                                    icon: Icons.delete_outline_rounded,
                                    label: AppStrings.settingsPrivacyDelete,
                                    danger: true,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AccountScreen(controller: controller),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: SalaVerdeSpace.xl),
                          const _CategoryHeader(label: AppStrings.settingsSectionInfo),
                          const SizedBox(height: SalaVerdeSpace.sm),
                          const SvSurfacePanel(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                _SettingsRow(
                                  icon: Icons.info_outline_rounded,
                                  label: AppStrings.settingsInfoAbout,
                                  subtitle: AppStrings.settingsInfoAboutBody,
                                ),
                                _RowDivider(),
                                _SettingsRow(
                                  icon: Icons.numbers_rounded,
                                  label: AppStrings.settingsInfoVersion,
                                  trailingText: '0.2.0',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            });
          },
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: SalaVerdeType.label(color: SalaVerdeColors.brassBright),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: SalaVerdeColors.borderSubtle);
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailingText,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final String? trailingText;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = danger ? SalaVerdeColors.errorBright : SalaVerdeColors.textPrimary;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SalaVerdeSpace.lg,
        vertical: SalaVerdeSpace.md,
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: danger ? SalaVerdeColors.errorBright : SalaVerdeColors.textSecondary),
          const SizedBox(width: SalaVerdeSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SalaVerdeType.bodyStrong(color: color)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailingText != null)
            Text(
              trailingText!,
              style: SalaVerdeType.numeric(color: SalaVerdeColors.textSecondary),
            )
          else if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: SalaVerdeColors.textMuted),
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}
