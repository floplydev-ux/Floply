import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../poker/deck.dart';
import '../poker/evaluator/hand_evaluator.dart';
import '../poker/game/action_resolver.dart';
import '../poker/game/game_state.dart';
import '../poker/game/legal_action_engine.dart';
import '../poker/game/opponent_policy.dart';
import '../poker/game/scenario_builder.dart';
import '../poker/hole_cards.dart';
import '../poker/poker_action.dart';
import '../../services/poker_audio_service.dart';
import 'coach_analyzer.dart';
import 'hero_decision_record.dart';

/// Orquesta una mano jugable completa de 6-max: el héroe (slot fijo)
/// contra 5 bots reales, de punta a punta — preflop → flop → turn → río
/// → showdown/fold, todo sobre el motor real ([GameState]/
/// [ActionResolver]/[LegalActionEngine]/[OpponentPolicy]), nunca un motor
/// propio. Ninguna calle se genera aislada: cada decisión (del héroe o
/// de un bot) parte de [ActionResolver.apply] sobre el estado anterior,
/// así que el historial completo de la mano queda en [state] en todo
/// momento.
///
/// **La mano se juega completa, sin correcciones a mitad de camino**
/// (evolución de la Mesa Coach): [applyHeroAction] aplica la acción real
/// del héroe y sigue de largo — resuelve a los bots y avanza de calle
/// sola, un paso a la vez con una pausa de ~1.5s entre cada uno
/// ([_stepDelay]) — hasta que vuelve a ser el turno del héroe o la mano
/// termina.
///
/// **Animaciones mínimas:**
///  - Deal: al arrancar cada mano, las cartas aparecen de a una por
///    asiento con [_dealStepDelay] (150ms) entre cada una — los bots
///    muestran dorso, el héroe ve su mano boca arriba.
///  - Pot award: al finalizar la mano, el stack del ganador se actualiza
///    después de una pausa de [_awardDelay] (800ms) para que el usuario
///    vea el estado "pot en mesa, stacks viejos" antes de que se mueva el
///    dinero.
///
/// **Cancelación limpia:** toda espera asíncrona usa un único [_stepTimer]
/// (Timer cancelable) + [_stepCompleter] (para desbloquear el await desde
/// [dispose] o al iniciar una nueva mano). La generación [_generation]
/// actúa como "token de cancelación": cuando sube, cualquier bucle que
/// guardó el valor previo abandona su iteración de inmediato.
///
/// **Bote sin side pots**: hereda la limitación ya documentada de
/// `PotManager` ("Alcance de esta pasada: solo bote principal") — con
/// stacks similares entre bots (ver [_rebuyIfBusted]) esto rara vez
/// importa en la práctica; no se implementa acá porque tocaría el motor
/// central, fuera de lo que amerita esta pasada.
class HandTableController extends ChangeNotifier {
  HandTableController({
    this.heroSlot = 0,
    this.startingStackBb = 100,
    Random? random,
    Duration stepDelay = const Duration(milliseconds: 1500),
    Duration dealStepDelay = const Duration(milliseconds: 150),
    Duration awardDelay = const Duration(milliseconds: 800),
  })  : _random = random ?? Random(),
        _stepDelay = stepDelay,
        _dealStepDelay = dealStepDelay,
        _awardDelay = awardDelay {
    _buttonSlot = (heroSlot + 3) % GameState.seatCount;
    _stacksBb = {
      for (var s = 0; s < GameState.seatCount; s++) s: startingStackBb,
    };
    _startNewHand();
    unawaited(_dealAndPlay());
  }

  final int heroSlot;
  final double startingStackBb;
  final Random _random;

  // ---------------------------------------------------------------------------
  // Delays / timings
  // ---------------------------------------------------------------------------

  /// Pausa entre cada acción de un bot o avance de calle. 1.5s da la
  /// sensación de "mesa online en tiempo real" sin acelerar tanto que se
  /// vuelva difícil seguir qué ocurre.
  ///
  /// Inyectable por el constructor para que los tests de rotación de botón
  /// puedan usar `Duration.zero` y no esperar 1.5s × N bots.
  final Duration _stepDelay;

  /// Intervalo entre cada carta repartida en la animación de deal (6 × 150ms
  /// = 900ms en total para las 6 cartas).
  final Duration _dealStepDelay;

  /// Pausa antes de que el stack del ganador se actualice visualmente al
  /// finalizar la mano — el usuario ve el estado "pot sobre la mesa,
  /// stacks sin tocar" antes de que se mueva el dinero.
  final Duration _awardDelay;

  // ---------------------------------------------------------------------------
  // Estado de la mano
  // ---------------------------------------------------------------------------

  late int _buttonSlot;
  late Map<int, double> _stacksBb;

  late GameState _state;
  GameState get state => _state;

  bool _disposed = false;

  final List<HeroDecisionRecord> _decisions = [];

  /// Las decisiones reales del héroe en la mano en curso (o la que acaba
  /// de terminar), en orden — la base del análisis de fin de mano.
  List<HeroDecisionRecord> get decisions => List.unmodifiable(_decisions);

  bool _handOver = false;
  bool get isHandOver => _handOver;

  /// `true` solo cuando la mano terminó con showdown real (río completo con
  /// 2+ jugadores activos o all-in). `false` cuando terminó por fold-out
  /// (todos excepto uno se retiraron) — en ese caso el ganador NO está
  /// obligado a mostrar sus cartas.
  bool _isShowdown = false;
  bool get isShowdown => _isShowdown;

  /// `true` una vez que el bote ya se transfirió al ganador (stack
  /// actualizado). `false` durante el intervalo [_awardDelay] al final de
  /// la mano, para que la UI pueda mostrar el estado "pot en mesa" antes
  /// de que se mueva el dinero.
  bool _potAwarded = false;
  bool get potAwarded => _potAwarded;

  /// Slots ganadores de la mano actual — `null` hasta que termina.
  Set<int>? _winnerSlots;
  Set<int>? get winnerSlots => _winnerSlots;

  /// El análisis del Coach para la mano que acaba de terminar — `null`
  /// mientras la mano sigue en curso.
  HandReview? get handReview => _handOver
      ? CoachAnalyzer.analyzeHand(
          decisions: _decisions,
          heroSlot: heroSlot,
          heroWon: _winnerSlots?.contains(heroSlot) ?? false,
        )
      : null;

  // ---------------------------------------------------------------------------
  // Deal animation
  // ---------------------------------------------------------------------------

  /// Cuántas cartas de las 6 ya "cayeron" en la animación de deal.
  /// 0 = sin cartas; 6 = todas repartidas.
  /// Los slots 0..(_dealProgress-1) ya tienen cartas visibles.
  int _dealProgress = 6;
  int get dealProgress => _dealProgress;

  // ---------------------------------------------------------------------------
  // Hero queries
  // ---------------------------------------------------------------------------

  bool get isHeroTurn => !_handOver && _state.toActSlot == heroSlot;

  Set<ActionType> get heroLegalActions =>
      isHeroTurn ? LegalActionEngine.legalActionTypes(_state) : const {};

  double? get heroMinRaiseToBb => isHeroTurn &&
          (heroLegalActions.contains(ActionType.raise) ||
              heroLegalActions.contains(ActionType.bet))
      ? LegalActionEngine.minRaiseToBb(_state)
      : null;

  double? get heroMaxRaiseToBb =>
      isHeroTurn && heroLegalActions.isNotEmpty
          ? LegalActionEngine.maxRaiseToBb(_state)
          : null;

  // ---------------------------------------------------------------------------
  // Pausa / reanudación
  // ---------------------------------------------------------------------------

  bool _paused = false;

  /// Pausa el procesamiento de bots y la animación de reparto. La mano
  /// queda exactamente en el estado en que estaba — cuando el usuario
  /// vuelva a entrar, [resume] la reanuda desde ese punto.
  void pause() {
    if (_paused || _disposed) return;
    _paused = true;
    _generation++;
    _cancelCurrentStep();
    _notify();
  }

  /// Reanuda el procesamiento luego de [pause]. Si era turno de un bot,
  /// lo retoma; si la animación de reparto no había terminado, la continúa.
  void resume() {
    if (!_paused || _disposed) return;
    _paused = false;
    _notify();
    if (_handOver) return;
    if (_dealProgress < GameState.seatCount) {
      unawaited(_resumeDeal());
    } else if (!isHeroTurn) {
      unawaited(_continueAfterResume());
    }
  }

  Future<void> _resumeDeal() async {
    final gen = _generation;
    for (var slot = _dealProgress; slot < GameState.seatCount; slot++) {
      await _delay(_dealStepDelay);
      if (_disposed || _generation != gen) return;
      _dealProgress = slot + 1;
      PokerAudioService.instance.play(PokerAudio.cardDeal);
      _notify();
    }
    if (_disposed || _generation != gen) return;
    await _playOutIfNeeded();
  }

  Future<void> _continueAfterResume() async {
    await _resolveUntilHeroOrEnd();
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Cancelación asíncrona
  // ---------------------------------------------------------------------------

  /// Timer activo — un único timer a la vez en toda la clase. Se cancela
  /// explícitamente en [dispose] y al iniciar una mano nueva.
  Timer? _stepTimer;

  /// Completer del await actual — completarlo desbloquea la espera sin
  /// esperar a que el timer dispare. Se usa en [dispose] y al cancelar
  /// un ciclo en marcha.
  Completer<void>? _stepCompleter;

  /// Contador de generación: se incrementa cada vez que se empieza una
  /// mano nueva. Cualquier bucle async que guardó el valor previo se
  /// aborta al compararlo con `_generation`.
  int _generation = 0;

  // ---------------------------------------------------------------------------
  // Acciones públicas
  // ---------------------------------------------------------------------------

  /// Aplica la acción real del héroe y sigue la mano sola.
  Future<void> applyHeroAction(PokerAction action) async {
    if (!isHeroTurn) return;
    final before = _state;
    _state = ActionResolver.apply(_state, action);
    _decisions.add(HeroDecisionRecord(
      before: before,
      action: action,
      after: _state,
      street: before.street,
    ));
    PokerAudioService.instance.play(_actionAudio(action));
    if (_actionInvolvesChips(action)) {
      PokerAudioService.instance.play(PokerAudio.chipsPlace);
    }
    await _settleIfHandOver();
    _notify();
    if (!_handOver) await _resolveUntilHeroOrEnd();
    _notify();
  }

  /// Empieza una mano nueva: cancela cualquier ciclo en marcha, rota el
  /// botón, hace rebuy a quien se quedó sin fichas y reparte cartas nuevas
  /// con animación de deal.
  Future<void> startNewHand() async {
    // Cancelar cualquier ciclo en marcha (bots, deal).
    _generation++;
    _cancelCurrentStep();

    // Si el bote todavía no fue otorgado (animación en curso), otorgarlo
    // ahora antes de empezar la nueva mano — así los stacks de la mano
    // siguiente parten del estado correcto.
    if (_handOver && !_potAwarded && _winnerSlots != null) {
      _state = _awardPot(_state, _winnerSlots!);
      _syncStacks();
      _potAwarded = true;
    }

    _buttonSlot = (_buttonSlot - 1) % GameState.seatCount;
    _startNewHand();
    _notify();
    await _dealAndPlay();
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  Future<void> _dealAndPlay() async {
    final gen = _generation;
    await _dealAnimated();
    if (_disposed || _generation != gen) return;
    await _playOutIfNeeded();
  }

  Future<void> _playOutIfNeeded() async {
    if (!isHeroTurn && !_handOver) await _resolveUntilHeroOrEnd();
    _notify();
  }

  void _startNewHand() {
    _handOver = false;
    _isShowdown = false;
    _winnerSlots = null;
    _potAwarded = false;
    _dealProgress = 0;
    _decisions.clear();
    _rebuyIfBusted();

    final deck = Deck(_random);
    final hands = <int, HoleCards>{
      for (var s = 0; s < GameState.seatCount; s++) s: deck.dealHoleCards(),
    };
    _state = ScenarioBuilder.freshHand(
      deck: deck,
      buttonSlot: _buttonSlot,
      stackOverridesBb: _stacksBb,
      explicitHandBySlot: hands,
    );
  }

  void _rebuyIfBusted() {
    for (final slot in _stacksBb.keys.toList()) {
      if (_stacksBb[slot]! <= 0) _stacksBb[slot] = startingStackBb;
    }
  }

  /// Animación de deal: hace aparecer las cartas de a una por asiento
  /// (dorso para bots, boca arriba para el héroe) con [_dealStepDelay]
  /// entre cada una. El orden es 0..5 (slot por slot, no posición de
  /// mesa). Espera 2 segundos antes de arrancar para que la mesa se vea
  /// vacía un momento — "mesa limpia antes del reparto".
  Future<void> _dealAnimated() async {
    final gen = _generation;
    await _delay(const Duration(seconds: 2));
    if (_disposed || _generation != gen) return;
    for (var slot = 0; slot < GameState.seatCount; slot++) {
      await _delay(_dealStepDelay);
      if (_disposed || _generation != gen) return;
      _dealProgress = slot + 1;
      PokerAudioService.instance.play(PokerAudio.cardDeal);
      _notify();
    }
  }

  /// Resuelve bots (uno por uno) y avanza de calle cuantas veces haga
  /// falta, hasta que sea el turno del héroe de nuevo o la mano termine
  /// — con [_stepDelay] y un `notifyListeners()` entre cada paso.
  Future<void> _resolveUntilHeroOrEnd() async {
    final gen = _generation;
    var guard = 0;
    while (!_handOver && _state.toActSlot != heroSlot) {
      await _delay(_stepDelay);
      if (_disposed || _generation != gen) return;
      if (_state.isStreetComplete) {
        final boardBefore = _state.board.length;
        _state = ActionResolver.advanceStreet(_state);
        _playCommunityCardSounds(_state.board.length - boardBefore, gen);
      } else {
        final botAction = OpponentPolicy.decide(_state);
        _state = ActionResolver.apply(_state, botAction);
        PokerAudioService.instance.play(_actionAudio(botAction));
        if (_actionInvolvesChips(botAction)) {
          PokerAudioService.instance.play(PokerAudio.chipsPlace);
        }
      }
      await _settleIfHandOver();
      _notify();
      guard++;
      if (guard > 200) {
        throw StateError('HandTableController: la mano no cerró tras $guard '
            'pasos — posible ciclo en OpponentPolicy/ActionResolver.');
      }
    }
    // Turno del héroe: avisar con sonido (solo una vez por transición).
    if (!_handOver && _state.toActSlot == heroSlot) {
      PokerAudioService.instance.play(PokerAudio.yourTurn);
    }
  }

  /// Detecta si la mano terminó y, si es así, calcula los ganadores y
  /// programa la transferencia del bote con un breve retraso visual.
  Future<void> _settleIfHandOver() async {
    if (_handOver) return; // ya procesado

    if (_state.isHandOver) {
      // Fold-out: ganó por retiros, sin showdown — cartas del villano NO se muestran.
      _handOver = true;
      _isShowdown = false;
      _winnerSlots = _state.winnerSlots;
      PokerAudioService.instance.play(PokerAudio.winner);
      _schedulePotAward(_winnerSlots!);
      return;
    }
    if (!_state.needsShowdown) return;

    // Showdown real: 2+ jugadores llegan al final — cartas se revelan.
    final hands = <int, HoleCards>{
      for (final s in _state.seats)
        if (s.isActive && s.holeCards != null) s.slot: s.holeCards!,
    };
    final winners = HandEvaluator.winners(hands, _state.board);
    _handOver = true;
    _isShowdown = true;
    _winnerSlots = winners;
    PokerAudioService.instance.play(PokerAudio.winner);
    _schedulePotAward(winners);
  }

  /// Programa la transferencia del bote al ganador después de [_awardDelay].
  /// La UI muestra el estado "pot en mesa, stacks viejos" durante ese
  /// intervalo — la animación mínima pedida por Fix 6.
  void _schedulePotAward(Set<int> winners) {
    _potAwarded = false;
    // Usamos el mismo timer único de la clase; en este punto la mano ya
    // terminó así que ningún bot está esperando en él.
    _stepTimer?.cancel();
    _stepTimer = Timer(_awardDelay, () {
      if (_disposed) return;
      _state = _awardPot(_state, winners);
      _syncStacks();
      _potAwarded = true;
      _stepTimer = null;
      _notify();
    });
  }

  GameState _awardPot(GameState state, Set<int> winners) {
    final share = state.pot.totalBb / winners.length;
    final newSeats = [
      for (final s in state.seats)
        winners.contains(s.slot) ? s.copyWith(stackBb: s.stackBb + share) : s,
    ];
    return state.copyWith(seats: newSeats);
  }

  void _syncStacks() {
    for (final s in _state.seats) {
      _stacksBb[s.slot] = s.stackBb;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers de async / cancelación
  // ---------------------------------------------------------------------------

  /// Espera [duration] usando un Timer cancelable. Si [dispose] o
  /// [startNewHand] se llaman mientras se espera, el Completer se
  /// completa inmediatamente (sin lanzar excepción) y el llamador debe
  /// verificar `_disposed` / `_generation` al volver.
  Future<void> _delay(Duration duration) async {
    if (_disposed) return;
    // Camino rápido para tests: Duration.zero no crea Timer ni Completer —
    // el overhead de la cola de eventos haría que los tests de rotación de
    // botón (6 manos × ~11 pasos) superasen el timeout de 30 s.
    // En producción nunca se pasa cero (los delays son 150ms/800ms/1500ms).
    if (duration == Duration.zero) return;
    final c = Completer<void>();
    _stepCompleter = c;
    _stepTimer?.cancel();
    _stepTimer = Timer(duration, () {
      if (!c.isCompleted) c.complete();
    });
    await c.future;
    // Limpiar solo si somos el completer activo (puede haber cambiado si
    // dispose/cancelCurrentStep se llamó entre medio).
    if (_stepCompleter == c) {
      _stepCompleter = null;
      _stepTimer = null;
    }
  }

  /// Cancela el Timer activo y desbloquea cualquier `await _delay` en marcha.
  void _cancelCurrentStep() {
    _stepTimer?.cancel();
    _stepTimer = null;
    final c = _stepCompleter;
    _stepCompleter = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Convierte una [PokerAction] al [PokerAudio] correspondiente.
  /// All-in tiene prioridad sobre bet/raise para que el sonido sea correcto
  /// cuando el stack restante coincide con el tamaño de la apuesta.
  static PokerAudio _actionAudio(PokerAction action) {
    return switch (action.type) {
      ActionType.fold => PokerAudio.fold,
      ActionType.check => PokerAudio.check,
      ActionType.call => PokerAudio.call,
      ActionType.limp => PokerAudio.call,
      ActionType.bet => PokerAudio.bet,
      ActionType.raise => PokerAudio.raise,
      ActionType.allIn => PokerAudio.allIn,
    };
  }

  /// `true` cuando la acción implica mover fichas — dispara [PokerAudio.chipsPlace]
  /// en paralelo al sonido de voz de la acción.
  static bool _actionInvolvesChips(PokerAction action) {
    return switch (action.type) {
      ActionType.bet ||
      ActionType.call ||
      ActionType.limp ||
      ActionType.raise ||
      ActionType.allIn =>
        true,
      _ => false,
    };
  }

  /// Dispara [PokerAudio.cardDeal] staggerado para cada carta comunitaria nueva.
  ///
  /// El stagger es 120ms (> el dedup de 100ms para [PokerAudio.cardDeal])
  /// y se aproxima al stagger visual de [CardEntrance] (55ms por carta más
  /// la expansión de [AnimatedSize] de 260ms). La generación [gen] se
  /// captura en el sitio de llamada: si la mano fue cancelada antes de que
  /// el Future.delayed dispare, el sonido se descarta limpiamente.
  void _playCommunityCardSounds(int count, int gen) {
    for (var i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        if (!_disposed && _generation == gen) {
          PokerAudioService.instance.play(PokerAudio.cardDeal);
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelCurrentStep();
    super.dispose();
  }
}
