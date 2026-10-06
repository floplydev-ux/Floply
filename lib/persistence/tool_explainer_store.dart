import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Preferencia "no volver a mostrar la explicación" de cada Tool (Grupo 3:
/// sistema de explicación contextual) — **por herramienta**, nunca una
/// sola preferencia global (Pot Odds y Blocker Explorer se recuerdan por
/// separado). Mismo mecanismo de archivo que ya usan
/// `FileAuthFlagStore`/`FileProfileStore` (nada de `shared_preferences`
/// nuevo para esto) — funciona sin conexión y sin Firebase, como pide la
/// sección 8: es un archivo JSON local, no una cuenta.
abstract class ToolExplainerStore {
  /// `true` si el usuario ya marcó "no volver a mostrar" para [toolId].
  Future<bool> isDismissed(String toolId);

  /// Guarda la preferencia de [toolId] — `true` para no volver a
  /// mostrarla sola, `false` para que vuelva a aparecer la próxima vez
  /// que se abra la herramienta.
  Future<void> setDismissed(String toolId, bool dismissed);
}

class FileToolExplainerStore implements ToolExplainerStore {
  FileToolExplainerStore({this.fileName = 'tool_explainers_dismissed.json'});

  final String fileName;
  Map<String, bool>? _cache;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<Map<String, bool>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final file = await _file();
      if (!await file.exists()) return _cache = {};
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _cache = raw.map((k, v) => MapEntry(k, v as bool));
    } catch (_) {
      return _cache = {};
    }
  }

  @override
  Future<bool> isDismissed(String toolId) async => (await _load())[toolId] ?? false;

  @override
  Future<void> setDismissed(String toolId, bool dismissed) async {
    final map = await _load();
    map[toolId] = dismissed;
    _cache = map;
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (_) {
      // best-effort — igual que el resto de la persistencia local.
    }
  }
}

/// Para tests: mismo patrón que `InMemoryAuthFlagStore`.
class InMemoryToolExplainerStore implements ToolExplainerStore {
  final Map<String, bool> _dismissed = {};

  @override
  Future<bool> isDismissed(String toolId) async => _dismissed[toolId] ?? false;

  @override
  Future<void> setDismissed(String toolId, bool dismissed) async {
    _dismissed[toolId] = dismissed;
  }
}

/// Instancia compartida por toda la app — un solo archivo en disco para
/// las 6 herramientas, cada una con su propia clave (`toolId`).
final ToolExplainerStore defaultToolExplainerStore = FileToolExplainerStore();
