/// PROTOTIPO — Fase 1 (PRUEBA 1) + Fase 1.5 (PRUEBA 3, contenido variable).
///
/// Entorno de **Flutter Widget Preview** — mismo mecanismo que ya usa el
/// proyecto (ver `poker_table_view_preview.dart`): `flutter
/// widget-preview start` desde la raíz.
///
/// Es la prueba más difícil (`docs/design/FLOPLY_PROTOTYPE_PHASE_1.md`):
/// no hay mesa de póker que le dé identidad automática. Reutiliza copy
/// REAL de `AppStrings`/`AppUser` (no texto inventado) para juzgar
/// composición/jerarquía/tipografía/superficies/profundidad.
///
/// Fase 1.5 agrega 5 variantes de contenido (`_HomeCase`) sin tocar
/// ninguna lógica real — son solo datos distintos servidos al mismo
/// layout, para comprobar que la composición no depende de que los
/// números/textos de muestra "queden bien":
/// - **A. Usuario nuevo** — copy real de "sin progreso todavía"
///   (`AppStrings.continueLearningNew*`), sin chips ni barra (no hay nada
///   que medir todavía).
/// - **B. Mucho progreso** — copy real de Academia completada
///   (`AppStrings.continueLearningCompleted*`), 13/13, CTA "PRACTICAR".
/// - **C. Texto largo** — título de lección largo derivado de una teoría
///   real (TN10, ver `academy_theory_prototype_preview.dart`).
/// - **D. Texto corto** — título de una sola palabra ("Set").
/// - **E. Estado secundario vacío** — reemplaza la lista de 3 destinos por
///   el patrón real "Empty State" de `FLOPLY_COMPONENTS.md` (nunca antes
///   construido en este playground).
///
/// Decisión deliberada frente al Home real (`home_screen.dart`): el fondo
/// es un color plano (`ProtoColor.background`), no el degradé de dos
/// colores que usa hoy `AppColors.backgroundGradient` — un gradiente de
/// fondo sin función física es exactamente lo que
/// `FLOPLY_ANTI_GENERIC.md` regla 5 prohíbe.
///
/// **No se toca `home_screen.dart` ni ningún widget de producción.**
library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import 'proto_components.dart';
import 'proto_tokens.dart';

// Hallazgo real de la Fase 1.5 (ver FLOPLY_VISUAL_STRESS_TEST.md §J): un
// `SizedBox` con ancho FIJO acá hacía que todo el barrido responsive de
// anchos ≥390dp fuera un no-op (el contenido se quedaba en 390 con
// espacio muerto alrededor, en vez de ocupar el ancho real del
// dispositivo) — el barrido angosto (300-375) sí funcionaba porque el
// `SizedBox` queda comprimido por las constraints del padre. `LayoutBuilder`
// usa el ancho real disponible, con 430dp como techo (el mayor ancho de
// teléfono común) para que siga viéndose como una pantalla de mobile — no
// una de escritorio — al abrirse suelto en el visor de Widget Preview.
Widget _stage(Widget child) {
  return ColoredBox(
    color: ProtoColor.background,
    child: Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth.clamp(0.0, 430.0)
              : 390.0;
          final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 844.0;
          return SizedBox(width: width, height: height, child: SafeArea(child: child));
        },
      ),
    ),
  );
}

enum _HomeCase { newUser, highProgress, longText, shortText, emptySecondary }

class _HomePrototype extends StatelessWidget {
  const _HomePrototype(this.homeCase);

  final _HomeCase homeCase;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          ProtoSpace.lg, ProtoSpace.lg, ProtoSpace.lg, ProtoSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: ProtoSpace.xl),
          _continueLearningHero(),
          const SizedBox(height: ProtoSpace.xxl),
          const Text(AppStrings.homeMoreLabel, style: ProtoType.label),
          const SizedBox(height: ProtoSpace.md),
          if (homeCase == _HomeCase.emptySecondary)
            _emptySecondaryState()
          else ...[
            _practiceRoomCard(),
            const SizedBox(height: ProtoSpace.md),
            _linkCard(
              icon: Icons.savings_outlined,
              title: AppStrings.bankrollTitle,
              description: AppStrings.bankrollDescription,
              accent: ProtoColor.brass,
            ),
            const SizedBox(height: ProtoSpace.sm),
            _linkCard(
              icon: Icons.calculate_outlined,
              title: AppStrings.toolsTitle,
              description: AppStrings.toolsDescription,
              // graphiteSteel puro mide 2.32:1 contra background — falla
              // incluso el umbral de ícono (3:1). Fase 1.5, ver
              // FLOPLY_VISUAL_STRESS_TEST.md §J.
              accent: ProtoColor.graphiteSteelBright,
            ),
            const SizedBox(height: ProtoSpace.sm),
            _linkCard(
              icon: Icons.forum_outlined,
              title: AppStrings.coachTitle,
              description: AppStrings.coachDescription,
              accent: ProtoColor.textMuted,
              muted: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ProtoColor.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: ProtoColor.borderSubtle),
          ),
          alignment: Alignment.center,
          child: Text(
            AppUser.current.firstName.substring(0, 1).toUpperCase(),
            style: ProtoType.title,
          ),
        ),
        const SizedBox(width: ProtoSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.homeGreeting(AppUser.current.firstName),
                style: ProtoType.title,
              ),
              const SizedBox(height: 2),
              const Text(AppStrings.homeGreetingSubtitle, style: ProtoType.caption),
            ],
          ),
        ),
      ],
    );
  }

  /// El único elemento con foco visual fuerte de la pantalla — igual que
  /// `ContinueLearningCard` real ("lo primero visible sin hacer scroll"),
  /// pero acá con la temperatura cálida de Academia (`feltGreen`) en vez
  /// de violeta. Varía completamente por `homeCase` (Fase 1.5, Prueba 3);
  /// el widget que la renderiza es el mismo en los 5 casos.
  Widget _continueLearningHero() {
    // feltGreen puro (superficie/relleno) mide 2.73:1 sobre
    // surfaceElevated como texto — todos los usos de este método son
    // texto/chip/relleno sobre fondo oscuro, así que corresponde la
    // variante Bright en los tres (eyebrow, chips, progreso). Fase 1.5,
    // ver FLOPLY_VISUAL_STRESS_TEST.md §J.
    const accent = ProtoColor.feltGreenBright;

    // Caso A: usuario nuevo — copy REAL de "sin progreso todavía", sin
    // chips ni barra (no hay nada que medir; mostrar "0/13" sería peor
    // que no mostrar nada, ver FLOPLY_UX_PATTERNS.md "Progresar").
    if (homeCase == _HomeCase.newUser) {
      return ProtoTappableCard(
        onTap: () {},
        padding: const EdgeInsets.all(ProtoSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.continueLearningEyebrow,
              style: ProtoType.label.copyWith(color: accent),
            ),
            const SizedBox(height: ProtoSpace.sm),
            const Text(AppStrings.continueLearningNewTitle, style: ProtoType.headline),
            const SizedBox(height: ProtoSpace.sm),
            const Text(AppStrings.continueLearningNewBody, style: ProtoType.body),
            const SizedBox(height: ProtoSpace.lg),
            ProtoButtonPrimary(
              label: AppStrings.continueLearningStartCta,
              accent: ProtoColor.brass,
              onTap: () {},
            ),
          ],
        ),
      );
    }

    final (String title, String chipLevels, String chipMastery, double progress, String cta) =
        switch (homeCase) {
      _HomeCase.highProgress => (
          AppStrings.continueLearningCompletedTitle,
          '13/13',
          '100%',
          1.0,
          AppStrings.academyStartPractice,
        ),
      // Caso C: texto largo — título real derivado de TN10 (nivel +
      // subnivel + teoría), la clase de string que de verdad puede
      // aparecer cuando el nombre de la lección no es corto.
      _HomeCase.longText => (
          'Nivel 6 · Pot odds avanzadas · Implied odds',
          '9/13',
          '54%',
          9 / 13,
          AppStrings.academyContinue,
        ),
      // Caso D: texto corto — el otro extremo real (título de una sola
      // palabra, T093).
      _HomeCase.shortText => (
          'Set',
          '4/13',
          '31%',
          4 / 13,
          AppStrings.academyContinue,
        ),
      _ => (
          'Nivel 4 · Tu mano hecha en el flop',
          '8/13',
          '76%',
          8 / 13,
          AppStrings.academyContinue,
        ),
    };

    return ProtoTappableCard(
      onTap: () {},
      padding: const EdgeInsets.all(ProtoSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            homeCase == _HomeCase.highProgress
                ? AppStrings.homeMoreLabel // no hay "seguimos donde quedaste" si ya se terminó
                : AppStrings.continueLearningEyebrow,
            style: ProtoType.label.copyWith(color: accent),
          ),
          const SizedBox(height: ProtoSpace.sm),
          Text(title, style: ProtoType.headline),
          if (homeCase == _HomeCase.highProgress) ...[
            const SizedBox(height: ProtoSpace.sm),
            const Text(AppStrings.continueLearningCompletedBody, style: ProtoType.body),
          ],
          const SizedBox(height: ProtoSpace.md),
          // Wrap, no Row: a 320-360dp de ancho (iPhone SE y similares) dos
          // chips con label + valor no entran en una sola línea — hallazgo
          // real de la QA de Fase 1 (ver FLOPLY_PROTOTYPE_PHASE_1.md §7).
          Wrap(
            spacing: ProtoSpace.sm,
            runSpacing: ProtoSpace.sm,
            children: [
              ProtoChipNumeric(value: chipLevels, label: 'NIVELES', accent: accent),
              ProtoChipNumeric(value: chipMastery, label: 'DOMINIO', accent: accent),
            ],
          ),
          const SizedBox(height: ProtoSpace.md),
          ProtoProgressLinear(value: progress, color: accent),
          const SizedBox(height: ProtoSpace.lg),
          ProtoButtonPrimary(label: cta, accent: ProtoColor.brass, onTap: () {}),
        ],
      ),
    );
  }

  /// Temperatura fría de Laboratorio (`steelBlue`) — mismo componente base
  /// (`ProtoTappableCard`) que el hero de Academia, distinto solo en
  /// acento y densidad de contenido (más liviano: es un atajo, no el foco
  /// principal de la pantalla).
  Widget _practiceRoomCard() {
    // steelBlue puro mide 3.08:1 contra surfaceElevated — falla como
    // texto (título) y queda al límite como ícono. Bright mide 6.2:1 en
    // la misma superficie. Fase 1.5, ver FLOPLY_VISUAL_STRESS_TEST.md §J.
    const accent = ProtoColor.steelBlueBright;
    return ProtoTappableCard(
      onTap: () {},
      child: Row(
        children: [
          const Icon(Icons.bolt_outlined, color: accent, size: 26),
          const SizedBox(width: ProtoSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.practiceRoomTitle,
                    style: ProtoType.title.copyWith(color: accent)),
                const SizedBox(height: 2),
                const Text(AppStrings.practiceRoomBody, style: ProtoType.caption),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: ProtoColor.textMuted),
        ],
      ),
    );
  }

  /// Los 3 destinos secundarios de Home. Nota importante para el
  /// "presupuesto de brass" (`FLOPLY_ANTI_GENERIC.md` 0.2): Bankroll usa
  /// `brass` acá SOLO en ícono/texto, nunca como relleno de superficie —
  /// el hero de arriba ya gastó el único relleno brass permitido en esta
  /// pantalla (el botón CONTINUAR/PRACTICAR). Si esta card también
  /// rellenara su fondo de dorado, la pantalla entera empezaría a leerse
  /// "casino".
  Widget _linkCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accent,
    bool muted = false,
  }) {
    final color = muted ? ProtoColor.textMuted : accent;
    return ProtoTappableCard(
      onTap: () {},
      padding: const EdgeInsets.all(ProtoSpace.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(ProtoRadius.sharp),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: ProtoSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: ProtoType.bodyStrong
                        .copyWith(color: muted ? color : ProtoColor.textPrimary)),
                const SizedBox(height: 2),
                Text(description, style: ProtoType.caption, maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Caso E — patrón "Empty State" real (`FLOPLY_COMPONENTS.md`: "ícono
  /// outline grande + texto explicando honestamente por qué está vacío").
  /// Nunca se había construido en el playground hasta la Fase 1.5.
  Widget _emptySecondaryState() {
    return ProtoSurfacePanel(
      padding: const EdgeInsets.symmetric(vertical: ProtoSpace.xxl, horizontal: ProtoSpace.lg),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 36, color: ProtoColor.textMuted),
          const SizedBox(height: ProtoSpace.md),
          Text(
            'Por ahora no tenemos más recomendaciones para vos',
            style: ProtoType.body.copyWith(color: ProtoColor.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Home · A. Usuario nuevo (Sala Verde)')
Widget previewHomeNewUser() => _stage(const _HomePrototype(_HomeCase.newUser));

@Preview(name: 'Home · B. Mucho progreso (Sala Verde)')
Widget previewHomeHighProgress() => _stage(const _HomePrototype(_HomeCase.highProgress));

@Preview(name: 'Home · C. Texto largo (Sala Verde)')
Widget previewHomeLongText() => _stage(const _HomePrototype(_HomeCase.longText));

@Preview(name: 'Home · D. Texto corto (Sala Verde)')
Widget previewHomeShortText() => _stage(const _HomePrototype(_HomeCase.shortText));

@Preview(name: 'Home · E. Estado secundario vacío (Sala Verde)')
Widget previewHomeEmptySecondary() => _stage(const _HomePrototype(_HomeCase.emptySecondary));
