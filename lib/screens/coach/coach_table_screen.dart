import 'package:flutter/material.dart';

import '../../engine/coach/hand_table_controller.dart';
import '../../engine/pedagogy/table_lesson.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';
import '../academy/widgets/poker_table_view.dart';
import 'coach_table_snapshot.dart';
import 'widgets/coach_action_bar.dart';
import 'widgets/coach_hand_over_banner.dart';
import 'widgets/coach_hand_review_panel.dart';
import 'widgets/coach_tools_drawer.dart';

/// La Mesa con Coach: una mano jugable completa de 6-max contra 5 bots.
/// Compone piezas ya existentes — [PokerTableView] (la misma mesa de
/// Academia/Laboratorio), [HandTableController] (el motor real) y los
/// widgets de esta carpeta — nunca una segunda mesa ni un segundo motor.
///
/// **La mano se juega de punta a punta sin interrupciones** (evolución de
/// la Mesa Coach, secciones 1/7): el héroe decide, la mesa sigue sola —
/// bots y avances de calle, uno a la vez — hasta el showdown/fold, y
/// recién ahí aparece el análisis del Coach ([CoachHandReviewPanel]),
/// nunca a mitad de la mano. Un botón siempre visible ("Herramientas de
/// ayuda") abre un panel contextual sin sacar al usuario de esta misma
/// pantalla — ver [_openTools].
///
/// **[controller] externo**: si el caller inyecta un [HandTableController]
/// existente, `CoachTableScreen` lo usa sin disponer ni crear el suyo. El
/// caller (p.ej. `HomeScreen`) es el dueño y lo dispone cuando corresponde.
/// Si [controller] es `null`, `CoachTableScreen` crea y dispone el suyo.
class CoachTableScreen extends StatefulWidget {
  const CoachTableScreen({super.key, this.controller});

  /// Controlador externo (sesión previa) — `null` crea uno nuevo.
  final HandTableController? controller;

  @override
  State<CoachTableScreen> createState() => _CoachTableScreenState();
}

class _CoachTableScreenState extends State<CoachTableScreen> {
  late final HandTableController _controller =
      widget.controller ?? HandTableController();

  /// `true` si este widget es dueño del controlador y debe disponer de él.
  bool get _ownsController => widget.controller == null;

  /// El análisis es opcional (evolución de la Mesa Coach, sección 3): esta
  /// bandera es puramente de la pantalla, no del motor — `false` hasta
  /// que el usuario toca "Ver análisis" en [CoachHandOverBanner], y se
  /// resetea al arrancar la siguiente mano para que nunca aparezca de
  /// entrada en la mano nueva.
  bool _showReview = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    // Si el controller es externo (sesión guardada), reanudar donde quedó.
    if (!_ownsController) _controller.resume();
  }

  void _onChange() => setState(() {});

  void _startNewHand() {
    setState(() => _showReview = false);
    _controller.startNewHand();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    if (_ownsController) {
      _controller.dispose();
    } else {
      // Pausar la mano para que los bots no sigan jugando en segundo plano.
      _controller.pause();
    }
    super.dispose();
  }

  void _openTools() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SalaVerdeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(SalaVerdeRadius.panel)),
      ),
      builder: (_) => CoachToolsDrawer(
        state: _controller.state,
        heroSlot: _controller.heroSlot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = CoachTableSnapshot.from(
      _controller.state,
      heroSlot: _controller.heroSlot,
      revealAll: _controller.isShowdown,
      winnerSlots: _controller.winnerSlots ?? const {},
      dealProgress: _controller.dealProgress,
    ).withCast(AppUser.current.firstName, 7);

    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onExit: () => Navigator.of(context).pop(), onTools: _openTools),
            Expanded(child: PokerTableView(snapshot: snapshot)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  SalaVerdeSpace.lg, 0, SalaVerdeSpace.lg, SalaVerdeSpace.lg),
              child: _bottomPanel(snapshot),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomPanel(TableSnapshot snapshot) {
    if (_controller.isHandOver) {
      final heroWon = _controller.winnerSlots?.contains(_controller.heroSlot) ?? false;
      final winnerNames = [
        for (final slot in _controller.winnerSlots ?? const <int>{})
          snapshot.seatAt(slot).name ?? snapshot.seatAt(slot).label,
      ];
      if (_showReview) {
        return CoachHandReviewPanel(
          heroWon: heroWon,
          winnerNames: winnerNames,
          review: _controller.handReview!,
          onNewHand: _startNewHand,
        );
      }
      return CoachHandOverBanner(
        heroWon: heroWon,
        winnerNames: winnerNames,
        onViewAnalysis: () => setState(() => _showReview = true),
        onContinue: _startNewHand,
      );
    }

    if (_controller.isHeroTurn) {
      return CoachActionBar(
        legalActions: _controller.heroLegalActions,
        minBb: _controller.heroMinRaiseToBb,
        maxBb: _controller.heroMaxRaiseToBb,
        potBb: _controller.state.pot.totalBb,
        onChoose: (action) => _controller.applyHeroAction(action),
      );
    }

    return SvSurfacePanel(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: SalaVerdeSpace.sm),
          Text(AppStrings.coachThinking, style: SalaVerdeType.body()),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onExit, required this.onTools});

  final VoidCallback onExit;
  final VoidCallback onTools;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          SalaVerdeSpace.lg, SalaVerdeSpace.sm, SalaVerdeSpace.lg, SalaVerdeSpace.sm),
      child: Row(
        children: [
          PressableScale(
            onTap: onExit,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SalaVerdeColors.surfaceElevated,
                border: Border.all(color: SalaVerdeColors.borderSubtle),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: SalaVerdeColors.textSecondary),
            ),
          ),
          const SizedBox(width: SalaVerdeSpace.md),
          Expanded(
            child: Text(AppStrings.coachTableTitle, style: SalaVerdeType.title()),
          ),
          PressableScale(
            onTap: onTools,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
                color: SalaVerdeColors.surfaceElevated,
                border: Border.all(color: SalaVerdeColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.handyman_rounded,
                      size: 16, color: SalaVerdeColors.brassBright),
                  const SizedBox(width: 6),
                  Text(AppStrings.coachToolsButton,
                      style: SalaVerdeType.label(color: SalaVerdeColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
