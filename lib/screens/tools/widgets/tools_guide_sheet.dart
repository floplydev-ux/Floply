import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../blocker_explorer_screen.dart' show kBlockerExplainer;
import '../combo_calculator_screen.dart' show kComboExplainer;
import '../ev_calculator_screen.dart' show kEvExplainer;
import '../equity_calculator_screen.dart' show kEquityExplainer;
import '../pot_odds_calculator_screen.dart' show kPotOddsExplainer;
import '../range/range_explorer_screen.dart' show kRangeExplainer;
import 'tool_explainer.dart';
import 'tool_widgets.dart' show kToolAccent;

/// Guía consolidada de Tools (sección "¿Cómo usar las herramientas?") —
/// una sola hoja, accesible desde el hub ([ToolsScreen], nunca desde
/// dentro de una herramienta puntual: para eso ya existe el ⓘ de cada
/// [ToolHeader]), que repasa las 6 calculadoras reales antes de que el
/// usuario entre a ninguna.
///
/// **Nunca un segundo sistema de ayuda**: reutiliza el mismo
/// [ToolExplainerContent] real de cada herramienta (`kRangeExplainer`,
/// `kEquityExplainer`, etc. — antes privados, ahora públicos
/// específicamente para esto) para "qué es"/"qué tenés que ingresar"/
/// "qué resultado obtenés" — el único contenido genuinamente nuevo acá es
/// "cuándo conviene usarla" y un ejemplo breve, que esos modales por
/// herramienta no tenían. Ninguna herramienta ni su matemática se toca.
///
/// Colapsada por defecto (pedido explícito: "no saturar la pantalla") —
/// cada tarjeta se expande individualmente para ver el detalle completo.
void showToolsGuideSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _ToolsGuideSheet(),
  );
}

class _ToolGuideEntry {
  const _ToolGuideEntry({
    required this.icon,
    required this.explainer,
    required this.whenToUse,
    required this.example,
  });

  final IconData icon;
  final ToolExplainerContent explainer;
  final String whenToUse;
  final String example;
}

/// Mismo orden conceptual que el hub ([ToolsScreen]): Rangos alimenta a
/// las demás, Pot Odds y EV cierran la cadena de decisión.
const List<_ToolGuideEntry> _kToolGuideEntries = [
  _ToolGuideEntry(
    icon: Icons.grid_on_rounded,
    explainer: kRangeExplainer,
    whenToUse: 'Antes de abrir o de pagar una mano, para saber si esa '
        'combinación entra en el rango habitual de tu posición — o para '
        'armar y guardar tu propio rango de estudio.',
    example: 'Elegís CO: ves que A9s entra en el rango de apertura (RFI) '
        'de esa posición.',
  ),
  _ToolGuideEntry(
    icon: Icons.pie_chart_rounded,
    explainer: kEquityExplainer,
    whenToUse: 'Cuando ya tenés un board concreto y querés saber qué tan '
        'adelante (o atrás) estás contra una mano o un rango puntual del '
        'rival.',
    example: 'AKs vs QQ en un board A-7-2: tu equity ronda el 70%.',
  ),
  _ToolGuideEntry(
    icon: Icons.percent_rounded,
    explainer: kPotOddsExplainer,
    whenToUse: 'Antes de pagar una apuesta, cuando todavía no tenés tu '
        'equity exacta pero querés el piso que necesitás para que pagar '
        'no sea una pérdida a largo plazo.',
    example: 'Bote de 10bb, te piden pagar 5bb → necesitás ~33% de '
        'equity para que pagar sea rentable.',
  ),
  _ToolGuideEntry(
    icon: Icons.query_stats_rounded,
    explainer: kEvExplainer,
    whenToUse: 'Cuando ya tenés una equity estimada (la tuya, o la que te '
        'dio la calculadora de Equity) y querés saber cuántas BB ganás o '
        'perdés en promedio con esa decisión.',
    example: 'Con 40% de equity, pagar 5bb en un bote de 15bb da un EV '
        'de -1bb: con esos números, pagar pierde a largo plazo.',
  ),
  _ToolGuideEntry(
    icon: Icons.style_rounded,
    explainer: kComboExplainer,
    whenToUse: 'Para contar cuántas combinaciones reales le quedan a una '
        'mano según qué cartas ya están fuera del mazo (tu mano, el '
        'board).',
    example: 'AKs tiene 4 combos en total; si vos tenés un As, le '
        'quedan como máximo 3.',
  ),
  _ToolGuideEntry(
    icon: Icons.block_rounded,
    explainer: kBlockerExplainer,
    whenToUse: 'Para pesar un farol o un call según cuánto tu mano le '
        'saca combos de valor (o de farol) al rango del rival.',
    example: 'Con AA en mano, un rival que sube con QQ+/AKs/AKo ya '
        'pierde 2 de sus 6 combos de AA — tu mano bloquea buena parte de '
        'su rango más fuerte.',
  ),
];

class _ToolsGuideSheet extends StatefulWidget {
  const _ToolsGuideSheet();

  @override
  State<_ToolsGuideSheet> createState() => _ToolsGuideSheetState();
}

class _ToolsGuideSheetState extends State<_ToolsGuideSheet> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SalaVerdeColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(SalaVerdeRadius.sheet)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    SalaVerdeSpace.lg, SalaVerdeSpace.lg, SalaVerdeSpace.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: SalaVerdeSpace.lg),
                        decoration: BoxDecoration(
                          color: SalaVerdeColors.borderSubtle,
                          borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: kToolAccent, size: 20),
                        const SizedBox(width: SalaVerdeSpace.sm),
                        Expanded(
                          child: Text(AppStrings.toolsGuideTitle, style: SalaVerdeType.title()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.toolsGuideSubtitle,
                      style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
                    ),
                    const SizedBox(height: SalaVerdeSpace.md),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: SalaVerdeSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _kToolGuideEntries.length; i++) ...[
                        if (i > 0) const SizedBox(height: SalaVerdeSpace.sm),
                        _ToolGuideCard(
                          entry: _kToolGuideEntries[i],
                          expanded: _expandedIndex == i,
                          onTap: () => setState(
                              () => _expandedIndex = _expandedIndex == i ? null : i),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(SalaVerdeSpace.lg),
                child: SvButtonPrimary(
                  label: AppStrings.toolsGuideClose,
                  accent: kToolAccent,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolGuideCard extends StatelessWidget {
  const _ToolGuideCard({
    required this.entry,
    required this.expanded,
    required this.onTap,
  });

  final _ToolGuideEntry entry;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = entry.explainer;
    return Container(
      decoration: BoxDecoration(
        color: SalaVerdeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        border: Border.all(color: SalaVerdeColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PressableScale(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(SalaVerdeSpace.md),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kToolAccent.withValues(alpha: 0.14),
                    ),
                    child: Icon(entry.icon, color: kToolAccent, size: 18),
                  ),
                  const SizedBox(width: SalaVerdeSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(content.title, style: SalaVerdeType.bodyStrong()),
                        if (!expanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            content.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: SalaVerdeColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  SalaVerdeSpace.md, 0, SalaVerdeSpace.md, SalaVerdeSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
                  const SizedBox(height: SalaVerdeSpace.sm),
                  Text(content.description, style: SalaVerdeType.body()),
                  const SizedBox(height: SalaVerdeSpace.md),
                  _GuideRow(label: AppStrings.toolsExplainerHowToUse, body: content.howToUse),
                  const SizedBox(height: SalaVerdeSpace.sm),
                  _GuideRow(label: AppStrings.toolsExplainerResult, body: content.result),
                  const SizedBox(height: SalaVerdeSpace.sm),
                  _GuideRow(label: AppStrings.toolsGuideWhenToUse, body: entry.whenToUse),
                  const SizedBox(height: SalaVerdeSpace.sm),
                  SvCalloutAccent(
                    eyebrow: AppStrings.toolsGuideExample,
                    body: entry.example,
                    color: kToolAccent,
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SalaVerdeType.label(color: SalaVerdeColors.textMuted)),
        const SizedBox(height: 4),
        Text(body, style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary)),
      ],
    );
  }
}
