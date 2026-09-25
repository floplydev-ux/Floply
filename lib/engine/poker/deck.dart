import 'dart:math';

import 'card.dart';
import 'hole_cards.dart';

/// Baraja repartidora con semilla controlada.
///
/// Toda la aleatoriedad del motor pasa por acá: nunca se usa `Random()`
/// suelto. Al construirla con un [Random] sembrado los ejercicios son
/// reproducibles en los tests.
class Deck {
  Deck(this._rng) : _cards = List.of(kFullDeck) {
    _cards.shuffle(_rng);
  }

  final Random _rng;
  final List<Card> _cards;

  int get remaining => _cards.length;

  /// Quita [cards] de la baraja (por ejemplo las que ya están en el board)
  /// para que no vuelvan a repartirse.
  void remove(Iterable<Card> cards) {
    final toRemove = cards.toSet();
    _cards.removeWhere(toRemove.contains);
  }

  Card dealCard() {
    if (_cards.isEmpty) {
      throw StateError('La baraja se quedó sin cartas');
    }
    return _cards.removeLast();
  }

  List<Card> dealCards(int count) =>
      List.generate(count, (_) => dealCard(), growable: false);

  HoleCards dealHoleCards() => HoleCards(dealCard(), dealCard());

  /// Reparte una mano concreta indicada por su [HandClass] (`AKs`, `77`),
  /// eligiendo palos concretos al azar entre los disponibles. Devuelve
  /// `null` si no quedan cartas suficientes para representarla.
  HoleCards? dealHandOfClass(String notation) {
    final isPair = notation.length == 2;
    final hiRank = Rank.fromLetter(notation[0]);
    final loRank = Rank.fromLetter(notation[1]);

    final hiOptions = _cards.where((c) => c.rank == hiRank).toList()
      ..shuffle(_rng);
    if (hiOptions.isEmpty) return null;

    if (isPair) {
      final loOptions =
          hiOptions.where((c) => c != hiOptions.first).toList();
      if (loOptions.isEmpty) return null;
      final a = hiOptions.first;
      final b = loOptions.first;
      _cards.removeWhere((c) => c == a || c == b);
      return HoleCards(a, b);
    }

    final suited = notation.endsWith('s');
    for (final hi in hiOptions) {
      final loOptions = _cards.where((c) {
        if (c.rank != loRank) return false;
        return suited ? c.suit == hi.suit : c.suit != hi.suit;
      }).toList()
        ..shuffle(_rng);
      if (loOptions.isNotEmpty) {
        final lo = loOptions.first;
        _cards.removeWhere((c) => c == hi || c == lo);
        return HoleCards(hi, lo);
      }
    }
    return null;
  }

  /// Reintenta hasta [maxAttempts] veces: baraja una copia de lo que
  /// queda en el mazo y prueba los primeros [count]. Si [predicate] los
  /// acepta, recién ahí los saca de verdad del mazo — un intento fallido
  /// no consume cartas. `null` si se agotan los intentos; no hay
  /// fallback silencioso a "lo que sea", decide el caller.
  List<Card>? tryDealMatching(
    int count,
    bool Function(List<Card> candidate) predicate, {
    int maxAttempts = 200,
  }) {
    if (_cards.length < count) return null;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = List<Card>.of(_cards)..shuffle(_rng);
      final picked = candidate.sublist(0, count);
      if (predicate(picked)) {
        final pickedSet = picked.toSet();
        _cards.removeWhere(pickedSet.contains);
        return picked;
      }
    }
    return null;
  }

  /// Elige un elemento al azar de [items] usando la semilla de la baraja.
  T pick<T>(List<T> items) => items[_rng.nextInt(items.length)];

  /// Devuelve una copia barajada de [items] con la semilla de la baraja.
  List<T> shuffled<T>(Iterable<T> items) {
    final list = List<T>.of(items);
    list.shuffle(_rng);
    return list;
  }

  bool nextBool() => _rng.nextBool();

  double nextDouble() => _rng.nextDouble();

  /// Entero en `[min, max]` (ambos inclusive).
  int intInRange(int min, int max) => min + _rng.nextInt(max - min + 1);
}
