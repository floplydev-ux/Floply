import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/deck.dart';
import 'package:poker_trainer/engine/poker/game/action_resolver.dart';
import 'package:poker_trainer/engine/poker/game/legal_action_engine.dart';
import 'package:poker_trainer/engine/poker/game/opponent_policy.dart';
import 'package:poker_trainer/engine/poker/game/scenario_builder.dart';
import 'package:poker_trainer/engine/poker/hole_cards.dart';
import 'package:poker_trainer/engine/poker/poker_action.dart';
import 'package:poker_trainer/engine/strategy/hand_strength.dart';
import 'package:poker_trainer/engine/strategy/hand_range.dart';
import 'package:poker_trainer/engine/strategy/opening_ranges.dart';

/// Devuelve la notación de la primera clase de mano (de las 169) cuyo
/// percentil cumple [matches] — más robusto que asumir a mano qué
/// percentil exacto tiene una notación puntual.
String _handWithPercentile(bool Function(double percentile) matches) {
  for (final hc in HandClass.all()) {
    if (matches(HandStrength.percentile(hc.notation))) return hc.notation;
  }
  throw StateError('Ninguna clase de mano cumple el percentil pedido');
}

/// Cartas concretas para una notación de clase, vía un mazo descartable
/// — solo hace falta que las cartas existan, no de qué mazo salieron.
HoleCards _concreteHand(String notation, {int seed = 0}) =>
    Deck(Random(seed)).dealHandOfClass(notation)!;

int _slotFor(Position position, int buttonSlot) =>
    TablePositions(buttonSlot).slotOf(position);

void main() {
  group('OpponentPolicy.decide — nadie subió más allá de la ciega grande', () {
    test('mano claramente en el rango de apertura: sube al tamaño estándar',
        () {
      final utgSlot = _slotFor(Position.utg, 0);
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {utgSlot: HoleCards.parse('AsAd')},
      );
      expect(state.toActSlot, utgSlot);
      final action = OpponentPolicy.decide(state);
      expect(action.type, ActionType.raise);
      expect(action.sizeBb, OpeningRanges.sizingFor(Position.utg));
    });

    test('mano claramente fuera del rango de apertura: foldea', () {
      final utgSlot = _slotFor(Position.utg, 0);
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {utgSlot: HoleCards.parse('7h2c')},
      );
      final action = OpponentPolicy.decide(state);
      expect(action.type, ActionType.fold);
    });

    test('la BB, con todos los limpers ya pagados, pasa (no foldea ni '
        'sube)', () {
      final bbSlot = _slotFor(Position.bb, 0);
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {bbSlot: HoleCards.parse('AsAd')},
      );
      while (state.toActSlot != bbSlot) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      }
      expect(OpponentPolicy.decide(state), const PokerAction(ActionType.check));
    });
  });

  group('OpponentPolicy.decide — enfrentando una subida', () {
    test('mano premium (percentil <= 0.06): resube a 3x la subida actual',
        () {
      final utgSlot = _slotFor(Position.utg, 0);
      final hjSlot = _slotFor(Position.hj, 0);
      final premium = _handWithPercentile((p) => p <= 0.05);
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {
          utgSlot: HoleCards.parse('7h2c'), // sube igual, mano irrelevante
          hjSlot: _concreteHand(premium, seed: 2),
        },
      );
      state = ActionResolver.apply(state, PokerAction.raiseTo(3));
      expect(state.toActSlot, hjSlot);
      final action = OpponentPolicy.decide(state);
      expect(action.type, ActionType.raise);
      expect(action.sizeBb, 9);
    });

    test('mano media (percentil entre 0.06 y 0.28): paga', () {
      final utgSlot = _slotFor(Position.utg, 0);
      final hjSlot = _slotFor(Position.hj, 0);
      final medium = _handWithPercentile((p) => p > 0.10 && p < 0.25);
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {
          utgSlot: HoleCards.parse('7h2c'),
          hjSlot: _concreteHand(medium, seed: 3),
        },
      );
      state = ActionResolver.apply(state, PokerAction.raiseTo(3));
      final action = OpponentPolicy.decide(state);
      expect(action.type, ActionType.call);
    });

    test('mano basura (percentil > 0.35): foldea', () {
      final utgSlot = _slotFor(Position.utg, 0);
      final hjSlot = _slotFor(Position.hj, 0);
      final trash = _handWithPercentile((p) => p > 0.5);
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {
          utgSlot: HoleCards.parse('7h2c'),
          hjSlot: _concreteHand(trash, seed: 4),
        },
      );
      state = ActionResolver.apply(state, PokerAction.raiseTo(3));
      final action = OpponentPolicy.decide(state);
      expect(action.type, ActionType.fold);
    });
  });

  group('OpponentPolicy.decide — nunca propone una acción ilegal', () {
    test('con stack corto, si la regla pide subir pero no alcanza ni para '
        'un raise completo, va all-in', () {
      final utgSlot = _slotFor(Position.utg, 0);
      final hjSlot = _slotFor(Position.hj, 0);
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        stackOverridesBb: {hjSlot: 2},
        explicitHandBySlot: {
          utgSlot: HoleCards.parse('7h2c'),
          hjSlot: HoleCards.parse('AsAd'), // premium: la regla "quiere" subir
        },
      );
      state = ActionResolver.apply(state, PokerAction.raiseTo(3));
      final action = OpponentPolicy.decide(state);
      expect(action.type, ActionType.allIn);
    });

    test('el tamaño de subida siempre queda clampeado a [minRaiseTo, '
        'maxRaiseTo] — nunca se arma un PokerAction fuera de rango', () {
      final utgSlot = _slotFor(Position.utg, 0);
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        stackOverridesBb: {utgSlot: 3}, // apenas alcanza para un raise mínimo
        explicitHandBySlot: {utgSlot: HoleCards.parse('AsAd')},
      );
      final action = OpponentPolicy.decide(state);
      // No debe explotar al aplicarla: si estuviera fuera de rango,
      // ActionResolver.apply tiraría IllegalActionException.
      expect(() => ActionResolver.apply(state, action), returnsNormally);
    });
  });

  group('OpponentPolicy.decide — falla explícita, no en silencio', () {
    test('sin jugador en turno (mano terminada): StateError', () {
      final bbSlot = _slotFor(Position.bb, 0);
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {bbSlot: HoleCards.parse('AsAd')},
      );
      while (!state.isHandOver) {
        if (state.toActSlot == bbSlot) break;
        state = ActionResolver.apply(state, const PokerAction(ActionType.fold));
      }
      expect(state.isHandOver, isTrue);
      expect(() => OpponentPolicy.decide(state), throwsStateError);
    });

    test('sin mano conocida (holeCards null): StateError', () {
      final state = ScenarioBuilder.freshHand(deck: Deck(Random(1)), buttonSlot: 0);
      expect(state.seatAt(state.toActSlot!).holeCards, isNull);
      expect(() => OpponentPolicy.decide(state), throwsStateError);
    });

    test('postflop (Grupo 8 — Mesa con Coach): decide una acción legal '
        'real, fundamentada en HandStrengthClassifier, no en '
        'UnsupportedError', () {
      final wideRange = HandRange.parse(const [
        '22+', 'A2s+', 'A2o+', 'K2s+', 'K2o+', 'Q2s+', 'Q2o+', 'J2s+', 'J2o+',
      ]);
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(9)),
        buttonSlot: 0,
        rangeBySlot: {for (var s = 0; s < 6; s++) s: wideRange},
      );
      while (state.toActSlot != _slotFor(Position.bb, 0)) {
        state = ActionResolver.apply(state, const PokerAction(ActionType.call));
      }
      state = ActionResolver.apply(state, const PokerAction(ActionType.check));
      state = ActionResolver.advanceStreet(state);
      expect(state.street.name, 'flop');
      final action = OpponentPolicy.decide(state);
      expect(LegalActionEngine.legalActionTypes(state), contains(action.type));
    });
  });

  group('OpponentPolicy.decide — OpponentProfile (Fase 8.7)', () {
    test('sin pasar profile, decide() se comporta exactamente igual que '
        'pasando profile: OpponentProfile.balanced explícito — cero cambio '
        'de comportamiento por la extracción', () {
      final utgSlot = _slotFor(Position.utg, 0);
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {utgSlot: HoleCards.parse('AsAd')},
      );
      expect(
        OpponentPolicy.decide(state),
        OpponentPolicy.decide(state, profile: OpponentProfile.balanced),
      );
    });

    test('un profile distinto realmente cambia la decisión — el parámetro '
        'no es decorativo', () {
      final utgSlot = _slotFor(Position.utg, 0);
      // Con balanced (openFrequency 0.5), esta mano fuera de rango foldea.
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {utgSlot: HoleCards.parse('7h2c')},
      );
      expect(OpponentPolicy.decide(state).type, ActionType.fold);

      const wideOpen = OpponentProfile(
        name: 'wideOpen',
        openFrequency: 0,
        threeBetPercentile: 0.06,
        callPercentile: 0.35,
        threeBetMultiplier: 3,
      );
      final action = OpponentPolicy.decide(state, profile: wideOpen);
      expect(action.type, ActionType.raise,
          reason: 'con openFrequency 0 (abre cualquier mano) ya no debería '
              'foldear');
    });
  });

  group('OpponentPolicy.decide — determinismo', () {
    test('el mismo GameState da siempre la misma decisión', () {
      final utgSlot = _slotFor(Position.utg, 0);
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {utgSlot: HoleCards.parse('AsAd')},
      );
      expect(OpponentPolicy.decide(state), OpponentPolicy.decide(state));
    });
  });

  group('OpponentPolicy.decide — passive/tag (Fase 10.1/10.2)', () {
    for (final profile in [OpponentProfile.passive, OpponentProfile.tag]) {
      test('${profile.name}: nunca propone una acción ilegal en una '
          'batería de manos, abriendo o enfrentando una subida', () {
        final utgSlot = _slotFor(Position.utg, 0);
        final hjSlot = _slotFor(Position.hj, 0);

        for (final notation in ['AA', 'KQs', 'T9s', '72o', 'J8o']) {
          // Abriendo: fresh hand, UTG es el primero en actuar.
          final openState = ScenarioBuilder.freshHand(
            deck: Deck(Random(notation.hashCode)),
            buttonSlot: 0,
            explicitHandBySlot: {utgSlot: _concreteHand(notation, seed: 1)},
          );
          final openAction = OpponentPolicy.decide(openState, profile: profile);
          expect(() => ActionResolver.apply(openState, openAction), returnsNormally,
              reason: '${profile.name}/$notation/open');

          // Enfrentando una subida: HJ decide tras el open de UTG. Ambas
          // manos salen del MISMO Deck (nunca de dos fuentes separadas)
          // para que nunca puedan pisarse — la mano de UTG es irrelevante
          // (solo abre para forzar la subida), pero tiene que ser una
          // carta real y única igual que cualquier otra.
          final sharedDeck = Deck(Random(notation.hashCode + 1));
          final hjHand = sharedDeck.dealHandOfClass(notation)!;
          final utgHand = HoleCards(sharedDeck.dealCard(), sharedDeck.dealCard());
          var facingState = ScenarioBuilder.freshHand(
            deck: sharedDeck,
            buttonSlot: 0,
            explicitHandBySlot: {utgSlot: utgHand, hjSlot: hjHand},
          );
          facingState = ActionResolver.apply(facingState, PokerAction.raiseTo(3));
          final facingAction = OpponentPolicy.decide(facingState, profile: profile);
          expect(() => ActionResolver.apply(facingState, facingAction), returnsNormally,
              reason: '${profile.name}/$notation/facing');
        }
      });

      test('${profile.name}: mismo estado siempre da la misma decisión',
          () {
        final utgSlot = _slotFor(Position.utg, 0);
        final state = ScenarioBuilder.freshHand(
          deck: Deck(Random(3)),
          buttonSlot: 0,
          explicitHandBySlot: {utgSlot: HoleCards.parse('Ts9s')},
        );
        expect(
          OpponentPolicy.decide(state, profile: profile),
          OpponentPolicy.decide(state, profile: profile),
        );
      });
    }

    test('passive siempre foldea manos mixtas (freq=0.5) que balanced '
        'abre probabilísticamente', () {
      // Las manos mixtas tienen freq=0.5 en el rango de apertura.
      // passive.openFrequency=0.7 → nunca las abre (determinístico).
      // balanced.openFrequency=0.5 → las abre ~50% de veces (probabilístico).
      // Solo verificamos la propiedad determinística: passive siempre foldea.
      final utgRange = OpeningRanges.forPosition(Position.utg);
      String? mixedNotation;
      for (final hc in HandClass.all()) {
        if ((utgRange.frequencyOf(hc.notation) - 0.5).abs() < 0.01) {
          mixedNotation = hc.notation;
          break;
        }
      }
      expect(mixedNotation, isNotNull,
          reason: 'debe existir al menos una clase de mano mixta (freq≈0.5) en UTG');

      final utgSlot = _slotFor(Position.utg, 0);
      final state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {utgSlot: _concreteHand(mixedNotation!, seed: 7)},
      );
      // Passive nunca abre manos mixtas (freq=0.5 < openFrequency=0.7).
      for (var i = 0; i < 20; i++) {
        expect(OpponentPolicy.decide(state, profile: OpponentProfile.passive).type,
            ActionType.fold,
            reason: 'passive no debería abrir freq=0.5 (run $i)');
      }
    });

    test('tag paga menos manos marginales que balanced: donde balanced '
        'paga (callPercentile más ancho), tag foldea', () {
      // percentile entre 0.25 (tag.callPercentile) y 0.28
      // (balanced.callPercentile): balanced todavía paga acá, tag ya no
      // (ni entra en su threeBetPercentile de 0.04, así que foldea).
      // Busca en la zona (0.25, 0.30) para tener más candidatos — el
      // umbral balanced=0.28 sigue siendo el que distingue ambos perfiles.
      final frontier = _handWithPercentile((p) => p > 0.25 && p < 0.28);
      final utgSlot = _slotFor(Position.utg, 0);
      final hjSlot = _slotFor(Position.hj, 0);
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(1)),
        buttonSlot: 0,
        explicitHandBySlot: {
          utgSlot: HoleCards.parse('7h2c'),
          hjSlot: _concreteHand(frontier, seed: 8),
        },
      );
      state = ActionResolver.apply(state, PokerAction.raiseTo(3));
      expect(OpponentPolicy.decide(state, profile: OpponentProfile.balanced).type,
          ActionType.call);
      expect(OpponentPolicy.decide(state, profile: OpponentProfile.tag).type,
          ActionType.fold);
    });
  });

  group('OpponentPolicy — integración de punta a punta', () {
    test('una ronda preflop completa jugada solo con OpponentPolicy '
        'converge sin ninguna acción puesta a mano, conservando las '
        'fichas en cada paso', () {
      final wideRange = HandRange.parse(const [
        '22+', 'A2s+', 'A2o+', 'K2s+', 'K2o+', 'Q2s+', 'Q2o+', 'J2s+', 'J2o+',
      ]);
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(21)),
        buttonSlot: 0,
        rangeBySlot: {for (var s = 0; s < 6; s++) s: wideRange},
      );
      final totalInicial =
          state.seats.fold(0.0, (sum, s) => sum + s.stackBb) + state.pot.totalBb;

      void checkConservation(String where) {
        final total = state.seats.fold(0.0, (sum, s) => sum + s.stackBb) +
            state.pot.totalBb;
        expect(total, closeTo(totalInicial, 1e-9), reason: where);
      }

      var guard = 0;
      while (!state.isStreetComplete && !state.isHandOver) {
        final action = OpponentPolicy.decide(state);
        state = ActionResolver.apply(state, action);
        checkConservation('tras la decisión #$guard de OpponentPolicy');
        guard++;
        expect(guard, lessThan(50),
            reason: 'no debería hacer falta tanto para cerrar preflop');
      }
      expect(state.isStreetComplete || state.isHandOver, isTrue);
    });

    test(
        'de punta a punta multi-calle (Grupo 8 — Mesa con Coach): '
        'OpponentPolicy resuelve preflop Y postflop por su cuenta, calle '
        'tras calle, hasta el showdown pendiente o el fin de la mano', () {
      final wideRange = HandRange.parse(const [
        '22+', 'A2s+', 'A2o+', 'K2s+', 'K2o+', 'Q2s+', 'Q2o+', 'J2s+', 'J2o+',
      ]);
      var state = ScenarioBuilder.freshHand(
        deck: Deck(Random(33)),
        buttonSlot: 0,
        rangeBySlot: {for (var s = 0; s < 6; s++) s: wideRange},
      );

      // De punta a punta: ninguna acción puesta a mano por el test, todo
      // sale de OpponentPolicy — tanto preflop como postflop.
      var guard = 0;
      while (!state.isHandOver &&
          !(state.street.name == 'river' && state.isStreetComplete)) {
        if (state.isStreetComplete) {
          state = ActionResolver.advanceStreet(state);
        } else {
          final action = OpponentPolicy.decide(state);
          expect(LegalActionEngine.legalActionTypes(state), contains(action.type));
          state = ActionResolver.apply(state, action);
        }
        guard++;
        expect(guard, lessThan(100));
      }

      if (state.isHandOver) {
        // Puede pasar (todos foldean menos uno) — igual de válido.
        expect(state.winnerSlots, isNotEmpty);
        return;
      }

      expect(state.needsShowdown, isTrue);
      expect(state.board.length, 5);
    });
  });
}
