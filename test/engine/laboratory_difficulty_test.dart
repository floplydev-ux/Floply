import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/difficulty_level.dart';
import 'package:poker_trainer/engine/exercises/exercise_scenario.dart';
import 'package:poker_trainer/engine/exercises/laboratory_difficulty.dart';

void main() {
  group('LaboratoryDifficulty.allowedScenarioKinds — el eje real de la '
      'dificultad', () {
    test('Fácil: una sola familia (openRaise)', () {
      expect(LaboratoryDifficulty.easy.allowedScenarioKinds,
          [PreflopScenarioKind.openRaise]);
    });

    test('Medio: abrir + responder a una apertura (3 familias)', () {
      expect(
        LaboratoryDifficulty.medium.allowedScenarioKinds.toSet(),
        {
          PreflopScenarioKind.openRaise,
          PreflopScenarioKind.defenseVsOpen,
          PreflopScenarioKind.shortStack,
        },
      );
    });

    test('Experto: las 5 familias que el motor soporta hoy', () {
      expect(LaboratoryDifficulty.expert.allowedScenarioKinds.toSet(),
          PreflopScenarioKind.values.toSet());
    });

    test('Medio es subconjunto estricto de Experto (nunca al revés)', () {
      final medium = LaboratoryDifficulty.medium.allowedScenarioKinds.toSet();
      final expert = LaboratoryDifficulty.expert.allowedScenarioKinds.toSet();
      expect(medium.difference(expert), isEmpty);
      expect(expert.difference(medium), isNotEmpty);
    });

    test('Fácil es subconjunto estricto de Medio', () {
      final easy = LaboratoryDifficulty.easy.allowedScenarioKinds.toSet();
      final medium = LaboratoryDifficulty.medium.allowedScenarioKinds.toSet();
      expect(easy.difference(medium), isEmpty);
      expect(medium.difference(easy), isNotEmpty);
    });
  });

  test('el sesgo de mano (handBias) es secundario, nunca el eje principal — '
      'reutiliza DifficultyLevel en vez de duplicarlo', () {
    expect(LaboratoryDifficulty.easy.handBias, DifficultyLevel.easy);
    expect(LaboratoryDifficulty.medium.handBias, DifficultyLevel.standard);
    expect(LaboratoryDifficulty.expert.handBias, DifficultyLevel.hard);
  });
}
