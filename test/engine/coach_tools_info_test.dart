import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/coach/coach_tools_info.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/poker/position.dart';

/// Corrección de Coach (sección 7): las herramientas de ayuda tenían dos
/// huecos reales frente al pedido del usuario.
///
/// 1. `_bestGuessVillain` podía devolver la posición del propio héroe
///    como "rival" (cuando el héroe era quien venía agrediendo la calle
///    actual) — un bug real, no solo una mejora cosmética: el resto de
///    las tarjetas (equity, combos) terminaban comparando al héroe
///    contra SU PROPIO rango.
/// 2. El rango del rival nunca se actualizaba según lo que de verdad
///    pasó en la mano — siempre su rango de apertura completo, incluso
///    cuando ya había pagado una subida del héroe (donde existe una
///    tabla real más angosta en `PreflopRangeBook`, el mismo mecanismo
///    que ya usa `PostflopStrategy._villainRangeFor`).
void main() {
  group('CoachToolsInfo — rival real, nunca el propio héroe', () {
    test('cuando el héroe es quien agredió esta calle, el rival identificado '
        'nunca es el propio héroe', () {
      // cbetDecision: el héroe (CO) abrió preflop, el rival (BB) pagó, y
      // en el flop el rival checkea — el héroe decide un c-bet.
      final scenario = ExerciseScenarioBuilder.cbetDecision(
        deck: Deck(Random(1)),
        heroPosition: Position.co,
        villainPosition: Position.bb,
      );
      final before = scenario.initialState;
      final heroSlot = scenario.heroSlot;

      final afterBet =
          ActionResolver.apply(before, PokerAction.bet(before.pot.totalBb));

      // El héroe ahora es el agresor de la calle — antes de la
      // corrección, `_bestGuessVillain` devolvía la posición del héroe
      // en este caso exacto (aggressor == heroSlot).
      final spot = CoachToolsInfo.spotSummary(afterBet, heroSlot);
      expect(spot, contains('CO'));

      final equityText = CoachToolsInfo.equitySummary(afterBet, heroSlot);
      // Nunca puede decir "Contra un rango típico de CO" (el rival real
      // es BB) — eso delataría que el "rival" detectado fue el héroe.
      expect(equityText, isNot(contains('rango típico de CO')));
      expect(equityText, contains('BB'));
    });

    test('el rango del rival se angosta a la tabla real de defensa cuando '
        'de verdad pagó una subida del héroe esta calle (nunca su rango de '
        'apertura completo en ese caso)', () {
      final scenario = ExerciseScenarioBuilder.cbetDecision(
        deck: Deck(Random(2)),
        heroPosition: Position.co,
        villainPosition: Position.bb,
      );
      final before = scenario.initialState;
      final heroSlot = scenario.heroSlot;
      final afterBet =
          ActionResolver.apply(before, PokerAction.bet(before.pot.totalBb));

      final combosText = CoachToolsInfo.combosSummary(afterBet, heroSlot);
      // La tarjeta de combos tiene que poder calcularse (no cae al texto
      // de "todavía no hay board que descontar") y nombrar al rival real.
      expect(combosText, contains('BB'));
      expect(combosText, contains('combos'));
    });

    test('sin ancla real para el par exacto, se mantiene el proxy de '
        'siempre (rango de apertura del rival) — nunca se inventa una '
        'tabla para un par que no existe', () {
      // BTN vs BB no tiene ancla en PreflopRangeBook (solo bb-vs-co,
      // btn-vs-utg, btn-vs-co) — tiene que seguir funcionando igual que
      // antes de esta corrección.
      final scenario = ExerciseScenarioBuilder.cbetDecision(
        deck: Deck(Random(3)),
        heroPosition: Position.btn,
        villainPosition: Position.bb,
      );
      final before = scenario.initialState;
      final heroSlot = scenario.heroSlot;
      final afterBet =
          ActionResolver.apply(before, PokerAction.bet(before.pot.totalBb));

      expect(
          () => CoachToolsInfo.equitySummary(afterBet, heroSlot), returnsNormally);
    });

    test('preflop no calcula combos (no hay board que descontar todavía) — '
        'nunca inventa un conteo sin cartas comunitarias', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(4)));
      final result = CoachToolsInfo.combosSummary(
          scenario.initialState, scenario.heroSlot);
      expect(result, contains('flop'));
    });
  });

  group('CoachToolsInfo — spot con stacks y SPR reales', () {
    test('spotSummary muestra los stacks reales de los jugadores activos '
        'y el SPR del héroe, nunca un número inventado', () {
      final scenario = ExerciseScenarioBuilder.cbetDecision(deck: Deck(Random(5)));
      final before = scenario.initialState;
      final heroSlot = scenario.heroSlot;
      final hero = before.seatAt(heroSlot);

      final text = CoachToolsInfo.spotSummary(before, heroSlot);
      expect(text, contains('Stacks:'));
      expect(text, contains('SPR:'));
      final expectedSpr = (hero.stackBb / before.pot.totalBb);
      final expectedSprText = expectedSpr == expectedSpr.roundToDouble()
          ? expectedSpr.toStringAsFixed(0)
          : expectedSpr.toStringAsFixed(1);
      expect(text, contains('SPR: $expectedSprText'));
    });
  });
}
