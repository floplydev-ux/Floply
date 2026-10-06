import 'package:flutter/material.dart';

import '../../../engine/poker/combos/combo_engine.dart';
import '../../../engine/poker/position.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../blocker_explorer_screen.dart';
import '../widgets/tool_explainer.dart';
import '../widgets/tool_guide_screen.dart';
import '../widgets/tool_widgets.dart';
import 'my_ranges_view.dart';
import 'range_builder_view.dart';
import 'range_compare_view.dart';
import 'range_explorer_controller.dart';
import 'range_import_export.dart';
import 'range_practice_view.dart';
import 'widgets/range_board_panel.dart';
import 'widgets/range_context_bar.dart';
import 'widgets/range_detail_sheet.dart';
import 'widgets/range_filters_bar.dart';
import 'widgets/range_matrix.dart';
import 'widgets/range_size_stat.dart';

/// Público (antes privado): reutilizado por la guía consolidada del hub
/// (`tools_guide_sheet.dart`) — ver el doc-comment equivalente en
/// `pot_odds_calculator_screen.dart`.
const kRangeToolId = 'range_explorer';
const kRangeExplainer = ToolExplainerContent(
  title: 'Rangos',
  description:
      'Explorá los rangos de referencia de FLOPly, construí los tuyos y '
      'practicá con ellos. Todas las frecuencias son las que declara '
      'cada rango — nunca un cálculo de equity ni una salida de solver.',
  howToUse: 'Elegí una posición para explorar el rango oficial, tocá '
      'una mano para ver sus combos, o pasate a "Construir" para armar '
      'uno propio.',
  result: 'La grilla completa de 13×13, con combos reales y, si cargás '
      'un board, cuántos de esos combos siguen disponibles.',
);

const kRangeGuide = ToolGuideContent(
  title: 'Rangos',
  tagline: 'Explorar, construir y practicar rangos',
  icon: Icons.grid_on_rounded,
  sections: [
    ToolGuideSection(
      label: '¿Para qué sirve?',
      body: 'Es la herramienta central para trabajar con rangos de '
          'apertura. Tres modos: Explorar (rangos oficiales), Construir '
          '(tus propios rangos) y Practicar (flashcards para memorizar '
          'qué manos jugás por posición).',
    ),
    ToolGuideSection(
      label: 'Los tres modos',
      items: [
        'Explorar: ve la grilla 13×13 de rangos oficiales por posición '
            '(UTG, HJ, CO, BTN, SB). Tocá una celda para ver sus combos.',
        'Construir: diseñá tu propio rango celda por celda, elegí '
            'frecuencias y guardalo.',
        'Practicar: te muestra una mano y tenés que decidir Raise o '
            'Fold según la posición seleccionada.',
      ],
    ),
    ToolGuideSection(
      label: 'La fórmula',
      isFormula: true,
      body: '% del rango = combos del rango ÷ 1326 × 100\n\n'
          'Donde 1326 = C(52,2) = total de manos posibles.',
    ),
    ToolGuideSection(
      label: 'Ejemplo',
      body: 'Rango QQ+,AKs,AKo\n'
          '→ 6+6+6+4+12 = 34 combos\n'
          '→ 34 ÷ 1326 × 100 = 2.6% de los hands posibles',
    ),
    ToolGuideSection(
      label: 'Errores comunes',
      items: [
        'El drill no penaliza las manos mixtas: si una mano tiene '
            'frecuencia parcial, tanto Raise como Fold son aceptados.',
        'Comparar rangos de posiciones distintas no tiene interpretación '
            'directa.',
      ],
    ),
    ToolGuideSection(
      label: 'Consejo FLOPly',
      body: 'Usá el modo Practicar 5 minutos por sesión, posición por '
          'posición. Es el camino más rápido para internalizar los rangos.',
    ),
  ],
);

enum _ExploreSubView { browse, myRanges, compare }

/// Range Explorer / Builder — herramienta profesional de rangos de
/// FLOPly (Explorar / Construir / Practicar). Reemplaza al visor V1
/// (solo lectura de RFI) manteniendo su mismo dato de origen
/// (`OpeningRanges`) como única fuente oficial.
class RangeExplorerScreen extends StatefulWidget {
  const RangeExplorerScreen({super.key, this.controller});

  /// Inyectable para tests (mismo criterio que `AcademyScreen({this.
  /// controller})`) — sin esto, todos los widget tests que guardan un
  /// rango propio compartirían el mismo `defaultSavedRangeStore`
  /// singleton entre sí.
  final RangeExplorerController? controller;

  @override
  State<RangeExplorerScreen> createState() => _RangeExplorerScreenState();
}

class _RangeExplorerScreenState extends State<RangeExplorerScreen> {
  late final _controller = widget.controller ?? RangeExplorerController();
  _ExploreSubView _subView = _ExploreSubView.browse;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _openBlockersFor(String notation) {
    final board = _controller.boardCards;
    final combos = ComboEngine.combosForNotation(notation, deadCards: board);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlockerExplorerScreen(
        initialHero: combos.isNotEmpty ? combos.first : null,
        initialBoard: board,
      ),
    ));
  }

  void _onCellTap(String notation) {
    _controller.selectCell(notation);
    showRangeDetailSheet(
      context,
      controller: _controller,
      notation: notation,
      onAnalyzeBlockers: () => _openBlockersFor(notation),
    );
  }

  Future<void> _importExport() async {
    final imported = await showRangeImportExportSheet(context, range: _controller.activeRange);
    if (imported == null || !mounted) return;
    _controller.startDraftFromScratch();
    for (final entry in imported.frequencies.entries) {
      _controller.setDraftFrequency(entry.key, entry.value);
    }
    _controller.setMode(RangeToolMode.build);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final isBbOfficial = c.isViewingOfficial && c.context.position == Position.bb;

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
                  icon: Icons.grid_on_rounded,
                  title: AppStrings.toolsRangesTitle,
                  subtitle: AppStrings.toolsRangesCalculatorSubtitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: ToolInfoButton(
                    onTap: () => showToolExplainerSheet(
                      context,
                      toolId: kRangeToolId,
                      content: kRangeExplainer,
                    ),
                  ),
                ),
                const SizedBox(height: SalaVerdeSpace.lg),
                RangeContextBar(controller: c),
                const SizedBox(height: SalaVerdeSpace.lg),
                _ModeTabs(mode: c.mode, onChanged: c.setMode),
                const SizedBox(height: SalaVerdeSpace.lg),
                if (c.mode == RangeToolMode.explore)
                  _buildExplore(context, c, isBbOfficial)
                else if (c.mode == RangeToolMode.build)
                  RangeBuilderView(controller: c)
                else
                  _buildPractice(c),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildExplore(BuildContext context, RangeExplorerController c, bool isBbOfficial) {
    if (isBbOfficial) {
      return const ToolEmptyState(
        title: AppStrings.rangesBbTitle,
        message: AppStrings.rangesBbBody,
        icon: Icons.shield_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Horizontal-scrollable: a 320dp los 3 links no entran junto
            // al ícono de Import/Export — se prefiere que esta fila
            // deslice antes que desbordar o achicar el texto hasta ser
            // ilegible.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SubViewLink(
                      label: AppStrings.rangesBrowseLabel,
                      active: _subView == _ExploreSubView.browse,
                      onTap: () => setState(() => _subView = _ExploreSubView.browse),
                    ),
                    const SizedBox(width: SalaVerdeSpace.md),
                    _SubViewLink(
                      label: AppStrings.rangesMyRangesTitle,
                      active: _subView == _ExploreSubView.myRanges,
                      onTap: () => setState(() => _subView = _ExploreSubView.myRanges),
                    ),
                    const SizedBox(width: SalaVerdeSpace.md),
                    _SubViewLink(
                      label: AppStrings.rangesCompareTitle,
                      active: _subView == _ExploreSubView.compare,
                      onTap: () => setState(() => _subView = _ExploreSubView.compare),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.import_export_rounded, color: kToolAccent),
              onPressed: _importExport,
              tooltip: AppStrings.rangesImportExportTitle,
            ),
          ],
        ),
        const SizedBox(height: SalaVerdeSpace.md),
        switch (_subView) {
          _ExploreSubView.browse => _buildBrowse(c),
          _ExploreSubView.myRanges => MyRangesView(
              controller: c,
              onOpen: (r) {
                c.openSaved(r.id);
                setState(() => _subView = _ExploreSubView.browse);
              },
              onEdit: (r) {
                c.startDraftFromSaved(r);
                c.setMode(RangeToolMode.build);
              },
            ),
          _ExploreSubView.compare => RangeCompareView(controller: c),
        },
      ],
    );
  }

  Widget _buildBrowse(RangeExplorerController c) {
    final range = c.activeRange;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          child: Row(
            children: [
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.rangesPositionLabel,
                  value: c.isViewingOfficial
                      ? c.context.position.fullName
                      : (c.openSavedRange?.name ?? ''),
                ),
              ),
              RangeSizeStat(range: range),
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        RangeFiltersBar(filters: c.filters, onChanged: c.setFilters),
        const SizedBox(height: SalaVerdeSpace.lg),
        ToolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RangeMatrix(
                range: range,
                selected: c.selectedNotation,
                onCellTap: _onCellTap,
                filters: c.filters,
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              const _Legend(),
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        ToolCard(child: RangeBoardPanel(controller: c)),
        if (!c.isViewingOfficial) ...[
          const SizedBox(height: SalaVerdeSpace.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: c.viewOfficial,
              child: const Text(AppStrings.rangesOpenOfficial),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPractice(RangeExplorerController c) {
    if (c.context.position == Position.bb && c.isViewingOfficial) {
      return const ToolEmptyState(
        title: AppStrings.rangesBbTitle,
        message: AppStrings.rangesBbBody,
        icon: Icons.shield_rounded,
      );
    }
    final range = c.activeRange;
    if (range.classes.isEmpty) {
      return const ToolEmptyState(
        message: AppStrings.rangesPracticeEmptyRange,
        icon: Icons.school_rounded,
      );
    }
    return RangePracticeView(range: range);
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});

  final RangeToolMode mode;
  final ValueChanged<RangeToolMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ToolModeChip(
            label: AppStrings.rangesModeExplore,
            active: mode == RangeToolMode.explore,
            onTap: () => onChanged(RangeToolMode.explore),
          ),
        ),
        const SizedBox(width: SalaVerdeSpace.sm),
        Expanded(
          child: ToolModeChip(
            label: AppStrings.rangesModeBuild,
            active: mode == RangeToolMode.build,
            onTap: () => onChanged(RangeToolMode.build),
          ),
        ),
        const SizedBox(width: SalaVerdeSpace.sm),
        Expanded(
          child: ToolModeChip(
            label: AppStrings.rangesModePractice,
            active: mode == RangeToolMode.practice,
            onTap: () => onChanged(RangeToolMode.practice),
          ),
        ),
      ],
    );
  }
}

class _SubViewLink extends StatelessWidget {
  const _SubViewLink({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: SalaVerdeType.caption(color: active ? kToolAccent : SalaVerdeColors.textMuted)
            .copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        const _LegendItem(color: SalaVerdeColors.success, label: AppStrings.rangesLegendFull),
        _LegendItem(
          color: SalaVerdeColors.success.withValues(alpha: 0.5),
          label: AppStrings.rangesLegendMixed,
        ),
        const _LegendItem(
          color: SalaVerdeColors.surfaceElevated,
          label: AppStrings.rangesLegendNone,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: SalaVerdeColors.borderSubtle),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary)),
      ],
    );
  }
}
