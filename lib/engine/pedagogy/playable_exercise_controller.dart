import 'package:flutter/foundation.dart';

import 'playable_exercise.dart';

/// La devolución de un ejercicio jugable ya resuelto: guarda las
/// evaluaciones de acción/tamaño y razonamiento por separado para que la
/// UI pueda mostrarlas de forma independiente, en vez de reducir todo a
/// un único correcto/incorrecto. [reasoning] es `null` cuando el
/// ejercicio no tiene ese paso (ver [ActionChoice.reasoning]).
class PlayableFeedback {
  const PlayableFeedback({
    required this.action,
    required this.size,
    required this.reasoning,
    required this.combined,
  });

  final ActionChoice action;
  final BetSizeOption? size;
  final ReasoningOption? reasoning;

  /// El peor de los ratings de acción/tamaño/razonamiento.
  final ExerciseRating combined;
}

/// El estado y la lógica de "elegir acción → elegir tamaño (si aplica) →
/// elegir razonamiento (si aplica) → devolución" de un ejercicio jugable
/// sobre la mesa — extraído de `AcademyController` para que cualquier
/// host (Academia, Laboratorio) lo reutilice sin duplicar la lógica de
/// calificación. Cada host solo aporta CUÁL es el ejercicio actual, su
/// posición dentro de la sesión, y qué hacer una vez resuelto.
mixin PlayableExerciseController on ChangeNotifier {
  /// El ejercicio jugable actual, o `null` si no corresponde mostrar uno
  /// ahora mismo.
  PlayableTableExercise? get currentPlayable;

  /// Posición dentro de la sesión/lección actual (1-based) y el total —
  /// para la barra de progreso de [PlayableTableExerciseView].
  int get itemNumber;
  int get itemTotal;

  /// Nombre para mostrar de un concepto, para el texto de devolución.
  String conceptName(String conceptId);

  /// Índice de la acción elegida; `null` mientras el alumno no decidió.
  int? playableActionIndex;

  /// Índice del tamaño elegido (si la acción elegida lo requiere).
  int? playableSizeIndex;

  PlayableFeedback? lastPlayableFeedback;

  ActionChoice? get _chosenPlayableAction {
    final ex = currentPlayable;
    final i = playableActionIndex;
    if (ex == null || i == null) return null;
    return ex.actions[i];
  }

  /// `true` mientras la acción elegida necesita tamaño y todavía no se
  /// eligió — la UI debe mostrar el paso de sizing antes que el de
  /// razonamiento.
  bool get needsPlayableSizing =>
      _chosenPlayableAction?.needsSizing == true && playableSizeIndex == null;

  /// Elige la acción (FOLD/CHECK/BET/RAISE/…). No confirma nada todavía:
  /// si la acción necesita tamaño, el siguiente paso es elegirlo; si no
  /// necesita tamaño ni tiene razonamiento, resuelve directo.
  void choosePlayableAction(int index) {
    final ex = currentPlayable;
    if (ex == null || playableActionIndex != null) return;
    if (index < 0 || index >= ex.actions.length) return;
    playableActionIndex = index;
    _autoResolveIfReady();
    notifyListeners();
  }

  void choosePlayableSize(int index) {
    final action = _chosenPlayableAction;
    if (action == null || playableSizeIndex != null) return;
    if (index < 0 || index >= action.sizeOptions.length) return;
    playableSizeIndex = index;
    _autoResolveIfReady();
    notifyListeners();
  }

  /// Si la acción elegida ya no necesita tamaño y no tiene paso de
  /// razonamiento (ver [ActionChoice.reasoning]), resuelve el ejercicio
  /// sin esperar más input — el caso de Laboratorio, que no pregunta
  /// "¿por qué?".
  void _autoResolveIfReady() {
    final action = _chosenPlayableAction;
    if (action == null || needsPlayableSizing) return;
    if (action.reasoning.isNotEmpty) return;
    _resolve(action, reasoning: null);
  }

  /// Registra el razonamiento elegido y calcula la devolución — solo
  /// aplica a ejercicios que sí tienen paso de razonamiento.
  void confirmPlayableReasoning(int reasoningIndex) {
    final action = _chosenPlayableAction;
    if (action == null || lastPlayableFeedback != null) return;
    if (needsPlayableSizing) return;
    if (reasoningIndex < 0 || reasoningIndex >= action.reasoning.length) {
      return;
    }
    _resolve(action, reasoning: action.reasoning[reasoningIndex]);
  }

  void _resolve(ActionChoice action, {required ReasoningOption? reasoning}) {
    final ex = currentPlayable;
    if (ex == null || lastPlayableFeedback != null) return;

    final size =
        action.needsSizing ? action.sizeOptions[playableSizeIndex!] : null;
    final decisionRating =
        _worstRating([action.rating, if (size != null) size.rating]);
    final combined = reasoning == null
        ? decisionRating
        : _worstRating([decisionRating, reasoning.rating]);

    final feedback = PlayableFeedback(
      action: action,
      size: size,
      reasoning: reasoning,
      combined: combined,
    );
    lastPlayableFeedback = feedback;
    onPlayableResolved(ex, feedback);
    notifyListeners();
  }

  /// Efectos propios del host una vez resuelto el ejercicio (puntaje,
  /// registro de concepto, envío de la respuesta real al motor…). No-op
  /// por defecto.
  void onPlayableResolved(PlayableTableExercise exercise,
      PlayableFeedback feedback) {}

  /// Terminada la explicación del ejercicio jugable, pasa al siguiente —
  /// cada host decide qué significa "siguiente".
  void advancePlayable();

  static ExerciseRating _worstRating(List<ExerciseRating> ratings) {
    const severity = {
      ExerciseRating.poor: 0,
      ExerciseRating.acceptable: 1,
      ExerciseRating.best: 2,
    };
    return ratings.reduce((a, b) => severity[a]! <= severity[b]! ? a : b);
  }
}
