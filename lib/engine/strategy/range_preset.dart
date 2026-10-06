import '../poker/position.dart';
import 'range_context.dart';

/// Un preset oficial de FLOPly (sección 25) — un atajo directo a un
/// `RangeContext` con datos reales detrás. Solo se generan presets para
/// situaciones que de verdad tienen datos: hoy, Open Raise para las 5
/// posiciones que abren (`Position.openers`). No hay presets de BB
/// Defense/3-bet/4-bet/Squeeze/Short Stack todavía porque no hay rango
/// real completo para ofrecerlos (regla 25: "solamente mostrar presets
/// cuyos datos estén realmente disponibles").
class RangePreset {
  const RangePreset({required this.id, required this.label, required this.context});

  final String id;
  final String label;
  final RangeContext context;

  static List<RangePreset> get openRaisePresets => [
        for (final position in Position.openers)
          RangePreset(
            id: 'open_raise_${position.name}',
            label: '${position.abbreviation} Open',
            context: RangeContext(position: position),
          ),
      ];
}
