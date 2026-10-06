import 'package:flutter/material.dart';

import '../../../engine/poker/poker_action.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// Barra de acciones del héroe sobre la mesa jugable (Grupo 8, sección
/// 4): solo muestra las acciones legales de [legalActions] — nunca una
/// lista fija — y, si BET/RAISE es legal, un slider real para elegir el
/// tamaño entre [minBb] y [maxBb], con atajos de tamaño típicos
/// (mínimo, mitad de bote, bote, all-in).
class CoachActionBar extends StatefulWidget {
  const CoachActionBar({
    super.key,
    required this.legalActions,
    required this.minBb,
    required this.maxBb,
    required this.potBb,
    required this.onChoose,
  });

  final Set<ActionType> legalActions;

  /// Rango legal para BET/RAISE — `null` si ninguno de los dos es legal.
  final double? minBb;
  final double? maxBb;

  final double potBb;

  final ValueChanged<PokerAction> onChoose;

  @override
  State<CoachActionBar> createState() => _CoachActionBarState();
}

class _CoachActionBarState extends State<CoachActionBar> {
  double? _sizeBb;
  bool _sizing = false;

  ActionType get _aggressiveType => widget.legalActions.contains(ActionType.raise)
      ? ActionType.raise
      : ActionType.bet;

  @override
  void didUpdateWidget(covariant CoachActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Una situación nueva (otra calle, otra decisión) siempre arranca sin
    // el paso de tamaño abierto — nunca arrastra el slider de la
    // decisión anterior.
    if (oldWidget.minBb != widget.minBb || oldWidget.maxBb != widget.maxBb) {
      _sizing = false;
      _sizeBb = null;
    }
  }

  void _openSizing() {
    setState(() {
      _sizing = true;
      _sizeBb = widget.minBb;
    });
  }

  void _confirmSize() {
    if (_sizeBb == null) return;
    widget.onChoose(_aggressiveType == ActionType.raise
        ? PokerAction.raiseTo(_sizeBb!)
        : PokerAction.bet(_sizeBb!));
  }

  @override
  Widget build(BuildContext context) {
    if (_sizing && widget.minBb != null && widget.maxBb != null) {
      return _SizingPanel(
        minBb: widget.minBb!,
        maxBb: widget.maxBb!,
        potBb: widget.potBb,
        value: _sizeBb ?? widget.minBb!,
        onChanged: (v) => setState(() => _sizeBb = v),
        onCancel: () => setState(() => _sizing = false),
        onConfirm: _confirmSize,
      );
    }

    final buttons = <_ActionSpec>[
      if (widget.legalActions.contains(ActionType.fold))
        _ActionSpec('FOLD', () => widget.onChoose(PokerAction.fold), _Tone.fold),
      if (widget.legalActions.contains(ActionType.check))
        _ActionSpec(
            'CHECK', () => widget.onChoose(PokerAction.check), _Tone.passive),
      if (widget.legalActions.contains(ActionType.call))
        _ActionSpec(
            'CALL', () => widget.onChoose(const PokerAction(ActionType.call)), _Tone.passive),
      if (widget.legalActions.contains(ActionType.bet))
        _ActionSpec('BET', _openSizing, _Tone.aggressive),
      if (widget.legalActions.contains(ActionType.raise))
        _ActionSpec('RAISE', _openSizing, _Tone.aggressive),
      if (widget.legalActions.contains(ActionType.allIn))
        _ActionSpec(
            'ALL-IN', () => widget.onChoose(const PokerAction(ActionType.allIn)), _Tone.aggressive),
    ];

    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _ActionButton(spec: buttons[i])),
        ],
      ],
    );
  }
}

enum _Tone { fold, passive, aggressive }

class _ActionSpec {
  const _ActionSpec(this.label, this.onTap, this.tone);
  final String label;
  final VoidCallback onTap;
  final _Tone tone;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.spec});

  final _ActionSpec spec;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, border, filled) = switch (spec.tone) {
      _Tone.fold => (
          SalaVerdeColors.errorBright,
          SalaVerdeColors.error.withValues(alpha: 0.08),
          SalaVerdeColors.errorBright.withValues(alpha: 0.45),
          false,
        ),
      _Tone.passive => (
          SalaVerdeColors.textSecondary,
          SalaVerdeColors.surfaceElevated,
          SalaVerdeColors.borderSubtle,
          false,
        ),
      _Tone.aggressive => (
          SalaVerdeColors.textPrimary,
          SalaVerdeColors.feltGreen,
          Colors.transparent,
          true,
        ),
    };

    return PressableScale(
      onTap: spec.onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: bg,
          border: Border.all(color: border, width: 1.4),
          boxShadow: filled
              ? [BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 5))]
              : null,
        ),
        child: Text(
          spec.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
            letterSpacing: 0.4,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _SizingPanel extends StatelessWidget {
  const _SizingPanel({
    required this.minBb,
    required this.maxBb,
    required this.potBb,
    required this.value,
    required this.onChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  final double minBb;
  final double maxBb;
  final double potBb;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  static String _fmt(double bb) =>
      bb == bb.roundToDouble() ? bb.toStringAsFixed(0) : bb.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final canSlide = maxBb > minBb;
    final presets = <(String, double)>[
      ('MIN', minBb),
      if (potBb > 0) ('1/2 POTE', (potBb * 0.5).clamp(minBb, maxBb)),
      if (potBb > 0) ('POTE', potBb.clamp(minBb, maxBb)),
      ('ALL-IN', maxBb),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_fmt(value)} BB',
          style: SalaVerdeType.title(),
        ),
        if (canSlide)
          Slider(
            value: value.clamp(minBb, maxBb),
            min: minBb,
            max: maxBb,
            activeColor: SalaVerdeColors.feltGreenBright,
            onChanged: onChanged,
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final (label, bb) in presets)
              PressableScale(
                onTap: () => onChanged(bb),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
                    color: SalaVerdeColors.surfaceElevated,
                    border: Border.all(color: SalaVerdeColors.borderSubtle),
                  ),
                  child: Text(label,
                      style: SalaVerdeType.bodyStrong().copyWith(fontSize: 12)),
                ),
              ),
          ],
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        Row(
          children: [
            Expanded(
              child: SvButtonSecondary(label: 'CANCELAR', onTap: onCancel),
            ),
            const SizedBox(width: SalaVerdeSpace.sm),
            Expanded(
              flex: 2,
              child: SvButtonPrimary(label: 'CONFIRMAR', onTap: onConfirm),
            ),
          ],
        ),
      ],
    );
  }
}
