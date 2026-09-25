import '../card.dart';
import '../combos/combo_engine.dart';
import '../evaluator/hand_evaluator.dart';
import '../hole_cards.dart';
import '../../strategy/hand_range.dart';
import 'equity_result.dart';

/// Calcula equity real de póker por enumeración exacta — nunca Monte
/// Carlo, nunca aproximación.
///
/// Reutiliza el motor existente tal cual está: [HandEvaluator] para
/// comparar manos hechas, [ComboEngine] para expandir un [HandRange] a
/// combos físicos con card removal ya aplicado. No declara un segundo
/// evaluador ni un segundo sistema de combos.
///
/// **Alcance de esta fase**: preflop (board vacío) queda fuera — igual
/// que [HandEvaluator.best], que exige `board.length` en {3, 4, 5}. Un
/// board vacío significaría enumerar C(48,5) = 1.712.304 runouts por
/// comparación, cada uno evaluando dos manos de 7 cartas (C(7,5)=21
/// sub-evaluaciones cada una) — del orden de 10^8 evaluaciones por
/// llamada. Eso es un problema de rendimiento real que amerita su propio
/// diseño (lookup tables o un evaluador de 7 cartas dedicado), no algo
/// para resolver de paso acá. Preflop se calcula hoy con
/// `HandStrength`/`OpeningRanges` (heurística de percentil, no equity
/// real) — sigue siendo así hasta una fase posterior.
class EquityEngine {
  const EquityEngine._();

  /// Equity de [hero] contra [villain], una mano concreta contra otra,
  /// en [board] (3, 4 o 5 cartas conocidas — flop, turn o river).
  ///
  /// River (`board.length == 5`) es una sola evaluación directa, sin
  /// enumerar nada — no es un caso especial en el código: pedir 0
  /// runouts adicionales ya cae naturalmente en "un solo resultado" (ver
  /// [_combinationsOfSize]).
  static EquityResult handVsHand(
    HoleCards hero,
    HoleCards villain,
    List<Card> board,
  ) {
    _validateBoardLength(board);
    final known = [...hero.cards, ...villain.cards, ...board];
    _validateNoDuplicates(known, context: 'hero/villain/board');

    final unseen = _unseenCards(known);
    final toDraw = 5 - board.length;

    var wins = 0, ties = 0, losses = 0;
    for (final runout in _combinationsOfSize(unseen, toDraw)) {
      final finalBoard = [...board, ...runout];
      final cmp = HandEvaluator.compare(hero, villain, finalBoard);
      if (cmp > 0) {
        wins++;
      } else if (cmp < 0) {
        losses++;
      } else {
        ties++;
      }
    }
    return EquityResult(wins: wins, ties: ties, losses: losses);
  }

  /// Equity de [hero] contra cada combo físico de [villainRange] (ya con
  /// las cartas de [hero] y [board] descontadas por [ComboEngine]),
  /// acumulando wins/ties/losses de los combos válidos — cada combo pesa
  /// como una posibilidad física individual (`AKs` aporta 4 combos,
  /// `AKo` aporta 12; nunca se tratan como una única posibilidad cada
  /// una, ver el doc-comment de [ComboEngine.combosForRange]).
  ///
  /// **Frecuencias**: [ComboEngine.combosForRange] hoy solo usa
  /// `frequencyOf(notation) > 0` como umbral de inclusión (una clase con
  /// frecuencia parcial, ej. `KJo @ 50%`, entra entera o no entra) — no
  /// pondera los combos devueltos por esa frecuencia. Esta fase hereda
  /// esa misma simplificación explícitamente: trabaja con inclusión de
  /// combos, no con ponderación probabilística por frecuencia. Ponderar
  /// (para que un rango mixto cuente "medio combo") queda para una fase
  /// posterior — no se inventa acá.
  ///
  /// Lanza [ArgumentError] si, después de descontar las cartas de [hero]
  /// y [board], no queda ningún combo válido en [villainRange] (rango
  /// vacío para este spot — nunca se devuelve un resultado con `total ==
  /// 0` en silencio).
  static EquityResult handVsRange(
    HoleCards hero,
    HandRange villainRange,
    List<Card> board,
  ) {
    _validateBoardLength(board);
    _validateNoDuplicates([...hero.cards, ...board], context: 'hero/board');

    final deadForRange = [...hero.cards, ...board];
    final villainCombos =
        ComboEngine.combosForRange(villainRange, deadCards: deadForRange);
    if (villainCombos.isEmpty) {
      throw ArgumentError(
          'EquityEngine.handVsRange: villainRange no tiene ningún combo '
          'válido una vez descontadas las cartas de hero y board.');
    }

    var total = EquityResult.zero;
    for (final villain in villainCombos) {
      // handVsHand vuelve a validar/calcular "unseen" para este combo
      // puntual — cada combo rival deja un pool de cartas desconocidas
      // ligeramente distinto (sus propias 2 cartas también quedan
      // "vivas" para él), así que no hay runouts precalculados que
      // compartir sin volver a filtrar por combo.
      total += handVsHand(hero, villain, board);
    }
    return total;
  }

  /// Equity de [heroRange] contra [villainRange] — cada combo físico de
  /// [heroRange] (con [board] descontado) enfrenta a cada combo de
  /// [villainRange] (con ese combo del héroe + [board] descontados),
  /// acumulando wins/ties/losses de todas las confrontaciones válidas.
  /// Reutiliza [handVsRange] para cada combo del héroe — no reimplementa
  /// la enumeración de runouts ni el filtrado de combos rivales.
  ///
  /// **Combos del héroe que bloquean el rango rival entero**: si, para un
  /// combo puntual de [heroRange], no queda ningún combo válido en
  /// [villainRange] (p. ej. el héroe tiene las únicas cartas que forman
  /// la única mano del rango rival), esa confrontación es imposible y se
  /// excluye del total — no hace que todo el cálculo falle. Solo lanza
  /// [ArgumentError] si NINGÚN combo de [heroRange] deja combos válidos
  /// en [villainRange] (los dos rangos se bloquean por completo entre
  /// sí), o si [heroRange] mismo no tiene combos tras descontar [board].
  ///
  /// **Rendimiento**: es el caso más pesado de `EquityEngine` (hasta
  /// `heroCombos.length × villainCombos.length × runouts` evaluaciones,
  /// ver el informe de Fase 0, §I) — para rangos anchos en preflop
  /// (board vacío está fuera de alcance igual que en [handVsHand]) o
  /// flop, correrlo fuera del isolate de UI (`compute()`), nunca en el
  /// camino de un `build()`.
  static EquityResult rangeVsRange(
    HandRange heroRange,
    HandRange villainRange,
    List<Card> board,
  ) {
    _validateBoardLength(board);
    _validateNoDuplicates(board, context: 'board');

    final heroCombos = ComboEngine.combosForRange(heroRange, deadCards: board);
    if (heroCombos.isEmpty) {
      throw ArgumentError(
          'EquityEngine.rangeVsRange: heroRange no tiene ningún combo '
          'válido una vez descontado el board.');
    }

    var total = EquityResult.zero;
    var confrontationsEvaluated = 0;
    for (final hero in heroCombos) {
      final villainCombos = ComboEngine.combosForRange(
        villainRange,
        deadCards: [...hero.cards, ...board],
      );
      if (villainCombos.isEmpty) continue;
      total += handVsRange(hero, villainRange, board);
      confrontationsEvaluated++;
    }

    if (confrontationsEvaluated == 0) {
      throw ArgumentError(
          'EquityEngine.rangeVsRange: ningún combo de heroRange deja '
          'combos válidos en villainRange — los rangos se bloquean por '
          'completo entre sí.');
    }
    return total;
  }

  static void _validateBoardLength(List<Card> board) {
    if (board.length != 3 && board.length != 4 && board.length != 5) {
      throw ArgumentError.value(board.length, 'board.length',
          'EquityEngine solo evalúa flop (3), turn (4) o river (5) — '
          'preflop (board vacío) está fuera de alcance de esta fase, ver '
          'el doc-comment de EquityEngine.');
    }
  }

  static void _validateNoDuplicates(List<Card> cards, {required String context}) {
    final seen = <Card>{};
    for (final c in cards) {
      if (!seen.add(c)) {
        throw ArgumentError(
            'EquityEngine: carta repetida entre $context: $c');
      }
    }
  }

  /// Las cartas de las 52 que no están en [known] — el pool real de
  /// runouts posibles. Nunca usa `Deck`/`Random`: la enumeración exacta
  /// necesita recorrer TODAS las combinaciones, no repartir una al azar.
  static List<Card> _unseenCards(List<Card> known) {
    final knownSet = known.toSet();
    return [for (final c in kFullDeck) if (!knownSet.contains(c)) c];
  }

  /// Todas las combinaciones de tamaño [size] de [pool], sin importar el
  /// orden — mismo algoritmo de enumeración por índices crecientes que
  /// ya usa `HandEvaluator._combinationsOf5`, generalizado a cualquier
  /// tamaño en vez de fijo en 5 (evita depender de un método privado
  /// ajeno, pero no inventa un segundo estilo de combinatoria).
  ///
  /// `size == 0` da exactamente una combinación: la lista vacía — así
  /// river (`toDraw == 0` en [handVsHand]) no necesita una rama aparte,
  /// "evaluar una vez, sin runouts" sale solo de este caso base.
  static Iterable<List<Card>> _combinationsOfSize(
      List<Card> pool, int size) sync* {
    if (size == 0) {
      yield const [];
      return;
    }
    if (size > pool.length) return;

    final n = pool.length;
    final indices = List<int>.generate(size, (i) => i);
    while (true) {
      yield [for (final i in indices) pool[i]];
      var i = size - 1;
      while (i >= 0 && indices[i] == i + n - size) {
        i--;
      }
      if (i < 0) return;
      indices[i]++;
      for (var j = i + 1; j < size; j++) {
        indices[j] = indices[j - 1] + 1;
      }
    }
  }
}
