import 'package:flutter/material.dart' hide Card;

import '../../engine/poker/card.dart';
import '../../engine/poker/combos/combo_engine.dart';
import '../../engine/poker/hole_cards.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import 'widgets/tool_widgets.dart';

/// Combo Calculator — cuarta herramienta real de Tools V1.
///
/// Entrada por notación de texto, igual que el resto de Tools: una
/// clase de mano (`AKs`, `77`, `AKo`) más cartas muertas opcionales
/// (`2c7d9h`). Todo el cálculo vive en [ComboEngine] (enumeración física
/// + card removal, ya probado) — esta pantalla solo parsea texto y
/// muestra la lista resultante de [HoleCards].
class ComboCalculatorScreen extends StatefulWidget {
  const ComboCalculatorScreen({super.key});

  @override
  State<ComboCalculatorScreen> createState() => _ComboCalculatorScreenState();
}

class _ComboCalculatorScreenState extends State<ComboCalculatorScreen> {
  final _handClassController = TextEditingController(text: 'AKs');
  final _deadCardsController = TextEditingController(text: '');

  HandClass? _handClass;
  List<HoleCards>? _combos;
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  @override
  void dispose() {
    _handClassController.dispose();
    _deadCardsController.dispose();
    super.dispose();
  }

  HandClass? _tryParseHandClass(String text) {
    final clean = text.trim();
    if (!HandClass.isValid(clean)) return null;
    return HandClass.parse(clean);
  }

  /// `null` si la notación es inválida; lista vacía si el campo está
  /// vacío (sin cartas muertas es una entrada válida, no un error).
  List<Card>? _tryParseDeadCards(String text) {
    final clean = text.trim().replaceAll(' ', '');
    if (clean.isEmpty) return const [];
    if (clean.length.isOdd) return null;
    final cards = <Card>[];
    final seen = <Card>{};
    try {
      for (var i = 0; i < clean.length; i += 2) {
        final card = Card.parse(clean.substring(i, i + 2));
        if (!seen.add(card)) return null; // carta repetida
        cards.add(card);
      }
    } catch (_) {
      return null;
    }
    return cards;
  }

  void _recalculate() {
    final handClass = _tryParseHandClass(_handClassController.text);
    final deadCards = _tryParseDeadCards(_deadCardsController.text);
    if (handClass == null || deadCards == null) {
      setState(() {
        _handClass = null;
        _combos = null;
        _invalid = true;
      });
      return;
    }
    setState(() {
      _handClass = handClass;
      _combos = ComboEngine.combosForHandClass(handClass, deadCards: deadCards);
      _invalid = false;
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
                    icon: Icons.view_module_rounded,
                    accentColor: AppColors.gold,
                    title: AppStrings.toolsComboTitle,
                    subtitle: AppStrings.toolsComboCalculatorSubtitle,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 20),
                  ToolCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ToolTextField(
                          label: AppStrings.comboHandClassLabel,
                          controller: _handClassController,
                          onChanged: _recalculate,
                          hintText: AppStrings.comboHandClassHint,
                          accentColor: AppColors.gold,
                        ),
                        const SizedBox(height: 14),
                        ToolTextField(
                          label: AppStrings.comboDeadCardsLabel,
                          controller: _deadCardsController,
                          onChanged: _recalculate,
                          hintText: AppStrings.comboDeadCardsHint,
                          accentColor: AppColors.gold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_invalid)
                    const ToolErrorCard(message: AppStrings.comboInvalidInput)
                  else if (_handClass != null && _combos != null)
                    _ResultCard(handClass: _handClass!, combos: _combos!),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.handClass, required this.combos});

  final HandClass handClass;
  final List<HoleCards> combos;

  @override
  Widget build(BuildContext context) {
    final total = handClass.combos;
    final available = combos.length;
    return ToolCard(
      gradientColors: const [Color(0xFF3A2E12), Color(0xFF241B0A)],
      borderColor: AppColors.gold.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.comboTotalLabel,
                  value: '$total',
                  big: true,
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.comboAvailableLabel,
                  value: '$available',
                  big: true,
                  color: AppColors.neonGreen,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.comboBlockedLabel,
                  value: '${total - available}',
                  big: true,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.comboExplanation(
              notation: handClass.notation,
              total: total,
              available: available,
            ),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (available == 0) ...[
            const SizedBox(height: 12),
            const ToolErrorCard(message: AppStrings.comboNoneAvailable),
          ] else ...[
            const SizedBox(height: 14),
            const Text(
              AppStrings.comboListLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final combo in combos)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Text(
                      combo.pretty,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
