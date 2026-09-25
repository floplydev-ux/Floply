import 'difficulty_level.dart';
import 'exercise_scenario.dart';

/// Los 3 niveles de entrenamiento que el usuario elige al entrar al
/// Laboratorio: **qué tipo de práctica quiere hacer**, no un ajuste fino
/// del motor.
///
/// No confundir con [DifficultyLevel] (`easy`/`standard`/`hard`), que
/// sigue existiendo tal cual y sigue controlando solo el sesgo de mano
/// dentro de una familia ya elegida — un eje distinto y más chico. El eje
/// real de esta clase es **cuántas familias de escenario** (y por lo
/// tanto cuántos conceptos y cuánta información previa) entran en juego:
/// eso es lo que hace que Experto se sienta más exigente que Fácil, no
/// simplemente manos más "difíciles" con los mismos conceptos de siempre.
///
/// Estado real del contenido disponible: [ExerciseScenarioBuilder] ya
/// tiene una primera familia postflop
/// (`PreflopScenarioKind.cbetDecision` — ver
/// `LABORATORIO_POSTFLOP_AUDITORIA_DISENO.md`), pero acotada a una sola
/// situación (c-bet de rango completo en un flop que favorece al
/// agresor). Por eso solo entra en **Experto**: necesita conceptos
/// bastante más avanzados (`cbet` se enseña recién en el nivel 8 de
/// Academia) que las 5 familias preflop, así que mezclarla en Fácil/
/// Medio rompería la progresión de dificultad real (qué tanto sabe el
/// alumno), no solo la de "cuántas familias hay". "Experto" sigue
/// significando *todo lo que el motor puede generar hoy* — turn/river,
/// más familias postflop, siguen sin existir.
enum LaboratoryDifficulty {
  /// Una sola familia (`openRaise`): el héroe decide si abre o no desde
  /// una posición, con una mano clara dentro o fuera de rango. El
  /// escenario preflop más simple que el motor puede generar.
  easy,

  /// Combina "abrir" con "responder a una apertura ajena" (`openRaise` +
  /// `defenseVsOpen` + `shortStack`): el alumno tiene que leer una acción
  /// previa además de su propia posición y rango — más de un concepto
  /// interactuando en la misma decisión.
  medium,

  /// Las 5 familias que el motor soporta hoy, incluyendo 3-bet y encarar
  /// un 3-bet — las líneas con más historial de acciones previas que hay
  /// que procesar antes de decidir.
  expert;

  /// Las familias de escenario que esta dificultad puede generar. El
  /// verdadero eje de la dificultad — nunca un ajuste de "número más
  /// grande" sobre la misma familia.
  List<PreflopScenarioKind> get allowedScenarioKinds => switch (this) {
        LaboratoryDifficulty.easy => const [
            PreflopScenarioKind.openRaise,
          ],
        LaboratoryDifficulty.medium => const [
            PreflopScenarioKind.openRaise,
            PreflopScenarioKind.defenseVsOpen,
            PreflopScenarioKind.shortStack,
          ],
        LaboratoryDifficulty.expert => PreflopScenarioKind.values,
      };

  /// `true` si esta dificultad puede generar `cbetDecision` — la única
  /// familia postflop hoy, gateada a Experto (ver el doc-comment de la
  /// clase). Atajo sobre [allowedScenarioKinds] para no repetir la
  /// comparación en cada caller.
  bool get includesPostflop => allowedScenarioKinds.contains(PreflopScenarioKind.cbetDecision);

  /// Sesgo de mano secundario para esta dificultad — reutiliza
  /// [DifficultyLevel], nunca lo duplica. Es un ajuste menor (qué tan
  /// obvia es la mano) sobre el eje real (arriba); documentado así para
  /// que nadie lo lea como "Experto = manos más difíciles".
  DifficultyLevel get handBias => switch (this) {
        LaboratoryDifficulty.easy => DifficultyLevel.easy,
        LaboratoryDifficulty.medium => DifficultyLevel.standard,
        LaboratoryDifficulty.expert => DifficultyLevel.hard,
      };

  String get label => switch (this) {
        LaboratoryDifficulty.easy => 'FÁCIL',
        LaboratoryDifficulty.medium => 'MEDIO',
        LaboratoryDifficulty.expert => 'EXPERTO',
      };

  String get subtitle => switch (this) {
        LaboratoryDifficulty.easy => 'Principiante',
        LaboratoryDifficulty.medium => 'Intermedio',
        LaboratoryDifficulty.expert => 'Integración total',
      };

  String get description => switch (this) {
        LaboratoryDifficulty.easy =>
          'Una sola decisión por ejercicio: abrir o no desde tu posición. '
              'Ideal para consolidar las primeras teorías.',
        LaboratoryDifficulty.medium =>
          'Abrir y responder a una apertura ajena, incluso con el stack '
              'corto. Combina más de un concepto por decisión.',
        LaboratoryDifficulty.expert =>
          'Todas las familias disponibles hoy, incluyendo 3-bet, encarar '
              'un 3-bet, y tu primera decisión postflop (c-bet).',
      };
}
