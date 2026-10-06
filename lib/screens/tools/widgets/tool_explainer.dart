import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../persistence/tool_explainer_store.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';

/// Sistema de explicación contextual de Tools (Grupo 3) — **una sola**
/// arquitectura para las 6 herramientas: cada Tool solo aporta su
/// [ToolExplainerContent] (texto), nunca su propia pantalla/lógica de
/// "primera vez". Ver el header de cada calculadora para el ícono ⓘ que
/// abre lo mismo bajo demanda (`ToolHeader.trailing`, reservado para
/// esto en el Grupo 2).
class ToolExplainerContent {
  const ToolExplainerContent({
    required this.title,
    required this.description,
    required this.howToUse,
    required this.result,
    this.extra,
  });

  /// Qué hace / para qué sirve — una idea, no un párrafo largo.
  final String description;
  final String title;

  /// Qué tiene que introducir/seleccionar el usuario.
  final String howToUse;

  /// Qué resultado obtiene y cómo interpretarlo (cuando hace falta).
  final String result;

  /// Información complementaria opcional (una advertencia puntual, un
  /// alcance del cálculo) — `null` si la herramienta no la necesita.
  final String? extra;
}

/// Se llama una vez por pantalla, en el primer frame (`initState` →
/// `addPostFrameCallback`): muestra la explicación solo si el usuario
/// todavía no marcó "no volver a mostrar" para [toolId].
Future<void> maybeShowToolExplainer(
  BuildContext context, {
  required String toolId,
  required ToolExplainerContent content,
  ToolExplainerStore? store,
}) async {
  final s = store ?? defaultToolExplainerStore;
  final dismissed = await s.isDismissed(toolId);
  if (dismissed || !context.mounted) return;
  await showToolExplainerSheet(context, toolId: toolId, content: content, store: s);
}

/// Abre la hoja de explicación incondicionalmente — lo que llama el
/// ícono ⓘ del header. Nunca depende de si la preferencia está activada:
/// la ayuda siempre tiene que poder recuperarse a mano (sección 3).
Future<void> showToolExplainerSheet(
  BuildContext context, {
  required String toolId,
  required ToolExplainerContent content,
  ToolExplainerStore? store,
}) {
  final s = store ?? defaultToolExplainerStore;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _ToolExplainerSheet(toolId: toolId, content: content, store: s),
  );
}

class _ToolExplainerSheet extends StatefulWidget {
  const _ToolExplainerSheet({
    required this.toolId,
    required this.content,
    required this.store,
  });

  final String toolId;
  final ToolExplainerContent content;
  final ToolExplainerStore store;

  @override
  State<_ToolExplainerSheet> createState() => _ToolExplainerSheetState();
}

class _ToolExplainerSheetState extends State<_ToolExplainerSheet> {
  bool _dontShowAgain = false;
  bool _loadingInitial = true;

  @override
  void initState() {
    super.initState();
    widget.store.isDismissed(widget.toolId).then((value) {
      if (!mounted) return;
      setState(() {
        _dontShowAgain = value;
        _loadingInitial = false;
      });
    });
  }

  Future<void> _close() async {
    // Se persiste siempre al cerrar (con el valor actual del check), sea
    // que la hoja se haya abierto sola o desde el ícono ⓘ — así
    // desmarcarla desde ⓘ la vuelve a activar, sin un mecanismo aparte.
    await widget.store.setDismissed(widget.toolId, _dontShowAgain);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SalaVerdeColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(SalaVerdeRadius.sheet)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SalaVerdeSpace.lg,
            SalaVerdeSpace.lg,
            SalaVerdeSpace.lg,
            SalaVerdeSpace.lg,
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
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: kToolExplainerAccent, size: 20),
                  const SizedBox(width: SalaVerdeSpace.sm),
                  Expanded(child: Text(content.title, style: SalaVerdeType.title())),
                ],
              ),
              const SizedBox(height: SalaVerdeSpace.lg),
              Text(content.description, style: SalaVerdeType.body()),
              const SizedBox(height: SalaVerdeSpace.lg),
              _ExplainerRow(
                label: AppStrings.toolsExplainerHowToUse,
                body: content.howToUse,
              ),
              const SizedBox(height: SalaVerdeSpace.md),
              _ExplainerRow(
                label: AppStrings.toolsExplainerResult,
                body: content.result,
              ),
              if (content.extra != null) ...[
                const SizedBox(height: SalaVerdeSpace.md),
                SvCalloutAccent(
                  eyebrow: AppStrings.toolsExplainerExtra,
                  body: content.extra!,
                  color: SalaVerdeColors.warning,
                  icon: Icons.info_outline_rounded,
                ),
              ],
              const SizedBox(height: SalaVerdeSpace.lg),
              const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
              const SizedBox(height: SalaVerdeSpace.md),
              Opacity(
                opacity: _loadingInitial ? 0.5 : 1,
                child: PressableScale(
                  onTap: _loadingInitial
                      ? () {}
                      : () => setState(() => _dontShowAgain = !_dontShowAgain),
                  child: Row(
                    children: [
                      Icon(
                        _dontShowAgain
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 20,
                        color: _dontShowAgain ? kToolExplainerAccent : SalaVerdeColors.textMuted,
                      ),
                      const SizedBox(width: SalaVerdeSpace.sm),
                      Expanded(
                        child: Text(
                          AppStrings.toolsExplainerDontShowAgain,
                          style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SalaVerdeSpace.lg),
              SvButtonPrimary(
                label: AppStrings.toolsExplainerCta,
                accent: kToolExplainerAccent,
                onTap: _close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplainerRow extends StatelessWidget {
  const _ExplainerRow({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SalaVerdeType.label(color: SalaVerdeColors.textMuted)),
        const SizedBox(height: 4),
        Text(body, style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary)),
      ],
    );
  }
}

/// Acento del sistema de explicación — deliberadamente el mismo
/// `graphiteSteelBright` que ya identifica a Tools (`kToolAccent` en
/// `tool_widgets.dart`), repetido acá con su propio nombre porque este
/// archivo no depende de `tool_widgets.dart` (evita un import circular
/// innecesario: varios screens importan este archivo Y ese).
const Color kToolExplainerAccent = SalaVerdeColors.graphiteSteelBright;

/// Botón ⓘ para el `trailing` de [ToolHeader] (y, desde la guía
/// consolidada, también en el header del hub) — mismo tamaño VISUAL que
/// el botón de volver, para que el header quede simétrico, pero con el
/// ÁREA TÁPABLE llevada al mínimo de accesibilidad (48×48,
/// `androidTapTargetGuideline` — hallazgo real de
/// `core_screens_accessibility_test.dart` al auditar por primera vez un
/// uso de este botón: antes el círculo de 36×36 ERA el tap target
/// entero). Mismo criterio que ya usa `HomeTopBar._IconCircleButton`:
/// `SizedBox` más grande centrando el círculo más chico adentro, nunca
/// agrandando el círculo en sí.
class ToolInfoButton extends StatelessWidget {
  const ToolInfoButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SalaVerdeColors.surfaceElevated,
              border: Border.all(color: SalaVerdeColors.borderSubtle),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: kToolExplainerAccent, size: 18),
          ),
        ),
      ),
    );
  }
}
