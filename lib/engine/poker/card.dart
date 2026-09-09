/// Primitivas de cartas de póker: palo, rango y carta individual.
///
/// Es la base sobre la que se construyen manos, boards y todo el motor.
/// No depende de Flutter: se puede testear sin levantar la UI.
library;

/// Los cuatro palos de la baraja francesa.
enum Suit {
  spades('s', '♠'),
  hearts('h', '♥'),
  diamonds('d', '♦'),
  clubs('c', '♣');

  const Suit(this.letter, this.symbol);

  /// Letra ASCII (`s`, `h`, `d`, `c`), usada en la notación compacta `As`.
  final String letter;

  /// Símbolo Unicode del palo, para mostrar en la UI.
  final String symbol;

  static Suit fromLetter(String letter) =>
      Suit.values.firstWhere((s) => s.letter == letter.toLowerCase());
}

/// Los trece rangos, del 2 al As.
enum Rank {
  two(2, '2'),
  three(3, '3'),
  four(4, '4'),
  five(5, '5'),
  six(6, '6'),
  seven(7, '7'),
  eight(8, '8'),
  nine(9, '9'),
  ten(10, 'T'),
  jack(11, 'J'),
  queen(12, 'Q'),
  king(13, 'K'),
  ace(14, 'A');

  const Rank(this.value, this.letter);

  /// Valor numérico (2..14). El As siempre vale 14 en este motor.
  final int value;

  /// Letra usada en notación (`A`, `K`, `Q`, `J`, `T`, `9`..`2`).
  final String letter;

  static Rank fromLetter(String letter) {
    final upper = letter.toUpperCase();
    return Rank.values.firstWhere((r) => r.letter == upper);
  }

  /// Rangos ordenados de mayor a menor (As primero).
  static List<Rank> get highToLow =>
      Rank.values.reversed.toList(growable: false);

  bool operator >(Rank other) => value > other.value;
  bool operator <(Rank other) => value < other.value;
  bool operator >=(Rank other) => value >= other.value;
  bool operator <=(Rank other) => value <= other.value;
}

/// Una carta concreta: rango + palo (`A♠`, `T♥`, ...).
///
/// Es inmutable y define igualdad por valor, así que se puede usar en
/// `Set<Card>` para detectar duplicados.
class Card {
  const Card(this.rank, this.suit);

  final Rank rank;
  final Suit suit;

  /// Parsea notación compacta de dos caracteres: `As`, `Td`, `2c`.
  factory Card.parse(String text) {
    if (text.length != 2) {
      throw FormatException('Carta inválida: "$text" (se esperaban 2 chars)');
    }
    return Card(Rank.fromLetter(text[0]), Suit.fromLetter(text[1]));
  }

  /// Notación compacta ASCII (`As`), estable para logs y persistencia.
  String get code => '${rank.letter}${suit.letter}';

  /// Notación linda para la UI (`A♠`).
  String get pretty => '${rank.letter}${suit.symbol}';

  @override
  bool operator ==(Object other) =>
      other is Card && other.rank == rank && other.suit == suit;

  @override
  int get hashCode => Object.hash(rank, suit);

  @override
  String toString() => code;
}

/// La baraja completa de 52 cartas, sin comodines.
final List<Card> kFullDeck = List.unmodifiable([
  for (final rank in Rank.values)
    for (final suit in Suit.values) Card(rank, suit),
]);
