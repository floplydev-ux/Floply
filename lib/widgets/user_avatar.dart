import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Círculo de identidad del usuario — foto si hay una URL válida, si no
/// (o si falla la carga) la inicial del nombre sobre el gradiente violeta
/// de siempre. No sabe nada de Firebase ni de dónde sale [photoUrl]: solo
/// recibe una URL ya resuelta (ver `FloplyUser.avatarUrl`) o `null`.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.size = 46,
  });

  final String displayName;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial =
        displayName.trim().isEmpty ? '?' : displayName.trim()[0].toUpperCase();

    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: AppColors.violetGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );

    final url = photoUrl;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (url == null || url.isEmpty)
            ? fallback
            : Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // Nunca un error visual: si la imagen no carga (URL
                // vencida, sin conexión, provider raro), se ve la misma
                // inicial de siempre — el usuario no nota la diferencia
                // entre "no tiene foto" y "la foto no cargó".
                errorBuilder: (context, error, stackTrace) => fallback,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }
}
