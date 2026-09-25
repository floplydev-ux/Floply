import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/l10n/app_strings.dart';

/// Fase 5 — regresión de BUG-002 (`FLOPLY_HUMAN_QA_PHASE4_5_2026-09-19.md`):
/// 3 strings de la sección "Auth — cuenta"/"conflicto de cuentas" de
/// [AppStrings] decían "Floply" en vez de "FLOPly" — el branding real,
/// usado correctamente en el resto de la app (p. ej. el logo de
/// `auth_screen.dart`).
///
/// Deliberadamente no es una migración global de naming (`FloplyUser`, el
/// nombre de clase del modelo de usuario, no cuenta — es un identificador
/// de código, no texto visible; ver §11 del informe de Fase 4.5) — solo
/// bloquea que estas 3 strings concretas vuelvan a tener el typo.
void main() {
  group('BUG-002 — branding "FLOPly" en las strings de cuenta', () {
    test('accountMethodsBody usa FLOPly', () {
      expect(AppStrings.accountMethodsBody, contains('FLOPly'));
      expect(AppStrings.accountMethodsBody, isNot(contains('Floply')));
    });

    test('accountGuestTitle usa FLOPly', () {
      expect(AppStrings.accountGuestTitle, contains('FLOPly'));
      expect(AppStrings.accountGuestTitle, isNot(contains('Floply')));
    });

    test('accountConflictTitle usa FLOPly', () {
      expect(AppStrings.accountConflictTitle, contains('FLOPly'));
      expect(AppStrings.accountConflictTitle, isNot(contains('Floply')));
    });
  });
}
