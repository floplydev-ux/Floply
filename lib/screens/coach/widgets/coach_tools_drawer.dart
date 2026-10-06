import 'package:flutter/material.dart';

import '../../../engine/coach/coach_tools_info.dart';
import '../../../engine/poker/game/game_state.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// "Herramientas de ayuda" (evolución de la Mesa Coach, sección 6): un
/// panel contextual sobre la mesa — nunca saca al usuario de la
/// pantalla (se abre como `showModalBottomSheet`, ver
/// `CoachTableScreen._openTools`) — con consultas seleccionables una por
/// vez, cada una contextualizada a la mano/calle actual vía
/// [CoachToolsInfo], que a su vez reutiliza los motores existentes
/// (`PotOddsEngine`/`EquityEngine`/`EVEngine`/`OpeningRanges`/
/// `ComboEngine`) — nunca un sistema matemático paralelo.
///
/// Recibe una FOTO de [state] (la del momento en que se abrió el panel),
/// no una referencia viva: es una consulta puntual, no un panel que
/// necesite seguir la mano en vivo mientras está abierto.
class CoachToolsDrawer extends StatefulWidget {
  const CoachToolsDrawer({
    super.key,
    required this.state,
    required this.heroSlot,
  });

  final GameState state;
  final int heroSlot;

  @override
  State<CoachToolsDrawer> createState() => _CoachToolsDrawerState();
}

class _ToolEntry {
  const _ToolEntry(this.label, this.icon, this.content);
  final String label;
  final IconData icon;
  final String Function(GameState, int) content;
}

class _CoachToolsDrawerState extends State<CoachToolsDrawer> {
  int? _selected;

  static const List<_ToolEntry> _tools = [
    _ToolEntry(AppStrings.coachToolRange, Icons.style_rounded,
        CoachToolsInfo.rangeSummary),
    _ToolEntry(AppStrings.coachToolPotOdds, Icons.percent_rounded,
        CoachToolsInfo.potOddsSummary),
    _ToolEntry(AppStrings.coachToolEquity, Icons.pie_chart_rounded,
        CoachToolsInfo.equitySummary),
    _ToolEntry(AppStrings.coachToolEv, Icons.calculate_rounded,
        CoachToolsInfo.evSummary),
    _ToolEntry(AppStrings.coachToolSpot, Icons.info_outline_rounded,
        CoachToolsInfo.spotSummary),
    _ToolEntry(AppStrings.coachToolCombos, Icons.grid_view_rounded,
        CoachToolsInfo.combosSummary),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            SalaVerdeSpace.lg, SalaVerdeSpace.sm, SalaVerdeSpace.lg, SalaVerdeSpace.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: SalaVerdeSpace.md),
                  decoration: BoxDecoration(
                    color: SalaVerdeColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _selected == null ? _buildList() : _buildDetail(_selected!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppStrings.coachToolsTitle, style: SalaVerdeType.title()),
        const SizedBox(height: SalaVerdeSpace.xs),
        Text(AppStrings.coachToolsSubtitle, style: SalaVerdeType.body()),
        const SizedBox(height: SalaVerdeSpace.md),
        for (var i = 0; i < _tools.length; i++) ...[
          if (i > 0) const SizedBox(height: SalaVerdeSpace.sm),
          SvTappableCard(
            onTap: () => setState(() => _selected = i),
            child: Row(
              children: [
                Icon(_tools[i].icon, size: 20, color: SalaVerdeColors.brassBright),
                const SizedBox(width: SalaVerdeSpace.md),
                Expanded(
                  child: Text(_tools[i].label, style: SalaVerdeType.bodyStrong()),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: SalaVerdeColors.textSecondary),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetail(int index) {
    final tool = _tools[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PressableScale(
              onTap: () => setState(() => _selected = null),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SalaVerdeColors.surfaceElevated,
                  border: Border.all(color: SalaVerdeColors.borderSubtle),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    size: 16, color: SalaVerdeColors.textSecondary),
              ),
            ),
            const SizedBox(width: SalaVerdeSpace.md),
            Expanded(
              child: Text(tool.label, style: SalaVerdeType.title()),
            ),
          ],
        ),
        const SizedBox(height: SalaVerdeSpace.md),
        SvSurfacePanel(
          child: Text(
            tool.content(widget.state, widget.heroSlot),
            style: SalaVerdeType.body(),
          ),
        ),
      ],
    );
  }
}
