import '../poker/position.dart';
import 'hand_range.dart';
import 'range_context.dart';

/// Un rango propio guardado por el usuario (sección 16/20 del pedido de
/// Rangos) — separado a propósito de los rangos oficiales de FLOPly
/// (`OpeningRanges`), que nunca se guardan como `SavedRange`: "oficial"
/// y "propio" son dos espacios distintos (sección 18), nunca se mezclan
/// en el mismo storage.
class SavedRange {
  const SavedRange({
    required this.id,
    required this.name,
    required this.frequencies,
    required this.createdAt,
    required this.updatedAt,
    this.position,
    this.situation,
    this.basedOnOfficialId,
  });

  final String id;
  final String name;

  /// Mismo formato que `HandRange.frequencies` — notación → frecuencia
  /// (0..1). Se guarda tal cual, sin reinventar una serialización propia
  /// de rangos.
  final Map<String, double> frequencies;

  /// Contexto de referencia (opcional: un rango propio puede no mapear a
  /// ninguna posición/situación real, p. ej. uno armado desde cero).
  final Position? position;
  final RangeSituation? situation;

  /// Si este rango nació duplicando un oficial, qué posición era (p. ej.
  /// `'btn'`) — para poder mostrar "editado a partir de BTN Open" en vez
  /// de presentarlo como si fuera oficial (sección 18).
  final String? basedOnOfficialId;

  final DateTime createdAt;
  final DateTime updatedAt;

  HandRange toHandRange() => HandRange(Map<String, double>.from(frequencies));

  SavedRange copyWith({
    String? id,
    String? name,
    Map<String, double>? frequencies,
    DateTime? updatedAt,
  }) =>
      SavedRange(
        id: id ?? this.id,
        name: name ?? this.name,
        frequencies: frequencies ?? this.frequencies,
        position: position,
        situation: situation,
        basedOnOfficialId: basedOnOfficialId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'frequencies': frequencies,
        'position': position?.name,
        'situation': situation?.name,
        'basedOnOfficialId': basedOnOfficialId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SavedRange.fromJson(Map<String, dynamic> json) => SavedRange(
        id: json['id'] as String,
        name: json['name'] as String,
        frequencies: (json['frequencies'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
        position: _positionByName(json['position'] as String?),
        situation: _situationByName(json['situation'] as String?),
        basedOnOfficialId: json['basedOnOfficialId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static Position? _positionByName(String? name) {
    if (name == null) return null;
    for (final p in Position.values) {
      if (p.name == name) return p;
    }
    return null;
  }

  static RangeSituation? _situationByName(String? name) {
    if (name == null) return null;
    for (final s in RangeSituation.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}
