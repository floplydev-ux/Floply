import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Anchos de teléfono que la suite ya usaba, repetidos como literal en
/// varios archivos (`home_screen_test.dart`, `preflop_session_summary_view_test.dart`,
/// los `academy_level*_test.dart`, entre otros) — de Android chico a un
/// teléfono grande. Fase 0 (infraestructura QA) los centraliza acá para que
/// los tests NUEVOS (golden, accessibility) no agreguen una sexta copia del
/// mismo número; los archivos existentes se dejan como están, no se tocan
/// sin necesidad.
const List<double> kResponsivePhoneWidths = [320.0, 360.0, 390.0, 412.0, 430.0];

/// Aplica [width] al `tester` con el mismo `devicePixelRatio: 3.0` que ya
/// usa el resto de la suite, y registra el `addTearDown(tester.view.reset)`
/// correspondiente — evita que un test nuevo se olvide del reset y deje
/// tamaño pegado para el próximo test del mismo archivo.
void setResponsiveWidth(WidgetTester tester, double width, {double height = 900}) {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}
