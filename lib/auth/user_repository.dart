import 'models/floply_user.dart';

/// Persistencia del perfil [FloplyUser] — separada a propósito de
/// [AuthRepository] (Fase 24: AUTHENTICATION ≠ USER PROFILE). Un cambio de
/// dónde vive el perfil (hoy Firestore) nunca debería tocar la capa de
/// autenticación ni viceversa.
abstract class UserRepository {
  Future<FloplyUser?> fetch(String id);

  Future<void> save(FloplyUser user);

  Future<void> delete(String id);
}
