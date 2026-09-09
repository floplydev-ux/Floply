import 'dart:math';

/// Un personaje de la mesa de la Academia (un rival NPC).
///
/// Da vida a la mesa sin convertir la app en una historia: solo nombre +
/// avatar. Las "personalidades" quedan para más adelante.
class AcademyPlayer {
  const AcademyPlayer(this.name, this.avatarId);

  final String name;

  /// 0..9 — la UI lo mapea a un color/ícono. Reemplazable por
  /// ilustraciones sin tocar los scripts.
  final int avatarId;
}

/// Elenco de personajes de la Academia.
class AcademyPlayers {
  AcademyPlayers._();

  /// Nombres naturales y variados (no profesionales, no placeholders).
  static const List<AcademyPlayer> roster = [
    AcademyPlayer('Nico', 0),
    AcademyPlayer('Sofi', 1),
    AcademyPlayer('Mateo', 2),
    AcademyPlayer('Lara', 3),
    AcademyPlayer('Bruno', 4),
    AcademyPlayer('Valen', 5),
    AcademyPlayer('Tomi', 6),
    AcademyPlayer('Mica', 7),
    AcademyPlayer('Fran', 8),
    AcademyPlayer('Agus', 9),
  ];

  /// Nombres del elenco, derivados de [roster] (una sola fuente de verdad).
  static Set<String> get names => {for (final p in roster) p.name};

  /// Elige [count] personajes distintos de forma **determinista** a partir
  /// de [seed] (así una misma lección siempre muestra el mismo elenco, y
  /// lecciones distintas muestran elencos distintos).
  static List<AcademyPlayer> pick(int seed, int count) {
    final pool = List<AcademyPlayer>.of(roster)..shuffle(Random(seed));
    return pool.take(count.clamp(0, roster.length)).toList();
  }

  /// Seed estable a partir de un id de lección ("2.1").
  static int seedFor(String lessonId) {
    var h = 0;
    for (final c in lessonId.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }
}
