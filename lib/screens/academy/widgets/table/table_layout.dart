import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Claves de test: las cartas del héroe y el board — los tests comprueban
/// que estén siempre visibles en pantalla. Viven en este archivo (la base
/// sin dependencias de `table/`) porque tanto `PlayerSeat` como
/// `CommunityCards` las necesitan; `poker_table_view.dart` las re-exporta
/// para que el import público externo (`import '.../poker_table_view.dart'`)
/// siga funcionando sin cambios.
const Key kAcademyTableHeroCardsKey = Key('academy.table.heroCards');
const Key kAcademyTableBoardKey = Key('academy.table.board');

/// Key del panel de un asiento (0..5) — para tests.
Key kAcademyTableAvatarKey(int slot) => Key('academy.table.avatar.$slot');

/// Paleta de materiales de la mesa — **local a este módulo**, no vive en
/// `AppColors` porque es específica de la materialidad física de la mesa
/// (madera, fieltro, marfil) y no se reutiliza en el resto de la app (Home,
/// Academia, Laboratorio, Bankroll siguen con la paleta violeta/neón de
/// `AppColors` sin cambios). Dirección: verde profundo + madera oscura +
/// dorado elegante + fondo casi negro.
class TableMaterial {
  TableMaterial._();

  static const Color feltCenter = Color(0xFF1D5C36);
  static const Color feltMid = Color(0xFF174D2D);
  static const Color feltEdge = Color(0xFF0C3020);

  static const Color railLight = Color(0xFF3A1F0A);
  static const Color railDark = Color(0xFF1E0E04);
  static const Color railSheen = Color(0xFF4D2C0E);

  static const Color gold = Color(0xFFC9A050);
  static const Color goldBright = Color(0xFFE0B860);
  static const Color goldDim = Color(0xFF7A5F2A);

  static const Color text = Color(0xFFE8DFD0);
  static const Color textSub = Color(0xFF9A9080);
  static const Color textDim = Color(0xFF4A4438);

  static const Color success = Color(0xFF30C870);
  static const Color focus = Color(0xFFF0BE50);

  // Cara marfil (ya no blanco puro) + tinta roja/negra más profunda —
  // referencia: mazo de casino premium (filete dorado, no un naipe
  // genérico). Dorso: verde + dorado, mismo lenguaje que el paño y el
  // riel, en vez del azul suelto que tenía antes.
  static const Color cardFaceTop = Color(0xFFFBF7EC);
  static const Color cardFaceBottom = Color(0xFFEEE6D2);
  static const Color cardRed = Color(0xFFA5302E);
  static const Color cardBlack = Color(0xFF181511);
  static const Color cardBack1 = Color(0xFF123D28);
  static const Color cardBack2 = Color(0xFF081F14);
  static const Color cardBackLattice = Color(0xFFC9A050);
}

/// Números tabulares nativos (sin fuente monoespaciada propia): alinea
/// columnas de cifras (stack/pot/bet) usando la fuente de plataforma.
/// Compartido por [PlayerSeat]/`PotBadge`/`BetChip` (viven en archivos
/// separados dentro de `table/`, todos dependen de este archivo base).
const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

/// Formatea un monto en BB: sin decimales si es entero, con un decimal si
/// no — mismo criterio en toda la mesa (panel, bote, apuesta).
String formatBb(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Geometría de la mesa.
///
/// **Regla única:** el paño ([feltRect], una elipse REAL — no un
/// rectángulo muy redondeado) es el sistema de coordenadas. El panel de
/// cada asiento va *sobre el perímetro* de la elipse. Fichas, board y bote
/// se ubican interpolando desde el asiento hacia el centro del paño
/// ([_toward]).
///
/// **La mesa solo sabe dónde está el jugador — nunca dónde están sus
/// cartas.** [panel] devuelve la posición del jugador completo: una sola
/// fórmula (`_toward(slot, 0.01)`), sin ninguna excepción por slot, héroe
/// incluido — lo único que cambia entre asientos es [seat] (dónde cae
/// cada uno alrededor de la elipse), no la fórmula.
///
/// Las cartas privadas NO tienen coordenada propia en esta clase: cada
/// `PlayerSeat` las ancla a SU PROPIA posición con un offset local fijo —
/// la mesa nunca necesita saber que existen. Panel y cartas son una sola
/// pieza (`PlayerSeat`, en `player_seat.dart`), y `TableLayout` solo ubica
/// esa pieza.
///
/// El paño mantiene una proporción horizontal fija de referencia
/// (~1.5:1, [ovalAspect]): en vez de estirarse hasta ocupar todo el alto
/// disponible, se recorta a esa proporción y se centra verticalmente en el
/// espacio que le da el padre — así la mesa siempre se lee como un óvalo
/// horizontal auténtico, sea cual sea el alto real del contenedor.
class TableLayout {
  TableLayout(this.size)
      : scale = (size.width / _referenceWidth).clamp(_minScale, 1.0);

  final Size size;

  /// Escala suave de avatares / cartas / tipografías.
  final double scale;

  static const double _referenceWidth = 384;
  static const double _minScale = 0.82;

  /// Techo del alto del paño, como fracción del alto TOTAL disponible.
  static const double _feltHeightCeiling = 0.94;

  /// Proporción ancho:alto objetivo del óvalo (mesa real, no cuadrada).
  static const double ovalAspect = 1.5;

  /// Ángulo de cada asiento sobre la elipse (0°=derecha, 90°=abajo). Héroe
  /// abajo; los otros cinco en arco sobre el paño, simétrico.
  ///
  /// **La mesa se juega en sentido horario** (regla del juego, no estética
  /// — ver `TablePositions` en `table_position.dart`, que define
  /// BTN→SB→BB→UTG→HJ→CO como el slot *decreciente*). Estos ángulos están
  /// elegidos para que recorrer los slots en ese mismo orden decreciente
  /// trace un arco horario en pantalla. Si algún día cambia la
  /// distribución, conservar esta propiedad: slot decreciente = horario.
  static const List<double> _angleDeg = [90, 32, 335, 270, 205, 148];

  /// Paño (verde), óvalo real, recortado a [ovalAspect] y centrado —
  /// horizontal Y verticalmente — en el espacio total disponible.
  ///
  /// [_feltHeightCeiling] y los márgenes de riel solo acotan cuánto puede
  /// crecer el óvalo (para dejarle aire al riel, que sobresale de
  /// [feltRect] en el pintor); una vez fijado su tamaño final, se centra en
  /// TODO el contenedor — nunca solo en la porción superior — para que la
  /// mesa no quede corrida hacia arriba con un vacío debajo.
  Rect get feltRect {
    final railX = size.width * 0.022;
    final railY = size.height * 0.02;
    final maxW = size.width - 2 * railX;
    final maxH = size.height * _feltHeightCeiling - 2 * railY;

    var h = maxH;
    var w = h * ovalAspect;
    if (w > maxW) {
      w = maxW;
      h = w / ovalAspect;
    }

    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  Offset get feltCentre => feltRect.center;

  /// Punto del perímetro de la elipse del paño para el asiento [slot].
  Offset seat(int slot) {
    final a = _angleDeg[slot] * math.pi / 180;
    return Offset(
      feltCentre.dx + feltRect.width / 2 * math.cos(a),
      feltCentre.dy + feltRect.height / 2 * math.sin(a),
    );
  }

  Offset _toward(int slot, double t) => Offset.lerp(seat(slot), feltCentre, t)!;

  /// Rectángulo inscrito en la elipse: cualquier caja centrada acá y de
  /// lado ≤ el suyo queda entera dentro del verde.
  Rect get _inscribed {
    final hw = feltRect.width / 2 * 0.70;
    final hh = feltRect.height / 2 * 0.70;
    return Rect.fromCenter(center: feltCentre, width: 2 * hw, height: 2 * hh);
  }

  /// Centro válido para una caja de tamaño [box] centrada en [c],
  /// garantizando que no se sale del verde.
  Offset clampInFelt(Offset c, Size box) {
    final r = _inscribed;
    return Offset(
      c.dx.clamp(r.left + box.width / 2, r.right - box.width / 2),
      c.dy.clamp(r.top + box.height / 2, r.bottom - box.height / 2),
    );
  }

  /// Vector unitario asiento → centro (hacia dónde apunta el asiento).
  Offset inward(int slot) {
    final v = feltCentre - seat(slot);
    final d = v.distance;
    return d == 0 ? const Offset(0, -1) : v / d;
  }

  /// Perpendicular a [inward]: "de costado" respecto al asiento, en vez de
  /// derecho hacia el centro. Afinado a mano en el taller para cartas y
  /// fichas de los asientos angulares (32°/335°/205°/148°) — el corrimiento
  /// sale simétrico solo porque se calcula en el sistema de cada asiento.
  Offset _tangent(int slot) {
    final v = inward(slot);
    return Offset(-v.dy, v.dx);
  }

  /// Slot del asiento de arriba (ángulo 270°) — el único, junto con el
  /// héroe (slot 0, ángulo 90°), que cae exactamente sobre el eje
  /// vertical del óvalo. Se usa solo para [panel]: decidir CUÁLES de los
  /// 6 asientos "respiran" un poco más, no para darles una fórmula
  /// distinta (los dos usan la misma cuenta: alejarse del centro).
  static const int _topSlot = 3;

  /// Cuánto se alejan del centro el héroe y el asiento de arriba respecto
  /// del resto — un único número, aplicado en sentidos opuestos, por eso
  /// quedan simétricos: `panel(slot) - inward(slot) * separation` mueve
  /// CUALQUIER asiento en línea recta alejándolo del centro; para el
  /// héroe [inward] apunta hacia arriba (así que alejarse es bajar), para
  /// el de arriba [inward] apunta hacia abajo (así que alejarse es
  /// subir) — la misma resta produce el efecto opuesto en cada uno sin
  /// necesidad de dos constantes ni de un signo manual.
  static const double _verticalBreathingRoom = 10;

  /// Panel de CUALQUIER asiento: **una sola fórmula base, sin excepciones
  /// por slot** — los 6 arrancan del mismo t sobre el perímetro de la
  /// elipse, héroe incluido. La única variación es [_verticalBreathingRoom]
  /// (arriba), que separa un poco más del centro a los dos asientos sobre
  /// el eje vertical (ver esa constante) para que la mesa respire —
  /// simétrico por construcción, no dos ajustes independientes.
  Offset panel(int slot) {
    final base = _toward(slot, 0.01);
    if (slot == 0 || slot == _topSlot) {
      return base - inward(slot) * (_verticalBreathingRoom * scale);
    }
    return base;
  }

  // Un empujón "de costado" (afinado a mano) además del t genérico.
  Offset bet(int slot) => _toward(slot, 0.53) + _tangent(slot) * (15 * scale);

  /// Cuánto se separa el botón de dealer de su panel: [_dealerToward] hacia
  /// el centro de la mesa (para caer sobre el paño, no sobre el panel) y
  /// [_dealerSide] "de costado" (para no superponerse con las cartas de
  /// ESE mismo jugador, que asoman derecho hacia arriba desde el panel).
  /// Éste es el offset BASE, igual para los 6 asientos — ver
  /// [_dealerSlot2Extra] para la única excepción puntual.
  static const double _dealerToward = 46;
  static const double _dealerSide = 22;

  /// Separación vertical mínima (dp, antes de escalar) que debe quedar
  /// entre el botón y su panel. En los asientos cuyo ángulo cae cerca del
  /// eje horizontal de la elipse, el aporte vertical de [_dealerToward] y
  /// [_dealerSide] casi se cancelan entre sí (son casi opuestos) y el
  /// botón queda a la misma altura que el panel, pegado a un costado —
  /// ver [dealerButton]. No es un caso fijo por asiento: se detecta solo,
  /// midiendo el propio offset ya calculado, así que sigue valiendo si el
  /// día de mañana cambian los ángulos de [_angleDeg].
  static const double _dealerMinVerticalGap = 18;

  /// Empujón adicional (dp, antes de escalar) que se suma cuando el
  /// offset no alcanza [_dealerMinVerticalGap] — en la dirección "de
  /// costado" ([_tangent]) que apunte hacia arriba en pantalla para ESE
  /// asiento en particular (se elige solo mirando el signo de la
  /// componente vertical de [_tangent], no el número de asiento).
  static const double _dealerVerticalBoost = 40;

  /// Empujón extra, solo de costado ([_tangent]), para el botón del héroe
  /// (asiento 0): no necesita más separación vertical (ya tiene de
  /// sobra), solo una composición un poco más equilibrada corriéndolo
  /// levemente hacia la derecha.
  static const int _heroSlot = 0;
  static const double _dealerHeroExtraSide = 12;

  /// Única excepción puntual pedida para el asiento 2: un empujón extra,
  /// hacia el centro del paño ([inward], la misma dirección que ya usa el
  /// resto de la fórmula — no una coordenada de pantalla aparte), para
  /// separarlo un poco más de su panel. No toca ningún otro asiento.
  static const int _slot2 = 2;
  static const double _dealerSlot2Extra = 14;

  /// Botón de dealer: **derivado de [panel], nunca una coordenada
  /// independiente.** Es el panel del asiento con el botón, corrido hacia
  /// el centro del paño ([inward]) y de costado ([_tangent]) — misma
  /// fórmula base para los 6, sin coordenadas propias por asiento. Como
  /// [inward]/[_tangent] cambian de signo según el ángulo del asiento,
  /// esta única fórmula da sola la posición simétrica para asientos
  /// enfrentados: si el héroe (abajo) tiene el botón arriba-y-a-un-lado de
  /// su panel, el asiento de arriba lo tiene abajo-y-al-lado-opuesto del
  /// suyo — reflejo exacto respecto del centro de la mesa. Si el panel se
  /// mueve, el botón lo sigue solo (depende de él, no de coordenadas
  /// propias); si el botón cambia de asiento, esta misma cuenta ya da la
  /// posición correcta para el nuevo dueño.
  ///
  /// Tres refuerzos, los tres calculados a partir de los mismos vectores
  /// [inward]/[_tangent] (nunca una coordenada de pantalla aparte):
  /// [_dealerVerticalBoost] entra solo cuando el offset base no separa lo
  /// suficiente en altura (se detecta midiendo el propio offset, no
  /// comparando el número de asiento), [_dealerHeroExtraSide] es la
  /// excepción puntual del héroe, y [_dealerSlot2Extra] la única excepción
  /// puntual del asiento 2 — el resto de los asientos (1, 3, 4, 5) usan
  /// exclusivamente el offset base + [_dealerVerticalBoost] cuando
  /// corresponde, sin tocar.
  Offset dealerButton(int slot) {
    var offset = inward(slot) * (_dealerToward * scale) +
        _tangent(slot) * (_dealerSide * scale);

    final minGap = _dealerMinVerticalGap * scale;
    if (offset.dy.abs() < minGap) {
      final t = _tangent(slot);
      // El costado de [_tangent] que apunta hacia arriba en pantalla para
      // ESTE asiento (dy negativo) — puede ser +tangent o -tangent según
      // el ángulo, de ahí que no haya un signo fijo en el código.
      final up = t.dy < 0 ? t : -t;
      offset += up * (_dealerVerticalBoost * scale);
    }

    if (slot == _heroSlot) {
      offset += _tangent(slot) * (_dealerHeroExtraSide * scale);
    }

    if (slot == _slot2) {
      offset += inward(slot) * (_dealerSlot2Extra * scale);
    }

    return panel(slot) + offset;
  }

  /// Board arriba del centro y bote debajo del board — el orden real de
  /// una mesa de casino (antes estaba invertido) — afinado a mano.
  Offset get board => feltCentre.translate(0, feltRect.height * -0.33);
  Offset get pot => feltCentre.translate(0, feltRect.height * 0.07);
}
