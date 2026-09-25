import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/equity/equity_engine.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/strategy/hand_range.dart';

// Mismo helper que ya usa hand_evaluator_test.dart — no se inventa un
// segundo formato de board para los tests.
List<Card> _board(String codes) {
  final clean = codes.replaceAll(' ', '');
  final cards = <Card>[];
  for (var i = 0; i < clean.length; i += 2) {
    cards.add(Card.parse(clean.substring(i, i + 2)));
  }
  return cards;
}

void main() {
  group('river — una sola evaluación, sin enumerar runouts', () {
    test('hero gana: par de ases le gana a par de reyes', () {
      final result = EquityEngine.handVsHand(
        HoleCards.parse('AhAd'),
        HoleCards.parse('KhKd'),
        _board('2c7d9hJc4s'),
      );
      expect(result.total, 1);
      expect(result.wins, 1);
      expect(result.ties, 0);
      expect(result.losses, 0);
      expect(result.equity, 1.0);
    });

    test('hero pierde: mismo board, manos invertidas', () {
      final result = EquityEngine.handVsHand(
        HoleCards.parse('KhKd'),
        HoleCards.parse('AhAd'),
        _board('2c7d9hJc4s'),
      );
      expect(result.total, 1);
      expect(result.wins, 0);
      expect(result.ties, 0);
      expect(result.losses, 1);
      expect(result.equity, 0.0);
    });

    test('empate: el board ya es una escalera color (ninguna hole card mejora)', () {
      final result = EquityEngine.handVsHand(
        HoleCards.parse('2c3c'),
        HoleCards.parse('4d5d'),
        _board('AhKhQhJhTh'),
      );
      expect(result.total, 1);
      expect(result.wins, 0);
      expect(result.ties, 1);
      expect(result.losses, 0);
      expect(result.equity, 0.5);
    });
  });

  group('flop — C(45,2) = 990 runouts, no C(47,2) = 1081', () {
    // Nota: 47/1081 sería el conteo si solo se descontaran hero+board del
    // mazo. Acá también se conoce la mano rival exacta (handVsHand), así
    // que sus 2 cartas TAMBIÉN salen del mazo antes de enumerar turn+river
    // — igual que cualquier calculadora de equity real (ej. la referencia
    // clásica de AA vs KK preflop se enumera sobre C(48,5), no C(50,5),
    // por la misma razón). unseen = 52 - 2(hero) - 2(villain) - 3(board)
    // = 45 -> C(45,2) = 990.
    test('total de runouts es 990, nunca 1081', () {
      final result = EquityEngine.handVsHand(
        HoleCards.parse('AsKd'),
        HoleCards.parse('QsQd'),
        _board('2c7d9h'),
      );
      expect(result.total, 990);
      expect(result.wins + result.ties + result.losses, result.total);
    });
  });

  group('turn — 44 rivers posibles, no 46', () {
    // Mismo razonamiento que en flop: unseen = 52 - 2 - 2 - 4 = 44.
    test('total de runouts es 44, nunca 46', () {
      final result = EquityEngine.handVsHand(
        HoleCards.parse('AsKd'),
        HoleCards.parse('QsQd'),
        _board('2c7d9hJc'),
      );
      expect(result.total, 44);
    });
  });

  group('river — total == 1 siempre', () {
    test('board completo: una sola evaluación, sin enumeración', () {
      final result = EquityEngine.handVsHand(
        HoleCards.parse('AsKd'),
        HoleCards.parse('QsQd'),
        _board('2c7d9hJc4s'),
      );
      expect(result.total, 1);
    });
  });

  group('card removal', () {
    test('las cartas de hero y board nunca aparecen en un runout', () {
      // AKs tiene 4 combos físicos (As-Ks, Ah-Kh, Ad-Kd, Ac-Kc). Hero ya
      // tiene As y Ks en la mano: el combo As-Ks es físicamente imposible
      // para el rival y debe descartarse — quedan 3, no 4.
      final result = EquityEngine.handVsRange(
        HoleCards.parse('AsKs'),
        HandRange.parse(['AKs']),
        _board('2c7d9h'),
      );
      expect(result.total, 3 * 990);
    });

    test('las cartas del board también bloquean combos rivales', () {
      // "55" tiene 6 combos (todos los pares de palos entre los 4
      // cincos). Con el 5c ya repartido en el board, los 3 combos que lo
      // usan (5s5c, 5h5c, 5d5c) quedan bloqueados — quedan 3, no 6.
      final result = EquityEngine.handVsRange(
        HoleCards.parse('AsKd'),
        HandRange.parse(['55']),
        _board('5c7d9h'),
      );
      expect(result.total, 3 * 990);
    });
  });

  group('hand vs range', () {
    test('rango de un solo par (AA): 6 combos, sin bloqueos', () {
      final result = EquityEngine.handVsRange(
        HoleCards.parse('KsKd'),
        HandRange.parse(['AA']),
        _board('2c7d9h'),
      );
      expect(result.total, 6 * 990);
    });

    test('rango de dos pares (AA, KK): 12 combos, sin bloqueos', () {
      final result = EquityEngine.handVsRange(
        HoleCards.parse('7h8h'),
        HandRange.parse(['AA', 'KK']),
        _board('2c9dTc'),
      );
      expect(result.total, 12 * 990);
    });

    test('rango vacío tras descontar hero/board lanza ArgumentError', () {
      // "AA" tiene 6 combos entre As/Ah/Ad/Ac. Hero ya tiene As, y el
      // board reparte los otros 3 ases (Ah, Ad, Ac): los 4 ases de la
      // baraja quedan completamente asignados y no puede quedar ningún
      // combo de AA vivo para el rival.
      expect(
        () => EquityEngine.handVsRange(
          HoleCards.parse('AsKd'),
          HandRange.parse(['AA']),
          _board('AhAdAcKcQd'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('range vs range', () {
    test('AA vs KK sin bloqueo cruzado: 6x6 combos, todos válidos', () {
      final result = EquityEngine.rangeVsRange(
        HandRange.parse(['AA']),
        HandRange.parse(['KK']),
        _board('2c7d9h'),
      );
      expect(result.total, 6 * 6 * 990);
      // AA le gana a KK en la enorme mayoría de los runouts.
      expect(result.equity, greaterThan(0.7));
    });

    test('AA vs AA: cada combo del héroe bloquea 2 de los 4 ases, deja '
        'exactamente 1 combo rival por cada combo del héroe (no 6)', () {
      final result = EquityEngine.rangeVsRange(
        HandRange.parse(['AA']),
        HandRange.parse(['AA']),
        _board('2c7d9h'),
      );
      expect(result.total, 6 * 1 * 990);
      // Dos manos idénticas de AA sobre el mismo board: siempre empate.
      expect(result.wins, 0);
      expect(result.losses, 0);
      expect(result.ties, result.total);
    });

    test('AKs vs AKo: comparte rangos (A y K), combos parcialmente '
        'bloqueados pero no vacíos', () {
      final result = EquityEngine.rangeVsRange(
        HandRange.parse(['AKs']),
        HandRange.parse(['AKo']),
        _board('2c7d9h'),
      );
      // 4 combos suited del héroe x 12 combos offsuit del rival, menos
      // los que comparten una carta con el combo del héroe puntual.
      expect(result.total, greaterThan(0));
      expect(result.total, lessThan(4 * 12 * 990));
    });

    test('heroRange sin combos tras descontar el board lanza ArgumentError', () {
      expect(
        () => EquityEngine.rangeVsRange(
          HandRange.parse(['AA']),
          HandRange.parse(['KK']),
          _board('AhAdAcKcQd'),
        ),
        throwsArgumentError,
      );
    });

    test('los rangos se bloquean por completo entre sí: lanza ArgumentError '
        'en vez de devolver un resultado vacío en silencio', () {
      // Board ya tiene 2 ases; heroRange=AA solo puede formar el combo
      // con los 2 ases que quedan libres — y ese combo deja 0 ases
      // disponibles para que villainRange=AA arme ningún combo.
      expect(
        () => EquityEngine.rangeVsRange(
          HandRange.parse(['AA']),
          HandRange.parse(['AA']),
          _board('AhAd2c'),
        ),
        throwsArgumentError,
      );
    });

    test('board inválido se rechaza igual que en handVsHand/handVsRange', () {
      expect(
        () => EquityEngine.rangeVsRange(
          HandRange.parse(['AA']),
          HandRange.parse(['KK']),
          const [],
        ),
        throwsArgumentError,
      );
    });
  });

  group('caso clásico de dominación (AK vs AQ)', () {
    test('la equity usa cartas y runouts reales, no fuerza abstracta', () {
      final result = EquityEngine.handVsHand(
        HoleCards.parse('AhKd'),
        HoleCards.parse('AsQd'),
        _board('2c7d9h'),
      );
      expect(result.total, 990);
      // No se afirma un número de solver: solo que la dominación real se
      // refleja en el resultado (hero muy favorito, no un 50/50 abstracto
      // de "dos manos altas").
      expect(result.wins, greaterThan(result.losses));
      expect(result.equity, greaterThan(0.6));
    });
  });

  group('board-only chop', () {
    test('full house íntegro en el board: nadie mejora, empate total', () {
      final result = EquityEngine.handVsHand(
        HoleCards.parse('2c3d'),
        HoleCards.parse('6h7d'),
        _board('5s5d5c9h9d'),
      );
      expect(result.ties, greaterThan(0));
      expect(result.equity, 0.5);
    });
  });

  group('casos especiales — integración ComboEngine + HandEvaluator + runouts', () {
    test('escalera baja (rueda A-2-3-4-5) le gana a carta alta', () {
      final result = EquityEngine.handVsHand(
        HoleCards.parse('AhKd'),
        HoleCards.parse('KhQd'),
        _board('2c3d4h5s9c'),
      );
      expect(result.wins, 1);
      expect(result.ties, 0);
      expect(result.losses, 0);
    });

    test('color le gana a pareja', () {
      final result = EquityEngine.handVsHand(
        HoleCards.parse('AhKh'),
        HoleCards.parse('JdTd'),
        _board('2h5h9hJcQc'),
      );
      expect(result.wins, 1);
      expect(result.ties, 0);
      expect(result.losses, 0);
    });
  });

  group('coherencia matemática (para todos los resultados de arriba)', () {
    test('wins + ties + losses == total, y las probabilidades suman ~1', () {
      final results = [
        EquityEngine.handVsHand(
          HoleCards.parse('AsKd'),
          HoleCards.parse('QsQd'),
          _board('2c7d9h'),
        ),
        EquityEngine.handVsHand(
          HoleCards.parse('AsKd'),
          HoleCards.parse('QsQd'),
          _board('2c7d9hJc'),
        ),
        EquityEngine.handVsRange(
          HoleCards.parse('7h8h'),
          HandRange.parse(['AA', 'KK']),
          _board('2c9dTc'),
        ),
      ];
      for (final r in results) {
        expect(r.wins + r.ties + r.losses, r.total);
        expect(
          r.winProbability + r.tieProbability + r.lossProbability,
          closeTo(1.0, 1e-9),
        );
        expect(r.equity, closeTo(r.winProbability + r.tieProbability / 2, 1e-9));
      }
    });
  });

  group('boards inválidos', () {
    test('board vacío (preflop) no es evaluable en esta fase', () {
      expect(
        () => EquityEngine.handVsHand(
          HoleCards.parse('AhKd'),
          HoleCards.parse('QsQd'),
          const [],
        ),
        throwsArgumentError,
      );
    });

    test('board de 6 cartas es inválido', () {
      expect(
        () => EquityEngine.handVsHand(
          HoleCards.parse('AhKd'),
          HoleCards.parse('QsQd'),
          _board('2c7d9hJc4s5s'),
        ),
        throwsArgumentError,
      );
    });

    test('carta repetida entre hero y villain lanza ArgumentError', () {
      expect(
        () => EquityEngine.handVsHand(
          HoleCards.parse('AhKd'),
          HoleCards.parse('AhQd'),
          _board('2c7d9h'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('rendimiento (medir, no optimizar de antemano)', () {
    test('hand vs hand en flop', () {
      final sw = Stopwatch()..start();
      final result = EquityEngine.handVsHand(
        HoleCards.parse('AhKd'),
        HoleCards.parse('QsQd'),
        _board('2c7d9h'),
      );
      sw.stop();
      // ignore: avoid_print
      print('handVsHand flop: ${sw.elapsedMilliseconds} ms para ${result.total} runouts');
      expect(result.total, 990);
    });

    test('hand vs hand en turn', () {
      final sw = Stopwatch()..start();
      final result = EquityEngine.handVsHand(
        HoleCards.parse('AhKd'),
        HoleCards.parse('QsQd'),
        _board('2c7d9hJc'),
      );
      sw.stop();
      // ignore: avoid_print
      print('handVsHand turn: ${sw.elapsedMilliseconds} ms para ${result.total} runouts');
      expect(result.total, 44);
    });

    test('hand vs range moderado en flop (rango de manos premium, 34 combos brutos)', () {
      final range = HandRange.parse(['AA', 'KK', 'QQ', 'AKs', 'AKo']);
      final sw = Stopwatch()..start();
      final result = EquityEngine.handVsRange(
        HoleCards.parse('7h8h'),
        range,
        _board('2c9dTc'),
      );
      sw.stop();
      // ignore: avoid_print
      print('handVsRange flop (~${range.comboCount.round()} combos brutos): '
          '${sw.elapsedMilliseconds} ms para ${result.total} runouts totales');
      expect(result.total, greaterThan(0));
    });

    test('range vs range chico en turn (2 clases x 2 clases, 12x12 combos brutos)', () {
      final heroRange = HandRange.parse(['AA', 'KK']);
      final villainRange = HandRange.parse(['QQ', 'JJ']);
      final sw = Stopwatch()..start();
      final result = EquityEngine.rangeVsRange(
        heroRange,
        villainRange,
        _board('2c9dTc5h'),
      );
      sw.stop();
      // ignore: avoid_print
      print('rangeVsRange turn (~${heroRange.comboCount.round()}x'
          '${villainRange.comboCount.round()} combos brutos): '
          '${sw.elapsedMilliseconds} ms para ${result.total} runouts totales '
          '— confirma por qué el informe de Fase 0 recomienda correr esto '
          'fuera del isolate de UI para rangos anchos en flop.');
      expect(result.total, greaterThan(0));
    });
  });
}
