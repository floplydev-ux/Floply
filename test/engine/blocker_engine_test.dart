import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/card.dart';
import 'package:poker_trainer/engine/poker/combos/combo_engine.dart';
import 'package:poker_trainer/engine/strategy/hand_range.dart';

// Mismo helper de formato que usan combo_engine_test y equity_engine_test.
List<Card> _cards(String codes) {
  final clean = codes.replaceAll(' ', '');
  final cards = <Card>[];
  for (var i = 0; i < clean.length; i += 2) {
    cards.add(Card.parse(clean.substring(i, i + 2)));
  }
  return cards;
}

// ─── Patrón que usa BlockerExplorerScreen ────────────────────────────────────
// total     = combosForRange(range, deadCards: board)
// available = combosForRange(range, deadCards: hero + board)
// blocked   = total - available
// ─────────────────────────────────────────────────────────────────────────────

int _total(HandRange range, List<Card> board) =>
    ComboEngine.combosForRange(range, deadCards: board).length;

int _available(HandRange range, List<Card> heroCards, List<Card> board) =>
    ComboEngine.combosForRange(range, deadCards: [...heroCards, ...board]).length;

int _blocked(HandRange range, List<Card> heroCards, List<Card> board) =>
    _total(range, board) - _available(range, heroCards, board);

void main() {
  // ── Caso de referencia (el mismo que usa el default de la pantalla) ────────
  group('caso de referencia — AhKd vs QQ+,AKs,AKo sin board', () {
    final range = HandRange.parse(const ['QQ', 'KK', 'AA', 'AKs', 'AKo']);
    final hero = _cards('AhKd');
    const board = <Card>[];

    test('total sin héroe: 34 combos (QQ6+KK6+AA6+AKs4+AKo12)', () {
      expect(_total(range, board), 34);
    });

    test('disponibles con AhKd: 21 combos', () {
      // QQ=6 (sin cambio), KK=6->3, AA=6->3, AKs=4->2, AKo=12->7.
      expect(_available(range, hero, board), 21);
    });

    test('bloqueados: 13 combos', () {
      expect(_blocked(range, hero, board), 13);
    });

    test('bloqueados + disponibles == total, siempre', () {
      final total = _total(range, board);
      final available = _available(range, hero, board);
      final blocked = total - available;
      expect(available + blocked, total);
    });
  });

  // ── Board reduce combos antes de que entren las cartas del héroe ──────────
  group('board como dead cards (reducción previa)', () {
    test('Ah en el board reduce AA: 6 -> 3 en el total', () {
      final range = HandRange.parse(const ['AA']);
      final board = _cards('Ah7d2c');
      expect(_total(range, board), 3);
    });

    test('board con Ah + héroe con As: AA queda con 1 combo disponible', () {
      final range = HandRange.parse(const ['AA']);
      final board = _cards('Ah7d2c');
      final hero = _cards('As');
      // Total=3 (Ah ya muerto); con As del héroe: quedan AdAc -> 1
      expect(_available(range, hero, board), 1);
      expect(_blocked(range, hero, board), 2);
    });

    test('4 ases muertos entre board y héroe -> AA: 0 disponibles', () {
      final range = HandRange.parse(const ['AA']);
      final board = _cards('AhAd2c');
      final hero = _cards('AsAc');
      expect(_available(range, hero, board), 0);
      expect(_blocked(range, hero, board), _total(range, board));
    });
  });

  // ── Héroe bloquea combos suited ───────────────────────────────────────────
  group('card removal en combos suited', () {
    test('AKs tiene 4 combos; héroe con As reduce a 3', () {
      final range = HandRange.parse(const ['AKs']);
      final hero = _cards('As');
      expect(_total(range, []), 4);
      expect(_available(range, hero, []), 3);
    });

    test('héroe con As y Ks bloquea AsKs — quedan 3 combos', () {
      final range = HandRange.parse(const ['AKs']);
      final hero = _cards('AsKs');
      expect(_available(range, hero, []), 3);
    });

    test('AKs: 2 cartas de distinto palo no bloquean ningún suited combo', () {
      final range = HandRange.parse(const ['AKs']);
      final hero = _cards('2c3d');
      expect(_available(range, hero, []), 4);
      expect(_blocked(range, hero, []), 0);
    });
  });

  // ── Héroe bloquea combos offsuit ──────────────────────────────────────────
  group('card removal en combos offsuit', () {
    test('AKo tiene 12 combos; héroe con As bloquea 3 -> quedan 9', () {
      final range = HandRange.parse(const ['AKo']);
      final hero = _cards('As');
      expect(_total(range, []), 12);
      expect(_available(range, hero, []), 9);
    });

    test('AKo: héroe con AsKd bloquea 5 combos -> quedan 7', () {
      final range = HandRange.parse(const ['AKo']);
      final hero = _cards('AsKd');
      // As bloquea 3 (AsKh, AsKc, AsKs -> s/suited eliminado porque es AKo),
      // Kd bloquea 3 (AhKd, AdKd, AcKd), AsKd es una sola combinación ->
      // deduplicada, quedan 12 - 5 = 7.
      expect(_available(range, hero, []), 7);
    });
  });

  // ── Rango con múltiples clases ────────────────────────────────────────────
  group('rango multíclase', () {
    test('QQ+,AKs — total 22 (QQ6+KK6+AA6+AKs4)', () {
      final range = HandRange.parse(const ['QQ', 'KK', 'AA', 'AKs']);
      expect(_total(range, []), 22);
    });

    test('QQ no se ve afectado por un héroe con ases', () {
      final hero = _cards('AsAh');
      // AA: AsAh/AsAd/AsAc bloqueados por As; AhAd/AhAc bloqueados por Ah.
      // Solo AsAc -> bloqueado por As también. AdAc queda, AsAc queda.
      // Realmente: As y Ah bloquean todo excepto AdAc -> 1.
      final totalAA = ComboEngine.combosForRange(
        HandRange.parse(const ['AA']),
        deadCards: hero,
      ).length;
      final totalQQ = ComboEngine.combosForRange(
        HandRange.parse(const ['QQ']),
        deadCards: hero,
      ).length;
      expect(totalAA, 1); // solo AdAc sobrevive
      expect(totalQQ, 6); // QQ no se ve afectado por A/A del héroe
    });
  });

  // ── Análisis preflop (board vacío) ────────────────────────────────────────
  group('board vacío — análisis preflop válido', () {
    test('sin board, el total solo depende del rango y el héroe', () {
      final range = HandRange.parse(const ['AA']);
      final hero = _cards('AhAd');
      // Héroe tiene Ah y Ad. Los 6 combos de AA son: AsAh, AsAd, AsAc, AhAd,
      // AhAc, AdAc. Cualquier combo que use Ah o Ad queda bloqueado (5 combos).
      // Solo AsAc no usa ninguno de los dos -> 1 disponible, 5 bloqueados.
      expect(_total(range, []), 6);
      expect(_available(range, hero, []), 1);
      expect(_blocked(range, hero, []), 5);
    });
  });

  // ── Invariante fundamental ────────────────────────────────────────────────
  group('invariante: disponibles <= total siempre', () {
    void check(HandRange range, List<Card> hero, List<Card> board) {
      final total = _total(range, board);
      final available = _available(range, hero, board);
      expect(available, lessThanOrEqualTo(total));
      expect(available, greaterThanOrEqualTo(0));
      expect(available + _blocked(range, hero, board), total);
    }

    test('AA con 1 carta muerta del héroe', () {
      check(HandRange.parse(const ['AA']), _cards('As'), _cards('7d'));
    });

    test('AKs+AKo con héroe AsKs y board AhKd', () {
      check(
        HandRange.parse(const ['AKs', 'AKo']),
        _cards('AsKs'),
        _cards('AhKd'),
      );
    });

    test('QQ+KK+AA con hero AhKd y board Qc', () {
      check(
        HandRange.parse(const ['QQ', 'KK', 'AA']),
        _cards('AhKd'),
        _cards('Qc'),
      );
    });
  });
}
