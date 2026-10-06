import 'package:flutter/material.dart';

import '../../../engine/strategy/saved_range.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../widgets/tool_widgets.dart';
import 'range_explorer_controller.dart';

/// "Mis Rangos" (sección 20) — separado de los oficiales de FLOPly
/// (sección 18): esta lista nunca mezcla `SavedRange` con
/// `OpeningRanges`. Abrir/editar/duplicar/eliminar viven acá;
/// comparar/practicar se disparan desde Explorar una vez abierto.
class MyRangesView extends StatelessWidget {
  const MyRangesView({
    super.key,
    required this.controller,
    required this.onOpen,
    required this.onEdit,
  });

  final RangeExplorerController controller;
  final ValueChanged<SavedRange> onOpen;
  final ValueChanged<SavedRange> onEdit;

  Future<void> _rename(BuildContext context, SavedRange range) async {
    final textController = TextEditingController(text: range.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SalaVerdeColors.surface,
        title: Text(AppStrings.rangesRename, style: SalaVerdeType.bodyStrong()),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: SalaVerdeType.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.rangesCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text.trim()),
            child: const Text(AppStrings.rangesRename),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await controller.updateRange(range.id, name: newName);
    }
  }

  Future<void> _confirmDelete(BuildContext context, SavedRange range) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SalaVerdeColors.surface,
        title: Text(AppStrings.rangesDelete, style: SalaVerdeType.bodyStrong()),
        content: Text(range.name, style: SalaVerdeType.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.rangesCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.rangesDelete,
                style: TextStyle(color: SalaVerdeColors.errorBright)),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteRange(range.id);
  }

  @override
  Widget build(BuildContext context) {
    if (controller.savedRangesLoading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: kToolAccent),
        ),
      );
    }
    if (controller.savedRanges.isEmpty) {
      return const ToolEmptyState(
        title: AppStrings.rangesMyRangesTitle,
        message: AppStrings.rangesMyRangesEmpty,
        icon: Icons.bookmark_border_rounded,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final range in controller.savedRanges) ...[
          _SavedRangeCard(
            range: range,
            onOpen: () => onOpen(range),
            onEdit: () => onEdit(range),
            onDuplicate: () => controller.duplicateRange(range),
            onRename: () => _rename(context, range),
            onDelete: () => _confirmDelete(context, range),
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
        ],
      ],
    );
  }
}

class _SavedRangeCard extends StatelessWidget {
  const _SavedRangeCard({
    required this.range,
    required this.onOpen,
    required this.onEdit,
    required this.onDuplicate,
    required this.onRename,
    required this.onDelete,
  });

  final SavedRange range;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final percent = range.toHandRange().percentOfAllHands;
    return ToolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PressableScale(
            onTap: onOpen,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(range.name, style: SalaVerdeType.bodyStrong()),
                      if (range.basedOnOfficialId != null)
                        Text(
                          '${AppStrings.rangesBasedOn} ${range.basedOnOfficialId}',
                          style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
                        ),
                    ],
                  ),
                ),
                Text('${percent.toStringAsFixed(1)}%',
                    style: SalaVerdeType.numeric(size: 14, color: SalaVerdeColors.success)),
              ],
            ),
          ),
          const SizedBox(height: SalaVerdeSpace.sm),
          Row(
            children: [
              _ActionLink(label: AppStrings.continueLabel, onTap: onOpen),
              const SizedBox(width: SalaVerdeSpace.md),
              _ActionLink(label: AppStrings.rangesModeBuild, onTap: onEdit),
              const SizedBox(width: SalaVerdeSpace.md),
              _ActionLink(label: AppStrings.rangesDuplicate, onTap: onDuplicate),
              const SizedBox(width: SalaVerdeSpace.md),
              _ActionLink(label: AppStrings.rangesRename, onTap: onRename),
              const Spacer(),
              _ActionLink(
                label: AppStrings.rangesDelete,
                onTap: onDelete,
                color: SalaVerdeColors.errorBright,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionLink extends StatelessWidget {
  const _ActionLink({required this.label, required this.onTap, this.color});

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Text(
        label,
        style: SalaVerdeType.caption(color: color ?? kToolAccent)
            .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}
