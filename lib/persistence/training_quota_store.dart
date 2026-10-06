import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../services/economy/training_quota_state.dart';

/// Persistencia de [TrainingQuotaState] — mismo mecanismo de archivo JSON
/// que [CoinsEconomyStore] (`coins_economy_store.dart`) y el resto de
/// `lib/persistence/`. Ver el doc-comment de ese archivo para por qué no
/// hay `shared_preferences` de por medio.
abstract class TrainingQuotaStore {
  Future<TrainingQuotaState?> load();
  Future<void> save(TrainingQuotaState state);
}

class FileTrainingQuotaStore implements TrainingQuotaStore {
  FileTrainingQuotaStore({this.fileName = 'floply_training_quota.json'});

  final String fileName;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  @override
  Future<TrainingQuotaState?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      return TrainingQuotaState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(TrainingQuotaState state) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {
      // best-effort — ver `FileCoinsEconomyStore.save`.
    }
  }
}

/// Para tests.
class InMemoryTrainingQuotaStore implements TrainingQuotaStore {
  TrainingQuotaState? _state;

  @override
  Future<TrainingQuotaState?> load() async => _state;

  @override
  Future<void> save(TrainingQuotaState state) async => _state = state;
}
