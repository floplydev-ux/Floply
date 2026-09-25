import 'models/floply_user.dart';
import 'user_repository.dart';

/// Implementación en memoria de [UserRepository], solo para tests (mismo
/// patrón que `InMemoryAcademyStore`/`FakeAuthRepository`).
class FakeUserRepository implements UserRepository {
  final Map<String, FloplyUser> _users = {};

  /// Simula backend caído (Firestore/red) para probar el manejo de
  /// errores de [AuthController] después de un login ya exitoso.
  bool throwOnFetch = false;

  @override
  Future<FloplyUser?> fetch(String id) async {
    if (throwOnFetch) throw Exception('fake: backend no disponible');
    return _users[id];
  }

  @override
  Future<void> save(FloplyUser user) async => _users[user.id] = user;

  @override
  Future<void> delete(String id) async => _users.remove(id);

  /// Para armar escenarios de test directamente.
  void seed(FloplyUser user) => _users[user.id] = user;
}
