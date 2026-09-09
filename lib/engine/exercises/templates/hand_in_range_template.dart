import '../../concepts/concept_ids.dart';
import '../../poker/poker_action.dart';
import '../../poker/street.dart';
import '../../strategy/opening_ranges.dart';
import '../../strategy/strategy.dart';
import '../exercise.dart';
import '../exercise_template.dart';
import '../generation_context.dart';
import 'hand_picker.dart';
import 'situation_factory.dart';

/// "¿{mano} está en el rango de apertura de {posición}? SÍ / NO"
///
/// Aísla el reconocimiento del rango, sin la carga de decidir una acción.
class HandInOpeningRangeTemplate extends ExerciseTemplate {
  const HandInOpeningRangeTemplate();

  @override
  String get id => 'hand_in_opening_range';

  @override
  ExerciseType get type => ExerciseType.handInRange;

  @override
  Street get street => Street.preflop;

  @override
  Set<String> get evaluatedConcepts => const {ConceptIds.openingRange};

  @override
  Set<String> get requiredConcepts =>
      const {ConceptIds.openingRange, ConceptIds.positionAdvantage};

  @override
  List<int> get supportedDifficulties => const [1, 2, 3];

  @override
  Exercise generate(GenerationContext ctx) {
    final deck = ctx.deck;
    final position = deck.pick(
      SituationFactory.openerPoolForDifficulty(ctx.difficulty),
    );
    final bias = HandPicker.biasForDifficulty(deck, ctx.difficulty);
    final hand = HandPicker.forBias(deck, position, bias);
    final range = OpeningRanges.forPosition(position);
    final inRange = range.frequencyOf(hand.notation) >= 0.5;

    const yes = AnswerOption(id: 'yes', label: 'SÍ, la abro', value: true);
    const no = AnswerOption(id: 'no', label: 'NO, no la abro', value: false);
    final options = deck.pick(const [true, false]) ? [yes, no] : [no, yes];

    final strategy = Strategy([
      StrategyOption(
        action: inRange ? PokerAction.raiseTo(2.5) : PokerAction.fold,
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: const [ConceptIds.openingRange],
        rationaleKey:
            inRange ? 'open.raise.in_range' : 'open.fold.out_of_range',
      ),
    ]);

    return Exercise(
      id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
      templateId: id,
      type: type,
      difficulty: ctx.difficulty,
      prompt: '¿${hand.pretty} (${hand.notation}) forma parte del rango con el '
          'que abrirías desde ${position.abbreviation} '
          '(${position.fullName}) si todos foldean hasta vos?',
      options: options,
      strategy: strategy,
      correctValue: inRange,
      evaluatedConcepts: ctx.keepTaught(evaluatedConcepts),
      requiredConcepts: requiredConcepts.toList(),
      reasoningConcepts: ctx.keepTaught(const [
        ConceptIds.openingRange,
        ConceptIds.positionAdvantage,
      ]),
      explanation: ExerciseExplanation(
        basic: inRange
            ? '${hand.notation} sí está en el rango de apertura de '
                '${position.abbreviation}.'
            : '${hand.notation} no llega: queda por fuera del rango de '
                'apertura de ${position.abbreviation}.',
        advanced: 'El rango de ${position.abbreviation} cubre cerca del '
            '${range.percentOfAllHands.round()}% de las manos. Las posiciones '
            'más tardías amplían ese porcentaje porque hay menos jugadores '
            'por actuar y se realiza mejor la equity.',
        advancedConcepts: const [ConceptIds.rangeWidth, ConceptIds.equityRealization],
        conceptSummary: 'Reconocer el rango de apertura',
      ),
      meta: {'position': position.abbreviation, 'hand': hand.notation},
    );
  }
}
