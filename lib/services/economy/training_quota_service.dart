import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../persistence/training_quota_store.dart';
import 'training_quota_state.dart';

/// Fachada de la cuota diaria de entrenamientos gratuitos.
///
/// **Independiente de FLOPly Coins** (pedido explícito de Fase 1): esta
/// clase no sabe nada de [FloplyCoinsService] ni viceversa — son dos
/// recursos distintos con reglas distintas (por día calendario vs. por
/// tiempo continuo). Esta clase solo sabe "cuántos gratuitos quedan hoy";
/// la conexión real (Fase 2: el entrenamiento extra, más allá de este
/// cupo, consume Coins por tiempo) vive un nivel más arriba, en
/// `EconomyAccessService` — nunca acá, para no romper esta independencia.
///
/// Mismo patrón de orquestación que [FloplyCoinsService]: la aritmética
/// real vive en [TrainingQuotaState] (inmutable), esta clase mantiene el
/// estado vigente, lo sincroniza contra el reloj real, lo persiste
/// best-effort y notifica a quien escuche.
class TrainingQuotaService extends ChangeNotifier {
  TrainingQuotaService({TrainingQuotaStore? store, DateTime Function()? clock})
      : _store = store ?? FileTrainingQuotaStore(),
        _clock = clock ?? DateTime.now {
    _state = TrainingQuotaState.initial(_clock());
  }

  final TrainingQuotaStore _store;
  final DateTime Function() _clock;
  late TrainingQuotaState _state;

  bool loading = true;

  Future<void> load() async {
    try {
      final saved = await _store.load();
      if (saved != null) _state = saved;
    } catch (_) {
      // best-effort: sin persistencia disponible, arranca con la cuota
      // completa de hoy.
    }
    _state = _state.advanced(_clock());
    loading = false;
    notifyListeners();
    unawaited(_persist());
  }

  int get remaining => _live.remaining;

  bool get hasFreeTrainingLeft => remaining > 0;

  DateTime get resetDate => _live.resetDate;

  TrainingQuotaState get _live => _state.advanced(_clock());

  /// Consume 1 entrenamiento gratuito de hoy. Devuelve `false` (sin
  /// consumir nada) si ya estaba en 0 — el caller decide qué hacer en ese
  /// caso (Fase 2: ofrecer Coins o publicidad; esta fase no lo conecta).
  Future<bool> consumeTraining() async {
    final before = _live;
    if (before.remaining <= 0) {
      _state = before;
      notifyListeners();
      return false;
    }
    _state = before.consuming();
    notifyListeners();
    await _persist();
    return true;
  }

  Future<void> _persist() async {
    try {
      await _store.save(_state);
    } catch (_) {
      // best-effort.
    }
  }
}
