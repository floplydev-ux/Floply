/// Formatea un entero con separador de miles ("1248" -> "1.248").
///
/// Implementado a mano para no depender del paquete `intl` en esta etapa
/// (formato es-AR). Si más adelante se agrega soporte multi-idioma real,
/// esta función se reemplaza por `NumberFormat` de `intl`.
String formatThousands(int value) {
  final isNegative = value < 0;
  final str = value.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final posFromEnd = str.length - i;
    buffer.write(str[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return isNegative ? '-${buffer.toString()}' : buffer.toString();
}
