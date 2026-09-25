import '../poker/game/game_state.dart';
import 'decision_context.dart';

/// Qué tipo de decisión representa un [ExerciseScenario] — el mismo eje
/// que las secciones A-E del pedido de Fase 5, no una clasificación por
/// tipo de pregunta (eso es [ExerciseType], en el sistema viejo de
/// `exercise.dart`, sin relación con esto).
///
/// **Nombre histórico**: las primeras 5 familias eran todas preflop, de
/// ahí el nombre del enum. [cbetDecision] (Laboratorio Postflop, ver
/// `LABORATORIO_POSTFLOP_AUDITORIA_DISENO.md`) es la primera familia
/// postflop — se agregó acá en vez de crear un enum paralelo para no
/// reescribir `LabSessionController`/`LaboratoryDifficulty`/
/// `PreflopSessionSummary` (que ya tipan todo en términos de este enum)
/// solo por precisión de nombre. Deuda de naming reconocida, no
/// escondida: si en algún momento se agregan más familias postflop,
/// ahí sí conviene renombrar el enum entero de una vez.
enum PreflopScenarioKind {
  /// Bote sin abrir: el héroe es el primero en entrar voluntariamente.
  openRaise,

  /// Un rival abrió; el héroe decide fold/call/3-bet.
  defenseVsOpen,

  /// Mismo mecanismo que [defenseVsOpen] — la diferencia es pedagógica
  /// (qué conceptos declara), no de generación.
  threeBet,

  /// El héroe abrió, un rival re-subió; el héroe decide.
  facingThreeBet,

  /// Cualquiera de los anteriores, con el stack lo bastante corto como
  /// para que `LegalActionEngine` restrinja las acciones legales.
  shortStack,

  /// Postflop — el héroe fue el agresor preflop y decide si c-apuesta
  /// en un flop que favorece a su rango (`PostflopStrategy.
  /// boardFavorsAggressor`), antes de cualquier apuesta en esta calle.
  /// El rival defensor checkea de guion (acción mecánica, no evaluada).
  cbetDecision;

  /// Nombre en lenguaje de jugador — Fase 8, promovido desde el
  /// `_kindLabel` privado de `preflop_session_summary_view.dart` (Fase 7)
  /// para que el selector de Custom (mismo lenguaje) no lo duplique.
  /// Mismo criterio que `LaboratoryDifficulty.label` en este directorio:
  /// el enum lleva su propia presentación, no una capa de mapeo aparte.
  String get label => switch (this) {
        PreflopScenarioKind.openRaise => 'Open Raise',
        PreflopScenarioKind.defenseVsOpen => 'Defensa de ciegas',
        PreflopScenarioKind.threeBet => '3-Bet',
        PreflopScenarioKind.facingThreeBet => 'Encarar un 3-Bet',
        PreflopScenarioKind.shortStack => 'Stack corto',
        PreflopScenarioKind.cbetDecision => 'C-Bet',
      };
}

/// Un ejercicio preflop completo: la situación real ([initialState], ya
/// en el punto exacto donde decide el héroe), su descripción
/// ([decisionContext]) y su metadata pedagógica.
///
/// Inmutable — se arma una sola vez (`ExerciseScenarioBuilder`) y no
/// cambia. No contiene widgets ni texto de presentación: eso es trabajo
/// de una capa posterior (Fase 6), no de este tipo.
class ExerciseScenario {
  const ExerciseScenario({
    required this.initialState,
    required this.heroSlot,
    required this.decisionContext,
    required this.objective,
    required this.evaluableConcepts,
    this.metadata = const {},
  });

  /// El estado del motor en el momento exacto en que el héroe tiene que
  /// decidir — no "el arranque de la mano", sino el punto de decisión
  /// real (después de que los rivales de fondo ya actuaron).
  final GameState initialState;

  final int heroSlot;

  /// Redundante con `DecisionContext.fromGameState(initialState,
  /// heroSlot: heroSlot)` a propósito: se calcula una sola vez al armar
  /// el escenario y se guarda, en vez de recalcularse en cada consulta.
  final DecisionContext decisionContext;

  final PreflopScenarioKind objective;

  /// Conceptos que este escenario evalúa — el evaluador nunca menciona
  /// un concepto que no esté acá.
  final List<String> evaluableConcepts;

  final Map<String, Object?> metadata;
}
