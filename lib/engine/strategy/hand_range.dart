import '../poker/card.dart';
import '../poker/hole_cards.dart';

/// Un rango de manos con frecuencia por clase (`AKs -> 1.0`, `KJo -> 0.5`).
///
/// Se construye a partir de notación estándar de rangos y sabe responder
/// dos preguntas centrales del motor:
///  * ¿esta mano está en el rango? (y con qué frecuencia)
///  * ¿cuántas combinaciones cubre? (para comparar amplitud)
class HandRange {
  HandRange(this._frequencies);

  /// Rango vacío.
  HandRange.empty() : _frequencies = {};

  final Map<String, double> _frequencies;

  Map<String, double> get frequencies => Map.unmodifiable(_frequencies);

  /// Clases de mano incluidas al menos parcialmente.
  Set<String> get classes => _frequencies.keys.toSet();

  bool contains(String notation) => frequencyOf(notation) > 0;

  bool containsHand(HoleCards hand) => contains(hand.notation);

  /// Frecuencia con la que el rango juega esta clase (0.0 .. 1.0).
  double frequencyOf(String notation) => _frequencies[notation] ?? 0.0;

  double frequencyOfHand(HoleCards hand) => frequencyOf(hand.notation);

  /// Suma de combinaciones concretas (ponderadas por frecuencia).
  /// Un rango "todas las manos" da 1326.
  double get comboCount {
    var total = 0.0;
    _frequencies.forEach((notation, freq) {
      total += HandClass.parse(notation).combos * freq;
    });
    return total;
  }

  /// Porcentaje del total de manos (0..100) que representa el rango.
  double get percentOfAllHands => comboCount / 1326 * 100;

  /// Une dos rangos quedándose con la frecuencia más alta por clase.
  HandRange merge(HandRange other) {
    final result = Map<String, double>.of(_frequencies);
    other._frequencies.forEach((k, v) {
      result[k] = v > (result[k] ?? 0) ? v : result[k]!;
    });
    return HandRange(result);
  }

  /// Parsea una lista de tokens de rango, cada uno con una frecuencia
  /// opcional entre paréntesis: `['77+', 'ATs+', 'KQo(0.5)']`.
  ///
  /// Tokens soportados:
  ///  * `AA`            par exacto
  ///  * `77+`           ese par y todos los mayores
  ///  * `AKs` / `AKo`   una clase suited/offsuit
  ///  * `ATs+`          fija la carta alta, el kicker sube hasta A-1
  ///  * `KJo+`          idem para offsuit
  ///  * `A5s-A2s`       rango explícito con carta alta fija
  factory HandRange.parse(List<String> tokens) {
    final freqs = <String, double>{};

    for (final raw in tokens) {
      var token = raw.trim();
      if (token.isEmpty) continue;

      var frequency = 1.0;
      final freqMatch = RegExp(r'\(([0-9]*\.?[0-9]+)\)$').firstMatch(token);
      if (freqMatch != null) {
        frequency = double.parse(freqMatch.group(1)!);
        token = token.substring(0, freqMatch.start).trim();
      }

      for (final notation in _expandToken(token)) {
        final existing = freqs[notation] ?? 0.0;
        if (frequency > existing) freqs[notation] = frequency;
      }
    }

    return HandRange(freqs);
  }

  static List<String> _expandToken(String token) {
    // Rango explícito: "A5s-A2s".
    if (token.contains('-')) {
      final parts = token.split('-');
      if (parts.length == 2) {
        return _expandDashRange(parts[0].trim(), parts[1].trim());
      }
    }

    final plus = token.endsWith('+');
    final body = plus ? token.substring(0, token.length - 1) : token;

    // Par: "AA" o "77+".
    if (body.length == 2 && body[0] == body[1]) {
      final rank = Rank.fromLetter(body[0]);
      if (!plus) return ['${rank.letter}${rank.letter}'];
      return [
        for (final r in Rank.values)
          if (r.value >= rank.value) '${r.letter}${r.letter}',
      ];
    }

    // Suited / offsuit: "AKs", "KJo+".
    if (body.length == 3) {
      final hi = Rank.fromLetter(body[0]);
      final lo = Rank.fromLetter(body[1]);
      final suit = body[2].toLowerCase();
      if (hi.value <= lo.value) {
        throw FormatException('Token de rango inválido: "$token"');
      }
      if (!plus) return ['${hi.letter}${lo.letter}$suit'];
      return [
        for (final r in Rank.values)
          if (r.value >= lo.value && r.value < hi.value)
            '${hi.letter}${r.letter}$suit',
      ];
    }

    throw FormatException('Token de rango no reconocido: "$token"');
  }

  static List<String> _expandDashRange(String from, String to) {
    if (from.length != 3 || to.length != 3) {
      throw FormatException('Rango con guion inválido: "$from-$to"');
    }
    final hi = Rank.fromLetter(from[0]);
    final suit = from[2].toLowerCase();
    if (to[0].toUpperCase() != hi.letter || to[2].toLowerCase() != suit) {
      throw FormatException('Rango con guion inconsistente: "$from-$to"');
    }
    final k1 = Rank.fromLetter(from[1]).value;
    final k2 = Rank.fromLetter(to[1]).value;
    final lowK = k1 < k2 ? k1 : k2;
    final highK = k1 < k2 ? k2 : k1;
    return [
      for (final r in Rank.values)
        if (r.value >= lowK && r.value <= highK && r.value < hi.value)
          '${hi.letter}${r.letter}$suit',
    ];
  }

  @override
  String toString() =>
      'HandRange(${_frequencies.length} clases, ${percentOfAllHands.toStringAsFixed(1)}%)';
}
