import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/sizing/bet_sizing_engine.dart';

void main() {
  group('BetSizingEngine.potSizedBet', () {
    test('pot-sized bet (fraction 1.0) == el bote', () {
      expect(BetSizingEngine.potSizedBet(10, fraction: 1.0), 10.0);
    });

    test('half-pot bet', () {
      expect(BetSizingEngine.potSizedBet(10, fraction: 0.5), 5.0);
    });

    test('fraction por defecto es 1.0 (pot-sized)', () {
      expect(BetSizingEngine.potSizedBet(20), 20.0);
    });

    test('overbet (fraction > 1.0) es válido', () {
      expect(BetSizingEngine.potSizedBet(10, fraction: 1.5), 15.0);
    });

    test('fraction 0 da un bet de 0', () {
      expect(BetSizingEngine.potSizedBet(10, fraction: 0), 0.0);
    });

    test('rechaza potBb o fraction negativos/no finitos', () {
      expect(() => BetSizingEngine.potSizedBet(-1), throwsArgumentError);
      expect(() => BetSizingEngine.potSizedBet(10, fraction: -0.1),
          throwsArgumentError);
      expect(() => BetSizingEngine.potSizedBet(double.nan),
          throwsArgumentError);
      expect(
        () => BetSizingEngine.potSizedBet(10, fraction: double.infinity),
        throwsArgumentError,
      );
    });
  });

  group('BetSizingEngine.asFractionOfPot', () {
    test('es el inverso exacto de potSizedBet', () {
      for (final fraction in [0.33, 0.5, 0.66, 0.75, 1.0, 1.5]) {
        final sizeBb = BetSizingEngine.potSizedBet(10, fraction: fraction);
        expect(BetSizingEngine.asFractionOfPot(sizeBb, 10),
            closeTo(fraction, 1e-9));
      }
    });

    test('bet de 0 sobre un bote real es 0% del pot', () {
      expect(BetSizingEngine.asFractionOfPot(0, 10), 0.0);
    });

    test('rechaza un bote <= 0 (no es un caso degenerado válido)', () {
      expect(() => BetSizingEngine.asFractionOfPot(5, 0), throwsArgumentError);
      expect(() => BetSizingEngine.asFractionOfPot(5, -1), throwsArgumentError);
    });

    test('rechaza sizeBb negativo/no finito', () {
      expect(() => BetSizingEngine.asFractionOfPot(-1, 10), throwsArgumentError);
      expect(() => BetSizingEngine.asFractionOfPot(double.nan, 10),
          throwsArgumentError);
    });
  });
}
