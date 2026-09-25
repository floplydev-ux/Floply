import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart' hide Card;

import '../../engine/poker/card.dart';
import '../../engine/poker/equity/equity_engine.dart';
import '../../engine/poker/equity/equity_result.dart';
import '../../engine/poker/hole_cards.dart';
import '../../engine/strategy/hand_range.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import 'widgets/tool_widgets.dart';

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
/// **Entrada por notación de texto** (`AhKd`, rangos como `77+,ATs+`):
/// misma notación que ya usa todo el motor — ver el doc-comment de
/// [HandRange.parse] para la mini-sintaxis de rangos. Un picker visual
/// de cartas/rangos es una pieza de UI bastante más grande, que queda
/// para un bloque aparte si hace falta.
///
/// **Por qué mano vs rango y rango vs rango no recalculan en vivo**
/// (a diferencia de mano vs mano): el propio doc-comment de
/// [EquityEngine.rangeVsRange] advierte que es el caso más pesado del
/// motor (`heroCombos × villainCombos × runouts` — hasta millones de
/// evaluaciones de mano de 7 cartas incluso con rangos chicos como
/// "AA,KK" vs "QQ,JJ") y pide explícitamente no correrlo en el camino
/// de un `build()`, sino fuera del isolate de UI. Estos dos modos
/// calculan solo al tocar "Calcular equity" (nunca en cada tecla) y la
/// llamada al motor corre con [compute] en un isolate aparte, así que
/// el hilo de UI nunca se bloquea — la animación de carga sigue
/// corriendo mientras el cálculo pesado pasa en paralelo.
class EquityCalculatorScreen extends StatefulWidget {
  const EquityCalculatorScreen({super.key});

  @override
  State<EquityCalculatorScreen> createState() => _EquityCalculatorScreenState();
}

class _EquityCalculatorScreenState extends State<EquityCalculatorScreen> {
  _EquityMode _mode = _EquityMode.handVsHand;

  // Modo 1: mano vs mano (V1, recalcula en vivo).
  final _heroController = TextEditingController(text: 'AhKd');
  final _villainController = TextEditingController(text: 'AsQd');
  final _boardController = TextEditingController(text: '2c7d9h');
  EquityResult? _result;
  bool _invalid = false;

  // Modo 2: mano vs rango (V2, botón "Calcular").
  final _hvrHeroController = TextEditingController(text: 'AhKd');
  final _hvrVillainRangeController = TextEditingController(text: 'QQ+,AKs,AKo');
  final _hvrBoardController = TextEditingController(text: '2c7d9h');
  _RangeCalcState _hvrState = _RangeCalcState.idle;
  EquityResult? _hvrResult;
  String? _hvrError;

  // Modo 3: rango vs rango (V2, botón "Calcular").
  final _rvrHeroRangeController = TextEditingController(text: 'AA,KK');
  final _rvrVillainRangeController = TextEditingController(text: 'QQ,JJ');
  final _rvrBoardController = TextEditingController(text: '2c7d9h');
  _RangeCalcState _rvrState = _RangeCalcState.idle;
  EquityResult? _rvrResult;
  String? _rvrError;

  @override
  void initState() {
    super.initState();
    _recalculateHandVsHand();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _villainController.dispose();
    _boardController.dispose();
    _hvrHeroController.dispose();
    _hvrVillainRangeController.dispose();
    _hvrBoardController.dispose();
    _rvrHeroRangeController.dispose();
    _rvrVillainRangeController.dispose();
    _rvrBoardController.dispose();
    super.dispose();
  }

  static HoleCards? _tryParseHand(String text) {
    try {
      return HoleCards.parse(text.trim().replaceAll(' ', ''));
    } catch (_) {
      return null;
    }
  }

  static List<Card>? _tryParseBoard(String text) {
    final clean = text.trim().replaceAll(' ', '');
    if (clean.length != 6 && clean.length != 8 && clean.length != 10) return null;
    try {
      return [
        for (var i = 0; i < clean.length; i += 2) Card.parse(clean.substring(i, i + 2)),
      ];
    } catch (_) {
      return null;
    }
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
    final hero = _tryParseHand(_heroController.text);
    final villain = _tryParseHand(_villainController.text);
    final board = _tryParseBoard(_boardController.text);
    if (hero == null || villain == null || board == null) {
      setState(() {
        _result = null;
        _invalid = true;
      });
      return;
    }
    try {
      final result = EquityEngine.handVsHand(hero, villain, board);
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

  Future<void> _calculateHandVsRange() async {
    final hero = _tryParseHand(_hvrHeroController.text);
    final board = _tryParseBoard(_hvrBoardController.text);
    if (hero == null || board == null) {
      setState(() {
        _hvrState = _RangeCalcState.error;
        _hvrError = AppStrings.equityInvalidInput;
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
    try {
      final result = await compute(
        _handVsRangeInIsolate,
        _HandVsRangeRequest(hero, villainRange, board),
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
    final board = _tryParseBoard(_rvrBoardController.text);
    if (board == null) {
      setState(() {
        _rvrState = _RangeCalcState.error;
        _rvrError = AppStrings.equityInvalidInput;
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
                    icon: Icons.pie_chart_rounded,
                    accentColor: AppColors.violetPrimary,
                    title: AppStrings.toolsEquityTitle,
                    subtitle: AppStrings.toolsEquityCalculatorSubtitle,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 20),
                  _ModeSelector(
                    mode: _mode,
                    onSelected: (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildHandVsHand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToolTextField(
                label: AppStrings.equityHeroLabel,
                controller: _heroController,
                onChanged: _recalculateHandVsHand,
                hintText: AppStrings.equityHeroHint,
                accentColor: AppColors.violetPrimary,
              ),
              const SizedBox(height: 14),
              ToolTextField(
                label: AppStrings.equityVillainLabel,
                controller: _villainController,
                onChanged: _recalculateHandVsHand,
                hintText: AppStrings.equityVillainHint,
                accentColor: AppColors.violetPrimary,
              ),
              const SizedBox(height: 14),
              ToolTextField(
                label: AppStrings.equityBoardLabel,
                controller: _boardController,
                onChanged: _recalculateHandVsHand,
                hintText: AppStrings.equityBoardHint,
                accentColor: AppColors.violetPrimary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_invalid)
          const ToolErrorCard(message: AppStrings.equityInvalidInput)
        else if (_result != null)
          _ResultCard(result: _result!),
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
              ToolTextField(
                label: AppStrings.equityHeroLabel,
                controller: _hvrHeroController,
                onChanged: () {},
                hintText: AppStrings.equityHeroHint,
                accentColor: AppColors.violetPrimary,
              ),
              const SizedBox(height: 14),
              ToolTextField(
                label: AppStrings.equityVillainRangeLabel,
                controller: _hvrVillainRangeController,
                onChanged: () {},
                hintText: AppStrings.equityVillainRangeHint,
                accentColor: AppColors.violetPrimary,
              ),
              const SizedBox(height: 14),
              ToolTextField(
                label: AppStrings.equityBoardLabel,
                controller: _hvrBoardController,
                onChanged: () {},
                hintText: AppStrings.equityBoardHint,
                accentColor: AppColors.violetPrimary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _CalculateButton(
          loading: _hvrState == _RangeCalcState.loading,
          onTap: _calculateHandVsRange,
        ),
        const SizedBox(height: 16),
        switch (_hvrState) {
          _RangeCalcState.idle =>
            const Text(AppStrings.equityRangeModeHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
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
                accentColor: AppColors.violetPrimary,
              ),
              const SizedBox(height: 14),
              ToolTextField(
                label: AppStrings.equityVillainRangeLabel,
                controller: _rvrVillainRangeController,
                onChanged: () {},
                hintText: AppStrings.equityVillainRangeHint,
                accentColor: AppColors.violetPrimary,
              ),
              const SizedBox(height: 14),
              ToolTextField(
                label: AppStrings.equityBoardLabel,
                controller: _rvrBoardController,
                onChanged: () {},
                hintText: AppStrings.equityBoardHint,
                accentColor: AppColors.violetPrimary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _CalculateButton(
          loading: _rvrState == _RangeCalcState.loading,
          onTap: _calculateRangeVsRange,
        ),
        const SizedBox(height: 16),
        switch (_rvrState) {
          _RangeCalcState.idle =>
            const Text(AppStrings.equityRangeModeHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          _RangeCalcState.loading => const SizedBox.shrink(),
          _RangeCalcState.error => ToolErrorCard(message: _rvrError!),
          _RangeCalcState.success => _RangeResultCard(result: _rvrResult!),
        },
      ],
    );
  }
}

enum _RangeCalcState { idle, loading, error, success }

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onSelected});

  final _EquityMode mode;
  final ValueChanged<_EquityMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ModeChip(
          label: AppStrings.equityModeHandVsHandLabel,
          active: mode == _EquityMode.handVsHand,
          onTap: () => onSelected(_EquityMode.handVsHand),
        ),
        _ModeChip(
          label: AppStrings.equityModeHandVsRangeLabel,
          active: mode == _EquityMode.handVsRange,
          onTap: () => onSelected(_EquityMode.handVsRange),
        ),
        _ModeChip(
          label: AppStrings.equityModeRangeVsRangeLabel,
          active: mode == _EquityMode.rangeVsRange,
          onTap: () => onSelected(_EquityMode.rangeVsRange),
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
              ? AppColors.violetPrimary.withValues(alpha: 0.18)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: active ? AppColors.violetPrimary : AppColors.surfaceBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: active ? AppColors.violetBright : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CalculateButton extends StatelessWidget {
  const _CalculateButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: loading ? () {} : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.violetPrimary.withValues(alpha: loading ? 0.4 : 1),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(AppColors.background),
                ),
              )
            : const Text(
                AppStrings.equityCalculateButtonLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.background,
                ),
              ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final EquityResult result;

  @override
  Widget build(BuildContext context) {
    return ToolCard(
      gradientColors: const [Color(0xFF2A1B45), Color(0xFF1B122E)],
      borderColor: AppColors.violetPrimary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolResultStat(
            label: 'EQUITY',
            value: '${(result.equity * 100).toStringAsFixed(1)}%',
            big: true,
            color: AppColors.violetBright,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityWinLabel,
                  value: '${(result.winProbability * 100).toStringAsFixed(1)}%',
                  color: AppColors.neonGreen,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityTieLabel,
                  value: '${(result.tieProbability * 100).toStringAsFixed(1)}%',
                  color: AppColors.gold,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityLoseLabel,
                  value: '${(result.lossProbability * 100).toStringAsFixed(1)}%',
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.equityExplanation(result.equity * 100),
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

/// Mismo lenguaje visual que [_ResultCard], más el conteo de
/// confrontaciones evaluadas (`result.total`) — relevante en mano vs
/// rango y rango vs rango porque ese número varía según cuántos combos
/// dejó vivos el card removal, algo que en mano vs mano es siempre
/// obvio a partir del board.
class _RangeResultCard extends StatelessWidget {
  const _RangeResultCard({required this.result});

  final EquityResult result;

  @override
  Widget build(BuildContext context) {
    return ToolCard(
      gradientColors: const [Color(0xFF2A1B45), Color(0xFF1B122E)],
      borderColor: AppColors.violetPrimary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolResultStat(
            label: 'EQUITY',
            value: '${(result.equity * 100).toStringAsFixed(1)}%',
            big: true,
            color: AppColors.violetBright,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityWinLabel,
                  value: '${(result.winProbability * 100).toStringAsFixed(1)}%',
                  color: AppColors.neonGreen,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityTieLabel,
                  value: '${(result.tieProbability * 100).toStringAsFixed(1)}%',
                  color: AppColors.gold,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.equityLoseLabel,
                  value: '${(result.lossProbability * 100).toStringAsFixed(1)}%',
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ToolResultStat(
            label: AppStrings.equityScenariosLabel,
            value: '${result.total}',
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.equityExplanation(result.equity * 100),
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
