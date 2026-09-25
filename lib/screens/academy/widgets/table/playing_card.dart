import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../engine/poker/card.dart' as poker;
import 'table_layout.dart';

/// Proporción física real de una carta de póker (2.5 × 3.5 pulgadas).
/// Todo el tamaño de una carta sale de una sola altura por familia — el
/// ancho se DERIVA de acá, nunca se fija por separado — así ninguna carta
/// puede terminar deformada en un rectángulo genérico, sea cual sea el
/// tamaño final.
const double cardAspect = 2.5 / 3.5;

/// Tamaño de referencia (antes de escalar) de una carta según su familia —
/// compartido por [PlayingCard] (tamaño real) y [CardRow] (para calcular
/// cuánto se solapan dos cartas consecutivas): si un día cambia el tamaño
/// de una familia, las dos quedan de acuerdo solas.
Size cardBaseSize({required bool hero, required bool small}) {
  final h = hero ? 34.0 : (small ? 30.0 : 36.0);
  return Size(h * cardAspect, h);
}

/// Una fila de cartas (mano privada o board) — mismo componente para los 6
/// asientos y el board, con `gap` decidiendo si se superponen (mano) o se
/// separan (board).
class CardRow extends StatelessWidget {
  const CardRow({
    super.key,
    required this.codes,
    this.small = false,
    this.hero = false,
    this.scale = 1,
    this.gap = 3,
    this.glowIndices = const {},
  });

  final List<String> codes;
  final bool small;
  final bool hero;
  final double scale;

  /// Distancia (dp) entre el borde izquierdo de una carta y el de la
  /// siguiente. Positivo = separadas (board); **negativo = superpuestas**
  /// (mano de héroe/rival, como en una mesa real: la de atrás queda tapada
  /// en parte por la de encima).
  final double gap;

  /// Índices (dentro de [codes]) que deben resaltarse individualmente.
  final Set<int> glowIndices;

  @override
  Widget build(BuildContext context) {
    final base = cardBaseSize(hero: hero, small: small);
    final cardW = base.width * scale, cardH = base.height * scale;
    // "step" en vez de un Row+Padding: con gap negativo, Padding no arma
    // una superposición predecible, así que posicionamos cada carta a
    // mano en un Stack — mismo resultado que antes cuando gap es positivo
    // (ver la nota en el taller, misma fórmula de los dos lados).
    final step = cardW + gap * scale;
    final totalW = codes.isEmpty ? 0.0 : cardW + step * (codes.length - 1);
    // Sin Opacity acá: una carta que se muestra siempre se muestra
    // completamente sólida — el caso "no mostrar" (jugador foldeado) se
    // resuelve más arriba, en PlayerSeat, no construyendo este widget.
    return SizedBox(
      width: totalW,
      height: cardH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < codes.length; i++)
            Positioned(
              left: i * step,
              // Entra con un pop breve (escala + fade) cada vez que ESTA
              // carta puntual aparece o cambia de cara.
              child: CardEntrance(
                key: ValueKey('card_${i}_${codes[i]}'),
                delay: Duration(milliseconds: 55 * i),
                child: PlayingCard(
                  code: codes[i],
                  small: small,
                  hero: hero,
                  scale: scale,
                  glow: glowIndices.contains(i),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Entrada breve (escala + fade) para una carta que recién aparece o se da
/// vuelta.
class CardEntrance extends StatelessWidget {
  const CardEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  static const _moveDuration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final total = _moveDuration + delay;
    final beginFraction =
        (delay.inMilliseconds / total.inMilliseconds).clamp(0.0, 0.85);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(beginFraction, 1, curve: Curves.easeOutBack),
      builder: (context, t, c) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child:
            Transform.scale(scale: 0.75 + 0.25 * t.clamp(0.0, 1.0), child: c),
      ),
      child: child,
    );
  }
}

/// Carta jugable: cara con índice + palo central protagonista; dorso con
/// reticulado — "sienten" cartas físicas, no rectángulos lisos. Un solo
/// componente para las 6 mesas, boca arriba o boca abajo.
class PlayingCard extends StatelessWidget {
  const PlayingCard({
    super.key,
    required this.code,
    required this.small,
    this.hero = false,
    this.scale = 1,
    this.glow = false,
  });

  final String code;
  final bool small;
  final bool hero;
  final double scale;

  /// Resaltado individual de esta carta (piloto visual): anillo + brillo
  /// propio, independiente del resaltado de zona.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final faceDown = code == '?' || code.length != 2;

    // Mano del héroe más chica (×0.76, afinado a mano): ya no es la más
    // grande de la mesa — ahora vive al costado, no arriba de todo.
    final base = cardBaseSize(hero: hero, small: small);
    final double baseW = base.width, baseH = base.height;
    final w = (faceDown ? baseW * 0.86 : baseW) * scale;
    final h = (faceDown ? baseH * 0.92 : baseH) * scale;
    final radius = w * 0.16;

    if (faceDown) {
      return Container(
        width: w,
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          // Borde oscuro con un dejo verde — a tono con el dorso (antes
          // era azulado, herencia del dorso azul que ya no existe).
          border: Border.all(color: const Color(0xFF0A2318), width: 1),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 5, offset: Offset(0, 2)),
          ],
        ),
        child: CustomPaint(
          painter: const CardBackPainter(),
          size: Size(w, h),
        ),
      );
    }

    final card = poker.Card.parse(code);
    final red =
        card.suit == poker.Suit.hearts || card.suit == poker.Suit.diamonds;
    final color = red ? TableMaterial.cardRed : TableMaterial.cardBlack;
    // Carta física real: un único índice (valor + palo chico, del mismo
    // tamaño visual) arriba a la izquierda, y el palo grande al centro
    // como protagonista — nada de marco decorativo, nada de pips
    // repetidos, un solo componente para las 6 mesas.
    //
    // El índice y el palo central viven en dos CARRILES de un Column, no
    // en coordenadas sueltas: indexZoneHeight reserva una franja arriba
    // (todo lo que necesita el índice, con margen) y el palo central se
    // ubica en el resto (Expanded), que un Column por definición nunca
    // solapa con la franja de arriba — no importa el rank (A, K, Q, J o
    // T) ni el tamaño final de la carta, la separación queda garantizada
    // por construcción, no por una distancia calculada a mano.
    final indexFontSize = w * 0.28;
    final suitFontSize = w * 0.58;
    // Margen real, no ajustado: rank+suit del índice miden ~0.41h de
    // alto (2.05 × indexFontSize) + el padding superior — 0.50h deja un
    // ~12% de aire de sobra para que no overflow por redondeo en ningún
    // tamaño de pantalla.
    final indexZoneHeight = h * 0.50;

    return Container(
      width: w,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Blanco/marfil sin degradé llamativo — una carta física, no una
        // "UI card": el gradiente es apenas perceptible (misma paleta que
        // antes, ya era sutil).
        gradient: const LinearGradient(
          colors: [TableMaterial.cardFaceTop, TableMaterial.cardFaceBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: glow
              ? TableMaterial.goldBright
              : Colors.black.withValues(alpha: 0.18),
          width: glow ? 2.0 : 0.8,
        ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: TableMaterial.goldBright.withValues(alpha: 0.6),
              blurRadius: 9,
              spreadRadius: 1.2,
            ),
          // Sombra de apoyo, sutil — separa la carta del felt sin
          // convertirla en un objeto "flotante".
          const BoxShadow(
              color: Colors.black45, blurRadius: 3, offset: Offset(0, 1.5)),
        ],
      ),
      child: Column(
        children: [
          // Carril superior: SOLO el índice (valor + palo chico), nunca
          // el palo central — el Column garantiza que lo de abajo no
          // pueda invadir esta franja pase lo que pase.
          SizedBox(
            height: indexZoneHeight,
            child: Padding(
              padding: EdgeInsets.only(left: w * 0.10, top: h * 0.04),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.rank.letter,
                      style: TextStyle(
                        fontSize: indexFontSize,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      card.suit.symbol,
                      style: TextStyle(
                        fontSize: indexFontSize,
                        height: 1.05,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Carril inferior: el resto de la carta — el palo grande vive
          // acá, nunca en la franja de arriba. Un empujón leve hacia
          // abajo-derecha (sigue siendo el elemento central de la
          // carta), lo suficientemente lejos del índice como para que
          // quede un espacio vacío claramente visible entre los dos.
          Expanded(
            child: Align(
              alignment: const Alignment(0.25, 0.15),
              child: Text(
                card.suit.symbol,
                style:
                    TextStyle(fontSize: suitFontSize, height: 1, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dorso de carta: verde profundo + reticulado dorado + un medallón central
/// y un filete perimetral, también dorados — mismo lenguaje verde/dorado
/// que el paño y la cara de la carta (antes era un azul suelto, sin
/// relación con el resto de la mesa).
class CardBackPainter extends CustomPainter {
  const CardBackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [TableMaterial.cardBack1, TableMaterial.cardBack2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    final lattice = Paint()
      ..color = TableMaterial.cardBackLattice.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    const cols = 3, rows = 4;
    final cw = size.width / cols, ch = size.height / rows;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cx = cw * c + cw / 2, cy = ch * r + ch / 2;
        final d = math.min(cw, ch) * 0.30;
        final path = Path()
          ..moveTo(cx, cy - d)
          ..lineTo(cx + d, cy)
          ..lineTo(cx, cy + d)
          ..lineTo(cx - d, cy)
          ..close();
        canvas.drawPath(path, lattice);
      }
    }

    // Medallón central: un rombo más grande y hueco — sugiere el sello
    // Art Déco de una carta de casino premium, sin tener que trazar una
    // ilustración completa.
    final cx = size.width / 2, cy = size.height / 2;
    final md = math.min(size.width, size.height) * 0.24;
    final medallion = Path()
      ..moveTo(cx, cy - md)
      ..lineTo(cx + md, cy)
      ..lineTo(cx, cy + md)
      ..lineTo(cx - md, cy)
      ..close();
    canvas.drawPath(
      medallion,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size.width * 0.018)
        ..color = TableMaterial.cardBackLattice.withValues(alpha: 0.85),
    );

    // Filete dorado perimetral, inset — mismo criterio que la cara.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(size.width * 0.09),
        Radius.circular(size.width * 0.10),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, size.width * 0.02)
        ..color = TableMaterial.cardBackLattice.withValues(alpha: 0.6),
    );

    canvas.drawRect(
      rect.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant CardBackPainter oldDelegate) => false;
}
