import 'position.dart';

/// Tipo de acción que un jugador puede tomar en una calle.
enum ActionType {
  fold('Fold'),
  check('Check'),
  call('Call'),
  bet('Bet'),
  raise('Raise'),
  limp('Limp'),
  allIn('All-in');

  const ActionType(this.label);
  final String label;

  bool get isAggressive => this == ActionType.bet || this == ActionType.raise;
  bool get putsChipsIn => this != ActionType.fold && this != ActionType.check;
}

/// Una acción concreta, opcionalmente con un tamaño en ciegas grandes.
///
/// Para `fold`/`check` el tamaño es irrelevante (`null`). Para
/// `raise`/`bet`/`call` representa el total apostado en BB.
class PokerAction {
  const PokerAction(this.type, {this.sizeBb});

  final ActionType type;
  final double? sizeBb;

  static const PokerAction fold = PokerAction(ActionType.fold);
  static const PokerAction check = PokerAction(ActionType.check);

  factory PokerAction.raiseTo(double bb) =>
      PokerAction(ActionType.raise, sizeBb: bb);
  factory PokerAction.call(double bb) => PokerAction(ActionType.call, sizeBb: bb);
  factory PokerAction.bet(double bb) => PokerAction(ActionType.bet, sizeBb: bb);

  /// Etiqueta corta para la UI (`RAISE 2.5bb`, `FOLD`).
  String get label {
    if (sizeBb == null) return type.label.toUpperCase();
    final size = sizeBb!;
    final text = size == size.roundToDouble()
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '${type.label.toUpperCase()} ${text}bb';
  }

  /// Dos acciones se consideran "la misma decisión" si coinciden en tipo
  /// y su tamaño está dentro de [sizeTolerance] BB (para no penalizar
  /// 2.5bb vs 2.4bb como si fueran acciones distintas).
  bool matches(PokerAction other, {double sizeTolerance = 0.35}) {
    if (other.type != type) return false;
    if (sizeBb == null || other.sizeBb == null) return true;
    return (sizeBb! - other.sizeBb!).abs() <= sizeTolerance;
  }

  @override
  bool operator ==(Object other) =>
      other is PokerAction && other.type == type && other.sizeBb == sizeBb;

  @override
  int get hashCode => Object.hash(type, sizeBb);

  @override
  String toString() => label;
}

/// Una acción ya ocurrida en la mano, atada a la posición que la tomó.
/// Sirve para describir el historial previo a la decisión del héroe.
class PriorAction {
  const PriorAction(this.position, this.action);

  final Position position;
  final PokerAction action;

  @override
  String toString() => '${position.abbreviation} ${action.label}';
}
