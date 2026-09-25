import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/auth/models/floply_user.dart';

void main() {
  FloplyUser userWith({String? photoUrl, String? customPhotoUrl}) {
    final now = DateTime(2026, 1, 1);
    return FloplyUser(
      id: 'uid-1',
      createdAt: now,
      updatedAt: now,
      displayName: 'Jugador',
      photoUrl: photoUrl,
      customPhotoUrl: customPhotoUrl,
    );
  }

  group('FloplyUser.avatarUrl — prioridad pedida por el usuario', () {
    test('sin ninguna foto -> null (el widget decide el fallback)', () {
      expect(userWith().avatarUrl, isNull);
    });

    test('solo la del proveedor (Google/Apple) -> esa', () {
      expect(userWith(photoUrl: 'https://google/foto.png').avatarUrl,
          'https://google/foto.png');
    });

    test(
        'avatar propio de Floply (a futuro) gana sobre la del proveedor '
        'sin tocar nada más', () {
      expect(
        userWith(
          photoUrl: 'https://google/foto.png',
          customPhotoUrl: 'https://floply/mi-avatar.png',
        ).avatarUrl,
        'https://floply/mi-avatar.png',
      );
    });
  });

  test('toJson/fromJson conserva customPhotoUrl (round-trip)', () {
    final user = userWith(
      photoUrl: 'https://google/foto.png',
      customPhotoUrl: 'https://floply/mi-avatar.png',
    );
    final restored = FloplyUser.fromJson(user.toJson());
    expect(restored.customPhotoUrl, 'https://floply/mi-avatar.png');
    expect(restored.avatarUrl, 'https://floply/mi-avatar.png');
  });

  test('copyWith no pisa customPhotoUrl si no se pasa', () {
    final user = userWith(customPhotoUrl: 'https://floply/mi-avatar.png');
    final updated = user.copyWith(displayName: 'Otro nombre');
    expect(updated.customPhotoUrl, 'https://floply/mi-avatar.png');
  });
}
