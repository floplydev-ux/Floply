import 'package:flutter/foundation.dart';

import '../../engine/academy/academy_engine.dart';
import '../../engine/academy/academy_progress.dart';
import '../../engine/academy/academy_store.dart';
import '../../engine/concepts/user_knowledge.dart';
import '../../engine/evaluation/evaluation_result.dart';
import '../../engine/evaluation/user_answer.dart';
import '../../engine/exercises/exercise.dart';
import '../../engine/pedagogy/academy_closing_examples.dart';
import '../../engine/pedagogy/academy_cumulative_reviews.dart';
import '../../engine/pedagogy/academy_exercise_scripts.dart';
import '../../engine/pedagogy/academy_players.dart';
import '../../engine/pedagogy/academy_playable_scripts.dart';
import '../../engine/pedagogy/academy_mentor_lessons.dart';
import '../../engine/pedagogy/academy_table_scripts.dart';
import '../../engine/pedagogy/academy_visual_theories.dart';
import '../../engine/pedagogy/curriculum.dart';
import '../../engine/pedagogy/lesson_content.dart';
import '../../engine/pedagogy/mentor_lesson.dart';
import '../../engine/pedagogy/playable_exercise.dart';
import '../../engine/pedagogy/playable_exercise_controller.dart';
import '../../engine/pedagogy/recovery_session.dart';
import '../../engine/pedagogy/table_exercise.dart';
import '../../engine/pedagogy/table_lesson.dart';
import '../../engine/pedagogy/theory.dart';
import '../../engine/pedagogy/visual_theory.dart';
import '../../engine/poker_trainer_engine.dart';
import '../../l10n/app_strings.dart';
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
        playable = null,
        options = exercise!.options.map((o) => o.label).toList();
  AcademyItem.check(this.check)
      : exercise = null,
        interactive = null,
        playable = null,
        options = check!.options;
  AcademyItem.interactive(this.interactive)
      : exercise = null,
        check = null,
        playable = null,
        options = interactive!.choices.map((c) => c.label).toList();
  AcademyItem.playable(this.playable)
      : exercise = null,
        check = null,
        interactive = null,
        options = playable!.actions.map((a) => a.label).toList();

  final Exercise? exercise;
  final ComprehensionCheck? check;
  final InteractiveTableExercise? interactive;
  final PlayableTableExercise? playable;
  final List<String> options;

  bool get isEngine => exercise != null;
  bool get isInteractive => interactive != null;
  bool get isPlayable => playable != null;
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
///
/// El estado/lógica de "elegir acción → tamaño → razonamiento →
/// devolución" de los ejercicios jugables vive en
/// [PlayableExerciseController] (compartido con Laboratorio) — acá solo
/// se implementan los 4 miembros que dependen de una lección
/// (`currentPlayable`/`itemNumber`/`itemTotal`/`conceptName`) y qué hacer
/// una vez resuelto un ejercicio (`onPlayableResolved`).
class AcademyController extends ChangeNotifier with PlayableExerciseController {
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

  /// Texto de la burbuja del paso de mesa activo, ya resuelto (nombres).
  /// Funciona tanto en [isInteractiveTheory] (guion legacy, antes de la
  /// teoría) como en [isClosingExample] (ejemplo de cierre, después).
  String? get currentBubbleText {
    final step = isClosingExample ? currentClosingExampleStep : currentTableStep;
    if (step == null) return null;
    return resolveText(step.bubble, castTable(step.table));
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

  // --- repaso acumulativo (después de aprobar el checkpoint de N3/6/9/13) ---
  bool _inCumulativeReview = false;
  bool get isCumulativeReview => _inCumulativeReview;

  /// El repaso pendiente más antiguo: el checkpoint que lo habilita ya está
  /// aprobado, pero el repaso todavía no se hizo. `null` si no hay ninguno
  /// (incluye el caso de haberlos hecho todos). Sirve tanto para ofrecerlo
  /// apenas se aprueba el checkpoint correspondiente (`LessonResultView`)
  /// como para recordarlo después desde el mapa (`LevelMap`).
  String? get pendingReviewId {
    for (final entry in AcademyCumulativeReviews.reviewByCheckpointLesson.entries) {
      if (progress.isCompleted(entry.key) && !progress.isCompleted(entry.value)) {
        return entry.value;
      }
    }
    return null;
  }

  String reviewTitle(String reviewId) =>
      AcademyCumulativeReviews.titles[reviewId] ?? reviewId;

  /// Arranca un repaso acumulativo: reutiliza el mismo recorrido
  /// ítem-por-ítem que cualquier lesson (mismo `_items`, misma fase
  /// `exercise` → `feedback` → `result`, misma vista
  /// `InteractiveTableExerciseView`), solo que los ítems no vienen de
  /// `AcademyExerciseScripts.forLesson(activeLessonId)` sino de la
  /// selección curada de [AcademyCumulativeReviews]. Al terminar,
  /// `_finishLesson()` llama a `academy.submitLesson('review.N', ...)`
  /// igual que con cualquier lesson: como `'review.N'` no es un subnivel
  /// real del currículo, `submitLesson` no lo trata como evaluación con
  /// umbral (no bloquea el progreso si sale bajo el puntaje) pero sí guarda
  /// el puntaje real en su propio `LessonProgress`, bajo su propio id
  /// sintético — no pisa el progreso de ningún subnivel real.
  void startCumulativeReview(String reviewId) {
    final set = AcademyCumulativeReviews.forId(reviewId);
    if (set == null || set.isEmpty) return;

    activeLessonId = reviewId;
    _recovering = false;
    _inCumulativeReview = true;
    // `_formative` es un campo de `_buildItems()` (Grupo 4, lessons de
    // teoría) que este método nunca llama — sin este reset, un repaso
    // disparado después de haber abierto un lesson de teoría en el medio
    // (banner del mapa, no el botón inmediato tras el checkpoint) hereda
    // `_formative == true` de esa lección y `_finishLesson()` fuerza el
    // puntaje del repaso a 1.0 sin importar cómo respondió — justo lo
    // que el repaso no debe hacer (su puntaje real tiene que quedar
    // guardado, ver el doc-comment de esta clase más arriba).
    _formative = false;
    _resetRun();
    // Mismo motivo que en _buildItems(): orden aleatorio, no el de autoría.
    final shuffled = List<InteractiveTableExercise>.from(set.exercises)
      ..shuffle();
    _items = shuffled.map(AcademyItem.interactive).toList();
    phase = AcademyPhase.exercise;
    notifyListeners();
  }

  // --- lección interactiva sobre la mesa (fase teoría) ---
  int tableStep = 0;

  /// Guion interactivo del lesson activo, si tiene.
  TableLessonScript? get tableScript => activeLessonId == null
      ? null
      : AcademyTableScripts.forLesson(activeLessonId!);

  /// `true` si la teoría de este lesson se enseña con la mesa interactiva.
  /// Deja de serlo cuando el guion terminó y se pasó a las fichas de teoría
  /// redactada (ver [isWrittenTheory]).
  bool get isInteractiveTheory =>
      phase == AcademyPhase.theory &&
      tableScript != null &&
      !_inWrittenTheory &&
      !_inMentorLesson;

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
    if (s == null || _inWrittenTheory || _inMentorLesson) return;
    if (tableStep < s.length - 1) {
      tableStep++;
      notifyListeners();
    } else {
      _enterWrittenTheoryOrExercises();
    }
  }

  void prevTableStep() {
    if (tableStep > 0) {
      tableStep--;
      notifyListeners();
    }
  }

  // --- teoría redactada (PASO 4): fichas de teoría, una por pantalla ---

  /// `true` mientras se recorren las fichas de teoría redactada del subnivel.
  /// Sub-fase dentro de [AcademyPhase.theory], después del guion de mesa (si
  /// lo hay) y antes de los ejercicios.
  bool _inWrittenTheory = false;
  int writtenTheoryStep = 0;

  /// Teorías del subnivel activo que ya tienen contenido redactado, en orden.
  List<Theory> get writtenTheories {
    final id = activeLessonId;
    if (id == null) return const [];
    final sub = academy.lessonById(id)?.sublevel;
    if (sub == null) return const [];
    return [
      for (final t in sub.theories)
        if (t.tieneContenido) t
    ];
  }

  bool get hasWrittenTheory => writtenTheories.isNotEmpty;

  /// `true` si la UI debe mostrar ahora las fichas de teoría redactada.
  bool get isWrittenTheory =>
      phase == AcademyPhase.theory && _inWrittenTheory && hasWrittenTheory;

  int get writtenTheoryCount => writtenTheories.length;

  Theory? get currentWrittenTheory {
    final list = writtenTheories;
    if (writtenTheoryStep < 0 || writtenTheoryStep >= list.length) return null;
    return list[writtenTheoryStep];
  }

  bool get isFirstWrittenTheory => writtenTheoryStep <= 0;
  bool get isLastWrittenTheory =>
      writtenTheoryStep >= writtenTheories.length - 1;

  /// Entra en la sub-fase de teoría redactada (o, si no hay, arranca los
  /// ejercicios directamente).
  void _enterWrittenTheoryOrExercises() {
    if (hasWrittenTheory) {
      writtenTheoryStep = 0;
      _beginWrittenTheoryStep();
    } else {
      startExercises();
    }
  }

  /// Arranca el paso actual de teoría redactada (`writtenTheoryStep`): si
  /// esa teoría puntual tiene una clase de mentor (Fase 3), esa REEMPLAZA
  /// por completo la ficha escrita ([isMentorLesson], nunca las dos); si
  /// no, pero tiene una experiencia visual piloto, primero esa
  /// ([isVisualTheory]); si no, la ficha escrita de siempre.
  void _beginWrittenTheoryStep() {
    final mentor = currentMentorLesson;
    _inMentorLesson = mentor != null;
    if (_inMentorLesson) {
      mentorBeatIndex = 0;
      _mentorCheckAnswers.clear();
      _inVisualTheory = false;
      _inWrittenTheory = false;
      notifyListeners();
      return;
    }
    _inVisualTheory = hasVisualTheory;
    _inWrittenTheory = !_inVisualTheory;
    visualStep = 0;
    notifyListeners();
  }

  /// Avanza una ficha de teoría redactada; en la última pasa al ejemplo de
  /// cierre del subnivel (si tiene) o directo a los ejercicios.
  void nextWrittenTheory() {
    if (writtenTheoryStep < writtenTheories.length - 1) {
      writtenTheoryStep++;
      _beginWrittenTheoryStep();
    } else {
      _inWrittenTheory = false;
      if (hasClosingExample) {
        _inClosingExample = true;
        closingExampleStep = 0;
        notifyListeners();
      } else {
        startExercises();
      }
    }
  }

  void prevWrittenTheory() {
    if (writtenTheoryStep > 0) {
      writtenTheoryStep--;
      notifyListeners();
    }
  }

  // --- piloto visual: teoría → experiencia visual → teoría escrita ---
  //
  // Sub-fase de [AcademyPhase.theory], antes de la ficha escrita de la
  // MISMA teoría (ver `_beginWrittenTheoryStep`). Solo se activa para las
  // teorías registradas en [AcademyVisualTheories]; para el resto de las
  // 326, `hasVisualTheory` es `false` y nada cambia respecto de hoy.

  bool _inVisualTheory = false;
  int visualStep = 0;

  /// Lección visual de la teoría que muestra ahora la fase teoría (la misma
  /// que [currentWrittenTheory]), si está registrada como piloto.
  VisualTheoryLesson? get currentVisualLesson {
    final t = currentWrittenTheory;
    return t == null ? null : AcademyVisualTheories.forTheory(t.id);
  }

  bool get hasVisualTheory => currentVisualLesson != null;

  /// `true` si la UI debe mostrar ahora la experiencia visual piloto.
  bool get isVisualTheory =>
      phase == AcademyPhase.theory && _inVisualTheory && hasVisualTheory;

  int get visualStepCount => currentVisualLesson?.length ?? 0;

  VisualTheoryStep? get currentVisualStep {
    final lesson = currentVisualLesson;
    if (lesson == null || visualStep < 0 || visualStep >= lesson.length) {
      return null;
    }
    return lesson.steps[visualStep];
  }

  bool get isFirstVisualStep => visualStep <= 0;
  bool get isLastVisualStep =>
      currentVisualLesson != null &&
      visualStep >= currentVisualLesson!.length - 1;

  /// Avanza un paso de la experiencia visual; en el último pasa a la ficha
  /// escrita de esa misma teoría.
  void nextVisualStep() {
    final lesson = currentVisualLesson;
    if (lesson == null) return;
    if (visualStep < lesson.length - 1) {
      visualStep++;
      notifyListeners();
    } else {
      _inVisualTheory = false;
      _inWrittenTheory = true;
      notifyListeners();
    }
  }

  void prevVisualStep() {
    if (visualStep > 0) {
      visualStep--;
      notifyListeners();
    }
  }

  // --- clase de mentor (Fase 3): reemplaza la ficha escrita ---
  //
  // Sub-fase de [AcademyPhase.theory], decidida en `_beginWrittenTheoryStep`
  // junto con el piloto visual. Solo se activa para teorías registradas en
  // [AcademyMentorLessons]; para el resto de las 326, `hasMentorLesson` es
  // `false` y el camino de hoy (piloto visual / ficha escrita) no cambia en
  // nada. A diferencia del piloto visual (que se muestra ANTES de la ficha
  // escrita de la misma teoría), la clase de mentor la REEMPLAZA: al
  // terminar sus turnos se pasa directo a la siguiente teoría del subnivel
  // (o a los ejercicios), sin mostrar la ficha estática de esta teoría.

  bool _inMentorLesson = false;
  int mentorBeatIndex = 0;
  final Map<int, int> _mentorCheckAnswers = {};

  /// Clase de mentor de la teoría que muestra ahora la fase teoría (la
  /// misma que [currentWrittenTheory]), si está registrada.
  MentorLesson? get currentMentorLesson {
    final t = currentWrittenTheory;
    return t == null ? null : AcademyMentorLessons.forTheory(t.id);
  }

  bool get hasMentorLesson => currentMentorLesson != null;

  /// `true` si la UI debe mostrar ahora la clase de mentor.
  bool get isMentorLesson =>
      phase == AcademyPhase.theory && _inMentorLesson && hasMentorLesson;

  int get mentorBeatCount => currentMentorLesson?.length ?? 0;

  MentorBeat? get currentMentorBeat {
    final lesson = currentMentorLesson;
    if (lesson == null ||
        mentorBeatIndex < 0 ||
        mentorBeatIndex >= lesson.length) {
      return null;
    }
    return lesson.beats[mentorBeatIndex];
  }

  bool get isFirstMentorBeat => mentorBeatIndex <= 0;
  bool get isLastMentorBeat =>
      currentMentorLesson != null &&
      mentorBeatIndex >= currentMentorLesson!.length - 1;

  /// Opción elegida en el turno de comprobación actual, o `null` si
  /// todavía no se respondió. Se guarda por índice de turno: volver ATRÁS
  /// a una pregunta ya respondida la muestra tal como quedó, en vez de
  /// resetearla.
  int? get mentorCheckAnswer => _mentorCheckAnswers[mentorBeatIndex];

  /// `true` si se puede avanzar el turno actual: siempre para un turno de
  /// habla ([MentorSayBeat]); solo tras responder para uno de comprobación
  /// ([MentorCheckBeat]) — nunca se puede "saltear" una pregunta sin
  /// contestarla, aunque no cuente para el progreso.
  bool get canAdvanceMentorBeat => switch (currentMentorBeat) {
        null => false,
        MentorSayBeat _ => true,
        MentorCheckBeat _ => mentorCheckAnswer != null,
      };

  /// Registra la respuesta del turno de comprobación actual.
  ///
  /// Exclusivamente pedagógico: a diferencia de [answerInteractive] (el
  /// ejercicio real), esto NUNCA llama `knowledge.recordAttempt`, nunca
  /// puntúa, nunca cuenta para mastery/XP/progreso. La distinción pedida es
  /// MentorCheck = "¿entendiste lo que acabo de enseñarte?", Exercise =
  /// "ahora aplicalo en una situación de póker".
  void answerMentorCheck(int optionIndex) {
    final beat = currentMentorBeat;
    if (beat is! MentorCheckBeat) return;
    if (optionIndex < 0 || optionIndex >= beat.check.options.length) return;
    if (_mentorCheckAnswers.containsKey(mentorBeatIndex)) return;
    _mentorCheckAnswers[mentorBeatIndex] = optionIndex;
    notifyListeners();
  }

  /// Texto del botón de avance del turno actual: "CONTINUAR" salvo en el
  /// último turno, donde refleja si además cierra el subnivel (mismo
  /// criterio que ya usaba la ficha escrita).
  String get mentorContinueLabel {
    if (!isLastMentorBeat) return AppStrings.academyContinue;
    return isLastWrittenTheory
        ? AppStrings.academyStartPractice
        : AppStrings.academyContinue;
  }

  /// Avanza un turno de la clase de mentor; en el último, pasa a la
  /// siguiente teoría del subnivel (o a los ejercicios) exactamente como si
  /// la ficha escrita de esta teoría ya se hubiera mostrado.
  void nextMentorBeat() {
    if (!canAdvanceMentorBeat) return;
    final lesson = currentMentorLesson;
    if (lesson == null) return;
    if (mentorBeatIndex < lesson.length - 1) {
      mentorBeatIndex++;
      notifyListeners();
    } else {
      _inMentorLesson = false;
      _mentorCheckAnswers.clear();
      nextWrittenTheory();
    }
  }

  void prevMentorBeat() {
    if (mentorBeatIndex > 0) {
      mentorBeatIndex--;
      notifyListeners();
    }
  }

  // --- ejemplo de cierre (piloto de 3 bloques, Fase 3.1) ---
  //
  // Sub-fase de [AcademyPhase.theory], DESPUÉS de que terminan las fichas de
  // teoría redactada del subnivel (ver `nextWrittenTheory`) y ANTES de los
  // ejercicios. A diferencia del guion de mesa legado ([tableScript], que
  // se muestra ANTES de las teorías), este se registra por subnivel en
  // [AcademyClosingExamples] y demuestra las teorías que el alumno ya leyó,
  // no las que está por leer. Reutiliza el mismo `TableLessonScript` que el
  // guion legado — misma mesa, mismo criterio de un paso a la vez — así que
  // la UI reutiliza el mismo widget ([InteractiveTableLesson]).

  bool _inClosingExample = false;
  int closingExampleStep = 0;

  TableLessonScript? get closingExampleScript => activeLessonId == null
      ? null
      : AcademyClosingExamples.forLesson(activeLessonId!);

  bool get hasClosingExample => closingExampleScript != null;

  /// `true` si la UI debe mostrar ahora el ejemplo de cierre.
  bool get isClosingExample =>
      phase == AcademyPhase.theory && _inClosingExample && hasClosingExample;

  int get closingExampleStepCount => closingExampleScript?.length ?? 0;

  TableStep? get currentClosingExampleStep {
    final s = closingExampleScript;
    if (s == null || closingExampleStep < 0 || closingExampleStep >= s.length) {
      return null;
    }
    return s.steps[closingExampleStep];
  }

  bool get isFirstClosingExampleStep => closingExampleStep <= 0;
  bool get isLastClosingExampleStep =>
      closingExampleScript != null &&
      closingExampleStep >= closingExampleScript!.length - 1;

  /// Texto del botón de avance del paso actual: "CONTINUAR" salvo en el
  /// último paso, donde refleja si además arranca la práctica (mismo
  /// criterio que [mentorContinueLabel]).
  String get closingExampleButtonLabel {
    if (!isLastClosingExampleStep) return AppStrings.academyContinue;
    return AppStrings.academyStartPractice;
  }

  /// Avanza un paso del ejemplo de cierre; en el último, pasa a los
  /// ejercicios.
  void nextClosingExampleStep() {
    final s = closingExampleScript;
    if (s == null) return;
    if (closingExampleStep < s.length - 1) {
      closingExampleStep++;
      notifyListeners();
    } else {
      _inClosingExample = false;
      startExercises();
    }
  }

  void prevClosingExampleStep() {
    if (closingExampleStep > 0) {
      closingExampleStep--;
      notifyListeners();
    }
  }

  /// Avanza la fase teoría cualquiera sea su sub-fase (guion de mesa →
  /// clase de mentor / experiencia visual piloto → fichas de teoría
  /// redactada → ejemplo de cierre → ejercicios). Pensado para recorridos
  /// automáticos; la UI usa los métodos específicos.
  void advanceTheory() {
    if (isInteractiveTheory) {
      nextTableStep();
    } else if (isClosingExample) {
      nextClosingExampleStep();
    } else if (isMentorLesson) {
      // Un recorrido automático no puede "pensar" una respuesta: si el
      // turno actual es una comprobación sin responder, toma la mejor
      // opción (mismo criterio que un alumno que entendió la clase).
      if (!canAdvanceMentorBeat) {
        final beat = currentMentorBeat;
        if (beat is MentorCheckBeat) {
          final bestIdx = beat.check.options
              .indexWhere((o) => o.rating == ExerciseRating.best);
          answerMentorCheck(bestIdx >= 0 ? bestIdx : 0);
        }
      }
      nextMentorBeat();
    } else if (isVisualTheory) {
      nextVisualStep();
    } else if (isWrittenTheory) {
      nextWrittenTheory();
    } else {
      startExercises();
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
  @override
  int get itemNumber => _itemIndex + 1;
  @override
  int get itemTotal => _items.length;

  // --- ejercicio interactivo sobre la mesa ---

  /// Set de ejercicios interactivos del lesson activo, si tiene.
  InteractiveExerciseSet? get exerciseSet => activeLessonId == null
      ? null
      : AcademyExerciseScripts.forLesson(activeLessonId!);

  InteractiveTableExercise? get currentInteractive => currentItem?.interactive;

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

  // --- ejercicio jugable (mesa + acción real) ---
  // El estado/lógica de elegir acción/tamaño/razonamiento vive en
  // PlayableExerciseController (mixin) — acá solo lo que es propio de
  // una lección: cuál es el ejercicio actual y qué hacer al resolverlo.

  @override
  PlayableTableExercise? get currentPlayable => currentItem?.playable;

  bool get isPlayableExercise =>
      phase == AcademyPhase.exercise && (currentItem?.isPlayable ?? false);

  /// Registra el resultado de un ejercicio jugable ya resuelto:
  ///
  ///  - Para el puntaje del lesson (aprobar/no aprobar) usa el PEOR de los
  ///    ratings ([PlayableFeedback.combined]): una buena acción con una
  ///    mala razón no cuenta como ítem resuelto del todo.
  ///  - Para el registro de concepto, aprovecha algo que
  ///    [UserConceptMastery] ya tenía pero que [answerInteractive] nunca
  ///    usaba: `recordAttempt` acepta `decisionCorrect` Y `reasoningCorrect`
  ///    por separado, y los acumula en contadores propios
  ///    (`decisionAccuracy`/`reasoningAccuracy`).
  @override
  void onPlayableResolved(
      PlayableTableExercise exercise, PlayableFeedback feedback) {
    final decisionRating = _worstRating([
      feedback.action.rating,
      if (feedback.size != null) feedback.size!.rating,
    ]);

    final score = _ratingScore(feedback.combined);
    _scoreSum += score;
    final ok = feedback.combined != ExerciseRating.poor;
    if (ok) _correctCount++;
    if (!ok && exercise.concept != null) _missedConcepts.add(exercise.concept!);
    if (exercise.concept != null) {
      knowledge.recordAttempt(
        exercise.concept!,
        decisionCorrect: decisionRating == ExerciseRating.best,
        reasoningCorrect: feedback.reasoning == null
            ? null
            : feedback.reasoning!.rating == ExerciseRating.best,
      );
    }
  }

  /// Terminada la explicación del ejercicio jugable, pasa al siguiente.
  @override
  void advancePlayable() {
    if (currentPlayable == null) return;
    nextItem();
  }

  static ExerciseRating _worstRating(List<ExerciseRating> ratings) {
    const severity = {
      ExerciseRating.poor: 0,
      ExerciseRating.acceptable: 1,
      ExerciseRating.best: 2,
    };
    return ratings.reduce((a, b) => severity[a]! <= severity[b]! ? a : b);
  }

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

  AcademyProgressSnapshot get snapshot => academy.snapshot(knowledge, progress);

  /// La lección a la que apunta [currentLessonId] (o `null` si la Academia
  /// ya está completa). Para la Home: evita que cada consumidor externo
  /// repita el recorrido de [levels] que hace [lessonView] por dentro.
  AcademyLessonView? get currentLessonView {
    final id = currentLessonId;
    return id == null ? null : lessonView(id);
  }

  LessonContent? contentFor(String lessonId) => academy.contentFor(lessonId);

  @override
  String conceptName(String id) => academy.conceptName(id);

  // ----------------------------------------------------------------
  // Recorrido de un lesson
  // ----------------------------------------------------------------

  void openLesson(String lessonId) {
    final view = lessonView(lessonId);
    if (view == null || view.state == LessonState.locked) return;

    activeLessonId = lessonId;
    _recovering = false;
    _inCumulativeReview = false;
    tableStep = 0;
    _inWrittenTheory = false;
    writtenTheoryStep = 0;
    _inVisualTheory = false;
    visualStep = 0;
    _inMentorLesson = false;
    mentorBeatIndex = 0;
    _mentorCheckAnswers.clear();
    _inClosingExample = false;
    closingExampleStep = 0;
    academy.openLesson(lessonId, knowledge, progress);
    _resetRun();

    final content = academy.contentFor(lessonId);
    final hasText = content != null && content.hasTheory;
    final hasGuion = AcademyTableScripts.has(lessonId);
    // Entra en la fase teoría si tiene teoría en texto, guion de mesa, o
    // teoría redactada (PASO 4).
    if (hasText || hasGuion || hasWrittenTheory) {
      phase = AcademyPhase.theory;
      // Sin guion ni texto heredado: se arranca directo en las fichas (o,
      // si la primera teoría es un piloto visual, en esa experiencia).
      if (!hasText && !hasGuion && hasWrittenTheory) {
        _beginWrittenTheoryStep();
      }
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
    _inWrittenTheory = false;
    _inVisualTheory = false;
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
    playableActionIndex = null;
    playableSizeIndex = null;
    lastPlayableFeedback = null;
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
    _inCumulativeReview = false;
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
    _inCumulativeReview = false;
    _inWrittenTheory = false;
    writtenTheoryStep = 0;
    _inVisualTheory = false;
    visualStep = 0;
    _inMentorLesson = false;
    mentorBeatIndex = 0;
    _mentorCheckAnswers.clear();
    _inClosingExample = false;
    closingExampleStep = 0;
    _items = [];
    playableActionIndex = null;
    playableSizeIndex = null;
    lastPlayableFeedback = null;
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
    playableActionIndex = null;
    playableSizeIndex = null;
    lastPlayableFeedback = null;
    lastFeedback = null;
    lastOutcome = null;
  }

  void _buildItems() {
    final id = activeLessonId;
    if (id == null) return;
    final content = academy.contentFor(id);
    final lesson = academy.lessonById(id);
    final isTheoryLesson = lesson?.kind == LessonKind.theory;

    // 0) Ejercicios jugables (mesa + acción real) — pilotos migrados.
    // Si el lesson tiene set acá, tapa su set equivalente (si lo tenía)
    // en AcademyExerciseScripts; ese contenido viejo no se borra, solo
    // deja de usarse en runtime (ver AcademyPlayableScripts).
    final playable = AcademyPlayableScripts.forLesson(id);
    if (playable != null && playable.exercises.isNotEmpty) {
      _items = playable.exercises.map(AcademyItem.playable).toList();
      _formative = false;
      return;
    }

    // 1) Ejercicios interactivos sobre la mesa (si el lesson tiene set).
    final set = AcademyExerciseScripts.forLesson(id);
    if (set != null && set.exercises.isNotEmpty) {
      // Orden aleatorio, no el orden de autoría: un lesson (sobre todo una
      // evaluación de módulo) se puede reintentar, y no debería mostrar
      // siempre exactamente la misma secuencia de preguntas. La respuesta
      // correcta de cada una no cambia — esto solo reordena CUÁL pregunta
      // sale primero.
      final shuffled = List<InteractiveTableExercise>.from(set.exercises)
        ..shuffle();
      _items = shuffled.map(AcademyItem.interactive).toList();
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

  /// La vista de una lección puntual (nivel, estado, progreso), buscando
  /// entre [levels]. Público porque la Home lo necesita a través de
  /// [currentLessonView] sin duplicar este recorrido.
  AcademyLessonView? lessonView(String lessonId) {
    final level = _levelViewFor(lessonId);
    if (level == null) return null;
    for (final l in level.lessons) {
      if (l.lesson.id == lessonId) return l;
    }
    return null;
  }
}
