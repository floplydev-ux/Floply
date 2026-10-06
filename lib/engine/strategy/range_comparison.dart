import '../poker/hole_cards.dart';
import 'hand_range.dart';

/// Diferencia de una clase de mano puntual entre dos rangos (sección 19
/// del pedido de Rangos: "Range Compare").
class RangeHandDiff {
  const RangeHandDiff({
    required this.notation,
    required this.frequencyA,
    required this.frequencyB,
  });

  final String notation;
  final double frequencyA;
  final double frequencyB;

  bool get isAdded => frequencyA <= 0 && frequencyB > 0;
  bool get isRemoved => frequencyA > 0 && frequencyB <= 0;
  bool get isFrequencyChanged =>
      frequencyA > 0 && frequencyB > 0 && frequencyA != frequencyB;
  bool get isUnchanged => !isAdded && !isRemoved && !isFrequencyChanged;
}

/// Comparación completa entre dos rangos — recorre `HandClass.all()` (el
/// mismo orden canónico que ya usa `ComboEngine.combosForRange`), no las
/// claves internas de cada `HandRange`, para que el resultado sea
/// determinista sin importar cómo se construyó cada rango.
class RangeComparison {
  const RangeComparison._(this.diffs);

  final List<RangeHandDiff> diffs;

  factory RangeComparison.compute(HandRange a, HandRange b) {
    final diffs = [
      for (final handClass in HandClass.all())
        RangeHandDiff(
          notation: handClass.notation,
          frequencyA: a.frequencyOf(handClass.notation),
          frequencyB: b.frequencyOf(handClass.notation),
        ),
    ];
    return RangeComparison._(diffs);
  }

  List<RangeHandDiff> get added => diffs.where((d) => d.isAdded).toList();
  List<RangeHandDiff> get removed => diffs.where((d) => d.isRemoved).toList();
  List<RangeHandDiff> get changed =>
      diffs.where((d) => d.isFrequencyChanged).toList();

  int get addedCount => added.length;
  int get removedCount => removed.length;
  int get changedCount => changed.length;

  RangeHandDiff? diffOf(String notation) {
    for (final d in diffs) {
      if (d.notation == notation) return d;
    }
    return null;
  }
}
