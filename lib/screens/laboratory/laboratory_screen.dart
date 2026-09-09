import 'package:flutter/material.dart';

import '../../engine/evaluation/evaluation_result.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable_scale.dart';
import 'lab_session_controller.dart';
import 'widgets/exercise_card.dart';
import 'widgets/feedback_panel.dart';
import 'widgets/session_summary.dart';

/// Pantalla del Laboratorio: práctica de ejercicios generados por el
/// motor. Reemplaza al placeholder "Próximamente" de esa pestaña.
class LaboratoryScreen extends StatefulWidget {
  const LaboratoryScreen({super.key, this.controller});

  /// Permite inyectar un controlador (tests / semilla fija). Si no se
  /// pasa, se crea uno estándar.
  final LabSessionController? controller;

  @override
  State<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends State<LaboratoryScreen> {
  late final LabSessionController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? LabSessionController();
    _ownsController = widget.controller == null;
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.backgroundGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _LabHeader(),
                      const SizedBox(height: 18),
                      _body(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _body() {
    switch (_controller.phase) {
      case LabPhase.idle:
        return _IdleView(onStart: _controller.start);
      case LabPhase.question:
        return _QuestionView(controller: _controller);
      case LabPhase.feedback:
        return _FeedbackView(controller: _controller);
      case LabPhase.summary:
        return SessionSummary(
          controller: _controller,
          onRestart: _controller.start,
        );
    }
  }
}

class _LabHeader extends StatelessWidget {
  const _LabHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonGreen.withValues(alpha: 0.18),
          ),
          child: const Icon(Icons.science_rounded,
              color: AppColors.neonGreenBright, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.labHeaderTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                AppStrings.labHeaderSubtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2A20), Color(0xFF081712)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Posición y apertura preflop',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cada ejercicio es una situación distinta generada por el motor. '
            'No hay respuestas para memorizar: importa el razonamiento y el '
            'valor esperado de tu decisión.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          _PrimaryButton(label: AppStrings.labStartSession, onTap: onStart),
        ],
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.controller});

  final LabSessionController controller;

  @override
  Widget build(BuildContext context) {
    final exercise = controller.current!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressBar(
          current: controller.answered + 1,
          total: controller.sessionLength,
        ),
        const SizedBox(height: 16),
        ExerciseCard(
          exercise: exercise,
          selectedOptionIds: controller.selectedOptionIds,
          selectedReasoningIds: controller.selectedReasoningIds,
          onToggleOption: (id) => controller.toggleOption(id, single: true),
          onToggleReasoning: controller.toggleReasoning,
          conceptName: _conceptName,
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: AppStrings.labConfirm,
          onTap: controller.canConfirm ? controller.confirm : null,
        ),
      ],
    );
  }

  String _conceptName(String id) =>
      controller.engine.concepts.tryById(id)?.name ?? id;
}

class _FeedbackView extends StatelessWidget {
  const _FeedbackView({required this.controller});

  final LabSessionController controller;

  @override
  Widget build(BuildContext context) {
    final EvaluationResult result = controller.lastResult!;
    final exercise = controller.current!;
    final last = controller.answered >= controller.sessionLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressBar(
          current: controller.answered,
          total: controller.sessionLength,
        ),
        const SizedBox(height: 16),
        FeedbackPanel(
          result: result,
          strategy: exercise.strategy,
          showAdvanced: controller.showAdvanced,
          onToggleAdvanced: controller.toggleAdvanced,
          conceptName: (id) =>
              controller.engine.concepts.tryById(id)?.name ?? id,
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: last ? AppStrings.labSessionSummary : AppStrings.labNext,
          onTap: controller.next,
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});

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
              height: 8,
              child: Stack(
                children: [
                  Container(color: AppColors.surfaceElevated),
                  FractionallySizedBox(
                    widthFactor: ratio.toDouble(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonGreenBright,
                            AppColors.neonGreen
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
          AppStrings.labProgress(current.clamp(0, total), total),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: PressableScale(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.neonGreenBright, AppColors.neonGreen],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.neonGreen.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.6,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
