import 'dart:async';

import 'package:flutter/material.dart';

import 'table_layout.dart';

/// Reemplazo temporal del stack por la acción recién confirmada — vive
/// DENTRO del mismo espacio donde normalmente se lee el stack de un
/// asiento (nunca un tooltip/popup aparte). Funciona igual para los 6
/// asientos: no sabe de posición, de héroe ni de bot — solo de la acción
/// (ya en la nomenclatura de FLOPly: `CHECK`/`FOLD`/`CALL`/`BET`/`RAISE`/
/// `ALL-IN`/`POST`, la misma que ya arma `CoachTableSnapshot`/
/// `ExerciseScenarioAdapter`) y su monto opcional en BB.
///
/// Se dispara solo: compara la acción nueva contra la última que ya vio
/// (`didUpdateWidget`), nunca en el primer build — así una mesa que
/// arranca con las ciegas ya puestas no "revive" esa acción vieja al
/// montar. Si llega una acción distinta mientras la anterior todavía se
/// está mostrando, reinicia el timer de inmediato con la nueva (sección
/// "DURACIÓN" del pedido).
///
/// No reemplaza ningún estado permanente: el fold ya se lee en el avatar
/// (desaturado + ✕) y el color del panel, ninguno de los dos depende de
/// este widget ni de su timer — acá solo se anima el texto que hoy ocupa
/// `posStackLine`.
class SeatActionBadge extends StatefulWidget {
  const SeatActionBadge({
    super.key,
    required this.action,
    required this.amountBb,
    required this.stackLine,
    required this.scale,
  });

  /// Ya en la nomenclatura de FLOPly. `null` = sin acción registrada en
  /// la calle actual.
  final String? action;

  /// Monto a mostrar debajo de la acción, en BB — `null` para acciones
  /// sin monto (CHECK/FOLD/ALL-IN, sección "JERARQUÍA" del pedido).
  final double? amountBb;

  /// El contenido normal (posición + stack) que se muestra en reposo y
  /// al volver — el mismo `Text.rich` de siempre, sin cambios.
  final Widget stackLine;

  final double scale;

  @override
  State<SeatActionBadge> createState() => _SeatActionBadgeState();
}

class _SeatActionBadgeState extends State<SeatActionBadge> {
  // "2.5-3s" pedido — el punto medio, ni al límite corto ni al largo.
  static const _displayDuration = Duration(milliseconds: 2800);
  // Transición deliberadamente corta y discreta (fade/scale sutil, nunca
  // llamativa) — el pedido explícitamente pide evitar animaciones rápidas
  // "que llamen la atención" en el sentido de flashy, no en el de lentas.
  static const _transitionDuration = Duration(milliseconds: 220);

  String? _lastSeenAction;
  String? _shownAction;
  double? _shownAmount;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lastSeenAction = widget.action;
  }

  @override
  void didUpdateWidget(covariant SeatActionBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final action = widget.action;
    if (action != null && action != _lastSeenAction) {
      _timer?.cancel();
      setState(() {
        _shownAction = action;
        _shownAmount = widget.amountBb;
      });
      _timer = Timer(_displayDuration, () {
        if (!mounted) return;
        setState(() => _shownAction = null);
      });
    }
    _lastSeenAction = action;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Sutil, no semáforo (sección "COLORES" del pedido): RAISE/ALL-IN
  /// reutilizan el dorado de foco que la mesa ya usa para "es tu turno",
  /// BET el verde ya usado para ganador, FOLD el mismo gris atenuado del
  /// nombre foldeado — ningún color nuevo entra a la paleta de la mesa.
  Color _accentFor(String action) => switch (action) {
        'RAISE' || 'ALL-IN' => TableMaterial.focus,
        'BET' => TableMaterial.success,
        'FOLD' => TableMaterial.textDim,
        _ => TableMaterial.text,
      };

  @override
  Widget build(BuildContext context) {
    final shown = _shownAction;
    final child = shown == null
        ? KeyedSubtree(key: const ValueKey('stack'), child: widget.stackLine)
        : _ActionBlock(
            key: ValueKey('action-$shown-${_shownAmount ?? ''}'),
            action: shown,
            amountBb: _shownAmount,
            color: _accentFor(shown),
            scale: widget.scale,
          );

    return AnimatedSwitcher(
      duration: _transitionDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// El bloque de dos líneas (acción + monto) o una sola línea (acciones
/// sin monto) — ver ejemplos de la sección "JERARQUÍA" del pedido.
class _ActionBlock extends StatelessWidget {
  const _ActionBlock({
    super.key,
    required this.action,
    required this.amountBb,
    required this.color,
    required this.scale,
  });

  final String action;
  final double? amountBb;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      action,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 9.5 * scale,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: color,
      ),
    );
    final amount = amountBb;
    if (amount == null) return label;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        Text(
          '${formatBb(amount)} BB',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 8.5 * scale,
            fontWeight: FontWeight.w600,
            color: TableMaterial.textSub,
            fontFeatures: tabularFigures,
          ),
        ),
      ],
    );
  }
}
