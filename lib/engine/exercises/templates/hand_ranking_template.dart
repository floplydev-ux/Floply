import '../../concepts/concept_ids.dart';
import '../../poker/hand_category.dart';
import '../../poker/poker_action.dart';
import '../../poker/street.dart';
import '../../strategy/strategy.dart';
import '../exercise.dart';
import '../exercise_template.dart';
import '../generation_context.dart';

/// "En el showdown, ¿cuál de estas dos manos gana?"
///
/// Familia de ejercicios sobre el ranking de manos hechas, sin cartas
/// concretas: el usuario tiene que reconocer la jerarquía y compararla.
/// Es el primer ejercicio que el motor sabe generar para la Academia.
class HandRankingTemplate extends ExerciseTemplate {
  const HandRankingTemplate();

  @override
  String get id => 'hand_ranking_compare';

  @override
  ExerciseType get type => ExerciseType.compareHands;

  @override
  Street get street => Street.river;

  @override
  Set<String> get evaluatedConcepts => const {ConceptIds.handRanking};

  @override
  Set<String> get requiredConcepts => const {ConceptIds.handRanking};

  @override
  List<int> get supportedDifficulties => const [1, 2, 3];

  @override
  double get weight => 0.6;

  @override
  Exercise generate(GenerationContext ctx) {
    final deck = ctx.deck;
    final categories = HandCategory.weakToStrong;

    // Cuanto mayor la dificultad, más cerca están las dos categorías en la
    // jerarquía (más difícil de distinguir).
    final maxDistance = switch (ctx.difficulty) {
      1 => 8,
      2 => 4,
      _ => 2,
    };
    final minDistance = ctx.difficulty >= 3 ? 1 : 2;

    final lowIndex = deck.intInRange(0, categories.length - 1 - minDistance);
    final maxHigh =
        (lowIndex + maxDistance).clamp(0, categories.length - 1);
    final highIndex = deck.intInRange(
      (lowIndex + minDistance).clamp(0, categories.length - 1),
      maxHigh,
    );
    if (highIndex <= lowIndex) {
      throw TemplateGenerationException('Categorías sin diferencia de fuerza');
    }

    final weaker = categories[lowIndex];
    final stronger = categories[highIndex];

    final weakerOption = AnswerOption(
      id: 'weak',
      label: weaker.label,
      value: weaker.name,
    );
    final strongerOption = AnswerOption(
      id: 'strong',
      label: stronger.label,
      value: stronger.name,
    );

    final strategy = Strategy(const [
      StrategyOption(
        action: PokerAction.check,
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: [ConceptIds.handRanking],
        rationaleKey: 'hand.ranking.stronger',
      ),
    ]);

    return Exercise(
      id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
      templateId: id,
      type: type,
      difficulty: ctx.difficulty,
      prompt: 'Los dos jugadores llegan al showdown.\n\n'
          '· ${weaker.label} (ej: ${weaker.example})\n'
          '· ${stronger.label} (ej: ${stronger.example})\n\n'
          '¿Cuál mano gana?',
      options: deck.nextBool()
          ? [weakerOption, strongerOption]
          : [strongerOption, weakerOption],
      strategy: strategy,
      correctValue: stronger.name,
      evaluatedConcepts: ctx.keepTaught(evaluatedConcepts),
      requiredConcepts: requiredConcepts.toList(),
      reasoningConcepts: const [],
      explanation: ExerciseExplanation(
        basic: '${stronger.label} gana: está más arriba en el ranking que '
            '${weaker.label}. ${stronger.description}',
        conceptSummary: 'Ranking de manos',
      ),
      meta: {
        'weaker': weaker.name,
        'stronger': stronger.name,
      },
    );
  }
}
