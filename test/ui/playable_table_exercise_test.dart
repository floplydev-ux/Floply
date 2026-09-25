import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/academy/academy_progress.dart'
    show LessonState;
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/concepts/concept_ids.dart';
import 'package:poker_trainer/engine/pedagogy/academy_playable_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';
import 'package:poker_trainer/engine/pedagogy/playable_exercise.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';

/// Lleva un [AcademyController] recién cargado hasta justo antes de
/// [lessonId], completando todo lo anterior eligiendo siempre la mejor
/// opción disponible (incluidos ítems jugables). Duplica a propósito el
/// helper equivalente de `academy_controller_test.dart`: son 2 archivos,
/// no vale la pena una tercera capa compartida para esto.
Future<void> reachLesson(AcademyController c, String lessonId) async {
  for (final id in Curriculum.lessonOrder) {
    if (id == lessonId) break;
    c.openLesson(id);
    while (c.phase == AcademyPhase.theory) {
      c.advanceTheory();
    }
    while (
        c.phase == AcademyPhase.exercise || c.phase == AcademyPhase.feedback) {
      if (c.phase == AcademyPhase.exercise) {
        final item = c.currentItem!;
        if (item.isPlayable) {
          answerPlayableBest(c);
        } else if (item.isInteractive) {
          c.answerInteractive(item.interactive!.bestChoiceIndex);
          c.advanceInteractive();
        } else if (item.isEngine) {
          final ex = item.exercise!;
          final best = ex.strategy.primary;
          var i = ex.options.indexWhere((o) =>
              (o.action != null && o.action!.matches(best.action)) ||
              (ex.correctValue != null && o.value == ex.correctValue));
          if (i < 0) i = 0;
          c.toggleOption(i);
          c.confirm();
        } else {
          c.toggleOption(item.check!.correctIndex);
          c.confirm();
        }
      } else {
        c.nextItem();
      }
    }
    c.exitLesson();
  }
  c.openLesson(lessonId);
  while (c.phase == AcademyPhase.theory) {
    c.advanceTheory();
  }
}

int _bestIndex<T>(List<T> options, ExerciseRating Function(T) rating) {
  final i = options.indexWhere((o) => rating(o) == ExerciseRating.best);
  return i < 0 ? 0 : i;
}

int _worstIndex<T>(List<T> options, ExerciseRating Function(T) rating) {
  final i = options.indexWhere((o) => rating(o) == ExerciseRating.poor);
  return i < 0 ? 0 : i;
}

/// Resuelve el ejercicio jugable actual eligiendo siempre la mejor opción
/// en cada paso (acción, tamaño si aplica, razón) y avanza.
void answerPlayableBest(AcademyController c) {
  final ex = c.currentPlayable!;
  c.choosePlayableAction(_bestIndex(ex.actions, (a) => a.rating));
  final action = ex.actions[c.playableActionIndex!];
  if (action.needsSizing) {
    c.choosePlayableSize(_bestIndex(action.sizeOptions, (s) => s.rating));
  }
  c.confirmPlayableReasoning(_bestIndex(action.reasoning, (r) => r.rating));
  c.advancePlayable();
}

void main() {
  AcademyController make() => AcademyController(
        engine: PokerTrainerEngine(seed: 7),
        store: InMemoryAcademyStore(),
      );

  group('AcademyPlayableScripts', () {
    test('los 4 pilotos están registrados y no vacíos', () {
      for (final id in ['5.3', '5.4', '5.5', '8.6']) {
        final set = AcademyPlayableScripts.forLesson(id);
        expect(set, isNotNull, reason: id);
        expect(set!.isEmpty, isFalse, reason: id);
      }
      expect(AcademyPlayableScripts.forLesson('1.1'), isNull);
    });

    test(
        'cada acción trae al menos una razón, y ninguna lista de '
        'acciones repite la misma calidad "best" dos veces', () {
      for (final set in AcademyPlayableScripts.byId.values) {
        for (final ex in set.exercises) {
          expect(ex.actions, isNotEmpty);
          for (final action in ex.actions) {
            expect(action.reasoning, isNotEmpty, reason: action.label);
          }
          final bestCount =
              ex.actions.where((a) => a.rating == ExerciseRating.best).length;
          expect(bestCount, lessThanOrEqualTo(1));
        }
      }
    });
  });

  group('flujo del controller', () {
    test(
        '5.3: solo aparecen las acciones legales que trae el contenido '
        '(FOLD/ABRIR, nada más)', () async {
      final c = make();
      await c.load();
      await reachLesson(c, '5.3');

      final ex = c.currentPlayable!;
      expect(ex.actions.map((a) => a.label).toSet(), {'ABRIR', 'FOLDEAR'});
    });

    test(
        '5.4: la acción con sizeOptions abre el paso de tamaño; la que no '
        'los tiene, no', () async {
      final c = make();
      await c.load();
      await reachLesson(c, '5.4');

      final ex = c.currentPlayable!;
      final raise = ex.actions.firstWhere((a) => a.action == PokerAction.raise);
      final fold = ex.actions.firstWhere((a) => a.action == PokerAction.fold);
      expect(raise.needsSizing, isTrue);
      expect(fold.needsSizing, isFalse);

      // Elegir la acción sin tamaño no debe pedir sizing.
      c.choosePlayableAction(ex.actions.indexOf(fold));
      expect(c.needsPlayableSizing, isFalse);
    });

    test(
        'nada se revela antes de confirmar: sin rating hasta elegir '
        'acción + (tamaño) + razón', () async {
      final c = make();
      await c.load();
      await reachLesson(c, '5.3');

      expect(c.lastPlayableFeedback, isNull);
      final ex = c.currentPlayable!;
      final bestIdx = _bestIndex(ex.actions, (a) => a.rating);
      c.choosePlayableAction(bestIdx);
      expect(c.lastPlayableFeedback, isNull,
          reason: 'elegir la acción todavía no confirma nada');

      final action = ex.actions[bestIdx];
      c.confirmPlayableReasoning(_bestIndex(action.reasoning, (r) => r.rating));
      expect(c.lastPlayableFeedback, isNotNull);
    });

    test('confirmPlayableReasoning es no-op mientras falta elegir tamaño',
        () async {
      final c = make();
      await c.load();
      await reachLesson(c, '5.4');

      final ex = c.currentPlayable!;
      final raiseIdx =
          ex.actions.indexWhere((a) => a.action == PokerAction.raise);
      c.choosePlayableAction(raiseIdx);
      expect(c.needsPlayableSizing, isTrue);

      c.confirmPlayableReasoning(0);
      expect(c.lastPlayableFeedback, isNull,
          reason: 'no debería poder confirmar razonamiento sin tamaño');
    });

    test(
        'estado se resetea entre ítems (advancePlayable limpia acción, '
        'tamaño y feedback)', () async {
      final c = make();
      await c.load();
      await reachLesson(c, '5.4');

      answerPlayableBest(c);
      expect(c.playableActionIndex, isNull);
      expect(c.playableSizeIndex, isNull);
      expect(c.lastPlayableFeedback, isNull);
    });

    test(
        'evaluación separada: misma acción, distinta calidad de '
        'razonamiento, se registra en ejes distintos de UserConceptMastery',
        () async {
      final c = make();
      await c.load();
      await reachLesson(c, '5.3');

      final ex = c.currentPlayable!;
      final bestActionIdx = _bestIndex(ex.actions, (a) => a.rating);
      final action = ex.actions[bestActionIdx];
      final worstReasonIdx = _worstIndex(action.reasoning, (r) => r.rating);
      expect(action.reasoning[worstReasonIdx].rating, ExerciseRating.poor,
          reason: 'el piloto 5.3 debe tener una razón mala para probar '
              'esto — si falla, revisar el contenido autoral');

      // Mejor acción posible + peor razonamiento posible.
      c.choosePlayableAction(bestActionIdx);
      c.confirmPlayableReasoning(worstReasonIdx);

      final mastery = c.knowledge.masteryOf(ConceptIds.openRaise);
      expect(mastery.attempts, 1);
      expect(mastery.decisionHits, 1,
          reason: 'la acción elegida fue la mejor: decisionCorrect');
      expect(mastery.reasoningAttempts, 1);
      expect(mastery.reasoningHits, 0,
          reason: 'la razón elegida fue mala: reasoningCorrect debe ser '
              'false, distinto de decisionCorrect');

      // El puntaje del lesson, en cambio, sí toma el peor de los dos ejes:
      // una buena acción con mala razón no cuenta como ítem resuelto.
      expect(c.lastPlayableFeedback!.combined, ExerciseRating.poor);
    });

    test(
        'concepto no enseñado: recordAttempt no explota y no marca '
        'dominio (regla fundamental intacta)', () async {
      final c = make();
      await c.load();
      // Sin ninguna progresión: ConceptIds.openRaise todavía está locked.
      expect(c.knowledge.isTaught(ConceptIds.openRaise), isFalse);

      c.knowledge.recordAttempt(ConceptIds.openRaise,
          decisionCorrect: true, reasoningCorrect: true);

      expect(c.knowledge.isTaught(ConceptIds.openRaise), isFalse);
      expect(c.knowledge.masteryOf(ConceptIds.openRaise).attempts, 0);
    });

    test(
        'completar 5.3 en formato jugable desbloquea 5.4 (progreso '
        'intacto)', () async {
      final c = make();
      await c.load();
      await reachLesson(c, '5.3');
      answerPlayableBest(c);
      expect(c.phase, AcademyPhase.result);
      expect(c.lastOutcome!.completed, isTrue);
      c.exitLesson();
      expect(c.academy.stateOf('5.4', c.progress), LessonState.available);
    });
  });

  group('widget', () {
    testWidgets(
        '390dp: la mesa muestra los botones de acción reales y el flujo '
        'completo (acción → razón → devolución → siguiente) no revienta',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final c = make();
      await c.load();
      await reachLesson(c, '5.3');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AcademyScreen(controller: c)),
      ));
      await tester.pumpAndSettle();

      final ex = c.currentPlayable!;
      for (final action in ex.actions) {
        expect(find.text(action.label), findsOneWidget);
      }

      final worstAction = ex.actions.firstWhere(
        (a) => a.rating == ExerciseRating.poor,
        orElse: () => ex.actions.first,
      );
      await tester.tap(find.text(worstAction.label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Paso de razonamiento: todas las opciones visibles.
      for (final reasoning in worstAction.reasoning) {
        expect(find.text(reasoning.label), findsOneWidget);
      }
      await tester.tap(find.text(worstAction.reasoning.first.label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // La devolución mezcla el feedback de la acción Y el del
      // razonamiento — no es un simple "elegiste X".
      expect(find.textContaining(worstAction.feedback), findsWidgets);

      // Avanzar hasta el siguiente ítem (o resultado) sin excepciones.
      var guard = 0;
      while (c.phase == AcademyPhase.exercise && guard++ < 10) {
        final nextLabel = find.text('CONTINUAR').evaluate().isNotEmpty
            ? 'CONTINUAR'
            : (find.text('SIGUIENTE').evaluate().isNotEmpty
                ? 'SIGUIENTE'
                : 'VER RESULTADO');
        await tester.tap(find.text(nextLabel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
