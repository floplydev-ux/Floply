import '../card.dart';
import '../hand_category.dart';
import '../hole_cards.dart';
import 'five_card_hand.dart';

/// Evalúa la mejor mano de 5 cartas posible a partir de las hole cards de
/// un jugador y un board de 3, 4 o 5 cartas comunitarias (flop/turn/river).
///
/// Pieza que faltaba en el motor (ver el informe de Fase 0,
/// `FASE0_AUDITORIA_ENGINE.md`, §C.1): `GameState.needsShowdown` y
/// `OpponentPolicy.decide` postflop dependían de esto para poder
/// resolverse. Puro Dart — sin Flutter, sin acoplarse a ninguna capa de
/// exercises/screens.
///
/// Alcance de esta pasada: solo el evaluador. No decide showdown por sí
/// mismo (ver `HandEvaluator.winners` para eso, y el informe final sobre
/// qué falta para integrarlo a `GameState`), no calcula equity, no
/// implementa combos ni EV — cada uno de esos es una pieza aparte que
/// puede apoyarse en este evaluador sin que él tenga que cambiar.
class HandEvaluator {
  const HandEvaluator._();

  /// La mejor mano de 5 cartas combinando [holeCards] (2) + [board]
  /// (3, 4 o 5). Evalúa las C(n,5) combinaciones posibles (21 en el caso
  /// más grande, river con 7 cartas disponibles) y devuelve la más fuerte.
  ///
  /// Lanza [ArgumentError] si [board] no tiene 3, 4 o 5 cartas (con menos
  /// de 5 cartas totales no hay una "mejor mano de 5" que evaluar — ese es
  /// el caso preflop, fuera del alcance de este evaluador) o si hay
  /// alguna carta repetida entre [holeCards] y [board].
  static FiveCardHand best(HoleCards holeCards, List<Card> board) {
    _validate(holeCards, board);
    final pool = [...holeCards.cards, ...board];

    FiveCardHand? bestSoFar;
    for (final five in _combinationsOf5(pool)) {
      final candidate = _evaluateFive(five);
      if (bestSoFar == null || candidate.compareTo(bestSoFar) > 0) {
        bestSoFar = candidate;
      }
    }
    return bestSoFar!;
  }

  /// Compara directamente dos manos en el mismo [board]. `>0` si [a] le
  /// gana a [b], `0` si empatan, `<0` si pierde. Atajo sobre [best] +
  /// [FiveCardHand.compareTo] para el caso más común de UI.
  static int compare(HoleCards a, HoleCards b, List<Card> board) =>
      best(a, board).compareTo(best(b, board));

  /// Resuelve el/los ganador(es) entre varias manos en el mismo [board] —
  /// puede haber empate (más de un slot). Pensado para reemplazar
  /// `GameState.winnerSlots == null` cuando `GameState.needsShowdown` sea
  /// `true` (ver el informe final sobre la integración pendiente).
  ///
  /// Lanza [ArgumentError] si [handsBySlot] está vacío.
  static Set<int> winners(Map<int, HoleCards> handsBySlot, List<Card> board) {
    if (handsBySlot.isEmpty) {
      throw ArgumentError.value(
          handsBySlot, 'handsBySlot', 'no puede estar vacío');
    }
    final evaluated = {
      for (final entry in handsBySlot.entries) entry.key: best(entry.value, board),
    };
    final top = evaluated.values.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    return {
      for (final entry in evaluated.entries)
        if (entry.value.compareTo(top) == 0) entry.key,
    };
  }

  static void _validate(HoleCards holeCards, List<Card> board) {
    if (board.length != 3 && board.length != 4 && board.length != 5) {
      throw ArgumentError.value(board.length, 'board.length',
          'debe ser 3 (flop), 4 (turn) o 5 (river) — con menos de 5 cartas '
          'totales no hay una mejor mano de 5 que evaluar');
    }
    final seen = <Card>{};
    for (final c in [...holeCards.cards, ...board]) {
      if (!seen.add(c)) {
        throw ArgumentError(
            'HandEvaluator: carta repetida entre hole cards y board: $c');
      }
    }
  }

  /// Todas las combinaciones de 5 cartas de [pool] (5, 6 o 7 elementos —
  /// C(5,5)=1, C(6,5)=6, C(7,5)=21), por índices crecientes — algoritmo
  /// estándar de enumeración de combinaciones, sin dependencias externas.
  static Iterable<List<Card>> _combinationsOf5(List<Card> pool) sync* {
    final n = pool.length;
    if (n == 5) {
      yield pool;
      return;
    }
    final indices = List<int>.generate(5, (i) => i);
    while (true) {
      yield [for (final i in indices) pool[i]];
      var i = 4;
      while (i >= 0 && indices[i] == i + n - 5) {
        i--;
      }
      if (i < 0) return;
      indices[i]++;
      for (var j = i + 1; j < 5; j++) {
        indices[j] = indices[j - 1] + 1;
      }
    }
  }

  /// Evalúa una mano concreta de exactamente 5 cartas: categoría +
  /// desempate. Es el corazón del evaluador — todo lo de arriba solo
  /// arma el pool y prueba combinaciones contra esto.
  static FiveCardHand _evaluateFive(List<Card> five) {
    final byRankDesc = [...five]
      ..sort((a, b) => b.rank.value.compareTo(a.rank.value));

    final counts = <Rank, int>{};
    for (final c in five) {
      counts[c.rank] = (counts[c.rank] ?? 0) + 1;
    }

    final isFlush = five.every((c) => c.suit == five.first.suit);

    final distinctRanksDesc = counts.keys.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final straightHigh = _straightHighRank(distinctRanksDesc);

    // Ranks agrupados por cuántas veces aparecen (4/3/2/1), cada bucket ya
    // ordenado de mayor a menor rango — así los kickers salen en el orden
    // correcto sin tener que resolverlo de nuevo en cada categoría.
    final byCount = <int, List<Rank>>{};
    for (final entry in counts.entries) {
      byCount.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    for (final ranks in byCount.values) {
      ranks.sort((a, b) => b.value.compareTo(a.value));
    }
    final quads = byCount[4] ?? const <Rank>[];
    final trips = byCount[3] ?? const <Rank>[];
    final pairs = byCount[2] ?? const <Rank>[];
    final singles = byCount[1] ?? const <Rank>[];

    if (isFlush && straightHigh != null) {
      return FiveCardHand(
        category: HandCategory.straightFlush,
        tiebreakers: [straightHigh],
        cards: byRankDesc,
      );
    }
    if (quads.isNotEmpty) {
      return FiveCardHand(
        category: HandCategory.quads,
        tiebreakers: [quads.first, ...singles],
        cards: byRankDesc,
      );
    }
    if (trips.isNotEmpty && pairs.isNotEmpty) {
      return FiveCardHand(
        category: HandCategory.fullHouse,
        tiebreakers: [trips.first, pairs.first],
        cards: byRankDesc,
      );
    }
    if (isFlush) {
      return FiveCardHand(
        category: HandCategory.flush,
        tiebreakers: distinctRanksDesc,
        cards: byRankDesc,
      );
    }
    if (straightHigh != null) {
      return FiveCardHand(
        category: HandCategory.straight,
        tiebreakers: [straightHigh],
        cards: byRankDesc,
      );
    }
    if (trips.isNotEmpty) {
      return FiveCardHand(
        category: HandCategory.trips,
        tiebreakers: [trips.first, ...singles],
        cards: byRankDesc,
      );
    }
    if (pairs.length == 2) {
      return FiveCardHand(
        category: HandCategory.twoPair,
        tiebreakers: [pairs[0], pairs[1], ...singles],
        cards: byRankDesc,
      );
    }
    if (pairs.length == 1) {
      return FiveCardHand(
        category: HandCategory.pair,
        tiebreakers: [pairs.first, ...singles],
        cards: byRankDesc,
      );
    }
    return FiveCardHand(
      category: HandCategory.highCard,
      tiebreakers: distinctRanksDesc,
      cards: byRankDesc,
    );
  }

  /// `null` si [distinctRanksDesc] (rangos únicos, de mayor a menor) no
  /// forma una escalera. Contempla la rueda (`A-2-3-4-5`, donde el As
  /// juega bajo y la carta alta de la escalera es el 5) como único caso
  /// especial — el resto es una corrida de 5 valores consecutivos.
  static Rank? _straightHighRank(List<Rank> distinctRanksDesc) {
    if (distinctRanksDesc.length != 5) return null;
    final values = distinctRanksDesc.map((r) => r.value).toList();
    if (values[0] == 14 &&
        values[1] == 5 &&
        values[2] == 4 &&
        values[3] == 3 &&
        values[4] == 2) {
      return Rank.five;
    }
    for (var i = 0; i < 4; i++) {
      if (values[i] - values[i + 1] != 1) return null;
    }
    return distinctRanksDesc.first;
  }
}
