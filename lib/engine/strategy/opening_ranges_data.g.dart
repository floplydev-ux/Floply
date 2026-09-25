// GENERADO por tool/ranges/gen_opening_ranges.dart — NO editar a mano.
// Fuente de verdad: assets/ranges/opening_ranges.json
// Regenerar tras cambiar el JSON: dart run tool/ranges/gen_opening_ranges.dart
//
// ignore_for_file: lines_longer_than_80_chars

/// Tokens de rango (notación `HandRange.parse`) por posición, tal cual
/// vienen del JSON — clave = `Position.name` (`utg`, `hj`, `co`, `btn`, `sb`).
const Map<String, List<String>> kOpeningRangeTokens = {
  'utg': ['55+', '44(0.5)', 'ATs+', 'A5s-A2s', 'KTs+', 'QTs+', 'JTs', 'T9s', '98s', 'AJo+', 'KQo', 'KJo(0.5)', 'ATo(0.5)'],
  'hj': ['44+', '33(0.5)', 'A9s+', 'A5s-A2s', 'K9s+', 'Q9s+', 'JTs', 'T9s', '98s', '87s', '76s(0.5)', 'ATo+', 'KJo+', 'QJo', 'KTo(0.5)'],
  'co': ['22+', 'A2s+', 'K7s+', 'Q9s+', 'J9s+', 'T8s+', '97s+', '86s+', '76s', '65s', '54s', 'K6s(0.5)', 'Q8s(0.5)', '75s(0.5)', 'A9o+', 'KTo+', 'QTo+', 'JTo', 'A8o(0.5)', 'K9o(0.5)', 'Q9o(0.5)'],
  'btn': ['22+', 'A2s+', 'K5s+', 'Q7s+', 'J8s+', 'T7s+', '96s+', '85s+', '75s+', '64s+', '54s', 'K4s(0.5)', 'Q6s(0.5)', 'J7s(0.5)', '53s(0.5)', '43s(0.5)', 'A2o+', 'K8o+', 'Q9o+', 'J9o+', 'T9o', '98o', 'K7o(0.5)', 'Q8o(0.5)', 'J8o(0.5)', 'T8o(0.5)', '87o(0.5)'],
  'sb': ['22+', 'A2s+', 'K6s+', 'Q8s+', 'J8s+', 'T8s+', '97s+', '86s+', '75s+', '65s', '54s', 'K5s(0.5)', 'Q7s(0.5)', '64s(0.5)', 'A7o+', 'A5o-A2o', 'K9o+', 'QTo+', 'JTo', 'A6o(0.5)', 'K8o(0.5)', 'Q9o(0.5)', 'J9o(0.5)'],
};

/// Tamaño de apertura estándar (BB) por posición.
const Map<String, double> kOpeningRangeSizingBb = {
  'utg': 2.5,
  'hj': 2.5,
  'co': 2.5,
  'btn': 2.5,
  'sb': 3.0,
};

/// Rango de tamaños defendibles (min, max) en BB, por posición.
const Map<String, (double, double)> kOpeningRangeSizingBounds = {
  'utg': (2.0, 3.0),
  'hj': (2.0, 3.0),
  'co': (2.0, 3.0),
  'btn': (2.0, 3.0),
  'sb': (2.5, 3.5),
};
