import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../engine/concepts/user_knowledge.dart';
import '../../engine/exercises/answer_evaluator.dart';
import '../../engine/exercises/difficulty_level.dart';
import '../../engine/exercises/exercise_scenario.dart';
import '../../engine/exercises/exercise_scenario_adapter.dart';
import '../../engine/exercises/exercise_scenario_builder.dart';
import '../../engine/exercises/laboratory_difficulty.dart';
import '../../engine/exercises/preflop_session_summary.dart';
import '../../engine/exercises/scenario_randomizer.dart';
import '../../engine/exercises/student_turn_controller.dart';
import '../../engine/exercises/templates/hand_picker.dart' show HandBias;
import '../../engine/pedagogy/playable_exercise.dart';
import '../../engine/pedagogy/playable_exercise_controller.dart';
import '../../engine/poker/deck.dart';
import '../../engine/poker/game/game_state.dart';
import '../../engine/poker/game/opponent_policy.dart';
import '../../engine/poker/position.dart';
import '../../engine/poker_trainer_engine.dart';
import '../../models/app_user.dart';

/// Fase actual de una sesión de práctica del Laboratorio.
enum LabPhase { idle, question, feedback, summary }

/// Coordina una sesión de práctica contra el [PokerTrainerEngine].
///
/// No sabe nada de widgets: la pantalla solo escucha [notifyListeners] y
/// pinta el estado. Así el flujo se puede testear sin UI.
///
/// **Fase 9**: eliminado el Modo Clásico (el camino que usaba
/// `Exercise`/`ExerciseGenerator`/`TableExerciseAdaptation` directamente
/// desde este controller vía `start()`/`_loadNext()`). El único motor que
/// queda acá es el nuevo (`ExerciseScenarioBuilder` →
/// `StudentTurnController` → [PlayableExerciseController], el mismo que
/// usa la Academia para sus ejercicios de mesa). `Exercise`/
/// `ExerciseGenerator` no se borraron del proyecto — Academia los sigue
/// usando para recuperación y práctica sin script interactivo (ver
/// `exercise.dart`) — solo dejaron de tener un llamador acá.
class LabSessionController extends ChangeNotifier with PlayableExerciseController {
  LabSessionController({PokerTrainerEngine? engine, this.sessionLength = 8})
      : engine = engine ?? PokerTrainerEngine() {
    knowledge = this.engine.newUser();
  }

  final PokerTrainerEngine engine;

  /// Cuántos ejercicios tiene la sesión activa. Mutable desde la Fase 8
  /// (antes `final`, siempre 8): Custom deja elegir la cantidad antes de
  /// arrancar (`startNewEngineSession`), Fácil/Medio/Experto siguen sin
  /// tocarlo — mismo default de siempre, cero cambio de comportamiento
  /// para esos tres.
  int sessionLength;

  late UserKnowledge knowledge;

  LabPhase phase = LabPhase.idle;

  ExerciseScenarioAdaptation? _newAdaptation;
  StudentTurnController? _turnController;

  /// Resultados reales del motor nuevo durante esta sesión — uno por
  /// decisión resuelta en [onPlayableResolved], nunca por cada opción
  /// de la vista previa. Base de [newEngineSummary] (Fase 8.5).
  final List<(PreflopScenarioKind, AnswerResult)> newEngineResults = [];

  /// Perfil de rival y dificultad activos para la sesión del motor nuevo
  /// en curso — se fijan una vez en [startNewEngineSession] y se
  /// reutilizan para cada ejercicio de esa sesión (coherencia dentro de
  /// la sesión). Defaults iguales al comportamiento previo a Fase 10
  /// (`balanced`/`standard`, este último equivalente a `HandBias.any`):
  /// arrancar sin argumentos no cambia nada de lo que ya funcionaba.
  OpponentProfile activeOpponentProfile = OpponentProfile.balanced;
  DifficultyLevel activeDifficulty = DifficultyLevel.standard;

  /// Dificultad de Laboratorio (Fácil/Medio/Experto) activa para la
  /// sesión en curso — `null` significa "sin restricción de familia"
  /// (nunca expuesto hoy por ningún botón real desde que la Fase 9
  /// eliminó el atajo de desarrollo que lo dejaba en `null` a propósito).
  /// Determina qué subconjunto de [PreflopScenarioKind] puede salir en
  /// [loadNewEnginePreflopExercise] — el eje real de la dificultad, ver
  /// `LaboratoryDifficulty`.
  LaboratoryDifficulty? activeLabDifficulty;

  /// Selección explícita del usuario (Fase 8, modo Custom) — mutuamente
  /// excluyente con [activeLabDifficulty] (`startNewEngineSession` limpia
  /// el que no corresponda). Cuando no es `null`, tiene prioridad sobre
  /// [activeLabDifficulty] en [loadNewEnginePreflopExercise]: el usuario
  /// eligió explícitamente qué practicar, no una dificultad preconfigurada.
  /// Nunca vacía en la práctica — `LaboratoryScreen` no deja arrancar
  /// Custom sin al menos una familia elegida (ver `_CustomSelector`); acá
  /// no se re-valida por las dudas porque `Deck.pick` de una lista vacía
  /// repetiría exactamente el `RangeError` ya documentado en la Fase 7,
  /// así que la garantía tiene que vivir en la UI, antes de esta llamada.
  List<PreflopScenarioKind>? activeCustomScenarioKinds;

  /// Resumen armado bajo demanda a partir de [newEngineResults] — la
  /// única fuente de verdad que consume `PreflopSessionSummaryView` al
  /// llegar a [LabPhase.summary] (Fase 9: ya no coexiste con un resumen
  /// del motor viejo).
  PreflopSessionSummary get newEngineSummary =>
      PreflopSessionSummary.fromResults(newEngineResults);

  /// El escenario del motor nuevo actualmente en juego, o `null`. Mínimo
  /// necesario para que el estado sea inspeccionable (tests, debug) sin
  /// exponer `_turnController` entero.
  ExerciseScenario? get newEngineScenario => _turnController?.scenario;

  /// El `GameState` real y actual del escenario del motor nuevo, o
  /// `null` — refleja las acciones ya aplicadas vía
  /// `StudentTurnController.applyHeroAction`.
  GameState? get newEngineGameState => _turnController?.state;

  /// `true` mientras el ejercicio actual se muestra como mesa jugable.
  /// Puede ser `false` en el caso límite (deliberadamente forzado en
  /// tests, no alcanzable con el usuario real de Laboratorio, que arranca
  /// con todo enseñado) donde `ExerciseScenarioAdapter.adapt` no
  /// encuentra ningún concepto evaluable.
  bool get isTableExercise => _newAdaptation != null;

  @override
  PlayableTableExercise? get currentPlayable => _newAdaptation?.tableExercise;

  /// Carga un ejercicio preflop generado por el motor nuevo
  /// (`ExerciseScenarioBuilder` → `ExerciseScenario` →
  /// `ExerciseScenarioAdapter`). `null` (sin cambiar de fase) si, tras
  /// filtrar los conceptos del escenario contra [knowledge], no queda
  /// ninguno evaluable para este usuario (ver
  /// `ExerciseScenarioAdapter.adapt`).
  ///
  /// [kind] elige la familia a generar; sin especificar, rota
  /// aleatoriamente entre las familias permitidas vía `Deck.pick` — mismo
  /// `Deck` que ya se crea acá, nunca una segunda fuente de `Random`
  /// (Fase 8.1). Esas familias permitidas salen de
  /// [activeCustomScenarioKinds] si el usuario eligió Custom (Fase 8), si
  /// no de [activeLabDifficulty] (Fácil/Medio/Experto), si no todas.
  void loadNewEnginePreflopExercise({Deck? deck, PreflopScenarioKind? kind}) {
    playableActionIndex = null;
    playableSizeIndex = null;
    lastPlayableFeedback = null;

    final d = deck ?? Deck(Random());
    final allowedKinds = activeCustomScenarioKinds ??
        activeLabDifficulty?.allowedScenarioKinds ??
        PreflopScenarioKind.values;
    final scenario = _buildScenario(kind ?? d.pick(allowedKinds), d);
    _turnController = StudentTurnController(scenario);
    _newAdaptation = ExerciseScenarioAdapter.adapt(
      scenario,
      knowledge,
      engine.concepts,
      heroName: AppUser.current.firstName,
    );
    phase = LabPhase.question;
    notifyListeners();
  }

  /// Despacha al método de `ExerciseScenarioBuilder` correspondiente a
  /// cada familia, pasando [activeOpponentProfile]/[activeDifficulty]
  /// tal cual están fijados para la sesión.
  ///
  /// Posición, asiento del botón y stack salen de [ScenarioRandomizer]
  /// en vez de los defaults fijos de cada builder — antes de esto, cada
  /// familia se generaba SIEMPRE con la misma pareja de posiciones (p.
  /// ej. `openRaise` siempre BTN, `defenseVsOpen` siempre BB vs CO), que
  /// era la causa real de que el Laboratorio se sintiera repetitivo: la
  /// única variedad entre ejercicios era la mano, nunca la situación.
  ///
  /// [_biasAppliesTo] limita a qué familias/posiciones se les aplica el
  /// sesgo de dificultad: `HandBias` (`clearlyInRange`/
  /// `clearlyOutOfRange`/`borderline`) se define en términos de
  /// `OpeningRanges.forPosition(heroPosition)`, y esa tabla no tiene
  /// datos reales para la BB (nunca "abre") — pedirle un sesgo distinto
  /// de `any` ahí nunca se puede satisfacer y `HandPicker.forBias`
  /// termina lanzando `TemplateGenerationException`. Antes esto se
  /// resolvía excluyendo familias enteras (porque su héroe SIEMPRE era
  /// la BB); ahora que la posición varía, la condición real es sobre la
  /// posición efectiva de cada intento, no sobre la familia.
  ExerciseScenario _buildScenario(PreflopScenarioKind kind, Deck deck) {
    final buttonSlot = ScenarioRandomizer.buttonSlot(deck);
    final stackBb = ScenarioRandomizer.normalStackBb(deck);

    HandBias biasFor(Position heroPosition, {bool applies = true}) =>
        applies && _biasAppliesTo(kind, heroPosition)
            ? activeDifficulty.heroHandBias(deck)
            : HandBias.any;

    switch (kind) {
      case PreflopScenarioKind.openRaise:
        final heroPosition = ScenarioRandomizer.openRaiseHeroPosition(deck);
        return ExerciseScenarioBuilder.openRaise(
          deck: deck,
          buttonSlot: buttonSlot,
          heroPosition: heroPosition,
          stackBb: stackBb,
          opponentProfile: activeOpponentProfile,
          heroHandBias: biasFor(heroPosition),
        );
      case PreflopScenarioKind.defenseVsOpen:
        final (opener, hero) = ScenarioRandomizer.facingOpenPositions(deck);
        return ExerciseScenarioBuilder.defenseVsOpen(
          deck: deck,
          buttonSlot: buttonSlot,
          heroPosition: hero,
          openerPosition: opener,
          stackBb: stackBb,
          opponentProfile: activeOpponentProfile,
          heroHandBias: biasFor(hero),
        );
      case PreflopScenarioKind.threeBet:
        final (opener, hero) = ScenarioRandomizer.facingOpenPositions(deck);
        return ExerciseScenarioBuilder.threeBet(
          deck: deck,
          buttonSlot: buttonSlot,
          heroPosition: hero,
          openerPosition: opener,
          stackBb: stackBb,
          opponentProfile: activeOpponentProfile,
          heroHandBias: biasFor(hero),
        );
      case PreflopScenarioKind.facingThreeBet:
        final (hero, threeBettor) = ScenarioRandomizer.facingThreeBetPositions(deck);
        return ExerciseScenarioBuilder.facingThreeBet(
          deck: deck,
          buttonSlot: buttonSlot,
          heroPosition: hero,
          threeBettorPosition: threeBettor,
          stackBb: stackBb,
          opponentProfile: activeOpponentProfile,
          heroHandBias: biasFor(hero),
        );
      case PreflopScenarioKind.shortStack:
        final (opener, hero) = ScenarioRandomizer.facingOpenPositions(deck);
        return ExerciseScenarioBuilder.shortStackFacingOpen(
          deck: deck,
          buttonSlot: buttonSlot,
          heroPosition: hero,
          openerPosition: opener,
          heroStackBb: ScenarioRandomizer.shortStackBb(deck),
          opponentProfile: activeOpponentProfile,
          heroHandBias: biasFor(hero),
        );
      case PreflopScenarioKind.cbetDecision:
        // Sin `opponentProfile`: a diferencia de las 5 familias
        // preflop, el villano de esta familia nunca consulta
        // `OpponentPolicy` — paga preflop y checkea el flop de guion
        // (ver el doc-comment de `ExerciseScenarioBuilder.cbetDecision`),
        // así que no hay ningún perfil de rival que pasarle.
        final (hero, villain) = ScenarioRandomizer.aggressorWithPositionPositions(deck);
        return ExerciseScenarioBuilder.cbetDecision(
          deck: deck,
          buttonSlot: buttonSlot,
          heroPosition: hero,
          villainPosition: villain,
          stackBb: stackBb,
          heroHandBias: biasFor(hero, applies: false),
        );
      case PreflopScenarioKind.facingCbet:
        final (aggressor, hero) = ScenarioRandomizer.facingCbetPositions(deck);
        return ExerciseScenarioBuilder.facingCbet(
          deck: deck,
          buttonSlot: buttonSlot,
          heroPosition: hero,
          aggressorPosition: aggressor,
          stackBb: stackBb,
          flopBetPotFraction: ScenarioRandomizer.betPotFraction(deck),
          turnBetPotFraction: ScenarioRandomizer.betPotFraction(deck),
        );
      case PreflopScenarioKind.turnBarrel:
        final (hero, villain) = ScenarioRandomizer.aggressorWithPositionPositions(deck);
        return ExerciseScenarioBuilder.turnBarrel(
          deck: deck,
          buttonSlot: buttonSlot,
          heroPosition: hero,
          villainPosition: villain,
          stackBb: stackBb,
          flopBetPotFraction: ScenarioRandomizer.betPotFraction(deck),
        );
      case PreflopScenarioKind.riverBarrel:
        final (hero, villain) = ScenarioRandomizer.aggressorWithPositionPositions(deck);
        return ExerciseScenarioBuilder.riverBarrel(
          deck: deck,
          buttonSlot: buttonSlot,
          heroPosition: hero,
          villainPosition: villain,
          stackBb: stackBb,
          flopBetPotFraction: ScenarioRandomizer.betPotFraction(deck),
          turnBetPotFraction: ScenarioRandomizer.betPotFraction(deck),
        );
    }
  }

  /// `false` si aplicar el sesgo de dificultad no tiene sentido acá:
  /// [heroPosition] es la BB (`OpeningRanges` no tiene rango de apertura
  /// propio para ella, ver el doc-comment de arriba), o [kind] es una de
  /// las familias postflop nuevas/`cbetDecision` — todas se gradúan por
  /// equity real contra el board (`PostflopStrategy`), no por si la mano
  /// del héroe "está en rango": la fuerza de la mano ya es un dato que
  /// la propia estrategia usa, pedirle además un sesgo de dificultad
  /// sería pedirle dos cosas contradictorias a `HandPicker`.
  static bool _biasAppliesTo(PreflopScenarioKind kind, Position heroPosition) =>
      heroPosition != Position.bb &&
      kind != PreflopScenarioKind.cbetDecision &&
      kind != PreflopScenarioKind.facingCbet &&
      kind != PreflopScenarioKind.turnBarrel &&
      kind != PreflopScenarioKind.riverBarrel;

  @override
  int get itemNumber => answered + 1;

  @override
  int get itemTotal => sessionLength;

  @override
  String conceptName(String conceptId) =>
      engine.concepts.tryById(conceptId)?.name ?? conceptId;

  int answered = 0;

  /// `true` mientras la sesión en curso (o la que llegó a
  /// [LabPhase.summary]) es del motor nuevo — decide qué resumen mostrar
  /// (Fase 9.9). Explícito en vez de inferido de `_newAdaptation != null`
  /// porque ese campo queda "viejo" (última mesa resuelta) al llegar a
  /// `summary`, y no se limpia entre caminos dentro de la misma instancia
  /// de controller.
  bool _newEngineSession = false;
  bool get isNewEngineSession => _newEngineSession;

  /// Arranca una sesión nueva (Fase 9.9/9.10). Resetea
  /// [answered]/[newEngineResults] para que la sesión anterior no
  /// contamine la nueva.
  ///
  /// [opponentProfile]/[difficulty] (Fase 10) fijan el rival y la
  /// dificultad para TODA la sesión (se reutilizan en cada ejercicio
  /// hasta el próximo `startNewEngineSession`) — sin argumentos, el
  /// comportamiento es exactamente el de antes de Fase 10. Ninguna
  /// selección adaptativa automática todavía: quien decide el perfil/
  /// dificultad es siempre el caller (Fase 10.11, arquitectura
  /// preparada, no un sistema adaptativo).
  ///
  /// [labDifficulty] (selector Fácil/Medio/Experto) es la forma normal en
  /// que la pantalla arranca una sesión: cuando se pasa, fija qué
  /// familias puede generar [loadNewEnginePreflopExercise]
  /// (`labDifficulty.allowedScenarioKinds`) y también el sesgo de mano
  /// (`labDifficulty.handBias`), pisando cualquier [difficulty] que se
  /// haya pasado junto con él.
  ///
  /// [customScenarioKinds] (Fase 8, modo Custom) es la selección real del
  /// usuario — mutuamente excluyente con [labDifficulty] (si se pasan los
  /// dos, gana Custom, ver [activeCustomScenarioKinds]). No debe llegar
  /// vacía: quien llama (`_CustomSelector`) ya garantiza al menos una
  /// familia elegida antes de habilitar el botón de arrancar.
  /// [customSessionLength], si se pasa, reemplaza [sessionLength] para
  /// esta sesión (Custom deja elegir cantidad; Fácil/Medio/Experto no
  /// pasan esto y siguen con el default de siempre).
  void startNewEngineSession({
    OpponentProfile opponentProfile = OpponentProfile.balanced,
    DifficultyLevel difficulty = DifficultyLevel.standard,
    LaboratoryDifficulty? labDifficulty,
    List<PreflopScenarioKind>? customScenarioKinds,
    int? customSessionLength,
  }) {
    assert(customScenarioKinds == null || customScenarioKinds.isNotEmpty,
        'customScenarioKinds no puede ser una lista vacía — Deck.pick '
        'repetiría el RangeError de la Fase 7 (exercise_generator.dart).');
    _newEngineSession = true;
    activeOpponentProfile = opponentProfile;
    activeDifficulty = labDifficulty?.handBias ?? difficulty;
    activeLabDifficulty = customScenarioKinds == null ? labDifficulty : null;
    activeCustomScenarioKinds = customScenarioKinds;
    if (customSessionLength != null) sessionLength = customSessionLength;
    answered = 0;
    newEngineResults.clear();
    loadNewEnginePreflopExercise();
  }

  /// Abandona la sesión en curso (en pregunta o en feedback) y vuelve a
  /// [LabPhase.idle] — el botón "Salir" de [_LabHeader]. Ningún dato que
  /// deshacer: `knowledge`/`newEngineResults` solo se escriben al
  /// confirmar una respuesta ([onPlayableResolved]), nunca antes, así que
  /// el ejercicio a medio resolver (o ya resuelto, si se sale desde el
  /// feedback) simplemente deja de mostrarse — mismo criterio que ya usa
  /// [returnToIdle] para el resumen.
  void exitSession() {
    _newAdaptation = null;
    _turnController = null;
    phase = LabPhase.idle;
    notifyListeners();
  }

  /// Vuelve a [LabPhase.idle] desde el resumen del motor nuevo (Fase 9.9)
  /// — no toca ningún dato de la sesión que acaba de terminar, solo
  /// navega.
  void returnToIdle() {
    phase = LabPhase.idle;
    notifyListeners();
  }

  /// Registra la decisión tomada en la mesa: la acción real se aplica vía
  /// [StudentTurnController] (`LegalActionEngine`/`ActionResolver` de
  /// verdad, nunca reinterpretados acá) y escribe en [knowledge] (ver
  /// [_recordKnowledge]).
  @override
  void onPlayableResolved(
      PlayableTableExercise exercise, PlayableFeedback feedback) {
    final newAdaptation = _newAdaptation!;
    final scenario = _turnController!.scenario;
    final action = newAdaptation.actionFor(feedback.action, feedback.size);
    _turnController!.applyHeroAction(action);

    final result = AnswerEvaluator.evaluate(scenario, action);
    newEngineResults.add((scenario.objective, result));
    _recordKnowledge(scenario, result);

    answered++;
    phase = LabPhase.feedback;
  }

  /// Escribe en [knowledge] con la misma convención que
  /// `PokerTrainerEngine.submit()` usa para el sistema viejo (reducir el
  /// veredicto a un booleano y llamar `recordAttempt` por cada concepto
  /// declarado del ejercicio, no solo los que justificaron la opción
  /// elegida). `best`/`acceptable`/`dependent` cuentan como acierto:
  /// ninguna de las tres es una mala elección (`dependent` significa que
  /// no hay una única respuesta correcta, no que esté mal) — solo `poor`
  /// cuenta como error. `recordAttempt` ya es un no-op si el concepto no
  /// está enseñado; el filtro explícito acá es una defensa adicional, no
  /// la única.
  void _recordKnowledge(ExerciseScenario scenario, AnswerResult result) {
    final decisionCorrect = result.verdict != AnswerVerdict.poor;
    for (final conceptId in scenario.evaluableConcepts) {
      if (!knowledge.taughtConcepts.contains(conceptId)) continue;
      knowledge.recordAttempt(conceptId, decisionCorrect: decisionCorrect);
    }
  }

  /// Terminada la explicación de un ejercicio de mesa, arma otro
  /// ejercicio real (nueva semilla, nueva instancia de
  /// `ExerciseScenario`) hasta completar [sessionLength] (Fase
  /// 9.9/9.10: misma unidad pedagógica, sin inventar energía/fichas), y
  /// ahí enruta a [LabPhase.summary].
  @override
  void advancePlayable() {
    if (answered >= sessionLength) {
      phase = LabPhase.summary;
      notifyListeners();
      return;
    }
    loadNewEnginePreflopExercise();
  }
}
