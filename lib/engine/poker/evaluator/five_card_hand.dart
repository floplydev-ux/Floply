import '../card.dart';
import '../hand_category.dart';

/// El resultado de evaluar una mano hecha de exactamente 5 cartas.
///
/// Reutiliza [HandCategory] (ya existía en `poker/hand_category.dart` para
/// uso pedagógico — mismos 9 valores, mismo orden de fuerza vía
/// `HandCategory.strength`) en vez de declarar una jerarquía paralela: acá
/// simplemente se le agrega el resultado *computado* (desempate + cartas
/// concretas) que ese enum, por sí solo, nunca tuvo.
///
/// Inmutable y comparable — nunca se compara por texto.
class FiveCardHand implements Comparable<FiveCardHand> {
  const FiveCardHand({
    required this.category,
    required this.tiebreakers,
    required this.cards,
  });

  final HandCategory category;

  /// Rangos que desempatan DENTRO de la misma categoría, en orden de mayor
  /// a menor peso (ej. full house: `[rango del trío, rango del par]`). Dos
  /// manos de la misma categoría siempre traen listas de igual longitud
  /// (la que le corresponde a esa categoría), así que compararlas
  /// elemento a elemento es seguro.
  final List<Rank> tiebreakers;

  /// Las cinco cartas exactas que forman esta mano (no las 7 disponibles),
  /// ordenadas de mayor a menor rango — para feedback pedagógico, mostrar
  /// showdown, o debug.
  final List<Card> cards;

  /// `>0` si esta mano le gana a [other], `0` si empatan exactamente,
  /// `<0` si pierde. Primero compara categoría, y solo si coinciden
  /// compara [tiebreakers] en orden.
  @override
  int compareTo(FiveCardHand other) {
    final byCategory = category.strength.compareTo(other.category.strength);
    if (byCategory != 0) return byCategory;
    for (var i = 0; i < tiebreakers.length; i++) {
      final byRank = tiebreakers[i].value.compareTo(other.tiebreakers[i].value);
      if (byRank != 0) return byRank;
    }
    return 0;
  }

  bool operator >(FiveCardHand other) => compareTo(other) > 0;
  bool operator <(FiveCardHand other) => compareTo(other) < 0;
  bool operator >=(FiveCardHand other) => compareTo(other) >= 0;
  bool operator <=(FiveCardHand other) => compareTo(other) <= 0;

  @override
  String toString() =>
      '${category.label} (${cards.map((c) => c.code).join(" ")})';
}
