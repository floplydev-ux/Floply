import '../poker/position.dart';
import 'hand_range.dart';

/// Rangos de apertura (Raise First In) para 6-max, ~100bb, cash.
///
/// Son rangos de referencia con fines pedagógicos: no pretenden ser una
/// solución GTO exacta, sino rangos coherentes y ampliamente aceptados,
/// suficientes para enseñar posición y selección de manos. Se pueden
/// afinar más adelante sin tocar el motor.
class OpeningRanges {
  OpeningRanges._();

  static final Map<Position, HandRange> _byPosition = {
    Position.utg: HandRange.parse(const [
      '55+', '44(0.5)',
      'ATs+', 'A5s-A2s', 'KTs+', 'QTs+', 'JTs', 'T9s', '98s',
      'AJo+', 'KQo', 'KJo(0.5)', 'ATo(0.5)',
    ]),
    Position.hj: HandRange.parse(const [
      '44+', '33(0.5)',
      'A9s+', 'A5s-A2s', 'K9s+', 'Q9s+', 'JTs', 'T9s', '98s', '87s', '76s(0.5)',
      'ATo+', 'KJo+', 'QJo', 'KTo(0.5)',
    ]),
    Position.co: HandRange.parse(const [
      '22+',
      'A2s+', 'K7s+', 'Q9s+', 'J9s+', 'T8s+', '97s+', '86s+', '76s', '65s', '54s',
      'K6s(0.5)', 'Q8s(0.5)', '75s(0.5)',
      'A9o+', 'KTo+', 'QTo+', 'JTo', 'A8o(0.5)', 'K9o(0.5)', 'Q9o(0.5)',
    ]),
    Position.btn: HandRange.parse(const [
      '22+',
      'A2s+', 'K5s+', 'Q7s+', 'J8s+', 'T7s+', '96s+', '85s+', '75s+', '64s+', '54s',
      'K4s(0.5)', 'Q6s(0.5)', 'J7s(0.5)', '53s(0.5)', '43s(0.5)',
      'A2o+', 'K8o+', 'Q9o+', 'J9o+', 'T9o', '98o',
      'K7o(0.5)', 'Q8o(0.5)', 'J8o(0.5)', 'T8o(0.5)', '87o(0.5)',
    ]),
    Position.sb: HandRange.parse(const [
      '22+',
      'A2s+', 'K6s+', 'Q8s+', 'J8s+', 'T8s+', '97s+', '86s+', '75s+', '65s', '54s',
      'K5s(0.5)', 'Q7s(0.5)', '64s(0.5)',
      'A7o+', 'A5o-A2o', 'K9o+', 'QTo+', 'JTo',
      'A6o(0.5)', 'K8o(0.5)', 'Q9o(0.5)', 'J9o(0.5)',
    ]),
  };

  /// Rango de apertura para [position]. La BB no abre, así que devuelve
  /// un rango vacío.
  static HandRange forPosition(Position position) =>
      _byPosition[position] ?? HandRange.empty();

  /// Tamaño de apertura estándar (en BB) para cada posición.
  static double sizingFor(Position position) =>
      position == Position.sb ? 3.0 : 2.5;

  /// Tamaños de apertura defendibles (viables aunque no preferidos).
  static bool isReasonableSizing(Position position, double sizeBb) {
    if (position == Position.sb) return sizeBb >= 2.5 && sizeBb <= 3.5;
    return sizeBb >= 2.0 && sizeBb <= 3.0;
  }
}
