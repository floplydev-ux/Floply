import '../poker/position.dart';
import 'hand_range.dart';
import 'opening_ranges_data.g.dart';

/// Rangos de apertura (Raise First In) para 6-max, ~100bb, cash.
///
/// Son rangos de referencia con fines pedagógicos: no pretenden ser una
/// solución GTO exacta, sino rangos coherentes y ampliamente aceptados,
/// suficientes para enseñar posición y selección de manos.
///
/// El contenido (qué manos entran en cada rango, el sizing) vive en
/// `assets/ranges/opening_ranges.json` — mismo patrón que ya usa el
/// currículo de la Academia (JSON como fuente de verdad, compilado a
/// `opening_ranges_data.g.dart` por `tool/ranges/gen_opening_ranges.dart`
/// para que esta clase lo siga leyendo de forma síncrona, sin I/O). Para
/// afinar un rango: editar el JSON y correr
/// `dart run tool/ranges/gen_opening_ranges.dart` — nunca tocar el
/// `.g.dart` a mano ni esta clase.
class OpeningRanges {
  OpeningRanges._();

  static final Map<Position, HandRange> _byPosition = {
    for (final entry in kOpeningRangeTokens.entries)
      Position.values.byName(entry.key): HandRange.parse(entry.value),
  };

  /// Rango de apertura para [position]. La BB no abre, así que devuelve
  /// un rango vacío (no tiene entrada en el JSON).
  static HandRange forPosition(Position position) =>
      _byPosition[position] ?? HandRange.empty();

  /// Tamaño de apertura estándar (en BB) para cada posición. `2.5` si
  /// [position] no tiene entrada propia (mismo default que tenía el
  /// `? :` de antes de esta migración, para la BB y cualquier posición
  /// futura sin dato explícito).
  static double sizingFor(Position position) =>
      kOpeningRangeSizingBb[position.name] ?? 2.5;

  /// Tamaños de apertura defendibles (viables aunque no preferidos).
  /// `[2.0, 3.0]` si [position] no tiene entrada propia — mismo default
  /// que el branch `else` de antes de esta migración.
  static bool isReasonableSizing(Position position, double sizeBb) {
    final (min, max) = reasonableSizingBounds(position);
    return sizeBb >= min && sizeBb <= max;
  }

  /// La banda `(mínimo, máximo)` defendible de [isReasonableSizing] — para
  /// quien necesite los bordes reales en vez de solo la pregunta sí/no
  /// (p. ej. `StrategyEngine._gradedRaiseOptions`, que arma las opciones
  /// de tamaño de apertura a partir de estos mismos bordes ya curados, en
  /// vez de inventar números nuevos).
  static (double, double) reasonableSizingBounds(Position position) =>
      kOpeningRangeSizingBounds[position.name] ?? (2.0, 3.0);
}
