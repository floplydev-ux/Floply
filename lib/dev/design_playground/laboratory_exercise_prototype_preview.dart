/// PROTOTIPO — Fase 1, PRUEBA 3 (Laboratorio / ejercicio interactivo).
///
/// Entorno de **Flutter Widget Preview** — mismo mecanismo que ya usa el
/// proyecto (ver `playable_table_exercise_preview.dart`, que sigue este
/// patrón exacto): `flutter widget-preview start` desde la raíz.
///
/// **Qué es real acá:** la situación (BTN con A♠J♠, todos foldearon), las
/// acciones, los tamaños, los ratings y los textos de feedback son
/// EXACTAMENTE los mismos que ya usa
/// `lib/screens/laboratory/widgets/playable_table_exercise_preview.dart`
/// (mismo `TableBuilder`, mismos tipos `PlayableTableExercise`/
/// `ActionChoice`/`BetSizeOption`) — no se inventó una situación nueva. La
/// mesa que se ve es **el `PokerTableView` real de producción, sin tocar
/// una línea**, embebido tal cual.
///
/// **Qué es nuevo acá:** el chrome alrededor de la mesa (header, franja de
/// fieltro acotada, botones de acción, chips de tamaño, panel de
/// feedback) usa los tokens de "Sala Verde" en vez de los widgets reales
/// `PlayableTableExerciseView`/`_ActionButtons`/`FeedbackPanel` (que están
/// escritos sobre `AppColors` y viven en `academy/widgets/`, compartidos
/// con Academia — tocarlos sería exactamente la "migración global"/
/// "reemplazo de componente existente" que esta fase prohíbe). Es una
/// implementación paralela y aislada para juzgar el lenguaje visual, no un
/// reemplazo.
///
/// Qué se prueba: si la temperatura fría (`steelBlue`) + una franja de
/// fieltro ACOTADA (no toda la pantalla, ver `FLOPLY_ANTI_GENERIC.md`
/// "Materialidad" 0.1) sostienen la sensación de tensión/decisión sin caer
/// en "mesa de casino de punta a punta", y si la mesa real convive con el
/// chrome nuevo sin que uno "contamine" al otro (criterio CONTROL del
/// prompt maestro).
///
/// **No se toca `PokerTableView`, `TableMaterial` ni
/// `PlayableTableExerciseView`.**
library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../engine/pedagogy/playable_exercise.dart';
import '../../engine/pedagogy/scripts/table_builder.dart';
import '../../engine/pedagogy/table_lesson.dart';
import '../../screens/academy/widgets/poker_table_view.dart';
import 'proto_components.dart';
import 'proto_tokens.dart';

// Ver la misma nota en `home_prototype_preview.dart`: un SizedBox de ancho
// fijo hacía inútil el barrido responsive por encima de 390dp. Fase 1.5,
// FLOPLY_VISUAL_STRESS_TEST.md §J.
Widget _stage(Widget child) {
  return ColoredBox(
    color: ProtoColor.background,
    child: Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth.clamp(0.0, 430.0)
              : 390.0;
          final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 844.0;
          return SizedBox(width: width, height: height, child: SafeArea(child: child));
        },
      ),
    ),
  );
}

/// Misma situación de ejemplo que
/// `playable_table_exercise_preview.dart:_openWithSizingSample` — copiada,
/// no reinventada, para que las dos pruebas (widget real vs. prototipo
/// visual) sean comparables lado a lado.
PlayableTableExercise _sampleExercise() {
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

(Color, IconData, String) _ratingLook(ExerciseRating rating) {
  return switch (rating) {
    ExerciseRating.best => (ProtoColor.success, Icons.check_rounded, 'MEJOR JUGADA'),
    ExerciseRating.acceptable => (ProtoColor.warning, Icons.remove_rounded, 'ACEPTABLE'),
    // errorBright, no error: el chip/callout usa esto como texto de
    // 12.5sp negrita — error puro mide 3.31:1 (falla texto normal/chico).
    // Fase 1.5, ver FLOPLY_VISUAL_STRESS_TEST.md §J.
    _ => (ProtoColor.errorBright, Icons.close_rounded, 'NO ES LO MEJOR'),
  };
}

class _LaboratoryExercisePrototype extends StatefulWidget {
  const _LaboratoryExercisePrototype({this.initialActionIndex, this.initialSizeIndex});

  /// Semillas para previews que arrancan a mitad de flujo — mismo patrón
  /// que `_PreviewController` en `playable_table_exercise_preview.dart`,
  /// que también deja abrir un preview ya con una acción/tamaño elegido
  /// en vez de forzar a tocar la pantalla primero.
  final int? initialActionIndex;
  final int? initialSizeIndex;

  @override
  State<_LaboratoryExercisePrototype> createState() =>
      _LaboratoryExercisePrototypeState();
}

class _LaboratoryExercisePrototypeState
    extends State<_LaboratoryExercisePrototype> {
  late final PlayableTableExercise _exercise = _sampleExercise();
  late int? _actionIndex = widget.initialActionIndex;
  late int? _sizeIndex = widget.initialSizeIndex;

  ActionChoice? get _chosenAction =>
      _actionIndex == null ? null : _exercise.actions[_actionIndex!];

  bool get _needsSizing => _chosenAction?.needsSizing ?? false;

  bool get _resolved =>
      _chosenAction != null && (!_needsSizing || _sizeIndex != null);

  ExerciseRating? get _resultRating {
    if (!_resolved) return null;
    if (_sizeIndex != null) return _chosenAction!.sizeOptions[_sizeIndex!].rating;
    return _chosenAction!.rating;
  }

  String? get _resultFeedback {
    if (!_resolved) return null;
    if (_sizeIndex != null) return _chosenAction!.sizeOptions[_sizeIndex!].feedback;
    return _chosenAction!.feedback;
  }

  TableSnapshot get _snapshot {
    if (!_resolved) return _exercise.situation;
    final sizeSnap =
        _sizeIndex != null ? _chosenAction!.sizeOptions[_sizeIndex!].afterDecision : null;
    return sizeSnap ?? _chosenAction!.afterDecision ?? _exercise.situation;
  }

  void _chooseAction(int index) {
    setState(() {
      _actionIndex = index;
      _sizeIndex = null;
    });
  }

  void _chooseSize(int index) => setState(() => _sizeIndex = index);

  void _reset() => setState(() {
        _actionIndex = null;
        _sizeIndex = null;
      });

  @override
  Widget build(BuildContext context) {
    const accent = ProtoColor.steelBlue; // temperatura fría de Laboratorio

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          ProtoSpace.lg, ProtoSpace.md, ProtoSpace.lg, ProtoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProtoSectionHeader(
            icon: Icons.bolt_outlined,
            title: 'Laboratorio',
            subtitle: 'Apertura preflop (RFI) · 1 de 1',
            // steelBlue puro mide 3.54:1 contra background — borderline
            // como ícono; Bright (7.1:1) da margen real. Fase 1.5, ver
            // FLOPLY_VISUAL_STRESS_TEST.md §J.
            accent: ProtoColor.steelBlueBright,
          ),
          const SizedBox(height: ProtoSpace.lg),
          // Franja de fieltro ACOTADA (altura fija), no fondo de pantalla
          // completa — regla dura de la Fase 0.5.
          Container(
            height: 300,
            padding: const EdgeInsets.all(ProtoSpace.sm),
            decoration: BoxDecoration(
              color: ProtoColor.surfaceFelt,
              borderRadius: BorderRadius.circular(ProtoRadius.panel),
            ),
            child: PokerTableView(snapshot: _snapshot),
          ),
          const SizedBox(height: ProtoSpace.lg),
          Text(_exercise.prompt, style: ProtoType.body),
          const SizedBox(height: ProtoSpace.lg),
          Expanded(
            child: SingleChildScrollView(
              child: _resolved ? _feedback(accent) : _decision(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decision(Color accent) {
    if (!_needsSizing || _actionIndex == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _exercise.actions.length; i++) ...[
            if (i > 0) const SizedBox(height: ProtoSpace.sm),
            _exercise.actions[i].action == PokerAction.fold
                ? ProtoButtonSecondary(
                    label: _exercise.actions[i].label,
                    onTap: () => _chooseAction(i),
                  )
                : ProtoButtonPrimary(
                    label: _exercise.actions[i].label,
                    accent: accent,
                    onTap: () => _chooseAction(i),
                  ),
          ],
        ],
      );
    }

    // Acción con sizing: elegir tamaño (chips numéricos seleccionables).
    final options = _chosenAction!.sizeOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('ELEGÍ EL TAMAÑO', style: ProtoType.label),
        const SizedBox(height: ProtoSpace.sm),
        Wrap(
          spacing: ProtoSpace.sm,
          runSpacing: ProtoSpace.sm,
          children: [
            for (var i = 0; i < options.length; i++)
              _SizeChip(
                label: options[i].label,
                selected: _sizeIndex == i,
                // steelBlue base falla como texto de chip seleccionado
                // (mide contra un fondo casi tan oscuro como
                // surfaceElevated); Bright es la variante correcta para
                // texto/borde. Fase 1.5, ver
                // FLOPLY_VISUAL_STRESS_TEST.md §J.
                accent: ProtoColor.steelBlueBright,
                onTap: () => _chooseSize(i),
              ),
          ],
        ),
      ],
    );
  }

  Widget _feedback(Color accent) {
    final rating = _resultRating!;
    final (color, icon, label) = _ratingLook(rating);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProtoChipStatus(label: label, icon: icon, color: color),
        const SizedBox(height: ProtoSpace.md),
        ProtoSurfacePanel(
          child: ProtoCalloutAccent(
            eyebrow: 'POR QUÉ',
            body: _resultFeedback!,
            color: color,
          ),
        ),
        const SizedBox(height: ProtoSpace.lg),
        ProtoButtonPrimary(
          label: 'SIGUIENTE EJERCICIO',
          accent: ProtoColor.brass,
          onTap: _reset,
        ),
      ],
    );
  }
}

/// Composición local (no es un componente nuevo del sistema): `chip.
/// numeric` + estado de selección. Se mantiene privado a este archivo
/// porque es específico de "elegir un tamaño de apuesta" — no se repite
/// en Home ni en Academia, así que no amerita subir a
/// `proto_components.dart` todavía (ver Fase 1, "COMPONENTES": no crear
/// sin necesidad real comprobada en más de una pantalla).
class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ProtoMotion.quick,
        curve: ProtoMotion.respondCurve,
        padding: const EdgeInsets.symmetric(horizontal: ProtoSpace.md, vertical: ProtoSpace.sm),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : ProtoColor.surfaceElevated,
          borderRadius: BorderRadius.circular(ProtoRadius.sharp),
          border: Border.all(color: selected ? accent : ProtoColor.borderSubtle),
        ),
        child: Text(
          label,
          style: ProtoType.numericInline.copyWith(
            color: selected ? accent : ProtoColor.textPrimary,
          ),
        ),
      ),
    );
  }
}

// Fase 1.5, Prueba 4: estados explícitos del ejercicio, no solo el punto
// de partida interactivo — mismo criterio que ya usa
// `playable_table_exercise_preview.dart` real (`previewChoosingAction`,
// `previewFeedbackBest`, `previewFeedbackPoor`) para poder inspeccionar
// cada paso sin tener que tocar la pantalla primero.

@Preview(name: 'Laboratorio · 1. antes de decidir (Sala Verde)')
Widget previewLaboratoryExercisePrototype() =>
    _stage(const _LaboratoryExercisePrototype());

@Preview(name: 'Laboratorio · 2. eligiendo tamaño, tras ABRIR (Sala Verde)')
Widget previewLaboratoryChoosingSize() =>
    _stage(const _LaboratoryExercisePrototype(initialActionIndex: 1));

@Preview(name: 'Laboratorio · 3. feedback MEJOR JUGADA — 2.5 BB (Sala Verde)')
Widget previewLaboratoryFeedbackBest() => _stage(
      const _LaboratoryExercisePrototype(initialActionIndex: 1, initialSizeIndex: 1),
    );

@Preview(name: 'Laboratorio · 4. feedback ACEPTABLE — 2 BB (Sala Verde)')
Widget previewLaboratoryFeedbackAcceptable() => _stage(
      const _LaboratoryExercisePrototype(initialActionIndex: 1, initialSizeIndex: 0),
    );

@Preview(name: 'Laboratorio · 5. feedback NO ES LO MEJOR — FOLD (Sala Verde)')
Widget previewLaboratoryFeedbackPoor() =>
    _stage(const _LaboratoryExercisePrototype(initialActionIndex: 0));
