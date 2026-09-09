import '../../concepts/concept_ids.dart';
import '../../poker/poker_action.dart';
import '../../poker/position.dart';
import '../../poker/street.dart';
import '../../strategy/opening_ranges.dart';
import '../exercise.dart';
import '../exercise_template.dart';
import '../generation_context.dart';
import 'hand_picker.dart';
import 'situation_factory.dart';

/// Challenge: decisión completa de apertura tardía (BTN / CO / SB) contra
/// las ciegas, con manos de borde y razonamiento obligatorio.
class FullOpenDecisionTemplate extends ExerciseTemplate {
  const FullOpenDecisionTemplate();

  @override
  String get id => 'full_open_decision';

  @override
  ExerciseType get type => ExerciseType.fullDecision;

  @override
  Street get street => Street.preflop;

  @override
  Set<String> get evaluatedConcepts => const {
        ConceptIds.openRaise,
        ConceptIds.openingRange,
        ConceptIds.positionAdvantage,
      };

  @override
  Set<String> get requiredConcepts => const {
        ConceptIds.openRaise,
        ConceptIds.openingRange,
        ConceptIds.positionAdvantage,
        ConceptIds.rangeWidth,
      };

  @override
  List<int> get supportedDifficulties => const [3, 4, 5];

  @override
  double get weight => 0.8;

  @override
  Exercise generate(GenerationContext ctx) {
    final deck = ctx.deck;
    final position =
        deck.pick(const [Position.co, Position.btn, Position.sb]);
    final bias = deck.pick(const [
      HandBias.borderline,
      HandBias.borderline,
      HandBias.clearlyOutOfRange,
      HandBias.clearlyInRange,
    ]);
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
    const foldOption =
        AnswerOption(id: 'fold', label: 'FOLD', action: PokerAction.fold);

    final blindsNote = position == Position.sb
        ? 'Solo te queda la BB por actuar, y vas a jugar el resto de la mano '
            'fuera de posición.'
        : 'Solo quedan SB y BB por actuar, y vas a tener posición sobre ellas '
            'en todas las calles.';

    return Exercise(
      id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
      templateId: id,
      type: type,
      difficulty: ctx.difficulty,
      prompt: 'Mesa 6-max, ${_fmt(stack)}bb efectivos. Todos foldean hasta vos '
          'en ${position.abbreviation} (${position.fullName}). '
          'Tenés ${hand.pretty}. $blindsNote ¿Qué hacés y por qué?',
      options: deck.nextBool()
          ? [raiseOption, foldOption]
          : [foldOption, raiseOption],
      strategy: strategy,
      situation: situation,
      evaluatedConcepts: ctx.keepTaught(evaluatedConcepts),
      requiredConcepts: requiredConcepts.toList(),
      reasoningConcepts: ctx.keepTaught(const [
        ConceptIds.openingRange,
        ConceptIds.positionAdvantage,
        ConceptIds.openRaise,
        ConceptIds.rangeWidth,
      ]),
      explanation: ExerciseExplanation(
        basic: strategy.primary.action.type == ActionType.raise
            ? 'Desde ${position.abbreviation}, con las ciegas por actuar, este '
                'tipo de mano entra en tu rango de apertura.'
            : 'Aun siendo posición tardía, ${hand.notation} es demasiado floja '
                'para abrir desde ${position.abbreviation}.',
        advanced: 'La clave es la realización de equity: en '
            '${position.abbreviation} jugás la mano con (o casi con) la última '
            'palabra, así que manos marginales suben de valor. Aun así hay un '
            'límite: por debajo de él, el EV de abrir es negativo.',
        advancedConcepts: const [
          ConceptIds.equityRealization,
          ConceptIds.ev,
        ],
        conceptSummary: 'Apertura tardía contra las ciegas',
      ),
      meta: {'position': position.abbreviation, 'hand': hand.notation},
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
