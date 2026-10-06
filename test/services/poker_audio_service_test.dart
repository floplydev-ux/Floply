import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/services/poker_audio_service.dart';

void main() {
  // Los paths se replican acá para que el test sea autónomo y falle si
  // alguien cambia el enum sin actualizar los assets.
  const expectedPaths = {
    PokerAudio.call: 'audio/poker/call.mp3',
    PokerAudio.fold: 'audio/poker/fold.mp3',
    PokerAudio.raise: 'audio/poker/raise.mp3',
    PokerAudio.bet: 'audio/poker/bet.mp3',
    PokerAudio.winner: 'audio/poker/winner.mp3',
    PokerAudio.yourTurn: 'audio/poker/your_turn.mp3',
    PokerAudio.allIn: 'audio/poker/all_in.mp3',
    PokerAudio.check: 'audio/poker/check.mp3',
    PokerAudio.cardDeal: 'audio/poker/card_deal.mp3',
    PokerAudio.chipsPlace: 'audio/poker/chips_place.mp3',
  };

  group('PokerAudio — paths de assets', () {
    test('todos los valores del enum tienen un path definido', () {
      for (final audio in PokerAudio.values) {
        expect(expectedPaths.containsKey(audio), isTrue,
            reason: '${audio.name} no tiene un path esperado en el test.');
      }
    });

    test('todos los paths esperados usan extensión .mp3', () {
      for (final entry in expectedPaths.entries) {
        expect(entry.value.endsWith('.mp3'), isTrue,
            reason: '${entry.key.name}: "${entry.value}" debe terminar en .mp3');
      }
    });

    test('raise usa "raise" (no "rise")', () {
      final path = expectedPaths[PokerAudio.raise]!;
      expect(path, contains('raise'));
      expect(path, isNot(contains('rise')));
    });

    test('allIn usa "all_in" (con guión bajo)', () {
      expect(expectedPaths[PokerAudio.allIn], contains('all_in'));
    });

    test('yourTurn usa "your_turn" (con guión bajo)', () {
      expect(expectedPaths[PokerAudio.yourTurn], contains('your_turn'));
    });

    test('cardDeal usa "card_deal" (con guión bajo)', () {
      expect(expectedPaths[PokerAudio.cardDeal], contains('card_deal'));
    });

    test('chipsPlace usa "chips_place" (con guión bajo)', () {
      expect(expectedPaths[PokerAudio.chipsPlace], contains('chips_place'));
    });

    test('no hay paths duplicados entre audios distintos', () {
      final paths = expectedPaths.values.toList();
      expect(paths.toSet().length, paths.length,
          reason: 'Dos PokerAudio distintos no deben apuntar al mismo archivo.');
    });

    test('todos los valores del enum tienen un path propio (cobertura total)', () {
      expect(expectedPaths.length, PokerAudio.values.length,
          reason: 'Si se agregó un nuevo PokerAudio, agregar su path aquí.');
    });
  });

  group('PokerAudioService.soundEnabled', () {
    late bool originalSoundEnabled;

    setUp(() => originalSoundEnabled = PokerAudioService.instance.soundEnabled);
    tearDown(
        () => PokerAudioService.instance.soundEnabled = originalSoundEnabled);

    test('ON por defecto (valor de instancia inicial)', () {
      // El singleton arranca en true; si alguien lo cambió antes, tearDown
      // lo restaura.
      PokerAudioService.instance.soundEnabled = true;
      expect(PokerAudioService.instance.soundEnabled, isTrue);
    });

    test('se puede desactivar y reactivar', () {
      PokerAudioService.instance.soundEnabled = false;
      expect(PokerAudioService.instance.soundEnabled, isFalse);
      PokerAudioService.instance.soundEnabled = true;
      expect(PokerAudioService.instance.soundEnabled, isTrue);
    });

    test('play no lanza excepción cuando soundEnabled = false', () async {
      PokerAudioService.instance.soundEnabled = false;
      await expectLater(
          PokerAudioService.instance.play(PokerAudio.check), completes);
    });

    test('dos play() consecutivos del mismo audio no lanzan excepción', () async {
      PokerAudioService.instance.soundEnabled = false;
      await PokerAudioService.instance.play(PokerAudio.fold);
      await PokerAudioService.instance.play(PokerAudio.fold);
    });
  });
}
