import 'card.dart';

/// Las dos cartas privadas del héroe.
///
/// Guarda las cartas concretas (`A♠ K♦`) pero también expone la
/// *clase* de mano (`AKo`, `AKs`, `77`), que es lo que usan los rangos.
class HoleCards {
  HoleCards(Card a, Card b)
      : // Orden canónico: primero la carta de rango más alto; a igual
        // rango, por palo, para que la representación sea estable.
        high = _higher(a, b),
        low = _lower(a, b) {
    // Chequeo real, no un `assert` — las manos se arman con cartas que
    // vienen de generación procedural (Deck/HandPicker), y esta
    // invariante tiene que sostenerse también en release.
    if (a == b) {
      throw ArgumentError('Las dos cartas del héroe no pueden ser iguales: $a');
    }
  }

  final Card high;
  final Card low;

  factory HoleCards.parse(String text) {
    final clean = text.replaceAll(' ', '');
    if (clean.length != 4) {
      throw FormatException('Mano inválida: "$text" (se esperaban 4 chars)');
    }
    return HoleCards(Card.parse(clean.substring(0, 2)), Card.parse(clean.substring(2)));
  }

  static Card _higher(Card a, Card b) {
    if (a.rank.value != b.rank.value) {
      return a.rank.value > b.rank.value ? a : b;
    }
    return a.suit.index <= b.suit.index ? a : b;
  }

  static Card _lower(Card a, Card b) => _higher(a, b) == a ? b : a;

  List<Card> get cards => [high, low];

  bool get isPair => high.rank == low.rank;
  bool get isSuited => high.suit == low.suit;
  bool get isOffsuit => !isPair && !isSuited;

  /// Diferencia de rango entre las dos cartas (0 para pares).
  int get gap => high.rank.value - low.rank.value;
  bool get isConnector => !isPair && gap == 1;

  /// La clase de mano en notación estándar: `AA`, `AKs`, `AKo`, `T9s`.
  String get notation {
    if (isPair) return '${high.rank.letter}${low.rank.letter}';
    return '${high.rank.letter}${low.rank.letter}${isSuited ? 's' : 'o'}';
  }

  /// Notación linda para la UI: `A♠ K♦`.
  String get pretty => '${high.pretty} ${low.pretty}';

  @override
  bool operator ==(Object other) =>
      other is HoleCards && other.high == high && other.low == low;

  @override
  int get hashCode => Object.hash(high, low);

  @override
  String toString() => '${high.code}${low.code}';
}

/// Utilidades sobre la notación de clases de mano (`AKs`, `77`, ...),
/// independientes de cartas concretas. Hay 169 clases distintas.
class HandClass {
  const HandClass._(this.notation);

  final String notation;

  static HandClass parse(String notation) {
    final n = notation.trim();
    if (!isValid(n)) {
      throw FormatException('Clase de mano inválida: "$notation"');
    }
    return HandClass._(n);
  }

  static bool isValid(String notation) {
    final n = notation.trim();
    if (n.length == 2) {
      return _rankOf(n[0]) != null && n[0] == n[1];
    }
    if (n.length == 3) {
      final r1 = _rankOf(n[0]);
      final r2 = _rankOf(n[1]);
      final t = n[2].toLowerCase();
      return r1 != null && r2 != null && r1 != r2 && (t == 's' || t == 'o');
    }
    return false;
  }

  static int? _rankOf(String letter) {
    try {
      return Rank.fromLetter(letter).value;
    } catch (_) {
      return null;
    }
  }

  bool get isPair => notation.length == 2;
  bool get isSuited => notation.endsWith('s');
  bool get isOffsuit => notation.endsWith('o');

  Rank get highRank => Rank.fromLetter(notation[0]);
  Rank get lowRank => Rank.fromLetter(notation[1]);

  /// Cuántas combinaciones concretas de cartas representa esta clase:
  /// 6 para pares, 4 para suited, 12 para offsuit. Total = 1326.
  int get combos {
    if (isPair) return 6;
    if (isSuited) return 4;
    return 12;
  }

  /// Las 169 clases de mano, ordenadas de forma estable.
  static List<HandClass> all() {
    final ranks = Rank.highToLow;
    final result = <HandClass>[];
    for (var i = 0; i < ranks.length; i++) {
      for (var j = 0; j < ranks.length; j++) {
        final hi = ranks[i];
        final lo = ranks[j];
        if (i == j) {
          result.add(HandClass._('${hi.letter}${lo.letter}'));
        } else if (i < j) {
          result.add(HandClass._('${hi.letter}${lo.letter}s'));
        } else {
          result.add(HandClass._('${lo.letter}${hi.letter}o'));
        }
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is HandClass && other.notation == notation;

  @override
  int get hashCode => notation.hashCode;

  @override
  String toString() => notation;
}
