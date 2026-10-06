import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/app_prefs.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';

/// Tipo de acceso que muestra la hoja — determina el copy y la Coin que
/// se explicará.
enum CoinUsageContext {
  /// Campo de Entrenamiento — consume cupo diario gratuito; Coins como
  /// respaldo si el cupo se agota.
  training,

  /// Tools — consume tiempo de FLOPly Coins mientras se usa.
  tools,
}

/// Hoja modal que aparece la primera vez que el usuario entra a
/// Entrenamiento o Tools, explicando qué coin se usa y cómo. Tiene un
/// checkbox "No volver a mostrar" que persiste en [AppPrefs].
///
/// Retorna `true` si el usuario tapó "Entrar" y quiere proceder,
/// `false` si cerró la hoja sin confirmar.
class CoinUsageSheet extends StatefulWidget {
  const CoinUsageSheet({super.key, required this.ctx});

  final CoinUsageContext ctx;

  @override
  State<CoinUsageSheet> createState() => _CoinUsageSheetState();

  /// Muestra la hoja y devuelve `true` cuando el usuario confirma "Entrar".
  /// Si el usuario marcó previamente "no volver a mostrar", devuelve `true`
  /// directamente sin abrir ninguna hoja.
  static Future<bool> maybeShow(
    BuildContext context,
    CoinUsageContext ctx,
  ) async {
    final alreadyDismissed = ctx == CoinUsageContext.training
        ? await AppPrefs.trainingCoinShown
        : await AppPrefs.toolsCoinShown;

    if (alreadyDismissed) return true;
    if (!context.mounted) return false;

    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CoinUsageSheet(ctx: ctx),
    );
    return proceed == true;
  }
}

class _CoinUsageSheetState extends State<CoinUsageSheet> {
  bool _dontShow = false;

  String get _title => widget.ctx == CoinUsageContext.training
      ? AppStrings.preEntryTrainingTitle
      : AppStrings.preEntryToolsTitle;

  String get _body => widget.ctx == CoinUsageContext.training
      ? AppStrings.preEntryTrainingCoinsBody
      : AppStrings.preEntryToolsCoinsBody;

  IconData get _icon => widget.ctx == CoinUsageContext.training
      ? Icons.fitness_center_rounded
      : Icons.build_rounded;

  Color get _accent => widget.ctx == CoinUsageContext.training
      ? SalaVerdeColors.feltGreenBright
      : SalaVerdeColors.brass;

  Future<void> _onEnter() async {
    if (_dontShow) {
      if (widget.ctx == CoinUsageContext.training) {
        await AppPrefs.dismissTrainingCoin();
      } else {
        await AppPrefs.dismissToolsCoin();
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SalaVerdeColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SalaVerdeRadius.panel),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        SalaVerdeSpace.lg,
        SalaVerdeSpace.lg,
        SalaVerdeSpace.lg,
        SalaVerdeSpace.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chip de ícono
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.15),
              ),
              child: Icon(_icon, color: _accent, size: 26),
            ),
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: SalaVerdeType.bodyStrong(),
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
          Text(
            _body,
            textAlign: TextAlign.center,
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
          ),
          const SizedBox(height: SalaVerdeSpace.lg),
          // Checkbox "no volver a mostrar"
          GestureDetector(
            onTap: () => setState(() => _dontShow = !_dontShow),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _dontShow,
                    onChanged: (v) => setState(() => _dontShow = v ?? false),
                    activeColor: SalaVerdeColors.violet,
                    side: BorderSide(
                      color: SalaVerdeColors.borderSubtle,
                      width: 1.5,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: SalaVerdeSpace.sm),
                Text(
                  AppStrings.preEntryDontShowAgain,
                  style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: SalaVerdeSpace.lg),
          // Botón Entrar
          PressableScale(
            onTap: _onEnter,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accent.withValues(alpha: 0.75)],
                ),
                borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
              ),
              child: Text(
                AppStrings.preEntryCta,
                style: SalaVerdeType.bodyStrong(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
