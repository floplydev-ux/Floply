import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Un único flag local: "el usuario ya eligió explícitamente continuar
/// sin cuenta". Sin esto, `AuthGate` volvería a mostrar la pantalla de
/// login en cada apertura de un usuario invitado (Fase 11 lo prohíbe
/// explícitamente). Deliberadamente no se usa `shared_preferences`: no
/// hace falta una dependencia nueva para un solo booleano — se reutiliza
/// el mismo mecanismo de archivo que ya usa `FileAcademyStore`.
abstract class AuthFlagStore {
  Future<bool> isGuestModeChosen();
  Future<void> setGuestModeChosen(bool value);
}

class FileAuthFlagStore implements AuthFlagStore {
  FileAuthFlagStore({this.fileName = 'guest_mode.flag'});

  final String fileName;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  @override
  Future<bool> isGuestModeChosen() async {
    try {
      final file = await _file();
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setGuestModeChosen(bool value) async {
    try {
      final file = await _file();
      if (value) {
        await file.writeAsString('1', flush: true);
      } else if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // best-effort: si no se puede persistir, la app sigue funcionando,
      // solo puede volver a preguntar en el próximo arranque.
    }
  }
}

/// Para tests / web: mismo patrón que `InMemoryAcademyStore`.
class InMemoryAuthFlagStore implements AuthFlagStore {
  bool _chosen = false;

  @override
  Future<bool> isGuestModeChosen() async => _chosen;

  @override
  Future<void> setGuestModeChosen(bool value) async => _chosen = value;
}
