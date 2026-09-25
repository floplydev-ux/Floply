import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/combos/combo_engine.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/strategy/hand_range.dart';

List<Card> _cards(String codes) {
  final clean = codes.replaceAll(' ', '');
  final cards = <Card>[];
  for (var i = 0; i < clean.length; i += 2) {
    cards.add(Card.parse(clean.substring(i, i + 2)));
  }
  return cards;
}

void main() {
  group('ComboEngine.combosForNotation — clases básicas', () {
    test('pares: 6 combos', () {
      expect(ComboEngine.combosForNotation('AA').length, 6);
      expect(ComboEngine.combosForNotation('KK').length, 6);
      expect(ComboEngine.combosForNotation('22').length, 6);
    });

    test('suited: 4 combos', () {
      expect(ComboEngine.combosForNotation('AKs').length, 4);
      expect(ComboEngine.combosForNotation('AQs').length, 4);
    });

    test('offsuit: 12 combos', () {
      expect(ComboEngine.combosForNotation('AKo').length, 12);
      expect(ComboEngine.combosForNotation('AQo').length, 12);
    });

    test('AA son exactamente las 6 combinaciones físicas esperadas', () {
      final combos = ComboEngine.combosForNotation('AA').map((h) => h.toString()).toSet();
      expect(combos, {'AsAh', 'AsAd', 'AsAc', 'AhAd', 'AhAc', 'AdAc'});
    });

    test('AKs son exactamente las 4 combinaciones suited', () {
      final combos = ComboEngine.combosForNotation('AKs').map((h) => h.toString()).toSet();
      expect(combos, {'AsKs', 'AhKh', 'AdKd', 'AcKc'});
    });

    test('AKo nunca incluye una combinación suited', () {
      final combos = ComboEngine.combosForNotation('AKo');
      expect(combos.every((h) => h.isOffsuit), isTrue);
      expect(combos.any((h) => h.isSuited), isFalse);
    });
  });

  group('ComboEngine — las 169 clases', () {
    test('cada clase produce el conteo correcto y sin duplicados', () {
      for (final handClass in HandClass.all()) {
        final combos = ComboEngine.combosForHandClass(handClass);
        expect(combos.length, handClass.combos, reason: handClass.notation);
        expect(combos.toSet().length, combos.length,
            reason: '${handClass.notation}: no debería haber duplicados');
        if (handClass.isPair) {
          expect(combos.every((h) => h.isPair), isTrue, reason: handClass.notation);
        } else if (handClass.isSuited) {
          expect(combos.every((h) => h.isSuited), isTrue, reason: handClass.notation);
        } else {
          expect(combos.every((h) => h.isOffsuit), isTrue, reason: handClass.notation);
        }
      }
    });

    test('el total sobre las 169 clases es 1326, sin duplicados globales', () {
      final all = <HoleCards>[];
      for (final handClass in HandClass.all()) {
        all.addAll(ComboEngine.combosForHandClass(handClass));
      }
      expect(all.length, 1326);
      expect(all.toSet().length, 1326);
    });
  });

  group('ComboEngine — card removal (pares)', () {
    test('AA + 1 carta muerta de la pareja -> 3', () {
      expect(
        ComboEngine.comboCountForNotation('AA', deadCards: _cards('As')),
        3,
      );
    });

    test('AA + 2 cartas muertas de la pareja -> 1', () {
      expect(
        ComboEngine.comboCountForNotation('AA', deadCards: _cards('AsAh')),
        1,
      );
    });

    test('AA + las 4 cartas muertas -> 0', () {
      expect(
        ComboEngine.comboCountForNotation('AA', deadCards: _cards('AsAhAdAc')),
        0,
      );
    });

    test('una carta muerta que no pertenece a la clase no cambia nada', () {
      expect(
        ComboEngine.comboCountForNotation('AA', deadCards: _cards('2h')),
        6,
      );
    });
  });

  group('ComboEngine — card removal (suited/offsuit)', () {
    test('AKs + 1 carta muerta -> 3', () {
      expect(
        ComboEngine.comboCountForNotation('AKs', deadCards: _cards('As')),
        3,
      );
      // Confirma cuál combo desapareció exactamente.
      final remaining =
          ComboEngine.combosForNotation('AKs', deadCards: _cards('As')).map((h) => h.toString());
      expect(remaining, containsAll(['AhKh', 'AdKd', 'AcKc']));
      expect(remaining, isNot(contains('AsKs')));
    });

    test('AKo + removal cruzado (una carta de cada rango) -> 7', () {
      // 12 combos totales; se van los 3 que usan As y los 3 que usan Kh,
      // pero "As Kh" se cuenta una sola vez -> se van 5, quedan 7.
      final dead = _cards('AsKh');
      final combos = ComboEngine.combosForNotation('AKo', deadCards: dead);
      expect(combos.length, 7);
      expect(combos.any((h) => h.cards.contains(Card.parse('As'))), isFalse);
      expect(combos.any((h) => h.cards.contains(Card.parse('Kh'))), isFalse);
    });

    test('AKo + todas las cartas de un rango -> 0', () {
      expect(
        ComboEngine.comboCountForNotation('AKo', deadCards: _cards('AsAhAdAc')),
        0,
      );
    });
  });

  group('ComboEngine — board como dead cards', () {
    test('un board de 3 cartas reduce un rango de un solo par correctamente', () {
      final board = _cards('Ah7d2c'); // Ah pertenece a AA, 7d/2c no
      final combos = ComboEngine.combosForNotation('AA', deadCards: board);
      expect(combos.length, 3);
      expect(combos.any((h) => h.cards.contains(Card.parse('Ah'))), isFalse);
    });

    test('board + hole cards del héroe combinados como dead cards', () {
      final board = _cards('Ah7d2c');
      final heroHand = HoleCards.parse('AsKd');
      final dead = {...board, ...heroHand.cards}; // As, Kd, Ah, 7d, 2c

      // AKo (12 combos) pierde todo lo que use As, Ah (el as del board
      // también es un as) o Kd — únicas dead cards relevantes para esta
      // clase (7d/2c no son A ni K): unión de 3+3+3 combos con solape en
      // (As,Kd) y (Ah,Kd) -> se van 7, quedan 5.
      final combos = ComboEngine.combosForNotation('AKo', deadCards: dead);
      expect(combos.length, 5);
      for (final dc in dead) {
        expect(combos.any((h) => h.cards.contains(dc)), isFalse, reason: dc.code);
      }
    });
  });

  group('ComboEngine.combosForRange', () {
    test('un rango de un solo par sin dead cards reproduce comboCount', () {
      final range = HandRange.parse(const ['QQ']);
      expect(ComboEngine.comboCountForRange(range), 6);
    });

    test('rango de dos clases + una carta muerta compartida', () {
      final range = HandRange.parse(const ['AA', 'KK']);
      final combos = ComboEngine.combosForRange(range, deadCards: _cards('Ah'));
      // AA pierde 3 (queda en 3), KK no se ve afectado (sigue en 6).
      expect(combos.length, 9);
      expect(combos.where((h) => h.notation == 'AA').length, 3);
      expect(combos.where((h) => h.notation == 'KK').length, 6);
    });

    test('un rango amplio no produce combos duplicados', () {
      final range = HandRange.parse(const ['22+']); // los 13 pares
      final combos = ComboEngine.combosForRange(range);
      expect(combos.length, 13 * 6);
      expect(combos.toSet().length, combos.length);
    });

    test('clases con frecuencia 0 no aportan combos', () {
      // HandRange.parse no genera frecuencias en 0 directamente, así que
      // se arma a mano para probar el umbral de inclusión.
      final range = HandRange(const {'AA': 1.0, 'KK': 0.0});
      final combos = ComboEngine.combosForRange(range);
      expect(combos.length, 6);
      expect(combos.every((h) => h.notation == 'AA'), isTrue);
    });

    test('orden determinista: mismo rango, mismas dead cards -> misma lista', () {
      final range = HandRange.parse(const ['AKs', 'AA', 'QQ']);
      final dead = _cards('Ah');
      final first = ComboEngine.combosForRange(range, deadCards: dead);
      final second = ComboEngine.combosForRange(range, deadCards: dead);
      expect(first, second);
    });

    test('el orden no depende de cómo se construyó el rango (mismas clases, '
        'tokens en otro orden)', () {
      final rangeA = HandRange.parse(const ['AA', 'KK', 'QQ']);
      final rangeB = HandRange.parse(const ['QQ', 'AA', 'KK']);
      expect(ComboEngine.combosForRange(rangeA), ComboEngine.combosForRange(rangeB));
    });
  });

  group('ComboEngine — validaciones', () {
    test('dead cards duplicadas no rompen ni cuentan doble', () {
      final dead = [Card.parse('As'), Card.parse('As')];
      expect(ComboEngine.comboCountForNotation('AA', deadCards: dead), 3);
    });

    test('notación inválida lanza (delega en HandClass.parse)', () {
      expect(() => ComboEngine.combosForNotation('XY'), throwsFormatException);
      expect(() => ComboEngine.combosForNotation('AA9'), throwsFormatException);
    });

    test('ningún combo generado tiene las dos cartas iguales', () {
      for (final handClass in HandClass.all()) {
        for (final combo in ComboEngine.combosForHandClass(handClass)) {
          expect(combo.high == combo.low, isFalse, reason: handClass.notation);
        }
      }
    });
  });
}
