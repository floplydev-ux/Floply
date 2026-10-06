import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart' hide Card;

import '../../engine/poker/card.dart';
import '../../engine/poker/equity/equity_engine.dart';
import '../../engine/poker/equity/equity_result.dart';
import '../../engine/poker/hole_cards.dart';
import '../../engine/strategy/hand_range.dart';
import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import 'ev_calculator_screen.dart';
import 'widgets/card_situation.dart';
import 'widgets/tool_explainer.dart';
import 'widgets/tool_guide_screen.dart';
import 'widgets/tool_widgets.dart';

/// Público (antes privado): reutilizado por la guía consolidada del hub
/// (`tools_guide_sheet.dart`) — ver el doc-comment equivalente en
/// `pot_odds_calculator_screen.dart`.
const kEquityToolId = 'equity_calculator';
const kEquityExplainer = ToolExplainerContent(
  title: 'Equity',
  description:
      'Calculá qué porcentaje del bote te corresponde en promedio, '
      'comparando tu mano (o rango) contra la del rival.',
  howToUse: 'Elegí el modo (mano vs mano, mano vs rango, rango vs rango). '
      'Para una mano, tocá sus 2 cartas para elegirlas; para un rango, '
      'escribilo en notación (ej. 77+,ATs+). El board se elige tocando '
      'sus cartas: 3 para el flop, y podés sumar el turn y el river.',
  result: 'Tu equity total, y cómo se reparte entre ganar, empatar y '
      'perder.',
  extra: 'En mano vs rango y rango vs rango el cálculo puede tardar unos '
      'segundos: enumera cada combinación física posible, no es una '
      'aproximación.',
);

const kEquityGuide = ToolGuideContent(
  title: 'Equity',
  tagline: 'Enumeración exacta de runouts',
  icon: Icons.pie_chart_rounded,
  sections: [
    ToolGuideSection(
      label: '¿Para qué sirve?',
      body: 'Calcula tu probabilidad real de ganar enumerando todos los '
          'runouts posibles. Sin Monte Carlo ni aproximaciones. Es el '
          'número que alimenta la calculadora de EV.',
    ),
    ToolGuideSection(
      label: '¿Cuándo usarla?',
      items: [
        'Con un board de flop, turn o river concreto.',
        'Para comparar tu equity real con la equity mínima de Pot Odds.',
        'Modo mano vs mano: instantáneo. Mano vs rango: unos segundos. '
            'Rango vs rango: puede tardar (no es una aproximación).',
      ],
    ),
    ToolGuideSection(
      label: 'Limitación importante',
      isNote: true,
      body: 'Solo funciona en flop, turn y river (board de 3, 4 o 5 '
          'cartas). El análisis preflop no está disponible.',
    ),
    ToolGuideSection(
      label: 'La fórmula',
      isFormula: true,
      body: 'equity = wins/total + ties/(total × 2)\n\n'
          'total = todos los runouts posibles con las cartas no vistas.',
    ),
    ToolGuideSection(
      label: 'Ejemplo',
      body: 'AhKd vs AsQd · Flop 2c7d9h\n'
          '→ Equity héroe ≈ 66%\n\n'
          'Desde el resultado podés pasar a EV con esta equity precargada.',
    ),
    ToolGuideSection(
      label: 'Errores comunes',
      items: [
        'Usar la misma carta en más de un slot — FLOPly detecta duplicados.',
        'Rango que queda vacío después de aplicar el board — se avisa con error.',
        'Esperar resultado instantáneo en rango vs rango con rangos amplios.',
      ],
    ),
  ],
);

enum _EquityMode { handVsHand, handVsRange, rangeVsRange }

/// Payload de [_handVsRangeInIsolate] — [compute] exige una función
/// tope de nivel (no un closure de instancia), así que los argumentos
/// viajan empaquetados en un solo objeto simple.
class _HandVsRangeRequest {
  const _HandVsRangeRequest(this.hero, this.villainRange, this.board);
  final HoleCards hero;
  final HandRange villainRange;
  final List<Card> board;
}

EquityResult _handVsRangeInIsolate(_HandVsRangeRequest request) =>
    EquityEngine.handVsRange(request.hero, request.villainRange, request.board);

class _RangeVsRangeRequest {
  const _RangeVsRangeRequest(this.heroRange, this.villainRange, this.board);
  final HandRange heroRange;
  final HandRange villainRange;
  final List<Card> board;
}

EquityResult _rangeVsRangeInIsolate(_RangeVsRangeRequest request) =>
    EquityEngine.rangeVsRange(request.heroRange, request.villainRange, request.board);

/// Equity Calculator — tercera herramienta real de Tools V1 (mano vs
/// mano), extendida en V2 con mano vs rango y rango vs rango sobre
/// [EquityEngine.handVsRange]/[EquityEngine.rangeVsRange].
///
/// **Selector universal de cartas:** la mano del héroe (los 3 modos), la
/// del rival (mano vs mano) y el board (los 3 modos) se eligen con
/// [CardSituationController]/[CardGroupField] — el mismo mecanismo que
/// usan Blocker Explorer y Combo Calculator, no un picker por modo. Los
/// rangos (mano vs rango, rango vs rango) no son cartas puntuales —
/// siguen en notación, que es la única forma sensata de expresar "77+,
/// ATs+".
///
/// **Por qué mano vs rango y rango vs rango no recalculan en vivo**
/// (a diferencia de mano vs mano): el propio doc-comment de
/// [EquityEngine.rangeVsRange] advierte que es el caso más pesado del
/// motor (`heroCombos × villainCombos × runouts`) y pide explícitamente
/// no correrlo en el camino de un `build()`. Estos dos modos calculan
/// solo al tocar "Calcular equity" y la llamada corre con [compute] en
/// un isolate aparte.
class EquityCalculatorScreen extends StatefulWidget {
  const EquityCalculatorScreen({
    super.key,
    this.initialHeroHand,
    this.initialHeroRangeTokens,
    this.initialVillainHand,
    this.initialVillainRangeTokens,
    this.initialBoard = const [],
  });

  /// Precarga desde otra herramienta (hoy: Blocker Explorer → mano vs
  /// rango; Rangos en modo Comparar → rango vs rango). El modo inicial
  /// se infiere de qué combinación de estos llega, nunca un parámetro de
  /// modo aparte — todo `null`/vacío conserva el comportamiento de
  /// siempre (mano vs mano con los valores por defecto).
  final HoleCards? initialHeroHand;
  final List<String>? initialHeroRangeTokens;
  final HoleCards? initialVillainHand;
  final List<String>? initialVillainRangeTokens;
  final List<Card> initialBoard;

  @override
  State<EquityCalculatorScreen> createState() => _EquityCalculatorScreenState();
}

class _EquityCalculatorScreenState extends State<EquityCalculatorScreen> {
  _EquityMode _mode = _EquityMode.handVsHand;

  // Modo 1: mano vs mano (V1, recalcula en vivo). Board 3-5 cartas: es lo
  // mínimo que acepta EquityEngine.handVsHand (preflop está fuera de
  // alcance del motor, ver su doc-comment), nunca 0.
  late final _hhSituation = CardSituationController([
    const CardGroupSpec(
      id: 'hero',
      label: AppStrings.equityHeroLabel,
      minCount: 2,
      maxCount: 2,
      accent: SalaVerdeColors.brassBright,
    ),
    const CardGroupSpec(
      id: 'villain',
      label: AppStrings.equityVillainLabel,
      minCount: 2,
      maxCount: 2,
      accent: SalaVerdeColors.errorBright,
    ),
    const CardGroupSpec(
      id: 'board',
      label: AppStrings.equityBoardLabel,
      minCount: 3,
      maxCount: 5,
      accent: SalaVerdeColors.steelBlueBright,
    ),
  ]);
  EquityResult? _result;

  // Modo 2: mano vs rango (V2, botón "Calcular"). El rango rival sigue en
  // notación de texto: un rango no son 2 cartas concretas del jugador.
  late final _hvrSituation = CardSituationController([
    const CardGroupSpec(
      id: 'hero',
      label: AppStrings.equityHeroLabel,
      minCount: 2,
      maxCount: 2,
      accent: SalaVerdeColors.brassBright,
    ),
    const CardGroupSpec(
      id: 'board',
      label: AppStrings.equityBoardLabel,
      minCount: 3,
      maxCount: 5,
      accent: SalaVerdeColors.steelBlueBright,
    ),
  ]);
  final _hvrVillainRangeController = TextEditingController(text: 'QQ+,AKs,AKo');
  _RangeCalcState _hvrState = _RangeCalcState.idle;
  EquityResult? _hvrResult;
  String? _hvrError;

  // Modo 3: rango vs rango (V2, botón "Calcular"). Ninguno de los dos
  // lados es una mano concreta acá — solo el board son cartas puntuales.
  final _rvrHeroRangeController = TextEditingController(text: 'AA,KK');
  final _rvrVillainRangeController = TextEditingController(text: 'QQ,JJ');
  late final _rvrSituation = CardSituationController([
    const CardGroupSpec(
      id: 'board',
      label: AppStrings.equityBoardLabel,
      minCount: 3,
      maxCount: 5,
      accent: SalaVerdeColors.steelBlueBright,
    ),
  ]);
  _RangeCalcState _rvrState = _RangeCalcState.idle;
  EquityResult? _rvrResult;
  String? _rvrError;

  @override
  void initState() {
    super.initState();
    final heroHand = widget.initialHeroHand;
    final villainHand = widget.initialVillainHand;
    final heroRangeTokens = widget.initialHeroRangeTokens;
    final villainRangeTokens = widget.initialVillainRangeTokens;
    final board = widget.initialBoard;

    // Modo inferido de qué llegó precargado — nunca un parámetro de modo
    // aparte (ver doc-comment del constructor).
    final bool startInRangeVsRange = heroRangeTokens != null && villainRangeTokens != null;
    final bool startInHandVsRange =
        !startInRangeVsRange && heroHand != null && villainRangeTokens != null;

    if (startInRangeVsRange) {
      _mode = _EquityMode.rangeVsRange;
      _rvrHeroRangeController.text = heroRangeTokens.join(',');
      _rvrVillainRangeController.text = villainRangeTokens.join(',');
      for (final card in board) {
        _rvrSituation.setCard('board', _rvrSituation.cardsOf('board').length, card);
      }
    } else if (startInHandVsRange) {
      _mode = _EquityMode.handVsRange;
      _hvrSituation.setCard('hero', 0, heroHand.high);
      _hvrSituation.setCard('hero', 1, heroHand.low);
      _hvrVillainRangeController.text = villainRangeTokens.join(',');
      for (final card in board) {
        _hvrSituation.setCard('board', _hvrSituation.cardsOf('board').length, card);
      }
    }

    if (heroHand != null && villainHand != null) {
      _hhSituation.setCard('hero', 0, heroHand.high);
      _hhSituation.setCard('hero', 1, heroHand.low);
      _hhSituation.setCard('villain', 0, villainHand.high);
      _hhSituation.setCard('villain', 1, villainHand.low);
      for (final card in board) {
        _hhSituation.setCard('board', _hhSituation.cardsOf('board').length, card);
      }
      if (!startInRangeVsRange && !startInHandVsRange) _mode = _EquityMode.handVsHand;
    } else if (!startInRangeVsRange && !startInHandVsRange) {
      _hhSituation.setCard('hero', 0, const Card(Rank.ace, Suit.hearts));
      _hhSituation.setCard('hero', 1, const Card(Rank.king, Suit.diamonds));
      _hhSituation.setCard('villain', 0, const Card(Rank.ace, Suit.spades));
      _hhSituation.setCard('villain', 1, const Card(Rank.queen, Suit.diamonds));
      _hhSituation.setCard('board', 0, const Card(Rank.two, Suit.clubs));
      _hhSituation.setCard('board', 1, const Card(Rank.seven, Suit.diamonds));
      _hhSituation.setCard('board', 2, const Card(Rank.nine, Suit.hearts));
    }
    _hhSituation.addListener(_recalculateHandVsHand);
    _recalculateHandVsHand();

    if (!startInHandVsRange) {
      _hvrSituation.setCard('hero', 0, const Card(Rank.ace, Suit.hearts));
      _hvrSituation.setCard('hero', 1, const Card(Rank.king, Suit.diamonds));
      _hvrSituation.setCard('board', 0, const Card(Rank.two, Suit.clubs));
      _hvrSituation.setCard('board', 1, const Card(Rank.seven, Suit.diamonds));
      _hvrSituation.setCard('board', 2, const Card(Rank.nine, Suit.hearts));
    }
    if (!startInRangeVsRange) {
      _rvrSituation.setCard('board', 0, const Card(Rank.two, Suit.clubs));
      _rvrSituation.setCard('board', 1, const Card(Rank.seven, Suit.diamonds));
      _rvrSituation.setCard('board', 2, const Card(Rank.nine, Suit.hearts));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Rango vs rango NO se calcula solo, a propósito: con dos rangos
      // reales anchos (el caso típico al llegar desde Comparar — p. ej.
      // "BTN Open vs UTG Open") el costo real es
      // `heroCombos × villainCombos × runouts` (ver el doc-comment de
      // `EquityEngine.rangeVsRange`), potencialmente varios segundos —
      // el botón "Calcular equity" existe justamente para que ese costo
      // sea una decisión explícita del usuario, no una sorpresa al
      // abrir la pantalla. Mano vs rango sí calcula sola: como máximo
      // son 4 combos de hero, mucho más barato.
      if (startInHandVsRange) _calculateHandVsRange();
    });
  }

  @override
  void dispose() {
    _hhSituation.removeListener(_recalculateHandVsHand);
    _hhSituation.dispose();
    _hvrSituation.dispose();
    _hvrVillainRangeController.dispose();
    _rvrHeroRangeController.dispose();
    _rvrVillainRangeController.dispose();
    _rvrSituation.dispose();
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

  void _recalculateHandVsHand() {
    if (!_hhSituation.isComplete('hero') ||
        !_hhSituation.isComplete('villain') ||
        !_hhSituation.isComplete('board')) {
      setState(() => _result = null);
      return;
    }
    final heroCards = _hhSituation.cardsOf('hero');
    final villainCards = _hhSituation.cardsOf('villain');
    final hero = HoleCards(heroCards[0], heroCards[1]);
    final villain = HoleCards(villainCards[0], villainCards[1]);
    final result = EquityEngine.handVsHand(hero, villain, _hhSituation.cardsOf('board'));
    setState(() => _result = result);
  }

  Future<void> _calculateHandVsRange() async {
    if (!_hvrSituation.isComplete('hero')) {
      setState(() {
        _hvrState = _RangeCalcState.error;
        _hvrError = AppStrings.toolsHandPickBoth;
      });
      return;
    }
    if (!_hvrSituation.isComplete('board')) {
      setState(() {
        _hvrState = _RangeCalcState.error;
        _hvrError = AppStrings.toolsBoardMissing(3 - _hvrSituation.cardsOf('board').length);
      });
      return;
    }
    final villainRange = _tryParseRange(_hvrVillainRangeController.text);
    if (villainRange == null) {
      setState(() {
        _hvrState = _RangeCalcState.error;
        _hvrError = AppStrings.equityRangeInvalidInput;
      });
      return;
    }

    setState(() => _hvrState = _RangeCalcState.loading);
    final heroCards = _hvrSituation.cardsOf('hero');
    try {
      final result = await compute(
        _handVsRangeInIsolate,
        _HandVsRangeRequest(
          HoleCards(heroCards[0], heroCards[1]),
          villainRange,
          _hvrSituation.cardsOf('board'),
        ),
      );
      if (!mounted) return;
      setState(() {
        _hvrResult = result;
        _hvrState = _RangeCalcState.success;
      });
    } on ArgumentError {
      if (!mounted) return;
      setState(() {
        _hvrState = _RangeCalcState.error;
        _hvrError = AppStrings.equityRangeBlockedError;
      });
    }
  }

  Future<void> _calculateRangeVsRange() async {
    if (!_rvrSituation.isComplete('board')) {
      setState(() {
        _rvrState = _RangeCalcState.error;
        _rvrError = AppStrings.toolsBoardMissing(3 - _rvrSituation.cardsOf('board').length);
      });
      return;
    }
    final heroRange = _tryParseRange(_rvrHeroRangeController.text);
    final villainRange = _tryParseRange(_rvrVillainRangeController.text);
    if (heroRange == null || villainRange == null) {
      setState(() {
        _rvrState = _RangeCalcState.error;
        _rvrError = AppStrings.equityRangeInvalidInput;
      });
      return;
    }

    setState(() => _rvrState = _RangeCalcState.loading);
    final board = _rvrSituation.cardsOf('board');
    try {
      final result = await compute(
        _rangeVsRangeInIsolate,
        _RangeVsRangeRequest(heroRange, villainRange, board),
      );
      if (!mounted) return;
      setState(() {
        _rvrResult = result;
        _rvrState = _RangeCalcState.success;
      });
    } on ArgumentError {
      if (!mounted) return;
      setState(() {
        _rvrState = _RangeCalcState.error;
        _rvrError = AppStrings.equityRangeBlockedError;
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
                  icon: Icons.pie_chart_rounded,
                  title: AppStrings.toolsEquityTitle,
                  subtitle: AppStrings.toolsEquityCalculatorSubtitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: ToolInfoButton(
                    onTap: () => showToolExplainerSheet(
                      context,
                      toolId: kEquityToolId,
                      content: kEquityExplainer,
                    ),
                  ),
                ),
                const SizedBox(height: SalaVerdeSpace.xl),
                Wrap(
                  spacing: SalaVerdeSpace.sm,
                  runSpacing: SalaVerdeSpace.sm,
                  children: [
                    ToolModeChip(
                      label: AppStrings.equityModeHandVsHandLabel,
                      active: _mode == _EquityMode.handVsHand,
                      onTap: () => setState(() => _mode = _EquityMode.handVsHand),
                    ),
                    ToolModeChip(
                      label: AppStrings.equityModeHandVsRangeLabel,
                      active: _mode == _EquityMode.handVsRange,
                      onTap: () => setState(() => _mode = _EquityMode.handVsRange),
                    ),
                    ToolModeChip(
                      label: AppStrings.equityModeRangeVsRangeLabel,
                      active: _mode == _EquityMode.rangeVsRange,
                      onTap: () => setState(() => _mode = _EquityMode.rangeVsRange),
                    ),
                  ],
                ),
                const SizedBox(height: SalaVerdeSpace.lg),
                switch (_mode) {
                  _EquityMode.handVsHand => _buildHandVsHand(),
                  _EquityMode.handVsRange => _buildHandVsRange(),
                  _EquityMode.rangeVsRange => _buildRangeVsRange(),
                },
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHandVsHand() {
    final handsReady = _hhSituation.isComplete('hero') && _hhSituation.isComplete('villain');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardGroupField(controller: _hhSituation, groupId: 'hero'),
              const SizedBox(height: SalaVerdeSpace.lg),
              CardGroupField(controller: _hhSituation, groupId: 'villain'),
              const SizedBox(height: SalaVerdeSpace.lg),
              CardGroupField(controller: _hhSituation, groupId: 'board'),
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        if (!handsReady)
          const ToolEmptyState(
            message: AppStrings.equityEmptyStateHands,
            icon: Icons.style_rounded,
          )
        else if (_result != null)
          _ResultCard(result: _result!)
        else
          ToolEmptyState(
            message: AppStrings.toolsBoardMissing(3 - _hhSituation.cardsOf('board').length),
            icon: Icons.style_rounded,
          ),
      ],
    );
  }

  Widget _buildHandVsRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardGroupField(controller: _hvrSituation, groupId: 'hero'),
              const SizedBox(height: SalaVerdeSpace.lg),
              ToolTextField(
                label: AppStrings.equityVillainRangeLabel,
                controller: _hvrVillainRangeController,
                onChanged: () {},
                hintText: AppStrings.equityVillainRangeHint,
              ),
              const SizedBox(height: SalaVerdeSpace.lg),
              CardGroupField(controller: _hvrSituation, groupId: 'board'),
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.md),
        ToolCalculateButton(
          label: AppStrings.equityCalculateButtonLabel,
          loading: _hvrState == _RangeCalcState.loading,
          onTap: _calculateHandVsRange,
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        switch (_hvrState) {
          _RangeCalcState.idle => const ToolEmptyState(message: AppStrings.equityRangeModeHint),
          _RangeCalcState.loading => const SizedBox.shrink(),
          _RangeCalcState.error => ToolErrorCard(message: _hvrError!),
          _RangeCalcState.success => _RangeResultCard(result: _hvrResult!),
        },
      ],
    );
  }

  Widget _buildRangeVsRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToolTextField(
                label: AppStrings.equityHeroRangeLabel,
                controller: _rvrHeroRangeController,
                onChanged: () {},
                hintText: AppStrings.equityHeroRangeHint,
              ),
              const SizedBox(height: SalaVerdeSpace.lg),
              ToolTextField(
                label: AppStrings.equityVillainRangeLabel,
                controller: _rvrVillainRangeController,
                onChanged: () {},
                hintText: AppStrings.equityVillainRangeHint,
              ),
              const SizedBox(height: SalaVerdeSpace.lg),
              CardGroupField(controller: _rvrSituation, groupId: 'board'),
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.md),
        ToolCalculateButton(
          label: AppStrings.equityCalculateButtonLabel,
          loading: _rvrState == _RangeCalcState.loading,
          onTap: _calculateRangeVsRange,
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        switch (_rvrState) {
          _RangeCalcState.idle => const ToolEmptyState(message: AppStrings.equityRangeModeHint),
          _RangeCalcState.loading => const SizedBox.shrink(),
          _RangeCalcState.error => ToolErrorCard(message: _rvrError!),
          _RangeCalcState.success => _RangeResultCard(result: _rvrResult!),
        },
      ],
    );
  }
}

enum _RangeCalcState { idle, loading, error, success }

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final EquityResult result;

  @override
  Widget build(BuildContext context) {
    return ToolCard(
      borderColor: kToolAccent.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolSectionLabel(AppStrings.toolsResultPrincipal, color: kToolAccent),
          const SizedBox(height: SalaVerdeSpace.sm),
          ToolResultStat(
            label: 'Equity',
            value: '${(result.equity * 100).toStringAsFixed(1)}%',
            big: true,
            color: kToolAccent,
          ),
          const SizedBox(height: SalaVerdeSpace.lg),
          const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
          const SizedBox(height: SalaVerdeSpace.md),
          Row(
            children: [
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityWinLabel,
                  value: '${(result.winProbability * 100).toStringAsFixed(1)}%',
                  color: SalaVerdeColors.success,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityTieLabel,
                  value: '${(result.tieProbability * 100).toStringAsFixed(1)}%',
                  color: SalaVerdeColors.warning,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityLoseLabel,
                  value: '${(result.lossProbability * 100).toStringAsFixed(1)}%',
                  color: SalaVerdeColors.errorBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(
            AppStrings.equityExplanation(result.equity * 100),
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          SizedBox(
            width: double.infinity,
            child: SvButtonSecondary(
              label: AppStrings.potOddsCalculateEv,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EvCalculatorScreen(
                  initialEquityPercent: result.equity * 100,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mismo lenguaje visual que [_ResultCard], más el conteo de
/// confrontaciones evaluadas (`result.total`).
class _RangeResultCard extends StatelessWidget {
  const _RangeResultCard({required this.result});

  final EquityResult result;

  @override
  Widget build(BuildContext context) {
    return ToolCard(
      borderColor: kToolAccent.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolSectionLabel(AppStrings.toolsResultPrincipal, color: kToolAccent),
          const SizedBox(height: SalaVerdeSpace.sm),
          ToolResultStat(
            label: 'Equity',
            value: '${(result.equity * 100).toStringAsFixed(1)}%',
            big: true,
            color: kToolAccent,
          ),
          const SizedBox(height: SalaVerdeSpace.lg),
          const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
          const SizedBox(height: SalaVerdeSpace.md),
          Row(
            children: [
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityWinLabel,
                  value: '${(result.winProbability * 100).toStringAsFixed(1)}%',
                  color: SalaVerdeColors.success,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityTieLabel,
                  value: '${(result.tieProbability * 100).toStringAsFixed(1)}%',
                  color: SalaVerdeColors.warning,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityLoseLabel,
                  value: '${(result.lossProbability * 100).toStringAsFixed(1)}%',
                  color: SalaVerdeColors.errorBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          ToolResultStat(
            label: AppStrings.equityScenariosLabel,
            value: '${result.total}',
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(
            AppStrings.equityExplanation(result.equity * 100),
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          SizedBox(
            width: double.infinity,
            child: SvButtonSecondary(
              label: AppStrings.potOddsCalculateEv,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EvCalculatorScreen(
                  initialEquityPercent: result.equity * 100,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
