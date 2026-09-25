import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/floply_user.dart';
import 'user_repository.dart';

/// Perfil de cuenta en Firestore, colección `users/{id}` — un documento
/// por [FloplyUser], keyado por el id interno de Floply (nunca por email
/// ni por el id de ningún proveedor).
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Future<FloplyUser?> fetch(String id) async {
    final snap = await _users.doc(id).get();
    final data = snap.data();
    if (data == null) return null;
    return FloplyUser.fromJson(data);
  }

  @override
  Future<void> save(FloplyUser user) async {
    await _users.doc(user.id).set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> delete(String id) async {
    await _users.doc(id).delete();
  }
}
