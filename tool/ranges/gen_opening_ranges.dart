// Genera lib/engine/strategy/opening_ranges_data.g.dart a partir de
// assets/ranges/opening_ranges.json — mismo patrón que
// tool/curriculum/gen_curriculum.py usa para el currículo: el JSON es
// la fuente de verdad legible/editable, el .g.dart es lo que el motor
// carga en tiempo de compilación (sin I/O asíncrono en el camino
// caliente de OpeningRanges, que hoy se llama de forma síncrona desde
// StrategyEngine/OpponentPolicy/PreflopStrategy).
//
// Correr con: dart run tool/ranges/gen_opening_ranges.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final jsonFile = File('assets/ranges/opening_ranges.json');
  final data = jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
  final posiciones = data['posiciones'] as Map<String, dynamic>;

  final tokensEntries = <String>[];
  final sizingEntries = <String>[];
  final boundsEntries = <String>[];

  for (final entry in posiciones.entries) {
    final position = entry.key;
    final value = entry.value as Map<String, dynamic>;
    final tokens = (value['tokens'] as List).cast<String>();
    final sizingBb = (value['sizingBb'] as num).toDouble();
    final bounds = value['sizingRazonable'] as Map<String, dynamic>;
    final min = (bounds['min'] as num).toDouble();
    final max = (bounds['max'] as num).toDouble();

    final tokenList = tokens.map((t) => "'${t.replaceAll("'", "\\'")}'").join(', ');
    tokensEntries.add("  '$position': [$tokenList],");
    sizingEntries.add("  '$position': $sizingBb,");
    boundsEntries.add("  '$position': ($min, $max),");
  }

  final buffer = StringBuffer()
    ..writeln('// GENERADO por tool/ranges/gen_opening_ranges.dart — NO editar a mano.')
    ..writeln('// Fuente de verdad: assets/ranges/opening_ranges.json')
    ..writeln('// Regenerar tras cambiar el JSON: dart run tool/ranges/gen_opening_ranges.dart')
    ..writeln('//')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln('/// Tokens de rango (notación `HandRange.parse`) por posición, tal cual')
    ..writeln('/// vienen del JSON — clave = `Position.name` (`utg`, `hj`, `co`, `btn`, `sb`).')
    ..writeln('const Map<String, List<String>> kOpeningRangeTokens = {')
    ..writeAll(tokensEntries, '\n')
    ..writeln()
    ..writeln('};')
    ..writeln()
    ..writeln('/// Tamaño de apertura estándar (BB) por posición.')
    ..writeln('const Map<String, double> kOpeningRangeSizingBb = {')
    ..writeAll(sizingEntries, '\n')
    ..writeln()
    ..writeln('};')
    ..writeln()
    ..writeln('/// Rango de tamaños defendibles (min, max) en BB, por posición.')
    ..writeln('const Map<String, (double, double)> kOpeningRangeSizingBounds = {')
    ..writeAll(boundsEntries, '\n')
    ..writeln()
    ..writeln('};');

  final outFile = File('lib/engine/strategy/opening_ranges_data.g.dart');
  outFile.writeAsStringSync(buffer.toString());
  // ignore: avoid_print
  print('Escrito ${outFile.path} (${posiciones.length} posiciones).');
}
