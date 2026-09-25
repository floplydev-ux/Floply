import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/strategy/preflop_authoring.dart';
import 'package:poker_trainer/engine/strategy/strategy.dart';

void main() {
  group('StrategicRatingTier', () {
    test('optimal y veryGood agrupan a top', () {
      expect(StrategicRating.optimal.tier, QualityTier.top);
      expect(StrategicRating.veryGood.tier, QualityTier.top);
    });

    test('viable agrupa a mid', () {
      expect(StrategicRating.viable.tier, QualityTier.mid);
    });

    test('dubious y bad agrupan a low', () {
      expect(StrategicRating.dubious.tier, QualityTier.low);
      expect(StrategicRating.bad.tier, QualityTier.low);
    });
  });

  group('ContextSensitivity', () {
    test('stable() no tiene factores y queda "revelado" por definición', () {
      const s = ContextSensitivity.stable();
      expect(s.isDependent, isFalse);
      expect(s.factors, isEmpty);
      expect(s.disclosedToStudent, isTrue);
    });

    test('dependent() exige al menos un factor', () {
      expect(
        () => ContextSensitivity.dependent(const []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('dependent() por default no está revelado al alumno', () {
      final s = ContextSensitivity.dependent([ContextFactor.opponentProfile]);
      expect(s.isDependent, isTrue);
      expect(s.disclosedToStudent, isFalse);
    });

    test('dependent() puede declararse revelado explícitamente', () {
      final s = ContextSensitivity.dependent(
        [ContextFactor.opponentProfile],
        disclosedToStudent: true,
      );
      expect(s.disclosedToStudent, isTrue);
    });
  });

  group('isCoherentCell', () {
    test('quality top + mixShare negligible es incoherente', () {
      expect(
        isCoherentCell(
          quality: StrategicRating.optimal,
          mixShare: MixShare.negligible,
        ),
        isFalse,
      );
      expect(
        isCoherentCell(
          quality: StrategicRating.veryGood,
          mixShare: MixShare.negligible,
        ),
        isFalse,
      );
    });

    test('quality top + mixShare pure/primary/secondary es coherente', () {
      for (final share in [
        MixShare.pure,
        MixShare.primary,
        MixShare.secondary,
      ]) {
        expect(
          isCoherentCell(quality: StrategicRating.optimal, mixShare: share),
          isTrue,
        );
      }
    });

    test('cualquier mixShare es coherente con quality mid/low', () {
      for (final quality in [
        StrategicRating.viable,
        StrategicRating.dubious,
        StrategicRating.bad,
      ]) {
        for (final share in MixShare.values) {
          expect(isCoherentCell(quality: quality, mixShare: share), isTrue);
        }
      }
    });
  });

  group('MixShare.representativeFrequency', () {
    test('es solo informativo: pure=100%, negligible cerca de 0%', () {
      expect(MixShare.pure.representativeFrequency, 1.0);
      expect(MixShare.negligible.representativeFrequency, lessThan(0.15));
    });

    test('primary siempre representa más que secondary', () {
      expect(
        MixShare.primary.representativeFrequency,
        greaterThan(MixShare.secondary.representativeFrequency),
      );
    });
  });

  group('StrategyRole', () {
    test('tiene exactamente los 8 roles definidos en el diseño', () {
      expect(StrategyRole.values, [
        StrategyRole.value,
        StrategyRole.bluff,
        StrategyRole.defend,
        StrategyRole.fold,
        StrategyRole.fourBetValue,
        StrategyRole.fourBetBluff,
        StrategyRole.jamValue,
        StrategyRole.jamBluff,
      ]);
    });
  });
}
