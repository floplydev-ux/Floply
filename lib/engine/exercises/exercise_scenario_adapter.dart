import '../concepts/concept_registry.dart';
import '../concepts/user_knowledge.dart';
import '../pedagogy/playable_exercise.dart' as playable;
import '../pedagogy/table_lesson.dart';
import '../poker/game/action_resolver.dart';
import '../poker/game/game_state.dart';
import '../poker/poker_action.dart';
import '../poker/sizing/bet_sizing_engine.dart';
import 'answer_evaluator.dart';
import 'decision_context.dart';
import 'exercise_scenario.dart';
import 'lab_feedback_builder.dart';
import 'preflop_rationale_bank.dart';
import 'scenario_strategy.dart';

/// Un [ExerciseScenario] ya traducido a la mesa existente, más el mapeo
/// de vuelta desde lo que el alumno tocó hacia la [PokerAction] real que
/// hay que aplicarle a [StudentTurnController] — mismo patrón que
/// `TableExerciseAdaptation` (`table_exercise_adapter.dart`) usa para el
/// sistema viejo, adaptado acá a que no hay un `UserAnswer`/`engine.
/// submit`: la acción real es lo único que hace falta reconstruir.
class ExerciseScenarioAdaptation {
  const ExerciseScenarioAdaptation(this.tableExercise, this._actionByChoice);

  final playable.PlayableTableExercise tableExercise;
  final Map<Object, PokerAction> _actionByChoice;

  /// La [PokerAction] real correspondiente a la [playable.ActionChoice]
  /// (y, si aplica, el [playable.BetSizeOption]) que el alumno eligió.
  PokerAction actionFor(playable.ActionChoice action, playable.BetSizeOption? size) =>
      _actionByChoice[size ?? action]!;
}

/// Traduce un [ExerciseScenario] del motor nuevo a un
/// [playable.PlayableTableExercise] para la mesa existente — **solo
/// traduce**, no decide legalidad ni agrega reglas de póker propias:
/// todo sale de `DecisionContext.legalActions` (ya calculado por
/// `LegalActionEngine`) y de `AnswerEvaluator` real.
///
/// Mismo patrón que `table_exercise_adapter.dart`: evalúa TODAS las
/// opciones legales por adelantado (vista previa completa) y arma un
/// `PlayableTableExercise` ya calificado — nunca se re-evalúa nada al
/// resolver la decisión real.
class ExerciseScenarioAdapter {
  const ExerciseScenarioAdapter._();

  /// `null` si, tras filtrar `scenario.evaluableConcepts` contra lo que
  /// [knowledge] tiene enseñado, no queda ningún concepto evaluable —
  /// mismo contrato que ya usa `adaptToTable` ("esta situación no es
  /// presentable a este usuario ahora"). Nunca se inventa una evaluación
  /// sobre un concepto no enseñado.
  static ExerciseScenarioAdaptation? adapt(
    ExerciseScenario scenario,
    UserKnowledge knowledge,
    ConceptRegistry registry, {
    String heroName = 'Vos',
    int seed = 0,
  }) {
    final taught = scenario.evaluableConcepts
        .where(knowledge.taughtConcepts.contains)
        .toList();
    if (taught.isEmpty) return null;

    final context = scenario.decisionContext;
    final initial = scenario.initialState;
    final heroSlot = scenario.heroSlot;

    final baseSnapshot = _toTableSnapshot(initial, heroSlot).withCast(heroName, seed);

    String conceptName(String id) => registry.tryById(id)?.name ?? id;

    String feedbackFor(AnswerResult result) {
      final concepts = result.justifyingConcepts.where(taught.contains).toList();
      // Texto real por `rationaleKey` si ya existe en el banco (Fase 1,
      // paso 8 del rediseño preflop — ver `PreflopRationaleBank`); si
      // no, el mismo texto genérico por veredicto que ya usaba esta
      // función para TODAS las claves antes de este paso.
      final base = PreflopRationaleBank.textFor(result.matchedOption.rationaleKey) ??
          switch (result.verdict) {
            AnswerVerdict.best => 'Es la mejor jugada en esta situación.',
            AnswerVerdict.acceptable =>
              'Es una jugada defendible, aunque no la preferida acá.',
            AnswerVerdict.poor => 'No es una buena elección en esta situación.',
            AnswerVerdict.dependent =>
              'No hay una única respuesta correcta acá: depende de tu rango '
                  'y tu estilo.',
          };
      if (concepts.isEmpty) return base;
      return '$base Repasá: ${concepts.map(conceptName).join(", ")}.';
    }

    playable.ExerciseRating toRating(AnswerVerdict verdict) => switch (verdict) {
          AnswerVerdict.best => playable.ExerciseRating.best,
          AnswerVerdict.acceptable ||
          AnswerVerdict.dependent =>
            playable.ExerciseRating.acceptable,
          AnswerVerdict.poor => playable.ExerciseRating.poor,
        };

    TableSnapshot afterAction(PokerAction action) {
      final next = ActionResolver.apply(initial, action);
      return _toTableSnapshot(next, heroSlot).withCast(heroName, seed);
    }

    final actionByChoice = <Object, PokerAction>{};
    final actions = <playable.ActionChoice>[];
    var anyDependent = false;

    final needsSizing = context.legalActions.contains(ActionType.raise) ||
        context.legalActions.contains(ActionType.bet);
    final recommendedSizes = needsSizing ? _recommendedSizes(scenario, context) : null;

    for (final type in context.legalActions) {
      if (type == ActionType.raise || type == ActionType.bet) {
        final sizeOptions = <playable.BetSizeOption>[];
        AnswerResult? firstResult;
        for (final sizeBb in recommendedSizes!) {
          final action = _sizedAction(type, sizeBb);
          final result = AnswerEvaluator.evaluate(scenario, action);
          firstResult ??= result;
          if (result.verdict == AnswerVerdict.dependent) anyDependent = true;

          final betSize = playable.BetSizeOption(
            label: '${_formatBb(action.sizeBb!)} BB',
            rating: toRating(result.verdict),
            feedback: feedbackFor(result),
            afterDecision: afterAction(action),
            richFeedback: LabFeedbackBuilder.build(scenario, result, knowledge, registry),
          );
          actionByChoice[betSize] = action;
          sizeOptions.add(betSize);
        }

        final choice = playable.ActionChoice(
          action: type,
          label: type.label.toUpperCase(),
          rating: toRating(firstResult!.verdict),
          feedback: feedbackFor(firstResult),
          sizeOptions: sizeOptions,
          richFeedback: LabFeedbackBuilder.build(scenario, firstResult, knowledge, registry),
        );
        actionByChoice[choice] = actionByChoice[sizeOptions.first]!;
        actions.add(choice);
      } else {
        final action = PokerAction(type);
        final result = AnswerEvaluator.evaluate(scenario, action);
        if (result.verdict == AnswerVerdict.dependent) anyDependent = true;

        final choice = playable.ActionChoice(
          action: type,
          label: type.label.toUpperCase(),
          rating: toRating(result.verdict),
          feedback: feedbackFor(result),
          afterDecision: afterAction(action),
          richFeedback: LabFeedbackBuilder.build(scenario, result, knowledge, registry),
        );
        actionByChoice[choice] = action;
        actions.add(choice);
      }
    }

    final explanationSteps = [
      playable.ExerciseExplainStep(
        text: 'Conceptos en juego acá: ${taught.map(conceptName).join(", ")}.',
        anchor: TableAnchor.heroCards,
      ),
    ];

    return ExerciseScenarioAdaptation(
      playable.PlayableTableExercise(
        situation: baseSnapshot,
        actions: actions,
        explanation: explanationSteps,
        concept: taught.first,
        strategyDependent: anyDependent,
      ),
      actionByChoice,
    );
  }

  static PokerAction _sizedAction(ActionType type, double sizeBb) =>
      type == ActionType.bet ? PokerAction.bet(sizeBb) : PokerAction.raiseTo(sizeBb);

  static String _formatBb(double bb) =>
      bb == bb.roundToDouble() ? bb.toStringAsFixed(0) : bb.toStringAsFixed(1);

  /// Los tamaños ofrecidos para RAISE/BET — clampeados a
  /// `[minRaiseToBb, maxRaiseToBb]`. `_SizeButtons` en la mesa ya
  /// renderiza cualquier cantidad de `BetSizeOption` — no hace falta
  /// ningún cambio de UI para esto.
  ///
  /// **BET** (sin cambios de comportamiento — Fase 8.4): el mínimo legal
  /// y, si difiere, el que recomienda la estrategia de referencia (o
  /// medio bote si [StrategyOption.action.sizeBb] es `null`, p. ej.
  /// `PostflopStrategy`: la lección ahí es "hay que apostar", no un
  /// tamaño exacto — cualquier tamaño matchea esa opción, ver su
  /// doc-comment; el tamaño sugerido nunca decide si la apuesta del
  /// alumno es correcta, eso lo sigue haciendo [AnswerEvaluator] contra
  /// la opción real).
  ///
  /// **RAISE** (Campo de Entrenamiento — corrección de Open Raise):
  /// siempre 3 tamaños reales y distintos cuando el rango legal lo
  /// permite, nunca un número fijo tipo "2.5/3/3.5" — arrancan de los
  /// tamaños que la propia estrategia ya calificó distinto (hoy: Open
  /// Raise, vía `StrategyEngine.openSizingStrategy` sobre la banda real
  /// de `OpeningRanges`) y se completan con el mínimo legal y pasos
  /// reales dentro de `[min, max]` hasta llegar a 3 — o hasta donde el
  /// rango legal realmente lo permita (un spot de stack corto con
  /// `min ≈ max` puede dar legítimamente menos de 3: forzar 3 botones
  /// idénticos sería peor que mostrar los que de verdad son distintos).
  static List<double> _recommendedSizes(
      ExerciseScenario scenario, DecisionContext context) {
    final strategy =
        ScenarioStrategy.forDecision(scenario.initialState, scenario.heroSlot);
    final min = context.minRaiseToBb!;
    final max = context.maxRaiseToBb!;
    double clamp(double size) => size < min ? min : (size > max ? max : size);

    final type =
        context.legalActions.contains(ActionType.raise) ? ActionType.raise : ActionType.bet;

    if (type == ActionType.bet) {
      final primary = strategy.primary;
      final desired = clamp(primary.action.type == ActionType.bet
          ? (primary.action.sizeBb ?? BetSizingEngine.potSizedBet(context.potBb, fraction: 0.5))
          : BetSizingEngine.potSizedBet(context.potBb, fraction: 0.5));
      return desired == min ? [min] : [min, desired];
    }

    final strategySizes = strategy.options
        .where((o) => o.action.type == ActionType.raise && o.action.sizeBb != null)
        .map((o) => clamp(o.action.sizeBb!));

    final sizes = {...strategySizes, min}.toList()..sort();
    const step = 0.5;
    var guard = 0;
    while (sizes.length < 3 && guard < 20) {
      guard++;
      final candidate = clamp(sizes.last + step);
      if (sizes.contains(candidate)) break; // tope del rango legal: no se puede crecer más.
      sizes.add(candidate);
      sizes.sort();
    }
    return sizes.take(3).toList();
  }

  static TableSnapshot _toTableSnapshot(GameState state, int heroSlot) => TableSnapshot(
        seats: [for (var slot = 0; slot < 6; slot++) _toSeatState(state, slot, heroSlot)],
        board: [for (final c in state.board) c.code],
        potBb: state.pot.totalBb,
        buttonSlot: state.buttonSlot,
      );

  static SeatState _toSeatState(GameState state, int slot, int heroSlot) {
    final player = state.seatAt(slot);
    if (player.sittingOut) return SeatState.empty(slot);

    final isHero = slot == heroSlot;
    final hand = player.holeCards;
    // Las cartas de los rivales nunca se muestran, aunque el motor las
    // conozca (las necesita OpponentPolicy) — mismo criterio que ya usa
    // table_exercise_adapter.dart.
    final cards = isHero && hand != null ? [hand.high.code, hand.low.code] : const <String>[];

    return SeatState(
      slot: slot,
      label: state.positionOf(slot).label,
      isHero: isHero,
      cards: cards,
      betBb: player.investedThisStreetBb,
      stackBb: player.stackBb,
      action: _lastActionLabel(state, slot),
      folded: player.folded,
      toAct: state.toActSlot == slot,
    );
  }

  /// `GameState`/`PlayerState` no guardan "última acción" por asiento —
  /// se deriva de `round.log` (poblado desde el hardening de Fase 2).
  /// Las ciegas no dejan entrada en el log (se postean al armar la mano,
  /// no vía `ActionResolver`), así que un asiento sin log pero con algo
  /// ya invertido esta calle se muestra como `'POST'`.
  static String? _lastActionLabel(GameState state, int slot) {
    final entries = state.round.log.where((e) => e.slot == slot);
    if (entries.isEmpty) {
      return state.seatAt(slot).investedThisStreetBb > 0 ? 'POST' : null;
    }
    return switch (entries.last.action.type) {
      ActionType.fold => 'FOLD',
      ActionType.check => 'CHECK',
      ActionType.call => 'CALL',
      ActionType.bet => 'BET',
      ActionType.raise => 'RAISE',
      ActionType.allIn => 'ALL-IN',
      ActionType.limp => 'CALL',
    };
  }
}
