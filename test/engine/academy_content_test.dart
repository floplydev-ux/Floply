import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/concepts/concept_registry.dart';
import 'package:poker_trainer/engine/exercises/exercise_generator.dart';
import 'package:poker_trainer/engine/pedagogy/academy_content.dart';
import 'package:poker_trainer/engine/pedagogy/curriculum.dart';

void main() {
  final curriculum = Curriculum.standard();
  final registry = ConceptRegistry.standard();

  test('el currículo tiene 5 niveles de 5 sub-niveles con la estructura '
      'teoría → práctica → evaluación', () {
    expect(curriculum.levels.length, 5);
    for (final level in curriculum.levels) {
      expect(level.lessons.length, 5, reason: 'nivel ${level.number}');
      expect(level.lessons.first.kind, LessonKind.theory);
      expect(level.lessons.last.kind, LessonKind.assessment);
    }
  });

  test('todos los sub-niveles tienen contenido pedagógico', () {
    for (final lesson in curriculum.allLessons) {
      expect(AcademyContent.has(lesson.id), isTrue,
          reason: 'falta contenido para ${lesson.id}');
      final content = AcademyContent.forLesson(lesson.id)!;
      expect(content.objective.trim(), isNotEmpty);
      if (lesson.kind == LessonKind.theory) {
        expect(content.hasTheory, isTrue, reason: '${lesson.id} sin teoría');
      }
      // Cada sub-nivel tiene con qué practicar: ejercicios del motor o
      // preguntas autorales.
      expect(content.usesEngine || content.checks.isNotEmpty, isTrue,
          reason: '${lesson.id} no tiene ejercicios');
    }
  });

  test('ningún concepto se practica/chequea antes de que la teoría lo '
      'introduzca', () {
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
              reason: '${lesson.id} chequea "${check.concept}" no '
                  'introducido');
        }
      }
    }
  });

  test('los conceptos de práctica tienen cobertura en el generador', () {
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

  test('todo concepto introducido existe en el registro', () {
    for (final lesson in curriculum.allLessons) {
      for (final c in lesson.conceptsIntroduced) {
        expect(registry.has(c), isTrue, reason: '${lesson.id}: "$c"');
      }
    }
  });

  test('las preguntas autorales están bien formadas', () {
    for (final lesson in curriculum.allLessons) {
      for (final check in AcademyContent.forLesson(lesson.id)!.checks) {
        expect(check.options.length, greaterThanOrEqualTo(2));
        expect(check.correctIndex, inInclusiveRange(0, check.options.length - 1));
        expect(check.explanation.trim(), isNotEmpty);
      }
    }
  });
}
