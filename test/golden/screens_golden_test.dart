import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/engine/poker_trainer_engine.dart';
import 'package:poker_trainer/screens/academy/academy_controller.dart';
import 'package:poker_trainer/screens/academy/academy_screen.dart';
import 'package:poker_trainer/screens/bankroll/bankroll_screen.dart';
import 'package:poker_trainer/screens/home/home_screen.dart';
import 'package:poker_trainer/screens/laboratory/lab_session_controller.dart';
import 'package:poker_trainer/screens/laboratory/laboratory_screen.dart';
import 'package:poker_trainer/screens/tools/tools_screen.dart';

/// Baseline visual (Fase 0) de una pantalla representativa por módulo, a
/// 390dp (referencia media del sweep responsive que ya usa la suite). Solo
/// cubre el estado INICIAL de cada pantalla — no cada paso de cada flujo
/// (teoría/ejercicio/feedback de Academia y Laboratorio quedan fuera de
/// esta fase a propósito, ver AUDITORIA/BASELINE: necesitan fixtures más
/// profundas que esto y no son necesarias para "tener una base"). Foto del
/// estado actual, no un veredicto de que el diseño esté bien.
const _deviceSize = Size(390, 844);

/// `scenarioConstraints` (BoxConstraints) por sí solo NO cambia lo que
/// `MediaQuery.of(context).size` reporta adentro — solo acota el tamaño del
/// box que envuelve al widget. Varios widgets de esta app (ver Design
/// System Baseline) miden su propio contenido contra el ancho de pantalla
/// real, así que sin este `MediaQuery` explícito el golden renderiza con
/// el tamaño de superficie por default de Alchemist (más ancho) y overflow
/// que NO existe en un dispositivo real de 390dp — los mismos widgets ya
/// pasan sin overflow a 390dp en `test/ui/home_screen_test.dart`, que sí
/// fija `tester.view.physicalSize`. Esto replica esa misma condición.
Widget _atDeviceSize(Widget home) => MediaQuery(
      data: const MediaQueryData(size: _deviceSize),
      child: MaterialApp(
        home: SizedBox(width: _deviceSize.width, height: _deviceSize.height, child: home),
      ),
    );

Future<AcademyController> _freshAcademyController() async {
  final controller = AcademyController(
    engine: PokerTrainerEngine(seed: 1),
    store: InMemoryAcademyStore(),
  );
  await controller.load();
  return controller;
}

void main() {
  goldenTest(
    'HomeScreen (usuario nuevo)',
    fileName: 'home_screen',
    builder: () => GoldenTestGroup(
      scenarioConstraints: BoxConstraints.tight(_deviceSize),
      children: [
        GoldenTestScenario(
          name: 'default',
          child: FutureBuilder<AcademyController>(
            future: _freshAcademyController(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return _atDeviceSize(HomeScreen(
                academyController: snapshot.data!,
                onGoToAcademy: () {},
                onGoToLaboratory: () {},
                onGoToProfile: () {},
              ));
            },
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'ToolsScreen (hub)',
    fileName: 'tools_screen',
    builder: () => GoldenTestGroup(
      scenarioConstraints: BoxConstraints.tight(_deviceSize),
      children: [
        GoldenTestScenario(name: 'default', child: _atDeviceSize(const ToolsScreen())),
      ],
    ),
  );

  goldenTest(
    'BankrollScreen',
    fileName: 'bankroll_screen',
    builder: () => GoldenTestGroup(
      scenarioConstraints: BoxConstraints.tight(_deviceSize),
      children: [
        GoldenTestScenario(name: 'default', child: _atDeviceSize(const BankrollScreen())),
      ],
    ),
  );

  goldenTest(
    'AcademyScreen (mapa de niveles)',
    fileName: 'academy_screen_level_map',
    builder: () => GoldenTestGroup(
      scenarioConstraints: BoxConstraints.tight(_deviceSize),
      children: [
        GoldenTestScenario(
          name: 'default',
          child: FutureBuilder<AcademyController>(
            future: _freshAcademyController(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return _atDeviceSize(
                  Scaffold(body: AcademyScreen(controller: snapshot.data!)));
            },
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'LaboratoryScreen (pantalla de inicio)',
    fileName: 'laboratory_screen_start',
    builder: () => GoldenTestGroup(
      scenarioConstraints: BoxConstraints.tight(_deviceSize),
      children: [
        GoldenTestScenario(
          name: 'default',
          child: _atDeviceSize(Scaffold(
            body: LaboratoryScreen(
              controller: LabSessionController(
                engine: PokerTrainerEngine(seed: 1),
                sessionLength: 3,
              ),
            ),
          )),
        ),
      ],
    ),
  );
}
