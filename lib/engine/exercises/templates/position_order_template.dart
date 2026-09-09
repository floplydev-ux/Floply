import '../../concepts/concept_ids.dart';
import '../../poker/poker_action.dart';
import '../../poker/position.dart';
import '../../poker/street.dart';
import '../../strategy/strategy.dart';
import '../exercise.dart';
import '../exercise_template.dart';
import '../generation_context.dart';

/// "¿Quién actúa antes / después en el preflop?"
///
/// Familia de ejercicios sobre el orden de acción de las posiciones en
/// 6-max. No usa cartas: refuerza los nombres de las posiciones y su
/// secuencia.
class PositionOrderTemplate extends ExerciseTemplate {
  const PositionOrderTemplate();

  @override
  String get id => 'position_action_order';

  @override
  ExerciseType get type => ExerciseType.multipleChoice;

  @override
  Street get street => Street.preflop;

  @override
  Set<String> get evaluatedConcepts => const {ConceptIds.positionNames};

  @override
  Set<String> get requiredConcepts => const {ConceptIds.positionNames};

  @override
  List<int> get supportedDifficulties => const [1, 2, 3];

  @override
  double get weight => 0.6;

  @override
  Exercise generate(GenerationContext ctx) {
    final deck = ctx.deck;
    // Orden de acción preflop: el enum ya está en ese orden (UTG..BB).
    const order = Position.values;

    // Dificultad 1: extremos (primero / último). 2-3: relativo entre dos.
    final variant = ctx.difficulty >= 2 ? deck.intInRange(0, 2) : deck.intInRange(0, 1);

    String prompt;
    Position answer;
    List<Position> pool;

    switch (variant) {
      case 0:
        prompt = 'En el preflop, ¿quién es el PRIMERO en actuar?';
        answer = order.first;
        pool = deck.shuffled(order).take(4).toList();
        if (!pool.contains(answer)) pool[0] = answer;
      case 1:
        prompt = 'En el preflop, ¿quién es el ÚLTIMO en actuar?';
        answer = order.last;
        pool = deck.shuffled(order).take(4).toList();
        if (!pool.contains(answer)) pool[0] = answer;
      default:
        final pivot = order[deck.intInRange(1, order.length - 2)];
        final after = deck.nextBool();
        prompt = after
            ? 'En el preflop, justo DESPUÉS de ${pivot.abbreviation} '
                '(${pivot.fullName}), ¿quién actúa?'
            : 'En el preflop, justo ANTES de ${pivot.abbreviation} '
                '(${pivot.fullName}), ¿quién actúa?';
        answer = after
            ? order[pivot.index + 1]
            : order[pivot.index - 1];
        pool = deck.shuffled(order.where((p) => p != pivot)).take(4).toList();
        if (!pool.contains(answer)) pool[0] = answer;
    }

    pool = deck.shuffled(pool);
    final options = pool
        .map((p) => AnswerOption(
              id: p.abbreviation,
              label: '${p.abbreviation} — ${p.fullName}',
              value: p.abbreviation,
            ))
        .toList();

    final strategy = Strategy(const [
      StrategyOption(
        action: PokerAction.check,
        frequency: 1.0,
        rating: StrategicRating.optimal,
        justifyingConcepts: [ConceptIds.positionNames],
        rationaleKey: 'position.order',
      ),
    ]);

    return Exercise(
      id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
      templateId: id,
      type: type,
      difficulty: ctx.difficulty,
      prompt: prompt,
      options: options,
      strategy: strategy,
      correctValue: answer.abbreviation,
      evaluatedConcepts: ctx.keepTaught(evaluatedConcepts),
      requiredConcepts: requiredConcepts.toList(),
      reasoningConcepts: const [],
      explanation: ExerciseExplanation(
        basic: 'El orden de acción preflop en 6-max es: '
            'UTG → HJ → CO → BTN → SB → BB. '
            'Por eso la respuesta es ${answer.abbreviation} '
            '(${answer.fullName}).',
        conceptSummary: 'Orden de acción preflop',
      ),
      meta: {'answer': answer.abbreviation, 'variant': variant},
    );
  }
}
