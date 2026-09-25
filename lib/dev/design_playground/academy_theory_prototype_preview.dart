/// PROTOTIPO — Fase 1 (PRUEBA 2) + Fase 1.5 (PRUEBA 1, teoría larga).
///
/// Entorno de **Flutter Widget Preview** — mismo mecanismo que ya usa el
/// proyecto para `poker_table_view_preview.dart` y
/// `playable_table_exercise_preview.dart`: `flutter widget-preview start`.
///
/// Dos teorías reales del currículo, no inventadas:
/// - **T093 "Set"** (nivel 4, subnivel 4.5 "Tu mano hecha en el flop" —
///   `curriculum_spec_data.g.dart:1368`) — teoría corta, 6 secciones,
///   ya usada en la Fase 1.
/// - **TN10 "Implied odds"** (nivel 6, subnivel 6.5 — INTERMEDIO,
///   `curriculum_spec_data.g.dart:1890`) — teoría LARGA: las 7 secciones
///   completas (incluye "CUÁNDO NO", que T093 no tiene) con párrafos
///   sustancialmente más extensos. Se eligió deliberadamente como la más
///   exigente de las dos más largas del currículo completo (ver
///   `FLOPLY_VISUAL_STRESS_TEST.md` §D) para forzar scroll real y stress
///   testear el ritmo editorial, no solo confirmarlo con un caso fácil.
///
/// Texto copiado verbatim de la fuente — no se editorializó ni se acortó
/// nada para que "quepa mejor" en el diseño.
///
/// Qué se prueba (Fase 1.5, criterio especial Academia): si el lenguaje
/// editorial (superficie de lectura plana, eyebrows sin color propio,
/// "presupuesto de materialidad") sigue leyéndose como una ficha coherente
/// —no como "muchas tarjetas seguidas"— cuando el contenido es realmente
/// largo, SIN agregar más color/superficies/badges para "hacerlo
/// interesante" (la trampa que este criterio pide vigilar explícitamente).
///
/// **No se toca `written_theory_view.dart` ni ningún archivo de
/// producción.**
library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'proto_components.dart';
import 'proto_tokens.dart';

// Ver la misma nota en `home_prototype_preview.dart`: un SizedBox de ancho
// fijo hacía inútil el barrido responsive por encima de 390dp. Fase 1.5,
// FLOPLY_VISUAL_STRESS_TEST.md §J.
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

class _TheorySectionData {
  const _TheorySectionData(this.eyebrow, this.body);
  final String eyebrow;
  final String body;
}

class _TheoryData {
  const _TheoryData({
    required this.headerTitle,
    required this.headerSubtitle,
    required this.titulo,
    required this.objetivo,
    required this.sections,
    required this.ideaClave,
  });

  final String headerTitle;
  final String headerSubtitle;
  final String titulo;
  final String objetivo;
  final List<_TheorySectionData> sections;
  final String ideaClave;
}

/// T093 "Set" — verbatim de `curriculum_spec_data.g.dart:1368`.
const _t093 = _TheoryData(
  headerTitle: 'Tu mano hecha en el flop',
  headerSubtitle: 'Nivel 4 · Teoría corta',
  titulo: 'Set',
  objetivo: 'Reconocer un set (trío con pareja servida) y por qué es oro.',
  sections: [
    _TheorySectionData(
      'QUÉ ES',
      'Un set es un trío formado con una pareja servida más una carta '
          'igual en el board.',
    ),
    _TheorySectionData(
      'POR QUÉ IMPORTA',
      'Es una de las manos más fuertes y mejor disimuladas del póker: '
          'nadie espera que tengas trío cuando solo hay una carta de ese '
          'valor a la vista en la mesa.',
    ),
    _TheorySectionData(
      'CÓMO FUNCIONA',
      'Necesitás haber empezado con una pareja servida, y que el board '
          'traiga una tercera carta de ese mismo valor.',
    ),
    _TheorySectionData(
      'CUÁNDO LO USÁS',
      'Cuando jugás parejas servidas, especialmente las bajas: el '
          'objetivo es ligar el set.',
    ),
    _TheorySectionData(
      'EJEMPLO',
      'Tenés 8♠8♦. Board: K♣8♥3♦. El 8 del board te da trío de ochos: un '
          'set. Nadie ve venir eso con solo un 8 a la vista.',
    ),
    _TheorySectionData(
      'ERROR COMÚN',
      'Confundir set con trips: en el set, la pareja es tuya y solo una '
          'carta viene del board. Es importante para saber si el rival '
          'puede tener el mismo trío que vos.',
    ),
  ],
  ideaClave: 'Set = pareja servida + una igual en el board. Fuerte y '
      'disimulado.',
);

/// TN10 "Implied odds" — verbatim de `curriculum_spec_data.g.dart:1890`.
/// Teoría LARGA a propósito (ver doc-comment de arriba): 7 secciones
/// completas, párrafos largos, la que de verdad estresa el scroll.
const _tn10 = _TheoryData(
  headerTitle: 'Pot odds avanzadas',
  headerSubtitle: 'Nivel 6 · Teoría larga · INTERMEDIO',
  titulo: 'Implied odds',
  objetivo:
      'Estimar lo que podés ganar en calles futuras si ligás tu proyecto.',
  sections: [
    _TheorySectionData(
      'QUÉ ES',
      'Las implied odds son una corrección a las pot odds: tienen en '
          'cuenta que, si completás tu proyecto, probablemente vas a poder '
          'ganar fichas EXTRA en las calles siguientes, más allá del bote '
          'final actual.',
    ),
    _TheorySectionData(
      'POR QUÉ IMPORTA',
      'A veces tu equity real es un poco menor que la necesaria por pot '
          'odds puras, pero el call igual conviene, porque completar tu '
          'proyecto te va a dejar ganar más fichas después.',
    ),
    _TheorySectionData(
      'CÓMO FUNCIONA',
      'Preguntate: si completo mi proyecto, ¿el rival me va a pagar más '
          'apuestas después? Cuanto más probable eso, más podés relajar la '
          'equity necesaria estricta de T116.',
    ),
    _TheorySectionData(
      'CUÁNDO LO USÁS',
      'Con proyectos que, al completarse, quedan bien disimulados y es '
          'probable que el rival siga pagando después (por ejemplo, un '
          'proyecto de escalera contra una mano fuerte del rival).',
    ),
    _TheorySectionData(
      'CUÁNDO NO',
      'Cuando es poco probable que el rival pague más fichas después de '
          'que completes tu proyecto (por ejemplo, si el board queda muy '
          'obvio y el rival se va a frenar).',
    ),
    _TheorySectionData(
      'EJEMPLO',
      'Con tu proyecto de escalera, si el rival tiene una pareja de ases '
          'y vos completás en el river, es bastante probable que pague una '
          "apuesta más — esas fichas extra 'implican' que podés pagar el "
          'call actual con un poquito menos de equity de la que pedían las '
          'pot odds puras.',
    ),
    _TheorySectionData(
      'ERROR COMÚN',
      "Usar 'implied odds' como excusa para pagar con cualquier equity "
          'insuficiente, sin evaluar en serio si de verdad vas a ganar más '
          'fichas después.',
    ),
  ],
  ideaClave: 'Implied odds = fichas extra que esperás ganar en calles '
      'futuras si completás tu proyecto. Te permite pagar con un poco '
      'menos de equity que la estrictamente necesaria.',
);

class _AcademyTheoryPrototype extends StatelessWidget {
  const _AcademyTheoryPrototype(this.theory);

  final _TheoryData theory;

  @override
  Widget build(BuildContext context) {
    // Temperatura cálida de Academia. Dos variantes deliberadas (hallazgo
    // de la Fase 1.5, ver FLOPLY_VISUAL_STRESS_TEST.md §J): `accent`
    // (base) solo se usa donde ya se midió que rinde contraste — acá,
    // como texto sobre `surfaceReading` (5.27:1). Ícono/progreso sobre
    // fondo oscuro usan `accentOnDark` (`feltGreenBright`, 6-7:1).
    const accent = ProtoColor.feltGreen;
    const accentOnDark = ProtoColor.feltGreenBright;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          ProtoSpace.lg, ProtoSpace.md, ProtoSpace.lg, ProtoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProtoSectionHeader(
            icon: Icons.school_outlined,
            title: theory.headerTitle,
            subtitle: theory.headerSubtitle,
            accent: accentOnDark,
          ),
          const SizedBox(height: ProtoSpace.lg),
          const ProtoProgressLinear(value: 1 / 1, color: accentOnDark),
          const SizedBox(height: ProtoSpace.xl),
          Expanded(
            child: SingleChildScrollView(
              child: ProtoReadingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(theory.titulo,
                        style: ProtoType.onReading(ProtoType.display)),
                    const SizedBox(height: ProtoSpace.md),
                    ProtoCalloutAccent(
                      eyebrow: 'OBJETIVO',
                      body: theory.objetivo,
                      color: accent,
                      icon: Icons.flag_outlined,
                      onReading: true,
                    ),
                    const SizedBox(height: ProtoSpace.xl),
                    for (var i = 0; i < theory.sections.length; i++)
                      _theorySection(
                        theory.sections[i].eyebrow,
                        theory.sections[i].body,
                        isLast: i == theory.sections.length - 1,
                      ),
                    const SizedBox(height: ProtoSpace.lg),
                    ProtoCalloutAccent(
                      eyebrow: 'IDEA CLAVE',
                      body: theory.ideaClave,
                      // brass puro sobre surfaceReading mide 2.17:1 (FALLA
                      // WCAG AA) — hallazgo real de la Fase 1.5. brassDeep
                      // mide 5.39:1 en la misma superficie.
                      color: ProtoColor.brassDeep,
                      icon: Icons.push_pin_outlined,
                      onReading: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: ProtoSpace.lg),
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: ProtoButtonSecondary(label: 'ATRÁS'),
              ),
              const SizedBox(width: ProtoSpace.md),
              Expanded(
                flex: 3,
                child: ProtoButtonPrimary(
                  label: 'PRACTICAR',
                  accent: ProtoColor.brass,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Deliberadamente SIN ícono ni color por tipo de sección (a diferencia
  /// de `_SectionView` real, que hoy usa 7 combinaciones distintas) — la
  /// jerarquía acá es puramente tipográfica: eyebrow uppercase + cuerpo.
  /// Ver "presupuesto de materialidad" (`FLOPLY_DESIGN_LANGUAGE.md` §5.1).
  /// Con TN10 (7 secciones largas) esto es lo que realmente se pone a
  /// prueba: nada nuevo se agregó para la teoría larga, es el mismo
  /// widget que T093.
  Widget _theorySection(String eyebrow, String body, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : ProtoSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: ProtoType.onReading(ProtoType.label, secondary: true)
                .copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 6),
          Text(body, style: ProtoType.onReading(ProtoType.body)),
        ],
      ),
    );
  }
}

@Preview(name: 'Academia · Teoría corta T093 "Set" (Sala Verde)')
Widget previewAcademyTheoryPrototype() => _stage(const _AcademyTheoryPrototype(_t093));

@Preview(name: 'Academia · Teoría LARGA TN10 "Implied odds" (Sala Verde)')
Widget previewAcademyTheoryLongPrototype() => _stage(const _AcademyTheoryPrototype(_tn10));
