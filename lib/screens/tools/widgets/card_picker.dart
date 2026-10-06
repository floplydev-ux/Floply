import 'package:flutter/material.dart' hide Card;

import '../../../engine/poker/card.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../theme/sala_verde/sala_verde_typography.dart';

/// Piezas visuales de bajo nivel para la selección de cartas en Tools —
/// reutilizadas por el selector universal ([CardGroupField] en
/// `card_situation.dart`), que es quien arma la UI completa de un grupo
/// de cartas (Hero/Rival/Board/cartas muertas…). Este archivo no expone
/// ningún picker "por herramienta": solo el contorno vacío
/// ([DottedCardOutline]) y el panel de selección en sí ([pickCard],
/// grilla de 52).

/// Contorno punteado del tamaño exacto de una carta física (misma
/// proporción que `PlayingCard`, nunca un rectángulo genérico) — el
/// "todavía falta elegir" visual, para que llenarlo se sienta como
/// completar la misma pieza, no como reemplazar un ícono por otro.
class DottedCardOutline extends StatelessWidget {
  const DottedCardOutline({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _DashedBorderPainter(radius: size.width * 0.16),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Icon(
          Icons.add_rounded,
          color: SalaVerdeColors.textMuted,
          size: size.width * 0.5,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = SalaVerdeColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const dashLength = 4.0, gapLength = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

/// Abre el panel de selección (grilla de 52, 13 filas por rango × 4
/// columnas por palo) y devuelve la carta elegida, o `null` si se
/// canceló. Tocar una carta disponible la confirma y cierra el panel en
/// el mismo gesto — no hace falta un botón "Confirmar" aparte: elegir ES
/// confirmar, como en una mesa real.
Future<Card?> pickCard(
  BuildContext context, {
  required Set<Card> excluded,
  Card? current,
}) {
  return showModalBottomSheet<Card>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _CardPickerSheet(excluded: excluded, current: current),
  );
}

class _CardPickerSheet extends StatelessWidget {
  const _CardPickerSheet({required this.excluded, this.current});

  final Set<Card> excluded;
  final Card? current;

  @override
  Widget build(BuildContext context) {
    // Alto acotado (no `mainAxisSize.min`): con las 13 filas por rango de
    // _CardGrid, el contenido intrínseco supera la altura de teléfonos
    // chicos — el handle/título quedan siempre visibles arriba y la
    // grilla sola scrollea, en vez de desbordar la pantalla.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: SalaVerdeColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(SalaVerdeRadius.sheet)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SalaVerdeSpace.lg,
                  SalaVerdeSpace.lg,
                  SalaVerdeSpace.lg,
                  0,
                ),
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
                    Text(AppStrings.toolsCardPickerTitle, style: SalaVerdeType.title()),
                    const SizedBox(height: SalaVerdeSpace.md),
                    const _SuitHeaderRow(),
                    const SizedBox(height: SalaVerdeSpace.xs),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    SalaVerdeSpace.lg,
                    0,
                    SalaVerdeSpace.lg,
                    SalaVerdeSpace.xl,
                  ),
                  child: _CardGrid(excluded: excluded, current: current),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Los 4 palos como encabezado de columna — puramente informativo (ayuda a
/// leer la grilla de un vistazo), alineado con las 4 columnas de
/// [_CardGrid] de abajo.
class _SuitHeaderRow extends StatelessWidget {
  const _SuitHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final suit in _CardGrid._suitOrder)
          Expanded(
            child: Center(
              child: Text(
                suit.symbol,
                style: TextStyle(
                  fontSize: 15,
                  color: (suit == Suit.hearts || suit == Suit.diamonds)
                      ? const Color(0xFFC0453D)
                      : SalaVerdeColors.textMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Grilla de 52 cartas — **13 filas por rango × 4 columnas por palo**
/// (no al revés): con 4 columnas cada celda tiene ancho de sobra para un
/// target táctil cómodo (`Table` estirado 13 columnas angostas era
/// ilegible/difícil de tocar en un teléfono real, ~21dp por celda). Ranks
/// de A a 2, de arriba hacia abajo — el orden en que se piensa una mano.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.excluded, this.current});

  final Set<Card> excluded;
  final Card? current;

  static const _suitOrder = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final rank in Rank.highToLow)
          TableRow(
            children: [
              for (final suit in _suitOrder)
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: _CardCell(
                    card: Card(rank, suit),
                    disabled: excluded.contains(Card(rank, suit)),
                    isCurrent: current == Card(rank, suit),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _CardCell extends StatelessWidget {
  const _CardCell({
    required this.card,
    required this.disabled,
    required this.isCurrent,
  });

  final Card card;
  final bool disabled;
  final bool isCurrent;

  bool get _red => card.suit == Suit.hearts || card.suit == Suit.diamonds;

  @override
  Widget build(BuildContext context) {
    final color = _red ? const Color(0xFFC0453D) : SalaVerdeColors.textPrimary;
    // Alto fijo (no derivado del ancho): 46dp cumple el mínimo de target
    // táctil (44dp) sin importar cuántas columnas quepan por pantalla.
    final cell = Container(
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: disabled ? SalaVerdeColors.background : SalaVerdeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        border: Border.all(
          color: isCurrent ? SalaVerdeColors.brassBright : SalaVerdeColors.borderSubtle,
          width: isCurrent ? 1.6 : 1,
        ),
      ),
      child: Opacity(
        opacity: disabled ? 0.28 : 1,
        child: Text(
          '${card.rank.letter}${card.suit.symbol}',
          style: SvMonoStyles.pokerValue.copyWith(
            fontSize: 15,
            color: color,
          ),
        ),
      ),
    );

    if (disabled) return cell;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(card),
      child: cell,
    );
  }
}
