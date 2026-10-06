import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../engine/strategy/saved_range.dart';

/// Persistencia de "Mis Rangos" (sección 20 del pedido de Rangos) — mismo
/// patrón que `FileToolExplainerStore`/`FileProfileStore`: un único
/// archivo JSON local vía `path_provider`, nada de `shared_preferences`
/// (decisión ya tomada en el proyecto), funciona sin conexión y sin
/// Firebase.
abstract class SavedRangeStore {
  Future<List<SavedRange>> loadAll();
  Future<void> saveAll(List<SavedRange> ranges);
}

class FileSavedRangeStore implements SavedRangeStore {
  FileSavedRangeStore({this.fileName = 'saved_ranges.json'});

  final String fileName;
  List<SavedRange>? _cache;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  @override
  Future<List<SavedRange>> loadAll() async {
    final cached = _cache;
    if (cached != null) return List.unmodifiable(cached);
    try {
      final file = await _file();
      if (!await file.exists()) return _cache = [];
      final raw = jsonDecode(await file.readAsString()) as List;
      return _cache = [
        for (final entry in raw) SavedRange.fromJson(entry as Map<String, dynamic>),
      ];
    } catch (_) {
      return _cache = [];
    }
  }

  @override
  Future<void> saveAll(List<SavedRange> ranges) async {
    _cache = List.of(ranges);
    try {
      final file = await _file();
      final raw = jsonEncode([for (final r in ranges) r.toJson()]);
      await file.writeAsString(raw, flush: true);
    } catch (_) {
      // best-effort — igual que el resto de la persistencia local.
    }
  }
}

/// Para tests: mismo patrón que `InMemoryToolExplainerStore`.
class InMemorySavedRangeStore implements SavedRangeStore {
  final List<SavedRange> _ranges = [];

  @override
  Future<List<SavedRange>> loadAll() async => List.unmodifiable(_ranges);

  @override
  Future<void> saveAll(List<SavedRange> ranges) async {
    _ranges
      ..clear()
      ..addAll(ranges);
  }
}

/// Instancia compartida por toda la app.
final SavedRangeStore defaultSavedRangeStore = FileSavedRangeStore();
