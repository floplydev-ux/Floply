import 'package:flutter/material.dart';

import '../../../../engine/pedagogy/table_lesson.dart';
import '../../../../theme/app_colors.dart';
import 'dealer_button.dart';
import 'playing_card.dart';
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

/// **El asiento completo: avatar + nombre + posición + stack + estado +
/// sus propias cartas privadas — una sola pieza, un solo componente.**
///
/// Fusiona a propósito lo que en otras mesas podría ser "PlayerPanel" +
/// "PlayerCards" separados: la mesa (`PokerTableView`/`TableLayout`) solo
/// sabe DÓNDE ESTÁ EL JUGADOR (`layout.panel(slot)`), nunca dónde están
/// sus cartas — separarlas en dos clases independientes obligaría a la
/// mesa a volver a calcular una coordenada de cartas por asiento, el
/// acoplamiento exacto que esta fusión evita. Ver [_cardsRise] más abajo:
/// el offset de las cartas es un número LOCAL a este widget, no una
/// coordenada de mesa.
///
/// Los 6 asientos (héroe incluido) se construyen llamando exactamente a
/// esta clase con los mismos parámetros; la única diferencia entre uno y
/// otro viene de los datos (`seat`) y de qué anchors le tocan a ESE
/// asiento en el sistema de resaltado (calculados por `PokerTableView`,
/// nunca aquí). No existe una versión distinta para el héroe: no hay
/// `_HeroPanel`, no hay `_HeroCards`, no hay parámetro `hero` que cambie
/// la estructura visual.
///
/// **Orden de pintado:** dentro del `Stack` de [build], las cartas van
/// PRIMERO y el panel DESPUÉS — así el panel tapa la mitad inferior de
/// las cartas, dando la sensación de que asoman desde atrás suyo.
///
/// **El botón de dealer NO vive acá** — es un elemento propio
/// ([DealerButton]), sobre el paño, que `PokerTableView` pinta aparte
/// (derivado de `TableLayout.dealerButton`, a su vez derivado de
/// `TableLayout.panel` para no tener coordenadas independientes) — así
/// queda claramente separado del panel en vez de leerse como parte suyo.
///
/// **Cartas: sólidas si el jugador sigue en la mano, invisibles si
/// foldeó.** Nunca hay un estado intermedio de opacidad: o se ven
/// completas, o no se construyen. Igual para el héroe que para cualquier
/// rival.
class PlayerSeat extends StatelessWidget {
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

  /// Cuánto asoman las cartas por ENCIMA del panel, en dp antes de
  /// escalar — el único número que hace falta tocar para cambiar esto en
  /// los 6 jugadores a la vez. [_cardsRiseRevealed] es un poco mayor
  /// porque la carta revelada es más grande.
  static const double _cardsRise = 20;
  static const double _cardsRiseRevealed = 26;

  /// Separación entre las dos cartas de la mano — ver [CardRow.gap].
  /// Negativo = superpuestas (la de atrás tapada en parte por la de
  /// encima); no afecta dónde queda el CENTRO del par, que [CardRow] ya
  /// arma centrado sobre sí mismo.
  static const double _cardsGap = -9;

  @override
  Widget build(BuildContext context) {
    final isWinner = seat.winner;
    // Los 6 paneles son la misma pieza: mismo tamaño de avatar para
    // héroe y rivales, sin excepción.
    final avatarSize = 25.0 * scale;
    final name = seat.name ?? (seat.isHero ? 'Vos' : seat.label);

    // Fondo del panel: SOLO dos estados posibles, los dos colores SÓLIDOS
    // (sin alfa, sin Opacity envolviendo el panel en ningún lado) —
    // depende EXCLUSIVAMENTE de si el jugador sigue en la mano
    // (seat.folded), nunca de si ganó ni de ningún resaltado de lección.
    // Ganador ya se lee por otro lado (borde, nombre, WinnerMark); acá
    // solo importa "¿sigue jugando esta mano o no?".
    final panelBg = seat.folded
        ? const Color(0xFF2C2E33) // gris sólido — fuera de la mano
        : const Color(0xFF0A0E14); // negro sólido — participando

    final panelBorder = seat.folded
        ? Colors.white.withValues(alpha: 0.05)
        : isWinner
            ? TableMaterial.success.withValues(alpha: 0.55)
            : seat.toAct
                ? TableMaterial.focus.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.08);

    final avatar = Container(
      width: avatarSize,
      height: avatarSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Mismo gris que panelBg (antes era un azulado propio, sin
        // relación con el nuevo gris del panel).
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
      // Mismo ícono para los 6 (antes el héroe tenía uno propio, distinto
      // del resto, con su propio color de contraste para el fondo dorado
      // que ya no existe).
      child: seat.folded
          ? Icon(Icons.close_rounded,
              size: avatarSize * 0.45, color: TableMaterial.textDim)
          : Icon(
              Icons.person_rounded,
              size: avatarSize * 0.55,
              color: Colors.white.withValues(alpha: 0.88),
            ),
    );

    // Mismo color de nombre para los 6 (antes el héroe tenía uno propio,
    // dorado, para hacer juego con su avatar dorado — que ya no existe).
    final nameColor = isWinner
        ? TableMaterial.success
        : seat.folded
            ? TableMaterial.textDim
            : TableMaterial.text;

    // Posición + stack en una sola línea de texto (sin Row anidado): un
    // Text.rich nunca desborda — si no entra, la elipsis se come el final,
    // nunca tira un RenderFlex overflow. Más robusto que un badge + texto
    // en dos widgets separados dentro de un espacio muy angosto.
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
      style: TextStyle(fontSize: 8.5 * scale),
    );

    final panelChrome = Container(
      // Mismo ancho máximo para los 6 (antes el héroe tenía una placa más
      // ancha que el resto).
      constraints: BoxConstraints(maxWidth: 128 * scale),
      padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 5 * scale),
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
          SizedBox(width: 6 * scale),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Misma tipografía para los 6 (antes el héroe tenía una
                  // fuente más grande que el resto).
                  style: TextStyle(
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                    color: nameColor,
                  ),
                ),
                SizedBox(height: 1 * scale),
                posStackLine,
              ],
            ),
          ),
          // La acción (SUBE/PAGA/FOLD/...) ya no se repite como etiqueta
          // en el panel: el fold se lee en el propio avatar (desaturado +
          // ✕) y una apuesta o subida ya se ve en la ficha junto al pozo
          // — el panel se mantiene limpio, solo identidad + stack.
          if (isWinner) ...[
            SizedBox(width: 4 * scale),
            WinnerMark(scale: scale),
          ],
        ],
      ),
    );

    // Sin Opacity acá: el panel es siempre 100% sólido — el halo de
    // Highlightable es un boxShadow (glow), no transparencia del panel.
    final panel = Highlightable(
      active: panelHighlighted,
      glow: glow,
      radius: 12,
      color: isWinner ? TableMaterial.success : TableMaterial.focus,
      child: panelChrome,
    );

    // Foldeado = sin cartas, sin estado intermedio: no hay dorso, no hay
    // opacidad reducida — directamente no se construye el bloque de
    // cartas. Igual para el héroe que para cualquier rival.
    if (seat.cards.isEmpty || seat.folded) return panel;

    final revealed = _isRevealed(seat);
    final rise = (revealed ? _cardsRiseRevealed : _cardsRise) * scale;
    final cards = Positioned.fill(
      // Ancladas a un offset LOCAL fijo respecto de este mismo panel
      // (centradas horizontalmente vía Align, así no hace falta saber el
      // ancho real del panel — que varía según el nombre — para
      // mantenerlas centradas).
      child: Align(
        alignment: Alignment.topCenter,
        child: Transform.translate(
          offset: Offset(0, -rise),
          // Sin Opacity acá: si el jugador sigue en la mano sus cartas
          // son siempre 100% sólidas — el halo de Highlightable es un
          // boxShadow (glow), no transparencia.
          child: Highlightable(
            active: cardsHighlighted,
            glow: glow,
            radius: 10,
            color: TableMaterial.focus,
            // La key de test del héroe vive ACÁ, en el asiento héroe — no
            // porque el héroe tenga un componente propio, sino porque el
            // test necesita encontrar SUS cartas puntuales.
            child: KeyedSubtree(
              key: seat.isHero ? kAcademyTableHeroCardsKey : null,
              child: CardRow(
                codes: seat.cards,
                small: !revealed,
                hero: seat.isHero,
                scale: scale,
                gap: _cardsGap,
                glowIndices: cardGlowIndices,
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1 — cartas, DETRÁS: como si asomaran desde atrás del panel.
        cards,
        // 2 — panel, DELANTE: tapa la mitad inferior de las cartas.
        panel,
      ],
    );
  }
}
