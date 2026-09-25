import 'package:flutter/material.dart';

import '../../engine/poker/ev/ev_bet_result.dart';
import '../../engine/poker/ev/ev_engine.dart';
import '../../engine/poker/ev/ev_result.dart';
import '../../engine/poker/pot_odds/pot_odds_engine.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import 'widgets/tool_widgets.dart';

enum _EvMode { call, bet }

/// EV Calculator — segunda herramienta real de Tools V1 (pagar un
/// call), extendida en Tools V2 con "Apostar / subir" (EV Avanzado,
/// alcance "Modelo A" — ver `EV_AVANZADO_AUDITORIA_DISENO.md`).
///
/// **Por qué dos modos y no un tercer campo opcional**: EV de pagar y
/// EV de apostar son fórmulas distintas — apostar tiene fold equity
/// (ganás el bote entero sin showdown si el rival se retira), pagar no.
/// Mismo criterio que ya usó Equity Calculator para sus 3 modos: cada
/// modo tiene sus propios inputs y su propio resultado, no un
/// formulario único con campos que a veces no aplican.
///
/// **Alcance deliberado del modo "Apostar / subir"** (ver el informe de
/// diseño, punto 4): el usuario pone el % de fold y el % de call — este
/// motor nunca los infiere. Si no suman 100%, el resto es la rama "el
/// rival sube", que el cálculo deja explícitamente afuera (no le
/// inventa un valor) — la UI lo muestra como una advertencia, nunca lo
/// esconde.
class EvCalculatorScreen extends StatefulWidget {
  const EvCalculatorScreen({super.key});

  @override
  State<EvCalculatorScreen> createState() => _EvCalculatorScreenState();
}

class _EvCalculatorScreenState extends State<EvCalculatorScreen> {
  _EvMode _mode = _EvMode.call;

  // Modo "Pagar un call" (V1).
  final _potController = TextEditingController(text: '10');
  final _callController = TextEditingController(text: '5');
  final _equityController = TextEditingController(text: '40');
  EVResult? _evResult;
  double? _requiredEquityPct;
  bool _invalid = false;

  // Modo "Apostar / subir" (V2).
  final _betPotController = TextEditingController(text: '10');
  final _betSizeController = TextEditingController(text: '5');
  final _betFoldController = TextEditingController(text: '40');
  final _betCallController = TextEditingController(text: '50');
  final _betEquityController = TextEditingController(text: '45');
  EVBetResult? _betResult;
  bool _betInvalid = false;

  @override
  void initState() {
    super.initState();
    _recalculateCall();
    _recalculateBet();
  }

  @override
  void dispose() {
    _potController.dispose();
    _callController.dispose();
    _equityController.dispose();
    _betPotController.dispose();
    _betSizeController.dispose();
    _betFoldController.dispose();
    _betCallController.dispose();
    _betEquityController.dispose();
    super.dispose();
  }

  double? _parse(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  void _recalculateCall() {
    final pot = _parse(_potController.text);
    final call = _parse(_callController.text);
    final equityPct = _parse(_equityController.text);
    if (pot == null || call == null || equityPct == null || equityPct < 0 || equityPct > 100) {
      setState(() {
        _evResult = null;
        _requiredEquityPct = null;
        _invalid = true;
      });
      return;
    }
    try {
      final potOdds = PotOddsEngine.calculate(potBeforeCallBb: pot, callAmountBb: call);
      final ev = EVEngine.calculateCall(
        equity: equityPct / 100,
        finalPotBb: potOdds.finalPotBb,
        callAmountBb: call,
      );
      setState(() {
        _evResult = ev;
        _requiredEquityPct = potOdds.requiredEquity * 100;
        _invalid = false;
      });
    } on ArgumentError {
      setState(() {
        _evResult = null;
        _requiredEquityPct = null;
        _invalid = true;
      });
    }
  }

  void _recalculateBet() {
    final pot = _parse(_betPotController.text);
    final bet = _parse(_betSizeController.text);
    final foldPct = _parse(_betFoldController.text);
    final callPct = _parse(_betCallController.text);
    final equityPct = _parse(_betEquityController.text);
    if (pot == null ||
        bet == null ||
        foldPct == null ||
        callPct == null ||
        equityPct == null ||
        foldPct < 0 ||
        callPct < 0 ||
        equityPct < 0 ||
        equityPct > 100) {
      setState(() {
        _betResult = null;
        _betInvalid = true;
      });
      return;
    }
    try {
      final result = EVEngine.calculateBet(
        foldProbability: foldPct / 100,
        callProbability: callPct / 100,
        potBeforeBetBb: pot,
        betSizeBb: bet,
        equityIfCalled: equityPct / 100,
      );
      setState(() {
        _betResult = result;
        _betInvalid = false;
      });
    } on ArgumentError {
      setState(() {
        _betResult = null;
        _betInvalid = true;
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
                    icon: Icons.trending_up_rounded,
                    accentColor: AppColors.neonGreen,
                    title: AppStrings.toolsEvTitle,
                    subtitle: AppStrings.toolsEvCalculatorSubtitle,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 20),
                  _ModeSelector(
                    mode: _mode,
                    onSelected: (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 16),
                  switch (_mode) {
                    _EvMode.call => _buildCallMode(),
                    _EvMode.bet => _buildBetMode(),
                  },
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCallMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToolNumberField(
                label: AppStrings.evPotLabel,
                controller: _potController,
                onChanged: _recalculateCall,
                suffixText: AppStrings.potOddsBbSuffix,
                accentColor: AppColors.neonGreen,
              ),
              const SizedBox(height: 14),
              ToolNumberField(
                label: AppStrings.evCallLabel,
                controller: _callController,
                onChanged: _recalculateCall,
                suffixText: AppStrings.potOddsBbSuffix,
                accentColor: AppColors.neonGreen,
              ),
              const SizedBox(height: 14),
              ToolNumberField(
                label: AppStrings.evEquityLabel,
                controller: _equityController,
                onChanged: _recalculateCall,
                suffixText: AppStrings.evPercentSuffix,
                accentColor: AppColors.neonGreen,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_invalid)
          const ToolErrorCard(message: AppStrings.evInvalidInput)
        else if (_evResult != null && _requiredEquityPct != null)
          _CallResultCard(
            result: _evResult!,
            requiredEquityPct: _requiredEquityPct!,
          ),
      ],
    );
  }

  Widget _buildBetMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToolNumberField(
                label: AppStrings.evBetPotLabel,
                controller: _betPotController,
                onChanged: _recalculateBet,
                suffixText: AppStrings.potOddsBbSuffix,
                accentColor: AppColors.neonGreen,
              ),
              const SizedBox(height: 14),
              ToolNumberField(
                label: AppStrings.evBetSizeLabel,
                controller: _betSizeController,
                onChanged: _recalculateBet,
                suffixText: AppStrings.potOddsBbSuffix,
                accentColor: AppColors.neonGreen,
              ),
              const SizedBox(height: 14),
              ToolNumberField(
                label: AppStrings.evBetFoldLabel,
                controller: _betFoldController,
                onChanged: _recalculateBet,
                suffixText: AppStrings.evPercentSuffix,
                accentColor: AppColors.neonGreen,
              ),
              const SizedBox(height: 14),
              ToolNumberField(
                label: AppStrings.evBetCallLabel,
                controller: _betCallController,
                onChanged: _recalculateBet,
                suffixText: AppStrings.evPercentSuffix,
                accentColor: AppColors.neonGreen,
              ),
              const SizedBox(height: 14),
              ToolNumberField(
                label: AppStrings.evBetEquityLabel,
                controller: _betEquityController,
                onChanged: _recalculateBet,
                suffixText: AppStrings.evPercentSuffix,
                accentColor: AppColors.neonGreen,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_betInvalid)
          const ToolErrorCard(message: AppStrings.evBetInvalidInput)
        else if (_betResult != null)
          _BetResultCard(result: _betResult!),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onSelected});

  final _EvMode mode;
  final ValueChanged<_EvMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ModeChip(
          label: AppStrings.evModeCallLabel,
          active: mode == _EvMode.call,
          onTap: () => onSelected(_EvMode.call),
        ),
        _ModeChip(
          label: AppStrings.evModeBetLabel,
          active: mode == _EvMode.bet,
          onTap: () => onSelected(_EvMode.bet),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? AppColors.neonGreen.withValues(alpha: 0.18)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: active ? AppColors.neonGreen : AppColors.surfaceBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: active ? AppColors.neonGreen : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CallResultCard extends StatelessWidget {
  const _CallResultCard({required this.result, required this.requiredEquityPct});

  final EVResult result;
  final double requiredEquityPct;

  @override
  Widget build(BuildContext context) {
    final color = result.isProfitable
        ? AppColors.neonGreen
        : result.isBreakEven
            ? AppColors.gold
            : AppColors.danger;
    final statusLabel = result.isProfitable
        ? AppStrings.evProfitableLabel
        : result.isBreakEven
            ? AppStrings.evBreakEvenLabel
            : AppStrings.evLosingLabel;

    return ToolCard(
      gradientColors: const [Color(0xFF153A2A), Color(0xFF0F2419)],
      borderColor: color.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.evResultLabel,
                  value:
                      '${result.evBb >= 0 ? '+' : ''}${formatToolNumber(result.evBb)} BB',
                  big: true,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.evRequiredEquityLabel,
                  value: '${requiredEquityPct.toStringAsFixed(1)}%',
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StatusPill(label: statusLabel, color: color),
          const SizedBox(height: 12),
          Text(
            AppStrings.evExplanation(
              evBb: result.evBb,
              equityPct: result.equity * 100,
              requiredEquityPct: requiredEquityPct,
            ),
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

class _BetResultCard extends StatelessWidget {
  const _BetResultCard({required this.result});

  final EVBetResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.isProfitable
        ? AppColors.neonGreen
        : result.isBreakEven
            ? AppColors.gold
            : AppColors.danger;
    final statusLabel = result.isProfitable
        ? AppStrings.evProfitableLabel
        : result.isBreakEven
            ? AppStrings.evBreakEvenLabel
            : AppStrings.evLosingLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          gradientColors: const [Color(0xFF153A2A), Color(0xFF0F2419)],
          borderColor: color.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToolResultStat(
                label: AppStrings.evResultLabel,
                value:
                    '${result.evBb >= 0 ? '+' : ''}${formatToolNumber(result.evBb)} BB',
                big: true,
                color: color,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.evBetFoldContributionLabel,
                      value:
                          '${result.evFoldBb >= 0 ? '+' : ''}${formatToolNumber(result.evFoldBb)} BB',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.evBetCallContributionLabel,
                      value:
                          '${result.evCallBb >= 0 ? '+' : ''}${formatToolNumber(result.evCallBb)} BB',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatusPill(label: statusLabel, color: color),
              const SizedBox(height: 12),
              Text(
                AppStrings.evBetExplanation(result.evBb),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (result.unmodeledProbability > 1e-9) ...[
          const SizedBox(height: 12),
          _WarningCard(
            message: AppStrings.evBetUnmodeledWarning(
                result.unmodeledProbability * 100),
          ),
        ],
      ],
    );
  }
}

/// Aviso informativo (no un error): la apuesta se calculó igual, pero
/// una parte de la probabilidad quedó afuera del modelo (la rama "el
/// rival sube"). Deliberadamente distinto de [ToolErrorCard] — mismo
/// tono que un "ojo con esto", no un "algo falló".
class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.warning.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.warning,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
