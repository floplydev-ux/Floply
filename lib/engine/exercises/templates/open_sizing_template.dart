import '../../concepts/concept_ids.dart';
import '../../poker/poker_action.dart';
import '../../poker/street.dart';
import '../../strategy/opening_ranges.dart';
import '../exercise.dart';
import '../exercise_template.dart';
import '../generation_context.dart';
import 'hand_picker.dart';
import 'situation_factory.dart';

/// "Vas a abrir desde {posición}. ¿Con qué tamaño?"
///
/// Asume que abrir es correcto (mano dentro de rango) y evalúa el sizing.
class OpenSizingTemplate extends ExerciseTemplate {
  const OpenSizingTemplate();

  @override
  String get id => 'open_sizing';

  @override
  ExerciseType get type => ExerciseType.chooseSizing;

  @override
  Street get street => Street.preflop;

  @override
  Set<String> get evaluatedConcepts => const {ConceptIds.openSizing};

  @override
  Set<String> get requiredConcepts =>
      const {ConceptIds.openSizing, ConceptIds.openRaise};

  @override
  List<int> get supportedDifficulties => const [1, 2, 3];

  @override
  Exercise generate(GenerationContext ctx) {
    final deck = ctx.deck;
    final position = deck.pick(
      SituationFactory.openerPoolForDifficulty(ctx.difficulty),
    );
    final hand = HandPicker.forBias(deck, position, HandBias.clearlyInRange);
    final stack = SituationFactory.stackForDifficulty(deck, ctx.difficulty);
    final ideal = OpeningRanges.sizingFor(position);

    // Siempre incluye el ideal; el resto son alternativas más chicas /
    // más grandes / claramente malas.
    final sizes = <double>{ideal, 2.0, 2.5, 3.0, 4.5}.toList()..sort();

    final situation = SituationFactory.firstIn(
      heroPosition: position,
      heroCards: hand,
      effectiveStackBb: stack,
      availableRaiseSizes: sizes,
    );

    final strategy = ctx.strategyEngine.openSizingStrategy(situation, sizes);

    final options = sizes
        .map((s) => AnswerOption(
              id: 's${_fmt(s).replaceAll(".", "_")}',
              label: s < 2.0 + 0.01 && s == 2.0
                  ? 'SUBIR a 2bb (mínimo)'
                  : 'SUBIR a ${_fmt(s)}bb',
              action: PokerAction.raiseTo(s),
              sizingBb: s,
            ))
        .toList();

    return Exercise(
      id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
      templateId: id,
      type: type,
      difficulty: ctx.difficulty,
      prompt: 'Abrís desde ${position.abbreviation} con ${hand.pretty} '
          '(${_fmt(stack)}bb efectivos). ¿Qué tamaño usás?',
      options: options,
      strategy: strategy,
      evaluatedConcepts: ctx.keepTaught(evaluatedConcepts),
      requiredConcepts: requiredConcepts.toList(),
      reasoningConcepts: ctx.keepTaught(const [ConceptIds.openSizing]),
      situation: situation,
      explanation: ExerciseExplanation(
        basic: 'Desde ${position.abbreviation} el tamaño estándar de apertura '
            'es ${_fmt(ideal)}bb. Subir mucho más infla el bote sin motivo; '
            'subir el mínimo le da un precio demasiado bueno a las ciegas.',
        advanced: 'Un tamaño equilibrado hace que tu rango de apertura sea '
            'difícil de explotar: si variás el sizing según la mano, el rival '
            'puede leer tu rango.',
        advancedConcepts: const [ConceptIds.gto],
        conceptSummary: 'Tamaño de apertura estándar',
      ),
      meta: {'position': position.abbreviation, 'ideal': ideal},
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
