import '../../concepts/concept_ids.dart';
import '../../poker/poker_action.dart';
import '../../poker/street.dart';
import '../../strategy/hand_strength.dart';
import '../../strategy/opening_ranges.dart';
import '../../strategy/strategy.dart';
import '../exercise.dart';
import '../exercise_template.dart';
import '../generation_context.dart';
import 'hand_picker.dart';
import 'situation_factory.dart';

/// "Desde {posición}, ¿qué mano preferís para abrir?"
///
/// Compara dos clases de mano: refuerza el ranking de manos aplicado a la
/// decisión de apertura.
class CompareHandsTemplate extends ExerciseTemplate {
  const CompareHandsTemplate();

  @override
  String get id => 'compare_hands_for_open';

  @override
  ExerciseType get type => ExerciseType.compareHands;

  @override
  Street get street => Street.preflop;

  @override
  Set<String> get evaluatedConcepts =>
      const {ConceptIds.openingRange, ConceptIds.handRanking};

  @override
  Set<String> get requiredConcepts =>
      const {ConceptIds.openingRange, ConceptIds.handRanking};

  @override
  List<int> get supportedDifficulties => const [1, 2, 3];

  @override
  Exercise generate(GenerationContext ctx) {
    final deck = ctx.deck;
    final position = deck.pick(
      SituationFactory.openerPoolForDifficulty(ctx.difficulty),
    );
    final range = OpeningRanges.forPosition(position);

    // Una mano dentro de rango, otra fuera (en dificultad baja) o ambas
    // dentro con distinta fuerza (dificultad alta).
    final bothInRange = ctx.difficulty >= 3 && deck.nextBool();
    final handA = HandPicker.forBias(deck, position, HandBias.clearlyInRange);
    final handB = bothInRange
        ? HandPicker.forBias(deck, position, HandBias.borderline)
        : HandPicker.forBias(deck, position, HandBias.clearlyOutOfRange);

    if (handA.notation == handB.notation) {
      throw TemplateGenerationException('Manos iguales sorteadas');
    }

    final freqA = range.frequencyOf(handA.notation);
    final freqB = range.frequencyOf(handB.notation);

    String better;
    if ((freqA >= 0.5) != (freqB >= 0.5)) {
      better = freqA >= 0.5 ? handA.notation : handB.notation;
    } else {
      better = HandStrength.chenScore(handA.notation) >=
              HandStrength.chenScore(handB.notation)
          ? handA.notation
          : handB.notation;
    }

    final optionA = AnswerOption(
      id: 'a',
      label: handA.pretty,
      value: handA.notation,
    );
    final optionB = AnswerOption(
      id: 'b',
      label: handB.pretty,
      value: handB.notation,
    );

    final strategy = Strategy([
      StrategyOption(
        action: PokerAction.raiseTo(OpeningRanges.sizingFor(position)),
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: const [
          ConceptIds.openingRange,
          ConceptIds.handRanking,
        ],
        rationaleKey: 'hand.compare.stronger',
      ),
    ]);

    return Exercise(
      id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
      templateId: id,
      type: type,
      difficulty: ctx.difficulty,
      prompt: 'Estás en ${position.abbreviation} y todos foldean hasta vos. '
          'Entre estas dos manos, ¿cuál preferís para abrir?',
      options: deck.nextBool() ? [optionA, optionB] : [optionB, optionA],
      strategy: strategy,
      correctValue: better,
      evaluatedConcepts: ctx.keepTaught(evaluatedConcepts),
      requiredConcepts: requiredConcepts.toList(),
      reasoningConcepts: ctx.keepTaught(const [
        ConceptIds.openingRange,
        ConceptIds.handRanking,
      ]),
      explanation: ExerciseExplanation(
        basic: better == handA.notation
            ? '${handA.notation} es mejor mano para abrir que ${handB.notation} '
                'desde ${position.abbreviation}.'
            : '${handB.notation} es mejor mano para abrir que ${handA.notation} '
                'desde ${position.abbreviation}.',
        advanced: 'Al comparar manos para abrir mirá cartas altas, si son del '
            'mismo palo y si conectan: eso define su equity y su potencial de '
            'seguir postflop.',
        advancedConcepts: const [ConceptIds.equity],
        conceptSummary: 'Comparar manos para abrir',
      ),
      meta: {
        'position': position.abbreviation,
        'handA': handA.notation,
        'handB': handB.notation,
      },
    );
  }
}
