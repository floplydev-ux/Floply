import '../concepts/concept.dart';
import '../concepts/concept_registry.dart';
import '../concepts/user_knowledge.dart';
import '../pedagogy/curriculum.dart';
import '../pedagogy/lab_feedback.dart';
import '../poker/poker_action.dart';
import '../strategy/decision_math.dart';
import 'answer_evaluator.dart';
import 'decision_context.dart';
import 'exercise_scenario.dart';
import 'preflop_rationale_bank.dart';

/// Arma la devolución estructurada de Laboratorio a partir de datos que ya
/// existen — nunca calcula estrategia ni juzga la decisión (eso ya lo hizo
/// [AnswerEvaluator]), solo traduce su resultado a algo explicable.
class LabFeedbackBuilder {
  const LabFeedbackBuilder._();

  static LabFeedback build(
    ExerciseScenario scenario,
    AnswerResult result,
    UserKnowledge knowledge,
    ConceptRegistry registry,
  ) {
    final context = scenario.decisionContext;

    Concept? concept;
    for (final id in result.justifyingConcepts) {
      if (!knowledge.isTaught(id)) continue;
      final found = registry.tryById(id);
      if (found != null) {
        concept = found;
        break;
      }
    }

    String? reviewLessonId;
    String? reviewLabel;
    if (concept != null && result.verdict != AnswerVerdict.best) {
      final lesson = _lessonIntroducing(concept.id);
      if (lesson != null) {
        reviewLessonId = lesson.id;
        reviewLabel = 'Nivel ${lesson.mainLevel}.${lesson.subLevel} — ${lesson.title}';
      }
    }

    return LabFeedback(
      expectedLabel: result.recommendedAction.label,
      strategicRating: result.matchedOption.rating,
      whyText: _whyText(result, context),
      math: _mathFor(result, context),
      conceptTitle: concept?.name,
      conceptExplanation: concept?.description,
      academyReviewLessonId: reviewLessonId,
      academyReviewLabel: reviewLabel,
    );
  }

  static String _whyText(AnswerResult result, DecisionContext context) {
    final fromBank = PreflopRationaleBank.textFor(result.matchedOption.rationaleKey);
    final base = fromBank ??
        switch (result.verdict) {
          AnswerVerdict.best => 'Es la mejor jugada en esta situación.',
          AnswerVerdict.acceptable =>
            'Es una jugada defendible, aunque no la preferida acá.',
          AnswerVerdict.poor => 'No es una buena elección en esta situación.',
          AnswerVerdict.dependent =>
            'No hay una única respuesta correcta acá: depende de tu rango y '
                'tu estilo.',
        };
    return _interpolate(base, context);
  }

  /// Placeholders simples que las entradas del banco pueden usar para
  /// hablar de la mano real jugada, no de un patrón genérico —
  /// `{board}`/`{heroHand}`, resueltos acá con los datos reales de
  /// [DecisionContext] (nunca inventados).
  static String _interpolate(String template, DecisionContext context) {
    if (!template.contains('{')) return template;
    final board =
        context.board.isEmpty ? 'este board' : context.board.map((c) => c.pretty).join(' ');
    return template
        .replaceAll('{board}', board)
        .replaceAll('{heroHand}', context.heroCards.pretty);
  }

  /// Combina la matemática que el motor de estrategia ya calculó
  /// ([StrategyOption.math] — equity/pot odds reales, hoy solo en las
  /// familias postflop de `PostflopStrategy`) con SPR/MDF, aritmética
  /// directa sobre [DecisionContext] que no necesita un motor propio.
  /// SPR/MDF solo se calculan cuando el héroe está encarando una apuesta o
  /// subida REAL de un rival esta calle — `toCallBb > 0` por sí solo no
  /// alcanza: preflop, `toCallBb` ya es > 0 con solo la ciega grande en
  /// juego (nadie "apostó" nada, es el punto de partida de la calle), así
  /// que mostrar MDF ahí sería ruido para la decisión más simple que
  /// existe (abrir o no). Ver [_facingBet].
  static DecisionMath? _mathFor(AnswerResult result, DecisionContext context) {
    final engineMath = result.matchedOption.math;

    double? sprValue;
    double? mdfPct;
    if (_facingBet(context) && context.toCallBb > 0 && context.potBb > 0) {
      sprValue = context.effectiveStackBb / context.potBb;
      final potBeforeBet = context.potBb - context.toCallBb;
      if (potBeforeBet > 0) {
        mdfPct = potBeforeBet / (potBeforeBet + context.toCallBb) * 100;
      }
    }

    if (engineMath == null && sprValue == null && mdfPct == null) return null;

    final combined = (engineMath ?? const DecisionMath()).copyWith(
      potBb: engineMath?.potBb ?? context.potBb,
      toCallBb: engineMath?.toCallBb ?? (context.toCallBb > 0 ? context.toCallBb : null),
      stackBb: engineMath?.stackBb ?? context.effectiveStackBb,
      sprValue: sprValue,
      mdfPct: mdfPct,
    );
    return combined.hasAny ? combined : null;
  }

  /// `true` si, en algún punto de esta calle (`DecisionContext.
  /// actionHistory`, el mismo `GameState.round.log` — nunca un historial
  /// paralelo), un rival hizo una apuesta/subida/all-in real que el héroe
  /// sigue debiendo igualar ahora mismo (`toCallBb > 0`). No alcanza con
  /// mirar solo la última entrada: entre la subida del rival y el turno
  /// del héroe puede haber folds de jugadores de fondo, que no cambian
  /// que la subida sigue en pie. Las ciegas nunca dejan entrada en este
  /// log (se postean al armar la mano, no vía `ActionResolver` — mismo
  /// hecho que ya usa `ExerciseScenarioAdapter._lastActionLabel`), así
  /// que abrir de entrada (incluso sobre limpers, que solo igualan la
  /// ciega sin subirla) da `false` acá, tal como corresponde.
  static bool _facingBet(DecisionContext context) {
    if (context.toCallBb <= 0) return false;
    return context.actionHistory.any((a) =>
        a.slot != context.heroSlot &&
        (a.action.type == ActionType.bet ||
            a.action.type == ActionType.raise ||
            a.action.type == ActionType.allIn));
  }

  /// La primera lección (en orden de currículo) cuyo `conceptsIntroduced`
  /// incluye [conceptId] — reutiliza el dato ya calculado en
  /// `Curriculum._build()` (expuesto por lección, público), nunca vuelve a
  /// derivar "dónde se enseña esto" con una regla propia. `null` si ningún
  /// subnivel real lo introduce (nunca se inventa ni se cita una lección
  /// fantasma).
  static Lesson? _lessonIntroducing(String conceptId) {
    for (final lesson in Curriculum.standard().allLessons) {
      if (lesson.conceptsIntroduced.contains(conceptId)) return lesson;
    }
    return null;
  }
}
