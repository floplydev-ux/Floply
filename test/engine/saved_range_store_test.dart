import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/strategy/saved_range.dart';
import 'package:poker_trainer/persistence/saved_range_store.dart';

SavedRange _range(String id, String name) => SavedRange(
      id: id,
      name: name,
      frequencies: const {'AA': 1.0},
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('loadAll de un store vacío devuelve una lista vacía', () async {
    final store = InMemorySavedRangeStore();
    expect(await store.loadAll(), isEmpty);
  });

  test('saveAll sobrevive a una nueva lectura (mismo store)', () async {
    final store = InMemorySavedRangeStore();
    await store.saveAll([_range('1', 'Uno'), _range('2', 'Dos')]);

    final reloaded = await store.loadAll();

    expect(reloaded.map((r) => r.name), ['Uno', 'Dos']);
  });

  test('saveAll reemplaza la lista completa, no la acumula', () async {
    final store = InMemorySavedRangeStore();
    await store.saveAll([_range('1', 'Uno')]);
    await store.saveAll([_range('2', 'Dos')]);

    final reloaded = await store.loadAll();

    expect(reloaded.length, 1);
    expect(reloaded.single.name, 'Dos');
  });
}
