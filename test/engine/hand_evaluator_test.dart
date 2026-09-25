import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/hand_category.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/evaluator/hand_evaluator.dart';

List<Card> _board(String codes) {
  final clean = codes.replaceAll(' ', '');
  final cards = <Card>[];
  for (var i = 0; i < clean.length; i += 2) {
    cards.add(Card.parse(clean.substring(i, i + 2)));
  }
  return cards;
}

void main() {
  group('HandEvaluator — categorías (flop, sin ambigüedad de elección)', () {
    test('high card', () {
      final result = HandEvaluator.best(
        HoleCards.parse('2h7c'),
        _board('9sJsKd'),
      );
      expect(result.category, HandCategory.highCard);
      expect(result.tiebreakers.map((r) => r.value),
          [Rank.king.value, Rank.jack.value, Rank.nine.value, Rank.seven.value, Rank.two.value]);
    });

    test('pair', () {
      final result = HandEvaluator.best(
        HoleCards.parse('2h2c'),
        _board('9sJsKd'),
      );
      expect(result.category, HandCategory.pair);
      expect(result.tiebreakers.first, Rank.two);
      expect(result.tiebreakers.sublist(1).map((r) => r.value),
          [Rank.king.value, Rank.jack.value, Rank.nine.value]);
    });

    test('two pair', () {
      final result = HandEvaluator.best(
        HoleCards.parse('2h2c'),
        _board('9s9dKd'),
      );
      expect(result.category, HandCategory.twoPair);
      expect(result.tiebreakers, [Rank.nine, Rank.two, Rank.king]);
    });

    test('trips (three of a kind)', () {
      final result = HandEvaluator.best(
        HoleCards.parse('2h2c'),
        _board('2dKd9s'),
      );
      expect(result.category, HandCategory.trips);
      expect(result.tiebreakers.first, Rank.two);
      expect(result.tiebreakers.sublist(1), [Rank.king, Rank.nine]);
    });

    test('straight', () {
      final result = HandEvaluator.best(
        HoleCards.parse('5h6c'),
        _board('7d8s9h'),
      );
      expect(result.category, HandCategory.straight);
      expect(result.tiebreakers, [Rank.nine]);
    });

    test('broadway straight (A-K-Q-J-T)', () {
      final result = HandEvaluator.best(
        HoleCards.parse('AhKc'),
        _board('QdJsTd'),
      );
      expect(result.category, HandCategory.straight);
      expect(result.tiebreakers, [Rank.ace]);
    });

    test('flush', () {
      final result = HandEvaluator.best(
        HoleCards.parse('As9s'),
        _board('2s5sKs'),
      );
      expect(result.category, HandCategory.flush);
      expect(result.tiebreakers, [Rank.ace, Rank.king, Rank.nine, Rank.five, Rank.two]);
    });

    test('full house', () {
      final result = HandEvaluator.best(
        HoleCards.parse('2h2c'),
        _board('2d9s9d'),
      );
      expect(result.category, HandCategory.fullHouse);
      expect(result.tiebreakers, [Rank.two, Rank.nine]);
    });

    test('quads (four of a kind)', () {
      final result = HandEvaluator.best(
        HoleCards.parse('2h2c'),
        _board('2d2s9h'),
      );
      expect(result.category, HandCategory.quads);
      expect(result.tiebreakers, [Rank.two, Rank.nine]);
    });

    test('straight flush', () {
      final result = HandEvaluator.best(
        HoleCards.parse('5h6h'),
        _board('7h8h9h'),
      );
      expect(result.category, HandCategory.straightFlush);
      expect(result.tiebreakers, [Rank.nine]);
    });
  });

  group('HandEvaluator — la rueda (A-2-3-4-5)', () {
    test('wheel: escalera al 5, el As juega bajo', () {
      final result = HandEvaluator.best(
        HoleCards.parse('Ah2c'),
        _board('3d4s5h'),
      );
      expect(result.category, HandCategory.straight);
      expect(result.tiebreakers, [Rank.five]);
    });

    test('wheel: escalera de color al 5', () {
      final result = HandEvaluator.best(
        HoleCards.parse('As2s'),
        _board('3s4s5s'),
      );
      expect(result.category, HandCategory.straightFlush);
      expect(result.tiebreakers, [Rank.five]);
    });

    test('wheel no le gana a una escalera normal más alta', () {
      final wheel = HandEvaluator.best(HoleCards.parse('Ah2c'), _board('3d4s5h'));
      final sixHigh = HandEvaluator.best(HoleCards.parse('3h4c'), _board('5d6s2h'));
      expect(wheel.tiebreakers.first, Rank.five);
      expect(sixHigh.tiebreakers.first, Rank.six);
      expect(sixHigh.compareTo(wheel) > 0, isTrue);
    });
  });

  group('HandEvaluator — desempates', () {
    test('pair vs pair: gana el kicker más alto', () {
      final board = _board('8h8d2c');
      final heroA = HoleCards.parse('AcKd'); // pareja de 8, kickers A,K,2
      final heroB = HoleCards.parse('QhJc'); // pareja de 8, kickers Q,J,2
      expect(HandEvaluator.compare(heroA, heroB, board) > 0, isTrue);
    });

    test('two pair vs two pair: mismos pares, desempata el kicker', () {
      final board = _board('8h8d3c');
      final heroA = HoleCards.parse('3h2c'); // 8-8-3-3, kicker 2
      final heroB = HoleCards.parse('3d4c'); // 8-8-3-3, kicker 4
      expect(HandEvaluator.compare(heroB, heroA, board) > 0, isTrue);
    });

    test('trips vs trips: desempata el mejor kicker', () {
      final board = _board('9h9d9s');
      final heroA = HoleCards.parse('AcKd'); // trío de 9, kickers A,K
      final heroB = HoleCards.parse('QhJc'); // trío de 9, kickers Q,J
      expect(HandEvaluator.compare(heroA, heroB, board) > 0, isTrue);
    });

    test('straight vs straight: gana la carta más alta', () {
      final heroLow = HandEvaluator.best(HoleCards.parse('5h6c'), _board('7d8s9h'));
      final heroHigh = HandEvaluator.best(HoleCards.parse('6h7c'), _board('8d9sTh'));
      expect(heroHigh.compareTo(heroLow) > 0, isTrue);
    });

    test('flush vs flush: se comparan las 5 cartas de mayor a menor', () {
      final board = _board('2s5sKs');
      final heroA = HoleCards.parse('As9s'); // A,K,9,5,2
      final heroB = HoleCards.parse('Qs7s'); // K,Q,7,5,2
      expect(HandEvaluator.compare(heroA, heroB, board) > 0, isTrue);
    });

    test('full house vs full house: primero desempata el trío, no el par', () {
      final board = _board('2d9s9d');
      final heroTripDeuces = HoleCards.parse('2h2c'); // trío 2, par 9 -> [2,9]
      final heroTripNines = HoleCards.parse('9h2s'); // trío 9, par 2 -> [9,2]
      expect(HandEvaluator.compare(heroTripNines, heroTripDeuces, board) > 0, isTrue);
    });

    test('quads vs quads: desempata el kicker', () {
      final board = _board('2d2s2c2hKh'); // los 4 doses ya están en el board
      final heroA = HoleCards.parse('AcQc'); // el mejor kicker disponible es el As
      final heroB = HoleCards.parse('JcTc'); // el mejor kicker disponible es el K del board
      final resultA = HandEvaluator.best(heroA, board);
      final resultB = HandEvaluator.best(heroB, board);
      expect(resultA.tiebreakers, [Rank.two, Rank.ace]);
      expect(resultB.tiebreakers, [Rank.two, Rank.king]);
      expect(HandEvaluator.compare(heroA, heroB, board) > 0, isTrue);
    });

    test('straight flush vs straight flush: gana la carta más alta', () {
      final low = HandEvaluator.best(HoleCards.parse('5h6h'), _board('7h8h9h'));
      final high = HandEvaluator.best(HoleCards.parse('6h7h'), _board('8h9hTh'));
      expect(high.compareTo(low) > 0, isTrue);
    });
  });

  group('HandEvaluator — el board juega (chop)', () {
    test('ninguno de los dos usa sus hole cards: empate exacto', () {
      final board = _board('AhKdQcJsTd'); // escalera Broadway completa en el board
      final heroA = HoleCards.parse('2h3c');
      final heroB = HoleCards.parse('4h5c');
      expect(HandEvaluator.compare(heroA, heroB, board), 0);

      final winners = HandEvaluator.winners(
        {0: heroA, 1: heroB},
        board,
      );
      expect(winners, {0, 1});
    });
  });

  group('HandEvaluator — mejor mano de 7 (no es solo "mano + board obvio")', () {
    test('caso 1: par en mano + board forman full house, no solo pareja', () {
      final result = HandEvaluator.best(
        HoleCards.parse('AhAc'),
        _board('AdKdKcQhJh'),
      );
      expect(result.category, HandCategory.fullHouse);
      expect(result.tiebreakers, [Rank.ace, Rank.king]);
    });

    test('caso 2: dos jugadores arman full houses distintos desde el mismo board paired', () {
      final board = _board('9h9d5c5s2h');
      final heroA = HoleCards.parse('9c2c'); // trío 9, mejor par disponible 5 -> [9,5]
      final heroB = HoleCards.parse('5h2d'); // trío 5, mejor par disponible 9 -> [5,9]
      final resultA = HandEvaluator.best(heroA, board);
      final resultB = HandEvaluator.best(heroB, board);
      expect(resultA.tiebreakers, [Rank.nine, Rank.five]);
      expect(resultB.tiebreakers, [Rank.five, Rank.nine]);
      expect(HandEvaluator.compare(heroA, heroB, board) > 0, isTrue);
    });

    test('caso 3: seis cartas del mismo palo — se elige el mejor flush de 5, no cualquiera', () {
      final result = HandEvaluator.best(
        HoleCards.parse('2s9s'),
        _board('KsJs7s4sQd'), // 6 espadas disponibles (2,9,K,J,7,4), Qd no pinta
      );
      expect(result.category, HandCategory.flush);
      expect(result.tiebreakers, [Rank.king, Rank.jack, Rank.nine, Rank.seven, Rank.four]);
    });

    test('caso 4: escalera de color posible junto con otras combinaciones — gana la categoría superior', () {
      final result = HandEvaluator.best(
        HoleCards.parse('5h6h'),
        _board('7h8h9hKcKd'), // escalera de color 5-9 en corazones, más par de K sueltos
      );
      expect(result.category, HandCategory.straightFlush);
      expect(result.tiebreakers, [Rank.nine]);
    });

    test('board pareado no obliga a jugar la pareja si hay una escalera mejor', () {
      final result = HandEvaluator.best(
        HoleCards.parse('JhTs'),
        _board('9h9dKcQd2s'),
      );
      expect(result.category, HandCategory.straight);
      expect(result.tiebreakers, [Rank.king]);
    });

    test('quads en el board: el kicker se elige entre todas las cartas disponibles', () {
      final result = HandEvaluator.best(
        HoleCards.parse('2h3c'),
        _board('9h9d9c9sKd'),
      );
      expect(result.category, HandCategory.quads);
      expect(result.tiebreakers, [Rank.nine, Rank.king]);
    });

    test('dos tríos disponibles en las 7 cartas: se arma el full house con el trío más alto', () {
      final result = HandEvaluator.best(
        HoleCards.parse('KhKc'),
        _board('Kd9h9d9c2s'), // 3 reyes + 3 nueves entre las 7 cartas
      );
      expect(result.category, HandCategory.fullHouse);
      expect(result.tiebreakers, [Rank.king, Rank.nine]);
    });
  });

  group('HandEvaluator.winners', () {
    test('un solo ganador claro entre 3 manos', () {
      final board = _board('2h7cKs');
      final winners = HandEvaluator.winners(
        {
          0: HoleCards.parse('AcAd'), // pareja de ases
          1: HoleCards.parse('QhJc'), // carta alta
          2: HoleCards.parse('9h8c'), // carta alta, peor
        },
        board,
      );
      expect(winners, {0});
    });

    test('lanza si el mapa de manos está vacío', () {
      expect(() => HandEvaluator.winners({}, _board('2h7cKs')),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('HandEvaluator — validaciones', () {
    test('rechaza un board con menos de 3 cartas', () {
      expect(
        () => HandEvaluator.best(HoleCards.parse('AhKh'), _board('2h7c')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rechaza un board con más de 5 cartas', () {
      expect(
        () => HandEvaluator.best(HoleCards.parse('AhKh'), _board('2h7c9sTdJd3c')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rechaza un board vacío (preflop) — fuera del alcance de este evaluador', () {
      expect(
        () => HandEvaluator.best(HoleCards.parse('AhKh'), const []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rechaza una carta repetida entre hole cards y board', () {
      expect(
        () => HandEvaluator.best(HoleCards.parse('AhKh'), _board('Ah7c9s')),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
