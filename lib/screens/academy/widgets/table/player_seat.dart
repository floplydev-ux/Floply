import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../engine/pedagogy/table_lesson.dart';
import '../../../../theme/app_colors.dart';
import 'dealer_button.dart';
import 'playing_card.dart';
import 'seat_action_badge.dart';
import 'table_highlight.dart';
import 'table_layout.dart';

/// Color de fondo del avatar — el mismo tono neutro para los 6 asientos,
/// héroe incluido. Nadie "destaca" por asignación arbitraria de color: los
/// 6 paneles tienen que leerse como la misma pieza repetida.
const List<Color> _avatarColors = [Color(0xFF3E5266), Color(0xFF171E28)];

/// Badge de posición (UTG / HJ / CO / BTN / SB / BB) — pequeña etiqueta
/// dentro del panel, nunca compite con nombre/stack.
Color _positionColor(String label) => switch (label) {
      'BTN' => TableMaterial.gold,
      'SB' || 'BB' => AppColors.diamondBlue,
      _ => TableMaterial.textSub,
    };

/// `true` si el asiento tiene sus dos cartas boca arriba (showdown) — para
/// elegir cara/dorso y tamaño de las cartas.
bool _isRevealed(SeatState s) => s.cards.length == 2 && !s.cards.contains('?');

/// Monto a mostrar junto a la acción, en BB — `null` para las acciones
/// que el pedido marca explícitamente sin cantidad (CHECK/FOLD/ALL-IN);
/// para el resto (CALL/BET/RAISE/POST), lo ya invertido esta calle
/// (`seat.betBb`, el mismo dato que ya muestra `BetChip` junto al pozo).
double? _actionAmountBb(String? action, double betBb) => switch (action) {
      'CHECK' || 'FOLD' || 'ALL-IN' || null => null,
      _ => betBb,
    };

/// Color de borde de iluminación temporal por tipo de acción (Fix 8).
///
/// Se apoya en la paleta de la mesa (TableMaterial) con toques mínimos de
/// colores estándar de Flutter — sin dependencias externas. La intensidad
/// del alfa es baja para no competir con el halo de `Highlightable`.
Color _actionBorderColor(String action) => switch (action) {
      'CHECK' => const Color(0xFF4A90D9).withValues(alpha: 0.60), // azul suave
      'CALL' => TableMaterial.success.withValues(alpha: 0.55), // verde suave
      'BET' => TableMaterial.gold.withValues(alpha: 0.70), // ámbar / dorado
      'RAISE' => const Color(0xFFFF8C00).withValues(alpha: 0.65), // naranja
      'ALL-IN' => const Color(0xFFE53935).withValues(alpha: 0.75), // rojo
      'FOLD' => Colors.white.withValues(alpha: 0.06), // casi invisible
      _ => Colors.white.withValues(alpha: 0.08),
    };

/// **El asiento completo: avatar + nombre + posición + stack + estado +
/// sus propias cartas privadas — una sola pieza, un solo componente.**
///
/// Fix 8: cuando un jugador realiza una acción, el borde del panel se
/// ilumina con un color acorde a la acción durante ~1.5s — usando el mismo
/// mecanismo de timer ya presente en `SeatActionBadge` (la "acción nueva"
/// se detecta comparando `seat.action` entre builds consecutivos) — y
/// desaparece solo. El estado visual de la acción (texto en badge) y el
/// estado del borde comparten la misma señal de datos (`seat.action`) pero
/// tienen timers independientes para poder evolucionar por separado.
class PlayerSeat extends StatefulWidget {
  const PlayerSeat({
    super.key,
    required this.seat,
    required this.scale,
    this.panelHighlighted = false,
    this.cardsHighlighted = false,
    this.glow = 1,
    this.cardGlowIndices = const {},
  });

  final SeatState seat;
  final double scale;

  /// Si el panel debe mostrar el halo de resaltado.
  final bool panelHighlighted;

  /// Si las cartas deben mostrar su propio halo de resaltado
  /// (independiente del panel).
  final bool cardsHighlighted;

  /// 0..1, intensidad del pulso del halo (compartido panel/cartas).
  final double glow;

  /// Índices de [seat.cards] a resaltar individualmente (piloto visual).
  final Set<int> cardGlowIndices;

  @override
  State<PlayerSeat> createState() => _PlayerSeatState();
}

class _PlayerSeatState extends State<PlayerSeat> {
  // Duración del highlight de borde por acción — algo más corto que el
  // badge de texto (2.8s) para que el borde desaparezca primero.
  static const _highlightDuration = Duration(milliseconds: 1500);

  String? _lastSeenAction;
  bool _actionHighlighted = false;
  Timer? _highlightTimer;

  /// Cuántos dp asoman las cartas por ENCIMA del panel, en dp antes de
  /// escalar — el único número que hace falta tocar para cambiar esto en
  /// los 6 jugadores a la vez. [_cardsRiseRevealed] es un poco mayor
  /// porque la carta revelada es más grande.
  static const double _cardsRise = 20;
  static const double _cardsRiseRevealed = 26;

  /// Separación entre las dos cartas de la mano — ver [CardRow.gap].
  static const double _cardsGap = -9;

  @override
  void initState() {
    super.initState();
    _lastSeenAction = widget.seat.action;
  }

  @override
  void didUpdateWidget(covariant PlayerSeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    final action = widget.seat.action;
    // Disparar highlight cuando llega una acción nueva (no en el primer
    // build, igual que SeatActionBadge).
    if (action != null && action != _lastSeenAction) {
      _highlightTimer?.cancel();
      setState(() => _actionHighlighted = true);
      _highlightTimer = Timer(_highlightDuration, () {
        if (!mounted) return;
        setState(() => _actionHighlighted = false);
      });
    }
    _lastSeenAction = action;
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seat = widget.seat;
    final isWinner = seat.winner;
    final avatarSize = 25.0 * widget.scale;
    final name = seat.name ?? (seat.isHero ? 'Vos' : seat.label);

    // Fondo del panel: solo dos estados posibles (foldeado / participando).
    final panelBg = seat.folded
        ? const Color(0xFF2C2E33)
        : const Color(0xFF0A0E14);

    // Borde del panel — prioridad: ganador > turno > acción reciente > reposo.
    // El highlight de acción (Fix 8) solo aparece cuando no hay un estado
    // más prioritario visible.
    final Color panelBorder;
    if (seat.folded) {
      panelBorder = Colors.white.withValues(alpha: 0.05);
    } else if (isWinner) {
      panelBorder = TableMaterial.success.withValues(alpha: 0.55);
    } else if (seat.toAct) {
      panelBorder = TableMaterial.focus.withValues(alpha: 0.7);
    } else if (_actionHighlighted && seat.action != null) {
      panelBorder = _actionBorderColor(seat.action!);
    } else {
      panelBorder = Colors.white.withValues(alpha: 0.08);
    }

    final avatar = Container(
      width: avatarSize,
      height: avatarSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: seat.folded
            ? const LinearGradient(
                colors: [Color(0xFF3A3C42), Color(0xFF1E2024)])
            : const LinearGradient(
                colors: _avatarColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: isWinner
              ? TableMaterial.success.withValues(alpha: 0.85)
              : seat.toAct
                  ? TableMaterial.focus
                  : Colors.white.withValues(alpha: 0.14),
          width: (isWinner || seat.toAct) ? 1.8 : 1.1,
        ),
      ),
      child: seat.folded
          ? Icon(Icons.close_rounded,
              size: avatarSize * 0.45, color: TableMaterial.textDim)
          : Icon(
              Icons.person_rounded,
              size: avatarSize * 0.55,
              color: Colors.white.withValues(alpha: 0.88),
            ),
    );

    final nameColor = isWinner
        ? TableMaterial.success
        : seat.folded
            ? TableMaterial.textDim
            : TableMaterial.text;

    final posStackLine = Text.rich(
      TextSpan(
        children: [
          if (seat.label.isNotEmpty)
            TextSpan(
              text: '${seat.label} ',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: _positionColor(seat.label),
              ),
            ),
          TextSpan(
            text: '${formatBb(seat.stackBb)} BB',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: TableMaterial.textSub,
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 8.5 * widget.scale),
    );

    final panelChrome = Container(
      constraints: BoxConstraints(maxWidth: 128 * widget.scale),
      padding: EdgeInsets.symmetric(
          horizontal: 7 * widget.scale, vertical: 5 * widget.scale),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: panelBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          SizedBox(width: 6 * widget.scale),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10 * widget.scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                    color: nameColor,
                  ),
                ),
                SizedBox(height: 1 * widget.scale),
                SeatActionBadge(
                  action: seat.action,
                  amountBb: _actionAmountBb(seat.action, seat.betBb),
                  stackLine: posStackLine,
                  scale: widget.scale,
                ),
              ],
            ),
          ),
          if (isWinner) ...[
            SizedBox(width: 4 * widget.scale),
            WinnerMark(scale: widget.scale),
          ],
        ],
      ),
    );

    final panel = Highlightable(
      active: widget.panelHighlighted,
      glow: widget.glow,
      radius: 12,
      color: isWinner ? TableMaterial.success : TableMaterial.focus,
      child: panelChrome,
    );

    if (seat.cards.isEmpty || seat.folded) return panel;

    final revealed = _isRevealed(seat);
    final rise = (revealed ? _cardsRiseRevealed : _cardsRise) * widget.scale;
    final cards = Positioned.fill(
      child: Align(
        alignment: Alignment.topCenter,
        child: Transform.translate(
          offset: Offset(0, -rise),
          child: Highlightable(
            active: widget.cardsHighlighted,
            glow: widget.glow,
            radius: 10,
            color: TableMaterial.focus,
            child: KeyedSubtree(
              key: seat.isHero ? kAcademyTableHeroCardsKey : null,
              child: CardRow(
                codes: seat.cards,
                small: !revealed,
                hero: seat.isHero,
                scale: widget.scale,
                gap: _cardsGap,
                glowIndices: widget.cardGlowIndices,
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        cards,
        panel,
      ],
    );
  }
}
