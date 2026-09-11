import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/exercises/exercise_generator.dart';
import 'package:poker_trainer/engine/pedagogy/academy_content.dart';
import 'package:poker_trainer/engine/pedagogy/academy_exercise_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/academy_table_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';

void main() {
  final curriculum = Curriculum.standard();
  final spec = curriculum.spec;
  final registry = ConceptRegistry.standard();

  test('13 niveles; el primer subnivel de cada uno es teoría y el último, '
      'checkpoint (evaluación)', () {
    expect(curriculum.levels.length, 13);
    for (final level in curriculum.levels) {
      expect(level.lessons, isNotEmpty, reason: 'N${level.number}');
      expect(level.lessons.first.kind, LessonKind.theory,
          reason: 'N${level.number}');
      expect(level.lessons.last.kind, LessonKind.assessment,
          reason: 'N${level.number}');
      expect(level.lessons.last.sublevel.esCheckpoint, isTrue);
    }
  });

  test('todo subnivel resuelve a un LessonContent con objetivo', () {
    for (final s in spec.allSublevels) {
      final content = AcademyContent.forLesson(s.code);
      expect(content, isNotNull, reason: s.code);
      expect(content!.objective.trim(), isNotEmpty, reason: s.code);
      expect(AcademyContent.has(s.code), isTrue);
    }
    expect(AcademyContent.forLesson('99.9'), isNull);
    expect(AcademyContent.has('99.9'), isFalse);
  });

  test('la migración no pierde contenido: todo guion y set histórico queda '
      're-anclado a algún subnivel nuevo', () {
    final anchoredScripts = <String>{
      for (final s in spec.allSublevels) ...?s.legacy?.tableScripts,
    };
    expect(anchoredScripts, containsAll(AcademyTableScripts.all.keys),
        reason: 'guiones de mesa sin re-anclar: '
            '${AcademyTableScripts.all.keys.toSet().difference(anchoredScripts)}');

    final anchoredSets = <String>{
      for (final s in spec.allSublevels) ...?s.legacy?.exerciseSets,
    };
    expect(anchoredSets, containsAll(AcademyExerciseScripts.all.keys),
        reason: 'sets de ejercicios sin re-anclar: '
            '${AcademyExerciseScripts.all.keys.toSet().difference(anchoredSets)}');

    // Y todo subnivel que hereda un guion/set lo resuelve.
    for (final code in AcademyTableScripts.lessonIds) {
      expect(AcademyTableScripts.forLesson(code), isNotNull, reason: code);
    }
    for (final code in AcademyExerciseScripts.lessonIds) {
      expect(AcademyExerciseScripts.forLesson(code)!.exercises, isNotEmpty,
          reason: code);
    }
  });

  test('ningún concepto se practica/chequea antes de que se introduzca', () {
    for (final lesson in curriculum.allLessons) {
      final available = curriculum.conceptsTaughtUpTo(lesson.id);
      final content = AcademyContent.forLesson(lesson.id)!;

      final spec = content.practice;
      if (spec != null) {
        expect(available.contains(spec.targetConcept), isTrue,
            reason: '${lesson.id} practica "${spec.targetConcept}" no '
                'introducido');
      }
      for (final check in content.checks) {
        if (check.concept != null) {
          expect(available.contains(check.concept), isTrue,
              reason: '${lesson.id} chequea "${check.concept}"');
        }
      }
    }
  });

  test('los conceptos de práctica heredados tienen cobertura en el generador',
      () {
    final practiceable = ExerciseGenerator.defaultTemplates
        .expand((t) => t.evaluatedConcepts)
        .toSet();
    for (final lesson in curriculum.allLessons) {
      final spec = AcademyContent.forLesson(lesson.id)!.practice;
      if (spec != null) {
        expect(practiceable.contains(spec.targetConcept), isTrue,
            reason: '${lesson.id}: "${spec.targetConcept}" sin template');
      }
    }
  });

  test('todo concepto introducido por el currículo existe en el registro', () {
    for (final lesson in curriculum.allLessons) {
      for (final c in lesson.conceptsIntroduced) {
        expect(registry.has(c), isTrue, reason: '${lesson.id}: "$c"');
      }
    }
  });

  test('las preguntas autorales heredadas están bien formadas', () {
    for (final lesson in curriculum.allLessons) {
      for (final check in AcademyContent.forLesson(lesson.id)!.checks) {
        expect(check.options.length, greaterThanOrEqualTo(2));
        expect(check.correctIndex,
            inInclusiveRange(0, check.options.length - 1));
        expect(check.explanation.trim(), isNotEmpty);
      }
    }
  });

  test('conceptos_clave del spec: todos existen hoy en el ConceptRegistry', () {
    for (final s in spec.allSublevels) {
      for (final c in s.conceptosClave) {
        expect(registry.has(c), isTrue, reason: '${s.code}: "$c"');
      }
    }
  });
}
