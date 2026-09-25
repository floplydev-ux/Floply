import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/ev/ev_engine.dart';
import 'package:poker_trainer/engine/poker/pot_odds/pot_odds_engine.dart';

void main() {
  group('casos obligatorios del enunciado', () {
    test('caso A — break-even: 25% de equity contra 15/5', () {
      final r = EVEngine.calculateCall(
        equity: 0.25,
        finalPotBb: 20,
        callAmountBb: 5,
      );
      expect(r.evBb, closeTo(0.0, 1e-9));
      expect(r.isBreakEven, isTrue);
      expect(r.isProfitable, isFalse);
      expect(r.isLosing, isFalse);
    });

    test('caso B — equity superior al precio: 50% contra 15/5 -> +5 bb', () {
      final r = EVEngine.calculateCall(
        equity: 0.50,
        finalPotBb: 20,
        callAmountBb: 5,
      );
      expect(r.evBb, closeTo(5.0, 1e-9));
      expect(r.isProfitable, isTrue);
    });

    test('caso C — equity inferior al precio: 10% contra 15/5 -> -3 bb', () {
      final r = EVEngine.calculateCall(
        equity: 0.10,
        finalPotBb: 20,
        callAmountBb: 5,
      );
      expect(r.evBb, closeTo(-3.0, 1e-9));
      expect(r.isLosing, isTrue);
    });

    test('caso D — finalPot 40, call 10, equity 35% -> +4 bb', () {
      final r = EVEngine.calculateCall(
        equity: 0.35,
        finalPotBb: 40,
        callAmountBb: 10,
      );
      expect(r.evBb, closeTo(4.0, 1e-9));
    });

    test('caso E — finalPot 100, call 20, equity 15% -> -5 bb', () {
      final r = EVEngine.calculateCall(
        equity: 0.15,
        finalPotBb: 100,
        callAmountBb: 20,
      );
      expect(r.evBb, closeTo(-5.0, 1e-9));
    });
  });

  group('no hay doble conteo del call', () {
    test('la fórmula nunca multiplica callAmount por (1 - equity)', () {
      // Si hubiera doble conteo (equity*finalPot - call*(1-equity)) con
      // equity=0.25, finalPot=20, call=5, el resultado sería
      // 5 - 5*0.75 = 1.25, no 0.
      final r = EVEngine.calculateCall(
        equity: 0.25,
        finalPotBb: 20,
        callAmountBb: 5,
      );
      expect(r.evBb, isNot(closeTo(1.25, 1e-6)));
      expect(r.evBb, closeTo(0.0, 1e-9));
    });
  });

  group('coherencia con PotOddsEngine (Fase 4 + Fase 5)', () {
    const scenarios = [(15.0, 5.0), (30.0, 10.0), (20.0, 20.0), (100.0, 10.0), (0.0, 8.0)];

    for (final (pot, call) in scenarios) {
      test('pot=$pot call=$call: equity==required -> EV=0; +delta -> EV>0; -delta -> EV<0', () {
        final potOdds = PotOddsEngine.calculate(potBeforeCallBb: pot, callAmountBb: call);

        final atRequired = EVEngine.calculateCall(
          equity: potOdds.requiredEquity,
          finalPotBb: potOdds.finalPotBb,
          callAmountBb: potOdds.callAmountBb,
        );
        expect(atRequired.evBb, closeTo(0.0, 1e-9));
        expect(atRequired.isBreakEven, isTrue);

        if (potOdds.requiredEquity < 1.0) {
          final aboveEquity =
              potOdds.requiredEquity + (1.0 - potOdds.requiredEquity) / 2;
          final above = EVEngine.calculateCall(
            equity: aboveEquity,
            finalPotBb: potOdds.finalPotBb,
            callAmountBb: potOdds.callAmountBb,
          );
          expect(above.evBb, greaterThan(0));
          expect(above.isProfitable, isTrue);
        }

        if (potOdds.requiredEquity > 0.0) {
          final belowEquity = potOdds.requiredEquity / 2;
          final below = EVEngine.calculateCall(
            equity: belowEquity,
            finalPotBb: potOdds.finalPotBb,
            callAmountBb: potOdds.callAmountBb,
          );
          expect(below.evBb, lessThan(0));
          expect(below.isLosing, isTrue);
        }
      });
    }
  });

  group('callAmount = 0 (opción A: se acepta, consistente con PotOddsEngine)', () {
    test('EV = equity * finalPot, sin rama especial', () {
      final r = EVEngine.calculateCall(
        equity: 0.4,
        finalPotBb: 15,
        callAmountBb: 0,
      );
      expect(r.evBb, closeTo(0.4 * 15, 1e-9));
    });
  });

  group('finalPot = 0 (fuerza callAmount = 0): caso degenerado pero válido', () {
    test('EV = 0 sin importar la equity', () {
      for (final equity in [0.0, 0.25, 0.5, 1.0]) {
        final r = EVEngine.calculateCall(
          equity: equity,
          finalPotBb: 0,
          callAmountBb: 0,
        );
        expect(r.evBb, 0.0);
        expect(r.isBreakEven, isTrue);
      }
    });
  });

  group('validaciones — rechazo explícito', () {
    test('equity negativa lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateCall(equity: -0.1, finalPotBb: 20, callAmountBb: 5),
        throwsArgumentError,
      );
    });

    test('equity > 1 lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateCall(equity: 1.1, finalPotBb: 20, callAmountBb: 5),
        throwsArgumentError,
      );
    });

    test('equity NaN lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateCall(
          equity: double.nan,
          finalPotBb: 20,
          callAmountBb: 5,
        ),
        throwsArgumentError,
      );
    });

    test('equity Infinity lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateCall(
          equity: double.infinity,
          finalPotBb: 20,
          callAmountBb: 5,
        ),
        throwsArgumentError,
      );
    });

    test('finalPot negativo lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateCall(equity: 0.5, finalPotBb: -1, callAmountBb: 5),
        throwsArgumentError,
      );
    });

    test('call negativo lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateCall(equity: 0.5, finalPotBb: 20, callAmountBb: -5),
        throwsArgumentError,
      );
    });

    test('finalPot NaN/Infinity lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateCall(
          equity: 0.5,
          finalPotBb: double.nan,
          callAmountBb: 5,
        ),
        throwsArgumentError,
      );
      expect(
        () => EVEngine.calculateCall(
          equity: 0.5,
          finalPotBb: double.infinity,
          callAmountBb: 5,
        ),
        throwsArgumentError,
      );
    });

    test('finalPot < callAmount lanza ArgumentError (matemáticamente imposible)', () {
      expect(
        () => EVEngine.calculateCall(equity: 0.5, finalPotBb: 4, callAmountBb: 5),
        throwsArgumentError,
      );
    });
  });

  group('invariantes', () {
    test('evBb == equity * finalPotBb - callAmountBb, siempre', () {
      const cases = [
        (0.25, 20.0, 5.0),
        (0.5, 40.0, 10.0),
        (0.0, 20.0, 5.0),
        (1.0, 20.0, 5.0),
        (0.4, 15.0, 0.0),
      ];
      for (final (equity, pot, call) in cases) {
        final r = EVEngine.calculateCall(
          equity: equity,
          finalPotBb: pot,
          callAmountBb: call,
        );
        expect(r.evBb, closeTo(equity * pot - call, 1e-9));
      }
    });
  });
}
