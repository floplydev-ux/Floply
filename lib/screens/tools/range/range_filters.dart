import '../../../engine/poker/card.dart';

/// Filtros de tipo de mano (sección 15). Se evalúan sobre la notación
/// (`'AKs'`, `'77'`, `'T9o'`...), reutilizando `Rank.fromLetter` tal cual
/// ya lo usa `HandRange`/`HandClass` — sin un segundo parser de rangos.
enum RangeTypeFilter {
  pocketPairs,
  suited,
  offsuit,
  broadways,
  suitedConnectors,
  suitedGappers,
  aceX,
  kingX,
  queenX,
  jackX;

  String get label => switch (this) {
        RangeTypeFilter.pocketPairs => 'Pares',
        RangeTypeFilter.suited => 'Suited',
        RangeTypeFilter.offsuit => 'Offsuit',
        RangeTypeFilter.broadways => 'Broadways',
        RangeTypeFilter.suitedConnectors => 'Conectores suited',
        RangeTypeFilter.suitedGappers => 'Gappers suited',
        RangeTypeFilter.aceX => 'A-x',
        RangeTypeFilter.kingX => 'K-x',
        RangeTypeFilter.queenX => 'Q-x',
        RangeTypeFilter.jackX => 'J-x',
      };

  bool matches(String notation) {
    final isPair = notation.length == 2;
    final isSuited = notation.endsWith('s');
    switch (this) {
      case RangeTypeFilter.pocketPairs:
        return isPair;
      case RangeTypeFilter.suited:
        return !isPair && isSuited;
      case RangeTypeFilter.offsuit:
        return !isPair && !isSuited;
      case RangeTypeFilter.broadways:
        final hi = Rank.fromLetter(notation[0]);
        final lo = Rank.fromLetter(notation[1]);
        return hi.value >= Rank.ten.value && lo.value >= Rank.ten.value;
      case RangeTypeFilter.suitedConnectors:
        if (isPair || !isSuited) return false;
        final hi = Rank.fromLetter(notation[0]);
        final lo = Rank.fromLetter(notation[1]);
        return hi.value - lo.value == 1;
      case RangeTypeFilter.suitedGappers:
        if (isPair || !isSuited) return false;
        final hi = Rank.fromLetter(notation[0]);
        final lo = Rank.fromLetter(notation[1]);
        return hi.value - lo.value == 2;
      case RangeTypeFilter.aceX:
        return !isPair && notation[0] == 'A';
      case RangeTypeFilter.kingX:
        return !isPair && notation[0] == 'K';
      case RangeTypeFilter.queenX:
        return !isPair && notation[0] == 'Q';
      case RangeTypeFilter.jackX:
        return !isPair && notation[0] == 'J';
    }
  }
}

/// Filtro por acción dominante (sección 15) — binario sobre la
/// frecuencia real de `HandRange`, no una acción declarada aparte.
enum RangeActionFilter {
  raise,
  mixed,
  fold;

  String get label => switch (this) {
        RangeActionFilter.raise => 'Raise',
        RangeActionFilter.mixed => 'Mixed',
        RangeActionFilter.fold => 'Fold',
      };

  bool matches(double frequency) => switch (this) {
        RangeActionFilter.raise => frequency >= 1.0,
        RangeActionFilter.mixed => frequency > 0 && frequency < 1.0,
        RangeActionFilter.fold => frequency <= 0,
      };
}

/// Bandas de frecuencia (sección 15).
enum RangeFrequencyBucket {
  full,
  high,
  mid,
  low,
  veryLow,
  zero;

  String get label => switch (this) {
        RangeFrequencyBucket.full => '100%',
        RangeFrequencyBucket.high => '75–99%',
        RangeFrequencyBucket.mid => '50–74%',
        RangeFrequencyBucket.low => '25–49%',
        RangeFrequencyBucket.veryLow => '1–24%',
        RangeFrequencyBucket.zero => '0%',
      };

  bool matches(double frequency) => switch (this) {
        RangeFrequencyBucket.full => frequency >= 1.0,
        RangeFrequencyBucket.high => frequency >= 0.75 && frequency < 1.0,
        RangeFrequencyBucket.mid => frequency >= 0.5 && frequency < 0.75,
        RangeFrequencyBucket.low => frequency >= 0.25 && frequency < 0.5,
        RangeFrequencyBucket.veryLow => frequency > 0 && frequency < 0.25,
        RangeFrequencyBucket.zero => frequency <= 0,
      };
}

/// Combinación de los 3 ejes de filtro — vacíos = sin filtrar (todo pasa).
/// Dentro de un mismo eje los filtros se combinan con OR (p. ej. "Pares o
/// Suited"); entre ejes distintos, con AND (sección 15: "los filtros
/// deben combinarse correctamente").
class RangeFilters {
  const RangeFilters({
    this.types = const {},
    this.actions = const {},
    this.frequencyBuckets = const {},
  });

  final Set<RangeTypeFilter> types;
  final Set<RangeActionFilter> actions;
  final Set<RangeFrequencyBucket> frequencyBuckets;

  bool get isEmpty => types.isEmpty && actions.isEmpty && frequencyBuckets.isEmpty;

  bool matches(String notation, double frequency) {
    if (types.isNotEmpty && !types.any((f) => f.matches(notation))) return false;
    if (actions.isNotEmpty && !actions.any((f) => f.matches(frequency))) return false;
    if (frequencyBuckets.isNotEmpty &&
        !frequencyBuckets.any((f) => f.matches(frequency))) {
      return false;
    }
    return true;
  }

  RangeFilters toggleType(RangeTypeFilter f) => RangeFilters(
        types: _toggled(types, f),
        actions: actions,
        frequencyBuckets: frequencyBuckets,
      );

  RangeFilters toggleAction(RangeActionFilter f) => RangeFilters(
        types: types,
        actions: _toggled(actions, f),
        frequencyBuckets: frequencyBuckets,
      );

  RangeFilters toggleFrequency(RangeFrequencyBucket f) => RangeFilters(
        types: types,
        actions: actions,
        frequencyBuckets: _toggled(frequencyBuckets, f),
      );

  static Set<T> _toggled<T>(Set<T> set, T value) {
    final result = Set<T>.of(set);
    if (!result.add(value)) result.remove(value);
    return result;
  }
}
