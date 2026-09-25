/// Señala que una generación puntual falló y hay que reintentar con otras
/// variables (no es un error del sistema).
///
/// Vive acá (en `poker/`, no en `exercises/`) porque la usan piezas de
/// capas más bajas que el motor de ejercicios — `HandPicker`,
/// `BoardGenerator`, `HandRange.sample` — y `poker/`/`strategy/` nunca
/// deberían depender de `exercises/` para importar un tipo. `exercises/
/// exercise_template.dart` la re-exporta para no romper los call sites
/// existentes.
class TemplateGenerationException implements Exception {
  TemplateGenerationException(this.message);
  final String message;
  @override
  String toString() => 'TemplateGenerationException: $message';
}
