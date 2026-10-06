import 'dart:async';

import 'package:flutter/material.dart';

import '../../engine/exercises/laboratory_difficulty.dart';
import '../../l10n/app_strings.dart';
import '../../services/ads/admob_rewarded_ad_service.dart';
import '../../services/ads/rewarded_ad_service.dart';
import '../../services/economy/economy_access_service.dart';
import '../../services/economy/economy_session.dart';
import '../../services/economy/floply_coins_service.dart';
import '../../services/economy/training_quota_service.dart';
import '../../services/premium/premium_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import '../academy/widgets/playable_table_exercise_view.dart';
import '../economy/widgets/economy_blocked_view.dart';
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
  const LaboratoryScreen({
    super.key,
    this.controller,
    this.onReviewInAcademy,
    this.coins,
    this.training,
    this.economyAccess,
  });

  /// Permite inyectar un controlador (tests / semilla fija). Si no se
  /// pasa, se crea uno estándar.
  final LabSessionController? controller;

  /// "Repasá en Academia" en la devolución post-respuesta — abre esa
  /// lección puntual y cambia a la pestaña Academia. `null` en tests que
  /// no ejercitan ese enlace (el botón entonces no se muestra, ver
  /// `PlayableTableExerciseView`).
  final ValueChanged<String>? onReviewInAcademy;

  /// Economía (integración con el producto real): la instancia
  /// compartida real la crea `AppShell` — `null` arma instancias propias
  /// (mismo criterio que [controller]) para no romper ningún call site
  /// anterior a esta integración.
  final FloplyCoinsService? coins;
  final TrainingQuotaService? training;
  final EconomyAccessService? economyAccess;

  @override
  State<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends State<LaboratoryScreen>
    with WidgetsBindingObserver {
  late final LabSessionController _controller;
  bool _ownsController = false;

  late final FloplyCoinsService _coins = widget.coins ?? FloplyCoinsService();
  late final TrainingQuotaService _training =
      widget.training ?? TrainingQuotaService();
  bool get _ownsEconomy => widget.coins == null;
  late final EconomyAccessService _economyAccess = widget.economyAccess ??
      EconomyAccessService(
        coins: _coins,
        training: _training,
        premium: StubPremiumService(),
        ads: AdMobRewardedAdService(coins: _coins),
      );

  /// Entrenamiento EXTRA (más allá del cupo gratis, sección 11): sesión
  /// de tiempo real contra Coins, igual mecanismo que Tools/Coach
  /// ([EconomySession], nunca uno propio) — `null` mientras se practica
  /// dentro del cupo gratis o en modo Premium (ninguno de los dos
  /// consume Coins).
  EconomySession? _extraSession;

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
    if (_coins.loading) _coins.load();
    if (_training.loading) _training.load();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onControllerChange);
  }

  /// Termina la sesión EXTRA en cuanto se deja de practicar de verdad
  /// (llega al resumen, o se sale a `idle`) — nunca sigue cobrando
  /// tiempo mientras se mira el resumen o el selector.
  void _onControllerChange() {
    if (_extraSession != null &&
        _controller.phase != LabPhase.question &&
        _controller.phase != LabPhase.feedback) {
      _endExtraSession();
    }
  }

  void _endExtraSession() {
    final session = _extraSession;
    _extraSession = null;
    session?.end();
  }

  void _exitSession() {
    _endExtraSession();
    _controller.exitSession();
  }

  void _backToIdleFromSummary() {
    _endExtraSession();
    _controller.returnToIdle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = _extraSession;
    if (session == null || !session.isActive) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        session.pause();
      case AppLifecycleState.resumed:
        session.resume();
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Confirma el inicio de la sesión según lo que haya decidido
  /// [EconomyAccessService.checkTrainingAccess]: consume 1 Training
  /// Quota (gratis) o arranca la sesión económica (extra) — nunca las
  /// dos, y nunca antes de que el usuario haya confirmado de verdad qué
  /// va a practicar (recién acá, no en `build()`/un rebuild, pedido
  /// explícito: "evitar doble consumo por rebuild/navigation").
  ///
  /// Nunca `await`: el consumo de quota ya actualiza su estado en
  /// memoria (y notifica) de forma síncrona dentro de
  /// `TrainingQuotaService.consumeTraining` — solo el guardado a disco
  /// queda en vuelo, best-effort, igual que el resto de la persistencia
  /// de la economía. Arrancar el ejercicio real nunca debe esperar a que
  /// ese guardado termine.
  void _beginEngineSession(EconomyAccessDecision decision, VoidCallback startEngine) {
    if (decision.status == EconomyAccessStatus.freeTraining) {
      unawaited(_economyAccess.confirmFreeTrainingStart());
    } else if (decision.status == EconomyAccessStatus.accessible) {
      _extraSession = EconomySession(coins: _coins)..start();
    }
    startEngine();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChange);
    _extraSession?.dispose();
    if (_ownsController) _controller.dispose();
    if (_ownsEconomy) {
      _coins.dispose();
      _training.dispose();
    }
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
        // `bottom: true` (antes `false`): con la navbar transparente de
        // `AppShell` (`extendBody: true`), este `SafeArea` reserva el
        // espacio real de la barra — antes era innecesario porque la
        // barra opaca ya lo reservaba por su cuenta.
        child: AnimatedBuilder(
          // También escucha `_coins`: el aviso de "te quedaste sin
          // Coins" durante el entrenamiento EXTRA depende de su saldo en
          // vivo, no solo de la fase del controller.
          animation: Listenable.merge([_controller, _coins]),
          builder: (context, _) {
            // Un ejercicio de mesa (ver LabSessionController.isTableExercise)
            // necesita alto completo, sin scroll — igual que la Academia
            // resuelve esto para PlayableTableExerciseView. El resto de las
            // fases (idle/summary, y los ejercicios que siguen siendo
            // pregunta de texto) mantienen el layout scrolleable de siempre.
            final inSession = _controller.phase == LabPhase.question ||
                _controller.phase == LabPhase.feedback;
            final showTable = _controller.isTableExercise && inSession;
            final onExit = inSession ? _exitSession : null;

            final extraSession = _extraSession;
            final outOfCoinsNow = extraSession != null &&
                extraSession.isActive &&
                _coins.availableTime <= Duration.zero;

            return LayoutBuilder(
              builder: (context, constraints) {
                final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
                final Widget content;
                if (showTable) {
                  content = Padding(
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
                            onReviewInAcademy: widget.onReviewInAcademy,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  content = SingleChildScrollView(
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
                }
                if (!outOfCoinsNow) return content;
                return Stack(
                  children: [
                    content,
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                        child: EconomyBlockedView(
                          access: _economyAccess,
                          decision: _economyAccess.checkTimedAccess(),
                          title: AppStrings.economyRanOutMidSessionTitle,
                          body: AppStrings.economyRanOutMidSessionBody,
                          onAdResult: (_) => setState(() {}),
                          onWait: () => setState(() {}),
                        ),
                      ),
                    ),
                  ],
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
        final decision = _economyAccess.checkTrainingAccess();
        if (decision.status == EconomyAccessStatus.noCoins) {
          return _TrainingBlockedView(
            access: _economyAccess,
            decision: decision,
            onAdResult: (_) => setState(() {}),
          );
        }
        if (_showingCustom) {
          return LaboratoryCustomSelector(
            onBack: () => setState(() => _showingCustom = false),
            onStart: (kinds, sessionLength) {
              setState(() => _showingCustom = false);
              _beginEngineSession(
                decision,
                () => _controller.startNewEngineSession(
                  customScenarioKinds: kinds.toList(),
                  customSessionLength: sessionLength,
                ),
              );
            },
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (decision.status == EconomyAccessStatus.accessible) ...[
              _ExtraTrainingBanner(resetDate: decision.trainingResetDate),
              const SizedBox(height: SalaVerdeSpace.md),
            ],
            _IdleView(
              onSelectDifficulty: (d) => _beginEngineSession(
                decision,
                () => _controller.startNewEngineSession(labDifficulty: d),
              ),
              onSelectCustom: () => setState(() => _showingCustom = true),
            ),
          ],
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
          // restricción por defecto. Cuenta como un entrenamiento MÁS: pasa
          // otra vez por el gate económico (quota si queda, si no Coins).
          onKeepPracticing: () => _beginEngineSession(
            _economyAccess.checkTrainingAccess(),
            () => _controller.startNewEngineSession(
              opponentProfile: _controller.activeOpponentProfile,
              difficulty: _controller.activeDifficulty,
              labDifficulty: _controller.activeLabDifficulty,
              customScenarioKinds: _controller.activeCustomScenarioKinds,
            ),
          ),
          onBackToLab: _backToIdleFromSummary,
        );
    }
  }
}

/// Aviso de "esto va a consumir Coins" — siempre visible ANTES de elegir
/// dificultad cuando ya no queda cupo gratis (nunca se cobra nada hasta
/// que el usuario de verdad elige una dificultad/arranca Custom, ver
/// [_LaboratoryScreenState._beginEngineSession]): transparencia primero,
/// nunca una sorpresa después.
class _ExtraTrainingBanner extends StatelessWidget {
  const _ExtraTrainingBanner({required this.resetDate});

  final DateTime? resetDate;

  @override
  Widget build(BuildContext context) {
    return SvSurfacePanel(
      borderColor: SalaVerdeColors.brassBright.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SvCalloutAccent(
            eyebrow: AppStrings.economyTrainingQuotaExhaustedTitle,
            body: AppStrings.economyExtraTrainingConfirmBody,
            color: SalaVerdeColors.brassBright,
            icon: Icons.bolt_rounded,
          ),
          if (resetDate != null) ...[
            const SizedBox(height: SalaVerdeSpace.sm),
            Text(
              AppStrings.economyTrainingResetHint(_untilMidnight(resetDate!)),
              style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  /// [resetDate] es el día calendario (medianoche) del último reset —
  /// el PRÓXIMO reset real es la medianoche siguiente a ese día.
  static String _untilMidnight(DateTime resetDate) {
    final nextMidnight = DateTime(resetDate.year, resetDate.month, resetDate.day + 1);
    final diff = nextMidnight.difference(DateTime.now());
    if (diff.inHours <= 0) return 'en unos minutos';
    return 'en ${diff.inHours}h';
  }
}

/// "Ya usaste tus entrenamientos gratis y no tenés Coins" — mismo
/// [EconomyBlockedView] de siempre, con el agregado del aviso de cuándo
/// vuelve el cupo diario (dato real de [TrainingQuotaService], nunca
/// inventado).
class _TrainingBlockedView extends StatelessWidget {
  const _TrainingBlockedView({
    required this.access,
    required this.decision,
    required this.onAdResult,
  });

  final EconomyAccessService access;
  final EconomyAccessDecision decision;
  final ValueChanged<RewardedAdShowResult> onAdResult;

  @override
  Widget build(BuildContext context) {
    return EconomyBlockedView(
      access: access,
      decision: decision,
      title: AppStrings.economyTrainingQuotaExhaustedTitle,
      body: AppStrings.economyTrainingQuotaExhaustedBody,
      onAdResult: onAdResult,
      onWait: null,
    );
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

