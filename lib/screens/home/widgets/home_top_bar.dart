import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/economy/coins_economy_state.dart';
import '../../../services/economy/floply_coins_service.dart';
import '../../../services/economy/training_quota_service.dart';
import '../../../services/economy/training_quota_state.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';

/// Formatea [Duration] como `MM:SS` (sin horas).
String _mmss(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Header fijo del Home — **diseño modular** (pedido explícito): Perfil,
/// Coins, Entrenamiento, Notificaciones y Configuración son 5 bloques
/// independientes, cada uno con su propio fondo, en vez de una única
/// barra sólida con contenido adentro. Vive FUERA del
/// `SingleChildScrollView` del Home (ver `home_screen.dart`) — nunca se
/// desplaza con el contenido.
///
/// **El contenedor general es transparente de verdad**: a diferencia de
/// la versión anterior (un degradé + línea inferior cubriendo todo el
/// ancho), acá no hay ninguna superficie detrás de los 5 módulos — el
/// fondo de la pantalla se ve alrededor de cada uno. Solo cada módulo,
/// individualmente, tiene su propio relleno — nunca "una franja negra
/// detrás de todos".
///
/// **Fuente única de verdad**: Coins/Entrenamientos salen de
/// [FloplyCoinsService]/[TrainingQuotaService] (mismos servicios que ya
/// usa el resto de la economía, nunca un contador propio); nombre/foto
/// salen de [AppUser.current] (la misma fuente que ya usa el saludo del
/// Home y la mesa de Coach). Este widget nunca guarda ni calcula nada,
/// solo escucha y pinta.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.coins,
    required this.training,
    required this.onOpenSettings,
    this.onTapCoins,
    this.onTapTraining,
  });

  final FloplyCoinsService coins;
  final TrainingQuotaService training;

  /// Módulo Configuración → `SettingsScreen` real (la misma que hoy
  /// también se abre desde Perfil). Notificaciones no tiene pantalla
  /// propia todavía (ver el doc-comment de [_NotificationsModule]) — por
  /// eso solo esta acción se recibe como callback, nunca un
  /// `AuthController` completo acá adentro: este widget sigue sin saber
  /// nada de autenticación.
  final VoidCallback onOpenSettings;

  /// Toque en el módulo de FLOPly Coins → abre la hoja informativa.
  final VoidCallback? onTapCoins;

  /// Toque en el módulo de Entrenamientos → abre la hoja informativa.
  final VoidCallback? onTapTraining;

  /// Alto visual compartido por los 3 módulos "pill" (Perfil/Coins/
  /// Entrenamiento) y diámetro de los 2 módulos circulares
  /// (Notificaciones/Configuración) — "alturas consistentes" (pedido
  /// explícito).
  static const double _moduleHeight = 40;

  /// Por debajo de este ancho, los módulos de economía dejan de mostrar
  /// "/máximo" (muestran solo el número actual) — "en teléfonos pequeños:
  /// reducir tamaños secundarios, priorizar... datos importantes" (pedido
  /// explícito). El valor exacto (`/6`, `/5`) sigue disponible para
  /// lectores de pantalla en el `Semantics.label` de [_StatModule],
  /// nunca se pierde información, solo se oculta visualmente.
  static const double _compactBreakpoint = 360;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sin decoración propia acá — el padding es el único propósito de
      // este nivel; cada módulo de abajo pone su propio fondo. Horizontal
      // chico a propósito (`sm`, no `md`): en 320dp con un nombre largo,
      // cada pixel de margen general le resta al único módulo que puede
      // ceder espacio (Perfil) — ver `_ProfileModule`.
      padding: const EdgeInsets.symmetric(
          horizontal: SalaVerdeSpace.sm, vertical: SalaVerdeSpace.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < _compactBreakpoint;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: Listenable.merge([coins, training]),
                builder: (context, _) {
                  if (coins.loading || training.loading) return const SizedBox.shrink();
                  // Tiempo parcial de la moneda activa: solo se muestra
                  // cuando hay una fracción de coin en consumo (> 0 y <
                  // timePerCoin). Valor estático en Home — el tiempo solo
                  // corre dentro de Tools; aquí solo reflejamos el estado
                  // pausado.
                  final partialSecs = coins.availableTime.inSeconds %
                      CoinsEconomyState.timePerCoin.inSeconds;
                  final coinSubLabel = (!compact && partialSecs > 0)
                      ? _mmss(Duration(seconds: partialSecs))
                      : null;
                  return _StatModule(
                    asset: 'assets/images/home/floply_coin.png',
                    circularImage: true,
                    current: coins.coins,
                    max: CoinsEconomyState.maxCoins,
                    semanticLabel: AppStrings.economyHomeCoinsLabel,
                    tint: SalaVerdeColors.brass,
                    compact: compact,
                    subLabel: coinSubLabel,
                    onTap: onTapCoins,
                  );
                },
              ),
              const SizedBox(width: SalaVerdeSpace.xs),
              AnimatedBuilder(
                animation: Listenable.merge([coins, training]),
                builder: (context, _) {
                  if (coins.loading || training.loading) return const SizedBox.shrink();
                  // Cuando el cupo gratuito se agota, sustituir el contador
                  // numérico por un cronómetro de recarga hasta medianoche.
                  if (training.remaining == 0) {
                    return _TrainingCountdownModule(
                      resetDate: training.resetDate,
                      onTap: onTapTraining,
                    );
                  }
                  return _StatModule(
                    asset: 'assets/images/home/economy_training_icon.png',
                    current: training.remaining,
                    max: TrainingQuotaState.dailyFreeTrainings,
                    semanticLabel: AppStrings.economyProfileTrainingLabel,
                    tint: SalaVerdeColors.feltGreenBright,
                    compact: compact,
                    onTap: onTapTraining,
                  );
                },
              ),
              const SizedBox(width: SalaVerdeSpace.xs),
              _IconModule(
                icon: Icons.notifications_none_rounded,
                semanticLabel: AppStrings.homeNotificationsLabel,
                // Sin backend/lógica de notificaciones todavía (pedido
                // explícito: "dejar el botón preparado sin crear un
                // sistema ficticio") — nunca un badge inventado.
                onTap: () {},
              ),
              const SizedBox(width: SalaVerdeSpace.xs),
              _IconModule(
                icon: Icons.settings_rounded,
                semanticLabel: AppStrings.profileSettingsCta,
                onTap: onOpenSettings,
              ),
            ],
          );
        },
      ),
    );
  }
}


/// Módulo de un dato de economía (Coins/Entrenamiento): ícono oficial +
/// "{current}/{max}", fondo propio con un whisper del color que
/// identifica a cada uno (dorado para Coins, esmeralda para
/// Entrenamiento) — "distintos tonos de verde oscuro... pero siempre
/// respetando el lenguaje visual premium", nunca colores chillones:
/// [tint] se mezcla al 10% sobre la misma superficie base de siempre, no
/// reemplaza la paleta.
///
/// Cuando [subLabel] está presente (p. ej. "08:42" del tiempo parcial de
/// la coin activa), se muestra debajo del contador principal en texto
/// secundario más pequeño — el pill crece en altura de forma natural
/// (sin desbordamiento, sin altura fija).
class _StatModule extends StatelessWidget {
  const _StatModule({
    required this.asset,
    required this.current,
    required this.max,
    required this.semanticLabel,
    required this.tint,
    required this.compact,
    this.circularImage = false,
    this.subLabel,
    this.onTap,
  });

  final String asset;
  final int current;
  final int max;
  final String semanticLabel;
  final Color tint;

  /// `true` en pantallas angostas: oculta "/{max}" (el dato secundario)
  /// y deja solo el número actual — nunca en el `Semantics.label`, que
  /// siempre informa el valor completo.
  final bool compact;

  /// `true` recorta la imagen a un círculo (útil para el chip FLOPly que
  /// tiene fondo opaco — el recorte elimina las esquinas blancas).
  final bool circularImage;

  /// Texto adicional opcional — cuando está presente se muestra debajo
  /// del contador como el tiempo restante de la moneda activa (p. ej.
  /// "08:42"). Solo se muestra cuando [compact] es `false`.
  final String? subLabel;

  /// Callback al tocar el módulo — abre la hoja informativa del coin.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showSub = subLabel != null && !compact;
    final content = Semantics(
      label: showSub
          ? '$semanticLabel: $current de $max, $subLabel restantes'
          : '$semanticLabel: $current de $max',
      button: onTap != null,
      child: ExcludeSemantics(
        child: Container(
          // Altura fija solo cuando no hay sub-etiqueta; con sub-etiqueta
          // el contenido dicta la altura para evitar desbordamiento.
          height: showSub ? null : HomeTopBar._moduleHeight,
          padding: EdgeInsets.symmetric(
            horizontal: 6,
            vertical: showSub ? 5 : 0,
          ),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
                tint.withValues(alpha: 0.12), SalaVerdeColors.surfaceElevated),
            borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
            border: Border.all(color: tint.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: circularImage
                    ? ClipOval(
                        child: Image.asset(asset, fit: BoxFit.cover),
                      )
                    : Image.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    compact ? '$current' : '$current/$max',
                    style: SalaVerdeType.numeric(
                        size: 12, color: SalaVerdeColors.textPrimary),
                  ),
                  if (showSub)
                    Text(
                      subLabel!,
                      style: SalaVerdeType.numeric(
                          size: 10, color: SalaVerdeColors.textSecondary),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

/// Módulo de entrenamiento cuando el cupo diario está agotado
/// (`remaining == 0`): cronómetro de cuenta regresiva hasta medianoche,
/// que es cuando [TrainingQuotaState] restablece los 5 entrenamientos
/// gratuitos. Solo actualiza la pantalla, nunca es fuente de verdad del
/// reset (esa sigue siendo [TrainingQuotaState.advanced]).
class _TrainingCountdownModule extends StatefulWidget {
  const _TrainingCountdownModule({required this.resetDate, this.onTap});

  final DateTime resetDate;
  final VoidCallback? onTap;

  @override
  State<_TrainingCountdownModule> createState() =>
      _TrainingCountdownModuleState();
}

class _TrainingCountdownModuleState extends State<_TrainingCountdownModule> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) { if (mounted) setState(() {}); },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _remaining() {
    final nextMidnight = DateTime(
      widget.resetDate.year,
      widget.resetDate.month,
      widget.resetDate.day + 1,
    );
    final diff = nextMidnight.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  Widget build(BuildContext context) {
    final dur = _remaining();
    final h = dur.inHours;
    final m = (dur.inMinutes % 60).toString().padLeft(2, '0');
    final s = (dur.inSeconds % 60).toString().padLeft(2, '0');
    final label = '$h:$m:$s';

    final content = Semantics(
      label: 'Entrenamientos: recarga en $label',
      button: widget.onTap != null,
      child: ExcludeSemantics(
        child: Container(
          height: HomeTopBar._moduleHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              SalaVerdeColors.feltGreenBright.withValues(alpha: 0.12),
              SalaVerdeColors.surfaceElevated,
            ),
            borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
            border: Border.all(
              color: SalaVerdeColors.feltGreenBright.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_rounded,
                size: 14,
                color: SalaVerdeColors.feltGreenBright,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: SalaVerdeType.numeric(
                  size: 12,
                  color: SalaVerdeColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.onTap == null) return content;
    return GestureDetector(onTap: widget.onTap, child: content);
  }
}

/// Módulo circular (Notificaciones/Configuración): mismo criterio de
/// accesibilidad que ya usa el resto del Home — círculo visual chico,
/// área tápable de 48×48 (`androidTapTargetGuideline`).
class _IconModule extends StatelessWidget {
  const _IconModule({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: PressableScale(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: HomeTopBar._moduleHeight,
              height: HomeTopBar._moduleHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SalaVerdeColors.surfaceElevated,
                border: Border.all(color: SalaVerdeColors.borderSubtle),
              ),
              child: Icon(icon, size: 18, color: SalaVerdeColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
