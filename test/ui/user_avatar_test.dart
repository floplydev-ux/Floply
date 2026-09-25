import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/widgets/user_avatar.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: child))),
      );

  testWidgets('sin photoUrl: muestra la inicial del nombre, sin romper',
      (tester) async {
    await pump(tester, const UserAvatar(displayName: 'Juan'));
    await tester.pump();

    expect(find.text('J'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nombre vacío: cae a "?" en vez de reventar', (tester) async {
    await pump(tester, const UserAvatar(displayName: ''));
    await tester.pump();

    expect(find.text('?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'con photoUrl que no puede cargar (sin red en test): cae a la '
      'inicial en vez de mostrar un error visual', (tester) async {
    await pump(
      tester,
      const UserAvatar(
        displayName: 'Juan',
        photoUrl: 'https://no-existe.invalid/foto.png',
      ),
    );
    // Deja que Image.network falle y el errorBuilder haga su trabajo.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('J'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('respeta el tamaño pedido', (tester) async {
    await pump(
      tester,
      const UserAvatar(displayName: 'Juan', size: 80),
    );
    await tester.pump();

    final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
    expect(sizedBox.width, 80);
    expect(sizedBox.height, 80);
  });
}
