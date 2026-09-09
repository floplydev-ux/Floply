import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../engine/academy/academy_store.dart';
import '../engine/concepts/concept_registry.dart';

/// Guarda el progreso de la Academia en un archivo JSON dentro del
/// directorio de documentos de la app. Sin dependencias nuevas
/// (`path_provider` ya estaba en `pubspec.yaml`).
class FileAcademyStore implements AcademyStore {
  FileAcademyStore({this.fileName = 'academy_progress.json'});

  final String fileName;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  @override
  Future<AcademySaveData?> load(ConceptRegistry registry) async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return AcademySaveData.decode(registry, await file.readAsString());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(AcademySaveData data) async {
    final file = await _file();
    await file.writeAsString(data.encode(), flush: true);
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {/* nada que borrar */}
  }
}
