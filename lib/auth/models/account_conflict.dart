import 'auth_provider_type.dart';

/// El caso de la Fase 9: el método de acceso que el usuario acaba de
/// intentar ya está asociado a OTRA cuenta Floply. No se fusiona nada
/// solo — la UI ([AccountConflictSheet]) debe mostrar esto y dejar
/// elegir explícitamente.
class AccountConflict {
  const AccountConflict({
    required this.attemptedProvider,
    this.existingEmail,
  });

  /// El proveedor con el que se intentó vincular/entrar y que generó el
  /// conflicto.
  final AuthProviderType attemptedProvider;

  /// El email (parcial u ofuscado si corresponde) de la cuenta existente,
  /// cuando el proveedor lo informa — para que el mensaje sea concreto
  /// ("ya está asociado a j***@gmail.com") en vez de genérico.
  final String? existingEmail;
}
