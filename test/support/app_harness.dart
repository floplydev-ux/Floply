import 'package:flutter/material.dart';
import 'package:poker_trainer/auth/auth_controller.dart';
import 'package:poker_trainer/auth/fake_auth_repository.dart';
import 'package:poker_trainer/auth/fake_user_repository.dart';
import 'package:poker_trainer/engine/academy/academy_store.dart';
import 'package:poker_trainer/persistence/local_auth_flag_store.dart';
import 'package:poker_trainer/screens/root/app_shell.dart';

/// La app completa (`AppShell`, invitado) sin Firebase real — mismo patrón
/// que ya usaba `test/ui/app_shell_test.dart` de forma privada, extraído
/// acá porque Fase 0 (infraestructura QA) lo necesita de nuevo en
/// accessibility, golden e integration tests: escribirlo una cuarta vez
/// hubiera sido la clase de duplicación que ya señalamos como hallazgo en
/// el resto de la app (ver Design System Baseline). Los tests existentes
/// que ya tenían su propia copia privada no se tocan — no hacía falta para
/// que corrieran.
Widget testAppShell({AcademyStore? academyStore}) => MaterialApp(
      home: AppShell(
        academyStore: academyStore ?? InMemoryAcademyStore(),
        authController: AuthController(
          authRepository: FakeAuthRepository(),
          userRepository: FakeUserRepository(),
          flagStore: InMemoryAuthFlagStore(),
          localStoreBuilder: () => InMemoryAcademyStore(),
          remoteAcademyStoreBuilder: (_) => InMemoryAcademyStore(),
        ),
      ),
    );
