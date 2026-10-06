import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/nav_destination.dart';
import '../theme/sala_verde/sala_verde_tokens.dart';

/// Barra de navegación inferior de la app.
///
/// Widget controlado: el padre decide qué pestaña está activa
/// ([currentIndex]) y qué pasa al tocar cada una ([onTap]). Los 5 destinos
/// salen de [kNavDestinations], la misma fuente que usan las pantallas
/// placeholder, para que íconos y labels no se dupliquen.
///
/// Grupo 1 (navegación/perfil/configuración): migrada a "Sala Verde" —
/// antes usaba `AppColors` (violeta/neón), la identidad vieja, mientras el
/// resto de la navegación raíz (Home) ya usa esta paleta desde la Fase 2.
/// El tab activo ahora se marca con una píldora de `brass` detrás del
/// ícono (no solo cambio de color) — la misma regla de "máximo un uso de
/// brass por pantalla" se cumple porque esta barra es global, no compite
/// con el `brass` de la pantalla que esté abajo.
///
/// **Transparente de verdad** (pedido explícito): ya no es un relleno
/// sólido de `surface` — es un `BackdropFilter` (desenfoque, "blur muy
/// sutil") sobre un degradé de muy baja opacidad, así el contenido de la
/// pantalla de atrás sigue viendo detrás en vez de cortarse contra una
/// caja. `AppShell` pasa `extendBody: true` para que el `body` ocupe la
/// pantalla completa por detrás de esta barra — el único cambio de
/// layout que hizo falta para que "atrás" exista de verdad, nunca una
/// pantalla en particular tocada. La línea superior pasa de
/// `borderSubtle` a un dorado apenas visible, mismo lenguaje que ya usa
/// `HomeTopBar` para separar sin "caja".
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SalaVerdeColors.background.withValues(alpha: 0.0),
                SalaVerdeColors.background.withValues(alpha: 0.28),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  for (int i = 0; i < kNavDestinations.length; i++)
                    Expanded(
                      child: _NavButton(
                        data: kNavDestinations[i],
                        isActive: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  final NavDestination data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? SalaVerdeColors.brassBright : SalaVerdeColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: isActive,
          label: data.label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: SalaVerdeMotion.fast,
                curve: SalaVerdeMotion.settleCurve,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? SalaVerdeColors.brass.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
                ),
                child: Icon(data.icon, color: color, size: 21),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                // `FittedBox`: "Campo de entrenamiento" en mayúsculas es
                // bastante más largo que el resto de los tabs (Academia,
                // Perfil...) — sin esto desbordaría en anchos chicos.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.label.toUpperCase(),
                    maxLines: 1,
                    style: SalaVerdeType.label(color: color).copyWith(
                      fontSize: 9.5,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
