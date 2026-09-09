import 'exercise.dart';

/// La "huella" de un ejercicio: lo mínimo para comparar si dos ejercicios
/// se parecen demasiado (anti-memorización).
class ExerciseSignature {
  ExerciseSignature({
    required this.templateId,
    required this.type,
    required this.targetConcept,
    required this.difficulty,
    required this.position,
    required this.handClass,
    required this.handNotation,
    required this.stackBucket,
    required this.correctActionLabel,
    required this.variantKey,
  });

  final String templateId;
  final ExerciseType type;
  final String targetConcept;
  final int difficulty;
  final String? position;

  /// `pair` / `suited` / `offsuit` / `null`.
  final String? handClass;

  /// Notación exacta de la mano (`AKs`), para detectar repetición literal.
  final String? handNotation;

  /// Bucket de stack: `short` / `100bb` / `deep` / `null`.
  final String? stackBucket;

  final String? correctActionLabel;

  /// Identidad "de contenido" del ejercicio: mismo template + mismas
  /// variables clave (posición(es), mano(s), respuesta correcta) => misma
  /// pregunta aunque cambie el texto.
  final String variantKey;

  factory ExerciseSignature.of(Exercise exercise) {
    final situation = exercise.situation;
    final hero = situation?.heroCards;
    String? handClass;
    if (hero != null) {
      handClass = hero.isPair
          ? 'pair'
          : hero.isSuited
              ? 'suited'
              : 'offsuit';
    }
    String? stackBucket;
    final stack = situation?.effectiveStackBb;
    if (stack != null) {
      stackBucket = stack < 40
          ? 'short'
          : stack <= 120
              ? '100bb'
              : 'deep';
    }
    return ExerciseSignature(
      templateId: exercise.templateId,
      type: exercise.type,
      targetConcept: exercise.evaluatedConcepts.isNotEmpty
          ? exercise.evaluatedConcepts.first
          : exercise.templateId,
      difficulty: exercise.difficulty,
      position: situation?.heroPosition.abbreviation,
      handClass: handClass,
      handNotation: hero?.notation,
      stackBucket: stackBucket,
      correctActionLabel: exercise.strategy.primary.action.label,
      variantKey: _variantKey(exercise),
    );
  }

  static String _variantKey(Exercise exercise) {
    final parts = <String>[exercise.templateId];
    final meta = exercise.meta;
    for (final key in meta.keys.toList()..sort()) {
      final value = meta[key];
      if (value is List) {
        final sorted = value.map((e) => '$e').toList()..sort();
        parts.add('$key=$sorted');
      } else {
        parts.add('$key=$value');
      }
    }
    if (exercise.correctValue != null) {
      parts.add('ans=${exercise.correctValue}');
    }
    return parts.join('|');
  }

  /// Similitud 0..1 con otra huella. 1.0 = prácticamente el mismo
  /// ejercicio.
  double similarityTo(ExerciseSignature other) {
    // Mismo contenido exacto: es la misma pregunta.
    if (variantKey == other.variantKey) return 1.0;

    if (handNotation != null && handNotation == other.handNotation) {
      // Misma mano exacta: alta similitud aunque cambie algo más.
      var s = 0.55;
      if (templateId == other.templateId) s += 0.2;
      if (position == other.position) s += 0.15;
      if (difficulty == other.difficulty) s += 0.1;
      return s.clamp(0.0, 1.0);
    }

    var score = 0.0;
    if (templateId == other.templateId) score += 0.35;
    if (type == other.type) score += 0.1;
    if (position != null && position == other.position) score += 0.2;
    if (handClass != null && handClass == other.handClass) score += 0.1;
    if (stackBucket != null && stackBucket == other.stackBucket) score += 0.1;
    if (correctActionLabel != null &&
        correctActionLabel == other.correctActionLabel) {
      score += 0.1;
    }
    if (difficulty == other.difficulty) score += 0.05;
    return score.clamp(0.0, 1.0);
  }
}

/// Guarda las huellas recientes y sabe decir si un ejercicio nuevo es
/// demasiado parecido a los últimos.
class ExerciseHistory {
  ExerciseHistory({this.capacity = 25});

  final int capacity;
  final List<ExerciseSignature> _recent = [];

  List<ExerciseSignature> get recent => List.unmodifiable(_recent);

  int get length => _recent.length;

  void record(Exercise exercise) => recordSignature(ExerciseSignature.of(exercise));

  void recordSignature(ExerciseSignature signature) {
    _recent.add(signature);
    if (_recent.length > capacity) {
      _recent.removeRange(0, _recent.length - capacity);
    }
  }

  void clear() => _recent.clear();

  /// Máxima similitud del candidato contra las últimas [lookback] huellas.
  double maxSimilarity(ExerciseSignature candidate, {int lookback = 6}) {
    if (_recent.isEmpty) return 0.0;
    final start = _recent.length - lookback;
    final window = _recent.sublist(start < 0 ? 0 : start);
    var max = 0.0;
    for (final sig in window) {
      final s = candidate.similarityTo(sig);
      if (s > max) max = s;
    }
    return max;
  }

  /// ¿El candidato repite exactamente una mano usada hace poco?
  bool repeatsRecentHand(ExerciseSignature candidate, {int lookback = 12}) {
    if (candidate.handNotation == null) return false;
    final start = _recent.length - lookback;
    final window = _recent.sublist(start < 0 ? 0 : start);
    return window.any((s) =>
        s.handNotation == candidate.handNotation &&
        s.templateId == candidate.templateId);
  }

  bool isTooSimilar(
    ExerciseSignature candidate, {
    double threshold = 0.8,
    int lookback = 6,
  }) {
    if (repeatsRecentHand(candidate)) return true;
    return maxSimilarity(candidate, lookback: lookback) >= threshold;
  }
}
