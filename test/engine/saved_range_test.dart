import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/poker/position.dart';
import 'package:poker_trainer/engine/strategy/range_context.dart';
import 'package:poker_trainer/engine/strategy/saved_range.dart';

void main() {
  test('toJson/fromJson hace un roundtrip fiel', () {
    final original = SavedRange(
      id: 'abc123',
      name: 'BTN Open — NL2',
      frequencies: const {'AA': 1.0, 'A5s': 0.5},
      position: Position.btn,
      situation: RangeSituation.openRaise,
      basedOnOfficialId: 'open_raise_btn',
      createdAt: DateTime(2026, 1, 1, 10),
      updatedAt: DateTime(2026, 1, 2, 11),
    );

    final restored = SavedRange.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.frequencies, original.frequencies);
    expect(restored.position, Position.btn);
    expect(restored.situation, RangeSituation.openRaise);
    expect(restored.basedOnOfficialId, 'open_raise_btn');
    expect(restored.createdAt, original.createdAt);
    expect(restored.updatedAt, original.updatedAt);
  });

  test('position/situation nulos sobreviven al roundtrip', () {
    final original = SavedRange(
      id: 'x',
      name: 'Desde cero',
      frequencies: const {'KK': 1.0},
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final restored = SavedRange.fromJson(original.toJson());

    expect(restored.position, isNull);
    expect(restored.situation, isNull);
    expect(restored.basedOnOfficialId, isNull);
  });

  test('toHandRange expone las mismas frecuencias', () {
    final saved = SavedRange(
      id: 'x',
      name: 'n',
      frequencies: const {'AA': 1.0, 'KQs': 0.25},
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final range = saved.toHandRange();

    expect(range.frequencyOf('AA'), 1.0);
    expect(range.frequencyOf('KQs'), 0.25);
    expect(range.frequencyOf('72o'), 0.0);
  });

  test('copyWith solo reemplaza los campos indicados', () {
    final saved = SavedRange(
      id: 'x',
      name: 'original',
      frequencies: const {'AA': 1.0},
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final renamed = saved.copyWith(name: 'nuevo nombre');

    expect(renamed.name, 'nuevo nombre');
    expect(renamed.frequencies, saved.frequencies);
    expect(renamed.id, saved.id);
  });
}
