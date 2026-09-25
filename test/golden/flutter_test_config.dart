import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Config de Alchemist, con alcance SOLO a `test/golden/` (Flutter busca el
/// `flutter_test_config.dart` más cercano hacia arriba del árbol — no se
/// puso en la raíz de `test/` a propósito, así el resto de la suite
/// (~960 tests) sigue corriendo exactamente igual que antes de esta fase).
///
/// `platformGoldensConfig` queda deshabilitado: esos goldens usan las
/// fuentes reales instaladas en la máquina que corre el test, así que un
/// golden generado en esta Windows local fallaría en cualquier otra
/// máquina/CI con fuentes distintas — lo opuesto a "reproducible"
/// (criterio de calidad ya usado para elegir este stack). `ciGoldensConfig`
/// quede habilitado: reemplaza el texto por bloques de color determinísticos,
/// independientes de fuentes instaladas — son los goldens que se versionan.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: CiGoldensConfig(enabled: true),
    ),
    run: testMain,
  );
}
