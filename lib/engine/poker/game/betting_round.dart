import '../poker_action.dart';
import '../street.dart';

/// Una acción ya ocurrida en la calle actual, atada al slot que la tomó.
///
/// No reutiliza `PriorAction` (`poker/poker_action.dart`) porque esa clase
/// guarda una [Position], no un slot, y ya tiene 12 sitios de uso en el
/// motor de ejercicios de una sola decisión — cambiarla ahí rompería esa
/// API sin necesidad.
typedef StreetAction = ({int slot, PokerAction action});

/// El estado de la ronda de apuestas de la calle en curso.
class BettingRound {
  BettingRound({
    required this.street,
    this.currentBetBb = 0,
    required this.minRaiseIncrementBb,
    this.lastAggressorSlot,
    Set<int> actedSlots = const {},
    Set<int> cannotReraiseSlots = const {},
    List<StreetAction> log = const [],
  })  : actedSlots = Set.unmodifiable(actedSlots),
        cannotReraiseSlots = Set.unmodifiable(cannotReraiseSlots),
        log = List.unmodifiable(log);

  final Street street;

  /// Monto total (no el incremento) que hay que igualar para seguir en
  /// mano en esta calle.
  final double currentBetBb;

  /// El incremento mínimo que debe tener un raise para ser válido (regla
  /// estándar NLHE: al menos el tamaño del último raise/bet).
  final double minRaiseIncrementBb;

  /// Slot del último jugador que apostó o subió en esta calle. `null` si
  /// nadie apostó todavía.
  final int? lastAggressorSlot;

  /// Slots que ya actuaron al menos una vez en esta calle desde la última
  /// subida (se usa para saber si la calle está cerrada).
  final Set<int> actedSlots;

  /// Slots que ya actuaron contra el nivel de apuesta actual y por lo
  /// tanto **no** pueden volver a subir mientras no haya un raise
  /// completo — solo pueden pagar o retirarse. Se llenan cuando alguien
  /// va all-in por un monto que sube la apuesta pero no llega a un raise
  /// completo (un "short all-in raise" no reabre la acción para quienes
  /// ya respondieron al nivel anterior; sí retienen su derecho a subir
  /// los jugadores que todavía no actuaron contra ese nivel). Ver
  /// [ActionResolver] y el informe de la auditoría de Fase 1+2.
  final Set<int> cannotReraiseSlots;

  /// Historial de acciones de esta calle, en orden.
  final List<StreetAction> log;

  BettingRound copyWith({
    Street? street,
    double? currentBetBb,
    double? minRaiseIncrementBb,
    int? lastAggressorSlot,
    bool clearLastAggressor = false,
    Set<int>? actedSlots,
    Set<int>? cannotReraiseSlots,
    List<StreetAction>? log,
  }) =>
      BettingRound(
        street: street ?? this.street,
        currentBetBb: currentBetBb ?? this.currentBetBb,
        minRaiseIncrementBb: minRaiseIncrementBb ?? this.minRaiseIncrementBb,
        lastAggressorSlot: clearLastAggressor
            ? null
            : (lastAggressorSlot ?? this.lastAggressorSlot),
        actedSlots: actedSlots ?? this.actedSlots,
        cannotReraiseSlots: cannotReraiseSlots ?? this.cannotReraiseSlots,
        log: log ?? this.log,
      );

  @override
  String toString() =>
      'BettingRound($street, bet: $currentBetBb, minRaiseInc: '
      '$minRaiseIncrementBb, lastAggressor: $lastAggressorSlot)';
}
