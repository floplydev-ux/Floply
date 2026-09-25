import 'package:flutter/material.dart';

import '../../../engine/poker/card.dart' as poker;
import '../../../engine/poker/hole_cards.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';

/// Una carta de póker chica para mostrar la mano del héroe.
///
/// **Fase 7**: cara de carta real (blanco/tinta), deliberadamente sin
/// re-tematizar a un color Sala Verde — es una carta física, como las de
/// `PokerTableView`, no una superficie de UI.
class MiniCard extends StatelessWidget {
  const MiniCard({super.key, required this.card});

  final poker.Card card;

  bool get _isRed =>
      card.suit == poker.Suit.hearts || card.suit == poker.Suit.diamonds;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: SalaVerdeElevation.level1,
      ),
      child: Text(
        card.pretty,
        style: SalaVerdeType.numeric(
          size: 16,
          color: _isRed ? const Color(0xFFD1345B) : Colors.black87,
        ),
      ),
    );
  }
}

/// La mano del héroe: dos [MiniCard] + notación.
class HeroHandView extends StatelessWidget {
  const HeroHandView({super.key, required this.hand});

  final HoleCards hand;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiniCard(card: hand.high),
        const SizedBox(width: SalaVerdeSpace.xs + 2),
        MiniCard(card: hand.low),
        const SizedBox(width: SalaVerdeSpace.sm + 2),
        Text(
          hand.notation,
          style: SalaVerdeType.bodyStrong(color: SalaVerdeColors.textMuted),
        ),
      ],
    );
  }
}
