import '../card.dart';
import '../hole_cards.dart';
import '../../strategy/hand_range.dart';

/// Transforma manos abstractas (`HandClass`/`HandRange`) en combinaciones
/// físicas concretas de [HoleCards], aplicando card removal.
///
/// Puro Dart, determinista, sin dependencia de `Deck`/`Random` — a
/// diferencia de `Deck.dealHandOfClass`/`HandRange.sample` (que *reparten*
/// una mano al azar), este motor *enumera* todas las combinaciones
/// posibles. Reutiliza [Card]/[HoleCards]/[HandClass]/[HandRange] tal
/// cual existen hoy — no declara ningún modelo de cartas/manos/rangos
/// paralelo.
///
/// Alcance de esta pasada (ver el informe de Fase 0,
/// `FASE0_AUDITORIA_ENGINE.md`, §F.1): solo enumeración física + card
/// removal. No calcula equity, no pondera por frecuencia (ver el
/// doc-comment de [combosForRange]) — eso es trabajo de `EquityEngine`
/// (Fase 3), que se apoya en esto sin que esto tenga que cambiar.
class ComboEngine {
  const ComboEngine._();

  /// Las combinaciones físicas concretas que representa [handClass],
  /// excluyendo cualquier combo que use una carta de [deadCards].
  ///
  /// Orden determinista (mismo `handClass`/`deadCards` → misma lista, en
  /// el mismo orden): para pares, las 6 combinaciones de a pares de palos
  /// en el orden de [Suit.values]; para suited/offsuit, recorriendo
  /// [Suit.values] para la carta alta y, dentro de cada una, para la
  /// baja. Nunca hay duplicados — cada combinación física pertenece a
  /// exactamente un par de palos, y [HoleCards] ya canonicaliza el orden
  /// alto/bajo, así que "As Kd" y "Kd As" nunca podrían aparecer como dos
  /// entradas distintas.
  static List<HoleCards> combosForHandClass(
    HandClass handClass, {
    Iterable<Card> deadCards = const [],
  }) =>
      _combosForHandClass(handClass, Set<Card>.of(deadCards));

  /// Atajo sobre [combosForHandClass] a partir de la notación (`'AKs'`,
  /// `'77'`) — la forma en que el resto del motor (`HandRange`,
  /// `OpeningRanges`, `HandStrength`) ya maneja las clases de mano, así
  /// que un caller típico no necesita pasar por `HandClass.parse` a mano.
  static List<HoleCards> combosForNotation(
    String notation, {
    Iterable<Card> deadCards = const [],
  }) =>
      combosForHandClass(HandClass.parse(notation), deadCards: deadCards);

  /// Cuántos combos concretos le quedan a [handClass] dadas [deadCards] —
  /// atajo para UI que solo necesita el número, sin materializar la lista.
  static int comboCount(
    HandClass handClass, {
    Iterable<Card> deadCards = const [],
  }) =>
      combosForHandClass(handClass, deadCards: deadCards).length;

  static int comboCountForNotation(
    String notation, {
    Iterable<Card> deadCards = const [],
  }) =>
      comboCount(HandClass.parse(notation), deadCards: deadCards);

  /// Todos los combos físicos de las clases que [range] incluye (`
  /// frequencyOf(notation) > 0`), excluyendo [deadCards].
  ///
  /// **Simplificación deliberada de esta fase**: la frecuencia de
  /// `HandRange` (ej. `KJo @ 50%`, un rango mixto) hoy solo se usa como
  /// umbral de inclusión (> 0 => la clase entra entera), no como peso
  /// sobre los combos devueltos — no hay "medio combo". Ponderar por
  /// frecuencia (para un muestreo aleatorio, o para que `EquityEngine`
  /// descuente combos de estrategias mixtas) queda fuera de esta pasada
  /// a propósito: `HandRange.sample()` ya cubre el caso de "una mano al
  /// azar respetando la frecuencia" para quien lo necesite hoy.
  ///
  /// Orden determinista e independiente de cómo se construyó [range]:
  /// recorre `HandClass.all()` (las 169 clases en su orden canónico), no
  /// las claves internas de `range` — dos rangos con las mismas clases
  /// incluidas, construidos de formas distintas (tokens en otro orden),
  /// dan exactamente la misma lista.
  static List<HoleCards> combosForRange(
    HandRange range, {
    Iterable<Card> deadCards = const [],
  }) {
    final dead = Set<Card>.of(deadCards);
    final result = <HoleCards>[];
    for (final handClass in HandClass.all()) {
      if (range.frequencyOf(handClass.notation) <= 0) continue;
      result.addAll(_combosForHandClass(handClass, dead));
    }
    return List.unmodifiable(result);
  }

  static int comboCountForRange(
    HandRange range, {
    Iterable<Card> deadCards = const [],
  }) =>
      combosForRange(range, deadCards: deadCards).length;

  static List<HoleCards> _combosForHandClass(
      HandClass handClass, Set<Card> dead) {
    final result = <HoleCards>[];

    if (handClass.isPair) {
      final rank = handClass.highRank;
      final cards = [for (final suit in Suit.values) Card(rank, suit)];
      for (var i = 0; i < cards.length; i++) {
        for (var j = i + 1; j < cards.length; j++) {
          _addIfAlive(result, cards[i], cards[j], dead);
        }
      }
      return List.unmodifiable(result);
    }

    final hi = handClass.highRank;
    final lo = handClass.lowRank;

    if (handClass.isSuited) {
      for (final suit in Suit.values) {
        _addIfAlive(result, Card(hi, suit), Card(lo, suit), dead);
      }
      return List.unmodifiable(result);
    }

    // Offsuit: todo par de palos distintos entre la carta alta y la baja.
    for (final suitHi in Suit.values) {
      for (final suitLo in Suit.values) {
        if (suitHi == suitLo) continue;
        _addIfAlive(result, Card(hi, suitHi), Card(lo, suitLo), dead);
      }
    }
    return List.unmodifiable(result);
  }

  static void _addIfAlive(
      List<HoleCards> result, Card a, Card b, Set<Card> dead) {
    if (dead.contains(a) || dead.contains(b)) return;
    result.add(HoleCards(a, b));
  }
}
