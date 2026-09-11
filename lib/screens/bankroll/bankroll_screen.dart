import 'package:flutter/material.dart';

import '../../engine/bankroll/bankroll_topic.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
// Reutiliza los controles de navegación y la barra de progreso del
// recorrido de la Academia: son genéricos (current/total, callbacks), sin
// ningún acoplamiento a currículo — el mismo criterio que ya se usó para
// unificar ATRÁS/CONTINUAR entre las fases de la Academia.
import '../academy/widgets/lesson_widgets.dart';

/// Módulo complementario de Bankroll: una ficha por tema, con navegación
/// ATRÁS / CONTINUAR — mismo lenguaje visual que una teoría de la
/// Academia, pero **fuera** del currículo de 326 teorías: sin ID, sin
/// prerrequisitos, sin `orden_global`, sin ejercicios. Se llega acá desde
/// Home, no desde el mapa de niveles.
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
      backgroundColor: AppColors.background,
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
              ),
              const SizedBox(height: 16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonItemProgress(current: _step + 1, total: _topics.length),
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('bankroll$_step'),
            child: _TopicCard(topic: topic),
          ),
        ),
        const SizedBox(height: 10),
        LessonNavControls(
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

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});

  final BankrollTopic topic;

  @override
  Widget build(BuildContext context) {
    final content = topic.contenido;
    final sections = <Widget>[];

    void add(String label, IconData icon, Color color, String? body) {
      if (body == null || body.trim().isEmpty) return;
      sections.add(_Section(label: label, icon: icon, color: color, body: body));
      sections.add(const SizedBox(height: 10));
    }

    add('QUÉ ES', Icons.savings_rounded, AppColors.gold, content.queEs);
    add('POR QUÉ IMPORTA', Icons.trending_up_rounded, AppColors.violetBright,
        content.porQueImporta);
    add('CÓMO FUNCIONA', Icons.settings_rounded, AppColors.textSecondary,
        content.comoFunciona);
    add('CUÁNDO LO USÁS', Icons.check_circle_rounded, AppColors.neonGreen,
        content.cuandoLoUso);
    add('CUÁNDO NO', Icons.block_rounded, AppColors.warning, content.cuandoNo);
    add('EJEMPLO', Icons.casino_rounded, AppColors.neonGreenBright, content.ejemplo);
    add('ERROR COMÚN', Icons.warning_amber_rounded, AppColors.danger,
        content.errorComun);
    if (sections.isNotEmpty) sections.removeLast();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          topic.titulo,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _ObjectivePill(text: topic.objetivo),
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
        color: AppColors.gold.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_rounded, size: 15, color: AppColors.gold),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.icon,
    required this.color,
    required this.body,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String body;

  @override
  Widget build(BuildContext context) {
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
            AppColors.gold.withValues(alpha: 0.22),
            AppColors.violetDeep.withValues(alpha: 0.22),
          ],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.push_pin_rounded, size: 14, color: AppColors.gold),
              SizedBox(width: 6),
              Text(
                'IDEA CLAVE',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.gold,
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

class _BankrollDone extends StatelessWidget {
  const _BankrollDone();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.savings_rounded, size: 56, color: AppColors.gold),
        const SizedBox(height: 16),
        const Text(
          AppStrings.bankrollDone,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            AppStrings.bankrollDoneBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        LessonSecondaryButton(
          label: AppStrings.academyBackToMap,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
