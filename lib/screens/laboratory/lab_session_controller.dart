import 'package:flutter/foundation.dart';

import '../../engine/concepts/user_knowledge.dart';
import '../../engine/evaluation/evaluation_result.dart';
import '../../engine/evaluation/user_answer.dart';
import '../../engine/exercises/exercise.dart';
import '../../engine/pedagogy/recovery_session.dart';
import '../../engine/poker_trainer_engine.dart';

/// Fase actual de una sesión de práctica del Laboratorio.
enum LabPhase { idle, question, feedback, summary }

/// Coordina una sesión de práctica contra el [PokerTrainerEngine].
///
/// No sabe nada de widgets: la pantalla solo escucha [notifyListeners] y
/// pinta el estado. Así el flujo se puede testear sin UI.
class LabSessionController extends ChangeNotifier {
  LabSessionController({PokerTrainerEngine? engine, this.sessionLength = 8})
      : engine = engine ?? PokerTrainerEngine() {
    knowledge = this.engine.newUser();
  }

  final PokerTrainerEngine engine;
  final int sessionLength;

  late UserKnowledge knowledge;

  LabPhase phase = LabPhase.idle;
  Exercise? current;
  EvaluationResult? lastResult;

  final Set<String> selectedOptionIds = {};
  final Set<String> selectedReasoningIds = {};
  bool showAdvanced = false;

  int answered = 0;
  final List<EvaluationResult> results = [];

  double get sessionDecisionScore => results.isEmpty
      ? 0
      : results.map((r) => r.decisionScore).reduce((a, b) => a + b) /
          results.length;

  Iterable<EvaluationResult> get reasoningResults =>
      results.where((r) => r.reasoningScore != null);

  double? get sessionReasoningScore {
    final scored = reasoningResults.toList();
    if (scored.isEmpty) return null;
    return scored.map((r) => r.reasoningScore!).reduce((a, b) => a + b) /
        scored.length;
  }

  RecoverySession? get recovery => engine.suggestedRecovery(knowledge);

  bool get canConfirm => selectedOptionIds.isNotEmpty;

  void start() {
    answered = 0;
    results.clear();
    _loadNext();
  }

  void _loadNext() {
    selectedOptionIds.clear();
    selectedReasoningIds.clear();
    showAdvanced = false;
    lastResult = null;
    current = engine.nextExercise(knowledge);
    phase = LabPhase.question;
    notifyListeners();
  }

  void toggleOption(String optionId, {required bool single}) {
    if (phase != LabPhase.question) return;
    if (single) {
      selectedOptionIds
        ..clear()
        ..add(optionId);
    } else if (!selectedOptionIds.add(optionId)) {
      selectedOptionIds.remove(optionId);
    }
    notifyListeners();
  }

  void toggleReasoning(String conceptId) {
    if (phase != LabPhase.question) return;
    if (!selectedReasoningIds.add(conceptId)) {
      selectedReasoningIds.remove(conceptId);
    }
    notifyListeners();
  }

  void confirm() {
    final exercise = current;
    if (exercise == null || !canConfirm) return;

    final answer = UserAnswer(
      exerciseId: exercise.id,
      selectedOptionId: selectedOptionIds.first,
      selectedOptionIds: selectedOptionIds.toList(),
      reasoningConceptIds: selectedReasoningIds.toList(),
    );

    lastResult = engine.submit(exercise, answer, knowledge);
    results.add(lastResult!);
    answered++;
    phase = LabPhase.feedback;
    notifyListeners();
  }

  void next() {
    if (answered >= sessionLength) {
      phase = LabPhase.summary;
      notifyListeners();
      return;
    }
    _loadNext();
  }

  void toggleAdvanced() {
    showAdvanced = !showAdvanced;
    notifyListeners();
  }
}
