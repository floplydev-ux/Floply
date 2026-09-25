import 'package:flutter/material.dart';

import 'playing_card.dart';
import 'table_layout.dart';

/// Zona del board: una sola caja con las comunitarias, separación pareja.
class CommunityCards extends StatelessWidget {
  const CommunityCards({
    super.key,
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
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CardRow(
          key: kAcademyTableBoardKey,
          codes: codes,
          small: true,
          scale: scale,
          gap: 4,
          glowIndices: glowIndices,
        ),
      ),
    );
  }
}
