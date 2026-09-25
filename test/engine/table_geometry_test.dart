import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/screens/academy/widgets/poker_table_view.dart';

/// Geometría: confirma que el recorrido real de la partida (BTN → SB → BB
/// → UTG → HJ → CO, ver [TablePositions]) traza un arco **horario** en
/// pantalla con la distribución de [TableLayout] — la regla no negociable
/// de la sección "sentido horario".
void main() {
  double angleOf(Offset v) => math.atan2(v.dy, v.dx);

  /// Normaliza una diferencia de ángulos a (-π, π].
  double normalize(double a) {
    var r = a;
    while (r <= -math.pi) {
      r += 2 * math.pi;
    }
    while (r > math.pi) {
      r -= 2 * math.pi;
    }
    return r;
  }

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    test(
        'el recorrido BTN→SB→BB→UTG→HJ→CO gira horario en pantalla '
        '(${size.width.toInt()}×${size.height.toInt()}), '
        'para cualquier buttonSlot', () {
      final layout = TableLayout(size);
      final centre = layout.feltCentre;

      for (var btn = 0; btn < 6; btn++) {
        final positions = TablePositions(btn);
        final order = positions.order(Street.flop);
        expect(order.length, 6);

        double totalTurn = 0;
        for (var i = 0; i < order.length; i++) {
          final a = layout.seat(order[i]) - centre;
          final b = layout.seat(order[(i + 1) % order.length]) - centre;
          final delta = normalize(angleOf(b) - angleOf(a));
          expect(
            delta,
            greaterThan(0),
            reason: 'btn=$btn, paso ${positions.positionOf(order[i]).label} '
                '→ ${positions.positionOf(order[(i + 1) % order.length]).label} '
                'debería girar en sentido horario en pantalla',
          );
          totalTurn += delta;
        }
        // Una vuelta completa: los 6 pasos suman exactamente 360°.
        expect(totalTurn, closeTo(2 * math.pi, 1e-6), reason: 'btn=$btn');
      }
    });

    test(
        'el héroe (slot 0) permanece abajo-centro '
        '(${size.width.toInt()}×${size.height.toInt()})', () {
      final layout = TableLayout(size);
      final heroOffset = layout.seat(0) - layout.feltCentre;
      // Abajo: dy > 0. Centrado: dx despreciable frente al radio.
      expect(heroOffset.dy, greaterThan(0));
      expect(heroOffset.dx.abs(), lessThan(heroOffset.dy.abs() * 0.05));
    });
  }
}
