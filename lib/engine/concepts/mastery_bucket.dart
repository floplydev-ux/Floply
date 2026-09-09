import 'concept_registry.dart';
import 'user_concept_mastery.dart';
import 'user_knowledge.dart';

/// Vista compacta del dominio de un concepto, para la UI de progreso.
class MasteryBucket {
  const MasteryBucket({
    required this.conceptId,
    required this.name,
    required this.state,
    required this.mastery,
    required this.decisionAccuracy,
    required this.attempts,
  });

  final String conceptId;
  final String name;
  final MasteryState state;
  final double mastery;
  final double decisionAccuracy;
  final int attempts;
}

/// Arma los buckets de dominio para los conceptos enseñados y
/// practicables, ordenados del más flojo al más sólido.
List<MasteryBucket> masteryBuckets(
  UserKnowledge knowledge,
  Set<String> practiceable, {
  ConceptRegistry? registry,
}) {
  final reg = registry ?? ConceptRegistry.standard();
  final buckets = <MasteryBucket>[];
  for (final id in practiceable) {
    if (!knowledge.isTaught(id)) continue;
    final m = knowledge.masteryOf(id);
    buckets.add(MasteryBucket(
      conceptId: id,
      name: reg.tryById(id)?.name ?? id,
      state: m.state,
      mastery: m.mastery,
      decisionAccuracy: m.decisionAccuracy,
      attempts: m.attempts,
    ));
  }
  buckets.sort((a, b) => a.mastery.compareTo(b.mastery));
  return buckets;
}
