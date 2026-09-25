import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/pot_odds/pot_odds_engine.dart';

void main() {
  group('casos de referencia', () {
    test('pot 15bb (10 + 5 de apuesta ya incluida), call 5bb -> 25%', () {
      final r = PotOddsEngine.calculate(potBeforeCallBb: 15, callAmountBb: 5);
      expect(r.finalPotBb, 20);
      expect(r.requiredEquity, 0.25);
      expect(r.potOddsRatio, 3.0); // 15:5 = 3:1
    });

    test('pot-sized bet ya incluido en el pot: requiredEquity 33.3% (2:1)', () {
      // Pot antes del call = 20 (10 que había + 10 del pot-sized bet),
      // call 10 -> finalPot 30 -> 10/30 = 33.3%.
      final r = PotOddsEngine.calculate(potBeforeCallBb: 20, callAmountBb: 10);
      expect(r.requiredEquity, closeTo(0.3333, 0.0001));
      expect(r.potOddsRatio, 2.0); // 20:10 = 2:1
    });

    test('call contra un pot vacío: requiredEquity 100%', () {
      final r = PotOddsEngine.calculate(potBeforeCallBb: 0, callAmountBb: 8);
      expect(r.finalPotBb, 8);
      expect(r.requiredEquity, 1.0);
      expect(r.potOddsRatio, 0.0);
    });

    test('all-in corto: el call puede ser menor a lo que aportó el rival '
        '(eso ya está resuelto en potBeforeCallBb, no acá)', () {
      final r = PotOddsEngine.calculate(potBeforeCallBb: 30, callAmountBb: 8);
      expect(r.finalPotBb, 38);
      expect(r.requiredEquity, closeTo(0.2105, 0.0001));
    });
  });

  group('edge cases', () {
    test('call de 0 (check-through): no lanza, no es NaN, ratio null', () {
      final r = PotOddsEngine.calculate(potBeforeCallBb: 10, callAmountBb: 0);
      expect(r.requiredEquity, 0.0);
      expect(r.potOddsRatio, isNull);
      expect(r.requiredEquity.isNaN, isFalse);
    });

    test('todo en cero (mano sin nada posteado): 0%, no NaN', () {
      final r = PotOddsEngine.calculate(potBeforeCallBb: 0, callAmountBb: 0);
      expect(r.finalPotBb, 0.0);
      expect(r.requiredEquity, 0.0);
      expect(r.requiredEquity.isNaN, isFalse);
    });
  });

  group('invariantes', () {
    test('finalPotBb == potBeforeCallBb + callAmountBb, siempre', () {
      const cases = [(15.0, 5.0), (30.0, 10.0), (20.0, 20.0), (100.0, 10.0), (0.0, 8.0)];
      for (final (pot, call) in cases) {
        final r = PotOddsEngine.calculate(potBeforeCallBb: pot, callAmountBb: call);
        expect(r.finalPotBb, pot + call);
        expect(r.finalPotBb, greaterThanOrEqualTo(r.callAmountBb));
      }
    });

    test('requiredEquity == callAmountBb / finalPotBb, siempre que finalPotBb > 0', () {
      const cases = [(15.0, 5.0), (30.0, 10.0), (20.0, 20.0), (100.0, 10.0)];
      for (final (pot, call) in cases) {
        final r = PotOddsEngine.calculate(potBeforeCallBb: pot, callAmountBb: call);
        expect(r.requiredEquity, closeTo(call / (pot + call), 1e-9));
      }
    });
  });

  group('validaciones — rechazo explícito', () {
    test('potBeforeCallBb negativo lanza ArgumentError', () {
      expect(() => PotOddsEngine.calculate(potBeforeCallBb: -1, callAmountBb: 5),
          throwsArgumentError);
    });

    test('callAmountBb negativo lanza ArgumentError', () {
      expect(() => PotOddsEngine.calculate(potBeforeCallBb: 10, callAmountBb: -1),
          throwsArgumentError);
    });

    test('NaN/Infinity en cualquiera de los dos lanza ArgumentError', () {
      expect(
        () => PotOddsEngine.calculate(potBeforeCallBb: double.nan, callAmountBb: 5),
        throwsArgumentError,
      );
      expect(
        () => PotOddsEngine.calculate(potBeforeCallBb: double.infinity, callAmountBb: 5),
        throwsArgumentError,
      );
      expect(
        () => PotOddsEngine.calculate(potBeforeCallBb: 10, callAmountBb: double.nan),
        throwsArgumentError,
      );
      expect(
        () => PotOddsEngine.calculate(potBeforeCallBb: 10, callAmountBb: double.infinity),
        throwsArgumentError,
      );
    });
  });
}
