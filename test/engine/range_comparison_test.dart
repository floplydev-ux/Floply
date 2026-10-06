import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/strategy/hand_range.dart';
import 'package:poker_trainer/engine/strategy/range_comparison.dart';

void main() {
  test('detecta manos agregadas, quitadas y con frecuencia distinta', () {
    final a = HandRange.parse(['AA', 'KK', 'AKs(0.5)']);
    final b = HandRange.parse(['AA', 'QQ', 'AKs']);

    final comparison = RangeComparison.compute(a, b);

    expect(comparison.addedCount, 1); // QQ
    expect(comparison.removedCount, 1); // KK
    expect(comparison.changedCount, 1); // AKs 0.5 -> 1.0

    expect(comparison.added.single.notation, 'QQ');
    expect(comparison.removed.single.notation, 'KK');
    expect(comparison.changed.single.notation, 'AKs');
  });

  test('una mano en ambos rangos con la misma frecuencia no cuenta como diff', () {
    final a = HandRange.parse(['AA']);
    final b = HandRange.parse(['AA']);
    final comparison = RangeComparison.compute(a, b);

    expect(comparison.addedCount, 0);
    expect(comparison.removedCount, 0);
    expect(comparison.changedCount, 0);
    expect(comparison.diffOf('AA')!.isUnchanged, isTrue);
  });

  test('comparar contra un rango vacío marca todo como agregado', () {
    final a = HandRange.empty();
    final b = HandRange.parse(['AA', 'KK']);
    final comparison = RangeComparison.compute(a, b);

    expect(comparison.addedCount, 2);
    expect(comparison.removedCount, 0);
  });

  test('diffOf devuelve null para una notación fuera de las 169 clases', () {
    final comparison = RangeComparison.compute(HandRange.empty(), HandRange.empty());
    expect(comparison.diffOf('XX'), isNull);
  });
}
