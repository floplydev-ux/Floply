import 'card.dart';
import 'deck.dart';
import 'generation_exception.dart';

/// Textura de un flop — definiciones mecánicas (rangos y palos), no
/// heurísticas de "peligroso/seguro": eso es juicio pedagógico, y le
/// corresponde a quien consuma esto (un template, un `ScenarioBuilder`
/// más específico), no al generador.
enum BoardTexture {
  /// Sin restricción.
  any,

  /// Al menos dos de las tres cartas comparten rango.
  paired,

  /// Las tres cartas son del mismo palo.
  monotone,

  /// Exactamente dos palos distintos entre las tres cartas (posible
  /// proyecto de color a un palo).
  twoTone,

  /// Tres palos distintos: ningún proyecto de color posible.
  rainbow,
}

/// Genera boards con una textura pedida, repartiendo de la baraja real.
///
/// Mismo patrón que `HandPicker.forBias`: sortea candidatos sobre
/// [Deck.tryDealMatching] y nunca cae a "lo que sea" si la textura
/// pedida ya no es alcanzable con lo que queda en el mazo — lanza
/// [TemplateGenerationException].
class BoardGenerator {
  const BoardGenerator._();

  /// Reparte un flop (3 cartas) que cumpla [texture].
  static List<Card> flop(
    Deck deck, {
    BoardTexture texture = BoardTexture.any,
    int maxAttempts = 200,
  }) {
    final result = deck.tryDealMatching(
      3,
      (candidate) => _matches(texture, candidate),
      maxAttempts: maxAttempts,
    );
    if (result == null) {
      throw TemplateGenerationException(
          'BoardGenerator: no se pudo generar un flop de textura '
          '$texture en $maxAttempts intentos (quedan ${deck.remaining} '
          'cartas en el mazo).');
    }
    return result;
  }

  static bool _matches(BoardTexture texture, List<Card> cards) {
    final suits = cards.map((c) => c.suit).toSet();
    switch (texture) {
      case BoardTexture.any:
        return true;
      case BoardTexture.paired:
        final ranks = cards.map((c) => c.rank).toList();
        return ranks.toSet().length < ranks.length;
      case BoardTexture.monotone:
        return suits.length == 1;
      case BoardTexture.twoTone:
        return suits.length == 2;
      case BoardTexture.rainbow:
        return suits.length == 3;
    }
  }
}
