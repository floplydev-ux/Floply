/// Identidad del usuario de la aplicación.
///
/// Fuente única del nombre del usuario: lo usa tanto la mesa de la Academia
/// como el saludo de la Home. Hoy no hay pantalla de perfil ni persistencia
/// propia: se usa un valor por defecto. Cuando exista un perfil real, basta
/// con asignar [AppUser.current] al cargar la sesión; nada de lo que lo lee
/// se tiene que tocar.
class AppUser {
  const AppUser({required this.displayName, this.photoUrl});

  /// Nombre configurado por el usuario (p. ej. "Juan G." o "Juan").
  final String displayName;

  /// Avatar ya resuelto (custom de Floply si existe, si no el del
  /// proveedor — ver `FloplyUser.avatarUrl`) o `null` si no hay ninguno.
  /// Nadie que lea esto necesita saber de dónde salió.
  final String? photoUrl;

  /// Primer nombre, que es lo que se muestra en el asiento de la mesa.
  String get firstName {
    final t = displayName.trim();
    if (t.isEmpty) return 'Vos';
    final first = t.split(RegExp(r'\s+')).first;
    return first.isEmpty ? 'Vos' : first;
  }

  /// El usuario actual. Mutable a propósito: un futuro sistema de perfil
  /// solo tiene que reemplazar esta referencia.
  static AppUser current = const AppUser(displayName: 'Juan');
}
