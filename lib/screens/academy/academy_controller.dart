import 'package:flutter/foundation.dart';

import '../../engine/academy/academy_engine.dart';
import '../../engine/academy/academy_progress.dart';
import '../../engine/academy/academy_store.dart';
import '../../engine/concepts/user_knowledge.dart';
import '../../engine/evaluation/evaluation_result.dart';
import '../../engine/evaluation/user_answer.dart';
import '../../engine/exercises/exercise.dart';
import '../../engine/pedagogy/academy_exercise_scripts.dart';
import '../../engine/pedagogy/academy_players.dart';
import '../../engine/pedagogy/academy_table_scripts.dart';
import '../../engine/pedagogy/curriculum.dart';
import '../../engine/pedagogy/lesson_content.dart';
import '../../engine/pedagogy/recovery_session.dart';
import '../../engine/pedagogy/table_exercise.dart';
import '../../engine/pedagogy/table_lesson.dart';
import '../../engine/poker_trainer_engine.dart';
import '../../models/app_user.dart';
import '../../persistence/academy_store_provider.dart';

/// Fase dentro del recorrido de un lesson.
enum AcademyPhase {
  /// Mapa de niveles (sin lesson abierto).
  map,

  /// Leyendo la teoría del lesson.
  theory,

  /// Resolviendo un ejercicio.
  exercise,

  /// Viendo el feedback de un ejercicio.
  feedback,

  /// Resultado final del lesson (aprobado / a recuperar).
  result,
}

/// Un ejercicio del lesson: del motor, una pregunta autoral, o un
/// ejercicio interactivo sobre la mesa.
class AcademyItem {
  AcademyItem.engine(this.exercise)
      : check = null,
        interactive = null,
        options = exercise!.options.map((o) => o.label).toList();
  AcademyItem.check(this.check)
      : exercise = null,
        interactive = null,
        options = check!.options;
  AcademyItem.interactive(this.interactive)
      : exercise = null,
        check = null,
        options = interactive!.choices.map((c) => c.label).toList();

  final Exercise? exercise;
  final ComprehensionCheck? check;
  final InteractiveTableExercise? interactive;
  final List<String> options;

  bool get isEngine => exercise != null;
  bool get isInteractive => interactive != null;
}

/// El feedback de un ítem ya respondido.
class AcademyItemFeedback {
  AcademyItemFeedback({
    required this.correct,
    required this.score,
    required this.text,
    this.evaluation,
    this.exercise,
  });

  final bool correct;
  final double score;
  final String text;
  final EvaluationResult? evaluation;
  final Exercise? exercise;
}

/// Coordina el recorrido de la Academia: carga/guarda el progreso, abre
/// lessons, pide ejercicios al [PokerTrainerEngine] y decide aprobados.
class AcademyController extends ChangeNotifier {
  AcademyController({
    PokerTrainerEngine? engine,
    AcademyStore? store,
    String? userName,
  })  : engine = engine ?? PokerTrainerEngine(),
        store = store ?? defaultAcademyStore(),
        userName = userName ?? AppUser.current.firstName {
    knowledge = this.engine.newAcademyUser();
    progress = AcademyProgress();
  }

  final PokerTrainerEngine engine;
  final AcademyStore store;

  /// Nombre que se muestra en el asiento del usuario en la mesa. Cambiarlo
  /// (o cambiar [AppUser.current]) actualiza todas las mesas sin tocar los
  /// guiones.
  String userName;

  /// Completa nombres y avatares de una mesa del guion activo: el usuario
  /// usa [userName]; los rivales, personajes de [AcademyPlayers] elegidos
  /// de forma determinista por lección.
  TableSnapshot castTable(TableSnapshot raw) =>
      raw.withCast(userName, AcademyPlayers.seedFor(activeLessonId ?? ''));

  /// Resuelve `{me}` / `{BTN}` / … en un texto pedagógico contra la mesa
  /// ya casteada.
  String resolveText(String raw, TableSnapshot casted) =>
      resolveTableText(raw, casted);

  /// Texto de la burbuja del paso de teoría actual, ya resuelto (nombres).
  String? get currentBubbleText {
    final s = currentTableStep;
    if (s == null) return null;
    return resolveText(s.bubble, castTable(s.table));
  }

  /// Resuelve un texto del ejercicio interactivo actual contra su mesa.
  String resolveInteractive(String raw) {
    final ex = currentInteractive;
    if (ex == null) return raw;
    return resolveText(raw, castTable(ex.situation));
  }

  String? get interactiveQuestionText => currentInteractive == null
      ? null
      : resolveInteractive(currentInteractive!.question);

  AcademyEngine get academy => engine.academy;

  late UserKnowledge knowledge;
  late AcademyProgress progress;

  bool loading = true;
  AcademyPhase phase = AcademyPhase.map;

  // --- estado del lesson activo ---
  String? activeLessonId;
  bool _recovering = false;
  bool get isRecovering => _recovering;

  // --- lección interactiva sobre la mesa (fase teoría) ---
  int tableStep = 0;

  /// Guion interactivo del lesson activo, si tiene.
  TableLessonScript? get tableScript => activeLessonId == null
      ? null
      : AcademyTableScripts.forLesson(activeLessonId!);

  /// `true` si la teoría de este lesson se enseña con la mesa interactiva.
  bool get isInteractiveTheory =>
      phase == AcademyPhase.theory && tableScript != null;

  int get tableStepCount => tableScript?.length ?? 0;

  TableStep? get currentTableStep {
    final s = tableScript;
    if (s == null || tableStep < 0 || tableStep >= s.length) return null;
    return s.steps[tableStep];
  }

  bool get isFirstTableStep => tableStep <= 0;
  bool get isLastTableStep =>
      tableScript != null && tableStep >= tableScript!.length - 1;

  /// Avanza un paso de la lección interactiva; en el último paso pasa a
  /// los ejercicios (mismo flujo que la teoría normal).
  void nextTableStep() {
    final s = tableScript;
    if (s == null) return;
    if (tableStep < s.length - 1) {
      tableStep++;
      notifyListeners();
    } else {
      startExercises();
    }
  }

  void prevTableStep() {
    if (tableStep > 0) {
      tableStep--;
      notifyListeners();
    }
  }

  List<AcademyItem> _items = [];
  int _itemIndex = 0;
  int _correctCount = 0;
  double _scoreSum = 0;
  bool _formative = false;
  final Set<String> _missedConcepts = {};

  AcademyItem? get currentItem =>
      _itemIndex < _items.length ? _items[_itemIndex] : null;
  int get itemNumber => _itemIndex + 1;
  int get itemTotal => _items.length;

  // --- ejercicio interactivo sobre la mesa ---

  /// Set de ejercicios interactivos del lesson activo, si tiene.
  InteractiveExerciseSet? get exerciseSet => activeLessonId == null
      ? null
      : AcademyExerciseScripts.forLesson(activeLessonId!);

  InteractiveTableExercise? get currentInteractive =>
      currentItem?.interactive;

  bool get isInteractiveExercise =>
      phase == AcademyPhase.exercise && (currentItem?.isInteractive ?? false);

  /// Índice de la opción elegida en el ejercicio interactivo actual;
  /// `null` mientras el usuario no respondió.
  int? interactiveChoice;

  /// Registra la decisión del usuario en el ejercicio interactivo actual
  /// (bloquea las demás opciones y calcula el feedback). No avanza de
  /// paso: la explicación la maneja la UI.
  void answerInteractive(int choiceIndex) {
    final ex = currentInteractive;
    if (ex == null || interactiveChoice != null) return;
    if (choiceIndex < 0 || choiceIndex >= ex.choices.length) return;

    interactiveChoice = choiceIndex;
    final choice = ex.choices[choiceIndex];
    final score = _ratingScore(choice.rating);
    _scoreSum += score;
    final ok = choice.rating != ExerciseRating.poor;
    if (ok) _correctCount++;
    if (!ok && ex.concept != null) _missedConcepts.add(ex.concept!);
    if (ex.concept != null) {
      // no-op si el concepto no está enseñado → regla fundamental intacta.
      knowledge.recordAttempt(
        ex.concept!,
        decisionCorrect: choice.rating == ExerciseRating.best,
      );
    }

    lastFeedback = AcademyItemFeedback(
      correct: ok,
      score: score,
      text: choice.feedback,
    );
    notifyListeners();
  }

  /// Terminada la explicación del ejercicio interactivo, pasa al siguiente
  /// (o al resultado del lesson).
  void advanceInteractive() {
    if (currentInteractive == null) return;
    nextItem();
  }

  static double _ratingScore(ExerciseRating r) => switch (r) {
        ExerciseRating.best => 1.0,
        ExerciseRating.acceptable => 0.72,
        ExerciseRating.poor => 0.15,
      };

  AcademyItemFeedback? lastFeedback;
  LessonOutcome? lastOutcome;

  final Set<int> _selectedOptionIdx = {};
  Set<int> get selectedOptionIdx => _selectedOptionIdx;
  bool get canConfirm => _selectedOptionIdx.isNotEmpty;

  // ----------------------------------------------------------------
  // Carga / persistencia
  // ----------------------------------------------------------------

  Future<void> load() async {
    try {
      final data = await store.load(engine.concepts);
      if (data != null) {
        knowledge = data.knowledge;
        progress = data.progress;
      }
    } catch (_) {
      // Sin persistencia disponible: se arranca de cero, no se rompe la app.
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await store
          .save(AcademySaveData(knowledge: knowledge, progress: progress));
    } catch (_) {
      // El progreso se guarda "best effort": si el disco falla, la sesión
      // sigue funcionando en memoria.
    }
  }

  /// Borra todo el progreso (para pruebas / "empezar de cero").
  Future<void> resetProgress() async {
    await store.clear();
    knowledge = engine.newAcademyUser();
    progress = AcademyProgress();
    exitLesson();
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // Vistas
  // ----------------------------------------------------------------

  List<AcademyLevelView> get levels => academy.overview(progress);

  String? get currentLessonId => academy.currentLessonId(progress);

  AcademyProgressSnapshot get snapshot =>
      academy.snapshot(knowledge, progress);

  LessonContent? contentFor(String lessonId) => academy.contentFor(lessonId);

  String conceptName(String id) => academy.conceptName(id);

  // ----------------------------------------------------------------
  // Recorrido de un lesson
  // ----------------------------------------------------------------

  void openLesson(String lessonId) {
    final view = _lessonView(lessonId);
    if (view == null || view.state == LessonState.locked) return;

    activeLessonId = lessonId;
    _recovering = false;
    tableStep = 0;
    academy.openLesson(lessonId, knowledge, progress);
    _resetRun();

    final content = academy.contentFor(lessonId);
    // Entra en la fase teoría si tiene teoría en texto O una lección
    // interactiva sobre la mesa (aunque no tenga bloques de texto).
    if ((content != null && content.hasTheory) ||
        AcademyTableScripts.has(lessonId)) {
      phase = AcademyPhase.theory;
    } else {
      _buildItems();
      phase = _items.isEmpty ? AcademyPhase.result : AcademyPhase.exercise;
      if (_items.isEmpty) _finishLesson();
    }
    _persist();
    notifyListeners();
  }

  /// Pasar de la teoría a los ejercicios.
  void startExercises() {
    _buildItems();
    if (_items.isEmpty) {
      _finishLesson();
    } else {
      phase = AcademyPhase.exercise;
    }
    notifyListeners();
  }

  void toggleOption(int index) {
    if (phase != AcademyPhase.exercise) return;
    _selectedOptionIdx
      ..clear()
      ..add(index);
    notifyListeners();
  }

  void confirm() {
    final item = currentItem;
    if (item == null || !canConfirm) return;
    final choice = _selectedOptionIdx.first;

    if (item.isEngine) {
      _gradeEngineItem(item.exercise!, choice);
    } else {
      _gradeCheckItem(item.check!, choice);
    }
    phase = AcademyPhase.feedback;
    notifyListeners();
  }

  void nextItem() {
    _itemIndex++;
    _selectedOptionIdx.clear();
    interactiveChoice = null;
    lastFeedback = null;
    if (_itemIndex >= _items.length) {
      _finishLesson();
    } else {
      phase = AcademyPhase.exercise;
    }
    notifyListeners();
  }

  /// Empezar la práctica de recuperación sugerida.
  void startRecovery() {
    final RecoverySession? session = engine.suggestedRecovery(knowledge);
    if (session == null) return;
    _recovering = true;
    _resetRun();
    _items = List.generate(
      session.exerciseCount,
      (_) => AcademyItem.engine(
        engine.nextExercise(
          knowledge,
          concept: session.conceptId,
          difficulty: session.difficulty,
        ),
      ),
    );
    phase = _items.isEmpty ? AcademyPhase.result : AcademyPhase.exercise;
    notifyListeners();
  }

  /// Reintentar el lesson (típicamente una evaluación no aprobada).
  void retryLesson() {
    final id = activeLessonId;
    if (id == null) return;
    openLesson(id);
  }

  void exitLesson() {
    activeLessonId = null;
    _recovering = false;
    _items = [];
    lastFeedback = null;
    lastOutcome = null;
    phase = AcademyPhase.map;
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // Internos
  // ----------------------------------------------------------------

  void _resetRun() {
    _items = [];
    _itemIndex = 0;
    _correctCount = 0;
    _scoreSum = 0;
    _missedConcepts.clear();
    _selectedOptionIdx.clear();
    interactiveChoice = null;
    lastFeedback = null;
    lastOutcome = null;
  }

  void _buildItems() {
    final id = activeLessonId;
    if (id == null) return;
    final content = academy.contentFor(id);
    final lesson = academy.lessonById(id);
    final isTheoryLesson = lesson?.kind == LessonKind.theory;

    // 1) Ejercicios interactivos sobre la mesa (si el lesson tiene set).
    final set = AcademyExerciseScripts.forLesson(id);
    if (set != null && set.exercises.isNotEmpty) {
      _items = set.exercises.map(AcademyItem.interactive).toList();
      _formative = false;
      return;
    }

    if (content?.practice != null) {
      final spec = content!.practice!;
      _items = List.generate(
        spec.exerciseCount,
        (_) => AcademyItem.engine(
          engine.nextExercise(
            knowledge,
            concept: spec.targetConcept,
            difficulty: spec.difficulty,
          ),
        ),
      );
    } else if (content != null && content.checks.isNotEmpty) {
      // En lessons de teoría, la mini pregunta es formativa: se muestra
      // pero no cuenta para aprobar ni toca el mastery.
      _items = content.checks.map(AcademyItem.check).toList();
      _formative = isTheoryLesson;
    } else {
      _items = [];
    }
  }

  void _gradeEngineItem(Exercise exercise, int choiceIdx) {
    final option = exercise.options[choiceIdx];
    final answer = UserAnswer(
      exerciseId: exercise.id,
      selectedOptionId: option.id,
    );
    final result = engine.submit(exercise, answer, knowledge);
    final correct = result.decisionScore >= 0.6;
    _scoreSum += result.decisionScore.clamp(0.0, 1.0);
    if (correct) _correctCount++;
    if (!correct) _missedConcepts.addAll(result.evaluatedConcepts);

    lastFeedback = AcademyItemFeedback(
      correct: correct,
      score: result.decisionScore,
      text: result.feedback,
      evaluation: result,
      exercise: exercise,
    );
  }

  void _gradeCheckItem(ComprehensionCheck check, int choiceIdx) {
    final correct = choiceIdx == check.correctIndex;
    _scoreSum += correct ? 1.0 : 0.0;
    if (correct) _correctCount++;
    if (!correct && check.concept != null) {
      _missedConcepts.add(check.concept!);
    }

    if (!_formative && check.concept != null) {
      // recordAttempt es no-op si el concepto no está enseñado: la regla
      // fundamental se respeta siempre.
      knowledge.recordAttempt(check.concept!, decisionCorrect: correct);
    }

    lastFeedback = AcademyItemFeedback(
      correct: correct,
      score: correct ? 1.0 : 0.0,
      text: correct
          ? '✅ Correcto. ${check.explanation}'
          : '❌ La respuesta era "${check.correctOption}". ${check.explanation}',
    );
  }

  void _finishLesson() {
    final id = activeLessonId;
    if (id == null) return;

    final total = _items.isEmpty ? 1 : _items.length;
    final score = _items.isEmpty ? 1.0 : (_scoreSum / total).clamp(0.0, 1.0);

    if (_recovering) {
      // La recuperación no "aprueba" nada: solo practica. Al terminar se
      // vuelve al resultado del lesson para poder reintentar.
      _recovering = false;
      lastOutcome = academy.submitLesson(
        id,
        LessonRunResult(
          score: 0,
          total: total,
          correct: _correctCount,
          weakConceptIds: _missedConcepts.toList(),
        ),
        knowledge,
        progress,
      );
      // No marca completado (score 0 en una evaluación); en un lesson
      // normal ya estaba completado igual.
      phase = AcademyPhase.result;
      _persist();
      notifyListeners();
      return;
    }

    final run = LessonRunResult(
      score: _formative ? 1.0 : score,
      total: total,
      correct: _correctCount,
      weakConceptIds: _missedConcepts.toList(),
    );
    lastOutcome = academy.submitLesson(id, run, knowledge, progress);
    phase = AcademyPhase.result;
    _persist();
    notifyListeners();
  }

  AcademyLevelView? _levelViewFor(String lessonId) {
    for (final level in levels) {
      for (final l in level.lessons) {
        if (l.lesson.id == lessonId) return level;
      }
    }
    return null;
  }

  AcademyLessonView? _lessonView(String lessonId) {
    final level = _levelViewFor(lessonId);
    if (level == null) return null;
    for (final l in level.lessons) {
      if (l.lesson.id == lessonId) return l;
    }
    return null;
  }
}
