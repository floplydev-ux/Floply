import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/theory.dart';

/// PASO 4 — contenido redactado. Verifica que los niveles redactados
/// llegan tipados a los modelos desde el JSON maestro. Las 326 teorías
/// (N1-N13) quedaron redactadas — ver [[academia-paso4-redaccion]].
void main() {
  final spec = CurriculumSpec.standard();

  /// Niveles cuyo contenido ya está redactado. Las 326 teorías (N1-N13)
  /// están completas: no queda ningún nivel pendiente.
  const nivelesRedactados = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

  test('N1.2 quedó reordenado: showdown → ganar por cartas → ganar por fold',
      () {
    final orden = spec
        .theoriesOfSublevel('1.2')
        .map((t) => t.id)
        .toList();
    expect(orden, ['T008', 'T009', 'T010']);
  });

  test('T006 (ranking) se apoya en T008 (showdown), no en T010 (ganar por fold)',
      () {
    final prereqs = spec.theoryById('T006')!.prerrequisitos;
    expect(prereqs, contains('T008'));
    expect(prereqs, isNot(contains('T010')));
    // y sigue sin apuntar hacia adelante
    final pos = {for (final t in spec.allTheories) t.id: t.ordenGlobal};
    final t006pos = pos['T006']!;
    for (final p in prereqs) {
      expect(pos[p], lessThan(t006pos), reason: p);
    }
  });

  for (final n in nivelesRedactados) {
    group('N$n redactado', () {
      final teorias = spec.theoriesOfLevel(n);

      test('todas las teorías del nivel tienen contenido y estado "listo"', () {
        expect(teorias, isNotEmpty);
        for (final t in teorias) {
          expect(t.estadoRedaccion, WritingStatus.listo, reason: t.id);
          expect(t.tieneContenido, isTrue, reason: t.id);
        }
      });

      test('cada teoría tiene qué es + idea clave y al menos dos secciones '
          'de desarrollo', () {
        for (final t in teorias) {
          final c = t.contenido!;
          expect(c.queEs, isNotNull, reason: '${t.id} queEs');
          expect(c.ideaClave, isNotNull, reason: '${t.id} ideaClave');
          final desarrollo = [
            c.porQueImporta,
            c.comoFunciona,
            c.cuandoLoUso,
            c.ejemplo,
          ].where((s) => s != null).length;
          expect(desarrollo, greaterThanOrEqualTo(2), reason: t.id);
        }
      });

      test('todo subnivel tiene al menos una teoría redactada', () {
        for (final s in spec.levelByNumber(n)!.sublevels) {
          expect(s.theories.where((t) => t.tieneContenido), isNotEmpty,
              reason: s.code);
        }
      });

      test('sin pasos de mesa redactados todavía', () {
        for (final t in teorias) {
          expect(t.contenido!.pasosMesa, isEmpty, reason: t.id);
        }
      });
    });
  }

  test('el contenido llega como TheoryContent tipado (no como Map)', () {
    final t = spec.theoryById('T001')!;
    expect(t.contenido, isA<TheoryContent>());
    expect(t.contenido!.queEs, contains('bote'));
    expect(t.contenido!.isEmpty, isFalse);
  });

  test('no queda ningún nivel pendiente: las 326 teorías están redactadas',
      () {
    final resto = spec.allTheories
        .where((t) => !nivelesRedactados.contains(t.nivel));
    expect(resto, isEmpty);
    expect(spec.allTheories.every((t) => t.estadoRedaccion == WritingStatus.listo),
        isTrue);
    expect(spec.allTheories.every((t) => t.tieneContenido), isTrue);
  });

  test('conteo global de teorías redactadas', () {
    final esperado = [
      for (final n in nivelesRedactados) spec.theoriesOfLevel(n).length,
    ].fold<int>(0, (a, b) => a + b);
    final real = spec.allTheories.where((t) => t.tieneContenido).length;
    expect(real, esperado);
  });
}
