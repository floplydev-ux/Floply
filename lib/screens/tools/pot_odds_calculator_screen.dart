import 'package:flutter/material.dart';

import '../../engine/poker/pot_odds/pot_odds_engine.dart';
import '../../engine/poker/pot_odds/pot_odds_result.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import 'widgets/tool_widgets.dart';

/// Pot Odds Calculator — primera herramienta real de Tools V1.
///
/// Puramente de presentación: todo el cálculo vive en [PotOddsEngine]
/// (`lib/engine/poker/pot_odds/`), motor puro Dart ya probado — esta
/// pantalla solo parsea texto, lo pasa al motor, y muestra el
/// [PotOddsResult]. Recalcula en vivo con cada cambio (`onChanged`), sin
/// botón "Calcular": el resultado tiene que estar visible de inmediato.
class PotOddsCalculatorScreen extends StatefulWidget {
  const PotOddsCalculatorScreen({super.key});

  @override
  State<PotOddsCalculatorScreen> createState() => _PotOddsCalculatorScreenState();
}

class _PotOddsCalculatorScreenState extends State<PotOddsCalculatorScreen> {
  final _potController = TextEditingController(text: '10');
  final _callController = TextEditingController(text: '5');

  PotOddsResult? _result;
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  @override
  void dispose() {
    _potController.dispose();
    _callController.dispose();
    super.dispose();
  }

  double? _parse(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  void _recalculate() {
    final pot = _parse(_potController.text);
    final call = _parse(_callController.text);
    if (pot == null || call == null) {
      setState(() {
        _result = null;
        _invalid = true;
      });
      return;
    }
    try {
      final result = PotOddsEngine.calculate(potBeforeCallBb: pot, callAmountBb: call);
      setState(() {
        _result = result;
        _invalid = false;
      });
    } on ArgumentError {
      setState(() {
        _result = null;
        _invalid = true;
      });
    }
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
                    icon: Icons.calculate_rounded,
                    accentColor: AppColors.diamondBlue,
                    title: AppStrings.toolsPotOddsTitle,
                    subtitle: AppStrings.toolsPotOddsCardDescription,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 20),
                  ToolCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ToolNumberField(
                          label: AppStrings.potOddsPotLabel,
                          controller: _potController,
                          onChanged: _recalculate,
                          suffixText: AppStrings.potOddsBbSuffix,
                        ),
                        const SizedBox(height: 14),
                        ToolNumberField(
                          label: AppStrings.potOddsCallLabel,
                          controller: _callController,
                          onChanged: _recalculate,
                          suffixText: AppStrings.potOddsBbSuffix,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_invalid)
                    const ToolErrorCard(message: AppStrings.potOddsInvalidInput)
                  else if (_result != null)
                    _ResultCard(result: _result!),
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
  const _ResultCard({required this.result});

  final PotOddsResult result;

  @override
  Widget build(BuildContext context) {
    return ToolCard(
      gradientColors: const [Color(0xFF15304A), Color(0xFF0F2337)],
      borderColor: AppColors.diamondBlue.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.potOddsRequiredEquityLabel,
                  value: '${(result.requiredEquity * 100).toStringAsFixed(1)}%',
                  big: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.potOddsFinalPotLabel,
                  value: '${formatToolNumber(result.finalPotBb)} BB',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ToolResultStat(
            label: AppStrings.potOddsRatioLabel,
            value: result.potOddsRatio == null
                ? '—'
                : '${formatToolNumber(result.potOddsRatio!)} : 1',
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.potOddsExplanation(result.requiredEquity * 100),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
