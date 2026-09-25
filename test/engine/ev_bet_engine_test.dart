import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/ev/ev_engine.dart';

void main() {
  group('EVEngine.calculateBet — casos válidos', () {
    test('EV positivo conocido (fold alto compensa una equity mediocre)', () {
      final r = EVEngine.calculateBet(
        foldProbability: 0.6,
        callProbability: 0.4,
        potBeforeBetBb: 10,
        betSizeBb: 5,
        equityIfCalled: 0.5,
      );
      // finalPotIfCalled = 10 + 2*5 = 20
      // evFold = 0.6*10 = 6; evCall = 0.4*(0.5*20 - 5) = 0.4*5 = 2
      expect(r.finalPotIfCalledBb, closeTo(20, 1e-9));
      expect(r.evFoldBb, closeTo(6, 1e-9));
      expect(r.evCallBb, closeTo(2, 1e-9));
      expect(r.evBb, closeTo(8, 1e-9));
      expect(r.isProfitable, isTrue);
      expect(r.unmodeledProbability, closeTo(0, 1e-9));
    });

    test('EV negativo conocido (fold bajo, mala equity si pagan)', () {
      final r = EVEngine.calculateBet(
        foldProbability: 0.1,
        callProbability: 0.9,
        potBeforeBetBb: 10,
        betSizeBb: 10,
        equityIfCalled: 0.2,
      );
      // finalPotIfCalled = 10 + 20 = 30
      // evFold = 0.1*10 = 1; evCall = 0.9*(0.2*30 - 10) = 0.9*(-4) = -3.6
      expect(r.evBb, closeTo(1 - 3.6, 1e-9));
      expect(r.isLosing, isTrue);
    });

    test('break-even exacto', () {
      final r = EVEngine.calculateBet(
        foldProbability: 0.2,
        callProbability: 0.8,
        potBeforeBetBb: 10,
        betSizeBb: 10,
        equityIfCalled: 0.25,
      );
      expect(r.evBb, closeTo(0, 1e-9));
      expect(r.isBreakEven, isTrue);
      expect(r.isProfitable, isFalse);
      expect(r.isLosing, isFalse);
    });

    test('fold puro (P(fold)=1): el EV es exactamente el pot actual, sin '
        'importar la equity', () {
      final r = EVEngine.calculateBet(
        foldProbability: 1,
        callProbability: 0,
        potBeforeBetBb: 15,
        betSizeBb: 7,
        equityIfCalled: 0, // irrelevante: callProbability es 0
      );
      expect(r.evBb, closeTo(15, 1e-9));
      expect(r.unmodeledProbability, closeTo(0, 1e-9));
    });

    test('call puro (P(fold)=0, P(call)=1): coincide exactamente con '
        'EVEngine.calculateCall para el mismo pot final y call', () {
      const pot = 12.0;
      const bet = 6.0;
      const equity = 0.42;
      final asBet = EVEngine.calculateBet(
        foldProbability: 0,
        callProbability: 1,
        potBeforeBetBb: pot,
        betSizeBb: bet,
        equityIfCalled: equity,
      );
      final asCall = EVEngine.calculateCall(
        equity: equity,
        finalPotBb: pot + 2 * bet,
        callAmountBb: bet,
      );
      expect(asBet.evBb, closeTo(asCall.evBb, 1e-9));
    });

    test('unmodeledProbability refleja la rama "el rival sube", excluida '
        'del cálculo', () {
      final r = EVEngine.calculateBet(
        foldProbability: 0.3,
        callProbability: 0.5,
        potBeforeBetBb: 10,
        betSizeBb: 5,
        equityIfCalled: 0.5,
      );
      expect(r.unmodeledProbability, closeTo(0.2, 1e-9));
    });
  });

  group('EVEngine.calculateBet — validación', () {
    test('foldProbability + callProbability > 1 lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateBet(
          foldProbability: 0.7,
          callProbability: 0.5,
          potBeforeBetBb: 10,
          betSizeBb: 5,
          equityIfCalled: 0.5,
        ),
        throwsArgumentError,
      );
    });

    test('foldProbability negativa lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateBet(
          foldProbability: -0.1,
          callProbability: 0.5,
          potBeforeBetBb: 10,
          betSizeBb: 5,
          equityIfCalled: 0.5,
        ),
        throwsArgumentError,
      );
    });

    test('callProbability > 1 lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateBet(
          foldProbability: 0,
          callProbability: 1.5,
          potBeforeBetBb: 10,
          betSizeBb: 5,
          equityIfCalled: 0.5,
        ),
        throwsArgumentError,
      );
    });

    test('foldProbability NaN/Infinity lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateBet(
          foldProbability: double.nan,
          callProbability: 0.5,
          potBeforeBetBb: 10,
          betSizeBb: 5,
          equityIfCalled: 0.5,
        ),
        throwsArgumentError,
      );
      expect(
        () => EVEngine.calculateBet(
          foldProbability: double.infinity,
          callProbability: 0.5,
          potBeforeBetBb: 10,
          betSizeBb: 5,
          equityIfCalled: 0.5,
        ),
        throwsArgumentError,
      );
    });

    test('potBeforeBetBb negativo lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateBet(
          foldProbability: 0.5,
          callProbability: 0.5,
          potBeforeBetBb: -1,
          betSizeBb: 5,
          equityIfCalled: 0.5,
        ),
        throwsArgumentError,
      );
    });

    test('betSizeBb negativo lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateBet(
          foldProbability: 0.5,
          callProbability: 0.5,
          potBeforeBetBb: 10,
          betSizeBb: -5,
          equityIfCalled: 0.5,
        ),
        throwsArgumentError,
      );
    });

    test('betSizeBb == 0 lanza ArgumentError (eso es un check, no una '
        'apuesta)', () {
      expect(
        () => EVEngine.calculateBet(
          foldProbability: 0.5,
          callProbability: 0.5,
          potBeforeBetBb: 10,
          betSizeBb: 0,
          equityIfCalled: 0.5,
        ),
        throwsArgumentError,
      );
    });

    test('equityIfCalled fuera de [0,1] lanza ArgumentError', () {
      expect(
        () => EVEngine.calculateBet(
          foldProbability: 0.5,
          callProbability: 0.5,
          potBeforeBetBb: 10,
          betSizeBb: 5,
          equityIfCalled: 1.1,
        ),
        throwsArgumentError,
      );
      expect(
        () => EVEngine.calculateBet(
          foldProbability: 0.5,
          callProbability: 0.5,
          potBeforeBetBb: 10,
          betSizeBb: 5,
          equityIfCalled: -0.1,
        ),
        throwsArgumentError,
      );
    });
  });
}
