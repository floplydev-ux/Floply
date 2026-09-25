import 'package:flutter/material.dart';

import '../../engine/bankroll/bankroll_topic.dart';
import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import '../academy/widgets/lesson_widgets.dart';

/// Módulo complementario de Bankroll: una ficha por tema, con navegación
/// ATRÁS / CONTINUAR — mismo lenguaje visual que una teoría de la
/// Academia, pero **fuera** del currículo de 326 teorías: sin ID, sin
/// prerrequisitos, sin `orden_global`, sin ejercicios. Se llega acá desde
/// Home, no desde el mapa de niveles.
///
/// **Fase 4** (`docs/design/FLOPLY_PHASE_4_LESSON_FLOW_HEADER.md`): migrado
/// a "Sala Verde" junto con `LessonFlowHeader` — dejar el header nuevo
/// sobre un cuerpo con el patrón viejo (7 secciones color/ícono propio +
/// "IDEA CLAVE" en gradiente dorado-violeta, idéntico al anti-patrón ya
/// corregido en `written_theory_view.dart` en la Fase 3) habría creado una
/// costura visual peor que la que esta fase busca cerrar. Reutiliza
/// componentes ya existentes (`SvReadingCard`, `SvCalloutAccent`,
/// `SvProgressLinear`, `SvLessonNavControls`) — cero componentes nuevos de
/// superficie, sin convertirse en un rediseño de Bankroll.
class BankrollScreen extends StatefulWidget {
  const BankrollScreen({super.key});

  @override
  State<BankrollScreen> createState() => _BankrollScreenState();
}

class _BankrollScreenState extends State<BankrollScreen> {
  int _step = 0;

  static const _topics = BankrollTopics.all;

  @override
  Widget build(BuildContext context) {
    final total = _topics.length;
    final done = _step >= total;

    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LessonFlowHeader(
                title: AppStrings.bankrollTitle,
                subtitle: AppStrings.bankrollScreenSubtitle,
                onBack: () => Navigator.of(context).maybePop(),
                variant: LessonFlowHeaderVariant.bankroll,
              ),
              const SizedBox(height: SalaVerdeSpace.lg),
              Expanded(
                child: done ? const _BankrollDone() : _buildStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    final topic = _topics[_step];
    final current = _step + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Progress(current: current, total: _topics.length),
        const SizedBox(height: SalaVerdeSpace.md),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('bankroll$_step'),
            child: _TopicCard(topic: topic),
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        SvLessonNavControls(
          canGoBack: _step > 0,
          buttonLabel: _step == _topics.length - 1
              ? AppStrings.academySeeResult
              : AppStrings.academyContinue,
          onBack: () => setState(() => _step = (_step - 1).clamp(0, _topics.length - 1)),
          onNext: () => setState(() => _step++),
        ),
      ],
    );
  }
}

/// Misma forma que `_Progress` de `written_theory_view.dart` (barra +
/// etiqueta + contador tabular; acá la etiqueta dice "TEMA" en vez de
/// "TEORÍA" — decir "BANKROLL" habría repetido el título del header
/// arriba). El temperamento de Bankroll es `brass`,
/// pero se usa `brassDeep` acá (relleno silencioso, fuera de la card de
/// lectura, sobre `background` oscuro) para no competir con el único
/// relleno brillante de la pantalla: el botón CONTINUAR/VER RESULTADO
/// (`FLOPLY_ANTI_GENERIC.md` 0.2 — brass como máximo una vez como acento
/// protagonista por pantalla).
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
            color: SalaVerdeColors.brassDeep,
          ),
        ),
        const SizedBox(width: SalaVerdeSpace.md),
        Text('TEMA', style: SalaVerdeType.label(color: SalaVerdeColors.textMuted)),
        const SizedBox(width: SalaVerdeSpace.xs),
        Text(
          '$current / $total',
          style: SalaVerdeType.numeric(size: 12, color: SalaVerdeColors.textMuted),
        ),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});

  final BankrollTopic topic;

  @override
  Widget build(BuildContext context) {
    final content = topic.contenido;
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
          Text(topic.titulo, style: SalaVerdeType.onReading(SalaVerdeType.headline())),
          const SizedBox(height: SalaVerdeSpace.md),
          SvCalloutAccent(
            eyebrow: 'OBJETIVO',
            body: topic.objetivo,
            // brass puro mide 2.17:1 sobre surfaceReading (falla WCAG AA) —
            // brassDeep mide 5.39:1. Mismo hallazgo que
            // FLOPLY_DESIGN_DECISIONS.md #7, aplicado acá.
            color: SalaVerdeColors.brassDeep,
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

/// Misma regla anti-fragmentación que `written_theory_view.dart`: sin
/// ícono ni color por sección, jerarquía puramente tipográfica.
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

class _BankrollDone extends StatelessWidget {
  const _BankrollDone();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.savings_rounded, size: 56, color: SalaVerdeColors.brassBright),
        const SizedBox(height: SalaVerdeSpace.lg),
        Text(
          AppStrings.bankrollDone,
          textAlign: TextAlign.center,
          style: SalaVerdeType.title(),
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SalaVerdeSpace.xl),
          child: Text(
            AppStrings.bankrollDoneBody,
            textAlign: TextAlign.center,
            style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.xxl),
        SvButtonSecondary(
          label: AppStrings.academyBackToMap,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
