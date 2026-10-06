import '../poker_action.dart';
import 'game_state.dart';

/// Qué acciones puede tomar el jugador en turno, y con qué tamaños.
///
/// Reglas estándar de No-Limit Hold'em (bookkeeping determinístico — nada
/// de IA, GTO ni muestreo). El diseño distingue [ActionType.allIn] de un
/// `call`/`raise` normal exactamente en el caso donde importa: cuando el
/// stack del jugador no alcanza para una acción de tamaño completo.
class LegalActionEngine {
  const LegalActionEngine._();

  /// Los tipos de acción legales para el jugador en turno ([GameState.
  /// toActSlot]). Vacío si no hay nadie en turno (mano terminada).
  static Set<ActionType> legalActionTypes(GameState state) {
    final slot = state.toActSlot;
    if (slot == null) return const {};
    final player = state.seatAt(slot);
    if (!player.canAct) return const {};

    final owed = state.round.currentBetBb - player.investedThisStreetBb;

    if (owed <= 0) {
      // Nadie apostó todavía en esta calle, o el jugador ya iguala lo que
      // hay (p. ej. la BB con su propia ciega antes de su opción): CHECK
      // siempre disponible. Si tiene con qué, BET — pero solo un BET de
      // tamaño completo (`minRaiseToBb`) si el stack le alcanza; con un
      // stack más corto que eso, la única apuesta real posible es
      // ALL-IN (regla estándar: un all-in no tiene que cumplir el
      // mínimo). Sin esto, `maxRaiseToBb` (todo el stack) podía quedar
      // por DEBAJO de `minRaiseToBb`, un rango `[min, max]` imposible
      // que `ActionResolver` rechazaba — hallazgo real de la Mesa con
      // Coach (Grupo 8) con stacks cortos tras varias calles de acción.
      if (player.stackBb <= 0) return const {ActionType.check};
      final canFullBet =
          player.investedThisStreetBb + player.stackBb >= minRaiseToBb(state);
      return {
        ActionType.check,
        canFullBet ? ActionType.bet : ActionType.allIn,
      };
    }

    if (player.stackBb <= owed) {
      // No le alcanza ni para igualar del todo: la única forma de seguir
      // en la mano es empujar el resto de su stack. Esto nunca supera
      // `currentBetBb`, así que no "sube" nada — no importa si el
      // jugador está en [BettingRound.cannotReraiseSlots].
      return const {ActionType.fold, ActionType.allIn};
    }

    if (state.round.cannotReraiseSlots.contains(slot)) {
      // Ya actuó contra este nivel de apuesta y el único aumento que
      // hubo después fue un all-in corto (no reabrió la acción): puede
      // pagar o retirarse, pero no puede volver a subir ni empujar de
      // más — ver el doc-comment de `BettingRound.cannotReraiseSlots`.
      return const {ActionType.fold, ActionType.call};
    }

    final canFullRaise =
        (player.stackBb - owed) >= state.round.minRaiseIncrementBb;
    return {
      ActionType.fold,
      ActionType.call,
      canFullRaise ? ActionType.raise : ActionType.allIn,
    };
  }

  /// El total (no el incremento) mínimo de una subida — o de una apuesta de
  /// apertura, que es el mismo cálculo con `currentBetBb == 0`. Cubre
  /// también el caso de la BB (o cualquiera que ya iguala lo que hay)
  /// decidiendo aumentar en vez de solo pasar: aunque la acción legal se
  /// llame `bet` ahí, el piso sigue siendo `currentBetBb + increment`, no
  /// `increment` a secas — ver `ActionResolver._applyAggressive`, que usa
  /// este mismo método para validar tanto `bet` como `raise`. Un total que
  /// no llega a esto no es una subida de tamaño completo: es un all-in
  /// corto (ver [legalActionTypes]).
  static double minRaiseToBb(GameState state) =>
      state.round.currentBetBb + state.round.minRaiseIncrementBb;

  /// El total máximo al que se puede subir o abrir: todo lo que el
  /// jugador en turno tiene, incluido lo ya invertido en esta calle.
  static double maxRaiseToBb(GameState state) {
    final slot = state.toActSlot;
    if (slot == null) {
      throw StateError('No hay jugador en turno');
    }
    final player = state.seatAt(slot);
    return player.investedThisStreetBb + player.stackBb;
  }
}
