/// Entorno de **Flutter Widget Preview** para el nuevo Laboratorio en
/// mesa ([PlayableTableExerciseView] reutilizado desde la Academia) —
/// pensado para ver/ajustar el layout sin depender de un celular
/// conectado ni de que el motor sortee un ejercicio de decisión.
///
/// **Cómo usarlo:** desde la raíz del proyecto,
/// ```
/// flutter widget-preview start
/// ```
/// abre una pestaña del navegador con hot reload. Cada preview de acá
/// abajo es un momento distinto del mismo flujo (elegir acción → elegir
/// tamaño → devolución óptima/pobre) — tocá los botones, es interactivo
/// de verdad, no una captura.
///
/// Este archivo **no se usa en producción** — ningún screen real lo
/// importa. No cambia estilo, motor, ni contenido real de Laboratorio;
/// el ejercicio de acá abajo es de muestra, igual de forma que el que
/// arma `table_exercise_adapter.dart` a partir de una situación real
/// (mismos tipos: sin paso de razonamiento, ver
/// `ActionChoice.reasoning`).
library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../engine/pedagogy/playable_exercise.dart';
import '../../../engine/pedagogy/playable_exercise_controller.dart';
import '../../../engine/pedagogy/scripts/table_builder.dart';
import '../../../engine/pedagogy/table_lesson.dart';
import '../../academy/widgets/playable_table_exercise_view.dart';

/// Controller mínimo para el taller: un solo ejercicio fijo, sin motor
/// ni progreso real detrás — [advancePlayable] solo reinicia la
/// decisión para poder probar de nuevo sin recargar la página.
class _PreviewController extends ChangeNotifier with PlayableExerciseController {
  _PreviewController(this._exercise);

  final PlayableTableExercise _exercise;

  @override
  PlayableTableExercise? get currentPlayable => _exercise;

  @override
  int get itemNumber => 1;

  @override
  int get itemTotal => 1;

  @override
  String conceptName(String conceptId) => 'Apertura preflop (RFI)';

  @override
  void advancePlayable() {
    playableActionIndex = null;
    playableSizeIndex = null;
    lastPlayableFeedback = null;
    notifyListeners();
  }
}

/// Caja + fondo — el mismo contenedor en el que vive el ejercicio en la
/// pantalla real de Laboratorio (ver `laboratory_screen.dart`: header +
/// la mesa a alto completo), en tamaño de teléfono en vertical.
Widget _stage(PlayableTableExercise exercise) =>
    _stageController(_PreviewController(exercise));

/// Igual que [_stage], pero recibiendo el controller ya armado — para
/// previews que arrancan a mitad de flujo (tamaño ya elegido, devolución
/// ya calculada) sin tener que tocar la pantalla primero.
Widget _stageController(_PreviewController controller) {
  return DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF13172E), Color(0xFF060812)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Center(
      child: SizedBox(
        width: 390,
        height: 760,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) =>
                PlayableTableExerciseView(controller: controller),
          ),
        ),
      ),
    ),
  );
}

/// La misma situación de ejemplo (BTN con AJs, todos foldearon) en sus
/// distintos momentos — RAISE con sizing, como el que arma el adapter
/// real para un ejercicio `chooseSizing`/`fullDecision`.
PlayableTableExercise _openWithSizingSample() {
  final situation = TableSnapshot(
    seats: TableBuilder.seats(
      labels: TableBuilder.btnHero,
      folded: const {3, 2, 1},
      cards: const {
        0: ['As', 'Js']
      },
      toAct: 0,
    ),
    potBb: 1.5,
    buttonSlot: 0,
  );

  TableSnapshot after({double betBb = 0, bool folds = false}) => TableSnapshot(
        seats: TableBuilder.seats(
          labels: TableBuilder.btnHero,
          folded: folds ? const {3, 2, 1, 0} : const {3, 2, 1},
          bets: betBb > 0 ? {0: betBb} : const {},
          cards: const {
            0: ['As', 'Js']
          },
        ),
        potBb: betBb > 0 ? 1.5 + betBb : 1.5,
        buttonSlot: 0,
      );

  return PlayableTableExercise(
    situation: situation,
    concept: 'open_raise',
    prompt: 'Llega limpio a vos en el BOTÓN con A♠J♠.',
    actions: [
      ActionChoice(
        action: PokerAction.fold,
        label: 'FOLD',
        rating: ExerciseRating.poor,
        feedback: 'AJs es una mano clara de apertura en el botón — el rango '
            'más ancho de la mesa. Foldear acá regala valor.',
        afterDecision: after(folds: true),
      ),
      ActionChoice(
        action: PokerAction.raise,
        label: 'ABRIR',
        rating: ExerciseRating.best,
        feedback: 'Sí: AJs entra cómodo en el rango de apertura del botón.',
        afterDecision: after(betBb: 2.5),
        sizeOptions: [
          BetSizeOption(
            label: '2 BB',
            rating: ExerciseRating.acceptable,
            feedback: 'Funciona, pero es un poco chico para el estándar de '
                'esta mesa — deja mucha gente barata detrás tuyo.',
            afterDecision: after(betBb: 2.0),
          ),
          BetSizeOption(
            label: '2.5 BB',
            rating: ExerciseRating.best,
            feedback: 'El tamaño estándar para abrir desde el botón: '
                'suficiente para desalentar defensas baratas, sin regalar '
                'demasiado si te vuelven a subir.',
            afterDecision: after(betBb: 2.5),
          ),
          BetSizeOption(
            label: '4 BB',
            rating: ExerciseRating.acceptable,
            feedback: 'Grande de más para un open sin nadie que haya '
                'mostrado fuerza todavía — funciona, pero achica el rango '
                'con el que te conviene abrir así.',
            afterDecision: after(betBb: 4.0),
          ),
        ],
      ),
    ],
    explanation: const [
      ExerciseExplainStep(
        text: 'En el botón solo quedan las ciegas por detrás — el rango de '
            'apertura más ancho de toda la mesa.',
        anchor: TableAnchor.heroCards,
      ),
    ],
  );
}

@Preview(name: 'Laboratorio · eligiendo acción')
Widget previewChoosingAction() => _stage(_openWithSizingSample());

@Preview(name: 'Laboratorio · eligiendo tamaño (tras ABRIR)')
Widget previewChoosingSize() {
  final controller = _PreviewController(_openWithSizingSample())
    ..choosePlayableAction(1); // ABRIR
  return _stageController(controller);
}

@Preview(name: 'Laboratorio · devolución óptima (2.5 BB)')
Widget previewFeedbackBest() {
  final controller = _PreviewController(_openWithSizingSample())
    ..choosePlayableAction(1) // ABRIR
    ..choosePlayableSize(1); // 2.5 BB — best
  return _stageController(controller);
}

@Preview(name: 'Laboratorio · devolución pobre (FOLD)')
Widget previewFeedbackPoor() {
  // FOLD no tiene sizing ni razonamiento: se resuelve solo apenas se
  // elige — el camino nuevo que no tiene la Academia.
  final controller = _PreviewController(_openWithSizingSample())
    ..choosePlayableAction(0);
  return _stageController(controller);
}
