import '../deck.dart';
import '../hole_cards.dart';
import '../../strategy/hand_range.dart';
import 'game_state.dart';
import 'player_state.dart';

/// Arma un [GameState] de arranque real — sin decidir ninguna jugada de
/// rival, eso es responsabilidad de un `OpponentPolicy` que todavía no
/// existe en esta fase.
///
/// Deliberadamente limitado a manos preflop: un "snapshot" ya a mitad de
/// mano en una calle postflop necesitaría montos ya invertidos por cada
/// rival, y calcular eso bien sin simular ninguna decisión es prematuro
/// sin un consumidor real que diga qué forma necesita.
class ScenarioBuilder {
  const ScenarioBuilder._();

  static const int _seatCount = GameState.seatCount;

  /// Arma una mano nueva: postea ciegas y reparte las manos pedidas.
  ///
  /// Un slot activo (no listado en [sittingOutSlots]) que no tiene ni
  /// [explicitHandBySlot] ni [rangeBySlot] queda con cartas ocultas
  /// (`holeCards: null`) — el mismo uso ya documentado en [PlayerState]
  /// para un rival cuya mano el héroe no ve.
  ///
  /// Todo el azar (qué mano sale de cada rango, el orden del resto del
  /// mazo) sale de [deck] — el único funnel de aleatoriedad del motor.
  static GameState freshHand({
    required Deck deck,
    int buttonSlot = 0,
    Set<int> sittingOutSlots = const {},
    double stackBb = 100,
    Map<int, double> stackOverridesBb = const {},
    Map<int, HandRange> rangeBySlot = const {},
    Map<int, HoleCards> explicitHandBySlot = const {},
    double smallBlindBb = 0.5,
    double bigBlindBb = 1,
  }) {
    if (explicitHandBySlot.keys.any(sittingOutSlots.contains) ||
        rangeBySlot.keys.any(sittingOutSlots.contains)) {
      throw ArgumentError(
          'Un slot sitting-out no puede tener una mano pedida '
          '(explicitHandBySlot / rangeBySlot).');
    }

    // Las manos explícitas se reservan primero: sus cartas concretas
    // salen del mazo aunque no hayan sido "repartidas" por el propio
    // Deck, para que ni el sampleo de otro slot ni el resto del mazo
    // puedan pisarlas.
    final holeCardsBySlot = <int, HoleCards>{};
    for (final entry in explicitHandBySlot.entries) {
      holeCardsBySlot[entry.key] = entry.value;
      deck.remove(entry.value.cards);
    }
    for (final entry in rangeBySlot.entries) {
      if (holeCardsBySlot.containsKey(entry.key)) continue;
      holeCardsBySlot[entry.key] = entry.value.sample(deck);
    }

    final seats = [
      for (var slot = 0; slot < _seatCount; slot++)
        PlayerState(
          slot: slot,
          holeCards: holeCardsBySlot[slot],
          stackBb: stackOverridesBb[slot] ?? stackBb,
          sittingOut: sittingOutSlots.contains(slot),
        ),
    ];

    // Recién ahora se congela el resto del mazo — después de repartir
    // toda mano pedida, así el board futuro nunca puede pisar una carta
    // ya en una mano.
    final remainingDeckCards = deck.dealCards(deck.remaining);

    return GameState.newHand(
      buttonSlot: buttonSlot,
      seats: seats,
      remainingDeckCards: remainingDeckCards,
      smallBlindBb: smallBlindBb,
      bigBlindBb: bigBlindBb,
    );
  }
}
