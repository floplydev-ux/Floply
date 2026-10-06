import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/engine/coach/hand_table_controller.dart';
import 'package:poker_trainer/engine/pedagogy/table_position.dart';
import 'package:poker_trainer/engine/poker/game/game_state.dart' show GameState;

/// Corrección de Coach (sección 5): el botón de dealer tiene que avanzar
/// en el sentido horario REAL de una mesa de póker — pasa siempre al
/// asiento que es la ciega chica (SB) de la mano anterior, nunca al que
/// era CO (eso era avanzar "al revés", el bug real: `_buttonSlot + 1` en
/// vez de `_buttonSlot - 1` — ver el doc-comment de
/// `HandTableController.startNewHand`). `TablePositions` (motor real,
/// `table_position.dart`) ya define el slot DECRECIENTE como el sentido
/// horario — este test verifica que `startNewHand` realmente lo respeta,
/// no solo que la asignación de posiciones DENTRO de una mano sea
/// correcta (eso nunca estuvo roto).
/// Instancia de prueba con todos los delays a cero — sin delays reales, los
/// tests de rotación de botón no esperan 1.5s × N bots × 6 manos.
HandTableController _fastController({int? seed, int heroSlot = 0}) =>
    HandTableController(
      random: seed != null ? Random(seed) : Random(),
      heroSlot: heroSlot,
      stepDelay: Duration.zero,
      dealStepDelay: Duration.zero,
      awardDelay: Duration.zero,
    );

void main() {
  group('HandTableController — rotación del botón (sentido horario real)', () {
    test('el botón pasa al asiento que hoy es SB, no al que es CO',
        () async {
      final controller = _fastController(seed: 1);
      addTearDown(controller.dispose);

      final buttonBefore = controller.state.buttonSlot;
      final sbSlotBefore = TablePositions(buttonBefore).slotOf(Position.sb);
      final coSlotBefore = TablePositions(buttonBefore).slotOf(Position.co);

      await controller.startNewHand();

      expect(controller.state.buttonSlot, sbSlotBefore,
          reason: 'el botón tiene que heredarlo quien era SB la mano '
              'anterior (sentido horario real)');
      expect(controller.state.buttonSlot, isNot(coSlotBefore),
          reason: 'nunca el que era CO — eso era el bug (sentido '
              'antihorario)');
    });

    test('la rotación es consistente a lo largo de varias manos', () async {
      final controller = _fastController(seed: 2);
      addTearDown(controller.dispose);

      for (var i = 0; i < 3; i++) {
        final buttonBefore = controller.state.buttonSlot;
        final expectedNext = TablePositions(buttonBefore).slotOf(Position.sb);
        await controller.startNewHand();
        expect(controller.state.buttonSlot, expectedNext, reason: 'mano ${i + 2}');
      }
    });

    test('después de 6 manos (una vuelta completa de 6-max) el botón '
        'vuelve exactamente al asiento de arranque', () async {
      final controller = _fastController(seed: 3);
      addTearDown(controller.dispose);

      final original = controller.state.buttonSlot;
      for (var i = 0; i < GameState.seatCount; i++) {
        await controller.startNewHand();
      }
      expect(controller.state.buttonSlot, original);
    });

    test('en 6 manos seguidas, el héroe (asiento fijo) pasa por las 6 '
        'posiciones reales, cada una exactamente una vez — nunca se '
        'salta ni repite ninguna', () async {
      final controller = _fastController(seed: 4, heroSlot: 0);
      addTearDown(controller.dispose);

      final heroPositions = <Position>[];
      for (var i = 0; i < Position.values.length; i++) {
        heroPositions.add(controller.state.positionOf(0));
        await controller.startNewHand();
      }

      expect(heroPositions.toSet(), Position.values.toSet());
      expect(heroPositions.length, Position.values.length,
          reason: 'ninguna posición se repite en las 6 manos');
    });
  });
}
