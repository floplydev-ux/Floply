import '../poker/deck.dart';
import 'templates/hand_picker.dart';

/// Primera representación de dificultad para el Laboratorio (Fase 10) —
/// solo controla qué tan clara es la mano del héroe dentro de la familia
/// de escenario ya elegida (`PreflopScenarioKind`); nunca cambia qué
/// conceptos evalúa un escenario, así que nunca puede exponer al alumno
/// a un concepto que no tenga enseñado (esa garantía sigue siendo de
/// `ExerciseScenarioAdapter.adapt`, independiente de esto).
enum DifficultyLevel {
  easy,
  standard,
  hard;

  /// El sesgo de mano a aplicar para esta dificultad — reutiliza
  /// `HandPicker.biasForDifficulty` (ya existente, Fase 1) para
  /// `easy`/`hard` tal cual, sin reinventar el sesgo. `standard` usa
  /// `HandBias.any` a propósito, no el nivel 2 de esa escala vieja: es
  /// el comportamiento default que ya tenía el motor antes de esta fase,
  /// y cambiarlo habría alterado sesiones existentes sin que nadie lo
  /// pidiera.
  HandBias heroHandBias(Deck deck) => switch (this) {
        DifficultyLevel.easy => HandPicker.biasForDifficulty(deck, 1),
        DifficultyLevel.standard => HandBias.any,
        DifficultyLevel.hard => HandPicker.biasForDifficulty(deck, 3),
      };
}
