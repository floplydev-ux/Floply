import 'package:cloud_firestore/cloud_firestore.dart';

import '../engine/academy/academy_store.dart';
import '../engine/concepts/concept_registry.dart';

/// El progreso de Academia en la nube — implementa el `AcademyStore` YA
/// EXISTENTE (`lib/engine/academy/academy_store.dart`), sin agregar una
/// interfaz nueva. `AcademyController` recibe esta clase exactamente
/// igual que recibiría un `FileAcademyStore`: nunca sabe que hay una nube
/// de por medio.
///
/// Un documento por usuario (`users/{uid}/academy/progress`), mismo blob
/// versionado que ya usa `FileAcademyStore` — mismo formato en todos
/// lados, cero migración de esquema.
class FirestoreAcademyStore implements AcademyStore {
  FirestoreAcademyStore({required this.uid, FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(uid).collection('academy').doc('progress');

  @override
  Future<AcademySaveData?> load(ConceptRegistry registry) async {
    final snap = await _doc.get();
    final data = snap.data();
    if (data == null) return null;
    return AcademySaveData.fromJson(registry, data);
  }

  @override
  Future<void> save(AcademySaveData data) async {
    await _doc.set(data.toJson());
  }

  @override
  Future<void> clear() async {
    await _doc.delete();
  }
}
