import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/exercises/answer_evaluator.dart';
import 'package:poker_trainer/engine/exercises/preflop_verdict.dart';
import 'package:poker_trainer/engine/strategy/preflop_authoring.dart';
import 'package:poker_trainer/engine/strategy/strategy.dart';

void main() {
  group('preflopVerdict — regla de la Fase 0.5, sección C', () {
    test('calidad top -> BEST, sin importar el contexto', () {
      expect(
        preflopVerdict(
          quality: StrategicRating.optimal,
          contextSensitivity: const ContextSensitivity.stable(),
        ),
        AnswerVerdict.best,
      );
      expect(
        preflopVerdict(
          quality: StrategicRating.veryGood,
          contextSensitivity:
              ContextSensitivity.dependent([ContextFactor.opponentProfile]),
        ),
        AnswerVerdict.best,
      );
    });

    test('calidad mid (viable) -> ACCEPTABLE, sin importar el contexto', () {
      expect(
        preflopVerdict(
          quality: StrategicRating.viable,
          contextSensitivity: const ContextSensitivity.stable(),
        ),
        AnswerVerdict.acceptable,
      );
    });

    test('calidad low + estable -> ERROR', () {
      expect(
        preflopVerdict(
          quality: StrategicRating.bad,
          contextSensitivity: const ContextSensitivity.stable(),
        ),
        AnswerVerdict.poor,
      );
      expect(
        preflopVerdict(
          quality: StrategicRating.dubious,
          contextSensitivity: const ContextSensitivity.stable(),
        ),
        AnswerVerdict.poor,
      );
    });

    test('calidad low + depende de un factor NO revelado -> DEPENDS', () {
      final ctx = ContextSensitivity.dependent(
        [ContextFactor.opponentProfile],
        disclosedToStudent: false,
      );
      expect(
        preflopVerdict(quality: StrategicRating.dubious, contextSensitivity: ctx),
        AnswerVerdict.dependent,
      );
    });

    test('calidad low + depende de un factor YA revelado -> ERROR, no DEPENDS', () {
      final ctx = ContextSensitivity.dependent(
        [ContextFactor.opponentProfile],
        disclosedToStudent: true,
      );
      expect(
        preflopVerdict(quality: StrategicRating.dubious, contextSensitivity: ctx),
        AnswerVerdict.poor,
      );
    });
  });

  group('casos A/B del informe de diseño (dos opciones del mismo spot)', () {
    test('caso A: dos acciones top-tier en un mix real son ambas BEST', () {
      final call = preflopVerdict(
        quality: StrategicRating.optimal,
        contextSensitivity: const ContextSensitivity.stable(),
      );
      final threeBet = preflopVerdict(
        quality: StrategicRating.veryGood,
        contextSensitivity: const ContextSensitivity.stable(),
      );
      expect(call, AnswerVerdict.best);
      expect(threeBet, AnswerVerdict.best);
    });

    test('caso B: la calidad decide el veredicto, no la frecuencia', () {
      final threeBet = preflopVerdict(
        quality: StrategicRating.optimal,
        contextSensitivity: const ContextSensitivity.stable(),
      );
      final call = preflopVerdict(
        quality: StrategicRating.viable,
        contextSensitivity: const ContextSensitivity.stable(),
      );
      expect(threeBet, AnswerVerdict.best);
      expect(call, AnswerVerdict.acceptable);
    });
  });
}
