import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../engine/pedagogy/table_lesson.dart';
import '../../../engine/poker/card.dart' as poker;
import '../../../theme/app_colors.dart';

/// Claves de test: las cartas del héroe y el board — los tests comprueban
/// que estén siempre visibles en pantalla.
const Key kAcademyTableHeroCardsKey = Key('academy.table.heroCards');
const Key kAcademyTableBoardKey = Key('academy.table.board');

/// Geometría de la mesa.
///
/// **Regla única:** el paño ([feltRect], una elipse) es el sistema de
/// coordenadas. El avatar de cada asiento va *sobre el perímetro* de la
/// elipse (mitad riel / mitad verde). Todo lo demás —plaquita, cartas,
/// fichas, dealer, mano del héroe, board, bote— se ubica interpolando
/// desde el asiento hacia el centro del paño ([_toward]); como la elipse
/// es convexa, con `t > 0` el punto cae **siempre dentro del verde**. Los
/// elementos con tamaño propio además se recortan al rectángulo inscrito
/// ([_clamp]).
class TableLayout {
  TableLayout(this.size)
      : scale = (size.width / _referenceWidth).clamp(_minScale, 1.0);

  final Size size;

  /// Escala suave de avatares / cartas / tipografías.
  final double scale;

  static const double _referenceWidth = 384;
  static const double _minScale = 0.82;

  /// Alto del paño (riel incluido) como fracción del área. Casi toda: la
  /// mano del héroe vive *dentro* del verde, no en una franja aparte.
  static const double feltHeightFrac = 0.94;

  /// Ángulo de cada asiento sobre la elipse (0°=derecha, 90°=abajo). Héroe
  /// abajo; los otros cinco en arco sobre el paño, simétrico.
  static const List<double> _angleDeg = [90, 148, 205, 270, 335, 32];

  /// Paño (verde). Riel fino alrededor.
  Rect get feltRect {
    final railX = size.width * 0.028;
    final railY = size.height * 0.02;
    return Rect.fromLTWH(
      railX,
      railY,
      size.width - 2 * railX,
      size.height * feltHeightFrac - 2 * railY,
    );
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

  Offset _toward(int slot, double t) =>
      Offset.lerp(seat(slot), feltCentre, t)!;

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

  /// Vector unitario asiento → centro (hacia dónde asoman las cartas).
  Offset inward(int slot) {
    final v = feltCentre - seat(slot);
    final d = v.distance;
    return d == 0 ? const Offset(0, -1) : v / d;
  }

  Offset plate(int slot) => _toward(slot, slot == 0 ? 0.17 : 0.085);
  Offset pocketCards(int slot, {bool out = false}) =>
      _toward(slot, out ? 0.27 : 0.14);
  Offset bet(int slot) => _toward(slot, 0.47);
  Offset button(int slot) => _toward(slot, slot == 0 ? 0.10 : 0.13);
  Offset get heroHand => _toward(0, 0.40);
  Offset get board => feltCentre.translate(0, feltRect.height * 0.03);
  Offset get pot => feltCentre.translate(0, -feltRect.height * 0.14);
}

/// La mesa de póker interactiva. Dibuja el paño, los pods, las cartas, las
/// fichas, el botón y el bote a partir de un [TableSnapshot], y resalta los
/// elementos indicados. La misma instancia permanece montada toda la
/// lección: sólo cambian el snapshot y el foco.
class PokerTableView extends StatelessWidget {
  const PokerTableView({
    super.key,
    required this.snapshot,
    this.highlight = const {},
    this.dimOthers = false,
    this.glow = 1,
    this.cardGlow = const {},
  });

  final TableSnapshot snapshot;
  final Set<TableAnchor> highlight;
  final bool dimOthers;

  /// 0..1, para el latido del resaltado.
  final double glow;

  /// Cartas puntuales a resaltar de forma individual (además del resaltado
  /// de zona de [highlight]). Vacío por defecto: no cambia nada para los
  /// guiones existentes. Pensado para el piloto visual (p. ej. señalar un
  /// out concreto en el board).
  final Set<CardRef> cardGlow;

  Set<int> _cardGlowIndices(CardSource source, {int slot = -1}) => {
        for (final r in cardGlow)
          if (r.source == source && (source != CardSource.seat || r.slot == slot))
            r.index,
      };

  bool _isHi(TableAnchor a) => highlight.contains(a);

  /// Atenuación del elemento no enfocado. El foco ya destaca con halo +
  /// escala, así que la atenuación es suave (0.5) y **nunca** toca el
  /// contexto que hay que poder comparar: board, bote y cualquier asiento
  /// con cartas reveladas.
  double _opacityFor(TableAnchor a, {bool context = false}) {
    if (!dimOthers || _isHi(a)) return 1;
    return context ? 0.85 : 0.5;
  }

  static bool _revealed(SeatState s) =>
      s.cards.length == 2 && !s.cards.contains('?');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final layout = TableLayout(size);
      final s = layout.scale;
      final opp = [
        for (final seat in snapshot.seats)
          if (!seat.empty && !seat.isHero) seat
      ];
      final hero = snapshot.hero;

      Widget dim(TableAnchor a, Widget child, {bool context = false}) =>
          Opacity(opacity: _opacityFor(a, context: context), child: child);

      return SizedBox.fromSize(
        size: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: CustomPaint(painter: _FeltPainter())),

            // --- Bote (rótulo, arriba del paño) ---
            _pin(
              layout.clampInFelt(layout.pot, Size(78 * s, 20 * s)),
              dim(
                TableAnchor.pot,
                _Highlightable(
                  active: _isHi(TableAnchor.pot),
                  glow: glow,
                  radius: 16,
                  child: _PotPill(bb: snapshot.potBb, scale: s),
                ),
                context: true,
              ),
            ),

            // --- Board: zona central única, recortada al verde ---
            if (snapshot.board.isNotEmpty)
              _pin(
                layout.clampInFelt(
                  layout.board,
                  Size(snapshot.board.length * 24.0 * s + 16, 40 * s),
                ),
                dim(
                  TableAnchor.board,
                  _Highlightable(
                    active: _isHi(TableAnchor.board),
                    glow: glow,
                    radius: 12,
                    child: _BoardZone(
                      codes: snapshot.board,
                      scale: s,
                      glowIndices: _cardGlowIndices(CardSource.board),
                    ),
                  ),
                  context: true,
                ),
              ),

            // --- Fichas apostadas: en la línea jugador → centro ---
            for (final seat in snapshot.seats)
              if (!seat.empty && seat.betBb > 0)
                _pin(
                  layout.bet(seat.slot),
                  dim(
                    TableAnchor.bet(seat.slot),
                    _Highlightable(
                      active: _isHi(TableAnchor.bet(seat.slot)),
                      glow: glow,
                      radius: 12,
                      child: _BetChips(bb: seat.betBb, scale: s),
                    ),
                  ),
                ),

            // --- Cartas privadas de los oponentes (asoman hacia el centro) ---
            for (final seat in opp)
              if (seat.cards.isNotEmpty)
                _pin(
                  layout.clampInFelt(
                    layout.pocketCards(seat.slot, out: _revealed(seat)),
                    Size(_revealed(seat) ? 54 * s : 34 * s,
                        _revealed(seat) ? 36 * s : 24 * s),
                  ),
                  dim(
                    TableAnchor.seat(seat.slot),
                    _CardRow(
                      codes: seat.cards,
                      small: !_revealed(seat),
                      scale: s,
                      glowIndices:
                          _cardGlowIndices(CardSource.seat, slot: seat.slot),
                    ),
                    context: _revealed(seat),
                  ),
                ),

            // --- Plaquitas: posición + nombre + stack, apenas dentro ---
            for (final seat in snapshot.seats)
              if (!seat.empty)
                _pin(
                  layout.plate(seat.slot),
                  dim(
                    TableAnchor.seat(seat.slot),
                    _PlateStack(
                      seat: seat,
                      highlighted: _isHi(TableAnchor.seat(seat.slot)),
                      scale: s,
                    ),
                    context: _revealed(seat),
                  ),
                ),

            // --- Avatares: sobre el perímetro del paño ---
            for (final seat in snapshot.seats)
              if (!seat.empty)
                _pin(
                  layout.seat(seat.slot),
                  dim(
                    TableAnchor.seat(seat.slot),
                    _AvatarPod(
                      seat: seat,
                      highlighted: _isHi(TableAnchor.seat(seat.slot)),
                      glow: glow,
                      scale: s,
                    ),
                    context: _revealed(seat),
                  ),
                ),

            // --- Dealer button: dentro del verde, junto a su dueño ---
            _pin(
              layout.button(snapshot.buttonSlot),
              _DealerButton(scale: s),
            ),

            // --- Mano del héroe: grande, sobre el verde, encima de todo ---
            if (hero.cards.isNotEmpty)
              _pin(
                layout.clampInFelt(layout.heroHand, Size(72 * s, 46 * s)),
                _Highlightable(
                  active: _isHi(TableAnchor.heroCards),
                  glow: glow,
                  radius: 10,
                  color: AppColors.neonGreenBright,
                  child: KeyedSubtree(
                    key: kAcademyTableHeroCardsKey,
                    child: _CardRow(
                      codes: hero.cards,
                      hero: true,
                      scale: s,
                      glowIndices: _cardGlowIndices(CardSource.hero),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Coloca [child] centrado en la coordenada [c].
  Widget _pin(Offset c, Widget child) {
    return Positioned(
      left: c.dx,
      top: c.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: child,
      ),
    );
  }
}

// ===================================================================
// Paño
// ===================================================================

class _FeltPainter extends CustomPainter {
  const _FeltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final felt = TableLayout(size).feltRect;
    // Riel (madera) rodeando el paño, dentro del área.
    final rail = Rect.fromLTRB(
      size.width * 0.006,
      size.height * 0.006,
      size.width * 0.994,
      felt.bottom + size.height * 0.024,
    );
    final railR = Radius.circular(rail.shortestSide * 0.42);
    final feltR = Radius.circular(felt.shortestSide * 0.40);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rail, railR),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF3A2A1E), Color(0xFF23160E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rail),
    );

    // Paño (verde) con viñeta: centro más claro.
    canvas.drawRRect(
      RRect.fromRectAndRadius(felt, feltR),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.12),
          radius: 0.95,
          colors: [Color(0xFF20724D), Color(0xFF0D3826)],
        ).createShader(felt),
    );

    // Línea interior sutil.
    canvas.drawRRect(
      RRect.fromRectAndRadius(felt.deflate(2), feltR),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant _FeltPainter oldDelegate) => false;
}

// ===================================================================
// Avatar (montado en el perímetro) + acción
// ===================================================================

List<Color> _avatarColors(SeatState seat) {
  if (seat.isHero) {
    return [AppColors.neonGreen, AppColors.neonGreenDeep];
  }
  const palette = <List<Color>>[
    [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
    [Color(0xFF4FD1FF), Color(0xFF0E5A80)],
    [Color(0xFFFFC94A), Color(0xFF8A6400)],
    [Color(0xFFFF7A9C), Color(0xFF8A2C46)],
    [Color(0xFF34D399), Color(0xFF065F46)],
    [Color(0xFFA78BFA), Color(0xFF5B21B6)],
    [Color(0xFFFB923C), Color(0xFF9A3412)],
    [Color(0xFF60A5FA), Color(0xFF1E40AF)],
    [Color(0xFFF472B6), Color(0xFF9D174D)],
    [Color(0xFF2DD4BF), Color(0xFF115E59)],
  ];
  final id = (seat.avatarId ?? seat.slot) % palette.length;
  return palette[id.abs()];
}

class _AvatarPod extends StatelessWidget {
  const _AvatarPod({
    required this.seat,
    required this.highlighted,
    required this.glow,
    required this.scale,
  });

  final SeatState seat;
  final bool highlighted;
  final double glow;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final accent =
        seat.isHero ? AppColors.neonGreenBright : AppColors.violetBright;
    final sz = (seat.isHero ? 32.0 : 29.0) * scale;

    final avatar = Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _avatarColors(seat),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: seat.toAct ? accent : Colors.white.withValues(alpha: 0.24),
          width: seat.toAct ? 2.4 : 1.3,
        ),
        boxShadow: seat.toAct
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.55),
                  blurRadius: 9,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Icon(
        seat.isHero ? Icons.person_rounded : Icons.face_rounded,
        size: sz * 0.56,
        color: Colors.white.withValues(alpha: 0.92),
      ),
    );

    return Opacity(
      opacity: seat.folded ? 0.42 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _Highlightable(
            active: highlighted,
            glow: glow,
            radius: 20,
            color: accent,
            child: avatar,
          ),
          if (seat.action != null)
            Positioned(
              top: -12 * scale,
              child: _ActionTag(
                  label: seat.action!, folded: seat.folded, scale: scale),
            ),
        ],
      ),
    );
  }
}

// ===================================================================
// Plaquita: posición + nombre + stack (apenas dentro del verde)
// ===================================================================

class _PlateStack extends StatelessWidget {
  const _PlateStack({
    required this.seat,
    required this.highlighted,
    required this.scale,
  });

  final SeatState seat;
  final bool highlighted;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final accent =
        seat.isHero ? AppColors.neonGreenBright : AppColors.violetBright;
    final name = seat.name ?? (seat.isHero ? 'Vos' : seat.label);

    return Opacity(
      opacity: seat.folded ? 0.5 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (seat.label.isNotEmpty) ...[
            _PositionPill(label: seat.label, scale: scale),
            SizedBox(height: 2 * scale),
          ],
          Container(
            constraints: BoxConstraints(maxWidth: 100 * scale),
            padding: EdgeInsets.symmetric(
                horizontal: 7 * scale, vertical: 3 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1C).withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: highlighted
                    ? accent.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: highlighted ? accent : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_fmt(seat.stackBb)} BB',
                  style: TextStyle(
                    fontSize: 9 * scale,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de posición (UTG / HJ / CO / BTN / SB / BB).
class _PositionPill extends StatelessWidget {
  const _PositionPill({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    final c = switch (label) {
      'BTN' => AppColors.gold,
      'SB' || 'BB' => AppColors.diamondBlue,
      _ => AppColors.violetSoft,
    };
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 1.0 * scale),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: c,
        ),
      ),
    );
  }
}

class _ActionTag extends StatelessWidget {
  const _ActionTag({
    required this.label,
    required this.folded,
    required this.scale,
  });

  final String label;
  final bool folded;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final Color c = folded
        ? AppColors.textMuted
        : (label == 'SUBE' || label == 'PAGA')
            ? AppColors.neonGreenBright
            : AppColors.gold;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 1.5 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF12162A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 8 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: c,
        ),
      ),
    );
  }
}

// ===================================================================
// Resaltado (halo + pulso de escala)
// ===================================================================

class _Highlightable extends StatelessWidget {
  const _Highlightable({
    required this.child,
    required this.active,
    required this.glow,
    this.radius = 12,
    this.color = AppColors.violetBright,
  });

  final Widget child;
  final bool active;
  final double glow;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final pulse = glow.clamp(0.0, 1.0);
    return Transform.scale(
      scale: 1 + 0.06 * pulse,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.30 + 0.45 * pulse),
              blurRadius: 12 + 14 * pulse,
              spreadRadius: 1 + 3 * pulse,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ===================================================================
// Cartas
// ===================================================================

/// Zona del board: una sola caja con las comunitarias, separación pareja.
class _BoardZone extends StatelessWidget {
  const _BoardZone({
    required this.codes,
    required this.scale,
    this.glowIndices = const {},
  });

  final List<String> codes;
  final double scale;
  final Set<int> glowIndices;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: Container(
        padding: EdgeInsets.all(5 * scale),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _CardRow(
          key: kAcademyTableBoardKey,
          codes: codes,
          small: true,
          scale: scale,
          gap: 3.5,
          glowIndices: glowIndices,
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
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
  final double gap;

  /// Índices (dentro de [codes]) que deben resaltarse individualmente.
  final Set<int> glowIndices;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < codes.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : gap * scale),
            child: _PlayingCard(
              code: codes[i],
              small: small,
              hero: hero,
              scale: scale,
              glow: glowIndices.contains(i),
            ),
          ),
      ],
    );
  }
}

class _PlayingCard extends StatelessWidget {
  const _PlayingCard({
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

    // Tamaños: héroe grande (su mano), oponente/board chico, dorso algo
    // menor que la cara.
    final double baseW = hero
        ? 30
        : small
            ? 21
            : 24;
    final double baseH = hero
        ? 42
        : small
            ? 29
            : 34;
    final w = (faceDown ? baseW * 0.82 : baseW) * scale;
    final h = (faceDown ? baseH * 0.9 : baseH) * scale;

    if (faceDown) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: const LinearGradient(
            colors: [Color(0xFF3A2C6E), Color(0xFF231A4E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Center(
          child: Container(
            width: w * 0.44,
            height: h * 0.44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
      );
    }

    final card = poker.Card.parse(code);
    final red =
        card.suit == poker.Suit.hearts || card.suit == poker.Suit.diamonds;
    final color = red ? const Color(0xFFD3283A) : const Color(0xFF17171F);

    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
        border: Border.all(
          color: glow
              ? AppColors.neonGreenBright
              : Colors.black.withValues(alpha: 0.18),
          width: glow ? 2.2 : 1,
        ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: AppColors.neonGreenBright.withValues(alpha: 0.65),
              blurRadius: 10,
              spreadRadius: 1.5,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rank.letter,
            style: TextStyle(
              fontSize: (hero ? 17.0 : (small ? 12.0 : 14.0)) * scale,
              height: 1,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              fontSize: (hero ? 13.0 : (small ? 10.0 : 11.0)) * scale,
              height: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// Bote / fichas / botón
// ===================================================================

class _PotPill extends StatelessWidget {
  const _PotPill({required this.bb, this.scale = 1});

  final double bb;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 11 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BOTE ',
            style: TextStyle(
              fontSize: 9 * scale,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            '${_fmt(bb)} BB',
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BetChips extends StatelessWidget {
  const _BetChips({required this.bb, this.scale = 1});

  final double bb;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 13 * scale,
          width: 17 * scale,
          child: Stack(
            children: [
              for (var i = 0; i < 2; i++)
                Positioned(
                  left: i * 5.0 * scale,
                  top: i * 1.5 * scale,
                  child: Container(
                    width: 12 * scale,
                    height: 12 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const [
                        AppColors.diamondBlue,
                        AppColors.gold,
                      ][i],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 3 * scale),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: 4 * scale, vertical: 1 * scale),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${_fmt(bb)} BB',
            style: TextStyle(
              fontSize: 8.5 * scale,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DealerButton extends StatelessWidget {
  const _DealerButton({this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18 * scale,
      height: 18 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFDC7A), Color(0xFFDFA43C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        'D',
        style: TextStyle(
          fontSize: 10 * scale,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF3A2A00),
        ),
      ),
    );
  }
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
