import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ===================================================================
/// Sistema de fichas de póker — denominaciones, cálculo de stack y
/// renderer. PÚBLICO y reutilizable en cualquier parte de la app: no hay
/// nada acá pensado solo para la mesa de la Academia.
///
/// Tres piezas:
/// 1. [ChipDenomination] + [kChipDenominations] — la tabla central de
///    colores/valores. Es el ÚNICO lugar que sabe "25 → verde".
/// 2. [calculateChipStack] — la cantidad de fichas es un concepto
///    (cuántos objetos dibujar), el valor total es otro (cuánto vale la
///    pila): esta función traduce un valor total a la combinación de
///    denominaciones que lo representa.
/// 3. [PokerChip] / [PokerChipStack] — la ficha maestra. Una sola
///    geometría (tamaño, perspectiva, grosor, forma, sombras), reutilizada
///    para las 5 denominaciones: lo único que cambia entre ellas es el
///    color, nunca la forma.
/// ===================================================================

// -----------------------------------------------------------------
// 1. Denominaciones
// -----------------------------------------------------------------

/// Una denominación de ficha: cuánto vale y cómo se ve. Inmutable y
/// comparable por valor (para tests y para `shouldRepaint`).
@immutable
class ChipDenomination {
  const ChipDenomination({
    required this.value,
    required this.displayName,
    required this.color,
    Color? accentColor,
  }) : accentColor = accentColor ?? _defaultAccent;

  /// Cuánto vale UNA ficha de esta denominación.
  final int value;

  /// Nombre para mostrar (debug, tooltips futuros).
  final String displayName;

  /// Color principal — cara y canto. Las variantes clara/oscura del
  /// degradé se derivan de este único color en tiempo de pintado (ver
  /// [_lighten]/[_darken] en la sección de renderer), así que agregar una
  /// denominación nueva no exige inventar una paleta de tres tonos a
  /// mano: un color alcanza.
  final Color color;

  /// Color de las muescas del canto y del reborde — marfil por defecto,
  /// como casi cualquier ficha real. Algunas denominaciones (la blanca)
  /// necesitan uno propio para no perder contraste cuerpo/muesca — de
  /// ahí que sea overridable por denominación.
  final Color accentColor;

  static const Color _defaultAccent = Color(0xFFF3EFE4);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChipDenomination &&
          other.value == value &&
          other.displayName == displayName &&
          other.color == color &&
          other.accentColor == accentColor);

  @override
  int get hashCode => Object.hash(value, displayName, color, accentColor);

  @override
  String toString() => 'ChipDenomination($value, $displayName)';
}

/// Tabla central de denominaciones — el ÚNICO lugar de toda la app donde
/// se define "qué valor tiene cada color". Cambiar acá (agregar, sacar,
/// recolorear una denominación) alcanza: ni el algoritmo de
/// [calculateChipStack] ni el renderer ([PokerChip]/[PokerChipStack])
/// tienen ningún color o valor hardcodeado — los dos leen esta lista.
///
/// El orden no importa (calculateChipStack ordena por su cuenta), pero se
/// declara descendente por legibilidad.
const List<ChipDenomination> kChipDenominations = [
  ChipDenomination(
    value: 100,
    displayName: 'Negra',
    color: Color(0xFF1C1C1E),
  ),
  ChipDenomination(
    value: 25,
    displayName: 'Verde',
    color: Color(0xFF1E7A4C),
  ),
  ChipDenomination(
    value: 10,
    displayName: 'Azul',
    color: Color(0xFF1F3E78),
  ),
  ChipDenomination(
    value: 5,
    displayName: 'Roja',
    color: Color(0xFFA5302E),
  ),
  ChipDenomination(
    value: 1,
    displayName: 'Blanca',
    // La blanca es la única cuyo cuerpo es casi tan claro como el marfil
    // de las muescas — necesita un acento propio (azul) para que el
    // patrón de muescas siga siendo legible.
    color: Color(0xFFF3EFE4),
    accentColor: Color(0xFF1F3E78),
  ),
];

// -----------------------------------------------------------------
// 2. Cálculo de stack
// -----------------------------------------------------------------

/// Cuántas fichas físicas, y de qué denominación, hacen falta para
/// representar [totalValue] — algoritmo goloso (siempre la denominación
/// más alta que todavía entra), correcto y óptimo en cantidad de fichas
/// porque [kChipDenominations] es una escala canónica (1/5/10/25/100,
/// como la moneda real: cada denominación es múltiplo limpio de una
/// combinación de las menores).
///
/// Devuelve una lista PLANA — una entrada por ficha física, no
/// "denominación + cantidad" — lista para mapear 1 a 1 a widgets:
/// `calculateChipStack(150)` da `[100, 25, 5, 5, 5, 5, 5]`, siete
/// elementos, no "100×1, 25×1, 5×5".
///
/// La CANTIDAD de fichas visuales y el VALOR que representa la pila son
/// conceptos distintos a propósito: esta función solo resuelve el
/// segundo. Cuántas de esas fichas conviene dibujar de verdad es
/// responsabilidad de [limitVisibleChips]/[PokerChipStack.maxVisibleChips].
List<ChipDenomination> calculateChipStack(int totalValue) {
  if (totalValue <= 0) return const [];
  final byValueDesc = [...kChipDenominations]
    ..sort((a, b) => b.value.compareTo(a.value));
  final chips = <ChipDenomination>[];
  var remaining = totalValue;
  for (final denom in byValueDesc) {
    while (remaining >= denom.value) {
      chips.add(denom);
      remaining -= denom.value;
    }
  }
  return chips;
}

/// Recorta una pila ya calculada a lo sumo a [maxVisible] fichas —
/// siempre las de MAYOR valor primero (ya vienen en ese orden desde
/// [calculateChipStack]), así que lo que se recorta es siempre el
/// remanente de menor valor. El valor total real de la pila no vive acá:
/// sigue mostrándose aparte (el texto del bote/apuesta ya lo hace), así
/// que la pila física puede quedar compacta sin que se pierda
/// información — un stack puede representar 500 de valor sin necesidad
/// de dibujar 500 fichas.
List<ChipDenomination> limitVisibleChips(
        List<ChipDenomination> chips, int maxVisible) =>
    chips.length <= maxVisible ? chips : chips.sublist(0, maxVisible);

// -----------------------------------------------------------------
// 3. Geometría y pintado — UNA sola implementación de "cómo se ve una
// ficha", compartida por la ficha suelta ([PokerChip]) y cada nivel de
// una pila ([PokerChipStack]). Nada acá conoce colores de denominación
// específicos: todo lo recibe por parámetro (ver [_paintChipBody]).
// -----------------------------------------------------------------

/// Compresión vertical compartida por TODOS los óvalos de una ficha
/// (canto, cara, anillo, brillo, reborde) — 1.0 sería un círculo
/// perfecto; un valor apenas por debajo alcanza para leerse como "vista
/// desde arriba, apoyada sobre una superficie inclinada" sin dejar de
/// leerse como redonda.
const double _chipFaceSquash = 0.90;

/// Rect elíptico (compresión [_chipFaceSquash]) centrado en [c], de radio
/// [radius] — el mismo óvalo para TODOS los elementos de una ficha, así
/// se leen como una sola pieza inclinada, nunca como capas sueltas con
/// perspectivas distintas.
Rect _chipOvalRect(Offset c, double radius) => Rect.fromCenter(
      center: c,
      width: radius * 2,
      height: radius * 2 * _chipFaceSquash,
    );

/// Alto (dp) de la extrusión vertical REAL de cada ficha — una caída
/// genuina hacia abajo (un `y` distinto, no otro radio), además del ancho
/// del canto ([edgeWidth]). Deliberadamente más chica que el propio ancho
/// del canto: domina la lectura "disco con canto ancho, apoyado con
/// volumen real", nunca "píldora/cápsula".
double _chipWallHeight(double edgeWidth) => edgeWidth * 0.8;

/// Silueta COMPLETA de una ficha con su altura real: el óvalo de arriba
/// (cara + canto) unido a una banda vertical y un segundo óvalo idéntico
/// [wallHeight] más abajo — un cilindro bajo visto casi desde arriba,
/// nunca una caja: el borde inferior queda tan curvo como el superior.
/// Se usa para el recorte de una pila (ver [_PokerChipPilePainter]) y
/// coincide exactamente con lo que pinta [_paintChipBody].
Path _chipSilhouette(Offset topCenter, double outerR, double wallHeight) {
  final top = Path()..addOval(_chipOvalRect(topCenter, outerR));
  if (wallHeight <= 0) return top;
  final band = Path()
    ..addRect(Rect.fromLTWH(
        topCenter.dx - outerR, topCenter.dy, outerR * 2, wallHeight));
  final bottom = Path()
    ..addOval(
        _chipOvalRect(Offset(topCenter.dx, topCenter.dy + wallHeight), outerR));
  return Path.combine(PathOperation.union,
      Path.combine(PathOperation.union, top, band), bottom);
}

/// Variante más clara de [c] — mezcla hacia blanco en proporción
/// [amount]. Así una denominación con un solo `color` alcanza para
/// generar el degradé de tres tonos (claro/base/oscuro) que necesita la
/// ficha, sin tener que declarar tres colores a mano por denominación.
Color _lighten(Color c, double amount) => Color.from(
      alpha: c.a,
      red: (c.r + (1 - c.r) * amount).clamp(0.0, 1.0),
      green: (c.g + (1 - c.g) * amount).clamp(0.0, 1.0),
      blue: (c.b + (1 - c.b) * amount).clamp(0.0, 1.0),
    );

/// Variante más oscura de [c] — mezcla hacia negro en proporción
/// [amount]. Ver [_lighten].
Color _darken(Color c, double amount) => Color.from(
      alpha: c.a,
      red: (c.r * (1 - amount)).clamp(0.0, 1.0),
      green: (c.g * (1 - amount)).clamp(0.0, 1.0),
      blue: (c.b * (1 - amount)).clamp(0.0, 1.0),
    );

/// Dibuja UNA ficha completa (pared vertical + canto + muescas + cara +
/// anillo + brillo + reborde), centrada en [center] — la cara y el canto
/// son **dos óvalos concéntricos**, mismo centro (el exterior = la cara +
/// [edgeWidth] de espesor hacia afuera, en TODAS direcciones), y debajo
/// hay una **pared vertical real** de alto [_chipWallHeight]: una caída
/// genuina hacia abajo, no otro radio más.
///
/// [denomination] controla ÚNICAMENTE el color — cuerpo, brillo, sombra y
/// acento se derivan todos de `denomination.color`/`accentColor`. La
/// geometría (tamaño, perspectiva, grosor, curvatura) es la MISMA para
/// las 5 denominaciones: cambiar la tabla de [kChipDenominations] nunca
/// necesita tocar esta función.
///
/// Esta función no sabe si la ficha está sola o tapada por otra encima —
/// eso lo resuelve quien la llama recortando el `Canvas` (ver
/// [_PokerChipPilePainter]) antes de invocarla.
void _paintChipBody(
  Canvas canvas, {
  required Offset center,
  required double faceR,
  required double edgeWidth,
  required double ringWidth,
  required ChipDenomination denomination,
}) {
  final bright = _lighten(denomination.color, 0.28);
  final base = denomination.color;
  final dim = _darken(denomination.color, 0.35);
  final accent = denomination.accentColor;

  final outerR = faceR + edgeWidth;
  final outerRect = _chipOvalRect(center, outerR);
  final faceRect = _chipOvalRect(center, faceR);
  final wallHeight = _chipWallHeight(edgeWidth);
  final outerBottom = center.dy + outerR * _chipFaceSquash;

  // Pared vertical: un CILINDRO REALMENTE RELLENO, no un contorno armado
  // con dos círculos. Se pinta con formas SÓLIDAS, en este orden — el
  // mismo truco de siempre de "capas que se tapan":
  //   1. el óvalo de ABAJO (el piso del cilindro), relleno completo;
  //   2. la banda rectangular que lo une con arriba, rellena completa —
  //      las dos con el MISMO Paint/degradé, sin costura de color;
  //   3. acentos en los bordes laterales de la banda (continúan el
  //      patrón de muescas del canto, ver más abajo);
  //   4. (más abajo en esta función) el óvalo de ARRIBA — cara + canto —
  //      pintado ENCIMA, tapando la mitad de arriba de todo lo anterior.
  if (wallHeight > 0.3) {
    final wallBottomCenter = Offset(center.dx, center.dy + wallHeight);
    final wallPaint = Paint()
      ..shader = LinearGradient(
        colors: [dim, base, bright, base, dim],
        stops: const [0.0, 0.22, 0.5, 0.78, 1.0],
      ).createShader(outerRect);
    canvas.drawOval(_chipOvalRect(wallBottomCenter, outerR), wallPaint);
    canvas.drawRect(
      Rect.fromLTWH(
          center.dx - outerR, outerBottom - 1, outerR * 2, wallHeight + 1),
      wallPaint,
    );
    // Acento en los bordes laterales de la banda: el ancho real de la
    // banda ya coincide con el del anillo de arriba (mismo outerR), pero
    // un relleno oscuro liso sin ninguna marca de alto contraste en sus
    // costados se LEE más angosto que el anillo (que sí tiene muescas
    // marcando su borde). Un acento angosto, mismo color que las
    // muescas, resuelve la lectura — y de paso es fiel a una ficha real,
    // donde las marcas del canto bajan por todo el costado.
    if (edgeWidth > 0.5) {
      final edgeAccentW = (edgeWidth * 0.32).clamp(0.5, 1.8);
      final edgeAccentPaint = Paint()..color = accent.withValues(alpha: 0.85);
      for (final side in [-1, 1]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              center.dx + side * outerR - (side > 0 ? edgeAccentW : 0),
              outerBottom - 0.5,
              edgeAccentW,
              wallHeight + 1,
            ),
            Radius.circular(edgeAccentW * 0.4),
          ),
          edgeAccentPaint,
        );
      }
    }
  }

  // Canto: el óvalo EXTERIOR completo, con un degradé IZQUIERDA→DERECHA
  // (oscuro en los dos extremos, más claro en el medio) — así se lee
  // como una superficie curva envolviendo un cilindro. Mismo color que
  // la cara (una ficha real es del mismo material en la cara y el canto,
  // solo que en sombra). Se ve como un anillo parejo alrededor de TODA
  // la cara — no solo abajo — porque la cara (más chica, mismo centro)
  // se dibuja encima y tapa únicamente su propia superficie.
  canvas.drawOval(
    outerRect,
    Paint()
      ..shader = LinearGradient(
        colors: [dim, base, bright, base, dim],
        stops: const [0.0, 0.22, 0.5, 0.78, 1.0],
      ).createShader(outerRect),
  );

  // Muescas del canto: el patrón real de una ficha de casino — un bloque
  // ancho y macizo alternado con un par de rayas finas, 8 posiciones en
  // total (4 bloques + 4 pares), nunca 8 marcas idénticas.
  if (edgeWidth > 0.5) {
    const groupCount = 4;
    final notchPaint = Paint()..color = accent.withValues(alpha: 0.95);
    final midR = (faceR + outerR) / 2;
    final blockW = (edgeWidth * 1.15).clamp(1.2, 5.0);
    final blockH = (edgeWidth * 1.9).clamp(1.8, 7.5);
    final dashW = (edgeWidth * 0.42).clamp(0.5, 1.8);
    final dashH = (edgeWidth * 1.5).clamp(1.4, 6.0);
    const dashGap = 0.16; // radianes entre las dos rayas de un mismo par.

    void notchAt(double angle, double w, double h) {
      final x = center.dx + math.cos(angle) * midR;
      final y = center.dy + math.sin(angle) * midR * _chipFaceSquash;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          Radius.circular(w * 0.3),
        ),
        notchPaint,
      );
      canvas.restore();
    }

    for (var i = 0; i < groupCount; i++) {
      final blockAngle = (i / groupCount) * 2 * math.pi;
      notchAt(blockAngle, blockW, blockH);
      final dashAngle = blockAngle + (math.pi / groupCount);
      notchAt(dashAngle - dashGap, dashW, dashH);
      notchAt(dashAngle + dashGap, dashW, dashH);
    }
  }

  // Cara del disco: gradiente con brillo superior-izquierdo, encima del
  // canto y sus muescas — cubre solo su propio óvalo (más chico),
  // dejando el anillo del canto visible alrededor.
  canvas.drawOval(
    faceRect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: [bright, base, dim],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(faceRect),
  );

  // Filete diagonal donde la cara se une con el canto — claro arriba a
  // la izquierda (recibe la luz), oscuro abajo a la derecha (en sombra).
  canvas.drawOval(
    _chipOvalRect(center, faceR),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (edgeWidth * 0.3).clamp(0.5, 1.4)
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          bright.withValues(alpha: 0.4),
          dim.withValues(alpha: 0.5),
          Colors.black.withValues(alpha: 0.35),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(faceRect),
  );

  // Anillo interior: separa un "centro" limpio, como el sello de una
  // ficha real.
  canvas.drawOval(
    _chipOvalRect(center, faceR * 0.52),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..color = Colors.white.withValues(alpha: 0.55),
  );

  // Brillo especular: un resplandor suave arriba-izquierda sobre TODA la
  // cara (satinado) más un arco corto encima.
  canvas.drawOval(
    faceRect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.6,
        colors: [
          Colors.white.withValues(alpha: 0.30),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(faceRect),
  );
  canvas.drawArc(
    faceRect.deflate(faceR * 0.14),
    math.pi * 1.05,
    math.pi * 0.55,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceR * 0.16
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.35),
  );

  // Reborde, MUY fino: UN solo trazo, en el borde exterior de TODA la
  // ficha — es lo que de verdad separa una ficha de la que tiene debajo
  // en la pila: cuando el `Canvas` está recortado a lo que queda visible
  // de esta ficha, lo que asoma trae consigo un tramo curvo de este
  // mismo trazo, nunca una línea recta artificial.
  canvas.drawOval(
    _chipOvalRect(center, outerR - 0.4),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (ringWidth * 0.6).clamp(0.5, 1.6)
      ..color = accent.withValues(alpha: 0.9),
  );
}

/// Sombra de apoyo contra el paño — debajo de TODA la ficha (o de la
/// BASE de una pila), un óvalo que sigue la silueta de la ficha, nunca
/// una forma rectangular. Independiente del color de denominación (una
/// sombra siempre es neutra).
void _paintChipGroundShadow(
  Canvas canvas, {
  required Offset center,
  required double outerR,
  required double edgeWidth,
}) {
  final wallBottom =
      center.dy + outerR * _chipFaceSquash + _chipWallHeight(edgeWidth);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(center.dx, wallBottom + edgeWidth * 0.4 + 1.0),
      width: outerR * 2 * 0.9,
      height: math.max(2.6, edgeWidth * 1.3),
    ),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
  );
}

// -----------------------------------------------------------------
// 4. Widgets públicos
// -----------------------------------------------------------------

/// Ficha física suelta — la pieza maestra: UNA sola geometría (tamaño,
/// perspectiva, grosor, forma, sombras) para cualquier denominación. Lo
/// único que cambia entre fichas es [denomination] (el color); nunca hay
/// un painter/widget distinto por color.
class PokerChip extends StatelessWidget {
  const PokerChip({
    super.key,
    required this.denomination,
    this.diameter = 12,
    this.thickness = _defaultThickness,
    this.borderWidth = 0.8,
  });

  /// Qué denominación (y por lo tanto qué color) es esta ficha.
  final ChipDenomination denomination;

  /// Diámetro de la CARA (el óvalo interior) — el ancho de la ficha antes
  /// de sumar el canto.
  final double diameter;

  /// Cuánto se ensancha el canto MÁS ALLÁ de la cara, en todas
  /// direcciones — el "espesor" físico de la ficha.
  final double thickness;

  final double borderWidth;

  static const double _defaultThickness = 2.2;

  /// Diámetro total de la ficha (cara + canto a los dos lados).
  static double outerDiameter(double diameter, double thickness) =>
      diameter + thickness * 2;

  @override
  Widget build(BuildContext context) {
    final outerD = outerDiameter(diameter, thickness);
    return SizedBox(
      width: outerD,
      height: outerD * _chipFaceSquash + _chipWallHeight(thickness),
      child: CustomPaint(
        painter: _PokerChipPainter(
          faceDiameter: diameter,
          edgeWidth: thickness,
          ringWidth: borderWidth,
          denomination: denomination,
        ),
      ),
    );
  }
}

class _PokerChipPainter extends CustomPainter {
  const _PokerChipPainter({
    required this.faceDiameter,
    required this.edgeWidth,
    required this.ringWidth,
    required this.denomination,
  });

  final double faceDiameter;
  final double edgeWidth;
  final double ringWidth;
  final ChipDenomination denomination;

  @override
  void paint(Canvas canvas, Size size) {
    final faceR = faceDiameter / 2;
    final outerR = faceR + edgeWidth;
    final center = Offset(outerR, outerR * _chipFaceSquash);
    _paintChipGroundShadow(canvas,
        center: center, outerR: outerR, edgeWidth: edgeWidth);
    _paintChipBody(canvas,
        center: center,
        faceR: faceR,
        edgeWidth: edgeWidth,
        ringWidth: ringWidth,
        denomination: denomination);
  }

  @override
  bool shouldRepaint(covariant _PokerChipPainter oldDelegate) =>
      oldDelegate.faceDiameter != faceDiameter ||
      oldDelegate.edgeWidth != edgeWidth ||
      oldDelegate.ringWidth != ringWidth ||
      oldDelegate.denomination != denomination;
}

/// Pila de fichas — recibe un [totalValue] (no una cantidad de fichas) y
/// arma automáticamente la combinación de denominaciones que lo
/// representa (ver [calculateChipStack]), apiladas físicamente: contacto
/// real, orden Z correcto, sombra de contacto localizada, sin huecos —
/// exactamente la misma mecánica que ya usa el resto de la mesa, ahora
/// generalizada a colores por ficha en vez de un color único.
///
/// Reutilizable en cualquier parte de la app:
/// ```dart
/// PokerChipStack(totalValue: 125)
/// ```
/// arma sola 1 ficha negra (100) + 1 verde (25).
class PokerChipStack extends StatelessWidget {
  const PokerChipStack({
    super.key,
    required this.totalValue,
    this.scale = 1,
    this.maxVisibleChips = 8,
    this.faceDiameter = 13,
    this.thickness = _defaultThickness,
  });

  /// Valor TOTAL que representa la pila — no la cantidad de fichas a
  /// dibujar (eso lo decide [calculateChipStack] + [maxVisibleChips]).
  final int totalValue;

  final double scale;

  /// Techo de fichas físicas a dibujar. Un stack puede representar un
  /// valor enorme sin necesidad de renderizar cientos de objetos — el
  /// valor total real se sigue mostrando aparte (el texto del
  /// bote/apuesta), así que superar este límite solo recorta la pila
  /// visual, nunca el valor que representa.
  final int maxVisibleChips;

  /// Diámetro de referencia de la CARA de cada ficha (antes de escalar).
  final double faceDiameter;

  /// Espesor de referencia de cada ficha (antes de escalar).
  final double thickness;

  static const double _defaultThickness = 2.4;

  @override
  Widget build(BuildContext context) {
    final chips =
        limitVisibleChips(calculateChipStack(totalValue), maxVisibleChips);
    if (chips.isEmpty) return const SizedBox.shrink();

    final faceD = faceDiameter * scale;
    final edgeWidth = thickness * scale;
    final wallHeight = _chipWallHeight(edgeWidth);
    final outerR = faceD / 2 + edgeWidth;
    // Cuánto asoma la ficha de abajo por encima de la que tiene encima —
    // no decide si hay huecos (el recorte booleano ya lo garantiza), solo
    // cuánto de cada ficha queda a la vista.
    final overlap = (edgeWidth + wallHeight) * 0.60;
    final topExtra = outerR * _chipFaceSquash;
    final shadowMargin = edgeWidth * 1.3 + 4;
    return SizedBox(
      width: outerR * 2,
      height: topExtra * 2 +
          overlap * (chips.length - 1) +
          wallHeight +
          shadowMargin,
      child: CustomPaint(
        painter: _PokerChipPilePainter(
          denominations: chips,
          faceDiameter: faceD,
          edgeWidth: edgeWidth,
          overlap: overlap,
          ringWidth: 0.9 * scale,
        ),
      ),
    );
  }
}

/// Pinta la pila completa en un solo `Canvas`.
///
/// **Por qué UN solo `CustomPaint` y no un widget por ficha:** apilar
/// cada ficha como un widget independiente (su propia caja, su propio
/// óvalo) solo tapa a la de abajo donde las dos cajas se superponen en un
/// rectángulo — pero el óvalo de una ficha se aleja de los bordes de SU
/// PROPIA caja cerca de los costados (así es una elipse), así que cerca
/// de los costados de la pila queda un hueco real entre el borde de una
/// ficha y el de la siguiente. La solución: cada ficha, de abajo hacia
/// arriba, se recorta (`Canvas.clipPath`) exactamente a lo que le queda
/// visible — su propio óvalo MENOS la unión de los óvalos de las fichas
/// que tiene encima — antes de pintarla. Esa resta geométrica no puede
/// dejar huecos: es una operación booleana exacta.
class _PokerChipPilePainter extends CustomPainter {
  const _PokerChipPilePainter({
    required this.denominations,
    required this.faceDiameter,
    required this.edgeWidth,
    required this.overlap,
    required this.ringWidth,
  });

  /// Una entrada por ficha física, de la BASE (índice 0) a la de más
  /// arriba — mismo orden que devuelve [calculateChipStack] (mayor valor
  /// primero), así que la ficha de mayor valor queda naturalmente en la
  /// base de la pila.
  final List<ChipDenomination> denominations;
  final double faceDiameter;
  final double edgeWidth;
  final double overlap;
  final double ringWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final count = denominations.length;
    final faceR = faceDiameter / 2;
    final outerR = faceR + edgeWidth;
    final wallHeight = _chipWallHeight(edgeWidth);
    final topExtra = outerR * _chipFaceSquash;

    // Centro de cada ficha — i=0 es la BASE (más abajo, más cerca del
    // paño), i=count-1 es la de más arriba. Todas comparten el mismo eje
    // horizontal (la pila crece derecho hacia arriba).
    final centers = [
      for (var i = 0; i < count; i++)
        Offset(outerR, topExtra + overlap * (count - 1 - i)),
    ];
    final ovals = [
      for (final c in centers) _chipSilhouette(c, outerR, wallHeight),
    ];

    // Recorte visible de cada ficha: su óvalo MENOS la unión de los
    // óvalos de las fichas que tiene ENCIMA (índice mayor).
    final visible = List<Path>.filled(count, Path());
    Path? aboveUnion;
    for (var i = count - 1; i >= 0; i--) {
      visible[i] = aboveUnion == null
          ? ovals[i]
          : Path.combine(PathOperation.difference, ovals[i], aboveUnion);
      aboveUnion = aboveUnion == null
          ? ovals[i]
          : Path.combine(PathOperation.union, aboveUnion, ovals[i]);
    }

    // Sombra de apoyo contra el paño — una sola, debajo de la BASE de
    // toda la pila.
    _paintChipGroundShadow(canvas,
        center: centers[0], outerR: outerR, edgeWidth: edgeWidth);

    for (var i = 0; i < count; i++) {
      if (i > 0) {
        // Sombra de CONTACTO: se pinta ANTES que la ficha i, recortada a
        // lo que queda visible de la ficha de ABAJO (i-1). La ficha i,
        // pintada justo después, tapa casi toda esta sombra excepto un
        // filo fino pegado a su propio borde.
        canvas.save();
        canvas.clipPath(visible[i - 1]);
        canvas.drawPath(
          _chipSilhouette(
              centers[i] + const Offset(0, 1.0), outerR * 1.04, wallHeight),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0),
        );
        canvas.restore();
      }

      canvas.save();
      canvas.clipPath(visible[i]);
      _paintChipBody(canvas,
          center: centers[i],
          faceR: faceR,
          edgeWidth: edgeWidth,
          ringWidth: ringWidth,
          denomination: denominations[i]);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PokerChipPilePainter oldDelegate) =>
      !listEquals(oldDelegate.denominations, denominations) ||
      oldDelegate.faceDiameter != faceDiameter ||
      oldDelegate.edgeWidth != edgeWidth ||
      oldDelegate.overlap != overlap ||
      oldDelegate.ringWidth != ringWidth;
}
