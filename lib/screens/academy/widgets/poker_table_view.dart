import 'package:flutter/material.dart';

import '../../../engine/pedagogy/table_lesson.dart';
import '../../../engine/poker/card.dart' as poker;
import '../../../theme/app_colors.dart';

/// Geometría de la mesa: dónde cae cada asiento, el bote, el board y los
/// puntos a los que apunta una burbuja. Todo en coordenadas del [Stack]
/// que dibuja la mesa (mismo espacio para mesa y burbujas).
class TableLayout {
  const TableLayout(this.size);

  final Size size;

  /// Centro de cada slot (0..5) como fracción del área.
  static const List<Offset> _seatFrac = [
    Offset(0.50, 0.885), // 0 héroe, abajo centro
    Offset(0.135, 0.70), // 1 abajo izquierda
    Offset(0.135, 0.30), // 2 arriba izquierda
    Offset(0.50, 0.11), //  3 arriba centro
    Offset(0.865, 0.30), // 4 arriba derecha
    Offset(0.865, 0.70), // 5 abajo derecha
  ];

  Offset seat(int slot) => Offset(
        _seatFrac[slot].dx * size.width,
        _seatFrac[slot].dy * size.height,
      );

  Offset get pot => Offset(0.50 * size.width, 0.57 * size.height);
  Offset get board => Offset(0.50 * size.width, 0.44 * size.height);
  Offset get heroCards => Offset(0.50 * size.width, 0.80 * size.height);

  /// Fichas apostadas de un slot: entre el asiento y el bote.
  Offset bet(int slot) => Offset.lerp(seat(slot), pot, 0.42)!;

  /// Botón del dealer: al lado del asiento, hacia el centro.
  Offset button(int slot) => Offset.lerp(seat(slot), Offset(size.width / 2, size.height / 2), 0.22)!;

  Offset anchorPoint(TableAnchor a) {
    switch (a.kind) {
      case TableAnchorKind.seat:
        return seat(a.slot);
      case TableAnchorKind.bet:
        return bet(a.slot);
      case TableAnchorKind.pot:
        return pot;
      case TableAnchorKind.board:
        return board;
      case TableAnchorKind.heroCards:
        return heroCards;
    }
  }
}

/// La mesa de póker interactiva. Dibuja el paño, los asientos, las cartas,
/// las fichas, el botón y el bote a partir de un [TableSnapshot], y resalta
/// los elementos indicados.
class PokerTableView extends StatelessWidget {
  const PokerTableView({
    super.key,
    required this.snapshot,
    this.highlight = const {},
    this.dimOthers = false,
    this.glow = 1,
  });

  final TableSnapshot snapshot;
  final Set<TableAnchor> highlight;
  final bool dimOthers;

  /// 0..1, para el latido del resaltado.
  final double glow;

  bool _isHi(TableAnchor a) => highlight.contains(a);

  double _opacityFor(TableAnchor a) {
    if (!dimOthers) return 1;
    return _isHi(a) ? 1 : 0.32;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final layout = TableLayout(size);

      return SizedBox.fromSize(
        size: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: CustomPaint(painter: _FeltPainter())),

            // Board (cartas comunitarias)
            if (snapshot.board.isNotEmpty)
              _centered(
                layout.board,
                Opacity(
                  opacity: _opacityFor(TableAnchor.board),
                  child: _Highlightable(
                    active: _isHi(TableAnchor.board),
                    glow: glow,
                    radius: 14,
                    child: _CardRow(codes: snapshot.board, small: true),
                  ),
                ),
              ),

            // Bote
            _centered(
              layout.pot,
              Opacity(
                opacity: _opacityFor(TableAnchor.pot),
                child: _Highlightable(
                  active: _isHi(TableAnchor.pot),
                  glow: glow,
                  radius: 16,
                  child: _PotPill(bb: snapshot.potBb),
                ),
              ),
            ),

            // Fichas apostadas
            for (final s in snapshot.seats)
              if (!s.empty && s.betBb > 0)
                _centered(
                  layout.bet(s.slot),
                  Opacity(
                    opacity: _opacityFor(TableAnchor.bet(s.slot)),
                    child: _Highlightable(
                      active: _isHi(TableAnchor.bet(s.slot)),
                      glow: glow,
                      radius: 14,
                      child: _BetChips(bb: s.betBb),
                    ),
                  ),
                ),

            // Botón del dealer
            _centered(layout.button(snapshot.buttonSlot), const _DealerButton()),

            // Asientos
            for (final s in snapshot.seats)
              if (!s.empty)
                _centered(
                  layout.seat(s.slot),
                  Opacity(
                    opacity: _opacityFor(TableAnchor.seat(s.slot)),
                    child: _SeatView(
                      seat: s,
                      highlighted: _isHi(TableAnchor.seat(s.slot)),
                      heroCardsHighlighted:
                          s.isHero && _isHi(TableAnchor.heroCards),
                      glow: glow,
                    ),
                  ),
                ),
          ],
        ),
      );
    });
  }

  Widget _centered(Offset c, Widget child) {
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
    final rail = Rect.fromLTWH(
      size.width * 0.02,
      size.height * 0.05,
      size.width * 0.96,
      size.height * 0.90,
    );
    final railRRect =
        RRect.fromRectAndRadius(rail, Radius.circular(size.width * 0.5));

    // Riel (madera)
    canvas.drawRRect(
      railRRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF3A2A1E), Color(0xFF23160E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rail),
    );

    // Paño (verde)
    final feltRect = rail.deflate(size.width * 0.045);
    final feltRRect =
        RRect.fromRectAndRadius(feltRect, Radius.circular(size.width * 0.5));
    canvas.drawRRect(
      feltRRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 0.9,
          colors: [Color(0xFF1F6F4A), Color(0xFF0E3C28)],
        ).createShader(feltRect),
    );

    // Línea interior sutil
    canvas.drawRRect(
      feltRRect.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant _FeltPainter oldDelegate) => false;
}

// ===================================================================
// Asiento
// ===================================================================

class _SeatView extends StatelessWidget {
  const _SeatView({
    required this.seat,
    required this.highlighted,
    required this.heroCardsHighlighted,
    required this.glow,
  });

  final SeatState seat;
  final bool highlighted;
  final bool heroCardsHighlighted;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final accent =
        seat.isHero ? AppColors.neonGreenBright : AppColors.violetBright;
    final dim = seat.folded;
    final displayName = seat.name ?? (seat.isHero ? 'Vos' : seat.label);

    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (seat.action != null)
            _ActionTag(label: seat.action!, folded: seat.folded),
          if (seat.action != null) const SizedBox(height: 3),
          // Cartas
          if (seat.cards.isNotEmpty)
            _Highlightable(
              active: heroCardsHighlighted,
              glow: glow,
              radius: 10,
              child: _CardRow(
                codes: seat.cards,
                small: !seat.isHero,
              ),
            ),
          if (seat.cards.isNotEmpty) const SizedBox(height: 3),
          // Avatar
          _Highlightable(
            active: highlighted,
            glow: glow,
            radius: 22,
            child: Container(
              width: seat.isHero ? 34 : 28,
              height: seat.isHero ? 34 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _avatarColors(seat),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: seat.toAct ? accent : AppColors.surfaceBorder,
                  width: seat.toAct ? 2 : 1,
                ),
              ),
              child: Icon(
                seat.isHero ? Icons.person_rounded : Icons.face_rounded,
                size: seat.isHero ? 18 : 15,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Etiqueta: nombre + posición · stack
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: highlighted
                    ? accent.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: highlighted ? accent : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${seat.label} · ${_fmt(seat.stackBb)}bb',
                  style: const TextStyle(
                    fontSize: 8,
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

  /// Color del avatar: el usuario en verde; cada personaje NPC con su
  /// propio color estable (por `avatarId`).
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
}

class _ActionTag extends StatelessWidget {
  const _ActionTag({required this.label, required this.folded});

  final String label;
  final bool folded;

  @override
  Widget build(BuildContext context) {
    final Color c = folded
        ? AppColors.textMuted
        : (label == 'SUBE' || label == 'PAGA')
            ? AppColors.neonGreenBright
            : AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: c,
        ),
      ),
    );
  }
}

// ===================================================================
// Resaltado (halo)
// ===================================================================

class _Highlightable extends StatelessWidget {
  const _Highlightable({
    required this.child,
    required this.active,
    required this.glow,
    this.radius = 12,
  });

  final Widget child;
  final bool active;
  final double glow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetBright.withValues(alpha: 0.35 + 0.35 * glow),
            blurRadius: 10 + 10 * glow,
            spreadRadius: 1 + 2 * glow,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ===================================================================
// Cartas
// ===================================================================

class _CardRow extends StatelessWidget {
  const _CardRow({required this.codes, this.small = false});

  final List<String> codes;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < codes.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
            child: _PlayingCard(code: codes[i], small: small),
          ),
      ],
    );
  }
}

class _PlayingCard extends StatelessWidget {
  const _PlayingCard({required this.code, required this.small});

  final String code;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final w = small ? 20.0 : 26.0;
    final h = small ? 28.0 : 37.0;

    if (code == '?' || code.length != 2) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: const LinearGradient(
            colors: [Color(0xFF3B2A78), Color(0xFF221653)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
      );
    }

    final card = poker.Card.parse(code);
    final red =
        card.suit == poker.Suit.hearts || card.suit == poker.Suit.diamonds;
    final color = red ? const Color(0xFFE23D4C) : const Color(0xFF1A1A22);

    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rank.letter,
            style: TextStyle(
              fontSize: small ? 11 : 14,
              height: 1,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              fontSize: small ? 9 : 11,
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
  const _PotPill({required this.bb});

  final double bb;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        'BOTE ${_fmt(bb)} BB',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _BetChips extends StatelessWidget {
  const _BetChips({required this.bb});

  final double bb;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 12,
          width: 22,
          child: Stack(
            children: [
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: i * 4.0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [
                        AppColors.violetPrimary,
                        AppColors.diamondBlue,
                        AppColors.gold,
                      ][i],
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _fmt(bb),
            style: const TextStyle(
              fontSize: 8.5,
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
  const _DealerButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Text(
        'D',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
