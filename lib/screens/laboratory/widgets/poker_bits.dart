import 'package:flutter/material.dart';

import '../../../engine/poker/card.dart' as poker;
import '../../../engine/poker/hole_cards.dart';
import '../../../theme/app_colors.dart';

/// Una carta de póker chica para mostrar la mano del héroe.
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
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        card.pretty,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
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
        const SizedBox(width: 6),
        MiniCard(card: hand.low),
        const SizedBox(width: 10),
        Text(
          hand.notation,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Chip que muestra una etiqueta clave/valor (posición, stack, etc.).
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
