import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import '../../widgets/sala_verde/sala_verde_widgets.dart';

/// Hoja para editar el nombre visible — usada tanto por cuenta real
/// ([AuthController.updateDisplayName]) como por invitado
/// ([AuthController.updateGuestDisplayName]); no sabe cuál de las dos es,
/// solo devuelve el texto nuevo (o `null` si se canceló).
Future<String?> showEditNameSheet(
  BuildContext context, {
  required String currentName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _EditNameSheet(currentName: currentName),
  );
}

class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.currentName});

  final String currentName;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    Navigator.of(context).pop(value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DecoratedBox(
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
                Text(AppStrings.profileEditNameTitle, style: SalaVerdeType.title()),
                const SizedBox(height: SalaVerdeSpace.lg),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: 40,
                  style: SalaVerdeType.body(color: SalaVerdeColors.textPrimary),
                  cursorColor: SalaVerdeColors.brassBright,
                  decoration: InputDecoration(
                    hintText: AppStrings.profileEditNameHint,
                    hintStyle: SalaVerdeType.body(color: SalaVerdeColors.textMuted),
                    filled: true,
                    fillColor: SalaVerdeColors.surfaceElevated,
                    counterStyle: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: SalaVerdeSpace.md),
                SvButtonPrimary(
                  label: AppStrings.profileEditNameSave,
                  onTap: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
