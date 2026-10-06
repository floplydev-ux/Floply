import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../engine/strategy/hand_range.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../widgets/tool_widgets.dart';

/// Import/Export (sección 26) — formato interno robusto (JSON) más CSV
/// simple, ambos vía el portapapeles: el proyecto no tiene ninguna
/// dependencia de compartir archivos, así que `Clipboard`
/// (`flutter/services.dart`, ya parte del SDK) es la vía sin agregar un
/// paquete nuevo solo para esto.
String rangeToJson(HandRange range) => jsonEncode(range.frequencies);

String rangeToCsv(HandRange range) {
  final buffer = StringBuffer('hand,frequency\n');
  final entries = range.frequencies.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  for (final e in entries) {
    buffer.writeln('${e.key},${e.value}');
  }
  return buffer.toString();
}

/// Devuelve `null` si [text] no es ni un JSON ni un CSV de rango válido.
HandRange? rangeFromText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) {
      return HandRange(decoded.map((k, v) => MapEntry(k as String, (v as num).toDouble())));
    }
  } catch (_) {
    // no era JSON — probamos CSV abajo.
  }
  try {
    final lines = trimmed.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final freqs = <String, double>{};
    for (final line in lines) {
      if (line.toLowerCase().startsWith('hand,')) continue;
      final parts = line.split(',');
      if (parts.length != 2) return null;
      freqs[parts[0].trim()] = double.parse(parts[1].trim());
    }
    return freqs.isEmpty ? null : HandRange(freqs);
  } catch (_) {
    return null;
  }
}

/// Hoja de Import/Export — dos botones de copiar + un campo para pegar.
Future<HandRange?> showRangeImportExportSheet(BuildContext context, {required HandRange range}) {
  return showModalBottomSheet<HandRange?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _ImportExportSheet(range: range),
  );
}

class _ImportExportSheet extends StatefulWidget {
  const _ImportExportSheet({required this.range});

  final HandRange range;

  @override
  State<_ImportExportSheet> createState() => _ImportExportSheetState();
}

class _ImportExportSheetState extends State<_ImportExportSheet> {
  final _pasteController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.rangesCopiedConfirmation)),
    );
  }

  void _import() {
    final parsed = rangeFromText(_pasteController.text);
    if (parsed == null) {
      setState(() => _error = AppStrings.rangesImportError);
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SalaVerdeColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(SalaVerdeRadius.sheet)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(SalaVerdeSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ToolSectionLabel(AppStrings.rangesImportExportTitle, color: kToolAccent),
              const SizedBox(height: SalaVerdeSpace.md),
              Row(
                children: [
                  Expanded(
                    child: SvButtonSecondary(
                      label: AppStrings.rangesExportJson,
                      onTap: () => _copy(rangeToJson(widget.range)),
                    ),
                  ),
                  const SizedBox(width: SalaVerdeSpace.sm),
                  Expanded(
                    child: SvButtonSecondary(
                      label: AppStrings.rangesExportCsv,
                      onTap: () => _copy(rangeToCsv(widget.range)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SalaVerdeSpace.lg),
              const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
              const SizedBox(height: SalaVerdeSpace.lg),
              ToolTextField(
                label: AppStrings.rangesImportLabel,
                controller: _pasteController,
                hintText: AppStrings.rangesImportHint,
                onChanged: () => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: SalaVerdeSpace.sm),
                ToolErrorCard(message: _error!),
              ],
              const SizedBox(height: SalaVerdeSpace.lg),
              SvButtonPrimary(
                label: AppStrings.rangesImportAction,
                accent: kToolAccent,
                onTap: _import,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
