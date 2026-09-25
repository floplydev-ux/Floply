import 'package:flutter/material.dart';

import '../../engine/exercises/laboratory_difficulty.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import '../academy/widgets/playable_table_exercise_view.dart';
import 'lab_session_controller.dart';
import 'widgets/laboratory_custom_selector.dart';
import 'widgets/laboratory_difficulty_selector.dart';
import 'widgets/preflop_session_summary_view.dart';

/// Pantalla del Laboratorio: práctica de ejercicios generados por el
/// motor. Reemplaza al placeholder "Próximamente" de esa pestaña.
///
/// **Fase 7** (`docs/design/FLOPLY_PHASE_7_LABORATORIO.md`): migrado a
/// "Sala Verde". Identidad de sección: `steelBlue`/`steelBlueBright`
/// (ya reservado para Laboratorio desde `SvSectionHeaderVariant`, Fase 3)
/// — el CTA principal sigue siendo `brass` (mismo criterio que Home/
/// Academia/Bankroll: un único color de acción en toda la app).
/// `PlayableTableExerciseView` (mesa) ya estaba migrado desde la Fase 5 y
/// no cambia acá.
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

  /// `true` mientras se muestra el selector de Custom (Fase 8) en vez de
  /// la lista Fácil/Medio/Experto — puramente de UI, nunca toca
  /// `LabPhase`: "configurando Custom" sigue siendo `LabPhase.idle`
  /// (ningún dato de sesión existe todavía), igual que ya cubre el
  /// estado existente sin necesitar una fase nueva.
  bool _showingCustom = false;

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
            // Un ejercicio de mesa (ver LabSessionController.isTableExercise)
            // necesita alto completo, sin scroll — igual que la Academia
            // resuelve esto para PlayableTableExerciseView. El resto de las
            // fases (idle/summary, y los ejercicios que siguen siendo
            // pregunta de texto) mantienen el layout scrolleable de siempre.
            final inSession = _controller.phase == LabPhase.question ||
                _controller.phase == LabPhase.feedback;
            final showTable = _controller.isTableExercise && inSession;
            final onExit = inSession ? _controller.exitSession : null;

            return LayoutBuilder(
              builder: (context, constraints) {
                final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
                if (showTable) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(pad, 16, pad, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LabHeader(onExit: onExit),
                        const SizedBox(height: 12),
                        Expanded(
                          child: PlayableTableExerciseView(
                            controller: _controller,
                            progressAccent: SalaVerdeColors.steelBlueBright,
                            pendingAccent: SalaVerdeColors.steelBlueBright,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LabHeader(onExit: onExit),
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
        if (_showingCustom) {
          return LaboratoryCustomSelector(
            onBack: () => setState(() => _showingCustom = false),
            onStart: (kinds, sessionLength) {
              setState(() => _showingCustom = false);
              _controller.startNewEngineSession(
                customScenarioKinds: kinds.toList(),
                customSessionLength: sessionLength,
              );
            },
          );
        }
        return _IdleView(
          onSelectDifficulty: (d) =>
              _controller.startNewEngineSession(labDifficulty: d),
          onSelectCustom: () => setState(() => _showingCustom = true),
        );
      case LabPhase.question:
      case LabPhase.feedback:
        // Caso límite (Fase 9): `isTableExercise` puede ser `false` si
        // `ExerciseScenarioAdapter.adapt` no encontró ningún concepto
        // evaluable (nunca alcanzable con el usuario real de Laboratorio,
        // que arranca con todo enseñado — sí forzado deliberadamente en
        // tests). No hay tarjeta de texto a la que caer: solo un estado
        // vacío seguro en vez de un ejercicio inexistente.
        return const _NoExerciseAvailable();
      case LabPhase.summary:
        return PreflopSessionSummaryView(
          controller: _controller,
          // Mantiene el mismo perfil/dificultad (o la misma selección
          // Custom, Fase 8) que ya estaban activos — "seguir practicando"
          // no debe volver silenciosamente a la dificultad sin
          // restricción por defecto.
          onKeepPracticing: () => _controller.startNewEngineSession(
            opponentProfile: _controller.activeOpponentProfile,
            difficulty: _controller.activeDifficulty,
            labDifficulty: _controller.activeLabDifficulty,
            customScenarioKinds: _controller.activeCustomScenarioKinds,
          ),
          onBackToLab: _controller.returnToIdle,
        );
    }
  }
}

class _NoExerciseAvailable extends StatelessWidget {
  const _NoExerciseAvailable();

  @override
  Widget build(BuildContext context) {
    return SvSurfacePanel(
      padding: const EdgeInsets.all(SalaVerdeSpace.xl),
      child: Text(
        'No hay ningún ejercicio disponible para practicar todavía.',
        style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
      ),
    );
  }
}

/// Reutiliza `SvSectionHeader` (Fase 3, `level_map.dart` es el otro
/// consumidor real) con `variant: laboratory` — el mismo componente
/// "AppBar de sección" en toda la app, no una versión propia con ícono en
/// círculo. El botón "salir" (solo durante una sesión activa) es el único
/// elemento que `SvSectionHeader` no cubre, así que va como `trailing`.
class _LabHeader extends StatelessWidget {
  const _LabHeader({this.onExit});

  /// Presente solo durante una sesión activa (pregunta/feedback) — `null`
  /// en idle/summary, donde ya hay su propio botón de "volver".
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return SvSectionHeader(
      icon: Icons.science_rounded,
      title: AppStrings.labHeaderTitle,
      subtitle: AppStrings.labHeaderSubtitle,
      variant: SvSectionHeaderVariant.laboratory,
      trailing: onExit == null
          ? null
          : Tooltip(
              message: AppStrings.labExitTooltip,
              child: PressableScale(
                onTap: onExit!,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SalaVerdeColors.surfaceElevated,
                    border: Border.all(color: SalaVerdeColors.borderSubtle),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: SalaVerdeColors.textSecondary, size: 18),
                ),
              ),
            ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.onSelectDifficulty,
    required this.onSelectCustom,
  });

  /// Punto de entrada normal: elegir Fácil/Medio/Experto y arrancar una
  /// sesión ya acotada a esa dificultad (`LabSessionController.
  /// startNewEngineSession(labDifficulty: ...)`).
  final ValueChanged<LaboratoryDifficulty> onSelectDifficulty;

  /// Muestra el selector de Custom (Fase 8) — no arranca nada todavía,
  /// solo revela `LaboratoryCustomSelector` (ver `_LaboratoryScreenState.
  /// _showingCustom`).
  final VoidCallback onSelectCustom;

  @override
  Widget build(BuildContext context) {
    return LaboratoryDifficultySelector(
      onSelect: onSelectDifficulty,
      onSelectCustom: onSelectCustom,
    );
  }
}

