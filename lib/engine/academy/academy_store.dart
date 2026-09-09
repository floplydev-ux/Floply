import 'dart:convert';

import '../concepts/concept_registry.dart';
import '../concepts/user_knowledge.dart';
import 'academy_progress.dart';

/// El estado persistente completo de un usuario de la Academia: su dominio
/// por concepto ([UserKnowledge]) más su progreso de recorrido
/// ([AcademyProgress]).
class AcademySaveData {
  const AcademySaveData({required this.knowledge, required this.progress});

  final UserKnowledge knowledge;
  final AcademyProgress progress;

  /// Serializa reutilizando `UserKnowledge.toJson` (sin base de datos).
  Map<String, dynamic> toJson() => {
        'version': 1,
        'knowledge': knowledge.toJson(),
        'academy': progress.toJson(),
      };

  static AcademySaveData fromJson(
    ConceptRegistry registry,
    Map<String, dynamic> json,
  ) {
    return AcademySaveData(
      knowledge: UserKnowledge.fromJson(
        registry,
        (json['knowledge'] as Map).cast<String, dynamic>(),
      ),
      progress: AcademyProgress.fromJson(
        (json['academy'] as Map? ?? {}).cast<String, dynamic>(),
      ),
    );
  }

  String encode() => jsonEncode(toJson());

  static AcademySaveData? decode(ConceptRegistry registry, String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return fromJson(registry, map);
    } catch (_) {
      return null;
    }
  }
}

/// Persistencia local del progreso de la Academia. Sin backend, sin login.
abstract class AcademyStore {
  Future<AcademySaveData?> load(ConceptRegistry registry);

  Future<void> save(AcademySaveData data);

  Future<void> clear();
}

/// Implementación en memoria: para tests y para correr sin disco.
class InMemoryAcademyStore implements AcademyStore {
  InMemoryAcademyStore([this._raw]);

  String? _raw;

  @override
  Future<AcademySaveData?> load(ConceptRegistry registry) async =>
      AcademySaveData.decode(registry, _raw);

  @override
  Future<void> save(AcademySaveData data) async {
    _raw = data.encode();
  }

  @override
  Future<void> clear() async {
    _raw = null;
  }
}
