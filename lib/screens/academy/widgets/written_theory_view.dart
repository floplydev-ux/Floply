import 'package:flutter/material.dart';

import '../../../engine/pedagogy/theory.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../academy_controller.dart';

/// Fichas de teoría redactada (PASO 4): una teoría por pantalla, con sus
/// secciones (QUÉ ES · POR QUÉ IMPORTA · CÓMO FUNCIONA · …) y navegación
/// CONTINUAR / ATRÁS. Es una sub-fase de [AcademyPhase.theory]: viene después
/// del guion de mesa (si lo hay) y antes de los ejercicios.
///
/// **Fase 3 — migración visual a "Sala Verde"** (ver
/// `docs/design/FLOPLY_PHASE_3_ACADEMIA.md`): primer uso en producción de
/// `surfaceReading` — validado con T093 "Set" (corta) y TN10 "Implied
/// odds" (larga, 7 secciones) antes de aplicarse a las 326 teorías que
/// pasan por este mismo widget genérico. Cambio deliberado respecto de la
/// versión anterior: las 7 secciones ya NO tienen un color/ícono propio
/// cada una (`_SectionView` real usaba 7 combinaciones distintas) — la
/// jerarquía ahora es puramente tipográfica (eyebrow + cuerpo), la regla
/// "anti-fragmentación" ya validada en el playground con TN10
/// (`FLOPLY_DESIGN_LANGUAGE.md`, sección `surfaceReading`).
///
/// Los controles ATRÁS/CONTINUAR usan `SvLessonNavControls` (no
/// `LessonNavControls` de `lesson_widgets.dart`, compartido con
/// exercise/feedback/result y fuera de alcance). Hasta la Fase 4 esto era
/// un `_TheoryNavControls` privado de este archivo (`FLOPLY_PHASE_3_
/// ACADEMIA.md` §P); se promovió a `sala_verde_widgets.dart` cuando
/// Bankroll pasó a ser un segundo consumidor real del mismo patrón — ver
/// `FLOPLY_PHASE_4_LESSON_FLOW_HEADER.md`.
class WrittenTheoryView extends StatelessWidget {
  const WrittenTheoryView({super.key, required this.controller});

  final AcademyController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theory = c.currentWrittenTheory;
    if (theory == null) return const SizedBox.shrink();

    final total = c.writtenTheoryCount;
    final current = c.writtenTheoryStep + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Progress(current: current, total: total),
        const SizedBox(height: SalaVerdeSpace.md),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('wt${theory.id}'),
            child: _TheoryCard(theory: theory),
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        SvLessonNavControls(
          canGoBack: !c.isFirstWrittenTheory,
          // En la última ficha, "PRACTICAR" solo si lo que sigue son los
          // ejercicios directamente — si el subnivel tiene ejemplo de
          // cierre (piloto de 3 bloques), ese viene antes: todavía es
          // "CONTINUAR".
          buttonLabel: (c.isLastWrittenTheory && !c.hasClosingExample)
              ? AppStrings.academyStartPractice
              : AppStrings.academyContinue,
          onBack: c.prevWrittenTheory,
          onNext: c.nextWrittenTheory,
        ),
      ],
    );
  }
}

/// Una teoría redactada completa: título + objetivo + secciones.
class _TheoryCard extends StatelessWidget {
  const _TheoryCard({required this.theory});

  final Theory theory;

  @override
  Widget build(BuildContext context) {
    final content = theory.contenido!;
    final sections = <Widget>[];

    void add(String eyebrow, String? body) {
      if (body == null || body.trim().isEmpty) return;
      sections.add(_SectionView(eyebrow: eyebrow, body: body));
    }

    add('QUÉ ES', content.queEs);
    add('POR QUÉ IMPORTA', content.porQueImporta);
    add('CÓMO FUNCIONA', content.comoFunciona);
    add('CUÁNDO LO USÁS', content.cuandoLoUso);
    add('CUÁNDO NO', content.cuandoNo);
    add('EJEMPLO', content.ejemplo);
    add('ERROR COMÚN', content.errorComun);

    return SvReadingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(theory.titulo, style: SalaVerdeType.onReading(SalaVerdeType.headline())),
          const SizedBox(height: SalaVerdeSpace.md),
          SvCalloutAccent(
            eyebrow: 'OBJETIVO',
            body: theory.objetivo,
            color: SalaVerdeColors.feltGreen,
            icon: Icons.flag_outlined,
            onReading: true,
          ),
          const SizedBox(height: SalaVerdeSpace.xl),
          ...sections,
          if (content.ideaClave != null && content.ideaClave!.trim().isNotEmpty) ...[
            const SizedBox(height: SalaVerdeSpace.sm),
            SvCalloutAccent(
              eyebrow: 'IDEA CLAVE',
              body: content.ideaClave!,
              // brass puro sobre surfaceReading mide 2.17:1 (falla WCAG
              // AA) — brassDeep mide 5.39:1. Ver
              // FLOPLY_DESIGN_DECISIONS.md #7.
              color: SalaVerdeColors.brassDeep,
              icon: Icons.push_pin_outlined,
              onReading: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Una sección de teoría (QUÉ ES / POR QUÉ IMPORTA / …). Deliberadamente
/// SIN ícono ni color por tipo de sección (a diferencia de la versión
/// anterior, que usaba 7 combinaciones ícono+color distintas) — la
/// jerarquía acá es puramente tipográfica: eyebrow uppercase + cuerpo. Ver
/// "presupuesto de materialidad" (`FLOPLY_DESIGN_LANGUAGE.md` §5.1) y la
/// regla anti-fragmentación de `surfaceReading`. Validado con TN10 (7
/// secciones, párrafos largos) en el playground antes de llegar acá.
class _SectionView extends StatelessWidget {
  const _SectionView({required this.eyebrow, required this.body});

  final String eyebrow;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SalaVerdeSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: SalaVerdeType.onReading(SalaVerdeType.label(), secondary: true)
                .copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 6),
          Text(body, style: SalaVerdeType.onReading(SalaVerdeType.body())),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: SvProgressLinear(
            value: ratio.toDouble(),
            color: SalaVerdeColors.feltGreenBright,
          ),
        ),
        const SizedBox(width: SalaVerdeSpace.md),
        Text('TEORÍA', style: SalaVerdeType.label(color: SalaVerdeColors.textMuted)),
        const SizedBox(width: SalaVerdeSpace.xs),
        Text(
          '$current / $total',
          style: SalaVerdeType.numeric(size: 12, color: SalaVerdeColors.textMuted),
        ),
      ],
    );
  }
}
