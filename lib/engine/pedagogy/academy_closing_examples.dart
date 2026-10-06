import 'academy_table_scripts.dart';
import 'scripts/closing_example_lessons.dart';
import 'scripts/n2_closing_examples.dart';
import 'scripts/n3_closing_examples.dart';
import 'scripts/n4_closing_examples.dart';
import 'scripts/n5_closing_examples.dart';
import 'scripts/n6_closing_examples.dart';
import 'scripts/n7_closing_examples.dart';
import 'scripts/n8_closing_examples.dart';
import 'scripts/n9_closing_examples.dart';
import 'scripts/n10_closing_examples.dart';
import 'scripts/n11_closing_examples.dart';
import 'scripts/n12_closing_examples.dart';
import 'scripts/n13_closing_examples.dart';
import 'table_lesson.dart';

/// Registro de **ejemplos de cierre** por código de subnivel.
///
/// Se muestra DESPUÉS de las fichas de teoría escrita y ANTES de los
/// ejercicios (ver `AcademyController.isClosingExample`). Dos fuentes:
///
///  1. **Hardcoded N1** (`_byId`): los 4 guiones originales del piloto de
///     3 bloques, uno por subnivel de N1.
///  2. **Migración Pattern B** (via [AcademyTableScripts.migratedClosingFor]):
///     guiones legacy que antes se mostraban ANTES de la teoría y que ahora
///     se sirven en la posición de cierre, sin reescribir su contenido.
///
/// Para Pattern C/D: devuelve null hasta que se redacten los guiones nuevos
/// (Fases 2-4 de la migración pedagógica).
class AcademyClosingExamples {
  AcademyClosingExamples._();

  static TableLessonScript? forLesson(String sublevelCode) {
    final hardcoded = _byId[sublevelCode];
    if (hardcoded != null) return hardcoded;
    return AcademyTableScripts.migratedClosingFor(sublevelCode);
  }

  static bool has(String sublevelCode) => forLesson(sublevelCode) != null;

  static final Map<String, TableLessonScript> _byId = {
    '1.1': ClosingExampleLessons.objetivoYCartas(),
    '1.2': ClosingExampleLessons.ganarLaMano(),
    '1.3': ClosingExampleLessons.lasAcciones(),
    '1.4': ClosingExampleLessons.lasCuatroCalles(),
    ...N2ClosingExamples.byId,
    ...N3ClosingExamples.byId,
    ...N4ClosingExamples.byId,
    ...N5ClosingExamples.byId,
    ...N6ClosingExamples.byId,
    ...N7ClosingExamples.byId,
    ...N8ClosingExamples.byId,
    ...N9ClosingExamples.byId,
    ...N10ClosingExamples.byId,
    ...N11ClosingExamples.byId,
    ...N12ClosingExamples.byId,
    ...N13ClosingExamples.byId,
  };
}
