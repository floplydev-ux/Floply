/// Las categorías de mano hecha en Texas Hold'em, ordenadas de más débil
/// (índice 0) a más fuerte (índice 8).
///
/// Es la base del concepto "ranking de manos": no involucra cartas
/// concretas ni evaluación de 7 cartas, solo la jerarquía que el jugador
/// tiene que reconocer y comparar.
enum HandCategory {
  highCard('Carta alta', 'A♠ Q♦ 9♣ 6♥ 2♠', 'Ninguna combinación: vale la carta más alta.'),
  pair('Pareja', 'K♠ K♦ 8♣ 5♥ 2♠', 'Dos cartas del mismo valor.'),
  twoPair('Doble pareja', 'J♠ J♦ 6♣ 6♥ 3♠', 'Dos parejas distintas.'),
  trips('Trío', '9♠ 9♦ 9♣ Q♥ 4♠', 'Tres cartas del mismo valor.'),
  straight('Escalera', '8♠ 7♦ 6♣ 5♥ 4♠', 'Cinco cartas en secuencia, palos mezclados.'),
  flush('Color', 'A♦ J♦ 8♦ 5♦ 2♦', 'Cinco cartas del mismo palo.'),
  fullHouse('Full', 'Q♠ Q♦ Q♣ 7♥ 7♠', 'Un trío y una pareja.'),
  quads('Póker', '5♠ 5♦ 5♣ 5♥ K♠', 'Cuatro cartas del mismo valor.'),
  straightFlush('Escalera de color', '9♣ 8♣ 7♣ 6♣ 5♣', 'Escalera y color a la vez.');

  const HandCategory(this.label, this.example, this.description);

  /// Nombre para mostrar (`Escalera`).
  final String label;

  /// Ejemplo de cinco cartas de esta categoría.
  final String example;

  /// Descripción corta de una línea.
  final String description;

  /// Fuerza relativa: mayor gana. Igual que `index`, pero explícito.
  int get strength => index;

  /// `true` si esta categoría gana a [other]. Nunca hay empate entre
  /// categorías distintas.
  bool beats(HandCategory other) => strength > other.strength;

  static List<HandCategory> get weakToStrong => values;
}
