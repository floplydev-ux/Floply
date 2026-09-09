import '../../concepts/concept_ids.dart';
import '../../poker/poker_action.dart';
import '../../poker/position.dart';
import '../../poker/street.dart';
import '../../strategy/opening_ranges.dart';
import '../../strategy/strategy.dart';
import '../exercise.dart';
import '../exercise_template.dart';
import '../generation_context.dart';

/// "¿Desde qué posición podés abrir MÁS manos?"
///
/// Evalúa el concepto de amplitud de rango y su relación con la posición,
/// sin cartas de por medio.
class WidestRangeTemplate extends ExerciseTemplate {
  const WidestRangeTemplate();

  @override
  String get id => 'widest_opening_range';

  @override
  ExerciseType get type => ExerciseType.compareRangeWidth;

  @override
  Street get street => Street.preflop;

  @override
  Set<String> get evaluatedConcepts =>
      const {ConceptIds.rangeWidth, ConceptIds.positionAdvantage};

  @override
  Set<String> get requiredConcepts =>
      const {ConceptIds.rangeWidth, ConceptIds.positionAdvantage};

  @override
  List<int> get supportedDifficulties => const [1, 2, 3];

  @override
  Exercise generate(GenerationContext ctx) {
    final deck = ctx.deck;
    final pool = deck.shuffled(Position.openers);
    final count = ctx.difficulty >= 3 ? 3 : deck.pick(const [2, 3]);
    final chosen = pool.take(count).toList();

    // Ordenar por amplitud real para conocer la respuesta.
    final byWidth = [...chosen]
      ..sort((a, b) => a.opensWiderThan(b) ? 1 : -1);
    final widest = byWidth.last;

    final options = chosen
        .map((p) => AnswerOption(
              id: p.abbreviation,
              label: '${p.abbreviation} — ${p.fullName}',
              value: p.abbreviation,
            ))
        .toList();

    final strategy = Strategy([
      StrategyOption(
        action: PokerAction.raiseTo(OpeningRanges.sizingFor(widest)),
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: const [
          ConceptIds.rangeWidth,
          ConceptIds.positionAdvantage,
        ],
        rationaleKey: 'range.wider.later',
      ),
    ]);

    final widthLine = chosen
        .map((p) =>
            '${p.abbreviation} ≈ ${OpeningRanges.forPosition(p).percentOfAllHands.round()}%')
        .join(', ');

    return Exercise(
      id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
      templateId: id,
      type: type,
      difficulty: ctx.difficulty,
      prompt: 'Si sos el primero en entrar al bote, ¿desde cuál de estas '
          'posiciones podés abrir MÁS manos: '
          '${chosen.map((p) => p.abbreviation).join(", ")}?',
      options: options,
      strategy: strategy,
      correctValue: widest.abbreviation,
      evaluatedConcepts: ctx.keepTaught(evaluatedConcepts),
      requiredConcepts: requiredConcepts.toList(),
      reasoningConcepts: ctx.keepTaught(const [
        ConceptIds.positionAdvantage,
        ConceptIds.rangeWidth,
      ]),
      explanation: ExerciseExplanation(
        basic: 'La posición más tardía abre más manos: ${widest.abbreviation} '
            'porque quedan menos jugadores por hablar. Rangos aproximados: '
            '$widthLine.',
        advanced: 'Con posición se realiza mejor la equity (podés controlar el '
            'tamaño del bote y ver actuar a los rivales), así que manos '
            'marginales pasan a ser rentables al abrir.',
        advancedConcepts: const [ConceptIds.equityRealization],
        conceptSummary: 'Posición y amplitud de rango',
      ),
      meta: {'positions': chosen.map((p) => p.abbreviation).toList()},
    );
  }
}
