import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/scripts/table_builder.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';

// `Street.flop` representa acá cualquier calle postflop: `order()` da la
// misma rotación (arranca en SB) para flop/turn/river — ver el comentario
// de `TablePositions.order`.

void main() {
  group('TablePositions.positionOf', () {
    test('con buttonSlot 0, reconstruye exactamente TableBuilder.btnHero', () {
      final p = TablePositions(0);
      for (final entry in TableBuilder.btnHero.entries) {
        expect(p.positionOf(entry.key).label, entry.value,
            reason: 'slot ${entry.key}');
      }
    });

    test('con buttonSlot 3, reconstruye exactamente TableBuilder.utgHero', () {
      final p = TablePositions(3);
      for (final entry in TableBuilder.utgHero.entries) {
        expect(p.positionOf(entry.key).label, entry.value,
            reason: 'slot ${entry.key}');
      }
    });

    test('BTN/SB/BB/UTG/HJ/CO correctos para cada buttonSlot posible', () {
      for (var btn = 0; btn < 6; btn++) {
        final p = TablePositions(btn);
        expect(p.positionOf(btn), Position.btn, reason: 'btn=$btn');
        expect(p.positionOf((btn - 1) % 6), Position.sb, reason: 'btn=$btn');
        expect(p.positionOf((btn - 2) % 6), Position.bb, reason: 'btn=$btn');
        expect(p.positionOf((btn - 3) % 6), Position.utg, reason: 'btn=$btn');
        expect(p.positionOf((btn - 4) % 6), Position.hj, reason: 'btn=$btn');
        expect(p.positionOf((btn - 5) % 6), Position.co, reason: 'btn=$btn');
      }
    });

    test('slotOf es la inversa de positionOf para cualquier buttonSlot', () {
      for (var btn = 0; btn < 6; btn++) {
        final p = TablePositions(btn);
        for (final pos in Position.values) {
          expect(p.positionOf(p.slotOf(pos)), pos, reason: 'btn=$btn $pos');
        }
      }
    });
  });

  group('orden de acción', () {
    test('preflop: UTG → HJ → CO → BTN → SB → BB', () {
      final p = TablePositions(0); // héroe/BTN en slot 0, como btnHero
      final order = p.order(Street.preflop).map(p.positionOf).toList();
      expect(order, [
        Position.utg,
        Position.hj,
        Position.co,
        Position.btn,
        Position.sb,
        Position.bb,
      ]);
    });

    test('postflop: SB → BB → UTG → HJ → CO → BTN', () {
      final p = TablePositions(0);
      final order = p.order(Street.flop).map(p.positionOf).toList();
      expect(order, [
        Position.sb,
        Position.bb,
        Position.utg,
        Position.hj,
        Position.co,
        Position.btn,
      ]);
    });

    test('el orden es el mismo ciclo sin importar el buttonSlot', () {
      for (var btn = 0; btn < 6; btn++) {
        final p = TablePositions(btn);
        expect(
            p.order(Street.preflop).map(p.positionOf),
            [
              Position.utg,
              Position.hj,
              Position.co,
              Position.btn,
              Position.sb,
              Position.bb,
            ],
            reason: 'btn=$btn');
        expect(
            p.order(Street.flop).map(p.positionOf),
            [
              Position.sb,
              Position.bb,
              Position.utg,
              Position.hj,
              Position.co,
              Position.btn,
            ],
            reason: 'btn=$btn');
      }
    });
  });

  group('jugadores foldeados / vacíos', () {
    test('un foldeado desaparece del orden activo mas sigue existiendo', () {
      final p = TablePositions(0);
      final sbSlot = p.slotOf(Position.sb);
      final active =
          p.activeOrder(Street.flop, folded: {sbSlot}).map(p.positionOf);
      expect(active, [
        Position.bb,
        Position.utg,
        Position.hj,
        Position.co,
        Position.btn,
      ]);
      expect(active.contains(Position.sb), isFalse);
    });

    test('varios folds: el orden activo solo tiene a los que siguen en pie',
        () {
      final p = TablePositions(0);
      final folded = {
        p.slotOf(Position.utg),
        p.slotOf(Position.hj),
        p.slotOf(Position.co),
      };
      final active = p
          .activeOrder(Street.preflop, folded: folded)
          .map(p.positionOf)
          .toList();
      expect(active, [Position.btn, Position.sb, Position.bb]);
    });

    test(
        'la mano del enunciado: UTG/HJ/CO/SB foldean preflop, en el flop '
        'solo actúan BB y BTN, en ese orden', () {
      final p = TablePositions(0); // hero BTN en slot 0
      final folded = {
        p.slotOf(Position.utg),
        p.slotOf(Position.hj),
        p.slotOf(Position.co),
        p.slotOf(Position.sb),
      };
      final active = p
          .activeOrder(Street.flop, folded: folded)
          .map(p.positionOf)
          .toList();
      expect(active, [Position.bb, Position.btn]);
    });

    test('asiento vacío también se excluye del orden activo', () {
      final p = TablePositions(0);
      final coSlot = p.slotOf(Position.co);
      final active =
          p.activeOrder(Street.preflop, empty: {coSlot}).map(p.positionOf);
      expect(active.contains(Position.co), isFalse);
      expect(active.length, 5);
    });
  });

  group('cambio de botón', () {
    test(
        'mover el botón un asiento (en sentido horario) avanza cada '
        'posición un lugar, como en una mesa real', () {
      final before = TablePositions(0);
      final after = TablePositions(1); // el botón avanza al slot 1
      expect(before.positionOf(0), Position.btn);
      expect(after.positionOf(1), Position.btn);
      // BTN → SB, SB → BB, BB → UTG, UTG → HJ, HJ → CO, CO → BTN: cada
      // asiento hereda la posición del que tenía antes "un lugar atrás".
      expect(before.positionOf(0), Position.btn);
      expect(after.positionOf(0), Position.sb); // el viejo BTN
      expect(before.positionOf(5), Position.sb);
      expect(after.positionOf(5), Position.bb); // el viejo SB
      expect(before.positionOf(4), Position.bb);
      expect(after.positionOf(4), Position.utg); // el viejo BB
      expect(before.positionOf(1), Position.co);
      expect(after.positionOf(1), Position.btn); // el viejo CO
    });
  });

  group('nextToAct', () {
    test('recorre toda la mesa activa en sentido correcto (preflop)', () {
      final p = TablePositions(0);
      final utg = p.slotOf(Position.utg);
      var cur = utg;
      final seen = <Position>[p.positionOf(cur)];
      for (var i = 0; i < 5; i++) {
        final n = p.nextToAct(cur, Street.preflop);
        expect(n, isNotNull);
        seen.add(p.positionOf(n!));
        cur = n;
      }
      expect(seen, [
        Position.utg,
        Position.hj,
        Position.co,
        Position.btn,
        Position.sb,
        Position.bb,
      ]);
      // Este modelo es una rotación, no un motor de rondas de apuesta: no
      // sabe "quién ya actuó". Sin folds, después de BB la rotación sigue
      // (correcto si la acción reabre, p. ej. BB sube) y vuelve a UTG.
      final afterBb = p.nextToAct(cur, Street.preflop);
      expect(afterBb, p.slotOf(Position.utg));
    });

    test('salta correctamente a los foldeados', () {
      final p = TablePositions(0);
      final folded = {p.slotOf(Position.hj), p.slotOf(Position.co)};
      final afterUtg =
          p.nextToAct(p.slotOf(Position.utg), Street.preflop, folded: folded);
      expect(p.positionOf(afterUtg!), Position.btn);
    });

    test('devuelve null cuando queda un solo jugador activo', () {
      final p = TablePositions(0);
      final folded = {
        p.slotOf(Position.sb),
        p.slotOf(Position.bb),
        p.slotOf(Position.utg),
        p.slotOf(Position.hj),
        p.slotOf(Position.co),
      };
      final n =
          p.nextToAct(p.slotOf(Position.btn), Street.flop, folded: folded);
      expect(n, isNull);
    });

    test('firstToAct respeta folds', () {
      final p = TablePositions(0);
      final utgSlot = p.slotOf(Position.utg);
      final first = p.firstToAct(Street.preflop, folded: {utgSlot});
      expect(p.positionOf(first!), Position.hj);
    });
  });
}
