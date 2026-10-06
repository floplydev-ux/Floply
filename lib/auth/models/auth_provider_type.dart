/// Un método de autenticación asociado a una [FloplyUser]. Deliberadamente
/// separado de la identidad: una cuenta puede tener varios a la vez (ver
/// `AuthController.link*`), y agregar uno nuevo (p. ej. `phone`) es sumar
/// un valor acá — ningún otro tipo de la capa de auth necesita cambiar.
enum AuthProviderType {
  google,
  apple,
  email,
  phone;

  /// El `providerId` que usa `firebase_auth` internamente
  /// (`UserInfo.providerId`), para traducir de/hacia Firebase sin que el
  /// resto de la app conozca esas constantes de texto.
  String get firebaseProviderId => switch (this) {
        AuthProviderType.google => 'google.com',
        AuthProviderType.apple => 'apple.com',
        AuthProviderType.email => 'password',
        AuthProviderType.phone => 'phone',
      };

  static AuthProviderType? fromFirebaseProviderId(String id) {
    for (final type in AuthProviderType.values) {
      if (type.firebaseProviderId == id) return type;
    }
    // firebase_auth reporta el método de email-link como 'emailLink' en
    // cuentas antiguas migradas.
    if (id == 'emailLink') return AuthProviderType.email;
    return null;
  }
}
