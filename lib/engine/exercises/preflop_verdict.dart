import '../strategy/preflop_authoring.dart';
import '../strategy/strategy.dart';
import 'answer_evaluator.dart';

/// La fórmula definitiva de "FLOPly — Fase 0.5" (informe de diseño,
/// sección C): el veredicto pedagógico depende SOLO de [QualityTier] +
/// [ContextSensitivity] — nunca de [MixShare]/frecuencia, que es
/// metadata descriptiva (ver `strategy/preflop_authoring.dart`).
///
/// Cableada al motor real: `AnswerEvaluator.evaluate`
/// (`exercises/answer_evaluator.dart`) llama esta función con el
/// `rating`/`contextSensitivity` reales de la [StrategyOption] elegida
/// — `StrategyOption` ya tiene esos dos campos
/// (`strategy/strategy.dart`), poblados donde corresponde por
/// `StrategyEngine.openRaiseStrategy` y las 3 estrategias de
/// `PreflopStrategy`. Reemplazó por completo al cálculo de `dependent`
/// que antes salía de la frecuencia (`strategy.isMixed && option.
/// frequency >= 0.15`).
AnswerVerdict preflopVerdict({
  required StrategicRating quality,
  required ContextSensitivity contextSensitivity,
}) {
  switch (quality.tier) {
    case QualityTier.top:
      return AnswerVerdict.best;
    case QualityTier.mid:
      return AnswerVerdict.acceptable;
    case QualityTier.low:
      final dependsForTheStudent = contextSensitivity.isDependent &&
          !contextSensitivity.disclosedToStudent;
      return dependsForTheStudent ? AnswerVerdict.dependent : AnswerVerdict.poor;
  }
}
