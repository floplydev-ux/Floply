import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../services/economy/coins_economy_state.dart';

/// Persistencia de [CoinsEconomyState] — mismo mecanismo de archivo JSON en
/// disco que ya usan `FileProfileStore`/`FileAuthFlagStore`
/// (deliberadamente sin `shared_preferences`, ver esos archivos): no hace
/// falta una dependencia nueva para un blob de estado tan chico. El mismo
/// patrón funciona sin cambios en Web (`dart:io` compila pero cualquier
/// operación real de archivo falla — el try/catch de abajo lo cubre,
/// degradando a "no persistido" en vez de romper la app).
abstract class CoinsEconomyStore {
  Future<CoinsEconomyState?> load();
  Future<void> save(CoinsEconomyState state);
}

class FileCoinsEconomyStore implements CoinsEconomyStore {
  FileCoinsEconomyStore({this.fileName = 'floply_coins_economy.json'});

  final String fileName;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  @override
  Future<CoinsEconomyState?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      return CoinsEconomyState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(CoinsEconomyState state) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {
      // best-effort: igual que `FileAuthFlagStore` — si no se puede
      // persistir, la app sigue funcionando con el estado en memoria.
    }
  }
}

/// Para tests: mismo patrón que `InMemoryProfileStore`.
class InMemoryCoinsEconomyStore implements CoinsEconomyStore {
  CoinsEconomyState? _state;

  @override
  Future<CoinsEconomyState?> load() async => _state;

  @override
  Future<void> save(CoinsEconomyState state) async => _state = state;
}
