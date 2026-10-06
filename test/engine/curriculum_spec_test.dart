import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/theory.dart';

void main() {
  final spec = CurriculumSpec.standard();

  test('carga: 13 niveles · 64 subniveles · 326 teorías', () {
    expect(spec.levels.length, 13);
    expect(spec.allSublevels.length, 64);
    expect(spec.theoryCount, 326);
    expect(spec.meta['total_teorias'], 326);
  });

  test('los 308 temas del documento maestro aparecen exactamente una vez', () {
    final numeros = <int, int>{};
    for (final t in spec.allTheories) {
      if (t.numeroCurriculo != null) {
        numeros[t.numeroCurriculo!] = (numeros[t.numeroCurriculo!] ?? 0) + 1;
      }
    }
    for (var i = 1; i <= 308; i++) {
      expect(numeros[i], 1, reason: 'tema $i');
    }
    expect(numeros.length, 308);
  });

  test('18 teorías nuevas, ninguna con número de currículo', () {
    final nuevas = spec.allTheories.where((t) => t.esNueva).toList();
    expect(nuevas.length, 18);
    expect(nuevas.every((t) => t.numeroCurriculo == null), isTrue);
    expect(nuevas.every((t) => t.id.startsWith('TN')), isTrue);
  });

  test('ids únicos y numeración global contigua 1..326', () {
    final ids = spec.allTheories.map((t) => t.id).toSet();
    expect(ids.length, 326);
    final orden = spec.allTheories.map((t) => t.ordenGlobal).toList()..sort();
    expect(orden, List.generate(326, (i) => i + 1));
  });

  test('validate(): sin errores', () {
    final issues = spec.validate();
    final errors = issues.where((i) => i.severity == 'error').toList();
    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('ningún prerrequisito apunta hacia adelante (DAG lineal-compatible)', () {
    final pos = {for (final t in spec.allTheories) t.id: t.ordenGlobal};
    for (final t in spec.allTheories) {
      for (final p in t.prerrequisitos) {
        expect(pos.containsKey(p), isTrue, reason: '${t.id} → $p inexistente');
        expect(pos[p]! < t.ordenGlobal, isTrue,
            reason: '${t.id} (${pos[t.id]}) depende de $p (${pos[p]})');
      }
    }
  });

  test('prerrequisitos transitivos: cerrados y acíclicos', () {
    for (final t in spec.allTheories) {
      final all = spec.allPrerequisitesOf(t.id);
      expect(all.contains(t.id), isFalse, reason: 'ciclo en ${t.id}');
      for (final p in all) {
        expect(spec.theoryById(p), isNotNull);
      }
    }
  });

  test('curva de dificultad monótona por nivel', () {
    var prev = -1;
    for (final l in spec.levels) {
      expect(l.dificultad.order, greaterThanOrEqualTo(prev),
          reason: 'N${l.n} ${l.dificultad}');
      prev = l.dificultad.order;
    }
    expect(spec.levels.first.dificultad, Difficulty.fundamental);
    expect(spec.levels.last.dificultad, Difficulty.avanzado);
  });

  test('cada nivel tiene una capacidad y cada subnivel un objetivo', () {
    for (final l in spec.levels) {
      expect(l.capacidad.trim(), isNotEmpty, reason: 'N${l.n}');
      for (final s in l.sublevels) {
        expect(s.objetivo.trim(), isNotEmpty, reason: s.code);
        expect(s.theories, isNotEmpty, reason: s.code);
      }
    }
  });

  test('N12 «Integración» y N13 «Dominio de NL2» con identidad propia', () {
    expect(spec.theoriesOfLevel(12).length, 29);
    expect(spec.theoriesOfLevel(13).length, 41);
    expect(spec.levelByNumber(13)!.nombre, contains('NL2'));
    // el capstone: la última teoría del currículo es "La decisión integrada".
    final last = spec.allTheories.reduce(
        (a, b) => a.ordenGlobal > b.ordenGlobal ? a : b);
    expect(last.id, 'T308');
    expect(last.nivel, 13);
  });

  test('desbloqueo: lineal por defecto, cambiable a prerrequisitos', () {
    expect(spec.unlockMode, CurriculumUnlockMode.linear);

    final order = spec.allSublevels.map((s) => s.code).toList();
    // primer subnivel siempre abierto
    expect(spec.isSublevelUnlocked(order.first, {}), isTrue);
    // el segundo, no, hasta completar el primero
    expect(spec.isSublevelUnlocked(order[1], {}), isFalse);
    expect(spec.isSublevelUnlocked(order[1], {order.first}), isTrue);

    // modo prerrequisitos: un subnivel abre con sus prereqs de teoría dominados
    final s53 = spec.sublevelByCode('5.3')!;
    final needed = s53.theories.expand((t) => t.prerrequisitos).toSet();
    expect(
      spec.isSublevelUnlocked('5.3', const {},
          completedTheoryIds: needed, mode: CurriculumUnlockMode.prerequisites),
      isTrue,
    );
    expect(
      spec.isSublevelUnlocked('5.3', const {},
          completedTheoryIds: const {}, mode: CurriculumUnlockMode.prerequisites),
      isFalse,
    );
  });

  test('conceptos_clave: solo ids que existen hoy en el ConceptRegistry', () {
    const known = {
      'rules', 'hand_ranking', 'position_names', 'position_btn', 'position_co',
      'position_hj', 'position_utg', 'position_blinds', 'position_advantage',
      'opening_range', 'open_raise', 'open_sizing', 'range_width', 'bb_defense',
      'call', 'three_bet', 'three_bet_value', 'three_bet_bluff', 'pot_odds',
      'equity', 'outs', 'combos', 'ev', 'equity_realization', 'range_advantage',
      'nut_advantage', 'cbet', 'board_texture', 'value_bet', 'bluff',
      'bluff_catcher', 'blockers', 'overbet', 'polarization', 'gto',
      'mixed_strategies', 'exploit',
    };
    for (final t in spec.allTheories) {
      for (final c in t.conceptosClave) {
        expect(known.contains(c), isTrue, reason: '${t.id}: "$c"');
      }
    }
  });

  test('legacy: apunta a lecciones históricas reales (1.1..5.5)', () {
    final oldIds = {
      for (var a = 1; a <= 5; a++)
        for (var b = 1; b <= 5; b++) '$a.$b',
    };
    for (final s in spec.allSublevels) {
      final lg = s.legacy;
      if (lg == null) continue;
      for (final id in [
        ...lg.tableScripts,
        ...lg.exerciseSets,
        ...lg.textTheory,
        ...lg.practice,
        ...lg.checks,
      ]) {
        expect(oldIds.contains(id), isTrue, reason: '${s.code} → $id');
      }
    }
    // todo el contenido interactivo actual queda re-anclado
    final scripts = <String>{
      for (final s in spec.allSublevels)
        ...?s.legacy?.tableScripts,
    };
    expect(scripts, containsAll(['1.2', '2.1', '3.1', '3.3', '4.1', '5.1']));
    final sets = <String>{
      for (final s in spec.allSublevels) ...?s.legacy?.exerciseSets,
    };
    // Los viejos '1.1'/'1.3' (guiones de mesa) y '1.4'/'1.5' (sets de
    // ejercicios) ya no se re-anclan: 1.1, 1.2, 1.3 y 1.4 migraron al
    // piloto de 3 bloques con ejemplos/ejercicios propios en Dart puro
    // (`AcademyClosingExamples`/`N1PilotExercises`, sin legacy) — con las
    // 4 migradas no queda ningún subnivel nuevo que necesite mostrar ese
    // contenido histórico. Solo '1.2' sigue re-anclado (vía '3.4'/'3.5').
    expect(sets, containsAll(['2.1', '2.2', '2.3',
      '2.4', '2.5', '3.1', '3.2', '3.3', '3.4', '3.5', '5.4']));
  });

  test(
      'estado de redacción: PASO 4 completo — las 326 teorías '
      '(N1-N13) están "listo"', () {
    const redactados = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
    for (final n in redactados) {
      final ts = spec.theoriesOfLevel(n);
      expect(ts, isNotEmpty);
      expect(ts.every((t) => t.estadoRedaccion == WritingStatus.listo), isTrue,
          reason: 'N$n');
      expect(ts.every((t) => t.tieneContenido), isTrue, reason: 'N$n');
    }

    // No queda ningún nivel fuera de la lista: PASO 4 está completo.
    final resto =
        spec.allTheories.where((t) => !redactados.contains(t.nivel));
    expect(resto, isEmpty);
  });
}
