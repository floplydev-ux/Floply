import 'package:flutter/material.dart' hide Card;

import '../../engine/poker/card.dart';
import '../../engine/poker/combos/combo_engine.dart';
import '../../engine/poker/hole_cards.dart';
import '../../engine/strategy/hand_range.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import 'widgets/tool_widgets.dart';

/// Blocker Explorer — sexta herramienta real de Tools (parte de V2, ver
/// `AUDITORIA_CHECKLIST_2026-09-18.md` §6).
///
/// Responde una pregunta puntual: de un rango rival, ¿cuántos combos
/// bloquean las dos cartas de tu mano (más el board, si hay)? Reutiliza
/// [ComboEngine] tal cual existe — corre el mismo cálculo dos veces con
/// distintas `deadCards` (solo board, vs. board + tu mano) y compara.
/// No suma ningún concepto nuevo al motor: es la misma idea del Combo
/// Calculator (combos totales vs. disponibles) pero aplicada a un
/// rango entero en vez de una sola clase, para responder
/// "¿qué tanto bloqueo con esta mano?" en vez de "¿cuántos combos me
/// quedan de esta clase?".
///
/// **Por qué recalcula en vivo** (a diferencia de mano vs rango/rango
/// vs rango del Equity Calculator): acá no hay runouts que enumerar —
/// es pura combinatoria de card removal, como mucho 169 clases × 12
/// combos, miles de operaciones, no millones. Ningún motivo para
/// gatillarlo con un botón aparte.
class BlockerExplorerScreen extends StatefulWidget {
  const BlockerExplorerScreen({super.key});

  @override
  State<BlockerExplorerScreen> createState() => _BlockerExplorerScreenState();
}

class _BlockerExplorerScreenState extends State<BlockerExplorerScreen> {
  final _heroController = TextEditingController(text: 'AhKd');
  final _villainRangeController = TextEditingController(text: 'QQ+,AKs,AKo');
  final _boardController = TextEditingController(text: '');

  _BlockerResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _villainRangeController.dispose();
    _boardController.dispose();
    super.dispose();
  }

  static HoleCards? _tryParseHand(String text) {
    try {
      return HoleCards.parse(text.trim().replaceAll(' ', ''));
    } catch (_) {
      return null;
    }
  }

  /// `null` si la notación es inválida; lista vacía si el board está
  /// vacío (board vacío = análisis preflop, entrada válida).
  static List<Card>? _tryParseBoard(String text) {
    final clean = text.trim().replaceAll(' ', '');
    if (clean.isEmpty) return const [];
    if (clean.length != 6 && clean.length != 8 && clean.length != 10) return null;
    try {
      return [
        for (var i = 0; i < clean.length; i += 2) Card.parse(clean.substring(i, i + 2)),
      ];
    } catch (_) {
      return null;
    }
  }

  static HandRange? _tryParseRange(String text) {
    final tokens = text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;
    try {
      final range = HandRange.parse(tokens);
      return range.classes.isEmpty ? null : range;
    } catch (_) {
      return null;
    }
  }

  void _recalculate() {
    final hero = _tryParseHand(_heroController.text);
    final board = _tryParseBoard(_boardController.text);
    if (hero == null) {
      setState(() {
        _result = null;
        _error = AppStrings.blockerInvalidHand;
      });
      return;
    }
    if (board == null) {
      setState(() {
        _result = null;
        _error = AppStrings.blockerInvalidBoard;
      });
      return;
    }
    final known = [...hero.cards, ...board];
    if (known.toSet().length != known.length) {
      setState(() {
        _result = null;
        _error = AppStrings.blockerInvalidBoard;
      });
      return;
    }
    final villainRange = _tryParseRange(_villainRangeController.text);
    if (villainRange == null) {
      setState(() {
        _result = null;
        _error = AppStrings.blockerInvalidRange;
      });
      return;
    }

    final deadBoardOnly = board;
    final deadHeroAndBoard = known;

    final total =
        ComboEngine.combosForRange(villainRange, deadCards: deadBoardOnly).length;
    if (total == 0) {
      setState(() {
        _result = null;
        _error = AppStrings.blockerEmptyRangeError;
      });
      return;
    }
    final available =
        ComboEngine.combosForRange(villainRange, deadCards: deadHeroAndBoard).length;

    final classes = <_ClassBlockInfo>[];
    for (final handClass in HandClass.all()) {
      if (villainRange.frequencyOf(handClass.notation) <= 0) continue;
      final before = ComboEngine.comboCount(handClass, deadCards: deadBoardOnly);
      if (before == 0) continue;
      final after = ComboEngine.comboCount(handClass, deadCards: deadHeroAndBoard);
      classes.add(_ClassBlockInfo(handClass.notation, before, after));
    }

    setState(() {
      _result = _BlockerResult(total: total, available: available, classes: classes);
      _error = null;
    });
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
          child: LayoutBuilder(builder: (context, constraints) {
            final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ToolHeader(
                    icon: Icons.block_rounded,
                    accentColor: AppColors.danger,
                    title: AppStrings.toolsBlockerTitle,
                    subtitle: AppStrings.toolsBlockerCalculatorSubtitle,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 20),
                  ToolCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ToolTextField(
                          label: AppStrings.blockerHeroLabel,
                          controller: _heroController,
                          onChanged: _recalculate,
                          hintText: AppStrings.blockerHeroHint,
                          accentColor: AppColors.danger,
                        ),
                        const SizedBox(height: 14),
                        ToolTextField(
                          label: AppStrings.blockerVillainRangeLabel,
                          controller: _villainRangeController,
                          onChanged: _recalculate,
                          hintText: AppStrings.blockerVillainRangeHint,
                          accentColor: AppColors.danger,
                        ),
                        const SizedBox(height: 14),
                        ToolTextField(
                          label: AppStrings.blockerBoardLabel,
                          controller: _boardController,
                          onChanged: _recalculate,
                          hintText: AppStrings.blockerBoardHint,
                          accentColor: AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    ToolErrorCard(message: _error!)
                  else if (_result != null)
                    _ResultSection(result: _result!),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BlockerResult {
  const _BlockerResult({
    required this.total,
    required this.available,
    required this.classes,
  });

  final int total;
  final int available;
  final List<_ClassBlockInfo> classes;
}

class _ClassBlockInfo {
  const _ClassBlockInfo(this.notation, this.before, this.after);

  final String notation;
  final int before;
  final int after;

  bool get isFullyBlocked => after == 0;
  bool get isPartiallyBlocked => after > 0 && after < before;
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.result});

  final _BlockerResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          gradientColors: const [Color(0xFF3A1620), Color(0xFF240D14)],
          borderColor: AppColors.danger.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.blockerTotalLabel,
                      value: '${result.total}',
                      big: true,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.blockerAvailableLabel,
                      value: '${result.available}',
                      big: true,
                      color: AppColors.neonGreen,
                    ),
                  ),
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.blockerBlockedLabel,
                      value: '${result.total - result.available}',
                      big: true,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.blockerExplanation(
                  total: result.total,
                  available: result.available,
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ToolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                AppStrings.blockerClassesHeader,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final classInfo in result.classes) _ClassChip(info: classInfo),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClassChip extends StatelessWidget {
  const _ClassChip({required this.info});

  final _ClassBlockInfo info;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color textColor;
    if (info.isFullyBlocked) {
      background = AppColors.danger.withValues(alpha: 0.18);
      textColor = AppColors.danger;
    } else if (info.isPartiallyBlocked) {
      background = AppColors.gold.withValues(alpha: 0.18);
      textColor = AppColors.gold;
    } else {
      background = AppColors.surfaceElevated;
      textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: background,
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${info.notation} ${info.after}/${info.before}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
