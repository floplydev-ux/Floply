/// El estado de la cuota diaria de entrenamientos gratuitos —
/// independiente de FLOPly Coins (ver el doc-comment de
/// [TrainingQuotaService]). Inmutable, sin IO: cada método devuelve un
/// [TrainingQuotaState] nuevo.
class TrainingQuotaState {
  const TrainingQuotaState({required this.remaining, required this.resetDate});

  /// Entrenamientos gratuitos que se otorgan al comenzar cada día
  /// calendario.
  static const int dailyFreeTrainings = 5;

  final int remaining;

  /// La fecha calendario (sin hora — ver [_dateOnly]) del último
  /// restablecimiento aplicado. Comparar fechas, nunca "han pasado 24hs":
  /// el pedido es explícito en que esto es por día calendario, no por
  /// ventana de tiempo.
  final DateTime resetDate;

  factory TrainingQuotaState.initial(DateTime now) => TrainingQuotaState(
        remaining: dailyFreeTrainings,
        resetDate: _dateOnly(now),
      );

  static DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Si [now] cae en un día calendario distinto al de [resetDate],
  /// restablece a [dailyFreeTrainings] — nunca acumula lo no usado de días
  /// anteriores, y nunca depende de que hayan pasado 24 horas exactas
  /// (cruzar la medianoche alcanza). `now` usa la hora LOCAL del
  /// dispositivo (mismo criterio que el resto de la app: no hay ninguna
  /// noción de zona horaria propia todavía).
  TrainingQuotaState advanced(DateTime now) {
    final today = _dateOnly(now);
    if (today.isAtSameMomentAs(resetDate)) return this;
    return TrainingQuotaState(remaining: dailyFreeTrainings, resetDate: today);
  }

  /// Consume 1 entrenamiento — no-op si ya está en 0 (nunca negativo).
  /// Asume que `this` ya está al día (llamar [advanced] antes).
  TrainingQuotaState consuming() =>
      remaining <= 0 ? this : TrainingQuotaState(remaining: remaining - 1, resetDate: resetDate);

  Map<String, dynamic> toJson() => {
        'remaining': remaining,
        'resetDate': resetDate.toIso8601String(),
      };

  factory TrainingQuotaState.fromJson(Map<String, dynamic> json) => TrainingQuotaState(
        remaining: json['remaining'] as int,
        resetDate: DateTime.parse(json['resetDate'] as String),
      );
}
