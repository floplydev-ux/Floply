import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// El nombre y la foto de perfil de un usuario **invitado** (sin cuenta):
/// no hay `FloplyUser`/Firestore para guardarlos, así que viven acá, en
/// disco — mismo mecanismo de archivo que ya usa `FileAuthFlagStore`
/// (deliberadamente sin `shared_preferences`, ver ese archivo). Un usuario
/// autenticado NO usa esta clase: su nombre/foto se editan sobre su propio
/// `FloplyUser` (`AuthController`), que ya persiste en Firestore.
class LocalProfile {
  const LocalProfile({this.displayName, this.avatarPath});

  final String? displayName;

  /// Ruta absoluta a un archivo de imagen en el disco del dispositivo
  /// (nunca una URL de red) — ver `UserAvatar`.
  final String? avatarPath;

  LocalProfile copyWith({String? displayName, String? avatarPath}) {
    return LocalProfile(
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'avatarPath': avatarPath,
      };

  factory LocalProfile.fromJson(Map<String, dynamic> json) => LocalProfile(
        displayName: json['displayName'] as String?,
        avatarPath: json['avatarPath'] as String?,
      );
}

abstract class ProfileStore {
  Future<LocalProfile> load();
  Future<void> save(LocalProfile profile);
}

class FileProfileStore implements ProfileStore {
  FileProfileStore({this.fileName = 'local_profile.json'});

  final String fileName;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  @override
  Future<LocalProfile> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const LocalProfile();
      final raw = await file.readAsString();
      return LocalProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const LocalProfile();
    }
  }

  @override
  Future<void> save(LocalProfile profile) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(profile.toJson()), flush: true);
    } catch (_) {
      // best-effort: igual que `FileAuthFlagStore`, si no se puede
      // persistir la app sigue funcionando con el valor en memoria.
    }
  }
}

/// Para tests: mismo patrón que `InMemoryAuthFlagStore`.
class InMemoryProfileStore implements ProfileStore {
  LocalProfile _profile = const LocalProfile();

  @override
  Future<LocalProfile> load() async => _profile;

  @override
  Future<void> save(LocalProfile profile) async => _profile = profile;
}
