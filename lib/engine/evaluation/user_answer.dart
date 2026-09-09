/// La respuesta cruda del usuario a un ejercicio.
///
/// Separa la *decisión* (qué opción eligió) del *razonamiento* (qué
/// conceptos dice que la justifican), para poder evaluarlos por separado.
class UserAnswer {
  const UserAnswer({
    required this.exerciseId,
    this.selectedOptionId,
    this.selectedOptionIds = const [],
    this.reasoningConceptIds = const [],
    this.orderedOptionIds = const [],
    this.numericValue,
  });

  final String exerciseId;

  /// Opción elegida (ejercicios de una sola respuesta).
  final String? selectedOptionId;

  /// Opciones elegidas (ejercicios de selección múltiple).
  final List<String> selectedOptionIds;

  /// Conceptos que el usuario marcó como "por esto elegí esta acción".
  final List<String> reasoningConceptIds;

  /// Orden propuesto (ejercicios de ordenar).
  final List<String> orderedOptionIds;

  /// Valor numérico (ejercicios de cálculo).
  final double? numericValue;

  List<String> get allSelectedIds => [
        if (selectedOptionId != null) selectedOptionId!,
        ...selectedOptionIds,
      ];
}
