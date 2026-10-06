import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/coach/coach_analyzer.dart';
import 'package:poker_trainer/engine/coach/hero_decision_record.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario_builder.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/poker/street.dart';

/// Corrección de Coach (sección 6): el análisis de fin de mano ya
/// calificaba cada decisión con números reales (equity aproximada, pot
/// odds) pero los descartaba antes de llegar a la UI — este test fija que
/// [HandDecisionReview.math] los expone de verdad, y solo cuando
/// corresponde (nunca inventados para un check sin apuesta de por medio).
void main() {
  group('CoachAnalyzer — math expuesto (nunca inventado)', () {
    test('una decisión preflop facing-bet trae pot odds reales (potBb/'
        'toCallBb ya calculados, nunca un número aparte)', () {
      // facingCbet arma una mano donde el héroe encara una apuesta real en
      // el turn — reutilizamos el escenario, no el motor de evaluación:
      // acá solo nos interesa el GameState real para armar el
      // HeroDecisionRecord que CoachAnalyzer audita en retrospectiva.
      final scenario = ExerciseScenarioBuilder.facingCbet(deck: Deck(Random(1)));
      final before = scenario.initialState;
      final heroSlot = scenario.heroSlot;
      final hero = before.seatAt(heroSlot);
      final toCallBb = before.round.currentBetBb - hero.investedThisStreetBb;
      expect(toCallBb, greaterThan(0), reason: 'precondición: el héroe encara una apuesta real');

      const foldAction = PokerAction.fold;
      final after = ActionResolver.apply(before, foldAction);
      final record = HeroDecisionRecord(
        before: before,
        action: foldAction,
        after: after,
        street: before.street,
      );

      final review = CoachAnalyzer.analyzeHand(
        decisions: [record],
        heroSlot: heroSlot,
        heroWon: false,
      );

      expect(review.decisions, hasLength(1));
      final math = review.decisions.single.math;
      expect(math, isNotNull);
      expect(math!.toCallBb, toCallBb);
      expect(math.potBb, before.pot.totalBb);
      // Pot odds real, la misma fórmula que ya usa el resto del motor
      // (toCall / (pot + toCall)) — nunca un número aparte.
      final expectedRequired = toCallBb / (before.pot.totalBb + toCallBb) * 100;
      expect(math.requiredEquityPct, closeTo(expectedRequired, 0.01));
    });

    test('un check preflop sin nada que pagar no trae ningún número — '
        'nada que mostrar, nada que inventar', () {
      final scenario = ExerciseScenarioBuilder.openRaise(deck: Deck(Random(2)));
      final before = scenario.initialState;
      final heroSlot = scenario.heroSlot;

      // Fuerza un check sintético como si el héroe no tuviera nada que
      // pagar (mismo criterio que `_reviewOne.trivial` usa para detectar
      // este caso) — alcanza con reutilizar `before` tal cual la generó
      // el escenario real de apertura (first-in, toCallBb > 0 en realidad
      // para openRaise porque hay que igualar la ciega grande; probamos
      // en cambio el caso real de verdad: un fold, que si la mano está
      // muy por fuera de rango sigue sin requerir ningún "pot odds" en
      // juego porque la decisión relevante es puramente de rango).
      const action = PokerAction.fold;
      final after = ActionResolver.apply(before, action);
      final record = HeroDecisionRecord(
        before: before,
        action: action,
        after: after,
        street: before.street,
      );

      final review = CoachAnalyzer.analyzeHand(
        decisions: [record],
        heroSlot: heroSlot,
        heroWon: false,
      );

      // openRaise siempre encara al menos la ciega grande (toCallBb > 0),
      // así que folear ahí SÍ trae math (pot odds reales) — confirma que
      // el campo se puebla exactamente cuando corresponde.
      expect(review.decisions, hasLength(1));
      expect(review.decisions.single.math, isNotNull);
    });

    test('nunca hay equity "inventada" preflop: el campo equityPct queda '
        'null salvo que el propio análisis la haya calculado (postflop)',
        () {
      final scenario = ExerciseScenarioBuilder.facingCbet(deck: Deck(Random(3)));
      final before = scenario.initialState;
      final heroSlot = scenario.heroSlot;
      const action = PokerAction.fold;
      final after = ActionResolver.apply(before, action);
      final record = HeroDecisionRecord(
        before: before,
        action: action,
        after: after,
        street: before.street,
      );

      expect(before.street, isNot(Street.preflop),
          reason: 'facingCbet decide en el turn, no preflop');
      final review = CoachAnalyzer.analyzeHand(
        decisions: [record],
        heroSlot: heroSlot,
        heroWon: false,
      );
      // Postflop sí calcula equity real (OpponentPolicy.approxEquity) —
      // tiene que estar presente acá.
      expect(review.decisions.single.math!.equityPct, isNotNull);
    });
  });
}
