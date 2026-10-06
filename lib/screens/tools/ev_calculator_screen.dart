import 'package:flutter/material.dart';

import '../../engine/poker/ev/ev_bet_result.dart';
import '../../engine/poker/ev/ev_engine.dart';
import '../../engine/poker/ev/ev_result.dart';
import '../../engine/poker/pot_odds/pot_odds_engine.dart';
import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import 'widgets/tool_explainer.dart';
import 'widgets/tool_guide_screen.dart';
import 'widgets/tool_widgets.dart';

/// Público (antes privado): reutilizado por la guía consolidada del hub
/// (`tools_guide_sheet.dart`) — ver el doc-comment equivalente en
/// `pot_odds_calculator_screen.dart`.
const kEvToolId = 'ev_calculator';
const kEvExplainer = ToolExplainerContent(
  title: 'EV',
  description:
      'Calculá el valor esperado (EV) de pagar un call, o de apostar/'
      'subir, según tu equity y las probabilidades que ingreses.',
  howToUse: 'Elegí el modo (Pagar un call / Apostar-subir) y completá el '
      'bote, el monto y tu equity estimada — o, en el modo apostar, el % '
      'de fold y de call del rival.',
  result: 'El EV en BB, y si la jugada es +EV, break-even o -EV con esos '
      'números.',
  extra: "En el modo 'Apostar/subir', si fold% + call% no suman 100%, el "
      'resto corresponde a que el rival suba — esa rama queda afuera del '
      'cálculo (te lo avisa un cartel aparte).',
);

const kEvGuide = ToolGuideContent(
  title: 'EV',
  tagline: 'Valor esperado de un call o una apuesta',
  icon: Icons.query_stats_rounded,
  sections: [
    ToolGuideSection(
      label: '¿Para qué sirve?',
      body: 'Te dice cuántos BB ganás (o perdés) en promedio por cada vez '
          'que tomás esa decisión. Un EV positivo es rentable a largo '
          'plazo, aunque pierdas la mano hoy.',
    ),
    ToolGuideSection(
      label: '¿Cuándo usarla?',
      items: [
        'Modo call: cuando tenés tu equity estimada y querés saber si el '
            'call es rentable y por cuánto.',
        'Modo apuesta: para comparar sizings o analizar si vale apostar '
            'con fold equity baja.',
      ],
    ),
    ToolGuideSection(
      label: '¿Qué necesito ingresar?',
      items: [
        'Modo call: bote antes del call, call, tu equity.',
        'Modo apuesta: bote, sizing, % que foldea, % que paga, equity '
            'si el rival paga.',
      ],
    ),
    ToolGuideSection(
      label: 'La fórmula',
      isFormula: true,
      body: 'Call:    EV = equity × pot_final − call\n'
          'Apuesta: EV = P(fold)×pot\n'
          '            + P(call)×(eq×pot_final − bet)',
    ),
    ToolGuideSection(
      label: 'Ejemplo',
      body: 'Bote 15 BB · Call 5 BB · Equity 35%\n'
          '→ EV = 0.35 × 20 − 5 = +2 BB\n\n'
          'Con 25% de equity el EV sería 0 (break-even).',
    ),
    ToolGuideSection(
      label: 'Tené en cuenta',
      isNote: true,
      body: "En modo apuesta, si fold% + call% no suman 100%, el resto "
          "corresponde a que el rival suba — esa rama queda afuera del "
          "cálculo y la herramienta te lo avisa.",
    ),
    ToolGuideSection(
      label: 'Errores comunes',
      items: [
        'Confundir pot_antes con pot_final. En modo call, ingresás el '
            'pot ANTES de pagar.',
        'Poner fold% + call% mayor a 100%: la herramienta lo rechaza.',
        'Usar la equity total en vez de la equity contra el rango de '
            'continuación del rival (su rango de calling es más fuerte).',
      ],
    ),
  ],
);

enum _EvMode { call, bet }

/// EV Calculator — segunda herramienta real de Tools V1 (pagar un
/// call), extendida en Tools V2 con "Apostar / subir" (EV Avanzado,
/// alcance "Modelo A" — ver `EV_AVANZADO_AUDITORIA_DISENO.md`).
///
/// Grupo 2: sin cartas que seleccionar (los inputs son bote/apuesta/
/// probabilidades en BB y %) — el trabajo acá es visual (Sala Verde) y
/// de consolidar los patrones que antes se repetían por pantalla
/// (`_ModeChip`, `_CalculateButton`, `_StatusPill`) en los componentes
/// compartidos de `tool_widgets.dart`.
class EvCalculatorScreen extends StatefulWidget {
  const EvCalculatorScreen({
    super.key,
    this.initialPotBb,
    this.initialCallBb,
    this.initialEquityPercent,
  });

  /// Precarga del modo "Pagar un call" desde otra herramienta (hoy: Pot
  /// Odds, Equity). `null` conserva los defaults de siempre (10/5/40).
  final double? initialPotBb;
  final double? initialCallBb;
  final double? initialEquityPercent;

  @override
  State<EvCalculatorScreen> createState() => _EvCalculatorScreenState();
}

class _EvCalculatorScreenState extends State<EvCalculatorScreen> {
  _EvMode _mode = _EvMode.call;

  // Modo "Pagar un call" (V1).
  late final _potController =
      TextEditingController(text: formatToolNumber(widget.initialPotBb ?? 10));
  late final _callController =
      TextEditingController(text: formatToolNumber(widget.initialCallBb ?? 5));
  late final _equityController =
      TextEditingController(text: formatToolNumber(widget.initialEquityPercent ?? 40));
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
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ToolHeader(
                  icon: Icons.query_stats_rounded,
                  title: AppStrings.toolsEvTitle,
                  subtitle: AppStrings.toolsEvCalculatorSubtitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: ToolInfoButton(
                    onTap: () => showToolExplainerSheet(
                      context,
                      toolId: kEvToolId,
                      content: kEvExplainer,
                    ),
                  ),
                ),
                const SizedBox(height: SalaVerdeSpace.xl),
                Wrap(
                  spacing: SalaVerdeSpace.sm,
                  runSpacing: SalaVerdeSpace.sm,
                  children: [
                    ToolModeChip(
                      label: AppStrings.evModeCallLabel,
                      active: _mode == _EvMode.call,
                      onTap: () => setState(() => _mode = _EvMode.call),
                    ),
                    ToolModeChip(
                      label: AppStrings.evModeBetLabel,
                      active: _mode == _EvMode.bet,
                      onTap: () => setState(() => _mode = _EvMode.bet),
                    ),
                  ],
                ),
                const SizedBox(height: SalaVerdeSpace.lg),
                switch (_mode) {
                  _EvMode.call => _buildCallMode(),
                  _EvMode.bet => _buildBetMode(),
                },
              ],
            ),
          );
        }),
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
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              ToolNumberField(
                label: AppStrings.evCallLabel,
                controller: _callController,
                onChanged: _recalculateCall,
                suffixText: AppStrings.potOddsBbSuffix,
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              ToolNumberField(
                label: AppStrings.evEquityLabel,
                controller: _equityController,
                onChanged: _recalculateCall,
                suffixText: AppStrings.evPercentSuffix,
              ),
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
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
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              ToolNumberField(
                label: AppStrings.evBetSizeLabel,
                controller: _betSizeController,
                onChanged: _recalculateBet,
                suffixText: AppStrings.potOddsBbSuffix,
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              ToolNumberField(
                label: AppStrings.evBetFoldLabel,
                controller: _betFoldController,
                onChanged: _recalculateBet,
                suffixText: AppStrings.evPercentSuffix,
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              ToolNumberField(
                label: AppStrings.evBetCallLabel,
                controller: _betCallController,
                onChanged: _recalculateBet,
                suffixText: AppStrings.evPercentSuffix,
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              ToolNumberField(
                label: AppStrings.evBetEquityLabel,
                controller: _betEquityController,
                onChanged: _recalculateBet,
                suffixText: AppStrings.evPercentSuffix,
              ),
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        if (_betInvalid)
          const ToolErrorCard(message: AppStrings.evBetInvalidInput)
        else if (_betResult != null)
          _BetResultCard(result: _betResult!),
      ],
    );
  }
}

Color _evColor(bool profitable, bool breakEven) => profitable
    ? SalaVerdeColors.success
    : breakEven
        ? SalaVerdeColors.warning
        : SalaVerdeColors.errorBright;

String _evStatusLabel(bool profitable, bool breakEven) => profitable
    ? AppStrings.evProfitableLabel
    : breakEven
        ? AppStrings.evBreakEvenLabel
        : AppStrings.evLosingLabel;

class _CallResultCard extends StatelessWidget {
  const _CallResultCard({required this.result, required this.requiredEquityPct});

  final EVResult result;
  final double requiredEquityPct;

  @override
  Widget build(BuildContext context) {
    final color = _evColor(result.isProfitable, result.isBreakEven);
    return ToolCard(
      borderColor: color.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolSectionLabel(AppStrings.toolsResultPrincipal, color: color),
          const SizedBox(height: SalaVerdeSpace.sm),
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
              Flexible(
                child: ToolStatusPill(
                  label: _evStatusLabel(result.isProfitable, result.isBreakEven),
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.lg),
          const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
          const SizedBox(height: SalaVerdeSpace.md),
          ToolResultStat(
            label: AppStrings.evRequiredEquityLabel,
            value: '${requiredEquityPct.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(
            AppStrings.evExplanation(
              evBb: result.evBb,
              equityPct: result.equity * 100,
              requiredEquityPct: requiredEquityPct,
            ),
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
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
    final color = _evColor(result.isProfitable, result.isBreakEven);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          borderColor: color.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToolSectionLabel(AppStrings.toolsResultPrincipal, color: color),
              const SizedBox(height: SalaVerdeSpace.sm),
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
                  Flexible(
                    child: ToolStatusPill(
                      label: _evStatusLabel(result.isProfitable, result.isBreakEven),
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SalaVerdeSpace.lg),
              const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
              const SizedBox(height: SalaVerdeSpace.md),
              Row(
                children: [
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.evBetFoldContributionLabel,
                      value:
                          '${result.evFoldBb >= 0 ? '+' : ''}${formatToolNumber(result.evFoldBb)} BB',
                    ),
                  ),
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.evBetCallContributionLabel,
                      value:
                          '${result.evCallBb >= 0 ? '+' : ''}${formatToolNumber(result.evCallBb)} BB',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              Text(
                AppStrings.evBetExplanation(result.evBb),
                style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
              ),
            ],
          ),
        ),
        if (result.unmodeledProbability > 1e-9) ...[
          const SizedBox(height: SalaVerdeSpace.md),
          ToolWarningCard(
            message: AppStrings.evBetUnmodeledWarning(result.unmodeledProbability * 100),
          ),
        ],
      ],
    );
  }
}
