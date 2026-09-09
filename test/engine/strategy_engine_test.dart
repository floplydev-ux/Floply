import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/poker_situation.dart';
import 'package:poker_trainer/engine/exercises/templates/situation_factory.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/poker/position.dart';
import 'package:poker_trainer/engine/strategy/strategy.dart';
import 'package:poker_trainer/engine/strategy/strategy_engine.dart';

void main() {
  const engine = StrategyEngine();

  PokerSituation firstIn(String pos, String hand, {double stack = 100}) {
    return SituationFactory.firstIn(
      heroPosition: Position.values.firstWhere((p) => p.abbreviation == pos),
      heroCards: HoleCards.parse(hand),
      effectiveStackBb: stack,
      availableRaiseSizes: const [2.5],
    );
  }

  group('openRaiseStrategy', () {
    test('mano premium desde UTG: subir es óptimo, foldear es malo', () {
      final s = engine.openRaiseStrategy(firstIn('UTG', 'AsAd'));
      final raise = s.optionFor(PokerAction.raiseTo(2.5))!;
      final fold = s.optionFor(PokerAction.fold)!;
      expect(raise.rating, StrategicRating.optimal);
      expect(fold.rating, StrategicRating.bad);
      expect(s.primary.action.type, ActionType.raise);
    });

    test('basura desde UTG: foldear es óptimo, subir es malo', () {
      final s = engine.openRaiseStrategy(firstIn('UTG', '7d2c'));
      expect(s.primary.action.type, ActionType.fold);
      expect(s.optionFor(PokerAction.raiseTo(2.5))!.rating, StrategicRating.bad);
    });

    test('la misma mano marginal se abre en BTN pero no en UTG', () {
      final utg = engine.openRaiseStrategy(firstIn('UTG', 'Jc9c'));
      final btn = engine.openRaiseStrategy(firstIn('BTN', 'Jc9c'));
      expect(utg.primary.action.type, ActionType.fold);
      expect(btn.primary.action.type, ActionType.raise);
    });

    test('mano de frontera produce estrategia mixta', () {
      // Buscamos una notación con frecuencia intermedia en BTN.
      final s = engine.openRaiseStrategy(firstIn('BTN', 'Kh7d'));
      expect(s.isMixed, isTrue);
      final total = s.totalFrequency;
      expect(total, closeTo(1.0, 0.001));
      // Ninguna de las dos acciones debería ser "mala" en una mixta.
      for (final o in s.options) {
        expect(o.rating.index, lessThanOrEqualTo(StrategicRating.viable.index));
      }
    });

    test('las frecuencias siempre suman ~1', () {
      for (final hand in ['AsKs', 'Qh9h', '5c5d', 'Ad3d', 'Ts8s', '9c4h']) {
        for (final pos in ['UTG', 'CO', 'BTN', 'SB']) {
          final s = engine.openRaiseStrategy(firstIn(pos, hand));
          expect(s.totalFrequency, closeTo(1.0, 0.02),
              reason: '$pos $hand');
        }
      }
    });
  });

  group('openSizingStrategy', () {
    test('el tamaño estándar es óptimo y el limp es malo', () {
      final situation = firstIn('CO', 'AsKs');
      final s = engine.openSizingStrategy(situation, const [1.5, 2.5, 3.0, 5.0]);
      expect(s.optionFor(PokerAction.raiseTo(2.5))!.rating,
          StrategicRating.optimal);
      expect(s.optionFor(PokerAction.raiseTo(1.5))!.rating, StrategicRating.bad);
      expect(s.optionFor(PokerAction.raiseTo(5.0))!.rating,
          StrategicRating.dubious);
    });
  });
}
