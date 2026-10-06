import 'package:audioplayers/audioplayers.dart';

/// Sonidos de póker disponibles en la aplicación.
///
/// Para agregar un nuevo sonido:
/// 1. Colocar el archivo en `assets/audio/poker/<nombre>.mp3`.
/// 2. Agregar un valor al enum.
/// 3. Agregar la entrada en [PokerAudioService._assetPath].
/// 4. Agregar en [PokerAudioService._minIntervalByAudio] si necesita
///    un intervalo de dedup distinto al default (300ms).
/// 5. Llamar a `PokerAudioService.instance.play(PokerAudio.nuevoSonido)`.
enum PokerAudio {
  // — Acciones de jugador —
  call,
  fold,
  raise,
  bet,
  winner,
  yourTurn,
  allIn,
  check,
  // — Cartas —
  cardDeal,   // una carta llega a su posición (deal + community)
  // — Fichas —
  chipsPlace; // fichas se colocan (bet / call / raise / all-in)

  String get _assetPath {
    return switch (this) {
      PokerAudio.call => 'audio/poker/call.mp3',
      PokerAudio.fold => 'audio/poker/fold.mp3',
      PokerAudio.raise => 'audio/poker/raise.mp3',
      PokerAudio.bet => 'audio/poker/bet.mp3',
      PokerAudio.winner => 'audio/poker/winner.mp3',
      PokerAudio.yourTurn => 'audio/poker/your_turn.mp3',
      PokerAudio.allIn => 'audio/poker/all_in.mp3',
      PokerAudio.check => 'audio/poker/check.mp3',
      PokerAudio.cardDeal => 'audio/poker/card_deal.mp3',
      PokerAudio.chipsPlace => 'audio/poker/chips_place.mp3',
    };
  }
}

/// Servicio centralizado de audio para todas las mesas de FLOPly.
///
/// Uso:
/// ```dart
/// PokerAudioService.instance.play(PokerAudio.call);
/// ```
///
/// Habilitar/deshabilitar sonido:
/// ```dart
/// PokerAudioService.instance.soundEnabled = false;
/// ```
///
/// Ciclo de vida: el servicio es un singleton de proceso. Cada mesa
/// llama a [play] directamente — no hay que crear ni destruir instancias
/// por pantalla. El singleton se autolimpia cuando el proceso termina.
class PokerAudioService {
  PokerAudioService._();

  static final PokerAudioService instance = PokerAudioService._();

  /// ON por defecto. Cambia en tiempo real — se respeta en la próxima
  /// llamada a [play].
  bool soundEnabled = true;

  /// Pool de un player por audio para evitar latencia en la primera
  /// reproducción. Los players se crean al primer uso y se reutilizan.
  final Map<PokerAudio, AudioPlayer> _players = {};

  /// Timestamp del último `play` por audio — protección anti-duplicados:
  /// si el mismo sonido ya se reprodujo dentro de su intervalo mínimo,
  /// la llamada se descarta. Evita acumulación por rebuilds o callbacks dobles.
  final Map<PokerAudio, DateTime> _lastPlayed = {};

  /// Intervalo mínimo entre dos reproducciones del mismo audio (ms).
  /// Default 300ms — suficiente para absorber doble-taps y rebuilds.
  static const int _defaultMinIntervalMs = 300;

  /// Override por sonido para los que se disparan en ráfaga rápida.
  /// cardDeal se reproduce una vez por carta: 150ms en el deal de hole-cards
  /// (intervalo de HandTableController._dealAnimated) y 120ms en community
  /// cards — ambos mayores que 100ms, así que pasan el guard.
  static const Map<PokerAudio, int> _minIntervalByAudio = {
    PokerAudio.cardDeal: 100,
  };

  /// Reproduce [audio] si el sonido está habilitado y no se reproduce ya.
  /// Nunca lanza excepción: si el audio falla, la partida continúa.
  Future<void> play(PokerAudio audio) async {
    if (!soundEnabled) return;

    final now = DateTime.now();
    final last = _lastPlayed[audio];
    final minMs = _minIntervalByAudio[audio] ?? _defaultMinIntervalMs;
    if (last != null && now.difference(last).inMilliseconds < minMs) {
      return;
    }
    _lastPlayed[audio] = now;

    try {
      final player = _players.putIfAbsent(audio, AudioPlayer.new);
      // stop() + play() garantiza que el sonido empieza desde el principio
      // aunque se llame mientras ya suena (ej. fold rápido seguido de fold).
      await player.stop();
      await player.play(AssetSource(audio._assetPath));
    } catch (_) {
      // El audio es complementario — nunca interrumpir la lógica de juego.
    }
  }

  /// Libera todos los reproductores. Llamar solo al cerrar la app o en
  /// tests — las mesas no necesitan llamar a esto porque el singleton
  /// sobrevive a la navegación (correcto: no queremos crear/destruir
  /// players en cada pantalla).
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _lastPlayed.clear();
  }
}
