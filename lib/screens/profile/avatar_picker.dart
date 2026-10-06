import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';

/// Elige una foto nueva de la galería o la cámara, la muestra en una
/// previsualización para confirmar, y la copia al almacenamiento propio de
/// la app (`getApplicationDocumentsDirectory`, igual que `FileAcademyStore`/
/// `FileAuthFlagStore` — nada de Firebase Storage: no hace falta subir la
/// imagen a la nube para que sobreviva a cerrar y volver a abrir la app en
/// EL MISMO dispositivo, que es todo lo pedido).
///
/// Devuelve la ruta absoluta del archivo ya guardado (`avatar_<ownerId>.jpg`,
/// sobrescribe la anterior), o `null` si el usuario canceló en cualquier
/// paso.
Future<String?> pickAndSaveAvatar(
  BuildContext context, {
  required String ownerId,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SourceSheet(),
  );
  if (source == null || !context.mounted) return null;

  final picker = ImagePicker();
  final XFile? picked;
  try {
    picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
  } catch (_) {
    return null;
  }
  if (picked == null || !context.mounted) return null;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _PreviewSheet(imagePath: picked!.path),
  );
  if (confirmed != true) return null;

  final dir = await getApplicationDocumentsDirectory();
  final dest = File('${dir.path}/avatar_$ownerId.jpg');
  await dest.writeAsBytes(await picked.readAsBytes(), flush: true);
  return dest.path;
}

/// Envoltorio visual compartido de las 2 hojas de este archivo — no se
/// promueve a `sala_verde_widgets.dart` porque, a diferencia de esos
/// componentes, esta forma (título + contenido con padding de hoja) todavía
/// no se repitió en una 3ª pantalla (criterio ya usado en este mismo
/// sistema, ver el doc-comment de `SvItemProgress`).
class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SalaVerdeColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SalaVerdeRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SalaVerdeSpace.lg,
            SalaVerdeSpace.lg,
            SalaVerdeSpace.lg,
            SalaVerdeSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: SalaVerdeSpace.lg),
                  decoration: BoxDecoration(
                    color: SalaVerdeColors.borderSubtle,
                    borderRadius: BorderRadius.circular(SalaVerdeRadius.pill),
                  ),
                ),
              ),
              Text(title, style: SalaVerdeType.title()),
              const SizedBox(height: SalaVerdeSpace.lg),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: AppStrings.profileChangePhoto,
      children: [
        _SourceTile(
          icon: Icons.photo_library_rounded,
          label: AppStrings.profilePickFromGallery,
          onTap: () => Navigator.of(context).pop(ImageSource.gallery),
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        _SourceTile(
          icon: Icons.photo_camera_rounded,
          label: AppStrings.profileTakePhoto,
          onTap: () => Navigator.of(context).pop(ImageSource.camera),
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: SalaVerdeColors.surfaceElevated,
          borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SalaVerdeSpace.lg,
          vertical: SalaVerdeSpace.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: SalaVerdeColors.brassBright, size: 22),
            const SizedBox(width: SalaVerdeSpace.md),
            Text(label, style: SalaVerdeType.bodyStrong()),
          ],
        ),
      ),
    );
  }
}

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: AppStrings.profileConfirmPhoto,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(SalaVerdeRadius.panel),
          child: Image.file(
            File(imagePath),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        Row(
          children: [
            Expanded(
              child: SvButtonSecondary(
                label: AppStrings.profileCancel,
                onTap: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: SalaVerdeSpace.md),
            Expanded(
              child: SvButtonPrimary(
                label: AppStrings.profileUsePhoto,
                onTap: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
