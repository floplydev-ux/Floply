import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/position.dart';
import 'package:poker_trainer/engine/strategy/opening_ranges.dart';
import 'package:poker_trainer/engine/strategy/opening_ranges_data.g.dart';

/// Fija los valores de referencia (rangos, sizing) tal cual estaban
/// hardcodeados en Dart antes de migrar `OpeningRanges` a datos
/// (`assets/ranges/opening_ranges.json` + `opening_ranges_data.g.dart`,
/// mismo patrón que ya usa el currículo de la Academia). El objetivo de
/// esta suite es que un cambio accidental en el JSON o en el generador
/// se note acá — no repite los tests generales de `HandRange`, que ya
/// existen en `hand_range_test.dart`.
void main() {
  group('OpeningRanges — las 5 posiciones que abren', () {
    test('la BB no tiene rango de apertura propio (rango vacío)', () {
      expect(OpeningRanges.forPosition(Position.bb).comboCount, 0);
    });

    test('las 5 posiciones que sí abren tienen datos en el JSON generado', () {
      for (final position in [
        Position.utg,
        Position.hj,
        Position.co,
        Position.btn,
        Position.sb,
      ]) {
        expect(kOpeningRangeTokens.containsKey(position.name), isTrue,
            reason: position.name);
        expect(OpeningRanges.forPosition(position).comboCount, greaterThan(0),
            reason: position.name);
      }
    });
  });

  group('OpeningRanges.forPosition — manos de referencia sin cambios', () {
    test('UTG abre AA a frecuencia 1.0 y descarta 72o', () {
      final utg = OpeningRanges.forPosition(Position.utg);
      expect(utg.frequencyOf('AA'), 1.0);
      expect(utg.frequencyOf('72o'), 0.0);
      expect(utg.frequencyOf('44'), 0.5, reason: 'mixta, como en el Dart original');
    });

    test('BTN abre mucho más ancho que UTG (más posiciones detrás)', () {
      final utg = OpeningRanges.forPosition(Position.utg);
      final btn = OpeningRanges.forPosition(Position.btn);
      expect(btn.comboCount, greaterThan(utg.comboCount));
      // 22 está en BTN pero no en UTG.
      expect(btn.frequencyOf('22'), 1.0);
      expect(utg.frequencyOf('22'), 0.0);
    });

    test('SB tiene su propio rango, más angosto que BTN pero incluye 22', () {
      final sb = OpeningRanges.forPosition(Position.sb);
      expect(sb.frequencyOf('22'), 1.0);
      expect(sb.frequencyOf('A5o'), 1.0, reason: "'A5o-A2o' en el token original");
      expect(sb.frequencyOf('A4o'), 1.0);
      expect(sb.frequencyOf('A6o'), 0.5, reason: "'A6o(0.5)' en el token original");
    });

    test('CO incluye 76s a frecuencia 1.0 (no mixta)', () {
      expect(OpeningRanges.forPosition(Position.co).frequencyOf('76s'), 1.0);
    });
  });

  group('OpeningRanges.sizingFor', () {
    test('SB abre a 3.0bb, el resto de las que abren a 2.5bb', () {
      expect(OpeningRanges.sizingFor(Position.sb), 3.0);
      for (final position in [Position.utg, Position.hj, Position.co, Position.btn]) {
        expect(OpeningRanges.sizingFor(position), 2.5, reason: position.name);
      }
    });

    test('la BB (sin entrada propia) cae al default de 2.5bb', () {
      expect(OpeningRanges.sizingFor(Position.bb), 2.5);
    });
  });

  group('OpeningRanges.isReasonableSizing', () {
    test('SB acepta 2.5-3.5bb', () {
      expect(OpeningRanges.isReasonableSizing(Position.sb, 2.5), isTrue);
      expect(OpeningRanges.isReasonableSizing(Position.sb, 3.5), isTrue);
      expect(OpeningRanges.isReasonableSizing(Position.sb, 2.4), isFalse);
      expect(OpeningRanges.isReasonableSizing(Position.sb, 3.6), isFalse);
    });

    test('el resto acepta 2.0-3.0bb', () {
      for (final position in [Position.utg, Position.hj, Position.co, Position.btn]) {
        expect(OpeningRanges.isReasonableSizing(position, 2.0), isTrue, reason: position.name);
        expect(OpeningRanges.isReasonableSizing(position, 3.0), isTrue, reason: position.name);
        expect(OpeningRanges.isReasonableSizing(position, 1.9), isFalse, reason: position.name);
        expect(OpeningRanges.isReasonableSizing(position, 3.1), isFalse, reason: position.name);
      }
    });

    test('la BB (sin entrada propia) cae al default 2.0-3.0bb', () {
      expect(OpeningRanges.isReasonableSizing(Position.bb, 2.0), isTrue);
      expect(OpeningRanges.isReasonableSizing(Position.bb, 3.5), isFalse);
    });
  });
}
