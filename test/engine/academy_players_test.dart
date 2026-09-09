import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/pedagogy/academy_players.dart';
import 'package:poker_trainer/engine/pedagogy/academy_table_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/academy_exercise_scripts.dart';
import 'package:poker_trainer/engine/pedagogy/table_lesson.dart';

void main() {
  test('el elenco no tiene nombres genéricos ni "Hero" / "Villain"', () {
    for (final p in AcademyPlayers.roster) {
      expect(p.name.trim(), isNotEmpty);
      expect(p.avatarId, inInclusiveRange(0, 9));
      final lower = p.name.toLowerCase();
      expect(lower, isNot(anyOf('hero', 'villain', 'villano', 'opponent')));
      expect(RegExp(r'player ?\d', caseSensitive: false).hasMatch(lower),
          isFalse);
    }
    expect(AcademyPlayers.roster.map((p) => p.name).toSet().length,
        AcademyPlayers.roster.length,
        reason: 'nombres repetidos');
  });

  test('pick() es determinista y sin repetidos', () {
    final a = AcademyPlayers.pick(1234, 5).map((p) => p.name).toList();
    final b = AcademyPlayers.pick(1234, 5).map((p) => p.name).toList();
    expect(a, b);
    expect(a.toSet().length, 5);
    // Semillas distintas → (casi siempre) elencos distintos.
    final c = AcademyPlayers.pick(9999, 5).map((p) => p.name).toList();
    expect(a, isNot(equals(c)));
  });

  test('seedFor es estable por lessonId', () {
    expect(AcademyPlayers.seedFor('2.1'), AcademyPlayers.seedFor('2.1'));
    expect(AcademyPlayers.seedFor('2.1'),
        isNot(AcademyPlayers.seedFor('2.2')));
  });

  test('withCast: el usuario usa su nombre; los rivales, el elenco', () {
    // Tomo una mesa de un guion real.
    final step = AcademyTableScripts.forLesson('3.1')!.steps.first;
    final cast = step.table.withCast('Juan', AcademyPlayers.seedFor('3.1'));

    final hero = cast.seats.firstWhere((s) => s.isHero);
    expect(hero.name, 'Juan');

    final npcs = cast.seats.where((s) => !s.isHero && !s.empty);
    for (final s in npcs) {
      expect(AcademyPlayers.names.contains(s.name), isTrue,
          reason: '"${s.name}" no está en el elenco');
      expect(s.avatarId, isNotNull);
      // Nunca un nombre-placeholder.
      expect(s.name!.toLowerCase(),
          isNot(anyOf('hero', 'villain', 'tú', 'vos')));
    }
    // Sin nombres repetidos en la mesa.
    final names = cast.seats
        .where((s) => !s.empty)
        .map((s) => s.name)
        .toList();
    expect(names.toSet().length, names.length);
  });

  test('withCast en TODOS los guiones (teoría y ejercicios) resuelve '
      'nombres sin romperse', () {
    void checkTable(TableSnapshot t, int seed) {
      final cast = t.withCast('Juan', seed);
      expect(cast.seats.where((s) => s.isHero).length, 1);
      for (final s in cast.seats.where((s) => !s.empty)) {
        expect(s.name, isNotNull);
      }
    }

    for (final e in AcademyTableScripts.all.entries) {
      final seed = AcademyPlayers.seedFor(e.key);
      for (final step in e.value.steps) {
        checkTable(step.table, seed);
        // resolver la burbuja no debe dejar marcadores.
        final resolved = resolveTableText(step.bubble, step.table.withCast('Juan', seed));
        expect(resolved.contains(RegExp(r'\{[A-Za-z]+\}')), isFalse,
            reason: '${e.key}: quedó un marcador sin resolver → $resolved');
      }
    }
    for (final e in AcademyExerciseScripts.all.entries) {
      final seed = AcademyPlayers.seedFor(e.key);
      for (final ex in e.value.exercises) {
        for (final t in [ex.situation, ex.afterDecision]) {
          if (t != null) checkTable(t, seed);
        }
        final cast = ex.situation.withCast('Juan', seed);
        for (final raw in [
          ex.question,
          for (final ch in ex.choices) ...[ch.label, ch.feedback],
          for (final st in ex.explanation) st.text,
        ]) {
          final r = resolveTableText(raw, cast);
          expect(r.contains(RegExp(r'\{[A-Za-z]+\}')), isFalse,
              reason: '${e.key}: marcador sin resolver → $r');
        }
      }
    }
  });
}
