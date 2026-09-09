/// Identidad del usuario de la aplicación.
///
/// Fuente única del **nombre que se muestra en la mesa de la Academia** (y,
/// a futuro, en cualquier otra pantalla). Hoy no hay pantalla de perfil ni
/// persistencia: se usa un valor por defecto que coincide con el de la
/// Home (`UserProgress.mock().name`). Cuando exista un perfil real, basta
/// con asignar [AppUser.current] al cargar la sesión; los scripts de la
/// mesa no se tocan.
class AppUser {
  const AppUser({required this.displayName});

  /// Nombre configurado por el usuario (p. ej. "Juan G." o "Juan").
  final String displayName;

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
