import 'package:flutter/material.dart';

import '../../../engine/pedagogy/theory.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../academy_controller.dart';
import 'lesson_widgets.dart';

/// Fichas de teoría redactada (PASO 4): una teoría por pantalla, con sus
/// secciones (QUÉ ES · POR QUÉ IMPORTA · CÓMO FUNCIONA · …) y navegación
/// CONTINUAR / ATRÁS. Es una sub-fase de [AcademyPhase.theory]: viene después
/// del guion de mesa (si lo hay) y antes de los ejercicios.
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
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('wt${theory.id}'),
            child: _TheoryCard(theory: theory),
          ),
        ),
        const SizedBox(height: 10),
        LessonNavControls(
          canGoBack: !c.isFirstWrittenTheory,
          buttonLabel: c.isLastWrittenTheory
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

    void add(_Sec kind, String? body) {
      if (body == null || body.trim().isEmpty) return;
      sections.add(_SectionView(kind: kind, body: body));
      sections.add(const SizedBox(height: 10));
    }

    add(_Sec.queEs, content.queEs);
    add(_Sec.porQue, content.porQueImporta);
    add(_Sec.como, content.comoFunciona);
    add(_Sec.cuando, content.cuandoLoUso);
    add(_Sec.cuandoNo, content.cuandoNo);
    add(_Sec.ejemplo, content.ejemplo);
    add(_Sec.error, content.errorComun);
    if (sections.isNotEmpty) sections.removeLast(); // drop trailing gap

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          theory.titulo,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _ObjectivePill(text: theory.objetivo),
        const SizedBox(height: 16),
        ...sections,
        if (content.ideaClave != null && content.ideaClave!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _KeyIdea(text: content.ideaClave!),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ObjectivePill extends StatelessWidget {
  const _ObjectivePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.violetPrimary.withValues(alpha: 0.1),
        border:
            Border.all(color: AppColors.violetPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_rounded, size: 15, color: AppColors.violetBright),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Sec { queEs, porQue, como, cuando, cuandoNo, ejemplo, error }

class _SectionView extends StatelessWidget {
  const _SectionView({required this.kind, required this.body});

  final _Sec kind;
  final String body;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (kind) {
      _Sec.queEs => (Icons.lightbulb_rounded, AppColors.gold, 'QUÉ ES'),
      _Sec.porQue => (
          Icons.trending_up_rounded,
          AppColors.violetBright,
          'POR QUÉ IMPORTA'
        ),
      _Sec.como => (
          Icons.settings_rounded,
          AppColors.textSecondary,
          'CÓMO FUNCIONA'
        ),
      _Sec.cuando => (
          Icons.check_circle_rounded,
          AppColors.neonGreen,
          'CUÁNDO LO USÁS'
        ),
      _Sec.cuandoNo => (Icons.block_rounded, AppColors.warning, 'CUÁNDO NO'),
      _Sec.ejemplo => (
          Icons.casino_rounded,
          AppColors.neonGreenBright,
          'EJEMPLO'
        ),
      _Sec.error => (
          Icons.warning_amber_rounded,
          AppColors.danger,
          'ERROR COMÚN'
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyIdea extends StatelessWidget {
  const _KeyIdea({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.violetPrimary.withValues(alpha: 0.22),
            AppColors.violetDeep.withValues(alpha: 0.22),
          ],
        ),
        border:
            Border.all(color: AppColors.violetBright.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.push_pin_rounded, size: 14, color: AppColors.violetBright),
              SizedBox(width: 6),
              Text(
                'IDEA CLAVE',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.violetBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: AppColors.surfaceElevated),
                  FractionallySizedBox(
                    widthFactor: ratio.toDouble(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.violetBright,
                            AppColors.violetPrimary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'TEORÍA $current / $total',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

