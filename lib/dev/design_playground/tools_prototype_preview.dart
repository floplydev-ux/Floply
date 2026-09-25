/// PROTOTIPO — Fase 1.5, PRUEBA 2 (Tools).
///
/// Entorno de **Flutter Widget Preview** — mismo mecanismo que el resto de
/// `lib/dev/design_playground/`: `flutter widget-preview start`.
///
/// **Qué es real acá:** la calculadora de Pot Odds (`PotOddsEngine`/
/// `PotOddsResult`, `lib/engine/poker/pot_odds/`) — la misma matemática
/// pura que usa `lib/screens/tools/pot_odds_calculator_screen.dart` en
/// producción — y TODO el copy (`AppStrings.potOdds*`, `toolsPotOdds*`),
/// verbatim. No se inventó ni la herramienta ni su texto.
///
/// **Qué es nuevo:** el chrome (inputs, resultado, estado de error) usa
/// los tokens de "Sala Verde" en vez de `ToolNumberField`/`ToolResultStat`
/// reales (`lib/screens/tools/widgets/tool_widgets.dart`, escritos sobre
/// `AppColors`) — misma razón que en Fase 1: no se puede reskinear un
/// widget que hardcodea su paleta sin editarlo, y editar Tools está fuera
/// de alcance de esta fase.
///
/// Qué se prueba (Fase 1.5, criterio especial Tools): si `graphiteSteel`
/// (el acento "neutro en temperatura" documentado para Tools, nunca antes
/// ejercitado en código) sostiene una pantalla de alta densidad funcional
/// — inputs + resultado numérico + estado de error — sin depender de
/// color por sección ni de la mesa, y sin derivar en dashboard/HUD/
/// terminal (ver `FLOPLY_ANTI_GENERIC.md`).
///
/// **No se toca `pot_odds_calculator_screen.dart` ni `tool_widgets.dart`.**
library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../engine/poker/pot_odds/pot_odds_engine.dart';
import '../../engine/poker/pot_odds/pot_odds_result.dart';
import '../../l10n/app_strings.dart';
import 'proto_components.dart';
import 'proto_tokens.dart';

Widget _stage(Widget child) {
  // Hallazgo real de la Fase 1.5 (ver FLOPLY_VISUAL_STRESS_TEST.md §J):
  // esta es la única de las 4 pantallas del playground con un `TextField`
  // real. `TextField` exige un ancestro `Material` (`debugCheckHasMaterial`)
  // — sin él, no solo falla ese assert: el layout completo se corrompe
  // (se observó un overflow reportado de ~200.000px, un síntoma, no un
  // bug de spacing independiente). Los otros 3 `_stage()` del playground
  // no lo necesitan porque no tienen ningún widget Material interactivo
  // (`PressableScale`/`GestureDetector` no lo exigen).
  // También corregido: un SizedBox de ancho fijo (390) hacía inútil el
  // barrido responsive por encima de 390dp — ver la misma nota en
  // `home_prototype_preview.dart`.
  return ColoredBox(
    color: ProtoColor.background,
    child: Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth.clamp(0.0, 430.0)
              : 390.0;
          final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 844.0;
          return SizedBox(
            width: width,
            height: height,
            child: SafeArea(
              child: Material(color: ProtoColor.background, child: child),
            ),
          );
        },
      ),
    ),
  );
}

class _ToolsPrototype extends StatefulWidget {
  const _ToolsPrototype();

  @override
  State<_ToolsPrototype> createState() => _ToolsPrototypeState();
}

class _ToolsPrototypeState extends State<_ToolsPrototype> {
  // Semilla realista: el propio ejemplo del doc-comment de PotOddsEngine
  // (pot 15bb + call previo del rival ya incluido, call 5bb -> 25%).
  final _potController = TextEditingController(text: '15');
  final _callController = TextEditingController(text: '5');

  PotOddsResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recompute();
    _potController.addListener(_recompute);
    _callController.addListener(_recompute);
  }

  @override
  void dispose() {
    _potController.dispose();
    _callController.dispose();
    super.dispose();
  }

  void _recompute() {
    final pot = double.tryParse(_potController.text.trim());
    final call = double.tryParse(_callController.text.trim());
    if (pot == null || call == null) {
      setState(() {
        _result = null;
        _error = AppStrings.potOddsInvalidInput;
      });
      return;
    }
    try {
      setState(() {
        _result = PotOddsEngine.calculate(potBeforeCallBb: pot, callAmountBb: call);
        _error = null;
      });
    } on ArgumentError {
      setState(() {
        _result = null;
        _error = AppStrings.potOddsInvalidInput;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = ProtoColor.graphiteSteelBright; // texto/ícono — ver proto_tokens.dart
    const accentFill = ProtoColor.graphiteSteel; // superficie/relleno

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          ProtoSpace.lg, ProtoSpace.md, ProtoSpace.lg, ProtoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProtoSectionHeader(
            icon: Icons.calculate_outlined,
            title: AppStrings.toolsPotOddsTitle,
            subtitle: AppStrings.toolsPotOddsSubtitle,
            accent: accent,
          ),
          const SizedBox(height: ProtoSpace.xl),
          _numberField(
            label: AppStrings.potOddsPotLabel,
            controller: _potController,
          ),
          const SizedBox(height: ProtoSpace.md),
          _numberField(
            label: AppStrings.potOddsCallLabel,
            controller: _callController,
          ),
          const SizedBox(height: ProtoSpace.xl),
          Expanded(
            child: SingleChildScrollView(
              child: _error != null ? _errorPanel(_error!) : _resultPanel(_result!, accentFill),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ProtoType.label),
        const SizedBox(height: ProtoSpace.sm),
        Container(
          decoration: BoxDecoration(
            color: ProtoColor.surfaceElevated,
            borderRadius: BorderRadius.circular(ProtoRadius.control),
            border: Border.all(color: ProtoColor.borderSubtle),
          ),
          padding: const EdgeInsets.symmetric(horizontal: ProtoSpace.md),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: ProtoType.numericInline.copyWith(fontSize: 17),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                ),
              ),
              const Text(AppStrings.potOddsBbSuffix, style: ProtoType.caption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorPanel(String message) {
    return ProtoSurfacePanel(
      child: ProtoCalloutAccent(
        eyebrow: 'ERROR',
        body: message,
        color: ProtoColor.errorBright,
        icon: Icons.error_outline_rounded,
      ),
    );
  }

  Widget _resultPanel(PotOddsResult result, Color accentFill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: ProtoSpace.sm,
          runSpacing: ProtoSpace.sm,
          children: [
            ProtoChipNumeric(
              value: '${result.finalPotBb.toStringAsFixed(1)} BB',
              label: AppStrings.potOddsFinalPotLabel.toUpperCase(),
            ),
            ProtoChipNumeric(
              value: '${(result.requiredEquity * 100).toStringAsFixed(1)}%',
              label: AppStrings.potOddsRequiredEquityLabel.toUpperCase(),
            ),
            if (result.potOddsRatio != null)
              ProtoChipNumeric(
                value: '${result.potOddsRatio!.toStringAsFixed(1)}:1',
                label: AppStrings.potOddsRatioLabel.toUpperCase(),
              ),
          ],
        ),
        const SizedBox(height: ProtoSpace.lg),
        ProtoSurfacePanel(
          child: ProtoCalloutAccent(
            eyebrow: 'QUÉ SIGNIFICA',
            body: AppStrings.potOddsExplanation(result.requiredEquity * 100),
            color: accentFill,
            icon: Icons.info_outline_rounded,
          ),
        ),
      ],
    );
  }
}

@Preview(name: 'Tools · Pot Odds (Sala Verde)')
Widget previewToolsPrototype() => _stage(const _ToolsPrototype());
