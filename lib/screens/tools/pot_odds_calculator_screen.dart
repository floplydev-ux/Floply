import 'package:flutter/material.dart';

import '../../engine/poker/pot_odds/pot_odds_engine.dart';
import '../../engine/poker/pot_odds/pot_odds_result.dart';
import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import 'ev_calculator_screen.dart';
import 'widgets/tool_explainer.dart';
import 'widgets/tool_guide_screen.dart';
import 'widgets/tool_widgets.dart';

/// Público (antes privado, `_kToolId`/`_kExplainer`): reutilizado por la
/// guía consolidada del hub (`lib/screens/tools/widgets/tools_guide_sheet.dart`)
/// para no duplicar contenido real — la guía abre esta MISMA hoja en vez
/// de reescribir "qué ingresar"/"cómo leer el resultado" con otras
/// palabras.
const kPotOddsToolId = 'pot_odds';
const kPotOddsExplainer = ToolExplainerContent(
  title: 'Pot Odds',
  description:
      'Calculá qué porcentaje de equity necesitás para que pagar una '
      'apuesta sea rentable a largo plazo.',
  howToUse: 'Ingresá el bote antes de pagar y lo que tenés que pagar, los '
      'dos en BB.',
  result: 'La equity necesaria (break-even) y el bote final. Si tu equity '
      'real en esta mano es mayor a la necesaria, pagar es +EV.',
);

const kPotOddsGuide = ToolGuideContent(
  title: 'Pot Odds',
  tagline: 'Calculadora del precio del call',
  icon: Icons.percent_rounded,
  sections: [
    ToolGuideSection(
      label: '¿Para qué sirve?',
      body: 'Pot Odds te dice qué porcentaje mínimo de equity necesitás para '
          'que un call sea break-even. También influyen implied odds, reverse '
          'implied odds y rake — Pot Odds da el número central del precio.',
    ),
    ToolGuideSection(
      label: '¿Cuándo usarla?',
      items: [
        'Frente a una apuesta, raise o all-in.',
        'Para comparar el precio del pot contra tu equity estimada.',
        'Como primer paso antes de calcular el EV.',
      ],
    ),
    ToolGuideSection(
      label: '¿Qué necesito ingresar?',
      items: [
        'Bote antes de tu call — incluyendo la apuesta del rival. '
            'Si había 10 BB y el rival apostó 5, ingresás 15.',
        'Lo que tenés que pagar.',
        'Tu equity real (opcional) — FLOPly la compara con el mínimo necesario.',
      ],
    ),
    ToolGuideSection(
      label: 'La fórmula',
      isFormula: true,
      body: 'Equity mínima = Call ÷ (Bote + Call)\n'
          'Ratio        = Bote ÷ Call  →  X : 1',
    ),
    ToolGuideSection(
      label: 'Ejemplo',
      body: 'Bote 15 BB · Call 5 BB\n'
          '→ Equity mínima = 5 ÷ 20 = 25%  ·  Ratio 3:1\n\n'
          'Si tenés 35% de equity: 35% > 25% → call favorable.',
    ),
    ToolGuideSection(
      label: 'Errores comunes',
      items: [
        'Poner el pot sin la apuesta del rival. '
            'Si había 10 BB y el rival apostó 5, ingresás 15, no 10.',
        'Confundir pot odds con equity: son conceptos distintos que '
            'después se comparan.',
        'Ignorar las implied odds con manos especulativas y proyectos.',
      ],
    ),
    ToolGuideSection(
      label: 'Consejo FLOPly',
      body: 'Primero mirá el precio (Pot Odds). Después la probabilidad '
          '(Equity). Después el valor de la decisión (EV). Desde el '
          'resultado podés pasar a EV con los datos precargados.',
    ),
  ],
);

/// Pot Odds Calculator — primera herramienta real de Tools V1.
///
/// Puramente de presentación: todo el cálculo vive en [PotOddsEngine]
/// (`lib/engine/poker/pot_odds/`), motor puro Dart ya probado — esta
/// pantalla solo parsea texto, lo pasa al motor, y muestra el
/// [PotOddsResult]. Recalcula en vivo con cada cambio (`onChanged`), sin
/// botón "Calcular": el resultado tiene que estar visible de inmediato.
///
/// Grupo 2 (profesionalización de Tools): sin selección de cartas —esta
/// calculadora nunca las necesitó—, así que el cambio acá es puramente
/// visual (Sala Verde) y de jerarquía de resultado (principal vs. datos
/// de apoyo, sección 5).
class PotOddsCalculatorScreen extends StatefulWidget {
  const PotOddsCalculatorScreen({super.key, this.initialPotBb, this.initialCallBb});

  /// Precarga desde otra herramienta. `null` conserva los defaults de
  /// siempre (10/5 BB).
  final double? initialPotBb;
  final double? initialCallBb;

  @override
  State<PotOddsCalculatorScreen> createState() => _PotOddsCalculatorScreenState();
}

class _PotOddsCalculatorScreenState extends State<PotOddsCalculatorScreen> {
  late final _potController =
      TextEditingController(text: formatToolNumber(widget.initialPotBb ?? 10));
  late final _callController =
      TextEditingController(text: formatToolNumber(widget.initialCallBb ?? 5));
  final _yourEquityController = TextEditingController();

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
    _yourEquityController.dispose();
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

  void _openEv() {
    final pot = _parse(_potController.text);
    final call = _parse(_callController.text);
    final yourEquity = _parse(_yourEquityController.text);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EvCalculatorScreen(
        initialPotBb: pot,
        initialCallBb: call,
        initialEquityPercent: yourEquity,
      ),
    ));
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
                  icon: Icons.percent_rounded,
                  title: AppStrings.toolsPotOddsTitle,
                  subtitle: AppStrings.toolsPotOddsCardDescription,
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: ToolInfoButton(
                    onTap: () => showToolExplainerSheet(
                      context,
                      toolId: kPotOddsToolId,
                      content: kPotOddsExplainer,
                    ),
                  ),
                ),
                const SizedBox(height: SalaVerdeSpace.xl),
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
                      const SizedBox(height: SalaVerdeSpace.md),
                      ToolNumberField(
                        label: AppStrings.potOddsCallLabel,
                        controller: _callController,
                        onChanged: _recalculate,
                        suffixText: AppStrings.potOddsBbSuffix,
                      ),
                      const SizedBox(height: SalaVerdeSpace.md),
                      ToolNumberField(
                        label: AppStrings.potOddsYourEquityLabel,
                        controller: _yourEquityController,
                        onChanged: () => setState(() {}),
                        suffixText: AppStrings.evPercentSuffix,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SalaVerdeSpace.lg),
                if (_invalid)
                  const ToolErrorCard(message: AppStrings.potOddsInvalidInput)
                else if (_result != null) ...[
                  _ResultCard(
                    result: _result!,
                    yourEquityPercent: _parse(_yourEquityController.text),
                  ),
                  const SizedBox(height: SalaVerdeSpace.lg),
                  SizedBox(
                    width: double.infinity,
                    child: SvButtonSecondary(
                      label: AppStrings.potOddsCalculateEv,
                      onTap: _openEv,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, this.yourEquityPercent});

  final PotOddsResult result;

  /// Equity real que ingresó el usuario (0..100), si la completó — la
  /// comparación es puramente informativa (sección 9), nunca decide por
  /// el usuario.
  final double? yourEquityPercent;

  @override
  Widget build(BuildContext context) {
    return ToolCard(
      borderColor: kToolAccent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolSectionLabel(AppStrings.toolsResultPrincipal, color: kToolAccent),
          const SizedBox(height: SalaVerdeSpace.sm),
          ToolResultStat(
            label: AppStrings.potOddsRequiredEquityLabel,
            value: '${(result.requiredEquity * 100).toStringAsFixed(1)}%',
            big: true,
            color: kToolAccent,
          ),
          const SizedBox(height: SalaVerdeSpace.lg),
          const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
          const SizedBox(height: SalaVerdeSpace.md),
          const ToolSectionLabel(AppStrings.toolsResultDatos),
          const SizedBox(height: SalaVerdeSpace.sm),
          Row(
            children: [
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.potOddsFinalPotLabel,
                  value: '${formatToolNumber(result.finalPotBb)} BB',
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.potOddsRatioLabel,
                  value: result.potOddsRatio == null
                      ? '—'
                      : '${formatToolNumber(result.potOddsRatio!)} : 1',
                ),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(
            AppStrings.potOddsExplanation(result.requiredEquity * 100),
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
          ),
          if (yourEquityPercent != null) ...[
            const SizedBox(height: SalaVerdeSpace.sm),
            Text(
              AppStrings.potOddsEquityComparison(
                yourEquityPct: yourEquityPercent!,
                requiredEquityPct: result.requiredEquity * 100,
              ),
              style: SalaVerdeType.caption(color: kToolAccent)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
