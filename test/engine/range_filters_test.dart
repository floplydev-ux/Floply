import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/screens/tools/range/range_filters.dart';

void main() {
  group('RangeTypeFilter', () {
    test('pocketPairs matchea solo pares', () {
      expect(RangeTypeFilter.pocketPairs.matches('AA'), isTrue);
      expect(RangeTypeFilter.pocketPairs.matches('AKs'), isFalse);
    });

    test('suited/offsuit son mutuamente excluyentes', () {
      expect(RangeTypeFilter.suited.matches('AKs'), isTrue);
      expect(RangeTypeFilter.suited.matches('AKo'), isFalse);
      expect(RangeTypeFilter.offsuit.matches('AKo'), isTrue);
      expect(RangeTypeFilter.offsuit.matches('AKs'), isFalse);
    });

    test('broadways requiere ambas cartas T+', () {
      expect(RangeTypeFilter.broadways.matches('AKo'), isTrue);
      expect(RangeTypeFilter.broadways.matches('KTs'), isTrue);
      expect(RangeTypeFilter.broadways.matches('K9s'), isFalse);
    });

    test('conectores suited tienen gap 1, gappers suited gap 2', () {
      expect(RangeTypeFilter.suitedConnectors.matches('KQs'), isTrue);
      expect(RangeTypeFilter.suitedConnectors.matches('KQo'), isFalse);
      expect(RangeTypeFilter.suitedGappers.matches('KJs'), isTrue);
      expect(RangeTypeFilter.suitedGappers.matches('KQs'), isFalse);
    });

    test('aceX/kingX excluyen pares', () {
      expect(RangeTypeFilter.aceX.matches('A5s'), isTrue);
      expect(RangeTypeFilter.aceX.matches('AA'), isFalse);
      expect(RangeTypeFilter.kingX.matches('KQo'), isTrue);
      expect(RangeTypeFilter.kingX.matches('AKo'), isFalse);
    });
  });

  group('RangeActionFilter', () {
    test('raise/mixed/fold cubren todo el rango 0..1 sin solaparse', () {
      expect(RangeActionFilter.raise.matches(1.0), isTrue);
      expect(RangeActionFilter.mixed.matches(0.5), isTrue);
      expect(RangeActionFilter.fold.matches(0.0), isTrue);
      expect(RangeActionFilter.raise.matches(0.99), isFalse);
      expect(RangeActionFilter.fold.matches(0.01), isFalse);
    });
  });

  group('RangeFrequencyBucket', () {
    test('las 6 bandas son contiguas y no se solapan', () {
      expect(RangeFrequencyBucket.full.matches(1.0), isTrue);
      expect(RangeFrequencyBucket.high.matches(0.8), isTrue);
      expect(RangeFrequencyBucket.mid.matches(0.6), isTrue);
      expect(RangeFrequencyBucket.low.matches(0.3), isTrue);
      expect(RangeFrequencyBucket.veryLow.matches(0.1), isTrue);
      expect(RangeFrequencyBucket.zero.matches(0.0), isTrue);
      // Bordes: 0.75 es "high", no "mid".
      expect(RangeFrequencyBucket.high.matches(0.75), isTrue);
      expect(RangeFrequencyBucket.mid.matches(0.75), isFalse);
    });
  });

  group('RangeFilters combinados', () {
    test('vacío no filtra nada', () {
      const filters = RangeFilters();
      expect(filters.isEmpty, isTrue);
      expect(filters.matches('72o', 0.0), isTrue);
    });

    test('mismo eje combina con OR', () {
      final filters = const RangeFilters().toggleType(RangeTypeFilter.pocketPairs).toggleType(RangeTypeFilter.suited);
      expect(filters.matches('AA', 1.0), isTrue); // par
      expect(filters.matches('AKs', 1.0), isTrue); // suited
      expect(filters.matches('AKo', 1.0), isFalse); // ninguno de los dos
    });

    test('ejes distintos combinan con AND', () {
      final filters = const RangeFilters()
          .toggleType(RangeTypeFilter.suited)
          .toggleAction(RangeActionFilter.raise);
      expect(filters.matches('AKs', 1.0), isTrue); // suited Y raise
      expect(filters.matches('AKs', 0.5), isFalse); // suited pero mixed, no raise
      expect(filters.matches('AKo', 1.0), isFalse); // raise pero no suited
    });

    test('toggle es reversible (tocar dos veces vuelve al estado original)', () {
      final once = const RangeFilters().toggleType(RangeTypeFilter.pocketPairs);
      final twice = once.toggleType(RangeTypeFilter.pocketPairs);
      expect(twice.types, isEmpty);
    });
  });
}
