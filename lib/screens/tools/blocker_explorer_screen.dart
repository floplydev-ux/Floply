import 'package:flutter/material.dart' hide Card;

import '../../engine/poker/card.dart';
import '../../engine/poker/combos/combo_engine.dart';
import '../../engine/poker/hole_cards.dart';
import '../../engine/strategy/hand_range.dart';
import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import 'combo_calculator_screen.dart';
import 'equity_calculator_screen.dart';
import 'range/range_explorer_controller.dart';
import 'range/range_explorer_screen.dart';
import 'widgets/card_situation.dart';
import 'widgets/tool_explainer.dart';
import 'widgets/tool_guide_screen.dart';
import 'widgets/tool_widgets.dart';

/// Público (antes privado): reutilizado por la guía consolidada del hub
/// (`tools_guide_sheet.dart`) — ver el doc-comment equivalente en
/// `pot_odds_calculator_screen.dart`.
const kBlockerToolId = 'blocker_explorer';
const kBlockerExplainer = ToolExplainerContent(
  title: 'Blockers',
  description:
      'Mostrá cuánto bloquea tu mano al rango del rival: cuántos de sus '
      'combos posibles ya no puede tener.',
  howToUse: 'Tocá tus 2 cartas para elegirlas, escribí el rango del '
      'rival y, si corresponde, tocá las cartas del board (opcional: '
      'podés dejarlo vacío para un análisis preflop).',
  result: 'Combos disponibles vs. bloqueados del rango rival, y el '
      'detalle por clase de mano.',
);

const kBlockerGuide = ToolGuideContent(
  title: 'Blockers',
  tagline: 'Efecto de tu mano sobre el rango del rival',
  icon: Icons.block_rounded,
  sections: [
    ToolGuideSection(
      label: '¿Para qué sirve?',
      body: 'Te muestra cuántos combos del rango del rival quedan '
          'disponibles después de que tu mano y el board bloquean combos. '
          'Cuantificá si tus cartas hacen más o menos probable que el '
          'rival tenga manos específicas.',
    ),
    ToolGuideSection(
      label: '¿Cuándo usarla?',
      items: [
        'Cuando evaluás un bluff: ¿tus cartas hacen menos probable que '
            'el rival tenga manos fuertes?',
        'Para analizar si conviene apostar por valor según los combos de '
            'nuts disponibles.',
        'En análisis postflop para cuantificar blockers antes de decidir.',
      ],
    ),
    ToolGuideSection(
      label: 'Cómo funciona',
      isFormula: true,
      body: 'total       = combos del rango (solo board como muertas)\n'
          'disponibles = combos (tu mano + board como muertas)\n'
          'bloqueados  = total − disponibles',
    ),
    ToolGuideSection(
      label: 'Ejemplo',
      body: 'AhKd vs QQ+,AKs,AKo (sin board)\n'
          '→ 34 totales · 21 disponibles · 13 bloqueados\n\n'
          'KK: 6→3 (Kd bloquea) · AA: 6→3 (Ah bloquea) · QQ: sin cambio',
    ),
    ToolGuideSection(
      label: 'Errores comunes',
      items: [
        'Concluir que un bluff es bueno solo por tener blockers. Los '
            'blockers son un factor, no la decisión completa.',
        'Ignorar que el board ya bloquea combos antes de que entre '
            'tu mano.',
      ],
    ),
    ToolGuideSection(
      label: 'Consejo FLOPly',
      body: 'Usá blockers junto con Equity: si bloqueás muchos combos de '
          'nuts del rival Y tu equity es razonable, el bluff tiene más '
          'sentido matemático.',
    ),
  ],
);

/// Blocker Explorer — sexta herramienta real de Tools (parte de V2, ver
/// `AUDITORIA_CHECKLIST_2026-09-18.md` §6).
///
/// Responde una pregunta puntual: de un rango rival, ¿cuántos combos
/// bloquean las dos cartas de tu mano (más el board, si hay)? Reutiliza
/// [ComboEngine] tal cual existe — corre el mismo cálculo dos veces con
/// distintas `deadCards` (solo board, vs. board + tu mano) y compara.
///
/// **Selector universal (sección 1):** tu mano y el board ahora se eligen
/// con [CardSituationController]/[CardGroupField] — mismo mecanismo que
/// Equity, no un picker aparte. El rango del rival sigue en texto — no
/// son "las cartas del jugador".
class BlockerExplorerScreen extends StatefulWidget {
  const BlockerExplorerScreen({
    super.key,
    this.initialHero,
    this.initialBoard = const [],
    this.initialVillainRangeTokens,
  });

  /// Precarga desde otra herramienta (hoy: Rangos, sección 13 — "Analizar
  /// blockers" desde una celda de la matriz). `null`/vacío conserva el
  /// comportamiento de siempre (mano A♥K♦ por defecto, sin board).
  final HoleCards? initialHero;
  final List<Card> initialBoard;
  final List<String>? initialVillainRangeTokens;

  @override
  State<BlockerExplorerScreen> createState() => _BlockerExplorerScreenState();
}

class _BlockerExplorerScreenState extends State<BlockerExplorerScreen> {
  late final _villainRangeController = TextEditingController(
    text: widget.initialVillainRangeTokens?.join(',') ?? 'QQ+,AKs,AKo',
  );

  // El board acá es opcional (min 0): a diferencia de EquityEngine,
  // ComboEngine no exige flop/turn/river — "sin board" es un análisis
  // preflop válido.
  late final _situation = CardSituationController([
    const CardGroupSpec(
      id: 'hero',
      label: AppStrings.blockerHeroLabel,
      minCount: 2,
      maxCount: 2,
      accent: SalaVerdeColors.brassBright,
    ),
    const CardGroupSpec(
      id: 'board',
      label: AppStrings.blockerBoardLabel,
      minCount: 0,
      maxCount: 5,
      accent: SalaVerdeColors.steelBlueBright,
    ),
  ]);

  _BlockerResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    final hero = widget.initialHero;
    if (hero != null) {
      _situation.setCard('hero', 0, hero.high);
      _situation.setCard('hero', 1, hero.low);
    } else {
      _situation.setCard('hero', 0, const Card(Rank.ace, Suit.hearts));
      _situation.setCard('hero', 1, const Card(Rank.king, Suit.diamonds));
    }
    for (final card in widget.initialBoard) {
      _situation.setCard('board', _situation.cardsOf('board').length, card);
    }
    _situation.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    _situation.removeListener(_recalculate);
    _situation.dispose();
    _villainRangeController.dispose();
    super.dispose();
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
    if (!_situation.isComplete('hero')) {
      setState(() {
        _result = null;
        _error = null;
      });
      return;
    }
    final heroCards = _situation.cardsOf('hero');
    final board = _situation.cardsOf('board');
    final hero = HoleCards(heroCards[0], heroCards[1]);
    final known = [...hero.cards, ...board];
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

  void _openEquity() {
    final heroCards = _situation.cardsOf('hero');
    final villainRange = _tryParseRange(_villainRangeController.text);
    if (heroCards.length < 2 || villainRange == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EquityCalculatorScreen(
        initialHeroHand: HoleCards(heroCards[0], heroCards[1]),
        initialVillainRangeTokens: villainRange.frequencies.keys.toList(),
        initialBoard: _situation.cardsOf('board'),
      ),
    ));
  }

  void _openRangeBuilder() {
    final villainRange = _tryParseRange(_villainRangeController.text);
    if (villainRange == null) return;
    final controller = RangeExplorerController()
      ..startDraftFromScratch()
      ..setMode(RangeToolMode.build);
    for (final entry in villainRange.frequencies.entries) {
      controller.setDraftFrequency(entry.key, entry.value);
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RangeExplorerScreen(controller: controller),
    ));
  }

  void _openCombos(String notation) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ComboCalculatorScreen(
        initialNotation: notation,
        initialDeadCards: _situation.cardsOf('board'),
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
                  icon: Icons.block_rounded,
                  title: AppStrings.toolsBlockerTitle,
                  subtitle: AppStrings.toolsBlockerCalculatorSubtitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: ToolInfoButton(
                    onTap: () => showToolExplainerSheet(
                      context,
                      toolId: kBlockerToolId,
                      content: kBlockerExplainer,
                    ),
                  ),
                ),
                const SizedBox(height: SalaVerdeSpace.xl),
                ToolCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CardGroupField(controller: _situation, groupId: 'hero'),
                      const SizedBox(height: SalaVerdeSpace.lg),
                      ToolTextField(
                        label: AppStrings.blockerVillainRangeLabel,
                        controller: _villainRangeController,
                        onChanged: _recalculate,
                        hintText: AppStrings.blockerVillainRangeHint,
                      ),
                      const SizedBox(height: SalaVerdeSpace.lg),
                      CardGroupField(controller: _situation, groupId: 'board'),
                    ],
                  ),
                ),
                const SizedBox(height: SalaVerdeSpace.lg),
                if (_error != null)
                  ToolErrorCard(message: _error!)
                else if (!_situation.isComplete('hero'))
                  const ToolEmptyState(
                    message: AppStrings.toolsHandPickBoth,
                    icon: Icons.style_rounded,
                  )
                else if (_result != null)
                  _ResultSection(
                    result: _result!,
                    onViewEquity: _openEquity,
                    onViewRangeInBuilder: _openRangeBuilder,
                    onViewCombos: _openCombos,
                  ),
              ],
            ),
          );
        }),
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
  const _ResultSection({
    required this.result,
    required this.onViewEquity,
    required this.onViewRangeInBuilder,
    required this.onViewCombos,
  });

  final _BlockerResult result;
  final VoidCallback onViewEquity;
  final VoidCallback onViewRangeInBuilder;
  final ValueChanged<String> onViewCombos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          borderColor: kToolAccent.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ToolSectionLabel(AppStrings.toolsResultPrincipal, color: kToolAccent),
              const SizedBox(height: SalaVerdeSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.blockerAvailableLabel,
                      value: '${result.available}',
                      big: true,
                      color: SalaVerdeColors.success,
                    ),
                  ),
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.blockerBlockedLabel,
                      value: '${result.total - result.available}',
                      big: true,
                      color: SalaVerdeColors.errorBright,
                    ),
                  ),
                  Expanded(
                    child: ToolResultStat(
                      label: AppStrings.blockerTotalLabel,
                      value: '${result.total}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              Text(
                AppStrings.blockerExplanation(
                  total: result.total,
                  available: result.available,
                ),
                style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        ToolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ToolSectionLabel(AppStrings.blockerClassesHeader),
              const SizedBox(height: SalaVerdeSpace.sm),
              Wrap(
                spacing: SalaVerdeSpace.sm,
                runSpacing: SalaVerdeSpace.sm,
                children: [
                  for (final classInfo in result.classes)
                    _ClassChip(info: classInfo, onTap: () => onViewCombos(classInfo.notation)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        Row(
          children: [
            Expanded(
              child: SvButtonSecondary(
                label: AppStrings.blockerViewEquity,
                onTap: onViewEquity,
              ),
            ),
            const SizedBox(width: SalaVerdeSpace.sm),
            Expanded(
              child: SvButtonSecondary(
                label: AppStrings.blockerViewRangeInBuilder,
                onTap: onViewRangeInBuilder,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClassChip extends StatelessWidget {
  const _ClassChip({required this.info, required this.onTap});

  final _ClassBlockInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (info.isFullyBlocked) {
      color = SalaVerdeColors.errorBright;
    } else if (info.isPartiallyBlocked) {
      color = SalaVerdeColors.warning;
    } else {
      color = SalaVerdeColors.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
          color: color.withValues(alpha: 0.14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          '${info.notation} ${info.after}/${info.before}',
          style: SalaVerdeType.caption(color: color).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
