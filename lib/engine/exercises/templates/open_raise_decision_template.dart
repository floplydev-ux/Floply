import '../../concepts/concept_ids.dart';
import '../../poker/poker_action.dart';
import '../../poker/position.dart';
import '../../poker/street.dart';
import '../../strategy/opening_ranges.dart';
import '../../strategy/strategy.dart';
import '../exercise.dart';
import '../exercise_template.dart';
import '../generation_context.dart';
import 'hand_picker.dart';
import 'situation_factory.dart';

/// "Todos foldean hasta vos en {posición}. Tenés {mano}. ¿Qué hacés?"
///
/// El ejercicio central del vertical slice: evalúa si el usuario abre las
/// manos correctas desde cada posición.
class OpenRaiseDecisionTemplate extends ExerciseTemplate {
  const OpenRaiseDecisionTemplate();

  @override
  String get id => 'open_raise_decision';

  @override
  ExerciseType get type => ExerciseType.chooseAction;

  @override
  Street get street => Street.preflop;

  @override
  Set<String> get evaluatedConcepts => const {
        ConceptIds.openRaise,
        ConceptIds.openingRange,
      };

  @override
  Set<String> get requiredConcepts => const {
        ConceptIds.openRaise,
        ConceptIds.openingRange,
        ConceptIds.positionAdvantage,
      };

  @override
  Set<String> get optionalConcepts => const {ConceptIds.mixedStrategies};

  @override
  List<int> get supportedDifficulties => const [1, 2, 3, 4];

  @override
  double get weight => 2.0;

  @override
  Exercise generate(GenerationContext ctx) {
    final deck = ctx.deck;
    final position = deck.pick(
      SituationFactory.openerPoolForDifficulty(ctx.difficulty),
    );
    final bias = HandPicker.biasForDifficulty(deck, ctx.difficulty);
    final hand = HandPicker.forBias(deck, position, bias);
    final stack = SituationFactory.stackForDifficulty(deck, ctx.difficulty);
    final idealSize = OpeningRanges.sizingFor(position);

    final situation = SituationFactory.firstIn(
      heroPosition: position,
      heroCards: hand,
      effectiveStackBb: stack,
      availableRaiseSizes: [idealSize],
    );

    final strategy = ctx.strategyEngine.openRaiseStrategy(situation);

    final raiseOption = AnswerOption(
      id: 'raise',
      label: 'SUBIR a ${_fmt(idealSize)}bb',
      action: PokerAction.raiseTo(idealSize),
    );
    const foldOption = AnswerOption(
      id: 'fold',
      label: 'FOLD',
      action: PokerAction.fold,
    );
    // Orden aleatorio para no fijar "la de arriba siempre es subir".
    final options = deck.pick(const [true, false])
        ? [raiseOption, foldOption]
        : [foldOption, raiseOption];

    final reasoning = ctx.keepTaught(const [
      ConceptIds.openingRange,
      ConceptIds.positionAdvantage,
      ConceptIds.openRaise,
    ]);

    final inRange = strategy.optionFor(PokerAction.raiseTo(idealSize))!.rating;

    return Exercise(
      id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
      templateId: id,
      type: type,
      difficulty: ctx.difficulty,
      prompt: 'Estás en ${position.abbreviation} (${position.fullName}). '
          '${situation.actionHistoryDescription} '
          'Tenés ${hand.pretty} con ${_fmt(stack)}bb efectivos. ¿Qué hacés?',
      options: options,
      strategy: strategy,
      evaluatedConcepts: ctx.keepTaught(evaluatedConcepts),
      requiredConcepts: requiredConcepts.toList(),
      optionalConcepts: ctx.keepTaught(optionalConcepts),
      reasoningConcepts: reasoning,
      situation: situation,
      explanation: _explain(position, hand.notation, strategy, inRange),
      meta: {
        'position': position.abbreviation,
        'hand': hand.notation,
        'bias': bias.name,
      },
    );
  }

  ExerciseExplanation _explain(
    Position position,
    String notation,
    Strategy strategy,
    StrategicRating raiseRating,
  ) {
    final opens = strategy.primary.action.type == ActionType.raise;
    final basic = opens
        ? '$notation entra en el rango con el que ${position.abbreviation} abre '
            'de primera mano. Cuanto más tarde es la posición, más ancho es ese '
            'rango.'
        : '$notation queda fuera del rango de apertura de '
            '${position.abbreviation}: es demasiado floja para abrir con '
            'tantos jugadores todavía por hablar.';
    return ExerciseExplanation(
      basic: basic,
      advanced: opens
          ? 'Desde ${position.abbreviation} esta mano realiza bien su equity: '
              'la posición te deja jugar más botes con iniciativa y capturar '
              'valor postflop, por eso se puede abrir más ancho.'
          : 'Abrir esta mano desde ${position.abbreviation} tiene EV negativo: '
              'la frecuencia con la que te 3-betean y jugás botes fuera de '
              'posición supera el valor de robar las ciegas.',
      advancedConcepts: const [
        ConceptIds.equityRealization,
        ConceptIds.ev,
      ],
      conceptSummary: 'Rango de apertura por posición',
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
