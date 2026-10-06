import '../poker/position.dart';

/// Formato del juego. Solo [cash] tiene datos reales hoy — [tournament]
/// existe para que el modelo no tenga que cambiar de forma el día que
/// haya rangos de torneo, pero ningún selector de la UI lo ofrece
/// todavía (mostrar una opción que no hace nada sería peor que no
/// mostrarla).
enum RangeFormat { cash, tournament }

/// Tamaño de mesa. Solo [sixMax] tiene datos reales — [eightMax] queda
/// reservado por el mismo motivo que [RangeFormat.tournament].
enum TableSize { sixMax, eightMax }

/// Situación preflop. Hoy la única con datos reales para las 5
/// posiciones que abren es [openRaise] (RFI, `OpeningRanges`). Los demás
/// casos existen para no tener que romper la forma del modelo cuando se
/// agreguen — deliberadamente no hay ningún dato detrás de ellos todavía
/// (`PreflopRangeBook` solo cubre 3 pares de posición puntuales,
/// pensados para la IA del Laboratorio, no una base de datos de rangos
/// completa) y por eso ningún selector de Rangos los ofrece hoy.
enum RangeSituation { openRaise, vsOpen, threeBet, facingThreeBet, shortStack }

extension RangeSituationLabel on RangeSituation {
  String get label => switch (this) {
        RangeSituation.openRaise => 'Open Raise',
        RangeSituation.vsOpen => 'vs Open',
        RangeSituation.threeBet => '3-bet',
        RangeSituation.facingThreeBet => 'vs 3-bet',
        RangeSituation.shortStack => 'Short Stack',
      };
}

/// El contexto completo de un rango — nunca debe mostrarse un rango
/// aislado, siempre junto a su formato/mesa/stack/posición/situación
/// (aunque, por ahora, formato/mesa/stack sean siempre el mismo valor
/// fijo: 100 BB de stack es el único dato real que tiene `OpeningRanges`
/// hoy, así que no es un campo variable de verdad todavía).
class RangeContext {
  const RangeContext({
    required this.position,
    this.situation = RangeSituation.openRaise,
    this.format = RangeFormat.cash,
    this.tableSize = TableSize.sixMax,
    this.stackBb = 100,
  });

  final Position position;
  final RangeSituation situation;
  final RangeFormat format;
  final TableSize tableSize;
  final int stackBb;

  /// "6-max · 100 BB · Cash · Open Raise" — el contexto siempre visible
  /// junto al rango (sección 5 del pedido).
  String get breadcrumb {
    final table = tableSize == TableSize.sixMax ? '6-max' : '8-max';
    final format = this.format == RangeFormat.cash ? 'Cash' : 'Torneo';
    return '$table · $stackBb BB · $format · ${situation.label}';
  }

  RangeContext copyWith({Position? position, RangeSituation? situation}) =>
      RangeContext(
        position: position ?? this.position,
        situation: situation ?? this.situation,
        format: format,
        tableSize: tableSize,
        stackBb: stackBb,
      );
}
