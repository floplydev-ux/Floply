import 'floply_user.dart';

/// Estado global de sesión de la app. `AuthGate` es el único widget que
/// debería ramificar sobre esto — el resto de la app pregunta
/// `AuthController.state` cuando lo necesita (Fase 25), nunca reimplementa
/// su propia lógica de "¿hay usuario?".
sealed class AuthState {
  const AuthState();
}

/// Resolviendo la sesión (arranque de la app, o justo después de
/// autenticar/cerrar sesión). `AuthGate` no debe mostrar login ni
/// contenido mientras está acá — evita el flash pedido en la Fase 10.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Sin cuenta todavía y sin haber elegido "continuar sin cuenta" — es el
/// único estado en el que se muestra `AuthScreen`.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Usando la app sin cuenta, a propósito (Fase 11). El progreso se guarda
/// localmente; nada bloquea el uso de la Academia.
class AuthGuest extends AuthState {
  const AuthGuest();
}

/// Sesión real, con una [FloplyUser] resuelta (no solo la identidad cruda
/// del proveedor).
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final FloplyUser user;
}
